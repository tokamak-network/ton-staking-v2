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
| **RAT 직접 예치 → coinage** | ✅ 완료 | 기존 스테이킹으로 변경 |
| **`_getValidatorCollateral()` 추가** | ✅ 완료 | coinage 조회 |
| **RAT 슬래싱 로직 변경** | ✅ 완료 | validator→RAT coinage 전송 (burn/mint) |
| **RAT 복구 로직 변경** | ✅ 완료 | RAT→validator coinage 전송 (burn/mint) |
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

### 2.3 Issue 3: 검증자 담보금 → 기존 스테이킹 (✅ 구현 완료)

#### 핵심 변경: RAT 직접 예치 → coinage 사용

**V3 결정**: 검증자 담보금도 시퀀서와 동일하게 기존 TON 스테이킹 사용

| 항목 | V2 (RAT 직접 예치) | V3 (coinage) - 구현 완료 |
|------|-------------------|--------------------------|
| 담보금 예치 | RAT에 TON 전송 | DepositManager 스테이킹 (별도 예치 불필요) |
| 자격 체크 | `RAT.depositedAmount` | `stakeOf(layer2, validator)` |
| 선차감 (트리거 시) | `depositedAmount -= C_off` | validator→RAT coinage 전송 (burn/mint) |
| 복구 (응답 시) | `depositedAmount += C_off` | RAT→validator coinage 전송 (burn/mint) |
| 슬래싱 확정 (타임아웃) | C_off 영구 몰수 | RAT이 coinage 보유, treasury로 전송 가능 |

#### 구현 완료 코드

```solidity
// RAT.sol - V3 구현 완료 ✅
function _getValidatorCollateral(address validator, address systemConfig) internal view returns (uint256) {
    address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
    if (layer2 == address(0)) return 0;
    return ISeigManagerForRAT(seigManager).stakeOf(layer2, validator);
}

// 선차감: validator coinage → RAT coinage (SeigManager 경유)
function _transferCoinageToRAT(address validator, address systemConfig, uint256 amount) internal {
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    ISeigManagerForRAT(seigManager).transferCoinageToRAT(layer2, validator, amount);
}

// 복구: RAT coinage → validator coinage (SeigManager 경유)
function _transferCoinageFromRAT(address validator, address systemConfig, uint256 amount) internal {
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    ISeigManagerForRAT(seigManager).transferCoinageFromRAT(layer2, validator, amount);
}

// SeigManagerV1_4.sol - RAT 연동 함수 (onlyRAT modifier 적용)
function transferCoinageToRAT(address layer2, address validator, uint256 amount) external onlyRAT {
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    coinage.burnFrom(validator, amount);
    coinage.mint(ratContract, amount);
}

function transferCoinageFromRAT(address layer2, address validator, uint256 amount) external onlyRAT {
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    coinage.burnFrom(ratContract, amount);
    coinage.mint(validator, amount);
}
```

> **핵심**: RAT은 coinage를 직접 조작할 권한이 없으므로, SeigManager를 통해 burn/mint를 수행합니다.
> **배포 시**: `SeigManagerV1_4.setRATContract(ratAddress)` 호출 필요

#### 체크리스트 (✅ 모두 완료)

- [x] **RAT 직접 예치 로직 제거**
  - [x] `registerValidator()` - TON 전송 로직 제거
  - [x] `depositedAmount` → `lockedForRAT`으로 변경
  - [x] `addDeposit()` 함수 제거
- [x] **`_getValidatorCollateral()` 추가** - coinage 조회
- [x] **슬래싱 로직 변경**
  - [x] `triggerAttentionTest()` - `_transferCoinageToRAT()` 사용
  - [x] `slashExpiredTest()` - 타임아웃 시 슬래싱 확정
- [x] **복구 로직 변경**
  - [x] `submitEvidence()` - `_transferCoinageFromRAT()` 사용
  - [x] `resolveClaim()` - `_transferCoinageFromRAT()` 사용
- [x] **스펙 문서 업데이트**

#### 설계 결정: 선차감-전송-복구 방식

**구현된 방식** (옵션 1 + 옵션 2 결합):
```
트리거 → validator→RAT coinage 전송 (C_off) → 응답 → RAT→validator coinage 전송 (C_off)
        lockedForRAT += C_off                        lockedForRAT -= C_off
                                              → 미응답/타임아웃 → RAT이 보유 (treasury로 전송 가능)
                                                                  lockedForRAT -= C_off
```
- 장점: 총 공급량 유지, 선차감으로 슬래싱 보장
- RAT coinage는 treasury로 전송 가능 (`withdrawSlashingsToTreasury`)

#### 수정 완료 파일

| 파일 | 수정 내용 | 상태 |
|------|----------|------|
| `src/validator/RAT.sol` | SeigManager 경유 coinage 전송, 슬래싱/복구 로직 | ✅ 완료 |
| `src/validator/RATStorage.sol` | `depositedAmount` → `lockedForRAT` | ✅ 완료 |
| `src/validator/IRAT.sol` | 인터페이스 업데이트 | ✅ 완료 |
| `src/stake/managers/SeigManagerV1_4.sol` | RAT 연동 함수 추가 (`transferCoinageToRAT`, `transferCoinageFromRAT`) | ✅ 완료 |
| `src/stake/managers/SeigManagerV1_4Storage.sol` | `ratContract` 변수 추가 | ✅ 완료 |
| `src/stake/interfaces/ISeigManagerV3.sol` | RAT 연동 인터페이스 추가 | ✅ 완료 |

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
| 검증자 담보금 coinage 조회 | `RAT.t.sol` | ⚠️ 테스트 업데이트 필요 |
| RAT 슬래싱 (validator→RAT coinage 전송) | `RAT.t.sol` | ⚠️ 테스트 업데이트 필요 |
| RAT 복구 (RAT→validator coinage 전송) | `RAT.t.sol` | ⚠️ 테스트 업데이트 필요 |

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

### 6.2 검증자 관련 - 구현 완료 ✅

| # | 항목 | 파일 | 상태 |
|---|------|------|------|
| 1 | **RAT 직접 예치 제거** | `RAT.sol` | ✅ |
| 2 | **`_getValidatorCollateral()` 추가** | `RAT.sol` | ✅ |
| 3 | **RAT 슬래싱 로직 변경** | `RAT.sol` | ✅ |
| 4 | **RAT 복구 로직 변경** | `RAT.sol` | ✅ |
| 5 | `relaxedValidatorCheck` flag 추가 | `RAT.sol`, `RATStorage.sol` | ✅ |

### 6.3 단기 (중간)

| # | 항목 | 담당 |
|---|------|------|
| 1 | RAT 테스트 케이스 업데이트 (coinage 연동) | QA팀 |
| 2 | RAT 랜덤 선택 알고리즘 검토 | 개발팀 |

### 6.4 장기 (낮음)

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

**검증자 관련 - 구현 완료** ✅:
1. **RAT 직접 예치 → coinage 사용** → ✅ 완료
2. **`_getValidatorCollateral()` coinage 조회** → ✅ 완료
3. **RAT 슬래싱 로직** → ✅ 완료 (validator→RAT coinage 전송)
4. **RAT 복구 로직** → ✅ 완료 (RAT→validator coinage 전송)
5. **`relaxedValidatorCheck` flag** → ✅ 완료

**테스트**: 기존 RAT 테스트를 coinage 연동에 맞게 업데이트 필요
> ⚠️ RAT 테스트 케이스가 새로운 coinage 전송 방식에 맞게 수정되어야 함

---

## 관련 문서

- [09-whitepaper-v2-to-v3-changes.md](./09-whitepaper-v2-to-v3-changes.md): V2→V3 변경사항
- [08-whitepaper-spec-comparison.md](./08-whitepaper-spec-comparison.md): 백서 vs 스펙 비교
- [07-economics-whitepaper-summary.md](./07-economics-whitepaper-summary.md): V3 백서 요약
