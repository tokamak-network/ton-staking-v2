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
eligible = (S_i ≥ θ × B_i)

여기서:
- S_i = SequencerVault.getSequencerDepositByLayer2(layer2)
- θ = minStakingRatio
- B_i = Layer2Manager.getBridgedTONByLayer(layer2)
```

---

### 1.3 onBridgedTONChange

Bridged TON 변경 시 자격을 재평가합니다 (Type 3 전용).

```solidity
function onBridgedTONChange() external onlyMigrated
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | OptimismPortal (Type 3) |
| **접근 제어** | `onlyMigrated` (V3 모드에서만) |
| **동작** | Early return 패턴 (revert 하지 않음) |

**동작 흐름**:
```
1. L1BridgeRegistry.rollupConfigWithPortal(msg.sender) → rollupConfig 조회
   ├─ 등록되지 않은 포탈 → early return
   └─ Type 3 아님 → early return

2. Layer2Manager.getLayer2BySystemConfig(rollupConfig) → layer2 조회
   └─ 등록되지 않은 L2 → early return

3. _updateEligibilityInternal(layer2)
   ├─ 자격 재평가 (S_i ≥ θ × B_i)
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

// SequencerVault 컨트랙트 주소 설정
function setSequencerVault(address vault) external onlyOwner
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
4. SeigManager.onStakingChange(layer2) ← V3 추가
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

## 5. RAT 함수

### 5.1 registerValidator

검증자를 등록합니다.

```solidity
function registerValidator(address systemConfig, uint256 depositAmount) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 검증자 |
| **최소 담보금** | C_off + Δ_validator |

**동작 흐름**:
```
1. TON.transferFrom(msg.sender, this, depositAmount)
2. 등록 정보 저장
   - validatorRegistrations[systemConfig][validator] 생성
   - validatorPools[systemConfig].validators.push()
3. 활성화: isActive = true
```

---

### 5.2 onApprove

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
| **호출 주체** | TON 컨트랙트 (TON.approveAndCall 경유) |
| **data 형식** | systemConfig 주소 (32바이트) |

**동작 흐름**:
```
1. msg.sender == ton 검증
2. data에서 systemConfig 추출
3. _registerValidatorInternal(owner, systemConfig, amount)
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
4. C_off 선차감
   - depositedAmount -= C_off
   - totalBondForRAT += C_off
5. 마감 시간 설정: deadline = block.timestamp + evidenceSubmissionPeriod
6. D_min 미만 시 비활성화
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
2. 상태 확인: status == Pending
3. 기한 확인: block.timestamp <= deadline
4. 증거 검증
5. 담보금 복구
   - depositedAmount += C_off
   - totalBondForRAT -= C_off
6. 비활성 상태였으면 재활성화 (D_min 이상 시)
7. 이벤트: EvidenceSubmitted
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
3. 담보금 복구
   - depositedAmount += C_off
   - totalBondForRAT -= C_off
4. 비활성 상태였으면 재활성화 (D_min 이상 시)
5. 이벤트: BondRestored
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
| **출금** | 즉시 (RAT 테스트 대기 중이면 마감 후) |

**동작 흐름**:
```
1. 활성 상태 확인
2. RAT 테스트 대기 확인: block.timestamp >= latestTestDeadline
3. 미응답 RAT 테스트 슬래싱 처리
   - accumulatedSlashings += totalBondForRAT
4. 비활성화: isActive = false
5. TON 반환: TON.transfer(msg.sender, depositedAmount)
6. 이벤트: ValidatorDeactivated
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

## 7. SequencerVault 함수

### 7.1 registerSequencer

시퀀서를 등록합니다.

```solidity
function registerSequencer(address systemConfig, uint256 depositAmount) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 (제3자 펀딩 가능) |
| **최소 담보금** | max(θ × B_i, H_max × C_max + Δ_sequencer) |

**동작 흐름**:
```
1. Layer2Manager.getLayer2BySystemConfig(systemConfig) → layer2, operator 조회
2. TON.transferFrom(msg.sender, this, depositAmount)
3. 등록 정보 저장
   - sequencerDeposits[systemConfig] = {operator, layer2, depositAmount, 0, true}
   - layer2ToSystemConfig[layer2] = systemConfig
4. 이벤트: SequencerRegistered
```

---

### 7.2 slashSequencerByGame

시퀀서를 슬래싱합니다 (Permissionless).

```solidity
function slashSequencerByGame(address gameAddress) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 |
| **조건** | 게임이 DEFENDER_WINS가 아닌 상태로 종료 |

**동작 흐름**:
```
1. DisputeGameFactory 검증 (가짜 게임 방지)
2. 게임 상태 확인: status != DEFENDER_WINS
3. 시퀀서 담보금 슬래싱
4. 챌린저 보상 계산: C_max + Δ/n
5. 챌린저 보상 누적
6. 나머지: accumulatedSlashings += 잔여분
7. 시퀀서 비활성화
8. 이벤트: SequencerSlashed
```

---

### 7.3 deactivateSequencer

시퀀서를 탈퇴시킵니다.

```solidity
function deactivateSequencer(address systemConfig) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | OperatorManager만 |

**동작 흐름**:
```
1. deposit.operator == msg.sender 확인
2. TON.transfer(msg.sender, depositedAmount)
3. 비활성화: isActive = false
4. 이벤트: SequencerDeactivated
```

---

### 7.4 조회 함수

```solidity
// 담보금 조회 (systemConfig 기준)
function getSequencerDeposit(address systemConfig) external view returns (uint256)

// 담보금 조회 (layer2 기준) - SeigManager에서 사용
function getSequencerDepositByLayer2(address layer2) external view returns (uint256)

// 활성 상태 확인
function isSequencerActive(address systemConfig) external view returns (bool)
function isSequencerActiveByLayer2(address layer2) external view returns (bool)

// 최소 담보금 계산 (백서 기반 해석)
function getMinimumCollateral(uint256 bridgedTON) external view returns (uint256)
// 반환: max(θ × bridgedTON, H_max × C_max + Δ_sequencer)

// 시퀀서 정보 조회
function getSequencerInfo(address systemConfig)
    external view returns (address operator, address layer2, uint256 depositedAmount, uint256 slashedAmount, bool isActive)
```

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

### 8.4 syncSequencerVault

Layer2Manager에서 SequencerVault 주소를 조회하여 로컬에 설정합니다.

```solidity
function syncSequencerVault() external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 |
| **조건** | Layer2Manager.sequencerVault()가 address(0)이 아니어야 함 |
| **조건** | 현재 저장된 값과 다른 값이어야 함 |

**동작 흐름**:
```
1. Layer2Manager.sequencerVault() 조회
2. address(0) 체크 → ZeroAddressError
3. 현재 값과 동일 체크 → SameAddressError
4. 로컬 스토리지에 저장
5. 이벤트: SequencerVaultSet
```

---

### 8.5 TYPE 3 업그레이드 절차

TYPE 1/2 롤업이 DisputeGame을 도입하여 TYPE 3로 업그레이드하려면:

```
1. L1BridgeRegistry.upgradeToType3(rollupConfig)
   └── DisputeGameFactory 확인 및 등록
   └── rollupType = 3으로 변경

2. OperatorManagerProxy.upgradeTo(V1_2 impl)
   └── owner가 직접 호출
   └── SequencerVault 연동 기능 활성화

3. OperatorManagerV1_2.syncSequencerVault()
   └── 누구나 호출 가능
   └── Layer2Manager에서 SequencerVault 주소 자동 조회
```

> **참고**: `_getSequencerVault()` 내부 함수는 로컬 스토리지에 값이 없으면 Layer2Manager에서 자동으로 조회하므로, `syncSequencerVault()` 호출은 선택사항입니다.

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

### 9.3 SequencerVault 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|---------|------|------|------|
| `minimumStakingRatio` | `setMinimumStakingRatio(θ)` | 0 < θ ≤ 1 | RAY |
| `maxFraudProofCost` | `setMaxFraudProofCost(C_max)` | C_max > 0 | TON |
| `sequencerAdditionalReward` | `setSequencerAdditionalReward(Δ)` | Δ ≥ 0 | TON |
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

### 10.4 SequencerVault 이벤트

```solidity
event SequencerRegistered(address indexed operator, address indexed systemConfig, address layer2, uint256 depositAmount);
event SequencerDeactivated(address indexed sequencer, address indexed systemConfig, uint256 returnedAmount);
event DepositAdded(address indexed sequencer, address indexed systemConfig, uint256 amount);
event SequencerSlashed(address indexed sequencer, address indexed systemConfig, address indexed gameAddress, uint256 slashedAmount, address challenger, uint256 challengerReward);
event SlashingsWithdrawnToTreasury(address indexed treasury, uint256 amount);
event ChallengerRewardClaimed(address indexed challenger, uint256 amount);
```

---

## 11. 관련 문서

- [01-system-overview.md](./01-system-overview.md): 시스템 개요
- [02-system-architecture.md](./02-system-architecture.md): 시스템 아키텍처
- [03-contract-structure.md](./03-contract-structure.md): 컨트랙트 구조
- [04-contract-roles.md](./04-contract-roles.md): 컨트랙트별 역할
- [05-actors.md](./05-actors.md): 액터 정의
