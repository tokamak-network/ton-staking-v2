# 현재 구현(V2) → 새 백서(V3) 변경사항 분석

이 문서는 현재 개발된 구현(V2, 07-08 문서 기반)에서 새로운 백서(Tokamak Economics Whitepaper V3, December 16, 2025)로 변경되면서 수정해야 할 사항을 정리합니다.

---

## 1. 용어 정의

| 용어 | 의미 |
|------|------|
| **V2 (현재 구현)** | 07-08 문서 기반으로 개발된 현재 코드베이스 (백서: `tokamak_economics_whitepaper_v2-2-20260106.pdf`) |
| **V3 (새 백서)** | `Tokamak_Economics_Whitepaper_V3.pdf` (2025.12.16) |

---

## 2. 주요 변경사항 요약

| 구분 | V2 (현재 구현) | V3 (새 백서 + 회의 결정) | 영향도 |
|------|---------------|-------------------------|--------|
| **시퀀서 담보금** | SequencerVault 별도 예치 | 기존 TON 스테이킹 (coinage) | **높음** |
| **검증자 담보금** | RAT 컨트랙트 직접 예치 | 기존 TON 스테이킹 (coinage) | **높음** |
| **검증자 담보금 체크** | 항상 체크 | `relaxedValidatorCheck` flag로 유연화 | **높음** |
| **L2 슬래싱 시 정지** | 물리적 정지 가능 | 물리적으로 정지하지 않음 | **높음** |
| Bridged TON 측정 | 기간 평균값 논의 | 최신 온체인 값 사용 | 중간 |

---

## 3. 핵심 변경 1: 담보금 = 기존 TON 스테이킹 통합 (시퀀서 + 검증자)

### 3.1 V2 (현재 구현) - 08 문서 Issue 2.1

08 문서에서 논의 중이던 내용:

```
백서 공식:
  D_sequencer = H_max · C_max + Δ_sequencer  (시퀀서 슬래싱 담보금)
  D_validator = C_off + Δ_validator          (검증자 슬래싱 담보금)
  T_i ≥ θ · B_i                              (시뇨리지 자격)

버나드 답변:
  - 시뇨리지 자격 스테이킹과 슬래싱 담보금은 원래 **별도 Vault** 의도
  - 합칠지 여부는 추가 논의 필요
```

**현재 구현**:
- 시퀀서: SequencerVault에 별도 예치
- 검증자: RAT 컨트랙트에 직접 TON 예치

### 3.2 V3 (새 백서 + 회의 결정)

> **Issue 1: Sequencer/Validator Collateral = 기존 TON 스테이킹**

**결정 내용**:
1. **시퀀서와 검증자 모두** 기존 TON 스테이킹 시스템을 담보금으로 활용
2. 별도 Vault (SequencerVault, RAT 직접 예치) 불필요

#### 3.2.1 시퀀서 담보금

```solidity
// 시뇨리지 수령 조건:
T_i ≥ max(H_max · C_max + Δ_sequencer, θ · B_i)

// 담보금 조회:
collateral = SeigManager.getSequencerStaked(layer2)
```

**슬래싱 동작**:
- 슬래싱 시 스테이킹된 **모든 금액이 몰수**됨
- 시뇨리지를 받을 수 없게 됨 (경제적 제약)
- **L2는 물리적으로 정지되지 않음**

#### 3.2.2 검증자 담보금

```solidity
// 최소 담보금 (relaxedValidatorCheck = false 시):
D_validator = C_off + Δ_validator

// 담보금 조회:
collateral = stakeOf(layer2, validator)

// RAT 슬래싱:
coinage.burnFrom(validator, C_off)
```

**RAT 메커니즘 변경**:
- 트리거 시: 담보금 잠금 (논리적) 또는 즉시 차감
- 증거 제출 시: 담보금 복구 (잠금 해제 또는 mint)
- 미응답 시: 담보금 영구 몰수 (burn 확정)

### 3.3 변경의 의미

| 항목 | V2 (별도 Vault/예치) | V3 (스테이킹 통합) |
|------|---------------------|-------------------|
| 자본 효율성 | 낮음 (중복 예치) | 높음 (단일 예치) |
| 구현 복잡도 | 높음 (Vault + RAT 관리) | 낮음 (기존 시스템 활용) |
| 시퀀서 진입 장벽 | 높음 | 낮음 |
| 검증자 진입 장벽 | 높음 (별도 예치 필요) | 낮음 (기존 스테이킹 활용) |

### 3.4 구현 수정 사항

#### 시퀀서 (SeigManager)
- [x] 기존 TON 스테이킹 시스템 활용 (새로운 Vault 불필요)
- [x] **SequencerVault DEPRECATED** 처리 완료
- [x] **`_getSequencerCollateral()` 수정** - coinage에서 조회
- [x] 최소 스테이킹 조건: `max(D_sequencer, θ · B_i)` 체크 로직 완료
- [ ] 슬래싱 시 coinage burn (기본 구조 완료, 상세 구현 필요)
- [x] L2 물리적 정지 로직 제거 (해당 로직 없음 확인)

#### 검증자 (RAT)
- [x] **RAT 직접 예치 → coinage 사용으로 변경** ✅ 완료
- [x] **`_getValidatorCollateral()` 추가** - coinage에서 조회 ✅ 완료
- [x] **RAT 슬래싱 로직 변경** - validator→RAT coinage 전송 ✅ 완료
- [x] **RAT 복구 로직 변경** - RAT→validator coinage 전송 ✅ 완료
- [x] `relaxedValidatorCheck` flag 추가 완료

### 3.5 담보금 시스템 변경 상세

#### 3.5.1 시퀀서 (SequencerVault → coinage)

| 항목 | V2 (SequencerVault) | V3 (coinage) |
|------|----------------------|--------------|
| 담보금 예치 | Vault에 별도 예치 | DepositManager 스테이킹 |
| 자격 체크 | `SequencerVault.getDeposit()` | `SeigManager.getSequencerStaked(layer2)` |
| 슬래싱 | Vault에서 차감 | `coinage.burnFrom()` |

```solidity
// SeigManagerV1_4.sol - V3 구현 완료
function _getSequencerCollateral(address layer2) internal view returns (uint256) {
    address operator = Layer2I(layer2).operator();
    return _coinages[layer2].balanceOf(operator);
}
```

#### 3.5.2 검증자 (RAT 직접 예치 → coinage)

| 항목 | V2 (RAT 직접 예치) | V3 (coinage) |
|------|-------------------|--------------|
| 담보금 예치 | RAT에 TON 전송 | DepositManager 스테이킹 (별도 예치 불필요) |
| 자격 체크 | `RAT.depositedAmount` | `stakeOf(layer2, validator)` |
| 선차감 | `depositedAmount -= C_off` | validator coinage → RAT coinage 전송 |
| 복구 | `depositedAmount += C_off` | RAT coinage → validator coinage 전송 |
| 슬래싱 확정 | C_off 영구 몰수 | RAT coinage 보유 (treasury로 전송 가능) |

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

// SeigManagerV1_4.sol - RAT 연동 함수
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

#### 3.5.3 RAT 메커니즘 변경

**V2 (이전)**:
```
트리거 → depositedAmount -= C_off → 응답 → depositedAmount += C_off
                                  → 미응답 → C_off 영구 몰수
```

**V3 (구현됨)** - 선차감-전송-복구 방식:
```
트리거 → validator→RAT coinage 전송 (C_off) → 응답 → RAT→validator coinage 전송 (C_off)
        lockedForRAT += C_off                        lockedForRAT -= C_off
                                              → 미응답/타임아웃 → RAT이 보유 (treasury로 전송 가능)
                                                                  lockedForRAT -= C_off
```

> **핵심 변경**: 선차감 시 바로 burn하지 않고, RAT coinage로 전송. 복구 시 RAT에서 다시 전송.

---

## 4. 핵심 변경 2: 검증자 담보금 체크 유연화

### 4.1 V2 (현재 구현) - 08 문서 Issue 2.2

08 문서에서 논의 중이던 내용:

```
백서 공식:
  C_off ≥ (c_m × N) / π_a
  D_validator = C_off + Δ_validator

버나드 답변:
  - 검증자는 등록 시에만 최소 담보금 조건 충족하면 됨
  - N_max 하드코딩 불필요, Δ_validator 버퍼가 충분하면 됨
```

### 4.2 V3 (새 백서 + 회의 결정)

> **Issue 2: Validator Minimum Collateral Calculation Formula**

**결정 내용**:
1. 검증자 유효성 검사 완화 여부를 나타내는 **flag 추가**
2. **초기에는 유효성 검사를 완화**하도록 flag 설정 (`relaxedValidatorCheck = true`)
3. **등록 시에는 항상 D_min 이상 필요** (flag와 무관)

### 4.3 구현 요구사항

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

### 4.4 운영 계획

| 단계 | `relaxedValidatorCheck` | 설명 |
|------|-------------------------|------|
| **1단계 (초기)** | `true` | 검증자 유치 용이, C_off 기준 (완화) |
| 2단계 (성장기) | `false` | 보안 강화, D_min 기준 (엄격) |

### 4.5 수정 필요 파일

- [x] `src/validator/RAT.sol`: `relaxedValidatorCheck` flag 추가 (초기값 `true`) ✅ 완료
- [x] `src/validator/RATStorage.sol`: 저장소에 flag 추가 ✅ 완료
- [x] `src/validator/IRAT.sol`: 인터페이스 업데이트 ✅ 완료
- [ ] 거버넌스 연동: DAO에서 flag 제어 가능하도록

---

## 5. 핵심 변경 3: L2 슬래싱 시 동작

### 5.1 V2 (현재)

백서에는 슬래싱 시 L2가 정지된다는 내용이 있었음

### 5.2 V3 (새 백서 + 회의 결정)

**결정**:
- 슬래싱으로 **시뇨리지 수령 불가** (경제적 제재)
- **L2는 물리적으로 정지하지 않음**
- 백서에서 "L2 정지" 관련 내용 삭제 예정

### 5.3 수정 사항

- [x] L2 물리적 정지 로직이 있다면 제거 ✅ 해당 로직 없음 확인
- [x] 슬래싱 후 시뇨리지 자격만 상실하도록 확인 ✅ 완료

---

## 6. 기존 08 문서 이슈 해결 상태

| 08 문서 이슈 | 상태 | V3 결정 |
|-------------|------|---------|
| 2.1 시퀀서 담보금 (별도 Vault vs 통합) | **해결됨** | 기존 스테이킹 시스템 활용 |
| 2.2 검증자 담보금 N_max | **해결됨** | `relaxedValidatorCheck` flag로 유연화 |
| 1.1 S_i vs T_i 변수명 | **해결됨** | T_i=스테이킹, S_i=시뇨리지로 통일 |
| 1.2 RAT 선택 알고리즘 | 미해결 | 추가 검토 필요 |
| 1.3 Fast Withdrawal | 미해결 | 향후 별도 모듈 |
| 2.3 Multi-Challenger | 미해결 | 추가 검토 필요 |

---

## 7. 현재 구현 상태

### 7.1 이미 V3 기준으로 구현된 항목 ✅

| 항목 | 파일 | 상태 |
|------|------|------|
| 검증자 L2별 보상 분배 | `ValidatorRewardV1.sol` | ✅ 완료 |
| L2별 검증자 할당 (`V_i`) | `RAT.sol` | ✅ 완료 |
| 검증자 없으면 DAO 귀속 | `ValidatorRewardV1.sol` | ✅ 완료 |
| 최신 Bridged TON 사용 | `SeigManagerV1_4.sol` | ✅ 완료 |

### 7.2 V3 변경에 따른 개발 상태

#### 시퀀서 관련
| 항목 | 설명 | 상태 |
|------|------|------|
| **SequencerVault DEPRECATED** | 기존 스테이킹으로 대체 | ✅ 완료 |
| **`_getSequencerCollateral()` 수정** | coinage 조회 | ✅ 완료 |
| **최소 스테이킹 조건** | `max(D_sequencer, θ · B_i)` | ✅ 완료 |
| **시퀀서 슬래싱 로직** | coinage.burnFrom() | ⚠️ 기본 구조 |

#### 검증자 관련
| 항목 | 설명 | 상태 |
|------|------|------|
| **RAT 직접 예치 → coinage** | 기존 스테이킹으로 변경 | ✅ 완료 |
| **`_getValidatorCollateral()` 추가** | coinage 조회 | ✅ 완료 |
| **RAT 슬래싱 로직 변경** | validator→RAT coinage 전송 | ✅ 완료 |
| **RAT 복구 로직 변경** | RAT→validator coinage 전송 | ✅ 완료 |
| **relaxedValidatorCheck flag** | 유효성 검사 완화 플래그 | ✅ 완료 |

#### 공통
| 항목 | 설명 | 상태 |
|------|------|------|
| **L2 물리적 정지 로직 제거** | 슬래싱 시에도 L2 운영 | ✅ 해당 없음 |

---

## 8. 액션 아이템

### 시퀀서 관련 - 구현 완료 ✅

| # | 항목 | 파일 | 상태 |
|---|------|------|------|
| 1 | **SequencerVault DEPRECATED** | `SeigManagerV1_4Storage.sol` | ✅ 완료 |
| 2 | **`_getSequencerCollateral()` 수정** | `SeigManagerV1_4.sol` | ✅ 완료 |
| 3 | **최소 스테이킹 조건 `max()`** | `SeigManagerV1_4.sol` | ✅ 완료 |
| 4 | **시퀀서 슬래싱 로직** | `SeigManagerV1_4.sol` | ⚠️ 기본 구조 |

### 검증자 관련 - 구현 완료 ✅

| # | 항목 | 파일 | 상태 |
|---|------|------|------|
| 1 | **RAT 직접 예치 제거** | `RAT.sol` | ✅ 완료 |
| 2 | **`_getValidatorCollateral()` 추가** | `RAT.sol` | ✅ 완료 |
| 3 | **RAT 슬래싱 로직 변경** | `RAT.sol` | ✅ 완료 |
| 4 | **RAT 복구 로직 변경** | `RAT.sol` | ✅ 완료 |
| 5 | `relaxedValidatorCheck` flag | `RAT.sol`, `RATStorage.sol` | ✅ 완료 |

### 단기 (중간)

| # | 항목 |
|---|------|
| 1 | 검증자 담보금 coinage 연동 설계 |
| 2 | RAT 메커니즘 재설계 (burn/mint vs 잠금) |
| 3 | 신규 테스트 케이스 작성 |
| 4 | 스펙 문서 업데이트 |

---

## 9. 결론

**V3 백서 + 회의 결정으로 해결된 사항**:

1. **08 문서 Issue 2.1 (담보금 구조)**: 시퀀서 + 검증자 모두 기존 TON 스테이킹 활용 ✅
2. **08 문서 Issue 2.2 (검증자 담보금)**: `relaxedValidatorCheck` flag로 유연화 ✅
3. **L2 정지 정책**: 슬래싱 시에도 물리적으로 정지하지 않음 ✅

**시퀀서 - 개발 완료** ✅:
- ✅ SequencerVault DEPRECATED
- ✅ `_getSequencerCollateral()` → coinage 조회
- ✅ 최소 스테이킹 조건 `max(D_seq, θ·B_i)`
- ⚠️ 슬래싱 로직 - 기본 구조 완료

**검증자 - 개발 완료** ✅:
- ✅ RAT 직접 예치 → coinage 사용으로 변경
- ✅ `_getValidatorCollateral()` → coinage 조회
- ✅ RAT 슬래싱 로직 → validator→RAT coinage 전송 (burn/mint)
- ✅ RAT 복구 로직 → RAT→validator coinage 전송 (burn/mint)
- ✅ `relaxedValidatorCheck` flag 추가 완료

---

## 관련 문서

- [07-economics-whitepaper-summary.md](./07-economics-whitepaper-summary.md): 백서 요약
- [08-whitepaper-spec-comparison.md](./08-whitepaper-spec-comparison.md): 백서 vs 스펙 비교 (기존 이슈)
- [10-v3-implementation-checklist.md](./10-v3-implementation-checklist.md): V3 구현 체크리스트
