# V2 Architecture Analysis

## 1. V2 Core Contract Structure

```
contracts/
├── stake/
│   ├── managers/
│   │   ├── SeigManagerV1_3.sol       ← Upgraded in V3 (SeigManagerV1_4)
│   │   ├── DepositManagerV1_2.sol    ← Upgraded in V3 (DepositManagerV1_3)
│   │   └── *Storage*.sol             ← V3 storage added
│   ├── tokens/
│   │   └── RefactorCoinageSnapshot.sol (no changes)
│   └── Layer2Registry.sol            (no changes)
├── layer2/
│   ├── Layer2ManagerV1_1.sol         ← Upgraded in V3 (Layer2ManagerV1_2)
│   ├── OperatorManagerV1_1.sol       (no changes)
│   └── L1BridgeRegistryV1_1.sol      ← Upgraded in V3 (L1BridgeRegistryV1_2)
├── dao/
│   ├── CandidateAddOnV1_1.sol        (no changes)
│   └── DAOCommittee_V1.sol           (no changes)
└── [V3 New]
    └── validator/
        ├── ValidatorPoolV1.sol       ← New (RAT validator rewards)
        └── ValidatorPoolStorage.sol
```

---

## 2. V2 Seigniorage Distribution Flow (Legacy - Deprecated in V3)

```
[V2 - Deprecated]
When updateSeigniorage() is called:
1. maxSeig = (currentBlock - lastSeigBlock) × seigPerBlock
2. stakedSeig = maxSeig × (WTON Total / TON Total Supply)
3. L2 distribution = TVL proportional

→ Completely replaced with new distribution formula in V3
```

---

## 3. V2 Two Seigniorage Distribution Systems

V2 operates **two seigniorage distribution systems**:

### 3.1 Staker Seigniorage: Coinage Factor Method (_tot, _coinages)

```solidity
// _tot: Manages "virtual balance" of entire staking pool
// _coinages[layer2]: Manages "virtual balance" of each L2 stakers

// 1. When updateSeigniorage is called, _tot's factor increases
//    → All stakers' balances automatically increase (rebasing effect)
uint256 prevTotalSupply = _tot.totalSupply();
uint256 nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
_tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

// 2. When a specific L2 calls commit(), it settles its share from _tot
//    → Receives accumulated seigniorage at once
uint256 prevTotalSupply = coinage.totalSupply();
uint256 nextTotalSupply = _tot.balanceOf(msg.sender);  // Tracked from _tot
uint256 seigs = nextTotalSupply - prevTotalSupply;     // Seigniorage to receive

// 3. Update that L2's coinage factor as well
coinage.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, coinage.factor()));

// 4. Actually mint WTON (to DepositManager)
IWTON(wton).mint(address(_depositManager), seigs);
```

**Coinage Characteristics:**
- `factor`: Balance multiplier. As factor increases, actual balance increases for same principal
- `_tot`: Global pool. Factor increases when seigniorage occurs each block
- `_coinages[layer2]`: Per-L2 pool. Settles from _tot when that L2 commits

### 3.2 L2 Sequencer Seigniorage: RewardPerUint Method (l2RewardPerUint + initialDebt)

```solidity
// 1. Calculate total L2 seigniorage (TVL proportional)
l2TotalSeigs = maxSeig × (totalLayer2TVL / totalTONSupply)

// 2. Accumulate reward per unit (linear increase)
l2RewardPerUint += (l2TotalSeigs × WEI_UNIT) / totalLayer2TVL

// 3. Calculate per-L2 reward (accumulated - initial debt)
layer2Seigs = (l2RewardPerUint × layer2Tvl_i) / WEI_UNIT - initialDebt_i

// 4. Update initial debt (next claim baseline)
initialDebt_i = (l2RewardPerUint × newLayer2Tvl_i) / WEI_UNIT
```

**RewardPerUint Characteristics:**
- `l2RewardPerUint`: Accumulated reward per TVL unit (continuously increases over time)
- `initialDebt`: Snapshot of accumulated value at participation time (considered already received)
- **Linear Proportional**: If TVL doubles, reward doubles

### 3.3 V2 Two Systems Comparison

| Category | Coinage (_tot, _coinages) | RewardPerUint (l2RewardPerUint) |
|----------|---------------------------|--------------------------------|
| **Target** | Stakers (TON depositors) | L2 Sequencers |
| **Distribution Basis** | Staking share | L2 TVL |
| **Mechanism** | Factor multiplier method | Accumulated unit reward method |
| **Settlement Time** | When L2 commits | When L2 calls updateSeigniorage |
| **Mint Target** | DepositManager | Layer2Manager |

---

## 4. V2 → V3 Storage Changes

V2 inherits 3 storage contracts. Changes in V3 are indicated below.

```solidity
// ============================================
// SeigManagerStorage (Base Storage) - V3 Changes
// ============================================

// --- Constants (Maintained) ---
uint256 constant public RAY = 1e27;
uint256 constant public MAX_VALID_COMMISSION = RAY;
uint256 constant public MIN_VALID_COMMISSION = 0.01e27;

// --- Base Contract Addresses ---
address internal _registry;        // ✅ Maintained
address internal _depositManager;  // ✅ Maintained
address internal _powerton;        // ⚪ V3: Unused
address public dao;                // ✅ Maintained

// --- Token Related (Maintained) ---
address internal _ton;             // ✅ Maintained
address internal _wton;            // ✅ Maintained
address public factory;            // ✅ Maintained

// --- Coinage Related (No Changes in V3) ---
RefactorCoinageSnapshotI internal _tot;                          // ✅ Maintained (no changes)
mapping (address => RefactorCoinageSnapshotI) internal _coinages; // ✅ Maintained (no changes)
mapping (address => uint256) internal _lastCommitBlock;           // ✅ Maintained

// --- Basic Seigniorage ---
uint256 internal _seigPerBlock;    // ✅ Maintained
uint256 internal _lastSeigBlock;   // ✅ Maintained

// --- Pause Related (Maintained) ---
uint256 internal _pausedBlock;
uint256 internal _unpausedBlock;
bool public paused;

// --- Commission Related ---
mapping (address => uint256) internal _commissionRates;          // ⚪ V3: Unused
mapping (address => bool) internal _isCommissionRateNegative;    // ⚪ V3: Unused
uint256 public adjustCommissionDelay;                            // ⚪ V3: Unused
// ... Other commission-related mappings unused

// --- V2 Distribution Rates ---
uint256 public powerTONSeigRate;   // ⚪ V3: Unused
uint256 public daoSeigRate;        // ⚪ V3: Unused (V3 uses daoDistributionRatio)
uint256 public relativeSeigRate;   // ✅ V3: Reused as transition parameter (r)
// Note: stakedSeigFactor (λ) is added in SeigManagerV1_4Storage

uint256 public accRelativeSeig;    // ⚪ V3: Unused
uint256 public minimumAmount;      // ✅ Maintained
uint256 public lastSnapshotId;     // ✅ Maintained

// ============================================
// SeigManagerV1_1Storage - V3 Changes
// ============================================
uint256 constant public SEIG_START_MAINNET = 10837698;           // ✅ Maintained
uint256 constant public INITIAL_TOTAL_SUPPLY_MAINNET = 50000000000000000000000000000000000; // ✅ Maintained
uint256 constant public BURNT_AMOUNT_MAINNET = 178111666909855730000000000000000;           // ✅ Maintained

uint256 public seigStartBlock;     // ✅ Maintained
uint256 public initialTotalSupply; // ✅ Maintained
uint256 public burntAmountAtDAO;   // ✅ Maintained

// ============================================
// SeigManagerV1_3Storage - V3 Changes
// ============================================
struct Layer2Reward {
    uint256 layer2Tvl;       // ⚪ V3: Unused (V3 uses bridgedTONInfo)
    uint256 initialDebt;     // ⚪ V3: Unused
    uint256 startBlock;      // ⚪ V3: Unused
}

address public l1BridgeRegistry;   // ✅ Maintained
address public layer2Manager;      // ✅ Maintained
uint256 public layer2StartBlock;   // ✅ Maintained
uint256 public l2RewardPerUint;    // ⚪ V3: Unused (V3 uses bridgedTONRewardPerUint)
uint256 public totalLayer2TVL;     // ⚪ V3: Unused (V3 uses totalEffectiveBridgedTON)

mapping(address => Layer2Reward) public layer2RewardInfo;  // ⚪ V3: Unused (V3 uses bridgedTONInfo)
mapping(address => uint256[]) public layer2PauseBlocks;    // ✅ Maintained
mapping(address => mapping(uint256 => uint256)) public layer2UnpauseBlocks; // ✅ Maintained

bool internal _lock;  // ✅ Maintained

// ============================================
// SeigManagerV1_4Storage (V3 New Addition)
// ============================================
// → Detailed definition in 02_v3_distribution.md and 04_implementation.md
```

---

## 5. V3 Storage Change Summary

| Existing Storage | V3 Status | Notes |
|-----------------|-----------|-------|
| `_tot` | ✅ Maintained | No changes |
| `_coinages` | ✅ Maintained | No changes |
| `_powerton` | ⚪ Unused | Storage slot maintained, not used in V3 |
| `powerTONSeigRate` | ⚪ Unused | Storage slot maintained, not used in V3 |
| `relativeSeigRate` | ✅ Reused | Used as V3 transition parameter r |
| `l2RewardPerUint` | ⚪ Unused | Storage slot maintained, not used in V3 |
| `totalLayer2TVL` | ⚪ Unused | Storage slot maintained, not used in V3 |
| `layer2RewardInfo` | ⚪ Unused | Storage slot maintained, not used in V3 |

| SeigManagerV1_4Storage (New) | Description |
|------------------------------|------------|
| `daoDistributionRatio` | d: DAO distribution ratio |
| `minStakingRatio` | θ: Minimum staking ratio |
| `validatorDistributionRatio` | α_v: Validator distribution ratio |
| `halfSaturationPoint` | k: Half-saturation point |
| `bridgedTONRewardPerUint` | Accumulated reward per Bridged TON unit |
| `totalEffectiveBridgedTON` | x: Total effective Bridged TON |
| `bridgedTONInfo` | Mapping of L2 Bridged TON information |
| `validatorPool` | ValidatorPool contract address |
| `stakedSeigFactor` | λ: Share seigniorage ratio (for transition) |

---

## 6. V3 Core Change: Staker Seigniorage Role Change

| Category | V2 | V3 |
|----------|-----|-----|
| **`_tot`, `_coinages`** | Used | ✅ **No changes** |
| **Staker Seigniorage** | Distributed via `setFactor()` | Gradually excluded from V3 distribution (existing logic maintained) |
| **Staking Role** | Determines seigniorage distribution amount | Used for eligibility check (S_i ≥ θ·B_i) |

- Existing storage slot structure is **not changed** (proxy pattern compatible)
- V3 new variables are added in **SeigManagerV1_4Storage**
- Functions related to `_tot`, `_coinages` are **not changed**

Whitepaper Quote:
> "In TON Staking V3, the distribution amount is determined based on each L2's Bridged TON.
> **L1 staking does not determine the distribution amount; rather, it functions as a minimum requirement to receive seigniorage.**"

| Beneficiary | V2 | V3 |
|-------------|-----|-----|
| **Stakers** | ✅ Coinage factor seigniorage | Gradually decreases, then not a V3 distribution target (used for eligibility) |
| **L2 Sequencers** | ✅ TVL proportional | ✅ Bridged TON proportional |
| **Validators** | ❌ None | ✅ α_v·y(x)/n |
| **DAO** | ✅ daoSeigRate | ✅ d·A₂ + undistributed portion |

