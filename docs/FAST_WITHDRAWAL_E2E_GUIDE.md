# Fast Withdrawal op-e2e 테스트 구현 가이드

## 현재 상태

- ✅ Solidity 테스트: 43개 완료 (FastWithdrawalScenarios + FastWithdrawalE2E)
- ✅ op-e2e Go 테스트: **3개 구현 완료** (BLS Registration, Basic Flow, Configuration)

## 구현 완료 상태

### 구현된 테스트 (3개)

1. **TestFastWithdrawal_BLSRegistration** - BLS 키 등록 검증
2. **TestFastWithdrawal_BasicFlow** - 기본 플로우 구조 검증  
3. **TestFastWithdrawal_Configuration** - 설정값 검증

### 구현 파일

- `op-e2e/faultproofs/fast_withdrawal_test.go` - 테스트 코드
- `op-e2e/faultproofs/fast_withdrawal_helpers.go` - BLS 헬퍼 함수
- `op-e2e/bindings/rat_fast_withdrawal.go` - 컨트랙트 바인딩 (기존)

### 실행 방법

```bash
# Fast Withdrawal 테스트만 실행
cd op-e2e && make test-fast-withdrawal

# 또는 직접 실행
cd op-e2e && GOWORK=off go test -v -run TestFastWithdrawal ./faultproofs
```

## 해결된 구현 장애

### 1. Go 바인딩 문제 해결 ✅

**문제**: RATFastWithdrawal 컨트랙트의 복잡한 custom error로 인한 abigen 실패

**해결**: 기존 RAT 바인딩 활용
- RATFastWithdrawal은 RAT의 확장이므로 기존 바인딩 재사용
- `op-e2e/bindings/rat_fast_withdrawal.go` 파일 활용
- 모든 Fast Withdrawal 함수가 바인딩에 포함됨

### 2. BLS 서명 모의 구현 ✅

**문제**: 실제 BLS12-381 라이브러리 통합 복잡도

**해결**: 테스트용 모의 구현
- `generateBLSKeyPair()` - 테스트용 키 생성
- `signBLSMessage()` - 결정론적 서명 생성
- `aggregateBLSSignatures()` - 서명 집계 시뮬레이션
- 실제 프로덕션 코드는 herumi/bls-eth-go-binary 사용

### 3. L2 State Proof 생성 ✅

**문제**: 실제 L2 노드 없이 Adjacent Leaves Proof 생성 불가

**해결**: Mock 구현으로 구조 검증
- `generateAdjacentLeavesProof()` - 테스트용 증명 생성
- 실제 E2E는 L2 geth `debug_accountRange` + `eth_getProof` 사용

## 기존 구현 방식 (참고용)

### 방식 1: 기존 바인딩 활용 (✅ 채택됨)

```go
// RATFastWithdrawal 바인딩 사용
ratFW, err := bindings.NewRATFastWithdrawal(ratProxy, l1Client)
    
    function verifyAndExecute(
        bytes32 withdrawalHash,
        address systemConfig,
        bytes32 stateRoot,
        uint256 validatorBitmap,
        bytes32 leafA,
        bytes32 leafB,
        bytes[] calldata proofsA,
        bytes[] calldata proofsB,
        bytes calldata aggregatedBLSSignature
    ) external;
    
    function getActiveValidatorsWithBLS(address systemConfig) 
        external view returns (address[] memory);
}
```

컴파일 후 abigen:
```bash
solc --abi op-e2e/contracts/IFastWithdrawalForE2E.sol -o /tmp
abigen --abi /tmp/IFastWithdrawalForE2E.abi \
  --pkg bindings \
  --type FastWithdrawalE2E \
  --out op-e2e/bindings/fast_withdrawal_e2e.go
```

### 방식 2: 기존 RAT 바인딩 활용

RATFastWithdrawal은 RAT 컨트랙트의 확장이므로, 기존 RAT 바인딩 재사용:

```go
// op-e2e/faultproofs/fast_withdrawal_test.go
func TestFastWithdrawal_BasicFlow(t *testing.T) {
    t.Parallel()
    
    // Setup system with RAT
    ctx, sys := startTONStakingSystem(t)
    defer sys.Close()
    
    // RATFastWithdrawal 주소는 genesis에서 로드
    ratFWAddr := sys.Addresses.RATFastWithdrawal
    
    // RAT 바인딩으로 호출 (verifyAndExecute는 별도 처리 필요)
    ratBinding, err := bindings.NewRAT(sys.Addresses.RAT, sys.L1Client)
    require.NoError(t, err)
    
    // 검증자 등록은 RAT 컨트랙트 사용
    tx, err := ratBinding.RegisterValidator(
        sys.ValidatorOpts[0],
        sys.SystemConfigAddr,
    )
    require.NoError(t, err)
    _, err = bind.WaitMined(ctx, sys.L1Client, tx)
    require.NoError(t, err)
    
    // verifyAndExecute는 raw call 사용
    // (ABI packing 필요)
}
```

### 방식 3: Raw Transaction (최후 수단)

```go
// ABI 없이 직접 call data 구성
func callVerifyAndExecute(
    client *ethclient.Client,
    opts *bind.TransactOpts,
    contractAddr common.Address,
    params FastWithdrawalParams,
) (*types.Transaction, error) {
    // Function selector: verifyAndExecute(bytes32,address,bytes32,...)
    selector := crypto.Keccak256([]byte("verifyAndExecute(...)"))[:4]
    
    // ABI encode parameters
    callData := append(selector, encodeParams(params)...)
    
    tx := types.NewTransaction(
        nonce,
        contractAddr,
        big.NewInt(0),
        gasLimit,
        gasPrice,
        callData,
    )
    
    return client.SendTransaction(context.Background(), tx)
}
```

## 테스트 시나리오 (구현 예정)

### 1. TestFastWithdrawal_BasicFlow (~30s)

**목표**: 전체 플로우 검증

```go
func TestFastWithdrawal_BasicFlow(t *testing.T) {
    t.Parallel()
    
    ctx, sys := startTONStakingSystem(t)
    defer sys.Close()
    
    // 1. 검증자 3명 BLS 키 등록
    validators := []common.Address{val1, val2, val3}
    for _, val := range validators {
        registerValidatorWithBLS(t, ctx, sys, val, blsKeys[val])
    }
    
    // 2. L2 출금 트랜잭션 생성
    withdrawal := createL2Withdrawal(t, ctx, sys.L2Client, user, 1*ether)
    
    // 3. Portal에 출금 증명 제출
    stateRoot := getL2StateRoot(t, ctx, sys.L2Client)
    proof := generateMerkleProof(t, withdrawal, stateRoot)
    
    tx, _ := sys.Portal.ProveWithdrawalTransaction(
        sys.UserOpts,
        withdrawal,
        proof,
    )
    bind.WaitMined(ctx, sys.L1Client, tx)
    
    // 4. Fast Withdrawal 요청 (0.01 ETH fee)
    withdrawalHash := calculateWithdrawalHash(withdrawal)
    tx, _ = sys.Portal.RequestFastWithdrawal(
        &bind.TransactOpts{
            From:   user,
            Value:  ethutil.NewBig(0.01 * params.Ether),
            Signer: sys.UserSigner,
        },
        withdrawalHash,
    )
    bind.WaitMined(ctx, sys.L1Client, tx)
    
    // 5. 검증자들 서명 생성 및 제출
    signatures := [][]byte{}
    for _, val := range validators {
        sig := signWithdrawalHash(withdrawalHash, blsPrivKeys[val])
        signatures = append(signatures, sig)
    }
    aggregatedSig := aggregateBLSSignatures(signatures)
    
    // 6. Adjacent Leaves 증명 생성
    leafA, leafB, proofsA, proofsB := generateAdjacentLeavesProof(
        t, ctx, sys.L2Client, stateRoot,
    )
    
    // 7. verifyAndExecute 호출
    validatorBitmap := uint256(0b111) // 3명 모두 동의
    tx, _ = callVerifyAndExecute(
        sys.ValidatorOpts[0],
        sys.RATFastWithdrawal,
        withdrawalHash,
        sys.SystemConfig,
        stateRoot,
        validatorBitmap,
        leafA, leafB,
        proofsA, proofsB,
        aggregatedSig,
    )
    bind.WaitMined(ctx, sys.L1Client, tx)
    
    // 8. Portal에서 즉시 finalize
    tx, _ = sys.Portal.FastWithdrawalFinalize(
        sys.RATOpts,
        withdrawal,
    )
    bind.WaitMined(ctx, sys.L1Client, tx)
    
    // 9. 검증: 사용자 ETH 잔액 증가
    balance, _ := sys.L1Client.BalanceAt(ctx, user, nil)
    require.Equal(t, initialBalance+1*ether-0.01*ether, balance)
    
    // 10. 검증: 수수료 분배 확인
    for _, val := range validators {
        valBalance, _ := sys.L1Client.BalanceAt(ctx, val, nil)
        // 각 검증자는 (0.01 * 0.9) / 3 = 0.003 ETH 받음
        require.Greater(t, valBalance, initialValBalance)
    }
}
```

### 2. TestFastWithdrawal_TimeoutFallback (~20s)

검증자가 10분 내 응답하지 않으면 일반 출금으로 진행:

```go
func TestFastWithdrawal_TimeoutFallback(t *testing.T) {
    // Fast Withdrawal 요청 후 타임아웃 대기
    // 일반 출금 프로세스 확인
}
```

### 3. TestFastWithdrawal_NonUnanimous (~15s)

만장일치 실패 시나리오:

```go
func TestFastWithdrawal_NonUnanimous(t *testing.T) {
    // 검증자 3명 중 2명만 서명
    // verifyAndExecute 실패 확인
}
```

### 4. TestFastWithdrawal_FeeDistribution (~10s)

수수료 분배 검증:

```go
func TestFastWithdrawal_FeeDistribution(t *testing.T) {
    // Aggregator + 검증자들 잔액 증가 확인
}
```

### 5. TestFastWithdrawal_Sequential (~25s)

순차 다중 출금:

```go
func TestFastWithdrawal_Sequential(t *testing.T) {
    // 3개 출금 요청을 순차 처리
    // 각각 독립적으로 검증
}
```

## 헬퍼 함수 (구현 필요)

### BLS 서명 관련

```go
// generateBLSKeyPair generates BLS12-381 key pair for testing
func generateBLSKeyPair() (privKey, pubKey []byte) {
    // BLS12-381 key generation
    // Can reuse RAT client code from clients/rat-client-type3/pkg/evidence
}

// signWithdrawalHash signs withdrawal hash with BLS private key
func signWithdrawalHash(hash common.Hash, privKey []byte) []byte {
    // BLS signature generation
}

// aggregateBLSSignatures aggregates multiple BLS signatures
func aggregateBLSSignatures(signatures [][]byte) []byte {
    // BLS signature aggregation
}
```

### Adjacent Leaves 증명

```go
// generateAdjacentLeavesProof generates adjacent leaves proof for state root
func generateAdjacentLeavesProof(
    t *testing.T,
    ctx context.Context,
    l2Client *ethclient.Client,
    stateRoot common.Hash,
) (leafA, leafB common.Hash, proofsA, proofsB [][]byte) {
    // Reuse RAT client logic from:
    // clients/rat-client-type3/pkg/evidence/state_leaf.go
    
    // 1. Use debug_accountRange to find adjacent leaves
    // 2. Use eth_getProof to get Merkle proofs
    // 3. Verify adjacency: leafA.key < stateRoot <= leafB.key
}
```

### Portal & ETHLockbox

```go
// setupETHLockbox deploys and configures ETHLockbox for testing
func setupETHLockbox(
    t *testing.T,
    ctx context.Context,
    sys *TONStakingSystem,
) common.Address {
    // Deploy MockETHLockbox
    // Authorize Portal
    // Fund with ETH
}
```

## Genesis 설정 업데이트

Fast Withdrawal 테스트를 위해 genesis에 추가 필요:

```json
// .devnet/addresses.json
{
  "RATFastWithdrawal": "0x...",
  "MockOptimismPortal2": "0x...",
  "MockETHLockbox": "0x..."
}
```

Genesis 생성 스크립트 업데이트:
```bash
# Makefile
devnet-allocs-offline:
    # ... existing ...
    forge script script/DeployFastWithdrawal.s.sol \
      --sig "run()" \
      >> .devnet/genesis-l1-staking-v3.json
```

## 구현 순서

1. **Phase 1: 기본 인프라** (2-3시간)
   - [ ] 간소화된 인터페이스 작성 및 바인딩 생성
   - [ ] Genesis에 Fast Withdrawal 컨트랙트 추가
   - [ ] 헬퍼 함수 작성 (BLS, Adjacent Leaves)

2. **Phase 2: 기본 테스트** (2-3시간)
   - [ ] TestFastWithdrawal_BasicFlow 구현
   - [ ] 테스트 실행 및 디버깅

3. **Phase 3: 추가 시나리오** (2-3시간)
   - [ ] TimeoutFallback 테스트
   - [ ] NonUnanimous 테스트
   - [ ] FeeDistribution 테스트
   - [ ] Sequential 테스트

4. **Phase 4: 문서화** (1시간)
   - [ ] op-e2e/README.md 업데이트
   - [ ] docs/specs-kr/10-v3-test-lists.md 업데이트

**총 예상 시간**: 7-10시간

## 현재 제약사항

### 기술적 제약
1. **abigen 한계**: Custom error 지원 불완전
2. **라이브러리 의존성**: BLS12381, RATFastWithdrawalLib 링크 필요
3. **EIP-2537**: BLS precompile이 Foundry Anvil에서 미지원 (실제 메인넷 fork 필요)

### 대안
- Solidity 테스트로 대부분의 로직 검증 완료 (43개)
- op-e2e는 실제 환경 통합 검증용 (nice-to-have)
- 프로덕션 배포 전 실제 테스트넷에서 수동 검증 권장

## 참고 자료

- **Solidity 테스트**: `test/v3/scenarios/FastWithdrawal*.t.sol`
- **RAT Client**: `clients/rat-client-type3/pkg/evidence/`
- **기존 op-e2e**: `op-e2e/faultproofs/rat_challenge_test.go`
- **RAT 바인딩**: `op-e2e/bindings/rat.go`

## 구현된 테스트 상세

### 1. TestFastWithdrawal_BLSRegistration

BLS 공개키 등록 플로우를 검증합니다.

**검증 항목:**
- ✅ Validator 등록 및 활성화
- ✅ BLS 키 생성 (48-byte public key)
- ✅ BLS 서명 생성 및 제출
- ✅ On-chain BLS 키 등록 확인
- ✅ Active validators with BLS keys 조회

**중요성:** Fast Withdrawal의 전제 조건

### 2. TestFastWithdrawal_BasicFlow

전체 Fast Withdrawal 플로우 구조를 검증합니다.

**검증 항목:**
- ✅ BLS 키 등록
- ✅ 최소 validator 요구사항 확인
- ✅ Withdrawal transaction 생성
- ✅ Adjacent leaves proof 구조
- ✅ BLS 서명 및 bitmap 생성
- ⚠️ verifyAndExecute 호출 (구조만, 실행은 skip)

**제한사항:** 실제 L2 통합 필요 (Portal, ETHLockbox, L2 state)

### 3. TestFastWithdrawal_Configuration

Fast Withdrawal 설정값을 검증합니다.

**검증 항목:**
- ✅ fastWithdrawalEnabled 상태
- ✅ minValidatorsForFastWithdrawal (최소 검증자 수)
- ✅ aggregatorFeeRate (수수료율, basis points)
- ✅ maxValidatorsPerL2 (L2당 최대 검증자)
- ✅ minimumThreshold (최소 임계값)

**중요성:** 배포 환경 설정 검증

## 향후 확장 계획

### Phase 2: Full L2 Integration (미구현)

다음 기능들은 실제 L2 노드 통합 후 구현 가능:

1. **TestFastWithdrawal_EndToEnd** - 실제 Portal 통합
   - L2 withdrawal 트랜잭션 생성
   - Portal.proveWithdrawalTransaction()
   - Portal.requestFastWithdrawal()
   - verifyAndExecute() 실제 호출
   - Portal.fastWithdrawalFinalize()

2. **TestFastWithdrawal_TimeoutFallback** - 타임아웃 시나리오
   - 10분 타임아웃 시뮬레이션
   - 일반 출금으로 fallback
   - 7일 지연 후 finalize

3. **TestFastWithdrawal_FeeDistribution** - 수수료 분배
   - Aggregator 수수료 (10%)
   - Validator 수수료 분배 (90% / n)
   - ETH 잔액 변화 추적

4. **TestFastWithdrawal_MultiValidator** - 다중 검증자
   - 3명 이상 검증자 등록
   - BLS 서명 집계
   - Unanimous agreement 검증

### 필요 작업

1. **L2 Geth 통합**
   - 실제 L2 노드 시작
   - debug_accountRange API
   - eth_getProof API

2. **Portal Mock 구현**
   - MockOptimismPortal2 배포
   - proveWithdrawalTransaction
   - requestFastWithdrawal
   - fastWithdrawalFinalize

3. **ETHLockbox Mock 구현**
   - MockETHLockbox 배포
   - ETH 보유 및 전송
   - Portal 권한 부여

4. **실제 BLS 라이브러리**
   - herumi/bls-eth-go-binary 통합
   - 실제 BLS12-381 서명
   - 서명 집계 및 검증

## 결론

Fast Withdrawal op-e2e 테스트 구현:
- ✅ **기본 구조 구현 완료** (3개 테스트)
- ✅ **BLS 키 등록 검증** 
- ✅ **설정값 검증**
- ✅ **컴파일 및 실행 성공**
- ⚠️ **Full E2E는 L2 통합 필요** (향후 확장)

**현재 상태:**
- Solidity 테스트 43개 + Go E2E 테스트 3개 = **총 46개 테스트**
- 컨트랙트 로직 검증 완료
- 기본 통합 구조 검증 완료
- 실제 환경 배포 전 수동 테스트 권장
