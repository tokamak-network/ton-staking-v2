# 시퀀서 슬래싱

## 1. 개요

Tokamak Network V3에서 시퀀서의 부정 행위(fraud)를 억제하기 위한 슬래싱 시스템입니다.

**V3 변경사항:**
- 시퀀서 담보금을 **SequencerVault**에 직접 TON으로 예치
- 담보금 시뇨리지 없음 (depositedAmount = 원금 - 슬래싱)
- DepositManager/coinage 미사용 → 즉시 출금 가능
- Bridged TON 기반 최소 담보금 요구

---

## 2. SequencerVault 아키텍처

### 2.1 개요

```
┌─────────────────────────────────────────────────────────────┐
│                     SequencerVault                          │
│                                                             │
│  - L2별 시퀀서 담보금 관리                                   │
│  - TON 직접 예치 (DepositManager 미사용)                    │
│  - 담보금 시뇨리지 없음                                      │
│  - Fraud Proof 기반 슬래싱                                  │
│  - SystemConfig 기반 L2 식별                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 예치 흐름

```
시퀀서 → SequencerVault.registerSequencer() → TON 직접 보관
                    │
                    ▼
        [시뇨리지 없음 - 원금 그대로 보관]
                    │
                    ▼
        deactivateSequencer() → TON 즉시 반환
```

### 2.3 컨트랙트 구조

```
src/sequencer/
├── ISequencerVault.sol          # 인터페이스
├── SequencerVaultStorage.sol    # 스토리지
├── SequencerVault.sol           # 구현체
└── SequencerVaultProxy.sol      # 프록시
```

---

## 3. 시퀀서 담보금

### 3.1 담보금 공식

백서 V3 기준 최소 담보금:

```
S_i >= θ · B_i + H_max · (C_max + Δ_sequencer)
```

| 파라미터 | 설명 | 기본값 |
|---------|------|--------|
| **θ** | Bridged TON 대비 최소 담보금 비율 | 0.1 (10%) |
| **B_i** | 해당 L2의 Bridged TON | L1BridgeRegistry에서 조회 |
| **H_max** | 최대 동시 챌린저 수 | 10 |
| **C_max** | 단일 fraud proof 예상 비용 | 1000 TON |
| **Δ_sequencer** | 시퀀서 추가 보상 | 100 TON |

### 3.2 최소 담보금 계산

```solidity
/// @notice 최소 담보금 계산 (Bridged TON 기반)
/// @dev 백서: S_i >= θ · B_i + H_max · (C_max + Δ_sequencer)
function getMinimumCollateral(uint256 bridgedTON)
    public view returns (uint256)
{
    // θ · B_i (Bridged TON 대비 최소 담보금)
    uint256 minFromBridgedTON = (bridgedTON * minimumStakingRatio) / RAY;

    // H_max · (C_max + Δ_sequencer) (동시 fraud proof 대응 비용)
    uint256 fraudProofBuffer = maxChallengers * (maxFraudProofCost + sequencerAdditionalReward);

    return minFromBridgedTON + fraudProofBuffer;
}
```

### 3.3 스토리지

```solidity
/// @notice 시퀀서 담보금 정보
/// @dev V3 정책: 담보금 시뇨리지 없음
struct SequencerDeposit {
    address operator;               // 오퍼레이터 주소 (출금 권한)
    address layer2;                 // L2 주소 (candidate)
    uint256 depositedAmount;        // 현재 유효 담보금 (원금 - 슬래싱 손실)
    uint256 slashedAmount;          // 누적 슬래싱 금액
    bool isActive;                  // 활성 상태
}

/// @notice systemConfig => SequencerDeposit
mapping(address => SequencerDeposit) public sequencerDeposits;

/// @notice layer2 => systemConfig (역방향 조회용)
/// @dev SeigManager에서 layer2 기준으로 담보금 조회 시 사용
mapping(address => address) public layer2ToSystemConfig;

// 파라미터
uint256 public minimumStakingRatio;        // θ (RAY 단위)
uint256 public maxFraudProofCost;          // C_max
uint256 public sequencerAdditionalReward;  // Δ_sequencer
uint256 public maxChallengers;             // H_max
```

---

## 4. 시퀀서 등록/탈퇴

### 4.1 시퀀서 등록

```solidity
/// @notice 시퀀서 등록 (TON 직접 예치)
/// @dev TON.approveAndCall(Vault, amount, systemConfig) 사용 권장
function registerSequencer(address systemConfig, uint256 depositAmount) external;
```

**등록 조건:**
- systemConfig가 유효해야 함 (L1BridgeRegistry에 등록)
- 최소 담보금 충족: `depositAmount >= getMinimumCollateral(bridgedTON)`
- 해당 systemConfig에 활성 시퀀서가 없어야 함

### 4.2 시퀀서 탈퇴

```solidity
/// @notice 시퀀서 탈퇴 및 즉시 출금
/// @dev V3: DepositManager 미사용으로 즉시 출금 가능
function deactivateSequencer(address systemConfig) external;
```

**탈퇴 특징:**
- 즉시 TON 반환 (2주 대기 없음)
- 시뇨리지 없으므로 depositedAmount 전액 반환

### 4.3 담보금 추가

```solidity
/// @notice 담보금 추가 예치
function addDeposit(address systemConfig, uint256 amount) external;
```

---

## 5. 슬래싱 메커니즘

### 5.1 슬래싱 조건

fraud proof 게임에서 챌린저가 승리하면 시퀀서의 담보금이 슬래싱됩니다.

### 5.2 슬래싱 흐름

```
Fraud Proof 게임 결과: 챌린저 승리
            │
            ▼
┌───────────────────────────────────────┐
│  SequencerVault.slashSequencerByGame()│
│  - 담보금 전액 차감                    │
│  - 챌린저 보상 누적 (pendingRewards)   │
│  - 나머지 Treasury 귀속분 누적         │
└───────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────┐
│  시퀀서 자동 비활성화                  │
│  챌린저가 나중에 claimChallengerReward │
└───────────────────────────────────────┘
```

### 5.3 챌린저 보상

> **TODO: 추가 검토 필요**
> - 챌린저(Challenger)와 검증자(Validator)의 역할 구분
> - 챌린저 보상 분배 방식 (직접 claim vs RAT 분배)
> - 챌린저 식별 방법 (`claimData(0).counteredBy` 정확성 검증)
>
> **❓ 확인 질문: 비검증자도 챌린저 보상을 받을 수 있는가?**
>
> RAT에 검증자로 등록되지 않은 계정도 시퀀서 슬래싱 시 챌린저 보상을 받을 수 있는가?
>
> - **현재 구현**: 검증자 등록 여부 체크 없이 `claimData(0).counteredBy` 주소에게 보상 지급
> - **백서 해석** (10페이지): "fraud proof succeeds, whether submitted by a challenger or validator"
>   → 챌린저와 검증자를 구분하며, fraud proof 제출은 permissionless
> - **결론 (추정)**: 비검증자도 챌린저 보상 수령 가능
>
> 👉 **이 해석이 의도된 설계인지 팀 내부 확인 필요**

```solidity
// 챌린저 보상 = C_max + Δ_sequencer
uint256 challengerReward = maxFraudProofCost + sequencerAdditionalReward;

// 챌린저 보상 누적 (나중에 claim)
pendingChallengerRewards[challenger] += challengerReward;

// 나머지는 Treasury 귀속분으로 누적
accumulatedSlashings += (actualSlash - challengerReward);

// 챌린저가 직접 보상 청구
function claimChallengerReward() external;
```

**V3 변경사항:**
- ~~스테이킹 잔액 이전~~ → TON 직접 보관
- 챌린저가 `claimChallengerReward()` 호출하여 보상 수령

### 5.4 슬래싱 예시

- `D_sequencer = 12,000 TON` (B_i=10,000, θ=0.1, H_max=10, C_max=1000, Δ=100)
- 챌린저 1명이 fraud proof 성공
- 챌린저 보상: `1000 + 100 = 1,100 TON`
- Treasury 귀속분: 슬래싱 금액에서 챌린저 보상 제외한 나머지

### 5.5 슬래싱 후 상태

슬래싱 후 담보금이 최소 요구량 미만이면:
- 시퀀서 자동 비활성화 (`isActive = false`)
- 시퀀서가 추가 담보금 예치 후 재등록 필요

---

## 6. 슬래싱 호출 (Permissionless)

### 6.1 슬래싱 함수

SequencerVault에서 슬래싱은 `slashSequencerByGame()` 함수로 실행됩니다. **Permissionless** 방식으로 누구나 호출 가능합니다.

```solidity
/// @notice 시퀀서 슬래싱 - Permissionless 방식
/// @dev 누구나 호출 가능, 게임 상태를 온체인에서 검증
/// @param gameAddress 종료된 FaultDisputeGame 주소
function slashSequencerByGame(address gameAddress) external;
```

### 6.2 슬래싱 시퀀스

```
┌──────────────┐     ┌─────────────────────┐     ┌────────────────┐
│   Anyone     │     │   FaultDisputeGame  │     │ SequencerVault │
└──────┬───────┘     └──────────┬──────────┘     └───────┬────────┘
       │                        │                        │
       │  slashSequencerByGame(gameAddress)              │
       │────────────────────────────────────────────────>│
       │                        │                        │
       │                        │  game.status()         │
       │                        │<───────────────────────│
       │                        │                        │
       │                        │  CHALLENGER_WINS       │
       │                        │───────────────────────>│
       │                        │                        │
       │                        │                        │ 담보금 슬래싱
       │                        │                        │ 챌린저 보상 전송
       │                        │                        │
       │      slashed           │                        │
       │<────────────────────────────────────────────────│
```

### 6.3 슬래싱 검증 (온체인)

```
┌─────────────────────────────────────────────────────────────┐
│                     검증 체크리스트                          │
├─────────────────────────────────────────────────────────────┤
│ ✓ 1. 중복 슬래싱 방지                                       │
│      slashedGames[gameAddress] == false 확인                │
│                                                             │
│ ✓ 2. 게임 상태 검증                                         │
│      game.status() == CHALLENGER_WINS (1) 확인              │
│                                                             │
│ ✓ 3. SystemConfig 조회                                      │
│      game.systemConfig() 호출                               │
│                                                             │
│ ✓ 4. DisputeGameFactory 검증                                │
│      systemConfig.disputeGameFactory() 조회                 │
│      L1BridgeRegistry에 등록된 factory인지 확인             │
│                                                             │
│ ✓ 5. 시퀀서 조회                                            │
│      systemConfigSequencer[systemConfig]                    │
│                                                             │
│ ✓ 6. 챌린저 온체인 조회                                     │
│      game.claimData(0).counteredBy                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. 슬래싱 구현

SequencerVault에서의 슬래싱 구현입니다.

```solidity
/// @notice 시퀀서 슬래싱 - Permissionless 방식
function slashSequencerByGame(address gameAddress) external whenNotPaused {
    // 1. 이미 슬래싱되었는지 확인
    if (slashedGames[gameAddress]) revert AlreadySlashedGameError();

    // 2. FaultDisputeGame 상태 조회 (CHALLENGER_WINS = 1)
    (bool success, bytes memory data) = gameAddress.staticcall(
        abi.encodeWithSignature("status()")
    );
    if (!success || data.length == 0) revert InvalidGameError();
    uint8 gameStatus = abi.decode(data, (uint8));
    if (gameStatus != 1) revert GameNotResolvedError();

    // 3. SystemConfig 조회
    (success, data) = gameAddress.staticcall(
        abi.encodeWithSignature("systemConfig()")
    );
    address systemConfig = abi.decode(data, (address));

    // 4. DisputeGameFactory 검증
    address factory = IOptimismSystemConfig(systemConfig).disputeGameFactory();
    address registeredConfig = IL1BridgeRegistry(l1BridgeRegistry)
        .rollupConfigWithDisputeGameFactory(factory);
    if (registeredConfig != systemConfig) revert InvalidFactoryError();

    // 5. 시퀀서 조회
    address sequencer = systemConfigSequencer[systemConfig];
    if (sequencer == address(0)) revert NotRegisteredError();
    SequencerDeposit storage deposit = sequencerDeposits[systemConfig][sequencer];

    // 6. 챌린저 온체인 조회
    address challenger = _getChallengerFromGame(gameAddress);

    // 7. 슬래싱 처리
    slashedGames[gameAddress] = true;
    _executeSlashing(systemConfig, sequencer, deposit, challenger, gameAddress);
}

/// @notice 내부 슬래싱 실행
function _executeSlashing(...) internal {
    // 담보금 전액 슬래싱
    uint256 actualSlash = deposit.depositedAmount;

    // 챌린저 보상 = C_max + Δ_sequencer
    uint256 challengerReward = maxFraudProofCost + sequencerAdditionalReward;

    // 담보금 차감
    deposit.depositedAmount = 0;
    deposit.slashedAmount += actualSlash;

    // Treasury 귀속분 누적
    accumulatedSlashings += (actualSlash - challengerReward);

    // 챌린저 보상 누적 (나중에 claim)
    pendingChallengerRewards[challenger] += challengerReward;

    // 시퀀서 비활성화
    deposit.isActive = false;

    emit SequencerSlashed(...);
}
```

---

## 8. 이벤트

```solidity
/// @notice 시퀀서 등록 이벤트
event SequencerRegistered(
    address indexed sequencer,
    address indexed systemConfig,
    uint256 depositAmount
);

/// @notice 시퀀서 탈퇴 이벤트
event SequencerDeactivated(
    address indexed sequencer,
    address indexed systemConfig,
    uint256 returnedAmount
);

/// @notice 시퀀서 슬래싱 이벤트
event SequencerSlashed(
    address indexed sequencer,
    address indexed systemConfig,
    address indexed gameAddress,
    uint256 slashedAmount,
    address challenger,
    uint256 challengerReward
);

/// @notice 슬래싱 금액 Treasury 전송 이벤트
event SlashingsWithdrawnToTreasury(
    address indexed treasury,
    uint256 amount
);
```

---

## 9. 거버넌스 파라미터

SequencerVault에서 거버넌스가 결정해야 하는 파라미터:

| 파라미터 | 설명 | 기본값 |
|---------|------|--------|
| **θ (minimumStakingRatio)** | Bridged TON 대비 최소 담보금 비율 | 0.1 (10%) |
| **H_max (maxChallengers)** | 최대 동시 챌린저 수 | 10 |
| **C_max (maxFraudProofCost)** | 단일 fraud proof 예상 비용 | 1000 TON |
| **Δ_sequencer (sequencerAdditionalReward)** | 시퀀서 추가 보상 | 100 TON |

