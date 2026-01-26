# Slashing Test Guide (Modular V3)

This document describes the structure and execution methods of the modularized slashing tests located in `test/v3/v3mode/BasicSlashing/`.

## 1. Test Objectives
The goal is to verify that the slashing mechanism of Tokamak Network V3 operates as intended across various scenarios, including basic operation, delegator protection, multi-operator environments, and security vulnerability attacks.

## 2. Test Environment Setup
The tests are built by inheriting from `BaseSlashingTest.sol`.
- **BaseSlashingTest**: Minimizes code duplication by providing infrastructure for TON/WTON deployment, Layer 2 registration, and helper functions (slashing execution, seigniorage updates, etc.).
- **Mocking**: Simulates slashing conditions without an actual Dispute Game by using `MockDisputeGameFactory` and `MockFaultDisputeGame2`.

## 3. Test File Summary

| File Name | Primary Test Content |
|-----------|----------------------|
| **SlashingBasicTest.t.sol** | Candidate registration, basic slashing process, and event emission verification. |
| **SlashingDelegatorTest.t.sol** | Protection of delegator stakes and seigniorage during operator slashing, and withdrawal availability after slashing. |
| **SlashingRewardRateTest.t.sol** | Verification of challenger rewards and burn amounts based on various reward rates (0%, 10%, 50%, 100%). |
| **SlashingSeigniorageTest.t.sol** | Slashing logic with unreceived seigniorage and full burning of principal/earnings. |
| **SlashingSecurityTest.t.sol** | Prevention of double slashing, restriction of rewards to winners only, and unauthorized access blocking. |
| **SlashingAttackVectorTest.t.sol**| Simulation of attacks using reentrancy vulnerabilities and malicious Dispute Game states. |
| **SlashingMultiOperatorTest.t.sol**| Independent slashing and first-come-first-served reward principles in multi-operator environments. |
| **SlashingEdgeCaseTest.t.sol** | Edge cases such as below-minimum stake, slashing after partial withdrawal, and invalid game states. |

## 4. How to Run Tests

### Running Specific Files (Recommended)
Since the tests are modularized, you can quickly test specific functionalities.
```bash
# Run delegator protection tests only
forge test --match-path test/v3/v3mode/BasicSlashing/SlashingDelegatorTest.t.sol -vvv

# Run security-related tests only
forge test --match-path test/v3/v3mode/BasicSlashing/SlashingSecurityTest.t.sol -vvv
```

### Running All Slashing Tests
```bash
# Run all tests within the BasicSlashing folder
forge test --match-path "test/v3/v3mode/BasicSlashing/*.t.sol" -vvv
```

## 5. Scenario Comparison and Change History
For detailed scenario mapping and change logs, please refer to the [Slashing Test Scenario Comparison](./slashing-test-scenario-comparison.md).
