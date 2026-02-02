---
id: scenario-tests
title: 시나리오 테스트
sidebar_position: 4
---

# 시나리오 테스트 (18개)

전체 워크플로우 및 복합 시나리오 테스트를 포함합니다.

## V3ScenarioReal.t.sol (8개)

### V3 마이그레이션 및 기본 시나리오

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| E2E-001 | test_E2E001_v3Migration | V3 마이그레이션 전체 플로우 |
| E2E-002 | test_E2E002_registerCandidateType3 | TYPE 3 후보 등록 |
| E2E-003 | test_E2E003_validatorDepositToRAT | 검증자 RAT 예치 |
| E2E-004 | test_E2E004_multipleValidatorsDeposit | 다중 검증자 예치 |
| E2E-005 | test_E2E005_updateSeigniorageAfterMigration | 마이그레이션 후 시뇨리지 업데이트 |
| E2E-006 | test_E2E006_updateSeigniorageMultipleTimes | 시뇨리지 다중 업데이트 |

### 검증자 생명주기 시나리오

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| E2E-012 | test_E2E012_validatorDeactivateAndReregister | 검증자 비활성화 후 재등록 |
| E2E-040 | test_E2E040_fullV3Scenario | V3 전체 시나리오 |

---

## MigrationScenarios.t.sol (7개)

### 마이그레이션 기본 시나리오

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| MIG-001 | test_MIG001_migrateToV3_success | 마이그레이션 성공 |
| MIG-002 | test_MIG002_migrateToV3_alreadyMigrated | 중복 마이그레이션 revert |
| MIG-003 | test_MIG003_migrateToV3_recordBlock | 마이그레이션 블록 기록 |

### 마이그레이션 후 상태 검증

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| MIG-010 | test_MIG010_migration_preservesStaking | 기존 스테이킹 보존 |
| MIG-011 | test_MIG011_migration_parametersPreset | 파라미터 사전 설정 |
| MIG-012 | test_MIG012_migration_firstV3Distribution | 첫 V3 분배 |
| MIG-013 | test_MIG013_migration_eligibilityReevaluation | 자격 재평가 |

---

## SequencerJourney.t.sol (3개)

### 시퀀서 전체 여정

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SCENSEQ-001 | test_SCENSEQ001_newSequencer_fullJourney | 신규 시퀀서 전체 여정 |
| SCENSEQ-002 | test_SCENSEQ002_sequencer_eligibilityTransition | 시퀀서 자격 전환 |
| SCENSEQ-003 | test_SCENSEQ003_sequencer_slashingRecovery | 시퀀서 슬래싱 복구 |

**커버리지:**
- 시퀀서 등록
- 초기 예치 및 자격 획득
- 시뇨리지 분배 및 보상 획득
- 자격 상실 및 재획득
- 슬래싱 이벤트 및 복구

---

## ValidatorJourney.t.sol (4개)

### 검증자 전체 여정

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SCENVAL-001 | test_SCENVAL001_validator_rewardClaim_fullJourney | 검증자 보상 청구 전체 여정 |
| SCENVAL-002 | test_SCENVAL002_validator_slashing_concept | 검증자 슬래싱 개념 |
| SCENVAL-003 | test_SCENVAL003_validator_reactivation_concept | 검증자 재활성화 개념 |
| SCENVAL-004 | test_SCENVAL004_validator_multiL2_rewards | 검증자 다중 L2 보상 |

**커버리지:**
- 검증자 등록 및 담보금 예치
- RAT 트리거 및 증거 제출
- 보상 분배 및 청구
- 슬래싱 및 복구 프로세스
- 다중 L2 참여 시나리오
- 비활성화 및 재활성화

---

## 시나리오 테스트 특징

### 통합 테스트 범위
- **컨트랙트 간 상호작용**: 여러 컨트랙트가 협력하는 복잡한 플로우
- **상태 전이 검증**: 시스템 상태의 전체 생명주기
- **엣지 케이스**: 실제 운영 환경에서 발생 가능한 경계 조건

### 실행 특징
- **실제 환경 시뮬레이션**: 프로덕션 환경과 유사한 조건
- **다단계 검증**: 각 단계별 상태 확인 및 검증
- **가스 효율성**: 실제 운영 비용 측정

---

## 다음 단계

- [Go E2E 테스트](e2e-tests.md) - op-e2e 통합 테스트
- [RAT Client 유닛 테스트](rat-client-unit-tests.md) - RAT Client Go 테스트
- [테스트 개요로 돌아가기](overview.md)
