# TON Staking V3 스마트 컨트랙트 구현 명세서

> **참고 문서**: [Tokamak_Economics_Whitepaper.pdf](../Tokamak_Economics_Whitepaper.pdf)

## 개요

이 문서는 **Tokamak Economics Whitepaper V2**를 기반으로, **기존 TON Staking V2 컨트랙트를 업그레이드**하여 V3 시스템을 구현하기 위한 명세서입니다.

### V3의 핵심 변경사항

| 구분 | V2 | V3 |일부
|------|-----|-----|
| **시뇨리지 분배 기준** | L2 TVL (단순 비례) | Bridged TON (성과 기반) |
| **분배 함수** | 선형 분배 | 쌍곡선 포화 함수 y(x) = L·(x/(k+x)) |
| **자격 조건** | 최소 예치금만 | S_i ≥ θ·B_i (스테이킹 비율 강제) |
| **검증자 보상** | 없음 | α_v·y(x) / n (RAT 기반) |
| **DAO 할당** | 고정 비율 | 고정 비율 + 미분배분 |

---

## 문서 구조

본 명세서는 다음과 같이 분리되어 있습니다:

| 문서 | 내용 |
|------|------|
| **[01_v2_architecture.md](./01_v2_architecture.md)** | V2 아키텍처 분석, Coinage/RewardPerUint 메커니즘, 스토리지 구조 |
| **[02_v3_distribution.md](./02_v3_distribution.md)** | V3 분배 공식, V2→V3 점진적 전환 메커니즘, 쌍곡선 함수 |
| **[03_sequencer_slashing.md](./03_sequencer_slashing.md)** | 시퀀서 슬래싱, 챌린저 보상, 반복 위반 페널티 |
| **[04_validator.md](./04_validator.md)** | 검증자 등록/탈퇴, 담보금, RAT 시스템, 검증자 보상 |
| **[05_validator_slashing.md](./05_validator_slashing.md)** | 검증자 슬래싱, RAT 미응답 처리, 선차감-복구 메커니즘 |
| **[06_bridged_ton_tracking.md](./06_bridged_ton_tracking.md)** | Bridged TON 추적 시스템, 콜백 인터페이스 |
| **[07_rat_implementation.md](./07_rat_implementation.md)** | RAT 구현체 설계 (Optimism 참고), IRAT/RATStorage/RAT.sol |
| **[08_implementation.md](./08_implementation.md)** | SeigManagerV1_4, ValidatorPoolV1, Layer2ManagerV1_2 구현 코드 |
| **[09_migration.md](./09_migration.md)** | 마이그레이션 가이드, 테스트 체크리스트, 배포 파라미터 |
| **[10_governance_parameters.md](./10_governance_parameters.md)** | 거버넌스 결정 파라미터 통합, 조정 가이드, 미결정 항목 |

---

## 핵심 수식 요약

### 변수 정의

| 변수 | 설명 |
|------|------|
| **A** | 전체 기간 시뇨리지 (발행될 총량) |
| **A₁** | 스테이커 지분 시뇨리지(S_staked)를 분배한 후 남은 양 |
| **A₂** | 스테이커 추가 시뇨리지(S_relative)까지 분배한 후 남은 양 → V3 분배 재원 |
| **S** | 총 스테이킹 금액 (WTON 총 공급량) |
| **T** | TON 총 발행량 |
| **λ** | 지분 시뇨리지 비율 (stakedSeigFactor, 1→0으로 감소) |
| **r** | 추가 시뇨리지 비율 (relativeSeigRate, 1→0으로 먼저 감소) |

### V2→V3 점진적 전환 공식

```
S_staked   = λ · A · (S / T)
A₁         = A - S_staked
           = A · (1 - λ · S/T)

S_relative = A₁ · r
A₂         = A₁ - S_relative
           = A₁ · (1 - r)
           = A · (1 - λ · S/T) · (1 - r)

V3 완전 전환 시 (λ = 0, r = 0):
A₂ = A · (1 - 0) · (1 - 0) = A
→ 전체 시뇨리지가 백서 V3 공식대로 분배됨
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
| (13) | `o_i = (1-α_v)·Seig_i`, `v_i = (α_v/n)·y(x)` | 시퀀서/검증자 분배 |

---

## 컨트랙트 구조

### 업그레이드 대상

```
contracts/
├── stake/
│   ├── managers/
│   │   ├── SeigManagerV1_3.sol       → SeigManagerV1_4.sol (업그레이드)
│   │   ├── DepositManagerV1_2.sol    → DepositManagerV1_3.sol (업그레이드)
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
uint256 public validatorDistributionRatio; // α_v: 검증자 분배 비율 (0.2e27 = 20%)
uint256 public halfSaturationPoint;       // k: 반포화점 (10_000_000e27 TON)
uint256 public stakedSeigFactor;          // λ: 지분 시뇨리지 비율 (전환용)
```

---

## 참고 자료

- **Tokamak Economics Whitepaper V2** (December 3, 2025)
- **TON Staking V2 문서**: `tokamak-network/ton-staking-v2/docs/kr/ton-staking-v2.md`
- **V2 코드베이스**: `tokamak-network/ton-staking-v2/contracts/`
