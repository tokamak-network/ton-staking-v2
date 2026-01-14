# 백서 vs 스펙 문서 비교 분석 결과

이 문서는 `07-economics-whitepaper-summary.md` (Tokamak Economics Whitepaper V2)를 기준으로 스펙 문서들(01~06)의 모호하거나 불명확하거나 틀린 부분을 분석한 결과입니다.

---

## 1. 모호하거나 불명확한 부분

### 1.1 시퀀서 담보금 vs SequencerVault 담보금 혼용 (01, 05) ✅ 해결됨

**위치**: `01-system-overview.md`, `05-actors.md` 등

**문제**: 스펙 문서에서 자격 조건을 설명할 때 `S_i`를 "시퀀서 담보금 (SequencerVault)"라고 하지만, 백서에서는 `T_i`를 "L2의 시퀀서가 L1 TON 스테이킹 컨트랙트에 스테이킹한 양"으로 정의합니다.

**해결 (V3 구현)**:
- 변수명 통일: `T_i` = 시퀀서 스테이킹 금액, `S_i` = L2 시뇨리지 분배량
- SequencerVault 제거: 기존 스테이킹 시스템(coinage) 사용
- 자격 조건: `T_i ≥ θ · B_i`
- 스테이킹 조회: `SeigManager.getSequencerStaked(layer2)`

```
V3 스펙: T_i ≥ θ · B_i (T_i = coinage.balanceOf(operator))
```

---

### 1.2 RAT 검증자 선택 방식 불명확 (01, 06)
**위치**: `01-system-overview.md:100`, `06-function-specs.md:386`

**문제**: 백서에서는 "validators are randomly selected at unpredictable times"라고 하는데, 스펙에서는 `triggerAttentionTest`에서 "검증자 랜덤 선택"이라고만 되어 있고 구체적인 선택 알고리즘이 없습니다.

**권장**: 랜덤 선택 알고리즘(예: VRF, blockhash 기반 등)을 명시해야 합니다.

---

### 1.3 Fast Withdrawal 구현 누락 (03, 04)
**위치**: 백서 Section 1.3.2

**문제**: 백서에서 중요한 리스크 완화 메커니즘으로 Fast Withdrawal을 설명하지만, 스펙 문서에서는 이에 대한 구현 내용이 전혀 없습니다.

**권장**: Fast Withdrawal 관련 컨트랙트/인터페이스를 스펙에 추가하거나, 별도 구현 예정임을 명시해야 합니다.

---

## 2. 백서와 불일치하는 부분

### 2.1 시퀀서 담보금 공식 차이 (01, 05) - **논의 중**
**위치**: `01-system-overview.md:220-221`, `05-actors.md:94`

**백서 공식**:
```
D_sequencer = H_max · C_max + Δ_sequencer  (Formula 1, p.10 - Fraud Proof 비용 커버)
T_i ≥ θ · B_i                              (Rule 4, p.15 - 시뇨리지 자격 조건)
```

**현재 구현**: 두 조건을 하나의 Vault에서 처리
```
최소 담보금 = max(θ · B_i, H_max · C_max + Δ_sequencer)
```

**버나드 답변 (논의 중)**:
- 시뇨리지 자격 스테이킹과 슬래싱 담보금은 원래 **별도 Vault** 의도
- 합칠지 여부는 추가 논의 필요
- "L1 TON Staking" 용어가 혼란 가능, 검토 필요
- 현재 Vault는 시퀀서/검증자 **담보금(bond)** 용

---

### 2.2 검증자 담보금 공식 차이 (01) - **논의 중**
**위치**: `01-system-overview.md:221-222`

**백서 공식 (게임 이론 기반)**:
```
C_off ≥ (c_m × N) / π_a

D_validator = C_off + Δ_validator
```

**스펙**: `C_off`가 고정 파라미터로 설정되어 있고, 검증자 수 N이나 모니터링 비용 `c_m`과의 관계가 설명되지 않습니다.

**버나드 답변 1차**:

| 항목 | 답변 |
|------|------|
| N의 정의 | L2별 검증자 수 (\|V_i\|), 시스템 전체가 아님, 현재 활성 검증자 수 |
| 공식의 성격 | 이론적 근거(theoretical rationale)이며, 실시간 동적 업데이트 규칙이 아님 |
| 권장 구현 방식 | `Δ_validator`에 충분한 마진을 설정 + **실질적인 N_max 고려 필요** |
| 검증자 모니터링 | `ValidatorRegistered` 이벤트로 자격 상태 확인 |
| 담보금 부족 시 | 충분한 유예 기간 제공 또는 소급 적용하지 않는 방식 적용 가능 |

**버나드 답변 2차 (논의 중)**:
- **(A) 옵션 확인**: 검증자는 등록 시에만 최소 담보금 조건 충족하면 됨
- **N_max 하드코딩 불필요**: Δ_validator 버퍼가 충분하면 됨
- **다른 의견 대기 중**

**현재 구현 (검토 필요)**:
- `maxValidatorsPerL2` 기본값: 100 (가스 한도 고려)
- 버나드는 N_max 하드코딩 불필요하다고 함, 재검토 필요

---

### 2.3 Multi-Challenger Fraud Proof 구현 불명확 (06)
**위치**: `06-function-specs.md:607-622`

**백서**: "multi-winner approach, where all valid fraud proofs submitted within the dispute period are recognized and rewarded"

**스펙**: `slashSequencerByGame()`에서 `C_max + Δ/n`으로 분배한다고 하지만, **복수의 챌린저를 어떻게 추적하는지** 구현 세부사항이 없습니다.

---

## 3. 요약

| 구분 | 개수 | 심각도 | 비고 |
|------|------|--------|------|
| 모호/불명확 | 3개 | 중간 | |
| 백서와 불일치 | 3개 (2개 해결) | 높음 | 2.1 시퀀서 담보금, 2.2 검증자 담보금 해결됨 |

---

## 4. 우선 수정 권장 사항

| # | 항목 | 상태 |
|---|------|------|
| 1 | **시퀀서 담보금 변수명 통일** (`S_i` → `T_i`) | ✅ 해결됨 |
| 2 | Fast Withdrawal 구현 계획 명시 | ⏳ 향후 |
| 3 | Multi-Challenger 추적 메커니즘 상세화 | ⏳ 향후 |
| 4 | RAT 검증자 선택 알고리즘 상세화 | ⏳ 검토 필요 |

---

## 5. 관련 문서

- [01-system-overview.md](./01-system-overview.md): 시스템 개요
- [02-system-architecture.md](./02-system-architecture.md): 시스템 아키텍처
- [03-contract-structure.md](./03-contract-structure.md): 컨트랙트 구조
- [04-contract-roles.md](./04-contract-roles.md): 컨트랙트별 역할
- [05-actors.md](./05-actors.md): 액터 정의
- [06-function-specs.md](./06-function-specs.md): 함수별 상세 설명
- [07-economics-whitepaper-summary.md](./07-economics-whitepaper-summary.md): 백서 요약
