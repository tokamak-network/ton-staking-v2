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
| **담보금 구조** | 별도 Vault 논의 중 (08문서 2.1) | 기존 TON 스테이킹으로 통합 | **높음** |
| **SequencerVault** | 별도 Vault 사용 | **불필요 (제거)** - 기존 스테이킹 활용 | **높음** |
| **검증자 담보금 체크** | 항상 체크 | `enforceMinDeposit` flag로 유연화 | **높음** |
| **L2 슬래싱 시 정지** | 물리적 정지 가능 | 물리적으로 정지하지 않음 | **높음** |
| Bridged TON 측정 | 기간 평균값 논의 | 최신 온체인 값 사용 | 중간 |

---

## 3. 핵심 변경 1: 담보금 = 기존 TON 스테이킹 통합

### 3.1 V2 (현재 구현) - 08 문서 Issue 2.1

08 문서에서 논의 중이던 내용:

```
백서 공식:
  D_sequencer = H_max · C_max + Δ_sequencer  (슬래싱 담보금)
  T_i ≥ θ · B_i                              (시뇨리지 자격)

버나드 답변:
  - 시뇨리지 자격 스테이킹과 슬래싱 담보금은 원래 **별도 Vault** 의도
  - 합칠지 여부는 추가 논의 필요
```

**현재 구현**: SequencerVault / ValidatorVault와 스테이킹이 분리되어 있었음

### 3.2 V3 (새 백서 + 회의 결정)

> **Issue 1: Sequencer Collateral and Sequencer Staking**

**결정 내용**:
1. 시퀀서 담보금과 스테이킹 조건은 **기존 TON 스테이킹 시스템을 활용**
2. 시뇨리지를 받으려면 두 조건 중 **더 큰 값** 이상을 스테이킹해야 함:

```solidity
// 시뇨리지 수령 조건:
minRequiredStake = max(H_max · C_max + Δ_sequencer, θ · B_i)
```

3. **슬래싱 동작**:
   - 슬래싱 시 스테이킹된 **모든 금액이 몰수**됨
   - 시뇨리지를 받을 수 없게 됨 (경제적 제약)
   - **L2는 물리적으로 정지되지 않음** (백서 수정 예정)

### 3.3 변경의 의미

| 항목 | V2 (별도 Vault 논의) | V3 (통합) |
|------|---------------------|----------|
| 자본 효율성 | 낮음 (중복 예치) | 높음 (단일 예치) |
| 구현 복잡도 | 높음 (2개 Vault) | 낮음 (기존 시스템 활용) |
| 시퀀서 진입 장벽 | 높음 | 낮음 |

### 3.4 구현 수정 사항

**수정 방향**:
- [x] 기존 TON 스테이킹 시스템 활용 (새로운 Vault 불필요)
- [ ] **SequencerVault 제거/미사용** - 기존 스테이킹으로 대체
- [ ] **SeigManagerV1_4._getSequencerCollateral() 수정** - coinage에서 조회하도록 변경
- [ ] 최소 스테이킹 조건: `max(D_sequencer, θ · B_i)` 체크 로직 확인
- [ ] 슬래싱 시 전액 몰수 → 시뇨리지 자격 상실 (coinage에서 차감)
- [ ] L2 물리적 정지 로직 제거 (있다면)

### 3.5 SequencerVault 제거 상세

**V3 결정**: 시퀀서 담보금 = 기존 TON 스테이킹

| 항목 | 현재 (SequencerVault) | V3 (기존 스테이킹) |
|------|----------------------|-------------------|
| 담보금 예치 | Vault에 별도 예치 | DepositManager에 스테이킹 |
| 자격 체크 | `SequencerVault.getSequencerDepositByLayer2()` | `coinage.balanceOf(operator)` |
| 슬래싱 | Vault에서 차감 | coinage에서 차감 |
| 자본 효율성 | 낮음 (중복 자금) | 높음 (단일 자금) |

**수정 필요 코드**:

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
```

**슬래싱 처리**:
- 기존: `SequencerVault.slashSequencerByGame()`
- V3: SeigManager 또는 별도 SlashManager에서 coinage 차감 처리

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
1. 검증자에게 최소 담보금이 필요한지 여부를 나타내는 **flag 추가**
2. **초기에는 최소 담보금이 필요하지 않도록** flag 설정 (`enforceMinDeposit = false`)

### 4.3 구현 요구사항

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

### 4.4 운영 계획

| 단계 | `enforceMinDeposit` | 설명 |
|------|---------------------|------|
| **1단계 (초기)** | `false` | 검증자 유치 용이, 진입 장벽 최소화 |
| 2단계 (성장기) | `true` | 보안 강화, 최소 담보금 요구 |

### 4.5 수정 필요 파일

- [ ] `src/validator/RAT.sol`: `enforceMinDeposit` flag 추가 (초기값 `false`)
- [ ] `src/validator/RATStorage.sol`: 저장소에 flag 추가
- [ ] `src/validator/IRAT.sol`: 인터페이스 업데이트
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

- [ ] L2 물리적 정지 로직이 있다면 제거
- [ ] 슬래싱 후 시뇨리지 자격만 상실하도록 확인

---

## 6. 기존 08 문서 이슈 해결 상태

| 08 문서 이슈 | 상태 | V3 결정 |
|-------------|------|---------|
| 2.1 시퀀서 담보금 (별도 Vault vs 통합) | **해결됨** | 기존 스테이킹 시스템 활용 |
| 2.2 검증자 담보금 N_max | **해결됨** | `enforceMinDeposit` flag로 유연화 |
| 1.1 S_i vs T_i 변수명 | 검토 필요 | 통합으로 단순화됨 |
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

### 7.2 V3 변경에 따른 신규 개발 필요 ⚠️

| 항목 | 설명 | 우선순위 |
|------|------|----------|
| **SequencerVault 제거/미사용** | 기존 스테이킹으로 대체, SeigManager 수정 | **높음** |
| **enforceMinDeposit flag** | 검증자 최저 담보금 체크 유연화 | **높음** |
| **최소 스테이킹 조건 확인** | `max(D_sequencer, θ · B_i)` 로직 확인 | 높음 |
| **L2 물리적 정지 로직 제거** | 슬래싱 시에도 L2 운영 가능 | 높음 |
| **슬래싱 로직 이전** | SequencerVault → SeigManager/SlashManager | 높음 |

---

## 8. 액션 아이템

### 즉시 필요 (높음)

| # | 항목 | 파일 |
|---|------|------|
| 1 | **SequencerVault 제거/미사용** | `SequencerVault.sol` (제거 또는 deprecated) |
| 2 | **`_getSequencerCollateral()` 수정** - coinage에서 조회 | `SeigManagerV1_4.sol` |
| 3 | **슬래싱 로직 이전** - coinage 차감 방식 | `SeigManagerV1_4.sol` 또는 `SlashManager.sol` |
| 4 | `enforceMinDeposit` flag 추가 (초기값 `false`) | `RAT.sol`, `RATStorage.sol` |
| 5 | 최소 스테이킹 조건 확인: `max(D_sequencer, θ·B_i)` | `SeigManagerV1_4.sol` |
| 6 | L2 물리적 정지 로직 확인/제거 | 슬래싱 관련 코드 |

### 단기 (중간)

| # | 항목 |
|---|------|
| 4 | 신규 테스트 케이스 작성 |
| 5 | 스펙 문서 업데이트 |

---

## 9. 결론

**V3 백서 + 회의 결정으로 해결된 사항**:

1. **08 문서 Issue 2.1 (담보금 구조)**: 기존 TON 스테이킹 시스템 활용으로 결정 ✅
2. **08 문서 Issue 2.2 (검증자 담보금)**: `enforceMinDeposit` flag로 유연화 ✅
3. **L2 정지 정책**: 슬래싱 시에도 물리적으로 정지하지 않음 ✅

**개발 필요 사항**:
- **SequencerVault 제거** - 기존 스테이킹으로 대체
- **SeigManagerV1_4._getSequencerCollateral() 수정** - coinage 조회
- **슬래싱 로직 이전** - coinage 차감 방식
- `enforceMinDeposit` flag 추가 (초기값 `false`)
- L2 정지 로직 제거 (있다면)

---

## 관련 문서

- [07-economics-whitepaper-summary.md](./07-economics-whitepaper-summary.md): 백서 요약
- [08-whitepaper-spec-comparison.md](./08-whitepaper-spec-comparison.md): 백서 vs 스펙 비교 (기존 이슈)
- [10-v3-implementation-checklist.md](./10-v3-implementation-checklist.md): V3 구현 체크리스트
