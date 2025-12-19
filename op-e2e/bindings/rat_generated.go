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

// RATABI is the input ABI used to generate the binding from.
const RATABI = "[{\"type\":\"function\",\"name\":\"accumulatedSlashings\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"activeTestCount\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addDeposit\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"attentionCost\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"attentionTests\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"validatorAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"bondAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"authorizedTrigger\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"batchToTestId\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deactivateValidator\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"emergencyWithdraw\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"evidenceSubmissionPeriod\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"factoryByGame\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"gameToTestId\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getActiveValidatorCount\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAttentionTest\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"validatorAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"bondAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getL2Validators\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinimumCollateral\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorCount\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorDeposit\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorRegistration\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"depositedAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalBondForRAT\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validatorIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"isActive\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"_seigManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_wton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_ton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_layer2Manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_owner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isValidatorActive\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1BridgeRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2Manager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minimumThreshold\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"onApprove\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ratTriggerProbability\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"registerValidator\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"depositAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resolveClaim\",\"inputs\":[{\"name\":\"_claimant\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"seigManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setAttentionCost\",\"inputs\":[{\"name\":\"cost\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setAuthorizedTrigger\",\"inputs\":[{\"name\":\"trigger\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setEvidenceSubmissionPeriod\",\"inputs\":[{\"name\":\"period\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setL1BridgeRegistry\",\"inputs\":[{\"name\":\"_l1BridgeRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMinimumThreshold\",\"inputs\":[{\"name\":\"threshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setPaused\",\"inputs\":[{\"name\":\"_paused\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setRatTriggerProbability\",\"inputs\":[{\"name\":\"probability\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSlashingPenalty\",\"inputs\":[{\"name\":\"penalty\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTreasury\",\"inputs\":[{\"name\":\"_treasury\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setValidatorBuffer\",\"inputs\":[{\"name\":\"buffer\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slashingPenalty\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"submitEvidence\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"evidence\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"treasury\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"triggerAttentionTest\",\"inputs\":[{\"name\":\"gameAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"blockHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"validateSlashingPenalty\",\"inputs\":[{\"name\":\"n\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorBuffer\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorIndexes\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorRegistrations\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"depositedAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalBondForRAT\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"pendingRewards\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"latestTestDeadline\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"validatorIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"isActive\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorSystemConfigs\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdrawSlashingsToTreasury\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"wton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"AttentionTestTriggered\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"gameAddress\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"indexed\":false,\"internalType\":\"uint32\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BondRestored\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"restoredAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositAdded\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EvidenceSubmitted\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"indexed\":false,\"internalType\":\"uint32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorDeactivated\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"returnedAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRegistered\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"depositAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"registrationId\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRestored\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorSlashed\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"slashedAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"removedFromSet\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false}]"

// RAT is an auto generated Go binding around an Ethereum contract.
type RAT struct {
	RATCaller     // Read-only binding to the contract
	RATTransactor // Write-only binding to the contract
	RATFilterer   // Log filterer for contract events
}

// RATCaller is an auto generated read-only Go binding around an Ethereum contract.
type RATCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RATTransactor is an auto generated write-only Go binding around an Ethereum contract.
type RATTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RATFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type RATFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RATSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type RATSession struct {
	Contract     *RAT              // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// RATCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type RATCallerSession struct {
	Contract *RATCaller    // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// RATTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type RATTransactorSession struct {
	Contract     *RATTransactor    // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// RATRaw is an auto generated low-level Go binding around an Ethereum contract.
type RATRaw struct {
	Contract *RAT // Generic contract binding to access the raw methods on
}

// RATCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type RATCallerRaw struct {
	Contract *RATCaller // Generic read-only contract binding to access the raw methods on
}

// RATTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type RATTransactorRaw struct {
	Contract *RATTransactor // Generic write-only contract binding to access the raw methods on
}

// NewRAT creates a new instance of RAT, bound to a specific deployed contract.
func NewRAT(address common.Address, backend bind.ContractBackend) (*RAT, error) {
	contract, err := bindRAT(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &RAT{RATCaller: RATCaller{contract: contract}, RATTransactor: RATTransactor{contract: contract}, RATFilterer: RATFilterer{contract: contract}}, nil
}

// NewRATCaller creates a new read-only instance of RAT, bound to a specific deployed contract.
func NewRATCaller(address common.Address, caller bind.ContractCaller) (*RATCaller, error) {
	contract, err := bindRAT(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &RATCaller{contract: contract}, nil
}

// NewRATTransactor creates a new write-only instance of RAT, bound to a specific deployed contract.
func NewRATTransactor(address common.Address, transactor bind.ContractTransactor) (*RATTransactor, error) {
	contract, err := bindRAT(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &RATTransactor{contract: contract}, nil
}

// NewRATFilterer creates a new log filterer instance of RAT, bound to a specific deployed contract.
func NewRATFilterer(address common.Address, filterer bind.ContractFilterer) (*RATFilterer, error) {
	contract, err := bindRAT(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &RATFilterer{contract: contract}, nil
}

// bindRAT binds a generic wrapper to an already deployed contract.
func bindRAT(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(RATABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RAT *RATRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RAT.Contract.RATCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RAT *RATRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RAT.Contract.RATTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RAT *RATRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RAT.Contract.RATTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RAT *RATCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RAT.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RAT *RATTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RAT.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RAT *RATTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RAT.Contract.contract.Transact(opts, method, params...)
}

// AccumulatedSlashings is a free data retrieval call binding the contract method 0xcd156819.
//
// Solidity: function accumulatedSlashings() view returns(uint256)
func (_RAT *RATCaller) AccumulatedSlashings(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "accumulatedSlashings")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AccumulatedSlashings is a free data retrieval call binding the contract method 0xcd156819.
//
// Solidity: function accumulatedSlashings() view returns(uint256)
func (_RAT *RATSession) AccumulatedSlashings() (*big.Int, error) {
	return _RAT.Contract.AccumulatedSlashings(&_RAT.CallOpts)
}

// AccumulatedSlashings is a free data retrieval call binding the contract method 0xcd156819.
//
// Solidity: function accumulatedSlashings() view returns(uint256)
func (_RAT *RATCallerSession) AccumulatedSlashings() (*big.Int, error) {
	return _RAT.Contract.AccumulatedSlashings(&_RAT.CallOpts)
}

// ActiveTestCount is a free data retrieval call binding the contract method 0xcdf7cf13.
//
// Solidity: function activeTestCount(address ) view returns(uint256)
func (_RAT *RATCaller) ActiveTestCount(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "activeTestCount", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ActiveTestCount is a free data retrieval call binding the contract method 0xcdf7cf13.
//
// Solidity: function activeTestCount(address ) view returns(uint256)
func (_RAT *RATSession) ActiveTestCount(arg0 common.Address) (*big.Int, error) {
	return _RAT.Contract.ActiveTestCount(&_RAT.CallOpts, arg0)
}

// ActiveTestCount is a free data retrieval call binding the contract method 0xcdf7cf13.
//
// Solidity: function activeTestCount(address ) view returns(uint256)
func (_RAT *RATCallerSession) ActiveTestCount(arg0 common.Address) (*big.Int, error) {
	return _RAT.Contract.ActiveTestCount(&_RAT.CallOpts, arg0)
}

// AttentionCost is a free data retrieval call binding the contract method 0x2c9e3798.
//
// Solidity: function attentionCost() view returns(uint256)
func (_RAT *RATCaller) AttentionCost(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "attentionCost")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AttentionCost is a free data retrieval call binding the contract method 0x2c9e3798.
//
// Solidity: function attentionCost() view returns(uint256)
func (_RAT *RATSession) AttentionCost() (*big.Int, error) {
	return _RAT.Contract.AttentionCost(&_RAT.CallOpts)
}

// AttentionCost is a free data retrieval call binding the contract method 0x2c9e3798.
//
// Solidity: function attentionCost() view returns(uint256)
func (_RAT *RATCallerSession) AttentionCost() (*big.Int, error) {
	return _RAT.Contract.AttentionCost(&_RAT.CallOpts)
}

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
//
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATCaller) AttentionTests(opts *bind.CallOpts, arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "attentionTests", arg0)

	outstruct := new(struct {
		ValidatorAddress common.Address
		SystemConfig     common.Address
		BatchIndex       uint32
		BatchHash        [32]byte
		BondAmount       *big.Int
		CreatedAt        *big.Int
		Deadline         *big.Int
		Status           uint8
	})

	outstruct.ValidatorAddress = out[0].(common.Address)
	outstruct.SystemConfig = out[1].(common.Address)
	outstruct.BatchIndex = out[2].(uint32)
	outstruct.BatchHash = out[3].([32]byte)
	outstruct.BondAmount = out[4].(*big.Int)
	outstruct.CreatedAt = out[5].(*big.Int)
	outstruct.Deadline = out[6].(*big.Int)
	outstruct.Status = out[7].(uint8)

	return *outstruct, err

}

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
//
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATSession) AttentionTests(arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	return _RAT.Contract.AttentionTests(&_RAT.CallOpts, arg0)
}

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
//
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATCallerSession) AttentionTests(arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	return _RAT.Contract.AttentionTests(&_RAT.CallOpts, arg0)
}

// AuthorizedTrigger is a free data retrieval call binding the contract method 0xe1705cb6.
//
// Solidity: function authorizedTrigger() view returns(address)
func (_RAT *RATCaller) AuthorizedTrigger(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "authorizedTrigger")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// AuthorizedTrigger is a free data retrieval call binding the contract method 0xe1705cb6.
//
// Solidity: function authorizedTrigger() view returns(address)
func (_RAT *RATSession) AuthorizedTrigger() (common.Address, error) {
	return _RAT.Contract.AuthorizedTrigger(&_RAT.CallOpts)
}

// AuthorizedTrigger is a free data retrieval call binding the contract method 0xe1705cb6.
//
// Solidity: function authorizedTrigger() view returns(address)
func (_RAT *RATCallerSession) AuthorizedTrigger() (common.Address, error) {
	return _RAT.Contract.AuthorizedTrigger(&_RAT.CallOpts)
}

// BatchToTestId is a free data retrieval call binding the contract method 0x0bec5691.
//
// Solidity: function batchToTestId(address , uint32 ) view returns(bytes32)
func (_RAT *RATCaller) BatchToTestId(opts *bind.CallOpts, arg0 common.Address, arg1 uint32) ([32]byte, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "batchToTestId", arg0, arg1)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// BatchToTestId is a free data retrieval call binding the contract method 0x0bec5691.
//
// Solidity: function batchToTestId(address , uint32 ) view returns(bytes32)
func (_RAT *RATSession) BatchToTestId(arg0 common.Address, arg1 uint32) ([32]byte, error) {
	return _RAT.Contract.BatchToTestId(&_RAT.CallOpts, arg0, arg1)
}

// BatchToTestId is a free data retrieval call binding the contract method 0x0bec5691.
//
// Solidity: function batchToTestId(address , uint32 ) view returns(bytes32)
func (_RAT *RATCallerSession) BatchToTestId(arg0 common.Address, arg1 uint32) ([32]byte, error) {
	return _RAT.Contract.BatchToTestId(&_RAT.CallOpts, arg0, arg1)
}

// EvidenceSubmissionPeriod is a free data retrieval call binding the contract method 0xacccb08f.
//
// Solidity: function evidenceSubmissionPeriod() view returns(uint256)
func (_RAT *RATCaller) EvidenceSubmissionPeriod(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "evidenceSubmissionPeriod")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// EvidenceSubmissionPeriod is a free data retrieval call binding the contract method 0xacccb08f.
//
// Solidity: function evidenceSubmissionPeriod() view returns(uint256)
func (_RAT *RATSession) EvidenceSubmissionPeriod() (*big.Int, error) {
	return _RAT.Contract.EvidenceSubmissionPeriod(&_RAT.CallOpts)
}

// EvidenceSubmissionPeriod is a free data retrieval call binding the contract method 0xacccb08f.
//
// Solidity: function evidenceSubmissionPeriod() view returns(uint256)
func (_RAT *RATCallerSession) EvidenceSubmissionPeriod() (*big.Int, error) {
	return _RAT.Contract.EvidenceSubmissionPeriod(&_RAT.CallOpts)
}

// FactoryByGame is a free data retrieval call binding the contract method 0x62592433.
//
// Solidity: function factoryByGame(address ) view returns(address)
func (_RAT *RATCaller) FactoryByGame(opts *bind.CallOpts, arg0 common.Address) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "factoryByGame", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// FactoryByGame is a free data retrieval call binding the contract method 0x62592433.
//
// Solidity: function factoryByGame(address ) view returns(address)
func (_RAT *RATSession) FactoryByGame(arg0 common.Address) (common.Address, error) {
	return _RAT.Contract.FactoryByGame(&_RAT.CallOpts, arg0)
}

// FactoryByGame is a free data retrieval call binding the contract method 0x62592433.
//
// Solidity: function factoryByGame(address ) view returns(address)
func (_RAT *RATCallerSession) FactoryByGame(arg0 common.Address) (common.Address, error) {
	return _RAT.Contract.FactoryByGame(&_RAT.CallOpts, arg0)
}

// GameToTestId is a free data retrieval call binding the contract method 0xddef8e85.
//
// Solidity: function gameToTestId(address ) view returns(bytes32)
func (_RAT *RATCaller) GameToTestId(opts *bind.CallOpts, arg0 common.Address) ([32]byte, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "gameToTestId", arg0)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GameToTestId is a free data retrieval call binding the contract method 0xddef8e85.
//
// Solidity: function gameToTestId(address ) view returns(bytes32)
func (_RAT *RATSession) GameToTestId(arg0 common.Address) ([32]byte, error) {
	return _RAT.Contract.GameToTestId(&_RAT.CallOpts, arg0)
}

// GameToTestId is a free data retrieval call binding the contract method 0xddef8e85.
//
// Solidity: function gameToTestId(address ) view returns(bytes32)
func (_RAT *RATCallerSession) GameToTestId(arg0 common.Address) ([32]byte, error) {
	return _RAT.Contract.GameToTestId(&_RAT.CallOpts, arg0)
}

// GetActiveValidatorCount is a free data retrieval call binding the contract method 0x2d6f4969.
//
// Solidity: function getActiveValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetActiveValidatorCount(opts *bind.CallOpts, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getActiveValidatorCount", systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetActiveValidatorCount is a free data retrieval call binding the contract method 0x2d6f4969.
//
// Solidity: function getActiveValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetActiveValidatorCount(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetActiveValidatorCount(&_RAT.CallOpts, systemConfig)
}

// GetActiveValidatorCount is a free data retrieval call binding the contract method 0x2d6f4969.
//
// Solidity: function getActiveValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetActiveValidatorCount(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetActiveValidatorCount(&_RAT.CallOpts, systemConfig)
}

// GetAttentionTest is a free data retrieval call binding the contract method 0x4eecc645.
//
// Solidity: function getAttentionTest(bytes32 testId) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATCaller) GetAttentionTest(opts *bind.CallOpts, testId [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getAttentionTest", testId)

	outstruct := new(struct {
		ValidatorAddress common.Address
		SystemConfig     common.Address
		BatchIndex       uint32
		BatchHash        [32]byte
		BondAmount       *big.Int
		CreatedAt        *big.Int
		Deadline         *big.Int
		Status           uint8
	})

	outstruct.ValidatorAddress = out[0].(common.Address)
	outstruct.SystemConfig = out[1].(common.Address)
	outstruct.BatchIndex = out[2].(uint32)
	outstruct.BatchHash = out[3].([32]byte)
	outstruct.BondAmount = out[4].(*big.Int)
	outstruct.CreatedAt = out[5].(*big.Int)
	outstruct.Deadline = out[6].(*big.Int)
	outstruct.Status = out[7].(uint8)

	return *outstruct, err

}

// GetAttentionTest is a free data retrieval call binding the contract method 0x4eecc645.
//
// Solidity: function getAttentionTest(bytes32 testId) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATSession) GetAttentionTest(testId [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	return _RAT.Contract.GetAttentionTest(&_RAT.CallOpts, testId)
}

// GetAttentionTest is a free data retrieval call binding the contract method 0x4eecc645.
//
// Solidity: function getAttentionTest(bytes32 testId) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATCallerSession) GetAttentionTest(testId [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	return _RAT.Contract.GetAttentionTest(&_RAT.CallOpts, testId)
}

// GetL2Validators is a free data retrieval call binding the contract method 0x068c2e6e.
//
// Solidity: function getL2Validators(address systemConfig) view returns(address[])
func (_RAT *RATCaller) GetL2Validators(opts *bind.CallOpts, systemConfig common.Address) ([]common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getL2Validators", systemConfig)

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetL2Validators is a free data retrieval call binding the contract method 0x068c2e6e.
//
// Solidity: function getL2Validators(address systemConfig) view returns(address[])
func (_RAT *RATSession) GetL2Validators(systemConfig common.Address) ([]common.Address, error) {
	return _RAT.Contract.GetL2Validators(&_RAT.CallOpts, systemConfig)
}

// GetL2Validators is a free data retrieval call binding the contract method 0x068c2e6e.
//
// Solidity: function getL2Validators(address systemConfig) view returns(address[])
func (_RAT *RATCallerSession) GetL2Validators(systemConfig common.Address) ([]common.Address, error) {
	return _RAT.Contract.GetL2Validators(&_RAT.CallOpts, systemConfig)
}

// GetMinimumCollateral is a free data retrieval call binding the contract method 0xd8c0ba59.
//
// Solidity: function getMinimumCollateral() view returns(uint256)
func (_RAT *RATCaller) GetMinimumCollateral(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getMinimumCollateral")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMinimumCollateral is a free data retrieval call binding the contract method 0xd8c0ba59.
//
// Solidity: function getMinimumCollateral() view returns(uint256)
func (_RAT *RATSession) GetMinimumCollateral() (*big.Int, error) {
	return _RAT.Contract.GetMinimumCollateral(&_RAT.CallOpts)
}

// GetMinimumCollateral is a free data retrieval call binding the contract method 0xd8c0ba59.
//
// Solidity: function getMinimumCollateral() view returns(uint256)
func (_RAT *RATCallerSession) GetMinimumCollateral() (*big.Int, error) {
	return _RAT.Contract.GetMinimumCollateral(&_RAT.CallOpts)
}

// GetValidatorCount is a free data retrieval call binding the contract method 0xf9560e45.
//
// Solidity: function getValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetValidatorCount(opts *bind.CallOpts, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getValidatorCount", systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetValidatorCount is a free data retrieval call binding the contract method 0xf9560e45.
//
// Solidity: function getValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetValidatorCount(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetValidatorCount(&_RAT.CallOpts, systemConfig)
}

// GetValidatorCount is a free data retrieval call binding the contract method 0xf9560e45.
//
// Solidity: function getValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetValidatorCount(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetValidatorCount(&_RAT.CallOpts, systemConfig)
}

// GetValidatorDeposit is a free data retrieval call binding the contract method 0x39b62bd1.
//
// Solidity: function getValidatorDeposit(address validator, address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetValidatorDeposit(opts *bind.CallOpts, validator common.Address, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getValidatorDeposit", validator, systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetValidatorDeposit is a free data retrieval call binding the contract method 0x39b62bd1.
//
// Solidity: function getValidatorDeposit(address validator, address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetValidatorDeposit(validator common.Address, systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetValidatorDeposit(&_RAT.CallOpts, validator, systemConfig)
}

// GetValidatorDeposit is a free data retrieval call binding the contract method 0x39b62bd1.
//
// Solidity: function getValidatorDeposit(address validator, address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetValidatorDeposit(validator common.Address, systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetValidatorDeposit(&_RAT.CallOpts, validator, systemConfig)
}

// GetValidatorRegistration is a free data retrieval call binding the contract method 0xf92879db.
//
// Solidity: function getValidatorRegistration(address validator, address systemConfig) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint32 validatorIndex, bool isActive)
func (_RAT *RATCaller) GetValidatorRegistration(opts *bind.CallOpts, validator common.Address, systemConfig common.Address) (struct {
	DepositedAmount *big.Int
	TotalBondForRAT *big.Int
	ValidatorIndex  uint32
	IsActive        bool
}, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getValidatorRegistration", validator, systemConfig)

	outstruct := new(struct {
		DepositedAmount *big.Int
		TotalBondForRAT *big.Int
		ValidatorIndex  uint32
		IsActive        bool
	})

	outstruct.DepositedAmount = out[0].(*big.Int)
	outstruct.TotalBondForRAT = out[1].(*big.Int)
	outstruct.ValidatorIndex = out[2].(uint32)
	outstruct.IsActive = out[3].(bool)

	return *outstruct, err

}

// GetValidatorRegistration is a free data retrieval call binding the contract method 0xf92879db.
//
// Solidity: function getValidatorRegistration(address validator, address systemConfig) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint32 validatorIndex, bool isActive)
func (_RAT *RATSession) GetValidatorRegistration(validator common.Address, systemConfig common.Address) (struct {
	DepositedAmount *big.Int
	TotalBondForRAT *big.Int
	ValidatorIndex  uint32
	IsActive        bool
}, error) {
	return _RAT.Contract.GetValidatorRegistration(&_RAT.CallOpts, validator, systemConfig)
}

// GetValidatorRegistration is a free data retrieval call binding the contract method 0xf92879db.
//
// Solidity: function getValidatorRegistration(address validator, address systemConfig) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint32 validatorIndex, bool isActive)
func (_RAT *RATCallerSession) GetValidatorRegistration(validator common.Address, systemConfig common.Address) (struct {
	DepositedAmount *big.Int
	TotalBondForRAT *big.Int
	ValidatorIndex  uint32
	IsActive        bool
}, error) {
	return _RAT.Contract.GetValidatorRegistration(&_RAT.CallOpts, validator, systemConfig)
}

// IsValidatorActive is a free data retrieval call binding the contract method 0x03225879.
//
// Solidity: function isValidatorActive(address validator, address systemConfig) view returns(bool)
func (_RAT *RATCaller) IsValidatorActive(opts *bind.CallOpts, validator common.Address, systemConfig common.Address) (bool, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "isValidatorActive", validator, systemConfig)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsValidatorActive is a free data retrieval call binding the contract method 0x03225879.
//
// Solidity: function isValidatorActive(address validator, address systemConfig) view returns(bool)
func (_RAT *RATSession) IsValidatorActive(validator common.Address, systemConfig common.Address) (bool, error) {
	return _RAT.Contract.IsValidatorActive(&_RAT.CallOpts, validator, systemConfig)
}

// IsValidatorActive is a free data retrieval call binding the contract method 0x03225879.
//
// Solidity: function isValidatorActive(address validator, address systemConfig) view returns(bool)
func (_RAT *RATCallerSession) IsValidatorActive(validator common.Address, systemConfig common.Address) (bool, error) {
	return _RAT.Contract.IsValidatorActive(&_RAT.CallOpts, validator, systemConfig)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_RAT *RATCaller) L1BridgeRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "l1BridgeRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_RAT *RATSession) L1BridgeRegistry() (common.Address, error) {
	return _RAT.Contract.L1BridgeRegistry(&_RAT.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_RAT *RATCallerSession) L1BridgeRegistry() (common.Address, error) {
	return _RAT.Contract.L1BridgeRegistry(&_RAT.CallOpts)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_RAT *RATCaller) Layer2Manager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "layer2Manager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_RAT *RATSession) Layer2Manager() (common.Address, error) {
	return _RAT.Contract.Layer2Manager(&_RAT.CallOpts)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_RAT *RATCallerSession) Layer2Manager() (common.Address, error) {
	return _RAT.Contract.Layer2Manager(&_RAT.CallOpts)
}

// MinimumThreshold is a free data retrieval call binding the contract method 0x75da30d0.
//
// Solidity: function minimumThreshold() view returns(uint256)
func (_RAT *RATCaller) MinimumThreshold(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "minimumThreshold")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MinimumThreshold is a free data retrieval call binding the contract method 0x75da30d0.
//
// Solidity: function minimumThreshold() view returns(uint256)
func (_RAT *RATSession) MinimumThreshold() (*big.Int, error) {
	return _RAT.Contract.MinimumThreshold(&_RAT.CallOpts)
}

// MinimumThreshold is a free data retrieval call binding the contract method 0x75da30d0.
//
// Solidity: function minimumThreshold() view returns(uint256)
func (_RAT *RATCallerSession) MinimumThreshold() (*big.Int, error) {
	return _RAT.Contract.MinimumThreshold(&_RAT.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_RAT *RATCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_RAT *RATSession) Owner() (common.Address, error) {
	return _RAT.Contract.Owner(&_RAT.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_RAT *RATCallerSession) Owner() (common.Address, error) {
	return _RAT.Contract.Owner(&_RAT.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_RAT *RATCaller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_RAT *RATSession) Paused() (bool, error) {
	return _RAT.Contract.Paused(&_RAT.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_RAT *RATCallerSession) Paused() (bool, error) {
	return _RAT.Contract.Paused(&_RAT.CallOpts)
}

// RatTriggerProbability is a free data retrieval call binding the contract method 0x51567bc2.
//
// Solidity: function ratTriggerProbability() view returns(uint256)
func (_RAT *RATCaller) RatTriggerProbability(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "ratTriggerProbability")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// RatTriggerProbability is a free data retrieval call binding the contract method 0x51567bc2.
//
// Solidity: function ratTriggerProbability() view returns(uint256)
func (_RAT *RATSession) RatTriggerProbability() (*big.Int, error) {
	return _RAT.Contract.RatTriggerProbability(&_RAT.CallOpts)
}

// RatTriggerProbability is a free data retrieval call binding the contract method 0x51567bc2.
//
// Solidity: function ratTriggerProbability() view returns(uint256)
func (_RAT *RATCallerSession) RatTriggerProbability() (*big.Int, error) {
	return _RAT.Contract.RatTriggerProbability(&_RAT.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_RAT *RATCaller) SeigManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "seigManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_RAT *RATSession) SeigManager() (common.Address, error) {
	return _RAT.Contract.SeigManager(&_RAT.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_RAT *RATCallerSession) SeigManager() (common.Address, error) {
	return _RAT.Contract.SeigManager(&_RAT.CallOpts)
}

// SlashingPenalty is a free data retrieval call binding the contract method 0x89f1ea64.
//
// Solidity: function slashingPenalty() view returns(uint256)
func (_RAT *RATCaller) SlashingPenalty(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "slashingPenalty")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// SlashingPenalty is a free data retrieval call binding the contract method 0x89f1ea64.
//
// Solidity: function slashingPenalty() view returns(uint256)
func (_RAT *RATSession) SlashingPenalty() (*big.Int, error) {
	return _RAT.Contract.SlashingPenalty(&_RAT.CallOpts)
}

// SlashingPenalty is a free data retrieval call binding the contract method 0x89f1ea64.
//
// Solidity: function slashingPenalty() view returns(uint256)
func (_RAT *RATCallerSession) SlashingPenalty() (*big.Int, error) {
	return _RAT.Contract.SlashingPenalty(&_RAT.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_RAT *RATCaller) Ton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "ton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_RAT *RATSession) Ton() (common.Address, error) {
	return _RAT.Contract.Ton(&_RAT.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_RAT *RATCallerSession) Ton() (common.Address, error) {
	return _RAT.Contract.Ton(&_RAT.CallOpts)
}

// Treasury is a free data retrieval call binding the contract method 0x61d027b3.
//
// Solidity: function treasury() view returns(address)
func (_RAT *RATCaller) Treasury(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "treasury")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Treasury is a free data retrieval call binding the contract method 0x61d027b3.
//
// Solidity: function treasury() view returns(address)
func (_RAT *RATSession) Treasury() (common.Address, error) {
	return _RAT.Contract.Treasury(&_RAT.CallOpts)
}

// Treasury is a free data retrieval call binding the contract method 0x61d027b3.
//
// Solidity: function treasury() view returns(address)
func (_RAT *RATCallerSession) Treasury() (common.Address, error) {
	return _RAT.Contract.Treasury(&_RAT.CallOpts)
}

// ValidateSlashingPenalty is a free data retrieval call binding the contract method 0xd0d6b9b5.
//
// Solidity: function validateSlashingPenalty(uint256 n) view returns(bool)
func (_RAT *RATCaller) ValidateSlashingPenalty(opts *bind.CallOpts, n *big.Int) (bool, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validateSlashingPenalty", n)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ValidateSlashingPenalty is a free data retrieval call binding the contract method 0xd0d6b9b5.
//
// Solidity: function validateSlashingPenalty(uint256 n) view returns(bool)
func (_RAT *RATSession) ValidateSlashingPenalty(n *big.Int) (bool, error) {
	return _RAT.Contract.ValidateSlashingPenalty(&_RAT.CallOpts, n)
}

// ValidateSlashingPenalty is a free data retrieval call binding the contract method 0xd0d6b9b5.
//
// Solidity: function validateSlashingPenalty(uint256 n) view returns(bool)
func (_RAT *RATCallerSession) ValidateSlashingPenalty(n *big.Int) (bool, error) {
	return _RAT.Contract.ValidateSlashingPenalty(&_RAT.CallOpts, n)
}

// ValidatorBuffer is a free data retrieval call binding the contract method 0xf7107b44.
//
// Solidity: function validatorBuffer() view returns(uint256)
func (_RAT *RATCaller) ValidatorBuffer(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validatorBuffer")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ValidatorBuffer is a free data retrieval call binding the contract method 0xf7107b44.
//
// Solidity: function validatorBuffer() view returns(uint256)
func (_RAT *RATSession) ValidatorBuffer() (*big.Int, error) {
	return _RAT.Contract.ValidatorBuffer(&_RAT.CallOpts)
}

// ValidatorBuffer is a free data retrieval call binding the contract method 0xf7107b44.
//
// Solidity: function validatorBuffer() view returns(uint256)
func (_RAT *RATCallerSession) ValidatorBuffer() (*big.Int, error) {
	return _RAT.Contract.ValidatorBuffer(&_RAT.CallOpts)
}

// ValidatorIndexes is a free data retrieval call binding the contract method 0x4e4a9a1b.
//
// Solidity: function validatorIndexes(address , address ) view returns(uint256)
func (_RAT *RATCaller) ValidatorIndexes(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validatorIndexes", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ValidatorIndexes is a free data retrieval call binding the contract method 0x4e4a9a1b.
//
// Solidity: function validatorIndexes(address , address ) view returns(uint256)
func (_RAT *RATSession) ValidatorIndexes(arg0 common.Address, arg1 common.Address) (*big.Int, error) {
	return _RAT.Contract.ValidatorIndexes(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorIndexes is a free data retrieval call binding the contract method 0x4e4a9a1b.
//
// Solidity: function validatorIndexes(address , address ) view returns(uint256)
func (_RAT *RATCallerSession) ValidatorIndexes(arg0 common.Address, arg1 common.Address) (*big.Int, error) {
	return _RAT.Contract.ValidatorIndexes(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive)
func (_RAT *RATCaller) ValidatorRegistrations(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address) (struct {
	DepositedAmount    *big.Int
	TotalBondForRAT    *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
}, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validatorRegistrations", arg0, arg1)

	outstruct := new(struct {
		DepositedAmount    *big.Int
		TotalBondForRAT    *big.Int
		PendingRewards     *big.Int
		LatestTestDeadline uint64
		ValidatorIndex     uint32
		IsActive           bool
	})

	outstruct.DepositedAmount = out[0].(*big.Int)
	outstruct.TotalBondForRAT = out[1].(*big.Int)
	outstruct.PendingRewards = out[2].(*big.Int)
	outstruct.LatestTestDeadline = out[3].(uint64)
	outstruct.ValidatorIndex = out[4].(uint32)
	outstruct.IsActive = out[5].(bool)

	return *outstruct, err

}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive)
func (_RAT *RATSession) ValidatorRegistrations(arg0 common.Address, arg1 common.Address) (struct {
	DepositedAmount    *big.Int
	TotalBondForRAT    *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
}, error) {
	return _RAT.Contract.ValidatorRegistrations(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive)
func (_RAT *RATCallerSession) ValidatorRegistrations(arg0 common.Address, arg1 common.Address) (struct {
	DepositedAmount    *big.Int
	TotalBondForRAT    *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
}, error) {
	return _RAT.Contract.ValidatorRegistrations(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorSystemConfigs is a free data retrieval call binding the contract method 0x8dc3b28e.
//
// Solidity: function validatorSystemConfigs(address , uint256 ) view returns(address)
func (_RAT *RATCaller) ValidatorSystemConfigs(opts *bind.CallOpts, arg0 common.Address, arg1 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validatorSystemConfigs", arg0, arg1)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ValidatorSystemConfigs is a free data retrieval call binding the contract method 0x8dc3b28e.
//
// Solidity: function validatorSystemConfigs(address , uint256 ) view returns(address)
func (_RAT *RATSession) ValidatorSystemConfigs(arg0 common.Address, arg1 *big.Int) (common.Address, error) {
	return _RAT.Contract.ValidatorSystemConfigs(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorSystemConfigs is a free data retrieval call binding the contract method 0x8dc3b28e.
//
// Solidity: function validatorSystemConfigs(address , uint256 ) view returns(address)
func (_RAT *RATCallerSession) ValidatorSystemConfigs(arg0 common.Address, arg1 *big.Int) (common.Address, error) {
	return _RAT.Contract.ValidatorSystemConfigs(&_RAT.CallOpts, arg0, arg1)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_RAT *RATCaller) Wton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "wton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_RAT *RATSession) Wton() (common.Address, error) {
	return _RAT.Contract.Wton(&_RAT.CallOpts)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_RAT *RATCallerSession) Wton() (common.Address, error) {
	return _RAT.Contract.Wton(&_RAT.CallOpts)
}

// AddDeposit is a paid mutator transaction binding the contract method 0x33026bb6.
//
// Solidity: function addDeposit(address systemConfig, uint256 amount) returns()
func (_RAT *RATTransactor) AddDeposit(opts *bind.TransactOpts, systemConfig common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "addDeposit", systemConfig, amount)
}

// AddDeposit is a paid mutator transaction binding the contract method 0x33026bb6.
//
// Solidity: function addDeposit(address systemConfig, uint256 amount) returns()
func (_RAT *RATSession) AddDeposit(systemConfig common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.AddDeposit(&_RAT.TransactOpts, systemConfig, amount)
}

// AddDeposit is a paid mutator transaction binding the contract method 0x33026bb6.
//
// Solidity: function addDeposit(address systemConfig, uint256 amount) returns()
func (_RAT *RATTransactorSession) AddDeposit(systemConfig common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.AddDeposit(&_RAT.TransactOpts, systemConfig, amount)
}

// DeactivateValidator is a paid mutator transaction binding the contract method 0xba50b879.
//
// Solidity: function deactivateValidator(address systemConfig) returns()
func (_RAT *RATTransactor) DeactivateValidator(opts *bind.TransactOpts, systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "deactivateValidator", systemConfig)
}

// DeactivateValidator is a paid mutator transaction binding the contract method 0xba50b879.
//
// Solidity: function deactivateValidator(address systemConfig) returns()
func (_RAT *RATSession) DeactivateValidator(systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.Contract.DeactivateValidator(&_RAT.TransactOpts, systemConfig)
}

// DeactivateValidator is a paid mutator transaction binding the contract method 0xba50b879.
//
// Solidity: function deactivateValidator(address systemConfig) returns()
func (_RAT *RATTransactorSession) DeactivateValidator(systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.Contract.DeactivateValidator(&_RAT.TransactOpts, systemConfig)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address token, uint256 amount) returns()
func (_RAT *RATTransactor) EmergencyWithdraw(opts *bind.TransactOpts, token common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "emergencyWithdraw", token, amount)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address token, uint256 amount) returns()
func (_RAT *RATSession) EmergencyWithdraw(token common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.EmergencyWithdraw(&_RAT.TransactOpts, token, amount)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address token, uint256 amount) returns()
func (_RAT *RATTransactorSession) EmergencyWithdraw(token common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.EmergencyWithdraw(&_RAT.TransactOpts, token, amount)
}

// Initialize is a paid mutator transaction binding the contract method 0x1459457a.
//
// Solidity: function initialize(address _seigManager, address _wton, address _ton, address _layer2Manager, address _owner) returns()
func (_RAT *RATTransactor) Initialize(opts *bind.TransactOpts, _seigManager common.Address, _wton common.Address, _ton common.Address, _layer2Manager common.Address, _owner common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "initialize", _seigManager, _wton, _ton, _layer2Manager, _owner)
}

// Initialize is a paid mutator transaction binding the contract method 0x1459457a.
//
// Solidity: function initialize(address _seigManager, address _wton, address _ton, address _layer2Manager, address _owner) returns()
func (_RAT *RATSession) Initialize(_seigManager common.Address, _wton common.Address, _ton common.Address, _layer2Manager common.Address, _owner common.Address) (*types.Transaction, error) {
	return _RAT.Contract.Initialize(&_RAT.TransactOpts, _seigManager, _wton, _ton, _layer2Manager, _owner)
}

// Initialize is a paid mutator transaction binding the contract method 0x1459457a.
//
// Solidity: function initialize(address _seigManager, address _wton, address _ton, address _layer2Manager, address _owner) returns()
func (_RAT *RATTransactorSession) Initialize(_seigManager common.Address, _wton common.Address, _ton common.Address, _layer2Manager common.Address, _owner common.Address) (*types.Transaction, error) {
	return _RAT.Contract.Initialize(&_RAT.TransactOpts, _seigManager, _wton, _ton, _layer2Manager, _owner)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_RAT *RATTransactor) OnApprove(opts *bind.TransactOpts, owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "onApprove", owner, spender, amount, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_RAT *RATSession) OnApprove(owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _RAT.Contract.OnApprove(&_RAT.TransactOpts, owner, spender, amount, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_RAT *RATTransactorSession) OnApprove(owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _RAT.Contract.OnApprove(&_RAT.TransactOpts, owner, spender, amount, data)
}

// RegisterValidator is a paid mutator transaction binding the contract method 0x9abee7d0.
//
// Solidity: function registerValidator(address systemConfig, uint256 depositAmount) returns()
func (_RAT *RATTransactor) RegisterValidator(opts *bind.TransactOpts, systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "registerValidator", systemConfig, depositAmount)
}

// RegisterValidator is a paid mutator transaction binding the contract method 0x9abee7d0.
//
// Solidity: function registerValidator(address systemConfig, uint256 depositAmount) returns()
func (_RAT *RATSession) RegisterValidator(systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.RegisterValidator(&_RAT.TransactOpts, systemConfig, depositAmount)
}

// RegisterValidator is a paid mutator transaction binding the contract method 0x9abee7d0.
//
// Solidity: function registerValidator(address systemConfig, uint256 depositAmount) returns()
func (_RAT *RATTransactorSession) RegisterValidator(systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.RegisterValidator(&_RAT.TransactOpts, systemConfig, depositAmount)
}

// ResolveClaim is a paid mutator transaction binding the contract method 0x94d645a8.
//
// Solidity: function resolveClaim(address _claimant) returns()
func (_RAT *RATTransactor) ResolveClaim(opts *bind.TransactOpts, _claimant common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "resolveClaim", _claimant)
}

// ResolveClaim is a paid mutator transaction binding the contract method 0x94d645a8.
//
// Solidity: function resolveClaim(address _claimant) returns()
func (_RAT *RATSession) ResolveClaim(_claimant common.Address) (*types.Transaction, error) {
	return _RAT.Contract.ResolveClaim(&_RAT.TransactOpts, _claimant)
}

// ResolveClaim is a paid mutator transaction binding the contract method 0x94d645a8.
//
// Solidity: function resolveClaim(address _claimant) returns()
func (_RAT *RATTransactorSession) ResolveClaim(_claimant common.Address) (*types.Transaction, error) {
	return _RAT.Contract.ResolveClaim(&_RAT.TransactOpts, _claimant)
}

// SetAttentionCost is a paid mutator transaction binding the contract method 0xc0a08bde.
//
// Solidity: function setAttentionCost(uint256 cost) returns()
func (_RAT *RATTransactor) SetAttentionCost(opts *bind.TransactOpts, cost *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setAttentionCost", cost)
}

// SetAttentionCost is a paid mutator transaction binding the contract method 0xc0a08bde.
//
// Solidity: function setAttentionCost(uint256 cost) returns()
func (_RAT *RATSession) SetAttentionCost(cost *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetAttentionCost(&_RAT.TransactOpts, cost)
}

// SetAttentionCost is a paid mutator transaction binding the contract method 0xc0a08bde.
//
// Solidity: function setAttentionCost(uint256 cost) returns()
func (_RAT *RATTransactorSession) SetAttentionCost(cost *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetAttentionCost(&_RAT.TransactOpts, cost)
}

// SetAuthorizedTrigger is a paid mutator transaction binding the contract method 0x370e9e18.
//
// Solidity: function setAuthorizedTrigger(address trigger) returns()
func (_RAT *RATTransactor) SetAuthorizedTrigger(opts *bind.TransactOpts, trigger common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setAuthorizedTrigger", trigger)
}

// SetAuthorizedTrigger is a paid mutator transaction binding the contract method 0x370e9e18.
//
// Solidity: function setAuthorizedTrigger(address trigger) returns()
func (_RAT *RATSession) SetAuthorizedTrigger(trigger common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetAuthorizedTrigger(&_RAT.TransactOpts, trigger)
}

// SetAuthorizedTrigger is a paid mutator transaction binding the contract method 0x370e9e18.
//
// Solidity: function setAuthorizedTrigger(address trigger) returns()
func (_RAT *RATTransactorSession) SetAuthorizedTrigger(trigger common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetAuthorizedTrigger(&_RAT.TransactOpts, trigger)
}

// SetEvidenceSubmissionPeriod is a paid mutator transaction binding the contract method 0x36c63d46.
//
// Solidity: function setEvidenceSubmissionPeriod(uint256 period) returns()
func (_RAT *RATTransactor) SetEvidenceSubmissionPeriod(opts *bind.TransactOpts, period *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setEvidenceSubmissionPeriod", period)
}

// SetEvidenceSubmissionPeriod is a paid mutator transaction binding the contract method 0x36c63d46.
//
// Solidity: function setEvidenceSubmissionPeriod(uint256 period) returns()
func (_RAT *RATSession) SetEvidenceSubmissionPeriod(period *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetEvidenceSubmissionPeriod(&_RAT.TransactOpts, period)
}

// SetEvidenceSubmissionPeriod is a paid mutator transaction binding the contract method 0x36c63d46.
//
// Solidity: function setEvidenceSubmissionPeriod(uint256 period) returns()
func (_RAT *RATTransactorSession) SetEvidenceSubmissionPeriod(period *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetEvidenceSubmissionPeriod(&_RAT.TransactOpts, period)
}

// SetL1BridgeRegistry is a paid mutator transaction binding the contract method 0x0c1da8df.
//
// Solidity: function setL1BridgeRegistry(address _l1BridgeRegistry) returns()
func (_RAT *RATTransactor) SetL1BridgeRegistry(opts *bind.TransactOpts, _l1BridgeRegistry common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setL1BridgeRegistry", _l1BridgeRegistry)
}

// SetL1BridgeRegistry is a paid mutator transaction binding the contract method 0x0c1da8df.
//
// Solidity: function setL1BridgeRegistry(address _l1BridgeRegistry) returns()
func (_RAT *RATSession) SetL1BridgeRegistry(_l1BridgeRegistry common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetL1BridgeRegistry(&_RAT.TransactOpts, _l1BridgeRegistry)
}

// SetL1BridgeRegistry is a paid mutator transaction binding the contract method 0x0c1da8df.
//
// Solidity: function setL1BridgeRegistry(address _l1BridgeRegistry) returns()
func (_RAT *RATTransactorSession) SetL1BridgeRegistry(_l1BridgeRegistry common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetL1BridgeRegistry(&_RAT.TransactOpts, _l1BridgeRegistry)
}

// SetMinimumThreshold is a paid mutator transaction binding the contract method 0x67058d29.
//
// Solidity: function setMinimumThreshold(uint256 threshold) returns()
func (_RAT *RATTransactor) SetMinimumThreshold(opts *bind.TransactOpts, threshold *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setMinimumThreshold", threshold)
}

// SetMinimumThreshold is a paid mutator transaction binding the contract method 0x67058d29.
//
// Solidity: function setMinimumThreshold(uint256 threshold) returns()
func (_RAT *RATSession) SetMinimumThreshold(threshold *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetMinimumThreshold(&_RAT.TransactOpts, threshold)
}

// SetMinimumThreshold is a paid mutator transaction binding the contract method 0x67058d29.
//
// Solidity: function setMinimumThreshold(uint256 threshold) returns()
func (_RAT *RATTransactorSession) SetMinimumThreshold(threshold *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetMinimumThreshold(&_RAT.TransactOpts, threshold)
}

// SetPaused is a paid mutator transaction binding the contract method 0x16c38b3c.
//
// Solidity: function setPaused(bool _paused) returns()
func (_RAT *RATTransactor) SetPaused(opts *bind.TransactOpts, _paused bool) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setPaused", _paused)
}

// SetPaused is a paid mutator transaction binding the contract method 0x16c38b3c.
//
// Solidity: function setPaused(bool _paused) returns()
func (_RAT *RATSession) SetPaused(_paused bool) (*types.Transaction, error) {
	return _RAT.Contract.SetPaused(&_RAT.TransactOpts, _paused)
}

// SetPaused is a paid mutator transaction binding the contract method 0x16c38b3c.
//
// Solidity: function setPaused(bool _paused) returns()
func (_RAT *RATTransactorSession) SetPaused(_paused bool) (*types.Transaction, error) {
	return _RAT.Contract.SetPaused(&_RAT.TransactOpts, _paused)
}

// SetRatTriggerProbability is a paid mutator transaction binding the contract method 0xd2e5bc72.
//
// Solidity: function setRatTriggerProbability(uint256 probability) returns()
func (_RAT *RATTransactor) SetRatTriggerProbability(opts *bind.TransactOpts, probability *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setRatTriggerProbability", probability)
}

// SetRatTriggerProbability is a paid mutator transaction binding the contract method 0xd2e5bc72.
//
// Solidity: function setRatTriggerProbability(uint256 probability) returns()
func (_RAT *RATSession) SetRatTriggerProbability(probability *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetRatTriggerProbability(&_RAT.TransactOpts, probability)
}

// SetRatTriggerProbability is a paid mutator transaction binding the contract method 0xd2e5bc72.
//
// Solidity: function setRatTriggerProbability(uint256 probability) returns()
func (_RAT *RATTransactorSession) SetRatTriggerProbability(probability *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetRatTriggerProbability(&_RAT.TransactOpts, probability)
}

// SetSlashingPenalty is a paid mutator transaction binding the contract method 0xf983386b.
//
// Solidity: function setSlashingPenalty(uint256 penalty) returns()
func (_RAT *RATTransactor) SetSlashingPenalty(opts *bind.TransactOpts, penalty *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setSlashingPenalty", penalty)
}

// SetSlashingPenalty is a paid mutator transaction binding the contract method 0xf983386b.
//
// Solidity: function setSlashingPenalty(uint256 penalty) returns()
func (_RAT *RATSession) SetSlashingPenalty(penalty *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetSlashingPenalty(&_RAT.TransactOpts, penalty)
}

// SetSlashingPenalty is a paid mutator transaction binding the contract method 0xf983386b.
//
// Solidity: function setSlashingPenalty(uint256 penalty) returns()
func (_RAT *RATTransactorSession) SetSlashingPenalty(penalty *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetSlashingPenalty(&_RAT.TransactOpts, penalty)
}

// SetTreasury is a paid mutator transaction binding the contract method 0xf0f44260.
//
// Solidity: function setTreasury(address _treasury) returns()
func (_RAT *RATTransactor) SetTreasury(opts *bind.TransactOpts, _treasury common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setTreasury", _treasury)
}

// SetTreasury is a paid mutator transaction binding the contract method 0xf0f44260.
//
// Solidity: function setTreasury(address _treasury) returns()
func (_RAT *RATSession) SetTreasury(_treasury common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetTreasury(&_RAT.TransactOpts, _treasury)
}

// SetTreasury is a paid mutator transaction binding the contract method 0xf0f44260.
//
// Solidity: function setTreasury(address _treasury) returns()
func (_RAT *RATTransactorSession) SetTreasury(_treasury common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetTreasury(&_RAT.TransactOpts, _treasury)
}

// SetValidatorBuffer is a paid mutator transaction binding the contract method 0x6ad83f91.
//
// Solidity: function setValidatorBuffer(uint256 buffer) returns()
func (_RAT *RATTransactor) SetValidatorBuffer(opts *bind.TransactOpts, buffer *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setValidatorBuffer", buffer)
}

// SetValidatorBuffer is a paid mutator transaction binding the contract method 0x6ad83f91.
//
// Solidity: function setValidatorBuffer(uint256 buffer) returns()
func (_RAT *RATSession) SetValidatorBuffer(buffer *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetValidatorBuffer(&_RAT.TransactOpts, buffer)
}

// SetValidatorBuffer is a paid mutator transaction binding the contract method 0x6ad83f91.
//
// Solidity: function setValidatorBuffer(uint256 buffer) returns()
func (_RAT *RATTransactorSession) SetValidatorBuffer(buffer *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetValidatorBuffer(&_RAT.TransactOpts, buffer)
}

// SubmitEvidence is a paid mutator transaction binding the contract method 0xe54f6237.
//
// Solidity: function submitEvidence(address systemConfig, uint32 batchIndex, bytes evidence) returns()
func (_RAT *RATTransactor) SubmitEvidence(opts *bind.TransactOpts, systemConfig common.Address, batchIndex uint32, evidence []byte) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "submitEvidence", systemConfig, batchIndex, evidence)
}

// SubmitEvidence is a paid mutator transaction binding the contract method 0xe54f6237.
//
// Solidity: function submitEvidence(address systemConfig, uint32 batchIndex, bytes evidence) returns()
func (_RAT *RATSession) SubmitEvidence(systemConfig common.Address, batchIndex uint32, evidence []byte) (*types.Transaction, error) {
	return _RAT.Contract.SubmitEvidence(&_RAT.TransactOpts, systemConfig, batchIndex, evidence)
}

// SubmitEvidence is a paid mutator transaction binding the contract method 0xe54f6237.
//
// Solidity: function submitEvidence(address systemConfig, uint32 batchIndex, bytes evidence) returns()
func (_RAT *RATTransactorSession) SubmitEvidence(systemConfig common.Address, batchIndex uint32, evidence []byte) (*types.Transaction, error) {
	return _RAT.Contract.SubmitEvidence(&_RAT.TransactOpts, systemConfig, batchIndex, evidence)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_RAT *RATTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_RAT *RATSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _RAT.Contract.TransferOwnership(&_RAT.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_RAT *RATTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _RAT.Contract.TransferOwnership(&_RAT.TransactOpts, newOwner)
}

// TriggerAttentionTest is a paid mutator transaction binding the contract method 0x004fe2b4.
//
// Solidity: function triggerAttentionTest(address gameAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, bytes32 blockHash) returns()
func (_RAT *RATTransactor) TriggerAttentionTest(opts *bind.TransactOpts, gameAddress common.Address, systemConfig common.Address, batchIndex uint32, batchHash [32]byte, blockHash [32]byte) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "triggerAttentionTest", gameAddress, systemConfig, batchIndex, batchHash, blockHash)
}

// TriggerAttentionTest is a paid mutator transaction binding the contract method 0x004fe2b4.
//
// Solidity: function triggerAttentionTest(address gameAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, bytes32 blockHash) returns()
func (_RAT *RATSession) TriggerAttentionTest(gameAddress common.Address, systemConfig common.Address, batchIndex uint32, batchHash [32]byte, blockHash [32]byte) (*types.Transaction, error) {
	return _RAT.Contract.TriggerAttentionTest(&_RAT.TransactOpts, gameAddress, systemConfig, batchIndex, batchHash, blockHash)
}

// TriggerAttentionTest is a paid mutator transaction binding the contract method 0x004fe2b4.
//
// Solidity: function triggerAttentionTest(address gameAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, bytes32 blockHash) returns()
func (_RAT *RATTransactorSession) TriggerAttentionTest(gameAddress common.Address, systemConfig common.Address, batchIndex uint32, batchHash [32]byte, blockHash [32]byte) (*types.Transaction, error) {
	return _RAT.Contract.TriggerAttentionTest(&_RAT.TransactOpts, gameAddress, systemConfig, batchIndex, batchHash, blockHash)
}

// WithdrawSlashingsToTreasury is a paid mutator transaction binding the contract method 0x116c4fcc.
//
// Solidity: function withdrawSlashingsToTreasury() returns()
func (_RAT *RATTransactor) WithdrawSlashingsToTreasury(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "withdrawSlashingsToTreasury")
}

// WithdrawSlashingsToTreasury is a paid mutator transaction binding the contract method 0x116c4fcc.
//
// Solidity: function withdrawSlashingsToTreasury() returns()
func (_RAT *RATSession) WithdrawSlashingsToTreasury() (*types.Transaction, error) {
	return _RAT.Contract.WithdrawSlashingsToTreasury(&_RAT.TransactOpts)
}

// WithdrawSlashingsToTreasury is a paid mutator transaction binding the contract method 0x116c4fcc.
//
// Solidity: function withdrawSlashingsToTreasury() returns()
func (_RAT *RATTransactorSession) WithdrawSlashingsToTreasury() (*types.Transaction, error) {
	return _RAT.Contract.WithdrawSlashingsToTreasury(&_RAT.TransactOpts)
}

// RATAttentionTestTriggeredIterator is returned from FilterAttentionTestTriggered and is used to iterate over the raw logs and unpacked data for AttentionTestTriggered events raised by the RAT contract.
type RATAttentionTestTriggeredIterator struct {
	Event *RATAttentionTestTriggered // Event containing the contract specifics and raw log

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
func (it *RATAttentionTestTriggeredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATAttentionTestTriggered)
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
		it.Event = new(RATAttentionTestTriggered)
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
func (it *RATAttentionTestTriggeredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATAttentionTestTriggeredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATAttentionTestTriggered represents a AttentionTestTriggered event raised by the RAT contract.
type RATAttentionTestTriggered struct {
	TestId       [32]byte
	Validator    common.Address
	SystemConfig common.Address
	GameAddress  common.Address
	BatchIndex   uint32
	Deadline     *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterAttentionTestTriggered is a free log retrieval operation binding the contract event 0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38.
//
// Solidity: event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline)
func (_RAT *RATFilterer) FilterAttentionTestTriggered(opts *bind.FilterOpts, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (*RATAttentionTestTriggeredIterator, error) {

	var testIdRule []interface{}
	for _, testIdItem := range testId {
		testIdRule = append(testIdRule, testIdItem)
	}
	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "AttentionTestTriggered", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATAttentionTestTriggeredIterator{contract: _RAT.contract, event: "AttentionTestTriggered", logs: logs, sub: sub}, nil
}

// WatchAttentionTestTriggered is a free log subscription operation binding the contract event 0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38.
//
// Solidity: event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline)
func (_RAT *RATFilterer) WatchAttentionTestTriggered(opts *bind.WatchOpts, sink chan<- *RATAttentionTestTriggered, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var testIdRule []interface{}
	for _, testIdItem := range testId {
		testIdRule = append(testIdRule, testIdItem)
	}
	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "AttentionTestTriggered", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATAttentionTestTriggered)
				if err := _RAT.contract.UnpackLog(event, "AttentionTestTriggered", log); err != nil {
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

// ParseAttentionTestTriggered is a log parse operation binding the contract event 0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38.
//
// Solidity: event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline)
func (_RAT *RATFilterer) ParseAttentionTestTriggered(log types.Log) (*RATAttentionTestTriggered, error) {
	event := new(RATAttentionTestTriggered)
	if err := _RAT.contract.UnpackLog(event, "AttentionTestTriggered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATBondRestoredIterator is returned from FilterBondRestored and is used to iterate over the raw logs and unpacked data for BondRestored events raised by the RAT contract.
type RATBondRestoredIterator struct {
	Event *RATBondRestored // Event containing the contract specifics and raw log

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
func (it *RATBondRestoredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATBondRestored)
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
		it.Event = new(RATBondRestored)
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
func (it *RATBondRestoredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATBondRestoredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATBondRestored represents a BondRestored event raised by the RAT contract.
type RATBondRestored struct {
	TestId         [32]byte
	Validator      common.Address
	SystemConfig   common.Address
	RestoredAmount *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterBondRestored is a free log retrieval operation binding the contract event 0x8b828ea68e5478964e1ee2efd72993bba0df811816b25542cd3e02acb778f24b.
//
// Solidity: event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 restoredAmount)
func (_RAT *RATFilterer) FilterBondRestored(opts *bind.FilterOpts, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (*RATBondRestoredIterator, error) {

	var testIdRule []interface{}
	for _, testIdItem := range testId {
		testIdRule = append(testIdRule, testIdItem)
	}
	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "BondRestored", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATBondRestoredIterator{contract: _RAT.contract, event: "BondRestored", logs: logs, sub: sub}, nil
}

// WatchBondRestored is a free log subscription operation binding the contract event 0x8b828ea68e5478964e1ee2efd72993bba0df811816b25542cd3e02acb778f24b.
//
// Solidity: event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 restoredAmount)
func (_RAT *RATFilterer) WatchBondRestored(opts *bind.WatchOpts, sink chan<- *RATBondRestored, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var testIdRule []interface{}
	for _, testIdItem := range testId {
		testIdRule = append(testIdRule, testIdItem)
	}
	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "BondRestored", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATBondRestored)
				if err := _RAT.contract.UnpackLog(event, "BondRestored", log); err != nil {
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

// ParseBondRestored is a log parse operation binding the contract event 0x8b828ea68e5478964e1ee2efd72993bba0df811816b25542cd3e02acb778f24b.
//
// Solidity: event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 restoredAmount)
func (_RAT *RATFilterer) ParseBondRestored(log types.Log) (*RATBondRestored, error) {
	event := new(RATBondRestored)
	if err := _RAT.contract.UnpackLog(event, "BondRestored", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATDepositAddedIterator is returned from FilterDepositAdded and is used to iterate over the raw logs and unpacked data for DepositAdded events raised by the RAT contract.
type RATDepositAddedIterator struct {
	Event *RATDepositAdded // Event containing the contract specifics and raw log

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
func (it *RATDepositAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATDepositAdded)
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
		it.Event = new(RATDepositAdded)
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
func (it *RATDepositAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATDepositAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATDepositAdded represents a DepositAdded event raised by the RAT contract.
type RATDepositAdded struct {
	Validator    common.Address
	SystemConfig common.Address
	Amount       *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterDepositAdded is a free log retrieval operation binding the contract event 0x63d8d7d5e63e9840ec91a12a160d27b7cfab294f6ba070b7359692acfe6b03bf.
//
// Solidity: event DepositAdded(address indexed validator, address indexed systemConfig, uint256 amount)
func (_RAT *RATFilterer) FilterDepositAdded(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address) (*RATDepositAddedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "DepositAdded", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATDepositAddedIterator{contract: _RAT.contract, event: "DepositAdded", logs: logs, sub: sub}, nil
}

// WatchDepositAdded is a free log subscription operation binding the contract event 0x63d8d7d5e63e9840ec91a12a160d27b7cfab294f6ba070b7359692acfe6b03bf.
//
// Solidity: event DepositAdded(address indexed validator, address indexed systemConfig, uint256 amount)
func (_RAT *RATFilterer) WatchDepositAdded(opts *bind.WatchOpts, sink chan<- *RATDepositAdded, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "DepositAdded", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATDepositAdded)
				if err := _RAT.contract.UnpackLog(event, "DepositAdded", log); err != nil {
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

// ParseDepositAdded is a log parse operation binding the contract event 0x63d8d7d5e63e9840ec91a12a160d27b7cfab294f6ba070b7359692acfe6b03bf.
//
// Solidity: event DepositAdded(address indexed validator, address indexed systemConfig, uint256 amount)
func (_RAT *RATFilterer) ParseDepositAdded(log types.Log) (*RATDepositAdded, error) {
	event := new(RATDepositAdded)
	if err := _RAT.contract.UnpackLog(event, "DepositAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATEvidenceSubmittedIterator is returned from FilterEvidenceSubmitted and is used to iterate over the raw logs and unpacked data for EvidenceSubmitted events raised by the RAT contract.
type RATEvidenceSubmittedIterator struct {
	Event *RATEvidenceSubmitted // Event containing the contract specifics and raw log

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
func (it *RATEvidenceSubmittedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATEvidenceSubmitted)
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
		it.Event = new(RATEvidenceSubmitted)
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
func (it *RATEvidenceSubmittedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATEvidenceSubmittedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATEvidenceSubmitted represents a EvidenceSubmitted event raised by the RAT contract.
type RATEvidenceSubmitted struct {
	TestId       [32]byte
	Validator    common.Address
	SystemConfig common.Address
	BatchIndex   uint32
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterEvidenceSubmitted is a free log retrieval operation binding the contract event 0xbf3ee2cdebc8d0e701d8f6bbed66db69a46f2cdeda4b1bf0eee3dab7b99114c9.
//
// Solidity: event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex)
func (_RAT *RATFilterer) FilterEvidenceSubmitted(opts *bind.FilterOpts, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (*RATEvidenceSubmittedIterator, error) {

	var testIdRule []interface{}
	for _, testIdItem := range testId {
		testIdRule = append(testIdRule, testIdItem)
	}
	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "EvidenceSubmitted", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATEvidenceSubmittedIterator{contract: _RAT.contract, event: "EvidenceSubmitted", logs: logs, sub: sub}, nil
}

// WatchEvidenceSubmitted is a free log subscription operation binding the contract event 0xbf3ee2cdebc8d0e701d8f6bbed66db69a46f2cdeda4b1bf0eee3dab7b99114c9.
//
// Solidity: event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex)
func (_RAT *RATFilterer) WatchEvidenceSubmitted(opts *bind.WatchOpts, sink chan<- *RATEvidenceSubmitted, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var testIdRule []interface{}
	for _, testIdItem := range testId {
		testIdRule = append(testIdRule, testIdItem)
	}
	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "EvidenceSubmitted", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATEvidenceSubmitted)
				if err := _RAT.contract.UnpackLog(event, "EvidenceSubmitted", log); err != nil {
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

// ParseEvidenceSubmitted is a log parse operation binding the contract event 0xbf3ee2cdebc8d0e701d8f6bbed66db69a46f2cdeda4b1bf0eee3dab7b99114c9.
//
// Solidity: event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex)
func (_RAT *RATFilterer) ParseEvidenceSubmitted(log types.Log) (*RATEvidenceSubmitted, error) {
	event := new(RATEvidenceSubmitted)
	if err := _RAT.contract.UnpackLog(event, "EvidenceSubmitted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATValidatorDeactivatedIterator is returned from FilterValidatorDeactivated and is used to iterate over the raw logs and unpacked data for ValidatorDeactivated events raised by the RAT contract.
type RATValidatorDeactivatedIterator struct {
	Event *RATValidatorDeactivated // Event containing the contract specifics and raw log

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
func (it *RATValidatorDeactivatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATValidatorDeactivated)
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
		it.Event = new(RATValidatorDeactivated)
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
func (it *RATValidatorDeactivatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATValidatorDeactivatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATValidatorDeactivated represents a ValidatorDeactivated event raised by the RAT contract.
type RATValidatorDeactivated struct {
	Validator      common.Address
	SystemConfig   common.Address
	ReturnedAmount *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterValidatorDeactivated is a free log retrieval operation binding the contract event 0xffcfa539e16382bc2fe8c1cd58e64186127bdc0dc70c50e2ba88beac80f1059a.
//
// Solidity: event ValidatorDeactivated(address indexed validator, address indexed systemConfig, uint256 returnedAmount)
func (_RAT *RATFilterer) FilterValidatorDeactivated(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address) (*RATValidatorDeactivatedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorDeactivated", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorDeactivatedIterator{contract: _RAT.contract, event: "ValidatorDeactivated", logs: logs, sub: sub}, nil
}

// WatchValidatorDeactivated is a free log subscription operation binding the contract event 0xffcfa539e16382bc2fe8c1cd58e64186127bdc0dc70c50e2ba88beac80f1059a.
//
// Solidity: event ValidatorDeactivated(address indexed validator, address indexed systemConfig, uint256 returnedAmount)
func (_RAT *RATFilterer) WatchValidatorDeactivated(opts *bind.WatchOpts, sink chan<- *RATValidatorDeactivated, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorDeactivated", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATValidatorDeactivated)
				if err := _RAT.contract.UnpackLog(event, "ValidatorDeactivated", log); err != nil {
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

// ParseValidatorDeactivated is a log parse operation binding the contract event 0xffcfa539e16382bc2fe8c1cd58e64186127bdc0dc70c50e2ba88beac80f1059a.
//
// Solidity: event ValidatorDeactivated(address indexed validator, address indexed systemConfig, uint256 returnedAmount)
func (_RAT *RATFilterer) ParseValidatorDeactivated(log types.Log) (*RATValidatorDeactivated, error) {
	event := new(RATValidatorDeactivated)
	if err := _RAT.contract.UnpackLog(event, "ValidatorDeactivated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATValidatorRegisteredIterator is returned from FilterValidatorRegistered and is used to iterate over the raw logs and unpacked data for ValidatorRegistered events raised by the RAT contract.
type RATValidatorRegisteredIterator struct {
	Event *RATValidatorRegistered // Event containing the contract specifics and raw log

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
func (it *RATValidatorRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATValidatorRegistered)
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
		it.Event = new(RATValidatorRegistered)
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
func (it *RATValidatorRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATValidatorRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATValidatorRegistered represents a ValidatorRegistered event raised by the RAT contract.
type RATValidatorRegistered struct {
	Validator      common.Address
	SystemConfig   common.Address
	DepositAmount  *big.Int
	RegistrationId *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterValidatorRegistered is a free log retrieval operation binding the contract event 0xc15d937eb6e674346338dc7e284a3337f4c01fe4c05be6f30e06f054fc5aecfe.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount, uint256 registrationId)
func (_RAT *RATFilterer) FilterValidatorRegistered(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address) (*RATValidatorRegisteredIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorRegistered", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorRegisteredIterator{contract: _RAT.contract, event: "ValidatorRegistered", logs: logs, sub: sub}, nil
}

// WatchValidatorRegistered is a free log subscription operation binding the contract event 0xc15d937eb6e674346338dc7e284a3337f4c01fe4c05be6f30e06f054fc5aecfe.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount, uint256 registrationId)
func (_RAT *RATFilterer) WatchValidatorRegistered(opts *bind.WatchOpts, sink chan<- *RATValidatorRegistered, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorRegistered", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATValidatorRegistered)
				if err := _RAT.contract.UnpackLog(event, "ValidatorRegistered", log); err != nil {
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

// ParseValidatorRegistered is a log parse operation binding the contract event 0xc15d937eb6e674346338dc7e284a3337f4c01fe4c05be6f30e06f054fc5aecfe.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount, uint256 registrationId)
func (_RAT *RATFilterer) ParseValidatorRegistered(log types.Log) (*RATValidatorRegistered, error) {
	event := new(RATValidatorRegistered)
	if err := _RAT.contract.UnpackLog(event, "ValidatorRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATValidatorRestoredIterator is returned from FilterValidatorRestored and is used to iterate over the raw logs and unpacked data for ValidatorRestored events raised by the RAT contract.
type RATValidatorRestoredIterator struct {
	Event *RATValidatorRestored // Event containing the contract specifics and raw log

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
func (it *RATValidatorRestoredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATValidatorRestored)
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
		it.Event = new(RATValidatorRestored)
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
func (it *RATValidatorRestoredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATValidatorRestoredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATValidatorRestored represents a ValidatorRestored event raised by the RAT contract.
type RATValidatorRestored struct {
	Validator    common.Address
	SystemConfig common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterValidatorRestored is a free log retrieval operation binding the contract event 0xacf682cec5d019e69bf9a11a0ee8d582373446ed7815c383edf30b5b40056699.
//
// Solidity: event ValidatorRestored(address indexed validator, address indexed systemConfig)
func (_RAT *RATFilterer) FilterValidatorRestored(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address) (*RATValidatorRestoredIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorRestored", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorRestoredIterator{contract: _RAT.contract, event: "ValidatorRestored", logs: logs, sub: sub}, nil
}

// WatchValidatorRestored is a free log subscription operation binding the contract event 0xacf682cec5d019e69bf9a11a0ee8d582373446ed7815c383edf30b5b40056699.
//
// Solidity: event ValidatorRestored(address indexed validator, address indexed systemConfig)
func (_RAT *RATFilterer) WatchValidatorRestored(opts *bind.WatchOpts, sink chan<- *RATValidatorRestored, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorRestored", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATValidatorRestored)
				if err := _RAT.contract.UnpackLog(event, "ValidatorRestored", log); err != nil {
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

// ParseValidatorRestored is a log parse operation binding the contract event 0xacf682cec5d019e69bf9a11a0ee8d582373446ed7815c383edf30b5b40056699.
//
// Solidity: event ValidatorRestored(address indexed validator, address indexed systemConfig)
func (_RAT *RATFilterer) ParseValidatorRestored(log types.Log) (*RATValidatorRestored, error) {
	event := new(RATValidatorRestored)
	if err := _RAT.contract.UnpackLog(event, "ValidatorRestored", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATValidatorSlashedIterator is returned from FilterValidatorSlashed and is used to iterate over the raw logs and unpacked data for ValidatorSlashed events raised by the RAT contract.
type RATValidatorSlashedIterator struct {
	Event *RATValidatorSlashed // Event containing the contract specifics and raw log

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
func (it *RATValidatorSlashedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATValidatorSlashed)
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
		it.Event = new(RATValidatorSlashed)
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
func (it *RATValidatorSlashedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATValidatorSlashedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATValidatorSlashed represents a ValidatorSlashed event raised by the RAT contract.
type RATValidatorSlashed struct {
	TestId         [32]byte
	Validator      common.Address
	SystemConfig   common.Address
	SlashedAmount  *big.Int
	RemovedFromSet bool
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterValidatorSlashed is a free log retrieval operation binding the contract event 0xb0568c5aad28a0ca5cd06a651d52c0017dfc3af0941a4cb05a6bce87aef1bfe8.
//
// Solidity: event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 slashedAmount, bool removedFromSet)
func (_RAT *RATFilterer) FilterValidatorSlashed(opts *bind.FilterOpts, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (*RATValidatorSlashedIterator, error) {

	var testIdRule []interface{}
	for _, testIdItem := range testId {
		testIdRule = append(testIdRule, testIdItem)
	}
	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorSlashed", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorSlashedIterator{contract: _RAT.contract, event: "ValidatorSlashed", logs: logs, sub: sub}, nil
}

// WatchValidatorSlashed is a free log subscription operation binding the contract event 0xb0568c5aad28a0ca5cd06a651d52c0017dfc3af0941a4cb05a6bce87aef1bfe8.
//
// Solidity: event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 slashedAmount, bool removedFromSet)
func (_RAT *RATFilterer) WatchValidatorSlashed(opts *bind.WatchOpts, sink chan<- *RATValidatorSlashed, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var testIdRule []interface{}
	for _, testIdItem := range testId {
		testIdRule = append(testIdRule, testIdItem)
	}
	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorSlashed", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATValidatorSlashed)
				if err := _RAT.contract.UnpackLog(event, "ValidatorSlashed", log); err != nil {
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

// ParseValidatorSlashed is a log parse operation binding the contract event 0xb0568c5aad28a0ca5cd06a651d52c0017dfc3af0941a4cb05a6bce87aef1bfe8.
//
// Solidity: event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 slashedAmount, bool removedFromSet)
func (_RAT *RATFilterer) ParseValidatorSlashed(log types.Log) (*RATValidatorSlashed, error) {
	event := new(RATValidatorSlashed)
	if err := _RAT.contract.UnpackLog(event, "ValidatorSlashed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
