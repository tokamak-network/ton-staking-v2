# 마이그레이션 가이드

## 1. 업그레이드 순서

```
1. SeigManagerV1_4Storage 배포
2. SeigManagerV1_4 로직 배포
3. RATStorage 배포
4. RAT 배포 (검증자 등록/담보금/슬래싱)
5. ValidatorRewardStorage 배포
6. ValidatorRewardV1 배포 (검증자 보상 분배)
7. Layer2ManagerV1_2 로직 배포
8. L1BridgeRegistryV1_2 로직 배포

9. 프록시 업그레이드:
   - ProxySeigManager.upgradeTo(SeigManagerV1_4)
   - ProxyLayer2Manager.upgradeTo(Layer2ManagerV1_2)
   - ProxyL1BridgeRegistry.upgradeTo(L1BridgeRegistryV1_2)

10. 초기 파라미터 설정:
    - setDaoDistributionRatio(0.2e27)     // d = 20%
    - setMinStakingRatio(0.1e27)          // θ = 10%
    - setValidatorDistributionRatio(0.2e27) // α = 20%
    - setHalfSaturationPoint(10_000_000e27) // k = 1000만 TON
    // 초기에는 v3Migrated = false (V2 모드)

11. 검증자 컨트랙트 연결:
    - SeigManager.setRatContract(RAT)
    - SeigManager.setValidatorReward(ValidatorRewardV1)
    - ValidatorRewardV1.setRatContract(RAT)
```

---

## 2. 데이터 마이그레이션

```solidity
/// @notice V2 → V3 데이터 마이그레이션
function migrateToV3() external onlyOwner {
    // 1. 기존 layer2RewardInfo에서 TVL 데이터 마이그레이션
    uint256 numLayer2s = ILayer2Registry(layer2Registry).numLayer2s();

    for (uint256 i = 0; i < numLayer2s; i++) {
        address layer2 = ILayer2Registry(layer2Registry).layer2ByIndex(i);

        // V2의 TVL 데이터를 V3의 초기 Bridged TON으로 설정
        uint256 currentTvl = layer2RewardInfo[layer2].layer2Tvl;

        bridgedTONInfo[layer2] = BridgedTONInfo({
            currentBridgedTON: currentTvl,
            effectiveBridgedTON: currentTvl,  // 초기에는 모두 유효
            initialDebt: 0,
            startBlock: block.number,
            lastUpdateTime: block.timestamp,
            isEligible: true  // 초기에는 모두 자격 있음으로 설정
        });

        // 전역 합계 갱신
        totalEffectiveBridgedTON += currentTvl;
    }

    // 2. 첫 기간 초기화
    currentPeriodId = 1;
    periods[1].startBlock = block.number;
}
```

---

## 3. 하위 호환성

```solidity
/// @notice V2 호환 updateSeigniorage (deprecated, V3 자동 호출)
function updateSeigniorage() external returns (bool) {
    // V3 로직으로 리다이렉트
    return updateSeigniorageV3();
}

/// @notice V2 호환 estimatedDistribute
function estimatedDistribute(uint256 blockNumber, address layer2)
    external view
    returns (
        uint256 maxSeig,
        uint256 stakedSeig,
        uint256 unstakedSeig,
        uint256 powertonSeig,
        uint256 daoSeig,
        uint256 relativeSeig,
        uint256 l2TotalSeigs,
        uint256 layer2Seigs
    )
{
    // V3 계산으로 대체
    (maxSeig, stakedSeig, unstakedSeig, powertonSeig, daoSeig, relativeSeig) =
        _calculateBaseDistribution();

    uint256 totalX = calculateTotalEffectiveBridgedTON();
    uint256 l2MaxAllocation = _calculateL2MaxAllocation(maxSeig, stakedSeig, unstakedSeig);
    l2TotalSeigs = hyperbolicSaturation(totalX, l2MaxAllocation);
    layer2Seigs = calculateL2Seigniorage(layer2, l2TotalSeigs, totalX);
}
```

---

## 4. 테스트 체크리스트

### 4.1 단위 테스트

- [ ] `checkEligibility()`: S_i ≥ θ·B_i 조건 검증
- [ ] `getEffectiveBridgedTON()`: 자격 없으면 0 반환
- [ ] `getTotalEffectiveBridgedTON()`: 전체 합계 정확성
- [ ] `hyperbolicSaturation()`: y(k) = L/2 확인, 단조 증가, 상한 L
- [ ] `calculateL2Seigniorage()`: 비례 분배 정확성
- [ ] `onBridgedTONChange()`: Bridged TON 변경 시 캐시 갱신

### 4.2 전환 메커니즘 테스트

- [ ] v3Migrated = false (V2 모드): V1_3 _increaseTot() 로직 동작 확인
- [ ] v3Migrated = false: stakedSeig = A × prevTotalSupply / tos 확인
- [ ] v3Migrated = false: Coinage factor 업데이트 확인
- [ ] v3Migrated = true (V3 모드): 스테이커 시뇨리지 0%, A₂ = A 확인

### 4.3 통합 테스트

- [ ] V2 → V3 마이그레이션 시나리오
- [ ] updateSeigniorageV3() 전체 플로우
- [ ] ValidatorReward 보상 분배 (distributeL2Rewards, claimAllRewards)
- [ ] 자격 상실 시 시뇨리지 재분배
- [ ] Layer2Manager → SeigManager 콜백 테스트
- [ ] L1Bridge → SeigManager 콜백 테스트

### 4.4 경계 조건 테스트

- [ ] x = 0 일 때 y(x) = 0
- [ ] 단일 L2만 자격 있을 때
- [ ] 모든 L2가 자격 없을 때
- [ ] 검증자가 0명일 때 (|V_i| = 0 → DAO Treasury)
- [ ] v3Migrated = true 일 때 A₂ = A 확인

---

## 5. 배포 파라미터 (권장값)

```solidity
// V3 핵심 파라미터 (RAY 단위: 1e27)
daoDistributionRatio = 0.2e27;        // d = 20%
minStakingRatio = 0.1e27;             // θ = 10%
validatorDistributionRatio = 0.2e27; // α = 20%
halfSaturationPoint = 10_000_000e27; // k = 1000만 TON

// 전환 제어 (초기값: V2 모드)
v3Migrated = false;                   // 초기: V2 모드
relativeSeigRate = 0.4e27;            // r = 40% (V2 모드에서만 사용)

// 검증자 풀 파라미터
minimumValidatorDeposit = 10_000e27; // 최소 1만 WTON
ratProbability = 0.01e27;            // π_a = 1%
ratResponseWindow = 1 hours;
```

---

## 6. V3 전환 일정 예시

| 단계 | 시기 | v3Migrated | 비고 |
|------|------|------------|------|
| Phase 0 | 배포 시 | false | V2 모드 (V1_3 로직) |
| Phase 1 | 전환 준비 | false | 검증자 등록, 스테이커 공지 |
| Phase 2 | 전환 실행 | true | `migrateToV3()` 호출, V3 모드 활성화 |

**전환 효과:**
- V2 → V3: 스테이커 시뇨리지 즉시 중단
- A₂ = A: 전체 시뇨리지가 V3 공식대로 분배

---

## 7. 신규/변경 컨트랙트 요약

| 컨트랙트 | 변경 유형 | 주요 변경 내용 |
|----------|----------|--------------|
| **SeigManagerV1_4** | 업그레이드 | Bridged TON 기반 분배, 쌍곡선 함수, 자격 조건, 점진적 전환 |
| **SeigManagerV1_4Storage** | 신규 | V3 파라미터 스토리지, 전환 파라미터 |
| **Layer2ManagerV1_2** | 업그레이드 | Bridged TON 조회/업데이트, 자격 확인 |
| **L1BridgeRegistryV1_2** | 업그레이드 | Bridged TON 조회 함수 추가 |
| **DepositManagerV1_2** | 업그레이드 | 구조화된 출금 요청 및 일괄 처리 지원 |
| **RAT** | 신규 | 검증자 등록/담보금/슬래싱 |
| **RATStorage** | 신규 | RAT 스토리지 |
| **ValidatorRewardV1** | 신규 | 검증자 보상 분배 (Per-L2 추적) |
| **ValidatorRewardStorage** | 신규 | ValidatorReward 스토리지 |

---

## 8. 참고 자료

- **Tokamak Economics Whitepaper V2** (December 9, 2025)
- **TON Staking V2 문서**: `/Users/zena/tonv2/ton-staking-v2/docs/kr/ton-staking-v2.md`
- **V2 코드베이스**: `/Users/zena/tonv2/ton-staking-v2/contracts/`
