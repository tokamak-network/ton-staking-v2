# Slashing vs RAT Test Analysis

본 문서는 `op-e2e` 폴더 내의 **Slashing 관련 테스트**와 **RAT(Reliability Available Token) 관련 테스트**의 차이점을 분석한 결과입니다.

## 1. 개요 (Overview)

Tokamak Network의 TON Staking V2 시스템에서 **Slashing**과 **RAT**은 서로 밀접하게 연관되어 있지만, 테스트의 초점은 서로 다른 시나리오를 검증하는 데 있습니다.

- **Slashing Test**: Operator가 부정한 행위(잘못된 State Root 제출 등)를 했을 때, **처벌(Stake 삭감) 및 보상 분배**가 올바르게 이루어지는지 검증합니다.
- **RAT Test**: 부정한 Challenge가 발생하거나 Dispute Game이 생성되었을 때, **RAT 시스템이 자동으로 트리거**되고, 정직한 Validator의 **자산(Bond)이 보호되거나 올바르게 반환**되는지 검증합니다.

## 2. Test 파일 비교

| 구분 | Slashing Tests | RAT Tests |
| :--- | :--- | :--- |
| **파일 경로** | `op-e2e/slashing/slashing_test.go` | `op-e2e/faultproofs/rat_challenge_test.go` |
| **테스트 시나리오** | Operator의 부정 -> Challenger 승리 -> **Operator 처벌** | Proposer의 부정 -> Challenger(Validator) 승리 -> **Validator 보호/보상** |
| **핵심 검증 대상** | `DepositManager`, `Layer2Manager` (Slashing 로직) | `RAT(Contract)`, `DisputeGameFactory`, `FaultDisputeGame` |
| **자산 흐름 (WTON)** | Operator Stake(WTON) **감소 (0으로)**<br>Challenger Balance(WTON) **증가 (보상 10%)** | Validator Deposit(WTON) **유지 (복구됨)**<br>Challenger Balance(WTON) **변동 없음** (ETH 보상 받음) |
| **자산 흐름 (ETH)** | - | Validator(Challenger)가 Game Bond(ETH) 획득 |

---

## 3. 상세 분석

### 3.1 Slashing Tests (`TestSlashing_BasicOperatorSlashing`)

이 테스트는 **Operator(검증인)가 처벌받는 상황**을 시뮬레이션합니다.

*   **시나리오**:
    1.  Validator(Operator)가 `CandidateAddOn`을 통해 등록하고 TON을 스테이킹합니다.
    2.  잘못된 Root Claim을 가진 `DisputeGame`이 생성됩니다 (이 경우 Operator가 Proposer로 간주됨).
    3.  Challenger가 해당 Claim을 공격(Attack)하고 게임에서 승리합니다 (`CHALLENGER_WINS`).
    4.  Challenger가 `Layer2Manager.slashingCandidate`를 호출하여 Slashing을 실행합니다.

*   **검증 포인트**:
    *   **Stake 삭감**: Operator의 `DepositManager` 내 Stake 잔액이 **0**이 되어야 합니다.
    *   **보상 지급**: Challenger는 삭감된 금액의 **10%**를 WTON으로 보상받아야 합니다.
    *   **소각**: 나머지 90%는 소각(Burn)되어야 합니다.

### 3.2 RAT Tests (`TestSimpleRAT_ChallengerWins`)

이 테스트는 **RAT 시스템이 정직한 검증인을 보호하는 상황**을 시뮬레이션합니다.

*   **시나리오**:
    1.  Validator가 RAT에 등록되어 있습니다.
    2.  누군가(Proposer)가 잘못된 Root Claim으로 `DisputeGame`을 생성합니다.
    3.  **RAT 트리거**: DisputeGame 생성이 감지되어 Validator의 Bond가 잠깁니다.
    4.  Validator(Challenger 역할)가 잘못된 Claim을 공격(Attack)하여 게임에서 승리합니다.
    5.  Validator가 `RAT.resolveClaim`을 호출하여 **잠긴 Bond를 복구**합니다.
    6.  Validator가 `FaultDisputeGame.claimCredit`을 호출하여 **ETH 보상(Game Bond)**을 받습니다.

*   **검증 포인트**:
    *   **RAT Trigger**: DisputeGame 생성 시 이벤트가 발생하고 Bond가 잠겨야 합니다.
    *   **Bond 복구**: 승리 후 `resolveClaim` 호출 시 Validator의 **Deposit 및 TotalBond가 원래대로 복구**되어야 합니다. (처벌받지 않음)
    *   **Game Reward**: Validator는 게임 승리 보상으로 **ETH(Bond)**를 수령해야 합니다. (WTON 아님)

---

## 4. 결론 (Conclusion)

두 테스트 스위트는 TON Staking V2의 신뢰성 모델을 완성하는 상호 보완적인 테스트입니다.

*   **/slashing**: "나쁜 짓을 하면 처벌받는다 (WTON 뺏김)" -> **처벌 확실성 검증**
*   **/faultproofs (RAT)**: "올바르게 행동하면 보호받고 보상받는다 (WTON 보호, ETH 획득)" -> **참여자 보호 검증**

개발 및 유지보수 시 이 두 가지 관점을 명확히 분리하여 테스트하는 것이 중요합니다.

---

**분석 모델 (Analysis Model)**:
이 분석은 **Google DeepMind의 Gemini 3 Pro** 모델을 사용하여, 소스 코드의 정적 분석 및 시나리오 역설계를 통해 수행되었습니다.