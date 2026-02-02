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

// FaultDisputeGameABI is the input ABI used to generate the binding from.
const FaultDisputeGameABI = "[{\"type\":\"function\",\"name\":\"attack\",\"inputs\":[{\"name\":\"_disputed\",\"type\":\"bytes32\",\"internalType\":\"Claim\"},{\"name\":\"_parentIndex\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_claim\",\"type\":\"bytes32\",\"internalType\":\"Claim\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"claimCredit\",\"inputs\":[{\"name\":\"_recipient\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimData\",\"inputs\":[{\"name\":\"_claimIndex\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"parentIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"counteredBy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"claimant\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bond\",\"type\":\"uint128\",\"internalType\":\"uint128\"},{\"name\":\"claim\",\"type\":\"bytes32\",\"internalType\":\"Claim\"},{\"name\":\"position\",\"type\":\"uint128\",\"internalType\":\"uint128\"},{\"name\":\"clock\",\"type\":\"uint128\",\"internalType\":\"uint128\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"claimDataLen\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"credit\",\"inputs\":[{\"name\":\"_recipient\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"defend\",\"inputs\":[{\"name\":\"_disputed\",\"type\":\"bytes32\",\"internalType\":\"Claim\"},{\"name\":\"_parentIndex\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_claim\",\"type\":\"bytes32\",\"internalType\":\"Claim\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"getRequiredBond\",\"inputs\":[{\"name\":\"_position\",\"type\":\"uint128\",\"internalType\":\"uint128\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxClockDuration\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxGameDepth\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"resolve\",\"inputs\":[],\"outputs\":[{\"name\":\"status_\",\"type\":\"uint8\",\"internalType\":\"enumGameStatus\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resolveClaim\",\"inputs\":[{\"name\":\"_claimIndex\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_numToResolve\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"rootClaim\",\"inputs\":[],\"outputs\":[{\"name\":\"rootClaim_\",\"type\":\"bytes32\",\"internalType\":\"Claim\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"splitDepth\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"status\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumGameStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"weth\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIDelayedWETHMinimal\"}],\"stateMutability\":\"view\"}]"

// FaultDisputeGame is an auto generated Go binding around an Ethereum contract.
type FaultDisputeGame struct {
	FaultDisputeGameCaller     // Read-only binding to the contract
	FaultDisputeGameTransactor // Write-only binding to the contract
	FaultDisputeGameFilterer   // Log filterer for contract events
}

// FaultDisputeGameCaller is an auto generated read-only Go binding around an Ethereum contract.
type FaultDisputeGameCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FaultDisputeGameTransactor is an auto generated write-only Go binding around an Ethereum contract.
type FaultDisputeGameTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FaultDisputeGameFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type FaultDisputeGameFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FaultDisputeGameSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type FaultDisputeGameSession struct {
	Contract     *FaultDisputeGame // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// FaultDisputeGameCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type FaultDisputeGameCallerSession struct {
	Contract *FaultDisputeGameCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts           // Call options to use throughout this session
}

// FaultDisputeGameTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type FaultDisputeGameTransactorSession struct {
	Contract     *FaultDisputeGameTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts           // Transaction auth options to use throughout this session
}

// FaultDisputeGameRaw is an auto generated low-level Go binding around an Ethereum contract.
type FaultDisputeGameRaw struct {
	Contract *FaultDisputeGame // Generic contract binding to access the raw methods on
}

// FaultDisputeGameCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type FaultDisputeGameCallerRaw struct {
	Contract *FaultDisputeGameCaller // Generic read-only contract binding to access the raw methods on
}

// FaultDisputeGameTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type FaultDisputeGameTransactorRaw struct {
	Contract *FaultDisputeGameTransactor // Generic write-only contract binding to access the raw methods on
}

// NewFaultDisputeGame creates a new instance of FaultDisputeGame, bound to a specific deployed contract.
func NewFaultDisputeGame(address common.Address, backend bind.ContractBackend) (*FaultDisputeGame, error) {
	contract, err := bindFaultDisputeGame(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &FaultDisputeGame{FaultDisputeGameCaller: FaultDisputeGameCaller{contract: contract}, FaultDisputeGameTransactor: FaultDisputeGameTransactor{contract: contract}, FaultDisputeGameFilterer: FaultDisputeGameFilterer{contract: contract}}, nil
}

// NewFaultDisputeGameCaller creates a new read-only instance of FaultDisputeGame, bound to a specific deployed contract.
func NewFaultDisputeGameCaller(address common.Address, caller bind.ContractCaller) (*FaultDisputeGameCaller, error) {
	contract, err := bindFaultDisputeGame(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &FaultDisputeGameCaller{contract: contract}, nil
}

// NewFaultDisputeGameTransactor creates a new write-only instance of FaultDisputeGame, bound to a specific deployed contract.
func NewFaultDisputeGameTransactor(address common.Address, transactor bind.ContractTransactor) (*FaultDisputeGameTransactor, error) {
	contract, err := bindFaultDisputeGame(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &FaultDisputeGameTransactor{contract: contract}, nil
}

// NewFaultDisputeGameFilterer creates a new log filterer instance of FaultDisputeGame, bound to a specific deployed contract.
func NewFaultDisputeGameFilterer(address common.Address, filterer bind.ContractFilterer) (*FaultDisputeGameFilterer, error) {
	contract, err := bindFaultDisputeGame(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &FaultDisputeGameFilterer{contract: contract}, nil
}

// bindFaultDisputeGame binds a generic wrapper to an already deployed contract.
func bindFaultDisputeGame(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(FaultDisputeGameABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_FaultDisputeGame *FaultDisputeGameRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _FaultDisputeGame.Contract.FaultDisputeGameCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_FaultDisputeGame *FaultDisputeGameRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.FaultDisputeGameTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_FaultDisputeGame *FaultDisputeGameRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.FaultDisputeGameTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_FaultDisputeGame *FaultDisputeGameCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _FaultDisputeGame.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_FaultDisputeGame *FaultDisputeGameTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_FaultDisputeGame *FaultDisputeGameTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.contract.Transact(opts, method, params...)
}

// ClaimData is a free data retrieval call binding the contract method 0xc6f0308c.
//
// Solidity: function claimData(uint256 _claimIndex) view returns(uint32 parentIndex, address counteredBy, address claimant, uint128 bond, bytes32 claim, uint128 position, uint128 clock)
func (_FaultDisputeGame *FaultDisputeGameCaller) ClaimData(opts *bind.CallOpts, _claimIndex *big.Int) (struct {
	ParentIndex uint32
	CounteredBy common.Address
	Claimant    common.Address
	Bond        *big.Int
	Claim       [32]byte
	Position    *big.Int
	Clock       *big.Int
}, error) {
	var out []interface{}
	err := _FaultDisputeGame.contract.Call(opts, &out, "claimData", _claimIndex)

	outstruct := new(struct {
		ParentIndex uint32
		CounteredBy common.Address
		Claimant    common.Address
		Bond        *big.Int
		Claim       [32]byte
		Position    *big.Int
		Clock       *big.Int
	})

	outstruct.ParentIndex = out[0].(uint32)
	outstruct.CounteredBy = out[1].(common.Address)
	outstruct.Claimant = out[2].(common.Address)
	outstruct.Bond = out[3].(*big.Int)
	outstruct.Claim = out[4].([32]byte)
	outstruct.Position = out[5].(*big.Int)
	outstruct.Clock = out[6].(*big.Int)

	return *outstruct, err

}

// ClaimData is a free data retrieval call binding the contract method 0xc6f0308c.
//
// Solidity: function claimData(uint256 _claimIndex) view returns(uint32 parentIndex, address counteredBy, address claimant, uint128 bond, bytes32 claim, uint128 position, uint128 clock)
func (_FaultDisputeGame *FaultDisputeGameSession) ClaimData(_claimIndex *big.Int) (struct {
	ParentIndex uint32
	CounteredBy common.Address
	Claimant    common.Address
	Bond        *big.Int
	Claim       [32]byte
	Position    *big.Int
	Clock       *big.Int
}, error) {
	return _FaultDisputeGame.Contract.ClaimData(&_FaultDisputeGame.CallOpts, _claimIndex)
}

// ClaimData is a free data retrieval call binding the contract method 0xc6f0308c.
//
// Solidity: function claimData(uint256 _claimIndex) view returns(uint32 parentIndex, address counteredBy, address claimant, uint128 bond, bytes32 claim, uint128 position, uint128 clock)
func (_FaultDisputeGame *FaultDisputeGameCallerSession) ClaimData(_claimIndex *big.Int) (struct {
	ParentIndex uint32
	CounteredBy common.Address
	Claimant    common.Address
	Bond        *big.Int
	Claim       [32]byte
	Position    *big.Int
	Clock       *big.Int
}, error) {
	return _FaultDisputeGame.Contract.ClaimData(&_FaultDisputeGame.CallOpts, _claimIndex)
}

// ClaimDataLen is a free data retrieval call binding the contract method 0x8980e0cc.
//
// Solidity: function claimDataLen() view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameCaller) ClaimDataLen(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FaultDisputeGame.contract.Call(opts, &out, "claimDataLen")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ClaimDataLen is a free data retrieval call binding the contract method 0x8980e0cc.
//
// Solidity: function claimDataLen() view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameSession) ClaimDataLen() (*big.Int, error) {
	return _FaultDisputeGame.Contract.ClaimDataLen(&_FaultDisputeGame.CallOpts)
}

// ClaimDataLen is a free data retrieval call binding the contract method 0x8980e0cc.
//
// Solidity: function claimDataLen() view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameCallerSession) ClaimDataLen() (*big.Int, error) {
	return _FaultDisputeGame.Contract.ClaimDataLen(&_FaultDisputeGame.CallOpts)
}

// Credit is a free data retrieval call binding the contract method 0xd5d44d80.
//
// Solidity: function credit(address _recipient) view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameCaller) Credit(opts *bind.CallOpts, _recipient common.Address) (*big.Int, error) {
	var out []interface{}
	err := _FaultDisputeGame.contract.Call(opts, &out, "credit", _recipient)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Credit is a free data retrieval call binding the contract method 0xd5d44d80.
//
// Solidity: function credit(address _recipient) view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameSession) Credit(_recipient common.Address) (*big.Int, error) {
	return _FaultDisputeGame.Contract.Credit(&_FaultDisputeGame.CallOpts, _recipient)
}

// Credit is a free data retrieval call binding the contract method 0xd5d44d80.
//
// Solidity: function credit(address _recipient) view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameCallerSession) Credit(_recipient common.Address) (*big.Int, error) {
	return _FaultDisputeGame.Contract.Credit(&_FaultDisputeGame.CallOpts, _recipient)
}

// GetRequiredBond is a free data retrieval call binding the contract method 0xc395e1ca.
//
// Solidity: function getRequiredBond(uint128 _position) view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameCaller) GetRequiredBond(opts *bind.CallOpts, _position *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _FaultDisputeGame.contract.Call(opts, &out, "getRequiredBond", _position)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetRequiredBond is a free data retrieval call binding the contract method 0xc395e1ca.
//
// Solidity: function getRequiredBond(uint128 _position) view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameSession) GetRequiredBond(_position *big.Int) (*big.Int, error) {
	return _FaultDisputeGame.Contract.GetRequiredBond(&_FaultDisputeGame.CallOpts, _position)
}

// GetRequiredBond is a free data retrieval call binding the contract method 0xc395e1ca.
//
// Solidity: function getRequiredBond(uint128 _position) view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameCallerSession) GetRequiredBond(_position *big.Int) (*big.Int, error) {
	return _FaultDisputeGame.Contract.GetRequiredBond(&_FaultDisputeGame.CallOpts, _position)
}

// MaxClockDuration is a free data retrieval call binding the contract method 0xdabd396d.
//
// Solidity: function maxClockDuration() view returns(uint64)
func (_FaultDisputeGame *FaultDisputeGameCaller) MaxClockDuration(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _FaultDisputeGame.contract.Call(opts, &out, "maxClockDuration")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// MaxClockDuration is a free data retrieval call binding the contract method 0xdabd396d.
//
// Solidity: function maxClockDuration() view returns(uint64)
func (_FaultDisputeGame *FaultDisputeGameSession) MaxClockDuration() (uint64, error) {
	return _FaultDisputeGame.Contract.MaxClockDuration(&_FaultDisputeGame.CallOpts)
}

// MaxClockDuration is a free data retrieval call binding the contract method 0xdabd396d.
//
// Solidity: function maxClockDuration() view returns(uint64)
func (_FaultDisputeGame *FaultDisputeGameCallerSession) MaxClockDuration() (uint64, error) {
	return _FaultDisputeGame.Contract.MaxClockDuration(&_FaultDisputeGame.CallOpts)
}

// MaxGameDepth is a free data retrieval call binding the contract method 0xfa315aa9.
//
// Solidity: function maxGameDepth() view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameCaller) MaxGameDepth(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FaultDisputeGame.contract.Call(opts, &out, "maxGameDepth")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxGameDepth is a free data retrieval call binding the contract method 0xfa315aa9.
//
// Solidity: function maxGameDepth() view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameSession) MaxGameDepth() (*big.Int, error) {
	return _FaultDisputeGame.Contract.MaxGameDepth(&_FaultDisputeGame.CallOpts)
}

// MaxGameDepth is a free data retrieval call binding the contract method 0xfa315aa9.
//
// Solidity: function maxGameDepth() view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameCallerSession) MaxGameDepth() (*big.Int, error) {
	return _FaultDisputeGame.Contract.MaxGameDepth(&_FaultDisputeGame.CallOpts)
}

// RootClaim is a free data retrieval call binding the contract method 0xbcef3b55.
//
// Solidity: function rootClaim() pure returns(bytes32 rootClaim_)
func (_FaultDisputeGame *FaultDisputeGameCaller) RootClaim(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _FaultDisputeGame.contract.Call(opts, &out, "rootClaim")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// RootClaim is a free data retrieval call binding the contract method 0xbcef3b55.
//
// Solidity: function rootClaim() pure returns(bytes32 rootClaim_)
func (_FaultDisputeGame *FaultDisputeGameSession) RootClaim() ([32]byte, error) {
	return _FaultDisputeGame.Contract.RootClaim(&_FaultDisputeGame.CallOpts)
}

// RootClaim is a free data retrieval call binding the contract method 0xbcef3b55.
//
// Solidity: function rootClaim() pure returns(bytes32 rootClaim_)
func (_FaultDisputeGame *FaultDisputeGameCallerSession) RootClaim() ([32]byte, error) {
	return _FaultDisputeGame.Contract.RootClaim(&_FaultDisputeGame.CallOpts)
}

// SplitDepth is a free data retrieval call binding the contract method 0xec5e6308.
//
// Solidity: function splitDepth() view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameCaller) SplitDepth(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FaultDisputeGame.contract.Call(opts, &out, "splitDepth")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// SplitDepth is a free data retrieval call binding the contract method 0xec5e6308.
//
// Solidity: function splitDepth() view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameSession) SplitDepth() (*big.Int, error) {
	return _FaultDisputeGame.Contract.SplitDepth(&_FaultDisputeGame.CallOpts)
}

// SplitDepth is a free data retrieval call binding the contract method 0xec5e6308.
//
// Solidity: function splitDepth() view returns(uint256)
func (_FaultDisputeGame *FaultDisputeGameCallerSession) SplitDepth() (*big.Int, error) {
	return _FaultDisputeGame.Contract.SplitDepth(&_FaultDisputeGame.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_FaultDisputeGame *FaultDisputeGameCaller) Status(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _FaultDisputeGame.contract.Call(opts, &out, "status")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_FaultDisputeGame *FaultDisputeGameSession) Status() (uint8, error) {
	return _FaultDisputeGame.Contract.Status(&_FaultDisputeGame.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_FaultDisputeGame *FaultDisputeGameCallerSession) Status() (uint8, error) {
	return _FaultDisputeGame.Contract.Status(&_FaultDisputeGame.CallOpts)
}

// Weth is a free data retrieval call binding the contract method 0x3fc8cef3.
//
// Solidity: function weth() view returns(address)
func (_FaultDisputeGame *FaultDisputeGameCaller) Weth(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _FaultDisputeGame.contract.Call(opts, &out, "weth")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Weth is a free data retrieval call binding the contract method 0x3fc8cef3.
//
// Solidity: function weth() view returns(address)
func (_FaultDisputeGame *FaultDisputeGameSession) Weth() (common.Address, error) {
	return _FaultDisputeGame.Contract.Weth(&_FaultDisputeGame.CallOpts)
}

// Weth is a free data retrieval call binding the contract method 0x3fc8cef3.
//
// Solidity: function weth() view returns(address)
func (_FaultDisputeGame *FaultDisputeGameCallerSession) Weth() (common.Address, error) {
	return _FaultDisputeGame.Contract.Weth(&_FaultDisputeGame.CallOpts)
}

// Attack is a paid mutator transaction binding the contract method 0x472777c6.
//
// Solidity: function attack(bytes32 _disputed, uint256 _parentIndex, bytes32 _claim) payable returns()
func (_FaultDisputeGame *FaultDisputeGameTransactor) Attack(opts *bind.TransactOpts, _disputed [32]byte, _parentIndex *big.Int, _claim [32]byte) (*types.Transaction, error) {
	return _FaultDisputeGame.contract.Transact(opts, "attack", _disputed, _parentIndex, _claim)
}

// Attack is a paid mutator transaction binding the contract method 0x472777c6.
//
// Solidity: function attack(bytes32 _disputed, uint256 _parentIndex, bytes32 _claim) payable returns()
func (_FaultDisputeGame *FaultDisputeGameSession) Attack(_disputed [32]byte, _parentIndex *big.Int, _claim [32]byte) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.Attack(&_FaultDisputeGame.TransactOpts, _disputed, _parentIndex, _claim)
}

// Attack is a paid mutator transaction binding the contract method 0x472777c6.
//
// Solidity: function attack(bytes32 _disputed, uint256 _parentIndex, bytes32 _claim) payable returns()
func (_FaultDisputeGame *FaultDisputeGameTransactorSession) Attack(_disputed [32]byte, _parentIndex *big.Int, _claim [32]byte) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.Attack(&_FaultDisputeGame.TransactOpts, _disputed, _parentIndex, _claim)
}

// ClaimCredit is a paid mutator transaction binding the contract method 0x60e27464.
//
// Solidity: function claimCredit(address _recipient) returns()
func (_FaultDisputeGame *FaultDisputeGameTransactor) ClaimCredit(opts *bind.TransactOpts, _recipient common.Address) (*types.Transaction, error) {
	return _FaultDisputeGame.contract.Transact(opts, "claimCredit", _recipient)
}

// ClaimCredit is a paid mutator transaction binding the contract method 0x60e27464.
//
// Solidity: function claimCredit(address _recipient) returns()
func (_FaultDisputeGame *FaultDisputeGameSession) ClaimCredit(_recipient common.Address) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.ClaimCredit(&_FaultDisputeGame.TransactOpts, _recipient)
}

// ClaimCredit is a paid mutator transaction binding the contract method 0x60e27464.
//
// Solidity: function claimCredit(address _recipient) returns()
func (_FaultDisputeGame *FaultDisputeGameTransactorSession) ClaimCredit(_recipient common.Address) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.ClaimCredit(&_FaultDisputeGame.TransactOpts, _recipient)
}

// Defend is a paid mutator transaction binding the contract method 0x7b0f0adc.
//
// Solidity: function defend(bytes32 _disputed, uint256 _parentIndex, bytes32 _claim) payable returns()
func (_FaultDisputeGame *FaultDisputeGameTransactor) Defend(opts *bind.TransactOpts, _disputed [32]byte, _parentIndex *big.Int, _claim [32]byte) (*types.Transaction, error) {
	return _FaultDisputeGame.contract.Transact(opts, "defend", _disputed, _parentIndex, _claim)
}

// Defend is a paid mutator transaction binding the contract method 0x7b0f0adc.
//
// Solidity: function defend(bytes32 _disputed, uint256 _parentIndex, bytes32 _claim) payable returns()
func (_FaultDisputeGame *FaultDisputeGameSession) Defend(_disputed [32]byte, _parentIndex *big.Int, _claim [32]byte) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.Defend(&_FaultDisputeGame.TransactOpts, _disputed, _parentIndex, _claim)
}

// Defend is a paid mutator transaction binding the contract method 0x7b0f0adc.
//
// Solidity: function defend(bytes32 _disputed, uint256 _parentIndex, bytes32 _claim) payable returns()
func (_FaultDisputeGame *FaultDisputeGameTransactorSession) Defend(_disputed [32]byte, _parentIndex *big.Int, _claim [32]byte) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.Defend(&_FaultDisputeGame.TransactOpts, _disputed, _parentIndex, _claim)
}

// Resolve is a paid mutator transaction binding the contract method 0x2810e1d6.
//
// Solidity: function resolve() returns(uint8 status_)
func (_FaultDisputeGame *FaultDisputeGameTransactor) Resolve(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FaultDisputeGame.contract.Transact(opts, "resolve")
}

// Resolve is a paid mutator transaction binding the contract method 0x2810e1d6.
//
// Solidity: function resolve() returns(uint8 status_)
func (_FaultDisputeGame *FaultDisputeGameSession) Resolve() (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.Resolve(&_FaultDisputeGame.TransactOpts)
}

// Resolve is a paid mutator transaction binding the contract method 0x2810e1d6.
//
// Solidity: function resolve() returns(uint8 status_)
func (_FaultDisputeGame *FaultDisputeGameTransactorSession) Resolve() (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.Resolve(&_FaultDisputeGame.TransactOpts)
}

// ResolveClaim is a paid mutator transaction binding the contract method 0x03c2924d.
//
// Solidity: function resolveClaim(uint256 _claimIndex, uint256 _numToResolve) returns()
func (_FaultDisputeGame *FaultDisputeGameTransactor) ResolveClaim(opts *bind.TransactOpts, _claimIndex *big.Int, _numToResolve *big.Int) (*types.Transaction, error) {
	return _FaultDisputeGame.contract.Transact(opts, "resolveClaim", _claimIndex, _numToResolve)
}

// ResolveClaim is a paid mutator transaction binding the contract method 0x03c2924d.
//
// Solidity: function resolveClaim(uint256 _claimIndex, uint256 _numToResolve) returns()
func (_FaultDisputeGame *FaultDisputeGameSession) ResolveClaim(_claimIndex *big.Int, _numToResolve *big.Int) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.ResolveClaim(&_FaultDisputeGame.TransactOpts, _claimIndex, _numToResolve)
}

// ResolveClaim is a paid mutator transaction binding the contract method 0x03c2924d.
//
// Solidity: function resolveClaim(uint256 _claimIndex, uint256 _numToResolve) returns()
func (_FaultDisputeGame *FaultDisputeGameTransactorSession) ResolveClaim(_claimIndex *big.Int, _numToResolve *big.Int) (*types.Transaction, error) {
	return _FaultDisputeGame.Contract.ResolveClaim(&_FaultDisputeGame.TransactOpts, _claimIndex, _numToResolve)
}
