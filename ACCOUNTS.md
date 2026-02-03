# TON Staking V3 - Account Management

This document defines the role assignment for Anvil default accounts to avoid conflicts.

## Account Roles

| # | Address | Private Key | Role | Usage |
|---|---------|-------------|------|-------|
| 0 | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` | **Deployer / L2 Operator** | - Deploys Optimism contracts<br>- Registers CandidateAddOn<br>- Operates L2 |
| 1 | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` | **TON Staking Deployer** | - Deploys TON Staking contracts (genesis)<br>- Has admin/manager role in L1BridgeRegistry<br>- Registers rollup configs |
| 2 | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` | **RAT Proxy Admin** | - **DO NOT USE** for validator<br>- Used as proxy admin in genesis<br>- Cannot call RAT functions directly |
| 3 | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | `0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a` | **Validator #1** | - First validator<br>- Stakes via DepositManager<br>- Registers to RAT |
| 4 | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` | `0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba` | **Validator #2** | - Second validator<br>- Stakes and registers to RAT |
| 5 | `0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc` | `0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e` | **Validator #3** | - Third validator<br>- Stakes and registers to RAT |
| 6 | `0x976EA74026E726554dB657fA54763abd0C3a0aa9` | `0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356` | **Challenger #1** | - RAT client operator<br>- Challenges invalid states |
| 7 | `0x14dC79964da2C08b23698B3D3cc7Ca32193d9955` | `0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97` | **Challenger #2** | - RAT client operator<br>- Challenges invalid states |
| 8 | `0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f` | `0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6` | **Challenger #3** | - RAT client operator<br>- Challenges invalid states |
| 9 | `0xa0Ee7A142d267C1f36714E4a8F75612F20a79720` | `0xf214f2b2cd398c806f84e317254e0f0b801d0643303237d97a22a48e01628897` | **Proposer** | - L2 proposer (op-proposer)<br>- Submits output roots |

## Important Notes

### Account #2 (0x3C44C...93BC) - RAT Proxy Admin

**⚠️ WARNING**: This account is set as the RAT proxy admin in genesis deployment. Due to TransparentUpgradeableProxy pattern:
- Cannot call RAT implementation functions directly
- Any attempt results in: `TransparentUpgradeableProxy: admin cannot fallback to proxy target`
- **Should NOT be used as a validator**

### Why Account Separation?

1. **Deployer (Account #0)**: Needs high nonce count for Optimism contract deployment
2. **TON Staking Deployer (Account #1)**: Separate nonce space for TON Staking contracts
3. **Proxy Admin (Account #2)**: Reserved for upgrade operations only
4. **Validators (#3-5)**: Independent accounts for validator operations
5. **Challengers (#6-8)**: RAT client operators
6. **Proposer (#9)**: L2 output proposal

## Genesis Configuration

In `DeployV3FullForDevnet.s.sol`:

```solidity
address constant OPTIMISM_DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Account #0
address constant DEPLOYER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;          // Account #1
address constant PROXY_ADMIN = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;     // Account #2
address constant VALIDATOR = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;       // Account #3
address constant PROPOSER = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;        // Account #4
address constant CHALLENGER = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;      // Account #5
```

## Validator Registration Process

### Step 1: Stake via DepositManager

Validators must first stake WTON through DepositManager:

```bash
DEPOSIT_MANAGER="0x90118d110B07ABB82Ba8980D1c5cC96EeA810d2C"
SYSTEM_CONFIG="0x577AcB7fA48878245a854ba51eD051a5B47cF83f"
VALIDATOR_KEY="0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"

# Stake WTON
cast send $DEPOSIT_MANAGER \
  "deposit(address,uint256)" \
  $SYSTEM_CONFIG 100000000000000000000000000000 \
  --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545
```

### Step 2: Register to RAT

After staking, register to RAT for validator assignment:

```bash
RAT="0xE5BD5bDC03371fB239956dbbF40bD185D6c2ea28"

# Register (systemConfig parameter)
cast send $RAT \
  "registerValidator(address)" \
  $SYSTEM_CONFIG \
  --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545
```

### Requirements

- V3 migration must be complete: `SeigManager.v3Migrated() == true`
- Minimum collateral: Check with `RAT.getDynamicMinimumCollateral(systemConfig)`
- Account must NOT be RAT proxy admin

## Docker Compose Integration

Update `docker-compose.yml` for RAT clients:

```yaml
rat-client-1:
  environment:
    - PRIVATE_KEY=0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356  # Account #6

rat-client-2:
  environment:
    - PRIVATE_KEY=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97  # Account #7

rat-client-3:
  environment:
    - PRIVATE_KEY=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6  # Account #8
```

## Troubleshooting

### "TransparentUpgradeableProxy: admin cannot fallback to proxy target"

**Cause**: Using RAT proxy admin account (0x3C44C...93BC) to call RAT functions

**Solution**: Use a different account (e.g., Account #3-8)

### "NotMigratedError()"

**Cause**: V3 migration not complete

**Solution**: 
```bash
cast send $SEIG_MANAGER "migrateToV3()" \
  --private-key $TON_STAKING_DEPLOYER_KEY --rpc-url http://localhost:8545
```

### "InsufficientCollateralError()"

**Cause**: Staked amount below minimum threshold

**Solution**: Check minimum and stake more:
```bash
cast call $RAT "getDynamicMinimumCollateral(address)(uint256)" \
  $SYSTEM_CONFIG --rpc-url http://localhost:8545
```
