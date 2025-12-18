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
| **C_max** | 단일 fraud proof 실행의 예상(estimated) 온체인 비용 | 프로토콜 레벨 (전체 동일) |
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

/// @notice C_max: 단일 fraud proof 실행의 예상(estimated) 온체인 비용
/// @dev 프로토콜에서 정의, 거버넌스로 변경 가능
/// @dev 회의록 결정: "maximum cost" → "estimated/sufficient cost"로 완화
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
| **C_max** | fraud proof 예상 비용 보전 (최소 보장) |
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

> **⚠️ 백서 vs 현재 구현 차이 (추가 개발 필요)**
>
> **백서 (Page 10):**
> > "A slashed sequencer is **suspended from sequencing** according to protocol rules. To resume operation, the sequencer must **restore the bond within the re-bond period**; failure to do so results in **permanent removal from the active sequencer set**."
>
> | 항목 | 백서 요구사항 | 현재 구현 |
> |------|--------------|----------|
> | **슬래싱 시 L2 시퀀싱** | ❌ 정지됨 (suspended) | ⚠️ 영향 없음 (시뇨리지 자격만 상실) |
> | **re-bond period** | ✅ 담보금 복구 기간 | ⚠️ 미구현 |
> | **영구 제거** | ✅ 기간 내 미복구 시 제거 | ⚠️ 미구현 |
>
> **추가 개발 필요 항목:**
> 1. 시퀀서 정지 메커니즘 (L2 시퀀싱 정지)
> 2. re-bond period 파라미터 및 로직
> 3. 영구 제거 메커니즘 (active sequencer set에서 제거)

---

## 5. 슬래싱 결정 및 호출

### 5.1 슬래싱 결정 주체

슬래싱은 **FaultDisputeGame** (Optimism의 Fraud Proof 시스템)을 통해 결정됩니다.

```
┌─────────────────────────────────────────────────────────────┐
│                    FaultDisputeGame                         │
│                                                             │
│  1. 시퀀서가 잘못된 상태 루트 제출                            │
│  2. 챌린저가 fraud proof 제출                                │
│  3. 분쟁 기간 동안 검증                                      │
│  4. 게임 종료: CHALLENGER_WINS / DEFENDER_WINS              │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
              게임 상태가 CHALLENGER_WINS (1)이면
                    슬래싱 실행 가능
```

### 5.2 슬래싱 호출 방식

슬래싱은 `slashSequencerByGame()` 함수를 통해 Permissionless로 실행됩니다.

게임이 `CHALLENGER_WINS`로 종료되면, **누구나** 슬래싱 실행 함수를 호출할 수 있습니다. 이는 이미 온체인에서 결정된 결과를 실행하는 것일 뿐이며, 호출자가 슬래싱을 "결정"하는 것이 아닙니다.

```solidity
/// @notice Permissionless 슬래싱 실행
/// @dev 게임 상태를 온체인에서 검증하여 슬래싱 결정
/// @param gameAddress 종료된 FaultDisputeGame 주소
function slashSequencerByGame(address gameAddress) external;
```

#### 챌린저 조회 방식

**⚠️ 중요: 챌린저 목록은 파라미터로 받지 않고, 온체인에서 직접 조회해야 합니다.**

챌린저를 파라미터로 받으면 호출자가 임의의 주소를 전달하여 보상을 탈취할 수 있습니다. 따라서 FaultDisputeGame 컨트랙트에서 직접 챌린저를 조회해야 합니다.

```
┌─────────────────────────────────────────────────────────────┐
│                  챌린저 조회 방식 (TODO)                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  옵션 1: 게임에서 직접 조회                                  │
│          FaultDisputeGame.getChallengers() 같은 함수 사용   │
│                                                             │
│  옵션 2: 이벤트 파싱                                        │
│          게임의 Move 이벤트를 파싱하여 챌린저 주소 수집      │
│                                                             │
│  옵션 3: 단일 챌린저                                        │
│          root claim에 dispute한 단일 챌린저만 보상          │
│                                                             │
│  → Optimism FaultDisputeGame 구조 확인 후 결정 필요         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 슬래싱 실행 전 검증 (중요)

Permissionless 함수이므로, 악의적인 호출을 방지하기 위한 검증이 필수입니다:

```
┌─────────────────────────────────────────────────────────────┐
│                     검증 체크리스트                          │
├─────────────────────────────────────────────────────────────┤
│ ✓ 1. DisputeGameFactory 검증                                │
│      해당 게임이 공식 Factory에서 생성되었는지 확인           │
│      → 가짜 게임 컨트랙트로 임의 슬래싱 방지                  │
│                                                             │
│ ✓ 2. 게임 상태 검증                                         │
│      status() == CHALLENGER_WINS (1) 인지 확인              │
│                                                             │
│ ✓ 3. 중복 슬래싱 방지                                       │
│      slashedGames[gameAddress] == false 확인                │
│                                                             │
│ ✓ 4. L2 매핑 검증                                           │
│      게임의 systemConfig → 유효한 L2 주소 매핑 확인          │
└─────────────────────────────────────────────────────────────┘
```

**✅ DisputeGameFactory 검증 구현됨**: L1BridgeRegistry에 등록된 rollupConfig와 매칭하여 가짜 게임 컨트랙트 방지

```solidity
// 실제 구현: L1BridgeRegistry 기반 검증
function slashSequencerByGame(address gameAddress) external onlyMigrated {
    // 1. 중복 슬래싱 방지
    if (slashedGames[gameAddress]) revert AlreadySlashedError();

    // 2. 게임 상태 확인 (CHALLENGER_WINS = 1)
    uint8 gameStatus = IFaultDisputeGame(gameAddress).status();
    if (gameStatus != 1) revert GameNotResolvedError();

    // 3. SystemConfig 조회
    address systemConfig = IFaultDisputeGame(gameAddress).systemConfig();

    // 4. DisputeGameFactory 검증 - 가짜 게임 컨트랙트 방지
    address factory = IOptimismSystemConfig(systemConfig).disputeGameFactory();
    if (factory == address(0)) revert InvalidFactoryError();

    // 5. L1BridgeRegistry에서 factory가 등록되어 있는지 확인
    address registeredConfig = IL1BridgeRegistry(l1BridgeRegistry)
        .rollupConfigWithDisputeGameFactory(factory);
    if (registeredConfig != systemConfig) revert InvalidFactoryError();

    // 6. Layer2 주소 조회
    address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
    if (layer2 == address(0)) revert InvalidGameError();

    // 7. 챌린저 온체인 조회 - claimData(0).counteredBy
    address challenger = _getChallengerFromGame(gameAddress);

    // 슬래싱 실행
    slashedGames[gameAddress] = true;
    _executeSlashingWithChallenger(layer2, challenger);
}
```

---

## 6. 슬래싱 구현

슬래싱은 `slashSequencerByGame()` → `_executeSlashing()` 흐름으로 실행됩니다.

```solidity
/// @notice 내부 슬래싱 실행
/// @dev 백서: "the entire bond (D_sequencer) is slashed"
/// @param layer2 슬래싱 대상 L2 주소
/// @param challengers 성공한 챌린저 목록 (온체인에서 조회됨)
function _executeSlashing(address layer2, address[] memory challengers) internal {
    uint256 n = challengers.length;

    // 시퀀서(오퍼레이터) 주소 조회
    address sequencer = Layer2I(layer2).operator();
    require(sequencer != address(0), "no operator");

    // 담보금 = 해당 L2에 스테이킹된 시퀀서의 금액
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    uint256 deposit = coinage.balanceOf(sequencer);
    require(deposit > 0, "no deposit to slash");

    if (n == 0) {
        // 챌린저가 없으면 전액 DAO로
        coinage.burnFrom(sequencer, deposit);
        coinage.mint(dao, deposit);
    } else {
        uint256 additionalReward = sequencerAdditionalReward[layer2];

        // 챌린저 보상 계산: R_challenger = C_max + (Δ_sequencer / n)
        uint256 perChallengerReward = maxFraudProofCost + (additionalReward / n);

        // 총 챌린저 보상이 담보금을 초과하지 않도록
        uint256 totalChallengerRewards = perChallengerReward * n;
        if (totalChallengerRewards > deposit) {
            perChallengerReward = deposit / n;
            totalChallengerRewards = perChallengerReward * n;
        }

        // 각 챌린저에게 스테이킹 잔액으로 이전
        for (uint256 i = 0; i < n; i++) {
            coinage.burnFrom(sequencer, perChallengerReward);
            coinage.mint(challengers[i], perChallengerReward);
            emit ChallengerRewarded(challengers[i], layer2, perChallengerReward);
        }

        // 나머지는 DAO로 이전
        uint256 remainder = deposit - totalChallengerRewards;
        if (remainder > 0) {
            coinage.burnFrom(sequencer, remainder);
            coinage.mint(dao, remainder);
        }
    }

    // L2 유효성 재평가 (S_i = 0 이므로 S_i ≥ θ·B_i 불충족)
    // → 해당 L2는 시뇨리지 분배에서 제외됨
    onStakingChange(layer2);

    // 슬래싱 기록 저장
    sequencerSlashTimestamps[layer2].push(block.timestamp);

    emit SequencerSlashed(layer2, sequencer, deposit, n);
}
```

### 6.1 SeigManager.transferStake 함수 (신규)

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

### 6.2 onStakingChange 함수 세부 동작

슬래싱 후 `onStakingChange()`가 호출되면 다음 작업이 수행되어야 합니다:

```
┌─────────────────────────────────────────────────────────────┐
│                  onStakingChange(layer2)                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. oldEligible = isEligible                                │
│  2. newEligible = checkEligibility(layer2)                  │
│                                                             │
│  3. if (oldEligible == newEligible) → return (변경 없음)    │
│                                                             │
│  4. if (true → false): 자격 상실                            │
│     ├─ updateSeigniorage() - 미정산 시뇨리지 정산           │
│     ├─ effectiveBridgedTON = 0                              │
│     └─ totalEffectiveBridgedTON 감소                        │
│                                                             │
│  5. if (false → true): 자격 획득                            │
│     ├─ effectiveBridgedTON = currentBridgedTON              │
│     ├─ totalEffectiveBridgedTON 증가                        │
│     └─ initialDebt 설정 (소급 방지)                         │
│                                                             │
│  6. isEligible = newEligible                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**핵심 포인트:**
- 상태가 변경되지 않으면 아무 작업도 하지 않음
- `true → false`: 시뇨리지 정산 먼저, 그 다음 effectiveBridgedTON = 0
- `false → true`: initialDebt 설정 필수 (과거 소급 방지)

```solidity
/// @notice 스테이킹 변경 시 L2 유효성 재평가
/// @param layer2 대상 L2 주소
function onStakingChange(address layer2) external {
    require(
        msg.sender == address(_depositManager) || msg.sender == address(this),
        "not authorized"
    );

    BridgedTONInfo storage info = bridgedTONInfo[layer2];
    bool oldEligible = info.isEligible;

    // 새로운 자격 상태 확인
    (bool newEligible, , ) = checkEligibility(layer2);

    // 상태 변경 없으면 리턴
    if (oldEligible == newEligible) return;

    if (oldEligible && !newEligible) {
        // true → false: 자격 상실
        // 1. 미정산 시뇨리지 먼저 정산
        ICandidate(layer2).updateSeigniorage();

        // 2. effectiveBridgedTON 제거
        totalEffectiveBridgedTON -= info.effectiveBridgedTON;
        info.effectiveBridgedTON = 0;

    } else {
        // false → true: 자격 획득
        // 1. effectiveBridgedTON 설정
        info.effectiveBridgedTON = info.currentBridgedTON;
        totalEffectiveBridgedTON += info.effectiveBridgedTON;

        // 2. initialDebt 설정 (이 시점부터 수익 시작)
        info.initialDebt = (bridgedTONRewardPerUnit * info.effectiveBridgedTON) / WEI_UNIT;
    }

    info.isEligible = newEligible;
    emit EligibilityChanged(layer2, newEligible, info.currentBridgedTON, info.effectiveBridgedTON);
}
```

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

```

---

## 8. 거버넌스 파라미터

시퀀서 슬래싱 시스템에서 거버넌스가 결정해야 하는 파라미터:

| 파라미터 | 설명 | 권장값 |
|---------|------|--------|
| **H_max** | 최대 동시 챌린저 수 | 10 |
| **C_max** | 단일 fraud proof 예상(estimated) 온체인 비용 | 10e27 (10 TON) |
| **minimumInitialDepositAmount** | V2 최소 담보금 | 1000.1e27 |

---

## 9. 구현 상태

`slashSequencerByGame` 함수 관련 개발 상태입니다.

### 9.1 ✅ DisputeGameFactory 검증 (구현 완료)

**목적**: 가짜 게임 컨트랙트로부터 보호

**구현된 검증 방식**:
1. `systemConfig.disputeGameFactory()` 조회
2. `L1BridgeRegistry.rollupConfigWithDisputeGameFactory(factory)` 조회로 등록된 factory인지 확인
3. 등록된 systemConfig와 일치하는지 검증

```solidity
// SeigManagerV1_4.sol - 실제 구현
address factory = IOptimismSystemConfig(systemConfig).disputeGameFactory();
if (factory == address(0)) revert InvalidFactoryError();

address registeredConfig = IL1BridgeRegistry(l1BridgeRegistry)
    .rollupConfigWithDisputeGameFactory(factory);
if (registeredConfig != systemConfig) revert InvalidFactoryError();
```

### 9.2 ✅ 챌린저 온체인 조회 (구현 완료)

**목적**: 보상받을 챌린저를 온체인에서 직접 조회

**구현된 조회 방식**: `claimData(0).counteredBy` - root claim을 counter한 단일 챌린저

```solidity
// SeigManagerV1_4.sol - 실제 구현
function _getChallengerFromGame(address gameAddress) internal view returns (address challenger) {
    // claimData(0) 조회: (parentIndex, counteredBy, claimant, bond, claim, position, clock)
    (bool success, bytes memory data) = gameAddress.staticcall(
        abi.encodeWithSignature("claimData(uint256)", 0)
    );
    if (success && data.length >= 64) {
        // counteredBy는 두 번째 필드 (32-63 bytes)
        assembly {
            challenger := mload(add(data, 64))
        }
    }
}
```

**참고**: 현재 구현은 단일 챌린저(root claim의 disputer)만 보상하는 방식입니다.

### 9.3 참고: Optimism FaultDisputeGame 구조

```
확인 필요한 Optimism 컨트랙트:
- packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol
- packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol
- packages/contracts-bedrock/src/dispute/interfaces/IFaultDisputeGame.sol

주요 확인 포인트:
1. ClaimData 구조체에 claimant(claim 제출자) 필드 존재 여부
2. rootClaim과 이에 대한 counterclaim 관계
3. resolve() 후 승자(challenger) 정보 접근 방법
```
