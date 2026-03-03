# 7. Deployment and Operations

[← Back to Table of Contents](./README.md) | [← Previous: API Specification](./06-api-specification.md)

---

## 7.1 Local Demo Execution (One-Click)

```bash
# Prerequisites: Foundry, Node.js v18+, MetaMask
git clone --recurse-submodules <repo-url>
cd ton-staking-v2

# One-Click Execution (Anvil + Contract Deployment + Frontend)
./run-lottery-demo.sh
```

### Script Execution Steps

| Step | Action | Details |
|------|------|----------|
| 1 | Start Anvil | `--host 0.0.0.0 --port 8545 --chain-id 31337 --block-time 1` |
| 2 | Deploy Contracts | Execute `DeployLotteryDemo.s.sol` (`--via-ir` flag is required) |
| 2.5 | Initialize Seigniorage | Call `updateSeigniorage()` once (Resolves First-Call Trap) |
| 3 | Install Frontend | `npm install` (First time only, when `node_modules` is not present) |
| 4 | Start Frontend | Accessible at `http://localhost:5173` |

### Deployment Artifacts

The deployment script outputs JSON between the `DEPLOYMENT_JSON_START` / `DEPLOYMENT_JSON_END` markers. This JSON is automatically saved to `demo-frontend/src/deployment.json` and includes the following addresses:

- `ton`, `wton` - Token addresses
- `seigManager`, `depositManager` - Staking infrastructure
- `daoCommittee` - DAO Committee
- `lotteryCandidate` - Created LotteryCandidate proxy
- `operator` - Operator address
- Addresses and private keys of each account

---

## 7.2 Test Account Information

> Anvil default test accounts. **NEVER USE ON MAINNET.**

| Role | Address | Private Key | Initial Balance |
|------|------|------------|----------|
| Deployer | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec...f80` | ETH only |
| Operator | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e9...e71` | 1001 TON (Pre-deposited) |
| User1 | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111af...a53` | 1000 TON |
| User2 | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | `0x7c852118a...fd7` | 1000 TON |
| User3 | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` | `0x47e179ec1...c71` | 1000 TON |

---

## 7.3 Manual Execution (3 Terminals)

```bash
# Terminal 1: Start Anvil
anvil --host 0.0.0.0 --port 8545 --chain-id 31337 --block-time 1
```

```bash
# Terminal 2: Deploy Contracts
forge script script/DeployLotteryDemo.s.sol --via-ir \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast

# Copy the JSON between DEPLOYMENT_JSON_START and END from the output and 
# save it to demo-frontend/src/deployment.json

# Initialize seigniorage (Resolves First-Call Trap, required!)
sleep 2
cast send <lotteryCandidate_address> "updateSeigniorage()" \
  --rpc-url http://localhost:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

```bash
# Terminal 3: Start Frontend
cd demo-frontend
npm install
npm run dev
# → Access http://localhost:5173
```

---

## 7.4 MetaMask Setup

1. **Add Network:**
   - Network Name: `Anvil`
   - RPC URL: `http://localhost:8545`
   - Chain ID: `31337`
   - Currency Symbol: `ETH`

2. **Import Test Accounts:**
   - Settings → Import Account → Paste Private Key

---

## 7.5 Foundry Build and Test

```bash
# Build contracts
forge build                          # or make build

# Run all tests
forge test                           # or make test

# Only LotteryCandidate tests (detailed logs)
forge test --match-contract LotteryCandidateScenarioTest -vvv

# Only V3 tests
forge test --match-path "test/v3/*"  # or make test-v3

# E2E Tests (Go, requires genesis file)
make devnet-allocs-offline           # Generate genesis
make test-e2e                        # Run E2E tests
```

---

## 7.6 Environment Variables

**File:** `.env.example`

| Variable Name | Description | Default Value |
|--------|------|--------|
| `INFURA_API_KEY` | Infura API Key | Placeholder |
| `ETHERSCAN_API_KEY` | Etherscan API Key | Placeholder |
| `COINMARKETCAP_API_KEY` | CoinMarketCap API Key | Placeholder |
| `ETH_NODE_URI_localhost` | Local RPC URL | `http://127.0.0.1:8545/` |
| `ETH_NODE_URI_MAINNET` | Ethereum Mainnet RPC | Infura URL |
| `ETH_NODE_URI_sepolia` | Sepolia Testnet RPC | Infura URL |
| `ETH_NODE_URI_TITAN_GOERLI` | Titan L2 Goerli RPC | Hardcoded URL |
| `ETH_NODE_URI_THANOS_SEPOLIA` | Thanos L2 Sepolia RPC | Hardcoded URL |
| `ADMIN` | Admin Private Key | Anvil Account #0 |
| `DEPLOYER` | Deployer Private Key | Anvil Account #0 |
| `DEPLOYER_PRIVATE_KEY` | Deployer Private Key | Anvil Account #0 |
| `SEPOLIA_PRIVATE_KEY` | Sepolia Testnet Key | Placeholder |
| `AGENDA_KEY` | Agenda Dedicated Key | Placeholder |

---

## 7.7 Key Makefile Commands

```bash
make build                  # Build contracts
make test                   # Run all Solidity tests
make test-v3                # Run only V3 tests
make clean                  # Clean build artifacts
make devnet-allocs-offline  # Generate genesis file
make test-e2e               # Run E2E tests
make test-e2e-unit          # E2E unit tests (no genesis needed)
make devnet-status          # Check devnet status
make devnet-clean           # Clean devnet state
make help                   # Help
```

---

## 7.8 CI/CD Flow

> **Needs Verification:** It is necessary to verify whether a CI/CD pipeline (e.g., GitHub Actions) is configured separately. Check for the existence of the `.github/workflows` directory in the repository.

---

[Next: Security Considerations →](./08-security.md)
