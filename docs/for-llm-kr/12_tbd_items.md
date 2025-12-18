# TBD (To Be Determined) 항목

## 1. 개요

이 문서는 TON Staking V3 구현 시 **추가 논의 또는 결정이 필요한 항목**들을 정리합니다. 각 항목은 백서와 현재 설계 간의 모호함, 또는 구현 세부사항이 미정인 부분입니다.

> **업데이트 (2025-12-18)**: V3 백서(December 16, 2025) 발행으로 일부 항목이 해결되었습니다. 해결된 항목은 ✅ 표시되어 있습니다.

---

## 2. 설계 결정 필요 항목

### 2.1 ✅ 검증자 보상 분배 방식 (V3에서 해결됨)

**관련 문서**: [07_rat_implementation.md](./07_rat_implementation.md) (섹션 6.6)

**✅ V3 백서에서 해결됨 (December 16, 2025)**

V3 백서가 검증자 보상 분배 방식을 명확히 정의했습니다:

**V3 백서 공식 (13), (14):**
```
v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|    ... (13) 검증자 j의 총 보상
o_i = (1 − α) · S_i                      ... (14) 시퀀서 보상

V_i = L2 i에 할당된 검증자 집합
|V_i| = 해당 L2의 활성 검증자 수
```

**해결 내용:**
- **L2별 V_i 집합 기반 분배 (기존 "해석 2") 채택**
- 검증자는 특정 L2(들)에 할당됨
- 각 L2별로 `(α · S_i) / |V_i|` 분배
- 검증자가 없는 L2(`|V_i| = 0`)의 경우 `α · S_i` → **DAO Treasury**

**인센티브 결과:**
- 더 많은 L2를 검증할수록 더 많은 보상 → 적극적 참여 유도

**관련 코드:**
- `src/validator/RAT.sol`: `distributeValidatorReward()` - V3 공식 13 구현
- `src/validator/IRAT.sol`: `ValidatorRewardToTreasury` 이벤트 - |V_i|=0 처리

<details>
<summary>📜 기존 V2 문제점 (참고용)</summary>

**백서 V2 공식 (13):**
```
v_i = (α/n) · y(x)
```

**문제점:**
백서 공식의 해석이 모호했습니다:

| 해석 | 설명 | 결과 |
|------|------|------|
| **해석 1** | 전체 y(x)에서 균등 분배 | 모든 검증자가 동일 보상 (L2 수와 무관) |
| **해석 2** | L2별 S_i에서 분배 | 더 많은 L2에 등록한 검증자가 더 많은 보상 |

</details>

---

### 2.2 🚨 시퀀서 담보금 출금과 슬래싱 회피 (보안 이슈)

**관련 문서**: [03_sequencer_slashing.md](./03_sequencer_slashing.md)

**문제점:**

현재 `deactivateSequencer()` 함수에 활성 fraud proof 게임 체크가 없어서, 시퀀서가 슬래싱을 회피할 수 있습니다.

```
공격 시나리오:
1. 시퀀서가 fraud proof 게임에서 질 것으로 예상
2. 게임이 종료(CHALLENGER_WINS)되기 전에 deactivateSequencer() 호출
3. 담보금 전액 즉시 출금
4. 게임 종료 후 slashSequencerByGame() 호출해도 담보금 = 0
5. 슬래싱 실패, 챌린저 보상도 없음
```

**해결 방안 (택 1):**

| 옵션 | 설명 | 장점 | 단점 |
|------|------|------|------|
| **A. 출금 대기 기간** | 7일 출금 대기 기간 추가 | 단순 구현 | 정상 출금도 7일 대기 |
| **B. 활성 게임 체크** | DisputeGameFactory에서 활성 게임 조회 후 출금 차단 | 정확한 차단 | 복잡한 구현, 가스비 |
| **C. 출금 예약제** | 출금 예약 후 일정 기간 후 처리 | 예측 가능 | 추가 트랜잭션 필요 |

**권장 방안: A + 부분적 B**
- 기본 7일 출금 대기 기간 (DepositManager와 유사)
- 활성 게임이 있으면 게임 종료까지 출금 불가 (추가 안전장치)

**구현 필요:**
- [ ] `deactivateSequencer()` 즉시 출금 → 출금 예약 방식으로 변경
- [ ] `pendingWithdrawals` 구조체 및 대기 기간 관리
- [ ] `processWithdrawal()` 함수 추가 (대기 기간 후 출금 처리)
- [ ] (선택) `hasActiveGame(systemConfig)` 체크 함수

---

### 2.3 ⚠️ 시퀀서 슬래싱과 L2 운영 (추가 개발 필요)

**관련 문서**: [03_sequencer_slashing.md](./03_sequencer_slashing.md) (섹션 4.5)

**현재 구현:**
- 슬래싱된 시퀀서는 담보금(스테이킹 금액)을 잃음
- 이로 인해 자격 조건 `S_i ≥ θ · B_i` 불충족 → 시뇨리지 분배에서 제외
- **L2 시퀀싱 자체에는 영향 없음** (시뇨리지만 못 받음)

**백서 (Page 10) 명시:**
> "A slashed sequencer is **suspended from sequencing** according to protocol rules. To resume operation, the sequencer must **restore the bond within the re-bond period**; failure to do so results in **permanent removal from the active sequencer set**."

**백서 vs 현재 구현 차이:**
| 항목 | 백서 요구사항 | 현재 구현 |
|------|--------------|----------|
| **슬래싱 시 L2 시퀀싱** | ❌ 정지됨 (suspended) | ⚠️ 영향 없음 |
| **re-bond period** | ✅ 담보금 복구 기간 | ⚠️ 미구현 |
| **영구 제거** | ✅ 기간 내 미복구 시 제거 | ⚠️ 미구현 |

**추가 개발 필요 항목:**
1. **시퀀서 정지 메커니즘**: 슬래싱 시 L2 시퀀싱 정지
2. **re-bond period 파라미터**: 담보금 복구 기간 설정 (예: 7일)
3. **영구 제거 메커니즘**: 기간 내 미복구 시 active sequencer set에서 제거

**구현 고려 사항:**
- Layer2Manager 연동 필요 (시퀀서 상태 관리)
- `sequencerSlashTimestamps` 활용하여 re-bond period 추적
- "active sequencer set" 개념 도입 필요

---

### 2.3 ✅ 몰수된 담보금 귀속처 (구현 완료)

**관련 문서**: [05_validator_slashing.md](./05_validator_slashing.md) (섹션 2.4)

**구현된 코드**: `src/validator/RAT.sol`

**결정 사항:** DAO Treasury 귀속

검증자가 RAT 미응답으로 슬래싱되면 `C_off` (슬래싱 페널티)가 `accumulatedSlashings`에 누적되고, Treasury로 전송됩니다.

**구현:**
```solidity
// RAT.sol:767-772
function withdrawSlashingsToTreasury() external {
    require(treasury != address(0), "treasury not set");
    uint256 amount = accumulatedSlashings;
    accumulatedSlashings = 0;
    IERC20(wton).safeTransfer(treasury, amount);
}
```

- **누가**: 누구나 호출 가능 (접근 제한 없음)
- **언제**: 원할 때 언제든지 호출
- **동작**: `accumulatedSlashings` 전액을 `treasury` 주소로 전송

**완료:**
- [x] 몰수된 담보금 귀속처 결정 → DAO Treasury
- [x] 귀속처별 구현 방식 설계 → `withdrawSlashingsToTreasury()` 함수

---

### 2.4 검증자 파라미터 값

**관련 문서**: [10_governance_parameters.md](./10_governance_parameters.md) (섹션 7)

**백서 V2 공식:**
```
c_m ≤ (π_a / N) · C_off    ... (3)
C_off ≥ (c_m · N) / π_a    ... (4)
D_validator = C_off + Δ_validator    ... (5)
```

**미정 파라미터:**

| 파라미터 | 기호 | 설명 | 결정 방법 |
|---------|------|------|----------|
| **attentionCost** | c_m | 에폭당 attentiveness 유지 비용 | 검증자 운영 비용 측정 필요 |
| **slashingPenalty** | C_off | 오프라인 시 슬래싱 페널티 | 공식 (4)로 계산: `(c_m · N) / π_a` |
| **minimumThreshold** | D_min | 최소 담보금 임계값 | C_off 이상 권장 |

**결정 필요 사항:**
- [ ] c_m (attentionCost) 측정: 실제 검증자 운영 비용 조사
- [ ] N (예상 검증자 수) 추정
- [ ] π_a (RAT 트리거 확률) 결정: 현재 권장값 1%
- [ ] 위 값들로 C_off 계산
- [ ] D_min을 C_off와 동일하게 할지, 버퍼를 둘지

---

## 3. 구현 세부사항 미정

### 3.1 RAT 증거 형식

**관련 문서**: [07_rat_implementation.md](./07_rat_implementation.md) (섹션 1.1)

**현재 상태:**
RAT 증거 형식이 미정입니다. `stateRoot`의 left/right 자식 해시를 사용하는 방식 등을 검토 중입니다.

**결정 필요 사항:**
- [ ] 증거 형식 결정
- [ ] 증거 검증 로직 구현

---

### 3.2 ✅ V3 검증자 담보금 시뇨리지 정책 (해결됨)

**관련 문서**: [04_validator.md](./04_validator.md), [07_rat_implementation.md](./07_rat_implementation.md)

**✅ V3에서 해결됨:**

V3에서는 **스테이킹에 대한 시뇨리지가 없습니다**. 따라서:

- **담보금 시뇨리지**: 없음 (V3 분배 공식에서 스테이커 시뇨리지 제외)
- **슬래싱 시 시뇨리지 처리**: 해당 없음 (시뇨리지가 없으므로)
- **검증자 보상**: `α · S_i / |V_i|` 공식으로 별도 지급 (스테이킹 시뇨리지와 무관)

> **참고**: 검증자가 받는 보상은 V3 공식 (13)의 `v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|`로, 담보금 스테이킹의 시뇨리지가 아니라 L2 검증 활동에 대한 보상입니다.

---

### 3.3 ✅ 검증자 담보금 원금 추적 (구현 완료)

**관련 문서**: [04_validator.md](./04_validator.md), [07_rat_implementation.md](./07_rat_implementation.md)

**구현된 코드:**
- `src/validator/RATStorage.sol`: `ValidatorRegistration.depositedPrincipal` 필드 추가
- `src/validator/RAT.sol`: `_registerValidatorInternal()`, `addDeposit()`, `deactivateValidator()` 원금 추적 적용
- `src/validator/IRAT.sol`: `getValidatorRegistration()` 인터페이스 추가

**해결된 문제:**

V3에서는 스테이킹 시뇨리지가 없지만, **Solidity 정수 나눗셈으로 인해 원금이 완전히 보존되지 않습니다**. `depositedPrincipal` 필드를 추가하여 원금을 추적합니다.

```
예치 시: 1000 WTON 예치
    │
    ▼
Coinage 계산: deposit / factor → 정수 나눗셈으로 소수점 손실
    │
    ▼
출금 시: balance * factor → 원금보다 작을 수 있음
```

**예시:**
```solidity
// 예치 시
uint256 deposit = 1000e27;       // 1000 WTON (RAY 단위)
uint256 factor = 1.1e27;         // 현재 factor
uint256 coinageBalance = deposit / factor;  // = 909090909...e27 (정수 나눗셈)

// 출금 시
uint256 withdrawal = coinageBalance * factor;  // = 999999999...e27 (< 1000e27)
```

**필요한 구현:**

검증자가 **전체 출금** 시 원금 전액을 받을 수 있도록 **원금(principal) 추적**이 필요합니다.

```solidity
// 검증자 등록 정보에 원금 저장
struct ValidatorInfo {
    uint256 depositedPrincipal;  // 원래 예치한 금액 (정수 손실 전)
    uint256 coinageBalance;      // Coinage에 기록된 잔액
    // ...
}

// 출금 시 원금 반환 보장
function withdrawCollateral() external {
    ValidatorInfo storage info = validators[msg.sender];

    // 원금과 현재 coinage 잔액 중 큰 값 반환
    // (V3에서는 시뇨리지가 없으므로 원금이 더 클 수 있음)
    uint256 withdrawal = info.depositedPrincipal;

    // 또는 원금 그대로 반환
    _withdraw(msg.sender, withdrawal);
}
```

**구현 완료:**
- [x] V3에서 스테이킹 시뇨리지 없음 → 해결됨
- [x] 원금 추적 변수 추가 (`depositedPrincipal`) → `RATStorage.sol`에 구현
- [x] 출금 시 원금 반환 보장 로직 구현 → `deactivateValidator()`에서 `depositedPrincipal` 반환
- [x] 추가 예치 시 원금 추적 → `addDeposit()`에서 `depositedPrincipal` 누적

**구현 세부사항:**
- Coinage factor가 증가해도 V3에서는 검증자 담보금에 시뇨리지가 적용되지 않음
- 출금 시 `depositedPrincipal` (원금)을 반환하여 정수 나눗셈 손실 방지

---

### 3.4 검증자 담보금 출금 시 가스비 정책

**관련 문서**: [04_validator.md](./04_validator.md), [07_rat_implementation.md](./07_rat_implementation.md)

**현재 상태:**
검증자가 탈퇴(`deactivateValidator`) 시 담보금 출금 요청이 생성됩니다. DepositManager의 출금 처리(`processRequest`) 시, 해당 검증자의 다른 대기 중인 출금 요청이 있으면 함께 처리될 수 있습니다.

**문제점:**

```
검증자 A가 deactivateValidator() 호출
    │
    └─► DepositManager.requestWithdrawal(RAT 컨트랙트, 담보금)
            │
            ▼
    대기 기간 후 processRequest() 호출
            │
            └─► 같은 계정의 다른 출금 요청도 함께 처리됨
                    │
                    └─► 추가 가스비 발생 (누가 부담?)
```

**주요 쟁점:**

| 쟁점 | 설명 |
|------|------|
| **추가 가스비 부담** | 다른 출금 요청 처리에 드는 가스비를 누가 부담하는지 |
| **출금 순서** | 담보금 출금이 먼저인지, 기존 대기 출금이 먼저인지 |
| **분리 처리** | 담보금 출금을 별도 메커니즘으로 처리할지 |

**가능한 옵션:**

| 옵션 | 설명 | 장단점 |
|------|------|--------|
| **현행 유지** | processRequest 호출자가 가스비 부담 | 단순, 호출자 불이익 가능 |
| **시뇨리지 수수료** | 검증자 시뇨리지에서 가스비 예비금 차감 | 공정, 구현 복잡 |
| **별도 출금 경로** | RAT 전용 출금 함수 구현 | 명확한 분리, 추가 개발 필요 |
| **일괄 처리 제한** | 담보금 출금만 단독 처리 | 간단, DepositManager 수정 필요 |

**결정 필요 사항:**
- [ ] 추가 가스비 부담 주체 결정
- [ ] 시뇨리지에서 수수료 할당 여부
- [ ] 별도 출금 메커니즘 필요 여부
- [ ] DepositManager 수정 범위 결정

**관련 고려 사항:**
- 현재 DepositManager.processRequest()는 FIFO로 대기 출금을 처리
- RAT 컨트랙트가 대리 스테이킹하므로, 출금 주체는 RAT 컨트랙트
- 검증자 개인의 다른 스테이킹과는 별개 (RAT 컨트랙트 주소로 스테이킹됨)

---

## 4. 우선순위

| 우선순위 | 항목 | 이유 | 상태 |
|---------|------|------|------|
| ~~높음~~ | ~~2.1 검증자 보상 분배 방식~~ | ~~핵심 인센티브 구조에 영향~~ | ✅ V3 해결 |
| **🚨 긴급** | 2.2 시퀀서 담보금 출금과 슬래싱 회피 | 보안 취약점: 시퀀서가 슬래싱 전 담보금 출금 가능 | ⚠️ 구현 필요 |
| **높음** | 2.3 시퀀서 슬래싱과 L2 운영 | 백서 요구사항 미구현 (시퀀서 정지, re-bond period, 영구 제거) | ⚠️ 추가 개발 필요 |
| **높음** | 2.4 검증자 파라미터 값 | 배포 전 필수 결정 | 미해결 |
| **높음** | 3.3 검증자 담보금 원금 추적 | 정수 나눗셈 손실로 원금 반환 보장 필요 | ⚠️ 구현 필요 |
| **중간** | 2.3 몰수된 담보금 귀속처 | 구현 시 필요하나 기본값 설정 가능 | 미해결 |
| **중간** | 3.1 RAT 증거 형식 | Optimism 방식 우선 채택 가능 | 미해결 |
| ~~중간~~ | ~~3.2 검증자 담보금 시뇨리지 정책~~ | ~~V3에서 스테이킹 시뇨리지 없음~~ | ✅ V3 해결 |
| **중간** | 3.4 검증자 담보금 출금 시 가스비 정책 | 사용자 경험에 영향, 구현 방식 결정 | 미해결 |

---

## 5. 참고 자료

- **Tokamak Economics Whitepaper V3** (December 16, 2025) - 최신
- **Tokamak Economics Whitepaper V2** (December 9, 2025)
- [04_validator.md](./04_validator.md): 검증자 등록/보상
- [05_validator_slashing.md](./05_validator_slashing.md): 검증자 슬래싱
- [07_rat_implementation.md](./07_rat_implementation.md): RAT 구현체
- [10_governance_parameters.md](./10_governance_parameters.md): 거버넌스 파라미터

---

## 6. 관련 코드 파일

| 파일 | 설명 | 관련 항목 |
|------|------|----------|
| `src/validator/RAT.sol` | RAT 검증자 관리 | 2.1 (해결), 2.3, 3.1, 3.2, 3.3, 3.4 |
| `src/validator/IRAT.sol` | RAT 인터페이스 | 2.1 (해결) |
| `src/staking/SeigManagerV1_4.sol` | 시뇨리지 분배 | 2.1 (해결), 2.4 |

---

## 7. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-12-18 | V3 백서 반영: 항목 2.1 해결됨 표시, V3 공식 및 관련 코드 추가 |
| 2025-12-18 | V3 시뇨리지 정책 반영: 3.2 해결됨 (스테이킹 시뇨리지 없음), 3.3 원금 추적 문제 추가 |
