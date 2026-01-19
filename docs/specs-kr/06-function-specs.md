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

### 1.3 onBridgedTONChange

Bridged TON 변경 시 자격을 재평가합니다 (Type 3 전용).

```solidity
function onBridgedTONChange() external whenV3Active
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
function setRAT(address rat) external onlyOwner
```

---

### 1.7 onWithdraw

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

### 1.8 onDeposit

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

### 2.2 onApprove

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

### 2.3 requestWithdrawal

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

### 2.4 processRequest

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

### 3.1 getBridgedTON

Bridged TON을 조회합니다.

```solidity
function getBridgedTON(address rollupConfig) public view returns (uint256 bridgedTON)
function getBridgedTONByLayer(address layer2) public view returns (uint256 bridgedTON)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 |
| **조회 방식** | L1BridgeRegistry.layer2TVL() 호출 |

---

### 3.2 getLayer2BySystemConfig

SystemConfig로 Layer2 주소를 조회합니다.

```solidity
function getLayer2BySystemConfig(address systemConfig) external view returns (address layer2)
```

---

## 4. L1BridgeRegistry 함수

### 4.1 layer2TVL

L2의 TVL (Bridged TON)을 조회합니다.

```solidity
function layer2TVL(address rollupConfig) external view returns (uint256)
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
| **용도** | onBridgedTONChange에서 msg.sender(Portal) → rollupConfig 조회 |

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

### 5.2 onApprove

TON.approveAndCall 콜백입니다 (담보금 부족 시 스테이킹 예치).

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
| **호출 주체** | TON 컨트랙트 (TON.approveAndCall 경유) |
| **data 형식** | systemConfig 주소 (32바이트) |

**동작 흐름**:
```
1. msg.sender == ton 검증
2. data에서 systemConfig 추출
3. TON을 DepositManager를 통해 스테이킹 예치
4. 검증자 등록:
   - 이미 등록된 검증자인지 확인
   - stakeOf(layer2, validator) >= D_min 확인
   - N_max (최대 검증자 수) 체크
   - 검증자 정보 저장 및 활성화
```

---

### 5.3 triggerAttentionTest

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

**동작 흐름**:
```
1. RAT.getL2Validators(systemConfig) 조회
2. 활성 검증자 수 계산
3. |V_i| = 0인 경우:
   └─► WTON.transfer(treasury, amount)
       └─► 이벤트: RewardToTreasury

4. |V_i| > 0인 경우:
   └─► perValidator = amount / activeCount
       └─► 각 검증자에게 보상 누적
           - validatorPendingRewards[validator] += perValidator
           - validatorL2PendingRewards[validator][systemConfig] += perValidator
       └─► 이벤트: ValidatorRewardReceived (각 검증자)
   └─► 이벤트: L2RewardDistributed
```

---

### 6.2 claimAllRewards

모든 보상을 청구합니다.

```solidity
function claimAllRewards() external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 검증자 |

**동작 흐름**:
```
1. total = validatorPendingRewards[msg.sender]
2. validatorPendingRewards[msg.sender] = 0
3. WTON.transfer(msg.sender, total)
4. 이벤트: RewardsClaimed
```

---

### 6.3 조회 함수

```solidity
// L2별 미청구 보상 조회
function getPendingRewardsByL2(address validator, address systemConfig)
    external view returns (uint256)

// 총 미청구 보상 조회
function getTotalPendingRewards(address validator) external view returns (uint256)
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

> **V3 변경사항**: 시퀀서 담보금은 별도 SequencerVault가 아닌 기존 스테이킹 시스템(coinage)을 사용합니다.

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

### 9.3 SeigManager 시퀀서 슬래싱 파라미터

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
event L2RewardDistributed(address indexed systemConfig, uint256 distributed, uint256 validatorCount);
event ValidatorRewardReceived(address indexed validator, address indexed systemConfig, uint256 amount);
event RewardToTreasury(address indexed systemConfig, uint256 amount);
event RewardsClaimed(address indexed validator, uint256 amount);
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
