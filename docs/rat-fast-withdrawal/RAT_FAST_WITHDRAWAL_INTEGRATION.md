# RAT Fast Withdrawal - Layer2 Integration Guide

## Repository Information

### RAT Contract (Implemented)
**Repository:** `tokamak-network/ton-staking-v2`  
**Branch:** `main`  
**Path:** `/Users/zena/tokamak-projects/ton-staking-v2`

**Implementation Status:** ✅ RAT Contract Implemented
- **RAT Fast Withdrawal Contract:** `src/validator/RATFastWithdrawal.sol`
- **Fast Withdrawal Library:** `src/libraries/RATFastWithdrawalLib.sol`
- **BLS Library:** `src/libraries/BLS12381.sol`
- **Test Coverage:** 43 Solidity tests passed

### Portal Integration (To Be Implemented)
**Repository:** Optimism fork  
**Path:** `/Users/zena/tokamak-projects/optimism`  
**Target File:** `packages/contracts-bedrock/src/L1/OptimismPortal2.sol`

**What's Implemented:**
- ✅ Go Clients: Validator Node + Aggregator Service (빌드 완료)

**What's Not Implemented (Requires Optimism Fork Work):**
- OptimismPortal2 modifications (described in this document)
- op-e2e Go tests

---

## Overview

This document describes the contract modifications required for Layer2 projects to integrate RAT Fast Withdrawal.

**Goal:** Reduce 7-day withdrawal delay → Instant withdrawal (RAT validator signatures)

---

## 🎯 필수 컨트랙트 변경사항

### 1. OptimismPortal2 수정

**파일:** `packages/contracts-bedrock/src/L1/OptimismPortal2.sol`

#### 1.1 스토리지 추가

```solidity
// ============================================================
// Fast Withdrawal Storage (RAT Integration)
// ============================================================

/// @notice RAT contract address for Fast Withdrawal verification
address public ratContract;

/// @notice RAT-verified withdrawals that can bypass the 7-day delay
mapping(bytes32 => bool) public ratVerifiedWithdrawals;

/// @notice Fast Withdrawal response period (default: 10 minutes)
uint256 public fastWithdrawalResponsePeriod;
```

#### 1.2 이벤트 추가

```solidity
/// @notice Emitted when a fast withdrawal is requested
event FastWithdrawalRequested(
    bytes32 indexed withdrawalHash,
    address indexed user,
    uint256 amount,
    bytes32 stateRoot,
    uint256 feePaid,
    uint256 deadline
);

/// @notice Emitted when a withdrawal is verified by RAT
event RATWithdrawalVerified(bytes32 indexed withdrawalHash);

/// @notice Emitted when a fast withdrawal is finalized
event FastWithdrawalFinalized(bytes32 indexed withdrawalHash, bool success);

/// @notice Emitted when the RAT contract address is updated
event RATContractUpdated(address indexed oldRatContract, address indexed newRatContract);
```

#### 1.3 에러 추가

```solidity
/// @notice Thrown when a withdrawal has not been verified by RAT
error OptimismPortal_NotVerifiedByRAT();

/// @notice Thrown when the caller is not the RAT contract
error OptimismPortal_OnlyRAT();
```

#### 1.4 함수 추가

##### A. proveAndRequestFastWithdrawal()

```solidity
/// @notice Prove withdrawal and request fast withdrawal (bypass 7-day delay)
/// @param _tx Withdrawal transaction
/// @param _disputeGameIndex Index of dispute game
/// @param _outputRootProof Output root proof
/// @param _withdrawalProof Withdrawal proof
function proveAndRequestFastWithdrawal(
    Types.WithdrawalTransaction memory _tx,
    uint256 _disputeGameIndex,
    Types.OutputRootProof calldata _outputRootProof,
    bytes[] calldata _withdrawalProof
) external payable {
    // 1. 일반 출금 증명 수행 (기존 로직 재사용)
    proveWithdrawalTransaction(_tx, _disputeGameIndex, _outputRootProof, _withdrawalProof);
    
    // 2. Fast Withdrawal 요청 기록
    bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);
    bytes32 stateRoot = _outputRootProof.stateRoot;
    
    emit FastWithdrawalRequested(
        withdrawalHash,
        msg.sender,
        _tx.value,
        stateRoot,
        msg.value,  // 수수료는 별도 처리 가능
        block.timestamp + fastWithdrawalResponsePeriod
    );
}
```

##### B. setRATWithdrawalVerified()

```solidity
/// @notice Mark a withdrawal as verified by RAT (RAT only)
/// @param _withdrawalHash Hash of the withdrawal transaction
function setRATWithdrawalVerified(bytes32 _withdrawalHash) external {
    require(msg.sender == ratContract, OptimismPortal_OnlyRAT());
    
    ratVerifiedWithdrawals[_withdrawalHash] = true;
    
    emit RATWithdrawalVerified(_withdrawalHash);
}
```

##### C. fastWithdrawalFinalize()

```solidity
/// @notice Finalize a fast withdrawal (bypass 7-day delay)
/// @param _tx Withdrawal transaction
function fastWithdrawalFinalize(Types.WithdrawalTransaction memory _tx) external {
    bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);
    
    // 1. RAT 검증 완료 확인
    require(ratVerifiedWithdrawals[withdrawalHash], OptimismPortal_NotVerifiedByRAT());
    
    // 2. 이중 출금 방지 (기존 매핑 재사용)
    require(!finalizedWithdrawals[withdrawalHash], OptimismPortal_AlreadyFinalized());
    
    // 3. 자산 전송
    address gasToken = systemConfig.gasPayingToken();
    
    if (gasToken == address(0)) {
        // Native ETH 체인
        bool success = SafeCall.call(_tx.target, gasleft(), _tx.value, _tx.data);
        require(success, "ETH transfer failed");
    } else {
        // Custom Gas Token 체인
        IERC20(gasToken).safeTransfer(_tx.target, _tx.value);
    }
    
    // 4. 완료 표시
    finalizedWithdrawals[withdrawalHash] = true;
    
    emit FastWithdrawalFinalized(withdrawalHash, true);
}
```

##### D. 관리자 함수

```solidity
/// @notice Set RAT contract address (Owner only)
/// @param _ratContract RAT contract address
function setRATContract(address _ratContract) external {
    require(msg.sender == guardian(), "OptimismPortal: only guardian");
    
    address oldRatContract = ratContract;
    ratContract = _ratContract;
    
    emit RATContractUpdated(oldRatContract, _ratContract);
}

/// @notice Set fast withdrawal response period (Owner only)
/// @param _period Response period in seconds
function setFastWithdrawalResponsePeriod(uint256 _period) external {
    require(msg.sender == guardian(), "OptimismPortal: only guardian");
    
    fastWithdrawalResponsePeriod = _period;
}
```

---

### 2. RAT Contract 수정

**파일:** `src/validator/RATFastWithdrawal.sol` (이미 구현됨)

#### 2.1 핵심 함수: verifyAndExecuteFastWithdrawal()

**현재 구현 위치:** `src/validator/RATFastWithdrawal.sol:330`

```solidity
/// @notice BLS 집계 서명 + 인접 리프 증명으로 빠른 출금 실행
/// @param _tx 출금 트랜잭션
/// @param input Fast Withdrawal 검증에 필요한 모든 데이터
/// @param _aggregatedSignature 검증자들의 BLS 집계 서명 (256 bytes)
function verifyAndExecuteFastWithdrawal(
    Types.WithdrawalTransaction calldata _tx,
    RATFastWithdrawalLib.FastWithdrawalInput calldata input,
    bytes calldata _aggregatedSignature
) external payable ifFree whenNotPaused {
    // 1. 사전 검증
    address portal = _validateFastWithdrawalPreconditions(input, _tx);
    
    // 2. 게임 클레임 체크 (DisputeGame에 클레임 있으면 차단)
    if (input.gameAddress != address(0)) {
        uint256 claimCount = IDisputeGame(input.gameAddress).claimDataLen();
        if (claimCount > 0) revert FastWithdrawalGameHasClaimsError();
    }
    
    // 3. 검증자 정보 조회 및 최소 검증자 수 체크
    uint256 validatorCount = validatorPools[input.systemConfig].activeCount;
    uint256 minValidators = minValidatorsForFastWithdrawal;
    if (minValidators == 0) revert FastWithdrawalDisabledError();
    if (validatorCount < minValidators) {
        revert FastWithdrawalInsufficientValidatorsError();
    }
    
    // 4. 만장일치 검증 (100% 검증자 서명)
    if (input.validatorBitmap != (1 << validatorCount) - 1) {
        revert FastWithdrawalNotUnanimousError();
    }
    
    // 5. BLS 공개키 수집 및 집계
    ValidatorPoolInfo storage pool = validatorPools[input.systemConfig];
    bytes[] memory publicKeys = new bytes[](validatorCount);
    for (uint256 i = 0; i < validatorCount; ++i) {
        publicKeys[i] = validatorRegistrations[input.systemConfig][pool.validators[i]].blsPublicKey;
    }
    bytes memory aggregatedPubKey = RATFastWithdrawalLib.aggregatePublicKeys(
        publicKeys,
        input.validatorBitmap,
        validatorCount
    );
    
    // 6. BLS 서명 검증
    RATFastWithdrawalLib.verifyBLSSignature(
        input,
        _aggregatedSignature,
        aggregatedPubKey
    );
    
    // 7. 인접 리프 증명 검증
    RATFastWithdrawalLib.verifyAdjacentLeaves(input);
    
    // 8. 검증 통과 → Portal에 알림
    _executeFastWithdrawal(input, _tx, portal);
}
```

#### 2.2 핵심 데이터 구조

```solidity
struct FastWithdrawalInput {
    bytes32 withdrawalHash;
    address systemConfig;
    address gameAddress;      // DisputeGame 주소 (클레임 체크용)
    bytes32 stateRoot;
    uint256 validatorBitmap;  // 서명한 검증자 비트맵
    bytes32 leafA;            // 인접 리프 A
    bytes32 leafB;            // 인접 리프 B
    bytes[] proofsA;          // 리프 A의 Merkle Proof
    bytes[] proofsB;          // 리프 B의 Merkle Proof
}
```

---

## 🔧 통합 단계

### Phase 1: OptimismPortal2 수정

**우선순위:** 높음  
**예상 작업:** 2-3일

1. **스토리지 추가**
   - `ratContract`, `ratVerifiedWithdrawals`, `fastWithdrawalResponsePeriod`
   
2. **이벤트 및 에러 추가**
   - 4개 이벤트, 2개 에러

3. **함수 구현**
   - `proveAndRequestFastWithdrawal()` - 기존 `proveWithdrawalTransaction()` 확장
   - `setRATWithdrawalVerified()` - RAT 전용 (접근 제어 중요)
   - `fastWithdrawalFinalize()` - 즉시 출금 실행
   - 관리자 함수 2개

4. **테스트 작성**
   - 정상 Fast Withdrawal 흐름
   - 접근 제어 테스트 (RAT만 setRATWithdrawalVerified 호출)
   - 이중 출금 방지 테스트
   - CGT 지원 테스트

### Phase 2: RAT 배포 및 연동

**우선순위:** 중간  
**예상 작업:** 1-2일

1. **RAT 컨트랙트 배포**
   - ton-staking-v2의 RAT 컨트랙트 사용
   - 또는 독자적인 RAT 시스템 구축

2. **Portal-RAT 연결**
   - `portal.setRATContract(ratAddress)`
   - `rat.setMinValidatorsForFastWithdrawal(3)` (예시)
   - `portal.setFastWithdrawalResponsePeriod(600)` (10분)

3. **검증자 등록**
   - 검증자들이 BLS 공개키 등록
   - 최소 검증자 수 충족 확인

### Phase 3: 오프체인 인프라

**우선순위:** 높음  
**예상 작업:** 3-5일

1. **Aggregator 구현**
   - `FastWithdrawalRequested` 이벤트 감지
   - 검증자들로부터 BLS 서명 수집
   - `verifyAndExecuteFastWithdrawal()` 호출

2. **검증자 클라이언트**
   - L2 상태 검증
   - BLS 서명 생성
   - Aggregator에게 서명 전송

---

## 📋 체크리스트

### OptimismPortal2 변경

- [ ] `ratContract` 스토리지 추가
- [ ] `ratVerifiedWithdrawals` 매핑 추가
- [ ] `fastWithdrawalResponsePeriod` 스토리지 추가
- [ ] `proveAndRequestFastWithdrawal()` 구현
- [ ] `setRATWithdrawalVerified()` 구현 (접근 제어: RAT only)
- [ ] `fastWithdrawalFinalize()` 구현
- [ ] `setRATContract()` 관리자 함수 구현
- [ ] `setFastWithdrawalResponsePeriod()` 관리자 함수 구현
- [ ] 이벤트 4개 추가
- [ ] 에러 2개 추가
- [ ] CGT(Custom Gas Token) 지원 확인
- [ ] 단위 테스트 작성
- [ ] 통합 테스트 작성

### RAT 통합

- [ ] RAT 컨트랙트 배포
- [ ] Portal에 RAT 주소 설정
- [ ] 최소 검증자 수 설정
- [ ] Aggregator 수수료율 설정
- [ ] 응답 기간 설정

### 오프체인 인프라

- [ ] Aggregator 서버 구현
- [ ] 검증자 클라이언트 구현
- [ ] BLS 서명 수집 로직
- [ ] 이벤트 모니터링
- [ ] 에러 처리 및 재시도 로직

---

## 🔍 주요 고려사항

### 1. 접근 제어

**중요:** `setRATWithdrawalVerified()`는 **반드시 RAT만 호출 가능**하도록 제한

```solidity
function setRATWithdrawalVerified(bytes32 _withdrawalHash) external {
    require(msg.sender == ratContract, OptimismPortal_OnlyRAT());
    // ...
}
```

**이유:** 무단 검증 완료 표시 방지 (보안 핵심)

### 2. 이중 출금 방지

**기존 `finalizedWithdrawals` 매핑 재사용**

```solidity
// ✅ Good: 기존 매핑 재사용
require(!finalizedWithdrawals[withdrawalHash], OptimismPortal_AlreadyFinalized());

// ❌ Bad: 새로운 매핑 추가 (불필요)
// require(!fastFinalizedWithdrawals[withdrawalHash], ...);
```

**장점:**
- 추가 스토리지 불필요
- Gas 절약
- 일반 출금 ↔ Fast 출금 간 이중 출금 자동 방지

### 3. Custom Gas Token 지원

**ETH와 CGT 모두 지원 필요**

```solidity
address gasToken = systemConfig.gasPayingToken();

if (gasToken == address(0)) {
    // Native ETH 체인
    SafeCall.call(_tx.target, gasleft(), _tx.value, _tx.data);
} else {
    // Custom Gas Token 체인
    IERC20(gasToken).safeTransfer(_tx.target, _tx.value);
}
```

### 4. 게임 클레임 체크

**DisputeGame에 클레임이 있으면 Fast Withdrawal 차단**

```solidity
if (input.gameAddress != address(0)) {
    uint256 claimCount = IDisputeGame(input.gameAddress).claimDataLen();
    if (claimCount > 0) revert FastWithdrawalGameHasClaimsError();
}
```

**이유:** 분쟁 중인 출금은 보수적으로 일반 출금(7일) 사용

### 5. 만장일치 요구

**100% 검증자 서명 필요 (N-of-N)**

```solidity
// 모든 검증자가 서명했는지 확인
if (input.validatorBitmap != (1 << validatorCount) - 1) {
    revert FastWithdrawalNotUnanimousError();
}
```

**이유:**
- 7일 대기를 건너뛰는 중대한 결정
- 한 명이라도 의심하면 일반 출금 사용
- 보수적 접근 = 안전 우선

---

## 🧪 테스트 시나리오

### 1. 정상 흐름

```solidity
function test_FastWithdrawal_Success() public {
    // 1. 사용자: proveAndRequestFastWithdrawal()
    portal.proveAndRequestFastWithdrawal{value: 0.01 ether}(tx, ...);
    
    // 2. RAT: verifyAndExecuteFastWithdrawal()
    // (BLS 서명 검증 + 인접 리프 검증)
    rat.verifyAndExecuteFastWithdrawal(tx, input, aggregatedSig);
    
    // 3. 검증 완료 확인
    assertTrue(portal.ratVerifiedWithdrawals(withdrawalHash));
    
    // 4. 사용자: fastWithdrawalFinalize()
    uint256 balanceBefore = user.balance;
    portal.fastWithdrawalFinalize(tx);
    
    // 5. 출금 완료 확인
    assertEq(user.balance, balanceBefore + 1 ether);
    assertTrue(portal.finalizedWithdrawals(withdrawalHash));
}
```

### 2. 접근 제어

```solidity
function test_setRATWithdrawalVerified_OnlyRAT() public {
    // RAT이 아닌 주소가 호출 시 실패
    vm.prank(attacker);
    vm.expectRevert(OptimismPortal_OnlyRAT.selector);
    portal.setRATWithdrawalVerified(withdrawalHash);
    
    // RAT만 성공
    vm.prank(ratContract);
    portal.setRATWithdrawalVerified(withdrawalHash);
    assertTrue(portal.ratVerifiedWithdrawals(withdrawalHash));
}
```

### 3. 이중 출금 방지

```solidity
function test_DoubleWithdrawal_Prevented() public {
    // Fast Withdrawal 완료
    portal.fastWithdrawalFinalize(tx);
    
    // 재시도 차단
    vm.expectRevert(OptimismPortal_AlreadyFinalized.selector);
    portal.fastWithdrawalFinalize(tx);
    
    // 일반 출금으로도 재시도 차단
    vm.expectRevert(OptimismPortal_AlreadyFinalized.selector);
    portal.finalizeWithdrawalTransaction(tx);
}
```

### 4. 게임 클레임 체크

```solidity
function test_GameHasClaims_FastWithdrawalBlocked() public {
    // 게임에 클레임 추가
    mockGame.addClaim(0, address(0), challenger, 1 ether);
    
    // Fast Withdrawal 시도
    vm.expectRevert(FastWithdrawalGameHasClaimsError.selector);
    rat.verifyAndExecuteFastWithdrawal(tx, input, aggregatedSig);
}
```

---

## 📊 예상 Gas 비용

| 작업 | Gas | 비고 |
|-----|-----|------|
| `proveAndRequestFastWithdrawal()` | ~80k | 기존 prove + 이벤트 |
| `verifyAndExecuteFastWithdrawal()` | ~280k | BLS 검증 + 인접 리프 검증 |
| `fastWithdrawalFinalize()` | ~50k | 자산 전송 + 상태 업데이트 |
| **총계** | **~410k** | vs 일반 출금 7일 대기 |

---

## 🚀 배포 순서

1. **RAT 컨트랙트 배포**
   ```bash
   forge script script/DeployRAT.s.sol --broadcast
   ```

2. **OptimismPortal2 업그레이드**
   ```bash
   # 프록시 업그레이드
   forge script script/UpgradePortal.s.sol --broadcast
   ```

3. **Portal-RAT 연결**
   ```bash
   cast send $PORTAL "setRATContract(address)" $RAT --private-key $PK
   cast send $PORTAL "setFastWithdrawalResponsePeriod(uint256)" 600 --private-key $PK
   ```

4. **RAT 설정**
   ```bash
   cast send $RAT "setMinValidatorsForFastWithdrawal(uint256)" 3 --private-key $PK
   cast send $RAT "setAggregatorFeeRate(uint256)" 1e26 --private-key $PK
   ```

5. **검증자 등록**
   ```bash
   cast send $RAT "registerValidatorWithBLS(address,bytes,bytes)" \
     $SYSTEM_CONFIG $BLS_PUBKEY $BLS_SIGNATURE --private-key $PK
   ```

---

## 📚 참고 자료

### 현재 구현 (ton-staking-v2)

- **RAT Fast Withdrawal 구현:** `src/validator/RATFastWithdrawal.sol`
- **BLS 라이브러리:** `src/libraries/BLS12381.sol`
- **인접 리프 검증:** `src/libraries/AdjacentLeavesVerifier.sol`
- **게임 클레임 체크:** `docs/rat-fast-withdrawal/GAME_CLAIM_CHECK.md`

### Optimism 원본

- **OptimismPortal2:** `optimism/packages/contracts-bedrock/src/L1/OptimismPortal2.sol`
- **DisputeGame:** `optimism/packages/contracts-bedrock/src/dispute/`
- **Types:** `optimism/packages/contracts-bedrock/src/libraries/Types.sol`

---

## ❓ FAQ

### Q1: 기존 일반 출금에 영향이 있나요?

**A:** 없습니다. Fast Withdrawal은 선택적 기능이며, 기존 7일 출금은 그대로 작동합니다.

### Q2: RAT 검증자가 없으면 어떻게 되나요?

**A:** Fast Withdrawal이 비활성화되고, 사용자는 일반 출금(7일)만 사용 가능합니다.

### Q3: 수수료는 어떻게 설정하나요?

**A:** OptimismPortal에서 자유롭게 설정 가능합니다. 일반적으로 출금액의 0.1~1% 정도를 권장합니다.

### Q4: Custom Gas Token도 지원하나요?

**A:** 네, `systemConfig.gasPayingToken()`을 통해 자동으로 감지하고 처리합니다.

### Q5: 만장일치 요구사항을 완화할 수 있나요?

**A:** 코드 수정으로 가능하지만, 보안상 100% 합의를 권장합니다. 7일을 건너뛰는 것은 중대한 결정이므로 보수적 접근이 필요합니다.

---

## 📞 지원

통합 과정에서 문제가 발생하면:
1. GitHub Issues 등록
2. 기술 문서 참조: `docs/rat-fast-withdrawal/`
3. 테스트 코드 참조: `test/v3/scenarios/FastWithdrawal*.t.sol`

---

*작성일: 2026-02-03*  
*버전: 1.0*  
*기준: ton-staking-v2 현재 구현*
