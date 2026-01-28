---
id: functions-seig-manager
sidebar_position: 2
---

# SeigManager 함수

시뇨리지 계산 및 분배 핵심 함수입니다.

## updateSeigniorage

시뇨리지 분배를 실행하는 핵심 함수입니다.

```solidity
function updateSeigniorage() external whenNotPaused returns (bool)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 각 L2가 개별 호출 |
| **접근 제어** | `whenNotPaused` |
| **가스비** | 고정 (호출 L2만 처리, L2 수와 무관) |

**동작 흐름**:

```
1. 전체 시뇨리지 계산
   A = (block.number - lastSeigBlock) × seigPerBlock

2. v3Migrated 확인

   V2 모드 (v3Migrated = false):
   └─► V1_3 _increaseTot() 로직 실행
       - stakedSeig = A × prevTotalSupply / tos
       - l2TotalSeigs = A × tempTotalLayer2TVL / tos
       - totalPseig = unstakedSeig × r
       - Coinage factor 업데이트

   V3 모드 (v3Migrated = true):
   └─► _distributeV3Seigniorage(A)
       - DAO 분배: d × A
       - L2 분배: y(x) = L × (x/(k+x))
       - 검증자 분배: α × S_i → ValidatorReward

3. lastSeigBlock = block.number
```

**이벤트**:
- `SeigGiven2`: 시뇨리지 분배 상세 정보
- `V3SeigniorageDistributed`: V3 분배 정보 (V3 모드에서만)

### V2 시뇨리지 분배 메커니즘

V2 모드에서 시퀀서가 시뇨리지를 받기 위한 전체 흐름입니다.

**전제 조건**:

```
1. Layer2 등록 완료
   - L1BridgeRegistry에 rollupConfig 등록
   - Layer2Manager에 registerCandidateAddOn() 호출
   - Operator가 minimumAmount 이상 스테이킹

2. Bridged TON 필요 (layer2TVL > 0)
   - Portal에 TON이 있어야 layer2TVL이 잡힘
   - layer2TVL = IERC20(ton).balanceOf(portal)
   - layer2TVL이 0이면 시뇨리지 분배 없음
```

**신규 L2의 첫 updateSeigniorage() 호출 시 주의사항**:

새로 등록된 L2가 처음으로 `updateSeigniorage()`를 호출하면 **즉시 시뇨리지를 받지 않습니다**.

```
┌─────────────────────────────────────────────────────────────────┐
│ 신규 L2의 첫 번째 updateSeigniorage() 호출                        │
├─────────────────────────────────────────────────────────────────┤
│ • startBlock 설정 (layer2RewardInfo[layer2].startBlock)         │
│ • 실제 시뇨리지 분배 없음 (시작점 기록만)                          │
│ • 이 블록부터 시뇨리지 계산이 시작됨                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                     (블록 진행 후)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 이후 updateSeigniorage() 호출                                    │
├─────────────────────────────────────────────────────────────────┤
│ • startBlock 이후 경과된 블록에 대한 시뇨리지 분배                │
│ • l2RewardPerUint 누적 (선형 방식)                               │
│ • Coinage factor를 통해 스테이커 잔액 자동 증가                   │
└─────────────────────────────────────────────────────────────────┘
```

> **참고**: 이미 시뇨리지를 받기 시작한 L2는 매 호출마다 정상적으로 시뇨리지를 받습니다. 위 내용은 신규 등록 L2의 첫 호출에만 해당됩니다.

**V2 시뇨리지 분배 공식**:

```solidity
// 1. 전체 L2 시뇨리지 계산
l2TotalSeigs = rmul(maxSeig, tempTotalLayer2TVL) / tos

// 2. 단위당 보상 누적 (선형 방식)
l2RewardPerUint += (l2TotalSeigs × WEI_UNIT) / totalLayer2TVL

// 3. 개별 L2 시뇨리지 계산
layer2Seigs = (l2RewardPerUint × layer2Tvl / WEI_UNIT) - initialDebt

// layer2Tvl = L1BridgeRegistry.layer2TVL(rollupConfig)
//           = IERC20(ton).balanceOf(portal)
```

**시퀀서/스테이커 시뇨리지 수령 방식**:

V2에서는 시뇨리지 수령 방식이 두 가지로 나뉩니다:

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Layer2 시퀀서 시뇨리지 (layer2Seigs)                          │
├─────────────────────────────────────────────────────────────────┤
│ • SeigManager에서 계산: layer2Seigs                              │
│ • Layer2Manager.transferL2Seigniorage() 호출                    │
│ • OperatorManager 주소로 WTON 직접 전송 (IERC20.transfer)       │
│ • Coinage 스테이킹과 별도로 WTON 잔액 증가                        │
│                                                                  │
│ 코드 흐름:                                                       │
│ SeigManagerV1_2.updateSeigniorageLayer()                        │
│   → layer2Seigs 계산                                            │
│   → ILayer2Manager.transferL2Seigniorage(layer2, layer2Seigs)  │
│      → Layer2ManagerV1_1.transferL2Seigniorage()               │
│         → address operator = operatorOfLayer[layer2]           │
│         → IERC20(wton).safeTransfer(operator, amount)          │
│                                                                  │
│ 주의: operator 주소는 OperatorManager 컨트랙트 주소              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 2. Operator/Staker 스테이킹 시뇨리지 (Coinage Factor)            │
├─────────────────────────────────────────────────────────────────┤
│ • updateSeigniorage() 호출 시 coinage.factor 증가               │
│ • 스테이커 잔액 = 예치량 × factor                                │
│ • factor 증가 → 스테이커 잔액 자동 증가 (시뇨리지 수령)          │
│                                                                  │
│ 예시:                                                            │
│ - 초기: 예치 100 WTON, factor = 1.0 → 잔액 100 WTON              │
│ - 시뇨리지 후: factor = 1.05 → 잔액 105 WTON (+5% 시뇨리지)       │
│                                                                  │
│ 적용 대상: Operator와 일반 Staker 모두                           │
└─────────────────────────────────────────────────────────────────┘
```

**V2 vs V3 핵심 차이**:

| 항목 | V2 모드 | V3 모드 |
|------|---------|---------|
| **분배 기준** | `layer2TVL` (Portal TON 잔액) | `effectiveBridgedTON` (자격 조건 포함) |
| **분배 함수** | 선형 누적 (`l2RewardPerUint`) | 쌍곡선 `y(x) = L·x/(k+x)` |
| **스테이커 시뇨리지** | ✅ 받음 (coinage factor) | ❌ 안 받음 |
| **검증자 보상** | ❌ 없음 | ✅ α×S_i / \|V_i\| |
| **자격 조건** | `minimumAmount` 만 체크 | `T_i ≥ max(θ×B_i, D_seq)` |

**V3 모드 보상 추적**:

시퀀서와 검증자의 보상이 **독립적으로 추적**됨:

```solidity
bridgedTONRewardPerUint  // 시퀀서용 (Bridged TON 단위당 보상)
validatorRewardPerUint   // 검증자용 (Bridged TON 단위당 보상)
```

업데이트 공식:
```
bridgedTONRewardPerUint += (1-α) × S_i / totalEffectiveBridgedTON
validatorRewardPerUint += α × S_i / totalEffectiveBridgedTON

여기서:
α = validatorDistributionRatio
S_i = L2별 시뇨리지
```

비율 관계:
```
validatorRewardPerUint / bridgedTONRewardPerUint ≈ α / (1-α)

예: α = 0.2 (20%)
→ 비율 = 0.2 / 0.8 = 0.25
```

---

## checkCurrentEligibility

L2의 자격 조건을 확인합니다.

```solidity
function checkCurrentEligibility(address layer2)
    external view
    returns (bool eligible, uint256 requiredStake, uint256 currentStake)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 |
| **반환값** | 자격 여부, 필요 담보금, 현재 담보금 |

**자격 조건**:
```
eligible = (T_i ≥ max(θ × B_i, D_sequencer))

여기서:
- T_i = SeigManager.getSequencerStaked(layer2) [WTON, 27 decimals]
- θ × B_i = 시뇨리지 자격 조건
- D_sequencer = H_max × C_max + Δ_sequencer (Fraud Proof 비용 커버)

파라미터:
- θ = minStakingRatio [RAY, 27 decimals]
- B_i = Layer2Manager.getBridgedTONByLayer(layer2) [TON, 18 decimals]
- H_max = maxChallengers (최대 동시 챌린저 수)
- C_max = maxFraudProofCost (단일 Fraud Proof 최대 비용)
- Δ_sequencer = sequencerAdditionalReward (시퀀서 추가 보상)
```

> **단위 참고**: T_i는 WTON(27 decimals), B_i는 TON(18 decimals). 비교 시 단위 변환 필요.

---

## onBridgedTonChange

Bridged TON 변경 시 자격을 재평가합니다 (Type 3 전용).

```solidity
function onBridgedTonChange() external whenV3Active
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | OptimismPortal (Type 3) |
| **접근 제어** | `whenV3Active` (V3 모드에서만) |
| **동작** | Early return 패턴 (revert 하지 않음) |

**동작 흐름**:
```
1. L1BridgeRegistry.rollupConfigWithPortal(msg.sender) → rollupConfig 조회
   ├─ 등록되지 않은 포탈 → early return
   └─ Type 3 아님 → early return

2. Layer2Manager.getLayer2BySystemConfig(rollupConfig) → layer2 조회
   └─ 등록되지 않은 L2 → early return

3. _updateEligibilityInternal(layer2)
   ├─ 자격 재평가 (T_i ≥ θ × B_i)
   └─ totalEffectiveBridgedTON 갱신
```

---

## onStakingChange

스테이킹 변경 시 자격을 재평가합니다.

```solidity
function onStakingChange(address layer2) external onlyDepositManager
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | DepositManager |
| **접근 제어** | `onlyDepositManager` |

---

## migrateToV3

V3 모드로 전환합니다.

```solidity
function migrateToV3() external onlyOwner
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | DAO (Owner) |
| **접근 제어** | `onlyOwner` |
| **되돌림** | 불가능 |

**전환 효과**:
- `v3Migrated = true`
- 스테이커 시뇨리지 비활성화
- Bridged TON 기반 분배 활성화
- 검증자 보상 활성화

---

## 거버넌스 함수

```solidity
// DAO 분배 비율 설정 (0 < d < 1)
function setDaoDistributionRatio(uint256 ratio) external onlyOwner

// 최소 스테이킹 비율 설정 (0 < θ ≤ 1)
function setMinStakingRatio(uint256 ratio) external onlyOwner

// 검증자 분배 비율 설정 (0 < α < 1)
function setValidatorDistributionRatio(uint256 ratio) external onlyOwner

// 반포화점 설정 (k > 0)
function setHalfSaturationPoint(uint256 k) external onlyOwner

// ValidatorReward 컨트랙트 주소 설정
function setValidatorReward(address reward) external onlyOwner

// RAT 컨트랙트 주소 설정
function setRatContract(address rat) external onlyOwner

// V2 로직 컨트랙트 설정 (V2 호환성)
function setV2Logic(address v2Logic) external onlyOwner

// 슬래싱 파라미터 설정
function setMaxChallengers(uint256 _maxChallengers) external onlyOwner
function setMaxFraudProofCost(uint256 _maxFraudProofCost) external onlyOwner
function setSequencerAdditionalReward(uint256 _sequencerAdditionalReward) external onlyOwner
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Owner (DAO) |
| **접근 제어** | `onlyOwner` |
| **경계 조건** | 모두 0 허용, 상한 없음 |

**슬래싱 파라미터 용도**:

D_sequencer 계산에 사용:
```
D_sequencer = maxChallengers × maxFraudProofCost + sequencerAdditionalReward

예시:
maxChallengers = 3
maxFraudProofCost = 50e27 WTON
sequencerAdditionalReward = 100e27 WTON
→ D_sequencer = 3 × 50e27 + 100e27 = 250e27 WTON
```

---

## RAT 연동 함수 (V3 전용)

RAT와의 담보금 전송을 처리합니다.

```solidity
// 검증자 → RAT으로 Coinage 전송 (슬래싱 선차감)
function transferCoinageToRat(address layer2, address validator, uint256 amount)
    external onlyRAT

// RAT → 검증자로 Coinage 반환 (증거 제출 또는 챌린지 승리)
function transferCoinageFromRat(address layer2, address validator, uint256 amount)
    external onlyRAT

// RAT → 지정 주소로 Coinage 전송 (특수 케이스)
function transferCoinageFromRatTo(address layer2, address to, uint256 amount)
    external onlyRAT
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | RAT 컨트랙트 |
| **접근 제어** | `onlyRAT` |
| **용도** | RAT 테스트 시 담보금 관리 |

---

## claimL2Seigniorage

시뇨리지 트리거 없이 L2 보상만 청구합니다 (가스 최적화용).

```solidity
function claimL2Seigniorage(address layer2) external whenV3Active whenNotPaused
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 |
| **접근 제어** | `whenV3Active`, `whenNotPaused` |
| **용도** | updateSeigniorage 없이 L2 보상만 청구 |

**동작 흐름**:
```
1. V3 모드 확인
2. layer2별 누적된 시뇨리지가 있으면 전송
3. 새로운 시뇨리지 계산은 하지 않음 (가스 절약)
```

---

## 자격 상실 시 자동 청구

L2가 시뇨리지 자격을 상실하면 **미청구 시퀀서 보상이 자동으로 청구됨**.

**트리거 함수**:
- `onStakingChange()` - DepositManager가 예치/출금 시 호출
- `checkAndUpdateEligibility()` - 내부 자격 상태 변경 감지

**동작 흐름**:
```
1. 자격 상태 변경 감지 (eligible → ineligible)
   ↓
2. 미청구 보상 자동 청구
   → _claimL2Seigniorage(layer2) 호출
   → OperatorManager로 WTON 전송
   ↓
3. effectiveBridgedTON = 0으로 설정
   ↓
4. 이벤트 발생: AutoClaimBeforeEligibilityLoss(layer2, amount)
```

**이벤트**:
```solidity
event AutoClaimBeforeEligibilityLoss(
    address indexed layer2,
    uint256 claimedAmount
);
```

---

## onWithdraw

출금 요청 시 담보금 최소 요구량을 체크합니다.

```solidity
function onWithdraw(address layer2, address account, uint256 amount) external onlyDepositManager returns (bool)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | DepositManager |
| **접근 제어** | `onlyDepositManager` |
| **반환값** | 항상 true |

**동작 흐름**:

```
1. 잔액 확인
   balance = coinage.balanceOf(account)
   require(balance >= amount)
   newBalance = balance - amount

2. 시퀀서(오퍼레이터) 담보금 체크
   if (account == layer2.operator()):
       V2 모드 (v3Migrated = false):
           require(newBalance >= minimumAmount)

       V3 모드 (v3Migrated = true):
           (_, requiredStake, _) = checkCurrentEligibility(layer2)
           require(newBalance >= requiredStake)

3. 검증자 담보금 체크 (V3만 해당)
   if (v3Migrated && ratContract != address(0)):
       validatorMin = RAT.getValidatorMinCollateralForLayer2(layer2, account)
       if (validatorMin > 0):
           require(newBalance >= validatorMin)

4. 출금 처리
   - TOT burn
   - Coinage burn
```

**출금 제한**:

```
V2 모드:
- 시퀀서: 출금 후 잔액 ≥ minimumAmount (고정값)

V3 모드:
시퀀서:
- 출금 후 잔액 ≥ max(θ × B_i, D_sequencer) 유지 필요
  - θ × B_i = minStakingRatio × getBridgedTONByLayer(layer2) (시뇨리지 자격)
  - D_sequencer = H_max × C_max + Δ_sequencer (Fraud Proof 비용)
- checkCurrentEligibility()로 실시간 계산

검증자:
- 활성 검증자는 출금 후 잔액 ≥ D_min (pure) 유지 필요
- D_min (pure) = C_off(dynamic) + Δ_validator
  - C_off(dynamic) = max(slashingPenalty, (c_m × N × RAY) / π_a)
- relaxedValidatorCheck와 무관하게 항상 pure D_min 적용 (보안 우선)
- 최소 담보금 미만으로 출금하려면 검증자 탈퇴(deactivateValidator()) 필요
```

---

## onDeposit

예치 요청 시 담보금 최소 요구량을 체크합니다.

```solidity
function onDeposit(address layer2, address account, uint256 amount) external onlyDepositManager returns (bool)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | DepositManager |
| **접근 제어** | `onlyDepositManager` |
| **반환값** | 항상 true |

**동작 흐름**:

```
1. 잔액 확인
   balance = coinage.balanceOf(account)
   newBalance = balance + amount

2. 시퀀서(오퍼레이터) 최소 담보금 체크
   if (account == layer2.operator()):
       V2 모드 (v3Migrated = false):
           require(newBalance >= minimumAmount)

       V3 모드 (v3Migrated = true):
           (_, requiredStake, _) = checkCurrentEligibility(layer2)
           require(newBalance >= requiredStake)

3. 예치 처리
   - TOT mint
   - Coinage mint

4. 자격 상태 업데이트 (V3만 해당)
   if (v3Migrated):
       _updateEligibilityInternal(layer2)
```

**예치 제한**:

```
V2 모드:
- 시퀀서: 예치 후 잔액 ≥ minimumAmount (고정값)

V3 모드:
- 시퀀서: 예치 후 잔액 ≥ max(θ × B_i, D_sequencer) 유지 필요
- 일반 사용자/검증자: 예치 금액 제한 없음 (시퀀서만 체크)
```
