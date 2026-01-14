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
| 구현 방식 | `enforceMinDeposit` flag 추가 |
| 초기 설정 | `false` (최소 담보금 체크 안함) |
| 향후 | DAO 거버넌스로 `true` 전환 가능 |

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

### 1.2 회의 결정에 따른 개발 필요 항목 ⚠️

| 항목 | 상태 | 우선순위 |
|------|------|----------|
| **SequencerVault 제거/미사용** | 신규 개발 | **높음** |
| **SeigManager._getSequencerCollateral() 수정** | 신규 개발 | **높음** |
| **슬래싱 로직 이전 (coinage 차감)** | 신규 개발 | **높음** |
| **enforceMinDeposit flag** | 신규 개발 | **높음** |
| **최소 스테이킹 조건 통합** | 확인/수정 | 높음 |
| **L2 물리적 정지 로직 제거** | 확인/수정 | 높음 |
| 슬래싱 후 자격 재평가 | 확인 | 중간 |

---

## 2. 개발 체크리스트

### 2.1 Issue 1: 시퀀서 담보금/스테이킹 통합 + SequencerVault 제거

#### 핵심 변경: SequencerVault → 기존 스테이킹

**V3 결정**: 시퀀서 담보금 = 기존 TON 스테이킹 (SequencerVault 불필요)

| 항목 | 현재 (SequencerVault) | V3 (기존 스테이킹) |
|------|----------------------|-------------------|
| 담보금 예치 | Vault에 별도 예치 | DepositManager에 스테이킹 |
| 자격 체크 | `SequencerVault.getSequencerDepositByLayer2()` | `coinage.balanceOf(operator)` |
| 슬래싱 | Vault에서 차감 | coinage에서 차감 |
| 자본 효율성 | 낮음 (중복 자금) | 높음 (단일 자금) |

#### 구현 요구사항

```solidity
// SeigManagerV1_4.sol - 현재
function _getSequencerCollateral(address layer2) internal view returns (uint256) {
    return ISequencerVault(sequencerVault).getSequencerDepositByLayer2(layer2);
}

// SeigManagerV1_4.sol - V3 수정
function _getSequencerCollateral(address layer2) internal view returns (uint256) {
    // V3: 기존 스테이킹에서 조회 (SequencerVault 미사용)
    address operator = Layer2I(layer2).operator();
    return _coinages[layer2].balanceOf(operator);
}

// 최소 스테이킹 조건 (checkCurrentEligibility 수정)
minRequiredStake = max(H_max · C_max + Δ_sequencer, θ · B_i)
```

#### 체크리스트

- [ ] **SequencerVault 제거/미사용 처리**
- [ ] **`_getSequencerCollateral()` 수정** - coinage에서 조회
- [ ] **슬래싱 로직 이전** - coinage 차감 방식으로 변경
- [ ] 현재 `checkCurrentEligibility()` 함수가 두 조건 모두 체크하는지 확인
- [ ] 두 조건의 max 값을 사용하도록 수정 (필요 시)
- [ ] 슬래싱 시 전액 몰수 로직 확인 (coinage에서 차감)
- [ ] **L2 물리적 정지 로직이 있다면 제거**

#### 수정 대상 파일

| 파일 | 수정 내용 |
|------|----------|
| `src/sequencer/SequencerVault.sol` | **제거 또는 deprecated 처리** |
| `src/stake/managers/SeigManagerV1_4.sol` | `_getSequencerCollateral()` 수정, 슬래싱 로직 추가 |
| `src/stake/managers/SeigManagerV1_4Storage.sol` | `sequencerVault` 변수 제거, 슬래싱 파라미터 추가 |

### 2.2 Issue 2: 검증자 최소 담보금 유연화

#### 구현 요구사항

```solidity
// RATStorage.sol에 추가
bool public enforceMinDeposit;  // 초기값: false

// RAT.sol에 추가
function setEnforceMinDeposit(bool _enforce) external onlyOwner {
    enforceMinDeposit = _enforce;
    emit EnforceMinDepositChanged(_enforce);
}

function registerValidator(address systemConfig, uint256 depositAmount) external {
    // 초기에는 체크 안함 (enforceMinDeposit = false)
    if (enforceMinDeposit) {
        require(depositAmount >= minValidatorDeposit, "Insufficient deposit");
    }
    // ... 기존 등록 로직
}
```

#### 체크리스트

- [ ] `RATStorage.sol`: `enforceMinDeposit` 변수 추가
- [ ] `RAT.sol`: `setEnforceMinDeposit()` 함수 추가
- [ ] `RAT.sol`: `registerValidator()` 내 조건부 체크 로직 추가
- [ ] `IRAT.sol`: 인터페이스 업데이트
- [ ] 초기화 시 `enforceMinDeposit = false` 설정
- [ ] 테스트 케이스 추가

#### 수정 대상 파일

| 파일 | 수정 내용 |
|------|----------|
| `src/validator/RATStorage.sol` | `enforceMinDeposit` 변수 추가 |
| `src/validator/RAT.sol` | setter 함수 및 조건부 로직 |
| `src/validator/IRAT.sol` | 인터페이스 |

---

## 3. 기존 이슈 상태 (08 문서 참조)

### 3.1 해결된 이슈 ✅

| 이슈 | 상태 | 해결 방법 |
|------|------|----------|
| 시퀀서/검증자 담보금 분리 | **해결됨** | 기존 스테이킹 시스템 활용 |
| 검증자 담보금 N_max | **해결됨** | enforceMinDeposit flag로 유연화 |

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

### 5.1 신규 테스트 필요

| 테스트 케이스 | 파일 | 우선순위 |
|--------------|------|----------|
| `enforceMinDeposit = false` 시 검증자 등록 | `RAT.t.sol` | **높음** |
| `enforceMinDeposit = true` 시 담보금 부족 거부 | `RAT.t.sol` | **높음** |
| 슬래싱 후 시뇨리지 자격 상실 | `SeigManager.t.sol` | 높음 |
| `max(D_sequencer, θ·B_i)` 조건 검증 | `SeigManager.t.sol` | 높음 |

### 5.2 기존 테스트 확인

| 테스트 | 파일 | 상태 |
|--------|------|------|
| 검증자 L2별 분배 | `ValidatorRewardV1.t.sol` | ✅ |
| 검증자 없으면 DAO | `ValidatorRewardV1.t.sol` | ✅ |
| 쌍곡선 포화 함수 | `SeigniorageFormulaValidation.t.sol` | ✅ |

---

## 6. 액션 아이템 요약

### 6.1 즉시 필요 (높음)

| # | 항목 | 담당 | 파일 |
|---|------|------|------|
| 1 | **SequencerVault 제거/미사용** | 개발팀 | `SequencerVault.sol` |
| 2 | **`_getSequencerCollateral()` 수정** | 개발팀 | `SeigManagerV1_4.sol` |
| 3 | **슬래싱 로직 이전 (coinage 차감)** | 개발팀 | `SeigManagerV1_4.sol` |
| 4 | `enforceMinDeposit` flag 추가 | 개발팀 | `RAT.sol`, `RATStorage.sol` |
| 5 | 최소 스테이킹 조건 확인/수정 (`max()`) | 개발팀 | `SeigManagerV1_4.sol` |
| 6 | L2 물리적 정지 로직 확인/제거 | 개발팀 | 관련 슬래싱 코드 |

### 6.2 단기 (중간)

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

**회의 결정으로 V3 변경 방향이 명확해졌습니다**:

1. **SequencerVault 제거**: 별도 Vault 불필요, 기존 스테이킹 시스템 활용 → **개발 필요**
2. **시퀀서 담보금**: coinage에서 조회, `max(D_sequencer, θ·B_i)` 조건 → **개발 필요**
3. **슬래싱**: coinage에서 차감, L2 물리적 정지 없음 → **개발 필요**
4. **검증자 담보금**: `enforceMinDeposit` flag로 유연화, 초기값 `false` → **개발 필요**

---

## 관련 문서

- [09-whitepaper-v2-to-v3-changes.md](./09-whitepaper-v2-to-v3-changes.md): V2→V3 변경사항
- [08-whitepaper-spec-comparison.md](./08-whitepaper-spec-comparison.md): 백서 vs 스펙 비교
- [07-economics-whitepaper-summary.md](./07-economics-whitepaper-summary.md): V3 백서 요약
