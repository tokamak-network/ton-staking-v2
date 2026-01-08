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

// DelayedWETHMinimalABI is the input ABI used to generate the binding from.
const DelayedWETHMinimalABI = "[{\"type\":\"function\",\"name\":\"delay\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"}]"

// DelayedWETHMinimal is an auto generated Go binding around an Ethereum contract.
type DelayedWETHMinimal struct {
	DelayedWETHMinimalCaller     // Read-only binding to the contract
	DelayedWETHMinimalTransactor // Write-only binding to the contract
	DelayedWETHMinimalFilterer   // Log filterer for contract events
}

// DelayedWETHMinimalCaller is an auto generated read-only Go binding around an Ethereum contract.
type DelayedWETHMinimalCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DelayedWETHMinimalTransactor is an auto generated write-only Go binding around an Ethereum contract.
type DelayedWETHMinimalTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DelayedWETHMinimalFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type DelayedWETHMinimalFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DelayedWETHMinimalSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type DelayedWETHMinimalSession struct {
	Contract     *DelayedWETHMinimal // Generic contract binding to set the session for
	CallOpts     bind.CallOpts       // Call options to use throughout this session
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// DelayedWETHMinimalCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type DelayedWETHMinimalCallerSession struct {
	Contract *DelayedWETHMinimalCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts             // Call options to use throughout this session
}

// DelayedWETHMinimalTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type DelayedWETHMinimalTransactorSession struct {
	Contract     *DelayedWETHMinimalTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts             // Transaction auth options to use throughout this session
}

// DelayedWETHMinimalRaw is an auto generated low-level Go binding around an Ethereum contract.
type DelayedWETHMinimalRaw struct {
	Contract *DelayedWETHMinimal // Generic contract binding to access the raw methods on
}

// DelayedWETHMinimalCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type DelayedWETHMinimalCallerRaw struct {
	Contract *DelayedWETHMinimalCaller // Generic read-only contract binding to access the raw methods on
}

// DelayedWETHMinimalTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type DelayedWETHMinimalTransactorRaw struct {
	Contract *DelayedWETHMinimalTransactor // Generic write-only contract binding to access the raw methods on
}

// NewDelayedWETHMinimal creates a new instance of DelayedWETHMinimal, bound to a specific deployed contract.
func NewDelayedWETHMinimal(address common.Address, backend bind.ContractBackend) (*DelayedWETHMinimal, error) {
	contract, err := bindDelayedWETHMinimal(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &DelayedWETHMinimal{DelayedWETHMinimalCaller: DelayedWETHMinimalCaller{contract: contract}, DelayedWETHMinimalTransactor: DelayedWETHMinimalTransactor{contract: contract}, DelayedWETHMinimalFilterer: DelayedWETHMinimalFilterer{contract: contract}}, nil
}

// NewDelayedWETHMinimalCaller creates a new read-only instance of DelayedWETHMinimal, bound to a specific deployed contract.
func NewDelayedWETHMinimalCaller(address common.Address, caller bind.ContractCaller) (*DelayedWETHMinimalCaller, error) {
	contract, err := bindDelayedWETHMinimal(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &DelayedWETHMinimalCaller{contract: contract}, nil
}

// NewDelayedWETHMinimalTransactor creates a new write-only instance of DelayedWETHMinimal, bound to a specific deployed contract.
func NewDelayedWETHMinimalTransactor(address common.Address, transactor bind.ContractTransactor) (*DelayedWETHMinimalTransactor, error) {
	contract, err := bindDelayedWETHMinimal(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &DelayedWETHMinimalTransactor{contract: contract}, nil
}

// NewDelayedWETHMinimalFilterer creates a new log filterer instance of DelayedWETHMinimal, bound to a specific deployed contract.
func NewDelayedWETHMinimalFilterer(address common.Address, filterer bind.ContractFilterer) (*DelayedWETHMinimalFilterer, error) {
	contract, err := bindDelayedWETHMinimal(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &DelayedWETHMinimalFilterer{contract: contract}, nil
}

// bindDelayedWETHMinimal binds a generic wrapper to an already deployed contract.
func bindDelayedWETHMinimal(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(DelayedWETHMinimalABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_DelayedWETHMinimal *DelayedWETHMinimalRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _DelayedWETHMinimal.Contract.DelayedWETHMinimalCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_DelayedWETHMinimal *DelayedWETHMinimalRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DelayedWETHMinimal.Contract.DelayedWETHMinimalTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_DelayedWETHMinimal *DelayedWETHMinimalRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _DelayedWETHMinimal.Contract.DelayedWETHMinimalTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_DelayedWETHMinimal *DelayedWETHMinimalCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _DelayedWETHMinimal.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_DelayedWETHMinimal *DelayedWETHMinimalTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DelayedWETHMinimal.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_DelayedWETHMinimal *DelayedWETHMinimalTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _DelayedWETHMinimal.Contract.contract.Transact(opts, method, params...)
}

// Delay is a free data retrieval call binding the contract method 0x6a42b8f8.
//
// Solidity: function delay() view returns(uint256)
func (_DelayedWETHMinimal *DelayedWETHMinimalCaller) Delay(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _DelayedWETHMinimal.contract.Call(opts, &out, "delay")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Delay is a free data retrieval call binding the contract method 0x6a42b8f8.
//
// Solidity: function delay() view returns(uint256)
func (_DelayedWETHMinimal *DelayedWETHMinimalSession) Delay() (*big.Int, error) {
	return _DelayedWETHMinimal.Contract.Delay(&_DelayedWETHMinimal.CallOpts)
}

// Delay is a free data retrieval call binding the contract method 0x6a42b8f8.
//
// Solidity: function delay() view returns(uint256)
func (_DelayedWETHMinimal *DelayedWETHMinimalCallerSession) Delay() (*big.Int, error) {
	return _DelayedWETHMinimal.Contract.Delay(&_DelayedWETHMinimal.CallOpts)
}
