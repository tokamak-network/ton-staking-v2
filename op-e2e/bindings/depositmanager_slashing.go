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
	_ = abi.ConvertType
)

// DepositManagerSlashingMetaData contains all meta data concerning the DepositManagerSlashing contract.
var DepositManagerSlashingMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"aliveImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"globalWithdrawalDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isOwner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1BridgeRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2Manager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minDepositGasLimit\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"oldDepositManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseProxy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxyImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"removeAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"selectorImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setSlashingRewardRate\",\"inputs\":[{\"name\":\"newRate\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slash\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"challenger\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slashingRewardRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferAdmin\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdrawalDelay\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"ChallengerRewarded\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"challenger\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Slashed\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"challenger\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"slashedAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"rewardAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SlashingRewardRateSet\",\"inputs\":[{\"name\":\"newRate\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false}]",
}

// DepositManagerSlashingABI is the input ABI used to generate the binding from.
// Deprecated: Use DepositManagerSlashingMetaData.ABI instead.
var DepositManagerSlashingABI = DepositManagerSlashingMetaData.ABI

// DepositManagerSlashing is an auto generated Go binding around an Ethereum contract.
type DepositManagerSlashing struct {
	DepositManagerSlashingCaller     // Read-only binding to the contract
	DepositManagerSlashingTransactor // Write-only binding to the contract
	DepositManagerSlashingFilterer   // Log filterer for contract events
}

// DepositManagerSlashingCaller is an auto generated read-only Go binding around an Ethereum contract.
type DepositManagerSlashingCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DepositManagerSlashingTransactor is an auto generated write-only Go binding around an Ethereum contract.
type DepositManagerSlashingTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DepositManagerSlashingFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type DepositManagerSlashingFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DepositManagerSlashingSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type DepositManagerSlashingSession struct {
	Contract     *DepositManagerSlashing // Generic contract binding to set the session for
	CallOpts     bind.CallOpts           // Call options to use throughout this session
	TransactOpts bind.TransactOpts       // Transaction auth options to use throughout this session
}

// DepositManagerSlashingCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type DepositManagerSlashingCallerSession struct {
	Contract *DepositManagerSlashingCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts                 // Call options to use throughout this session
}

// DepositManagerSlashingTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type DepositManagerSlashingTransactorSession struct {
	Contract     *DepositManagerSlashingTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts                 // Transaction auth options to use throughout this session
}

// DepositManagerSlashingRaw is an auto generated low-level Go binding around an Ethereum contract.
type DepositManagerSlashingRaw struct {
	Contract *DepositManagerSlashing // Generic contract binding to access the raw methods on
}

// DepositManagerSlashingCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type DepositManagerSlashingCallerRaw struct {
	Contract *DepositManagerSlashingCaller // Generic read-only contract binding to access the raw methods on
}

// DepositManagerSlashingTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type DepositManagerSlashingTransactorRaw struct {
	Contract *DepositManagerSlashingTransactor // Generic write-only contract binding to access the raw methods on
}

// NewDepositManagerSlashing creates a new instance of DepositManagerSlashing, bound to a specific deployed contract.
func NewDepositManagerSlashing(address common.Address, backend bind.ContractBackend) (*DepositManagerSlashing, error) {
	contract, err := bindDepositManagerSlashing(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &DepositManagerSlashing{DepositManagerSlashingCaller: DepositManagerSlashingCaller{contract: contract}, DepositManagerSlashingTransactor: DepositManagerSlashingTransactor{contract: contract}, DepositManagerSlashingFilterer: DepositManagerSlashingFilterer{contract: contract}}, nil
}

// NewDepositManagerSlashingCaller creates a new read-only instance of DepositManagerSlashing, bound to a specific deployed contract.
func NewDepositManagerSlashingCaller(address common.Address, caller bind.ContractCaller) (*DepositManagerSlashingCaller, error) {
	contract, err := bindDepositManagerSlashing(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &DepositManagerSlashingCaller{contract: contract}, nil
}

// NewDepositManagerSlashingTransactor creates a new write-only instance of DepositManagerSlashing, bound to a specific deployed contract.
func NewDepositManagerSlashingTransactor(address common.Address, transactor bind.ContractTransactor) (*DepositManagerSlashingTransactor, error) {
	contract, err := bindDepositManagerSlashing(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &DepositManagerSlashingTransactor{contract: contract}, nil
}

// NewDepositManagerSlashingFilterer creates a new log filterer instance of DepositManagerSlashing, bound to a specific deployed contract.
func NewDepositManagerSlashingFilterer(address common.Address, filterer bind.ContractFilterer) (*DepositManagerSlashingFilterer, error) {
	contract, err := bindDepositManagerSlashing(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &DepositManagerSlashingFilterer{contract: contract}, nil
}

// bindDepositManagerSlashing binds a generic wrapper to an already deployed contract.
func bindDepositManagerSlashing(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := DepositManagerSlashingMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_DepositManagerSlashing *DepositManagerSlashingRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _DepositManagerSlashing.Contract.DepositManagerSlashingCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_DepositManagerSlashing *DepositManagerSlashingRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.DepositManagerSlashingTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_DepositManagerSlashing *DepositManagerSlashingRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.DepositManagerSlashingTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_DepositManagerSlashing *DepositManagerSlashingCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _DepositManagerSlashing.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_DepositManagerSlashing *DepositManagerSlashingTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_DepositManagerSlashing *DepositManagerSlashingTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_DepositManagerSlashing *DepositManagerSlashingSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _DepositManagerSlashing.Contract.DEFAULTADMINROLE(&_DepositManagerSlashing.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _DepositManagerSlashing.Contract.DEFAULTADMINROLE(&_DepositManagerSlashing.CallOpts)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) AliveImplementation(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "aliveImplementation", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _DepositManagerSlashing.Contract.AliveImplementation(&_DepositManagerSlashing.CallOpts, arg0)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _DepositManagerSlashing.Contract.AliveImplementation(&_DepositManagerSlashing.CallOpts, arg0)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_DepositManagerSlashing *DepositManagerSlashingSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _DepositManagerSlashing.Contract.GetRoleAdmin(&_DepositManagerSlashing.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _DepositManagerSlashing.Contract.GetRoleAdmin(&_DepositManagerSlashing.CallOpts, role)
}

// GlobalWithdrawalDelay is a free data retrieval call binding the contract method 0x6ec3d5ae.
//
// Solidity: function globalWithdrawalDelay() view returns(uint256)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) GlobalWithdrawalDelay(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "globalWithdrawalDelay")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GlobalWithdrawalDelay is a free data retrieval call binding the contract method 0x6ec3d5ae.
//
// Solidity: function globalWithdrawalDelay() view returns(uint256)
func (_DepositManagerSlashing *DepositManagerSlashingSession) GlobalWithdrawalDelay() (*big.Int, error) {
	return _DepositManagerSlashing.Contract.GlobalWithdrawalDelay(&_DepositManagerSlashing.CallOpts)
}

// GlobalWithdrawalDelay is a free data retrieval call binding the contract method 0x6ec3d5ae.
//
// Solidity: function globalWithdrawalDelay() view returns(uint256)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) GlobalWithdrawalDelay() (*big.Int, error) {
	return _DepositManagerSlashing.Contract.GlobalWithdrawalDelay(&_DepositManagerSlashing.CallOpts)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _DepositManagerSlashing.Contract.HasRole(&_DepositManagerSlashing.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _DepositManagerSlashing.Contract.HasRole(&_DepositManagerSlashing.CallOpts, role, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) IsAdmin(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "isAdmin", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingSession) IsAdmin(account common.Address) (bool, error) {
	return _DepositManagerSlashing.Contract.IsAdmin(&_DepositManagerSlashing.CallOpts, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) IsAdmin(account common.Address) (bool, error) {
	return _DepositManagerSlashing.Contract.IsAdmin(&_DepositManagerSlashing.CallOpts, account)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) IsOwner(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "isOwner")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingSession) IsOwner() (bool, error) {
	return _DepositManagerSlashing.Contract.IsOwner(&_DepositManagerSlashing.CallOpts)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) IsOwner() (bool, error) {
	return _DepositManagerSlashing.Contract.IsOwner(&_DepositManagerSlashing.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) L1BridgeRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "l1BridgeRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingSession) L1BridgeRegistry() (common.Address, error) {
	return _DepositManagerSlashing.Contract.L1BridgeRegistry(&_DepositManagerSlashing.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) L1BridgeRegistry() (common.Address, error) {
	return _DepositManagerSlashing.Contract.L1BridgeRegistry(&_DepositManagerSlashing.CallOpts)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) Layer2Manager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "layer2Manager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingSession) Layer2Manager() (common.Address, error) {
	return _DepositManagerSlashing.Contract.Layer2Manager(&_DepositManagerSlashing.CallOpts)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) Layer2Manager() (common.Address, error) {
	return _DepositManagerSlashing.Contract.Layer2Manager(&_DepositManagerSlashing.CallOpts)
}

// MinDepositGasLimit is a free data retrieval call binding the contract method 0xdd283f97.
//
// Solidity: function minDepositGasLimit() view returns(uint32)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) MinDepositGasLimit(opts *bind.CallOpts) (uint32, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "minDepositGasLimit")

	if err != nil {
		return *new(uint32), err
	}

	out0 := *abi.ConvertType(out[0], new(uint32)).(*uint32)

	return out0, err

}

// MinDepositGasLimit is a free data retrieval call binding the contract method 0xdd283f97.
//
// Solidity: function minDepositGasLimit() view returns(uint32)
func (_DepositManagerSlashing *DepositManagerSlashingSession) MinDepositGasLimit() (uint32, error) {
	return _DepositManagerSlashing.Contract.MinDepositGasLimit(&_DepositManagerSlashing.CallOpts)
}

// MinDepositGasLimit is a free data retrieval call binding the contract method 0xdd283f97.
//
// Solidity: function minDepositGasLimit() view returns(uint32)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) MinDepositGasLimit() (uint32, error) {
	return _DepositManagerSlashing.Contract.MinDepositGasLimit(&_DepositManagerSlashing.CallOpts)
}

// OldDepositManager is a free data retrieval call binding the contract method 0x2153c239.
//
// Solidity: function oldDepositManager() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) OldDepositManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "oldDepositManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// OldDepositManager is a free data retrieval call binding the contract method 0x2153c239.
//
// Solidity: function oldDepositManager() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingSession) OldDepositManager() (common.Address, error) {
	return _DepositManagerSlashing.Contract.OldDepositManager(&_DepositManagerSlashing.CallOpts)
}

// OldDepositManager is a free data retrieval call binding the contract method 0x2153c239.
//
// Solidity: function oldDepositManager() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) OldDepositManager() (common.Address, error) {
	return _DepositManagerSlashing.Contract.OldDepositManager(&_DepositManagerSlashing.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) PauseProxy(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "pauseProxy")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingSession) PauseProxy() (bool, error) {
	return _DepositManagerSlashing.Contract.PauseProxy(&_DepositManagerSlashing.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) PauseProxy() (bool, error) {
	return _DepositManagerSlashing.Contract.PauseProxy(&_DepositManagerSlashing.CallOpts)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) ProxyImplementation(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "proxyImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _DepositManagerSlashing.Contract.ProxyImplementation(&_DepositManagerSlashing.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _DepositManagerSlashing.Contract.ProxyImplementation(&_DepositManagerSlashing.CallOpts, arg0)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) SelectorImplementation(opts *bind.CallOpts, arg0 [4]byte) (common.Address, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "selectorImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _DepositManagerSlashing.Contract.SelectorImplementation(&_DepositManagerSlashing.CallOpts, arg0)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _DepositManagerSlashing.Contract.SelectorImplementation(&_DepositManagerSlashing.CallOpts, arg0)
}

// SlashingRewardRate is a free data retrieval call binding the contract method 0x8b0d5abe.
//
// Solidity: function slashingRewardRate() view returns(uint256)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) SlashingRewardRate(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "slashingRewardRate")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// SlashingRewardRate is a free data retrieval call binding the contract method 0x8b0d5abe.
//
// Solidity: function slashingRewardRate() view returns(uint256)
func (_DepositManagerSlashing *DepositManagerSlashingSession) SlashingRewardRate() (*big.Int, error) {
	return _DepositManagerSlashing.Contract.SlashingRewardRate(&_DepositManagerSlashing.CallOpts)
}

// SlashingRewardRate is a free data retrieval call binding the contract method 0x8b0d5abe.
//
// Solidity: function slashingRewardRate() view returns(uint256)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) SlashingRewardRate() (*big.Int, error) {
	return _DepositManagerSlashing.Contract.SlashingRewardRate(&_DepositManagerSlashing.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _DepositManagerSlashing.Contract.SupportsInterface(&_DepositManagerSlashing.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _DepositManagerSlashing.Contract.SupportsInterface(&_DepositManagerSlashing.CallOpts, interfaceId)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) Ton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "ton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingSession) Ton() (common.Address, error) {
	return _DepositManagerSlashing.Contract.Ton(&_DepositManagerSlashing.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) Ton() (common.Address, error) {
	return _DepositManagerSlashing.Contract.Ton(&_DepositManagerSlashing.CallOpts)
}

// WithdrawalDelay is a free data retrieval call binding the contract method 0x4ce97036.
//
// Solidity: function withdrawalDelay(address ) view returns(uint256)
func (_DepositManagerSlashing *DepositManagerSlashingCaller) WithdrawalDelay(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManagerSlashing.contract.Call(opts, &out, "withdrawalDelay", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WithdrawalDelay is a free data retrieval call binding the contract method 0x4ce97036.
//
// Solidity: function withdrawalDelay(address ) view returns(uint256)
func (_DepositManagerSlashing *DepositManagerSlashingSession) WithdrawalDelay(arg0 common.Address) (*big.Int, error) {
	return _DepositManagerSlashing.Contract.WithdrawalDelay(&_DepositManagerSlashing.CallOpts, arg0)
}

// WithdrawalDelay is a free data retrieval call binding the contract method 0x4ce97036.
//
// Solidity: function withdrawalDelay(address ) view returns(uint256)
func (_DepositManagerSlashing *DepositManagerSlashingCallerSession) WithdrawalDelay(arg0 common.Address) (*big.Int, error) {
	return _DepositManagerSlashing.Contract.WithdrawalDelay(&_DepositManagerSlashing.CallOpts, arg0)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactor) AddAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.contract.Transact(opts, "addAdmin", account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.AddAdmin(&_DepositManagerSlashing.TransactOpts, account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactorSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.AddAdmin(&_DepositManagerSlashing.TransactOpts, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.GrantRole(&_DepositManagerSlashing.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.GrantRole(&_DepositManagerSlashing.TransactOpts, role, account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactor) RemoveAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.contract.Transact(opts, "removeAdmin", account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.RemoveAdmin(&_DepositManagerSlashing.TransactOpts, account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactorSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.RemoveAdmin(&_DepositManagerSlashing.TransactOpts, account)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DepositManagerSlashing.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_DepositManagerSlashing *DepositManagerSlashingSession) RenounceOwnership() (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.RenounceOwnership(&_DepositManagerSlashing.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.RenounceOwnership(&_DepositManagerSlashing.TransactOpts)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.contract.Transact(opts, "renounceRole", role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.RenounceRole(&_DepositManagerSlashing.TransactOpts, role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactorSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.RenounceRole(&_DepositManagerSlashing.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.RevokeRole(&_DepositManagerSlashing.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.RevokeRole(&_DepositManagerSlashing.TransactOpts, role, account)
}

// SetSlashingRewardRate is a paid mutator transaction binding the contract method 0x5c1f2454.
//
// Solidity: function setSlashingRewardRate(uint256 newRate) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactor) SetSlashingRewardRate(opts *bind.TransactOpts, newRate *big.Int) (*types.Transaction, error) {
	return _DepositManagerSlashing.contract.Transact(opts, "setSlashingRewardRate", newRate)
}

// SetSlashingRewardRate is a paid mutator transaction binding the contract method 0x5c1f2454.
//
// Solidity: function setSlashingRewardRate(uint256 newRate) returns()
func (_DepositManagerSlashing *DepositManagerSlashingSession) SetSlashingRewardRate(newRate *big.Int) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.SetSlashingRewardRate(&_DepositManagerSlashing.TransactOpts, newRate)
}

// SetSlashingRewardRate is a paid mutator transaction binding the contract method 0x5c1f2454.
//
// Solidity: function setSlashingRewardRate(uint256 newRate) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactorSession) SetSlashingRewardRate(newRate *big.Int) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.SetSlashingRewardRate(&_DepositManagerSlashing.TransactOpts, newRate)
}

// Slash is a paid mutator transaction binding the contract method 0x563bf264.
//
// Solidity: function slash(address layer2, address operator, address challenger) returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingTransactor) Slash(opts *bind.TransactOpts, layer2 common.Address, operator common.Address, challenger common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.contract.Transact(opts, "slash", layer2, operator, challenger)
}

// Slash is a paid mutator transaction binding the contract method 0x563bf264.
//
// Solidity: function slash(address layer2, address operator, address challenger) returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingSession) Slash(layer2 common.Address, operator common.Address, challenger common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.Slash(&_DepositManagerSlashing.TransactOpts, layer2, operator, challenger)
}

// Slash is a paid mutator transaction binding the contract method 0x563bf264.
//
// Solidity: function slash(address layer2, address operator, address challenger) returns(bool)
func (_DepositManagerSlashing *DepositManagerSlashingTransactorSession) Slash(layer2 common.Address, operator common.Address, challenger common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.Slash(&_DepositManagerSlashing.TransactOpts, layer2, operator, challenger)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactor) TransferAdmin(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.contract.Transact(opts, "transferAdmin", newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_DepositManagerSlashing *DepositManagerSlashingSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.TransferAdmin(&_DepositManagerSlashing.TransactOpts, newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactorSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.TransferAdmin(&_DepositManagerSlashing.TransactOpts, newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactor) TransferOwnership(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.contract.Transact(opts, "transferOwnership", newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_DepositManagerSlashing *DepositManagerSlashingSession) TransferOwnership(newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.TransferOwnership(&_DepositManagerSlashing.TransactOpts, newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_DepositManagerSlashing *DepositManagerSlashingTransactorSession) TransferOwnership(newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManagerSlashing.Contract.TransferOwnership(&_DepositManagerSlashing.TransactOpts, newAdmin)
}

// DepositManagerSlashingChallengerRewardedIterator is returned from FilterChallengerRewarded and is used to iterate over the raw logs and unpacked data for ChallengerRewarded events raised by the DepositManagerSlashing contract.
type DepositManagerSlashingChallengerRewardedIterator struct {
	Event *DepositManagerSlashingChallengerRewarded // Event containing the contract specifics and raw log

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
func (it *DepositManagerSlashingChallengerRewardedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerSlashingChallengerRewarded)
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
		it.Event = new(DepositManagerSlashingChallengerRewarded)
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
func (it *DepositManagerSlashingChallengerRewardedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerSlashingChallengerRewardedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerSlashingChallengerRewarded represents a ChallengerRewarded event raised by the DepositManagerSlashing contract.
type DepositManagerSlashingChallengerRewarded struct {
	Layer2     common.Address
	Challenger common.Address
	Amount     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterChallengerRewarded is a free log retrieval operation binding the contract event 0x00a258f9d794ab8fcbdc7f27cbe8f9305018187f22e7a07c917dcb6dd72960ab.
//
// Solidity: event ChallengerRewarded(address indexed layer2, address indexed challenger, uint256 amount)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) FilterChallengerRewarded(opts *bind.FilterOpts, layer2 []common.Address, challenger []common.Address) (*DepositManagerSlashingChallengerRewardedIterator, error) {

	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}
	var challengerRule []interface{}
	for _, challengerItem := range challenger {
		challengerRule = append(challengerRule, challengerItem)
	}

	logs, sub, err := _DepositManagerSlashing.contract.FilterLogs(opts, "ChallengerRewarded", layer2Rule, challengerRule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerSlashingChallengerRewardedIterator{contract: _DepositManagerSlashing.contract, event: "ChallengerRewarded", logs: logs, sub: sub}, nil
}

// WatchChallengerRewarded is a free log subscription operation binding the contract event 0x00a258f9d794ab8fcbdc7f27cbe8f9305018187f22e7a07c917dcb6dd72960ab.
//
// Solidity: event ChallengerRewarded(address indexed layer2, address indexed challenger, uint256 amount)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) WatchChallengerRewarded(opts *bind.WatchOpts, sink chan<- *DepositManagerSlashingChallengerRewarded, layer2 []common.Address, challenger []common.Address) (event.Subscription, error) {

	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}
	var challengerRule []interface{}
	for _, challengerItem := range challenger {
		challengerRule = append(challengerRule, challengerItem)
	}

	logs, sub, err := _DepositManagerSlashing.contract.WatchLogs(opts, "ChallengerRewarded", layer2Rule, challengerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerSlashingChallengerRewarded)
				if err := _DepositManagerSlashing.contract.UnpackLog(event, "ChallengerRewarded", log); err != nil {
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

// ParseChallengerRewarded is a log parse operation binding the contract event 0x00a258f9d794ab8fcbdc7f27cbe8f9305018187f22e7a07c917dcb6dd72960ab.
//
// Solidity: event ChallengerRewarded(address indexed layer2, address indexed challenger, uint256 amount)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) ParseChallengerRewarded(log types.Log) (*DepositManagerSlashingChallengerRewarded, error) {
	event := new(DepositManagerSlashingChallengerRewarded)
	if err := _DepositManagerSlashing.contract.UnpackLog(event, "ChallengerRewarded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DepositManagerSlashingRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the DepositManagerSlashing contract.
type DepositManagerSlashingRoleAdminChangedIterator struct {
	Event *DepositManagerSlashingRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *DepositManagerSlashingRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerSlashingRoleAdminChanged)
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
		it.Event = new(DepositManagerSlashingRoleAdminChanged)
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
func (it *DepositManagerSlashingRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerSlashingRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerSlashingRoleAdminChanged represents a RoleAdminChanged event raised by the DepositManagerSlashing contract.
type DepositManagerSlashingRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*DepositManagerSlashingRoleAdminChangedIterator, error) {

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

	logs, sub, err := _DepositManagerSlashing.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerSlashingRoleAdminChangedIterator{contract: _DepositManagerSlashing.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *DepositManagerSlashingRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _DepositManagerSlashing.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerSlashingRoleAdminChanged)
				if err := _DepositManagerSlashing.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) ParseRoleAdminChanged(log types.Log) (*DepositManagerSlashingRoleAdminChanged, error) {
	event := new(DepositManagerSlashingRoleAdminChanged)
	if err := _DepositManagerSlashing.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DepositManagerSlashingRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the DepositManagerSlashing contract.
type DepositManagerSlashingRoleGrantedIterator struct {
	Event *DepositManagerSlashingRoleGranted // Event containing the contract specifics and raw log

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
func (it *DepositManagerSlashingRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerSlashingRoleGranted)
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
		it.Event = new(DepositManagerSlashingRoleGranted)
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
func (it *DepositManagerSlashingRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerSlashingRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerSlashingRoleGranted represents a RoleGranted event raised by the DepositManagerSlashing contract.
type DepositManagerSlashingRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*DepositManagerSlashingRoleGrantedIterator, error) {

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

	logs, sub, err := _DepositManagerSlashing.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerSlashingRoleGrantedIterator{contract: _DepositManagerSlashing.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *DepositManagerSlashingRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _DepositManagerSlashing.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerSlashingRoleGranted)
				if err := _DepositManagerSlashing.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) ParseRoleGranted(log types.Log) (*DepositManagerSlashingRoleGranted, error) {
	event := new(DepositManagerSlashingRoleGranted)
	if err := _DepositManagerSlashing.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DepositManagerSlashingRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the DepositManagerSlashing contract.
type DepositManagerSlashingRoleRevokedIterator struct {
	Event *DepositManagerSlashingRoleRevoked // Event containing the contract specifics and raw log

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
func (it *DepositManagerSlashingRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerSlashingRoleRevoked)
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
		it.Event = new(DepositManagerSlashingRoleRevoked)
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
func (it *DepositManagerSlashingRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerSlashingRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerSlashingRoleRevoked represents a RoleRevoked event raised by the DepositManagerSlashing contract.
type DepositManagerSlashingRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*DepositManagerSlashingRoleRevokedIterator, error) {

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

	logs, sub, err := _DepositManagerSlashing.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerSlashingRoleRevokedIterator{contract: _DepositManagerSlashing.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *DepositManagerSlashingRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _DepositManagerSlashing.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerSlashingRoleRevoked)
				if err := _DepositManagerSlashing.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) ParseRoleRevoked(log types.Log) (*DepositManagerSlashingRoleRevoked, error) {
	event := new(DepositManagerSlashingRoleRevoked)
	if err := _DepositManagerSlashing.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DepositManagerSlashingSlashedIterator is returned from FilterSlashed and is used to iterate over the raw logs and unpacked data for Slashed events raised by the DepositManagerSlashing contract.
type DepositManagerSlashingSlashedIterator struct {
	Event *DepositManagerSlashingSlashed // Event containing the contract specifics and raw log

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
func (it *DepositManagerSlashingSlashedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerSlashingSlashed)
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
		it.Event = new(DepositManagerSlashingSlashed)
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
func (it *DepositManagerSlashingSlashedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerSlashingSlashedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerSlashingSlashed represents a Slashed event raised by the DepositManagerSlashing contract.
type DepositManagerSlashingSlashed struct {
	Layer2        common.Address
	Operator      common.Address
	Challenger    common.Address
	SlashedAmount *big.Int
	RewardAmount  *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterSlashed is a free log retrieval operation binding the contract event 0x09df3cb1accb9fbac12e8b5bae698faf2ec90f7ac6441409ebe4f369a90e9d7b.
//
// Solidity: event Slashed(address indexed layer2, address indexed operator, address indexed challenger, uint256 slashedAmount, uint256 rewardAmount)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) FilterSlashed(opts *bind.FilterOpts, layer2 []common.Address, operator []common.Address, challenger []common.Address) (*DepositManagerSlashingSlashedIterator, error) {

	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var challengerRule []interface{}
	for _, challengerItem := range challenger {
		challengerRule = append(challengerRule, challengerItem)
	}

	logs, sub, err := _DepositManagerSlashing.contract.FilterLogs(opts, "Slashed", layer2Rule, operatorRule, challengerRule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerSlashingSlashedIterator{contract: _DepositManagerSlashing.contract, event: "Slashed", logs: logs, sub: sub}, nil
}

// WatchSlashed is a free log subscription operation binding the contract event 0x09df3cb1accb9fbac12e8b5bae698faf2ec90f7ac6441409ebe4f369a90e9d7b.
//
// Solidity: event Slashed(address indexed layer2, address indexed operator, address indexed challenger, uint256 slashedAmount, uint256 rewardAmount)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) WatchSlashed(opts *bind.WatchOpts, sink chan<- *DepositManagerSlashingSlashed, layer2 []common.Address, operator []common.Address, challenger []common.Address) (event.Subscription, error) {

	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var challengerRule []interface{}
	for _, challengerItem := range challenger {
		challengerRule = append(challengerRule, challengerItem)
	}

	logs, sub, err := _DepositManagerSlashing.contract.WatchLogs(opts, "Slashed", layer2Rule, operatorRule, challengerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerSlashingSlashed)
				if err := _DepositManagerSlashing.contract.UnpackLog(event, "Slashed", log); err != nil {
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

// ParseSlashed is a log parse operation binding the contract event 0x09df3cb1accb9fbac12e8b5bae698faf2ec90f7ac6441409ebe4f369a90e9d7b.
//
// Solidity: event Slashed(address indexed layer2, address indexed operator, address indexed challenger, uint256 slashedAmount, uint256 rewardAmount)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) ParseSlashed(log types.Log) (*DepositManagerSlashingSlashed, error) {
	event := new(DepositManagerSlashingSlashed)
	if err := _DepositManagerSlashing.contract.UnpackLog(event, "Slashed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DepositManagerSlashingSlashingRewardRateSetIterator is returned from FilterSlashingRewardRateSet and is used to iterate over the raw logs and unpacked data for SlashingRewardRateSet events raised by the DepositManagerSlashing contract.
type DepositManagerSlashingSlashingRewardRateSetIterator struct {
	Event *DepositManagerSlashingSlashingRewardRateSet // Event containing the contract specifics and raw log

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
func (it *DepositManagerSlashingSlashingRewardRateSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerSlashingSlashingRewardRateSet)
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
		it.Event = new(DepositManagerSlashingSlashingRewardRateSet)
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
func (it *DepositManagerSlashingSlashingRewardRateSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerSlashingSlashingRewardRateSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerSlashingSlashingRewardRateSet represents a SlashingRewardRateSet event raised by the DepositManagerSlashing contract.
type DepositManagerSlashingSlashingRewardRateSet struct {
	NewRate *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterSlashingRewardRateSet is a free log retrieval operation binding the contract event 0x4516d205ba286f0de279fdf522722b9a7ea371e7b3cec08a1e073a40896dffb5.
//
// Solidity: event SlashingRewardRateSet(uint256 newRate)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) FilterSlashingRewardRateSet(opts *bind.FilterOpts) (*DepositManagerSlashingSlashingRewardRateSetIterator, error) {

	logs, sub, err := _DepositManagerSlashing.contract.FilterLogs(opts, "SlashingRewardRateSet")
	if err != nil {
		return nil, err
	}
	return &DepositManagerSlashingSlashingRewardRateSetIterator{contract: _DepositManagerSlashing.contract, event: "SlashingRewardRateSet", logs: logs, sub: sub}, nil
}

// WatchSlashingRewardRateSet is a free log subscription operation binding the contract event 0x4516d205ba286f0de279fdf522722b9a7ea371e7b3cec08a1e073a40896dffb5.
//
// Solidity: event SlashingRewardRateSet(uint256 newRate)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) WatchSlashingRewardRateSet(opts *bind.WatchOpts, sink chan<- *DepositManagerSlashingSlashingRewardRateSet) (event.Subscription, error) {

	logs, sub, err := _DepositManagerSlashing.contract.WatchLogs(opts, "SlashingRewardRateSet")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerSlashingSlashingRewardRateSet)
				if err := _DepositManagerSlashing.contract.UnpackLog(event, "SlashingRewardRateSet", log); err != nil {
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

// ParseSlashingRewardRateSet is a log parse operation binding the contract event 0x4516d205ba286f0de279fdf522722b9a7ea371e7b3cec08a1e073a40896dffb5.
//
// Solidity: event SlashingRewardRateSet(uint256 newRate)
func (_DepositManagerSlashing *DepositManagerSlashingFilterer) ParseSlashingRewardRateSet(log types.Log) (*DepositManagerSlashingSlashingRewardRateSet, error) {
	event := new(DepositManagerSlashingSlashingRewardRateSet)
	if err := _DepositManagerSlashing.contract.UnpackLog(event, "SlashingRewardRateSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
