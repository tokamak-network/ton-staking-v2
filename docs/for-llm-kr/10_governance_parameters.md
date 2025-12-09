# 거버넌스 결정 파라미터 통합

## 1. 개요

이 문서는 TON Staking V3 시스템에서 **거버넌스가 결정해야 하는 모든 파라미터**를 통합 정리합니다. 각 파라미터는 프로토콜 운영에 중요한 영향을 미치며, DAO 거버넌스를 통해 조정됩니다.

---

## 2. 파라미터 전체 목록

### 2.1 V3 시뇨리지 분배 파라미터

| 파라미터 | 기호 | 설명 | 권장값 | 단위 |
|---------|------|------|--------|------|
| **daoDistributionRatio** | d | DAO 고정 분배 비율 | 0.2e27 (20%) | RAY |
| **minStakingRatio** | θ | 최소 스테이킹 비율 (자격 조건) | 0.1e27 (10%) | RAY |
| **validatorDistributionRatio** | α_v | 검증자 분배 비율 | 0.2e27 (20%) | RAY |
| **halfSaturationPoint** | k | 쌍곡선 반포화점 | 10,000,000e27 | RAY (TON) |

**관련 공식:**
- 백서 (7): `S_DAO = d · A₂`
- 백서 (8): `S_i ≥ θ · B_i`
- 백서 (11): `y(k) = L/2`
- 백서 (13): `v_i = (α_v/n) · y(x)`

---

### 2.2 V2→V3 전환 파라미터

| 파라미터 | 기호 | 설명 | 초기값 | V3 완전 전환 시 |
|---------|------|------|--------|----------------|
| **stakedSeigFactor** | λ | 지분 시뇨리지 비율 | 1e27 (100%) | 0 |
| **relativeSeigRate** | r | 추가 시뇨리지 비율 | 0.4e27 (40%) | 0 |

**전환 원칙:**
- r (추가 시뇨리지)를 먼저 0으로 감소
- λ (지분 시뇨리지)는 나중에 감소
- 완전 전환 시 A₂ = A (전체 시뇨리지가 V3 공식으로 분배)

---

### 2.3 슬래싱 파라미터

| 파라미터 | 기호 | 설명 | 권장값 | 비고 |
|---------|------|------|--------|------|
| **maxChallengers** | H_max | 최대 동시 챌린저 수 | 10 | 프로토콜 레벨 |
| **maxFraudProofCost** | C_max | 단일 fraud proof 최대 온체인 비용 | 10e27 (10 TON) | RAY 단위 |
| **penaltyFactor** | γ | 반복 위반 페널티 팩터 | TBD (γ > 1) | - |
| **slashingWindow** | - | 슬래싱 윈도우 기간 | TBD | 초(seconds) |
| **minimumInitialDepositAmount** | - | V2 최소 담보금 (하위 호환) | 1000.1e27 | RAY 단위 |

**관련 공식:**
- 백서 (1): `D_sequencer = H_max · C_max + Δ_sequencer`
- 백서 (2): `R_challenger = C_max + (Δ_sequencer / n)`
- 백서 (3): `D^(n) = γ^(n-1) · D^(1)`

---

### 2.4 검증자 풀 파라미터

| 파라미터 | 설명 | 권장값 | 비고 |
|---------|------|--------|------|
| **minimumValidatorDeposit** | 최소 검증자 담보금 | 10,000e27 (1만 WTON) | RAY 단위 |
| **ratProbability** | RAT 발생 확률 (π_a) | 0.01e27 (1%) | RAY 단위 |
| **ratResponseWindow** | RAT 응답 윈도우 | 1 hours | 초(seconds) |

**관련 공식:**
- 백서 (5): `D_validator ≥ (c_m · N) / π_a`
- 백서 (6): `D_validator = (c_m · N) / π_a + Δ_validator`

---

## 3. 파라미터 분류

### 3.1 프로토콜 레벨 (전체 동일)

시스템 전체에 적용되는 파라미터:

```solidity
// 시뇨리지 분배
uint256 public daoDistributionRatio;       // d
uint256 public minStakingRatio;            // θ
uint256 public validatorDistributionRatio; // α_v
uint256 public halfSaturationPoint;        // k

// 전환
uint256 public stakedSeigFactor;           // λ
uint256 public relativeSeigRate;           // r

// 슬래싱
uint256 public maxChallengers;             // H_max
uint256 public maxFraudProofCost;          // C_max
uint256 public penaltyFactor;              // γ
uint256 public slashingWindow;

// 검증자
uint256 public minimumValidatorDeposit;
uint256 public ratProbability;             // π_a
uint256 public ratResponseWindow;
```

### 3.2 개별 설정 가능

시퀀서/검증자가 개별적으로 설정할 수 있는 파라미터:

```solidity
// 시퀀서별 추가 보상 (Δ_sequencer)
mapping(address => uint256) public sequencerAdditionalReward;

// 검증자별 추가 담보금 (Δ_validator)
// ValidatorInfo.depositAmount - minimumValidatorDeposit로 계산
```

---

## 4. 권장 초기 설정

### 4.1 배포 시 초기값

```solidity
// ========================================
// V3 시뇨리지 분배 (RAY 단위: 1e27)
// ========================================
daoDistributionRatio = 0.2e27;        // d = 20%
minStakingRatio = 0.1e27;             // θ = 10%
validatorDistributionRatio = 0.2e27; // α_v = 20%
halfSaturationPoint = 10_000_000e27; // k = 1000만 TON

// ========================================
// 전환 파라미터 (V2와 동일하게 시작)
// ========================================
stakedSeigFactor = 1e27;              // λ = 100%
relativeSeigRate = 0.4e27;            // r = 40%

// ========================================
// 슬래싱 파라미터
// ========================================
maxChallengers = 10;                   // H_max = 10명
maxFraudProofCost = 10e27;             // C_max = 10 TON
minimumInitialDepositAmount = 1000.1e27; // V2 기존값 유지
penaltyFactor = TBD;                   // γ: 거버넌스 결정 필요
slashingWindow = TBD;                  // 거버넌스 결정 필요

// ========================================
// 검증자 풀 파라미터
// ========================================
minimumValidatorDeposit = 10_000e27;  // 최소 1만 WTON
ratProbability = 0.01e27;             // π_a = 1%
ratResponseWindow = 1 hours;
```

---

## 5. 파라미터 조정 가이드

### 5.1 시뇨리지 분배 조정

| 파라미터 | 증가 시 효과 | 감소 시 효과 |
|---------|-------------|-------------|
| **d (DAO 비율)** | DAO 수익 증가, L2 인센티브 감소 | DAO 수익 감소, L2 인센티브 증가 |
| **θ (최소 스테이킹)** | 자격 조건 강화, 참여 L2 감소 | 자격 조건 완화, 참여 L2 증가 |
| **α_v (검증자 비율)** | 검증자 수익 증가, 시퀀서 수익 감소 | 검증자 수익 감소, 시퀀서 수익 증가 |
| **k (반포화점)** | 포화 속도 감소, 대형 L2 유리 | 포화 속도 증가, 소형 L2 유리 |

### 5.2 전환 파라미터 조정

거버넌스에서 λ, r 값을 조정할 때 고려해야 할 시장 지표:

| 지표 | 설명 | 전환 조건 예시 |
|------|------|----------------|
| **총 Bridged TON** | V3 분배 기준이 되는 값 | Bridged TON > 1억 TON 시 전환 가속 |
| **L2 활성도** | L2 트랜잭션 수, 사용자 수 | 활성 L2 수 > 10개 시 전환 가속 |
| **스테이킹 비율** | 전체 TON 중 스테이킹 비율 | 스테이킹 비율 안정화 시 전환 가속 |
| **스테이커 APY** | 스테이커의 연간 수익률 | APY가 목표 범위 내일 때 전환 진행 |
| **TON 가격 변동성** | 시장 안정성 지표 | 변동성 낮을 때 전환 가속 |

### 5.3 슬래싱 파라미터 조정

| 파라미터 | 증가 시 효과 | 감소 시 효과 |
|---------|-------------|-------------|
| **H_max** | 더 많은 챌린저 참여 가능 | 챌린저 참여 제한 |
| **C_max** | 챌린저 보상 증가, 시퀀서 담보금 증가 | 챌린저 보상 감소 |
| **γ (페널티 팩터)** | 반복 위반 억제력 강화 | 반복 위반 억제력 약화 |
| **slashingWindow** | 더 긴 기간 동안 위반 누적 | 더 짧은 기간 동안만 위반 누적 |

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

## 7. 미결정 파라미터 (TBD)

거버넌스에서 결정이 필요한 파라미터:

| 파라미터 | 설명 | 결정 시 고려사항 |
|---------|------|-----------------|
| **penaltyFactor (γ)** | 반복 위반 페널티 팩터 | 1.5~2.0 권장, 억제력과 공정성 균형 |
| **slashingWindow** | 슬래싱 윈도우 기간 | 1주~1개월 권장, 시퀀서 회복 기회 고려 |

---

## 8. 설정 함수 목록

### 8.1 SeigManagerV1_4

```solidity
function setDaoDistributionRatio(uint256 ratio) external onlyOwner;
function setMinStakingRatio(uint256 ratio) external onlyOwner;
function setValidatorDistributionRatio(uint256 ratio) external onlyOwner;
function setHalfSaturationPoint(uint256 k) external onlyOwner;
function setStakedSeigFactor(uint256 lambda) external onlyOwner;
function setRelativeSeigRate(uint256 rate) external onlyOwner;
function setValidatorPool(address pool) external onlyOwner;
```

### 8.2 슬래싱 컨트랙트

```solidity
function setMaxChallengers(uint256 hMax) external onlyOwner;
function setMaxFraudProofCost(uint256 cMax) external onlyOwner;
function setPenaltyFactor(uint256 gamma) external onlyOwner;
function setSlashingWindow(uint256 window) external onlyOwner;
function setMinimumInitialDepositAmount(uint256 amount) external onlyOwner;
```

### 8.3 ValidatorPoolV1

```solidity
function setMinimumValidatorDeposit(uint256 amount) external onlyOwner;
function setRatProbability(uint256 probability) external onlyOwner;
function setRatResponseWindow(uint256 window) external onlyOwner;
```

---

## 9. 참고 자료

- **Tokamak Economics Whitepaper V2**
- **[02_v3_distribution.md](./02_v3_distribution.md)**: V3 분배 공식 상세
- **[03_sequencer_slashing.md](./03_sequencer_slashing.md)**: 슬래싱 시스템 상세
- **[08_implementation.md](./08_implementation.md)**: 구현 코드
- **[09_migration.md](./09_migration.md)**: 마이그레이션 가이드
