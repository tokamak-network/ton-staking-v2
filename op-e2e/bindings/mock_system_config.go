// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package bindings

import (
	"errors"
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
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
)

// MockSystemConfigMetaData contains all meta data concerning the MockSystemConfig contract.
var MockSystemConfigMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"receive\",\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"disputeGameFactory\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1CrossDomainMessenger\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1ERC721Bridge\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1StandardBridge\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l2OutputOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"name\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"optimismMintableERC20Factory\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"optimismPortal\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDisputeGame\",\"inputs\":[{\"name\":\"_dispute\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDisputeGameFactory\",\"inputs\":[{\"name\":\"_factory\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setName\",\"inputs\":[{\"name\":\"_name\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTargetOwner\",\"inputs\":[{\"name\":\"_target\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_addr\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setUnsafeBlockSigner\",\"inputs\":[{\"name\":\"_unsafeBlockSigner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unsafeBlockSigner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false}]",
}

// MockSystemConfigABI is the input ABI used to generate the binding from.
const MockSystemConfigABI = "[{\"type\":\"constructor\",\"inputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"receive\",\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"disputeGameFactory\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1CrossDomainMessenger\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1ERC721Bridge\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1StandardBridge\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l2OutputOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"name\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"optimismMintableERC20Factory\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"optimismPortal\",\"inputs\":[],\"outputs\":[{\"name\":\"addr_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDisputeGame\",\"inputs\":[{\"name\":\"_dispute\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDisputeGameFactory\",\"inputs\":[{\"name\":\"_factory\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setName\",\"inputs\":[{\"name\":\"_name\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTargetOwner\",\"inputs\":[{\"name\":\"_target\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_addr\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setUnsafeBlockSigner\",\"inputs\":[{\"name\":\"_unsafeBlockSigner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unsafeBlockSigner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false}]"

// MockSystemConfig is an auto generated Go binding around an Ethereum contract.
type MockSystemConfig struct {
	MockSystemConfigCaller     // Read-only binding to the contract
	MockSystemConfigTransactor // Write-only binding to the contract
	MockSystemConfigFilterer   // Log filterer for contract events
}

// MockSystemConfigCaller is an auto generated read-only Go binding around an Ethereum contract.
type MockSystemConfigCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockSystemConfigTransactor is an auto generated write-only Go binding around an Ethereum contract.
type MockSystemConfigTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockSystemConfigFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MockSystemConfigFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockSystemConfigSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MockSystemConfigSession struct {
	Contract     *MockSystemConfig // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// MockSystemConfigCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MockSystemConfigCallerSession struct {
	Contract *MockSystemConfigCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts           // Call options to use throughout this session
}

// MockSystemConfigTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MockSystemConfigTransactorSession struct {
	Contract     *MockSystemConfigTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts           // Transaction auth options to use throughout this session
}

// MockSystemConfigRaw is an auto generated low-level Go binding around an Ethereum contract.
type MockSystemConfigRaw struct {
	Contract *MockSystemConfig // Generic contract binding to access the raw methods on
}

// MockSystemConfigCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MockSystemConfigCallerRaw struct {
	Contract *MockSystemConfigCaller // Generic read-only contract binding to access the raw methods on
}

// MockSystemConfigTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MockSystemConfigTransactorRaw struct {
	Contract *MockSystemConfigTransactor // Generic write-only contract binding to access the raw methods on
}

// NewMockSystemConfig creates a new instance of MockSystemConfig, bound to a specific deployed contract.
func NewMockSystemConfig(address common.Address, backend bind.ContractBackend) (*MockSystemConfig, error) {
	contract, err := bindMockSystemConfig(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MockSystemConfig{MockSystemConfigCaller: MockSystemConfigCaller{contract: contract}, MockSystemConfigTransactor: MockSystemConfigTransactor{contract: contract}, MockSystemConfigFilterer: MockSystemConfigFilterer{contract: contract}}, nil
}

// NewMockSystemConfigCaller creates a new read-only instance of MockSystemConfig, bound to a specific deployed contract.
func NewMockSystemConfigCaller(address common.Address, caller bind.ContractCaller) (*MockSystemConfigCaller, error) {
	contract, err := bindMockSystemConfig(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MockSystemConfigCaller{contract: contract}, nil
}

// NewMockSystemConfigTransactor creates a new write-only instance of MockSystemConfig, bound to a specific deployed contract.
func NewMockSystemConfigTransactor(address common.Address, transactor bind.ContractTransactor) (*MockSystemConfigTransactor, error) {
	contract, err := bindMockSystemConfig(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MockSystemConfigTransactor{contract: contract}, nil
}

// NewMockSystemConfigFilterer creates a new log filterer instance of MockSystemConfig, bound to a specific deployed contract.
func NewMockSystemConfigFilterer(address common.Address, filterer bind.ContractFilterer) (*MockSystemConfigFilterer, error) {
	contract, err := bindMockSystemConfig(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MockSystemConfigFilterer{contract: contract}, nil
}

// bindMockSystemConfig binds a generic wrapper to an already deployed contract.
func bindMockSystemConfig(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(MockSystemConfigABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockSystemConfig *MockSystemConfigRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockSystemConfig.Contract.MockSystemConfigCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockSystemConfig *MockSystemConfigRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.MockSystemConfigTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockSystemConfig *MockSystemConfigRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.MockSystemConfigTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockSystemConfig *MockSystemConfigCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockSystemConfig.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockSystemConfig *MockSystemConfigTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockSystemConfig *MockSystemConfigTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.contract.Transact(opts, method, params...)
}

// DisputeGameFactory is a free data retrieval call binding the contract method 0xf2b4e617.
//
// Solidity: function disputeGameFactory() view returns(address)
func (_MockSystemConfig *MockSystemConfigCaller) DisputeGameFactory(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MockSystemConfig.contract.Call(opts, &out, "disputeGameFactory")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err
}

// DisputeGameFactory is a free data retrieval call binding the contract method 0xf2b4e617.
//
// Solidity: function disputeGameFactory() view returns(address)
func (_MockSystemConfig *MockSystemConfigSession) DisputeGameFactory() (common.Address, error) {
	return _MockSystemConfig.Contract.DisputeGameFactory(&_MockSystemConfig.CallOpts)
}

// DisputeGameFactory is a free data retrieval call binding the contract method 0xf2b4e617.
//
// Solidity: function disputeGameFactory() view returns(address)
func (_MockSystemConfig *MockSystemConfigCallerSession) DisputeGameFactory() (common.Address, error) {
	return _MockSystemConfig.Contract.DisputeGameFactory(&_MockSystemConfig.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MockSystemConfig *MockSystemConfigCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MockSystemConfig.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MockSystemConfig *MockSystemConfigSession) Owner() (common.Address, error) {
	return _MockSystemConfig.Contract.Owner(&_MockSystemConfig.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MockSystemConfig *MockSystemConfigCallerSession) Owner() (common.Address, error) {
	return _MockSystemConfig.Contract.Owner(&_MockSystemConfig.CallOpts)
}

// UnsafeBlockSigner is a free data retrieval call binding the contract method 0x1fd19ee1.
//
// Solidity: function unsafeBlockSigner() view returns(address)
func (_MockSystemConfig *MockSystemConfigCaller) UnsafeBlockSigner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MockSystemConfig.contract.Call(opts, &out, "unsafeBlockSigner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err
}

// UnsafeBlockSigner is a free data retrieval call binding the contract method 0x1fd19ee1.
//
// Solidity: function unsafeBlockSigner() view returns(address)
func (_MockSystemConfig *MockSystemConfigSession) UnsafeBlockSigner() (common.Address, error) {
	return _MockSystemConfig.Contract.UnsafeBlockSigner(&_MockSystemConfig.CallOpts)
}

// UnsafeBlockSigner is a free data retrieval call binding the contract method 0x1fd19ee1.
//
// Solidity: function unsafeBlockSigner() view returns(address)
func (_MockSystemConfig *MockSystemConfigCallerSession) UnsafeBlockSigner() (common.Address, error) {
	return _MockSystemConfig.Contract.UnsafeBlockSigner(&_MockSystemConfig.CallOpts)
}

// SetDisputeGame is a paid mutator transaction binding the contract method 0xc5e4172e.
//
// Solidity: function setDisputeGame(address _dispute) returns()
func (_MockSystemConfig *MockSystemConfigTransactor) SetDisputeGame(opts *bind.TransactOpts, _dispute common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.contract.Transact(opts, "setDisputeGame", _dispute)
}

// SetDisputeGame is a paid mutator transaction binding the contract method 0xc5e4172e.
//
// Solidity: function setDisputeGame(address _dispute) returns()
func (_MockSystemConfig *MockSystemConfigSession) SetDisputeGame(_dispute common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.SetDisputeGame(&_MockSystemConfig.TransactOpts, _dispute)
}

// SetDisputeGame is a paid mutator transaction binding the contract method 0xc5e4172e.
//
// Solidity: function setDisputeGame(address _dispute) returns()
func (_MockSystemConfig *MockSystemConfigTransactorSession) SetDisputeGame(_dispute common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.SetDisputeGame(&_MockSystemConfig.TransactOpts, _dispute)
}

// SetDisputeGameFactory is a paid mutator transaction binding the contract method 0x04f4e3b0.
//
// Solidity: function setDisputeGameFactory(address _factory) returns()
func (_MockSystemConfig *MockSystemConfigTransactor) SetDisputeGameFactory(opts *bind.TransactOpts, _factory common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.contract.Transact(opts, "setDisputeGameFactory", _factory)
}

// SetDisputeGameFactory is a paid mutator transaction binding the contract method 0x04f4e3b0.
//
// Solidity: function setDisputeGameFactory(address _factory) returns()
func (_MockSystemConfig *MockSystemConfigSession) SetDisputeGameFactory(_factory common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.SetDisputeGameFactory(&_MockSystemConfig.TransactOpts, _factory)
}

// SetDisputeGameFactory is a paid mutator transaction binding the contract method 0x04f4e3b0.
//
// Solidity: function setDisputeGameFactory(address _factory) returns()
func (_MockSystemConfig *MockSystemConfigTransactorSession) SetDisputeGameFactory(_factory common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.SetDisputeGameFactory(&_MockSystemConfig.TransactOpts, _factory)
}

// SetUnsafeBlockSigner is a paid mutator transaction binding the contract method 0x18d13918.
//
// Solidity: function setUnsafeBlockSigner(address _unsafeBlockSigner) returns()
func (_MockSystemConfig *MockSystemConfigTransactor) SetUnsafeBlockSigner(opts *bind.TransactOpts, _unsafeBlockSigner common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.contract.Transact(opts, "setUnsafeBlockSigner", _unsafeBlockSigner)
}

// SetUnsafeBlockSigner is a paid mutator transaction binding the contract method 0x18d13918.
//
// Solidity: function setUnsafeBlockSigner(address _unsafeBlockSigner) returns()
func (_MockSystemConfig *MockSystemConfigSession) SetUnsafeBlockSigner(_unsafeBlockSigner common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.SetUnsafeBlockSigner(&_MockSystemConfig.TransactOpts, _unsafeBlockSigner)
}

// SetUnsafeBlockSigner is a paid mutator transaction binding the contract method 0x18d13918.
//
// Solidity: function setUnsafeBlockSigner(address _unsafeBlockSigner) returns()
func (_MockSystemConfig *MockSystemConfigTransactorSession) SetUnsafeBlockSigner(_unsafeBlockSigner common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.SetUnsafeBlockSigner(&_MockSystemConfig.TransactOpts, _unsafeBlockSigner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MockSystemConfig *MockSystemConfigTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MockSystemConfig *MockSystemConfigSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.TransferOwnership(&_MockSystemConfig.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MockSystemConfig *MockSystemConfigTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _MockSystemConfig.Contract.TransferOwnership(&_MockSystemConfig.TransactOpts, newOwner)
}
