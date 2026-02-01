// Code generated - DO NOT EDIT.
// This file is a generated binding for WinningChallengerTracker.

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

const WinningChallengerTrackerABI = `[{"type":"function","name":"getWinningChallengers","inputs":[{"name":"game","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getWinningChallengersCount","inputs":[{"name":"game","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"isWinningChallenger","inputs":[{"name":"game","type":"address","internalType":"address"},{"name":"challenger","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"recordWinner","inputs":[{"name":"game","type":"address","internalType":"address"},{"name":"winner","type":"address","internalType":"address"},{"name":"gameCreator","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"WinnerRecorded","inputs":[{"name":"game","type":"address","indexed":true,"internalType":"address"},{"name":"winner","type":"address","indexed":true,"internalType":"address"}],"anonymous":false}]`

var WinningChallengerTrackerBin = "0x6080604052348015600e575f80fd5b506104b38061001c5f395ff3fe608060405234801561000f575f80fd5b506004361061004a575f3560e01c806342a94c301461004e578063487fc0cf14610063578063844956aa146100ab578063f4c03bb0146100cb575b5f80fd5b61006161005c3660046103bc565b610121565b005b6100986100713660046103fc565b73ffffffffffffffffffffffffffffffffffffffff165f9081526001602052604090205490565b6040519081526020015b60405180910390f35b6100be6100b93660046103fc565b610307565b6040516100a2919061041c565b6101116100d9366004610475565b73ffffffffffffffffffffffffffffffffffffffff9182165f9081526020818152604080832093909416825291909152205460ff1690565b60405190151581526020016100a2565b3373ffffffffffffffffffffffffffffffffffffffff8416146101ca576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152603160248201527f57696e6e696e674368616c6c656e676572547261636b65723a2063616c6c657260448201527f206d757374206265207468652067616d65000000000000000000000000000000606482015260840160405180910390fd5b8073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff160361020257505050565b73ffffffffffffffffffffffffffffffffffffffff8084165f908152602081815260408083209386168352929052205460ff161561023f57505050565b73ffffffffffffffffffffffffffffffffffffffff8084165f8181526020818152604080832094871680845294825280832080547fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0016600190811790915584845280835281842080549182018155845291832090910180547fffffffffffffffffffffffff00000000000000000000000000000000000000001685179055517f9cdf897a7e5878b92cba96a281f1b69a71712e064a8221f4ef96ea0df682ea0b9190a3505050565b73ffffffffffffffffffffffffffffffffffffffff81165f9081526001602090815260409182902080548351818402810184019094528084526060939283018282801561038857602002820191905f5260205f20905b815473ffffffffffffffffffffffffffffffffffffffff16815260019091019060200180831161035d575b50505050509050919050565b803573ffffffffffffffffffffffffffffffffffffffff811681146103b7575f80fd5b919050565b5f805f606084860312156103ce575f80fd5b6103d784610394565b92506103e560208501610394565b91506103f360408501610394565b90509250925092565b5f6020828403121561040c575f80fd5b61041582610394565b9392505050565b602080825282518282018190525f9190848201906040850190845b8181101561046957835173ffffffffffffffffffffffffffffffffffffffff1683529284019291840191600101610437565b50909695505050505050565b5f8060408385031215610486575f80fd5b61048f83610394565b915061049d60208401610394565b9050925092905056fea164736f6c6343000819000a"

type WinningChallengerTracker struct {
	WinningChallengerTrackerCaller
	WinningChallengerTrackerTransactor
	WinningChallengerTrackerFilterer
}

type WinningChallengerTrackerCaller struct {
	contract *bind.BoundContract
}

type WinningChallengerTrackerTransactor struct {
	contract *bind.BoundContract
}

type WinningChallengerTrackerFilterer struct {
	contract *bind.BoundContract
}

type WinningChallengerTrackerSession struct {
	Contract     *WinningChallengerTracker
	CallOpts     bind.CallOpts
	TransactOpts bind.TransactOpts
}

type WinningChallengerTrackerCallerSession struct {
	Contract *WinningChallengerTrackerCaller
	CallOpts bind.CallOpts
}

type WinningChallengerTrackerTransactorSession struct {
	Contract     *WinningChallengerTrackerTransactor
	TransactOpts bind.TransactOpts
}

type WinningChallengerTrackerRaw struct {
	Contract *WinningChallengerTracker
}

type WinningChallengerTrackerCallerRaw struct {
	Contract *WinningChallengerTrackerCaller
}

type WinningChallengerTrackerTransactorRaw struct {
	Contract *WinningChallengerTrackerTransactor
}

func NewWinningChallengerTracker(address common.Address, backend bind.ContractBackend) (*WinningChallengerTracker, error) {
	contract, err := bindWinningChallengerTracker(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &WinningChallengerTracker{
		WinningChallengerTrackerCaller:     WinningChallengerTrackerCaller{contract: contract},
		WinningChallengerTrackerTransactor: WinningChallengerTrackerTransactor{contract: contract},
		WinningChallengerTrackerFilterer:   WinningChallengerTrackerFilterer{contract: contract},
	}, nil
}

func NewWinningChallengerTrackerCaller(address common.Address, caller bind.ContractCaller) (*WinningChallengerTrackerCaller, error) {
	contract, err := bindWinningChallengerTracker(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &WinningChallengerTrackerCaller{contract: contract}, nil
}

func NewWinningChallengerTrackerTransactor(address common.Address, transactor bind.ContractTransactor) (*WinningChallengerTrackerTransactor, error) {
	contract, err := bindWinningChallengerTracker(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &WinningChallengerTrackerTransactor{contract: contract}, nil
}

func NewWinningChallengerTrackerFilterer(address common.Address, filterer bind.ContractFilterer) (*WinningChallengerTrackerFilterer, error) {
	contract, err := bindWinningChallengerTracker(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &WinningChallengerTrackerFilterer{contract: contract}, nil
}

func bindWinningChallengerTracker(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(WinningChallengerTrackerABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

func (_WinningChallengerTracker *WinningChallengerTrackerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _WinningChallengerTracker.Contract.WinningChallengerTrackerCaller.contract.Call(opts, result, method, params...)
}

func (_WinningChallengerTracker *WinningChallengerTrackerRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WinningChallengerTracker.Contract.WinningChallengerTrackerTransactor.contract.Transfer(opts)
}

func (_WinningChallengerTracker *WinningChallengerTrackerRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _WinningChallengerTracker.Contract.WinningChallengerTrackerTransactor.contract.Transact(opts, method, params...)
}

func (_WinningChallengerTracker *WinningChallengerTrackerCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _WinningChallengerTracker.Contract.contract.Call(opts, result, method, params...)
}

func (_WinningChallengerTracker *WinningChallengerTrackerTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WinningChallengerTracker.Contract.contract.Transfer(opts)
}

func (_WinningChallengerTracker *WinningChallengerTrackerTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _WinningChallengerTracker.Contract.contract.Transact(opts, method, params...)
}

func (_WinningChallengerTracker *WinningChallengerTrackerCaller) GetWinningChallengers(opts *bind.CallOpts, game common.Address) ([]common.Address, error) {
	var out []interface{}
	err := _WinningChallengerTracker.contract.Call(opts, &out, "getWinningChallengers", game)

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err
}

func (_WinningChallengerTracker *WinningChallengerTrackerSession) GetWinningChallengers(game common.Address) ([]common.Address, error) {
	return _WinningChallengerTracker.Contract.GetWinningChallengers(&_WinningChallengerTracker.CallOpts, game)
}

func (_WinningChallengerTracker *WinningChallengerTrackerCallerSession) GetWinningChallengers(game common.Address) ([]common.Address, error) {
	return _WinningChallengerTracker.Contract.GetWinningChallengers(&_WinningChallengerTracker.CallOpts, game)
}

func (_WinningChallengerTracker *WinningChallengerTrackerCaller) GetWinningChallengersCount(opts *bind.CallOpts, game common.Address) (*big.Int, error) {
	var out []interface{}
	err := _WinningChallengerTracker.contract.Call(opts, &out, "getWinningChallengersCount", game)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err
}

func (_WinningChallengerTracker *WinningChallengerTrackerSession) GetWinningChallengersCount(game common.Address) (*big.Int, error) {
	return _WinningChallengerTracker.Contract.GetWinningChallengersCount(&_WinningChallengerTracker.CallOpts, game)
}

func (_WinningChallengerTracker *WinningChallengerTrackerCallerSession) GetWinningChallengersCount(game common.Address) (*big.Int, error) {
	return _WinningChallengerTracker.Contract.GetWinningChallengersCount(&_WinningChallengerTracker.CallOpts, game)
}

func (_WinningChallengerTracker *WinningChallengerTrackerCaller) IsWinningChallenger(opts *bind.CallOpts, game common.Address, challenger common.Address) (bool, error) {
	var out []interface{}
	err := _WinningChallengerTracker.contract.Call(opts, &out, "isWinningChallenger", game, challenger)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err
}

func (_WinningChallengerTracker *WinningChallengerTrackerSession) IsWinningChallenger(game common.Address, challenger common.Address) (bool, error) {
	return _WinningChallengerTracker.Contract.IsWinningChallenger(&_WinningChallengerTracker.CallOpts, game, challenger)
}

func (_WinningChallengerTracker *WinningChallengerTrackerCallerSession) IsWinningChallenger(game common.Address, challenger common.Address) (bool, error) {
	return _WinningChallengerTracker.Contract.IsWinningChallenger(&_WinningChallengerTracker.CallOpts, game, challenger)
}

func (_WinningChallengerTracker *WinningChallengerTrackerTransactor) RecordWinner(opts *bind.TransactOpts, game common.Address, winner common.Address, gameCreator common.Address) (*types.Transaction, error) {
	return _WinningChallengerTracker.contract.Transact(opts, "recordWinner", game, winner, gameCreator)
}

func (_WinningChallengerTracker *WinningChallengerTrackerSession) RecordWinner(game common.Address, winner common.Address, gameCreator common.Address) (*types.Transaction, error) {
	return _WinningChallengerTracker.Contract.RecordWinner(&_WinningChallengerTracker.TransactOpts, game, winner, gameCreator)
}

func (_WinningChallengerTracker *WinningChallengerTrackerTransactorSession) RecordWinner(game common.Address, winner common.Address, gameCreator common.Address) (*types.Transaction, error) {
	return _WinningChallengerTracker.Contract.RecordWinner(&_WinningChallengerTracker.TransactOpts, game, winner, gameCreator)
}

type WinningChallengerTrackerWinnerRecordedIterator struct {
	Event    *WinningChallengerTrackerWinnerRecorded
	contract *bind.BoundContract
	event    string
	logs     chan types.Log
	sub      ethereum.Subscription
	done     bool
	fail     error
}

func (it *WinningChallengerTrackerWinnerRecordedIterator) Next() bool {
	if it.fail != nil {
		return false
	}
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WinningChallengerTrackerWinnerRecorded)
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
	select {
	case log := <-it.logs:
		it.Event = new(WinningChallengerTrackerWinnerRecorded)
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

func (it *WinningChallengerTrackerWinnerRecordedIterator) Error() error {
	return it.fail
}

func (it *WinningChallengerTrackerWinnerRecordedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

type WinningChallengerTrackerWinnerRecorded struct {
	Game   common.Address
	Winner common.Address
	Raw    types.Log
}

func (_WinningChallengerTracker *WinningChallengerTrackerFilterer) FilterWinnerRecorded(opts *bind.FilterOpts, game []common.Address, winner []common.Address) (*WinningChallengerTrackerWinnerRecordedIterator, error) {
	var gameRule []interface{}
	for _, gameItem := range game {
		gameRule = append(gameRule, gameItem)
	}
	var winnerRule []interface{}
	for _, winnerItem := range winner {
		winnerRule = append(winnerRule, winnerItem)
	}

	logs, sub, err := _WinningChallengerTracker.contract.FilterLogs(opts, "WinnerRecorded", gameRule, winnerRule)
	if err != nil {
		return nil, err
	}
	return &WinningChallengerTrackerWinnerRecordedIterator{contract: _WinningChallengerTracker.contract, event: "WinnerRecorded", logs: logs, sub: sub}, nil
}

func (_WinningChallengerTracker *WinningChallengerTrackerFilterer) WatchWinnerRecorded(opts *bind.WatchOpts, sink chan<- *WinningChallengerTrackerWinnerRecorded, game []common.Address, winner []common.Address) (event.Subscription, error) {
	var gameRule []interface{}
	for _, gameItem := range game {
		gameRule = append(gameRule, gameItem)
	}
	var winnerRule []interface{}
	for _, winnerItem := range winner {
		winnerRule = append(winnerRule, winnerItem)
	}

	logs, sub, err := _WinningChallengerTracker.contract.WatchLogs(opts, "WinnerRecorded", gameRule, winnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				event := new(WinningChallengerTrackerWinnerRecorded)
				if err := _WinningChallengerTracker.contract.UnpackLog(event, "WinnerRecorded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
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

func (_WinningChallengerTracker *WinningChallengerTrackerFilterer) ParseWinnerRecorded(log types.Log) (*WinningChallengerTrackerWinnerRecorded, error) {
	event := new(WinningChallengerTrackerWinnerRecorded)
	if err := _WinningChallengerTracker.contract.UnpackLog(event, "WinnerRecorded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

func DeployWinningChallengerTracker(auth *bind.TransactOpts, backend bind.ContractBackend) (common.Address, *types.Transaction, *WinningChallengerTracker, error) {
	parsed, err := abi.JSON(strings.NewReader(WinningChallengerTrackerABI))
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	address, tx, contract, err := bind.DeployContract(auth, parsed, common.FromHex(WinningChallengerTrackerBin), backend)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &WinningChallengerTracker{
		WinningChallengerTrackerCaller:     WinningChallengerTrackerCaller{contract: contract},
		WinningChallengerTrackerTransactor: WinningChallengerTrackerTransactor{contract: contract},
		WinningChallengerTrackerFilterer:   WinningChallengerTrackerFilterer{contract: contract},
	}, nil
}
