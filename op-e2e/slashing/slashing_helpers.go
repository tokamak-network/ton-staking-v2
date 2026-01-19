package slashing

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// SlashingContracts holds all slashing-related contract instances
type SlashingContracts struct {
	Layer2ManagerSlashing  *bindings.Layer2ManagerSlashing
	DepositManagerSlashing *bindings.DepositManagerSlashing
	SeigManagerSlashing    *bindings.SeigManagerSlashing
	DepositManager         *bindings.DepositManager
	Layer2ManagerV11       *bindings.Layer2ManagerV11
}

// connectSlashingContracts connects to all slashing-related contracts
func connectSlashingContracts(t *testing.T, sys *rat.TONStakingSystem) *SlashingContracts {
	// Layer2Manager_Slashing
	layer2ManagerSlashing, err := bindings.NewLayer2ManagerSlashing(
		sys.Addresses.Layer2ManagerProxy,
		sys.L1Client,
	)
	require.NoError(t, err, "Failed to connect to Layer2Manager_Slashing")

	// DepositManager_Slashing
	depositManagerSlashing, err := bindings.NewDepositManagerSlashing(
		sys.Addresses.DepositManagerProxy,
		sys.L1Client,
	)
	require.NoError(t, err, "Failed to connect to DepositManager_Slashing")

	// SeigManager_Slashing
	seigManagerSlashing, err := bindings.NewSeigManagerSlashing(
		sys.Addresses.SeigManagerProxy,
		sys.L1Client,
	)
	require.NoError(t, err, "Failed to connect to SeigManager_Slashing")

	// DepositManager
	depositManager, err := bindings.NewDepositManager(
		sys.Addresses.DepositManagerProxy,
		sys.L1Client,
	)
	require.NoError(t, err, "Failed to connect to DepositManager")

	// Layer2ManagerV11
	layer2ManagerV11, err := bindings.NewLayer2ManagerV11(
		sys.Addresses.Layer2ManagerProxy,
		sys.L1Client,
	)
	require.NoError(t, err, "Failed to connect to Layer2ManagerV11")

	return &SlashingContracts{
		Layer2ManagerSlashing:  layer2ManagerSlashing,
		DepositManagerSlashing: depositManagerSlashing,
		SeigManagerSlashing:    seigManagerSlashing,
		DepositManager:         depositManager,
		Layer2ManagerV11:       layer2ManagerV11,
	}
}

// registerOperatorWithCandidateAddOn registers an operator with CandidateAddOn
// Returns: candidateAddOn address, operatorManager address
func registerOperatorWithCandidateAddOn(
	t *testing.T,
	sys *rat.TONStakingSystem,
	contracts *SlashingContracts,
	operatorAuth *bind.TransactOpts,
	stakeAmount *big.Int,
) (common.Address, common.Address) {
	// Use MockSystemConfig (deployed in Genesis for E2E tests)
	// This provides unsafeBlockSigner, optimismPortal, etc.
	// If MockSystemConfig is not present (zero address), fallback to SystemConfig
	rollupConfig := sys.Addresses.MockSystemConfig
	if rollupConfig == (common.Address{}) {
		rollupConfig = sys.Addresses.SystemConfig
		t.Logf("Using Real SystemConfig: %s (Mock not found)", rollupConfig.Hex())
	} else {
		t.Logf("Using MockSystemConfig: %s (pre-registered in Genesis)", rollupConfig.Hex())
	}

	// Step 1: Approve TON to Layer2Manager
	ton, err := bindings.NewERC20(sys.Addresses.TON, sys.L1Client)
	require.NoError(t, err, "Failed to connect to TON")

	approveTx, err := ton.Approve(operatorAuth, sys.Addresses.Layer2ManagerProxy, stakeAmount)
	require.NoError(t, err, "Failed to approve TON")

	approveReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err, "Failed to wait for TON approval")
	require.Equal(t, types.ReceiptStatusSuccessful, approveReceipt.Status, "TON approval failed")

	t.Logf("✓ Approved %s TON to Layer2Manager", stakeAmount.String())

	// 1. Register CandidateAddOn via Layer2Manager
	memo := "Test Operator for Slashing"
	// rollupConfig already defined above
	flagTon := true // Use TON (not WTON) - matches Forge test!

	// Ensure high gas limit for complex registration (matches Forge's ~5.2M usage)
	operatorAuth.GasLimit = 10000000

	tx, err := contracts.Layer2ManagerV11.RegisterCandidateAddOn(
		operatorAuth,
		rollupConfig,
		stakeAmount,
		flagTon,
		memo,
	)
	require.NoError(t, err, "Failed to register CandidateAddOn")

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
	require.NoError(t, err, "Failed to wait for CandidateAddOn registration")
	require.Equal(t, types.ReceiptStatusSuccessful, receipt.Status, "CandidateAddOn registration failed")

	// Parse addresses from logs
	var candidateAddOn common.Address
	var operatorManager common.Address

	for _, l := range receipt.Logs {
		// Event signature: RegisteredCandidateAddOn(address,uint256,string,address,address)
		event, err := contracts.Layer2ManagerV11.ParseRegisteredCandidateAddOn(*l)
		if err == nil {
			candidateAddOn = event.CandidateAddOn
			operatorManager = event.Operator
			break
		}
	}

	require.NotEqual(t, (common.Address{}), candidateAddOn, "CandidateAddOn address not found in logs")
	require.NotEqual(t, (common.Address{}), operatorManager, "OperatorManager address not found in logs")

	t.Logf("✓ CandidateAddOn registered: %s", candidateAddOn.Hex())
	t.Logf("✓ OperatorManager: %s", operatorManager.Hex())

	// 2. Deposit stake via DepositManager
	// We need to approve WTON to DepositManager first
	wtonERC20, err := bindings.NewERC20(sys.Addresses.WTON, sys.L1Client)
	require.NoError(t, err, "Failed to connect to WTON as ERC20")

	// Mint some WTON or convert TON if needed - but Genesis already minted WTON to test accounts!
	approveWtonTx, err := wtonERC20.Approve(operatorAuth, sys.Addresses.DepositManagerProxy, stakeAmount)
	require.NoError(t, err, "Failed to approve WTON")
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, approveWtonTx)
	require.NoError(t, err, "Wait for WTON approval failed")
	t.Logf("✓ Approved %s WTON to DepositManager", stakeAmount.String())

	tx, err = contracts.DepositManager.Deposit(
		operatorAuth,
		candidateAddOn,
		stakeAmount,
	)
	require.NoError(t, err, "Failed to deposit stake")

	receipt, err = bind.WaitMined(sys.Ctx, sys.L1Client, tx)
	require.NoError(t, err, "Failed to wait for deposit")
	require.Equal(t, types.ReceiptStatusSuccessful, receipt.Status, "Deposit failed")

	t.Logf("✓ Deposited %s WTON", stakeAmount.String())

	return candidateAddOn, operatorManager
}

// executeSlashing executes slashing for a given operator
func executeSlashing(
	t *testing.T,
	sys *rat.TONStakingSystem,
	contracts *SlashingContracts,
	challengerAuth *bind.TransactOpts,
	operatorManager common.Address,
	gameAddress common.Address,
	rootClaim [32]byte,
	extraData []byte,
) *types.Receipt {
	// GameType is 0 for FaultDisputeGame
	gameType := uint32(0)

	tx, err := contracts.Layer2ManagerSlashing.SlashingCandidate(
		challengerAuth,
		operatorManager,
		gameType,
		rootClaim,
		extraData,
		gameAddress,
	)
	require.NoError(t, err, "Failed to execute slashing")

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
	require.NoError(t, err, "Failed to wait for slashing")
	require.Equal(t, types.ReceiptStatusSuccessful, receipt.Status, "Slashing failed")

	t.Logf("✓ Slashing executed for OperatorManager: %s", operatorManager.Hex())

	return receipt
}

// getStakeBalance returns the stake balance for an account in a candidateAddOn
func getStakeBalance(
	t *testing.T,
	sys *rat.TONStakingSystem,
	contracts *SlashingContracts,
	candidateAddOn common.Address,
	account common.Address,
) *big.Int {
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	balance, err := contracts.DepositManager.AccStaked(
		callOpts,
		candidateAddOn,
		account,
	)
	require.NoError(t, err, "Failed to get stake balance")

	return balance
}

// getWTONBalance returns the WTON balance for an account
func getWTONBalance(
	t *testing.T,
	sys *rat.TONStakingSystem,
	account common.Address,
) *big.Int {
	wton, err := bindings.NewERC20(
		sys.Addresses.WTON,
		sys.L1Client,
	)
	require.NoError(t, err, "Failed to connect to WTON")

	callOpts := &bind.CallOpts{Context: sys.Ctx}
	balance, err := wton.BalanceOf(callOpts, account)
	require.NoError(t, err, "Failed to get WTON balance")

	return balance
}

// getSlashingRewardRate returns the current slashing reward rate
func getSlashingRewardRate(
	t *testing.T,
	sys *rat.TONStakingSystem,
	contracts *SlashingContracts,
) *big.Int {
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	rate, err := contracts.DepositManagerSlashing.SlashingRewardRate(callOpts)
	require.NoError(t, err, "Failed to get slashing reward rate")

	return rate
}

// setSlashingRewardRate sets the slashing reward rate (only deployer can call)
func setSlashingRewardRate(
	t *testing.T,
	sys *rat.TONStakingSystem,
	contracts *SlashingContracts,
	deployerAuth *bind.TransactOpts,
	rate *big.Int,
) {
	tx, err := contracts.DepositManagerSlashing.SetSlashingRewardRate(
		deployerAuth,
		rate,
	)
	require.NoError(t, err, "Failed to set slashing reward rate")

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
	require.NoError(t, err, "Failed to wait for rate setting")
	require.Equal(t, types.ReceiptStatusSuccessful, receipt.Status, "Setting rate failed")

	t.Logf("✓ Slashing reward rate set to: %s", rate.String())
}
