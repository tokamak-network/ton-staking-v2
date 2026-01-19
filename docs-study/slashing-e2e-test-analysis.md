# Slashing E2E Test Analysis: BasicOperatorSlashing

## 1. 개요 (Overview)
`TestSlashing_BasicOperatorSlashing` 테스트는 **Basic Operator Slashing** 시나리오를 검증하는 End-to-End 테스트입니다.
Operator가 부정한 행위(Faulty Claim)를 했다고 가정하고, Challenger가 이를 반박(Attack)하여 승리한 뒤, 최종적으로 Operator의 스테이킹 자금을 삭감(Slashing)하고 Challenger가 보상을 받는 전체 흐름을 테스트합니다.

- **테스트 파일**: `op-e2e/slashing/slashing_test.go`
- **관련 컨트랙트**: `FaultDisputeGame`, `Layer2Manager_Slashing`, `DepositManager_Slashing`, `SeigManager_Slashing`

---

## 2. 테스트 시나리오 단계 (Steps)

### Step 1: Operator 등록 (Register Operator)
*   **행위**: `Validator` 계정이 `OperatorManager`를 생성하고 초기 보증금(`1,000,000 TON`)을 입금하여 `CandidateAddOn`을 등록합니다.
*   **중요 포인트**:
    *   입금은 `OperatorManager` 컨트랙트 주소 명의로 `DepositManager`에 기록됩니다.
    *   `registercandidateAddOn` 내부에서 `TON` -> `WTON` 변환(`x 1e9`)이 일어납니다.

### Step 2: Dispute Game 생성 및 공격 (Setup & Attack)
*   **행위**: `Challenger`가 `FaultDisputeGame`을 생성하고, Root Claim에 대해 `Attack`을 수행합니다.
*   **상태**: 게임 생성 시 `rootClaim`과 `extraData`(Block Number)가 기록됩니다.

### Step 3: 시간 경과 (Advance Clock)
*   **행위**: `MaxClockDuration` (약 3.5일) 이상의 시간을 강제로 진행시킵니다 (`frees.IncreaseTime`).
*   **이유**: 게임을 종료(Resolve)하려면 챌린지 기간이 만료되어야 하기 때문입니다.

### Step 4: 게임 종료 (Resolve)
*   **행위**: `ResolveClaim`을 호출하여 서브게임을 확정하고, `Resolve`를 호출하여 최종 게임 승패를 결정합니다.
*   **결과**: `CHALLENGER_WINS` (Enum Value: `1`).

### Step 5: 슬래싱 실행 (Execute Slashing)
*   **행위**: Challenger가 `Layer2Manager.slashingCandidate`를 호출합니다.
*   **로직**:
    1.  `DisputeGameFactory`에서 해당 게임이 유효한지 검증 (`rootClaim`, `extraData` 키 사용).
    2.  게임 승자가 `Challenger`인지 확인.
    3.  `DepositManager.slash` 호출 -> `SeigManager`에 `onSlash` 요청 -> 자금 소각.

### Step 6: 결과 검증 (Verify Results)
*   **Operator Stake**: `OperatorManager` 주소의 `AccStaked`가 `0`이 되었는지 확인.
*   **Challenger Reward**: Challenger가 삭감된 금액의 10%를 `WTON`으로 수령했는지 확인.

---

## 3. 주요 디버깅 이슈 및 해결 (Troubleshooting)

이번 테스트를 성공시키기 위해 해결했던 주요 기술적 이슈들입니다.

### 🛑 Issue 1: `ResolveClaim` Revert (Auth Reuse)
*   **현상**: `ResolveClaim` 호출 시 `EvmError: Revert` 발생.
*   **원인**: `Attack` 단계에서 사용한 `TransactOpts` (`challengerAuth`) 객체를 그대로 재사용했는데, 여기에 `Value` (Bond Amount)가 설정되어 있었습니다. `ResolveClaim`은 `non-payable` 함수라 `Value`가 있으면 리버트됩니다.
*   **해결**: `ResolveClaim` 호출 전 `auth.Value = big.NewInt(0)`으로 명시적 초기화.

### 🛑 Issue 2: Game Status Mismatch (Enum Value)
*   **현상**: `Expected: 2 (DEFENDER_WINS)`, `Actual: 1 (CHALLENGER_WINS)` 에러 발생으로 혼동.
*   **원인**: `Optimism`의 `GameStatus` Enum 정의 오해.
    *   `0: IN_PROGRESS`
    *   `1: CHALLENGER_WINS` (우리가 원하는 결과)
    *   `2: DEFENDER_WINS`
*   **해결**: 테스트 기대값을 `1`로 수정.

### 🛑 Issue 3: `wrong dispute game Address` Revert
*   **현상**: `Review` 단계에서 `Layer2Manager`가 "잘못된 게임 주소"라며 리버트.
*   **원인**: `slashingCandidate` 호출 시 넘겨준 `extraData` (Block Number bytes)가 게임 생성 시 사용된 값과 일치하지 않았음. `DisputeGameFactory`는 `(GameType, RootClaim, ExtraData)`를 키로 사용하여 게임 주소를 찾기 때문에, 하나라도 다르면 주소를 못 찾습니다.
*   **해결**: `createDisputeGame`에서 사용한 `testL2BlockNumber(100)`를 패딩하여 정확한 `extraData`를 전달.

### 🛑 Issue 4: Operator Stake Not Slashed (Verification Target)
*   **현상**: 슬래싱 트랜잭션은 성공했으나, `StakeOf` 조회 결과 잔액이 그대로(`10^24`)임.
*   **원인**: **검증 대상 주소 오류**.
    *   테스트 코드에서 `Validator EOA` 주소로 잔액을 확인했습니다.
    *   하지만 실제 슬래싱 대상은 `OperatorManager` (Initial Deposit 주체)였습니다. `Validator EOA`의 추가 입금분은 슬래싱 대상이 아니었습니다.
*   **해결**: `OperatorManager` 주소의 `AccStaked`를 조회하도록 수정하여 `0`임을 확인.

### 🛑 Issue 5: Reward Amount Mismatch (Unit Conversion)
*   **현상**: 예상 보상액(`5000 WTON`)과 실제 보상액(`10^32 WTON`)이 불일치.
*   **원인**: `TON` vs `WTON` 단위 혼동.
    *   테스트 입력 `depositAmount`는 `TON` 단위(18 decimals)입니다.
    *   `Layer2Manager`는 이를 `WTON` (27 decimals)으로 변환하여 입금하므로 `x 1e9`가 적용됩니다.
    *   실제 슬래싱 된 금액은 `1,000,000 * 10^18 * 10^9 = 10^33` (Wei -> Ray 변환).
    *   보상은 이의 10%인 `10^32`.
*   **해결**: 예상 보상 계산 식에 `x 1e9`를 추가하여 단위를 맞춤.

---

## 4. 결론 (Conclusion)
이 테스트는 **OperatorManager** 단위의 슬래싱이 정상 작동함을 입증했습니다.
*   `FaultDisputeGame`의 승패가 슬래싱 로직에 올바르게 연동됩니다.
*   `DepositManager`와 `SeigManager` 간의 자금 소각 및 보상 분배가 정확한 비율로 실행됩니다.
*   **주의**: 테스트 작성 시 `EOA`와 `OperatorManager` 간의 주체 구분을 명확히 해야 하며, `TON`과 `WTON`의 Decimals 차이를 항상 고려해야 합니다.

---

## 5. 테스트 실행 방법 (How to Run)

### 사전 준비 (Prerequisites)
테스트를 실행하기 전에 오프라인에서 Genesis 파일을 생성해야 합니다. (최초 1회 실행)
```bash
make devnet-allocs-offline
```

### 개별 테스트 실행 (Individual Test)
`TestSlashing_BasicOperatorSlashing` 테스트 시나리오만 단독으로 실행합니다. (빠름)

```bash
cd op-e2e
# GOWORK=off is recommended to avoid dependency conflicts
GOWORK=off go test -v -run TestSlashing_BasicOperatorSlashing ./slashing/...
```

### Slashing 패키지 테스트 실행 (Slashing Suite)
`slashing` 패키지의 모든 통합 테스트를 실행합니다.

```bash
cd op-e2e
GOWORK=off go test -v ./slashing/...
```

### FaultProofs 패키지 테스트 실행 (FaultProofs Suite)
`faultproofs` 패키지의 테스트(RAT Challenge 등)만 실행합니다.

```bash
cd op-e2e
GOWORK=off go test -v ./faultproofs/...
```

### 전체 E2E 테스트 실행 (Full Suite)
`faultproofs`와 `slashing` 모든 패키지의 테스트를 실행하려면 `Makefile` 명령어를 사용하세요.

```bash
make test-e2e
```
(이 명령어는 내부적으로 `go test -v ./faultproofs/... ./slashing/...`을 실행합니다.)
