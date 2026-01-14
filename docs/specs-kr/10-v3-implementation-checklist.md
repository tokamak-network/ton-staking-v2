# V3 구현 체크리스트 및 개발 수정사항

이 문서는 Whitepaper V3 업그레이드에 따른 개발 수정/추가 사항을 정리합니다.

**참고 백서 파일**:
- V2 백서: `tokamak_economics_whitepaper_v2-2-20260106.pdf`
- V3 백서: `Tokamak_Economics_Whitepaper_V3.pdf`

---

## 0. 회의 결정사항 (2025-01)

### Issue 1: 시퀀서 담보금과 스테이킹 통합

| 항목 | 결정 |
|------|------|
| 담보금 시스템 | 기존 TON 스테이킹 시스템 활용 |
| **SequencerVault** | **불필요 (제거)** - 별도 Vault 대신 기존 스테이킹 활용 |
| 최소 스테이킹 조건 | `max(H_max · C_max + Δ_sequencer, θ · B_i)` |
| 슬래싱 동작 | 스테이킹(coinage) 전액 몰수, 시뇨리지 자격 상실 |
| L2 정지 | **물리적으로 정지하지 않음** (백서 수정 예정) |

### Issue 2: 검증자 최소 담보금 유연화

| 항목 | 결정 |
|------|------|
| 구현 방식 | `relaxedValidatorCheck` flag 추가 |
| 초기 설정 | `true` (유효성 검사 완화, C_off 기준) |
| 향후 | DAO 거버넌스로 `false` 전환 가능 (D_min 기준) |
| 등록 시 | 항상 D_min 이상 필요 (flag와 무관) |

---

## 1. 현재 구현 상태 요약

### 1.1 V3 기준 구현 완료 항목 ✅

| 항목 | 파일 | 백서 공식 |
|------|------|----------|
| 검증자 L2별 보상 분배 | `ValidatorRewardV1.sol` | Formula 13 |
| L2별 검증자 할당 | `RAT.sol` | V_i 개념 |
| 검증자 없으면 DAO 귀속 | `ValidatorRewardV1.sol` | p.17 |
| Bridged TON 기반 자격 | `SeigManagerV1_4.sol` | Formula 8, 9 |
| 쌍곡선 포화 함수 | `SeigManagerV1_4.sol` | Formula 11 |
| DAO 고정 분배 | `SeigManagerV1_4.sol` | Formula 7 |
| 최소 스테이킹 요건 | `SeigManagerV1_4.sol` | Rule 4 |

### 1.2 회의 결정에 따른 개발 항목 상태

#### 시퀀서 관련
| 항목 | 상태 | 비고 |
|------|------|------|
| **SequencerVault DEPRECATED** | ✅ 완료 | 기존 스테이킹으로 대체 |
| **`getSequencerStaked()` 함수** | ✅ 완료 | coinage 조회 |
| **최소 스테이킹 조건** | ✅ 완료 | `max(D_seq, θ·B_i)` |
| **시퀀서 슬래싱 로직** | ⚠️ 기본 구조 | coinage.burnFrom() |

#### 검증자 관련
| 항목 | 상태 | 비고 |
|------|------|------|
| **RAT 직접 예치 → coinage** | ❌ 미구현 | 기존 스테이킹으로 변경 필요 |
| **`_getValidatorCollateral()` 추가** | ❌ 미구현 | coinage 조회 |
| **RAT 슬래싱 로직 변경** | ❌ 미구현 | coinage.burnFrom() |
| **RAT 복구 로직 변경** | ❌ 미구현 | coinage.mint() 또는 잠금 해제 |
| **relaxedValidatorCheck flag** | ✅ 완료 | RAT.sol, RATStorage.sol, IRAT.sol |

#### 공통
| 항목 | 상태 | 비고 |
|------|------|------|
| **L2 물리적 정지 로직 제거** | ✅ 완료 | 해당 로직 없음 확인 |
| 슬래싱 후 자격 재평가 | ✅ 완료 | checkCurrentEligibility() |

---

## 2. 개발 체크리스트

### 2.1 Issue 1: 시퀀서 담보금/스테이킹 통합 + SequencerVault 제거

#### 핵심 변경: SequencerVault → 기존 스테이킹

**V3 결정**: 시퀀서 담보금 = 기존 TON 스테이킹 (SequencerVault 불필요)

| 항목 | 현재 (SequencerVault) | V3 (기존 스테이킹) |
|------|----------------------|-------------------|
| 담보금 예치 | Vault에 별도 예치 | DepositManager에 스테이킹 |
| 자격 체크 | `SequencerVault.getSequencerDepositByLayer2()` | `SeigManager.getSequencerStaked(layer2)` |
| 슬래싱 | Vault에서 차감 | coinage에서 차감 |
| 자본 효율성 | 낮음 (중복 자금) | 높음 (단일 자금) |

#### 구현 요구사항

```solidity
// SeigManagerV1_4.sol - V3 구현
function getSequencerStaked(address layer2) public view returns (uint256) {
    // V3: 기존 스테이킹에서 조회 (SequencerVault 미사용)
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    if (address(coinage) == address(0)) return 0;

    address operator = Layer2I(layer2).operator();
    if (operator == address(0)) return 0;

    return coinage.balanceOf(operator);
}

// 최소 스테이킹 조건 (checkCurrentEligibility 수정)
minRequiredStake = max(H_max · C_max + Δ_sequencer, θ · B_i)
```

#### 체크리스트

- [x] **SequencerVault DEPRECATED 처리** ✅
- [x] **`getSequencerStaked()` 함수** - coinage에서 조회 ✅
- [ ] **슬래싱 로직** - coinage 차감 방식 (기본 구조 완료, 상세 구현 필요)
- [x] 현재 `checkCurrentEligibility()` 함수가 두 조건 모두 체크하는지 확인 ✅
- [x] 두 조건의 max 값을 사용하도록 수정 ✅
- [ ] 슬래싱 시 전액 몰수 로직 (상세 구현 필요)
- [x] **L2 물리적 정지 로직** - 해당 로직 없음 확인 ✅

#### 수정 완료 파일

| 파일 | 수정 내용 | 상태 |
|------|----------|------|
| `src/stake/managers/SeigManagerV1_4Storage.sol` | `sequencerVault` DEPRECATED, `sequencerAdditionalReward`, `slashedGames` 추가 | ✅ |
| `src/stake/managers/SeigManagerV1_4.sol` | `getSequencerStaked()` coinage 조회, `checkCurrentEligibility()` max 조건 | ✅ |

### 2.2 Issue 2: 검증자 유효성 검사 유연화

#### 구현 요구사항

```solidity
// RATStorage.sol에 추가
bool public relaxedValidatorCheck;  // 초기값: true (완화)

// RAT.sol에 추가
function setRelaxedValidatorCheck(bool _relaxed) external onlyOwner {
    relaxedValidatorCheck = _relaxed;
    emit RelaxedValidatorCheckUpdated(_relaxed);
}

function registerValidator(address systemConfig, uint256 depositAmount) external {
    // 등록 시 항상 D_min 이상 필요 (flag와 무관)
    require(depositAmount >= minValidatorDeposit, "Insufficient deposit");
    // ... 기존 등록 로직
}

// 등록 후 유효성 검사 (flag에 따라 기준 변경)
function isValidValidator(address layer2, address validator) public view returns (bool) {
    uint256 stake = stakeOf(layer2, validator);
    if (relaxedValidatorCheck) {
        return stake >= C_off;  // 완화
    } else {
        return stake >= D_min;  // 엄격
    }
}
```

#### 체크리스트

- [x] `RATStorage.sol`: `relaxedValidatorCheck` 변수 추가 ✅
- [x] `RAT.sol`: `setRelaxedValidatorCheck()` 함수 추가 ✅
- [x] `RAT.sol`: `registerValidator()` 내 무조건 D_min 체크 ✅
- [x] `IRAT.sol`: 인터페이스 업데이트 ✅
- [x] 초기화 시 `relaxedValidatorCheck = true` 설정 (기본값, 완화) ✅
- [x] 테스트 케이스 추가 ✅

#### 수정 완료 파일

| 파일 | 수정 내용 | 상태 |
|------|----------|------|
| `src/validator/RATStorage.sol` | `relaxedValidatorCheck` 변수 추가 | ✅ |
| `src/validator/RAT.sol` | `setRelaxedValidatorCheck()` 함수, 무조건 D_min 체크 | ✅ |
| `src/validator/IRAT.sol` | `setRelaxedValidatorCheck()`, `RelaxedValidatorCheckUpdated` 이벤트 | ✅ |

### 2.3 Issue 3: 검증자 담보금 → 기존 스테이킹 (신규)

#### 핵심 변경: RAT 직접 예치 → coinage 사용

**V3 결정**: 검증자 담보금도 시퀀서와 동일하게 기존 TON 스테이킹 사용

| 항목 | V2 (RAT 직접 예치) | V3 (coinage) |
|------|-------------------|--------------|
| 담보금 예치 | RAT에 TON 전송 | DepositManager 스테이킹 |
| 자격 체크 | `RAT.depositedAmount` | `stakeOf(layer2, validator)` |
| 슬래싱 (C_off) | `depositedAmount -= C_off` | `coinage.burnFrom(validator, C_off)` |
| 복구 | `depositedAmount += C_off` | `coinage.mint()` 또는 잠금 해제 |

#### 구현 요구사항

```solidity
// RAT.sol - V3 수정 필요
function _getValidatorCollateral(address validator, address systemConfig) internal view returns (uint256) {
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    RefactorCoinageSnapshotI coinage = SeigManagerI(seigManager).coinages(layer2);
    return SeigManagerI(seigManager).stakeOf(layer2, validator);
}

// RAT 슬래싱
function _slashValidator(address validator, address systemConfig, uint256 amount) internal {
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    RefactorCoinageSnapshotI coinage = SeigManagerI(seigManager).coinages(layer2);
    coinage.burnFrom(validator, amount);
}

// RAT 복구 (옵션 1: mint)
function _restoreValidator(address validator, address systemConfig, uint256 amount) internal {
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    RefactorCoinageSnapshotI coinage = SeigManagerI(seigManager).coinages(layer2);
    coinage.mint(validator, amount);
}
```

#### 체크리스트

- [ ] **RAT 직접 예치 로직 제거**
  - [ ] `registerValidator()` - TON 전송 로직 제거
  - [ ] `depositedAmount` 관련 로직 제거
  - [ ] `addDeposit()` 함수 제거 또는 변경
- [ ] **`_getValidatorCollateral()` 추가** - coinage 조회
- [ ] **슬래싱 로직 변경**
  - [ ] `triggerAttentionTest()` - coinage.burnFrom() 사용
  - [ ] 또는 잠금 방식으로 변경
- [ ] **복구 로직 변경**
  - [ ] `submitEvidence()` - coinage.mint() 또는 잠금 해제
  - [ ] `resolveClaim()` - coinage.mint() 또는 잠금 해제
- [ ] **테스트 케이스 수정**
- [ ] **스펙 문서 업데이트**

#### 설계 결정 필요

**옵션 1: 즉시 burn/mint 방식**
```
트리거 → coinage.burnFrom(C_off) → 응답 → coinage.mint(C_off)
```
- 장점: 단순함
- 단점: 빈번한 burn/mint

**옵션 2: 잠금 방식**
```
트리거 → lockedAmount += C_off → 응답 → lockedAmount -= C_off
                              → 미응답 → coinage.burnFrom(C_off)
```
- 장점: 실제 슬래싱 시에만 burn
- 단점: 잠금 상태 관리 필요

#### 수정 대상 파일

| 파일 | 수정 내용 | 상태 |
|------|----------|------|
| `src/validator/RAT.sol` | coinage 연동, 슬래싱/복구 로직 | ❌ 미구현 |
| `src/validator/RATStorage.sol` | depositedAmount 제거, 잠금 관련 추가 | ❌ 미구현 |
| `src/validator/IRAT.sol` | 인터페이스 업데이트 | ❌ 미구현 |

---

## 3. 기존 이슈 상태 (08 문서 참조)

### 3.1 해결된 이슈 ✅

| 이슈 | 상태 | 해결 방법 |
|------|------|----------|
| 시퀀서/검증자 담보금 분리 | **해결됨** | 기존 스테이킹 시스템 활용 |
| 검증자 담보금 N_max | **해결됨** | relaxedValidatorCheck flag로 유연화 |

### 3.2 검토 필요 이슈 ⚠️

#### 3.2.1 RAT 검증자 랜덤 선택 알고리즘

**백서** (p.8):
> "validators are randomly selected at unpredictable times"

**확인 필요**:
```
src/validator/RAT.sol:triggerAttentionTest() 함수 검토
- 랜덤 소스: blockhash? VRF?
- 예측 불가능성 보장 여부
```

#### 3.2.2 Multi-Challenger 추적

**백서** (p.10, Formula 2):
```
R_challenger = C_max + Δ_sequencer / n
```

**확인 필요**:
- DisputeGame에서 복수 챌린저 추적 방식

---

## 4. 향후 개발 항목

### 4.1 Fast Withdrawal (미구현)

**우선순위**: 낮음 (별도 모듈로 구현 예정)

### 4.2 Multi-Sequencer 지원

**현재 상태**: 단일 시퀀서 모델
**향후 계획**: Multi-Sequencer 지원 시 슬래싱 로직 수정 필요

---

## 5. 테스트 체크리스트

### 5.1 신규 테스트 상태

#### 시퀀서 관련
| 테스트 케이스 | 파일 | 상태 |
|--------------|------|------|
| `max(D_sequencer, θ·B_i)` 조건 검증 | `SeigManager.t.sol` | ✅ 완료 |
| 슬래싱 후 시뇨리지 자격 상실 | `SeigManager.t.sol` | ⚠️ 상세 구현 시 |

#### 검증자 관련
| 테스트 케이스 | 파일 | 상태 |
|--------------|------|------|
| 등록 시 D_min 미만 거부 (항상) | `RAT.t.sol` | ✅ 완료 |
| `relaxedValidatorCheck` 유효성 검사 | `RAT.t.sol` | ✅ 완료 |
| 검증자 담보금 coinage 조회 | `RAT.t.sol` | ❌ 구현 필요 |
| RAT 슬래싱 coinage.burnFrom() | `RAT.t.sol` | ❌ 구현 필요 |
| RAT 복구 coinage.mint() | `RAT.t.sol` | ❌ 구현 필요 |

### 5.2 기존 테스트 확인

| 테스트 | 파일 | 상태 |
|--------|------|------|
| 검증자 L2별 분배 | `ValidatorRewardV1.t.sol` | ✅ |
| 검증자 없으면 DAO | `ValidatorRewardV1.t.sol` | ✅ |
| 쌍곡선 포화 함수 | `SeigniorageFormulaValidation.t.sol` | ✅ |

---

## 6. 액션 아이템 요약

### 6.1 시퀀서 관련 - 완료 ✅

| # | 항목 | 파일 | 상태 |
|---|------|------|------|
| 1 | **SequencerVault DEPRECATED** | `SeigManagerV1_4Storage.sol` | ✅ |
| 2 | **`getSequencerStaked()` 함수** | `SeigManagerV1_4.sol` | ✅ |
| 3 | **최소 스테이킹 조건 `max()`** | `SeigManagerV1_4.sol` | ✅ |
| 4 | **시퀀서 슬래싱 로직** | `SeigManagerV1_4.sol` | ⚠️ 기본 구조 |

### 6.2 검증자 관련 - 구현 필요 ❌

| # | 항목 | 파일 | 상태 |
|---|------|------|------|
| 1 | **RAT 직접 예치 제거** | `RAT.sol` | ❌ |
| 2 | **`_getValidatorCollateral()` 추가** | `RAT.sol` | ❌ |
| 3 | **RAT 슬래싱 로직 변경** | `RAT.sol` | ❌ |
| 4 | **RAT 복구 로직 변경** | `RAT.sol` | ❌ |
| 5 | `relaxedValidatorCheck` flag 추가 | `RAT.sol`, `RATStorage.sol` | ✅ |

### 6.3 단기 (중간)

| # | 항목 | 담당 |
|---|------|------|
| 4 | 신규 테스트 케이스 작성 | QA팀 |
| 5 | RAT 랜덤 선택 알고리즘 검토 | 개발팀 |

### 6.3 장기 (낮음)

| # | 항목 | 담당 |
|---|------|------|
| 6 | Fast Withdrawal 모듈 설계 | 아키텍처팀 |
| 7 | Multi-Sequencer 지원 설계 | 아키텍처팀 |

---

## 7. 결론

**시퀀서 관련 - 구현 완료** ✅:
1. **SequencerVault DEPRECATED** → ✅ 완료
2. **`getSequencerStaked()` coinage 조회** → ✅ 완료
3. **최소 스테이킹 조건 `max(D_seq, θ·B_i)`** → ✅ 완료
4. **시퀀서 슬래싱 로직** → ⚠️ 기본 구조 완료

**검증자 관련 - 구현 필요** ❌:
1. **RAT 직접 예치 → coinage 사용** → ❌ 미구현
2. **`_getValidatorCollateral()` coinage 조회** → ❌ 미구현
3. **RAT 슬래싱/복구 로직 coinage 연동** → ❌ 미구현
4. **`relaxedValidatorCheck` flag** → ✅ 완료

**테스트 결과**: 198 passed, 0 failed (2026-01-14)
> ⚠️ 검증자 coinage 연동 후 테스트 수정 필요

---

## 관련 문서

- [09-whitepaper-v2-to-v3-changes.md](./09-whitepaper-v2-to-v3-changes.md): V2→V3 변경사항
- [08-whitepaper-spec-comparison.md](./08-whitepaper-spec-comparison.md): 백서 vs 스펙 비교
- [07-economics-whitepaper-summary.md](./07-economics-whitepaper-summary.md): V3 백서 요약
