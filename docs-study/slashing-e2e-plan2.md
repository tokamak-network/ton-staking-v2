# 슬래싱 E2E 테스트 시나리오 2: 일반 스테이커 보호 (Delegator Protection)

## 🎯 목표
Operator가 슬래싱당했을 때, 일반 위임자(Delegator)의 지분(원금 + 시뇨리지)이 보호되는지 검증합니다.

## 📋 진행 상황
- [x] 시나리오 1: 기본 Operator 슬래싱 (완료)
- [x] 시나리오 2: 일반 스테이커 보호 (완료)

---

## 🔧 구현 계획

### 1. 헬퍼 함수 추가 (`op-e2e/slashing/slashing_helpers.go`)

Operator 외의 제3자(Delegator)가 스테이킹할 수 있는 함수가 필요합니다.

```go
// delegatorDeposit: 일반 스테이커가 특정 Candidate에게 예치
func delegatorDeposit(
    t *testing.T,
    sys *rat.TONStakingSystem,
    contracts *SlashingContracts,
    delegatorAuth *bind.TransactOpts,
    candidateAddOn common.Address,
    amount *big.Int,
)
```

**구현 내용:**
1. Delegator 계정 생성 및 TON/WTON 지급
2. DepositManager에 WTON 승인
3. `DepositManager.deposit(candidateAddOn, operatorManager, amount)` 호출
4. 예치 완료 이벤트/상태 확인

### 2. 테스트 케이스 작성 (`op-e2e/slashing/slashing_test.go`)

새로운 테스트 함수 `TestSlashing_DelegatorProtection`를 추가합니다.

#### 테스트 시나리오 흐름
1. **환경 설정**: `BasicOperatorSlashing`과 동일한 초기 설정
2. **Operator 등록**: 10,000 TON 스테이킹 (기존 헬퍼 사용)
3. **Delegator 예치**:
   - 새로운 Delegator 계정 생성
   - 5,000 TON 예치 (신규 헬퍼 `delegatorDeposit` 사용)
4. **시간 경과 (시뇨리지 발생)**:
   - `rat.AdvanceTimeAndMine`을 사용하여 충분한 시간(예: 14일 이상) 진행
   - 시뇨리지가 발생할 수 있는 조건 시뮬레이션
5. **Slashing 실행**:
   - Mock Dispute Game 생성 -> Challenger 승리 -> Slashing 실행
6. **검증 (Assertions)**:
   - **Operator**: 스테이크가 **0**이어야 함 (전액 소각/보상)
   - **Delegator**: 스테이크가 **보존**되어야 함 (원금 5,000 TON + @)
   - **Delegator 출금 가능 여부 확인**: (선택) 출금 요청이 성공하는지 확인

#### 예상 코드 구조

```go
func TestSlashing_DelegatorProtection(t *testing.T) {
    t.Parallel()
    // ... setup ...

    // 1. Operator Register
    candidateAddOn, operatorManager := registerOperatorWithCandidateAddOn(...)

    // 2. Delegator Deposit
    delegatorAmt := big.NewInt(5000 * 1e18)
    delegatorDeposit(..., delegatorAuth, candidateAddOn, delegatorAmt)

    // 3. Time Travel (Seigniorage)
    rat.AdvanceTimeAndMine(t, sys, 100000) 

    // 4. Slashing Flow
    // ... Create Game, Challenge, Resolve, Execute Slash ...

    // 5. Verify
    opStake := getStakeBalance(..., operatorManager) // Should be 0
    delStake := getStakeBalance(..., delegatorAddr) // Should be >= delegatorAmt

    require.Equal(t, 0, opStake.Cmp(big.NewInt(0)))
    require.True(t, delStake.Cmp(delegatorAmt) >= 0)
}
```

---

## 📅 작업 순서

1. **`slashing_helpers.go` 업데이트**: `delegatorDeposit` 함수 구현
2. **`slashing_test.go` 업데이트**: `TestSlashing_DelegatorProtection` 함수 구현
3. **테스트 실행 및 검증**:
   ```bash
   go test -v ./op-e2e/slashing -run TestSlashing_DelegatorProtection
   ```
