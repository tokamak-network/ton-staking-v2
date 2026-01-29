# TON Staking V3

> V3 staking smart contracts for Tokamak Network

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.4-blue)](https://soliditylang.org/)

**Based on:** [Tokamak Economics Whitepaper V3](https://github.com/tokamak-network/papers) (December 2025)

---

## 🚀 Quick Start

```bash
# Clone with submodules
git clone --recursive https://github.com/tokamak-network/ton-staking-v2.git
cd ton-staking-v2

# Install dependencies
forge install

# Build
forge build

# Run tests
forge test

# Run E2E tests
make devnet-allocs-offline  # First time only
make test-e2e
```

---

## 📖 What is TON Staking V3?

TON Staking V3 is an Ethereum L1 staking system that incentivizes:
- 🔒 **L2 Sequencers** - Secure network operation through performance-based rewards
- ✅ **Validators** - Continuous network monitoring via RAT (Randomized Attention Test)
- 🎯 **Fair Distribution** - Rewards based on actual network contribution (Bridged TON)

---

## 🆚 V2 → V3 Key Changes

| Feature | V2 | V3 |
|---------|-----|-----|
| **Distribution Basis** | L2 TVL | Bridged TON (performance) |
| **Distribution Function** | Linear | Hyperbolic: `y(x) = L·(x/(k+x))` |
| **Eligibility** | Minimum deposit | Staking ratio: `S_i ≥ θ·B_i` |
| **Validator Rewards** | None | `α·y(x) / n` |
| **Staker Seigniorage** | ✅ Provided | ❌ Deprecated |

**For detailed changes:** [V2 to V3 Upgrade Guide](./docs/specs-kr/08-v2-to-v3-upgrade-guide.md)

---

## 🏗️ System Architecture

```
Ethereum L1
├── SeigManager V3 ─────► Seigniorage distribution (hyperbolic)
├── DepositManager ─────► TON/WTON staking
├── Layer2Manager ──────► L2 registration & Bridged TON queries
├── L1BridgeRegistry ───► Bridge/Portal TVL tracking
├── RAT ────────────────► Validator attention tests & slashing
└── ValidatorReward ────► Validator reward pool

Optimism L2 (Titan, Thanos, etc.)
└── DisputeGameFactory ─► RAT triggers on dispute game creation
```

**Detailed docs:** [System Architecture](./docs/specs-kr/02-system-architecture.md)

---

## 📦 Core Contracts

| Contract | Version | Role |
|----------|---------|------|
| **SeigManagerV3_1** | V1_4 | V3 seigniorage distribution |
| **DepositManagerV3** | V1_2 | Staking management |
| **Layer2ManagerV3** | V1_2 | L2 registration |
| **L1BridgeRegistryV1_2** | V1_2 | Bridge TVL queries |
| **RAT** | V1 | Validator attention tests |
| **ValidatorRewardV1** | V1 | Validator rewards |

**Full contract details:** [Contract Structure](./docs/specs-kr/03-contract-structure.md)

---

## 🧪 Testing

### Quick Test Commands
```bash
# All tests
forge test

# V3 tests only
forge test --match-path "test/v3/*"

# Specific contract
forge test --match-contract RATTest

# E2E tests (Go)
make test-e2e
```

### Test Documentation
- **[Testing Guide](./docs/test/README.md)** - Complete testing overview
- **[Quick Commands](./docs/test/QUICK-COMMANDS.md)** - All test commands reference
- **[E2E Tests](./op-e2e/README.md)** - Go-based end-to-end tests

**Test Coverage:** 175+ unit/integration tests + 7 E2E tests

---

## 📚 Documentation

### 🌐 Developer Guide (Recommended)
**Complete interactive documentation with search:**
- **English:** https://tokamak-network.github.io/ton-staking-v2/
- **한국어:** https://tokamak-network.github.io/ton-staking-v2/ko/

Includes system architecture, actor guides, function specs, and V2→V3 upgrade guide.

### 📖 Core Specifications (Korean)
- [System Overview](./docs/specs-kr/01-system-overview.md) - V3 introduction & changes
- [System Architecture](./docs/specs-kr/02-system-architecture.md) - Contract dependencies & flow
- [Contract Structure](./docs/specs-kr/03-contract-structure.md) - Directory & storage layout
- [Contract Roles](./docs/specs-kr/04-contract-roles.md) - Responsibilities & interactions
- [Actors](./docs/specs-kr/05-actors.md) - Sequencer, Validator, DAO roles
- [Function Specs](./docs/specs-kr/06-function-specs.md) - Detailed function reference
- [V2→V3 Upgrade](./docs/specs-kr/08-v2-to-v3-upgrade-guide.md) - Migration guide

### 🧪 Test Documentation
- [Testing Guide](./docs/test/README.md) - Quick start & overview
- [Quick Commands](./docs/test/QUICK-COMMANDS.md) - Command reference
- [E2E Tests](./op-e2e/README.md) - Go E2E test guide
- [Genesis Setup](./op-e2e/GENESIS-SETUP.md) - E2E environment setup

---

## 📂 Project Structure

```
src/
├── stake/              # Core staking logic
│   └── managers/       # SeigManager, DepositManager
├── layer2/             # L2 management
│   ├── managers/       # Layer2Manager, L1BridgeRegistry
│   └── factory/        # OperatorManagerFactory
├── validator/          # Validator system
│   ├── RAT.sol         # Randomized Attention Test
│   └── ValidatorRewardV1.sol
└── dao/                # DAO governance

test/
├── v3/                 # V3 unit tests
│   ├── v3mode/         # V3 mode tests
│   ├── scenarios/      # Integration scenarios
│   └── invariants/     # Invariant tests
└── v2mode/             # V2 compatibility tests

op-e2e/                 # Go E2E tests
├── faultproofs/        # RAT scenario tests
└── e2eutils/           # Test utilities
```

---

## 🔧 Development

### Requirements
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Go 1.22+](https://go.dev/dl/) (for E2E tests)
- [Node.js](https://nodejs.org/) (optional, for documentation)

### Build
```bash
forge build
```

### Test
```bash
# Solidity tests
forge test

# E2E tests
make devnet-allocs-offline  # Generate genesis (once)
make test-e2e
```

### Clean
```bash
forge clean
```

---

## 🔗 External Libraries

| Library | Purpose |
|---------|---------|
| [@optimism](https://github.com/ethereum-optimism/optimism) | L1/L2 interfaces (SystemConfig, Portal, Bridge) |
| [@openzeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts) | Standard contracts (ERC20, Access Control, Math) |
| [@tokamak-dao](https://github.com/tokamak-network/tokamak-dao-contracts) | DAO governance contracts |

### Submodules
```bash
# Update optimism library
git submodule update --remote lib/optimism

# Update all submodules
git submodule update --init --recursive
```

---

## 🌐 Networks

### Mainnet (TBD)
- **Chain ID:** 1 (Ethereum)
- **Contracts:** TBD

### Testnet (TBD)
- **Chain ID:** 5 (Goerli) / 11155111 (Sepolia)
- **Contracts:** TBD

---

## 🤝 Contributing

We welcome contributions! Please see:
- [Contributing Guidelines](./CONTRIBUTING.md) (if available)
- [Code of Conduct](./CODE_OF_CONDUCT.md) (if available)

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `forge test && make test-e2e`
5. Submit a pull request

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/tokamak-network/ton-staking-v2/issues)
- **Discussions:** [GitHub Discussions](https://github.com/tokamak-network/ton-staking-v2/discussions)
- **Documentation:** [docs/specs-kr/](./docs/specs-kr/)

---

## 📄 License

MIT License - see [LICENSE](./LICENSE) for details

---

## 🔗 Related Projects

- [Tokamak Network](https://tokamak.network/)
- [Optimism](https://optimism.io/)
- [Tokamak DAO Contracts](https://github.com/tokamak-network/tokamak-dao-contracts)

---

**Built with ❤️ by [Tokamak Network](https://tokamak.network/)**
