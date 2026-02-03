// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package bindings

import (
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
)

// RATFastWithdrawalLibFastWithdrawalInput is an auto generated low-level Go binding around an user-defined struct.
type RATFastWithdrawalLibFastWithdrawalInput struct {
	WithdrawalHash  [32]byte
	SystemConfig    common.Address
	StateRoot       [32]byte
	ValidatorBitmap *big.Int
	LeafA           [32]byte
	LeafB           [32]byte
	ProofsA         [][]byte
	ProofsB         [][]byte
}

// TypesWithdrawalTransaction is an auto generated low-level Go binding around an user-defined struct.
type TypesWithdrawalTransaction struct {
	Nonce    *big.Int
	Sender   common.Address
	Target   common.Address
	Value    *big.Int
	GasLimit *big.Int
	Data     []byte
}

// RATFastWithdrawalABI is the input ABI used to generate the binding from.
const RATFastWithdrawalABI = "[{\"type\":\"receive\",\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"accumulatedSlashings\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"activeTestCount\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"aggregatorFeeRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"aliveImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"attentionCost\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"attentionTests\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"validatorAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"gameAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"bondAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"authorizedTrigger\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"batchToTestId\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"challengeGameDuration\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"evidenceSubmissionPeriod\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"factoryByGame\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"fastWithdrawalEnabled\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"gameToTestId\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getActiveValidatorsWithBLS\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"validators\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"blsKeys\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"validBLSCount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getBatchValidatorBLSPublicKeys\",\"inputs\":[{\"name\":\"validators\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"blsPublicKeys\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorBLSPubKey\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"hasValidatorBLSKey\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isOwner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1BridgeRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"latestDeadlineTest\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2Manager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxValidatorsPerL2\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minValidatorsForFastWithdrawal\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minimumThreshold\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseProxy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"processedWithdrawals\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxyImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ratTriggerProbability\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"registerBLSPublicKey\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"blsPublicKey\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"blsProofOfPossession\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerValidatorWithBLS\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"blsPublicKey\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"blsProofOfPossession\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"relaxedValidatorCheck\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"removeAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safetyBuffer\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"seigManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"selectorImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setAggregatorFeeRate\",\"inputs\":[{\"name\":\"rate\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMinValidatorsForFastWithdrawal\",\"inputs\":[{\"name\":\"minValidators\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slashingPenalty\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferAdmin\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"treasury\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorBuffer\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorIndexes\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorRegistrations\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"lockedForRAT\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"pendingRewards\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"latestTestDeadline\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"validatorIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"isActive\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"blsPublicKey\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorReward\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorSystemConfigs\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"verifyAndExecuteFastWithdrawal\",\"inputs\":[{\"name\":\"_tx\",\"type\":\"tuple\",\"internalType\":\"structTypes.WithdrawalTransaction\",\"components\":[{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"input\",\"type\":\"tuple\",\"internalType\":\"structRATFastWithdrawalLib.FastWithdrawalInput\",\"components\":[{\"name\":\"withdrawalHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"stateRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"validatorBitmap\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"leafA\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"leafB\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"proofsA\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"proofsB\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}]},{\"name\":\"_aggregatedSignature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"wton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"AggregatorFeeRateUpdated\",\"inputs\":[{\"name\":\"newRate\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BLSPublicKeyRegistered\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"blsPublicKey\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BLSPublicKeyUpdated\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldKey\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"},{\"name\":\"newKey\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FastWithdrawalExecuted\",\"inputs\":[{\"name\":\"withdrawalHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"aggregator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinValidatorsForFastWithdrawalUpdated\",\"inputs\":[{\"name\":\"newMinValidators\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRegistered\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"collateral\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"index\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false}]"

// RATFastWithdrawal is an auto generated Go binding around an Ethereum contract.
type RATFastWithdrawal struct {
	RATFastWithdrawalCaller     // Read-only binding to the contract
	RATFastWithdrawalTransactor // Write-only binding to the contract
	RATFastWithdrawalFilterer   // Log filterer for contract events
}

// RATFastWithdrawalCaller is an auto generated read-only Go binding around an Ethereum contract.
type RATFastWithdrawalCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RATFastWithdrawalTransactor is an auto generated write-only Go binding around an Ethereum contract.
type RATFastWithdrawalTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RATFastWithdrawalFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type RATFastWithdrawalFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RATFastWithdrawalSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type RATFastWithdrawalSession struct {
	Contract     *RATFastWithdrawal // Generic contract binding to set the session for
	CallOpts     bind.CallOpts      // Call options to use throughout this session
	TransactOpts bind.TransactOpts  // Transaction auth options to use throughout this session
}

// RATFastWithdrawalCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type RATFastWithdrawalCallerSession struct {
	Contract *RATFastWithdrawalCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts            // Call options to use throughout this session
}

// RATFastWithdrawalTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type RATFastWithdrawalTransactorSession struct {
	Contract     *RATFastWithdrawalTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts            // Transaction auth options to use throughout this session
}

// RATFastWithdrawalRaw is an auto generated low-level Go binding around an Ethereum contract.
type RATFastWithdrawalRaw struct {
	Contract *RATFastWithdrawal // Generic contract binding to access the raw methods on
}

// RATFastWithdrawalCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type RATFastWithdrawalCallerRaw struct {
	Contract *RATFastWithdrawalCaller // Generic read-only contract binding to access the raw methods on
}

// RATFastWithdrawalTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type RATFastWithdrawalTransactorRaw struct {
	Contract *RATFastWithdrawalTransactor // Generic write-only contract binding to access the raw methods on
}

// NewRATFastWithdrawal creates a new instance of RATFastWithdrawal, bound to a specific deployed contract.
func NewRATFastWithdrawal(address common.Address, backend bind.ContractBackend) (*RATFastWithdrawal, error) {
	contract, err := bindRATFastWithdrawal(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawal{RATFastWithdrawalCaller: RATFastWithdrawalCaller{contract: contract}, RATFastWithdrawalTransactor: RATFastWithdrawalTransactor{contract: contract}, RATFastWithdrawalFilterer: RATFastWithdrawalFilterer{contract: contract}}, nil
}

// NewRATFastWithdrawalCaller creates a new read-only instance of RATFastWithdrawal, bound to a specific deployed contract.
func NewRATFastWithdrawalCaller(address common.Address, caller bind.ContractCaller) (*RATFastWithdrawalCaller, error) {
	contract, err := bindRATFastWithdrawal(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalCaller{contract: contract}, nil
}

// NewRATFastWithdrawalTransactor creates a new write-only instance of RATFastWithdrawal, bound to a specific deployed contract.
func NewRATFastWithdrawalTransactor(address common.Address, transactor bind.ContractTransactor) (*RATFastWithdrawalTransactor, error) {
	contract, err := bindRATFastWithdrawal(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalTransactor{contract: contract}, nil
}

// NewRATFastWithdrawalFilterer creates a new log filterer instance of RATFastWithdrawal, bound to a specific deployed contract.
func NewRATFastWithdrawalFilterer(address common.Address, filterer bind.ContractFilterer) (*RATFastWithdrawalFilterer, error) {
	contract, err := bindRATFastWithdrawal(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalFilterer{contract: contract}, nil
}

// bindRATFastWithdrawal binds a generic wrapper to an already deployed contract.
func bindRATFastWithdrawal(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(RATFastWithdrawalABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RATFastWithdrawal *RATFastWithdrawalRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RATFastWithdrawal.Contract.RATFastWithdrawalCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RATFastWithdrawal *RATFastWithdrawalRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RATFastWithdrawalTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RATFastWithdrawal *RATFastWithdrawalRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RATFastWithdrawalTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RATFastWithdrawal *RATFastWithdrawalCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RATFastWithdrawal.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RATFastWithdrawal *RATFastWithdrawalTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RATFastWithdrawal *RATFastWithdrawalTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _RATFastWithdrawal.Contract.DEFAULTADMINROLE(&_RATFastWithdrawal.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _RATFastWithdrawal.Contract.DEFAULTADMINROLE(&_RATFastWithdrawal.CallOpts)
}

// AccumulatedSlashings is a free data retrieval call binding the contract method 0xcd156819.
//
// Solidity: function accumulatedSlashings() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) AccumulatedSlashings(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "accumulatedSlashings")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AccumulatedSlashings is a free data retrieval call binding the contract method 0xcd156819.
//
// Solidity: function accumulatedSlashings() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) AccumulatedSlashings() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.AccumulatedSlashings(&_RATFastWithdrawal.CallOpts)
}

// AccumulatedSlashings is a free data retrieval call binding the contract method 0xcd156819.
//
// Solidity: function accumulatedSlashings() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) AccumulatedSlashings() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.AccumulatedSlashings(&_RATFastWithdrawal.CallOpts)
}

// ActiveTestCount is a free data retrieval call binding the contract method 0xcdf7cf13.
//
// Solidity: function activeTestCount(address ) view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) ActiveTestCount(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "activeTestCount", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ActiveTestCount is a free data retrieval call binding the contract method 0xcdf7cf13.
//
// Solidity: function activeTestCount(address ) view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) ActiveTestCount(arg0 common.Address) (*big.Int, error) {
	return _RATFastWithdrawal.Contract.ActiveTestCount(&_RATFastWithdrawal.CallOpts, arg0)
}

// ActiveTestCount is a free data retrieval call binding the contract method 0xcdf7cf13.
//
// Solidity: function activeTestCount(address ) view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) ActiveTestCount(arg0 common.Address) (*big.Int, error) {
	return _RATFastWithdrawal.Contract.ActiveTestCount(&_RATFastWithdrawal.CallOpts, arg0)
}

// AggregatorFeeRate is a free data retrieval call binding the contract method 0xf7ab329f.
//
// Solidity: function aggregatorFeeRate() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) AggregatorFeeRate(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "aggregatorFeeRate")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AggregatorFeeRate is a free data retrieval call binding the contract method 0xf7ab329f.
//
// Solidity: function aggregatorFeeRate() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) AggregatorFeeRate() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.AggregatorFeeRate(&_RATFastWithdrawal.CallOpts)
}

// AggregatorFeeRate is a free data retrieval call binding the contract method 0xf7ab329f.
//
// Solidity: function aggregatorFeeRate() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) AggregatorFeeRate() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.AggregatorFeeRate(&_RATFastWithdrawal.CallOpts)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) AliveImplementation(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "aliveImplementation", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _RATFastWithdrawal.Contract.AliveImplementation(&_RATFastWithdrawal.CallOpts, arg0)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _RATFastWithdrawal.Contract.AliveImplementation(&_RATFastWithdrawal.CallOpts, arg0)
}

// AttentionCost is a free data retrieval call binding the contract method 0x2c9e3798.
//
// Solidity: function attentionCost() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) AttentionCost(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "attentionCost")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AttentionCost is a free data retrieval call binding the contract method 0x2c9e3798.
//
// Solidity: function attentionCost() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) AttentionCost() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.AttentionCost(&_RATFastWithdrawal.CallOpts)
}

// AttentionCost is a free data retrieval call binding the contract method 0x2c9e3798.
//
// Solidity: function attentionCost() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) AttentionCost() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.AttentionCost(&_RATFastWithdrawal.CallOpts)
}

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
//
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, address gameAddress, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) AttentionTests(opts *bind.CallOpts, arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	GameAddress      common.Address
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "attentionTests", arg0)

	outstruct := new(struct {
		ValidatorAddress common.Address
		SystemConfig     common.Address
		BatchIndex       uint32
		GameAddress      common.Address
		BatchHash        [32]byte
		BondAmount       *big.Int
		CreatedAt        *big.Int
		Deadline         *big.Int
		Status           uint8
	})

	outstruct.ValidatorAddress = out[0].(common.Address)
	outstruct.SystemConfig = out[1].(common.Address)
	outstruct.BatchIndex = out[2].(uint32)
	outstruct.GameAddress = out[3].(common.Address)
	outstruct.BatchHash = out[4].([32]byte)
	outstruct.BondAmount = out[5].(*big.Int)
	outstruct.CreatedAt = out[6].(*big.Int)
	outstruct.Deadline = out[7].(*big.Int)
	outstruct.Status = out[8].(uint8)

	return *outstruct, err

}

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
//
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, address gameAddress, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RATFastWithdrawal *RATFastWithdrawalSession) AttentionTests(arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	GameAddress      common.Address
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	return _RATFastWithdrawal.Contract.AttentionTests(&_RATFastWithdrawal.CallOpts, arg0)
}

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
//
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, address gameAddress, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) AttentionTests(arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	GameAddress      common.Address
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	return _RATFastWithdrawal.Contract.AttentionTests(&_RATFastWithdrawal.CallOpts, arg0)
}

// AuthorizedTrigger is a free data retrieval call binding the contract method 0xe1705cb6.
//
// Solidity: function authorizedTrigger() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) AuthorizedTrigger(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "authorizedTrigger")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// AuthorizedTrigger is a free data retrieval call binding the contract method 0xe1705cb6.
//
// Solidity: function authorizedTrigger() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) AuthorizedTrigger() (common.Address, error) {
	return _RATFastWithdrawal.Contract.AuthorizedTrigger(&_RATFastWithdrawal.CallOpts)
}

// AuthorizedTrigger is a free data retrieval call binding the contract method 0xe1705cb6.
//
// Solidity: function authorizedTrigger() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) AuthorizedTrigger() (common.Address, error) {
	return _RATFastWithdrawal.Contract.AuthorizedTrigger(&_RATFastWithdrawal.CallOpts)
}

// BatchToTestId is a free data retrieval call binding the contract method 0x0bec5691.
//
// Solidity: function batchToTestId(address , uint32 ) view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) BatchToTestId(opts *bind.CallOpts, arg0 common.Address, arg1 uint32) ([32]byte, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "batchToTestId", arg0, arg1)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// BatchToTestId is a free data retrieval call binding the contract method 0x0bec5691.
//
// Solidity: function batchToTestId(address , uint32 ) view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalSession) BatchToTestId(arg0 common.Address, arg1 uint32) ([32]byte, error) {
	return _RATFastWithdrawal.Contract.BatchToTestId(&_RATFastWithdrawal.CallOpts, arg0, arg1)
}

// BatchToTestId is a free data retrieval call binding the contract method 0x0bec5691.
//
// Solidity: function batchToTestId(address , uint32 ) view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) BatchToTestId(arg0 common.Address, arg1 uint32) ([32]byte, error) {
	return _RATFastWithdrawal.Contract.BatchToTestId(&_RATFastWithdrawal.CallOpts, arg0, arg1)
}

// ChallengeGameDuration is a free data retrieval call binding the contract method 0x41faedf5.
//
// Solidity: function challengeGameDuration() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) ChallengeGameDuration(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "challengeGameDuration")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ChallengeGameDuration is a free data retrieval call binding the contract method 0x41faedf5.
//
// Solidity: function challengeGameDuration() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) ChallengeGameDuration() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.ChallengeGameDuration(&_RATFastWithdrawal.CallOpts)
}

// ChallengeGameDuration is a free data retrieval call binding the contract method 0x41faedf5.
//
// Solidity: function challengeGameDuration() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) ChallengeGameDuration() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.ChallengeGameDuration(&_RATFastWithdrawal.CallOpts)
}

// EvidenceSubmissionPeriod is a free data retrieval call binding the contract method 0xacccb08f.
//
// Solidity: function evidenceSubmissionPeriod() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) EvidenceSubmissionPeriod(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "evidenceSubmissionPeriod")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// EvidenceSubmissionPeriod is a free data retrieval call binding the contract method 0xacccb08f.
//
// Solidity: function evidenceSubmissionPeriod() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) EvidenceSubmissionPeriod() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.EvidenceSubmissionPeriod(&_RATFastWithdrawal.CallOpts)
}

// EvidenceSubmissionPeriod is a free data retrieval call binding the contract method 0xacccb08f.
//
// Solidity: function evidenceSubmissionPeriod() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) EvidenceSubmissionPeriod() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.EvidenceSubmissionPeriod(&_RATFastWithdrawal.CallOpts)
}

// FactoryByGame is a free data retrieval call binding the contract method 0x62592433.
//
// Solidity: function factoryByGame(address ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) FactoryByGame(opts *bind.CallOpts, arg0 common.Address) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "factoryByGame", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// FactoryByGame is a free data retrieval call binding the contract method 0x62592433.
//
// Solidity: function factoryByGame(address ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) FactoryByGame(arg0 common.Address) (common.Address, error) {
	return _RATFastWithdrawal.Contract.FactoryByGame(&_RATFastWithdrawal.CallOpts, arg0)
}

// FactoryByGame is a free data retrieval call binding the contract method 0x62592433.
//
// Solidity: function factoryByGame(address ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) FactoryByGame(arg0 common.Address) (common.Address, error) {
	return _RATFastWithdrawal.Contract.FactoryByGame(&_RATFastWithdrawal.CallOpts, arg0)
}

// FastWithdrawalEnabled is a free data retrieval call binding the contract method 0xdfee9a04.
//
// Solidity: function fastWithdrawalEnabled() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) FastWithdrawalEnabled(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "fastWithdrawalEnabled")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// FastWithdrawalEnabled is a free data retrieval call binding the contract method 0xdfee9a04.
//
// Solidity: function fastWithdrawalEnabled() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) FastWithdrawalEnabled() (bool, error) {
	return _RATFastWithdrawal.Contract.FastWithdrawalEnabled(&_RATFastWithdrawal.CallOpts)
}

// FastWithdrawalEnabled is a free data retrieval call binding the contract method 0xdfee9a04.
//
// Solidity: function fastWithdrawalEnabled() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) FastWithdrawalEnabled() (bool, error) {
	return _RATFastWithdrawal.Contract.FastWithdrawalEnabled(&_RATFastWithdrawal.CallOpts)
}

// GameToTestId is a free data retrieval call binding the contract method 0xddef8e85.
//
// Solidity: function gameToTestId(address ) view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) GameToTestId(opts *bind.CallOpts, arg0 common.Address) ([32]byte, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "gameToTestId", arg0)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GameToTestId is a free data retrieval call binding the contract method 0xddef8e85.
//
// Solidity: function gameToTestId(address ) view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalSession) GameToTestId(arg0 common.Address) ([32]byte, error) {
	return _RATFastWithdrawal.Contract.GameToTestId(&_RATFastWithdrawal.CallOpts, arg0)
}

// GameToTestId is a free data retrieval call binding the contract method 0xddef8e85.
//
// Solidity: function gameToTestId(address ) view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) GameToTestId(arg0 common.Address) ([32]byte, error) {
	return _RATFastWithdrawal.Contract.GameToTestId(&_RATFastWithdrawal.CallOpts, arg0)
}

// GetActiveValidatorsWithBLS is a free data retrieval call binding the contract method 0xe96562bc.
//
// Solidity: function getActiveValidatorsWithBLS(address systemConfig) view returns(address[] validators, bytes[] blsKeys, uint256 validBLSCount)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) GetActiveValidatorsWithBLS(opts *bind.CallOpts, systemConfig common.Address) (struct {
	Validators    []common.Address
	BlsKeys       [][]byte
	ValidBLSCount *big.Int
}, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "getActiveValidatorsWithBLS", systemConfig)

	outstruct := new(struct {
		Validators    []common.Address
		BlsKeys       [][]byte
		ValidBLSCount *big.Int
	})

	outstruct.Validators = out[0].([]common.Address)
	outstruct.BlsKeys = out[1].([][]byte)
	outstruct.ValidBLSCount = out[2].(*big.Int)

	return *outstruct, err

}

// GetActiveValidatorsWithBLS is a free data retrieval call binding the contract method 0xe96562bc.
//
// Solidity: function getActiveValidatorsWithBLS(address systemConfig) view returns(address[] validators, bytes[] blsKeys, uint256 validBLSCount)
func (_RATFastWithdrawal *RATFastWithdrawalSession) GetActiveValidatorsWithBLS(systemConfig common.Address) (struct {
	Validators    []common.Address
	BlsKeys       [][]byte
	ValidBLSCount *big.Int
}, error) {
	return _RATFastWithdrawal.Contract.GetActiveValidatorsWithBLS(&_RATFastWithdrawal.CallOpts, systemConfig)
}

// GetActiveValidatorsWithBLS is a free data retrieval call binding the contract method 0xe96562bc.
//
// Solidity: function getActiveValidatorsWithBLS(address systemConfig) view returns(address[] validators, bytes[] blsKeys, uint256 validBLSCount)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) GetActiveValidatorsWithBLS(systemConfig common.Address) (struct {
	Validators    []common.Address
	BlsKeys       [][]byte
	ValidBLSCount *big.Int
}, error) {
	return _RATFastWithdrawal.Contract.GetActiveValidatorsWithBLS(&_RATFastWithdrawal.CallOpts, systemConfig)
}

// GetBatchValidatorBLSPublicKeys is a free data retrieval call binding the contract method 0xac102e31.
//
// Solidity: function getBatchValidatorBLSPublicKeys(address[] validators, address systemConfig) view returns(bytes[] blsPublicKeys)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) GetBatchValidatorBLSPublicKeys(opts *bind.CallOpts, validators []common.Address, systemConfig common.Address) ([][]byte, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "getBatchValidatorBLSPublicKeys", validators, systemConfig)

	if err != nil {
		return *new([][]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([][]byte)).(*[][]byte)

	return out0, err

}

// GetBatchValidatorBLSPublicKeys is a free data retrieval call binding the contract method 0xac102e31.
//
// Solidity: function getBatchValidatorBLSPublicKeys(address[] validators, address systemConfig) view returns(bytes[] blsPublicKeys)
func (_RATFastWithdrawal *RATFastWithdrawalSession) GetBatchValidatorBLSPublicKeys(validators []common.Address, systemConfig common.Address) ([][]byte, error) {
	return _RATFastWithdrawal.Contract.GetBatchValidatorBLSPublicKeys(&_RATFastWithdrawal.CallOpts, validators, systemConfig)
}

// GetBatchValidatorBLSPublicKeys is a free data retrieval call binding the contract method 0xac102e31.
//
// Solidity: function getBatchValidatorBLSPublicKeys(address[] validators, address systemConfig) view returns(bytes[] blsPublicKeys)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) GetBatchValidatorBLSPublicKeys(validators []common.Address, systemConfig common.Address) ([][]byte, error) {
	return _RATFastWithdrawal.Contract.GetBatchValidatorBLSPublicKeys(&_RATFastWithdrawal.CallOpts, validators, systemConfig)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _RATFastWithdrawal.Contract.GetRoleAdmin(&_RATFastWithdrawal.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _RATFastWithdrawal.Contract.GetRoleAdmin(&_RATFastWithdrawal.CallOpts, role)
}

// GetValidatorBLSPubKey is a free data retrieval call binding the contract method 0x43ef42be.
//
// Solidity: function getValidatorBLSPubKey(address validator, address systemConfig) view returns(bytes)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) GetValidatorBLSPubKey(opts *bind.CallOpts, validator common.Address, systemConfig common.Address) ([]byte, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "getValidatorBLSPubKey", validator, systemConfig)

	if err != nil {
		return *new([]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([]byte)).(*[]byte)

	return out0, err

}

// GetValidatorBLSPubKey is a free data retrieval call binding the contract method 0x43ef42be.
//
// Solidity: function getValidatorBLSPubKey(address validator, address systemConfig) view returns(bytes)
func (_RATFastWithdrawal *RATFastWithdrawalSession) GetValidatorBLSPubKey(validator common.Address, systemConfig common.Address) ([]byte, error) {
	return _RATFastWithdrawal.Contract.GetValidatorBLSPubKey(&_RATFastWithdrawal.CallOpts, validator, systemConfig)
}

// GetValidatorBLSPubKey is a free data retrieval call binding the contract method 0x43ef42be.
//
// Solidity: function getValidatorBLSPubKey(address validator, address systemConfig) view returns(bytes)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) GetValidatorBLSPubKey(validator common.Address, systemConfig common.Address) ([]byte, error) {
	return _RATFastWithdrawal.Contract.GetValidatorBLSPubKey(&_RATFastWithdrawal.CallOpts, validator, systemConfig)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _RATFastWithdrawal.Contract.HasRole(&_RATFastWithdrawal.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _RATFastWithdrawal.Contract.HasRole(&_RATFastWithdrawal.CallOpts, role, account)
}

// HasValidatorBLSKey is a free data retrieval call binding the contract method 0xf2b75bc3.
//
// Solidity: function hasValidatorBLSKey(address validator, address systemConfig) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) HasValidatorBLSKey(opts *bind.CallOpts, validator common.Address, systemConfig common.Address) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "hasValidatorBLSKey", validator, systemConfig)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasValidatorBLSKey is a free data retrieval call binding the contract method 0xf2b75bc3.
//
// Solidity: function hasValidatorBLSKey(address validator, address systemConfig) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) HasValidatorBLSKey(validator common.Address, systemConfig common.Address) (bool, error) {
	return _RATFastWithdrawal.Contract.HasValidatorBLSKey(&_RATFastWithdrawal.CallOpts, validator, systemConfig)
}

// HasValidatorBLSKey is a free data retrieval call binding the contract method 0xf2b75bc3.
//
// Solidity: function hasValidatorBLSKey(address validator, address systemConfig) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) HasValidatorBLSKey(validator common.Address, systemConfig common.Address) (bool, error) {
	return _RATFastWithdrawal.Contract.HasValidatorBLSKey(&_RATFastWithdrawal.CallOpts, validator, systemConfig)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) IsAdmin(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "isAdmin", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) IsAdmin(account common.Address) (bool, error) {
	return _RATFastWithdrawal.Contract.IsAdmin(&_RATFastWithdrawal.CallOpts, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) IsAdmin(account common.Address) (bool, error) {
	return _RATFastWithdrawal.Contract.IsAdmin(&_RATFastWithdrawal.CallOpts, account)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) IsOwner(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "isOwner")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) IsOwner() (bool, error) {
	return _RATFastWithdrawal.Contract.IsOwner(&_RATFastWithdrawal.CallOpts)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) IsOwner() (bool, error) {
	return _RATFastWithdrawal.Contract.IsOwner(&_RATFastWithdrawal.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) L1BridgeRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "l1BridgeRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) L1BridgeRegistry() (common.Address, error) {
	return _RATFastWithdrawal.Contract.L1BridgeRegistry(&_RATFastWithdrawal.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) L1BridgeRegistry() (common.Address, error) {
	return _RATFastWithdrawal.Contract.L1BridgeRegistry(&_RATFastWithdrawal.CallOpts)
}

// LatestDeadlineTest is a free data retrieval call binding the contract method 0x44f1c99d.
//
// Solidity: function latestDeadlineTest(address ) view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) LatestDeadlineTest(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "latestDeadlineTest", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LatestDeadlineTest is a free data retrieval call binding the contract method 0x44f1c99d.
//
// Solidity: function latestDeadlineTest(address ) view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) LatestDeadlineTest(arg0 common.Address) (*big.Int, error) {
	return _RATFastWithdrawal.Contract.LatestDeadlineTest(&_RATFastWithdrawal.CallOpts, arg0)
}

// LatestDeadlineTest is a free data retrieval call binding the contract method 0x44f1c99d.
//
// Solidity: function latestDeadlineTest(address ) view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) LatestDeadlineTest(arg0 common.Address) (*big.Int, error) {
	return _RATFastWithdrawal.Contract.LatestDeadlineTest(&_RATFastWithdrawal.CallOpts, arg0)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) Layer2Manager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "layer2Manager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) Layer2Manager() (common.Address, error) {
	return _RATFastWithdrawal.Contract.Layer2Manager(&_RATFastWithdrawal.CallOpts)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) Layer2Manager() (common.Address, error) {
	return _RATFastWithdrawal.Contract.Layer2Manager(&_RATFastWithdrawal.CallOpts)
}

// MaxValidatorsPerL2 is a free data retrieval call binding the contract method 0xcfa424ea.
//
// Solidity: function maxValidatorsPerL2() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) MaxValidatorsPerL2(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "maxValidatorsPerL2")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxValidatorsPerL2 is a free data retrieval call binding the contract method 0xcfa424ea.
//
// Solidity: function maxValidatorsPerL2() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) MaxValidatorsPerL2() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.MaxValidatorsPerL2(&_RATFastWithdrawal.CallOpts)
}

// MaxValidatorsPerL2 is a free data retrieval call binding the contract method 0xcfa424ea.
//
// Solidity: function maxValidatorsPerL2() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) MaxValidatorsPerL2() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.MaxValidatorsPerL2(&_RATFastWithdrawal.CallOpts)
}

// MinValidatorsForFastWithdrawal is a free data retrieval call binding the contract method 0xcc103906.
//
// Solidity: function minValidatorsForFastWithdrawal() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) MinValidatorsForFastWithdrawal(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "minValidatorsForFastWithdrawal")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MinValidatorsForFastWithdrawal is a free data retrieval call binding the contract method 0xcc103906.
//
// Solidity: function minValidatorsForFastWithdrawal() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) MinValidatorsForFastWithdrawal() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.MinValidatorsForFastWithdrawal(&_RATFastWithdrawal.CallOpts)
}

// MinValidatorsForFastWithdrawal is a free data retrieval call binding the contract method 0xcc103906.
//
// Solidity: function minValidatorsForFastWithdrawal() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) MinValidatorsForFastWithdrawal() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.MinValidatorsForFastWithdrawal(&_RATFastWithdrawal.CallOpts)
}

// MinimumThreshold is a free data retrieval call binding the contract method 0x75da30d0.
//
// Solidity: function minimumThreshold() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) MinimumThreshold(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "minimumThreshold")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MinimumThreshold is a free data retrieval call binding the contract method 0x75da30d0.
//
// Solidity: function minimumThreshold() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) MinimumThreshold() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.MinimumThreshold(&_RATFastWithdrawal.CallOpts)
}

// MinimumThreshold is a free data retrieval call binding the contract method 0x75da30d0.
//
// Solidity: function minimumThreshold() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) MinimumThreshold() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.MinimumThreshold(&_RATFastWithdrawal.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) PauseProxy(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "pauseProxy")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) PauseProxy() (bool, error) {
	return _RATFastWithdrawal.Contract.PauseProxy(&_RATFastWithdrawal.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) PauseProxy() (bool, error) {
	return _RATFastWithdrawal.Contract.PauseProxy(&_RATFastWithdrawal.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) Paused() (bool, error) {
	return _RATFastWithdrawal.Contract.Paused(&_RATFastWithdrawal.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) Paused() (bool, error) {
	return _RATFastWithdrawal.Contract.Paused(&_RATFastWithdrawal.CallOpts)
}

// ProcessedWithdrawals is a free data retrieval call binding the contract method 0xbf49d631.
//
// Solidity: function processedWithdrawals(bytes32 ) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) ProcessedWithdrawals(opts *bind.CallOpts, arg0 [32]byte) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "processedWithdrawals", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ProcessedWithdrawals is a free data retrieval call binding the contract method 0xbf49d631.
//
// Solidity: function processedWithdrawals(bytes32 ) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) ProcessedWithdrawals(arg0 [32]byte) (bool, error) {
	return _RATFastWithdrawal.Contract.ProcessedWithdrawals(&_RATFastWithdrawal.CallOpts, arg0)
}

// ProcessedWithdrawals is a free data retrieval call binding the contract method 0xbf49d631.
//
// Solidity: function processedWithdrawals(bytes32 ) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) ProcessedWithdrawals(arg0 [32]byte) (bool, error) {
	return _RATFastWithdrawal.Contract.ProcessedWithdrawals(&_RATFastWithdrawal.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) ProxyImplementation(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "proxyImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _RATFastWithdrawal.Contract.ProxyImplementation(&_RATFastWithdrawal.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _RATFastWithdrawal.Contract.ProxyImplementation(&_RATFastWithdrawal.CallOpts, arg0)
}

// RatTriggerProbability is a free data retrieval call binding the contract method 0x51567bc2.
//
// Solidity: function ratTriggerProbability() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) RatTriggerProbability(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "ratTriggerProbability")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// RatTriggerProbability is a free data retrieval call binding the contract method 0x51567bc2.
//
// Solidity: function ratTriggerProbability() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) RatTriggerProbability() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.RatTriggerProbability(&_RATFastWithdrawal.CallOpts)
}

// RatTriggerProbability is a free data retrieval call binding the contract method 0x51567bc2.
//
// Solidity: function ratTriggerProbability() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) RatTriggerProbability() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.RatTriggerProbability(&_RATFastWithdrawal.CallOpts)
}

// RelaxedValidatorCheck is a free data retrieval call binding the contract method 0x0fab0073.
//
// Solidity: function relaxedValidatorCheck() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) RelaxedValidatorCheck(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "relaxedValidatorCheck")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// RelaxedValidatorCheck is a free data retrieval call binding the contract method 0x0fab0073.
//
// Solidity: function relaxedValidatorCheck() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) RelaxedValidatorCheck() (bool, error) {
	return _RATFastWithdrawal.Contract.RelaxedValidatorCheck(&_RATFastWithdrawal.CallOpts)
}

// RelaxedValidatorCheck is a free data retrieval call binding the contract method 0x0fab0073.
//
// Solidity: function relaxedValidatorCheck() view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) RelaxedValidatorCheck() (bool, error) {
	return _RATFastWithdrawal.Contract.RelaxedValidatorCheck(&_RATFastWithdrawal.CallOpts)
}

// SafetyBuffer is a free data retrieval call binding the contract method 0x0caebb61.
//
// Solidity: function safetyBuffer() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) SafetyBuffer(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "safetyBuffer")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// SafetyBuffer is a free data retrieval call binding the contract method 0x0caebb61.
//
// Solidity: function safetyBuffer() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) SafetyBuffer() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.SafetyBuffer(&_RATFastWithdrawal.CallOpts)
}

// SafetyBuffer is a free data retrieval call binding the contract method 0x0caebb61.
//
// Solidity: function safetyBuffer() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) SafetyBuffer() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.SafetyBuffer(&_RATFastWithdrawal.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) SeigManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "seigManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) SeigManager() (common.Address, error) {
	return _RATFastWithdrawal.Contract.SeigManager(&_RATFastWithdrawal.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) SeigManager() (common.Address, error) {
	return _RATFastWithdrawal.Contract.SeigManager(&_RATFastWithdrawal.CallOpts)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) SelectorImplementation(opts *bind.CallOpts, arg0 [4]byte) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "selectorImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _RATFastWithdrawal.Contract.SelectorImplementation(&_RATFastWithdrawal.CallOpts, arg0)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _RATFastWithdrawal.Contract.SelectorImplementation(&_RATFastWithdrawal.CallOpts, arg0)
}

// SlashingPenalty is a free data retrieval call binding the contract method 0x89f1ea64.
//
// Solidity: function slashingPenalty() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) SlashingPenalty(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "slashingPenalty")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// SlashingPenalty is a free data retrieval call binding the contract method 0x89f1ea64.
//
// Solidity: function slashingPenalty() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) SlashingPenalty() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.SlashingPenalty(&_RATFastWithdrawal.CallOpts)
}

// SlashingPenalty is a free data retrieval call binding the contract method 0x89f1ea64.
//
// Solidity: function slashingPenalty() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) SlashingPenalty() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.SlashingPenalty(&_RATFastWithdrawal.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _RATFastWithdrawal.Contract.SupportsInterface(&_RATFastWithdrawal.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _RATFastWithdrawal.Contract.SupportsInterface(&_RATFastWithdrawal.CallOpts, interfaceId)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) Ton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "ton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) Ton() (common.Address, error) {
	return _RATFastWithdrawal.Contract.Ton(&_RATFastWithdrawal.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) Ton() (common.Address, error) {
	return _RATFastWithdrawal.Contract.Ton(&_RATFastWithdrawal.CallOpts)
}

// Treasury is a free data retrieval call binding the contract method 0x61d027b3.
//
// Solidity: function treasury() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) Treasury(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "treasury")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Treasury is a free data retrieval call binding the contract method 0x61d027b3.
//
// Solidity: function treasury() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) Treasury() (common.Address, error) {
	return _RATFastWithdrawal.Contract.Treasury(&_RATFastWithdrawal.CallOpts)
}

// Treasury is a free data retrieval call binding the contract method 0x61d027b3.
//
// Solidity: function treasury() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) Treasury() (common.Address, error) {
	return _RATFastWithdrawal.Contract.Treasury(&_RATFastWithdrawal.CallOpts)
}

// ValidatorBuffer is a free data retrieval call binding the contract method 0xf7107b44.
//
// Solidity: function validatorBuffer() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) ValidatorBuffer(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "validatorBuffer")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ValidatorBuffer is a free data retrieval call binding the contract method 0xf7107b44.
//
// Solidity: function validatorBuffer() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) ValidatorBuffer() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.ValidatorBuffer(&_RATFastWithdrawal.CallOpts)
}

// ValidatorBuffer is a free data retrieval call binding the contract method 0xf7107b44.
//
// Solidity: function validatorBuffer() view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) ValidatorBuffer() (*big.Int, error) {
	return _RATFastWithdrawal.Contract.ValidatorBuffer(&_RATFastWithdrawal.CallOpts)
}

// ValidatorIndexes is a free data retrieval call binding the contract method 0x4e4a9a1b.
//
// Solidity: function validatorIndexes(address , address ) view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) ValidatorIndexes(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "validatorIndexes", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ValidatorIndexes is a free data retrieval call binding the contract method 0x4e4a9a1b.
//
// Solidity: function validatorIndexes(address , address ) view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalSession) ValidatorIndexes(arg0 common.Address, arg1 common.Address) (*big.Int, error) {
	return _RATFastWithdrawal.Contract.ValidatorIndexes(&_RATFastWithdrawal.CallOpts, arg0, arg1)
}

// ValidatorIndexes is a free data retrieval call binding the contract method 0x4e4a9a1b.
//
// Solidity: function validatorIndexes(address , address ) view returns(uint256)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) ValidatorIndexes(arg0 common.Address, arg1 common.Address) (*big.Int, error) {
	return _RATFastWithdrawal.Contract.ValidatorIndexes(&_RATFastWithdrawal.CallOpts, arg0, arg1)
}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 lockedForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive, bytes blsPublicKey)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) ValidatorRegistrations(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address) (struct {
	LockedForRAT       *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
	BlsPublicKey       []byte
}, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "validatorRegistrations", arg0, arg1)

	outstruct := new(struct {
		LockedForRAT       *big.Int
		PendingRewards     *big.Int
		LatestTestDeadline uint64
		ValidatorIndex     uint32
		IsActive           bool
		BlsPublicKey       []byte
	})

	outstruct.LockedForRAT = out[0].(*big.Int)
	outstruct.PendingRewards = out[1].(*big.Int)
	outstruct.LatestTestDeadline = out[2].(uint64)
	outstruct.ValidatorIndex = out[3].(uint32)
	outstruct.IsActive = out[4].(bool)
	outstruct.BlsPublicKey = out[5].([]byte)

	return *outstruct, err

}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 lockedForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive, bytes blsPublicKey)
func (_RATFastWithdrawal *RATFastWithdrawalSession) ValidatorRegistrations(arg0 common.Address, arg1 common.Address) (struct {
	LockedForRAT       *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
	BlsPublicKey       []byte
}, error) {
	return _RATFastWithdrawal.Contract.ValidatorRegistrations(&_RATFastWithdrawal.CallOpts, arg0, arg1)
}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 lockedForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive, bytes blsPublicKey)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) ValidatorRegistrations(arg0 common.Address, arg1 common.Address) (struct {
	LockedForRAT       *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
	BlsPublicKey       []byte
}, error) {
	return _RATFastWithdrawal.Contract.ValidatorRegistrations(&_RATFastWithdrawal.CallOpts, arg0, arg1)
}

// ValidatorReward is a free data retrieval call binding the contract method 0x75b94133.
//
// Solidity: function validatorReward() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) ValidatorReward(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "validatorReward")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ValidatorReward is a free data retrieval call binding the contract method 0x75b94133.
//
// Solidity: function validatorReward() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) ValidatorReward() (common.Address, error) {
	return _RATFastWithdrawal.Contract.ValidatorReward(&_RATFastWithdrawal.CallOpts)
}

// ValidatorReward is a free data retrieval call binding the contract method 0x75b94133.
//
// Solidity: function validatorReward() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) ValidatorReward() (common.Address, error) {
	return _RATFastWithdrawal.Contract.ValidatorReward(&_RATFastWithdrawal.CallOpts)
}

// ValidatorSystemConfigs is a free data retrieval call binding the contract method 0x8dc3b28e.
//
// Solidity: function validatorSystemConfigs(address , uint256 ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) ValidatorSystemConfigs(opts *bind.CallOpts, arg0 common.Address, arg1 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "validatorSystemConfigs", arg0, arg1)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ValidatorSystemConfigs is a free data retrieval call binding the contract method 0x8dc3b28e.
//
// Solidity: function validatorSystemConfigs(address , uint256 ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) ValidatorSystemConfigs(arg0 common.Address, arg1 *big.Int) (common.Address, error) {
	return _RATFastWithdrawal.Contract.ValidatorSystemConfigs(&_RATFastWithdrawal.CallOpts, arg0, arg1)
}

// ValidatorSystemConfigs is a free data retrieval call binding the contract method 0x8dc3b28e.
//
// Solidity: function validatorSystemConfigs(address , uint256 ) view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) ValidatorSystemConfigs(arg0 common.Address, arg1 *big.Int) (common.Address, error) {
	return _RATFastWithdrawal.Contract.ValidatorSystemConfigs(&_RATFastWithdrawal.CallOpts, arg0, arg1)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCaller) Wton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RATFastWithdrawal.contract.Call(opts, &out, "wton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalSession) Wton() (common.Address, error) {
	return _RATFastWithdrawal.Contract.Wton(&_RATFastWithdrawal.CallOpts)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_RATFastWithdrawal *RATFastWithdrawalCallerSession) Wton() (common.Address, error) {
	return _RATFastWithdrawal.Contract.Wton(&_RATFastWithdrawal.CallOpts)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) AddAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "addAdmin", account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.AddAdmin(&_RATFastWithdrawal.TransactOpts, account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.AddAdmin(&_RATFastWithdrawal.TransactOpts, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.GrantRole(&_RATFastWithdrawal.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.GrantRole(&_RATFastWithdrawal.TransactOpts, role, account)
}

// RegisterBLSPublicKey is a paid mutator transaction binding the contract method 0x5d9e941f.
//
// Solidity: function registerBLSPublicKey(address systemConfig, bytes blsPublicKey, bytes blsProofOfPossession) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) RegisterBLSPublicKey(opts *bind.TransactOpts, systemConfig common.Address, blsPublicKey []byte, blsProofOfPossession []byte) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "registerBLSPublicKey", systemConfig, blsPublicKey, blsProofOfPossession)
}

// RegisterBLSPublicKey is a paid mutator transaction binding the contract method 0x5d9e941f.
//
// Solidity: function registerBLSPublicKey(address systemConfig, bytes blsPublicKey, bytes blsProofOfPossession) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) RegisterBLSPublicKey(systemConfig common.Address, blsPublicKey []byte, blsProofOfPossession []byte) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RegisterBLSPublicKey(&_RATFastWithdrawal.TransactOpts, systemConfig, blsPublicKey, blsProofOfPossession)
}

// RegisterBLSPublicKey is a paid mutator transaction binding the contract method 0x5d9e941f.
//
// Solidity: function registerBLSPublicKey(address systemConfig, bytes blsPublicKey, bytes blsProofOfPossession) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) RegisterBLSPublicKey(systemConfig common.Address, blsPublicKey []byte, blsProofOfPossession []byte) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RegisterBLSPublicKey(&_RATFastWithdrawal.TransactOpts, systemConfig, blsPublicKey, blsProofOfPossession)
}

// RegisterValidatorWithBLS is a paid mutator transaction binding the contract method 0xb0b55e0e.
//
// Solidity: function registerValidatorWithBLS(address systemConfig, bytes blsPublicKey, bytes blsProofOfPossession) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) RegisterValidatorWithBLS(opts *bind.TransactOpts, systemConfig common.Address, blsPublicKey []byte, blsProofOfPossession []byte) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "registerValidatorWithBLS", systemConfig, blsPublicKey, blsProofOfPossession)
}

// RegisterValidatorWithBLS is a paid mutator transaction binding the contract method 0xb0b55e0e.
//
// Solidity: function registerValidatorWithBLS(address systemConfig, bytes blsPublicKey, bytes blsProofOfPossession) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) RegisterValidatorWithBLS(systemConfig common.Address, blsPublicKey []byte, blsProofOfPossession []byte) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RegisterValidatorWithBLS(&_RATFastWithdrawal.TransactOpts, systemConfig, blsPublicKey, blsProofOfPossession)
}

// RegisterValidatorWithBLS is a paid mutator transaction binding the contract method 0xb0b55e0e.
//
// Solidity: function registerValidatorWithBLS(address systemConfig, bytes blsPublicKey, bytes blsProofOfPossession) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) RegisterValidatorWithBLS(systemConfig common.Address, blsPublicKey []byte, blsProofOfPossession []byte) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RegisterValidatorWithBLS(&_RATFastWithdrawal.TransactOpts, systemConfig, blsPublicKey, blsProofOfPossession)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) RemoveAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "removeAdmin", account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RemoveAdmin(&_RATFastWithdrawal.TransactOpts, account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RemoveAdmin(&_RATFastWithdrawal.TransactOpts, account)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) RenounceOwnership() (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RenounceOwnership(&_RATFastWithdrawal.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RenounceOwnership(&_RATFastWithdrawal.TransactOpts)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "renounceRole", role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RenounceRole(&_RATFastWithdrawal.TransactOpts, role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RenounceRole(&_RATFastWithdrawal.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RevokeRole(&_RATFastWithdrawal.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.RevokeRole(&_RATFastWithdrawal.TransactOpts, role, account)
}

// SetAggregatorFeeRate is a paid mutator transaction binding the contract method 0x20494cba.
//
// Solidity: function setAggregatorFeeRate(uint256 rate) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) SetAggregatorFeeRate(opts *bind.TransactOpts, rate *big.Int) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "setAggregatorFeeRate", rate)
}

// SetAggregatorFeeRate is a paid mutator transaction binding the contract method 0x20494cba.
//
// Solidity: function setAggregatorFeeRate(uint256 rate) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) SetAggregatorFeeRate(rate *big.Int) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.SetAggregatorFeeRate(&_RATFastWithdrawal.TransactOpts, rate)
}

// SetAggregatorFeeRate is a paid mutator transaction binding the contract method 0x20494cba.
//
// Solidity: function setAggregatorFeeRate(uint256 rate) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) SetAggregatorFeeRate(rate *big.Int) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.SetAggregatorFeeRate(&_RATFastWithdrawal.TransactOpts, rate)
}

// SetMinValidatorsForFastWithdrawal is a paid mutator transaction binding the contract method 0x57f544de.
//
// Solidity: function setMinValidatorsForFastWithdrawal(uint256 minValidators) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) SetMinValidatorsForFastWithdrawal(opts *bind.TransactOpts, minValidators *big.Int) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "setMinValidatorsForFastWithdrawal", minValidators)
}

// SetMinValidatorsForFastWithdrawal is a paid mutator transaction binding the contract method 0x57f544de.
//
// Solidity: function setMinValidatorsForFastWithdrawal(uint256 minValidators) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) SetMinValidatorsForFastWithdrawal(minValidators *big.Int) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.SetMinValidatorsForFastWithdrawal(&_RATFastWithdrawal.TransactOpts, minValidators)
}

// SetMinValidatorsForFastWithdrawal is a paid mutator transaction binding the contract method 0x57f544de.
//
// Solidity: function setMinValidatorsForFastWithdrawal(uint256 minValidators) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) SetMinValidatorsForFastWithdrawal(minValidators *big.Int) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.SetMinValidatorsForFastWithdrawal(&_RATFastWithdrawal.TransactOpts, minValidators)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) TransferAdmin(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "transferAdmin", newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.TransferAdmin(&_RATFastWithdrawal.TransactOpts, newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.TransferAdmin(&_RATFastWithdrawal.TransactOpts, newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) TransferOwnership(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "transferOwnership", newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) TransferOwnership(newAdmin common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.TransferOwnership(&_RATFastWithdrawal.TransactOpts, newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) TransferOwnership(newAdmin common.Address) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.TransferOwnership(&_RATFastWithdrawal.TransactOpts, newAdmin)
}

// VerifyAndExecuteFastWithdrawal is a paid mutator transaction binding the contract method 0x2bd3aefe.
//
// Solidity: function verifyAndExecuteFastWithdrawal((uint256,address,address,uint256,uint256,bytes) _tx, (bytes32,address,bytes32,uint256,bytes32,bytes32,bytes[],bytes[]) input, bytes _aggregatedSignature) payable returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) VerifyAndExecuteFastWithdrawal(opts *bind.TransactOpts, _tx TypesWithdrawalTransaction, input RATFastWithdrawalLibFastWithdrawalInput, _aggregatedSignature []byte) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.Transact(opts, "verifyAndExecuteFastWithdrawal", _tx, input, _aggregatedSignature)
}

// VerifyAndExecuteFastWithdrawal is a paid mutator transaction binding the contract method 0x2bd3aefe.
//
// Solidity: function verifyAndExecuteFastWithdrawal((uint256,address,address,uint256,uint256,bytes) _tx, (bytes32,address,bytes32,uint256,bytes32,bytes32,bytes[],bytes[]) input, bytes _aggregatedSignature) payable returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) VerifyAndExecuteFastWithdrawal(_tx TypesWithdrawalTransaction, input RATFastWithdrawalLibFastWithdrawalInput, _aggregatedSignature []byte) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.VerifyAndExecuteFastWithdrawal(&_RATFastWithdrawal.TransactOpts, _tx, input, _aggregatedSignature)
}

// VerifyAndExecuteFastWithdrawal is a paid mutator transaction binding the contract method 0x2bd3aefe.
//
// Solidity: function verifyAndExecuteFastWithdrawal((uint256,address,address,uint256,uint256,bytes) _tx, (bytes32,address,bytes32,uint256,bytes32,bytes32,bytes[],bytes[]) input, bytes _aggregatedSignature) payable returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) VerifyAndExecuteFastWithdrawal(_tx TypesWithdrawalTransaction, input RATFastWithdrawalLibFastWithdrawalInput, _aggregatedSignature []byte) (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.VerifyAndExecuteFastWithdrawal(&_RATFastWithdrawal.TransactOpts, _tx, input, _aggregatedSignature)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactor) Receive(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RATFastWithdrawal.contract.RawTransact(opts, nil) // calldata is disallowed for receive function
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_RATFastWithdrawal *RATFastWithdrawalSession) Receive() (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.Receive(&_RATFastWithdrawal.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_RATFastWithdrawal *RATFastWithdrawalTransactorSession) Receive() (*types.Transaction, error) {
	return _RATFastWithdrawal.Contract.Receive(&_RATFastWithdrawal.TransactOpts)
}

// RATFastWithdrawalAggregatorFeeRateUpdatedIterator is returned from FilterAggregatorFeeRateUpdated and is used to iterate over the raw logs and unpacked data for AggregatorFeeRateUpdated events raised by the RATFastWithdrawal contract.
type RATFastWithdrawalAggregatorFeeRateUpdatedIterator struct {
	Event *RATFastWithdrawalAggregatorFeeRateUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RATFastWithdrawalAggregatorFeeRateUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATFastWithdrawalAggregatorFeeRateUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RATFastWithdrawalAggregatorFeeRateUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RATFastWithdrawalAggregatorFeeRateUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATFastWithdrawalAggregatorFeeRateUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATFastWithdrawalAggregatorFeeRateUpdated represents a AggregatorFeeRateUpdated event raised by the RATFastWithdrawal contract.
type RATFastWithdrawalAggregatorFeeRateUpdated struct {
	NewRate *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterAggregatorFeeRateUpdated is a free log retrieval operation binding the contract event 0x711e3847c4c369b7ab83e2bc2b794878a2c62e330a193c1cecf4a61c52a741a3.
//
// Solidity: event AggregatorFeeRateUpdated(uint256 newRate)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) FilterAggregatorFeeRateUpdated(opts *bind.FilterOpts) (*RATFastWithdrawalAggregatorFeeRateUpdatedIterator, error) {

	logs, sub, err := _RATFastWithdrawal.contract.FilterLogs(opts, "AggregatorFeeRateUpdated")
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalAggregatorFeeRateUpdatedIterator{contract: _RATFastWithdrawal.contract, event: "AggregatorFeeRateUpdated", logs: logs, sub: sub}, nil
}

// WatchAggregatorFeeRateUpdated is a free log subscription operation binding the contract event 0x711e3847c4c369b7ab83e2bc2b794878a2c62e330a193c1cecf4a61c52a741a3.
//
// Solidity: event AggregatorFeeRateUpdated(uint256 newRate)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) WatchAggregatorFeeRateUpdated(opts *bind.WatchOpts, sink chan<- *RATFastWithdrawalAggregatorFeeRateUpdated) (event.Subscription, error) {

	logs, sub, err := _RATFastWithdrawal.contract.WatchLogs(opts, "AggregatorFeeRateUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATFastWithdrawalAggregatorFeeRateUpdated)
				if err := _RATFastWithdrawal.contract.UnpackLog(event, "AggregatorFeeRateUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseAggregatorFeeRateUpdated is a log parse operation binding the contract event 0x711e3847c4c369b7ab83e2bc2b794878a2c62e330a193c1cecf4a61c52a741a3.
//
// Solidity: event AggregatorFeeRateUpdated(uint256 newRate)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) ParseAggregatorFeeRateUpdated(log types.Log) (*RATFastWithdrawalAggregatorFeeRateUpdated, error) {
	event := new(RATFastWithdrawalAggregatorFeeRateUpdated)
	if err := _RATFastWithdrawal.contract.UnpackLog(event, "AggregatorFeeRateUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATFastWithdrawalBLSPublicKeyRegisteredIterator is returned from FilterBLSPublicKeyRegistered and is used to iterate over the raw logs and unpacked data for BLSPublicKeyRegistered events raised by the RATFastWithdrawal contract.
type RATFastWithdrawalBLSPublicKeyRegisteredIterator struct {
	Event *RATFastWithdrawalBLSPublicKeyRegistered // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RATFastWithdrawalBLSPublicKeyRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATFastWithdrawalBLSPublicKeyRegistered)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RATFastWithdrawalBLSPublicKeyRegistered)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RATFastWithdrawalBLSPublicKeyRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATFastWithdrawalBLSPublicKeyRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATFastWithdrawalBLSPublicKeyRegistered represents a BLSPublicKeyRegistered event raised by the RATFastWithdrawal contract.
type RATFastWithdrawalBLSPublicKeyRegistered struct {
	Validator    common.Address
	SystemConfig common.Address
	BlsPublicKey []byte
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterBLSPublicKeyRegistered is a free log retrieval operation binding the contract event 0xd7a56e64a4cd1aeb35e575da573ffdbd29cbafdf2ef88c1772197d7c72be405f.
//
// Solidity: event BLSPublicKeyRegistered(address indexed validator, address indexed systemConfig, bytes blsPublicKey)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) FilterBLSPublicKeyRegistered(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address) (*RATFastWithdrawalBLSPublicKeyRegisteredIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.FilterLogs(opts, "BLSPublicKeyRegistered", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalBLSPublicKeyRegisteredIterator{contract: _RATFastWithdrawal.contract, event: "BLSPublicKeyRegistered", logs: logs, sub: sub}, nil
}

// WatchBLSPublicKeyRegistered is a free log subscription operation binding the contract event 0xd7a56e64a4cd1aeb35e575da573ffdbd29cbafdf2ef88c1772197d7c72be405f.
//
// Solidity: event BLSPublicKeyRegistered(address indexed validator, address indexed systemConfig, bytes blsPublicKey)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) WatchBLSPublicKeyRegistered(opts *bind.WatchOpts, sink chan<- *RATFastWithdrawalBLSPublicKeyRegistered, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.WatchLogs(opts, "BLSPublicKeyRegistered", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATFastWithdrawalBLSPublicKeyRegistered)
				if err := _RATFastWithdrawal.contract.UnpackLog(event, "BLSPublicKeyRegistered", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseBLSPublicKeyRegistered is a log parse operation binding the contract event 0xd7a56e64a4cd1aeb35e575da573ffdbd29cbafdf2ef88c1772197d7c72be405f.
//
// Solidity: event BLSPublicKeyRegistered(address indexed validator, address indexed systemConfig, bytes blsPublicKey)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) ParseBLSPublicKeyRegistered(log types.Log) (*RATFastWithdrawalBLSPublicKeyRegistered, error) {
	event := new(RATFastWithdrawalBLSPublicKeyRegistered)
	if err := _RATFastWithdrawal.contract.UnpackLog(event, "BLSPublicKeyRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATFastWithdrawalBLSPublicKeyUpdatedIterator is returned from FilterBLSPublicKeyUpdated and is used to iterate over the raw logs and unpacked data for BLSPublicKeyUpdated events raised by the RATFastWithdrawal contract.
type RATFastWithdrawalBLSPublicKeyUpdatedIterator struct {
	Event *RATFastWithdrawalBLSPublicKeyUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RATFastWithdrawalBLSPublicKeyUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATFastWithdrawalBLSPublicKeyUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RATFastWithdrawalBLSPublicKeyUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RATFastWithdrawalBLSPublicKeyUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATFastWithdrawalBLSPublicKeyUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATFastWithdrawalBLSPublicKeyUpdated represents a BLSPublicKeyUpdated event raised by the RATFastWithdrawal contract.
type RATFastWithdrawalBLSPublicKeyUpdated struct {
	Validator    common.Address
	SystemConfig common.Address
	OldKey       []byte
	NewKey       []byte
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterBLSPublicKeyUpdated is a free log retrieval operation binding the contract event 0x478ede1a0b31e28897a65e0890321b21945ae941c1226813edc126448b158163.
//
// Solidity: event BLSPublicKeyUpdated(address indexed validator, address indexed systemConfig, bytes oldKey, bytes newKey)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) FilterBLSPublicKeyUpdated(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address) (*RATFastWithdrawalBLSPublicKeyUpdatedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.FilterLogs(opts, "BLSPublicKeyUpdated", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalBLSPublicKeyUpdatedIterator{contract: _RATFastWithdrawal.contract, event: "BLSPublicKeyUpdated", logs: logs, sub: sub}, nil
}

// WatchBLSPublicKeyUpdated is a free log subscription operation binding the contract event 0x478ede1a0b31e28897a65e0890321b21945ae941c1226813edc126448b158163.
//
// Solidity: event BLSPublicKeyUpdated(address indexed validator, address indexed systemConfig, bytes oldKey, bytes newKey)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) WatchBLSPublicKeyUpdated(opts *bind.WatchOpts, sink chan<- *RATFastWithdrawalBLSPublicKeyUpdated, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.WatchLogs(opts, "BLSPublicKeyUpdated", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATFastWithdrawalBLSPublicKeyUpdated)
				if err := _RATFastWithdrawal.contract.UnpackLog(event, "BLSPublicKeyUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseBLSPublicKeyUpdated is a log parse operation binding the contract event 0x478ede1a0b31e28897a65e0890321b21945ae941c1226813edc126448b158163.
//
// Solidity: event BLSPublicKeyUpdated(address indexed validator, address indexed systemConfig, bytes oldKey, bytes newKey)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) ParseBLSPublicKeyUpdated(log types.Log) (*RATFastWithdrawalBLSPublicKeyUpdated, error) {
	event := new(RATFastWithdrawalBLSPublicKeyUpdated)
	if err := _RATFastWithdrawal.contract.UnpackLog(event, "BLSPublicKeyUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATFastWithdrawalFastWithdrawalExecutedIterator is returned from FilterFastWithdrawalExecuted and is used to iterate over the raw logs and unpacked data for FastWithdrawalExecuted events raised by the RATFastWithdrawal contract.
type RATFastWithdrawalFastWithdrawalExecutedIterator struct {
	Event *RATFastWithdrawalFastWithdrawalExecuted // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RATFastWithdrawalFastWithdrawalExecutedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATFastWithdrawalFastWithdrawalExecuted)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RATFastWithdrawalFastWithdrawalExecuted)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RATFastWithdrawalFastWithdrawalExecutedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATFastWithdrawalFastWithdrawalExecutedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATFastWithdrawalFastWithdrawalExecuted represents a FastWithdrawalExecuted event raised by the RATFastWithdrawal contract.
type RATFastWithdrawalFastWithdrawalExecuted struct {
	WithdrawalHash [32]byte
	User           common.Address
	Amount         *big.Int
	Aggregator     common.Address
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterFastWithdrawalExecuted is a free log retrieval operation binding the contract event 0x1aaa01941956fd91c141031b29c0127102e25e96d19bf17c07e0f27cf1fcc77c.
//
// Solidity: event FastWithdrawalExecuted(bytes32 indexed withdrawalHash, address indexed user, uint256 amount, address indexed aggregator)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) FilterFastWithdrawalExecuted(opts *bind.FilterOpts, withdrawalHash [][32]byte, user []common.Address, aggregator []common.Address) (*RATFastWithdrawalFastWithdrawalExecutedIterator, error) {

	var withdrawalHashRule []interface{}
	for _, withdrawalHashItem := range withdrawalHash {
		withdrawalHashRule = append(withdrawalHashRule, withdrawalHashItem)
	}
	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	var aggregatorRule []interface{}
	for _, aggregatorItem := range aggregator {
		aggregatorRule = append(aggregatorRule, aggregatorItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.FilterLogs(opts, "FastWithdrawalExecuted", withdrawalHashRule, userRule, aggregatorRule)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalFastWithdrawalExecutedIterator{contract: _RATFastWithdrawal.contract, event: "FastWithdrawalExecuted", logs: logs, sub: sub}, nil
}

// WatchFastWithdrawalExecuted is a free log subscription operation binding the contract event 0x1aaa01941956fd91c141031b29c0127102e25e96d19bf17c07e0f27cf1fcc77c.
//
// Solidity: event FastWithdrawalExecuted(bytes32 indexed withdrawalHash, address indexed user, uint256 amount, address indexed aggregator)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) WatchFastWithdrawalExecuted(opts *bind.WatchOpts, sink chan<- *RATFastWithdrawalFastWithdrawalExecuted, withdrawalHash [][32]byte, user []common.Address, aggregator []common.Address) (event.Subscription, error) {

	var withdrawalHashRule []interface{}
	for _, withdrawalHashItem := range withdrawalHash {
		withdrawalHashRule = append(withdrawalHashRule, withdrawalHashItem)
	}
	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	var aggregatorRule []interface{}
	for _, aggregatorItem := range aggregator {
		aggregatorRule = append(aggregatorRule, aggregatorItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.WatchLogs(opts, "FastWithdrawalExecuted", withdrawalHashRule, userRule, aggregatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATFastWithdrawalFastWithdrawalExecuted)
				if err := _RATFastWithdrawal.contract.UnpackLog(event, "FastWithdrawalExecuted", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseFastWithdrawalExecuted is a log parse operation binding the contract event 0x1aaa01941956fd91c141031b29c0127102e25e96d19bf17c07e0f27cf1fcc77c.
//
// Solidity: event FastWithdrawalExecuted(bytes32 indexed withdrawalHash, address indexed user, uint256 amount, address indexed aggregator)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) ParseFastWithdrawalExecuted(log types.Log) (*RATFastWithdrawalFastWithdrawalExecuted, error) {
	event := new(RATFastWithdrawalFastWithdrawalExecuted)
	if err := _RATFastWithdrawal.contract.UnpackLog(event, "FastWithdrawalExecuted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATFastWithdrawalMinValidatorsForFastWithdrawalUpdatedIterator is returned from FilterMinValidatorsForFastWithdrawalUpdated and is used to iterate over the raw logs and unpacked data for MinValidatorsForFastWithdrawalUpdated events raised by the RATFastWithdrawal contract.
type RATFastWithdrawalMinValidatorsForFastWithdrawalUpdatedIterator struct {
	Event *RATFastWithdrawalMinValidatorsForFastWithdrawalUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RATFastWithdrawalMinValidatorsForFastWithdrawalUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATFastWithdrawalMinValidatorsForFastWithdrawalUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RATFastWithdrawalMinValidatorsForFastWithdrawalUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RATFastWithdrawalMinValidatorsForFastWithdrawalUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATFastWithdrawalMinValidatorsForFastWithdrawalUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATFastWithdrawalMinValidatorsForFastWithdrawalUpdated represents a MinValidatorsForFastWithdrawalUpdated event raised by the RATFastWithdrawal contract.
type RATFastWithdrawalMinValidatorsForFastWithdrawalUpdated struct {
	NewMinValidators *big.Int
	Raw              types.Log // Blockchain specific contextual infos
}

// FilterMinValidatorsForFastWithdrawalUpdated is a free log retrieval operation binding the contract event 0x0e39b0a344e72aaf1511b737ab2bd6f482260457ef4361c52fdca7103d9a9381.
//
// Solidity: event MinValidatorsForFastWithdrawalUpdated(uint256 newMinValidators)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) FilterMinValidatorsForFastWithdrawalUpdated(opts *bind.FilterOpts) (*RATFastWithdrawalMinValidatorsForFastWithdrawalUpdatedIterator, error) {

	logs, sub, err := _RATFastWithdrawal.contract.FilterLogs(opts, "MinValidatorsForFastWithdrawalUpdated")
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalMinValidatorsForFastWithdrawalUpdatedIterator{contract: _RATFastWithdrawal.contract, event: "MinValidatorsForFastWithdrawalUpdated", logs: logs, sub: sub}, nil
}

// WatchMinValidatorsForFastWithdrawalUpdated is a free log subscription operation binding the contract event 0x0e39b0a344e72aaf1511b737ab2bd6f482260457ef4361c52fdca7103d9a9381.
//
// Solidity: event MinValidatorsForFastWithdrawalUpdated(uint256 newMinValidators)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) WatchMinValidatorsForFastWithdrawalUpdated(opts *bind.WatchOpts, sink chan<- *RATFastWithdrawalMinValidatorsForFastWithdrawalUpdated) (event.Subscription, error) {

	logs, sub, err := _RATFastWithdrawal.contract.WatchLogs(opts, "MinValidatorsForFastWithdrawalUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATFastWithdrawalMinValidatorsForFastWithdrawalUpdated)
				if err := _RATFastWithdrawal.contract.UnpackLog(event, "MinValidatorsForFastWithdrawalUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMinValidatorsForFastWithdrawalUpdated is a log parse operation binding the contract event 0x0e39b0a344e72aaf1511b737ab2bd6f482260457ef4361c52fdca7103d9a9381.
//
// Solidity: event MinValidatorsForFastWithdrawalUpdated(uint256 newMinValidators)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) ParseMinValidatorsForFastWithdrawalUpdated(log types.Log) (*RATFastWithdrawalMinValidatorsForFastWithdrawalUpdated, error) {
	event := new(RATFastWithdrawalMinValidatorsForFastWithdrawalUpdated)
	if err := _RATFastWithdrawal.contract.UnpackLog(event, "MinValidatorsForFastWithdrawalUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATFastWithdrawalRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the RATFastWithdrawal contract.
type RATFastWithdrawalRoleAdminChangedIterator struct {
	Event *RATFastWithdrawalRoleAdminChanged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RATFastWithdrawalRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATFastWithdrawalRoleAdminChanged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RATFastWithdrawalRoleAdminChanged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RATFastWithdrawalRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATFastWithdrawalRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATFastWithdrawalRoleAdminChanged represents a RoleAdminChanged event raised by the RATFastWithdrawal contract.
type RATFastWithdrawalRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*RATFastWithdrawalRoleAdminChangedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalRoleAdminChangedIterator{contract: _RATFastWithdrawal.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *RATFastWithdrawalRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATFastWithdrawalRoleAdminChanged)
				if err := _RATFastWithdrawal.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleAdminChanged is a log parse operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) ParseRoleAdminChanged(log types.Log) (*RATFastWithdrawalRoleAdminChanged, error) {
	event := new(RATFastWithdrawalRoleAdminChanged)
	if err := _RATFastWithdrawal.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATFastWithdrawalRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the RATFastWithdrawal contract.
type RATFastWithdrawalRoleGrantedIterator struct {
	Event *RATFastWithdrawalRoleGranted // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RATFastWithdrawalRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATFastWithdrawalRoleGranted)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RATFastWithdrawalRoleGranted)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RATFastWithdrawalRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATFastWithdrawalRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATFastWithdrawalRoleGranted represents a RoleGranted event raised by the RATFastWithdrawal contract.
type RATFastWithdrawalRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*RATFastWithdrawalRoleGrantedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalRoleGrantedIterator{contract: _RATFastWithdrawal.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *RATFastWithdrawalRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATFastWithdrawalRoleGranted)
				if err := _RATFastWithdrawal.contract.UnpackLog(event, "RoleGranted", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleGranted is a log parse operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) ParseRoleGranted(log types.Log) (*RATFastWithdrawalRoleGranted, error) {
	event := new(RATFastWithdrawalRoleGranted)
	if err := _RATFastWithdrawal.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATFastWithdrawalRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the RATFastWithdrawal contract.
type RATFastWithdrawalRoleRevokedIterator struct {
	Event *RATFastWithdrawalRoleRevoked // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RATFastWithdrawalRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATFastWithdrawalRoleRevoked)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RATFastWithdrawalRoleRevoked)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RATFastWithdrawalRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATFastWithdrawalRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATFastWithdrawalRoleRevoked represents a RoleRevoked event raised by the RATFastWithdrawal contract.
type RATFastWithdrawalRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*RATFastWithdrawalRoleRevokedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalRoleRevokedIterator{contract: _RATFastWithdrawal.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *RATFastWithdrawalRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _RATFastWithdrawal.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATFastWithdrawalRoleRevoked)
				if err := _RATFastWithdrawal.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleRevoked is a log parse operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) ParseRoleRevoked(log types.Log) (*RATFastWithdrawalRoleRevoked, error) {
	event := new(RATFastWithdrawalRoleRevoked)
	if err := _RATFastWithdrawal.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATFastWithdrawalValidatorRegisteredIterator is returned from FilterValidatorRegistered and is used to iterate over the raw logs and unpacked data for ValidatorRegistered events raised by the RATFastWithdrawal contract.
type RATFastWithdrawalValidatorRegisteredIterator struct {
	Event *RATFastWithdrawalValidatorRegistered // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RATFastWithdrawalValidatorRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATFastWithdrawalValidatorRegistered)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RATFastWithdrawalValidatorRegistered)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RATFastWithdrawalValidatorRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATFastWithdrawalValidatorRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATFastWithdrawalValidatorRegistered represents a ValidatorRegistered event raised by the RATFastWithdrawal contract.
type RATFastWithdrawalValidatorRegistered struct {
	Validator    common.Address
	SystemConfig common.Address
	Layer2       common.Address
	Collateral   *big.Int
	Index        *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterValidatorRegistered is a free log retrieval operation binding the contract event 0x317f78b7f1495be7f160c255693f09ccbd5367aa7acd721aa14eb14308da785c.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, address indexed layer2, uint256 collateral, uint256 index)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) FilterValidatorRegistered(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address, layer2 []common.Address) (*RATFastWithdrawalValidatorRegisteredIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}
	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _RATFastWithdrawal.contract.FilterLogs(opts, "ValidatorRegistered", validatorRule, systemConfigRule, layer2Rule)
	if err != nil {
		return nil, err
	}
	return &RATFastWithdrawalValidatorRegisteredIterator{contract: _RATFastWithdrawal.contract, event: "ValidatorRegistered", logs: logs, sub: sub}, nil
}

// WatchValidatorRegistered is a free log subscription operation binding the contract event 0x317f78b7f1495be7f160c255693f09ccbd5367aa7acd721aa14eb14308da785c.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, address indexed layer2, uint256 collateral, uint256 index)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) WatchValidatorRegistered(opts *bind.WatchOpts, sink chan<- *RATFastWithdrawalValidatorRegistered, validator []common.Address, systemConfig []common.Address, layer2 []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}
	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _RATFastWithdrawal.contract.WatchLogs(opts, "ValidatorRegistered", validatorRule, systemConfigRule, layer2Rule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATFastWithdrawalValidatorRegistered)
				if err := _RATFastWithdrawal.contract.UnpackLog(event, "ValidatorRegistered", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseValidatorRegistered is a log parse operation binding the contract event 0x317f78b7f1495be7f160c255693f09ccbd5367aa7acd721aa14eb14308da785c.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, address indexed layer2, uint256 collateral, uint256 index)
func (_RATFastWithdrawal *RATFastWithdrawalFilterer) ParseValidatorRegistered(log types.Log) (*RATFastWithdrawalValidatorRegistered, error) {
	event := new(RATFastWithdrawalValidatorRegistered)
	if err := _RATFastWithdrawal.contract.UnpackLog(event, "ValidatorRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
