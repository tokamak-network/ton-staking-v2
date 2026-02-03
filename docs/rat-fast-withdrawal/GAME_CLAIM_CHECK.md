# RAT Fast Withdrawal - DisputeGame 클레임 체크 기능

## 개요

RAT Fast Withdrawal 시스템에 DisputeGame 클레임 체크 기능이 추가되었습니다. 이 기능은 OptimismPortal의 DisputeGame에서 클레임이 발생한 경우 Fast Withdrawal을 차단하여 보안을 강화합니다.

## 배경

Fast Withdrawal은 검증자들의 집단서명을 통해 즉시 출금을 가능하게 하는 기능입니다. 하지만 DisputeGame에 클레임이 존재하는 경우, 해당 출금 트랜잭션에 대한 분쟁이 진행 중일 수 있으므로 Fast Withdrawal을 허용해서는 안됩니다.

## 구현 내용

### 1. IDisputeGame 인터페이스 확장

**파일**: `src/validator/interfaces/IDisputeGame.sol`

```solidity
/// @title IDisputeGame
/// @notice Minimal interface for querying DisputeGame rootClaim
interface IDisputeGame {
    /// @notice Returns the root claim of this DisputeGame
    /// @return The root claim (hash of OutputRootProof)
    function rootClaim() external view returns (bytes32);

    /// @notice Returns the number of claims in this DisputeGame
    /// @return len_ The number of claims
    function claimDataLen() external view returns (uint256 len_);
}
```

### 2. FastWithdrawalInput 구조체 확장

**파일**: `src/libraries/RATFastWithdrawalLib.sol`

```solidity
struct FastWithdrawalInput {
    bytes32 withdrawalHash;
    address systemConfig;
    address gameAddress;    // 추가: DisputeGame 주소
    bytes32 stateRoot;
    uint256 validatorBitmap;
    bytes32 leafA;
    bytes32 leafB;
    bytes[] proofsA;
    bytes[] proofsB;
}
```

### 3. 새로운 에러 타입 추가

**파일**: `src/validator/RATFastWithdrawal.sol`

```solidity
error FastWithdrawalGameHasClaimsError();
```

### 4. 집단서명검증 로직에 게임 클레임 체크 추가

**파일**: `src/validator/RATFastWithdrawal.sol:337-342`

```solidity
function verifyAndExecuteFastWithdrawal(
    Types.WithdrawalTransaction calldata _tx,
    RATFastWithdrawalLib.FastWithdrawalInput calldata input,
    bytes calldata _aggregatedSignature
) external payable ifFree whenNotPaused {
    // 사전 검증 (portal 주소 반환받아 재사용)
    address portal = _validateFastWithdrawalPreconditions(input, _tx);

    // 게임 클레임 체크: DisputeGame에 클레임이 하나라도 있으면 Fast Withdrawal 불가
    if (input.gameAddress != address(0)) {
        uint256 claimCount = IDisputeGame(input.gameAddress).claimDataLen();
        if (claimCount > 0) revert FastWithdrawalGameHasClaimsError();
    }

    // 나머지 검증 로직...
}
```

## 동작 방식

### Fast Withdrawal 흐름 with 게임 클레임 체크

```
┌────────────────────────────────────────────────────────────────┐
│ 1. 사용자가 OptimismPortal2에서 출금 증명                        │
│    - proveAndRequestFastWithdrawal() 호출                       │
│    - DisputeGame 생성 및 withdrawalHash 발행                    │
└────────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────────┐
│ 2. RAT 검증자들이 L2 상태 검증                                  │
│    - stateRoot 확인                                            │
│    - Merkle proof 검증                                         │
│    - BLS 서명 생성                                             │
└────────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────────┐
│ 3. Aggregator가 집계 서명 제출                                  │
│    - verifyAndExecuteFastWithdrawal() 호출                     │
│    - gameAddress 포함                                          │
└────────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────────┐
│ 4. RAT 컨트랙트: 사전 검증                                      │
│    - withdrawalHash 유효성 확인                                 │
│    - 중복 실행 방지                                            │
└────────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────────┐
│ 5. RAT 컨트랙트: 게임 클레임 체크 ⭐ NEW                         │
│    - if (gameAddress != address(0))                            │
│    -   claimCount = IDisputeGame(gameAddress).claimDataLen()   │
│    -   if (claimCount > 0) revert                              │
└────────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────────┐
│ 6. RAT 컨트랙트: 검증자 검증                                    │
│    - 최소 검증자 수 확인                                        │
│    - 만장일치 검증                                             │
└────────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────────┐
│ 7. RAT 컨트랙트: BLS 서명 검증                                  │
│    - 공개키 집계                                               │
│    - 집계 서명 검증                                            │
└────────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────────┐
│ 8. RAT 컨트랙트: Fast Withdrawal 실행                           │
│    - OptimismPortal2.setWithdrawalVerified() 호출              │
│    - OptimismPortal2.fastWithdrawalFinalize() 호출             │
└────────────────────────────────────────────────────────────────┘
```

### 클레임이 있는 경우

```
DisputeGame에 클레임 존재
    ↓
Aggregator가 verifyAndExecuteFastWithdrawal() 호출
    ↓
게임 클레임 체크 (Step 5)
    ↓
claimDataLen() > 0 감지
    ↓
FastWithdrawalGameHasClaimsError 발생
    ↓
트랜잭션 revert
    ↓
Fast Withdrawal 차단 ✓
```

### 클레임이 없는 경우

```
DisputeGame에 클레임 없음
    ↓
Aggregator가 verifyAndExecuteFastWithdrawal() 호출
    ↓
게임 클레임 체크 (Step 5)
    ↓
claimDataLen() == 0 확인
    ↓
다음 검증 단계로 진행
    ↓
BLS 서명 검증 등...
    ↓
Fast Withdrawal 실행 ✓
```

## 테스트 커버리지

### 단위 테스트

**파일**: `test/v3/scenarios/FastWithdrawalScenarios.t.sol`

1. **test_FastWithdrawal_GameHasClaims_Reverts**
   - 게임에 클레임이 1개 있을 때 Fast Withdrawal이 차단되는지 확인
   - 예상 결과: `FastWithdrawalGameHasClaimsError` 발생

2. **test_FastWithdrawal_GameMultipleClaims_Reverts**
   - 게임에 여러 클레임이 있을 때 Fast Withdrawal이 차단되는지 확인
   - 예상 결과: `FastWithdrawalGameHasClaimsError` 발생

3. **test_FastWithdrawal_GameNoClaims_PassesGameCheck**
   - 게임에 클레임이 없을 때 게임 체크를 통과하는지 확인
   - 예상 결과: 게임 체크 통과 (다른 검증에서 실패할 수 있음)

4. **test_FastWithdrawal_GameAddressZero_SkipsCheck**
   - `gameAddress`가 `address(0)`일 때 게임 체크를 건너뛰는지 확인
   - 예상 결과: 게임 체크 스킵

5. **test_FastWithdrawal_GameClaimCheck_RunsBeforeOtherValidations**
   - 게임 클레임 체크가 다른 검증보다 먼저 실행되는지 확인
   - 예상 결과: 검증자가 없어도 게임 클레임이 있으면 `FastWithdrawalGameHasClaimsError` 발생

### 테스트 실행 결과

```bash
$ forge test --match-test "test_FastWithdrawal_Game" -vv

Ran 5 tests for test/v3/scenarios/FastWithdrawalScenarios.t.sol:FastWithdrawalScenariosTest
[PASS] test_FastWithdrawal_GameAddressZero_SkipsCheck() (gas: 102486)
[PASS] test_FastWithdrawal_GameClaimCheck_RunsBeforeOtherValidations() (gas: 629461)
[PASS] test_FastWithdrawal_GameHasClaims_Reverts() (gas: 630197)
[PASS] test_FastWithdrawal_GameMultipleClaims_Reverts() (gas: 759721)
[PASS] test_FastWithdrawal_GameNoClaims_PassesGameCheck() (gas: 560003)
Suite result: ok. 5 passed; 0 failed; 0 skipped
```

## 보안 고려사항

### 1. 클레임 존재 여부 체크의 중요성

- **문제**: DisputeGame에 클레임이 있다는 것은 해당 출금에 대한 분쟁이 진행 중이라는 의미
- **리스크**: 분쟁 중인 출금을 Fast Withdrawal로 실행하면 잘못된 상태 전환 가능
- **해결책**: 클레임이 하나라도 있으면 Fast Withdrawal을 무조건 차단

### 2. gameAddress 필수 여부

- `gameAddress`가 `address(0)`인 경우 게임 클레임 체크를 건너뜀
- 이는 하위 호환성을 위한 것이며, 새로운 Fast Withdrawal 요청은 항상 `gameAddress`를 포함해야 함
- 향후 버전에서는 `gameAddress`를 필수로 변경할 수 있음

### 3. 체크 순서

게임 클레임 체크는 다른 검증보다 먼저 실행됩니다:
1. 사전 검증 (withdrawalHash, 중복 실행 방지)
2. **게임 클레임 체크** ⭐
3. 최소 검증자 수 확인
4. 만장일치 검증
5. BLS 서명 검증

이렇게 하면 불필요한 계산을 방지하고 가스를 절약할 수 있습니다.

## 사용 예시

### Aggregator 구현 예시

```javascript
async function submitFastWithdrawal(withdrawalHash, gameAddress) {
    // 1. DisputeGame의 클레임 개수 확인
    const game = await ethers.getContractAt("IDisputeGame", gameAddress);
    const claimCount = await game.claimDataLen();
    
    if (claimCount > 0) {
        console.log(`❌ Fast Withdrawal 불가: 게임에 ${claimCount}개의 클레임 존재`);
        return;
    }
    
    console.log(`✓ 게임 클레임 없음: Fast Withdrawal 진행 가능`);
    
    // 2. 검증자 서명 수집
    const signatures = await collectValidatorSignatures(withdrawalHash);
    
    // 3. Fast Withdrawal 제출
    const tx = await ratFastWithdrawal.verifyAndExecuteFastWithdrawal(
        withdrawalTransaction,
        {
            withdrawalHash,
            systemConfig,
            gameAddress,  // 반드시 포함
            stateRoot,
            validatorBitmap,
            leafA,
            leafB,
            proofsA,
            proofsB
        },
        aggregatedSignature
    );
    
    await tx.wait();
    console.log(`✓ Fast Withdrawal 성공`);
}
```

### 에러 처리

```javascript
try {
    await ratFastWithdrawal.verifyAndExecuteFastWithdrawal(
        tx,
        input,
        signature
    );
} catch (error) {
    if (error.message.includes("FastWithdrawalGameHasClaimsError")) {
        console.error("❌ DisputeGame에 클레임이 존재하여 Fast Withdrawal 불가");
        console.error("→ 일반 출금(7일 대기)을 사용하거나 클레임 해결 대기 필요");
    } else {
        console.error("기타 에러:", error.message);
    }
}
```

## 설계 원칙

### 간단하고 명확한 정책

Fast Withdrawal은 **클레임이 하나라도 있으면 무조건 차단**하는 단순하고 명확한 정책을 따릅니다.

**이유:**
- ✅ **보안 우선**: 클레임이 있다는 것은 분쟁이 있다는 신호
- ✅ **단순성**: 복잡한 조건 체크 없이 명확한 규칙
- ✅ **예측 가능성**: 사용자와 검증자 모두 동작을 쉽게 이해
- ✅ **가스 효율**: 최소한의 체크로 빠른 판단

**타임스탬프 기반 만료 체크나 복잡한 상태 체크는 불필요합니다:**
- Fast Withdrawal은 즉시 출금을 위한 기능
- 클레임이 있으면 일반 출금(7일)을 사용하면 됨
- 복잡한 로직은 보안 위험과 가스 비용 증가

## 요약

- ✅ DisputeGame 클레임 체크 기능 추가
- ✅ `IDisputeGame.claimDataLen()` 인터페이스 확장
- ✅ `FastWithdrawalInput.gameAddress` 필드 추가
- ✅ `FastWithdrawalGameHasClaimsError` 에러 타입 추가
- ✅ 5개의 단위 테스트 작성 및 통과
- ✅ 게임 클레임이 있으면 Fast Withdrawal 차단
- ✅ 보안 강화 및 분쟁 중 출금 방지

## 참고 자료

- OptimismPortal2 DisputeGame 인터페이스: `/Users/zena/tokamak-projects/optimism/packages/contracts-bedrock/interfaces/dispute/IDisputeGame.sol`
- FaultDisputeGame 구현: `/Users/zena/tokamak-projects/optimism/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol`
- RAT Fast Withdrawal 구현: `src/validator/RATFastWithdrawal.sol`
- 테스트 파일: `test/v3/scenarios/FastWithdrawalScenarios.t.sol`
