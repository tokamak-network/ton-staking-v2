# 9. Quickstart Guide (For New Maintainers)

## Step 1: Check Environment

```bash
cd /path/to/ton-staking-v2

# Check Foundry installation
forge --version    # Necessary: Foundry

# Check Go installation
go version         # Necessary: Go 1.23+

# Check Docker (For Full Optimism tests)
docker --version

# Initialize submodule
git submodule update --init --recursive
```

---

## Step 2: Build Contracts

```bash
# Build TON Staking V2
forge build

# Build Optimism contracts
cd lib/optimism/packages/contracts-bedrock
forge build --skip test
```

---

## Step 3: Run Foundry Unit Tests

```bash
# From the project root

# AdvancedSlashing tests (24) - Multi-Challenger reward distribution
forge test --match-path "test/v3/v3mode/AdvancedSlashing/*.t.sol" -v

# BasicSlashing tests (38) - Basic slashing logic
forge test --match-path "test/v3/v3mode/BasicSlashing/*.t.sol" -v
```

---

## Step 4: Run E2E Tests

```bash
# Generate Genesis (Initial once)
make devnet-allocs-offline

# Slashing E2E tests (41, ~2 mins)
cd op-e2e && make test-slashing-all
```

---

## Step 5: Recommended Code Understanding Order

It is recommended to follow this order when initially understanding the code:

### Stage 1: Grasping the Big Picture

Read `docs-study/AdvancedSlash/advanced-slash-architecture.md`
- System architecture diagram
- Data flow (Game Creation → Challenge → Slashing → Reward Distribution)

### Stage 2: Understanding Winner Determination Logic

Read `docs-study/AdvancedSlash/distributeBond-winner-analysis.md`
- Why the `_distributeBond` recipient is considered the winner
- Reason for the `gameCreator` filtering
- Analysis of 3 cases

### Stage 3: Core New Contracts

Read `lib/optimism/packages/contracts-bedrock/src/dispute/WinningChallengerTracker.sol`
- `recordWinner()`: Winner recording logic
- Access Control: `msg.sender == game`
- Duplication prevention mechanism

### Stage 4: FaultDisputeGame Modifications

Search for `_recordWinningChallenger` in `lib/optimism/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol`
- Check locations called from within 3 places in `resolveClaim()`
- Check `initialize(address, address)` overload

### Stage 5: TON Slashing Logic

`slashingCandidate()` function in `src/layer2/Layer2Manager_Slashing.sol`
- Verify game state (CHALLENGER_WINS)
- `_getWinningChallengers()` → Array of winners query
- Calls `DepositManager.slash()`

### Stage 6: Reward Distribution

`slash()`, `_distributeRewards()` functions in `src/stake/managers/DepositManager_Slashing.sol`
- Equal distribution logic
- Remainder processing
- WTON safeTransfer

---

## Commonly Used Commands

```bash
# Foundry test (Specific)
forge test --match-test test_TwoChallengers_50_50_Split -vvv

# E2E All
cd op-e2e && make test-slashing-all

# E2E by Category
cd op-e2e && make test-reward-distribution

# Optimism faultproofs test (Full devnet)
cd lib/optimism && go test -v -timeout 15m -run "TestOutputAlphabetGame_" ./op-e2e/faultproofs/...

# Regenerate Genesis
make devnet-allocs-offline

# Build Solidity
forge build
cd lib/optimism/packages/contracts-bedrock && forge build --skip test
```

---

## Helpful Documents

| Priority | Document | Reason |
|----------|----------|--------|
| High | `docs-study/AdvancedSlash/advanced-slash-architecture.md` | Full architecture |
| High | `docs-study/AdvancedSlash/implementation-summary.md` | Complete list of changed files |
| Medium | `docs-study/AdvancedSlash/distributeBond-winner-analysis.md` | Detail on winner determination logic |
| Medium | `docs-study/AdvancedSlash/e2e-test/real-faultdisputegame-migration-complete.md` | Latest E2E test state |
| Low | `docs-study/AdvancedSlash/e2e-test/dispute-game-depth-bond-analysis.md` | Bond cost analysis |
| Low | `docs-study/AdvancedSlash/anotherOption/` | Alternative reward distribution options |
