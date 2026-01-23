package rat

import (
	"crypto/ecdsa"
	"math/big"
	"strings"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
)

// Common test constants
const (
	// Test accounts private keys (Anvil test accounts)
	ValidatorPrivateKey  = "7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6" // Account #3
	DeployerPrivateKey   = "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d" // Account #1
	ProposerPrivateKey   = "47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a" // Account #4
	ChallengerPrivateKey = "8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba" // Account #5

	// Test parameters
	TestDepositAmountTON = 50000 // 50000 TON
	TestL2BlockNumber    = 100

	// Event signatures
	EventDisputeGameCreated     = "0x5b565efe82411da98814f356d0e7bcb8f0219b8d970307c5afb4a6903a8b2e35"
	EventAttentionTestTriggered = "0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38"
)

// TestAccounts holds all test account information
type TestAccounts struct {
	Validator struct {
		Key  *ecdsa.PrivateKey
		Addr common.Address
		Auth *bind.TransactOpts
	}
	Deployer struct {
		Key  *ecdsa.PrivateKey
		Addr common.Address
		Auth *bind.TransactOpts
	}
	Proposer struct {
		Key  *ecdsa.PrivateKey
		Addr common.Address
		Auth *bind.TransactOpts
	}
	Challenger struct {
		Key  *ecdsa.PrivateKey
		Addr common.Address
		Auth *bind.TransactOpts
	}
}

// TestContracts holds all contract instances
type TestContracts struct {
	RAT  *bindings.RAT
	TON  *bindings.ERC20
	WTON *bindings.WTON
}

// SetupTestAccounts creates and configures all test accounts
func SetupTestAccounts(t *testing.T, sys *TONStakingSystem) *TestAccounts {
	chainID, err := sys.L1Client.ChainID(sys.Ctx)
	require.NoError(t, err)

	accounts := &TestAccounts{}

	// Setup validator
	accounts.Validator.Key, err = crypto.HexToECDSA(ValidatorPrivateKey)
	require.NoError(t, err)
	accounts.Validator.Addr = crypto.PubkeyToAddress(accounts.Validator.Key.PublicKey)
	accounts.Validator.Auth, err = bind.NewKeyedTransactorWithChainID(accounts.Validator.Key, chainID)
	require.NoError(t, err)
	accounts.Validator.Auth.GasLimit = 3000000

	// Setup deployer
	accounts.Deployer.Key, err = crypto.HexToECDSA(DeployerPrivateKey)
	require.NoError(t, err)
	accounts.Deployer.Addr = crypto.PubkeyToAddress(accounts.Deployer.Key.PublicKey)
	accounts.Deployer.Auth, err = bind.NewKeyedTransactorWithChainID(accounts.Deployer.Key, chainID)
	require.NoError(t, err)
	accounts.Deployer.Auth.GasLimit = 3000000

	// Setup proposer
	accounts.Proposer.Key, err = crypto.HexToECDSA(ProposerPrivateKey)
	require.NoError(t, err)
	accounts.Proposer.Addr = crypto.PubkeyToAddress(accounts.Proposer.Key.PublicKey)
	accounts.Proposer.Auth, err = bind.NewKeyedTransactorWithChainID(accounts.Proposer.Key, chainID)
	require.NoError(t, err)
	accounts.Proposer.Auth.GasLimit = 5000000

	// Setup challenger
	accounts.Challenger.Key, err = crypto.HexToECDSA(ChallengerPrivateKey)
	require.NoError(t, err)
	accounts.Challenger.Addr = crypto.PubkeyToAddress(accounts.Challenger.Key.PublicKey)
	accounts.Challenger.Auth, err = bind.NewKeyedTransactorWithChainID(accounts.Challenger.Key, chainID)
	require.NoError(t, err)
	accounts.Challenger.Auth.GasLimit = 5000000

	return accounts
}

// ConnectTestContracts connects to RAT, TON, and WTON contracts
func ConnectTestContracts(t *testing.T, sys *TONStakingSystem) *TestContracts {
	contracts := &TestContracts{}

	var err error
	contracts.RAT, err = bindings.NewRAT(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	contracts.TON, err = bindings.NewERC20(sys.Addresses.TON, sys.L1Client)
	require.NoError(t, err)

	contracts.WTON, err = bindings.NewWTON(sys.Addresses.WTON, sys.L1Client)
	require.NoError(t, err)

	return contracts
}

// GetTestDepositAmount returns the standard test deposit amount (50000 TON in wei)
func GetTestDepositAmount() *big.Int {
	depositAmount := new(big.Int).SetUint64(TestDepositAmountTON)
	depositAmount.Mul(depositAmount, big.NewInt(1e18)) // Convert to wei
	return depositAmount
}

// AdjustMinimumCollateral adjusts RAT minimum collateral requirements if needed
func AdjustMinimumCollateral(t *testing.T, sys *TONStakingSystem, contracts *TestContracts, deployerAuth *bind.TransactOpts, depositAmount *big.Int) {
	callOpts := &bind.CallOpts{Context: sys.Ctx}
	minCollateral, err := contracts.RAT.GetMinimumCollateral(callOpts)
	require.NoError(t, err)

	// If deposit is sufficient, no adjustment needed
	if depositAmount.Cmp(minCollateral) >= 0 {
		return
	}

	t.Logf("Adjusting minimum collateral from %s to fit deposit %s", minCollateral.String(), depositAmount.String())

	// Set slashing penalty and validator buffer to 1/4 of deposit each
	quarterDeposit := new(big.Int).Div(depositAmount, big.NewInt(4))

	_, err = contracts.RAT.SetSlashingPenalty(deployerAuth, quarterDeposit)
	require.NoError(t, err)

	_, err = contracts.RAT.SetValidatorBuffer(deployerAuth, quarterDeposit)
	require.NoError(t, err)

	t.Logf("✓ Collateral requirements adjusted")
}

// RegisterValidatorWithTON registers a validator with TON deposit (V3 method)
// This uses the new flow: mint WTON -> deposit to DepositManager -> register with RAT
func RegisterValidatorWithTON(t *testing.T, sys *TONStakingSystem, contracts *TestContracts, validatorAuth *bind.TransactOpts, depositAmount *big.Int) {
	// Step 1: Get MockLayer2 address
	layer2 := sys.Addresses.MockLayer2
	if layer2 == (common.Address{}) {
		t.Fatal("MockLayer2 address not found in system addresses")
	}
	t.Logf("Using MockLayer2: %s", layer2.Hex())

	// Step 2: Increase deposit amount by 1% to account for coinage rounding
	adjustedAmount := new(big.Int).Mul(depositAmount, big.NewInt(101))
	adjustedAmount.Div(adjustedAmount, big.NewInt(100))
	t.Logf("Adjusted deposit amount: %s WTON (original: %s)", adjustedAmount.String(), depositAmount.String())

	// Step 3: Mint WTON to validator
	mintTx, err := contracts.WTON.Mint(validatorAuth, validatorAuth.From, adjustedAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, mintTx)
	require.NoError(t, err)
	t.Logf("✓ Minted %s WTON to validator", adjustedAmount.String())

	// Step 4: Approve WTON to DepositManager
	depositManager, err := bindings.NewDepositManager(sys.Addresses.DepositManagerProxy, sys.L1Client)
	require.NoError(t, err)

	approveTx, err := contracts.WTON.Approve(validatorAuth, sys.Addresses.DepositManagerProxy, adjustedAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err)
	t.Logf("✓ Approved %s WTON to DepositManager", adjustedAmount.String())

	// Step 5: Deposit WTON to Layer2 via DepositManager
	depositTx, err := depositManager.Deposit(validatorAuth, layer2, adjustedAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, depositTx)
	require.NoError(t, err)
	t.Logf("✓ Deposited %s WTON to Layer2", adjustedAmount.String())

	// Step 6: Register validator with RAT (no deposit parameter in V3)
	registerTx, err := contracts.RAT.RegisterValidator(validatorAuth, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, registerTx)
	require.NoError(t, err)

	t.Logf("✓ Validator registered with RAT (using coinage balance)")
}

// CreateDisputeGameWithWrongClaim creates a DisputeGame with a wrong root claim
func CreateDisputeGameWithWrongClaim(t *testing.T, sys *TONStakingSystem, proposerAuth *bind.TransactOpts) (*types.Receipt, common.Address) {
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	// Connect to DisputeGameFactory
	dgf, err := bindings.NewDisputeGameFactory(sys.Addresses.DisputeGameFactory, sys.L1Client)
	require.NoError(t, err)

	// Get required init bond
	gameType := uint32(0)
	initBond, err := dgf.InitBonds(callOpts, gameType)
	require.NoError(t, err)

	// Set bond value
	proposerAuth.Value = initBond

	// Create wrong root claim (obviously incorrect)
	rootClaim := [32]byte{0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}

	// extraData: 32 bytes containing l2BlockNumber
	l2BlockNumber := big.NewInt(TestL2BlockNumber)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

	// Create game
	createGameTx, err := dgf.Create(proposerAuth, gameType, rootClaim, extraData)
	require.NoError(t, err)

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, createGameTx)
	require.NoError(t, err)

	// Parse game address from DisputeGameCreated event
	var gameAddress common.Address
	for _, log := range receipt.Logs {
		if log.Topics[0].Hex() == EventDisputeGameCreated {
			gameAddress = common.HexToAddress(log.Topics[1].Hex())
			break
		}
	}
	require.NotEqual(t, common.Address{}, gameAddress, "Should have game address")

	t.Logf("✓ DisputeGame created at: %s", gameAddress.Hex())

	return receipt, gameAddress
}

// ParseRATTriggerEvent parses the AttentionTestTriggered event from receipt
func ParseRATTriggerEvent(t *testing.T, receipt *types.Receipt, expectedValidator common.Address) (testID [32]byte, triggered bool) {
	for _, log := range receipt.Logs {
		if log.Topics[0].Hex() == EventAttentionTestTriggered {
			triggered = true
			testID = log.Topics[1]
			selectedValidator := common.HexToAddress(log.Topics[2].Hex())

			t.Logf("✓ RAT triggered - Test ID: %s, Validator: %s",
				common.BytesToHash(testID[:]).Hex(), selectedValidator.Hex())

			require.Equal(t, expectedValidator, selectedValidator, "Wrong validator selected")
			return testID, true
		}
	}

	return [32]byte{}, false
}

// AdvanceTimeAndMine advances time in Anvil and mines a block
func AdvanceTimeAndMine(t *testing.T, sys *TONStakingSystem, seconds int64) {
	var timeResult interface{}
	err := sys.L1Client.Client().Call(&timeResult, "evm_increaseTime", seconds)
	require.NoError(t, err, "Failed to advance time")
	t.Logf("✓ Time advanced by %d seconds", seconds)

	var mineResult interface{}
	err = sys.L1Client.Client().Call(&mineResult, "evm_mine")
	require.NoError(t, err, "Failed to mine block")
	t.Logf("✓ Block mined")
}

// CreateDisputeGame creates a dispute game with a given root claim
func CreateDisputeGame(t *testing.T, sys *TONStakingSystem, proposerAuth *bind.TransactOpts, rootClaim [32]byte) (*types.Receipt, common.Address) {
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	// Connect to DisputeGameFactory
	dgf, err := bindings.NewDisputeGameFactory(sys.Addresses.DisputeGameFactory, sys.L1Client)
	require.NoError(t, err)

	// Get required init bond
	gameType := uint32(0)
	initBond, err := dgf.InitBonds(callOpts, gameType)
	require.NoError(t, err)

	// Set bond value
	proposerAuth.Value = initBond

	// extraData: 32 bytes containing l2BlockNumber
	l2BlockNumber := big.NewInt(TestL2BlockNumber)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

	// Create game
	createGameTx, err := dgf.Create(proposerAuth, gameType, rootClaim, extraData)
	require.NoError(t, err)

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, createGameTx)
	require.NoError(t, err)

	// Parse game address from DisputeGameCreated event
	gameAddress := ParseDisputeGameCreatedEvent(t, receipt)
	require.NotEqual(t, common.Address{}, gameAddress, "Should have game address")

	t.Logf("✓ DisputeGame created at: %s", gameAddress.Hex())

	return receipt, gameAddress
}

// ParseDisputeGameCreatedEvent parses the DisputeGameCreated event from receipt
func ParseDisputeGameCreatedEvent(t *testing.T, receipt *types.Receipt) common.Address {
	for _, log := range receipt.Logs {
		if log.Topics[0].Hex() == EventDisputeGameCreated {
			gameAddress := common.HexToAddress(log.Topics[1].Hex())
			return gameAddress
		}
	}
	return common.Address{}
}

// ParseRATTriggerEventWithBatchIndex parses the AttentionTestTriggered event with batchIndex from receipt
func ParseRATTriggerEventWithBatchIndex(t *testing.T, receipt *types.Receipt, expectedValidator common.Address) (testID [32]byte, batchIndex uint32, triggered bool) {
	for _, log := range receipt.Logs {
		if log.Topics[0].Hex() == EventAttentionTestTriggered {
			triggered = true
			testID = log.Topics[1]
			selectedValidator := common.HexToAddress(log.Topics[2].Hex())

			// Parse non-indexed data for batchIndex
			ratABI, err := abi.JSON(strings.NewReader(bindings.RATABI))
			require.NoError(t, err)

			type EventData struct {
				GameAddress common.Address
				BatchIndex  uint32
				Deadline    *big.Int
			}
			var data EventData
			err = ratABI.UnpackIntoInterface(&data, "AttentionTestTriggered", log.Data)
			require.NoError(t, err)

			batchIndex = data.BatchIndex
			t.Logf("✓ RAT triggered - Test ID: %s, Validator: %s, Batch: %d",
				common.BytesToHash(testID[:]).Hex(), selectedValidator.Hex(), batchIndex)

			require.Equal(t, expectedValidator, selectedValidator, "Wrong validator selected")
			return testID, batchIndex, true
		}
	}

	return [32]byte{}, 0, false
}

// AttackClaim attacks a claim in a DisputeGame
func AttackClaim(t *testing.T, sys *TONStakingSystem, challengerAuth *bind.TransactOpts, gameAddress common.Address, correctClaim [32]byte, wrongRootClaim [32]byte) {
	// Connect to FaultDisputeGame
	game, err := bindings.NewFaultDisputeGame(gameAddress, sys.L1Client)
	require.NoError(t, err)

	callOpts := &bind.CallOpts{Context: sys.Ctx}

	// Attack the root claim (claim index 0)
	parentClaim := wrongRootClaim // Wrong claim to attack
	parentIndex := big.NewInt(0)

	// Get required bond
	// Calculate next position using LibPosition logic (move(position, true) -> position * 2 for attack)
	// Root claim is at position 1 (gindex 1) usually in FaultDisputeGame lib, but here using ClaimData(0).
	// Let's rely on contract to tell us the bond or just use InitBond/claimData.Bond

	claimData, err := game.ClaimData(callOpts, parentIndex)
	require.NoError(t, err)

	// Position calculation might be complex to replicate exactly without LibPosition.
	// But usually for attack of root (level 0), we go to level 1.
	// Let's try to get bond for the next move.
	// Actually, `GetRequiredBond(position)` takes the *target* position.
	// If root is at '1' (gindex), attack is at '2'.
	// But let's check `claimData.Position`.

	nextPosition := new(big.Int).Mul(claimData.Position, big.NewInt(2)) // Attack moves to left child (2*i)

	requiredBond, err := game.GetRequiredBond(callOpts, nextPosition)
	if err != nil {
		t.Logf("⚠️ Failed to get required bond for pos %s: %v. Using parent bond.", nextPosition, err)
		requiredBond = claimData.Bond
	}

	t.Logf("Attacking claim 0 with bond: %s", requiredBond.String())

	// Set bond value
	challengerAuth.Value = requiredBond

	attackTx, err := game.Attack(challengerAuth, parentClaim, parentIndex, correctClaim)
	require.NoError(t, err)

	// Reset Auth Value
	challengerAuth.Value = nil

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, attackTx)
	require.NoError(t, err)
	require.Equal(t, types.ReceiptStatusSuccessful, receipt.Status, "Attack transaction failed")

	t.Logf("✓ Challenger attacked claim with correct root claim")
}

// ResolveGame resolves a DisputeGame (assumes simple 2-claim structure: Root + Attack)
func ResolveGame(t *testing.T, sys *TONStakingSystem, challengerAuth *bind.TransactOpts, gameAddress common.Address) {
	// Connect to FaultDisputeGame
	game, err := bindings.NewFaultDisputeGame(gameAddress, sys.L1Client)
	require.NoError(t, err)

	// Resolve claims bottom-up (simplistic approach for this test: Claim 1 (Attack) -> Claim 0 (Root))
	// In a real generic helper, we should traverse the DAG.

	t.Log("Resolving subgame for Claim 1 (Attack)...")
	// ResolveClaim(claimIndex, bondIndex) - bondIndex usually 0 if not managing multiple bonds per claim
	resolveTx1, err := game.ResolveClaim(challengerAuth, big.NewInt(1), big.NewInt(0))
	if err == nil {
		_, err = bind.WaitMined(sys.Ctx, sys.L1Client, resolveTx1)
		require.NoError(t, err)
	} else {
		t.Logf("⚠️ Failed to resolve claim 1: %v (might already be resolved or invalid)", err)
	}

	t.Log("Resolving subgame for Claim 0 (Root)...")
	resolveTx0, err := game.ResolveClaim(challengerAuth, big.NewInt(0), big.NewInt(0))
	if err == nil {
		_, err = bind.WaitMined(sys.Ctx, sys.L1Client, resolveTx0)
		require.NoError(t, err)
	} else {
		t.Logf("⚠️ Failed to resolve claim 0: %v", err)
	}

	// Resolve the game
	t.Log("Resolving main game...")
	resolveTx, err := game.Resolve(challengerAuth)
	require.NoError(t, err)

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, resolveTx)
	require.NoError(t, err)
	require.Equal(t, types.ReceiptStatusSuccessful, receipt.Status, "Resolve transaction failed")

	t.Logf("✓ DisputeGame resolved")
}

// GetGameStatus returns the current status of a DisputeGame
func GetGameStatus(t *testing.T, sys *TONStakingSystem, gameAddress common.Address) uint8 {
	// Connect to FaultDisputeGame
	game, err := bindings.NewFaultDisputeGame(gameAddress, sys.L1Client)
	require.NoError(t, err)

	callOpts := &bind.CallOpts{Context: sys.Ctx}
	status, err := game.Status(callOpts)
	require.NoError(t, err)

	return status
}
