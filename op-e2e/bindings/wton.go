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

// WTONABI is the input ABI used to generate the binding from.
const WTONABI = "[{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"mint\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onApprove\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"tonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceMinter\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceTonMinter\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"swapFromTONAndTransfer\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"tonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"swapToTON\",\"inputs\":[{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"swapToTONAndTransfer\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"wtonAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transfer\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"}]"

// WTON is an auto generated Go binding around an Ethereum contract.
type WTON struct {
	WTONCaller     // Read-only binding to the contract
	WTONTransactor // Write-only binding to the contract
	WTONFilterer   // Log filterer for contract events
}

// WTONCaller is an auto generated read-only Go binding around an Ethereum contract.
type WTONCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// WTONTransactor is an auto generated write-only Go binding around an Ethereum contract.
type WTONTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// WTONFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type WTONFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// WTONSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type WTONSession struct {
	Contract     *WTON             // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// WTONCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type WTONCallerSession struct {
	Contract *WTONCaller   // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// WTONTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type WTONTransactorSession struct {
	Contract     *WTONTransactor   // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// WTONRaw is an auto generated low-level Go binding around an Ethereum contract.
type WTONRaw struct {
	Contract *WTON // Generic contract binding to access the raw methods on
}

// WTONCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type WTONCallerRaw struct {
	Contract *WTONCaller // Generic read-only contract binding to access the raw methods on
}

// WTONTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type WTONTransactorRaw struct {
	Contract *WTONTransactor // Generic write-only contract binding to access the raw methods on
}

// NewWTON creates a new instance of WTON, bound to a specific deployed contract.
func NewWTON(address common.Address, backend bind.ContractBackend) (*WTON, error) {
	contract, err := bindWTON(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &WTON{WTONCaller: WTONCaller{contract: contract}, WTONTransactor: WTONTransactor{contract: contract}, WTONFilterer: WTONFilterer{contract: contract}}, nil
}

// NewWTONCaller creates a new read-only instance of WTON, bound to a specific deployed contract.
func NewWTONCaller(address common.Address, caller bind.ContractCaller) (*WTONCaller, error) {
	contract, err := bindWTON(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &WTONCaller{contract: contract}, nil
}

// NewWTONTransactor creates a new write-only instance of WTON, bound to a specific deployed contract.
func NewWTONTransactor(address common.Address, transactor bind.ContractTransactor) (*WTONTransactor, error) {
	contract, err := bindWTON(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &WTONTransactor{contract: contract}, nil
}

// NewWTONFilterer creates a new log filterer instance of WTON, bound to a specific deployed contract.
func NewWTONFilterer(address common.Address, filterer bind.ContractFilterer) (*WTONFilterer, error) {
	contract, err := bindWTON(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &WTONFilterer{contract: contract}, nil
}

// bindWTON binds a generic wrapper to an already deployed contract.
func bindWTON(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(WTONABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_WTON *WTONRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _WTON.Contract.WTONCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_WTON *WTONRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WTON.Contract.WTONTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_WTON *WTONRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _WTON.Contract.WTONTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_WTON *WTONCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _WTON.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_WTON *WTONTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WTON.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_WTON *WTONTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _WTON.Contract.contract.Transact(opts, method, params...)
}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address account) view returns(uint256 amount)
func (_WTON *WTONCaller) BalanceOf(opts *bind.CallOpts, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _WTON.contract.Call(opts, &out, "balanceOf", account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address account) view returns(uint256 amount)
func (_WTON *WTONSession) BalanceOf(account common.Address) (*big.Int, error) {
	return _WTON.Contract.BalanceOf(&_WTON.CallOpts, account)
}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address account) view returns(uint256 amount)
func (_WTON *WTONCallerSession) BalanceOf(account common.Address) (*big.Int, error) {
	return _WTON.Contract.BalanceOf(&_WTON.CallOpts, account)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_WTON *WTONCaller) Ton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _WTON.contract.Call(opts, &out, "ton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_WTON *WTONSession) Ton() (common.Address, error) {
	return _WTON.Contract.Ton(&_WTON.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_WTON *WTONCallerSession) Ton() (common.Address, error) {
	return _WTON.Contract.Ton(&_WTON.CallOpts)
}

// Mint is a paid mutator transaction binding the contract method 0x40c10f19.
//
// Solidity: function mint(address account, uint256 amount) returns(bool)
func (_WTON *WTONTransactor) Mint(opts *bind.TransactOpts, account common.Address, amount *big.Int) (*types.Transaction, error) {
	return _WTON.contract.Transact(opts, "mint", account, amount)
}

// Mint is a paid mutator transaction binding the contract method 0x40c10f19.
//
// Solidity: function mint(address account, uint256 amount) returns(bool)
func (_WTON *WTONSession) Mint(account common.Address, amount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.Mint(&_WTON.TransactOpts, account, amount)
}

// Mint is a paid mutator transaction binding the contract method 0x40c10f19.
//
// Solidity: function mint(address account, uint256 amount) returns(bool)
func (_WTON *WTONTransactorSession) Mint(account common.Address, amount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.Mint(&_WTON.TransactOpts, account, amount)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 tonAmount, bytes data) returns(bool)
func (_WTON *WTONTransactor) OnApprove(opts *bind.TransactOpts, owner common.Address, spender common.Address, tonAmount *big.Int, data []byte) (*types.Transaction, error) {
	return _WTON.contract.Transact(opts, "onApprove", owner, spender, tonAmount, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 tonAmount, bytes data) returns(bool)
func (_WTON *WTONSession) OnApprove(owner common.Address, spender common.Address, tonAmount *big.Int, data []byte) (*types.Transaction, error) {
	return _WTON.Contract.OnApprove(&_WTON.TransactOpts, owner, spender, tonAmount, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 tonAmount, bytes data) returns(bool)
func (_WTON *WTONTransactorSession) OnApprove(owner common.Address, spender common.Address, tonAmount *big.Int, data []byte) (*types.Transaction, error) {
	return _WTON.Contract.OnApprove(&_WTON.TransactOpts, owner, spender, tonAmount, data)
}

// RenounceMinter is a paid mutator transaction binding the contract method 0x98650275.
//
// Solidity: function renounceMinter() returns()
func (_WTON *WTONTransactor) RenounceMinter(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WTON.contract.Transact(opts, "renounceMinter")
}

// RenounceMinter is a paid mutator transaction binding the contract method 0x98650275.
//
// Solidity: function renounceMinter() returns()
func (_WTON *WTONSession) RenounceMinter() (*types.Transaction, error) {
	return _WTON.Contract.RenounceMinter(&_WTON.TransactOpts)
}

// RenounceMinter is a paid mutator transaction binding the contract method 0x98650275.
//
// Solidity: function renounceMinter() returns()
func (_WTON *WTONTransactorSession) RenounceMinter() (*types.Transaction, error) {
	return _WTON.Contract.RenounceMinter(&_WTON.TransactOpts)
}

// RenounceTonMinter is a paid mutator transaction binding the contract method 0x05eeb9f7.
//
// Solidity: function renounceTonMinter() returns()
func (_WTON *WTONTransactor) RenounceTonMinter(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WTON.contract.Transact(opts, "renounceTonMinter")
}

// RenounceTonMinter is a paid mutator transaction binding the contract method 0x05eeb9f7.
//
// Solidity: function renounceTonMinter() returns()
func (_WTON *WTONSession) RenounceTonMinter() (*types.Transaction, error) {
	return _WTON.Contract.RenounceTonMinter(&_WTON.TransactOpts)
}

// RenounceTonMinter is a paid mutator transaction binding the contract method 0x05eeb9f7.
//
// Solidity: function renounceTonMinter() returns()
func (_WTON *WTONTransactorSession) RenounceTonMinter() (*types.Transaction, error) {
	return _WTON.Contract.RenounceTonMinter(&_WTON.TransactOpts)
}

// SwapFromTONAndTransfer is a paid mutator transaction binding the contract method 0x588420b7.
//
// Solidity: function swapFromTONAndTransfer(address to, uint256 tonAmount) returns(bool)
func (_WTON *WTONTransactor) SwapFromTONAndTransfer(opts *bind.TransactOpts, to common.Address, tonAmount *big.Int) (*types.Transaction, error) {
	return _WTON.contract.Transact(opts, "swapFromTONAndTransfer", to, tonAmount)
}

// SwapFromTONAndTransfer is a paid mutator transaction binding the contract method 0x588420b7.
//
// Solidity: function swapFromTONAndTransfer(address to, uint256 tonAmount) returns(bool)
func (_WTON *WTONSession) SwapFromTONAndTransfer(to common.Address, tonAmount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.SwapFromTONAndTransfer(&_WTON.TransactOpts, to, tonAmount)
}

// SwapFromTONAndTransfer is a paid mutator transaction binding the contract method 0x588420b7.
//
// Solidity: function swapFromTONAndTransfer(address to, uint256 tonAmount) returns(bool)
func (_WTON *WTONTransactorSession) SwapFromTONAndTransfer(to common.Address, tonAmount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.SwapFromTONAndTransfer(&_WTON.TransactOpts, to, tonAmount)
}

// SwapToTON is a paid mutator transaction binding the contract method 0xf53fe70f.
//
// Solidity: function swapToTON(uint256 wtonAmount) returns(bool)
func (_WTON *WTONTransactor) SwapToTON(opts *bind.TransactOpts, wtonAmount *big.Int) (*types.Transaction, error) {
	return _WTON.contract.Transact(opts, "swapToTON", wtonAmount)
}

// SwapToTON is a paid mutator transaction binding the contract method 0xf53fe70f.
//
// Solidity: function swapToTON(uint256 wtonAmount) returns(bool)
func (_WTON *WTONSession) SwapToTON(wtonAmount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.SwapToTON(&_WTON.TransactOpts, wtonAmount)
}

// SwapToTON is a paid mutator transaction binding the contract method 0xf53fe70f.
//
// Solidity: function swapToTON(uint256 wtonAmount) returns(bool)
func (_WTON *WTONTransactorSession) SwapToTON(wtonAmount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.SwapToTON(&_WTON.TransactOpts, wtonAmount)
}

// SwapToTONAndTransfer is a paid mutator transaction binding the contract method 0xe3b99e85.
//
// Solidity: function swapToTONAndTransfer(address to, uint256 wtonAmount) returns(bool)
func (_WTON *WTONTransactor) SwapToTONAndTransfer(opts *bind.TransactOpts, to common.Address, wtonAmount *big.Int) (*types.Transaction, error) {
	return _WTON.contract.Transact(opts, "swapToTONAndTransfer", to, wtonAmount)
}

// SwapToTONAndTransfer is a paid mutator transaction binding the contract method 0xe3b99e85.
//
// Solidity: function swapToTONAndTransfer(address to, uint256 wtonAmount) returns(bool)
func (_WTON *WTONSession) SwapToTONAndTransfer(to common.Address, wtonAmount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.SwapToTONAndTransfer(&_WTON.TransactOpts, to, wtonAmount)
}

// SwapToTONAndTransfer is a paid mutator transaction binding the contract method 0xe3b99e85.
//
// Solidity: function swapToTONAndTransfer(address to, uint256 wtonAmount) returns(bool)
func (_WTON *WTONTransactorSession) SwapToTONAndTransfer(to common.Address, wtonAmount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.SwapToTONAndTransfer(&_WTON.TransactOpts, to, wtonAmount)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address to, uint256 amount) returns(bool)
func (_WTON *WTONTransactor) Transfer(opts *bind.TransactOpts, to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _WTON.contract.Transact(opts, "transfer", to, amount)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address to, uint256 amount) returns(bool)
func (_WTON *WTONSession) Transfer(to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.Transfer(&_WTON.TransactOpts, to, amount)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address to, uint256 amount) returns(bool)
func (_WTON *WTONTransactorSession) Transfer(to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.Transfer(&_WTON.TransactOpts, to, amount)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 amount) returns(bool)
func (_WTON *WTONTransactor) TransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _WTON.contract.Transact(opts, "transferFrom", from, to, amount)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 amount) returns(bool)
func (_WTON *WTONSession) TransferFrom(from common.Address, to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.TransferFrom(&_WTON.TransactOpts, from, to, amount)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 amount) returns(bool)
func (_WTON *WTONTransactorSession) TransferFrom(from common.Address, to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _WTON.Contract.TransferFrom(&_WTON.TransactOpts, from, to, amount)
}
