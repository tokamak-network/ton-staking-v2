# TON Staking V3 스마트 컨트랙트 구현 명세서

> **참고 문서**: [Tokamak_Economics_Whitepape_V2_(121025).pdf](../Tokamak_Economics_Whitepape_V2_(121025).pdf) (December 9, 2025)

## 개요

이 문서는 **Tokamak Economics Whitepaper V2**를 기반으로, **기존 TON Staking V2 컨트랙트를 업그레이드**하여 V3 시스템을 구현하기 위한 명세서입니다.

### V3의 핵심 변경사항

| 구분 | V2 | V3 |
|------|-----|-----|
| **시뇨리지 분배 기준** | L2 TVL (단순 비례) | Bridged TON (성과 기반) |
| **분배 함수** | 선형 분배 | 쌍곡선 포화 함수 y(x) = L·(x/(k+x)) |
| **자격 조건** | 최소 예치금만 | S_i ≥ θ·B_i (스테이킹 비율 강제) |
| **검증자 보상** | 없음 | α·y(x) / n (RAT 기반) |
| **DAO 할당** | 고정 비율 | 고정 비율 + 미분배분 |

---

## 문서 구조

본 명세서는 다음과 같이 분리되어 있습니다:

| 문서 | 내용 |
|------|------|
| **[01_v2_architecture.md](./01_v2_architecture.md)** | V2 아키텍처 분석, Coinage/RewardPerUint 메커니즘, 스토리지 구조 |
| **[02_v3_distribution.md](./02_v3_distribution.md)** | V3 분배 공식, V2→V3 점진적 전환 메커니즘, 쌍곡선 함수 |
| **[03_sequencer_slashing.md](./03_sequencer_slashing.md)** | 시퀀서 슬래싱, 챌린저 보상 |
| **[04_validator.md](./04_validator.md)** | 검증자 등록/탈퇴, 담보금, RAT 시스템, 검증자 보상 |
| **[05_validator_slashing.md](./05_validator_slashing.md)** | 검증자 슬래싱, RAT 미응답 처리, 선차감-복구 메커니즘 |
| **[06_bridged_ton_tracking.md](./06_bridged_ton_tracking.md)** | Bridged TON 추적 시스템, 콜백 인터페이스 |
| **[07_rat_implementation.md](./07_rat_implementation.md)** | RAT 구현체 설계, IRAT/RATStorage/RAT.sol |
| **[08_implementation.md](./08_implementation.md)** | SeigManagerV1_4, ValidatorPoolV1, Layer2ManagerV1_2 구현 코드 |
| **[09_migration.md](./09_migration.md)** | 마이그레이션 가이드, 테스트 체크리스트, 배포 파라미터 |
| **[10_governance_parameters.md](./10_governance_parameters.md)** | 거버넌스 결정 파라미터 통합, 조정 가이드, 미결정 항목 |
| **[11_whitepaper_v2_changes.md](./11_whitepaper_v2_changes.md)** | 백서 V2 변경사항 추적, 문서 수정 이력 |
| **[12_tbd_items.md](./12_tbd_items.md)** | 미결정 항목 (TBD), 설계 결정 필요 사항 |
| **[13_external_interfaces.md](./13_external_interfaces.md)** | 외부 인터페이스, 호출 주체/시점, 이벤트 |

---

## 핵심 수식 요약

### 변수 정의

| 변수 | 설명 |
|------|------|
| **A** | 전체 기간 시뇨리지 (발행될 총량) |
| **A₂** | V3 분배 재원 (v3Migrated = true일 때 A₂ = A) |
| **S** | 총 스테이킹 금액 (WTON 총 공급량) |
| **T** | TON 총 발행량 |
| **r** | 추가 시뇨리지 비율 (relativeSeigRate, V2 모드에서만 사용) |

### V2→V3 전환 방식

```
v3Migrated 플래그 기반 즉시 전환:

V2 모드 (v3Migrated = false):
- V1_3 _increaseTot() 로직 그대로 사용
- stakedSeig = A × prevTotalSupply / tos
- totalPseig = unstakedSeig × r
- Coinage factor 업데이트

V3 모드 (v3Migrated = true):
- A₂ = A (전체 시뇨리지가 V3 분배 재원)
- 스테이커 시뇨리지 = 0
- Coinage factor 변경 없음
- 백서 V3 공식대로 분배 (DAO + L2)
```

### 백서 핵심 공식

| 공식 번호 | 수식 | 설명 |
|----------|------|------|
| (7) | `S_DAO = d · A₂` | DAO 고정 분배 |
| (8) | `S_i ≥ θ · B_i` | L2 자격 조건 |
| (9) | `1_i = {1 if eligible, 0 otherwise}` | 자격 지시 함수 |
| (10) | `x = Σ B̃_i` | 전체 유효 Bridged TON |
| (11) | `y(x) = L · (x/(k+x))` | 쌍곡선 포화 함수 |
| (12) | `Seig_i = y(x) · (B̃_i/x)` | L2별 시뇨리지 |
| (13) | `o_i = (1-α)·Seig_i`, `v_i = (α/n)·y(x)` | 시퀀서/검증자 분배 |

---

## 컨트랙트 구조

### 업그레이드 대상

```
contracts/
├── stake/
│   ├── managers/
│   │   ├── SeigManagerV1_3.sol       → SeigManagerV1_4.sol (업그레이드)
│   │   ├── DepositManagerV1_1.sol    → DepositManagerV1_2.sol (업그레이드)
│   │   └── SeigManagerV1_4Storage.sol (신규)
├── layer2/
│   ├── Layer2ManagerV1_1.sol         → Layer2ManagerV1_2.sol (업그레이드)
│   └── L1BridgeRegistryV1_1.sol      → L1BridgeRegistryV1_2.sol (업그레이드)
└── [V3 신규]
    └── validator/
        ├── RAT.sol                   (신규) - Optimism 참고
        ├── RATStorage.sol            (신규)
        └── interfaces/
            └── IRAT.sol              (신규)
```

### V3 핵심 파라미터

```solidity
// 백서 기반 파라미터 (RAY 단위: 1e27)
uint256 public daoDistributionRatio;      // d: DAO 고정 비율 (0.2e27 = 20%)
uint256 public minStakingRatio;           // θ: 최소 스테이킹 비율 (0.1e27 = 10%)
uint256 public validatorDistributionRatio; // α: 검증자 분배 비율 (0.2e27 = 20%)
uint256 public halfSaturationPoint;       // k: 반포화점 (10_000_000e27 TON)

// 전환 제어
bool public v3Migrated;                   // V3 모드 활성화 플래그
```

---

## 참고 자료

- **Tokamak Economics Whitepaper V2** (December 9, 2025)
- **TON Staking V2 문서**: `tokamak-network/ton-staking-v2/docs/kr/ton-staking-v2.md`
- **V2 코드베이스**: `tokamak-network/ton-staking-v2/contracts/`
