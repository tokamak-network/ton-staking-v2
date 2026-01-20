# Comparison of RAT and Slashing Tests in op-e2e

This document analyzes the key differences and similarities between the **Randomized Attention Test (RAT)** tests and the **Slashing** tests within the `op-e2e` directory of the TON Staking V3 system. The analysis is based on a direct comparison of the test code and patterns.

## 1. Overview

| Aspect | RAT Tests | Slashing Tests |
| :--- | :--- | :--- |
| **Primary Location** | `op-e2e/faultproofs/` | `op-e2e/slashing/` |
| **Main File** | `rat_challenge_test.go` | `slashing_test.go` |
| **Core Purpose** | Verify the lifecycle of validator challenges and evidence submission. | Verify the economic penalty (slashing) of malicious operators. |
| **Tested Entity** | Validator (as challenger) | Operator (as proposer) |
| **Key Trigger** | Creation of a `DisputeGame` (via `RAT` probability). | A `DisputeGame` that has been resolved with `CHALLENGER_WINS`. |
| **Final Action** | `RAT.ResolveClaim()` to restore the validator's bond. | `Layer2ManagerSlashing.SlashingCandidate()` to slash the operator's stake. |

## 2. Test Patterns and Structure

Both sets of tests follow a similar high-level structure of setup, trigger, action, and verification. However, the specific patterns diverge significantly.

### Common Patterns

*   **Isolated Environment**: Both use `rat.StartTONStakingSystem(t)` to launch a clean Anvil node with a pre-configured genesis state for reliable, parallel testing.
*   **Deterministic Triggering**: Both override probabilistic systems for test reliability. The RAT test sets `SetRatTriggerProbability` to 100%, while the slashing test ensures the `DisputeGame` is created with a wrong claim to guarantee a challenger win.
*   **Time Manipulation**: Both use `evm_increaseTime` to simulate the passage of time required by the protocol (e.g., challenge period, withdrawal delay).

### Divergent Patterns

*   **RAT Test Pattern (`TestSimpleRAT_ChallengerWins`)**:
    1.  **Register**: A validator deposits TON to `RAT.registerValidator()`.
    2.  **Trigger**: A proposer creates a `DisputeGame` with a wrong claim.
    3.  **Evidence Submission**: The selected validator calls `RAT.submitEvidence()` to challenge the proposal.
    4.  **Game Resolution**: The challenger wins the `DisputeGame`.
    5.  **Bond Restoration**: The validator calls `RAT.resolveClaim()` to get their locked bond back.
    
    This pattern is focused on the validator's workflow and their financial incentives to participate.

*   **Slashing Test Pattern (`TestSlashing_BasicOperatorSlashing`)**:
    1.  **Register**: An operator registers with `Layer2Manager.registerCandidateAddOn()` and deposits WTON.
    2.  **Trigger**: A challenger creates a `DisputeGame` with a wrong claim, triggering the RAT system.
    3.  **Game Resolution**: The challenger wins the `DisputeGame`.
    4.  **Slashing Execution**: The challenger calls `Layer2ManagerSlashing.slashingCandidate()`.
    5.  **Stake Forfeiture**: The operator's entire stake is slashed.
    6.  **Reward Distribution**: The challenger receives a 10% reward, and 90% is burned.
    
    This pattern is focused on the operator's punishment and the economic disincentive for malicious behavior.

## 3. Key Differences in Verification Logic

The most significant difference lies in what the tests verify and the state they expect to see after the challenge is resolved.

| Verification Point | RAT Tests | Slashing Tests |
| :--- | :--- | :--- |
| **Validator/Operator Stake** | Verifies the deposit **remains intact** or is restored. (`regAfterResolve.DepositedAmount.Cmp(depositAmount) == 0`)| Verifies the stake is **fully removed**. (`operatorStake.Cmp(big.NewInt(0)) == 0`)|
| **Bond/Balance** | Verifies the bond that was temporarily locked for the challenge is **restored to 0**. (`regAfterResolve.TotalBondForRAT.Cmp(big.NewInt(0)) == 0`) | Does not directly verify the challenger's bond; focuses on the operator's forfeited funds. |
| **Reward** | The validator is **not financially rewarded** for participation (beyond bond restoration). | The challenger receives a **10% reward** of the slashed amount. (`challengerReward ≈ expectedReward`)|
| **Burn/Penalty** | No funds are burned. The penalty is reputational. | **90% of the stake is burned** or otherwise removed from circulation. |

## 4. Model Used for Analysis

This analysis was performed using the **Sisyphus** AI Agent from OhMyOpenCode. The agent used a parallel exploration strategy, launching multiple background `explore` agents to analyze the codebase simultaneously. It synthesized findings from both the `op-e2e/faultproofs` and `op-e2e/slashing` directories, comparing test structures, assertions, and helper functions to produce this comparative document. (qwne3-235b)