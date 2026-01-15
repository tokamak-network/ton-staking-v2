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

// DepositManagerMetaData contains all meta data concerning the DepositManager contract.
var DepositManagerMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"accStaked\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"accStakedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"accStakedLayer2\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"accUnstaked\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"accUnstakedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"accUnstakedLayer2\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"aliveImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deposit\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"deposit\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"accounts\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"deposit\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getDelayBlocks\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"globalWithdrawalDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"wton_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"registry_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"seigManager_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"globalWithdrawalDelay_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"oldDepositManager_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isOwner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"numPendingRequests\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"numRequests\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"oldDepositManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"onApprove\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"pauseProxy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingUnstaked\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingUnstakedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingUnstakedLayer2\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"processRequest\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiveTON\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"processRequests\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"n\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiveTON\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proxyImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"redeposit\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"redepositMulti\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"n\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"removeAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"requestWithdrawal\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"requestWithdrawalAll\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"seigManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"selectorImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setGlobalWithdrawalDelay\",\"inputs\":[{\"name\":\"globalWithdrawalDelay_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSeigManager\",\"inputs\":[{\"name\":\"seigManager_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setWithdrawalDelay\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"withdrawalDelay_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferAdmin\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdrawalDelay\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdrawalRequest\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"withdrawableBlockNumber\",\"type\":\"uint128\",\"internalType\":\"uint128\"},{\"name\":\"amount\",\"type\":\"uint128\",\"internalType\":\"uint128\"},{\"name\":\"processed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdrawalRequestIndex\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"wton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"Deposited\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawalProcessed\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawalRequested\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false}]",
}

// DepositManagerABI is the input ABI used to generate the binding from.
// Deprecated: Use DepositManagerMetaData.ABI instead.
var DepositManagerABI = DepositManagerMetaData.ABI

// DepositManager is an auto generated Go binding around an Ethereum contract.
type DepositManager struct {
	DepositManagerCaller     // Read-only binding to the contract
	DepositManagerTransactor // Write-only binding to the contract
	DepositManagerFilterer   // Log filterer for contract events
}

// DepositManagerCaller is an auto generated read-only Go binding around an Ethereum contract.
type DepositManagerCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DepositManagerTransactor is an auto generated write-only Go binding around an Ethereum contract.
type DepositManagerTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DepositManagerFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type DepositManagerFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DepositManagerSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type DepositManagerSession struct {
	Contract     *DepositManager   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// DepositManagerCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type DepositManagerCallerSession struct {
	Contract *DepositManagerCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// DepositManagerTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type DepositManagerTransactorSession struct {
	Contract     *DepositManagerTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// DepositManagerRaw is an auto generated low-level Go binding around an Ethereum contract.
type DepositManagerRaw struct {
	Contract *DepositManager // Generic contract binding to access the raw methods on
}

// DepositManagerCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type DepositManagerCallerRaw struct {
	Contract *DepositManagerCaller // Generic read-only contract binding to access the raw methods on
}

// DepositManagerTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type DepositManagerTransactorRaw struct {
	Contract *DepositManagerTransactor // Generic write-only contract binding to access the raw methods on
}

// NewDepositManager creates a new instance of DepositManager, bound to a specific deployed contract.
func NewDepositManager(address common.Address, backend bind.ContractBackend) (*DepositManager, error) {
	contract, err := bindDepositManager(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &DepositManager{DepositManagerCaller: DepositManagerCaller{contract: contract}, DepositManagerTransactor: DepositManagerTransactor{contract: contract}, DepositManagerFilterer: DepositManagerFilterer{contract: contract}}, nil
}

// NewDepositManagerCaller creates a new read-only instance of DepositManager, bound to a specific deployed contract.
func NewDepositManagerCaller(address common.Address, caller bind.ContractCaller) (*DepositManagerCaller, error) {
	contract, err := bindDepositManager(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &DepositManagerCaller{contract: contract}, nil
}

// NewDepositManagerTransactor creates a new write-only instance of DepositManager, bound to a specific deployed contract.
func NewDepositManagerTransactor(address common.Address, transactor bind.ContractTransactor) (*DepositManagerTransactor, error) {
	contract, err := bindDepositManager(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &DepositManagerTransactor{contract: contract}, nil
}

// NewDepositManagerFilterer creates a new log filterer instance of DepositManager, bound to a specific deployed contract.
func NewDepositManagerFilterer(address common.Address, filterer bind.ContractFilterer) (*DepositManagerFilterer, error) {
	contract, err := bindDepositManager(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &DepositManagerFilterer{contract: contract}, nil
}

// bindDepositManager binds a generic wrapper to an already deployed contract.
func bindDepositManager(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := DepositManagerMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_DepositManager *DepositManagerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _DepositManager.Contract.DepositManagerCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_DepositManager *DepositManagerRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DepositManager.Contract.DepositManagerTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_DepositManager *DepositManagerRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _DepositManager.Contract.DepositManagerTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_DepositManager *DepositManagerCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _DepositManager.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_DepositManager *DepositManagerTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DepositManager.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_DepositManager *DepositManagerTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _DepositManager.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_DepositManager *DepositManagerCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_DepositManager *DepositManagerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _DepositManager.Contract.DEFAULTADMINROLE(&_DepositManager.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_DepositManager *DepositManagerCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _DepositManager.Contract.DEFAULTADMINROLE(&_DepositManager.CallOpts)
}

// AccStaked is a free data retrieval call binding the contract method 0x2d2fab94.
//
// Solidity: function accStaked(address layer2, address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCaller) AccStaked(opts *bind.CallOpts, layer2 common.Address, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "accStaked", layer2, account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AccStaked is a free data retrieval call binding the contract method 0x2d2fab94.
//
// Solidity: function accStaked(address layer2, address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerSession) AccStaked(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccStaked(&_DepositManager.CallOpts, layer2, account)
}

// AccStaked is a free data retrieval call binding the contract method 0x2d2fab94.
//
// Solidity: function accStaked(address layer2, address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCallerSession) AccStaked(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccStaked(&_DepositManager.CallOpts, layer2, account)
}

// AccStakedAccount is a free data retrieval call binding the contract method 0x0055f5c1.
//
// Solidity: function accStakedAccount(address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCaller) AccStakedAccount(opts *bind.CallOpts, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "accStakedAccount", account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AccStakedAccount is a free data retrieval call binding the contract method 0x0055f5c1.
//
// Solidity: function accStakedAccount(address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerSession) AccStakedAccount(account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccStakedAccount(&_DepositManager.CallOpts, account)
}

// AccStakedAccount is a free data retrieval call binding the contract method 0x0055f5c1.
//
// Solidity: function accStakedAccount(address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCallerSession) AccStakedAccount(account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccStakedAccount(&_DepositManager.CallOpts, account)
}

// AccStakedLayer2 is a free data retrieval call binding the contract method 0x010ca390.
//
// Solidity: function accStakedLayer2(address layer2) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCaller) AccStakedLayer2(opts *bind.CallOpts, layer2 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "accStakedLayer2", layer2)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AccStakedLayer2 is a free data retrieval call binding the contract method 0x010ca390.
//
// Solidity: function accStakedLayer2(address layer2) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerSession) AccStakedLayer2(layer2 common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccStakedLayer2(&_DepositManager.CallOpts, layer2)
}

// AccStakedLayer2 is a free data retrieval call binding the contract method 0x010ca390.
//
// Solidity: function accStakedLayer2(address layer2) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCallerSession) AccStakedLayer2(layer2 common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccStakedLayer2(&_DepositManager.CallOpts, layer2)
}

// AccUnstaked is a free data retrieval call binding the contract method 0x9d91b87b.
//
// Solidity: function accUnstaked(address layer2, address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCaller) AccUnstaked(opts *bind.CallOpts, layer2 common.Address, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "accUnstaked", layer2, account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AccUnstaked is a free data retrieval call binding the contract method 0x9d91b87b.
//
// Solidity: function accUnstaked(address layer2, address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerSession) AccUnstaked(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccUnstaked(&_DepositManager.CallOpts, layer2, account)
}

// AccUnstaked is a free data retrieval call binding the contract method 0x9d91b87b.
//
// Solidity: function accUnstaked(address layer2, address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCallerSession) AccUnstaked(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccUnstaked(&_DepositManager.CallOpts, layer2, account)
}

// AccUnstakedAccount is a free data retrieval call binding the contract method 0xa3543989.
//
// Solidity: function accUnstakedAccount(address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCaller) AccUnstakedAccount(opts *bind.CallOpts, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "accUnstakedAccount", account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AccUnstakedAccount is a free data retrieval call binding the contract method 0xa3543989.
//
// Solidity: function accUnstakedAccount(address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerSession) AccUnstakedAccount(account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccUnstakedAccount(&_DepositManager.CallOpts, account)
}

// AccUnstakedAccount is a free data retrieval call binding the contract method 0xa3543989.
//
// Solidity: function accUnstakedAccount(address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCallerSession) AccUnstakedAccount(account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccUnstakedAccount(&_DepositManager.CallOpts, account)
}

// AccUnstakedLayer2 is a free data retrieval call binding the contract method 0x8af4a948.
//
// Solidity: function accUnstakedLayer2(address layer2) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCaller) AccUnstakedLayer2(opts *bind.CallOpts, layer2 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "accUnstakedLayer2", layer2)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AccUnstakedLayer2 is a free data retrieval call binding the contract method 0x8af4a948.
//
// Solidity: function accUnstakedLayer2(address layer2) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerSession) AccUnstakedLayer2(layer2 common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccUnstakedLayer2(&_DepositManager.CallOpts, layer2)
}

// AccUnstakedLayer2 is a free data retrieval call binding the contract method 0x8af4a948.
//
// Solidity: function accUnstakedLayer2(address layer2) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCallerSession) AccUnstakedLayer2(layer2 common.Address) (*big.Int, error) {
	return _DepositManager.Contract.AccUnstakedLayer2(&_DepositManager.CallOpts, layer2)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_DepositManager *DepositManagerCaller) AliveImplementation(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "aliveImplementation", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_DepositManager *DepositManagerSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _DepositManager.Contract.AliveImplementation(&_DepositManager.CallOpts, arg0)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_DepositManager *DepositManagerCallerSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _DepositManager.Contract.AliveImplementation(&_DepositManager.CallOpts, arg0)
}

// GetDelayBlocks is a free data retrieval call binding the contract method 0xb5f19db2.
//
// Solidity: function getDelayBlocks(address layer2) view returns(uint256)
func (_DepositManager *DepositManagerCaller) GetDelayBlocks(opts *bind.CallOpts, layer2 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "getDelayBlocks", layer2)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetDelayBlocks is a free data retrieval call binding the contract method 0xb5f19db2.
//
// Solidity: function getDelayBlocks(address layer2) view returns(uint256)
func (_DepositManager *DepositManagerSession) GetDelayBlocks(layer2 common.Address) (*big.Int, error) {
	return _DepositManager.Contract.GetDelayBlocks(&_DepositManager.CallOpts, layer2)
}

// GetDelayBlocks is a free data retrieval call binding the contract method 0xb5f19db2.
//
// Solidity: function getDelayBlocks(address layer2) view returns(uint256)
func (_DepositManager *DepositManagerCallerSession) GetDelayBlocks(layer2 common.Address) (*big.Int, error) {
	return _DepositManager.Contract.GetDelayBlocks(&_DepositManager.CallOpts, layer2)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_DepositManager *DepositManagerCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_DepositManager *DepositManagerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _DepositManager.Contract.GetRoleAdmin(&_DepositManager.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_DepositManager *DepositManagerCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _DepositManager.Contract.GetRoleAdmin(&_DepositManager.CallOpts, role)
}

// GlobalWithdrawalDelay is a free data retrieval call binding the contract method 0x6ec3d5ae.
//
// Solidity: function globalWithdrawalDelay() view returns(uint256)
func (_DepositManager *DepositManagerCaller) GlobalWithdrawalDelay(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "globalWithdrawalDelay")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GlobalWithdrawalDelay is a free data retrieval call binding the contract method 0x6ec3d5ae.
//
// Solidity: function globalWithdrawalDelay() view returns(uint256)
func (_DepositManager *DepositManagerSession) GlobalWithdrawalDelay() (*big.Int, error) {
	return _DepositManager.Contract.GlobalWithdrawalDelay(&_DepositManager.CallOpts)
}

// GlobalWithdrawalDelay is a free data retrieval call binding the contract method 0x6ec3d5ae.
//
// Solidity: function globalWithdrawalDelay() view returns(uint256)
func (_DepositManager *DepositManagerCallerSession) GlobalWithdrawalDelay() (*big.Int, error) {
	return _DepositManager.Contract.GlobalWithdrawalDelay(&_DepositManager.CallOpts)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_DepositManager *DepositManagerCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_DepositManager *DepositManagerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _DepositManager.Contract.HasRole(&_DepositManager.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_DepositManager *DepositManagerCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _DepositManager.Contract.HasRole(&_DepositManager.CallOpts, role, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_DepositManager *DepositManagerCaller) IsAdmin(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "isAdmin", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_DepositManager *DepositManagerSession) IsAdmin(account common.Address) (bool, error) {
	return _DepositManager.Contract.IsAdmin(&_DepositManager.CallOpts, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_DepositManager *DepositManagerCallerSession) IsAdmin(account common.Address) (bool, error) {
	return _DepositManager.Contract.IsAdmin(&_DepositManager.CallOpts, account)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_DepositManager *DepositManagerCaller) IsOwner(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "isOwner")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_DepositManager *DepositManagerSession) IsOwner() (bool, error) {
	return _DepositManager.Contract.IsOwner(&_DepositManager.CallOpts)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_DepositManager *DepositManagerCallerSession) IsOwner() (bool, error) {
	return _DepositManager.Contract.IsOwner(&_DepositManager.CallOpts)
}

// NumPendingRequests is a free data retrieval call binding the contract method 0x5c0df46b.
//
// Solidity: function numPendingRequests(address layer2, address account) view returns(uint256)
func (_DepositManager *DepositManagerCaller) NumPendingRequests(opts *bind.CallOpts, layer2 common.Address, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "numPendingRequests", layer2, account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// NumPendingRequests is a free data retrieval call binding the contract method 0x5c0df46b.
//
// Solidity: function numPendingRequests(address layer2, address account) view returns(uint256)
func (_DepositManager *DepositManagerSession) NumPendingRequests(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.NumPendingRequests(&_DepositManager.CallOpts, layer2, account)
}

// NumPendingRequests is a free data retrieval call binding the contract method 0x5c0df46b.
//
// Solidity: function numPendingRequests(address layer2, address account) view returns(uint256)
func (_DepositManager *DepositManagerCallerSession) NumPendingRequests(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.NumPendingRequests(&_DepositManager.CallOpts, layer2, account)
}

// NumRequests is a free data retrieval call binding the contract method 0xf762eb57.
//
// Solidity: function numRequests(address layer2, address account) view returns(uint256)
func (_DepositManager *DepositManagerCaller) NumRequests(opts *bind.CallOpts, layer2 common.Address, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "numRequests", layer2, account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// NumRequests is a free data retrieval call binding the contract method 0xf762eb57.
//
// Solidity: function numRequests(address layer2, address account) view returns(uint256)
func (_DepositManager *DepositManagerSession) NumRequests(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.NumRequests(&_DepositManager.CallOpts, layer2, account)
}

// NumRequests is a free data retrieval call binding the contract method 0xf762eb57.
//
// Solidity: function numRequests(address layer2, address account) view returns(uint256)
func (_DepositManager *DepositManagerCallerSession) NumRequests(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.NumRequests(&_DepositManager.CallOpts, layer2, account)
}

// OldDepositManager is a free data retrieval call binding the contract method 0x2153c239.
//
// Solidity: function oldDepositManager() view returns(address)
func (_DepositManager *DepositManagerCaller) OldDepositManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "oldDepositManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// OldDepositManager is a free data retrieval call binding the contract method 0x2153c239.
//
// Solidity: function oldDepositManager() view returns(address)
func (_DepositManager *DepositManagerSession) OldDepositManager() (common.Address, error) {
	return _DepositManager.Contract.OldDepositManager(&_DepositManager.CallOpts)
}

// OldDepositManager is a free data retrieval call binding the contract method 0x2153c239.
//
// Solidity: function oldDepositManager() view returns(address)
func (_DepositManager *DepositManagerCallerSession) OldDepositManager() (common.Address, error) {
	return _DepositManager.Contract.OldDepositManager(&_DepositManager.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_DepositManager *DepositManagerCaller) PauseProxy(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "pauseProxy")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_DepositManager *DepositManagerSession) PauseProxy() (bool, error) {
	return _DepositManager.Contract.PauseProxy(&_DepositManager.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_DepositManager *DepositManagerCallerSession) PauseProxy() (bool, error) {
	return _DepositManager.Contract.PauseProxy(&_DepositManager.CallOpts)
}

// PendingUnstaked is a free data retrieval call binding the contract method 0x2638fdf5.
//
// Solidity: function pendingUnstaked(address layer2, address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCaller) PendingUnstaked(opts *bind.CallOpts, layer2 common.Address, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "pendingUnstaked", layer2, account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PendingUnstaked is a free data retrieval call binding the contract method 0x2638fdf5.
//
// Solidity: function pendingUnstaked(address layer2, address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerSession) PendingUnstaked(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.PendingUnstaked(&_DepositManager.CallOpts, layer2, account)
}

// PendingUnstaked is a free data retrieval call binding the contract method 0x2638fdf5.
//
// Solidity: function pendingUnstaked(address layer2, address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCallerSession) PendingUnstaked(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.PendingUnstaked(&_DepositManager.CallOpts, layer2, account)
}

// PendingUnstakedAccount is a free data retrieval call binding the contract method 0xa0b2a913.
//
// Solidity: function pendingUnstakedAccount(address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCaller) PendingUnstakedAccount(opts *bind.CallOpts, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "pendingUnstakedAccount", account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PendingUnstakedAccount is a free data retrieval call binding the contract method 0xa0b2a913.
//
// Solidity: function pendingUnstakedAccount(address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerSession) PendingUnstakedAccount(account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.PendingUnstakedAccount(&_DepositManager.CallOpts, account)
}

// PendingUnstakedAccount is a free data retrieval call binding the contract method 0xa0b2a913.
//
// Solidity: function pendingUnstakedAccount(address account) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCallerSession) PendingUnstakedAccount(account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.PendingUnstakedAccount(&_DepositManager.CallOpts, account)
}

// PendingUnstakedLayer2 is a free data retrieval call binding the contract method 0xd285f78c.
//
// Solidity: function pendingUnstakedLayer2(address layer2) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCaller) PendingUnstakedLayer2(opts *bind.CallOpts, layer2 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "pendingUnstakedLayer2", layer2)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PendingUnstakedLayer2 is a free data retrieval call binding the contract method 0xd285f78c.
//
// Solidity: function pendingUnstakedLayer2(address layer2) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerSession) PendingUnstakedLayer2(layer2 common.Address) (*big.Int, error) {
	return _DepositManager.Contract.PendingUnstakedLayer2(&_DepositManager.CallOpts, layer2)
}

// PendingUnstakedLayer2 is a free data retrieval call binding the contract method 0xd285f78c.
//
// Solidity: function pendingUnstakedLayer2(address layer2) view returns(uint256 wtonAmount)
func (_DepositManager *DepositManagerCallerSession) PendingUnstakedLayer2(layer2 common.Address) (*big.Int, error) {
	return _DepositManager.Contract.PendingUnstakedLayer2(&_DepositManager.CallOpts, layer2)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_DepositManager *DepositManagerCaller) ProxyImplementation(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "proxyImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_DepositManager *DepositManagerSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _DepositManager.Contract.ProxyImplementation(&_DepositManager.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_DepositManager *DepositManagerCallerSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _DepositManager.Contract.ProxyImplementation(&_DepositManager.CallOpts, arg0)
}

// Registry is a free data retrieval call binding the contract method 0x7b103999.
//
// Solidity: function registry() view returns(address)
func (_DepositManager *DepositManagerCaller) Registry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "registry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Registry is a free data retrieval call binding the contract method 0x7b103999.
//
// Solidity: function registry() view returns(address)
func (_DepositManager *DepositManagerSession) Registry() (common.Address, error) {
	return _DepositManager.Contract.Registry(&_DepositManager.CallOpts)
}

// Registry is a free data retrieval call binding the contract method 0x7b103999.
//
// Solidity: function registry() view returns(address)
func (_DepositManager *DepositManagerCallerSession) Registry() (common.Address, error) {
	return _DepositManager.Contract.Registry(&_DepositManager.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_DepositManager *DepositManagerCaller) SeigManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "seigManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_DepositManager *DepositManagerSession) SeigManager() (common.Address, error) {
	return _DepositManager.Contract.SeigManager(&_DepositManager.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_DepositManager *DepositManagerCallerSession) SeigManager() (common.Address, error) {
	return _DepositManager.Contract.SeigManager(&_DepositManager.CallOpts)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_DepositManager *DepositManagerCaller) SelectorImplementation(opts *bind.CallOpts, arg0 [4]byte) (common.Address, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "selectorImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_DepositManager *DepositManagerSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _DepositManager.Contract.SelectorImplementation(&_DepositManager.CallOpts, arg0)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_DepositManager *DepositManagerCallerSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _DepositManager.Contract.SelectorImplementation(&_DepositManager.CallOpts, arg0)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_DepositManager *DepositManagerCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_DepositManager *DepositManagerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _DepositManager.Contract.SupportsInterface(&_DepositManager.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_DepositManager *DepositManagerCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _DepositManager.Contract.SupportsInterface(&_DepositManager.CallOpts, interfaceId)
}

// WithdrawalDelay is a free data retrieval call binding the contract method 0x4ce97036.
//
// Solidity: function withdrawalDelay(address ) view returns(uint256)
func (_DepositManager *DepositManagerCaller) WithdrawalDelay(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "withdrawalDelay", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WithdrawalDelay is a free data retrieval call binding the contract method 0x4ce97036.
//
// Solidity: function withdrawalDelay(address ) view returns(uint256)
func (_DepositManager *DepositManagerSession) WithdrawalDelay(arg0 common.Address) (*big.Int, error) {
	return _DepositManager.Contract.WithdrawalDelay(&_DepositManager.CallOpts, arg0)
}

// WithdrawalDelay is a free data retrieval call binding the contract method 0x4ce97036.
//
// Solidity: function withdrawalDelay(address ) view returns(uint256)
func (_DepositManager *DepositManagerCallerSession) WithdrawalDelay(arg0 common.Address) (*big.Int, error) {
	return _DepositManager.Contract.WithdrawalDelay(&_DepositManager.CallOpts, arg0)
}

// WithdrawalRequest is a free data retrieval call binding the contract method 0x8fbef2d0.
//
// Solidity: function withdrawalRequest(address layer2, address account, uint256 index) view returns(uint128 withdrawableBlockNumber, uint128 amount, bool processed)
func (_DepositManager *DepositManagerCaller) WithdrawalRequest(opts *bind.CallOpts, layer2 common.Address, account common.Address, index *big.Int) (struct {
	WithdrawableBlockNumber *big.Int
	Amount                  *big.Int
	Processed               bool
}, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "withdrawalRequest", layer2, account, index)

	outstruct := new(struct {
		WithdrawableBlockNumber *big.Int
		Amount                  *big.Int
		Processed               bool
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.WithdrawableBlockNumber = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.Amount = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.Processed = *abi.ConvertType(out[2], new(bool)).(*bool)

	return *outstruct, err

}

// WithdrawalRequest is a free data retrieval call binding the contract method 0x8fbef2d0.
//
// Solidity: function withdrawalRequest(address layer2, address account, uint256 index) view returns(uint128 withdrawableBlockNumber, uint128 amount, bool processed)
func (_DepositManager *DepositManagerSession) WithdrawalRequest(layer2 common.Address, account common.Address, index *big.Int) (struct {
	WithdrawableBlockNumber *big.Int
	Amount                  *big.Int
	Processed               bool
}, error) {
	return _DepositManager.Contract.WithdrawalRequest(&_DepositManager.CallOpts, layer2, account, index)
}

// WithdrawalRequest is a free data retrieval call binding the contract method 0x8fbef2d0.
//
// Solidity: function withdrawalRequest(address layer2, address account, uint256 index) view returns(uint128 withdrawableBlockNumber, uint128 amount, bool processed)
func (_DepositManager *DepositManagerCallerSession) WithdrawalRequest(layer2 common.Address, account common.Address, index *big.Int) (struct {
	WithdrawableBlockNumber *big.Int
	Amount                  *big.Int
	Processed               bool
}, error) {
	return _DepositManager.Contract.WithdrawalRequest(&_DepositManager.CallOpts, layer2, account, index)
}

// WithdrawalRequestIndex is a free data retrieval call binding the contract method 0xc647f26e.
//
// Solidity: function withdrawalRequestIndex(address layer2, address account) view returns(uint256 index)
func (_DepositManager *DepositManagerCaller) WithdrawalRequestIndex(opts *bind.CallOpts, layer2 common.Address, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "withdrawalRequestIndex", layer2, account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WithdrawalRequestIndex is a free data retrieval call binding the contract method 0xc647f26e.
//
// Solidity: function withdrawalRequestIndex(address layer2, address account) view returns(uint256 index)
func (_DepositManager *DepositManagerSession) WithdrawalRequestIndex(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.WithdrawalRequestIndex(&_DepositManager.CallOpts, layer2, account)
}

// WithdrawalRequestIndex is a free data retrieval call binding the contract method 0xc647f26e.
//
// Solidity: function withdrawalRequestIndex(address layer2, address account) view returns(uint256 index)
func (_DepositManager *DepositManagerCallerSession) WithdrawalRequestIndex(layer2 common.Address, account common.Address) (*big.Int, error) {
	return _DepositManager.Contract.WithdrawalRequestIndex(&_DepositManager.CallOpts, layer2, account)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_DepositManager *DepositManagerCaller) Wton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DepositManager.contract.Call(opts, &out, "wton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_DepositManager *DepositManagerSession) Wton() (common.Address, error) {
	return _DepositManager.Contract.Wton(&_DepositManager.CallOpts)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_DepositManager *DepositManagerCallerSession) Wton() (common.Address, error) {
	return _DepositManager.Contract.Wton(&_DepositManager.CallOpts)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_DepositManager *DepositManagerTransactor) AddAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "addAdmin", account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_DepositManager *DepositManagerSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.AddAdmin(&_DepositManager.TransactOpts, account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_DepositManager *DepositManagerTransactorSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.AddAdmin(&_DepositManager.TransactOpts, account)
}

// Deposit is a paid mutator transaction binding the contract method 0x47e7ef24.
//
// Solidity: function deposit(address layer2, uint256 amount) returns(bool)
func (_DepositManager *DepositManagerTransactor) Deposit(opts *bind.TransactOpts, layer2 common.Address, amount *big.Int) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "deposit", layer2, amount)
}

// Deposit is a paid mutator transaction binding the contract method 0x47e7ef24.
//
// Solidity: function deposit(address layer2, uint256 amount) returns(bool)
func (_DepositManager *DepositManagerSession) Deposit(layer2 common.Address, amount *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.Deposit(&_DepositManager.TransactOpts, layer2, amount)
}

// Deposit is a paid mutator transaction binding the contract method 0x47e7ef24.
//
// Solidity: function deposit(address layer2, uint256 amount) returns(bool)
func (_DepositManager *DepositManagerTransactorSession) Deposit(layer2 common.Address, amount *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.Deposit(&_DepositManager.TransactOpts, layer2, amount)
}

// Deposit0 is a paid mutator transaction binding the contract method 0x562fa0df.
//
// Solidity: function deposit(address layer2, address[] accounts, uint256[] amounts) returns(bool)
func (_DepositManager *DepositManagerTransactor) Deposit0(opts *bind.TransactOpts, layer2 common.Address, accounts []common.Address, amounts []*big.Int) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "deposit0", layer2, accounts, amounts)
}

// Deposit0 is a paid mutator transaction binding the contract method 0x562fa0df.
//
// Solidity: function deposit(address layer2, address[] accounts, uint256[] amounts) returns(bool)
func (_DepositManager *DepositManagerSession) Deposit0(layer2 common.Address, accounts []common.Address, amounts []*big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.Deposit0(&_DepositManager.TransactOpts, layer2, accounts, amounts)
}

// Deposit0 is a paid mutator transaction binding the contract method 0x562fa0df.
//
// Solidity: function deposit(address layer2, address[] accounts, uint256[] amounts) returns(bool)
func (_DepositManager *DepositManagerTransactorSession) Deposit0(layer2 common.Address, accounts []common.Address, amounts []*big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.Deposit0(&_DepositManager.TransactOpts, layer2, accounts, amounts)
}

// Deposit1 is a paid mutator transaction binding the contract method 0x8340f549.
//
// Solidity: function deposit(address layer2, address account, uint256 amount) returns(bool)
func (_DepositManager *DepositManagerTransactor) Deposit1(opts *bind.TransactOpts, layer2 common.Address, account common.Address, amount *big.Int) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "deposit1", layer2, account, amount)
}

// Deposit1 is a paid mutator transaction binding the contract method 0x8340f549.
//
// Solidity: function deposit(address layer2, address account, uint256 amount) returns(bool)
func (_DepositManager *DepositManagerSession) Deposit1(layer2 common.Address, account common.Address, amount *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.Deposit1(&_DepositManager.TransactOpts, layer2, account, amount)
}

// Deposit1 is a paid mutator transaction binding the contract method 0x8340f549.
//
// Solidity: function deposit(address layer2, address account, uint256 amount) returns(bool)
func (_DepositManager *DepositManagerTransactorSession) Deposit1(layer2 common.Address, account common.Address, amount *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.Deposit1(&_DepositManager.TransactOpts, layer2, account, amount)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_DepositManager *DepositManagerTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_DepositManager *DepositManagerSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.GrantRole(&_DepositManager.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_DepositManager *DepositManagerTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.GrantRole(&_DepositManager.TransactOpts, role, account)
}

// Initialize is a paid mutator transaction binding the contract method 0x530b97a4.
//
// Solidity: function initialize(address wton_, address registry_, address seigManager_, uint256 globalWithdrawalDelay_, address oldDepositManager_) returns()
func (_DepositManager *DepositManagerTransactor) Initialize(opts *bind.TransactOpts, wton_ common.Address, registry_ common.Address, seigManager_ common.Address, globalWithdrawalDelay_ *big.Int, oldDepositManager_ common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "initialize", wton_, registry_, seigManager_, globalWithdrawalDelay_, oldDepositManager_)
}

// Initialize is a paid mutator transaction binding the contract method 0x530b97a4.
//
// Solidity: function initialize(address wton_, address registry_, address seigManager_, uint256 globalWithdrawalDelay_, address oldDepositManager_) returns()
func (_DepositManager *DepositManagerSession) Initialize(wton_ common.Address, registry_ common.Address, seigManager_ common.Address, globalWithdrawalDelay_ *big.Int, oldDepositManager_ common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.Initialize(&_DepositManager.TransactOpts, wton_, registry_, seigManager_, globalWithdrawalDelay_, oldDepositManager_)
}

// Initialize is a paid mutator transaction binding the contract method 0x530b97a4.
//
// Solidity: function initialize(address wton_, address registry_, address seigManager_, uint256 globalWithdrawalDelay_, address oldDepositManager_) returns()
func (_DepositManager *DepositManagerTransactorSession) Initialize(wton_ common.Address, registry_ common.Address, seigManager_ common.Address, globalWithdrawalDelay_ *big.Int, oldDepositManager_ common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.Initialize(&_DepositManager.TransactOpts, wton_, registry_, seigManager_, globalWithdrawalDelay_, oldDepositManager_)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_DepositManager *DepositManagerTransactor) OnApprove(opts *bind.TransactOpts, owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "onApprove", owner, spender, amount, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_DepositManager *DepositManagerSession) OnApprove(owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _DepositManager.Contract.OnApprove(&_DepositManager.TransactOpts, owner, spender, amount, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_DepositManager *DepositManagerTransactorSession) OnApprove(owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _DepositManager.Contract.OnApprove(&_DepositManager.TransactOpts, owner, spender, amount, data)
}

// ProcessRequest is a paid mutator transaction binding the contract method 0xc20a44c6.
//
// Solidity: function processRequest(address layer2, bool receiveTON) returns(bool)
func (_DepositManager *DepositManagerTransactor) ProcessRequest(opts *bind.TransactOpts, layer2 common.Address, receiveTON bool) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "processRequest", layer2, receiveTON)
}

// ProcessRequest is a paid mutator transaction binding the contract method 0xc20a44c6.
//
// Solidity: function processRequest(address layer2, bool receiveTON) returns(bool)
func (_DepositManager *DepositManagerSession) ProcessRequest(layer2 common.Address, receiveTON bool) (*types.Transaction, error) {
	return _DepositManager.Contract.ProcessRequest(&_DepositManager.TransactOpts, layer2, receiveTON)
}

// ProcessRequest is a paid mutator transaction binding the contract method 0xc20a44c6.
//
// Solidity: function processRequest(address layer2, bool receiveTON) returns(bool)
func (_DepositManager *DepositManagerTransactorSession) ProcessRequest(layer2 common.Address, receiveTON bool) (*types.Transaction, error) {
	return _DepositManager.Contract.ProcessRequest(&_DepositManager.TransactOpts, layer2, receiveTON)
}

// ProcessRequests is a paid mutator transaction binding the contract method 0xfb0713b1.
//
// Solidity: function processRequests(address layer2, uint256 n, bool receiveTON) returns(bool)
func (_DepositManager *DepositManagerTransactor) ProcessRequests(opts *bind.TransactOpts, layer2 common.Address, n *big.Int, receiveTON bool) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "processRequests", layer2, n, receiveTON)
}

// ProcessRequests is a paid mutator transaction binding the contract method 0xfb0713b1.
//
// Solidity: function processRequests(address layer2, uint256 n, bool receiveTON) returns(bool)
func (_DepositManager *DepositManagerSession) ProcessRequests(layer2 common.Address, n *big.Int, receiveTON bool) (*types.Transaction, error) {
	return _DepositManager.Contract.ProcessRequests(&_DepositManager.TransactOpts, layer2, n, receiveTON)
}

// ProcessRequests is a paid mutator transaction binding the contract method 0xfb0713b1.
//
// Solidity: function processRequests(address layer2, uint256 n, bool receiveTON) returns(bool)
func (_DepositManager *DepositManagerTransactorSession) ProcessRequests(layer2 common.Address, n *big.Int, receiveTON bool) (*types.Transaction, error) {
	return _DepositManager.Contract.ProcessRequests(&_DepositManager.TransactOpts, layer2, n, receiveTON)
}

// Redeposit is a paid mutator transaction binding the contract method 0xb8bee628.
//
// Solidity: function redeposit(address layer2) returns(bool)
func (_DepositManager *DepositManagerTransactor) Redeposit(opts *bind.TransactOpts, layer2 common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "redeposit", layer2)
}

// Redeposit is a paid mutator transaction binding the contract method 0xb8bee628.
//
// Solidity: function redeposit(address layer2) returns(bool)
func (_DepositManager *DepositManagerSession) Redeposit(layer2 common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.Redeposit(&_DepositManager.TransactOpts, layer2)
}

// Redeposit is a paid mutator transaction binding the contract method 0xb8bee628.
//
// Solidity: function redeposit(address layer2) returns(bool)
func (_DepositManager *DepositManagerTransactorSession) Redeposit(layer2 common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.Redeposit(&_DepositManager.TransactOpts, layer2)
}

// RedepositMulti is a paid mutator transaction binding the contract method 0x445e83b9.
//
// Solidity: function redepositMulti(address layer2, uint256 n) returns(bool)
func (_DepositManager *DepositManagerTransactor) RedepositMulti(opts *bind.TransactOpts, layer2 common.Address, n *big.Int) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "redepositMulti", layer2, n)
}

// RedepositMulti is a paid mutator transaction binding the contract method 0x445e83b9.
//
// Solidity: function redepositMulti(address layer2, uint256 n) returns(bool)
func (_DepositManager *DepositManagerSession) RedepositMulti(layer2 common.Address, n *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.RedepositMulti(&_DepositManager.TransactOpts, layer2, n)
}

// RedepositMulti is a paid mutator transaction binding the contract method 0x445e83b9.
//
// Solidity: function redepositMulti(address layer2, uint256 n) returns(bool)
func (_DepositManager *DepositManagerTransactorSession) RedepositMulti(layer2 common.Address, n *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.RedepositMulti(&_DepositManager.TransactOpts, layer2, n)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_DepositManager *DepositManagerTransactor) RemoveAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "removeAdmin", account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_DepositManager *DepositManagerSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.RemoveAdmin(&_DepositManager.TransactOpts, account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_DepositManager *DepositManagerTransactorSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.RemoveAdmin(&_DepositManager.TransactOpts, account)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_DepositManager *DepositManagerTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_DepositManager *DepositManagerSession) RenounceOwnership() (*types.Transaction, error) {
	return _DepositManager.Contract.RenounceOwnership(&_DepositManager.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_DepositManager *DepositManagerTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _DepositManager.Contract.RenounceOwnership(&_DepositManager.TransactOpts)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_DepositManager *DepositManagerTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "renounceRole", role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_DepositManager *DepositManagerSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.RenounceRole(&_DepositManager.TransactOpts, role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_DepositManager *DepositManagerTransactorSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.RenounceRole(&_DepositManager.TransactOpts, role, account)
}

// RequestWithdrawal is a paid mutator transaction binding the contract method 0xda95ebf7.
//
// Solidity: function requestWithdrawal(address layer2, uint256 amount) returns(bool)
func (_DepositManager *DepositManagerTransactor) RequestWithdrawal(opts *bind.TransactOpts, layer2 common.Address, amount *big.Int) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "requestWithdrawal", layer2, amount)
}

// RequestWithdrawal is a paid mutator transaction binding the contract method 0xda95ebf7.
//
// Solidity: function requestWithdrawal(address layer2, uint256 amount) returns(bool)
func (_DepositManager *DepositManagerSession) RequestWithdrawal(layer2 common.Address, amount *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.RequestWithdrawal(&_DepositManager.TransactOpts, layer2, amount)
}

// RequestWithdrawal is a paid mutator transaction binding the contract method 0xda95ebf7.
//
// Solidity: function requestWithdrawal(address layer2, uint256 amount) returns(bool)
func (_DepositManager *DepositManagerTransactorSession) RequestWithdrawal(layer2 common.Address, amount *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.RequestWithdrawal(&_DepositManager.TransactOpts, layer2, amount)
}

// RequestWithdrawalAll is a paid mutator transaction binding the contract method 0x6b2160b7.
//
// Solidity: function requestWithdrawalAll(address layer2) returns(bool)
func (_DepositManager *DepositManagerTransactor) RequestWithdrawalAll(opts *bind.TransactOpts, layer2 common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "requestWithdrawalAll", layer2)
}

// RequestWithdrawalAll is a paid mutator transaction binding the contract method 0x6b2160b7.
//
// Solidity: function requestWithdrawalAll(address layer2) returns(bool)
func (_DepositManager *DepositManagerSession) RequestWithdrawalAll(layer2 common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.RequestWithdrawalAll(&_DepositManager.TransactOpts, layer2)
}

// RequestWithdrawalAll is a paid mutator transaction binding the contract method 0x6b2160b7.
//
// Solidity: function requestWithdrawalAll(address layer2) returns(bool)
func (_DepositManager *DepositManagerTransactorSession) RequestWithdrawalAll(layer2 common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.RequestWithdrawalAll(&_DepositManager.TransactOpts, layer2)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_DepositManager *DepositManagerTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_DepositManager *DepositManagerSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.RevokeRole(&_DepositManager.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_DepositManager *DepositManagerTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.RevokeRole(&_DepositManager.TransactOpts, role, account)
}

// SetGlobalWithdrawalDelay is a paid mutator transaction binding the contract method 0xa79da341.
//
// Solidity: function setGlobalWithdrawalDelay(uint256 globalWithdrawalDelay_) returns()
func (_DepositManager *DepositManagerTransactor) SetGlobalWithdrawalDelay(opts *bind.TransactOpts, globalWithdrawalDelay_ *big.Int) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "setGlobalWithdrawalDelay", globalWithdrawalDelay_)
}

// SetGlobalWithdrawalDelay is a paid mutator transaction binding the contract method 0xa79da341.
//
// Solidity: function setGlobalWithdrawalDelay(uint256 globalWithdrawalDelay_) returns()
func (_DepositManager *DepositManagerSession) SetGlobalWithdrawalDelay(globalWithdrawalDelay_ *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.SetGlobalWithdrawalDelay(&_DepositManager.TransactOpts, globalWithdrawalDelay_)
}

// SetGlobalWithdrawalDelay is a paid mutator transaction binding the contract method 0xa79da341.
//
// Solidity: function setGlobalWithdrawalDelay(uint256 globalWithdrawalDelay_) returns()
func (_DepositManager *DepositManagerTransactorSession) SetGlobalWithdrawalDelay(globalWithdrawalDelay_ *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.SetGlobalWithdrawalDelay(&_DepositManager.TransactOpts, globalWithdrawalDelay_)
}

// SetSeigManager is a paid mutator transaction binding the contract method 0x7657f20a.
//
// Solidity: function setSeigManager(address seigManager_) returns()
func (_DepositManager *DepositManagerTransactor) SetSeigManager(opts *bind.TransactOpts, seigManager_ common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "setSeigManager", seigManager_)
}

// SetSeigManager is a paid mutator transaction binding the contract method 0x7657f20a.
//
// Solidity: function setSeigManager(address seigManager_) returns()
func (_DepositManager *DepositManagerSession) SetSeigManager(seigManager_ common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.SetSeigManager(&_DepositManager.TransactOpts, seigManager_)
}

// SetSeigManager is a paid mutator transaction binding the contract method 0x7657f20a.
//
// Solidity: function setSeigManager(address seigManager_) returns()
func (_DepositManager *DepositManagerTransactorSession) SetSeigManager(seigManager_ common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.SetSeigManager(&_DepositManager.TransactOpts, seigManager_)
}

// SetWithdrawalDelay is a paid mutator transaction binding the contract method 0xdc5a709f.
//
// Solidity: function setWithdrawalDelay(address layer2, uint256 withdrawalDelay_) returns()
func (_DepositManager *DepositManagerTransactor) SetWithdrawalDelay(opts *bind.TransactOpts, layer2 common.Address, withdrawalDelay_ *big.Int) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "setWithdrawalDelay", layer2, withdrawalDelay_)
}

// SetWithdrawalDelay is a paid mutator transaction binding the contract method 0xdc5a709f.
//
// Solidity: function setWithdrawalDelay(address layer2, uint256 withdrawalDelay_) returns()
func (_DepositManager *DepositManagerSession) SetWithdrawalDelay(layer2 common.Address, withdrawalDelay_ *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.SetWithdrawalDelay(&_DepositManager.TransactOpts, layer2, withdrawalDelay_)
}

// SetWithdrawalDelay is a paid mutator transaction binding the contract method 0xdc5a709f.
//
// Solidity: function setWithdrawalDelay(address layer2, uint256 withdrawalDelay_) returns()
func (_DepositManager *DepositManagerTransactorSession) SetWithdrawalDelay(layer2 common.Address, withdrawalDelay_ *big.Int) (*types.Transaction, error) {
	return _DepositManager.Contract.SetWithdrawalDelay(&_DepositManager.TransactOpts, layer2, withdrawalDelay_)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_DepositManager *DepositManagerTransactor) TransferAdmin(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "transferAdmin", newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_DepositManager *DepositManagerSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.TransferAdmin(&_DepositManager.TransactOpts, newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_DepositManager *DepositManagerTransactorSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.TransferAdmin(&_DepositManager.TransactOpts, newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_DepositManager *DepositManagerTransactor) TransferOwnership(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManager.contract.Transact(opts, "transferOwnership", newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_DepositManager *DepositManagerSession) TransferOwnership(newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.TransferOwnership(&_DepositManager.TransactOpts, newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_DepositManager *DepositManagerTransactorSession) TransferOwnership(newAdmin common.Address) (*types.Transaction, error) {
	return _DepositManager.Contract.TransferOwnership(&_DepositManager.TransactOpts, newAdmin)
}

// DepositManagerDepositedIterator is returned from FilterDeposited and is used to iterate over the raw logs and unpacked data for Deposited events raised by the DepositManager contract.
type DepositManagerDepositedIterator struct {
	Event *DepositManagerDeposited // Event containing the contract specifics and raw log

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
func (it *DepositManagerDepositedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerDeposited)
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
		it.Event = new(DepositManagerDeposited)
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
func (it *DepositManagerDepositedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerDepositedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerDeposited represents a Deposited event raised by the DepositManager contract.
type DepositManagerDeposited struct {
	Layer2    common.Address
	Depositor common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterDeposited is a free log retrieval operation binding the contract event 0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7.
//
// Solidity: event Deposited(address indexed layer2, address depositor, uint256 amount)
func (_DepositManager *DepositManagerFilterer) FilterDeposited(opts *bind.FilterOpts, layer2 []common.Address) (*DepositManagerDepositedIterator, error) {

	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _DepositManager.contract.FilterLogs(opts, "Deposited", layer2Rule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerDepositedIterator{contract: _DepositManager.contract, event: "Deposited", logs: logs, sub: sub}, nil
}

// WatchDeposited is a free log subscription operation binding the contract event 0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7.
//
// Solidity: event Deposited(address indexed layer2, address depositor, uint256 amount)
func (_DepositManager *DepositManagerFilterer) WatchDeposited(opts *bind.WatchOpts, sink chan<- *DepositManagerDeposited, layer2 []common.Address) (event.Subscription, error) {

	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _DepositManager.contract.WatchLogs(opts, "Deposited", layer2Rule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerDeposited)
				if err := _DepositManager.contract.UnpackLog(event, "Deposited", log); err != nil {
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

// ParseDeposited is a log parse operation binding the contract event 0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7.
//
// Solidity: event Deposited(address indexed layer2, address depositor, uint256 amount)
func (_DepositManager *DepositManagerFilterer) ParseDeposited(log types.Log) (*DepositManagerDeposited, error) {
	event := new(DepositManagerDeposited)
	if err := _DepositManager.contract.UnpackLog(event, "Deposited", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DepositManagerRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the DepositManager contract.
type DepositManagerRoleAdminChangedIterator struct {
	Event *DepositManagerRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *DepositManagerRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerRoleAdminChanged)
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
		it.Event = new(DepositManagerRoleAdminChanged)
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
func (it *DepositManagerRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerRoleAdminChanged represents a RoleAdminChanged event raised by the DepositManager contract.
type DepositManagerRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_DepositManager *DepositManagerFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*DepositManagerRoleAdminChangedIterator, error) {

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

	logs, sub, err := _DepositManager.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerRoleAdminChangedIterator{contract: _DepositManager.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_DepositManager *DepositManagerFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *DepositManagerRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _DepositManager.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerRoleAdminChanged)
				if err := _DepositManager.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_DepositManager *DepositManagerFilterer) ParseRoleAdminChanged(log types.Log) (*DepositManagerRoleAdminChanged, error) {
	event := new(DepositManagerRoleAdminChanged)
	if err := _DepositManager.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DepositManagerRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the DepositManager contract.
type DepositManagerRoleGrantedIterator struct {
	Event *DepositManagerRoleGranted // Event containing the contract specifics and raw log

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
func (it *DepositManagerRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerRoleGranted)
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
		it.Event = new(DepositManagerRoleGranted)
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
func (it *DepositManagerRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerRoleGranted represents a RoleGranted event raised by the DepositManager contract.
type DepositManagerRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_DepositManager *DepositManagerFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*DepositManagerRoleGrantedIterator, error) {

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

	logs, sub, err := _DepositManager.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerRoleGrantedIterator{contract: _DepositManager.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_DepositManager *DepositManagerFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *DepositManagerRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _DepositManager.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerRoleGranted)
				if err := _DepositManager.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_DepositManager *DepositManagerFilterer) ParseRoleGranted(log types.Log) (*DepositManagerRoleGranted, error) {
	event := new(DepositManagerRoleGranted)
	if err := _DepositManager.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DepositManagerRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the DepositManager contract.
type DepositManagerRoleRevokedIterator struct {
	Event *DepositManagerRoleRevoked // Event containing the contract specifics and raw log

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
func (it *DepositManagerRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerRoleRevoked)
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
		it.Event = new(DepositManagerRoleRevoked)
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
func (it *DepositManagerRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerRoleRevoked represents a RoleRevoked event raised by the DepositManager contract.
type DepositManagerRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_DepositManager *DepositManagerFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*DepositManagerRoleRevokedIterator, error) {

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

	logs, sub, err := _DepositManager.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerRoleRevokedIterator{contract: _DepositManager.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_DepositManager *DepositManagerFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *DepositManagerRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _DepositManager.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerRoleRevoked)
				if err := _DepositManager.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_DepositManager *DepositManagerFilterer) ParseRoleRevoked(log types.Log) (*DepositManagerRoleRevoked, error) {
	event := new(DepositManagerRoleRevoked)
	if err := _DepositManager.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DepositManagerWithdrawalProcessedIterator is returned from FilterWithdrawalProcessed and is used to iterate over the raw logs and unpacked data for WithdrawalProcessed events raised by the DepositManager contract.
type DepositManagerWithdrawalProcessedIterator struct {
	Event *DepositManagerWithdrawalProcessed // Event containing the contract specifics and raw log

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
func (it *DepositManagerWithdrawalProcessedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerWithdrawalProcessed)
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
		it.Event = new(DepositManagerWithdrawalProcessed)
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
func (it *DepositManagerWithdrawalProcessedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerWithdrawalProcessedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerWithdrawalProcessed represents a WithdrawalProcessed event raised by the DepositManager contract.
type DepositManagerWithdrawalProcessed struct {
	Layer2    common.Address
	Depositor common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterWithdrawalProcessed is a free log retrieval operation binding the contract event 0xcd1fce47d5ad89dd70b04c75bd6bdb8114d4d4ff7b4393f9fb5937e733ba9582.
//
// Solidity: event WithdrawalProcessed(address indexed layer2, address depositor, uint256 amount)
func (_DepositManager *DepositManagerFilterer) FilterWithdrawalProcessed(opts *bind.FilterOpts, layer2 []common.Address) (*DepositManagerWithdrawalProcessedIterator, error) {

	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _DepositManager.contract.FilterLogs(opts, "WithdrawalProcessed", layer2Rule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerWithdrawalProcessedIterator{contract: _DepositManager.contract, event: "WithdrawalProcessed", logs: logs, sub: sub}, nil
}

// WatchWithdrawalProcessed is a free log subscription operation binding the contract event 0xcd1fce47d5ad89dd70b04c75bd6bdb8114d4d4ff7b4393f9fb5937e733ba9582.
//
// Solidity: event WithdrawalProcessed(address indexed layer2, address depositor, uint256 amount)
func (_DepositManager *DepositManagerFilterer) WatchWithdrawalProcessed(opts *bind.WatchOpts, sink chan<- *DepositManagerWithdrawalProcessed, layer2 []common.Address) (event.Subscription, error) {

	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _DepositManager.contract.WatchLogs(opts, "WithdrawalProcessed", layer2Rule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerWithdrawalProcessed)
				if err := _DepositManager.contract.UnpackLog(event, "WithdrawalProcessed", log); err != nil {
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

// ParseWithdrawalProcessed is a log parse operation binding the contract event 0xcd1fce47d5ad89dd70b04c75bd6bdb8114d4d4ff7b4393f9fb5937e733ba9582.
//
// Solidity: event WithdrawalProcessed(address indexed layer2, address depositor, uint256 amount)
func (_DepositManager *DepositManagerFilterer) ParseWithdrawalProcessed(log types.Log) (*DepositManagerWithdrawalProcessed, error) {
	event := new(DepositManagerWithdrawalProcessed)
	if err := _DepositManager.contract.UnpackLog(event, "WithdrawalProcessed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DepositManagerWithdrawalRequestedIterator is returned from FilterWithdrawalRequested and is used to iterate over the raw logs and unpacked data for WithdrawalRequested events raised by the DepositManager contract.
type DepositManagerWithdrawalRequestedIterator struct {
	Event *DepositManagerWithdrawalRequested // Event containing the contract specifics and raw log

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
func (it *DepositManagerWithdrawalRequestedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DepositManagerWithdrawalRequested)
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
		it.Event = new(DepositManagerWithdrawalRequested)
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
func (it *DepositManagerWithdrawalRequestedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DepositManagerWithdrawalRequestedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DepositManagerWithdrawalRequested represents a WithdrawalRequested event raised by the DepositManager contract.
type DepositManagerWithdrawalRequested struct {
	Layer2    common.Address
	Depositor common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterWithdrawalRequested is a free log retrieval operation binding the contract event 0x04c56a409d50971e45c5a2d96e5d557d2b0f1d66d40f14b141e4c958b0f39b32.
//
// Solidity: event WithdrawalRequested(address indexed layer2, address depositor, uint256 amount)
func (_DepositManager *DepositManagerFilterer) FilterWithdrawalRequested(opts *bind.FilterOpts, layer2 []common.Address) (*DepositManagerWithdrawalRequestedIterator, error) {

	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _DepositManager.contract.FilterLogs(opts, "WithdrawalRequested", layer2Rule)
	if err != nil {
		return nil, err
	}
	return &DepositManagerWithdrawalRequestedIterator{contract: _DepositManager.contract, event: "WithdrawalRequested", logs: logs, sub: sub}, nil
}

// WatchWithdrawalRequested is a free log subscription operation binding the contract event 0x04c56a409d50971e45c5a2d96e5d557d2b0f1d66d40f14b141e4c958b0f39b32.
//
// Solidity: event WithdrawalRequested(address indexed layer2, address depositor, uint256 amount)
func (_DepositManager *DepositManagerFilterer) WatchWithdrawalRequested(opts *bind.WatchOpts, sink chan<- *DepositManagerWithdrawalRequested, layer2 []common.Address) (event.Subscription, error) {

	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _DepositManager.contract.WatchLogs(opts, "WithdrawalRequested", layer2Rule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DepositManagerWithdrawalRequested)
				if err := _DepositManager.contract.UnpackLog(event, "WithdrawalRequested", log); err != nil {
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

// ParseWithdrawalRequested is a log parse operation binding the contract event 0x04c56a409d50971e45c5a2d96e5d557d2b0f1d66d40f14b141e4c958b0f39b32.
//
// Solidity: event WithdrawalRequested(address indexed layer2, address depositor, uint256 amount)
func (_DepositManager *DepositManagerFilterer) ParseWithdrawalRequested(log types.Log) (*DepositManagerWithdrawalRequested, error) {
	event := new(DepositManagerWithdrawalRequested)
	if err := _DepositManager.contract.UnpackLog(event, "WithdrawalRequested", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
