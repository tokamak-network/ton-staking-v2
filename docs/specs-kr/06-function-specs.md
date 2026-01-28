# TON Staking V3 함수별 상세 설명

## 1. SeigManager 함수

### 1.1 updateSeigniorage

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

#### 1.1.1 V2 시뇨리지 분배 메커니즘 (상세)

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

### 1.2 checkCurrentEligibility

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

### 1.3 onBridgedTonChange

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

### 1.4 onStakingChange

스테이킹 변경 시 자격을 재평가합니다.

```solidity
function onStakingChange(address layer2) external onlyDepositManager
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | DepositManager |
| **접근 제어** | `onlyDepositManager` |

---

### 1.5 migrateToV3

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

### 1.6 거버넌스 함수

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

### 1.7 RAT 연동 함수 (V3 전용)

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

### 1.8 claimL2Seigniorage

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

### 1.9 자격 상실 시 자동 청구

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

**자격 재획득**:
- 담보금 추가 예치 후 자격 재획득 시
- `effectiveBridgedTON` 복원
- 새로운 보상부터 다시 누적
- **자격 상실 기간의 보상은 받지 못함**

**이벤트**:
```solidity
event AutoClaimBeforeEligibilityLoss(
    address indexed layer2,
    uint256 claimedAmount
);
```

---

### 1.10 onWithdraw

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

### 1.10 onDeposit

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

---

## 2. DepositManager 함수

### 2.1 deposit

WTON을 스테이킹합니다.

```solidity
function deposit(address layer2, address account, uint256 amount)
    external
    onlyLayer2(layer2)
    returns (bool)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 스테이커 |
| **파라미터** | layer2: L2 주소, account: 수혜자, amount: WTON 금액 |

**동작 흐름**:
```
1. WTON.transferFrom(msg.sender, this, amount)
2. 스테이킹 기록 업데이트
   - _accStaked[layer2][account] += amount
   - _accStakedLayer2[layer2] += amount
3. SeigManager.onDeposit(layer2, account, amount)
   - V3: 최소 담보금 체크 및 자격 상태 업데이트 포함
```

---

### 2.2 설정 함수 (V3 전용)

DepositManagerV3에서 추가된 설정 함수들입니다.

```solidity
// 주소 초기 설정 (L1BridgeRegistry, Layer2Manager)
function setAddresses(address _l1BridgeRegistry, address _layer2Manager) external onlyOwner
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Owner (DAO) |
| **용도** | V3 배포 후 초기 설정 |

---

### 2.3 onApprove

TON.approveAndCall 콜백입니다.

```solidity
function onApprove(
    address owner,
    address spender,
    uint256 amount,
    bytes calldata data
) external returns (bool)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | WTON 컨트랙트 (TON.approveAndCall 경유) |
| **data 형식** | layer2 주소 (32바이트) |

---

### 2.4 requestWithdrawal

출금을 요청합니다.

```solidity
function requestWithdrawal(address layer2, uint256 amount) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 스테이커 |
| **대기 기간** | 2주 (약 100,800 블록) |
| **출금 제한** | SeigManager.onWithdraw()에서 체크 (1.7 참조) |

---

### 2.5 processRequest

출금을 처리합니다.

```solidity
function processRequest(address layer2) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 스테이커 |
| **조건** | 2주 대기 기간 경과 |

---

## 3. Layer2Manager 함수

### 3.1 getBridgedTon

Bridged TON을 조회합니다.

```solidity
function getBridgedTon(address rollupConfig) public view returns (uint256 bridgedTON)
function getBridgedTonByLayer(address layer2) public view returns (uint256 bridgedTON)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 |
| **조회 방식** | L1BridgeRegistry.layer2Tvl() 호출 |

---

### 3.2 설정 함수 (V3 전용)

Layer2ManagerV3에서 추가된 설정 함수들입니다.

```solidity
// 주소 설정 1 (L1BridgeRegistry, DepositManager)
function setAddresses1(address _l1BridgeRegistry, address _depositManager) external onlyOwner

// 주소 설정 2 (SeigManager, OperatorManagerFactory)
function setAddresses2(address _seigManager, address _operatorManagerFactory) external onlyOwner

// OperatorManagerFactory 업데이트
function setOperatorManagerFactory(address _operatorManagerFactory) external onlyOwner
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Owner (DAO) |
| **용도** | V3 배포 후 초기 설정 및 업데이트 |

---

### 3.3 getLayer2BySystemConfig

SystemConfig로 Layer2 주소를 조회합니다.

```solidity
function getLayer2BySystemConfig(address systemConfig) external view returns (address layer2)
```

---

## 4. L1BridgeRegistry 함수

### 4.1 layer2Tvl

L2의 TVL (Bridged TON)을 조회합니다.

```solidity
function layer2Tvl(address rollupConfig) external view returns (uint256)
```

**롤업 타입별 조회 방식**:

| 타입 | 조회 대상 | 조회 방법 |
|------|----------|----------|
| Type 1 (Legacy) | L1StandardBridge | TON 잔액 조회 |
| Type 2 (Bedrock) | OptimismPortal | TON 잔액 조회 |
| Type 3 (Dispute Game) | OptimismPortal | TON 잔액 조회 |

---

### 4.2 rollupConfigWithPortal

Portal 주소로 rollupConfig를 역조회합니다.

```solidity
function rollupConfigWithPortal(address portal) external view returns (address rollupConfig)
```

| 항목 | 내용 |
|------|------|
| **용도** | onBridgedTonChange에서 msg.sender(Portal) → rollupConfig 조회 |

---

### 4.3 setTypeRegistrant

타입별 등록 권한자를 설정합니다.

```solidity
function setTypeRegistrant(uint8 _type, address _registrant) external onlyManager
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Manager |
| **파라미터** | `_type`: 롤업 타입 (1, 2, 3, ...), `_registrant`: 권한자 주소 |
| **특이사항** | `address(0)` 설정 시 Manager만 등록 가능 |

---

### 4.4 upgradeToType3

TYPE 1/2에서 TYPE 3로 업그레이드합니다.

```solidity
function upgradeToType3(address rollupConfig) external onlyManager
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Manager |
| **사전 조건** | TYPE 1 또는 2로 등록되어 있어야 함, DisputeGameFactory 필요 |

**동작 흐름**:
```
1. 현재 타입 확인 (TYPE 1 또는 2만 허용)
2. DisputeGameFactory 주소 조회 및 검증
3. Portal 주소 조회 및 검증
4. Portal 등록:
   - portal[portal_] 미등록 시 true로 설정
   - rollupConfigWithPortal 미설정 시 설정 + 이벤트 발생
   - 다른 rollupConfig에 등록되어 있으면 revert
5. DisputeGameFactory 중복 체크 및 등록
6. rollupType = 3으로 변경
```

---

### 4.5 registerRollupConfigByType

타입별 권한 체크를 통한 롤업 등록입니다.

```solidity
function registerRollupConfigByType(
    address rollupConfig,
    uint8 _type,
    address _l2TON,
    string calldata _name
) external onlyTypeRegistrant(_type)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Manager 또는 `typeRegistrant[_type]` |
| **파라미터** | `_type`: 1(Legacy), 2(Bedrock), 3(Dispute Game) |

---

### 4.6 setAddresses

초기 설정을 수행합니다.

```solidity
function setAddresses(
    address _layer2Manager,
    address _seigManager,
    address _ton
) external onlyOwner
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Owner |
| **사전 조건** | ton == address(0) (미초기화 상태) |
| **특이사항** | 한 번만 호출 가능 |

---

### 4.7 setSeigniorageCommittee

SeigniorageCommittee 주소를 설정합니다.

```solidity
function setSeigniorageCommittee(address _seigniorageCommittee) external onlyOwner
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Owner |
| **특이사항** | 기존과 동일한 주소 설정 불가 |

---

### 4.8 rejectCandidateAddOn

특정 rollupConfig의 시뇨리지 발행을 중지합니다.

```solidity
function rejectCandidateAddOn(address rollupConfig) external onlySeigniorageCommittee
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | SeigniorageCommittee |
| **사전 조건** | rollupType != 0 (등록된 상태) |

**동작 흐름**:
```
1. 등록 여부 확인
2. rejectedSeigs = true
3. rejectedL2Deposit = true
4. Layer2Manager.pauseCandidateAddOn(rollupConfig) 호출
5. 이벤트: RejectedCandidateAddOn
```

---

### 4.9 restoreCandidateAddOn

중지된 시뇨리지 발행을 복원합니다.

```solidity
function restoreCandidateAddOn(
    address rollupConfig,
    bool rejectedL2Deposit
) external onlySeigniorageCommittee
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | SeigniorageCommittee |
| **사전 조건** | rejectedSeigs == true (중지된 상태) |

**동작 흐름**:
```
1. 중지 상태 확인
2. rejectedSeigs = false
3. rejectedL2Deposit = 파라미터 값
4. Layer2Manager.unpauseCandidateAddOn(rollupConfig) 호출
5. 이벤트: RestoredCandidateAddOn
```

---

### 4.10 registerRollupConfig

Registrant 권한으로 롤업을 등록합니다.

```solidity
function registerRollupConfig(
    address rollupConfig,
    uint8 _type,
    address _l2TON,
    string calldata _name
) external onlyRegistrant
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Registrant |
| **파라미터** | `_type`: 1(Legacy), 2(Bedrock), 3(Dispute Game) |
| **특이사항** | V1_2의 `_registerRollupConfig` 사용 (rollupConfigWithPortal 설정 포함) |

---

### 4.11 View 함수들

```solidity
// 롤업 타입 조회
function rollupType(address rollupConfig) external view returns (uint8)

// L2 TON 주소 조회
function l2TON(address rollupConfig) external view returns (address)

// 롤업 전체 정보 조회
function getRollupInfo(address rollupConfig) external view returns (
    uint8 type_,
    address l2TON_,
    bool rejectedSeigs_,
    bool rejectedL2Deposit_,
    string memory name_
)

// 시뇨리지 중지 여부
function isRejectedSeigs(address rollupConfig) external view returns (bool)

// L2 예치 중지 여부
function isRejectedL2Deposit(address rollupConfig) external view returns (bool)

// 등록 가능 여부
function availableForRegistration(address rollupConfig, uint8 _type) external view returns (bool)
```

---

## 5. RAT 함수

### 5.1 registerValidator

검증자를 등록합니다 (V3: 기존 스테이킹 사용).

```solidity
function registerValidator(address systemConfig) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 검증자 |
| **최소 담보금** | D_min = C_off + Δ_validator (coinage 기준) |

**동작 흐름**:
```
1. 이미 활성 검증자인지 확인
   └─ isActive = true면 실패 (AlreadyRegisteredError)

2. 현재 스테이킹 금액 확인: stakeOf(layer2, validator)

3. 스테이킹 금액 >= D_min 확인
   └─ 부족 시: 등록 실패 (InsufficientCollateralError)

4. 등록 정보 저장
   - validatorRegistrations[systemConfig][validator] 생성/업데이트
   - validatorPools[systemConfig].validators.push()

5. 활성화: isActive = true
```

**재등록 (자동 제거 후)**:

검증자가 담보금 부족으로 자동 제거(`isActive = false`)된 경우:

```
1. 담보금 보충
   - DepositManager.deposit()로 D_min 이상 예치

2. 재등록
   - RAT.registerValidator(systemConfig) 호출
   - isActive = false 상태이므로 재등록 가능
   - D_min 이상이면 다시 활성화

주의사항:
- 진행 중인 RAT 테스트가 있어도 재등록 가능
  (담보금이 coinage에 있으므로 슬래싱 처리 가능)
- V3: 검증자 보상은 ValidatorReward 컨트랙트에서 별도 관리
```

---

### 5.2 triggerAttentionTest

RAT 테스트를 트리거합니다.

```solidity
function triggerAttentionTest(
    address gameAddress,
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | DisputeGameFactory |
| **트리거 확률** | π_a (ratTriggerProbability) |

**동작 흐름**:
```
1. 권한 검증: L1BridgeRegistry에서 factory 확인
2. 확률 체크: hash(blockHash) % MAX < π_a
3. 검증자 랜덤 선택
4. C_off 선차감: 검증자 coinage에서 C_off를 RAT 컨트랙트로 전송 (스테이킹 금액 감소)
5. 마감 시간 설정: deadline = block.timestamp + evidenceSubmissionPeriod
6. relaxedValidatorCheck에 따라 C_off 또는 D_min 미만 시 비활성화
7. 이벤트: AttentionTestTriggered
```

---

### 5.4 submitEvidence

RAT 증거를 제출합니다.

```solidity
function submitEvidence(
    address systemConfig,
    uint32 batchIndex,
    bytes calldata evidence
) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 선택된 검증자 |
| **기한** | evidenceSubmissionPeriod 내 |

**동작 흐름**:
```
1. 검증자 확인: test.validatorAddress == msg.sender
2. 상태 확인: status == EvidencePeriod
3. 기한 확인: block.timestamp <= deadline
4. 증거 검증
5. 담보금 복구: RAT 컨트랙트에서 검증자에게 C_off 반환 (스테이킹 금액 복구)
6. 자동 재활성화 시도:
   - isActive=false이고 담보금이 임계값 이상이면 자동 재활성화
   - 임계값: relaxedValidatorCheck ? C_off : D_min
7. 이벤트: EvidenceSubmitted (재활성화 시 ValidatorReactivated 추가 발생)
```

---

### 5.5 resolveClaim

챌린지 승리 시 담보금을 복구합니다.

```solidity
function resolveClaim(address _claimant) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | FaultDisputeGame |
| **용도** | 챌린저(검증자)가 게임에서 승리했을 때 담보금 복구 |

**동작 흐름**:
```
1. msg.sender(게임 주소)로 testId 조회
2. 선택된 검증자 == _claimant 확인
3. 담보금 복구: RAT 컨트랙트에서 검증자에게 C_off 반환 (스테이킹 금액 복구)
4. 자동 재활성화 시도:
   - isActive=false이고 담보금이 임계값 이상이면 자동 재활성화
   - 임계값: relaxedValidatorCheck ? C_off : D_min
5. 이벤트: BondRestored (재활성화 시 ValidatorReactivated 추가 발생)
```

---

### 5.6 deactivateValidator

검증자를 탈퇴시킵니다.

```solidity
function deactivateValidator(address systemConfig) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 검증자 본인 |
| **출금** | DepositManager.requestWithdrawal() 사용 |

**동작 흐름**:
```
1. 활성 상태 확인
2. RAT 테스트 대기 확인: block.timestamp >= latestTestDeadline
3. 미응답 RAT 테스트 C_off 몰수 처리
4. 비활성화: isActive = false
5. 이벤트: ValidatorDeactivated

스테이킹 출금은 별도로 DepositManager.requestWithdrawal() 사용
```

---

### 5.7 조회 함수

```solidity
// 최소 담보금 계산
function getMinimumCollateral() external view returns (uint256)
// 반환: slashingPenalty + validatorBuffer

// L2별 검증자 목록 조회
function getL2Validators(address systemConfig) external view returns (address[] memory)

// 검증자 활성 상태 확인
function isValidatorActive(address validator, address systemConfig) external view returns (bool)

// 활성 검증자 수 조회
function getActiveValidatorCount(address systemConfig) external view returns (uint256)

// 검증자 등록 정보 조회
function getValidatorRegistration(address validator, address systemConfig)
    external view returns (uint256 depositedAmount, uint256 totalBondForRAT, uint32 validatorIndex, bool isActive)
```

---

### 5.13 D_min 계산 공식

검증자 최소 담보금 D_min은 동적으로 계산됩니다.

**기본 공식**:

```
C_off = max(slashingPenalty, (c_m × N × RAY) / π_a)
D_min = C_off + validatorBuffer

여기서:
slashingPenalty = 슬래싱 페널티 (기본값)
c_m = attentionCost (모니터링 비용)
N = 검증자 수 (최소 1)
π_a = ratTriggerProbability (RAT 트리거 확률)
validatorBuffer = 검증자 버퍼
```

**예시 계산**:

```
slashingPenalty = 100e27 WTON
attentionCost = 150e27 WTON
N = 3 (검증자 3명)
π_a = 1e27 (100%)
validatorBuffer = 100e27 WTON

→ C_off = max(100e27, (150e27 × 3 × 1e27) / 1e27) 
        = max(100e27, 450e27) 
        = 450e27 WTON

→ D_min = 450e27 + 100e27 = 550e27 WTON
```

**검증자 수 증가 효과**:
- N이 증가하면 C_off도 증가 (동적)
- 더 많은 검증자 → 더 높은 D_min 요구

---

### 5.14 relaxedValidatorCheck 플래그

검증자 유효성 체크 모드를 제어합니다.

| 모드 | relaxedValidatorCheck | C_off 계산 | 용도 |
|------|----------------------|-----------|------|
| **완화 모드** | `true` | `C_off = slashingPenalty` (고정) | 초기 네트워크, 검증자 유치 |
| **엄격 모드** | `false` | `C_off = max(slashingPenalty, formula)` (동적) | 안정적 네트워크, 보안 우선 |

**함수별 차이**:

1. **getDynamicMinimumCollateral(systemConfig)**
   - **항상** 동적 공식 사용 (relaxedCheck 무시)
   - 실제 게임 이론 기반 최소값 조회
   - 용도: 파라미터 조정 시 참고

2. **getCoffWithRelaxedCheck(systemConfig)**
   - relaxedCheck 플래그에 따라 다름
   - `true`: `slashingPenalty` 반환 (고정)
   - `false`: 동적 공식 사용
   - 용도: 실제 검증자 유효성 체크

**거버넌스 설정**:

```solidity
// 완화 모드 (초기 네트워크)
rat.setRelaxedValidatorCheck(true);
rat.setSlashingPenalty(100e27);  // 고정값만 사용

// 엄격 모드 (안정적 네트워크)
rat.setRelaxedValidatorCheck(false);
rat.setAttentionCost(150e27);     // 동적 공식 활성화
rat.setRatTriggerProbability(1e27);
```

**주의사항**:
- `onWithdraw()` 체크는 **항상 pure D_min 사용** (보안 우선)
- `triggerAttentionTest()` 제거 기준은 relaxedCheck에 따름:
  - `true`: 제거 기준 = C_off (완화)
  - `false`: 제거 기준 = D_min (엄격)

---

## 6. ValidatorReward 함수

### 6.1 distributeL2Rewards

L2별 검증자 보상을 분배합니다.

```solidity
function distributeL2Rewards(address systemConfig, uint256 amount) external onlySeigManager
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | SeigManager |
| **접근 제어** | `onlySeigManager` |
| **가스 복잡도** | O(1) - 검증자 수와 무관 |

**동작 흐름**:
```
1. RAT.getActiveValidatorCount(systemConfig) 조회
2. |V_i| = 0인 경우:
   └─► WTON.transfer(seigManager.dao(), amount)
       └─► 이벤트: RewardToDAO

3. |V_i| > 0인 경우:
   └─► perValidator = amount / activeCount
   └─► rewardPerValidator[systemConfig] += perValidator (O(1) 누적)
   └─► 이벤트: L2RewardDistributed
```

**RewardPerValidator 패턴**:
- O(1) 복잡도: 검증자별 순회 없이 전역 누적값만 업데이트
- L2별 보상 추적은 이벤트(`ValidatorRewardReceived`)를 통해 수행
- 검증자 없을 때 `seigManager.dao()`로 전송

---

### 6.2 claimAllRewards

모든 L2에서 받은 보상을 청구합니다.

```solidity
function claimAllRewards() external ifFree
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 검증자 |
| **가스 복잡도** | O(L) - 검증자가 등록된 L2 수에 비례 |
| **주의** | 등록된 L2가 많으면 가스 한도 초과 가능 → `claimRewardsByL2s` 사용 권장 |

**동작 흐름**:
```
1. _syncAllRewards(validator): 모든 L2 보상 동기화
   └─► 각 L2에 대해:
       - earned = rewardPerValidator[systemConfig] - validatorRewardDebt[validator][systemConfig]
       - 활성 검증자인 경우에만 validatorPendingRewards[validator] += earned
       - validatorRewardDebt[validator][systemConfig] = rewardPerValidator[systemConfig]
       - 이벤트: ValidatorRewardReceived (각 L2)

2. total = validatorPendingRewards[msg.sender]
3. validatorPendingRewards[msg.sender] = 0
4. WTON.transfer(msg.sender, total)
5. 이벤트: RewardsClaimed
```

---

### 6.2.1 claimRewardsByL2s

특정 L2들에서 받은 보상을 청구합니다 (가스 최적화용).

```solidity
function claimRewardsByL2s(address[] calldata systemConfigs) external ifFree
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 검증자 |
| **가스 복잡도** | O(N) - 지정된 L2 수에 비례 |
| **용도** | 등록된 L2가 많을 때 배치로 청구 |

**동작 흐름**:
```
1. 지정된 L2들만 보상 동기화
   └─► 각 systemConfig에 대해:
       - isValidatorInL2[validator][systemConfig] 확인
       - 등록된 L2만 _syncReward 호출

2. total = validatorPendingRewards[msg.sender]
3. validatorPendingRewards[msg.sender] = 0
4. WTON.transfer(msg.sender, total)
5. 이벤트: RewardsClaimed
```

**사용 예시** (100개 L2 등록 시):
```solidity
// 배치 1: 처음 50개 L2 청구
address[] memory batch1 = new address[](50);
// ... batch1 배열 설정
validatorReward.claimRewardsByL2s(batch1);

// 배치 2: 나머지 50개 L2 청구
address[] memory batch2 = new address[](50);
// ... batch2 배열 설정
validatorReward.claimRewardsByL2s(batch2);
```

**지연 계산 (Lazy Evaluation)**:
- 보상은 분배 시점이 아닌 청구 시점에 계산됨
- 비활성화된 검증자는 보상을 받지 않음

---

### 6.3 registerValidatorToL2

검증자를 L2에 등록합니다 (RAT에서 호출).

```solidity
function registerValidatorToL2(address validator, address systemConfig) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | RAT 컨트랙트 |
| **접근 제어** | `msg.sender == ratContract` |

**동작 흐름**:
```
1. 이미 등록된 경우 스킵
2. validatorL2List[validator].push(systemConfig)
3. isValidatorInL2[validator][systemConfig] = true
4. validatorRewardDebt[validator][systemConfig] = rewardPerValidator[systemConfig]
5. 이벤트: ValidatorRegisteredToL2
```

---

### 6.4 syncValidatorReward / resetValidatorDebt

검증자 비활성화/재활성화 시 보상 동기화를 처리합니다.

```solidity
function syncValidatorReward(address validator, address systemConfig) external
function resetValidatorDebt(address validator, address systemConfig) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | RAT 컨트랙트 |
| **접근 제어** | `msg.sender == ratContract` |

**syncValidatorReward** (비활성화 전):
- 현재까지의 보상을 `validatorPendingRewards`에 누적
- 비활성화되어도 누적된 보상은 청구 가능

**resetValidatorDebt** (재활성화 시):
- `validatorRewardDebt`를 현재 `rewardPerValidator`로 리셋
- 비활성화 기간 동안의 보상을 받지 않도록 처리

---

### 6.5 조회 함수

```solidity
// 총 청구 가능 보상 조회 (미동기화 보상 포함)
function getClaimableRewards(address validator) external view returns (uint256 total)

// 총 미청구 보상 조회 (동기화된 것만)
function getPendingRewards(address validator) external view returns (uint256)

// L2별 미청구 보상 조회 (이벤트 사용 권장)
function getPendingRewardsByL2(address validator, address systemConfig)
    external pure returns (uint256)  // 항상 0 반환
```

**권장 사용법**:
- 총 보상 조회: `getClaimableRewards(validator)`
- L2별 보상 추적: `ValidatorRewardReceived` 이벤트 구독

---

### 6.6 검증자 재등록 메커니즘

검증자가 비활성화 후 재등록할 때의 보상 처리 메커니즘입니다.

**6.6.1 비활성화 시**

```
1. RAT.deactivateValidator() 호출 (자발적 탈퇴)
   또는
   RAT.triggerAttentionTest() 자동 제거 (담보금 부족)
   ↓
2. RAT → ValidatorReward.syncValidatorReward(validator, systemConfig)
   ↓
3. 현재까지 누적 보상 저장:
   validatorPendingRewards[validator] += (earned - debt)
   ↓
4. isActive = false 설정
```

**6.6.2 비활성화 기간**

```
- 새 보상 분배 시 분배 대상에서 제외됨
- isActive = false이므로 activeValidatorCount에 포함되지 않음
- 분배량 = totalAmount / activeValidatorCount (비활성 검증자 제외)
- 비활성 검증자는 받지 못하고, 활성 검증자들만 나눠 받음
```

**6.6.3 재등록 시**

```
1. 담보금 보충: DepositManager.deposit()로 D_min 이상 예치
   ↓
2. RAT.registerValidator(systemConfig) 호출 (재등록)
   ↓
3. RAT → ValidatorReward.resetValidatorDebt(validator, systemConfig)
   ↓
4. debt[validator][systemConfig] = rewardPerValidator[systemConfig]
   (현재 시점으로 debt 리셋)
   ↓
5. isActive = true 설정
```

**6.6.4 재등록 후**

```
- 기존 동기화된 보상(3단계 저장분)만 청구 가능
- 비활성화 기간에는 분배 대상에서 제외되어 받지 못함 (활성 검증자들이 나눠 받음)
- 재등록 시점 이후 새 보상부터 다시 받음
```

**예시**:

```solidity
// 1. 검증자 등록 → 보상 1000 분배 → 청구 가능: 1000

// 2. 검증자 비활성화 (syncValidatorReward 호출)
//    → validatorPendingRewards[validator] = 1000

// 3. 비활성화 기간 → 보상 2000 분배
//    → 비활성이므로 분배 대상 제외 (활성 검증자들이 나눠 받음)
//    → validator1 청구 가능: 1000 (그대로)

// 4. 검증자 재등록 (resetValidatorDebt 호출)
//    → debt = 현재 rewardPerValidator(3000)로 리셋
//    → 청구 가능: 1000 (그대로)

// 5. 재등록 후 보상 500 분배
//    → rewardPerValidator = 3500
//    → earned = 3500 - 3000 = 500
//    → 청구 가능: 1000 + 500 = 1500
```

**참고**: 비활성화 기간의 보상(2000)은 validator1에게 분배되지 않고, 활성 검증자들이 나눠 받았음.

---

### 6.7 비활성 검증자 제외 메커니즘

보상 분배 시 비활성 검증자는 자동으로 제외됩니다.

```solidity
// distributeL2Rewards() 내부
activeValidatorCount = RAT.getActiveValidatorCount(systemConfig)
perValidator = totalAmount / activeValidatorCount  // 비활성 제외

// 예시:
// 총 검증자: 5명
// 활성 검증자: 3명 (2명 비활성)
// 보상: 1000 WTON
// → perValidator = 1000 / 3 = 333.33 WTON (활성 검증자만)
```

**효과**:
- 비활성 검증자는 보상 0
- 활성 검증자들이 더 많은 보상 받음
- 검증자 참여 인센티브 강화

---

### 6.8 검증자 없을 때 DAO 전송

검증자가 0명이면 전체 검증자 보상이 DAO Treasury로 전송됩니다.

```solidity
if (activeValidatorCount == 0) {
    address daoVault = ISeigManager(seigManager).dao();
    WTON.transfer(daoVault, amount);
    emit RewardToDAO(systemConfig, amount);
    return;
}
```

**이벤트**:
```solidity
event RewardToDAO(
    address indexed systemConfig,
    uint256 amount
);
```

---

## 7. SeigManager 시퀀서 슬래싱 함수

### 7.1 slashSequencerByGame

시퀀서를 슬래싱합니다 (Permissionless). V3에서는 SeigManager에서 처리합니다.

```solidity
function slashSequencerByGame(address gameAddress) external whenV3Active whenNotPaused
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 |
| **조건** | 게임이 DEFENDER_WINS가 아닌 상태로 종료 |

**동작 흐름**:
```
1. DisputeGameFactory 검증 (가짜 게임 방지)
2. 게임 상태 확인: status != DEFENDER_WINS
3. 시퀀서 전체 스테이킹 금액 몰수 (coinage.burnFrom)
4. 챌린저 보상 계산: C_max + Δ/n
5. 챌린저 보상 지급 (WTON.mint)
6. 나머지: DAO Treasury
7. 이벤트: SequencerSlashed
```

> **V3 변경사항**: 시퀀서 담보금은 기존 스테이킹 시스템(coinage)을 사용합니다.

---

## 8. OperatorManagerFactory 함수

### 8.1 createOperatorManager

오퍼레이터 매니저를 생성합니다.

```solidity
function createOperatorManager(address rollupConfig) external returns (address operatorManager)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Layer2Manager만 |
| **구현체** | V1_1 (기본, TYPE 3 업그레이드시 V1_2로 수동 업그레이드) |

**동작 흐름**:
```
1. msg.sender == layer2Manager 확인
2. rollupConfig의 unsafeBlockSigner() → sManager 조회
3. CREATE2로 OperatorManagerProxy 생성
4. upgradeTo(operatorManagerImp), setAddresses() 호출
5. transferManager(sManager), transferOwnership(sOwner)
```

---

### 8.2 getAddress

오퍼레이터 매니저 주소를 계산합니다.

```solidity
function getAddress(address rollupConfig) public view returns (address)
```

| 항목 | 내용 |
|------|------|
| **용도** | CREATE2 주소 계산 |

---

### 8.3 설정 함수

```solidity
// 구현체 변경
function changeOperatorManagerImp(address newOperatorManagerImp) external onlyOwner

// 주소 설정
function setAddresses(address _depositManager, address _ton, address _wton, address _layer2Manager) external onlyOwner
```

---

### 8.4 TYPE 3 업그레이드 절차

TYPE 1/2 롤업이 DisputeGame을 도입하여 TYPE 3로 업그레이드하려면:

```
1. L1BridgeRegistry.upgradeToType3(rollupConfig)
   └── DisputeGameFactory 확인 및 등록
   └── rollupType = 3으로 변경

2. OperatorManagerProxy.upgradeTo(V1_2 impl)
   └── owner가 직접 호출
   └── TYPE 3 기능 활성화
```

---

## 9. 거버넌스 파라미터 요약

### 9.1 SeigManager 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|---------|------|------|------|
| `daoDistributionRatio` | `setDaoDistributionRatio(d)` | 0 < d < 1 | RAY |
| `minStakingRatio` | `setMinStakingRatio(θ)` | 0 < θ ≤ 1 | RAY |
| `validatorDistributionRatio` | `setValidatorDistributionRatio(α)` | 0 < α < 1 | RAY |
| `halfSaturationPoint` | `setHalfSaturationPoint(k)` | k > 0 | RAY (TON) |

### 9.2 RAT 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|---------|------|------|------|
| `slashingPenalty` | `setSlashingPenalty(C_off)` | C_off > 0 | TON |
| `validatorBuffer` | `setValidatorBuffer(Δ)` | Δ ≥ 0 | TON |
| `ratTriggerProbability` | `setRatTriggerProbability(π_a)` | 0 < π_a ≤ 1 | RAY |
| `minimumThreshold` | `setMinimumThreshold(D_min)` | D_min > 0 | TON |
| `evidenceSubmissionPeriod` | `setEvidenceSubmissionPeriod(t)` | t > 0 | 초 |
| `validatorReward` | `setValidatorReward(addr)` | addr != 0 | 주소 |

### 9.3 ValidatorReward 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|---------|------|------|------|
| `seigManager` | `setSeigManager(addr)` | addr != 0 | 주소 |
| `ratContract` | `setRatContract(addr)` | addr != 0 | 주소 |

### 9.4 SeigManager 시퀀서 슬래싱 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|---------|------|------|------|
| `maxFraudProofCost` | `setMaxFraudProofCost(C_max)` | C_max > 0 | WTON |
| `sequencerAdditionalReward` | `setSequencerAdditionalReward(Δ)` | Δ ≥ 0 | WTON |
| `maxChallengers` | `setMaxChallengers(H_max)` | H_max > 0 | 개수 |

---

## 10. 이벤트 목록

### 10.1 SeigManager 이벤트

```solidity
event V3SeigniorageDistributed(uint256 totalSeigniorage, uint256 l2MaxAllocation, uint256 totalDistributed, uint256 daoAmount, uint256 validatorPoolAmount);
event EligibilityChanged(address indexed layer2, bool eligible, uint256 bridgedTON, uint256 effectiveBridgedTON);
event V3MigrationCompleted(uint256 blockNumber, uint256 totalMigratedL2s);
event SeigGiven2(address indexed layer2, uint256 totalSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 pseig, uint256 l2TotalSeigs, uint256 layer2Seigs);
```

### 10.2 RAT 이벤트

```solidity
event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount, uint256 registrationId);
event ValidatorDeactivated(address indexed validator, address indexed systemConfig, uint256 returnedAmount);
event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline);
event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex);
event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 slashedAmount, bool removedFromSet);
event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 restoredAmount);
```

### 10.3 ValidatorReward 이벤트

```solidity
// L2별 검증자 보상 분배 이벤트 (요약)
event L2RewardDistributed(
    address indexed systemConfig,
    uint256 totalAmount,           // 총 분배 금액
    uint256 activeValidatorCount,  // 활성 검증자 수
    uint256 perValidator           // 검증자당 분배 금액
);

// 검증자별 보상 분배 이벤트 (청구 시점에 발생)
event ValidatorRewardReceived(
    address indexed validator,
    address indexed systemConfig,
    uint256 amount
);

// 검증자 없을 때 DAO 귀속 이벤트
event RewardToDAO(address indexed systemConfig, uint256 amount);

// 검증자 보상 청구 이벤트
event RewardsClaimed(address indexed validator, uint256 amount);

// 검증자 L2 등록 이벤트
event ValidatorRegisteredToL2(
    address indexed validator,
    address indexed systemConfig,
    uint256 initialDebt
);
```

### 10.4 SeigManager 시퀀서 슬래싱 이벤트

```solidity
event SequencerSlashed(address indexed layer2, address indexed gameAddress, uint256 slashedAmount, address challenger, uint256 challengerReward);
```

---

## 11. 관련 문서

- [01-system-overview.md](./01-system-overview.md): 시스템 개요
- [02-system-architecture.md](./02-system-architecture.md): 시스템 아키텍처
- [03-contract-structure.md](./03-contract-structure.md): 컨트랙트 구조
- [04-contract-roles.md](./04-contract-roles.md): 컨트랙트별 역할
- [05-actors.md](./05-actors.md): 액터 정의
