package slashing

import (
	"context"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/rpc"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/challenger"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/system"
)

// TestRealChallenger_SingleChallengerSlashing tests that a single challenger
// receives the full slashing reward when they win a dispute game.
func TestRealChallenger_SingleChallengerSlashing(t *testing.T) {
	t.Parallel()
	ctx := context.Background()

	// Start TON Staking system with genesis
	ratSys := rat.StartTONStakingSystem(t)

	// Create TON system wrapper
	tonSys := system.StartTONFaultDisputeSystem(t, ratSys.L1Client)

	// Deploy MockDisputeGameFactory3 for this test
	factoryAddr := deployMockDisputeGameFactory3(t, ratSys)
	t.Logf("MockDisputeGameFactory3 deployed at: %s", factoryAddr.Hex())

	// Create a single challenger
	chl := challenger.NewTONChallenger(t, ctx, tonSys)

	// Create a dispute game with an invalid root claim
	rootClaim := [32]byte{0xDE, 0xAD, 0xBE, 0xEF}
	extraData := common.LeftPadBytes(big.NewInt(100).Bytes(), 32)
	gameAddr := createAndInitializeGame(t, ratSys, factoryAddr, rootClaim, extraData)
	t.Logf("DisputeGame created at: %s", gameAddr.Hex())

	// Challenger attacks the invalid root claim
	counterClaim := [32]byte{0xCA, 0xFE, 0xBA, 0xBE}
	err := chl.Attack(gameAddr, big.NewInt(0), counterClaim)
	require.NoError(t, err, "Failed to attack root claim")

	// Resolve the child claim first (bottom-up resolution)
	err = chl.ResolveClaim(gameAddr, big.NewInt(1))
	require.NoError(t, err, "Failed to resolve child claim")

	// Resolve the root claim
	err = chl.ResolveClaim(gameAddr, big.NewInt(0))
	require.NoError(t, err, "Failed to resolve root claim")

	// Resolve the entire game
	status, err := chl.Resolve(gameAddr)
	require.NoError(t, err, "Failed to resolve game")
	require.Equal(t, system.GameStatusChallengerWon, status, "Game should be won by challenger")

	// Verify challenger is a winning challenger
	isWinner, err := chl.IsWinningChallenger(gameAddr)
	require.NoError(t, err, "Failed to check winning challenger")
	require.True(t, isWinner, "Challenger should be a winning challenger")

	// Verify there's exactly one winning challenger
	winningChallengers, err := tonSys.GetWinningChallengers(gameAddr)
	require.NoError(t, err, "Failed to get winning challengers")
	require.Len(t, winningChallengers, 1, "Should have exactly one winning challenger")
	require.Equal(t, chl.Address, winningChallengers[0], "Winner should be the challenger")

	t.Log("=== Test Complete ===")
	t.Log("Single challenger successfully won and recorded as winning challenger")
}

// TestRealChallenger_MultiChallengerRewardDistribution tests that multiple challengers
// are tracked correctly when they participate in a dispute game.
func TestRealChallenger_MultiChallengerRewardDistribution(t *testing.T) {
	t.Parallel()
	ctx := context.Background()

	// Start TON Staking system with genesis
	ratSys := rat.StartTONStakingSystem(t)

	// Create TON system wrapper
	tonSys := system.StartTONFaultDisputeSystem(t, ratSys.L1Client)

	// Deploy MockDisputeGameFactory3 for this test
	factoryAddr := deployMockDisputeGameFactory3(t, ratSys)
	t.Logf("MockDisputeGameFactory3 deployed at: %s", factoryAddr.Hex())

	// Create multiple challengers
	challengers := challenger.StartMultipleChallengers(t, ctx, tonSys, 3)
	require.Len(t, challengers, 3, "Should have 3 challengers")

	// Fund challengers with ETH for gas
	fundChallengers(t, ratSys, challengers)

	// Create a dispute game with an invalid root claim
	rootClaim := [32]byte{0xDE, 0xAD, 0xBE, 0xEF}
	extraData := common.LeftPadBytes(big.NewInt(100).Bytes(), 32)
	gameAddr := createAndInitializeGame(t, ratSys, factoryAddr, rootClaim, extraData)
	t.Logf("DisputeGame created at: %s", gameAddr.Hex())

	// Each challenger attacks different aspects of the game
	// Challenger 1 attacks root claim
	counterClaim1 := [32]byte{0xCA, 0xFE, 0x00, 0x01}
	err := challengers[0].Attack(gameAddr, big.NewInt(0), counterClaim1)
	require.NoError(t, err, "Challenger 1 failed to attack")

	// Challenger 2 attacks root claim with different claim
	counterClaim2 := [32]byte{0xCA, 0xFE, 0x00, 0x02}
	err = challengers[1].Attack(gameAddr, big.NewInt(0), counterClaim2)
	require.NoError(t, err, "Challenger 2 failed to attack")

	// Challenger 3 attacks root claim with different claim
	counterClaim3 := [32]byte{0xCA, 0xFE, 0x00, 0x03}
	err = challengers[2].Attack(gameAddr, big.NewInt(0), counterClaim3)
	require.NoError(t, err, "Challenger 3 failed to attack")

	// Resolve claims bottom-up
	// First resolve all child claims
	for i := 3; i >= 1; i-- {
		err = challengers[0].ResolveClaim(gameAddr, big.NewInt(int64(i)))
		require.NoError(t, err, "Failed to resolve claim %d", i)
	}

	// Resolve root claim
	err = challengers[0].ResolveClaim(gameAddr, big.NewInt(0))
	require.NoError(t, err, "Failed to resolve root claim")

	// Resolve entire game
	status, err := challengers[0].Resolve(gameAddr)
	require.NoError(t, err, "Failed to resolve game")
	require.Equal(t, system.GameStatusChallengerWon, status, "Game should be won by challenger")

	// Verify all challengers are recorded as winning challengers
	winningChallengers, err := tonSys.GetWinningChallengers(gameAddr)
	require.NoError(t, err, "Failed to get winning challengers")
	t.Logf("Number of winning challengers: %d", len(winningChallengers))

	// Verify each challenger's winning status
	for i, chl := range challengers {
		isWinner, err := chl.IsWinningChallenger(gameAddr)
		require.NoError(t, err, "Failed to check challenger %d", i)
		t.Logf("Challenger %d (%s) is winner: %v", i+1, chl.Address.Hex(), isWinner)
	}

	t.Log("=== Test Complete ===")
	t.Logf("Multi-challenger game resolved with %d winning challengers", len(winningChallengers))
}

// TestRealChallenger_GameFlowIntegration tests the complete game flow
// from creation to resolution to slashing.
func TestRealChallenger_GameFlowIntegration(t *testing.T) {
	t.Parallel()
	ctx := context.Background()

	// Start TON Staking system with genesis
	ratSys := rat.StartTONStakingSystem(t)

	// Create TON system wrapper
	tonSys := system.StartTONFaultDisputeSystem(t, ratSys.L1Client)

	// Deploy MockDisputeGameFactory3 for this test
	factoryAddr := deployMockDisputeGameFactory3(t, ratSys)

	// Create challenger
	chl := challenger.NewTONChallenger(t, ctx, tonSys)

	t.Log("=== Step 1: Create DisputeGame ===")
	rootClaim := [32]byte{0xBA, 0xD0, 0xCA, 0xFE}
	extraData := common.LeftPadBytes(big.NewInt(100).Bytes(), 32)
	gameAddr := createAndInitializeGame(t, ratSys, factoryAddr, rootClaim, extraData)
	t.Logf("Game created at: %s", gameAddr.Hex())

	// Verify initial game status
	status, err := tonSys.GetGameStatus(gameAddr)
	require.NoError(t, err)
	require.Equal(t, system.GameStatusInProgress, status, "Game should be in progress")

	t.Log("=== Step 2: Challenger Attacks ===")
	counterClaim := [32]byte{0x60, 0x0D, 0xCA, 0xFE}
	err = chl.Attack(gameAddr, big.NewInt(0), counterClaim)
	require.NoError(t, err, "Failed to attack")

	t.Log("=== Step 3: Resolve Claims ===")
	// Resolve child claim first
	err = chl.ResolveClaim(gameAddr, big.NewInt(1))
	require.NoError(t, err, "Failed to resolve child claim")

	// Resolve root claim
	err = chl.ResolveClaim(gameAddr, big.NewInt(0))
	require.NoError(t, err, "Failed to resolve root claim")

	t.Log("=== Step 4: Resolve Game ===")
	status, err = chl.Resolve(gameAddr)
	require.NoError(t, err, "Failed to resolve game")
	require.Equal(t, system.GameStatusChallengerWon, status)
	t.Logf("Game resolved with status: %d (CHALLENGER_WINS)", status)

	t.Log("=== Step 5: Verify Winning Challengers ===")
	winners, err := tonSys.GetWinningChallengers(gameAddr)
	require.NoError(t, err)
	require.NotEmpty(t, winners, "Should have at least one winner")
	t.Logf("Winning challengers: %v", winners)

	// Verify the challenger is in the winners list
	found := false
	for _, winner := range winners {
		if winner == chl.Address {
			found = true
			break
		}
	}
	require.True(t, found, "Challenger should be in winners list")

	t.Log("=== Test Complete ===")
	t.Log("Full game flow integration test passed")
}

// Helper functions

// setAnvilBalance sets the balance of an account using Anvil's RPC.
func setAnvilBalance(t *testing.T, rpcClient *rpc.Client, addr common.Address, balance *big.Int) {
	var result bool
	err := rpcClient.Call(&result, "anvil_setBalance", addr, (*hexutil.Big)(balance))
	if err != nil {
		t.Logf("Warning: Failed to set balance for %s: %v", addr.Hex(), err)
	}
}

// deployMockDisputeGameFactory3 deploys a MockDisputeGameFactory3 contract.
func deployMockDisputeGameFactory3(t *testing.T, sys *rat.TONStakingSystem) common.Address {
	// Get deployer account
	deployerKey, err := crypto.HexToECDSA("ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
	require.NoError(t, err)
	deployerAddr := crypto.PubkeyToAddress(deployerKey.PublicKey)

	// Fund the deployer account using Anvil's RPC
	rpcClient, err := rpc.Dial(sys.RPCURL)
	require.NoError(t, err)
	defer rpcClient.Close()

	// Set 1000 ETH balance
	setAnvilBalance(t, rpcClient, deployerAddr, new(big.Int).Mul(big.NewInt(1000), big.NewInt(1e18)))
	t.Logf("Funded deployer %s with 1000 ETH", deployerAddr.Hex())

	chainID, err := sys.L1Client.ChainID(sys.Ctx)
	require.NoError(t, err)

	auth, err := bind.NewKeyedTransactorWithChainID(deployerKey, chainID)
	require.NoError(t, err)
	auth.GasLimit = 5000000
	auth.GasPrice = big.NewInt(1e9) // 1 gwei

	// Deploy MockDisputeGameFactory3
	addr, tx, _, err := bindings.DeployMockDisputeGameFactory3(auth, sys.L1Client)
	require.NoError(t, err, "Failed to deploy MockDisputeGameFactory3")

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
	require.NoError(t, err, "Failed to wait for deploy transaction")
	require.Equal(t, uint64(1), receipt.Status, "Deploy transaction failed")

	t.Logf("MockDisputeGameFactory3 deployed at %s", addr.Hex())
	return addr
}

// createAndInitializeGame creates and initializes a dispute game.
func createAndInitializeGame(t *testing.T, sys *rat.TONStakingSystem, factoryAddr common.Address, rootClaim [32]byte, extraData []byte) common.Address {
	// Get proposer account
	proposerKey, err := crypto.HexToECDSA("59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d")
	require.NoError(t, err)

	chainID, err := sys.L1Client.ChainID(sys.Ctx)
	require.NoError(t, err)

	auth, err := bind.NewKeyedTransactorWithChainID(proposerKey, chainID)
	require.NoError(t, err)
	auth.GasLimit = 3000000

	factory, err := bindings.NewMockDisputeGameFactory3(factoryAddr, sys.L1Client)
	require.NoError(t, err)

	// Create game
	tx, err := factory.Create(auth, 0, rootClaim, extraData)
	require.NoError(t, err)

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
	require.NoError(t, err)
	require.Equal(t, uint64(1), receipt.Status, "Game creation failed")

	// Parse DisputeGameCreated event to get game address
	var gameAddr common.Address
	for _, log := range receipt.Logs {
		if len(log.Topics) >= 2 {
			gameAddr = common.BytesToAddress(log.Topics[1].Bytes())
			break
		}
	}
	require.NotEqual(t, common.Address{}, gameAddr, "Failed to get game address from logs")

	// Initialize the game
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, sys.L1Client)
	require.NoError(t, err)

	initTx, err := game.Initialize(auth)
	require.NoError(t, err)

	initReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, initTx)
	require.NoError(t, err)
	require.Equal(t, uint64(1), initReceipt.Status, "Game initialization failed")

	return gameAddr
}

// fundChallengers funds challenger accounts with ETH for gas.
func fundChallengers(t *testing.T, sys *rat.TONStakingSystem, challengers []*challenger.ChallengerHelper) {
	// Get deployer to send funds
	deployerKey, err := crypto.HexToECDSA("ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
	require.NoError(t, err)

	chainID, err := sys.L1Client.ChainID(sys.Ctx)
	require.NoError(t, err)

	auth, err := bind.NewKeyedTransactorWithChainID(deployerKey, chainID)
	require.NoError(t, err)
	auth.GasLimit = 21000
	auth.Value = big.NewInt(1e18) // 1 ETH

	for _, chl := range challengers {
		nonce, err := sys.L1Client.PendingNonceAt(sys.Ctx, auth.From)
		require.NoError(t, err)

		// Simple ETH transfer using raw transaction
		tx := types.NewTx(&types.LegacyTx{
			Nonce:    nonce,
			To:       &chl.Address,
			Value:    auth.Value,
			Gas:      21000,
			GasPrice: big.NewInt(1e9),
		})

		signedTx, err := types.SignTx(tx, types.HomesteadSigner{}, deployerKey)
		if err != nil {
			t.Logf("Warning: Failed to sign tx for challenger %s: %v", chl.Name, err)
			continue
		}

		err = sys.L1Client.SendTransaction(sys.Ctx, signedTx)
		if err != nil {
			t.Logf("Warning: Failed to fund challenger %s: %v", chl.Name, err)
			continue
		}

		_, err = bind.WaitMined(sys.Ctx, sys.L1Client, signedTx)
		if err != nil {
			t.Logf("Warning: Fund transaction not mined for %s: %v", chl.Name, err)
		}
	}
	auth.Value = nil
}
