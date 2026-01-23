# 슬래싱 E2E 테스트 시나리오 3: 슬래싱 후 재스테이킹 (Re-staking after Slashing)

## 🎯 목표
Operator가 슬래싱당한 후:
1. Operator의 스테이크가 0인 상태에서는 시뇨리지(Seigniorage)가 발생하지 않음을 검증합니다.
2. Operator가 다시 스테이킹(Re-staking)을 할 수 있는지 검증합니다.
3. 재스테이킹 후에는 시뇨리지가 정상적으로 발생하는지 검증합니다.

## 📋 진행 상황
- [x] 시나리오 1: 기본 Operator 슬래싱 (완료)
- [x] 시나리오 2: 일반 스테이커 보호 (완료)
- [x] 시나리오 3: 슬래싱 후 재스테이킹 (완료)

---

## 🔧 구현 계획

### 1. 헬퍼 함수 검토 (`op-e2e/slashing/slashing_helpers.go`)

기존 헬퍼 함수들을 재사용할 수 있을 것으로 보입니다.
- `registerOperatorWithCandidateAddOn`: 초기 등록
- `delegatorDeposit`: (필요시) 추가 예치
- `executeSlashing`: 슬래싱 실행
- `getStakeBalance`: 잔액 확인

추가적으로, 시뇨리지 발생 여부를 정밀하게 확인하기 위한 헬퍼가 필요할 수 있습니다.
- `checkSeigniorageAccrual`: 특정 기간 동안 시뇨리지가 증가했는지 확인하는 로직 (테스트 코드 내 구현)

### 2. 테스트 케이스 작성 (`op-e2e/slashing/slashing_test.go`)

새로운 테스트 함수 `TestSlashing_ReRegistrationAfterSlashing`를 추가합니다.

#### 테스트 시나리오 흐름
1. **환경 설정 & Operator 등록**: 
   - 10,000 TON 스테이킹.
2. **Slashing 실행**:
   - Dispute Game 생성 -> Challenge -> Resolve -> Slashing.
   - Operator 스테이크가 0이 됨을 확인.
3. **시뇨리지 중단 검증**:
   - 시간 경과 (예: 100일).
   - `updateSeigniorage` 호출.
   - 스테이크가 여전히 0인지(혹은 증가하지 않는지) 확인. (스테이크가 0이면 시뇨리지 배분 로직상 받을 지분이 0이어야 함)
4. **Re-staking (재예치)**:
   - Operator가 다시 10,000 TON을 예치.
   - `DepositManager.deposit` 사용.
5. **시뇨리지 재개 검증**:
   - 시간 경과 (예: 100일).
   - `updateSeigniorage` 호출.
   - 스테이크가 `원금 + 시뇨리지`로 증가했는지 확인.

#### 예상 코드 구조

```go
func TestSlashing_ReRegistrationAfterSlashing(t *testing.T) {
    t.Parallel()
    // ... setup ...

    // 1. Register & Slash
    candidateAddOn, operatorManager := registerOperatorWithCandidateAddOn(...)
    // ... execute slashing ...
    // Verify stake is 0

    // 2. Verify NO Seigniorage
    rat.AdvanceTimeAndMine(t, sys, 100000)
    // Try update seigniorage (if applicable helpers exist or manual call)
    stake := getStakeBalance(..., operatorManager)
    require.Equal(t, 0, stake.Cmp(big.NewInt(0)), "Stake should remain 0")

    // 3. Re-stake
    // Operator needs WTON. Swap TON->WTON if needed or use previous funds if any left (likely 0).
    // Mint/Transfer new TON to Operator.
    // Approve & Deposit.
    
    // 4. Verify Seigniorage Resumes
    rat.AdvanceTimeAndMine(t, sys, 100000)
    stakeAfter := getStakeBalance(..., operatorManager)
    require.True(t, stakeAfter.Cmp(reStakedAmount) > 0, "Seigniorage should accrue")
}
```

---

## 📅 작업 순서

1. **`slashing_test.go` 업데이트**: `TestSlashing_ReRegistrationAfterSlashing` 함수 구현
2. **테스트 실행 및 검증**:
   ```bash
   go test -v ./op-e2e/slashing -run TestSlashing_ReRegistrationAfterSlashing
   ```
