# 슬래싱 E2E 테스트 시나리오 2 Implementation Walkthrough

## 📝 작업 요약
`docs-study/BasicSlash/slashing-e2e-plan2.md`에 따라 **시나리오 2: 일반 스테이커 보호 (Delegator Protection)** 테스트를 구현하고 검증했습니다.

## 🔄 주요 변경 사항

### 1. 헬퍼 함수 추가 (`op-e2e/slashing/slashing_helpers.go`)
- **`delegatorDeposit` 함수 추가**:
  - 일반 스테이커(Delegator)가 CandidateAddOn에 WTON을 예치하는 기능을 구현했습니다.
  - WTON Approve -> Deposit 과정을 `bind.TransactOpts`를 사용하여 수행합니다.

```go
func delegatorDeposit(
    t *testing.T,
    sys *rat.TONStakingSystem,
    contracts *SlashingContracts,
    delegatorAuth *bind.TransactOpts,
    candidateAddOn common.Address,
    amount *big.Int,
) {
    // ... WTON Approve & Deposit ...
}
```

### 2. 테스트 케이스 구현 (`op-e2e/slashing/slashing_test.go`)
- **`TestSlashing_DelegatorProtection` 함수 추가**:
  1. **환경 설정**: Anvil 계정 #2를 Delegator로 설정하고, Deployer로부터 TON을 전송받아 WTON으로 스왑하여 자금을 마련했습니다.
  2. **Operator 등록**: 10,000 TON 스테이킹.
  3. **Delegator 예치**: `delegatorDeposit`을 사용하여 5,000 TON(상당의 WTON)을 예치했습니다.
  4. **시뮬레이션**: 14일 시간을 경과시킨 후, Operator에 대한 슬래싱을 실행했습니다.
  5. **검증**:
     - Operator의 지분은 0으로 전액 소각/보상되었습니다.
     - Delegator의 지분은 5,000 TON 그대로 보존됨을 확인했습니다.

### 3. Verification
테스트 실행 명령:
```bash
GOWORK=off go test -v ./slashing -run TestSlashing_DelegatorProtection
```

결과:
```
--- PASS: TestSlashing_DelegatorProtection (30.09s)
    slashing_test.go:304: Delegator stake after slashing: 5000000000000000000000000000000 WTON
    slashing_test.go:308: ✅ Test Passed: Delegator assets protected
PASS
```

## ✅ 결론
Operator 슬래싱 시 Delegator의 자산이 안전하게 보호됨을 E2E 레벨에서 검증 완료했습니다.
