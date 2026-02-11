# Interactive Demo Session Scenarios (Front Demo)

This document describes the expected behavior for the Interactive Demo Session in the front demo.

## Entry Point
- Front UI: **Interactive Demo Session** section
- Options: **Single Challenger**, **Two Challengers**
- Action: Click **Start Demo Session**

---

## Scenario 1: Single Challenger

### Expected Flow
1. DisputeGame starts.
2. A single challenger participates.
3. The challenger wins the dispute.
4. Operator can be slashed by clicking **Slash Operator**.
5. Slashing executes successfully.
6. The winning challenger receives the reward.

### Verification Signals (examples)
- Game status becomes **Resolved**
- Operator slashed event emitted
- Challenger reward/credit claimed successfully

---

## Scenario 2: Two Challengers (Subgame Wins)

### Expected Flow
1. DisputeGame starts.
2. Two challengers participate in a subgame.
3. Both challengers win the subgame.
4. Operator can be slashed by clicking **Slash Operator**.
5. Slashing executes successfully.
6. Both winning challengers receive rewards.

### Verification Signals (examples)
- Game status becomes **Resolved**
- Operator slashed event emitted
- Rewards distributed to both winning challengers

---

## Issue Statement (Current)
- Single Challenger scenario completes successfully.
- Two Challengers scenario does not complete as expected: operator slashing or reward distribution for both challengers fails or does not trigger.

