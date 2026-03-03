# 3. Directory Structure Description

[← Back to Table of Contents](./README.md) | [← Previous: System Architecture](./02-system-architecture.md)

---

> ★ marks the core files of the LotteryCandidate feature.

```
ton-staking-v2/
│
├── src/                              # Solidity source code (180 files)
│   │
│   ├── dao/                          # ★ DAO Governance (52 files) - LotteryCandidate core
│   │   ├── LotteryCandidate.sol          # ★ Core implementation contract (Lottery+Staking)
│   │   ├── LotteryCandidateProxy.sol     # ★ Proxy contract
│   │   ├── LotteryCandidateStorage.sol   # ★ Storage layout definition
│   │   ├── Candidate.sol                 # Existing candidate contract (for comparison)
│   │   ├── CandidateAddOnV1_1.sol        # Add-on candidate
│   │   ├── DAOCommittee_V1.sol           # ★ DAO Committee (includes createLotteryCandidate)
│   │   ├── DAOCommitteeOwner.sol         # DAO Committee Owner functions
│   │   ├── StorageStateCommittee.sol     # Committee storage V1
│   │   ├── StorageStateCommitteeV2.sol   # ★ Committee storage V2 (includes lotteryCandidateFactory)
│   │   │
│   │   ├── factory/                      # Factory contracts
│   │   │   ├── LotteryCandidateFactory.sol   # ★ Lottery Candidate Factory
│   │   │   ├── CandidateFactory.sol          # Existing candidate factory
│   │   │   └── CandidateAddOnFactory.sol     # Add-on candidate factory
│   │   │
│   │   ├── interfaces/                   # DAO Interfaces (17 files)
│   │   │   ├── ICandidate.sol
│   │   │   ├── IDAOCommittee.sol
│   │   │   ├── IDAOAgendaManager.sol
│   │   │   ├── IDAOVault.sol
│   │   │   └── ... (others)
│   │   │
│   │   └── lib/                          # Utilities
│   │       ├── Agenda.sol
│   │       └── BytesLib.sol
│   │
│   ├── stake/                        # Staking System (50 files)
│   │   ├── managers/
│   │   │   ├── SeigManagerV3_1.sol       # V3 Seigniorage Core (Hyperbolic saturation function)
│   │   │   ├── SeigManagerV3_2.sol       # V3 delegatecall (V2 compatible mode)
│   │   │   ├── SeigManagerV1_2.sol       # V1.2 Base implementation
│   │   │   ├── DepositManagerV3.sol      # V3 Deposit/Withdrawal management
│   │   │   └── Storage*.sol              # Storage definition files
│   │   ├── tokens/
│   │   │   ├── AutoRefactorCoinage.sol   # Refactored Coinage Token
│   │   │   └── RefactorCoinageSnapshot.sol # Snapshot feature
│   │   ├── factory/
│   │   │   └── CoinageFactory.sol        # Coinage Token Factory
│   │   └── Layer2Registry.sol            # L2 Registry (Coinage deployment)
│   │
│   ├── layer2/                       # L2 Management (38 files)
│   │   ├── Layer2ManagerV3.sol           # V3 L2 Manager
│   │   ├── L1BridgeRegistryV1_2.sol      # L1 Bridge Registry
│   │   └── OperatorManagerV1_2.sol       # Operator Manager
│   │
│   ├── validator/                    # Validator System (8 files)
│   │   ├── RAT.sol                       # Randomized Attention Test
│   │   └── ValidatorRewardV1.sol         # Validator Reward
│   │
│   ├── proxy/                        # Proxy Pattern (8 files)
│   │   ├── Proxy.sol                     # Generic Proxy
│   │   ├── ProxyStorage.sol              # Proxy Storage base
│   │   └── DAOCommitteeProxy2.sol        # DAO Committee Proxy
│   │
│   ├── common/                       # Common Utils (6 files)
│   │   ├── AccessibleCommon.sol          # Access control common
│   │   └── AuthRole.sol                  # Role definitions
│   │
│   ├── accessControl/                # Access Control (6 files)
│   ├── libraries/                    # Utility Libraries (5 files)
│   │   ├── DSMath.sol, FullMath.sol, SafeERC20.sol, Create2.sol
│   │
│   └── mocks/                        # Test Mock Contracts (11 files)
│       ├── MockTON.sol, MockWTON.sol
│       ├── MockDisputeGameFactory.sol
│       └── ... (others)
│
├── test/                             # Test Suite (36 files)
│   └── v3/
│       ├── scenarios/
│       │   ├── LotteryCandidate.t.sol    # ★ LotteryCandidate Scenario Test
│       │   ├── SequencerJourney.t.sol
│       │   └── ValidatorJourney.t.sol
│       ├── v3mode/                       # V3 Mode Tests
│       │   ├── RAT.t.sol
│       │   ├── ValidatorRewardV1.t.sol
│       │   └── BasicSlashing/            # Slashing Tests (8)
│       ├── v2mode/                       # V2 Compatibility Tests
│       ├── invariants/                   # Invariant Tests
│       └── helpers/                      # Test Helpers
│
├── script/                           # Deployment Scripts (9 files)
│   ├── DeployLotteryDemo.s.sol           # ★ Lottery Demo Deployment (459 lines)
│   ├── DeployV3Full.s.sol                # V3 Full Deployment
│   ├── DeployV3FullSlash.s.sol           # V3 Deployment with Slashing
│   └── VerifyGenesisSetup.s.sol          # Genesis Verification
│
├── demo-frontend/                    # ★ React Frontend
│   ├── src/
│   │   ├── App.tsx                       # Main App (Settings Management + Layout)
│   │   ├── main.tsx                      # Entry point
│   │   ├── wagmi.ts                      # Web3 Config (Anvil only)
│   │   ├── contracts/
│   │   │   └── abi.ts                    # ★ Contract ABI Definition (Manual management)
│   │   └── components/
│   │       ├── ConnectWallet.tsx          # Wallet Connect/Disconnect
│   │       ├── LotteryInfo.tsx           # Lottery Status Dashboard
│   │       ├── LotteryActions.tsx        # Lottery Enter/Draw Buttons
│   │       ├── DepositForm.tsx           # TON Deposit (approve → deposit)
│   │       ├── UserBalance.tsx           # Display Balance (TON/WTON/Deposit)
│   │       ├── SeignioragePanel.tsx      # Seigniorage Distribution + Block Mining Tool
│   │       └── PastRounds.tsx            # Past Rounds Results History
│   ├── package.json                      # React 18 + Vite + wagmi + Tailwind
│   └── vite.config.ts
│
├── docs/LotteryCandidate/            # ★ LotteryCandidate Documentation
│   ├── en/                               # English (README, contracts, scenario, demo)
│   ├── kr/                               # Korean (same structure, demo is more detailed)
│   ├── handover/                         # ★ Handover Docs (These documents)
│   ├── seigniorage-update-report.md      # Seigniorage Issue Resolution Report
│   └── seigniorage-troubleshooting.md    # Seigniorage Troubleshooting Guide
│
├── docs/                             # Full Project Documentation
│   ├── specs-kr/                         # Korean Specs (12 files)
│   ├── test/                             # Test Documentation (8 files)
│   ├── deployment/                       # Deployment Guide
│   └── *.pdf                             # Whitepapers (V1~V3)
│
├── lib/                              # Git Submodules
│   ├── forge-std/                        # Foundry Standard Library
│   ├── openzeppelin-contracts/           # OpenZeppelin
│   ├── optimism/                         # Optimism (Tokamak fork)
│   └── tokamak-dao-contracts/            # Tokamak DAO
│
├── op-e2e/                           # Go E2E Tests (27 bindings)
│
├── run-lottery-demo.sh               # ★ One-click Demo Run Script
├── Makefile                          # Build/Test/Deploy Automation
├── foundry.toml                      # Foundry Configuration
├── hardhat.config.ts                 # Hardhat Configuration
├── .env.example                      # Environment variables example
├── README.md                         # Project README (English)
└── README_kr.md                      # Project README (Korean)
```

---

[Next: Core Business Logic →](./04-business-logic.md)
