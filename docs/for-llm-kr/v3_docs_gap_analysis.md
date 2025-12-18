# V3 백서 반영 상태 검토 결과

> **검토일**: 2025-12-18
> **검토 대상**:
> - `docs/for-llm-kr/` 디렉토리 내 개발 문서
> - `Tokamak_Economics_Whitepaper_V3.pdf` (December 16, 2025)
> - `whitepaper_v2_to_v3_changes.md`

---

## 1. 검토 목적

V3 백서(2025-12-16)의 변경사항이 `docs/for-llm-kr/` 디렉토리의 개발 문서에 적절히 반영되어 있는지 확인하고, 업데이트가 필요한 부분을 식별합니다.

---

## 2. 핵심 변경사항 반영 현황

| 변경사항 | V3 백서 내용 | 문서 반영 상태 | 비고 |
|---------|-------------|---------------|------|
| **검증자 보상 공식** | `v_j = Σ_{i: j∈V_i} (α · S_i) / \|V_i\|` | ✅ 반영 완료 | 02, 04, 07, 08 문서 업데이트 |
| **L2별 검증자 할당 (V_i)** | 검증자가 특정 L2에 할당됨 | ✅ 반영 완료 | 04, 07 문서에 V_i 개념 추가 |
| **검증자 미할당 시 DAO Treasury** | `\|V_i\| = 0`이면 α·S_i → DAO | ✅ 반영 완료 | 04, 07 문서 + RAT.sol:592-598 |
| **측정 방식** | 온체인 호출 시점 최신값 | ✅ 반영 완료 | 02, 08 문서에 섹션 추가 |

---

## 3. ✅ 문서별 상세 분석 - 모두 완료

### 3.1 ✅ `04_validator.md` - 검증자 문서

**업데이트 완료:**
- ✅ V3 공식 `v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|` 반영 (섹션 7.1)
- ✅ L2별 검증자 할당(V_i) 개념 추가 (섹션 7.2)
- ✅ DAO Treasury 귀속 로직 추가 (섹션 7.3)
- ✅ 관련 코드 참조 추가 (섹션 11, 12)

---

### 3.2 ✅ `02_v3_distribution.md` - 분배 공식 문서

**업데이트 완료:**
- ✅ 검증자별 보상 공식을 V3로 변경
- ✅ L2별 분배 구조 명확화
- ✅ 공식 (14) `o_i = (1 − α) · S_i` 분리 표기
- ✅ 측정 방식 변경 추가 (섹션 6.1)

---

### 3.3 ✅ `07_rat_implementation.md` - RAT 구현 문서

**업데이트 완료:**
- ✅ 공식 참조 부분 V3로 업데이트
- ✅ V_i 개념과 연결하여 설명 보완
- ✅ DAO Treasury 귀속 로직 문서화
- ✅ 관련 코드 섹션 추가

---

### 3.4 ✅ `08_implementation.md` - 구현 문서

**업데이트 완료:**
- ✅ 코드 주석의 공식 참조를 V3로 수정
- ✅ 분배 로직 설명 업데이트
- ✅ V3 측정 방식 섹션 추가 (섹션 5.3, 7.1)
- ✅ 관련 코드 파일 테이블 추가 (섹션 6)

---

### 3.5 ✅ `12_tbd_items.md` - TBD 항목

**업데이트 완료:**
- ✅ 항목 2.1을 "해결됨"으로 표시
- ✅ V3 백서 참조 추가
- ✅ V3 공식 및 관련 코드 명시
- ✅ 변경 이력 섹션 추가

**V3에서 해결된 내용:**
> V3 백서가 이를 명확히 함: **L2별 V_i 집합 기반 분배 (해석 2)**

---

## 4. ✅ 측정 방식 변경 반영 완료 (2025-12-18)

### 4.1 변경 내용

| 구분 | V2 | V3 |
|------|-----|-----|
| **측정 방식** | 기간 평균값 (averaged values over the period) | 온체인 호출 시점 최신값 (latest observed values) |
| **샘플링** | 주기적 스냅샷 기반 | 고정 간격 아님, 온체인 호출 기반 |

### 4.2 영향받는 문서 - ✅ 완료

- ✅ `02_v3_distribution.md`: 섹션 6.1 측정 방식 변경 추가
- ✅ `08_implementation.md`: 섹션 5.3, 7.1 V3 측정 방식 설명 추가

### 4.3 구현 상태 - ✅ 이미 V3 준수

코드가 이미 V3 측정 방식(온체인 호출 시점 최신값)을 사용하고 있습니다:

```solidity
// SeigManagerV1_4.sol:345 - Bridged TON 실시간 조회
uint256 bridgedTON = ILayer2Manager(layer2Manager).getBridgedTONByLayer(layer2);

// SeigManagerV1_4.sol:351 - Staked TON 실시간 조회
currentStake = _getSequencerStake(layer2);
```

**관련 코드:**
- `src/stake/managers/SeigManagerV1_4.sol`: `checkCurrentEligibility()` - 호출 시점 자격 조건 검증
- `src/layer2/Layer2ManagerV1_2.sol`: `getBridgedTON()` - 현재 Bridged TON 조회

---

## 5. ✅ 권장 조치사항 - 모두 완료

### 5.1 우선순위 높음 (공식 변경) - ✅ 완료

| 순위 | 문서 | 조치 내용 | 상태 |
|------|------|----------|------|
| 1 | `02_v3_distribution.md` | 공식 (13)을 V3 버전으로 변경, V_i 개념 추가 | ✅ 완료 |
| 2 | `04_validator.md` | 검증자 보상 공식 V3로 수정, L2 할당 메커니즘 설명 | ✅ 완료 |
| 3 | `12_tbd_items.md` | 항목 2.1 해결됨 표시 (V3에서 명확화) | ✅ 완료 |

### 5.2 우선순위 중간 - ✅ 완료

| 순위 | 문서 | 조치 내용 | 상태 |
|------|------|----------|------|
| 4 | `08_implementation.md` | 코드 주석의 공식 참조 수정 | ✅ 완료 |
| 5 | `07_rat_implementation.md` | 공식 설명 V3로 업데이트 | ✅ 완료 |

### 5.3 우선순위 낮음

| 순위 | 문서 | 조치 내용 | 상태 |
|------|------|----------|------|
| 6 | 전체 문서 | 측정 방식 변경 반영 (기간 평균 → 최신값) | ✅ 완료 |
| 7 | 전체 문서 | 용어 및 표현 톤 통일 | 미완료 |

---

## 6. ✅ 추가 문서화 항목 반영 완료 (2025-12-18)

V3 백서에서 새로 명확화된 내용이 개발 문서에 반영되었습니다:

### 6.1 ✅ 검증자 할당 메커니즘 - 완료

V3에서 검증자는 **수동 할당 방식**으로 특정 L2(SystemConfig)에 등록합니다.

**할당 방식:**
- ✅ **수동 할당**: 검증자가 `registerValidator(systemConfig, amount)`로 모니터링할 L2를 선택
- ✅ 복수 L2 등록 가능 (하나의 주소가 여러 SystemConfig에 등록)
- ✅ L2별 독립적 담보금 관리

**데이터 구조 (실제 구현):**
```solidity
// RATStorage.sol - 실제 구현된 구조
/// @notice L2별 할당된 검증자 집합 (systemConfig => validator => registration)
mapping(address => mapping(address => ValidatorRegistration)) public validatorRegistrations;

/// @notice L2별 검증자 풀 정보 (systemConfig => pool info)
mapping(address => ValidatorPoolInfo) internal validatorPools;

/// @notice 검증자가 할당된 L2 목록 (validator => systemConfig[])
mapping(address => address[]) public validatorSystemConfigs;
```

**문서화 위치:**
- `04_validator.md`: 섹션 1.1, 4, 7.2
- `07_rat_implementation.md`: 섹션 3, 4, 6

**관련 코드:**
| 파일 | 라인 | 역할 |
|------|------|------|
| `RATStorage.sol` | 33-41 | ValidatorRegistration 구조체 |
| `RATStorage.sol` | 56-61 | ValidatorPoolInfo 구조체 |
| `RATStorage.sol` | 68, 71, 77 | 검증자 매핑 구조 |
| `RAT.sol` | 209-225 | registerValidator 함수 |
| `RAT.sol` | 352-395 | _registerValidatorInternal 내부 로직 |

### 6.2 ✅ DAO Treasury 귀속 로직 - 완료

검증자 미할당 L2의 처리가 구현되었습니다:

**V3 백서 규칙:**
- 조건: `|V_i| = 0` (L2 i에 검증자 없음)
- 처리: `α · S_i` → DAO Treasury
- ✅ `treasury` 변수로 주소 관리
- ✅ `setTreasury(address)` 함수로 설정

**문서화 위치:**
- `04_validator.md`: 섹션 7.3, 12
- `07_rat_implementation.md`: 섹션 6.6

**관련 코드:**
| 파일 | 라인 | 역할 |
|------|------|------|
| `RATStorage.sol` | 152-153 | treasury 변수 |
| `RAT.sol` | 585-614 | distributeValidatorReward - |V_i|=0 처리 |
| `RAT.sol` | 739-741 | setTreasury 함수 |
| `RAT.sol` | 755-760 | withdrawSlashingsToTreasury 함수 |
| `IRAT.sol` | 101-106 | ValidatorRewardToTreasury 이벤트 |

**구현 코드 (RAT.sol:585-614):**
```solidity
function distributeValidatorReward(address systemConfig, uint256 amount)
    external
    onlySeigManager
{
    ValidatorPoolInfo storage pool = validatorPools[systemConfig];

    // V3 백서: |V_i| = 0이면 α·S_i → DAO Treasury
    if (pool.activeCount == 0) {
        if (treasury != address(0) && amount > 0) {
            IERC20(wton).safeTransfer(treasury, amount);
            emit ValidatorRewardToTreasury(systemConfig, amount);
        }
        return;
    }

    // v_i = amount / n (V3 공식 13: (α·S_i) / |V_i|)
    uint256 perValidator = amount / pool.activeCount;
    // ...
}
```

---

## 7. 결론

### 7.1 현재 상태 - ✅ V3 반영 완료

`docs/for-llm-kr/` 문서들이 **V3 백서 기준으로 업데이트**되었습니다.

### 7.2 주요 갭 해결 현황

| 항목 | 상태 | 수정 문서 |
|------|------|----------|
| **검증자 보상 공식** V3 반영 | ✅ 완료 | 02, 04, 07, 08 |
| **L2별 검증자 할당 (V_i)** | ✅ 완료 | 04, 07 |
| **DAO Treasury 처리** | ✅ 완료 | 04, 07 |
| **측정 방식 변경** | ✅ 완료 | 02, 08 |
| **검증자 할당 메커니즘 문서화** | ✅ 완료 | 04, 07, gap analysis |
| **DAO Treasury 귀속 로직 문서화** | ✅ 완료 | 04, 07, gap analysis |

### 7.3 코드 V3 일치 확인

| 항목 | 파일 | 라인 | 상태 |
|------|------|------|------|
| 검증자 보상 공식 (13) | RAT.sol | 601-603 | ✅ |
| L2별 검증자 풀 구조체 | RATStorage.sol | 56-61 | ✅ |
| L2별 검증자 풀 매핑 | RATStorage.sol | 68, 71, 77 | ✅ |
| DAO Treasury 귀속 | RAT.sol | 592-598 | ✅ |
| 측정 방식 (최신값) | SeigManagerV1_4.sol | 345, 351 | ✅ |

### 7.4 남은 작업

| 항목 | 우선순위 |
|------|---------|
| 용어 및 표현 톤 통일 | 낮음 |

---

## 8. 관련 문서

- `whitepaper_v2_to_v3_changes.md`: V2 → V3 백서 변경사항 상세
- `Tokamak_Economics_Whitepaper_V3.pdf`: V3 백서 원본
- `12_tbd_items.md`: 미결정 항목 목록

---

## 9. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-12-18 | 최초 작성 - V3 백서 반영 상태 검토 |
| 2025-12-18 | 측정 방식 변경 반영 완료 - 02_v3_distribution.md, 08_implementation.md 업데이트 |
| 2025-12-18 | 검증자 할당 메커니즘 문서화 완료 - 섹션 6.1 업데이트 |
| 2025-12-18 | DAO Treasury 귀속 로직 문서화 완료 - 섹션 6.2 업데이트 |
| 2025-12-18 | 전체 V3 반영 완료 - 결론 섹션 업데이트 |
