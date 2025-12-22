package rat

import (
	"context"
	"crypto/ecdsa"
	"math/big"
	"strings"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
)

// ValidatorRegistration represents validator registration data
type ValidatorRegistration struct {
	DepositedAmount *big.Int
	TotalBondForRAT *big.Int
	ValidatorIndex  uint32
	IsActive        bool
}

// AttentionTest represents an attention test data
type AttentionTest struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}

// AttentionTestStatus represents the status of an attention test
type AttentionTestStatus uint8

const (
	AttentionTestStatusPending AttentionTestStatus = iota
	AttentionTestStatusResponded
	AttentionTestStatusSlashed
	AttentionTestStatusExpired
)

// RATHelper provides helper functions for RAT E2E tests
type RATHelper struct {
	t        *testing.T
	client   *ethclient.Client
	address  common.Address
	contract *bindings.RAT
}

// NewRATHelper creates a new RAT helper instance
func NewRATHelper(t *testing.T, client *ethclient.Client, address common.Address) *RATHelper {
	contract, err := bindings.NewRAT(address, client)
	if err != nil {
		t.Fatalf("Failed to create RAT contract binding: %v", err)
	}

	return &RATHelper{
		t:        t,
		client:   client,
		address:  address,
		contract: contract,
	}
}

// Address returns the RAT contract address
func (h *RATHelper) Address() common.Address {
	return h.address
}

// Contract returns the underlying RAT contract binding
func (h *RATHelper) Contract() *bindings.RAT {
	return h.contract
}

// GetMinimumCollateral returns the minimum collateral required for validators
func (h *RATHelper) GetMinimumCollateral(ctx context.Context) *big.Int {
	opts := &bind.CallOpts{Context: ctx}
	result, err := h.contract.GetMinimumCollateral(opts)
	if err != nil {
		h.t.Logf("Warning: GetMinimumCollateral failed: %v, returning default", err)
		return MulRAY(200) // Default D_min = 200 WTON
	}
	return result
}

// GetSlashingPenalty returns the slashing penalty amount
func (h *RATHelper) GetSlashingPenalty(ctx context.Context) *big.Int {
	opts := &bind.CallOpts{Context: ctx}
	result, err := h.contract.SlashingPenalty(opts)
	if err != nil {
		h.t.Logf("Warning: SlashingPenalty failed: %v, returning default", err)
		return MulRAY(100) // Default C_off = 100 WTON
	}
	return result
}

// GetValidatorBuffer returns the validator buffer amount
func (h *RATHelper) GetValidatorBuffer(ctx context.Context) *big.Int {
	opts := &bind.CallOpts{Context: ctx}
	result, err := h.contract.ValidatorBuffer(opts)
	if err != nil {
		h.t.Logf("Warning: ValidatorBuffer failed: %v, returning default", err)
		return MulRAY(100) // Default Δ_validator = 100 WTON
	}
	return result
}

// GetValidatorRegistration returns the validator registration data
func (h *RATHelper) GetValidatorRegistration(ctx context.Context, systemConfig, validator common.Address) *ValidatorRegistration {
	opts := &bind.CallOpts{Context: ctx}
	result, err := h.contract.GetValidatorRegistration(opts, validator, systemConfig)
	if err != nil {
		h.t.Logf("Warning: GetValidatorRegistration failed: %v, returning empty", err)
		return &ValidatorRegistration{
			DepositedAmount: big.NewInt(0),
			TotalBondForRAT: big.NewInt(0),
			ValidatorIndex:  0,
			IsActive:        false,
		}
	}
	return &ValidatorRegistration{
		DepositedAmount: result.DepositedAmount,
		TotalBondForRAT: result.TotalBondForRAT,
		ValidatorIndex:  result.ValidatorIndex,
		IsActive:        result.IsActive,
	}
}

// GetAttentionTest returns the attention test data by test ID
func (h *RATHelper) GetAttentionTest(ctx context.Context, testId [32]byte) *AttentionTest {
	opts := &bind.CallOpts{Context: ctx}
	result, err := h.contract.GetAttentionTest(opts, testId)
	if err != nil {
		h.t.Logf("Warning: GetAttentionTest failed: %v, returning empty", err)
		return &AttentionTest{
			ValidatorAddress: common.Address{},
			SystemConfig:     common.Address{},
			BatchIndex:       0,
			BatchHash:        [32]byte{},
			BondAmount:       big.NewInt(0),
			CreatedAt:        big.NewInt(0),
			Deadline:         big.NewInt(0),
			Status:           0,
		}
	}
	return &AttentionTest{
		ValidatorAddress: result.ValidatorAddress,
		SystemConfig:     result.SystemConfig,
		BatchIndex:       result.BatchIndex,
		BatchHash:        result.BatchHash,
		BondAmount:       result.BondAmount,
		CreatedAt:        result.CreatedAt,
		Deadline:         result.Deadline,
		Status:           result.Status,
	}
}

// GetTestIdByGame returns the test ID for a given game address
func (h *RATHelper) GetTestIdByGame(ctx context.Context, gameAddress common.Address) [32]byte {
	opts := &bind.CallOpts{Context: ctx}
	testId, err := h.contract.GameToTestId(opts, gameAddress)
	if err != nil {
		h.t.Logf("Warning: GameToTestId failed: %v, returning zero", err)
		return [32]byte{}
	}
	return testId
}

// GetValidatorCount returns the total validator count for a system config
func (h *RATHelper) GetValidatorCount(ctx context.Context, systemConfig common.Address) *big.Int {
	opts := &bind.CallOpts{Context: ctx}
	count, err := h.contract.GetValidatorCount(opts, systemConfig)
	if err != nil {
		h.t.Logf("Warning: GetValidatorCount failed: %v, returning 0", err)
		return big.NewInt(0)
	}
	return count
}

// GetActiveValidatorCount returns the active validator count for a system config
func (h *RATHelper) GetActiveValidatorCount(ctx context.Context, systemConfig common.Address) *big.Int {
	opts := &bind.CallOpts{Context: ctx}
	count, err := h.contract.GetActiveValidatorCount(opts, systemConfig)
	if err != nil {
		h.t.Logf("Warning: GetActiveValidatorCount failed: %v, returning 0", err)
		return big.NewInt(0)
	}
	return count
}

// GetL2Validators returns the list of validators for a system config
func (h *RATHelper) GetL2Validators(ctx context.Context, systemConfig common.Address) []common.Address {
	opts := &bind.CallOpts{Context: ctx}
	validators, err := h.contract.GetL2Validators(opts, systemConfig)
	if err != nil {
		h.t.Logf("Warning: GetL2Validators failed: %v, returning empty", err)
		return []common.Address{}
	}
	return validators
}

// IsValidatorActive returns whether a validator is active for a system config
func (h *RATHelper) IsValidatorActive(ctx context.Context, validator, systemConfig common.Address) bool {
	opts := &bind.CallOpts{Context: ctx}
	active, err := h.contract.IsValidatorActive(opts, validator, systemConfig)
	if err != nil {
		h.t.Logf("Warning: IsValidatorActive failed: %v, returning false", err)
		return false
	}
	return active
}

// GetValidatorDeposit returns the validator deposit amount
func (h *RATHelper) GetValidatorDeposit(ctx context.Context, validator, systemConfig common.Address) *big.Int {
	opts := &bind.CallOpts{Context: ctx}
	deposit, err := h.contract.GetValidatorDeposit(opts, validator, systemConfig)
	if err != nil {
		h.t.Logf("Warning: GetValidatorDeposit failed: %v, returning 0", err)
		return big.NewInt(0)
	}
	return deposit
}

// GetWTON returns the WTON address from the RAT contract
func (h *RATHelper) GetWTON(ctx context.Context) common.Address {
	opts := &bind.CallOpts{Context: ctx}
	wton, err := h.contract.Wton(opts)
	if err != nil {
		h.t.Logf("Warning: GetWTON failed: %v", err)
		return common.Address{}
	}
	return wton
}

// GetTON returns the TON address from the RAT contract
func (h *RATHelper) GetTON(ctx context.Context) common.Address {
	opts := &bind.CallOpts{Context: ctx}
	ton, err := h.contract.Ton(opts)
	if err != nil {
		h.t.Logf("Warning: GetTON failed: %v", err)
		return common.Address{}
	}
	return ton
}

// ApproveTON approves TON spending for the RAT contract
func (h *RATHelper) ApproveTON(ctx context.Context, privateKey *ecdsa.PrivateKey, chainID *big.Int, amount *big.Int) (*types.Transaction, error) {
	tonAddr := h.GetTON(ctx)
	if tonAddr == (common.Address{}) {
		return nil, nil
	}

	// Create ERC20 approve call
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return nil, err
	}
	opts.Context = ctx

	// ERC20 approve function signature: approve(address,uint256)
	erc20ABI := `[{"inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]`

	parsed, err := abi.JSON(strings.NewReader(erc20ABI))
	if err != nil {
		return nil, err
	}

	data, err := parsed.Pack("approve", h.address, amount)
	if err != nil {
		return nil, err
	}

	nonce, err := h.client.PendingNonceAt(ctx, opts.From)
	if err != nil {
		return nil, err
	}

	gasPrice, err := h.client.SuggestGasPrice(ctx)
	if err != nil {
		return nil, err
	}

	tx := types.NewTransaction(nonce, tonAddr, big.NewInt(0), 100000, gasPrice, data)
	signedTx, err := opts.Signer(opts.From, tx)
	if err != nil {
		return nil, err
	}

	err = h.client.SendTransaction(ctx, signedTx)
	if err != nil {
		return nil, err
	}

	return signedTx, nil
}

// RegisterValidator registers a new validator with the given deposit
// Note: Call ApproveWTON first to approve WTON spending
func (h *RATHelper) RegisterValidator(ctx context.Context, privateKey *ecdsa.PrivateKey, chainID *big.Int, systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return nil, err
	}
	opts.Context = ctx
	return h.contract.RegisterValidator(opts, systemConfig, depositAmount)
}

// RegisterValidatorWithApproval uses TON.approveAndCall to register a validator in one call
// Note: RAT uses TON (not WTON) for validator deposits
// The RAT contract has onApprove callback that handles the deposit
func (h *RATHelper) RegisterValidatorWithApproval(ctx context.Context, privateKey *ecdsa.PrivateKey, chainID *big.Int, systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	tonAddr := h.GetTON(ctx)
	if tonAddr == (common.Address{}) {
		return nil, nil
	}

	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return nil, err
	}
	opts.Context = ctx

	// TON.approveAndCall(address spender, uint256 amount, bytes data)
	// data = abi.encode(systemConfig) for RAT.onApprove
	approveAndCallABI := `[{"inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"},{"name":"data","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]`

	parsed, err := abi.JSON(strings.NewReader(approveAndCallABI))
	if err != nil {
		return nil, err
	}

	// Encode systemConfig as 32 bytes for RAT.onApprove
	data := common.LeftPadBytes(systemConfig.Bytes(), 32)

	callData, err := parsed.Pack("approveAndCall", h.address, depositAmount, data)
	if err != nil {
		return nil, err
	}

	nonce, err := h.client.PendingNonceAt(ctx, opts.From)
	if err != nil {
		return nil, err
	}

	gasPrice, err := h.client.SuggestGasPrice(ctx)
	if err != nil {
		return nil, err
	}

	tx := types.NewTransaction(nonce, tonAddr, big.NewInt(0), 300000, gasPrice, callData)
	signedTx, err := opts.Signer(opts.From, tx)
	if err != nil {
		return nil, err
	}

	err = h.client.SendTransaction(ctx, signedTx)
	if err != nil {
		return nil, err
	}

	return signedTx, nil
}

// DeactivateValidator deactivates a validator
func (h *RATHelper) DeactivateValidator(ctx context.Context, privateKey *ecdsa.PrivateKey, chainID *big.Int, systemConfig common.Address) (*types.Transaction, error) {
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return nil, err
	}
	opts.Context = ctx
	return h.contract.DeactivateValidator(opts, systemConfig)
}

// AddDeposit adds deposit to an existing validator
func (h *RATHelper) AddDeposit(ctx context.Context, privateKey *ecdsa.PrivateKey, chainID *big.Int, systemConfig common.Address, amount *big.Int) (*types.Transaction, error) {
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return nil, err
	}
	opts.Context = ctx
	return h.contract.AddDeposit(opts, systemConfig, amount)
}

// SubmitEvidence submits evidence for an attention test
func (h *RATHelper) SubmitEvidence(ctx context.Context, privateKey *ecdsa.PrivateKey, chainID *big.Int, systemConfig common.Address, batchIndex uint32, evidence []byte) (*types.Transaction, error) {
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return nil, err
	}
	opts.Context = ctx
	return h.contract.SubmitEvidence(opts, systemConfig, batchIndex, evidence)
}

// WaitForAttentionTest waits for an attention test to be created for a game
func (h *RATHelper) WaitForAttentionTest(ctx context.Context, gameAddress common.Address, timeout time.Duration) *AttentionTest {
	deadline := time.Now().Add(timeout)

	for time.Now().Before(deadline) {
		testId := h.GetTestIdByGame(ctx, gameAddress)
		if testId != [32]byte{} {
			return h.GetAttentionTest(ctx, testId)
		}
		time.Sleep(100 * time.Millisecond)
	}

	h.t.Fatalf("Timeout waiting for attention test for game %s", gameAddress.Hex())
	return nil
}

// WaitForReceipt waits for a transaction receipt
func (h *RATHelper) WaitForReceipt(ctx context.Context, tx *types.Transaction, timeout time.Duration) *types.Receipt {
	deadline := time.Now().Add(timeout)

	for time.Now().Before(deadline) {
		receipt, err := h.client.TransactionReceipt(ctx, tx.Hash())
		if err == nil {
			return receipt
		}
		time.Sleep(100 * time.Millisecond)
	}

	h.t.Fatalf("Timeout waiting for transaction receipt %s", tx.Hash().Hex())
	return nil
}

// TransactOpts creates transaction options with the given private key
func TransactOpts(ctx context.Context, client *ethclient.Client, privateKey *ecdsa.PrivateKey, chainID *big.Int) (*bind.TransactOpts, error) {
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return nil, err
	}
	opts.Context = ctx
	return opts, nil
}

// RAY returns 1e27 (RAY unit used in TON Staking)
func RAY() *big.Int {
	ray := new(big.Int)
	ray.SetString("1000000000000000000000000000", 10)
	return ray
}

// MulRAY multiplies a value by RAY
func MulRAY(value int64) *big.Int {
	result := big.NewInt(value)
	return result.Mul(result, RAY())
}

// DivRAY divides a value by RAY
func DivRAY(value *big.Int) *big.Int {
	return new(big.Int).Div(value, RAY())
}

// ToWTON converts a human-readable amount to WTON (RAY format)
func ToWTON(amount int64) *big.Int {
	return MulRAY(amount)
}

// FromWTON converts WTON (RAY format) to human-readable amount
func FromWTON(amount *big.Int) *big.Int {
	return DivRAY(amount)
}

// Constants
const DefaultTimeout = 30 * time.Second

// RequireNoError is a helper to check for errors
func RequireNoError(t *testing.T, err error, msg string) {
	require.NoError(t, err, msg)
}
