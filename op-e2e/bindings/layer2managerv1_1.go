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

// Layer2ManagerV11MetaData contains all meta data concerning the Layer2ManagerV11 contract.
var Layer2ManagerV11MetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"aliveImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"availableRegister\",\"inputs\":[{\"name\":\"_rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"result\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"candidateAddOnOfOperator\",\"inputs\":[{\"name\":\"_oper\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"checkL1Bridge\",\"inputs\":[{\"name\":\"_rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"result\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"l1Bridge\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"portal\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2Ton\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"checkL1BridgeDetail\",\"inputs\":[{\"name\":\"_rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"result\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"l1Bridge\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"portal\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l2Ton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_type\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"rejectedSeigs\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"rejectedL2Deposit\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"checkLayer2TVL\",\"inputs\":[{\"name\":\"_rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"result\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"dao\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"depositManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isOwner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1BridgeRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layerInfo\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minimumInitialDepositAmount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"onApprove\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"operatorInfo\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"candidateAddOn\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"operatorManagerFactory\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"operatorOfLayer\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"operatorOfRollupConfig\",\"inputs\":[{\"name\":\"_rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseCandidateAddOn\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"pauseProxy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxyImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"registerCandidateAddOn\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"flagTon\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"memo\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"rollupConfigInfo\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"operatorManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"rollupConfigOfOperator\",\"inputs\":[{\"name\":\"_oper\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"seigManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"selectorImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setAddresses\",\"inputs\":[{\"name\":\"_l1BridgeRegistry\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_operatorManagerFactory\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_ton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_wton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_dao\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_depositManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_seigManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_swapProxy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMinimumInitialDepositAmount\",\"inputs\":[{\"name\":\"_minimumInitialDepositAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOperatorManagerFactory\",\"inputs\":[{\"name\":\"_operatorManagerFactory\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"statusLayer2\",\"inputs\":[{\"name\":\"_rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"swapProxy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferAdmin\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferL2Seigniorage\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpauseCandidateAddOn\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"verifyOperator\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"verified\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"wton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"PausedCandidateAddOn\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"candidateAddOn\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RegisteredCandidateAddOn\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"memo\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"candidateAddOn\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SetAddresses\",\"inputs\":[{\"name\":\"_l2Register\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"_operatorManagerFactory\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"_ton\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"_wton\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"_dao\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"_depositManager\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"_seigManager\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"_swapProxy\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SetMinimumInitialDepositAmount\",\"inputs\":[{\"name\":\"_minimumInitialDepositAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SetOperatorManagerFactory\",\"inputs\":[{\"name\":\"_operatorManagerFactory\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferWTON\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UnpausedCandidateAddOn\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"candidateAddOn\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ExcludeError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"IncludeError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OnApproveError\",\"inputs\":[{\"name\":\"x\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"RegisterError\",\"inputs\":[{\"name\":\"x\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"StatusError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZeroAddressError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZeroBytesError\",\"inputs\":[]}]",
}

// Layer2ManagerV11ABI is the input ABI used to generate the binding from.
// Deprecated: Use Layer2ManagerV11MetaData.ABI instead.
var Layer2ManagerV11ABI = Layer2ManagerV11MetaData.ABI

// Layer2ManagerV11 is an auto generated Go binding around an Ethereum contract.
type Layer2ManagerV11 struct {
	Layer2ManagerV11Caller     // Read-only binding to the contract
	Layer2ManagerV11Transactor // Write-only binding to the contract
	Layer2ManagerV11Filterer   // Log filterer for contract events
}

// Layer2ManagerV11Caller is an auto generated read-only Go binding around an Ethereum contract.
type Layer2ManagerV11Caller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// Layer2ManagerV11Transactor is an auto generated write-only Go binding around an Ethereum contract.
type Layer2ManagerV11Transactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// Layer2ManagerV11Filterer is an auto generated log filtering Go binding around an Ethereum contract events.
type Layer2ManagerV11Filterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// Layer2ManagerV11Session is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type Layer2ManagerV11Session struct {
	Contract     *Layer2ManagerV11 // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// Layer2ManagerV11CallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type Layer2ManagerV11CallerSession struct {
	Contract *Layer2ManagerV11Caller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts           // Call options to use throughout this session
}

// Layer2ManagerV11TransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type Layer2ManagerV11TransactorSession struct {
	Contract     *Layer2ManagerV11Transactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts           // Transaction auth options to use throughout this session
}

// Layer2ManagerV11Raw is an auto generated low-level Go binding around an Ethereum contract.
type Layer2ManagerV11Raw struct {
	Contract *Layer2ManagerV11 // Generic contract binding to access the raw methods on
}

// Layer2ManagerV11CallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type Layer2ManagerV11CallerRaw struct {
	Contract *Layer2ManagerV11Caller // Generic read-only contract binding to access the raw methods on
}

// Layer2ManagerV11TransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type Layer2ManagerV11TransactorRaw struct {
	Contract *Layer2ManagerV11Transactor // Generic write-only contract binding to access the raw methods on
}

// NewLayer2ManagerV11 creates a new instance of Layer2ManagerV11, bound to a specific deployed contract.
func NewLayer2ManagerV11(address common.Address, backend bind.ContractBackend) (*Layer2ManagerV11, error) {
	contract, err := bindLayer2ManagerV11(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11{Layer2ManagerV11Caller: Layer2ManagerV11Caller{contract: contract}, Layer2ManagerV11Transactor: Layer2ManagerV11Transactor{contract: contract}, Layer2ManagerV11Filterer: Layer2ManagerV11Filterer{contract: contract}}, nil
}

// NewLayer2ManagerV11Caller creates a new read-only instance of Layer2ManagerV11, bound to a specific deployed contract.
func NewLayer2ManagerV11Caller(address common.Address, caller bind.ContractCaller) (*Layer2ManagerV11Caller, error) {
	contract, err := bindLayer2ManagerV11(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11Caller{contract: contract}, nil
}

// NewLayer2ManagerV11Transactor creates a new write-only instance of Layer2ManagerV11, bound to a specific deployed contract.
func NewLayer2ManagerV11Transactor(address common.Address, transactor bind.ContractTransactor) (*Layer2ManagerV11Transactor, error) {
	contract, err := bindLayer2ManagerV11(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11Transactor{contract: contract}, nil
}

// NewLayer2ManagerV11Filterer creates a new log filterer instance of Layer2ManagerV11, bound to a specific deployed contract.
func NewLayer2ManagerV11Filterer(address common.Address, filterer bind.ContractFilterer) (*Layer2ManagerV11Filterer, error) {
	contract, err := bindLayer2ManagerV11(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11Filterer{contract: contract}, nil
}

// bindLayer2ManagerV11 binds a generic wrapper to an already deployed contract.
func bindLayer2ManagerV11(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := Layer2ManagerV11MetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Layer2ManagerV11 *Layer2ManagerV11Raw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Layer2ManagerV11.Contract.Layer2ManagerV11Caller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Layer2ManagerV11 *Layer2ManagerV11Raw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.Layer2ManagerV11Transactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Layer2ManagerV11 *Layer2ManagerV11Raw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.Layer2ManagerV11Transactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Layer2ManagerV11 *Layer2ManagerV11CallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Layer2ManagerV11.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) DEFAULTADMINROLE() ([32]byte, error) {
	return _Layer2ManagerV11.Contract.DEFAULTADMINROLE(&_Layer2ManagerV11.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _Layer2ManagerV11.Contract.DEFAULTADMINROLE(&_Layer2ManagerV11.CallOpts)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) AliveImplementation(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "aliveImplementation", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) AliveImplementation(arg0 common.Address) (bool, error) {
	return _Layer2ManagerV11.Contract.AliveImplementation(&_Layer2ManagerV11.CallOpts, arg0)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _Layer2ManagerV11.Contract.AliveImplementation(&_Layer2ManagerV11.CallOpts, arg0)
}

// AvailableRegister is a free data retrieval call binding the contract method 0x6a909247.
//
// Solidity: function availableRegister(address _rollupConfig) view returns(bool result)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) AvailableRegister(opts *bind.CallOpts, _rollupConfig common.Address) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "availableRegister", _rollupConfig)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AvailableRegister is a free data retrieval call binding the contract method 0x6a909247.
//
// Solidity: function availableRegister(address _rollupConfig) view returns(bool result)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) AvailableRegister(_rollupConfig common.Address) (bool, error) {
	return _Layer2ManagerV11.Contract.AvailableRegister(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// AvailableRegister is a free data retrieval call binding the contract method 0x6a909247.
//
// Solidity: function availableRegister(address _rollupConfig) view returns(bool result)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) AvailableRegister(_rollupConfig common.Address) (bool, error) {
	return _Layer2ManagerV11.Contract.AvailableRegister(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// CandidateAddOnOfOperator is a free data retrieval call binding the contract method 0x7bae05f1.
//
// Solidity: function candidateAddOnOfOperator(address _oper) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) CandidateAddOnOfOperator(opts *bind.CallOpts, _oper common.Address) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "candidateAddOnOfOperator", _oper)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// CandidateAddOnOfOperator is a free data retrieval call binding the contract method 0x7bae05f1.
//
// Solidity: function candidateAddOnOfOperator(address _oper) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) CandidateAddOnOfOperator(_oper common.Address) (common.Address, error) {
	return _Layer2ManagerV11.Contract.CandidateAddOnOfOperator(&_Layer2ManagerV11.CallOpts, _oper)
}

// CandidateAddOnOfOperator is a free data retrieval call binding the contract method 0x7bae05f1.
//
// Solidity: function candidateAddOnOfOperator(address _oper) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) CandidateAddOnOfOperator(_oper common.Address) (common.Address, error) {
	return _Layer2ManagerV11.Contract.CandidateAddOnOfOperator(&_Layer2ManagerV11.CallOpts, _oper)
}

// CheckL1Bridge is a free data retrieval call binding the contract method 0x58bf884f.
//
// Solidity: function checkL1Bridge(address _rollupConfig) view returns(bool result, address l1Bridge, address portal, address l2Ton)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) CheckL1Bridge(opts *bind.CallOpts, _rollupConfig common.Address) (struct {
	Result   bool
	L1Bridge common.Address
	Portal   common.Address
	L2Ton    common.Address
}, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "checkL1Bridge", _rollupConfig)

	outstruct := new(struct {
		Result   bool
		L1Bridge common.Address
		Portal   common.Address
		L2Ton    common.Address
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Result = *abi.ConvertType(out[0], new(bool)).(*bool)
	outstruct.L1Bridge = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	outstruct.Portal = *abi.ConvertType(out[2], new(common.Address)).(*common.Address)
	outstruct.L2Ton = *abi.ConvertType(out[3], new(common.Address)).(*common.Address)

	return *outstruct, err

}

// CheckL1Bridge is a free data retrieval call binding the contract method 0x58bf884f.
//
// Solidity: function checkL1Bridge(address _rollupConfig) view returns(bool result, address l1Bridge, address portal, address l2Ton)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) CheckL1Bridge(_rollupConfig common.Address) (struct {
	Result   bool
	L1Bridge common.Address
	Portal   common.Address
	L2Ton    common.Address
}, error) {
	return _Layer2ManagerV11.Contract.CheckL1Bridge(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// CheckL1Bridge is a free data retrieval call binding the contract method 0x58bf884f.
//
// Solidity: function checkL1Bridge(address _rollupConfig) view returns(bool result, address l1Bridge, address portal, address l2Ton)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) CheckL1Bridge(_rollupConfig common.Address) (struct {
	Result   bool
	L1Bridge common.Address
	Portal   common.Address
	L2Ton    common.Address
}, error) {
	return _Layer2ManagerV11.Contract.CheckL1Bridge(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// CheckL1BridgeDetail is a free data retrieval call binding the contract method 0x2e0f1775.
//
// Solidity: function checkL1BridgeDetail(address _rollupConfig) view returns(bool result, address l1Bridge, address portal, address l2Ton, uint8 _type, uint8 status, bool rejectedSeigs, bool rejectedL2Deposit)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) CheckL1BridgeDetail(opts *bind.CallOpts, _rollupConfig common.Address) (struct {
	Result            bool
	L1Bridge          common.Address
	Portal            common.Address
	L2Ton             common.Address
	Type              uint8
	Status            uint8
	RejectedSeigs     bool
	RejectedL2Deposit bool
}, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "checkL1BridgeDetail", _rollupConfig)

	outstruct := new(struct {
		Result            bool
		L1Bridge          common.Address
		Portal            common.Address
		L2Ton             common.Address
		Type              uint8
		Status            uint8
		RejectedSeigs     bool
		RejectedL2Deposit bool
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Result = *abi.ConvertType(out[0], new(bool)).(*bool)
	outstruct.L1Bridge = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	outstruct.Portal = *abi.ConvertType(out[2], new(common.Address)).(*common.Address)
	outstruct.L2Ton = *abi.ConvertType(out[3], new(common.Address)).(*common.Address)
	outstruct.Type = *abi.ConvertType(out[4], new(uint8)).(*uint8)
	outstruct.Status = *abi.ConvertType(out[5], new(uint8)).(*uint8)
	outstruct.RejectedSeigs = *abi.ConvertType(out[6], new(bool)).(*bool)
	outstruct.RejectedL2Deposit = *abi.ConvertType(out[7], new(bool)).(*bool)

	return *outstruct, err

}

// CheckL1BridgeDetail is a free data retrieval call binding the contract method 0x2e0f1775.
//
// Solidity: function checkL1BridgeDetail(address _rollupConfig) view returns(bool result, address l1Bridge, address portal, address l2Ton, uint8 _type, uint8 status, bool rejectedSeigs, bool rejectedL2Deposit)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) CheckL1BridgeDetail(_rollupConfig common.Address) (struct {
	Result            bool
	L1Bridge          common.Address
	Portal            common.Address
	L2Ton             common.Address
	Type              uint8
	Status            uint8
	RejectedSeigs     bool
	RejectedL2Deposit bool
}, error) {
	return _Layer2ManagerV11.Contract.CheckL1BridgeDetail(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// CheckL1BridgeDetail is a free data retrieval call binding the contract method 0x2e0f1775.
//
// Solidity: function checkL1BridgeDetail(address _rollupConfig) view returns(bool result, address l1Bridge, address portal, address l2Ton, uint8 _type, uint8 status, bool rejectedSeigs, bool rejectedL2Deposit)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) CheckL1BridgeDetail(_rollupConfig common.Address) (struct {
	Result            bool
	L1Bridge          common.Address
	Portal            common.Address
	L2Ton             common.Address
	Type              uint8
	Status            uint8
	RejectedSeigs     bool
	RejectedL2Deposit bool
}, error) {
	return _Layer2ManagerV11.Contract.CheckL1BridgeDetail(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// CheckLayer2TVL is a free data retrieval call binding the contract method 0x89c0db62.
//
// Solidity: function checkLayer2TVL(address _rollupConfig) view returns(bool result, uint256 amount)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) CheckLayer2TVL(opts *bind.CallOpts, _rollupConfig common.Address) (struct {
	Result bool
	Amount *big.Int
}, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "checkLayer2TVL", _rollupConfig)

	outstruct := new(struct {
		Result bool
		Amount *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Result = *abi.ConvertType(out[0], new(bool)).(*bool)
	outstruct.Amount = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// CheckLayer2TVL is a free data retrieval call binding the contract method 0x89c0db62.
//
// Solidity: function checkLayer2TVL(address _rollupConfig) view returns(bool result, uint256 amount)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) CheckLayer2TVL(_rollupConfig common.Address) (struct {
	Result bool
	Amount *big.Int
}, error) {
	return _Layer2ManagerV11.Contract.CheckLayer2TVL(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// CheckLayer2TVL is a free data retrieval call binding the contract method 0x89c0db62.
//
// Solidity: function checkLayer2TVL(address _rollupConfig) view returns(bool result, uint256 amount)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) CheckLayer2TVL(_rollupConfig common.Address) (struct {
	Result bool
	Amount *big.Int
}, error) {
	return _Layer2ManagerV11.Contract.CheckLayer2TVL(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// Dao is a free data retrieval call binding the contract method 0x4162169f.
//
// Solidity: function dao() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) Dao(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "dao")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Dao is a free data retrieval call binding the contract method 0x4162169f.
//
// Solidity: function dao() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) Dao() (common.Address, error) {
	return _Layer2ManagerV11.Contract.Dao(&_Layer2ManagerV11.CallOpts)
}

// Dao is a free data retrieval call binding the contract method 0x4162169f.
//
// Solidity: function dao() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) Dao() (common.Address, error) {
	return _Layer2ManagerV11.Contract.Dao(&_Layer2ManagerV11.CallOpts)
}

// DepositManager is a free data retrieval call binding the contract method 0x6c7ac9d8.
//
// Solidity: function depositManager() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) DepositManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "depositManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// DepositManager is a free data retrieval call binding the contract method 0x6c7ac9d8.
//
// Solidity: function depositManager() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) DepositManager() (common.Address, error) {
	return _Layer2ManagerV11.Contract.DepositManager(&_Layer2ManagerV11.CallOpts)
}

// DepositManager is a free data retrieval call binding the contract method 0x6c7ac9d8.
//
// Solidity: function depositManager() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) DepositManager() (common.Address, error) {
	return _Layer2ManagerV11.Contract.DepositManager(&_Layer2ManagerV11.CallOpts)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _Layer2ManagerV11.Contract.GetRoleAdmin(&_Layer2ManagerV11.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _Layer2ManagerV11.Contract.GetRoleAdmin(&_Layer2ManagerV11.CallOpts, role)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _Layer2ManagerV11.Contract.HasRole(&_Layer2ManagerV11.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _Layer2ManagerV11.Contract.HasRole(&_Layer2ManagerV11.CallOpts, role, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) IsAdmin(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "isAdmin", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) IsAdmin(account common.Address) (bool, error) {
	return _Layer2ManagerV11.Contract.IsAdmin(&_Layer2ManagerV11.CallOpts, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) IsAdmin(account common.Address) (bool, error) {
	return _Layer2ManagerV11.Contract.IsAdmin(&_Layer2ManagerV11.CallOpts, account)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) IsOwner(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "isOwner")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) IsOwner() (bool, error) {
	return _Layer2ManagerV11.Contract.IsOwner(&_Layer2ManagerV11.CallOpts)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) IsOwner() (bool, error) {
	return _Layer2ManagerV11.Contract.IsOwner(&_Layer2ManagerV11.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) L1BridgeRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "l1BridgeRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) L1BridgeRegistry() (common.Address, error) {
	return _Layer2ManagerV11.Contract.L1BridgeRegistry(&_Layer2ManagerV11.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) L1BridgeRegistry() (common.Address, error) {
	return _Layer2ManagerV11.Contract.L1BridgeRegistry(&_Layer2ManagerV11.CallOpts)
}

// LayerInfo is a free data retrieval call binding the contract method 0x5df5fb3c.
//
// Solidity: function layerInfo(address layer2) view returns(address rollupConfig, address operator)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) LayerInfo(opts *bind.CallOpts, layer2 common.Address) (struct {
	RollupConfig common.Address
	Operator     common.Address
}, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "layerInfo", layer2)

	outstruct := new(struct {
		RollupConfig common.Address
		Operator     common.Address
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.RollupConfig = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.Operator = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)

	return *outstruct, err

}

// LayerInfo is a free data retrieval call binding the contract method 0x5df5fb3c.
//
// Solidity: function layerInfo(address layer2) view returns(address rollupConfig, address operator)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) LayerInfo(layer2 common.Address) (struct {
	RollupConfig common.Address
	Operator     common.Address
}, error) {
	return _Layer2ManagerV11.Contract.LayerInfo(&_Layer2ManagerV11.CallOpts, layer2)
}

// LayerInfo is a free data retrieval call binding the contract method 0x5df5fb3c.
//
// Solidity: function layerInfo(address layer2) view returns(address rollupConfig, address operator)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) LayerInfo(layer2 common.Address) (struct {
	RollupConfig common.Address
	Operator     common.Address
}, error) {
	return _Layer2ManagerV11.Contract.LayerInfo(&_Layer2ManagerV11.CallOpts, layer2)
}

// MinimumInitialDepositAmount is a free data retrieval call binding the contract method 0xe9d6ec4f.
//
// Solidity: function minimumInitialDepositAmount() view returns(uint256)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) MinimumInitialDepositAmount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "minimumInitialDepositAmount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MinimumInitialDepositAmount is a free data retrieval call binding the contract method 0xe9d6ec4f.
//
// Solidity: function minimumInitialDepositAmount() view returns(uint256)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) MinimumInitialDepositAmount() (*big.Int, error) {
	return _Layer2ManagerV11.Contract.MinimumInitialDepositAmount(&_Layer2ManagerV11.CallOpts)
}

// MinimumInitialDepositAmount is a free data retrieval call binding the contract method 0xe9d6ec4f.
//
// Solidity: function minimumInitialDepositAmount() view returns(uint256)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) MinimumInitialDepositAmount() (*big.Int, error) {
	return _Layer2ManagerV11.Contract.MinimumInitialDepositAmount(&_Layer2ManagerV11.CallOpts)
}

// OperatorInfo is a free data retrieval call binding the contract method 0x50c246d6.
//
// Solidity: function operatorInfo(address ) view returns(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) OperatorInfo(opts *bind.CallOpts, arg0 common.Address) (struct {
	RollupConfig   common.Address
	CandidateAddOn common.Address
}, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "operatorInfo", arg0)

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
func (_Layer2ManagerV11 *Layer2ManagerV11Session) OperatorInfo(arg0 common.Address) (struct {
	RollupConfig   common.Address
	CandidateAddOn common.Address
}, error) {
	return _Layer2ManagerV11.Contract.OperatorInfo(&_Layer2ManagerV11.CallOpts, arg0)
}

// OperatorInfo is a free data retrieval call binding the contract method 0x50c246d6.
//
// Solidity: function operatorInfo(address ) view returns(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) OperatorInfo(arg0 common.Address) (struct {
	RollupConfig   common.Address
	CandidateAddOn common.Address
}, error) {
	return _Layer2ManagerV11.Contract.OperatorInfo(&_Layer2ManagerV11.CallOpts, arg0)
}

// OperatorManagerFactory is a free data retrieval call binding the contract method 0xaba8e577.
//
// Solidity: function operatorManagerFactory() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) OperatorManagerFactory(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "operatorManagerFactory")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// OperatorManagerFactory is a free data retrieval call binding the contract method 0xaba8e577.
//
// Solidity: function operatorManagerFactory() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) OperatorManagerFactory() (common.Address, error) {
	return _Layer2ManagerV11.Contract.OperatorManagerFactory(&_Layer2ManagerV11.CallOpts)
}

// OperatorManagerFactory is a free data retrieval call binding the contract method 0xaba8e577.
//
// Solidity: function operatorManagerFactory() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) OperatorManagerFactory() (common.Address, error) {
	return _Layer2ManagerV11.Contract.OperatorManagerFactory(&_Layer2ManagerV11.CallOpts)
}

// OperatorOfLayer is a free data retrieval call binding the contract method 0xe4a3b456.
//
// Solidity: function operatorOfLayer(address ) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) OperatorOfLayer(opts *bind.CallOpts, arg0 common.Address) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "operatorOfLayer", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// OperatorOfLayer is a free data retrieval call binding the contract method 0xe4a3b456.
//
// Solidity: function operatorOfLayer(address ) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) OperatorOfLayer(arg0 common.Address) (common.Address, error) {
	return _Layer2ManagerV11.Contract.OperatorOfLayer(&_Layer2ManagerV11.CallOpts, arg0)
}

// OperatorOfLayer is a free data retrieval call binding the contract method 0xe4a3b456.
//
// Solidity: function operatorOfLayer(address ) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) OperatorOfLayer(arg0 common.Address) (common.Address, error) {
	return _Layer2ManagerV11.Contract.OperatorOfLayer(&_Layer2ManagerV11.CallOpts, arg0)
}

// OperatorOfRollupConfig is a free data retrieval call binding the contract method 0xff600b69.
//
// Solidity: function operatorOfRollupConfig(address _rollupConfig) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) OperatorOfRollupConfig(opts *bind.CallOpts, _rollupConfig common.Address) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "operatorOfRollupConfig", _rollupConfig)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// OperatorOfRollupConfig is a free data retrieval call binding the contract method 0xff600b69.
//
// Solidity: function operatorOfRollupConfig(address _rollupConfig) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) OperatorOfRollupConfig(_rollupConfig common.Address) (common.Address, error) {
	return _Layer2ManagerV11.Contract.OperatorOfRollupConfig(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// OperatorOfRollupConfig is a free data retrieval call binding the contract method 0xff600b69.
//
// Solidity: function operatorOfRollupConfig(address _rollupConfig) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) OperatorOfRollupConfig(_rollupConfig common.Address) (common.Address, error) {
	return _Layer2ManagerV11.Contract.OperatorOfRollupConfig(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) PauseProxy(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "pauseProxy")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) PauseProxy() (bool, error) {
	return _Layer2ManagerV11.Contract.PauseProxy(&_Layer2ManagerV11.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) PauseProxy() (bool, error) {
	return _Layer2ManagerV11.Contract.PauseProxy(&_Layer2ManagerV11.CallOpts)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) ProxyImplementation(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "proxyImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _Layer2ManagerV11.Contract.ProxyImplementation(&_Layer2ManagerV11.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _Layer2ManagerV11.Contract.ProxyImplementation(&_Layer2ManagerV11.CallOpts, arg0)
}

// RollupConfigInfo is a free data retrieval call binding the contract method 0x72898c23.
//
// Solidity: function rollupConfigInfo(address ) view returns(uint8 status, address operatorManager)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) RollupConfigInfo(opts *bind.CallOpts, arg0 common.Address) (struct {
	Status          uint8
	OperatorManager common.Address
}, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "rollupConfigInfo", arg0)

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
func (_Layer2ManagerV11 *Layer2ManagerV11Session) RollupConfigInfo(arg0 common.Address) (struct {
	Status          uint8
	OperatorManager common.Address
}, error) {
	return _Layer2ManagerV11.Contract.RollupConfigInfo(&_Layer2ManagerV11.CallOpts, arg0)
}

// RollupConfigInfo is a free data retrieval call binding the contract method 0x72898c23.
//
// Solidity: function rollupConfigInfo(address ) view returns(uint8 status, address operatorManager)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) RollupConfigInfo(arg0 common.Address) (struct {
	Status          uint8
	OperatorManager common.Address
}, error) {
	return _Layer2ManagerV11.Contract.RollupConfigInfo(&_Layer2ManagerV11.CallOpts, arg0)
}

// RollupConfigOfOperator is a free data retrieval call binding the contract method 0xa37d6aa7.
//
// Solidity: function rollupConfigOfOperator(address _oper) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) RollupConfigOfOperator(opts *bind.CallOpts, _oper common.Address) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "rollupConfigOfOperator", _oper)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// RollupConfigOfOperator is a free data retrieval call binding the contract method 0xa37d6aa7.
//
// Solidity: function rollupConfigOfOperator(address _oper) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) RollupConfigOfOperator(_oper common.Address) (common.Address, error) {
	return _Layer2ManagerV11.Contract.RollupConfigOfOperator(&_Layer2ManagerV11.CallOpts, _oper)
}

// RollupConfigOfOperator is a free data retrieval call binding the contract method 0xa37d6aa7.
//
// Solidity: function rollupConfigOfOperator(address _oper) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) RollupConfigOfOperator(_oper common.Address) (common.Address, error) {
	return _Layer2ManagerV11.Contract.RollupConfigOfOperator(&_Layer2ManagerV11.CallOpts, _oper)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) SeigManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "seigManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) SeigManager() (common.Address, error) {
	return _Layer2ManagerV11.Contract.SeigManager(&_Layer2ManagerV11.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) SeigManager() (common.Address, error) {
	return _Layer2ManagerV11.Contract.SeigManager(&_Layer2ManagerV11.CallOpts)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) SelectorImplementation(opts *bind.CallOpts, arg0 [4]byte) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "selectorImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _Layer2ManagerV11.Contract.SelectorImplementation(&_Layer2ManagerV11.CallOpts, arg0)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _Layer2ManagerV11.Contract.SelectorImplementation(&_Layer2ManagerV11.CallOpts, arg0)
}

// StatusLayer2 is a free data retrieval call binding the contract method 0x79a0e6ea.
//
// Solidity: function statusLayer2(address _rollupConfig) view returns(uint8)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) StatusLayer2(opts *bind.CallOpts, _rollupConfig common.Address) (uint8, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "statusLayer2", _rollupConfig)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// StatusLayer2 is a free data retrieval call binding the contract method 0x79a0e6ea.
//
// Solidity: function statusLayer2(address _rollupConfig) view returns(uint8)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) StatusLayer2(_rollupConfig common.Address) (uint8, error) {
	return _Layer2ManagerV11.Contract.StatusLayer2(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// StatusLayer2 is a free data retrieval call binding the contract method 0x79a0e6ea.
//
// Solidity: function statusLayer2(address _rollupConfig) view returns(uint8)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) StatusLayer2(_rollupConfig common.Address) (uint8, error) {
	return _Layer2ManagerV11.Contract.StatusLayer2(&_Layer2ManagerV11.CallOpts, _rollupConfig)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Layer2ManagerV11.Contract.SupportsInterface(&_Layer2ManagerV11.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Layer2ManagerV11.Contract.SupportsInterface(&_Layer2ManagerV11.CallOpts, interfaceId)
}

// SwapProxy is a free data retrieval call binding the contract method 0x6ec4be90.
//
// Solidity: function swapProxy() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) SwapProxy(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "swapProxy")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SwapProxy is a free data retrieval call binding the contract method 0x6ec4be90.
//
// Solidity: function swapProxy() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) SwapProxy() (common.Address, error) {
	return _Layer2ManagerV11.Contract.SwapProxy(&_Layer2ManagerV11.CallOpts)
}

// SwapProxy is a free data retrieval call binding the contract method 0x6ec4be90.
//
// Solidity: function swapProxy() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) SwapProxy() (common.Address, error) {
	return _Layer2ManagerV11.Contract.SwapProxy(&_Layer2ManagerV11.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) Ton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "ton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) Ton() (common.Address, error) {
	return _Layer2ManagerV11.Contract.Ton(&_Layer2ManagerV11.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) Ton() (common.Address, error) {
	return _Layer2ManagerV11.Contract.Ton(&_Layer2ManagerV11.CallOpts)
}

// VerifyOperator is a free data retrieval call binding the contract method 0x84b65aaf.
//
// Solidity: function verifyOperator(address layer2, address _rollupConfig, address _operator) view returns(bool verified)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) VerifyOperator(opts *bind.CallOpts, layer2 common.Address, _rollupConfig common.Address, _operator common.Address) (bool, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "verifyOperator", layer2, _rollupConfig, _operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// VerifyOperator is a free data retrieval call binding the contract method 0x84b65aaf.
//
// Solidity: function verifyOperator(address layer2, address _rollupConfig, address _operator) view returns(bool verified)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) VerifyOperator(layer2 common.Address, _rollupConfig common.Address, _operator common.Address) (bool, error) {
	return _Layer2ManagerV11.Contract.VerifyOperator(&_Layer2ManagerV11.CallOpts, layer2, _rollupConfig, _operator)
}

// VerifyOperator is a free data retrieval call binding the contract method 0x84b65aaf.
//
// Solidity: function verifyOperator(address layer2, address _rollupConfig, address _operator) view returns(bool verified)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) VerifyOperator(layer2 common.Address, _rollupConfig common.Address, _operator common.Address) (bool, error) {
	return _Layer2ManagerV11.Contract.VerifyOperator(&_Layer2ManagerV11.CallOpts, layer2, _rollupConfig, _operator)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Caller) Wton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Layer2ManagerV11.contract.Call(opts, &out, "wton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) Wton() (common.Address, error) {
	return _Layer2ManagerV11.Contract.Wton(&_Layer2ManagerV11.CallOpts)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_Layer2ManagerV11 *Layer2ManagerV11CallerSession) Wton() (common.Address, error) {
	return _Layer2ManagerV11.Contract.Wton(&_Layer2ManagerV11.CallOpts)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) AddAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "addAdmin", account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.AddAdmin(&_Layer2ManagerV11.TransactOpts, account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.AddAdmin(&_Layer2ManagerV11.TransactOpts, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.GrantRole(&_Layer2ManagerV11.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.GrantRole(&_Layer2ManagerV11.TransactOpts, role, account)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) OnApprove(opts *bind.TransactOpts, owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "onApprove", owner, spender, amount, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11Session) OnApprove(owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.OnApprove(&_Layer2ManagerV11.TransactOpts, owner, spender, amount, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) OnApprove(owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.OnApprove(&_Layer2ManagerV11.TransactOpts, owner, spender, amount, data)
}

// PauseCandidateAddOn is a paid mutator transaction binding the contract method 0x32d89cc6.
//
// Solidity: function pauseCandidateAddOn(address rollupConfig) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) PauseCandidateAddOn(opts *bind.TransactOpts, rollupConfig common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "pauseCandidateAddOn", rollupConfig)
}

// PauseCandidateAddOn is a paid mutator transaction binding the contract method 0x32d89cc6.
//
// Solidity: function pauseCandidateAddOn(address rollupConfig) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) PauseCandidateAddOn(rollupConfig common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.PauseCandidateAddOn(&_Layer2ManagerV11.TransactOpts, rollupConfig)
}

// PauseCandidateAddOn is a paid mutator transaction binding the contract method 0x32d89cc6.
//
// Solidity: function pauseCandidateAddOn(address rollupConfig) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) PauseCandidateAddOn(rollupConfig common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.PauseCandidateAddOn(&_Layer2ManagerV11.TransactOpts, rollupConfig)
}

// RegisterCandidateAddOn is a paid mutator transaction binding the contract method 0xc04a0a42.
//
// Solidity: function registerCandidateAddOn(address rollupConfig, uint256 amount, bool flagTon, string memo) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) RegisterCandidateAddOn(opts *bind.TransactOpts, rollupConfig common.Address, amount *big.Int, flagTon bool, memo string) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "registerCandidateAddOn", rollupConfig, amount, flagTon, memo)
}

// RegisterCandidateAddOn is a paid mutator transaction binding the contract method 0xc04a0a42.
//
// Solidity: function registerCandidateAddOn(address rollupConfig, uint256 amount, bool flagTon, string memo) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) RegisterCandidateAddOn(rollupConfig common.Address, amount *big.Int, flagTon bool, memo string) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.RegisterCandidateAddOn(&_Layer2ManagerV11.TransactOpts, rollupConfig, amount, flagTon, memo)
}

// RegisterCandidateAddOn is a paid mutator transaction binding the contract method 0xc04a0a42.
//
// Solidity: function registerCandidateAddOn(address rollupConfig, uint256 amount, bool flagTon, string memo) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) RegisterCandidateAddOn(rollupConfig common.Address, amount *big.Int, flagTon bool, memo string) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.RegisterCandidateAddOn(&_Layer2ManagerV11.TransactOpts, rollupConfig, amount, flagTon, memo)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) RemoveAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "removeAdmin", account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.RemoveAdmin(&_Layer2ManagerV11.TransactOpts, account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.RemoveAdmin(&_Layer2ManagerV11.TransactOpts, account)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) RenounceOwnership() (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.RenounceOwnership(&_Layer2ManagerV11.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.RenounceOwnership(&_Layer2ManagerV11.TransactOpts)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "renounceRole", role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.RenounceRole(&_Layer2ManagerV11.TransactOpts, role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.RenounceRole(&_Layer2ManagerV11.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.RevokeRole(&_Layer2ManagerV11.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.RevokeRole(&_Layer2ManagerV11.TransactOpts, role, account)
}

// SetAddresses is a paid mutator transaction binding the contract method 0xd733cfd0.
//
// Solidity: function setAddresses(address _l1BridgeRegistry, address _operatorManagerFactory, address _ton, address _wton, address _dao, address _depositManager, address _seigManager, address _swapProxy) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) SetAddresses(opts *bind.TransactOpts, _l1BridgeRegistry common.Address, _operatorManagerFactory common.Address, _ton common.Address, _wton common.Address, _dao common.Address, _depositManager common.Address, _seigManager common.Address, _swapProxy common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "setAddresses", _l1BridgeRegistry, _operatorManagerFactory, _ton, _wton, _dao, _depositManager, _seigManager, _swapProxy)
}

// SetAddresses is a paid mutator transaction binding the contract method 0xd733cfd0.
//
// Solidity: function setAddresses(address _l1BridgeRegistry, address _operatorManagerFactory, address _ton, address _wton, address _dao, address _depositManager, address _seigManager, address _swapProxy) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) SetAddresses(_l1BridgeRegistry common.Address, _operatorManagerFactory common.Address, _ton common.Address, _wton common.Address, _dao common.Address, _depositManager common.Address, _seigManager common.Address, _swapProxy common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.SetAddresses(&_Layer2ManagerV11.TransactOpts, _l1BridgeRegistry, _operatorManagerFactory, _ton, _wton, _dao, _depositManager, _seigManager, _swapProxy)
}

// SetAddresses is a paid mutator transaction binding the contract method 0xd733cfd0.
//
// Solidity: function setAddresses(address _l1BridgeRegistry, address _operatorManagerFactory, address _ton, address _wton, address _dao, address _depositManager, address _seigManager, address _swapProxy) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) SetAddresses(_l1BridgeRegistry common.Address, _operatorManagerFactory common.Address, _ton common.Address, _wton common.Address, _dao common.Address, _depositManager common.Address, _seigManager common.Address, _swapProxy common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.SetAddresses(&_Layer2ManagerV11.TransactOpts, _l1BridgeRegistry, _operatorManagerFactory, _ton, _wton, _dao, _depositManager, _seigManager, _swapProxy)
}

// SetMinimumInitialDepositAmount is a paid mutator transaction binding the contract method 0x4318dc1d.
//
// Solidity: function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) SetMinimumInitialDepositAmount(opts *bind.TransactOpts, _minimumInitialDepositAmount *big.Int) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "setMinimumInitialDepositAmount", _minimumInitialDepositAmount)
}

// SetMinimumInitialDepositAmount is a paid mutator transaction binding the contract method 0x4318dc1d.
//
// Solidity: function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) SetMinimumInitialDepositAmount(_minimumInitialDepositAmount *big.Int) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.SetMinimumInitialDepositAmount(&_Layer2ManagerV11.TransactOpts, _minimumInitialDepositAmount)
}

// SetMinimumInitialDepositAmount is a paid mutator transaction binding the contract method 0x4318dc1d.
//
// Solidity: function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) SetMinimumInitialDepositAmount(_minimumInitialDepositAmount *big.Int) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.SetMinimumInitialDepositAmount(&_Layer2ManagerV11.TransactOpts, _minimumInitialDepositAmount)
}

// SetOperatorManagerFactory is a paid mutator transaction binding the contract method 0xc8452265.
//
// Solidity: function setOperatorManagerFactory(address _operatorManagerFactory) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) SetOperatorManagerFactory(opts *bind.TransactOpts, _operatorManagerFactory common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "setOperatorManagerFactory", _operatorManagerFactory)
}

// SetOperatorManagerFactory is a paid mutator transaction binding the contract method 0xc8452265.
//
// Solidity: function setOperatorManagerFactory(address _operatorManagerFactory) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) SetOperatorManagerFactory(_operatorManagerFactory common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.SetOperatorManagerFactory(&_Layer2ManagerV11.TransactOpts, _operatorManagerFactory)
}

// SetOperatorManagerFactory is a paid mutator transaction binding the contract method 0xc8452265.
//
// Solidity: function setOperatorManagerFactory(address _operatorManagerFactory) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) SetOperatorManagerFactory(_operatorManagerFactory common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.SetOperatorManagerFactory(&_Layer2ManagerV11.TransactOpts, _operatorManagerFactory)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) TransferAdmin(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "transferAdmin", newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.TransferAdmin(&_Layer2ManagerV11.TransactOpts, newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.TransferAdmin(&_Layer2ManagerV11.TransactOpts, newAdmin)
}

// TransferL2Seigniorage is a paid mutator transaction binding the contract method 0xe5cf4e15.
//
// Solidity: function transferL2Seigniorage(address layer2, uint256 amount) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) TransferL2Seigniorage(opts *bind.TransactOpts, layer2 common.Address, amount *big.Int) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "transferL2Seigniorage", layer2, amount)
}

// TransferL2Seigniorage is a paid mutator transaction binding the contract method 0xe5cf4e15.
//
// Solidity: function transferL2Seigniorage(address layer2, uint256 amount) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) TransferL2Seigniorage(layer2 common.Address, amount *big.Int) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.TransferL2Seigniorage(&_Layer2ManagerV11.TransactOpts, layer2, amount)
}

// TransferL2Seigniorage is a paid mutator transaction binding the contract method 0xe5cf4e15.
//
// Solidity: function transferL2Seigniorage(address layer2, uint256 amount) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) TransferL2Seigniorage(layer2 common.Address, amount *big.Int) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.TransferL2Seigniorage(&_Layer2ManagerV11.TransactOpts, layer2, amount)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) TransferOwnership(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "transferOwnership", newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) TransferOwnership(newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.TransferOwnership(&_Layer2ManagerV11.TransactOpts, newAdmin)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newAdmin) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) TransferOwnership(newAdmin common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.TransferOwnership(&_Layer2ManagerV11.TransactOpts, newAdmin)
}

// UnpauseCandidateAddOn is a paid mutator transaction binding the contract method 0xd523c077.
//
// Solidity: function unpauseCandidateAddOn(address rollupConfig) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Transactor) UnpauseCandidateAddOn(opts *bind.TransactOpts, rollupConfig common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.contract.Transact(opts, "unpauseCandidateAddOn", rollupConfig)
}

// UnpauseCandidateAddOn is a paid mutator transaction binding the contract method 0xd523c077.
//
// Solidity: function unpauseCandidateAddOn(address rollupConfig) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11Session) UnpauseCandidateAddOn(rollupConfig common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.UnpauseCandidateAddOn(&_Layer2ManagerV11.TransactOpts, rollupConfig)
}

// UnpauseCandidateAddOn is a paid mutator transaction binding the contract method 0xd523c077.
//
// Solidity: function unpauseCandidateAddOn(address rollupConfig) returns()
func (_Layer2ManagerV11 *Layer2ManagerV11TransactorSession) UnpauseCandidateAddOn(rollupConfig common.Address) (*types.Transaction, error) {
	return _Layer2ManagerV11.Contract.UnpauseCandidateAddOn(&_Layer2ManagerV11.TransactOpts, rollupConfig)
}

// Layer2ManagerV11PausedCandidateAddOnIterator is returned from FilterPausedCandidateAddOn and is used to iterate over the raw logs and unpacked data for PausedCandidateAddOn events raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11PausedCandidateAddOnIterator struct {
	Event *Layer2ManagerV11PausedCandidateAddOn // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerV11PausedCandidateAddOnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerV11PausedCandidateAddOn)
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
		it.Event = new(Layer2ManagerV11PausedCandidateAddOn)
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
func (it *Layer2ManagerV11PausedCandidateAddOnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerV11PausedCandidateAddOnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerV11PausedCandidateAddOn represents a PausedCandidateAddOn event raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11PausedCandidateAddOn struct {
	RollupConfig   common.Address
	CandidateAddOn common.Address
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterPausedCandidateAddOn is a free log retrieval operation binding the contract event 0x14280f6eab1c847215d9714b0aa6711ad26e21304f06a85a46ad07a1f11e8370.
//
// Solidity: event PausedCandidateAddOn(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) FilterPausedCandidateAddOn(opts *bind.FilterOpts) (*Layer2ManagerV11PausedCandidateAddOnIterator, error) {

	logs, sub, err := _Layer2ManagerV11.contract.FilterLogs(opts, "PausedCandidateAddOn")
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11PausedCandidateAddOnIterator{contract: _Layer2ManagerV11.contract, event: "PausedCandidateAddOn", logs: logs, sub: sub}, nil
}

// WatchPausedCandidateAddOn is a free log subscription operation binding the contract event 0x14280f6eab1c847215d9714b0aa6711ad26e21304f06a85a46ad07a1f11e8370.
//
// Solidity: event PausedCandidateAddOn(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) WatchPausedCandidateAddOn(opts *bind.WatchOpts, sink chan<- *Layer2ManagerV11PausedCandidateAddOn) (event.Subscription, error) {

	logs, sub, err := _Layer2ManagerV11.contract.WatchLogs(opts, "PausedCandidateAddOn")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerV11PausedCandidateAddOn)
				if err := _Layer2ManagerV11.contract.UnpackLog(event, "PausedCandidateAddOn", log); err != nil {
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

// ParsePausedCandidateAddOn is a log parse operation binding the contract event 0x14280f6eab1c847215d9714b0aa6711ad26e21304f06a85a46ad07a1f11e8370.
//
// Solidity: event PausedCandidateAddOn(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) ParsePausedCandidateAddOn(log types.Log) (*Layer2ManagerV11PausedCandidateAddOn, error) {
	event := new(Layer2ManagerV11PausedCandidateAddOn)
	if err := _Layer2ManagerV11.contract.UnpackLog(event, "PausedCandidateAddOn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerV11RegisteredCandidateAddOnIterator is returned from FilterRegisteredCandidateAddOn and is used to iterate over the raw logs and unpacked data for RegisteredCandidateAddOn events raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11RegisteredCandidateAddOnIterator struct {
	Event *Layer2ManagerV11RegisteredCandidateAddOn // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerV11RegisteredCandidateAddOnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerV11RegisteredCandidateAddOn)
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
		it.Event = new(Layer2ManagerV11RegisteredCandidateAddOn)
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
func (it *Layer2ManagerV11RegisteredCandidateAddOnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerV11RegisteredCandidateAddOnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerV11RegisteredCandidateAddOn represents a RegisteredCandidateAddOn event raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11RegisteredCandidateAddOn struct {
	RollupConfig   common.Address
	WtonAmount     *big.Int
	Memo           string
	Operator       common.Address
	CandidateAddOn common.Address
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterRegisteredCandidateAddOn is a free log retrieval operation binding the contract event 0x3685763fd42e5061ff53b001782ad759eafbc93a460b368a4ce42228ec45da98.
//
// Solidity: event RegisteredCandidateAddOn(address rollupConfig, uint256 wtonAmount, string memo, address operator, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) FilterRegisteredCandidateAddOn(opts *bind.FilterOpts) (*Layer2ManagerV11RegisteredCandidateAddOnIterator, error) {

	logs, sub, err := _Layer2ManagerV11.contract.FilterLogs(opts, "RegisteredCandidateAddOn")
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11RegisteredCandidateAddOnIterator{contract: _Layer2ManagerV11.contract, event: "RegisteredCandidateAddOn", logs: logs, sub: sub}, nil
}

// WatchRegisteredCandidateAddOn is a free log subscription operation binding the contract event 0x3685763fd42e5061ff53b001782ad759eafbc93a460b368a4ce42228ec45da98.
//
// Solidity: event RegisteredCandidateAddOn(address rollupConfig, uint256 wtonAmount, string memo, address operator, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) WatchRegisteredCandidateAddOn(opts *bind.WatchOpts, sink chan<- *Layer2ManagerV11RegisteredCandidateAddOn) (event.Subscription, error) {

	logs, sub, err := _Layer2ManagerV11.contract.WatchLogs(opts, "RegisteredCandidateAddOn")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerV11RegisteredCandidateAddOn)
				if err := _Layer2ManagerV11.contract.UnpackLog(event, "RegisteredCandidateAddOn", log); err != nil {
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

// ParseRegisteredCandidateAddOn is a log parse operation binding the contract event 0x3685763fd42e5061ff53b001782ad759eafbc93a460b368a4ce42228ec45da98.
//
// Solidity: event RegisteredCandidateAddOn(address rollupConfig, uint256 wtonAmount, string memo, address operator, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) ParseRegisteredCandidateAddOn(log types.Log) (*Layer2ManagerV11RegisteredCandidateAddOn, error) {
	event := new(Layer2ManagerV11RegisteredCandidateAddOn)
	if err := _Layer2ManagerV11.contract.UnpackLog(event, "RegisteredCandidateAddOn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerV11RoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11RoleAdminChangedIterator struct {
	Event *Layer2ManagerV11RoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerV11RoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerV11RoleAdminChanged)
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
		it.Event = new(Layer2ManagerV11RoleAdminChanged)
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
func (it *Layer2ManagerV11RoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerV11RoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerV11RoleAdminChanged represents a RoleAdminChanged event raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11RoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*Layer2ManagerV11RoleAdminChangedIterator, error) {

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

	logs, sub, err := _Layer2ManagerV11.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11RoleAdminChangedIterator{contract: _Layer2ManagerV11.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *Layer2ManagerV11RoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _Layer2ManagerV11.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerV11RoleAdminChanged)
				if err := _Layer2ManagerV11.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) ParseRoleAdminChanged(log types.Log) (*Layer2ManagerV11RoleAdminChanged, error) {
	event := new(Layer2ManagerV11RoleAdminChanged)
	if err := _Layer2ManagerV11.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerV11RoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11RoleGrantedIterator struct {
	Event *Layer2ManagerV11RoleGranted // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerV11RoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerV11RoleGranted)
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
		it.Event = new(Layer2ManagerV11RoleGranted)
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
func (it *Layer2ManagerV11RoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerV11RoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerV11RoleGranted represents a RoleGranted event raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11RoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*Layer2ManagerV11RoleGrantedIterator, error) {

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

	logs, sub, err := _Layer2ManagerV11.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11RoleGrantedIterator{contract: _Layer2ManagerV11.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *Layer2ManagerV11RoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _Layer2ManagerV11.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerV11RoleGranted)
				if err := _Layer2ManagerV11.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) ParseRoleGranted(log types.Log) (*Layer2ManagerV11RoleGranted, error) {
	event := new(Layer2ManagerV11RoleGranted)
	if err := _Layer2ManagerV11.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerV11RoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11RoleRevokedIterator struct {
	Event *Layer2ManagerV11RoleRevoked // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerV11RoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerV11RoleRevoked)
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
		it.Event = new(Layer2ManagerV11RoleRevoked)
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
func (it *Layer2ManagerV11RoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerV11RoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerV11RoleRevoked represents a RoleRevoked event raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11RoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*Layer2ManagerV11RoleRevokedIterator, error) {

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

	logs, sub, err := _Layer2ManagerV11.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11RoleRevokedIterator{contract: _Layer2ManagerV11.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *Layer2ManagerV11RoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _Layer2ManagerV11.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerV11RoleRevoked)
				if err := _Layer2ManagerV11.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) ParseRoleRevoked(log types.Log) (*Layer2ManagerV11RoleRevoked, error) {
	event := new(Layer2ManagerV11RoleRevoked)
	if err := _Layer2ManagerV11.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerV11SetAddressesIterator is returned from FilterSetAddresses and is used to iterate over the raw logs and unpacked data for SetAddresses events raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11SetAddressesIterator struct {
	Event *Layer2ManagerV11SetAddresses // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerV11SetAddressesIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerV11SetAddresses)
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
		it.Event = new(Layer2ManagerV11SetAddresses)
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
func (it *Layer2ManagerV11SetAddressesIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerV11SetAddressesIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerV11SetAddresses represents a SetAddresses event raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11SetAddresses struct {
	L2Register             common.Address
	OperatorManagerFactory common.Address
	Ton                    common.Address
	Wton                   common.Address
	Dao                    common.Address
	DepositManager         common.Address
	SeigManager            common.Address
	SwapProxy              common.Address
	Raw                    types.Log // Blockchain specific contextual infos
}

// FilterSetAddresses is a free log retrieval operation binding the contract event 0x617f1cba5d7b9d5d3c81f0d5c78720ec2be227878bac84c0851b70e4cf61cb08.
//
// Solidity: event SetAddresses(address _l2Register, address _operatorManagerFactory, address _ton, address _wton, address _dao, address _depositManager, address _seigManager, address _swapProxy)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) FilterSetAddresses(opts *bind.FilterOpts) (*Layer2ManagerV11SetAddressesIterator, error) {

	logs, sub, err := _Layer2ManagerV11.contract.FilterLogs(opts, "SetAddresses")
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11SetAddressesIterator{contract: _Layer2ManagerV11.contract, event: "SetAddresses", logs: logs, sub: sub}, nil
}

// WatchSetAddresses is a free log subscription operation binding the contract event 0x617f1cba5d7b9d5d3c81f0d5c78720ec2be227878bac84c0851b70e4cf61cb08.
//
// Solidity: event SetAddresses(address _l2Register, address _operatorManagerFactory, address _ton, address _wton, address _dao, address _depositManager, address _seigManager, address _swapProxy)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) WatchSetAddresses(opts *bind.WatchOpts, sink chan<- *Layer2ManagerV11SetAddresses) (event.Subscription, error) {

	logs, sub, err := _Layer2ManagerV11.contract.WatchLogs(opts, "SetAddresses")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerV11SetAddresses)
				if err := _Layer2ManagerV11.contract.UnpackLog(event, "SetAddresses", log); err != nil {
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

// ParseSetAddresses is a log parse operation binding the contract event 0x617f1cba5d7b9d5d3c81f0d5c78720ec2be227878bac84c0851b70e4cf61cb08.
//
// Solidity: event SetAddresses(address _l2Register, address _operatorManagerFactory, address _ton, address _wton, address _dao, address _depositManager, address _seigManager, address _swapProxy)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) ParseSetAddresses(log types.Log) (*Layer2ManagerV11SetAddresses, error) {
	event := new(Layer2ManagerV11SetAddresses)
	if err := _Layer2ManagerV11.contract.UnpackLog(event, "SetAddresses", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerV11SetMinimumInitialDepositAmountIterator is returned from FilterSetMinimumInitialDepositAmount and is used to iterate over the raw logs and unpacked data for SetMinimumInitialDepositAmount events raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11SetMinimumInitialDepositAmountIterator struct {
	Event *Layer2ManagerV11SetMinimumInitialDepositAmount // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerV11SetMinimumInitialDepositAmountIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerV11SetMinimumInitialDepositAmount)
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
		it.Event = new(Layer2ManagerV11SetMinimumInitialDepositAmount)
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
func (it *Layer2ManagerV11SetMinimumInitialDepositAmountIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerV11SetMinimumInitialDepositAmountIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerV11SetMinimumInitialDepositAmount represents a SetMinimumInitialDepositAmount event raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11SetMinimumInitialDepositAmount struct {
	MinimumInitialDepositAmount *big.Int
	Raw                         types.Log // Blockchain specific contextual infos
}

// FilterSetMinimumInitialDepositAmount is a free log retrieval operation binding the contract event 0x50e01964a144ee7e40d80d0792ff2641558654ef906fd81502421f22bf6ca92c.
//
// Solidity: event SetMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) FilterSetMinimumInitialDepositAmount(opts *bind.FilterOpts) (*Layer2ManagerV11SetMinimumInitialDepositAmountIterator, error) {

	logs, sub, err := _Layer2ManagerV11.contract.FilterLogs(opts, "SetMinimumInitialDepositAmount")
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11SetMinimumInitialDepositAmountIterator{contract: _Layer2ManagerV11.contract, event: "SetMinimumInitialDepositAmount", logs: logs, sub: sub}, nil
}

// WatchSetMinimumInitialDepositAmount is a free log subscription operation binding the contract event 0x50e01964a144ee7e40d80d0792ff2641558654ef906fd81502421f22bf6ca92c.
//
// Solidity: event SetMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) WatchSetMinimumInitialDepositAmount(opts *bind.WatchOpts, sink chan<- *Layer2ManagerV11SetMinimumInitialDepositAmount) (event.Subscription, error) {

	logs, sub, err := _Layer2ManagerV11.contract.WatchLogs(opts, "SetMinimumInitialDepositAmount")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerV11SetMinimumInitialDepositAmount)
				if err := _Layer2ManagerV11.contract.UnpackLog(event, "SetMinimumInitialDepositAmount", log); err != nil {
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

// ParseSetMinimumInitialDepositAmount is a log parse operation binding the contract event 0x50e01964a144ee7e40d80d0792ff2641558654ef906fd81502421f22bf6ca92c.
//
// Solidity: event SetMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) ParseSetMinimumInitialDepositAmount(log types.Log) (*Layer2ManagerV11SetMinimumInitialDepositAmount, error) {
	event := new(Layer2ManagerV11SetMinimumInitialDepositAmount)
	if err := _Layer2ManagerV11.contract.UnpackLog(event, "SetMinimumInitialDepositAmount", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerV11SetOperatorManagerFactoryIterator is returned from FilterSetOperatorManagerFactory and is used to iterate over the raw logs and unpacked data for SetOperatorManagerFactory events raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11SetOperatorManagerFactoryIterator struct {
	Event *Layer2ManagerV11SetOperatorManagerFactory // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerV11SetOperatorManagerFactoryIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerV11SetOperatorManagerFactory)
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
		it.Event = new(Layer2ManagerV11SetOperatorManagerFactory)
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
func (it *Layer2ManagerV11SetOperatorManagerFactoryIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerV11SetOperatorManagerFactoryIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerV11SetOperatorManagerFactory represents a SetOperatorManagerFactory event raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11SetOperatorManagerFactory struct {
	OperatorManagerFactory common.Address
	Raw                    types.Log // Blockchain specific contextual infos
}

// FilterSetOperatorManagerFactory is a free log retrieval operation binding the contract event 0x2342c0559c82fec746d047e08479a8b46bf45d4265f1db1c3a685b542c06f6a2.
//
// Solidity: event SetOperatorManagerFactory(address _operatorManagerFactory)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) FilterSetOperatorManagerFactory(opts *bind.FilterOpts) (*Layer2ManagerV11SetOperatorManagerFactoryIterator, error) {

	logs, sub, err := _Layer2ManagerV11.contract.FilterLogs(opts, "SetOperatorManagerFactory")
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11SetOperatorManagerFactoryIterator{contract: _Layer2ManagerV11.contract, event: "SetOperatorManagerFactory", logs: logs, sub: sub}, nil
}

// WatchSetOperatorManagerFactory is a free log subscription operation binding the contract event 0x2342c0559c82fec746d047e08479a8b46bf45d4265f1db1c3a685b542c06f6a2.
//
// Solidity: event SetOperatorManagerFactory(address _operatorManagerFactory)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) WatchSetOperatorManagerFactory(opts *bind.WatchOpts, sink chan<- *Layer2ManagerV11SetOperatorManagerFactory) (event.Subscription, error) {

	logs, sub, err := _Layer2ManagerV11.contract.WatchLogs(opts, "SetOperatorManagerFactory")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerV11SetOperatorManagerFactory)
				if err := _Layer2ManagerV11.contract.UnpackLog(event, "SetOperatorManagerFactory", log); err != nil {
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

// ParseSetOperatorManagerFactory is a log parse operation binding the contract event 0x2342c0559c82fec746d047e08479a8b46bf45d4265f1db1c3a685b542c06f6a2.
//
// Solidity: event SetOperatorManagerFactory(address _operatorManagerFactory)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) ParseSetOperatorManagerFactory(log types.Log) (*Layer2ManagerV11SetOperatorManagerFactory, error) {
	event := new(Layer2ManagerV11SetOperatorManagerFactory)
	if err := _Layer2ManagerV11.contract.UnpackLog(event, "SetOperatorManagerFactory", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerV11TransferWTONIterator is returned from FilterTransferWTON and is used to iterate over the raw logs and unpacked data for TransferWTON events raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11TransferWTONIterator struct {
	Event *Layer2ManagerV11TransferWTON // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerV11TransferWTONIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerV11TransferWTON)
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
		it.Event = new(Layer2ManagerV11TransferWTON)
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
func (it *Layer2ManagerV11TransferWTONIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerV11TransferWTONIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerV11TransferWTON represents a TransferWTON event raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11TransferWTON struct {
	Layer2 common.Address
	To     common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterTransferWTON is a free log retrieval operation binding the contract event 0xa8a9366ade6fe20cecb8cfb135bf668209b911ef84313bd0a412aa86feb85503.
//
// Solidity: event TransferWTON(address layer2, address to, uint256 amount)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) FilterTransferWTON(opts *bind.FilterOpts) (*Layer2ManagerV11TransferWTONIterator, error) {

	logs, sub, err := _Layer2ManagerV11.contract.FilterLogs(opts, "TransferWTON")
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11TransferWTONIterator{contract: _Layer2ManagerV11.contract, event: "TransferWTON", logs: logs, sub: sub}, nil
}

// WatchTransferWTON is a free log subscription operation binding the contract event 0xa8a9366ade6fe20cecb8cfb135bf668209b911ef84313bd0a412aa86feb85503.
//
// Solidity: event TransferWTON(address layer2, address to, uint256 amount)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) WatchTransferWTON(opts *bind.WatchOpts, sink chan<- *Layer2ManagerV11TransferWTON) (event.Subscription, error) {

	logs, sub, err := _Layer2ManagerV11.contract.WatchLogs(opts, "TransferWTON")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerV11TransferWTON)
				if err := _Layer2ManagerV11.contract.UnpackLog(event, "TransferWTON", log); err != nil {
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

// ParseTransferWTON is a log parse operation binding the contract event 0xa8a9366ade6fe20cecb8cfb135bf668209b911ef84313bd0a412aa86feb85503.
//
// Solidity: event TransferWTON(address layer2, address to, uint256 amount)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) ParseTransferWTON(log types.Log) (*Layer2ManagerV11TransferWTON, error) {
	event := new(Layer2ManagerV11TransferWTON)
	if err := _Layer2ManagerV11.contract.UnpackLog(event, "TransferWTON", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// Layer2ManagerV11UnpausedCandidateAddOnIterator is returned from FilterUnpausedCandidateAddOn and is used to iterate over the raw logs and unpacked data for UnpausedCandidateAddOn events raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11UnpausedCandidateAddOnIterator struct {
	Event *Layer2ManagerV11UnpausedCandidateAddOn // Event containing the contract specifics and raw log

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
func (it *Layer2ManagerV11UnpausedCandidateAddOnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(Layer2ManagerV11UnpausedCandidateAddOn)
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
		it.Event = new(Layer2ManagerV11UnpausedCandidateAddOn)
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
func (it *Layer2ManagerV11UnpausedCandidateAddOnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *Layer2ManagerV11UnpausedCandidateAddOnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// Layer2ManagerV11UnpausedCandidateAddOn represents a UnpausedCandidateAddOn event raised by the Layer2ManagerV11 contract.
type Layer2ManagerV11UnpausedCandidateAddOn struct {
	RollupConfig   common.Address
	CandidateAddOn common.Address
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterUnpausedCandidateAddOn is a free log retrieval operation binding the contract event 0xaf0a20fb16d60a15e38b6cd70fa0cce0bd2a744265663dfcbc90a02b360caf80.
//
// Solidity: event UnpausedCandidateAddOn(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) FilterUnpausedCandidateAddOn(opts *bind.FilterOpts) (*Layer2ManagerV11UnpausedCandidateAddOnIterator, error) {

	logs, sub, err := _Layer2ManagerV11.contract.FilterLogs(opts, "UnpausedCandidateAddOn")
	if err != nil {
		return nil, err
	}
	return &Layer2ManagerV11UnpausedCandidateAddOnIterator{contract: _Layer2ManagerV11.contract, event: "UnpausedCandidateAddOn", logs: logs, sub: sub}, nil
}

// WatchUnpausedCandidateAddOn is a free log subscription operation binding the contract event 0xaf0a20fb16d60a15e38b6cd70fa0cce0bd2a744265663dfcbc90a02b360caf80.
//
// Solidity: event UnpausedCandidateAddOn(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) WatchUnpausedCandidateAddOn(opts *bind.WatchOpts, sink chan<- *Layer2ManagerV11UnpausedCandidateAddOn) (event.Subscription, error) {

	logs, sub, err := _Layer2ManagerV11.contract.WatchLogs(opts, "UnpausedCandidateAddOn")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(Layer2ManagerV11UnpausedCandidateAddOn)
				if err := _Layer2ManagerV11.contract.UnpackLog(event, "UnpausedCandidateAddOn", log); err != nil {
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

// ParseUnpausedCandidateAddOn is a log parse operation binding the contract event 0xaf0a20fb16d60a15e38b6cd70fa0cce0bd2a744265663dfcbc90a02b360caf80.
//
// Solidity: event UnpausedCandidateAddOn(address rollupConfig, address candidateAddOn)
func (_Layer2ManagerV11 *Layer2ManagerV11Filterer) ParseUnpausedCandidateAddOn(log types.Log) (*Layer2ManagerV11UnpausedCandidateAddOn, error) {
	event := new(Layer2ManagerV11UnpausedCandidateAddOn)
	if err := _Layer2ManagerV11.contract.UnpackLog(event, "UnpausedCandidateAddOn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
