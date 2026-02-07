# TON Staking V3 Devnet Setup - Work Summary

## ✅ Completed Tasks

### 1. L1 Node Issue Resolution
**Problem**: Geth in Post-merge (PoS) mode requires beacon client, blocks weren't being produced
**Solution**: Replaced Geth with **Anvil**
```bash
anvil --port 8545 --chain-id 900 --block-time 1 \
  --init .devnet/genesis-l1-staking-v3.json
```

**Benefits**:
- ✅ Auto-mines blocks every second
- ✅ No beacon client required  
- ✅ 30M gas limit (vs Geth's 4.7M)
- ✅ Developer-friendly

### 2. Rollup Registration
**Status**: ✅ Complete

Registered SystemConfig to L1BridgeRegistry as Type 3 rollup:
```bash
cast send 0x2dE080e97B0caE9825375D31f5D0eD5751fDf16D \
  "registerRollupConfigByManager(address,uint8,address,string)" \
  0x577AcB7fA48878245a854ba51eD051a5B47cF83f 3 0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E "Devnet L2" \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
  --rpc-url http://localhost:8545
```

**Verification**:
```bash
$ cast call 0x2dE080e97B0caE9825375D31f5D0eD5751fDf16D \
  "getRollupInfo(address)(uint8,address,bool,bool,string)" \
  0x577AcB7fA48878245a854ba51eD051a5B47cF83f \
  --rpc-url http://localhost:8545

3  # Type 3 (Optimism Bedrock DisputeGame)
0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E  # L2 TON
false
false
"Devnet L2"
```

### 3. L2 Operator Staking
**Status**: ✅ Complete

Registered CandidateAddOn with 1001 WTON stake:
```bash
# 1. Approve WTON
cast send 0x2B2fE3204CcB8282ac6bC31d485cB6aa010d193a "approve(address,uint256)" \
  0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44 \
  0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --rpc-url http://localhost:8545

# 2. Register CandidateAddOn
cast send 0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44 \
  "registerCandidateAddOn(address,uint256,bool,string)" \
  0x577AcB7fA48878245a854ba51eD051a5B47cF83f 1001000000000000000000000000000 false "Devnet Operator" \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --rpc-url http://localhost:8545
```

**Created Resources**:
- OperatorManager: `0x97F06B72fa7D6ea5B8BE8BDE4B67e272128Ac7B7`
- CandidateAddOn: Created and linked

### 4. Account Organization
**Status**: ✅ Complete

Created `ACCOUNTS.md` to prevent account conflicts:

| Account | Address | Role | Notes |
|---------|---------|------|-------|
| #0 | 0xf39Fd...2266 | Deployer / L2 Operator | ✅ Used |
| #1 | 0x70997...79C8 | TON Staking Deployer | ✅ Used (has manager role) |
| #2 | 0x3C44C...93BC | RAT Proxy Admin | ⚠️ DO NOT USE for validator |
| #3 | 0x90F79...3b906 | Validator #1 | ✅ Ready to use |
| #4 | 0x15d34...6A65 | Validator #2 | Available |
| #5+ | ... | Challengers/Others | Available |

**Important**: Account #2 is RAT proxy admin and cannot call RAT functions due to TransparentUpgradeableProxy pattern.

### 5. Documentation
**Status**: ✅ Complete

Created comprehensive documentation:
- `DEVNET_SETUP.md` - Complete setup guide
- `ACCOUNTS.md` - Account management and roles
- `SETUP_SUMMARY.md` - This file
- `scripts/register-and-stake.sh` - Automated registration script

## ⚠️ Known Issues

### Validator Registration
**Status**: ❌ Blocked

**Problem**: DepositManager requires Layer2 to be registered in Layer2Registry
```
Error: Caller is not a Layer2
```

**Root Cause**:
- OperatorManager (`0x97F06B72fa7D6ea5B8BE8BDE4B67e272128Ac7B7`) is NOT registered in Layer2Registry
- `DepositManager.deposit()` has `onlyLayer2` modifier
- This checks `Layer2Registry.layer2s(address)` which returns `false`

**Investigation Needed**:
1. Check if `Layer2Manager.registerCandidateAddOn()` should auto-register OperatorManager in Layer2Registry
2. If not, identify the correct function to register OperatorManager
3. Verify if this is a devnet-specific issue or expected behavior

**Workaround** (if needed):
Manual registration in Layer2Registry (requires appropriate permissions)

## 📋 Next Steps

### Immediate
1. **Resolve OperatorManager registration in Layer2Registry**
   - Review `Layer2Manager.registerCandidateAddOn()` implementation
   - Check if there's a missing step in the registration flow
   - Consider if genesis deployment should pre-register it

2. **Complete Validator Registration**
   Once OperatorManager is properly registered:
   ```bash
   # Deposit via OperatorManager
   cast send $DEPOSIT_MANAGER "deposit(address,address,uint256)" \
     $OPERATOR_MANAGER $VALIDATOR_ADDR 100000000000000000000000000000 \
     --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545
   
   # Register to RAT
   cast send $RAT "registerValidator(address)" $SYSTEM_CONFIG \
     --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545
   ```

3. **Verify V3 Migration**
   ```bash
   cast call $SEIG_MANAGER "v3Migrated()(bool)" --rpc-url http://localhost:8545
   ```

### Future
1. Start RAT clients for challenge monitoring
2. Deploy L2 components (op-node, op-batcher, op-proposer)
3. Test end-to-end flow with actual state proposals
4. Document complete validator journey

## 📝 Key Learnings

### Genesis vs Runtime
- **Genesis includes**: All contract deployments, rollup types, basic permissions
- **Genesis excludes**: Rollup config registration, operator staking, validator registration
- These must be done at runtime via transactions

### Geth vs Anvil for Devnet
- **Geth**: Production-ready but complex (PoS requires beacon client)
- **Anvil**: Perfect for devnet (instant blocks, high gas limit, no extra dependencies)
- **Recommendation**: Use Anvil for devnet L1

### Account Separation Critical
- Proxy admin accounts cannot call implementation functions (TransparentUpgradeableProxy)
- Separate accounts needed for: deployer, admin, operators, validators, challengers
- Document account roles clearly to avoid confusion

## 🔧 Tools & Scripts Created

### register-and-stake.sh
Automated script for:
- ✅ Verifying L1 node health
- ✅ Registering rollup config
- ✅ Funding accounts
- ✅ Registering CandidateAddOn
- ⚠️ Validator registration (blocked)

### Manual Commands Reference
All key operations documented with copy-paste ready commands in:
- `DEVNET_SETUP.md` - Manual setup steps
- `ACCOUNTS.md` - Account-specific operations

## 📊 System Status

```
✅ L1 Node: Running (Anvil on port 8545)
✅ Genesis: Deployed with all contracts
✅ Rollup: Registered as Type 3
✅ L2 Operator: Staked 1001 WTON
✅ OperatorManager: Created (0x97F06...7B7)
❌ Validator: Blocked (OperatorManager not in Layer2Registry)
⏸️  RAT Clients: Not started
⏸️  L2 Components: Not deployed
```

## 🎯 Success Criteria
- [x] L1 producing blocks automatically
- [x] Rollup registered in L1BridgeRegistry
- [x] CandidateAddOn registered with operator stake
- [x] Account roles clearly documented
- [ ] Validator successfully registered and staked
- [ ] RAT accepts validator registration
- [ ] End-to-end challenge flow working

## 📞 Support & References

**Contract Addresses** (`.devnet/addresses.json`):
- TON: `0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E`
- WTON: `0x2B2fE3204CcB8282ac6bC31d485cB6aa010d193a`
- Layer2Manager: `0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44`
- L1BridgeRegistry: `0x2dE080e97B0caE9825375D31f5D0eD5751fDf16D`
- DepositManager: `0x90118d110B07ABB82Ba8980D1c5cC96EeA810d2C`
- SeigManager: `0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe`
- RAT: `0xE5BD5bDC03371fB239956dbbF40bD185D6c2ea28`
- Layer2Registry: `0x05Aa229Aec102f78CE0E852A812a388F076Aa555`

**Key Files**:
- Genesis: `.devnet/genesis-l1-staking-v3.json`
- Deployment script: `script/DeployV3FullForDevnet.s.sol`
- Setup docs: `DEVNET_SETUP.md`, `ACCOUNTS.md`
