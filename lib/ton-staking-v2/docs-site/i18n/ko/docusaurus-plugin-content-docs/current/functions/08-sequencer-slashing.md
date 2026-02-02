---
id: functions-sequencer-slashing
sidebar_position: 8
---

# 시퀀서 슬래싱 함수

SeigManager V3에서 처리하는 시퀀서 슬래싱 함수입니다.

## slashSequencerByGame

시퀀서를 슬래싱합니다 (Permissionless). V3에서는 SeigManager에서 처리합니다.

```solidity
function slashSequencerByGame(address gameAddress) external whenV3Active whenNotPaused
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 |
| **조건** | 게임이 DEFENDER_WINS가 아닌 상태로 종료 |

**동작 흐름**:
```
1. DisputeGameFactory 검증 (가짜 게임 방지)
2. 게임 상태 확인: status != DEFENDER_WINS
3. 시퀀서 전체 스테이킹 금액 몰수 (coinage.burnFrom)
4. 챌린저 보상 계산: C_max + Δ/n
5. 챌린저 보상 지급 (WTON.mint)
6. 나머지: DAO Treasury
7. 이벤트: SequencerSlashed
```

> **V3 변경사항**: 시퀀서 담보금은 기존 스테이킹 시스템(coinage)을 사용합니다.

---

## 관련 이벤트

```solidity
event SequencerSlashed(
    address indexed layer2,
    address indexed gameAddress,
    uint256 slashedAmount,
    address challenger,
    uint256 challengerReward
);
```

---

## 거버넌스 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|---------|------|------|------|
| `maxFraudProofCost` | `setMaxFraudProofCost(C_max)` | C_max > 0 | WTON |
| `sequencerAdditionalReward` | `setSequencerAdditionalReward(Δ)` | Δ ≥ 0 | WTON |
| `maxChallengers` | `setMaxChallengers(H_max)` | H_max > 0 | count |

**슬래싱 파라미터 용도**:

D_sequencer 계산에 사용:
```
D_sequencer = maxChallengers × maxFraudProofCost + sequencerAdditionalReward

예시:
maxChallengers = 3
maxFraudProofCost = 50e27 WTON
sequencerAdditionalReward = 100e27 WTON
→ D_sequencer = 3 × 50e27 + 100e27 = 250e27 WTON
```
