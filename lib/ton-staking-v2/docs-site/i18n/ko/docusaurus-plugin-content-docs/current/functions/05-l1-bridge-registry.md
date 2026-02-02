---
id: functions-l1-bridge-registry
sidebar_position: 5
---

# L1BridgeRegistry 함수

브릿지/포털 등록 및 TVL 조회 함수입니다.

## layer2Tvl

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

## rollupConfigWithPortal

Portal 주소로 rollupConfig를 역조회합니다.

```solidity
function rollupConfigWithPortal(address portal) external view returns (address rollupConfig)
```

| 항목 | 내용 |
|------|------|
| **용도** | onBridgedTonChange에서 msg.sender(Portal) → rollupConfig 조회 |

---

## setTypeRegistrant

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

## upgradeToType3

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

## registerRollupConfigByType

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

## setAddresses

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

## setSeigniorageCommittee

SeigniorageCommittee 주소를 설정합니다.

```solidity
function setSeigniorageCommittee(address _seigniorageCommittee) external onlyOwner
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Owner |
| **특이사항** | 기존과 동일한 주소 설정 불가 |

---

## rejectCandidateAddOn

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

## restoreCandidateAddOn

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

## registerRollupConfig

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

## View 함수들

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
