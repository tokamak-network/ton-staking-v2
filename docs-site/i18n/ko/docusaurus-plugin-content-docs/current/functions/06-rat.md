---
id: functions-rat
sidebar_position: 6
---

# RAT 함수

밸리데이터 등록 및 Randomized Attention Test(RAT) 함수입니다.

## registerValidator

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

## triggerAttentionTest

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

## submitEvidence

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

## resolveClaim

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

## deactivateValidator

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

## 조회 함수

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

## D_min 계산 공식

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

## relaxedValidatorCheck 플래그

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
