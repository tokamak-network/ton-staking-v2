---
id: 09_migration
slug: /09_migration
---
# 마이그레이션 가이드

## 1. 업그레이드 순서

```
1. SeigManagerV1_4Storage 배포
2. SeigManagerV1_4 로직 배포
3. ValidatorPoolStorage 배포
4. ValidatorPoolV1 배포
5. Layer2ManagerV1_2 로직 배포
6. L1BridgeRegistryV1_2 로직 배포

7. 프록시 업그레이드:
   - ProxySeigManager.upgradeTo(SeigManagerV1_4)
   - ProxyLayer2Manager.upgradeTo(Layer2ManagerV1_2)
   - ProxyL1BridgeRegistry.upgradeTo(L1BridgeRegistryV1_2)

8. 초기 파라미터 설정:
   - setDaoDistributionRatio(0.2e27)     // d = 20%
   - setMinStakingRatio(0.1e27)          // θ = 10%
   - setValidatorDistributionRatio(0.2e27) // α = 20%
   - setHalfSaturationPoint(10_000_000e27) // k = 1000만 TON
   - setStakedSeigFactor(1e27)           // λ = 100% (초기: V2와 동일)

9. ValidatorPool 연결:
   - SeigManager.setValidatorPool(ValidatorPoolV1)
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
- [ ] `onStakingChange()`: 스테이킹 변경 시 유효성 재평가

### 4.2 전환 메커니즘 테스트

- [ ] λ = 1, r = 0.4 (V2 상태): 스테이커 시뇨리지 100%
- [ ] λ = 1, r = 0: 추가 시뇨리지 없음
- [ ] λ = 0.5, r = 0: 지분 시뇨리지 50%
- [ ] λ = 0, r = 0 (V3 상태): 스테이커 시뇨리지 0%, A₂ = A

### 4.3 통합 테스트

- [ ] V2 → V3 마이그레이션 시나리오
- [ ] updateSeigniorageV3() 전체 플로우
- [ ] ValidatorPool 보상 분배
- [ ] 자격 상실 시 시뇨리지 재분배
- [ ] DepositManager → SeigManager 콜백 테스트
- [ ] L1Bridge → SeigManager 콜백 테스트

### 4.4 경계 조건 테스트

- [ ] x = 0 일 때 y(x) = 0
- [ ] 단일 L2만 자격 있을 때
- [ ] 모든 L2가 자격 없을 때
- [ ] 검증자가 0명일 때
- [ ] λ = 0, r = 0 일 때 A₂ = A 확인

---

## 5. 배포 파라미터 (권장값)

```solidity
// V3 핵심 파라미터 (RAY 단위: 1e27)
daoDistributionRatio = 0.2e27;        // d = 20%
minStakingRatio = 0.1e27;             // θ = 10%
validatorDistributionRatio = 0.2e27; // α = 20%
halfSaturationPoint = 10_000_000e27; // k = 1000만 TON

// 전환 파라미터 (초기값)
stakedSeigFactor = 1e27;              // λ = 100% (V2와 동일)
relativeSeigRate = 0.4e27;            // r = 40% (V2 기존값 유지)

// 검증자 풀 파라미터
minimumValidatorDeposit = 10_000e27; // 최소 1만 WTON
ratProbability = 0.01e27;            // π_a = 1%
ratResponseWindow = 1 hours;
```

---

## 6. 점진적 전환 일정 예시

| 단계 | 시기 | λ | r | 비고 |
|------|------|---|---|------|
| Phase 0 | 배포 시 | 1.0 | 0.4 | V2와 동일 |
| Phase 1 | +1개월 | 1.0 | 0.2 | 추가 시뇨리지 50% 감소 |
| Phase 2 | +2개월 | 1.0 | 0.0 | 추가 시뇨리지 완전 제거 |
| Phase 3 | +3개월 | 0.7 | 0.0 | 지분 시뇨리지 30% 감소 |
| Phase 4 | +4개월 | 0.4 | 0.0 | 지분 시뇨리지 60% 감소 |
| Phase 5 | +5개월 | 0.0 | 0.0 | V3 완전 전환 |

---

## 7. 신규/변경 컨트랙트 요약

| 컨트랙트 | 변경 유형 | 주요 변경 내용 |
|----------|----------|--------------|
| **SeigManagerV1_4** | 업그레이드 | Bridged TON 기반 분배, 쌍곡선 함수, 자격 조건, 점진적 전환 |
| **SeigManagerV1_4Storage** | 신규 | V3 파라미터 스토리지, 전환 파라미터 |
| **Layer2ManagerV1_2** | 업그레이드 | Bridged TON 조회/업데이트, 자격 확인 |
| **L1BridgeRegistryV1_2** | 업그레이드 | Bridged TON 조회 함수 추가 |
| **DepositManagerV1_3** | 업그레이드 | onStakingChange 콜백 호출 |
| **ValidatorPoolV1** | 신규 | RAT 검증자 보상 관리 |
| **ValidatorPoolStorage** | 신규 | 검증자 데이터 스토리지 |

---

## 8. 참고 자료

- **Tokamak Economics Whitepaper V2** (December 9, 2025)
- **TON Staking V2 문서**: `/Users/zena/tonv2/ton-staking-v2/docs/kr/ton-staking-v2.md`
- **V2 코드베이스**: `/Users/zena/tonv2/ton-staking-v2/contracts/`
