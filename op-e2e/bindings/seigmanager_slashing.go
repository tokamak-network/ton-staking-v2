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

// SeigManagerSlashingMetaData contains all meta data concerning the SeigManagerSlashing contract.
var SeigManagerSlashingMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"BURNT_AMOUNT_MAINNET\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"CHALLENGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"INITIAL_TOTAL_SUPPLY_MAINNET\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MANAGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MAX_VALID_COMMISSION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MINTER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MIN_VALID_COMMISSION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"OPERATOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"PAUSE_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"RAY\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"REGISTRANT_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SEIG_START_MAINNET\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"accRelativeSeig\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addChallenger\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addMinter\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addOperator\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"adjustCommissionDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"aliveImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"bridgedTONInfo\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"currentBridgedTON\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"effectiveBridgedTON\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initialDebt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"startBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"lastUpdateTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"isEligible\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"bridgedTONRewardPerUint\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"burntAmountAtDAO\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"currentPeriodId\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"dao\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"daoDistributionRatio\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"daoSeigRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"delayedCommissionBlock\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"delayedCommissionRate\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"delayedCommissionRateNegative\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"factory\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"halfSaturationPoint\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialTotalSupply\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isChallenger\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isMinter\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isOperator\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isOwner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1BridgeRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l2RewardPerUint\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"lastSnapshotId\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2Manager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2PauseBlocks\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2RewardInfo\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"layer2Tvl\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initialDebt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"startBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2StartBlock\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2UnpauseBlocks\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxChallengers\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxFraudProofCost\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minStakingRatio\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minimumAmount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"onSlash\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"pauseProxy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"periods\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"startBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"endBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalSeigniorage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalDistributed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validatorPoolAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"finalized\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"powerTONSeigRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxyImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"relativeSeigRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"removeAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeChallenger\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeMinter\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeOperator\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceChallenger\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceMinter\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOperator\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"seigStartBlock\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"selectorImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"sequencerVault\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"stakedSeigFactor\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalEffectiveBridgedTON\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalLayer2TVL\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferAdmin\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"v3Migrated\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"v3MigrationBlock\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorDistributionRatio\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorReward\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Slashed\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false}]",
}

// SeigManagerSlashingABI is the input ABI used to generate the binding from.
// Deprecated: Use SeigManagerSlashingMetaData.ABI instead.
var SeigManagerSlashingABI = SeigManagerSlashingMetaData.ABI

// SeigManagerSlashing is an auto generated Go binding around an Ethereum contract.
type SeigManagerSlashing struct {
	SeigManagerSlashingCaller     // Read-only binding to the contract
	SeigManagerSlashingTransactor // Write-only binding to the contract
	SeigManagerSlashingFilterer   // Log filterer for contract events
}

// SeigManagerSlashingCaller is an auto generated read-only Go binding around an Ethereum contract.
type SeigManagerSlashingCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SeigManagerSlashingTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SeigManagerSlashingTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SeigManagerSlashingFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SeigManagerSlashingFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SeigManagerSlashingSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SeigManagerSlashingSession struct {
	Contract     *SeigManagerSlashing // Generic contract binding to set the session for
	CallOpts     bind.CallOpts        // Call options to use throughout this session
	TransactOpts bind.TransactOpts    // Transaction auth options to use throughout this session
}

// SeigManagerSlashingCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SeigManagerSlashingCallerSession struct {
	Contract *SeigManagerSlashingCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts              // Call options to use throughout this session
}

// SeigManagerSlashingTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SeigManagerSlashingTransactorSession struct {
	Contract     *SeigManagerSlashingTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts              // Transaction auth options to use throughout this session
}

// SeigManagerSlashingRaw is an auto generated low-level Go binding around an Ethereum contract.
type SeigManagerSlashingRaw struct {
	Contract *SeigManagerSlashing // Generic contract binding to access the raw methods on
}

// SeigManagerSlashingCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SeigManagerSlashingCallerRaw struct {
	Contract *SeigManagerSlashingCaller // Generic read-only contract binding to access the raw methods on
}

// SeigManagerSlashingTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SeigManagerSlashingTransactorRaw struct {
	Contract *SeigManagerSlashingTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSeigManagerSlashing creates a new instance of SeigManagerSlashing, bound to a specific deployed contract.
func NewSeigManagerSlashing(address common.Address, backend bind.ContractBackend) (*SeigManagerSlashing, error) {
	contract, err := bindSeigManagerSlashing(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SeigManagerSlashing{SeigManagerSlashingCaller: SeigManagerSlashingCaller{contract: contract}, SeigManagerSlashingTransactor: SeigManagerSlashingTransactor{contract: contract}, SeigManagerSlashingFilterer: SeigManagerSlashingFilterer{contract: contract}}, nil
}

// NewSeigManagerSlashingCaller creates a new read-only instance of SeigManagerSlashing, bound to a specific deployed contract.
func NewSeigManagerSlashingCaller(address common.Address, caller bind.ContractCaller) (*SeigManagerSlashingCaller, error) {
	contract, err := bindSeigManagerSlashing(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SeigManagerSlashingCaller{contract: contract}, nil
}

// NewSeigManagerSlashingTransactor creates a new write-only instance of SeigManagerSlashing, bound to a specific deployed contract.
func NewSeigManagerSlashingTransactor(address common.Address, transactor bind.ContractTransactor) (*SeigManagerSlashingTransactor, error) {
	contract, err := bindSeigManagerSlashing(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SeigManagerSlashingTransactor{contract: contract}, nil
}

// NewSeigManagerSlashingFilterer creates a new log filterer instance of SeigManagerSlashing, bound to a specific deployed contract.
func NewSeigManagerSlashingFilterer(address common.Address, filterer bind.ContractFilterer) (*SeigManagerSlashingFilterer, error) {
	contract, err := bindSeigManagerSlashing(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SeigManagerSlashingFilterer{contract: contract}, nil
}

// bindSeigManagerSlashing binds a generic wrapper to an already deployed contract.
func bindSeigManagerSlashing(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SeigManagerSlashingMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SeigManagerSlashing *SeigManagerSlashingRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SeigManagerSlashing.Contract.SeigManagerSlashingCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SeigManagerSlashing *SeigManagerSlashingRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.SeigManagerSlashingTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SeigManagerSlashing *SeigManagerSlashingRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.SeigManagerSlashingTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SeigManagerSlashing *SeigManagerSlashingCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SeigManagerSlashing.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SeigManagerSlashing *SeigManagerSlashingTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SeigManagerSlashing *SeigManagerSlashingTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.contract.Transact(opts, method, params...)
}

// BURNTAMOUNTMAINNET is a free data retrieval call binding the contract method 0x4631179e.
//
// Solidity: function BURNT_AMOUNT_MAINNET() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) BURNTAMOUNTMAINNET(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "BURNT_AMOUNT_MAINNET")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BURNTAMOUNTMAINNET is a free data retrieval call binding the contract method 0x4631179e.
//
// Solidity: function BURNT_AMOUNT_MAINNET() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) BURNTAMOUNTMAINNET() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.BURNTAMOUNTMAINNET(&_SeigManagerSlashing.CallOpts)
}

// BURNTAMOUNTMAINNET is a free data retrieval call binding the contract method 0x4631179e.
//
// Solidity: function BURNT_AMOUNT_MAINNET() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) BURNTAMOUNTMAINNET() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.BURNTAMOUNTMAINNET(&_SeigManagerSlashing.CallOpts)
}

// CHALLENGERROLE is a free data retrieval call binding the contract method 0x530adbb4.
//
// Solidity: function CHALLENGER_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) CHALLENGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "CHALLENGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// CHALLENGERROLE is a free data retrieval call binding the contract method 0x530adbb4.
//
// Solidity: function CHALLENGER_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingSession) CHALLENGERROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.CHALLENGERROLE(&_SeigManagerSlashing.CallOpts)
}

// CHALLENGERROLE is a free data retrieval call binding the contract method 0x530adbb4.
//
// Solidity: function CHALLENGER_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) CHALLENGERROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.CHALLENGERROLE(&_SeigManagerSlashing.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.DEFAULTADMINROLE(&_SeigManagerSlashing.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.DEFAULTADMINROLE(&_SeigManagerSlashing.CallOpts)
}

// INITIALTOTALSUPPLYMAINNET is a free data retrieval call binding the contract method 0xacd848fa.
//
// Solidity: function INITIAL_TOTAL_SUPPLY_MAINNET() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) INITIALTOTALSUPPLYMAINNET(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "INITIAL_TOTAL_SUPPLY_MAINNET")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// INITIALTOTALSUPPLYMAINNET is a free data retrieval call binding the contract method 0xacd848fa.
//
// Solidity: function INITIAL_TOTAL_SUPPLY_MAINNET() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) INITIALTOTALSUPPLYMAINNET() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.INITIALTOTALSUPPLYMAINNET(&_SeigManagerSlashing.CallOpts)
}

// INITIALTOTALSUPPLYMAINNET is a free data retrieval call binding the contract method 0xacd848fa.
//
// Solidity: function INITIAL_TOTAL_SUPPLY_MAINNET() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) INITIALTOTALSUPPLYMAINNET() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.INITIALTOTALSUPPLYMAINNET(&_SeigManagerSlashing.CallOpts)
}

// MANAGERROLE is a free data retrieval call binding the contract method 0xec87621c.
//
// Solidity: function MANAGER_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) MANAGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "MANAGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// MANAGERROLE is a free data retrieval call binding the contract method 0xec87621c.
//
// Solidity: function MANAGER_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingSession) MANAGERROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.MANAGERROLE(&_SeigManagerSlashing.CallOpts)
}

// MANAGERROLE is a free data retrieval call binding the contract method 0xec87621c.
//
// Solidity: function MANAGER_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) MANAGERROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.MANAGERROLE(&_SeigManagerSlashing.CallOpts)
}

// MAXVALIDCOMMISSION is a free data retrieval call binding the contract method 0x4123196f.
//
// Solidity: function MAX_VALID_COMMISSION() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) MAXVALIDCOMMISSION(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "MAX_VALID_COMMISSION")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXVALIDCOMMISSION is a free data retrieval call binding the contract method 0x4123196f.
//
// Solidity: function MAX_VALID_COMMISSION() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) MAXVALIDCOMMISSION() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MAXVALIDCOMMISSION(&_SeigManagerSlashing.CallOpts)
}

// MAXVALIDCOMMISSION is a free data retrieval call binding the contract method 0x4123196f.
//
// Solidity: function MAX_VALID_COMMISSION() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) MAXVALIDCOMMISSION() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MAXVALIDCOMMISSION(&_SeigManagerSlashing.CallOpts)
}

// MINTERROLE is a free data retrieval call binding the contract method 0xd5391393.
//
// Solidity: function MINTER_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) MINTERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "MINTER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// MINTERROLE is a free data retrieval call binding the contract method 0xd5391393.
//
// Solidity: function MINTER_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingSession) MINTERROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.MINTERROLE(&_SeigManagerSlashing.CallOpts)
}

// MINTERROLE is a free data retrieval call binding the contract method 0xd5391393.
//
// Solidity: function MINTER_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) MINTERROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.MINTERROLE(&_SeigManagerSlashing.CallOpts)
}

// MINVALIDCOMMISSION is a free data retrieval call binding the contract method 0xa7dcc850.
//
// Solidity: function MIN_VALID_COMMISSION() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) MINVALIDCOMMISSION(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "MIN_VALID_COMMISSION")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MINVALIDCOMMISSION is a free data retrieval call binding the contract method 0xa7dcc850.
//
// Solidity: function MIN_VALID_COMMISSION() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) MINVALIDCOMMISSION() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MINVALIDCOMMISSION(&_SeigManagerSlashing.CallOpts)
}

// MINVALIDCOMMISSION is a free data retrieval call binding the contract method 0xa7dcc850.
//
// Solidity: function MIN_VALID_COMMISSION() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) MINVALIDCOMMISSION() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MINVALIDCOMMISSION(&_SeigManagerSlashing.CallOpts)
}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) OPERATORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "OPERATOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingSession) OPERATORROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.OPERATORROLE(&_SeigManagerSlashing.CallOpts)
}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) OPERATORROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.OPERATORROLE(&_SeigManagerSlashing.CallOpts)
}

// PAUSEROLE is a free data retrieval call binding the contract method 0x389ed267.
//
// Solidity: function PAUSE_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) PAUSEROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "PAUSE_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// PAUSEROLE is a free data retrieval call binding the contract method 0x389ed267.
//
// Solidity: function PAUSE_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingSession) PAUSEROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.PAUSEROLE(&_SeigManagerSlashing.CallOpts)
}

// PAUSEROLE is a free data retrieval call binding the contract method 0x389ed267.
//
// Solidity: function PAUSE_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) PAUSEROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.PAUSEROLE(&_SeigManagerSlashing.CallOpts)
}

// RAY is a free data retrieval call binding the contract method 0x552033c4.
//
// Solidity: function RAY() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) RAY(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "RAY")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// RAY is a free data retrieval call binding the contract method 0x552033c4.
//
// Solidity: function RAY() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) RAY() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.RAY(&_SeigManagerSlashing.CallOpts)
}

// RAY is a free data retrieval call binding the contract method 0x552033c4.
//
// Solidity: function RAY() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) RAY() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.RAY(&_SeigManagerSlashing.CallOpts)
}

// REGISTRANTROLE is a free data retrieval call binding the contract method 0x6f5b142b.
//
// Solidity: function REGISTRANT_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) REGISTRANTROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "REGISTRANT_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// REGISTRANTROLE is a free data retrieval call binding the contract method 0x6f5b142b.
//
// Solidity: function REGISTRANT_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingSession) REGISTRANTROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.REGISTRANTROLE(&_SeigManagerSlashing.CallOpts)
}

// REGISTRANTROLE is a free data retrieval call binding the contract method 0x6f5b142b.
//
// Solidity: function REGISTRANT_ROLE() view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) REGISTRANTROLE() ([32]byte, error) {
	return _SeigManagerSlashing.Contract.REGISTRANTROLE(&_SeigManagerSlashing.CallOpts)
}

// SEIGSTARTMAINNET is a free data retrieval call binding the contract method 0xd8c47966.
//
// Solidity: function SEIG_START_MAINNET() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) SEIGSTARTMAINNET(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "SEIG_START_MAINNET")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// SEIGSTARTMAINNET is a free data retrieval call binding the contract method 0xd8c47966.
//
// Solidity: function SEIG_START_MAINNET() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) SEIGSTARTMAINNET() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.SEIGSTARTMAINNET(&_SeigManagerSlashing.CallOpts)
}

// SEIGSTARTMAINNET is a free data retrieval call binding the contract method 0xd8c47966.
//
// Solidity: function SEIG_START_MAINNET() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) SEIGSTARTMAINNET() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.SEIGSTARTMAINNET(&_SeigManagerSlashing.CallOpts)
}

// AccRelativeSeig is a free data retrieval call binding the contract method 0xf8229348.
//
// Solidity: function accRelativeSeig() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) AccRelativeSeig(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "accRelativeSeig")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AccRelativeSeig is a free data retrieval call binding the contract method 0xf8229348.
//
// Solidity: function accRelativeSeig() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) AccRelativeSeig() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.AccRelativeSeig(&_SeigManagerSlashing.CallOpts)
}

// AccRelativeSeig is a free data retrieval call binding the contract method 0xf8229348.
//
// Solidity: function accRelativeSeig() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) AccRelativeSeig() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.AccRelativeSeig(&_SeigManagerSlashing.CallOpts)
}

// AdjustCommissionDelay is a free data retrieval call binding the contract method 0xdf7fbef0.
//
// Solidity: function adjustCommissionDelay() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) AdjustCommissionDelay(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "adjustCommissionDelay")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AdjustCommissionDelay is a free data retrieval call binding the contract method 0xdf7fbef0.
//
// Solidity: function adjustCommissionDelay() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) AdjustCommissionDelay() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.AdjustCommissionDelay(&_SeigManagerSlashing.CallOpts)
}

// AdjustCommissionDelay is a free data retrieval call binding the contract method 0xdf7fbef0.
//
// Solidity: function adjustCommissionDelay() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) AdjustCommissionDelay() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.AdjustCommissionDelay(&_SeigManagerSlashing.CallOpts)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) AliveImplementation(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "aliveImplementation", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.AliveImplementation(&_SeigManagerSlashing.CallOpts, arg0)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.AliveImplementation(&_SeigManagerSlashing.CallOpts, arg0)
}

// BridgedTONInfo is a free data retrieval call binding the contract method 0xaf67939b.
//
// Solidity: function bridgedTONInfo(address ) view returns(uint256 currentBridgedTON, uint256 effectiveBridgedTON, uint256 initialDebt, uint256 startBlock, uint256 lastUpdateTime, bool isEligible)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) BridgedTONInfo(opts *bind.CallOpts, arg0 common.Address) (struct {
	CurrentBridgedTON   *big.Int
	EffectiveBridgedTON *big.Int
	InitialDebt         *big.Int
	StartBlock          *big.Int
	LastUpdateTime      *big.Int
	IsEligible          bool
}, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "bridgedTONInfo", arg0)

	outstruct := new(struct {
		CurrentBridgedTON   *big.Int
		EffectiveBridgedTON *big.Int
		InitialDebt         *big.Int
		StartBlock          *big.Int
		LastUpdateTime      *big.Int
		IsEligible          bool
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.CurrentBridgedTON = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.EffectiveBridgedTON = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.InitialDebt = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.StartBlock = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.LastUpdateTime = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)
	outstruct.IsEligible = *abi.ConvertType(out[5], new(bool)).(*bool)

	return *outstruct, err

}

// BridgedTONInfo is a free data retrieval call binding the contract method 0xaf67939b.
//
// Solidity: function bridgedTONInfo(address ) view returns(uint256 currentBridgedTON, uint256 effectiveBridgedTON, uint256 initialDebt, uint256 startBlock, uint256 lastUpdateTime, bool isEligible)
func (_SeigManagerSlashing *SeigManagerSlashingSession) BridgedTONInfo(arg0 common.Address) (struct {
	CurrentBridgedTON   *big.Int
	EffectiveBridgedTON *big.Int
	InitialDebt         *big.Int
	StartBlock          *big.Int
	LastUpdateTime      *big.Int
	IsEligible          bool
}, error) {
	return _SeigManagerSlashing.Contract.BridgedTONInfo(&_SeigManagerSlashing.CallOpts, arg0)
}

// BridgedTONInfo is a free data retrieval call binding the contract method 0xaf67939b.
//
// Solidity: function bridgedTONInfo(address ) view returns(uint256 currentBridgedTON, uint256 effectiveBridgedTON, uint256 initialDebt, uint256 startBlock, uint256 lastUpdateTime, bool isEligible)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) BridgedTONInfo(arg0 common.Address) (struct {
	CurrentBridgedTON   *big.Int
	EffectiveBridgedTON *big.Int
	InitialDebt         *big.Int
	StartBlock          *big.Int
	LastUpdateTime      *big.Int
	IsEligible          bool
}, error) {
	return _SeigManagerSlashing.Contract.BridgedTONInfo(&_SeigManagerSlashing.CallOpts, arg0)
}

// BridgedTONRewardPerUint is a free data retrieval call binding the contract method 0x40560ecc.
//
// Solidity: function bridgedTONRewardPerUint() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) BridgedTONRewardPerUint(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "bridgedTONRewardPerUint")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BridgedTONRewardPerUint is a free data retrieval call binding the contract method 0x40560ecc.
//
// Solidity: function bridgedTONRewardPerUint() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) BridgedTONRewardPerUint() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.BridgedTONRewardPerUint(&_SeigManagerSlashing.CallOpts)
}

// BridgedTONRewardPerUint is a free data retrieval call binding the contract method 0x40560ecc.
//
// Solidity: function bridgedTONRewardPerUint() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) BridgedTONRewardPerUint() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.BridgedTONRewardPerUint(&_SeigManagerSlashing.CallOpts)
}

// BurntAmountAtDAO is a free data retrieval call binding the contract method 0xbf7f4733.
//
// Solidity: function burntAmountAtDAO() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) BurntAmountAtDAO(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "burntAmountAtDAO")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BurntAmountAtDAO is a free data retrieval call binding the contract method 0xbf7f4733.
//
// Solidity: function burntAmountAtDAO() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) BurntAmountAtDAO() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.BurntAmountAtDAO(&_SeigManagerSlashing.CallOpts)
}

// BurntAmountAtDAO is a free data retrieval call binding the contract method 0xbf7f4733.
//
// Solidity: function burntAmountAtDAO() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) BurntAmountAtDAO() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.BurntAmountAtDAO(&_SeigManagerSlashing.CallOpts)
}

// CurrentPeriodId is a free data retrieval call binding the contract method 0x988e6595.
//
// Solidity: function currentPeriodId() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) CurrentPeriodId(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "currentPeriodId")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// CurrentPeriodId is a free data retrieval call binding the contract method 0x988e6595.
//
// Solidity: function currentPeriodId() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) CurrentPeriodId() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.CurrentPeriodId(&_SeigManagerSlashing.CallOpts)
}

// CurrentPeriodId is a free data retrieval call binding the contract method 0x988e6595.
//
// Solidity: function currentPeriodId() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) CurrentPeriodId() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.CurrentPeriodId(&_SeigManagerSlashing.CallOpts)
}

// Dao is a free data retrieval call binding the contract method 0x4162169f.
//
// Solidity: function dao() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) Dao(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "dao")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Dao is a free data retrieval call binding the contract method 0x4162169f.
//
// Solidity: function dao() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingSession) Dao() (common.Address, error) {
	return _SeigManagerSlashing.Contract.Dao(&_SeigManagerSlashing.CallOpts)
}

// Dao is a free data retrieval call binding the contract method 0x4162169f.
//
// Solidity: function dao() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) Dao() (common.Address, error) {
	return _SeigManagerSlashing.Contract.Dao(&_SeigManagerSlashing.CallOpts)
}

// DaoDistributionRatio is a free data retrieval call binding the contract method 0xe4805348.
//
// Solidity: function daoDistributionRatio() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) DaoDistributionRatio(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "daoDistributionRatio")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// DaoDistributionRatio is a free data retrieval call binding the contract method 0xe4805348.
//
// Solidity: function daoDistributionRatio() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) DaoDistributionRatio() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.DaoDistributionRatio(&_SeigManagerSlashing.CallOpts)
}

// DaoDistributionRatio is a free data retrieval call binding the contract method 0xe4805348.
//
// Solidity: function daoDistributionRatio() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) DaoDistributionRatio() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.DaoDistributionRatio(&_SeigManagerSlashing.CallOpts)
}

// DaoSeigRate is a free data retrieval call binding the contract method 0x5998a8d7.
//
// Solidity: function daoSeigRate() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) DaoSeigRate(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "daoSeigRate")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// DaoSeigRate is a free data retrieval call binding the contract method 0x5998a8d7.
//
// Solidity: function daoSeigRate() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) DaoSeigRate() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.DaoSeigRate(&_SeigManagerSlashing.CallOpts)
}

// DaoSeigRate is a free data retrieval call binding the contract method 0x5998a8d7.
//
// Solidity: function daoSeigRate() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) DaoSeigRate() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.DaoSeigRate(&_SeigManagerSlashing.CallOpts)
}

// DelayedCommissionBlock is a free data retrieval call binding the contract method 0xcbfebe62.
//
// Solidity: function delayedCommissionBlock(address ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) DelayedCommissionBlock(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "delayedCommissionBlock", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// DelayedCommissionBlock is a free data retrieval call binding the contract method 0xcbfebe62.
//
// Solidity: function delayedCommissionBlock(address ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) DelayedCommissionBlock(arg0 common.Address) (*big.Int, error) {
	return _SeigManagerSlashing.Contract.DelayedCommissionBlock(&_SeigManagerSlashing.CallOpts, arg0)
}

// DelayedCommissionBlock is a free data retrieval call binding the contract method 0xcbfebe62.
//
// Solidity: function delayedCommissionBlock(address ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) DelayedCommissionBlock(arg0 common.Address) (*big.Int, error) {
	return _SeigManagerSlashing.Contract.DelayedCommissionBlock(&_SeigManagerSlashing.CallOpts, arg0)
}

// DelayedCommissionRate is a free data retrieval call binding the contract method 0xe2fe8fd1.
//
// Solidity: function delayedCommissionRate(address ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) DelayedCommissionRate(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "delayedCommissionRate", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// DelayedCommissionRate is a free data retrieval call binding the contract method 0xe2fe8fd1.
//
// Solidity: function delayedCommissionRate(address ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) DelayedCommissionRate(arg0 common.Address) (*big.Int, error) {
	return _SeigManagerSlashing.Contract.DelayedCommissionRate(&_SeigManagerSlashing.CallOpts, arg0)
}

// DelayedCommissionRate is a free data retrieval call binding the contract method 0xe2fe8fd1.
//
// Solidity: function delayedCommissionRate(address ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) DelayedCommissionRate(arg0 common.Address) (*big.Int, error) {
	return _SeigManagerSlashing.Contract.DelayedCommissionRate(&_SeigManagerSlashing.CallOpts, arg0)
}

// DelayedCommissionRateNegative is a free data retrieval call binding the contract method 0xac753a7a.
//
// Solidity: function delayedCommissionRateNegative(address ) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) DelayedCommissionRateNegative(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "delayedCommissionRateNegative", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// DelayedCommissionRateNegative is a free data retrieval call binding the contract method 0xac753a7a.
//
// Solidity: function delayedCommissionRateNegative(address ) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) DelayedCommissionRateNegative(arg0 common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.DelayedCommissionRateNegative(&_SeigManagerSlashing.CallOpts, arg0)
}

// DelayedCommissionRateNegative is a free data retrieval call binding the contract method 0xac753a7a.
//
// Solidity: function delayedCommissionRateNegative(address ) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) DelayedCommissionRateNegative(arg0 common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.DelayedCommissionRateNegative(&_SeigManagerSlashing.CallOpts, arg0)
}

// Factory is a free data retrieval call binding the contract method 0xc45a0155.
//
// Solidity: function factory() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) Factory(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "factory")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Factory is a free data retrieval call binding the contract method 0xc45a0155.
//
// Solidity: function factory() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingSession) Factory() (common.Address, error) {
	return _SeigManagerSlashing.Contract.Factory(&_SeigManagerSlashing.CallOpts)
}

// Factory is a free data retrieval call binding the contract method 0xc45a0155.
//
// Solidity: function factory() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) Factory() (common.Address, error) {
	return _SeigManagerSlashing.Contract.Factory(&_SeigManagerSlashing.CallOpts)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SeigManagerSlashing.Contract.GetRoleAdmin(&_SeigManagerSlashing.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SeigManagerSlashing.Contract.GetRoleAdmin(&_SeigManagerSlashing.CallOpts, role)
}

// HalfSaturationPoint is a free data retrieval call binding the contract method 0x767ea8b9.
//
// Solidity: function halfSaturationPoint() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) HalfSaturationPoint(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "halfSaturationPoint")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// HalfSaturationPoint is a free data retrieval call binding the contract method 0x767ea8b9.
//
// Solidity: function halfSaturationPoint() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) HalfSaturationPoint() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.HalfSaturationPoint(&_SeigManagerSlashing.CallOpts)
}

// HalfSaturationPoint is a free data retrieval call binding the contract method 0x767ea8b9.
//
// Solidity: function halfSaturationPoint() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) HalfSaturationPoint() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.HalfSaturationPoint(&_SeigManagerSlashing.CallOpts)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.HasRole(&_SeigManagerSlashing.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.HasRole(&_SeigManagerSlashing.CallOpts, role, account)
}

// InitialTotalSupply is a free data retrieval call binding the contract method 0x311028af.
//
// Solidity: function initialTotalSupply() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) InitialTotalSupply(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "initialTotalSupply")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// InitialTotalSupply is a free data retrieval call binding the contract method 0x311028af.
//
// Solidity: function initialTotalSupply() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) InitialTotalSupply() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.InitialTotalSupply(&_SeigManagerSlashing.CallOpts)
}

// InitialTotalSupply is a free data retrieval call binding the contract method 0x311028af.
//
// Solidity: function initialTotalSupply() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) InitialTotalSupply() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.InitialTotalSupply(&_SeigManagerSlashing.CallOpts)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) IsAdmin(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "isAdmin", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) IsAdmin(account common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.IsAdmin(&_SeigManagerSlashing.CallOpts, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) IsAdmin(account common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.IsAdmin(&_SeigManagerSlashing.CallOpts, account)
}

// IsChallenger is a free data retrieval call binding the contract method 0xa415d8dc.
//
// Solidity: function isChallenger(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) IsChallenger(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "isChallenger", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsChallenger is a free data retrieval call binding the contract method 0xa415d8dc.
//
// Solidity: function isChallenger(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) IsChallenger(account common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.IsChallenger(&_SeigManagerSlashing.CallOpts, account)
}

// IsChallenger is a free data retrieval call binding the contract method 0xa415d8dc.
//
// Solidity: function isChallenger(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) IsChallenger(account common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.IsChallenger(&_SeigManagerSlashing.CallOpts, account)
}

// IsMinter is a free data retrieval call binding the contract method 0xaa271e1a.
//
// Solidity: function isMinter(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) IsMinter(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "isMinter", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsMinter is a free data retrieval call binding the contract method 0xaa271e1a.
//
// Solidity: function isMinter(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) IsMinter(account common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.IsMinter(&_SeigManagerSlashing.CallOpts, account)
}

// IsMinter is a free data retrieval call binding the contract method 0xaa271e1a.
//
// Solidity: function isMinter(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) IsMinter(account common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.IsMinter(&_SeigManagerSlashing.CallOpts, account)
}

// IsOperator is a free data retrieval call binding the contract method 0x6d70f7ae.
//
// Solidity: function isOperator(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) IsOperator(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "isOperator", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsOperator is a free data retrieval call binding the contract method 0x6d70f7ae.
//
// Solidity: function isOperator(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) IsOperator(account common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.IsOperator(&_SeigManagerSlashing.CallOpts, account)
}

// IsOperator is a free data retrieval call binding the contract method 0x6d70f7ae.
//
// Solidity: function isOperator(address account) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) IsOperator(account common.Address) (bool, error) {
	return _SeigManagerSlashing.Contract.IsOperator(&_SeigManagerSlashing.CallOpts, account)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) IsOwner(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "isOwner")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) IsOwner() (bool, error) {
	return _SeigManagerSlashing.Contract.IsOwner(&_SeigManagerSlashing.CallOpts)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) IsOwner() (bool, error) {
	return _SeigManagerSlashing.Contract.IsOwner(&_SeigManagerSlashing.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) L1BridgeRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "l1BridgeRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingSession) L1BridgeRegistry() (common.Address, error) {
	return _SeigManagerSlashing.Contract.L1BridgeRegistry(&_SeigManagerSlashing.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) L1BridgeRegistry() (common.Address, error) {
	return _SeigManagerSlashing.Contract.L1BridgeRegistry(&_SeigManagerSlashing.CallOpts)
}

// L2RewardPerUint is a free data retrieval call binding the contract method 0xf9bae41a.
//
// Solidity: function l2RewardPerUint() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) L2RewardPerUint(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "l2RewardPerUint")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// L2RewardPerUint is a free data retrieval call binding the contract method 0xf9bae41a.
//
// Solidity: function l2RewardPerUint() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) L2RewardPerUint() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.L2RewardPerUint(&_SeigManagerSlashing.CallOpts)
}

// L2RewardPerUint is a free data retrieval call binding the contract method 0xf9bae41a.
//
// Solidity: function l2RewardPerUint() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) L2RewardPerUint() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.L2RewardPerUint(&_SeigManagerSlashing.CallOpts)
}

// LastSnapshotId is a free data retrieval call binding the contract method 0x837afbc0.
//
// Solidity: function lastSnapshotId() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) LastSnapshotId(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "lastSnapshotId")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LastSnapshotId is a free data retrieval call binding the contract method 0x837afbc0.
//
// Solidity: function lastSnapshotId() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) LastSnapshotId() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.LastSnapshotId(&_SeigManagerSlashing.CallOpts)
}

// LastSnapshotId is a free data retrieval call binding the contract method 0x837afbc0.
//
// Solidity: function lastSnapshotId() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) LastSnapshotId() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.LastSnapshotId(&_SeigManagerSlashing.CallOpts)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) Layer2Manager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "layer2Manager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingSession) Layer2Manager() (common.Address, error) {
	return _SeigManagerSlashing.Contract.Layer2Manager(&_SeigManagerSlashing.CallOpts)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) Layer2Manager() (common.Address, error) {
	return _SeigManagerSlashing.Contract.Layer2Manager(&_SeigManagerSlashing.CallOpts)
}

// Layer2PauseBlocks is a free data retrieval call binding the contract method 0xd601c9cf.
//
// Solidity: function layer2PauseBlocks(address , uint256 ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) Layer2PauseBlocks(opts *bind.CallOpts, arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "layer2PauseBlocks", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Layer2PauseBlocks is a free data retrieval call binding the contract method 0xd601c9cf.
//
// Solidity: function layer2PauseBlocks(address , uint256 ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) Layer2PauseBlocks(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _SeigManagerSlashing.Contract.Layer2PauseBlocks(&_SeigManagerSlashing.CallOpts, arg0, arg1)
}

// Layer2PauseBlocks is a free data retrieval call binding the contract method 0xd601c9cf.
//
// Solidity: function layer2PauseBlocks(address , uint256 ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) Layer2PauseBlocks(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _SeigManagerSlashing.Contract.Layer2PauseBlocks(&_SeigManagerSlashing.CallOpts, arg0, arg1)
}

// Layer2RewardInfo is a free data retrieval call binding the contract method 0x5f6fb8b9.
//
// Solidity: function layer2RewardInfo(address ) view returns(uint256 layer2Tvl, uint256 initialDebt, uint256 startBlock)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) Layer2RewardInfo(opts *bind.CallOpts, arg0 common.Address) (struct {
	Layer2Tvl   *big.Int
	InitialDebt *big.Int
	StartBlock  *big.Int
}, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "layer2RewardInfo", arg0)

	outstruct := new(struct {
		Layer2Tvl   *big.Int
		InitialDebt *big.Int
		StartBlock  *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Layer2Tvl = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.InitialDebt = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.StartBlock = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// Layer2RewardInfo is a free data retrieval call binding the contract method 0x5f6fb8b9.
//
// Solidity: function layer2RewardInfo(address ) view returns(uint256 layer2Tvl, uint256 initialDebt, uint256 startBlock)
func (_SeigManagerSlashing *SeigManagerSlashingSession) Layer2RewardInfo(arg0 common.Address) (struct {
	Layer2Tvl   *big.Int
	InitialDebt *big.Int
	StartBlock  *big.Int
}, error) {
	return _SeigManagerSlashing.Contract.Layer2RewardInfo(&_SeigManagerSlashing.CallOpts, arg0)
}

// Layer2RewardInfo is a free data retrieval call binding the contract method 0x5f6fb8b9.
//
// Solidity: function layer2RewardInfo(address ) view returns(uint256 layer2Tvl, uint256 initialDebt, uint256 startBlock)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) Layer2RewardInfo(arg0 common.Address) (struct {
	Layer2Tvl   *big.Int
	InitialDebt *big.Int
	StartBlock  *big.Int
}, error) {
	return _SeigManagerSlashing.Contract.Layer2RewardInfo(&_SeigManagerSlashing.CallOpts, arg0)
}

// Layer2StartBlock is a free data retrieval call binding the contract method 0xd0d2ff70.
//
// Solidity: function layer2StartBlock() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) Layer2StartBlock(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "layer2StartBlock")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Layer2StartBlock is a free data retrieval call binding the contract method 0xd0d2ff70.
//
// Solidity: function layer2StartBlock() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) Layer2StartBlock() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.Layer2StartBlock(&_SeigManagerSlashing.CallOpts)
}

// Layer2StartBlock is a free data retrieval call binding the contract method 0xd0d2ff70.
//
// Solidity: function layer2StartBlock() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) Layer2StartBlock() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.Layer2StartBlock(&_SeigManagerSlashing.CallOpts)
}

// Layer2UnpauseBlocks is a free data retrieval call binding the contract method 0xb9237999.
//
// Solidity: function layer2UnpauseBlocks(address , uint256 ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) Layer2UnpauseBlocks(opts *bind.CallOpts, arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "layer2UnpauseBlocks", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Layer2UnpauseBlocks is a free data retrieval call binding the contract method 0xb9237999.
//
// Solidity: function layer2UnpauseBlocks(address , uint256 ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) Layer2UnpauseBlocks(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _SeigManagerSlashing.Contract.Layer2UnpauseBlocks(&_SeigManagerSlashing.CallOpts, arg0, arg1)
}

// Layer2UnpauseBlocks is a free data retrieval call binding the contract method 0xb9237999.
//
// Solidity: function layer2UnpauseBlocks(address , uint256 ) view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) Layer2UnpauseBlocks(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _SeigManagerSlashing.Contract.Layer2UnpauseBlocks(&_SeigManagerSlashing.CallOpts, arg0, arg1)
}

// MaxChallengers is a free data retrieval call binding the contract method 0xb249f288.
//
// Solidity: function maxChallengers() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) MaxChallengers(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "maxChallengers")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxChallengers is a free data retrieval call binding the contract method 0xb249f288.
//
// Solidity: function maxChallengers() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) MaxChallengers() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MaxChallengers(&_SeigManagerSlashing.CallOpts)
}

// MaxChallengers is a free data retrieval call binding the contract method 0xb249f288.
//
// Solidity: function maxChallengers() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) MaxChallengers() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MaxChallengers(&_SeigManagerSlashing.CallOpts)
}

// MaxFraudProofCost is a free data retrieval call binding the contract method 0xababaa24.
//
// Solidity: function maxFraudProofCost() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) MaxFraudProofCost(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "maxFraudProofCost")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxFraudProofCost is a free data retrieval call binding the contract method 0xababaa24.
//
// Solidity: function maxFraudProofCost() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) MaxFraudProofCost() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MaxFraudProofCost(&_SeigManagerSlashing.CallOpts)
}

// MaxFraudProofCost is a free data retrieval call binding the contract method 0xababaa24.
//
// Solidity: function maxFraudProofCost() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) MaxFraudProofCost() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MaxFraudProofCost(&_SeigManagerSlashing.CallOpts)
}

// MinStakingRatio is a free data retrieval call binding the contract method 0xdd8732bf.
//
// Solidity: function minStakingRatio() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) MinStakingRatio(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "minStakingRatio")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MinStakingRatio is a free data retrieval call binding the contract method 0xdd8732bf.
//
// Solidity: function minStakingRatio() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) MinStakingRatio() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MinStakingRatio(&_SeigManagerSlashing.CallOpts)
}

// MinStakingRatio is a free data retrieval call binding the contract method 0xdd8732bf.
//
// Solidity: function minStakingRatio() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) MinStakingRatio() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MinStakingRatio(&_SeigManagerSlashing.CallOpts)
}

// MinimumAmount is a free data retrieval call binding the contract method 0xbb0c8298.
//
// Solidity: function minimumAmount() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) MinimumAmount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "minimumAmount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MinimumAmount is a free data retrieval call binding the contract method 0xbb0c8298.
//
// Solidity: function minimumAmount() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) MinimumAmount() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MinimumAmount(&_SeigManagerSlashing.CallOpts)
}

// MinimumAmount is a free data retrieval call binding the contract method 0xbb0c8298.
//
// Solidity: function minimumAmount() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) MinimumAmount() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.MinimumAmount(&_SeigManagerSlashing.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) PauseProxy(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "pauseProxy")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) PauseProxy() (bool, error) {
	return _SeigManagerSlashing.Contract.PauseProxy(&_SeigManagerSlashing.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) PauseProxy() (bool, error) {
	return _SeigManagerSlashing.Contract.PauseProxy(&_SeigManagerSlashing.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) Paused() (bool, error) {
	return _SeigManagerSlashing.Contract.Paused(&_SeigManagerSlashing.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) Paused() (bool, error) {
	return _SeigManagerSlashing.Contract.Paused(&_SeigManagerSlashing.CallOpts)
}

// Periods is a free data retrieval call binding the contract method 0xea4a1104.
//
// Solidity: function periods(uint256 ) view returns(uint256 startBlock, uint256 endBlock, uint256 totalSeigniorage, uint256 totalDistributed, uint256 validatorPoolAmount, bool finalized)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) Periods(opts *bind.CallOpts, arg0 *big.Int) (struct {
	StartBlock          *big.Int
	EndBlock            *big.Int
	TotalSeigniorage    *big.Int
	TotalDistributed    *big.Int
	ValidatorPoolAmount *big.Int
	Finalized           bool
}, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "periods", arg0)

	outstruct := new(struct {
		StartBlock          *big.Int
		EndBlock            *big.Int
		TotalSeigniorage    *big.Int
		TotalDistributed    *big.Int
		ValidatorPoolAmount *big.Int
		Finalized           bool
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.StartBlock = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.EndBlock = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.TotalSeigniorage = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.TotalDistributed = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.ValidatorPoolAmount = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)
	outstruct.Finalized = *abi.ConvertType(out[5], new(bool)).(*bool)

	return *outstruct, err

}

// Periods is a free data retrieval call binding the contract method 0xea4a1104.
//
// Solidity: function periods(uint256 ) view returns(uint256 startBlock, uint256 endBlock, uint256 totalSeigniorage, uint256 totalDistributed, uint256 validatorPoolAmount, bool finalized)
func (_SeigManagerSlashing *SeigManagerSlashingSession) Periods(arg0 *big.Int) (struct {
	StartBlock          *big.Int
	EndBlock            *big.Int
	TotalSeigniorage    *big.Int
	TotalDistributed    *big.Int
	ValidatorPoolAmount *big.Int
	Finalized           bool
}, error) {
	return _SeigManagerSlashing.Contract.Periods(&_SeigManagerSlashing.CallOpts, arg0)
}

// Periods is a free data retrieval call binding the contract method 0xea4a1104.
//
// Solidity: function periods(uint256 ) view returns(uint256 startBlock, uint256 endBlock, uint256 totalSeigniorage, uint256 totalDistributed, uint256 validatorPoolAmount, bool finalized)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) Periods(arg0 *big.Int) (struct {
	StartBlock          *big.Int
	EndBlock            *big.Int
	TotalSeigniorage    *big.Int
	TotalDistributed    *big.Int
	ValidatorPoolAmount *big.Int
	Finalized           bool
}, error) {
	return _SeigManagerSlashing.Contract.Periods(&_SeigManagerSlashing.CallOpts, arg0)
}

// PowerTONSeigRate is a free data retrieval call binding the contract method 0x6304a624.
//
// Solidity: function powerTONSeigRate() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) PowerTONSeigRate(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "powerTONSeigRate")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PowerTONSeigRate is a free data retrieval call binding the contract method 0x6304a624.
//
// Solidity: function powerTONSeigRate() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) PowerTONSeigRate() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.PowerTONSeigRate(&_SeigManagerSlashing.CallOpts)
}

// PowerTONSeigRate is a free data retrieval call binding the contract method 0x6304a624.
//
// Solidity: function powerTONSeigRate() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) PowerTONSeigRate() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.PowerTONSeigRate(&_SeigManagerSlashing.CallOpts)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) ProxyImplementation(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "proxyImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _SeigManagerSlashing.Contract.ProxyImplementation(&_SeigManagerSlashing.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _SeigManagerSlashing.Contract.ProxyImplementation(&_SeigManagerSlashing.CallOpts, arg0)
}

// RelativeSeigRate is a free data retrieval call binding the contract method 0x25374a9a.
//
// Solidity: function relativeSeigRate() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) RelativeSeigRate(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "relativeSeigRate")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// RelativeSeigRate is a free data retrieval call binding the contract method 0x25374a9a.
//
// Solidity: function relativeSeigRate() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) RelativeSeigRate() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.RelativeSeigRate(&_SeigManagerSlashing.CallOpts)
}

// RelativeSeigRate is a free data retrieval call binding the contract method 0x25374a9a.
//
// Solidity: function relativeSeigRate() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) RelativeSeigRate() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.RelativeSeigRate(&_SeigManagerSlashing.CallOpts)
}

// SeigStartBlock is a free data retrieval call binding the contract method 0xf96032e6.
//
// Solidity: function seigStartBlock() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) SeigStartBlock(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "seigStartBlock")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// SeigStartBlock is a free data retrieval call binding the contract method 0xf96032e6.
//
// Solidity: function seigStartBlock() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) SeigStartBlock() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.SeigStartBlock(&_SeigManagerSlashing.CallOpts)
}

// SeigStartBlock is a free data retrieval call binding the contract method 0xf96032e6.
//
// Solidity: function seigStartBlock() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) SeigStartBlock() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.SeigStartBlock(&_SeigManagerSlashing.CallOpts)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) SelectorImplementation(opts *bind.CallOpts, arg0 [4]byte) (common.Address, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "selectorImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _SeigManagerSlashing.Contract.SelectorImplementation(&_SeigManagerSlashing.CallOpts, arg0)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _SeigManagerSlashing.Contract.SelectorImplementation(&_SeigManagerSlashing.CallOpts, arg0)
}

// SequencerVault is a free data retrieval call binding the contract method 0x9b8230ac.
//
// Solidity: function sequencerVault() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) SequencerVault(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "sequencerVault")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SequencerVault is a free data retrieval call binding the contract method 0x9b8230ac.
//
// Solidity: function sequencerVault() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingSession) SequencerVault() (common.Address, error) {
	return _SeigManagerSlashing.Contract.SequencerVault(&_SeigManagerSlashing.CallOpts)
}

// SequencerVault is a free data retrieval call binding the contract method 0x9b8230ac.
//
// Solidity: function sequencerVault() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) SequencerVault() (common.Address, error) {
	return _SeigManagerSlashing.Contract.SequencerVault(&_SeigManagerSlashing.CallOpts)
}

// StakedSeigFactor is a free data retrieval call binding the contract method 0xc094902b.
//
// Solidity: function stakedSeigFactor() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) StakedSeigFactor(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "stakedSeigFactor")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// StakedSeigFactor is a free data retrieval call binding the contract method 0xc094902b.
//
// Solidity: function stakedSeigFactor() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) StakedSeigFactor() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.StakedSeigFactor(&_SeigManagerSlashing.CallOpts)
}

// StakedSeigFactor is a free data retrieval call binding the contract method 0xc094902b.
//
// Solidity: function stakedSeigFactor() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) StakedSeigFactor() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.StakedSeigFactor(&_SeigManagerSlashing.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SeigManagerSlashing.Contract.SupportsInterface(&_SeigManagerSlashing.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SeigManagerSlashing.Contract.SupportsInterface(&_SeigManagerSlashing.CallOpts, interfaceId)
}

// TotalEffectiveBridgedTON is a free data retrieval call binding the contract method 0x279fff74.
//
// Solidity: function totalEffectiveBridgedTON() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) TotalEffectiveBridgedTON(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "totalEffectiveBridgedTON")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalEffectiveBridgedTON is a free data retrieval call binding the contract method 0x279fff74.
//
// Solidity: function totalEffectiveBridgedTON() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) TotalEffectiveBridgedTON() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.TotalEffectiveBridgedTON(&_SeigManagerSlashing.CallOpts)
}

// TotalEffectiveBridgedTON is a free data retrieval call binding the contract method 0x279fff74.
//
// Solidity: function totalEffectiveBridgedTON() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) TotalEffectiveBridgedTON() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.TotalEffectiveBridgedTON(&_SeigManagerSlashing.CallOpts)
}

// TotalLayer2TVL is a free data retrieval call binding the contract method 0x6e71186b.
//
// Solidity: function totalLayer2TVL() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) TotalLayer2TVL(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "totalLayer2TVL")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalLayer2TVL is a free data retrieval call binding the contract method 0x6e71186b.
//
// Solidity: function totalLayer2TVL() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) TotalLayer2TVL() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.TotalLayer2TVL(&_SeigManagerSlashing.CallOpts)
}

// TotalLayer2TVL is a free data retrieval call binding the contract method 0x6e71186b.
//
// Solidity: function totalLayer2TVL() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) TotalLayer2TVL() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.TotalLayer2TVL(&_SeigManagerSlashing.CallOpts)
}

// V3Migrated is a free data retrieval call binding the contract method 0x067ccc0a.
//
// Solidity: function v3Migrated() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) V3Migrated(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "v3Migrated")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// V3Migrated is a free data retrieval call binding the contract method 0x067ccc0a.
//
// Solidity: function v3Migrated() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingSession) V3Migrated() (bool, error) {
	return _SeigManagerSlashing.Contract.V3Migrated(&_SeigManagerSlashing.CallOpts)
}

// V3Migrated is a free data retrieval call binding the contract method 0x067ccc0a.
//
// Solidity: function v3Migrated() view returns(bool)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) V3Migrated() (bool, error) {
	return _SeigManagerSlashing.Contract.V3Migrated(&_SeigManagerSlashing.CallOpts)
}

// V3MigrationBlock is a free data retrieval call binding the contract method 0xe2e70a77.
//
// Solidity: function v3MigrationBlock() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) V3MigrationBlock(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "v3MigrationBlock")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// V3MigrationBlock is a free data retrieval call binding the contract method 0xe2e70a77.
//
// Solidity: function v3MigrationBlock() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) V3MigrationBlock() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.V3MigrationBlock(&_SeigManagerSlashing.CallOpts)
}

// V3MigrationBlock is a free data retrieval call binding the contract method 0xe2e70a77.
//
// Solidity: function v3MigrationBlock() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) V3MigrationBlock() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.V3MigrationBlock(&_SeigManagerSlashing.CallOpts)
}

// ValidatorDistributionRatio is a free data retrieval call binding the contract method 0x20e18d19.
//
// Solidity: function validatorDistributionRatio() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) ValidatorDistributionRatio(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "validatorDistributionRatio")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ValidatorDistributionRatio is a free data retrieval call binding the contract method 0x20e18d19.
//
// Solidity: function validatorDistributionRatio() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) ValidatorDistributionRatio() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.ValidatorDistributionRatio(&_SeigManagerSlashing.CallOpts)
}

// ValidatorDistributionRatio is a free data retrieval call binding the contract method 0x20e18d19.
//
// Solidity: function validatorDistributionRatio() view returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) ValidatorDistributionRatio() (*big.Int, error) {
	return _SeigManagerSlashing.Contract.ValidatorDistributionRatio(&_SeigManagerSlashing.CallOpts)
}

// ValidatorReward is a free data retrieval call binding the contract method 0x75b94133.
//
// Solidity: function validatorReward() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCaller) ValidatorReward(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SeigManagerSlashing.contract.Call(opts, &out, "validatorReward")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ValidatorReward is a free data retrieval call binding the contract method 0x75b94133.
//
// Solidity: function validatorReward() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingSession) ValidatorReward() (common.Address, error) {
	return _SeigManagerSlashing.Contract.ValidatorReward(&_SeigManagerSlashing.CallOpts)
}

// ValidatorReward is a free data retrieval call binding the contract method 0x75b94133.
//
// Solidity: function validatorReward() view returns(address)
func (_SeigManagerSlashing *SeigManagerSlashingCallerSession) ValidatorReward() (common.Address, error) {
	return _SeigManagerSlashing.Contract.ValidatorReward(&_SeigManagerSlashing.CallOpts)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) AddAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "addAdmin", account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.AddAdmin(&_SeigManagerSlashing.TransactOpts, account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.AddAdmin(&_SeigManagerSlashing.TransactOpts, account)
}

// AddChallenger is a paid mutator transaction binding the contract method 0x0ceb6780.
//
// Solidity: function addChallenger(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) AddChallenger(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "addChallenger", account)
}

// AddChallenger is a paid mutator transaction binding the contract method 0x0ceb6780.
//
// Solidity: function addChallenger(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) AddChallenger(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.AddChallenger(&_SeigManagerSlashing.TransactOpts, account)
}

// AddChallenger is a paid mutator transaction binding the contract method 0x0ceb6780.
//
// Solidity: function addChallenger(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) AddChallenger(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.AddChallenger(&_SeigManagerSlashing.TransactOpts, account)
}

// AddMinter is a paid mutator transaction binding the contract method 0x983b2d56.
//
// Solidity: function addMinter(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) AddMinter(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "addMinter", account)
}

// AddMinter is a paid mutator transaction binding the contract method 0x983b2d56.
//
// Solidity: function addMinter(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) AddMinter(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.AddMinter(&_SeigManagerSlashing.TransactOpts, account)
}

// AddMinter is a paid mutator transaction binding the contract method 0x983b2d56.
//
// Solidity: function addMinter(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) AddMinter(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.AddMinter(&_SeigManagerSlashing.TransactOpts, account)
}

// AddOperator is a paid mutator transaction binding the contract method 0x9870d7fe.
//
// Solidity: function addOperator(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) AddOperator(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "addOperator", account)
}

// AddOperator is a paid mutator transaction binding the contract method 0x9870d7fe.
//
// Solidity: function addOperator(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) AddOperator(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.AddOperator(&_SeigManagerSlashing.TransactOpts, account)
}

// AddOperator is a paid mutator transaction binding the contract method 0x9870d7fe.
//
// Solidity: function addOperator(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) AddOperator(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.AddOperator(&_SeigManagerSlashing.TransactOpts, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.GrantRole(&_SeigManagerSlashing.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.GrantRole(&_SeigManagerSlashing.TransactOpts, role, account)
}

// OnSlash is a paid mutator transaction binding the contract method 0x453260d7.
//
// Solidity: function onSlash(address layer2, address operator) returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) OnSlash(opts *bind.TransactOpts, layer2 common.Address, operator common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "onSlash", layer2, operator)
}

// OnSlash is a paid mutator transaction binding the contract method 0x453260d7.
//
// Solidity: function onSlash(address layer2, address operator) returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingSession) OnSlash(layer2 common.Address, operator common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.OnSlash(&_SeigManagerSlashing.TransactOpts, layer2, operator)
}

// OnSlash is a paid mutator transaction binding the contract method 0x453260d7.
//
// Solidity: function onSlash(address layer2, address operator) returns(uint256)
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) OnSlash(layer2 common.Address, operator common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.OnSlash(&_SeigManagerSlashing.TransactOpts, layer2, operator)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) RemoveAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "removeAdmin", account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RemoveAdmin(&_SeigManagerSlashing.TransactOpts, account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RemoveAdmin(&_SeigManagerSlashing.TransactOpts, account)
}

// RemoveChallenger is a paid mutator transaction binding the contract method 0x6c578c1d.
//
// Solidity: function removeChallenger(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) RemoveChallenger(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "removeChallenger", account)
}

// RemoveChallenger is a paid mutator transaction binding the contract method 0x6c578c1d.
//
// Solidity: function removeChallenger(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) RemoveChallenger(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RemoveChallenger(&_SeigManagerSlashing.TransactOpts, account)
}

// RemoveChallenger is a paid mutator transaction binding the contract method 0x6c578c1d.
//
// Solidity: function removeChallenger(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) RemoveChallenger(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RemoveChallenger(&_SeigManagerSlashing.TransactOpts, account)
}

// RemoveMinter is a paid mutator transaction binding the contract method 0x3092afd5.
//
// Solidity: function removeMinter(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) RemoveMinter(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "removeMinter", account)
}

// RemoveMinter is a paid mutator transaction binding the contract method 0x3092afd5.
//
// Solidity: function removeMinter(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) RemoveMinter(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RemoveMinter(&_SeigManagerSlashing.TransactOpts, account)
}

// RemoveMinter is a paid mutator transaction binding the contract method 0x3092afd5.
//
// Solidity: function removeMinter(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) RemoveMinter(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RemoveMinter(&_SeigManagerSlashing.TransactOpts, account)
}

// RemoveOperator is a paid mutator transaction binding the contract method 0xac8a584a.
//
// Solidity: function removeOperator(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) RemoveOperator(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "removeOperator", account)
}

// RemoveOperator is a paid mutator transaction binding the contract method 0xac8a584a.
//
// Solidity: function removeOperator(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) RemoveOperator(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RemoveOperator(&_SeigManagerSlashing.TransactOpts, account)
}

// RemoveOperator is a paid mutator transaction binding the contract method 0xac8a584a.
//
// Solidity: function removeOperator(address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) RemoveOperator(account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RemoveOperator(&_SeigManagerSlashing.TransactOpts, account)
}

// RenounceChallenger is a paid mutator transaction binding the contract method 0x25e90db4.
//
// Solidity: function renounceChallenger() returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) RenounceChallenger(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "renounceChallenger")
}

// RenounceChallenger is a paid mutator transaction binding the contract method 0x25e90db4.
//
// Solidity: function renounceChallenger() returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) RenounceChallenger() (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RenounceChallenger(&_SeigManagerSlashing.TransactOpts)
}

// RenounceChallenger is a paid mutator transaction binding the contract method 0x25e90db4.
//
// Solidity: function renounceChallenger() returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) RenounceChallenger() (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RenounceChallenger(&_SeigManagerSlashing.TransactOpts)
}

// RenounceMinter is a paid mutator transaction binding the contract method 0x98650275.
//
// Solidity: function renounceMinter() returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) RenounceMinter(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "renounceMinter")
}

// RenounceMinter is a paid mutator transaction binding the contract method 0x98650275.
//
// Solidity: function renounceMinter() returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) RenounceMinter() (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RenounceMinter(&_SeigManagerSlashing.TransactOpts)
}

// RenounceMinter is a paid mutator transaction binding the contract method 0x98650275.
//
// Solidity: function renounceMinter() returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) RenounceMinter() (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RenounceMinter(&_SeigManagerSlashing.TransactOpts)
}

// RenounceOperator is a paid mutator transaction binding the contract method 0x2ab6f8db.
//
// Solidity: function renounceOperator() returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) RenounceOperator(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "renounceOperator")
}

// RenounceOperator is a paid mutator transaction binding the contract method 0x2ab6f8db.
//
// Solidity: function renounceOperator() returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) RenounceOperator() (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RenounceOperator(&_SeigManagerSlashing.TransactOpts)
}

// RenounceOperator is a paid mutator transaction binding the contract method 0x2ab6f8db.
//
// Solidity: function renounceOperator() returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) RenounceOperator() (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RenounceOperator(&_SeigManagerSlashing.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) RenounceOwnership() (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RenounceOwnership(&_SeigManagerSlashing.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RenounceOwnership(&_SeigManagerSlashing.TransactOpts)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "renounceRole", role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RenounceRole(&_SeigManagerSlashing.TransactOpts, role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RenounceRole(&_SeigManagerSlashing.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RevokeRole(&_SeigManagerSlashing.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.RevokeRole(&_SeigManagerSlashing.TransactOpts, role, account)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactor) TransferAdmin(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.contract.Transact(opts, "transferAdmin", newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_SeigManagerSlashing *SeigManagerSlashingSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.TransferAdmin(&_SeigManagerSlashing.TransactOpts, newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_SeigManagerSlashing *SeigManagerSlashingTransactorSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _SeigManagerSlashing.Contract.TransferAdmin(&_SeigManagerSlashing.TransactOpts, newAdmin)
}

// SeigManagerSlashingRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the SeigManagerSlashing contract.
type SeigManagerSlashingRoleAdminChangedIterator struct {
	Event *SeigManagerSlashingRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *SeigManagerSlashingRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SeigManagerSlashingRoleAdminChanged)
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
		it.Event = new(SeigManagerSlashingRoleAdminChanged)
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
func (it *SeigManagerSlashingRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SeigManagerSlashingRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SeigManagerSlashingRoleAdminChanged represents a RoleAdminChanged event raised by the SeigManagerSlashing contract.
type SeigManagerSlashingRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*SeigManagerSlashingRoleAdminChangedIterator, error) {

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

	logs, sub, err := _SeigManagerSlashing.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &SeigManagerSlashingRoleAdminChangedIterator{contract: _SeigManagerSlashing.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *SeigManagerSlashingRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _SeigManagerSlashing.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SeigManagerSlashingRoleAdminChanged)
				if err := _SeigManagerSlashing.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) ParseRoleAdminChanged(log types.Log) (*SeigManagerSlashingRoleAdminChanged, error) {
	event := new(SeigManagerSlashingRoleAdminChanged)
	if err := _SeigManagerSlashing.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SeigManagerSlashingRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the SeigManagerSlashing contract.
type SeigManagerSlashingRoleGrantedIterator struct {
	Event *SeigManagerSlashingRoleGranted // Event containing the contract specifics and raw log

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
func (it *SeigManagerSlashingRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SeigManagerSlashingRoleGranted)
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
		it.Event = new(SeigManagerSlashingRoleGranted)
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
func (it *SeigManagerSlashingRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SeigManagerSlashingRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SeigManagerSlashingRoleGranted represents a RoleGranted event raised by the SeigManagerSlashing contract.
type SeigManagerSlashingRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SeigManagerSlashingRoleGrantedIterator, error) {

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

	logs, sub, err := _SeigManagerSlashing.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SeigManagerSlashingRoleGrantedIterator{contract: _SeigManagerSlashing.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *SeigManagerSlashingRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SeigManagerSlashing.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SeigManagerSlashingRoleGranted)
				if err := _SeigManagerSlashing.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) ParseRoleGranted(log types.Log) (*SeigManagerSlashingRoleGranted, error) {
	event := new(SeigManagerSlashingRoleGranted)
	if err := _SeigManagerSlashing.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SeigManagerSlashingRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the SeigManagerSlashing contract.
type SeigManagerSlashingRoleRevokedIterator struct {
	Event *SeigManagerSlashingRoleRevoked // Event containing the contract specifics and raw log

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
func (it *SeigManagerSlashingRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SeigManagerSlashingRoleRevoked)
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
		it.Event = new(SeigManagerSlashingRoleRevoked)
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
func (it *SeigManagerSlashingRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SeigManagerSlashingRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SeigManagerSlashingRoleRevoked represents a RoleRevoked event raised by the SeigManagerSlashing contract.
type SeigManagerSlashingRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SeigManagerSlashingRoleRevokedIterator, error) {

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

	logs, sub, err := _SeigManagerSlashing.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SeigManagerSlashingRoleRevokedIterator{contract: _SeigManagerSlashing.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *SeigManagerSlashingRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SeigManagerSlashing.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SeigManagerSlashingRoleRevoked)
				if err := _SeigManagerSlashing.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) ParseRoleRevoked(log types.Log) (*SeigManagerSlashingRoleRevoked, error) {
	event := new(SeigManagerSlashingRoleRevoked)
	if err := _SeigManagerSlashing.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SeigManagerSlashingSlashedIterator is returned from FilterSlashed and is used to iterate over the raw logs and unpacked data for Slashed events raised by the SeigManagerSlashing contract.
type SeigManagerSlashingSlashedIterator struct {
	Event *SeigManagerSlashingSlashed // Event containing the contract specifics and raw log

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
func (it *SeigManagerSlashingSlashedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SeigManagerSlashingSlashed)
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
		it.Event = new(SeigManagerSlashingSlashed)
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
func (it *SeigManagerSlashingSlashedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SeigManagerSlashingSlashedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SeigManagerSlashingSlashed represents a Slashed event raised by the SeigManagerSlashing contract.
type SeigManagerSlashingSlashed struct {
	Layer2   common.Address
	Operator common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterSlashed is a free log retrieval operation binding the contract event 0xfd4a68324450a7ad187510820dce9e139c7d75a8e84d90d4977e2730638e64d5.
//
// Solidity: event Slashed(address layer2, address operator)
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) FilterSlashed(opts *bind.FilterOpts) (*SeigManagerSlashingSlashedIterator, error) {

	logs, sub, err := _SeigManagerSlashing.contract.FilterLogs(opts, "Slashed")
	if err != nil {
		return nil, err
	}
	return &SeigManagerSlashingSlashedIterator{contract: _SeigManagerSlashing.contract, event: "Slashed", logs: logs, sub: sub}, nil
}

// WatchSlashed is a free log subscription operation binding the contract event 0xfd4a68324450a7ad187510820dce9e139c7d75a8e84d90d4977e2730638e64d5.
//
// Solidity: event Slashed(address layer2, address operator)
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) WatchSlashed(opts *bind.WatchOpts, sink chan<- *SeigManagerSlashingSlashed) (event.Subscription, error) {

	logs, sub, err := _SeigManagerSlashing.contract.WatchLogs(opts, "Slashed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SeigManagerSlashingSlashed)
				if err := _SeigManagerSlashing.contract.UnpackLog(event, "Slashed", log); err != nil {
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

// ParseSlashed is a log parse operation binding the contract event 0xfd4a68324450a7ad187510820dce9e139c7d75a8e84d90d4977e2730638e64d5.
//
// Solidity: event Slashed(address layer2, address operator)
func (_SeigManagerSlashing *SeigManagerSlashingFilterer) ParseSlashed(log types.Log) (*SeigManagerSlashingSlashed, error) {
	event := new(SeigManagerSlashingSlashed)
	if err := _SeigManagerSlashing.contract.UnpackLog(event, "Slashed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
