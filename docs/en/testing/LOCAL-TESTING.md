# Local Testing Guide (V3)

This guide explains how to test the V3 integrated DelegateStaking locally.

## Prerequisites

- Foundry installed (`forge`, `anvil`, `cast`)
- Node.js 18+

## 1. Run Anvil

Run Anvil in a new terminal:

```bash
anvil
```

Default accounts will be created:
- Account #0 (Deployer): `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- Account #1 (Sequencer1): `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
- Account #2 (Sequencer2): `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`

## 2. Deploy V3 Environment

```bash
forge script script/DeployLocalV3.s.sol --rpc-url http://localhost:8545 --broadcast
```

Check the contract addresses from the deployment output:

```
========== DEPLOYMENT SUMMARY ==========
TOKEN ADDRESSES:
  TON:                   0x5FbDB2315678afecb367f032d93F642f64180aa3
  WTON:                  0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

V3 INFRASTRUCTURE:
  SeigManager:           0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  Layer2Manager:         0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9

DELEGATE STAKING:
  DelegateStakingV3:     0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
  DelegateTrigger:       0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
==========================================
```

## 3. Interaction Scripts

### Register Sequencer

```bash
# Set environment variables (check addresses from deployment output)
export STAKING=0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
export LAYER2=<layer2_address_from_deployment>
export OPERATOR_MANAGER=<operator_manager_from_deployment>
export COMMISSION=1000  # 10%

# Register sequencer (using Account #1)
forge script script/InteractV3.s.sol:RegisterSequencer --rpc-url http://localhost:8545 --broadcast
```

### Stake TON

```bash
export STAKING=0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
export TON=0x5FbDB2315678afecb367f032d93F642f64180aa3
export SEQUENCER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
export AMOUNT=1000000000000000000000  # 1000 TON

forge script script/InteractV3.s.sol:StakeTON --rpc-url http://localhost:8545 --broadcast
```

### Trigger Seigniorage

```bash
export STAKING=0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
export SEQUENCER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

forge script script/InteractV3.s.sol:TriggerSeigniorage --rpc-url http://localhost:8545 --broadcast
```

### Claim Rewards

```bash
export STAKING=0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
export WTON=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export SEQUENCER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

forge script script/InteractV3.s.sol:ClaimRewards --rpc-url http://localhost:8545 --broadcast
```

## 4. Direct Interaction with Cast

### Check Balances

```bash
# TON balance
cast call $TON "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# WTON balance
cast call $WTON "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### Query Staking Information

```bash
# Sequencer info
cast call $STAKING "getSequencerInfo(address)" $SEQUENCER

# Staker info
cast call $STAKING "getStakeInfo(address,address)" $STAKER $SEQUENCER

# Pending rewards
cast call $STAKING "pendingRewards(address,address)(uint256)" $STAKER $SEQUENCER
```

### Send Transactions Directly

```bash
# Approve TON
cast send $TON "approve(address,uint256)" $STAKING 1000000000000000000000 --private-key $PRIVATE_KEY

# Stake
cast send $STAKING "stake(address,uint256)" $SEQUENCER 1000000000000000000000 --private-key $PRIVATE_KEY
```

## 5. Mock V3 Components

Deployed mock contracts:

| Component | Description |
|-----------|-------------|
| `MockSeigManagerV3` | V3 SeigManager simulation (eligibility requirements, seigniorage calculation) |
| `MockLayer2ManagerV3` | L2 registration and OperatorManager creation |
| `MockOperatorManagerV3` | Seigniorage claim processing |

### Update BridgedTON (for seigniorage calculation)

```bash
cast send $SEIG_MANAGER "updateBridgedTON(address,uint256)" $LAYER2 100000000000000000000000 --private-key $PRIVATE_KEY
```

### Update StakedTON (for eligibility requirements)

```bash
cast send $SEIG_MANAGER "updateStakedTON(address,uint256)" $LAYER2 10000000000000000000000 --private-key $PRIVATE_KEY
```

## 6. Run Tests

```bash
# Full V3 tests
forge test --match-path "test/DelegateStakingV3.t.sol" -vvv

# Specific test
forge test --match-test test_Stake -vvv
```

## 7. Troubleshooting

### Transaction Failure
- Use `cast call` to invoke the function and check the revert message
- Verify permissions (operator, owner, etc.)
- Check sufficient balance/approval

### Address Mismatch
- Verify actual addresses from deployment logs
- Check that environment variables are set correctly

### Seigniorage Trigger Failure
- Check WTON balance in OperatorManager
- Verify that DelegateStaking is an authorized claimer for OperatorManager

---

## 8. V3 Upgradeable Version Testing (Recommended)

To test the UUPS Upgradeable version (`DelegateStakingV3Upgradeable`), use the following scripts.

### Deploy Environment

```bash
# Run Anvil (separate terminal)
anvil

# Deploy V3 Upgradeable environment
forge script script/DeployLocalV3Upgradeable.s.sol --rpc-url http://localhost:8545 --broadcast
```

Deployment output:

```
====================================================================
           V3 UPGRADEABLE DEPLOYMENT SUMMARY
====================================================================
 Network: localhost (Anvil)    Chain ID: 31337
--------------------------------------------------------------------
 TOKENS
   TON:
      0x5FbDB2315678afecb367f032d93F642f64180aa3
   WTON:
      0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
--------------------------------------------------------------------
 DELEGATE STAKING (UUPS UPGRADEABLE)
   Implementation:
      0x...
   Proxy:
      0x...
====================================================================
```

### Interaction Scripts

#### Full Flow Test (Recommended)

```bash
forge script script/InteractV3Upgradeable.s.sol:FullFlowTest --rpc-url http://localhost:8545 --broadcast
```

This script automatically tests the following:
1. Initial state verification
2. User1 stakes 1000 TON to Sequencer1
3. Trigger seigniorage
4. Claim rewards
5. Claim commission
6. Request unstake
7. Withdraw (after unbonding)

#### Individual Scripts

```bash
# Stake TON
forge script script/InteractV3Upgradeable.s.sol:StakeTON --rpc-url http://localhost:8545 --broadcast

# Trigger seigniorage
forge script script/InteractV3Upgradeable.s.sol:TriggerSeigniorage --rpc-url http://localhost:8545 --broadcast

# Claim rewards
forge script script/InteractV3Upgradeable.s.sol:ClaimRewards --rpc-url http://localhost:8545 --broadcast

# Unstake
forge script script/InteractV3Upgradeable.s.sol:Unstake --rpc-url http://localhost:8545 --broadcast

# Withdraw
forge script script/InteractV3Upgradeable.s.sol:Withdraw --rpc-url http://localhost:8545 --broadcast

# Redelegate
forge script script/InteractV3Upgradeable.s.sol:Redelegate --rpc-url http://localhost:8545 --broadcast

# Claim commission (sequencer)
forge script script/InteractV3Upgradeable.s.sol:ClaimCommission --rpc-url http://localhost:8545 --broadcast

# View state
forge script script/InteractV3Upgradeable.s.sol:ViewState --rpc-url http://localhost:8545 --broadcast
```

### Default Addresses (Anvil Deterministic Deployment)

DeployLocalV3Upgradeable.s.sol always deploys to the same addresses:

| Role | Address |
|------|---------|
| Deployer (#0) | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` |
| Sequencer1 (#1) | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` |
| Sequencer2 (#2) | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` |
| User1 (#3) | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` |
| User2 (#4) | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` |

### Upgrade Testing

```bash
# Upgradeable tests
forge test --match-path "test/DelegateStakingV3Upgradeable.t.sol" --match-test "Upgrade" -vvv
```
