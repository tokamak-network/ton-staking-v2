# 시퀀서 슬래싱

## 1. 개요

Tokamak Network V3에서 시퀀서의 부정 행위(fraud)를 억제하기 위한 슬래싱 시스템입니다. Multi-Challenger Fraud Proof 방식을 채택하여 모든 유효한 챌린저에게 보상을 제공합니다.

---

## 2. Multi-Challenger Fraud Proof

백서에 따르면, 단일 승자 챌린지 시스템에서는 악의적인 L1 proposer/builder가 트랜잭션 순서를 조작하면 정직한 챌린저가 배제될 수 있습니다. Tokamak Network는 **다중 승자 방식**을 채택하여, 분쟁 기간 내에 제출된 모든 유효한 fraud proof가 인정되고 보상받습니다.

---

## 3. 시퀀서 담보금

### 3.1 담보금 공식

백서 공식 (1)에 따른 시퀀서 담보금:

```
D_sequencer = H_max · C_max + Δ_sequencer
```

| 파라미터 | 설명 | 범위 |
|---------|------|------|
| **H_max** | 최대 동시 챌린저 수 | 프로토콜 레벨 (전체 동일) |
| **C_max** | 단일 fraud proof 실행의 최대 온체인 비용 | 프로토콜 레벨 (전체 동일) |
| **Δ_sequencer** | 시퀀서가 제공하는 추가 보상 | 시퀀서별 설정 가능 |

V3에서는 백서 공식과 기존 V2 최소 담보금 중 **큰 값**을 최소 담보금으로 사용합니다.

```solidity
/// @notice 백서 공식 (1): D_sequencer = H_max · C_max + Δ_sequencer
function calculateSequencerDepositByFormula(uint256 additionalReward)
    public view
    returns (uint256)
{
    return (maxChallengers * maxFraudProofCost) + additionalReward;
}

/// @notice V3 최소 담보금 계산
/// @dev max(백서 공식, V2 최소 담보금)
/// @param additionalReward Δ_sequencer: 시퀀서가 설정한 추가 보상
function getMinimumSequencerDeposit(uint256 additionalReward)
    public view
    returns (uint256)
{
    uint256 formulaDeposit = calculateSequencerDepositByFormula(additionalReward);

    // V2 최소 담보금과 백서 공식 중 큰 값 사용
    return formulaDeposit > minimumInitialDepositAmount
        ? formulaDeposit
        : minimumInitialDepositAmount;
}
```

### 3.2 담보금 = L2 스테이킹 금액

시퀀서의 담보금은 **별도로 저장되지 않고**, 해당 L2에 스테이킹된 금액(S_i)을 조회하여 사용합니다. 이는 V2의 기존 구조를 그대로 활용합니다.

```solidity
/// @notice 시퀀서 담보금 조회 (= 해당 L2의 스테이킹 금액)
/// @dev SeigManager.stakedOf()를 통해 조회
/// @param layer2 L2 주소 (candidate)
function getSequencerDeposit(address layer2) public view returns (uint256) {
    // 해당 L2의 시퀀서(오퍼레이터)의 스테이킹 잔액 조회
    address sequencer = ILayer2Manager(layer2Manager).getOperator(layer2);
    return ISeigManager(seigManager).stakedOf(layer2, sequencer);
}
```

### 3.3 스토리지

```solidity
// ============================================
// 프로토콜 레벨 파라미터 (전체 동일)
// ============================================

/// @notice H_max: 최대 동시 챌린저 수
/// @dev 프로토콜에서 정의, 거버넌스로 변경 가능
uint256 public maxChallengers;

/// @notice C_max: 단일 fraud proof 실행의 최대 온체인 비용
/// @dev 프로토콜에서 정의, 거버넌스로 변경 가능
uint256 public maxFraudProofCost;

/// @notice V2 최소 담보금 (기존, 하위 호환용)
uint256 public minimumInitialDepositAmount;  // 예: 1000.1 TON

// ============================================
// 시퀀서별 파라미터
// ============================================

/// @notice 시퀀서별 추가 보상 (Δ_sequencer)
/// @dev 시퀀서가 개별적으로 설정, 기본값 0
mapping(address => uint256) public sequencerAdditionalReward;

// NOTE: 시퀀서 담보금은 별도 저장하지 않음
// → SeigManager.stakedOf(layer2, sequencer)로 조회
```

---

## 4. 슬래싱 메커니즘

### 4.1 슬래싱 조건

fraud proof가 성공하면 시퀀서의 **전체 담보금(D_sequencer)이 슬래싱**됩니다.

### 4.2 슬래싱 흐름

```
시퀀서 담보금 (D_sequencer) 전체 슬래싱
            │
            ▼
    ┌───────────────────────┐
    │  챌린저들에게 분배     │
    │  R = C_max + (Δ/n)    │
    │  × n명                │
    └───────────────────────┘
            │
            ▼
    ┌───────────────────────┐
    │  나머지 → DAO 재무    │
    └───────────────────────┘
            │
            ▼
    ┌───────────────────────┐
    │  L2 유효성 재평가     │
    │  onStakingChange()    │
    └───────────────────────┘
```

### 4.3 챌린저 보상 공식

백서 공식 (2)에 따른 챌린저 보상:

```
R_challenger = C_max + (Δ_sequencer / n)
```

| 파라미터 | 설명 |
|---------|------|
| **C_max** | fraud proof 비용 보전 (최소 보장) |
| **Δ_sequencer** | 시퀀서가 설정한 추가 보상 |
| **n** | 성공한 챌린저 수 |

### 4.4 슬래싱 예시

- `D_sequencer = 100 WTON` (H_max=5, C_max=10, Δ_sequencer=50)
- 챌린저 3명이 fraud proof 성공
- 각 챌린저 보상: `R = 10 + (50/3) = 26.67 WTON`
- 총 챌린저 보상: `26.67 × 3 = 80 WTON`
- DAO로 이전: `100 - 80 = 20 WTON`

챌린저는 최소 `C_max`(fraud proof 비용)를 보장받고, 추가로 `Δ_sequencer/n`의 이익을 얻습니다.

**중요**: 슬래싱된 금액은 스테이킹된 WTON이므로, 출금 대기 기간 없이 바로 transfer할 수 없습니다. 따라서 **챌린저의 스테이킹 잔액으로 이전**됩니다 (coinage 잔액 변경). 챌린저가 실제 WTON을 받으려면 일반 출금 절차를 거쳐야 합니다.

### 4.5 슬래싱과 L2 유효성

슬래싱이 발생하면 시퀀서의 담보금이 0이 되므로, 해당 L2의 스테이킹 조건 `S_i ≥ θ · B_i`를 충족하지 못하게 됩니다. 따라서 슬래싱 후 `onStakingChange()`를 호출하여 L2 유효성을 재평가해야 합니다.

- 슬래싱 전: `S_i = 100 WTON`, `B_i = 500 TON`, `θ = 0.1` → `100 ≥ 50` ✅ 유효
- 슬래싱 후: `S_i = 0 WTON` → `0 ≥ 50` ❌ 무효 → 시뇨리지 분배에서 제외

---

## 5. 슬래싱 구현

```solidity
/// @notice 시퀀서 슬래싱 (fraud proof 성공 시)
/// @dev 백서: "the entire bond (D_sequencer) is slashed"
/// @param layer2 슬래싱 대상 L2 주소
/// @param challengers 성공한 챌린저 목록
function slashSequencer(address layer2, address[] calldata challengers)
    external
    onlyDisputeContract
{
    uint256 n = challengers.length;
    require(n > 0 && n <= maxChallengers, "invalid challenger count");

    // 시퀀서(오퍼레이터) 주소 조회
    address sequencer = ILayer2Manager(layer2Manager).getOperator(layer2);

    // 담보금 = 해당 L2에 스테이킹된 시퀀서의 금액
    uint256 deposit = ISeigManager(seigManager).stakedOf(layer2, sequencer);
    require(deposit > 0, "no deposit to slash");

    uint256 additionalReward = sequencerAdditionalReward[layer2];

    // 챌린저 보상 계산: R_challenger = C_max + (Δ_sequencer / n)
    uint256 perChallengerReward = maxFraudProofCost + (additionalReward / n);

    // 각 챌린저에게 스테이킹 잔액으로 이전 (coinage 잔액 변경)
    // 출금 대기 기간 없이 바로 transfer할 수 없으므로 스테이킹 상태 유지
    for (uint256 i = 0; i < n; i++) {
        ISeigManager(seigManager).transferStake(
            layer2,
            sequencer,           // from: 시퀀서
            challengers[i],      // to: 챌린저
            perChallengerReward
        );
    }

    // 나머지는 DAO의 스테이킹 잔액으로 이전
    uint256 totalChallengerRewards = perChallengerReward * n;
    uint256 remainder = deposit - totalChallengerRewards;
    if (remainder > 0) {
        ISeigManager(seigManager).transferStake(
            layer2,
            sequencer,  // from: 시퀀서
            dao,        // to: DAO
            remainder
        );
    }

    // L2 유효성 재평가 (S_i = 0 이므로 S_i ≥ θ·B_i 불충족)
    // → 해당 L2는 시뇨리지 분배에서 제외됨
    ISeigManager(seigManager).onStakingChange(layer2);

    // 슬래싱 기록 저장 (반복 위반 페널티용)
    sequencerSlashTimestamps[layer2].push(block.timestamp);

    emit SequencerSlashed(layer2, sequencer, deposit, n);
}
```

### 5.1 SeigManager.transferStake 함수 (신규)

슬래싱 시 스테이킹 잔액을 이전하기 위한 함수:

```solidity
/// @notice 스테이킹 잔액 이전 (슬래싱 컨트랙트 전용)
/// @dev coinage 잔액을 from에서 to로 이전, 출금 없이 스테이킹 상태 유지
/// @param layer2 L2 주소
/// @param from 출발 계정 (슬래싱 대상)
/// @param to 도착 계정 (챌린저 또는 DAO)
/// @param amount 이전 금액
function transferStake(
    address layer2,
    address from,
    address to,
    uint256 amount
) external onlySlashingContract {
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    require(coinage.balanceOf(from) >= amount, "insufficient balance");

    // from의 잔액 차감, to의 잔액 증가
    coinage.burn(from, amount);
    coinage.mint(to, amount);

    emit StakeTransferred(layer2, from, to, amount);
}
```

---

## 6. 반복 위반 페널티

### 6.1 페널티 공식

백서 공식 (3)에 따르면, 시퀀서가 **슬래싱 윈도우(slashing window)** 내에 여러 번 fraud를 저지르면 필요 담보금이 증가합니다:

```
D_sequencer^(n) = γ^(n-1) · D_sequencer^(1)
```

| 파라미터 | 설명 |
|---------|------|
| **γ** | 페널티 팩터 (γ > 1, 거버넌스에서 결정) |
| **n** | 슬래싱 윈도우 내 위반 횟수 |
| **D^(1)** | 기본 담보금 |

**슬래싱 윈도우 동작 방식:**
- 슬래싱 윈도우는 **슬래싱이 발생한 시점부터** 시작됨
- 윈도우 내에 추가 슬래싱이 발생하면 위반 횟수(n)가 증가하고 필요 담보금이 γ배씩 증가
- 윈도우가 종료되면 (마지막 슬래싱 후 일정 기간 경과) 위반 횟수가 리셋됨
- 구체적인 윈도우 기간은 거버넌스에서 결정

### 6.2 페널티 스토리지

```solidity
/// @notice 페널티 팩터 (γ > 1)
/// @dev 거버넌스에서 결정
uint256 public penaltyFactor;

/// @notice 슬래싱 윈도우 (이 기간 내 반복 위반 시 페널티 증가)
/// @dev 구체적인 기간은 거버넌스에서 결정
uint256 public slashingWindow;

/// @notice L2별 슬래싱 기록 (layer2 => timestamps)
mapping(address => uint256[]) public sequencerSlashTimestamps;
```

### 6.3 페널티 계산 구현

```solidity
/// @notice 최근 위반 횟수 조회
/// @param layer2 L2 주소
function getRecentViolationCount(address layer2)
    public view
    returns (uint256 count)
{
    uint256[] storage timestamps = sequencerSlashTimestamps[layer2];
    uint256 windowStart = block.timestamp - slashingWindow;

    for (uint256 i = timestamps.length; i > 0; i--) {
        if (timestamps[i - 1] >= windowStart) {
            count++;
        } else {
            break;  // 시간순 정렬이므로 더 이상 확인 불필요
        }
    }
}

/// @notice 반복 위반 시 필요 담보금 계산
/// @dev 백서 공식 (3): D^(n) = γ^(n-1) · D^(1)
/// @param layer2 L2 주소
/// @param baseDeposit 기본 담보금
function getRequiredDepositWithPenalty(address layer2, uint256 baseDeposit)
    public view
    returns (uint256)
{
    uint256 violations = getRecentViolationCount(layer2);
    if (violations == 0) return baseDeposit;

    // γ^(n-1) · D^(1)
    uint256 multiplier = RAY;
    for (uint256 i = 0; i < violations; i++) {
        multiplier = FullMath.rmul(multiplier, penaltyFactor);
    }
    return FullMath.rmul(baseDeposit, multiplier);
}
```

### 6.4 페널티 예시

γ = 1.5, 기본 담보금 = 100 WTON인 경우:

| 위반 횟수 | 필요 담보금 | 계산 |
|----------|------------|------|
| 1회 | 100 WTON | 1.5^0 × 100 |
| 2회 | 150 WTON | 1.5^1 × 100 |
| 3회 | 225 WTON | 1.5^2 × 100 |
| 4회 | 337.5 WTON | 1.5^3 × 100 |

---

## 7. 이벤트

```solidity
/// @notice 시퀀서 슬래싱 이벤트
event SequencerSlashed(
    address indexed layer2,
    address indexed sequencer,
    uint256 slashedAmount,
    uint256 challengerCount
);

/// @notice 챌린저 보상 지급 이벤트
event ChallengerRewarded(
    address indexed challenger,
    address indexed layer2,
    uint256 reward
);

/// @notice 스테이킹 잔액 이전 이벤트
event StakeTransferred(
    address indexed layer2,
    address indexed from,
    address indexed to,
    uint256 amount
);

/// @notice 반복 위반 페널티 적용 이벤트
event PenaltyApplied(
    address indexed layer2,
    uint256 violationCount,
    uint256 requiredDeposit
);
```

---

## 8. 거버넌스 파라미터

시퀀서 슬래싱 시스템에서 거버넌스가 결정해야 하는 파라미터:

| 파라미터 | 설명 | 권장값 |
|---------|------|--------|
| **H_max** | 최대 동시 챌린저 수 | 10 |
| **C_max** | 단일 fraud proof 최대 온체인 비용 | 10e27 (10 TON) |
| **γ (penaltyFactor)** | 반복 위반 페널티 팩터 (γ > 1) | TBD |
| **slashingWindow** | 슬래싱 윈도우 기간 | TBD |
| **minimumInitialDepositAmount** | V2 최소 담보금 | 1000.1e27 |
