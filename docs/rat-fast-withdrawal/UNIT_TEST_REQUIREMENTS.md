# Fast Withdrawal 단위 테스트 요구사항

이 문서는 Fast Withdrawal 기능에 필요한 단위 테스트 목록을 정리합니다.

---

## 1. 관리자 함수 테스트

### 1.1 setOptimismPortal()

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| ADMIN-001 | test_setOptimismPortal_success | 정상적으로 Portal 주소 설정 | ✅ 완료 |
| ADMIN-002 | test_setOptimismPortal_revertNonOwner | 비소유자 호출 시 revert | ✅ 완료 |
| ADMIN-003 | test_setOptimismPortal_emitEvent | OptimismPortalSet 이벤트 발생 | ✅ 완료 |
| ADMIN-004 | test_setOptimismPortal_overwrite | 기존 설정 덮어쓰기 | ❌ 미구현 |
| ADMIN-005 | test_setOptimismPortal_zeroAddress | address(0) 설정 허용 여부 | ❌ 미구현 |

### 1.2 setFastWithdrawalEnabled()

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| ADMIN-006 | test_setFastWithdrawalEnabled_toggle | true/false 토글 | ✅ 완료 |
| ADMIN-007 | test_setFastWithdrawalEnabled_revertNonOwner | 비소유자 호출 시 revert | ✅ 완료 |
| ADMIN-008 | test_setFastWithdrawalEnabled_emitEvent | FastWithdrawalEnabledUpdated 이벤트 | ✅ 완료 |

### 1.3 setAggregatorFeeRate()

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| ADMIN-009 | test_setAggregatorFeeRate_success | 정상적으로 수수료율 설정 | ✅ 완료 |
| ADMIN-010 | test_setAggregatorFeeRate_revertTooHigh | rate > RAY 시 revert | ✅ 완료 |
| ADMIN-011 | test_setAggregatorFeeRate_emitEvent | AggregatorFeeRateUpdated 이벤트 | ✅ 완료 |
| ADMIN-012 | test_setAggregatorFeeRate_zeroRate | 0% 수수료 설정 | ❌ 미구현 |
| ADMIN-013 | test_setAggregatorFeeRate_maxRate | 100% (RAY) 수수료 설정 | ❌ 미구현 |

---

## 2. BLS 키 관리 함수 테스트

### 2.1 registerValidatorWithBLS()

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| BLS-001 | test_registerValidatorWithBLS_success | 정상 등록 (담보금 충분, 유효한 PoP) | ❌ 미구현 |
| BLS-002 | test_registerValidatorWithBLS_revertNotMigrated | V3 마이그레이션 전 revert | ❌ 미구현 |
| BLS-003 | test_registerValidatorWithBLS_revertInvalidSystemConfig | systemConfig == 0 시 revert | ❌ 미구현 |
| BLS-004 | test_registerValidatorWithBLS_revertInvalidPubKeyLength | 공개키 != 48 bytes 시 revert | ❌ 미구현 |
| BLS-005 | test_registerValidatorWithBLS_revertInvalidPoPLength | PoP != 96 bytes 시 revert | ❌ 미구현 |
| BLS-006 | test_registerValidatorWithBLS_revertAlreadyRegistered | 이미 등록된 검증자 | ❌ 미구현 |
| BLS-007 | test_registerValidatorWithBLS_revertInsufficientCollateral | 담보금 부족 | ❌ 미구현 |
| BLS-008 | test_registerValidatorWithBLS_revertInvalidPoP | PoP 검증 실패 | ❌ 미구현 |
| BLS-009 | test_registerValidatorWithBLS_emitEvent | BLSPublicKeyRegistered 이벤트 | ❌ 미구현 |

### 2.2 registerBLSPublicKey()

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| BLS-010 | test_registerBLSPublicKey_newKey | 기존 검증자가 새 BLS 키 등록 | ❌ 미구현 |
| BLS-011 | test_registerBLSPublicKey_updateKey | 기존 BLS 키 업데이트 | ❌ 미구현 |
| BLS-012 | test_registerBLSPublicKey_revertNotActive | 비활성 검증자 revert | ❌ 미구현 |
| BLS-013 | test_registerBLSPublicKey_revertInvalidPubKeyLength | 공개키 길이 오류 | ❌ 미구현 |
| BLS-014 | test_registerBLSPublicKey_revertInvalidPoPLength | PoP 길이 오류 | ❌ 미구현 |
| BLS-015 | test_registerBLSPublicKey_revertInvalidPoP | PoP 검증 실패 | ❌ 미구현 |
| BLS-016 | test_registerBLSPublicKey_emitRegisteredEvent | 새 키 등록 시 Registered 이벤트 | ❌ 미구현 |
| BLS-017 | test_registerBLSPublicKey_emitUpdatedEvent | 키 업데이트 시 Updated 이벤트 | ❌ 미구현 |

### 2.3 View 함수들

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| BLS-018 | test_getValidatorBLSPubKey_registered | 등록된 키 조회 | ❌ 미구현 |
| BLS-019 | test_getValidatorBLSPubKey_notRegistered | 미등록 시 빈 bytes | ❌ 미구현 |
| BLS-020 | test_getBatchValidatorBLSPublicKeys | 일괄 조회 | ❌ 미구현 |
| BLS-021 | test_hasValidatorBLSKey_true | 키 등록 상태 true | ❌ 미구현 |
| BLS-022 | test_hasValidatorBLSKey_false | 키 미등록 상태 false | ❌ 미구현 |
| BLS-023 | test_getActiveValidatorsWithBLS | BLS 키 포함 검증자 목록 조회 | ❌ 미구현 |

---

## 3. Fast Withdrawal 핵심 함수 테스트

### 3.1 verifyAndExecuteFastWithdrawal() - 사전 조건

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| FW-001 | test_fastWithdrawal_revertDisabled | 비활성화 시 revert | ✅ 완료 |
| FW-002 | test_fastWithdrawal_revertPortalNotSet | Portal 미설정 시 revert | ✅ 완료 |
| FW-003 | test_fastWithdrawal_revertAlreadyProcessed | 중복 처리 시 revert | ✅ 완료 |
| FW-004 | test_fastWithdrawal_revertInvalidHash | 해시 불일치 시 revert | ✅ 완료 |
| FW-005 | test_fastWithdrawal_revertPaused | paused 상태 시 revert | ❌ 미구현 |
| FW-006 | test_fastWithdrawal_revertReentrancy | 재진입 공격 방어 (ifFree) | ❌ 미구현 |

### 3.2 verifyAndExecuteFastWithdrawal() - BLS 서명 검증

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| FW-007 | test_fastWithdrawal_revertNoValidators | 검증자 0명 시 revert | ❌ 미구현 |
| FW-008 | test_fastWithdrawal_revertNotUnanimous | 서명자 수 != 검증자 수 | ❌ 미구현 |
| FW-009 | test_fastWithdrawal_revertInvalidBitmap | 비트맵 범위 초과 | ❌ 미구현 |
| FW-010 | test_fastWithdrawal_revertBLSKeyNotRegistered | BLS 키 미등록 검증자 | ❌ 미구현 |
| FW-011 | test_fastWithdrawal_revertInvalidSignature | BLS 서명 검증 실패 | ❌ 미구현 |

### 3.3 verifyAndExecuteFastWithdrawal() - 인접 리프 검증

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| FW-012 | test_fastWithdrawal_revertInvalidAdjacentLeaves | 인접 리프 검증 실패 | ❌ 미구현 |

### 3.4 verifyAndExecuteFastWithdrawal() - 성공 케이스

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| FW-013 | test_fastWithdrawal_success_singleValidator | 단일 검증자 성공 | ❌ 미구현 |
| FW-014 | test_fastWithdrawal_success_multipleValidators | 다중 검증자 성공 | ❌ 미구현 |
| FW-015 | test_fastWithdrawal_setsProcessedTrue | processedWithdrawals 업데이트 | ❌ 미구현 |
| FW-016 | test_fastWithdrawal_callsPortalSetVerified | Portal.setWithdrawalVerified 호출 | ❌ 미구현 |
| FW-017 | test_fastWithdrawal_callsPortalFinalize | Portal.fastWithdrawalFinalize 호출 | ❌ 미구현 |
| FW-018 | test_fastWithdrawal_emitEvent | FastWithdrawalExecuted 이벤트 | ❌ 미구현 |

---

## 4. 헬퍼 함수 테스트

### 4.1 _hashWithdrawal()

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| HELP-001 | test_hashWithdrawal_deterministic | 동일 입력 → 동일 출력 | ✅ 완료 |
| HELP-002 | test_hashWithdrawal_differentNonces | 다른 nonce → 다른 해시 | ✅ 완료 |
| HELP-003 | test_hashWithdrawal_differentValues | 다른 value → 다른 해시 | ✅ 완료 |
| HELP-004 | testFuzz_hashWithdrawal | Fuzz 테스트 | ✅ 완료 |

### 4.2 _countSetBits()

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| HELP-005 | test_countSetBits_zero | 0 → 0 | ✅ 완료 |
| HELP-006 | test_countSetBits_singleBit | 단일 비트 카운트 | ✅ 완료 |
| HELP-007 | test_countSetBits_multipleBits | 다중 비트 카운트 | ✅ 완료 |
| HELP-008 | test_countSetBits_allSet | uint256.max → 256 | ✅ 완료 |
| HELP-009 | testFuzz_countSetBits | Fuzz 테스트 | ✅ 완료 |

### 4.3 _aggregatePublicKeys()

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| HELP-010 | test_aggregatePublicKeys_singleKey | 단일 키 (집계 불필요) | ❌ 미구현 |
| HELP-011 | test_aggregatePublicKeys_multipleKeys | 다중 키 집계 | ❌ 미구현 |
| HELP-012 | test_aggregatePublicKeys_revertInvalidBitmap | 비트맵 오버플로우 | ❌ 미구현 |
| HELP-013 | test_aggregatePublicKeys_revertBLSKeyNotRegistered | 키 미등록 | ❌ 미구현 |

### 4.4 _distributeFastWithdrawalFees()

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| HELP-014 | test_distributeFees_zeroBalance | 잔액 0 시 스킵 | ❌ 미구현 |
| HELP-015 | test_distributeFees_aggregatorOnly | aggregatorFeeRate = 100% | ❌ 미구현 |
| HELP-016 | test_distributeFees_validatorsOnly | aggregatorFeeRate = 0% | ❌ 미구현 |
| HELP-017 | test_distributeFees_split | 90/10 분배 | ❌ 미구현 |
| HELP-018 | test_distributeFees_noValidatorReward | validatorReward = address(0) | ❌ 미구현 |
| HELP-019 | test_distributeFees_revertAggregatorTransferFailed | 집계자 전송 실패 | ❌ 미구현 |
| HELP-020 | test_distributeFees_revertValidatorTransferFailed | 검증자 전송 실패 | ❌ 미구현 |

---

## 5. 라이브러리 테스트

### 5.1 AdjacentLeavesVerifier

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| LIB-001 | test_verify_emptyProofs | 빈 증명 → false | ✅ 완료 |
| LIB-002 | test_verify_sameLeaves | 동일 리프 → false | ✅ 완료 |
| LIB-003 | test_verify_rootMismatch | 루트 불일치 → false | ✅ 완료 |
| LIB-004 | test_verify_validDirectSiblings | 직접 형제 → true | ✅ 완료 |
| LIB-005 | test_verify_deeperTree | 깊은 트리 인접 리프 | ✅ 완료 |
| LIB-006 | test_verifySimpleAdjacency_sameLeaves | 단순 인접 - 동일 리프 | ✅ 완료 |
| LIB-007 | test_verifySimpleAdjacency_directSiblings | 단순 인접 - 직접 형제 | ✅ 완료 |
| LIB-008 | test_verifySimpleAdjacency_withCommonProof | 공통 증명 포함 | ✅ 완료 |
| LIB-009 | test_computeRoot_singleProof | 단일 증명 루트 계산 | ✅ 완료 |
| LIB-010 | test_computeRoot_multipleProofs | 다중 증명 루트 계산 | ✅ 완료 |

### 5.2 BLS12381 (Precompile 필요 - Mock 테스트)

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| LIB-011 | test_parseG1Point_validLength | 48 bytes 유효 | ❌ 미구현 |
| LIB-012 | test_parseG1Point_invalidLength | != 48 bytes revert | ❌ 미구현 |
| LIB-013 | test_parseG2Point_validLength | 96 bytes 유효 | ❌ 미구현 |
| LIB-014 | test_parseG2Point_invalidLength | != 96 bytes revert | ❌ 미구현 |
| LIB-015 | test_verifyProofOfPossession_valid | 유효한 PoP | ❌ 미구현 |
| LIB-016 | test_verifyProofOfPossession_invalid | 무효한 PoP | ❌ 미구현 |
| LIB-017 | test_verifyAggregatedSignature_valid | 유효한 집계 서명 | ❌ 미구현 |
| LIB-018 | test_verifyAggregatedSignature_invalid | 무효한 집계 서명 | ❌ 미구현 |
| LIB-019 | test_aggregatePublicKeys_twoKeys | 2개 키 집계 | ❌ 미구현 |
| LIB-020 | test_countSetBits_library | 비트 카운트 | ❌ 미구현 |

---

## 6. 스토리지 테스트

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| STOR-001 | test_optimismPortals_mapping | Portal 매핑 읽기/쓰기 | ✅ 완료 |
| STOR-002 | test_processedWithdrawals_mapping | 처리 완료 매핑 | ✅ 완료 |
| STOR-003 | test_aggregatorFeeRate_storage | 수수료율 스토리지 | ❌ 미구현 |
| STOR-004 | test_fastWithdrawalEnabled_storage | 활성화 플래그 | ❌ 미구현 |

---

## 7. 통합 시나리오 테스트 (E2E)

| 테스트 ID | 테스트명 | 설명 | 상태 |
|-----------|---------|------|------|
| E2E-001 | test_fullFlow_singleValidator | 단일 검증자 전체 흐름 | ❌ 미구현 |
| E2E-002 | test_fullFlow_multipleValidators | 다중 검증자 전체 흐름 | ❌ 미구현 |
| E2E-003 | test_fullFlow_feeDistribution | 수수료 분배 포함 전체 흐름 | ❌ 미구현 |
| E2E-004 | test_fullFlow_withPortalInteraction | Portal 연동 전체 흐름 | ❌ 미구현 |

---

## 테스트 현황 요약

| 카테고리 | 완료 | 미구현 | 합계 |
|----------|------|--------|------|
| 관리자 함수 | 8 | 5 | 13 |
| BLS 키 관리 | 0 | 23 | 23 |
| Fast Withdrawal 핵심 | 4 | 14 | 18 |
| 헬퍼 함수 | 9 | 11 | 20 |
| 라이브러리 | 10 | 10 | 20 |
| 스토리지 | 2 | 2 | 4 |
| 통합 테스트 | 0 | 4 | 4 |
| **합계** | **33** | **69** | **102** |

---

## 우선순위 권장사항

### P0 (Critical) - 즉시 구현 필요
1. `test_fastWithdrawal_revertPaused` - 보안 관련
2. `test_fastWithdrawal_revertReentrancy` - 보안 관련
3. BLS-001 ~ BLS-008 (registerValidatorWithBLS 테스트)
4. FW-007 ~ FW-011 (BLS 서명 검증 테스트)

### P1 (High) - 다음 단계 구현
1. BLS-010 ~ BLS-017 (registerBLSPublicKey 테스트)
2. FW-013 ~ FW-018 (성공 케이스 테스트)
3. HELP-010 ~ HELP-020 (헬퍼 함수 테스트)

### P2 (Medium) - 안정화 후 구현
1. BLS-018 ~ BLS-023 (View 함수 테스트)
2. LIB-011 ~ LIB-020 (BLS12381 라이브러리 테스트)
3. E2E 테스트

### P3 (Low) - 나중에 구현
1. ADMIN-004, ADMIN-005, ADMIN-012, ADMIN-013
2. 나머지 스토리지 테스트

---

## 테스트 실행 명령어

```bash
# 전체 Fast Withdrawal 테스트 실행 (--via-ir 필요)
forge test --match-path test/v3/FastWithdrawal.t.sol -vv --via-ir

# 특정 테스트만 실행
forge test --match-test test_setOptimismPortal -vv --via-ir

# 가스 리포트와 함께 실행
forge test --match-path test/v3/FastWithdrawal.t.sol --gas-report --via-ir
```

---

*Last Updated: 2026-02-02*
