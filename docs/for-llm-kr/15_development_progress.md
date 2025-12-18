# TON Staking V3 개발 진행사항

> 작성일: 2025-12-15
> 브랜치: `ton-staking-v3/dev`
> 기반: Tokamak Economics Whitepaper V2 (December 9, 2025)

---

## 1. 프로젝트 개요

TON Staking V3는 Tokamak Network의 차세대 스테이킹 스마트 컨트랙트입니다.

### 1.1 주요 기능

- **V3 시뇨리지 분배**: Bridged TON 기반 쌍곡선 포화 함수
- **검증자 시스템**: RAT (검증자 등록/슬래싱), ValidatorReward (보상 분배)
- **V2→V3 전환**: `v3Migrated` 플래그를 통한 즉시 전환
- **Optimism 연동**: FaultDisputeGame 기반 시퀀서 슬래싱

### 1.2 프로젝트 구조

```
src/
├── stake/              # 스테이킹 핵심 로직
│   ├── managers/       # SeigManager, DepositManager
│   └── tokens/         # Coinage 토큰
├── layer2/             # L2 관리 및 브릿지 연동
├── validator/          # V3 검증자 시스템
│   ├── RAT.sol                 # 검증자 등록/담보금/슬래싱
│   └── ValidatorRewardV1.sol   # 검증자 보상 분배
└── dao/                # DAO 관련 컨트랙트

lib/
├── optimism/           # tokamak-network/optimism (branch: feature/ton-staking-v3)
├── openzeppelin-contracts/
└── forge-std/
```

---

## 2. 테스트 현황

**전체 292개 테스트 통과 (100%)**

| 테스트 스위트 | 통과 | 실패 | 건너뜀 |
|-------------|------|------|--------|
| RATTest | 39 | 0 | 0 |
| Layer2ManagerV1_2RealTest | 31 | 0 | 0 |
| L1BridgeRegistryV1_2RealTest | 29 | 0 | 0 |
| DepositManagerV1_2RealTest | 27 | 0 | 0 |
| DepositManagerV1_2Test | 24 | 0 | 0 |
| ValidatorRewardV1Test | 21 | 0 | 0 |
| SeigManagerV1_4Test | 21 | 0 | 0 |
| SeigManagerV1_4RealTest | 21 | 0 | 0 |
| EndToEndSeigniorageTest | 13 | 0 | 0 |
| L1BridgeRegistryV1_2Test | 13 | 0 | 0 |
| SequencerSlashingTest | 12 | 0 | 0 |
| SeigniorageDistributionTest | 11 | 0 | 0 |
| SlashSequencerByGameTest | 9 | 0 | 0 |
| DeployV3ForkTest | 6 | 0 | 0 |
| E2ELocalSimulationTest | 6 | 0 | 0 |
| E2EMainnetForkLiveTest | 6 | 0 | 0 |
| E2EMainnetForkTest | 3 | 0 | 0 |
| **총계** | **292** | **0** | **0** |

---

## 3. 구현 완료된 핵심 컴포넌트

| 컴포넌트 | 파일 | 상태 | 설명 |
|---------|------|------|------|
| **RAT** | `src/validator/RAT.sol` | ✅ 완료 | 검증자 등록/담보금/슬래싱 |
| **ValidatorReward** | `src/validator/ValidatorRewardV1.sol` | ✅ 완료 | 검증자 보상 분배 (Per-L2 추적) |
| **SeigManager V1.4** | `src/stake/managers/SeigManagerV1_4.sol` | ✅ 완료 | V3 시뇨리지 분배 |
| **DepositManager V1.2** | `src/stake/managers/DepositManagerV1_2.sol` | ✅ 완료 | 검증자 담보금 관리 |
| **L1BridgeRegistry** | `src/layer2/L1BridgeRegistryV1_2.sol` | ✅ 완료 | Bridged TON 추적 |
| **Layer2Manager V1.2** | `src/layer2/Layer2ManagerV1_2.sol` | ✅ 완료 | L2 관리 |
| **Sequencer Slashing** | `SeigManagerV1_4.sol` | ✅ 완료 | Permissionless 슬래싱 |

---

## 4. Optimism 연동 현황

### 4.1 연동 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                      TON Staking V3                              │
├─────────────────┬─────────────────┬─────────────────────────────┤
│  RAT.sol        │ SeigManager     │ L1BridgeRegistry            │
│  (검증자 관리)   │ (시퀀서 슬래싱)  │ (Bridged TON 추적)           │
└────────┬────────┴────────┬────────┴────────────┬────────────────┘
         │                 │                      │
         ▼                 ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Optimism (lib/optimism)                    │
├─────────────────┬─────────────────┬─────────────────────────────┤
│DisputeGameFactory│FaultDisputeGame │ SystemConfig / OptimismPortal│
│ (RAT 트리거)     │ (resolveClaim)  │ (L2 식별자)                   │
└─────────────────┴─────────────────┴─────────────────────────────┘
```

### 4.2 RAT (Randomized Attention Test) 연동 - 완료

| 기능 | 상태 | 테스트 |
|-----|------|--------|
| `triggerAttentionTest(systemConfig, batchIndex, ...)` | ✅ | 39/39 통과 |
| `resolveClaim(claimant)` - 게임에서 systemConfig 조회 후 담보금 복구 | ✅ | 통과 |
| `activeTestByValidator[systemConfig][validator]` 매핑 | ✅ | 통과 |
| 검증자 등록/탈퇴/재등록 | ✅ | 통과 |
| 증거 제출 및 슬래싱 | ✅ | 통과 |
| 검증자 보상 분배 | ✅ | 통과 |

**핵심 인터페이스** (`src/validator/IRAT.sol`):
```solidity
// DisputeGameFactory에서 호출 (게임 생성 시)
function triggerAttentionTest(
    address systemConfig,     // L2 식별자
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external;

// FaultDisputeGame에서 호출 (챌린저 승리 시)
// msg.sender(게임)의 systemConfig()를 조회하여 테스트 찾기
function resolveClaim(address _claimant) external;
```

### 4.3 Permissionless 시퀀서 슬래싱 - 완료

| 기능 | 상태 | 테스트 |
|-----|------|--------|
| `slashSequencerByGame(gameAddress, challengers)` | ✅ | 9/9 통과 |
| 게임 상태 조회 (`status()`) | ✅ | 통과 |
| SystemConfig → Layer2 조회 | ✅ | 통과 |
| 챌린저 보상 분배 | ✅ | 통과 |

**핵심 코드** (`src/stake/managers/SeigManagerV1_4.sol:558-592`):
```solidity
function slashSequencerByGame(
    address gameAddress,
    address[] calldata challengers
) external onlyMigrated {
    // FaultDisputeGame에서 status() 직접 조회
    // CHALLENGER_WINS 확인 후 슬래싱 실행
}
```

### 4.4 Bridged TON 추적 - 완료

| 기능 | 상태 | 테스트 |
|-----|------|--------|
| L1BridgeRegistry TVL 추적 | ✅ | 29/29 통과 |
| Legacy (L1StandardBridge) 지원 | ✅ | 통과 |
| Bedrock (OptimismPortal) 지원 | ✅ | 통과 |
| `onBridgedTONChange` 콜백 | ✅ | 통과 |

### 4.5 Optimism 서브모듈 현황

```
lib/optimism/
├── Repository: tokamak-network/optimism
├── Branch: feature/ton-staking-v3
├── RAT 연동 코드:
│   ├── interfaces/L1/IRAT.sol - RAT 인터페이스 정의
│   ├── src/dispute/DisputeGameFactory.sol - triggerAttentionTest 호출
│   └── src/dispute/FaultDisputeGame.sol - resolveClaimRat 콜백
├── 주요 인터페이스:
│   ├── IFaultDisputeGame - 게임 상태 조회
│   ├── ISystemConfig - L2 식별
│   └── IOptimismPortal2 - Bedrock 브릿지
```

### 4.6 Optimism 측 RAT 연동 구현 현황

| 컴포넌트 | 수정 내용 | 상태 |
|---------|---------|------|
| **IRAT 인터페이스** | `triggerAttentionTest`, `resolveClaim` 정의 | ✅ 구현 완료 |
| **DisputeGameFactory** | `IRAT.triggerAttentionTest()` 호출 | ✅ 구현 완료 |
| **FaultDisputeGame** | `resolveClaimRat()` 콜백 | ✅ 구현 완료 |
| **L1StandardBridge** | `onBridgedTONChange()` 호출 (선택) | 📋 설계 완료 |

**DisputeGameFactory.sol** (라인 203-211):
```solidity
// Trigger RAT attention test if RAT contract is set and game type is CANNON
// gameAddress는 파라미터로 전달하지 않음 - RAT가 msg.sender로 추적
if (rat != address(0) && _gameType.raw() == GameTypes.CANNON.raw()) {
    try IRAT(rat).triggerAttentionTest(
        systemConfig,                           // L2 식별자
        uint32(_disputeGameList.length - 1),    // batchIndex
        Claim.unwrap(_rootClaim),               // batchHash
        parentHash                              // blockHash (랜덤 시드)
    ) { } catch { }
}
```

**FaultDisputeGame.sol** (라인 943-946):
```solidity
function resolveClaimRat(address claimant) internal {
    // RAT가 this.systemConfig()를 호출하여 L2 식별
    if (rat != address(0)) {
        try IRAT(rat).resolveClaim(claimant) { } catch { }
    }
}

// RAT.resolveClaim()에서 호출할 view 함수 필요
function systemConfig() external view returns (address);
```

> **참고**: `optimism_integration_guide.md`에 상세 구현 가이드 작성됨

### 4.7 연동 흐름

```
1. DisputeGame 생성 시:
   DisputeGameFactory.create()
   → IRAT.triggerAttentionTest(systemConfig, batchIndex, batchHash, blockHash)
   → RAT: 검증자 랜덤 선택, C_off 선차감
   → RAT: activeTestByValidator[systemConfig][validator] = testId 저장

2. 챌린저 승리 시:
   FaultDisputeGame.resolveClaim()
   → IRAT.resolveClaim(winner)
   → RAT: msg.sender.systemConfig() 조회하여 L2 식별
   → RAT: activeTestByValidator[systemConfig][winner]로 테스트 찾기
   → RAT: 담보금 복구 (winner가 선택된 검증자인 경우)

3. 시퀀서 슬래싱:
   누구나 SeigManager.slashSequencerByGame(gameAddr, challengers) 호출
   → SeigManager: game.status() == CHALLENGER_WINS 확인
   → 시퀀서 담보금 슬래싱, 챌린저 보상 분배
```

---

## 5. 최근 개발 활동

### 5.1 최근 커밋 히스토리

1. **RAT 인터페이스 Optimism 호환 수정** (2025-12-15)
   - `triggerAttentionTest`에서 `gameAddress` 파라미터 제거
   - `resolveClaim`이 게임의 `systemConfig()` 조회하여 테스트 찾기
   - `gameToTestId` → `activeTestByValidator[systemConfig][validator]` 매핑 변경
2. **RAT 테스트 & 검증자 재등록 로직** 추가
3. **Optimism 서브모듈** 통합 (`lib/optimism`)
4. **Permissionless 시퀀서 슬래싱** 구현
5. **V3 배포 인프라** 구축
6. **Docusaurus 문서 사이트** (한/영 지원)
7. **E2E 테스트 설계 문서** 작성

### 5.2 관련 브랜치

- `ton-staking-v3/dev` - 메인 개발 브랜치 (현재)
- `ton-staking-v3/dev-slashing-sequencer` - 시퀀서 슬래싱 개발
- `ton-staking-v3/dev-add-optimism-lib` - Optimism 라이브러리 추가

---

## 6. 미결정 사항 (TBD)

### 6.1 높은 우선순위

| 항목 | 설명 | 관련 문서 | 상태 |
|-----|------|---------|------|
| ~~검증자 보상 분배 방식~~ | ~~해석 1 (균등) vs 해석 2 (L2별)~~ | `12_tbd_items.md` §2.1 | ✅ V3 해결 |
| 검증자 파라미터 값 | `c_m`, `C_off`, `D_min` 결정 | `12_tbd_items.md` §2.4 | 미해결 |
| ~~검증자 담보금 시뇨리지 정책~~ | ~~V3: 담보금 시뇨리지 없음~~ | `12_tbd_items.md` §3.2 | ✅ V3 해결 |
| 검증자 담보금 원금 추적 | 정수 나눗셈 손실로 원금 반환 보장 필요 | `12_tbd_items.md` §3.3 | ⚠️ 구현 필요 |

### 6.2 중간 우선순위

| 항목 | 설명 | 관련 문서 | 상태 |
|-----|------|---------|------|
| 몰수된 담보금 귀속처 | DAO/소각/분배 중 선택 | `12_tbd_items.md` §2.3 | 미해결 |
| RAT 증거 형식 | Optimism 방식 채택 여부 | `12_tbd_items.md` §3.1 | 미해결 |
| 검증자 출금 시 가스비 정책 | 부담 주체 결정 | `12_tbd_items.md` §3.4 | 미해결 |

### 6.3 낮은 우선순위

| 항목 | 설명 | 관련 문서 |
|-----|------|---------|
| 시퀀서 슬래싱 시 L2 운영 정지 여부 | 현재 설계로 동작 가능 | `12_tbd_items.md` §2.2 |

---

## 7. 다음 단계

### 7.1 TON V3 측

- [ ] TBD 항목 결정 (높은 우선순위)
- [ ] 실제 메인넷 파라미터 값 결정
- [ ] 감사(Audit) 준비

### 7.2 Optimism 측

- [x] DisputeGameFactory에 RAT 트리거 추가 (lib/optimism에 구현됨)
- [x] FaultDisputeGame에 resolveClaim 콜백 추가 (lib/optimism에 구현됨)
- [ ] FaultDisputeGame에 `systemConfig()` view 함수 추가 필요
- [ ] 통합 테스트

### 7.3 통합

- [ ] 테스트넷 E2E 테스트
- [ ] 메인넷 배포 준비

---

## 8. 참고 문서

- [01_v2_architecture.md](./01_v2_architecture.md) - V2 아키텍처
- [02_v3_distribution.md](./02_v3_distribution.md) - V3 시뇨리지 분배
- [03_sequencer_slashing.md](./03_sequencer_slashing.md) - 시퀀서 슬래싱
- [04_validator.md](./04_validator.md) - 검증자 시스템
- [07_rat_implementation.md](./07_rat_implementation.md) - RAT 구현
- [12_tbd_items.md](./12_tbd_items.md) - 미결정 사항
- [optimism_integration_guide.md](./optimism_integration_guide.md) - Optimism 연동 가이드
