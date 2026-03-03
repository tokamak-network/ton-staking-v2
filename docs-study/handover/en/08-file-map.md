# 8. Complete File Map

## Solidity Contracts (Core)

| File Path | Status | Role |
|-----------|--------|------|
| `lib/optimism/.../src/dispute/WinningChallengerTracker.sol` | New | Track winners contract |
| `lib/optimism/.../src/dispute/IWinningChallengerTracker.sol` | New | Interface |
| `lib/optimism/.../src/dispute/FaultDisputeGame.sol` | Modified | Dispute game core |
| `lib/optimism/.../src/dispute/DisputeGameFactory.sol` | Modified | Game factory |
| `lib/optimism/.../interfaces/dispute/IInitializable.sol` | Modified | Added initialize signature |
| `lib/optimism/.../interfaces/dispute/IDisputeGameFactory.sol` | Modified | Added tracker getter/setter |
| `lib/optimism/.../src/L1/OPContractsManager.sol` | Modified | Deployment manager |
| `lib/optimism/.../interfaces/L1/IOPContractsManager.sol` | Modified | Modified DeployInput |
| `lib/optimism/.../src/libraries/Blueprint.sol` | Reference | Blueprint deployment logic (Related to Issue #2) |

> **Note**: `lib/optimism/...` = `lib/optimism/packages/contracts-bedrock`

## Solidity Contracts (TON Staking)

| File Path | Status | Role |
|-----------|--------|------|
| `src/layer2/Layer2Manager_Slashing.sol` | Modified | Verify slashing candidate and execute |
| `src/stake/managers/DepositManager_Slashing.sol` | Modified | Execute slashing and distribute rewards |
| `src/stake/managers/SeigManager_Slashing.sol` | Modified | Process seigniorage slashing |
| `src/layer2/interfaces/IFaultDisputeGame.sol` | Modified | DisputeGame interface |
| `src/stake/interfaces/IIDepositManager.sol` | Modified | DepositManager interface |

## Mock Contracts (For Testing)

| File Path | Role |
|-----------|------|
| `src/mocks/MockFaultDisputeGame2.sol` | Simple game mock (Legacy) |
| `src/mocks/MockFaultDisputeGame3.sol` | Actual game flow simulation mock |
| `src/mocks/MockDisputeGameFactory3.sol` | Mock game factory |
| `src/mocks/MockSystemConfig.sol` | Added setDisputeGameFactory() function |

---

## Go Pipeline

| File Path | Role |
|-----------|------|
| `lib/optimism/op-deployer/pkg/deployer/state/chain_intent.go` | Tracker address in ChainProofParams |
| `lib/optimism/op-deployer/pkg/deployer/opcm/opchain.go` | Tracker address in DeployOPChainInput |
| `lib/optimism/op-deployer/pkg/deployer/pipeline/opchain.go` | Pipeline passing logic |
| `lib/optimism/op-chain-ops/cmd/devnet-allocs/main.go` | Devnet allocs generation options |
| `lib/optimism/packages/contracts-bedrock/scripts/deploy/DeployOPChain.s.sol` | Deployment script |
| `lib/optimism/packages/contracts-bedrock/scripts/deploy/DeployConfig.s.sol` | Deployment configuration |
| `lib/optimism/packages/contracts-bedrock/scripts/deploy/Deploy.s.sol` | Main deployment |

---

## Foundry Tests

| File Path | Number of Tests | Content |
|-----------|-----------------|---------|
| `test/v3/v3mode/AdvancedSlashing/BaseAdvancedSlashingTest.sol` | - | Base test |
| `test/v3/v3mode/AdvancedSlashing/SingleChallengerTest.t.sol` | 4 | Single challenger |
| `test/v3/v3mode/AdvancedSlashing/MultiChallengerEqualDistributionTest.t.sol` | 5 | Equal distribution |
| `test/v3/v3mode/AdvancedSlashing/WinnerTrackingTest.t.sol` | 5 | Winner tracking |
| `test/v3/v3mode/AdvancedSlashing/RemainderDistributionTest.t.sol` | 5 | Remainder distribution |
| `test/v3/v3mode/AdvancedSlashing/RealisticGameFlowTest.t.sol` | 5 | Realistic game flow |

---

## E2E Tests

| File Path | Role |
|-----------|------|
| `op-e2e/system/ton_system.go` | TON system wrapper |
| `op-e2e/slashing/slashing_helpers.go` | Common helper functions |
| `op-e2e/slashing/real_game_helpers.go` | Full Optimism + TON helpers |
| `op-e2e/slashing/slashing_test.go` | Basic slashing test |
| `op-e2e/slashing/slashing_challenger_test.go` | Real Challenger tests (5) |
| `op-e2e/slashing/multi_challenger_test.go` | Multi-Challenger tests (6) |
| `op-e2e/slashing/slashing_integration_test.go` | Slashing integration tests (4) |
| `op-e2e/slashing/reward_distribution_test.go` | Reward distribution tests (6) |
| `op-e2e/slashing/edge_cases_test.go` | Edge Cases tests (6) |
| `op-e2e/slashing/delegator_protection_test.go` | Delegator protection tests (4) |
| `op-e2e/slashing/complex_scenarios_test.go` | Complex scenarios tests (5) |
| `op-e2e/slashing/permission_security_test.go` | Permission/Security tests (7) |
| `op-e2e/Makefile` | Test execution targets |
| `op-e2e/go.work` | Go workspace settings |

---

## Deployment Scripts

| File Path | Role |
|-----------|------|
| `script/DeployV3WithSlashingForDevnet.s.sol` | Devnet deployment (Includes V3 migration) |
| `deployments/v3-devnet-slashing.json` | Deployed contract addresses |
| `.devnet/addresses.json` | Devnet allocs result addresses |
| `lib/optimism/packages/contracts-bedrock/foundry.toml` | Compiler optimization settings |

---

## Legacy Design/Implementation Documents

| Document Path | Description |
|---------------|-------------|
| `docs-study/AdvancedSlash/advanced-slash-architecture.md` | Full architecture design doc |
| `docs-study/AdvancedSlash/implementation-summary.md` | Implementation completion doc |
| `docs-study/AdvancedSlash/winning-challenger-tracking-plan.md` | Tracking implementation plan |
| `docs-study/AdvancedSlash/distributeBond-winner-analysis.md` | Winner determination analysis |
| `docs-study/AdvancedSlash/e2e-test/` | Collection of E2E test docs |
| `docs-study/AdvancedSlash/test/` | Foundry test docs |
| `docs-study/AdvancedSlash/anotherOption/` | Reward distribution alternative options |
| `docs-study/AdvancedSlash/en/` | English documents |

---

Next: [09-quickstart.md](./09-quickstart.md)
