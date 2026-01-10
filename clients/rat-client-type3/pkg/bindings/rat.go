// Code generated - DO NOT EDIT.
// This file is a manually created binding for RAT contract

package bindings

import (
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
)

// RATABI is the input ABI used to generate the binding from.
const RATABI = `[
	{
		"type": "function",
		"name": "submitEvidence",
		"inputs": [
			{"name": "systemConfig", "type": "address"},
			{"name": "batchIndex", "type": "uint32"},
			{"name": "evidenceData", "type": "bytes"}
		],
		"outputs": [],
		"stateMutability": "nonpayable"
	},
	{
		"type": "function",
		"name": "registerValidator",
		"inputs": [
			{"name": "systemConfig", "type": "address"}
		],
		"outputs": [],
		"stateMutability": "payable"
	},
	{
		"type": "function",
		"name": "attentionTests",
		"inputs": [
			{"name": "", "type": "bytes32"}
		],
		"outputs": [
			{"name": "validatorAddress", "type": "address"},
			{"name": "systemConfig", "type": "address"},
			{"name": "batchIndex", "type": "uint32"},
			{"name": "gameAddress", "type": "address"},
			{"name": "batchHash", "type": "bytes32"},
			{"name": "bondAmount", "type": "uint256"},
			{"name": "createdAt", "type": "uint256"},
			{"name": "deadline", "type": "uint256"},
			{"name": "status", "type": "uint8"}
		],
		"stateMutability": "view"
	},
	{
		"type": "event",
		"name": "AttentionTestTriggered",
		"inputs": [
			{"name": "testId", "type": "bytes32", "indexed": true},
			{"name": "validator", "type": "address", "indexed": true},
			{"name": "systemConfig", "type": "address", "indexed": true},
			{"name": "gameAddress", "type": "address", "indexed": false},
			{"name": "batchIndex", "type": "uint32", "indexed": false},
			{"name": "deadline", "type": "uint256", "indexed": false}
		]
	},
	{
		"type": "event",
		"name": "EvidenceSubmitted",
		"inputs": [
			{"name": "testId", "type": "bytes32", "indexed": true},
			{"name": "validator", "type": "address", "indexed": true},
			{"name": "systemConfig", "type": "address", "indexed": true},
			{"name": "batchIndex", "type": "uint32", "indexed": false}
		]
	}
]`

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

// NewRAT creates a new instance of RAT, bound to a specific deployed contract.
func NewRAT(address common.Address, backend bind.ContractBackend) (*RAT, error) {
	contract, err := bindRAT(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &RAT{RATCaller: RATCaller{contract: contract}, RATTransactor: RATTransactor{contract: contract}, RATFilterer: RATFilterer{contract: contract}}, nil
}

// bindRAT binds a generic wrapper to an already deployed contract.
func bindRAT(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(RATABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// SubmitEvidence is a paid mutator transaction binding the contract method 0x...
func (_RAT *RATTransactor) SubmitEvidence(opts *bind.TransactOpts, systemConfig common.Address, batchIndex uint32, evidenceData []byte) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "submitEvidence", systemConfig, batchIndex, evidenceData)
}

// SubmitEvidence is a paid mutator transaction binding the contract method.
func (_RAT *RAT) SubmitEvidence(opts *bind.TransactOpts, systemConfig common.Address, batchIndex uint32, evidenceData []byte) (*types.Transaction, error) {
	return _RAT.RATTransactor.SubmitEvidence(opts, systemConfig, batchIndex, evidenceData)
}

// AttentionTestResult represents the return values from attentionTests getter
type AttentionTestResult struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	GameAddress      common.Address
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
func (_RAT *RATCaller) AttentionTests(opts *bind.CallOpts, testId [32]byte) (*AttentionTestResult, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "attentionTests", testId)
	if err != nil {
		return nil, err
	}

	result := new(AttentionTestResult)
	result.ValidatorAddress = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	result.SystemConfig = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	result.BatchIndex = *abi.ConvertType(out[2], new(uint32)).(*uint32)
	result.GameAddress = *abi.ConvertType(out[3], new(common.Address)).(*common.Address)
	result.BatchHash = *abi.ConvertType(out[4], new([32]byte)).(*[32]byte)
	result.BondAmount = *abi.ConvertType(out[5], new(*big.Int)).(**big.Int)
	result.CreatedAt = *abi.ConvertType(out[6], new(*big.Int)).(**big.Int)
	result.Deadline = *abi.ConvertType(out[7], new(*big.Int)).(**big.Int)
	result.Status = *abi.ConvertType(out[8], new(uint8)).(*uint8)

	return result, nil
}

// AttentionTests is a free data retrieval call binding the contract method.
func (_RAT *RAT) AttentionTests(opts *bind.CallOpts, testId [32]byte) (*AttentionTestResult, error) {
	return _RAT.RATCaller.AttentionTests(opts, testId)
}

// RATAttentionTestTriggeredIterator is returned from FilterAttentionTestTriggered and is used to iterate over the raw logs and unpacked data for AttentionTestTriggered events
type RATAttentionTestTriggeredIterator struct {
	Event *RATAttentionTestTriggered // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// RATAttentionTestTriggered represents a AttentionTestTriggered event
type RATAttentionTestTriggered struct {
	TestId       [32]byte
	Validator    common.Address
	SystemConfig common.Address
	GameAddress  common.Address
	BatchIndex   uint32
	Deadline     *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterAttentionTestTriggered is a free log retrieval operation binding the contract event
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
