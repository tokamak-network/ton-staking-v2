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

// Layer2ManagerSlashingMetaData contains all meta data concerning the Layer2ManagerSlashing contract.
var Layer2ManagerSlashingMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"aliveImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"cachedBridgedTON\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"dao\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"depositManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isOwner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1BridgeRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"lastBridgedTONUpdateBlock\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minimumInitialDepositAmount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"operatorInfo\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"candidateAddOn\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"operatorManagerFactory\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"operatorOfLayer\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseProxy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxyImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"removeAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"rollupConfigInfo\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"operatorManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"seigManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"selectorImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"sequencerVault\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"slashingCandidate\",\"inputs\":[{\"name\":\"_operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_gameType\",\"type\":\"uint32\",\"internalType\":\"GameType\"},{\"name\":\"_rootClaim\",\"type\":\"bytes32\",\"internalType\":\"Claim\"},{\"name\":\"_extraData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"_disputeGame\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"swapProxy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferAdmin\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"wton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"CandidateSlashed\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"challenger\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"disputeGame\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"SlashingError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"StatusError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZeroAddressError\",\"inputs\":[]}]",
}

// Layer2ManagerSlashingABI is the input ABI used to generate the binding from.
// Deprecated: Use Layer2ManagerSlashingMetaData.ABI instead.
var Layer2ManagerSlashingABI = Layer2ManagerSlashingMetaData.ABI

// Layer2ManagerSlashing is an auto generated Go binding around an Ethereum contract.
type Layer2ManagerSlashing struct {
	Layer2ManagerSlashingCaller     // Read-only binding to the contract
	Layer2ManagerSlashingTransactor // Write-only binding to the contract
	Layer2ManagerSlashingFilterer   // Log filterer for contract events
}

// Layer2ManagerSlashingCaller is an auto generated read-only Go binding around an Ethereum contract.
type Layer2ManagerSlashingCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// Layer2ManagerSlashingTransactor is an auto generated write-only Go binding around an Ethereum contract.
type Layer2ManagerSlashingTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// Layer2ManagerSlashingFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type Layer2ManagerSlashingFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// Layer2ManagerSlashingSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type Layer2ManagerSlashingSession struct {
	Contract     *Layer2ManagerSlashing // Generic contract binding to set the session for
	CallOpts     bind.CallOpts          // Call options to use throughout this session
	TransactOpts bind.TransactOpts      // Transaction auth options to use throughout this session
}

// Layer2ManagerSlashingCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type Layer2ManagerSlashingCallerSession struct {
	Contract *Layer2ManagerSlashingCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts                // Call options to use throughout this session
}

// Layer2ManagerSlashingTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type Layer2ManagerSlashingTransactorSession struct {
	Contract     *Layer2ManagerSlashingTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts                // Transaction auth options to use throughout this session
}

// Layer2ManagerSlashingRaw is an auto generated low-level Go binding around an Ethereum contract.
type Layer2ManagerSlashingRaw struct {
	Contract *Layer2ManagerSlashing // Generic contract binding to access the raw methods on
}

// Layer2ManagerSlashingCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type Layer2ManagerSlashingCallerRaw struct {
	Contract *Layer2ManagerSlashingCaller // Generic read-only contract binding to access the raw methods on
}

// Layer2ManagerSlashingTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type Layer2ManagerSlashingTransactorRaw struct {
	Contract *Layer2ManagerSlashingTransactor // Generic write-only contract binding to access the raw methods on
}

// NewLayer2ManagerSlashing creates a new instance of Layer2ManagerSlashing, bound to a specific deployed contract.
func NewLayer2ManagerSlashing(address common.Address, backend bind.ContractBackend) (*Layer2ManagerSlashing, error) {
	contract, err := bindLayer2ManagerSlashing(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerSlashing{Layer2ManagerSlashingCaller: Layer2ManagerSlashingCaller{contract: contract}, Layer2ManagerSlashingTransactor: Layer2ManagerSlashingTransactor{contract: contract}, Layer2ManagerSlashingFilterer: Layer2ManagerSlashingFilterer{contract: contract}}, nil
}

// NewLayer2ManagerSlashingCaller creates a new read-only instance of Layer2ManagerSlashing, bound to a specific deployed contract.
func NewLayer2ManagerSlashingCaller(address common.Address, caller bind.ContractCaller) (*Layer2ManagerSlashingCaller, error) {
	contract, err := bindLayer2ManagerSlashing(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerSlashingCaller{contract: contract}, nil
}

// NewLayer2ManagerSlashingTransactor creates a new write-only instance of Layer2ManagerSlashing, bound to a specific deployed contract.
func NewLayer2ManagerSlashingTransactor(address common.Address, transactor bind.ContractTransactor) (*Layer2ManagerSlashingTransactor, error) {
	contract, err := bindLayer2ManagerSlashing(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerSlashingTransactor{contract: contract}, nil
}

// NewLayer2ManagerSlashingFilterer creates a new log filterer instance of Layer2ManagerSlashing, bound to a specific deployed contract.
func NewLayer2ManagerSlashingFilterer(address common.Address, filterer bind.ContractFilterer) (*Layer2ManagerSlashingFilterer, error) {
	contract, err := bindLayer2ManagerSlashing(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerSlashingFilterer{contract: contract}, nil
}

// bindLayer2ManagerSlashing binds a generic wrapper to an already deployed contract.
func bindLayer2ManagerSlashing(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := Layer2ManagerSlashingMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Layer2ManagerSlashing *Layer2ManagerSlashingRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Layer2ManagerSlashing.Contract.Layer2ManagerSlashingCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Layer2ManagerSlashing *Layer2ManagerSlashingRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.Layer2ManagerSlashingTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Layer2ManagerSlashing *Layer2ManagerSlashingRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.Layer2ManagerSlashingTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Layer2ManagerSlashing.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _Layer2ManagerSlashing.Contract.DEFAULTADMINROLE(&_Layer2ManagerSlashing.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _Layer2ManagerSlashing.Contract.DEFAULTADMINROLE(&_Layer2ManagerSlashing.CallOpts)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) AliveImplementation(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "aliveImplementation", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _Layer2ManagerSlashing.Contract.AliveImplementation(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _Layer2ManagerSlashing.Contract.AliveImplementation(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// CachedBridgedTON is a free data retrieval call binding the contract method 0xe509ccbb.
//
// Solidity: function cachedBridgedTON(address ) view returns(uint256)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) CachedBridgedTON(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "cachedBridgedTON", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// CachedBridgedTON is a free data retrieval call binding the contract method 0xe509ccbb.
//
// Solidity: function cachedBridgedTON(address ) view returns(uint256)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) CachedBridgedTON(arg0 common.Address) (*big.Int, error) {
	return _Layer2ManagerSlashing.Contract.CachedBridgedTON(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// CachedBridgedTON is a free data retrieval call binding the contract method 0xe509ccbb.
//
// Solidity: function cachedBridgedTON(address ) view returns(uint256)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) CachedBridgedTON(arg0 common.Address) (*big.Int, error) {
	return _Layer2ManagerSlashing.Contract.CachedBridgedTON(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// Dao is a free data retrieval call binding the contract method 0x4162169f.
//
// Solidity: function dao() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) Dao(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "dao")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Dao is a free data retrieval call binding the contract method 0x4162169f.
//
// Solidity: function dao() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) Dao() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.Dao(&_Layer2ManagerSlashing.CallOpts)
}

// Dao is a free data retrieval call binding the contract method 0x4162169f.
//
// Solidity: function dao() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) Dao() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.Dao(&_Layer2ManagerSlashing.CallOpts)
}

// DepositManager is a free data retrieval call binding the contract method 0x6c7ac9d8.
//
// Solidity: function depositManager() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) DepositManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "depositManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// DepositManager is a free data retrieval call binding the contract method 0x6c7ac9d8.
//
// Solidity: function depositManager() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) DepositManager() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.DepositManager(&_Layer2ManagerSlashing.CallOpts)
}

// DepositManager is a free data retrieval call binding the contract method 0x6c7ac9d8.
//
// Solidity: function depositManager() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) DepositManager() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.DepositManager(&_Layer2ManagerSlashing.CallOpts)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _Layer2ManagerSlashing.Contract.GetRoleAdmin(&_Layer2ManagerSlashing.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _Layer2ManagerSlashing.Contract.GetRoleAdmin(&_Layer2ManagerSlashing.CallOpts, role)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _Layer2ManagerSlashing.Contract.HasRole(&_Layer2ManagerSlashing.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _Layer2ManagerSlashing.Contract.HasRole(&_Layer2ManagerSlashing.CallOpts, role, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) IsAdmin(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "isAdmin", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) IsAdmin(account common.Address) (bool, error) {
	return _Layer2ManagerSlashing.Contract.IsAdmin(&_Layer2ManagerSlashing.CallOpts, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) IsAdmin(account common.Address) (bool, error) {
	return _Layer2ManagerSlashing.Contract.IsAdmin(&_Layer2ManagerSlashing.CallOpts, account)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) IsOwner(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "isOwner")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) IsOwner() (bool, error) {
	return _Layer2ManagerSlashing.Contract.IsOwner(&_Layer2ManagerSlashing.CallOpts)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) IsOwner() (bool, error) {
	return _Layer2ManagerSlashing.Contract.IsOwner(&_Layer2ManagerSlashing.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) L1BridgeRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "l1BridgeRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) L1BridgeRegistry() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.L1BridgeRegistry(&_Layer2ManagerSlashing.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) L1BridgeRegistry() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.L1BridgeRegistry(&_Layer2ManagerSlashing.CallOpts)
}

// LastBridgedTONUpdateBlock is a free data retrieval call binding the contract method 0x335f5eee.
//
// Solidity: function lastBridgedTONUpdateBlock(address ) view returns(uint256)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) LastBridgedTONUpdateBlock(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "lastBridgedTONUpdateBlock", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LastBridgedTONUpdateBlock is a free data retrieval call binding the contract method 0x335f5eee.
//
// Solidity: function lastBridgedTONUpdateBlock(address ) view returns(uint256)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) LastBridgedTONUpdateBlock(arg0 common.Address) (*big.Int, error) {
	return _Layer2ManagerSlashing.Contract.LastBridgedTONUpdateBlock(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// LastBridgedTONUpdateBlock is a free data retrieval call binding the contract method 0x335f5eee.
//
// Solidity: function lastBridgedTONUpdateBlock(address ) view returns(uint256)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) LastBridgedTONUpdateBlock(arg0 common.Address) (*big.Int, error) {
	return _Layer2ManagerSlashing.Contract.LastBridgedTONUpdateBlock(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// MinimumInitialDepositAmount is a free data retrieval call binding the contract method 0xe9d6ec4f.
//
// Solidity: function minimumInitialDepositAmount() view returns(uint256)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) MinimumInitialDepositAmount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "minimumInitialDepositAmount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MinimumInitialDepositAmount is a free data retrieval call binding the contract method 0xe9d6ec4f.
//
// Solidity: function minimumInitialDepositAmount() view returns(uint256)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) MinimumInitialDepositAmount() (*big.Int, error) {
	return _Layer2ManagerSlashing.Contract.MinimumInitialDepositAmount(&_Layer2ManagerSlashing.CallOpts)
}

// MinimumInitialDepositAmount is a free data retrieval call binding the contract method 0xe9d6ec4f.
//
// Solidity: function minimumInitialDepositAmount() view returns(uint256)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) MinimumInitialDepositAmount() (*big.Int, error) {
	return _Layer2ManagerSlashing.Contract.MinimumInitialDepositAmount(&_Layer2ManagerSlashing.CallOpts)
}

// OperatorInfo is a free data retrieval call binding the contract method 0x50c246d6.
//
// Solidity: function operatorInfo(address ) view returns(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) OperatorInfo(opts *bind.CallOpts, arg0 common.Address) (struct {
	RollupConfig   common.Address
	CandidateAddOn common.Address
}, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "operatorInfo", arg0)

	outstruct := new(struct {
		RollupConfig   common.Address
		CandidateAddOn common.Address
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.RollupConfig = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.CandidateAddOn = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)

	return *outstruct, err

}

// OperatorInfo is a free data retrieval call binding the contract method 0x50c246d6.
//
// Solidity: function operatorInfo(address ) view returns(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) OperatorInfo(arg0 common.Address) (struct {
	RollupConfig   common.Address
	CandidateAddOn common.Address
}, error) {
	return _Layer2ManagerSlashing.Contract.OperatorInfo(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// OperatorInfo is a free data retrieval call binding the contract method 0x50c246d6.
//
// Solidity: function operatorInfo(address ) view returns(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) OperatorInfo(arg0 common.Address) (struct {
	RollupConfig   common.Address
	CandidateAddOn common.Address
}, error) {
	return _Layer2ManagerSlashing.Contract.OperatorInfo(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// OperatorManagerFactory is a free data retrieval call binding the contract method 0xaba8e577.
//
// Solidity: function operatorManagerFactory() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) OperatorManagerFactory(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "operatorManagerFactory")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// OperatorManagerFactory is a free data retrieval call binding the contract method 0xaba8e577.
//
// Solidity: function operatorManagerFactory() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) OperatorManagerFactory() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.OperatorManagerFactory(&_Layer2ManagerSlashing.CallOpts)
}

// OperatorManagerFactory is a free data retrieval call binding the contract method 0xaba8e577.
//
// Solidity: function operatorManagerFactory() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) OperatorManagerFactory() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.OperatorManagerFactory(&_Layer2ManagerSlashing.CallOpts)
}

// OperatorOfLayer is a free data retrieval call binding the contract method 0xe4a3b456.
//
// Solidity: function operatorOfLayer(address ) view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) OperatorOfLayer(opts *bind.CallOpts, arg0 common.Address) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "operatorOfLayer", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// OperatorOfLayer is a free data retrieval call binding the contract method 0xe4a3b456.
//
// Solidity: function operatorOfLayer(address ) view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) OperatorOfLayer(arg0 common.Address) (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.OperatorOfLayer(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// OperatorOfLayer is a free data retrieval call binding the contract method 0xe4a3b456.
//
// Solidity: function operatorOfLayer(address ) view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) OperatorOfLayer(arg0 common.Address) (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.OperatorOfLayer(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) PauseProxy(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "pauseProxy")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) PauseProxy() (bool, error) {
	return _Layer2ManagerSlashing.Contract.PauseProxy(&_Layer2ManagerSlashing.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) PauseProxy() (bool, error) {
	return _Layer2ManagerSlashing.Contract.PauseProxy(&_Layer2ManagerSlashing.CallOpts)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) ProxyImplementation(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "proxyImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.ProxyImplementation(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.ProxyImplementation(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// RollupConfigInfo is a free data retrieval call binding the contract method 0x72898c23.
//
// Solidity: function rollupConfigInfo(address ) view returns(uint8 status, address operatorManager)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) RollupConfigInfo(opts *bind.CallOpts, arg0 common.Address) (struct {
	Status          uint8
	OperatorManager common.Address
}, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "rollupConfigInfo", arg0)

	outstruct := new(struct {
		Status          uint8
		OperatorManager common.Address
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Status = *abi.ConvertType(out[0], new(uint8)).(*uint8)
	outstruct.OperatorManager = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)

	return *outstruct, err

}

// RollupConfigInfo is a free data retrieval call binding the contract method 0x72898c23.
//
// Solidity: function rollupConfigInfo(address ) view returns(uint8 status, address operatorManager)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) RollupConfigInfo(arg0 common.Address) (struct {
	Status          uint8
	OperatorManager common.Address
}, error) {
	return _Layer2ManagerSlashing.Contract.RollupConfigInfo(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// RollupConfigInfo is a free data retrieval call binding the contract method 0x72898c23.
//
// Solidity: function rollupConfigInfo(address ) view returns(uint8 status, address operatorManager)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) RollupConfigInfo(arg0 common.Address) (struct {
	Status          uint8
	OperatorManager common.Address
}, error) {
	return _Layer2ManagerSlashing.Contract.RollupConfigInfo(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) SeigManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "seigManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) SeigManager() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.SeigManager(&_Layer2ManagerSlashing.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) SeigManager() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.SeigManager(&_Layer2ManagerSlashing.CallOpts)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) SelectorImplementation(opts *bind.CallOpts, arg0 [4]byte) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "selectorImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.SelectorImplementation(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.SelectorImplementation(&_Layer2ManagerSlashing.CallOpts, arg0)
}

// SequencerVault is a free data retrieval call binding the contract method 0x9b8230ac.
//
// Solidity: function sequencerVault() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) SequencerVault(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "sequencerVault")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SequencerVault is a free data retrieval call binding the contract method 0x9b8230ac.
//
// Solidity: function sequencerVault() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) SequencerVault() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.SequencerVault(&_Layer2ManagerSlashing.CallOpts)
}

// SequencerVault is a free data retrieval call binding the contract method 0x9b8230ac.
//
// Solidity: function sequencerVault() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) SequencerVault() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.SequencerVault(&_Layer2ManagerSlashing.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Layer2ManagerSlashing.Contract.SupportsInterface(&_Layer2ManagerSlashing.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Layer2ManagerSlashing.Contract.SupportsInterface(&_Layer2ManagerSlashing.CallOpts, interfaceId)
}

// SwapProxy is a free data retrieval call binding the contract method 0x6ec4be90.
//
// Solidity: function swapProxy() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) SwapProxy(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "swapProxy")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SwapProxy is a free data retrieval call binding the contract method 0x6ec4be90.
//
// Solidity: function swapProxy() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) SwapProxy() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.SwapProxy(&_Layer2ManagerSlashing.CallOpts)
}

// SwapProxy is a free data retrieval call binding the contract method 0x6ec4be90.
//
// Solidity: function swapProxy() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) SwapProxy() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.SwapProxy(&_Layer2ManagerSlashing.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) Ton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "ton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) Ton() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.Ton(&_Layer2ManagerSlashing.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) Ton() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.Ton(&_Layer2ManagerSlashing.CallOpts)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCaller) Wton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerSlashing.contract.Call(opts, &out, "wton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) Wton() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.Wton(&_Layer2ManagerSlashing.CallOpts)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingCallerSession) Wton() (common.Address, error) {
	return _Layer2ManagerSlashing.Contract.Wton(&_Layer2ManagerSlashing.CallOpts)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactor) AddAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.contract.Transact(opts, "addAdmin", account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.AddAdmin(&_Layer2ManagerSlashing.TransactOpts, account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.AddAdmin(&_Layer2ManagerSlashing.TransactOpts, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.GrantRole(&_Layer2ManagerSlashing.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.GrantRole(&_Layer2ManagerSlashing.TransactOpts, role, account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactor) RemoveAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.contract.Transact(opts, "removeAdmin", account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.RemoveAdmin(&_Layer2ManagerSlashing.TransactOpts, account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.RemoveAdmin(&_Layer2ManagerSlashing.TransactOpts, account)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) RenounceOwnership() (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.RenounceOwnership(&_Layer2ManagerSlashing.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.RenounceOwnership(&_Layer2ManagerSlashing.TransactOpts)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.contract.Transact(opts, "renounceRole", role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.RenounceRole(&_Layer2ManagerSlashing.TransactOpts, role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.RenounceRole(&_Layer2ManagerSlashing.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.RevokeRole(&_Layer2ManagerSlashing.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.RevokeRole(&_Layer2ManagerSlashing.TransactOpts, role, account)
}

// SlashingCandidate is a paid mutator transaction binding the contract method 0x2a184612.
//
// Solidity: function slashingCandidate(address _operator, uint32 _gameType, bytes32 _rootClaim, bytes _extraData, address _disputeGame) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactor) SlashingCandidate(opts *bind.TransactOpts, _operator common.Address, _gameType uint32, _rootClaim [32]byte, _extraData []byte, _disputeGame common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.contract.Transact(opts, "slashingCandidate", _operator, _gameType, _rootClaim, _extraData, _disputeGame)
}

// SlashingCandidate is a paid mutator transaction binding the contract method 0x2a184612.
//
// Solidity: function slashingCandidate(address _operator, uint32 _gameType, bytes32 _rootClaim, bytes _extraData, address _disputeGame) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) SlashingCandidate(_operator common.Address, _gameType uint32, _rootClaim [32]byte, _extraData []byte, _disputeGame common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.SlashingCandidate(&_Layer2ManagerSlashing.TransactOpts, _operator, _gameType, _rootClaim, _extraData, _disputeGame)
}

// SlashingCandidate is a paid mutator transaction binding the contract method 0x2a184612.
//
// Solidity: function slashingCandidate(address _operator, uint32 _gameType, bytes32 _rootClaim, bytes _extraData, address _disputeGame) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorSession) SlashingCandidate(_operator common.Address, _gameType uint32, _rootClaim [32]byte, _extraData []byte, _disputeGame common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.SlashingCandidate(&_Layer2ManagerSlashing.TransactOpts, _operator, _gameType, _rootClaim, _extraData, _disputeGame)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactor) TransferAdmin(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.contract.Transact(opts, "transferAdmin", newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.TransferAdmin(&_Layer2ManagerSlashing.TransactOpts, newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.TransferAdmin(&_Layer2ManagerSlashing.TransactOpts, newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactor) TransferOwnership(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.contract.Transact(opts, "transferOwnership", newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingSession) TransferOwnership(newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.TransferOwnership(&_Layer2ManagerSlashing.TransactOpts, newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_Layer2ManagerSlashing *Layer2ManagerSlashingTransactorSession) TransferOwnership(newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerSlashing.Contract.TransferOwnership(&_Layer2ManagerSlashing.TransactOpts, newAdmin)
}

// Layer2ManagerSlashingCandidateSlashedIterator is returned from FilterCandidateSlashed and is used to iterate over the raw logs and unpacked data for CandidateSlashed events raised by the Layer2ManagerSlashing contract.
type Layer2ManagerSlashingCandidateSlashedIterator struct {
	Event *Layer2ManagerSlashingCandidateSlashed // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerSlashingCandidateSlashedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerSlashingCandidateSlashed)
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
		it.Event = new(Layer2ManagerSlashingCandidateSlashed)
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
func (it *Layer2ManagerSlashingCandidateSlashedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerSlashingCandidateSlashedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerSlashingCandidateSlashed represents a CandidateSlashed event raised by the Layer2ManagerSlashing contract.
type Layer2ManagerSlashingCandidateSlashed struct {
	Operator    common.Address
	Challenger  common.Address
	DisputeGame common.Address
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterCandidateSlashed is a free log retrieval operation binding the contract event 0x057aca867c8676e2a0e00d02fd02312a48400f6fa3f6f621572e982d193d3912.
//
// Solidity: event CandidateSlashed(address indexed operator, address indexed challenger, address disputeGame)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) FilterCandidateSlashed(opts *bind.FilterOpts, operator []common.Address, challenger []common.Address) (*Layer2ManagerSlashingCandidateSlashedIterator, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var challengerRule []interface{}
	for _, challengerItem := range challenger {
		challengerRule = append(challengerRule, challengerItem)
	}

	logs, sub, err := _Layer2ManagerSlashing.contract.FilterLogs(opts, "CandidateSlashed", operatorRule, challengerRule)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerSlashingCandidateSlashedIterator{contract: _Layer2ManagerSlashing.contract, event: "CandidateSlashed", logs: logs, sub: sub}, nil
}

// WatchCandidateSlashed is a free log subscription operation binding the contract event 0x057aca867c8676e2a0e00d02fd02312a48400f6fa3f6f621572e982d193d3912.
//
// Solidity: event CandidateSlashed(address indexed operator, address indexed challenger, address disputeGame)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) WatchCandidateSlashed(opts *bind.WatchOpts, sink chan<- *Layer2ManagerSlashingCandidateSlashed, operator []common.Address, challenger []common.Address) (event.Subscription, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var challengerRule []interface{}
	for _, challengerItem := range challenger {
		challengerRule = append(challengerRule, challengerItem)
	}

	logs, sub, err := _Layer2ManagerSlashing.contract.WatchLogs(opts, "CandidateSlashed", operatorRule, challengerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerSlashingCandidateSlashed)
				if err := _Layer2ManagerSlashing.contract.UnpackLog(event, "CandidateSlashed", log); err != nil {
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

// ParseCandidateSlashed is a log parse operation binding the contract event 0x057aca867c8676e2a0e00d02fd02312a48400f6fa3f6f621572e982d193d3912.
//
// Solidity: event CandidateSlashed(address indexed operator, address indexed challenger, address disputeGame)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) ParseCandidateSlashed(log types.Log) (*Layer2ManagerSlashingCandidateSlashed, error) {
	event := new(Layer2ManagerSlashingCandidateSlashed)
	if err := _Layer2ManagerSlashing.contract.UnpackLog(event, "CandidateSlashed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerSlashingRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the Layer2ManagerSlashing contract.
type Layer2ManagerSlashingRoleAdminChangedIterator struct {
	Event *Layer2ManagerSlashingRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerSlashingRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerSlashingRoleAdminChanged)
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
		it.Event = new(Layer2ManagerSlashingRoleAdminChanged)
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
func (it *Layer2ManagerSlashingRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerSlashingRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerSlashingRoleAdminChanged represents a RoleAdminChanged event raised by the Layer2ManagerSlashing contract.
type Layer2ManagerSlashingRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*Layer2ManagerSlashingRoleAdminChangedIterator, error) {

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

	logs, sub, err := _Layer2ManagerSlashing.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerSlashingRoleAdminChangedIterator{contract: _Layer2ManagerSlashing.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *Layer2ManagerSlashingRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _Layer2ManagerSlashing.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerSlashingRoleAdminChanged)
				if err := _Layer2ManagerSlashing.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) ParseRoleAdminChanged(log types.Log) (*Layer2ManagerSlashingRoleAdminChanged, error) {
	event := new(Layer2ManagerSlashingRoleAdminChanged)
	if err := _Layer2ManagerSlashing.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerSlashingRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the Layer2ManagerSlashing contract.
type Layer2ManagerSlashingRoleGrantedIterator struct {
	Event *Layer2ManagerSlashingRoleGranted // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerSlashingRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerSlashingRoleGranted)
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
		it.Event = new(Layer2ManagerSlashingRoleGranted)
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
func (it *Layer2ManagerSlashingRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerSlashingRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerSlashingRoleGranted represents a RoleGranted event raised by the Layer2ManagerSlashing contract.
type Layer2ManagerSlashingRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*Layer2ManagerSlashingRoleGrantedIterator, error) {

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

	logs, sub, err := _Layer2ManagerSlashing.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerSlashingRoleGrantedIterator{contract: _Layer2ManagerSlashing.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *Layer2ManagerSlashingRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _Layer2ManagerSlashing.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerSlashingRoleGranted)
				if err := _Layer2ManagerSlashing.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) ParseRoleGranted(log types.Log) (*Layer2ManagerSlashingRoleGranted, error) {
	event := new(Layer2ManagerSlashingRoleGranted)
	if err := _Layer2ManagerSlashing.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerSlashingRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the Layer2ManagerSlashing contract.
type Layer2ManagerSlashingRoleRevokedIterator struct {
	Event *Layer2ManagerSlashingRoleRevoked // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerSlashingRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerSlashingRoleRevoked)
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
		it.Event = new(Layer2ManagerSlashingRoleRevoked)
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
func (it *Layer2ManagerSlashingRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerSlashingRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerSlashingRoleRevoked represents a RoleRevoked event raised by the Layer2ManagerSlashing contract.
type Layer2ManagerSlashingRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*Layer2ManagerSlashingRoleRevokedIterator, error) {

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

	logs, sub, err := _Layer2ManagerSlashing.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerSlashingRoleRevokedIterator{contract: _Layer2ManagerSlashing.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *Layer2ManagerSlashingRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _Layer2ManagerSlashing.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerSlashingRoleRevoked)
				if err := _Layer2ManagerSlashing.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_Layer2ManagerSlashing *Layer2ManagerSlashingFilterer) ParseRoleRevoked(log types.Log) (*Layer2ManagerSlashingRoleRevoked, error) {
	event := new(Layer2ManagerSlashingRoleRevoked)
	if err := _Layer2ManagerSlashing.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
