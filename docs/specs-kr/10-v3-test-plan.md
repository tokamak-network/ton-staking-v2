# TON Staking V3 테스트 계획서

> **작성일**: 2026-01-21
> **최종 수정일**: 2026-01-22 (테스트 구현 현황 업데이트)
> **대상 버전**: TON Staking V3 (SeigManagerV1_4, RAT, ValidatorReward)
> **참조 문서**: Tokamak Economics Whitepaper V3

---

## 목차

- [1. 개요](#1-개요)
- [2. 단위 테스트 (Unit Tests)](#2-단위-테스트-unit-tests)
- [3. 통합 테스트 (Integration Tests)](#3-통합-테스트-integration-tests)
- [4. E2E 시나리오 테스트](#4-e2e-시나리오-테스트)
- [5. 엣지 케이스 테스트](#5-엣지-케이스-테스트)
- [6. 보안 테스트](#6-보안-테스트)
- [7. 테스트 우선순위](#7-테스트-우선순위)
- [8. 테스트 파일 현황](#8-테스트-파일-현황)

---

## 1. 개요

### 1.1 테스트 목적

TON Staking V3 시스템의 핵심 기능을 검증하여 다음을 보장합니다:

1. **시뇨리지 분배 정확성**: 백서 공식대로 DAO/시퀀서/검증자에게 정확히 분배
2. **RAT 메커니즘 안정성**: 검증자 선택, 슬래싱, 복구 프로세스의 정확성
3. **자격 검증 정확성**: 시퀀서/검증자 담보금 조건 검증
4. **보안**: 권한 검증, 재진입 방지, 랜덤 조작 방지

### 1.2 테스트 대상 컨트랙트

| 컨트랙트 | 역할 | 테스트 파일 |
|---------|------|------------|
| SeigManagerV1_4 | V3 시뇨리지 분배 | `SeigManagerV1_4Real.t.sol`, `SeigniorageDistribution.t.sol` |
| RAT | Randomized Attention Test | `RAT.t.sol` |
| ValidatorReward | 검증자 보상 분배 | `ValidatorRewardV1.t.sol` |
| Layer2ManagerV1_2 | L2 등록/관리 | `Layer2ManagerV1_2Real.t.sol` |
| L1BridgeRegistryV1_2 | L1 브릿지 정보 관리 | `L1BridgeRegistryV1_2Real.t.sol` |
| DepositManagerV1_2 | 스테이킹 예치/출금 | `DepositManagerV1_2Real.t.sol` |

### 1.3 핵심 공식 (백서 V3 기준)

```
시뇨리지 분배:
- y(x) = L × (x / (k + x))           // 쌍곡선 포화 함수
- S_i = y(x) × (B̃_i / x)            // 개별 L2 시뇨리지
- 시퀀서 보상: (1-α) × S_i
- 검증자 보상: α × S_i / |V_i|
- DAO 분배: d × A + (L - y(x))       // 고정 + 미분배분

자격 조건:
- 시퀀서: T_i ≥ max(D_sequencer, θ × B_i)
- 검증자: D_validator = C_off + Δ_validator

RAT 균형 조건:
- C_off ≥ (c_m × n) / π_a
```

---

## 2. 단위 테스트 (Unit Tests)

### 2.1 SeigManagerV1_4 테스트

#### 2.1.1 쌍곡선 포화 함수

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SM-001 | `hyperbolicSaturation(0, L)` | x=0일 때 y=0 반환 | ✅ |
| SM-002 | `hyperbolicSaturation(k, L)` | x=k일 때 y=L/2 반환 (반포화점) | ✅ |
| SM-003 | `hyperbolicSaturation(∞, L)` | x→∞일 때 y→L 수렴 | ✅ |
| SM-004 | 단조 증가 검증 | x 증가 시 y 단조 증가 | ✅ |
| SM-005 | Fuzz 테스트 | 임의 x, L에서 y ≤ L 검증 | ✅ |

#### 2.1.2 시퀀서 보상 계산

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SM-010 | `calculateSequencerReward()` 기본 | α=20%일 때 시퀀서 80% 수령 | ✅ |
| SM-011 | α=0 검증 | 검증자 없을 때 시퀀서 100% 수령 | ✅ |
| SM-012 | Fuzz 테스트 | 임의 α, seig에서 정확성 검증 | ✅ |

#### 2.1.3 자격 검증

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SM-020 | `checkCurrentEligibility()` 충족 | T_i ≥ max(D_seq, θ×B_i) 시 eligible=true | ⚠️ |
| SM-021 | `checkCurrentEligibility()` 미달 | T_i < max(D_seq, θ×B_i) 시 eligible=false | ⚠️ |
| SM-022 | D_sequencer 계산 | H_max × C_max + Δ_sequencer 검증 | ✅ |
| SM-023 | θ×B_i 계산 | TON→WTON 단위 변환 검증 | ✅ |

#### 2.1.4 V3 파라미터 Setter

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SM-030 | `setDaoDistributionRatio()` | d 설정 (0 < d < 1) | ✅ |
| SM-031 | `setMinStakingRatio()` | θ 설정 (0 < θ ≤ 1) | ✅ |
| SM-032 | `setValidatorDistributionRatio()` | α 설정 (0 < α < 1) | ✅ |
| SM-033 | `setHalfSaturationPoint()` | k 설정 (k > 0) | ✅ |
| SM-034 | ~~`setStakedSeigFactor()`~~ | ~~λ 설정~~ | N/A (V3에서 제거) |
| SM-035 | 범위 초과 revert | 파라미터 범위 검증 | ✅ |

#### 2.1.5 RAT 연동 함수

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SM-040 | `transferCoinageToRAT()` | validator→RAT coinage 전송 | ✅ |
| SM-041 | `transferCoinageFromRAT()` | RAT→validator coinage 복구 | ✅ |
| SM-042 | `transferCoinageFromRATTo()` | RAT→Treasury coinage 전송 | ✅ |
| SM-043 | onlyRAT 권한 검증 | RAT 외 호출 시 revert | ✅ |

#### 2.1.6 마이그레이션

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SM-050 | `migrateToV3()` 실행 | v3Migrated=true 설정 | ✅ |
| SM-051 | 중복 마이그레이션 방지 | 이미 마이그레이션된 상태에서 revert | ✅ |
| SM-052 | 마이그레이션 블록 기록 | v3MigrationBlock 설정 검증 | ✅ |

---

### 2.2 RAT 테스트

#### 2.2.1 검증자 등록/탈퇴

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| RAT-001 | `registerValidator()` 성공 | D_min 이상 담보금으로 등록 | ✅ |
| RAT-002 | `registerValidator()` 담보금 부족 | D_min 미만 시 revert | ✅ |
| RAT-003 | `registerValidator()` 중복 등록 | 이미 등록된 검증자 revert | ✅ |
| RAT-004 | `deactivateValidator()` 성공 | 활성 검증자 탈퇴 | ✅ |
| RAT-005 | `deactivateValidator()` 비활성 | 비활성 검증자 탈퇴 시 revert | ✅ |
| RAT-006 | 다중 검증자 등록 | 동일 L2에 여러 검증자 등록 | ✅ |
| RAT-007 | N_max 초과 검증 | 최대 검증자 수 초과 시 revert | ✅ |

#### 2.2.2 동적 담보금 계산

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| RAT-010 | `getDynamicMinimumCollateral()` | D_min = C_off + Δ_validator | ✅ |
| RAT-011 | `getDynamicCoff()` | C_off = max(slashingPenalty, (c_m×N)/π_a) | ✅ |
| RAT-012 | `getCoffWithRelaxedCheck()` relaxed | relaxed=true 시 slashingPenalty 반환 | ✅ |
| RAT-013 | `getCoffWithRelaxedCheck()` strict | relaxed=false 시 동적 C_off 반환 | ✅ |
| RAT-014 | attentionCost 설정 | c_m 설정 후 공식 적용 검증 | ✅ |

#### 2.2.3 RAT 트리거

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| RAT-020 | `triggerAttentionTest()` 성공 | 유효 factory에서 트리거 | ✅ |
| RAT-021 | 확률적 트리거 | π_a=0 시 트리거 안 됨 | ✅ |
| RAT-022 | 검증자 없을 때 | activeCount=0 시 무시 | ✅ |
| RAT-023 | 중복 테스트 방지 | 동일 batchIndex 재트리거 시 revert | ✅ |
| RAT-024 | 선차감 검증 | validator coinage→RAT coinage 전송 | ✅ |
| RAT-025 | 담보금 부족 시 제거 | remaining < threshold 시 검증자 제거 | ✅ |
| RAT-026 | 담보금 0 시 테스트 미생성 | available=0 시 테스트 없이 제거 | ✅ |

#### 2.2.4 증거 제출 및 복구

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| RAT-030 | `submitEvidence()` 성공 | deadline 전 증거 제출 시 복구 | ✅ |
| RAT-031 | `submitEvidence()` deadline 초과 | deadline 후 제출 시 revert | ✅ |
| RAT-032 | `submitEvidence()` 비선택 검증자 | 선택되지 않은 검증자 제출 시 revert | ✅ |
| RAT-033 | `resolveClaim()` ChallengePeriod | 챌린지 기간 내 승리 시 복구 | ✅ |
| RAT-034 | `resolveClaim()` 기간 초과 | challengeGameDuration 후 복구 불가 | ✅ |
| RAT-035 | 재활성화 (담보금 충분) | 복구 후 threshold 이상 시 자동 재활성화 | ✅ |
| RAT-036 | 재활성화 실패 (담보금 부족) | 복구 후 threshold 미만 시 비활성 유지 | ✅ |

#### 2.2.5 상태 조회

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| RAT-040 | `getAttentionTestStatus()` EvidencePeriod | deadline 전 상태 | ✅ |
| RAT-041 | `getAttentionTestStatus()` ChallengePeriod | deadline~challengeGameDuration 상태 | ✅ |
| RAT-042 | `getAttentionTestStatus()` Slashed | 전체 기간 경과 후 상태 | ✅ |
| RAT-043 | `getAttentionTestStatus()` RestoredByEvidence | 증거 제출 후 상태 | ✅ |
| RAT-044 | `getAttentionTestStatus()` RestoredByChallenge | 챌린지 승리 후 상태 | ✅ |

#### 2.2.6 Treasury 출금

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| RAT-050 | `withdrawSlashingsToTreasury()` 성공 | 전체 기간+safetyBuffer 경과 후 출금 | ✅ |
| RAT-051 | `withdrawSlashingsToTreasury()` 조기 호출 | 대기 기간 미경과 시 revert | ✅ |
| RAT-052 | Treasury 미설정 시 | treasury=0 시 revert | ✅ |

---

### 2.3 ValidatorReward 테스트

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| VR-001 | `distributeL2Rewards()` 기본 | α×S_i 검증자 풀로 분배 | ⚠️ |
| VR-002 | 검증자 0명 시 DAO 귀속 | 검증자 없으면 α×S_i → DAO | ✅ |
| VR-003 | 다수 검증자 균등 분배 | (α×S_i)/|V_i| 균등 분배 | ✅ |
| VR-004 | 보상 claim | 검증자 개별 보상 수령 | ✅ |

---

### 2.4 시뇨리지 분배 테스트

#### 2.4.1 V3 분배 검증

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SD-010 | DAO 고정 분배 | S_DAO = d × A 검증 | ✅ |
| SD-011 | 미분배분 DAO 귀속 | L - y(x) → DAO 검증 | ✅ |
| SD-012 | 검증자/시퀀서 분배 | α×y, (1-α)×y 검증 | ✅ |
| SD-013 | 자격 미달 L2 제외 | T_i < required 시 B̃_i=0 | ✅ |
| SD-014 | 슬래싱된 L2 제외 | isPaused=true 시 분배 제외 | ✅ |
| SD-015 | 모든 L2 슬래싱 시 | 전액 DAO 귀속 | ✅ |

---

## 3. 통합 테스트 (Integration Tests)

### 3.1 Layer2 등록 플로우

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| INT-001 | L1BridgeRegistry 등록 | `registerRollupConfig()` TYPE 3 | ✅ |
| INT-002 | Layer2Manager 등록 | `registerCandidateAddOn()` | ✅ |
| INT-003 | OperatorManager 자동 생성 | factory에서 자동 생성 | ✅ |
| INT-004 | CandidateAddOn 자동 생성 | DAO.createCandidateAddOn() 호출 | ✅ |
| INT-005 | Coinage 자동 배포 | Layer2Registry.registerAndDeployCoinage() | ✅ |
| INT-006 | SystemConfig→Layer2 매핑 | `getLayer2BySystemConfig()` 검증 | ✅ |
| INT-007 | DisputeGameFactory 매핑 | rollupConfigWithDisputeGameFactory 검증 | ✅ |

### 3.2 스테이킹 플로우

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| INT-010 | DepositManager TON 예치 | TON → WTON → coinage | ⚠️ |
| INT-011 | DepositManager WTON 예치 | WTON → coinage | ⚠️ |
| INT-012 | 시퀀서 최소 담보금 V3 | max(θ×B_i, D_seq) 검증 | ✅ |
| INT-013 | 검증자 출금 제한 | D_min 이상 유지 검증 | ⚠️ (SeigManager 구현 필요) |
| INT-014 | `onStakingChange()` 콜백 | 스테이킹 변경 시 자격 자동 업데이트 | ⚠️ (V3ScenarioReal에서 통합 테스트) |
| INT-015 | `onDeposit()` 콜백 | 예치 시 tot/coinage mint | ✅ |
| INT-016 | `onWithdraw()` 콜백 | 출금 시 tot/coinage burn | ✅ |

### 3.3 RAT ↔ SeigManager 연동

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| INT-020 | Coinage 선차감 (실제) | validator→RAT 전송 (실제 컨트랙트) | ✅ |
| INT-021 | Coinage 복구 (실제) | RAT→validator 전송 (실제 컨트랙트) | ✅ |
| INT-022 | Coinage 슬래싱 (실제) | RAT→Treasury 전송 (실제 컨트랙트) | ✅ |
| INT-023 | 잔액 동기화 검증 | 전송 후 각 계정 잔액 검증 | ✅ |

### 3.4 Bridged TON 연동

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| INT-030 | `onBridgedTONChange()` 트리거 | OptimismPortal에서 호출 | ✅ |
| INT-031 | effectiveBridgedTON 업데이트 | 자격 상태에 따라 업데이트 | ✅ |
| INT-032 | totalEffectiveBridgedTON 동기화 | 전체 합계 동기화 | ✅ |

---

## 4. E2E 시나리오 테스트

### 4.1 V3 마이그레이션 시나리오

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| E2E-001 | V2 → V3 전환 | 파라미터 설정 + migrateToV3() | ✅ |
| E2E-002 | 기존 L2 자격 평가 | 마이그레이션 후 자동 평가 | ❌ |
| ~~E2E-003~~ | ~~V3 → V2 롤백~~ | ~~v3Migrated = false 전환~~ | N/A (롤백 불가) |
| E2E-004 | 마이그레이션 후 첫 시뇨리지 | V3 로직으로 분배 검증 | ⚠️ |

### 4.2 검증자 라이프사이클

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| E2E-010 | 정상 플로우 | 등록 → RAT 응답 → 보상 수령 | ⚠️ |
| E2E-011 | 슬래싱 플로우 | 등록 → RAT 미응답 → 슬래싱 | ✅ |
| E2E-012 | 재등록 플로우 | 탈퇴 → 재등록 | ✅ |
| E2E-013 | 재활성화 플로우 | 담보금 부족 → 강제 제거 → 복구 → 재활성화 | ✅ |
| E2E-014 | 다중 L2 검증자 | 동일 검증자가 여러 L2 등록 | ✅ |

### 4.3 시퀀서 슬래싱 시나리오

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| E2E-020 | Fraud Proof 슬래싱 | DisputeGame 연동 슬래싱 | ✅ |
| E2E-021 | 슬래싱 후 시뇨리지 중단 | isPaused 시 분배 제외 | ✅ |
| E2E-022 | L2 서비스 연속성 | 슬래싱 후에도 L2 정지 안 됨 | ✅ |
| E2E-023 | 챌린저 보상 지급 | slashedAmount / challengerCount | ✅ |

### 4.4 시뇨리지 분배 시나리오

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| E2E-030 | 단일 L2 분배 | 전체 y(x) 수령 | ✅ |
| E2E-031 | 다중 L2 비례 분배 | B̃_i / Σ B̃_i 비례 분배 | ✅ |
| E2E-032 | 자격 변동 시 분배 | 중간에 자격 상실/획득 | ✅ |
| E2E-033 | 블록 연속 분배 | 여러 블록 연속 updateSeigniorage | ⚠️ |
| E2E-034 | 보상 누적 검증 | 여러 기간 후 누적 보상 정확성 | ✅ |

### 4.5 전체 플로우 시나리오

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| E2E-040 | Full V3 Scenario | 마이그레이션 → L2 등록 → 검증자 등록 → 시뇨리지 분배 | ✅ |
| E2E-041 | Multi-Actor Scenario | 다수 시퀀서/검증자/스테이커 동시 참여 | ❌ |

---

## 5. 엣지 케이스 테스트

### 5.1 경계값 테스트

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| EDGE-001 | x = 0 (L2 없음) | 전액 DAO 귀속 | ✅ |
| EDGE-002 | x = k (반포화점) | y = L/2 검증 | ✅ |
| EDGE-003 | x → ∞ (큰 값) | y → L 수렴 검증 | ✅ |
| EDGE-004 | θ = 0 (담보금 없음) | 모든 L2 자격 충족 | ✅ |
| EDGE-005 | α = 0 (검증자 없음) | 전액 시퀀서로 | ✅ |
| EDGE-006 | d = 0 (DAO 없음) | 전액 L2로 | ✅ |
| EDGE-007 | d = 1 (전액 DAO) | L2 분배 없음 | ✅ |
| EDGE-008 | B_i = 0 (Bridged TON 없음) | 해당 L2 분배 없음 | ✅ |

### 5.2 동시성/순서 테스트

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| EDGE-010 | 동시 RAT 트리거 | 동일 검증자 중복 선택 방지 | ✅ |
| EDGE-011 | 동시 증거 제출 | 이미 응답한 테스트 거부 | ✅ |
| EDGE-012 | 스테이킹 변경 + RAT 동시 | 경쟁 상태 처리 | ✅ |
| EDGE-013 | 마이그레이션 중 시뇨리지 | 마이그레이션 트랜잭션 중 분배 | ❌ |

### 5.3 오버플로우/언더플로우

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| EDGE-020 | 대량 시뇨리지 분배 | RAY 단위 오버플로우 방지 | ⚠️ Fuzz |
| EDGE-021 | 0 나눗셈 방지 | x=0, totalEffective=0 시 | ✅ |
| EDGE-022 | 언더플로우 방지 | 출금 시 잔액 부족 | ✅ |

---

## 6. 보안 테스트

### 6.1 권한 테스트

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SEC-001 | onlyOwner 함수 | 비권한자 호출 거부 | ✅ |
| SEC-002 | onlyRAT 함수 | RAT 외 호출 거부 | ✅ |
| SEC-003 | onlyDepositManager | DepositManager 외 호출 거부 | ✅ |
| SEC-004 | onlyValidFactory | 유효 Factory만 트리거 | ✅ |
| SEC-005 | onlyL1BridgeOrRegistry | L1BridgeRegistry 외 거부 | ✅ |

### 6.2 재진입 공격 방지

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SEC-010 | ifFree modifier | 재진입 방지 테스트 | ✅ |
| SEC-011 | CEI 패턴 준수 | Checks-Effects-Interactions 검증 | ✅ |
| SEC-012 | 외부 호출 후 상태 | 외부 호출 후 상태 일관성 | ✅ |

### 6.3 랜덤 조작 방지

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SEC-020 | blockHash 기반 랜덤 | L2 시퀀서 조작 불가 검증 | ✅ |
| SEC-021 | 랜덤 분포 검증 | 균등 분포 통계 테스트 | ✅ |
| SEC-022 | timestamp 조작 방지 | timestamp 범위 검증 | ✅ |

### 6.4 입력 검증

| 테스트 ID | 테스트 항목 | 설명 | 상태 |
|-----------|------------|------|------|
| SEC-030 | Zero address 검증 | address(0) 입력 거부 | ✅ |
| SEC-031 | 파라미터 범위 검증 | 유효 범위 초과 시 revert | ✅ |
| SEC-032 | 배열 길이 검증 | 빈 배열, 과대 배열 처리 | ✅ |

---

## 7. 테스트 우선순위

### 7.1 🔴 높음 (필수 - P0)

마이그레이션 전 반드시 완료해야 하는 테스트:

| 우선순위 | 테스트 ID | 설명 | 상태 |
|---------|----------|------|------|
| 1 | INT-020~023 | RAT ↔ SeigManager 실제 연동 (Mock 대신 실제 컨트랙트) | ✅ 완료 |
| 2 | INT-013 | 검증자 출금 제한 (D_min 이상 유지 검증) | ⚠️ SeigManager 구현 필요 |
| 3 | E2E-031 | 다중 L2 시뇨리지 비례 분배 정확성 | ✅ 완료 |
| 4 | SEC-002, 003 | onlyRAT/onlyDepositManager 권한 검증 | ✅ 완료 |
| 5 | SM-040~043 | SeigManager RAT 연동 함수 테스트 | ✅ 완료 |

### 7.2 🟡 중간 (권장 - P1)

마이그레이션 후 운영 안정성을 위해 권장되는 테스트:

| 우선순위 | 테스트 ID | 설명 |
|---------|----------|------|
| 6 | E2E-020 | Fraud Proof 슬래싱 연동 (DisputeGame) |
| 7 | EDGE-010, 012 | 동시성 테스트 (경쟁 상태 처리) |
| 8 | SEC-010~012 | 재진입 공격 방지 (ifFree modifier) |
| 9 | VR-001~004 | ValidatorReward 분배 검증 |
| 10 | INT-030~032 | Bridged TON 연동 테스트 |

### 7.3 🟢 낮음 (선택 - P2)

향후 개선을 위해 추가 가능한 테스트:

| 우선순위 | 테스트 ID | 설명 |
|---------|----------|------|
| 11 | SEC-020~022 | 통계적 랜덤 분포 검증 |
| 12 | E2E-003 | V3 → V2 롤백 테스트 |
| 13 | E2E-041 | Multi-Actor 스트레스 테스트 |
| 14 | EDGE-004~008 | 추가 경계값 테스트 |

---

## 8. 테스트 파일 현황

### 8.1 현재 테스트 파일

```
test/v3/
├── RAT.t.sol                           # RAT 단위 테스트 (Mock 기반)
├── RATSeigManagerIntegration.t.sol     # RAT ↔ SeigManager 실제 연동 테스트 (신규)
├── SeigManagerV1_4Real.t.sol           # SeigManager 단위 테스트 (실제 배포)
├── SeigniorageDistribution.t.sol       # 시뇨리지 분배 단위 테스트 (Mock 기반)
├── SeigniorageFormulaValidation.t.sol  # 백서 공식 검증
├── ValidatorRewardV1.t.sol             # ValidatorReward 테스트
├── ValidatorWithdrawalRestriction.t.sol # 검증자 출금 제한 테스트 (신규)
├── V3ScenarioReal.t.sol                # E2E 시나리오 테스트 (실제 배포)
├── BasicFunctions.t.sol                # 기본 기능 테스트
├── Layer2ManagerV1_2Real.t.sol         # Layer2Manager 테스트
├── L1BridgeRegistryV1_2Real.t.sol      # L1BridgeRegistry 테스트
├── DepositManagerV1_2Real.t.sol        # DepositManager 테스트
├── MultiL2SeigniorageDistribution.t.sol # 다중 L2 분배 테스트 (신규)
└── SecurityPermissions.t.sol           # 권한 검증 테스트 (신규)
```

### 8.2 신규 추가된 테스트 파일 (2026-01-21 ~ 01-22)

```
test/v3/ (신규 추가)
├── RATSeigManagerIntegration.t.sol      # RAT ↔ SeigManager 실제 연동 테스트 ✅
├── ValidatorWithdrawalRestriction.t.sol # 검증자 출금 제한 테스트 ⚠️ (일부 skip)
├── MultiL2SeigniorageDistribution.t.sol # 다중 L2 분배 테스트 ✅
└── SecurityPermissions.t.sol            # 권한 검증 테스트 ✅
    ├── SEC-001~005: 권한 테스트 ✅
    ├── SEC-010~012: 재진입 방지 테스트 ✅
    ├── SEC-020~022: 랜덤 보안 테스트 ✅
    └── SEC-032: 배열 길이 검증 ✅
```

### 8.3 추가 필요 테스트

```
미구현 테스트 (❌):
├── E2E-002: 기존 L2 자격 평가 (마이그레이션 후 자동 평가)
├── E2E-041: Multi-Actor Scenario (다수 시퀀서/검증자/스테이커 동시 참여)
└── EDGE-013: 마이그레이션 중 시뇨리지 (마이그레이션 트랜잭션 중 분배)

부분 구현 테스트 (⚠️):
├── SM-020~021: checkCurrentEligibility 충족/미달
├── INT-010~011: DepositManager TON/WTON 예치
├── INT-013~014: 검증자 출금 제한, onStakingChange 콜백
├── VR-001: distributeL2Rewards 기본
├── E2E-004: 마이그레이션 후 첫 시뇨리지
├── E2E-010: 정상 플로우
├── E2E-033: 블록 연속 분배
└── EDGE-020: 대량 시뇨리지 분배 Fuzz
```

### 8.4 테스트 실행 명령

```bash
# 전체 V3 테스트 실행
forge test --match-path "test/v3/*.sol" -vvv

# 특정 테스트 파일 실행
forge test --match-path "test/v3/RAT.t.sol" -vvv

# 특정 테스트 함수 실행
forge test --match-test "test_registerValidator" -vvv

# Gas 리포트 포함
forge test --match-path "test/v3/*.sol" --gas-report

# Fork 테스트 (메인넷 상태 사용)
forge test --match-path "test/v3/*.sol" --fork-url $ETH_RPC_URL
```

---

## 부록: 테스트 상태 범례

| 상태 | 의미 |
|-----|------|
| ✅ | 테스트 완료 및 통과 |
| ⚠️ | 부분 구현 또는 Mock 기반 테스트 |
| ❌ | 테스트 미구현 (구현 필요) |
| N/A | 해당 없음 (기능 제거 또는 불필요) |

---

## 부록: 테스트 구현 현황 요약 (2026-01-22)

### 총 테스트 현황

| 카테고리 | 완료 (✅) | 부분 (⚠️) | 미구현 (❌) | N/A |
|---------|-----------|-----------|-------------|-----|
| SeigManager 단위 (SM) | 18 | 2 | 0 | 1 |
| RAT 단위 (RAT) | 26 | 0 | 0 | 0 |
| ValidatorReward (VR) | 3 | 1 | 0 | 0 |
| 시뇨리지 분배 (SD) | 6 | 0 | 0 | 0 |
| 통합 테스트 (INT) | 13 | 4 | 0 | 0 |
| E2E 시나리오 | 14 | 4 | 2 | 1 |
| 엣지 케이스 (EDGE) | 11 | 1 | 1 | 0 |
| 보안 테스트 (SEC) | 12 | 0 | 0 | 0 |
| **총계** | **103** | **12** | **3** | **2** |

### 구현률

- **완료율**: 103 / 118 = **87.3%**
- **부분 포함**: 115 / 118 = **97.5%**

### 핵심 테스트 완료 현황

- ✅ RAT ↔ SeigManager 연동 (INT-020~023)
- ✅ 다중 L2 시뇨리지 분배 (E2E-031)
- ✅ 권한 검증 (SEC-001~005)
- ✅ 재진입 방지 (SEC-010~012)
- ✅ 랜덤 보안 (SEC-020~022)
- ✅ Bridged TON 연동 (INT-030~032)
- ✅ Fraud Proof 슬래싱 (E2E-020~023)

---

*문서 끝*
