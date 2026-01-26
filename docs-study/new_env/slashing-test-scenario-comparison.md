# Slashing Test Scenario Comparison

## Overview

이 문서는 두 개의 테스트 스위트를 비교합니다:
1. **Original (Monolithic)**: `test/Slashing/SlashingTest.t.sol` - 단일 파일에 모든 시나리오
2. **New (Modular)**: `test/v3/v3mode/BasicSlashing/` - 기능별로 분리된 테스트 파일들

---

## Test File Structure

### Original (test/Slashing/SlashingTest.t.sol)
- 단일 파일: 2,272 lines
- 18개 시나리오가 하나의 파일에 집중

### New (test/v3/v3mode/BasicSlashing/)
```
Slashing/
├── BaseSlashingTest.sol           # 공통 헬퍼 함수 (Base)
├── SlashingBasicTest.t.sol        # 기본 시나리오 (3개)
├── SlashingRewardRateTest.t.sol   # 보상률 테스트 (4개)
├── SlashingSeigniorageTest.t.sol  # 시뇨리지 테스트 (3개)
├── SlashingSecurityTest.t.sol     # 보안 테스트 (4개)
├── SlashingMultiOperatorTest.t.sol# 다중 운영자 테스트 (4개)
├── SlashingEdgeCaseTest.t.sol     # 엣지 케이스 테스트 (5개)
└── SlashingDelegatorTest.t.sol    # 위임자 보호 테스트 (4개) ✅ NEW
```

---

## Scenario Comparison Table

| # | Scenario (EN) | 시나리오 (KR) | Original | New File | Status |
|---|--------------|--------------|----------|----------|--------|
| 1 | Candidate Registration & Staking | 후보 등록 및 스테이킹 | `test_CandidateRegistrationAndStaking` | SlashingBasicTest | ✅ 동일 |
| 2 | Basic Slashing & Reward | 기본 슬래싱 및 보상 | `test_SlashingAndReward` | SlashingBasicTest | ✅ 동일 |
| 3 | 50% Reward Rate | 50% 보상 비율 | `test_Slashing_CustomRewardRate_50Percent` | SlashingRewardRateTest | ✅ 동일 |
| 4 | Principal + Seigniorage Burns | 원금+시뇨리지 소각 | `test_Slashing_WithSeigniorage_BurnsAll` | SlashingSeigniorageTest | ✅ 동일 |
| 5 | Unreceived Seigniorage Slashing | 미수령 시뇨리지 슬래싱 | `test_Slashing_WithUnreceivedSeigniorage` | SlashingSeigniorageTest | ✅ 동일 |
| 6 | Prevent Double Slashing | 중복 슬래싱 방지 | `test_Slashing_PreventDoubleSlashing` | SlashingSecurityTest | ✅ 동일 |
| 7 | Multiple Operators Independence | 다중 운영자 독립성 | `test_Slashing_MultipleOperators_Independence` | SlashingMultiOperatorTest | ✅ 동일 |
| 8 | Minimum Stake Slashing | 최소 스테이크 슬래싱 | `test_Slashing_BelowMinimumStake` | SlashingEdgeCaseTest | ✅ 동일 |
| 9 | Zero Reward Rate (All Burned) | 0% 보상 (전액 소각) | `test_Slashing_ZeroRewardRate_AllBurned` | SlashingRewardRateTest | ✅ 동일 |
| 10 | 100% Reward Rate | 100% 보상 비율 | `test_Slashing_FullRewardRate_100Percent` | SlashingRewardRateTest | ✅ 동일 |
| 11 | Multiple Challengers (First Wins) | 다중 챌린저 (선착순) | `test_Slashing_MultipleChallengers_FirstWins` | SlashingMultiOperatorTest | ✅ 동일 |
| 12 | Re-registration After Slashing | 슬래싱 후 재등록 | `test_Slashing_ReRegistrationAfterSlashing` | SlashingEdgeCaseTest | ✅ 동일 |
| 13 | Partial Withdrawal Then Slashing | 부분 출금 후 슬래싱 | `test_Slashing_AfterPartialWithdrawal` | SlashingEdgeCaseTest | ✅ 동일 |
| 14 | Invalid Game States | 잘못된 게임 상태 | `test_Slashing_InvalidGameStates` | SlashingEdgeCaseTest | ✅ 동일 |
| 15 | Event Emission Verification | 이벤트 발생 검증 | `test_Slashing_EventEmission` | SlashingBasicTest | ✅ 동일 |
| 16 | Unauthorized DepositManager Access | 비인가 DepositManager 접근 | `test_Slashing_UnauthorizedDepositManagerAccess` | SlashingSecurityTest | ✅ 동일 |
| 17 | Unauthorized SeigManager Access | 비인가 SeigManager 접근 | `test_Slashing_UnauthorizedSeigManagerAccess` | SlashingSecurityTest | ✅ 동일 |
| 18 | Delegator Seigniorage Protection | 위임자 시뇨리지 보호 | `test_Slashing_DelegatorSeigniorageProtection` | SlashingDelegatorTest | ✅ 추가됨 |
| 19 | New Delegator After Slashing | 슬래싱 후 새 위임자 | `test_Slashing_NewDelegatorAfterSlashing` | SlashingMultiOperatorTest | ✅ 동일 |
| 20 | Comprehensive Delegator Scenario | 종합 위임자 시나리오 | `test_Slashing_ComprehensiveDelegatorScenario` | SlashingDelegatorTest | ✅ 추가됨 |
| 21 | Debug UpdateSeigniorage | 시뇨리지 업데이트 디버그 | `test_Debug_UpdateSeigniorage` | SlashingSeigniorageTest | ✅ 동일 |

---

## New Tests (v3/v3mode Only)

| Scenario | File | Description |
|----------|------|-------------|
| `test_Slashing_DefaultRewardRate_10Percent` | SlashingRewardRateTest | 기본 10% 보상률 검증 |
| `test_Slashing_OnlyWinnerGetsReward` | SlashingSecurityTest | 승자만 보상 받는지 검증 |
| `test_Slashing_BothOperators_Sequential` | SlashingMultiOperatorTest | 순차적 양쪽 운영자 슬래싱 |
| `test_Slashing_LargeStake` | SlashingEdgeCaseTest | 대량 스테이크 (100만 TON) 슬래싱 |
| `test_Slashing_AllDelegatorsCanWithdrawAfterSlashing` | SlashingDelegatorTest | 다중 위임자 전체 출금 테스트 |
| `test_Slashing_DelegatorPartialWithdrawalThenSlashing` | SlashingDelegatorTest | 부분 출금 후 슬래싱 시나리오 |

---

## Previously Missing Scenarios - NOW ADDED ✅

### 1. Delegator Seigniorage Protection (위임자 시뇨리지 보호)

**Original**: `test_Slashing_DelegatorSeigniorageProtection`
**New**: ✅ `SlashingDelegatorTest.t.sol`

**테스트 내용**:
- Operator 등록 후 여러 delegator가 스테이킹
- 시간 경과로 시뇨리지 발생
- Operator만 슬래싱되고 delegator의 스테이크와 시뇨리지는 보호됨
- 슬래싱 후에도 delegator가 출금 가능한지 확인

### 2. Comprehensive Delegator Scenario (종합 위임자 시나리오)

**Original**: `test_Slashing_ComprehensiveDelegatorScenario`
**New**: ✅ `SlashingDelegatorTest.t.sol`

**테스트 내용**:
- Operator 등록
- Delegator1 스테이킹
- 시간 경과 (첫 번째 시뇨리지)
- Delegator2 중간 참여
- 추가 시간 경과 (두 번째 시뇨리지)
- 슬래싱 실행
- Delegator1이 더 많은 시뇨리지를 받았는지 검증 (더 오래 스테이킹)

### 3. Additional Delegator Tests (추가 테스트)

**New only**:
- `test_Slashing_AllDelegatorsCanWithdrawAfterSlashing` - 다중 위임자 출금
- `test_Slashing_DelegatorPartialWithdrawalThenSlashing` - 부분 출금 후 슬래싱

---

## Code Structure Improvements:

| 항목 | Original | New (v3/v3mode) |
|------|----------|-----------------|
| 코드 재사용 | 반복 코드 많음 | BaseSlashingTest로 헬퍼 추출 |
| 파일 크기 | 2,272 lines | ~150-300 lines/file |
| 테스트 분류 | 무질서 | 기능별 분리 |
| 유지보수성 | 낮음 | 높음 |

---

## Summary

| 카테고리 | Original | New (v3/v3mode) | 상태 |
|---------|----------|-----------------|------|
| 기본 기능 | 2개 | 3개 | ✅ 확장됨 |
| 보상률 변경 | 3개 | 4개 | ✅ 확장됨 |
| 시뇨리지 | 3개 | 3개 | ✅ 동일 |
| 보안 | 3개 | 4개 | ✅ 확장됨 |
| 다중 운영자 | 2개 | 4개 | ✅ 확장됨 |
| 엣지 케이스 | 4개 | 5개 | ✅ 확장됨 |
| **위임자 보호** | **2개** | **4개** | ✅ 확장됨 |
| **총계** | **19개** | **27개** | ✅ +8개 (전체 커버리지 완료) |

### 결론
- 새로운 v3/v3mode 테스트는 구조적으로 개선되었고 테스트가 확장됨
- ✅ **모든 시나리오 커버리지 완료**: Original 테스트의 모든 시나리오 + 추가 테스트 포함
- ✅ **위임자 테스트 추가됨**: `SlashingDelegatorTest.t.sol` (4개 테스트)
