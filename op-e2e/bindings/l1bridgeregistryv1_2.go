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

// L1BridgeRegistryV12MetaData contains all meta data concerning the L1BridgeRegistryV12 contract.
var L1BridgeRegistryV12MetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"CHALLENGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MANAGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MINTER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"OPERATOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"PAUSE_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"REGISTRANT_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addManager\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addRegistrant\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"aliveImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"availableForRegistration\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_type\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"outputs\":[{\"name\":\"valid\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"disputeGameFactory\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRollupInfo\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"type_\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"l2TON_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rejectedSeigs_\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"rejectedL2Deposit_\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"name_\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isManager\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isOwner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isRegistrant\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isRejectedL2Deposit\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"rejectedL2Deposit\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isRejectedSeigs\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"rejectedSeigs\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1Bridge\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l2TON\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"l2TonAddress\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2Manager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2TVL\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseProxy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"portal\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxyImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"registerRollupConfig\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_type\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"_l2TON\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_name\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerRollupConfig\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_type\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"_l2TON\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerRollupConfigByManager\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_type\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"_l2TON\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerRollupConfigByManager\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_type\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"_l2TON\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_name\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerRollupConfigByType\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_type\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"_l2TON\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerRollupConfigByType\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_type\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"_l2TON\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_name\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registeredNames\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"rejectCandidateAddOn\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"rejectRollupConfig\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"rejectedSeigs\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"removeAdmin\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeManager\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeRegistrant\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceManager\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRegistrant\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"restoreCandidateAddOn\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rejectedL2Deposit\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeManager\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRegistrant\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"rollupConfigWithDisputeGameFactory\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"rollupConfigWithPortal\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"rollupInfo\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"rollupType\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"l2TON\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rejectedSeigs\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"rejectedL2Deposit\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"rollupType\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"rollupType_\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"seigManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"seigniorageCommittee\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"selectorImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setAddresses\",\"inputs\":[{\"name\":\"_layer2Manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_seigManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_ton\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSeigniorageCommittee\",\"inputs\":[{\"name\":\"_seigniorageCommittee\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTypeRegistrant\",\"inputs\":[{\"name\":\"_type\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"_registrant\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferAdmin\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"typeRegistrant\",\"inputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"upgradeToType3\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"AddedBridge\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"bridge\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AddedDisputeGameFactory\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"disputeGameFactory\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AddedPortal\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"portal\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RegisteredRollupConfig\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"type_\",\"type\":\"uint8\",\"indexed\":false,\"internalType\":\"uint8\"},{\"name\":\"l2TON\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RejectedCandidateAddOn\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RestoredCandidateAddOn\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SetAddresses\",\"inputs\":[{\"name\":\"_layer2Manager\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"_seigManager\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"_ton\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SetBlockingL2Deposit\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"rejectedL2Deposit\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SetSeigniorageCommittee\",\"inputs\":[{\"name\":\"_seigniorageCommittee\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TypeRegistrantSet\",\"inputs\":[{\"name\":\"rollupType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"uint8\"},{\"name\":\"registrant\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpgradedToType3\",\"inputs\":[{\"name\":\"rollupConfig\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"previousType\",\"type\":\"uint8\",\"indexed\":false,\"internalType\":\"uint8\"},{\"name\":\"portal\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"disputeGameFactory\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"BridgeError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DisputeGameFactoryError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NonRejectedError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotAuthorizedError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OnlyRejectedError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PortalError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"RegisterError\",\"inputs\":[{\"name\":\"x\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"UpgradeError\",\"inputs\":[{\"name\":\"x\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ZeroAddressError\",\"inputs\":[]}]",
}

// L1BridgeRegistryV12ABI is the input ABI used to generate the binding from.
// Deprecated: Use L1BridgeRegistryV12MetaData.ABI instead.
var L1BridgeRegistryV12ABI = L1BridgeRegistryV12MetaData.ABI

// L1BridgeRegistryV12 is an auto generated Go binding around an Ethereum contract.
type L1BridgeRegistryV12 struct {
	L1BridgeRegistryV12Caller     // Read-only binding to the contract
	L1BridgeRegistryV12Transactor // Write-only binding to the contract
	L1BridgeRegistryV12Filterer   // Log filterer for contract events
}

// L1BridgeRegistryV12Caller is an auto generated read-only Go binding around an Ethereum contract.
type L1BridgeRegistryV12Caller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// L1BridgeRegistryV12Transactor is an auto generated write-only Go binding around an Ethereum contract.
type L1BridgeRegistryV12Transactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// L1BridgeRegistryV12Filterer is an auto generated log filtering Go binding around an Ethereum contract events.
type L1BridgeRegistryV12Filterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// L1BridgeRegistryV12Session is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type L1BridgeRegistryV12Session struct {
	Contract     *L1BridgeRegistryV12 // Generic contract binding to set the session for
	CallOpts     bind.CallOpts        // Call options to use throughout this session
	TransactOpts bind.TransactOpts    // Transaction auth options to use throughout this session
}

// L1BridgeRegistryV12CallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type L1BridgeRegistryV12CallerSession struct {
	Contract *L1BridgeRegistryV12Caller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts              // Call options to use throughout this session
}

// L1BridgeRegistryV12TransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type L1BridgeRegistryV12TransactorSession struct {
	Contract     *L1BridgeRegistryV12Transactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts              // Transaction auth options to use throughout this session
}

// L1BridgeRegistryV12Raw is an auto generated low-level Go binding around an Ethereum contract.
type L1BridgeRegistryV12Raw struct {
	Contract *L1BridgeRegistryV12 // Generic contract binding to access the raw methods on
}

// L1BridgeRegistryV12CallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type L1BridgeRegistryV12CallerRaw struct {
	Contract *L1BridgeRegistryV12Caller // Generic read-only contract binding to access the raw methods on
}

// L1BridgeRegistryV12TransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type L1BridgeRegistryV12TransactorRaw struct {
	Contract *L1BridgeRegistryV12Transactor // Generic write-only contract binding to access the raw methods on
}

// NewL1BridgeRegistryV12 creates a new instance of L1BridgeRegistryV12, bound to a specific deployed contract.
func NewL1BridgeRegistryV12(address common.Address, backend bind.ContractBackend) (*L1BridgeRegistryV12, error) {
	contract, err := bindL1BridgeRegistryV12(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12{L1BridgeRegistryV12Caller: L1BridgeRegistryV12Caller{contract: contract}, L1BridgeRegistryV12Transactor: L1BridgeRegistryV12Transactor{contract: contract}, L1BridgeRegistryV12Filterer: L1BridgeRegistryV12Filterer{contract: contract}}, nil
}

// NewL1BridgeRegistryV12Caller creates a new read-only instance of L1BridgeRegistryV12, bound to a specific deployed contract.
func NewL1BridgeRegistryV12Caller(address common.Address, caller bind.ContractCaller) (*L1BridgeRegistryV12Caller, error) {
	contract, err := bindL1BridgeRegistryV12(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12Caller{contract: contract}, nil
}

// NewL1BridgeRegistryV12Transactor creates a new write-only instance of L1BridgeRegistryV12, bound to a specific deployed contract.
func NewL1BridgeRegistryV12Transactor(address common.Address, transactor bind.ContractTransactor) (*L1BridgeRegistryV12Transactor, error) {
	contract, err := bindL1BridgeRegistryV12(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12Transactor{contract: contract}, nil
}

// NewL1BridgeRegistryV12Filterer creates a new log filterer instance of L1BridgeRegistryV12, bound to a specific deployed contract.
func NewL1BridgeRegistryV12Filterer(address common.Address, filterer bind.ContractFilterer) (*L1BridgeRegistryV12Filterer, error) {
	contract, err := bindL1BridgeRegistryV12(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12Filterer{contract: contract}, nil
}

// bindL1BridgeRegistryV12 binds a generic wrapper to an already deployed contract.
func bindL1BridgeRegistryV12(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := L1BridgeRegistryV12MetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Raw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _L1BridgeRegistryV12.Contract.L1BridgeRegistryV12Caller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Raw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.L1BridgeRegistryV12Transactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Raw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.L1BridgeRegistryV12Transactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _L1BridgeRegistryV12.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.contract.Transact(opts, method, params...)
}

// CHALLENGERROLE is a free data retrieval call binding the contract method 0x530adbb4.
//
// Solidity: function CHALLENGER_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) CHALLENGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "CHALLENGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// CHALLENGERROLE is a free data retrieval call binding the contract method 0x530adbb4.
//
// Solidity: function CHALLENGER_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) CHALLENGERROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.CHALLENGERROLE(&_L1BridgeRegistryV12.CallOpts)
}

// CHALLENGERROLE is a free data retrieval call binding the contract method 0x530adbb4.
//
// Solidity: function CHALLENGER_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) CHALLENGERROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.CHALLENGERROLE(&_L1BridgeRegistryV12.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) DEFAULTADMINROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.DEFAULTADMINROLE(&_L1BridgeRegistryV12.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.DEFAULTADMINROLE(&_L1BridgeRegistryV12.CallOpts)
}

// MANAGERROLE is a free data retrieval call binding the contract method 0xec87621c.
//
// Solidity: function MANAGER_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) MANAGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "MANAGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// MANAGERROLE is a free data retrieval call binding the contract method 0xec87621c.
//
// Solidity: function MANAGER_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) MANAGERROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.MANAGERROLE(&_L1BridgeRegistryV12.CallOpts)
}

// MANAGERROLE is a free data retrieval call binding the contract method 0xec87621c.
//
// Solidity: function MANAGER_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) MANAGERROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.MANAGERROLE(&_L1BridgeRegistryV12.CallOpts)
}

// MINTERROLE is a free data retrieval call binding the contract method 0xd5391393.
//
// Solidity: function MINTER_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) MINTERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "MINTER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// MINTERROLE is a free data retrieval call binding the contract method 0xd5391393.
//
// Solidity: function MINTER_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) MINTERROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.MINTERROLE(&_L1BridgeRegistryV12.CallOpts)
}

// MINTERROLE is a free data retrieval call binding the contract method 0xd5391393.
//
// Solidity: function MINTER_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) MINTERROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.MINTERROLE(&_L1BridgeRegistryV12.CallOpts)
}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) OPERATORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "OPERATOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) OPERATORROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.OPERATORROLE(&_L1BridgeRegistryV12.CallOpts)
}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) OPERATORROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.OPERATORROLE(&_L1BridgeRegistryV12.CallOpts)
}

// PAUSEROLE is a free data retrieval call binding the contract method 0x389ed267.
//
// Solidity: function PAUSE_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) PAUSEROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "PAUSE_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// PAUSEROLE is a free data retrieval call binding the contract method 0x389ed267.
//
// Solidity: function PAUSE_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) PAUSEROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.PAUSEROLE(&_L1BridgeRegistryV12.CallOpts)
}

// PAUSEROLE is a free data retrieval call binding the contract method 0x389ed267.
//
// Solidity: function PAUSE_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) PAUSEROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.PAUSEROLE(&_L1BridgeRegistryV12.CallOpts)
}

// REGISTRANTROLE is a free data retrieval call binding the contract method 0x6f5b142b.
//
// Solidity: function REGISTRANT_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) REGISTRANTROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "REGISTRANT_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// REGISTRANTROLE is a free data retrieval call binding the contract method 0x6f5b142b.
//
// Solidity: function REGISTRANT_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) REGISTRANTROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.REGISTRANTROLE(&_L1BridgeRegistryV12.CallOpts)
}

// REGISTRANTROLE is a free data retrieval call binding the contract method 0x6f5b142b.
//
// Solidity: function REGISTRANT_ROLE() view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) REGISTRANTROLE() ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.REGISTRANTROLE(&_L1BridgeRegistryV12.CallOpts)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) AliveImplementation(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "aliveImplementation", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) AliveImplementation(arg0 common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.AliveImplementation(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.AliveImplementation(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// AvailableForRegistration is a free data retrieval call binding the contract method 0xc87957e7.
//
// Solidity: function availableForRegistration(address rollupConfig, uint8 _type) view returns(bool valid)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) AvailableForRegistration(opts *bind.CallOpts, rollupConfig common.Address, _type uint8) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "availableForRegistration", rollupConfig, _type)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AvailableForRegistration is a free data retrieval call binding the contract method 0xc87957e7.
//
// Solidity: function availableForRegistration(address rollupConfig, uint8 _type) view returns(bool valid)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) AvailableForRegistration(rollupConfig common.Address, _type uint8) (bool, error) {
	return _L1BridgeRegistryV12.Contract.AvailableForRegistration(&_L1BridgeRegistryV12.CallOpts, rollupConfig, _type)
}

// AvailableForRegistration is a free data retrieval call binding the contract method 0xc87957e7.
//
// Solidity: function availableForRegistration(address rollupConfig, uint8 _type) view returns(bool valid)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) AvailableForRegistration(rollupConfig common.Address, _type uint8) (bool, error) {
	return _L1BridgeRegistryV12.Contract.AvailableForRegistration(&_L1BridgeRegistryV12.CallOpts, rollupConfig, _type)
}

// DisputeGameFactory is a free data retrieval call binding the contract method 0x935fae57.
//
// Solidity: function disputeGameFactory(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) DisputeGameFactory(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "disputeGameFactory", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// DisputeGameFactory is a free data retrieval call binding the contract method 0x935fae57.
//
// Solidity: function disputeGameFactory(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) DisputeGameFactory(arg0 common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.DisputeGameFactory(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// DisputeGameFactory is a free data retrieval call binding the contract method 0x935fae57.
//
// Solidity: function disputeGameFactory(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) DisputeGameFactory(arg0 common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.DisputeGameFactory(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.GetRoleAdmin(&_L1BridgeRegistryV12.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _L1BridgeRegistryV12.Contract.GetRoleAdmin(&_L1BridgeRegistryV12.CallOpts, role)
}

// GetRollupInfo is a free data retrieval call binding the contract method 0xf5e9b26b.
//
// Solidity: function getRollupInfo(address rollupConfig) view returns(uint8 type_, address l2TON_, bool rejectedSeigs_, bool rejectedL2Deposit_, string name_)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) GetRollupInfo(opts *bind.CallOpts, rollupConfig common.Address) (struct {
	Type              uint8
	L2TON             common.Address
	RejectedSeigs     bool
	RejectedL2Deposit bool
	Name              string
}, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "getRollupInfo", rollupConfig)

	outstruct := new(struct {
		Type              uint8
		L2TON             common.Address
		RejectedSeigs     bool
		RejectedL2Deposit bool
		Name              string
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Type = *abi.ConvertType(out[0], new(uint8)).(*uint8)
	outstruct.L2TON = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	outstruct.RejectedSeigs = *abi.ConvertType(out[2], new(bool)).(*bool)
	outstruct.RejectedL2Deposit = *abi.ConvertType(out[3], new(bool)).(*bool)
	outstruct.Name = *abi.ConvertType(out[4], new(string)).(*string)

	return *outstruct, err

}

// GetRollupInfo is a free data retrieval call binding the contract method 0xf5e9b26b.
//
// Solidity: function getRollupInfo(address rollupConfig) view returns(uint8 type_, address l2TON_, bool rejectedSeigs_, bool rejectedL2Deposit_, string name_)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) GetRollupInfo(rollupConfig common.Address) (struct {
	Type              uint8
	L2TON             common.Address
	RejectedSeigs     bool
	RejectedL2Deposit bool
	Name              string
}, error) {
	return _L1BridgeRegistryV12.Contract.GetRollupInfo(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// GetRollupInfo is a free data retrieval call binding the contract method 0xf5e9b26b.
//
// Solidity: function getRollupInfo(address rollupConfig) view returns(uint8 type_, address l2TON_, bool rejectedSeigs_, bool rejectedL2Deposit_, string name_)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) GetRollupInfo(rollupConfig common.Address) (struct {
	Type              uint8
	L2TON             common.Address
	RejectedSeigs     bool
	RejectedL2Deposit bool
	Name              string
}, error) {
	return _L1BridgeRegistryV12.Contract.GetRollupInfo(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.HasRole(&_L1BridgeRegistryV12.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.HasRole(&_L1BridgeRegistryV12.CallOpts, role, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) IsAdmin(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "isAdmin", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) IsAdmin(account common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsAdmin(&_L1BridgeRegistryV12.CallOpts, account)
}

// IsAdmin is a free data retrieval call binding the contract method 0x24d7806c.
//
// Solidity: function isAdmin(address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) IsAdmin(account common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsAdmin(&_L1BridgeRegistryV12.CallOpts, account)
}

// IsManager is a free data retrieval call binding the contract method 0xf3ae2415.
//
// Solidity: function isManager(address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) IsManager(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "isManager", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsManager is a free data retrieval call binding the contract method 0xf3ae2415.
//
// Solidity: function isManager(address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) IsManager(account common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsManager(&_L1BridgeRegistryV12.CallOpts, account)
}

// IsManager is a free data retrieval call binding the contract method 0xf3ae2415.
//
// Solidity: function isManager(address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) IsManager(account common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsManager(&_L1BridgeRegistryV12.CallOpts, account)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) IsOwner(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "isOwner")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) IsOwner() (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsOwner(&_L1BridgeRegistryV12.CallOpts)
}

// IsOwner is a free data retrieval call binding the contract method 0x8f32d59b.
//
// Solidity: function isOwner() view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) IsOwner() (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsOwner(&_L1BridgeRegistryV12.CallOpts)
}

// IsRegistrant is a free data retrieval call binding the contract method 0x86ad05b6.
//
// Solidity: function isRegistrant(address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) IsRegistrant(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "isRegistrant", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsRegistrant is a free data retrieval call binding the contract method 0x86ad05b6.
//
// Solidity: function isRegistrant(address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) IsRegistrant(account common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsRegistrant(&_L1BridgeRegistryV12.CallOpts, account)
}

// IsRegistrant is a free data retrieval call binding the contract method 0x86ad05b6.
//
// Solidity: function isRegistrant(address account) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) IsRegistrant(account common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsRegistrant(&_L1BridgeRegistryV12.CallOpts, account)
}

// IsRejectedL2Deposit is a free data retrieval call binding the contract method 0xe65906e0.
//
// Solidity: function isRejectedL2Deposit(address rollupConfig) view returns(bool rejectedL2Deposit)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) IsRejectedL2Deposit(opts *bind.CallOpts, rollupConfig common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "isRejectedL2Deposit", rollupConfig)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsRejectedL2Deposit is a free data retrieval call binding the contract method 0xe65906e0.
//
// Solidity: function isRejectedL2Deposit(address rollupConfig) view returns(bool rejectedL2Deposit)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) IsRejectedL2Deposit(rollupConfig common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsRejectedL2Deposit(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// IsRejectedL2Deposit is a free data retrieval call binding the contract method 0xe65906e0.
//
// Solidity: function isRejectedL2Deposit(address rollupConfig) view returns(bool rejectedL2Deposit)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) IsRejectedL2Deposit(rollupConfig common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsRejectedL2Deposit(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// IsRejectedSeigs is a free data retrieval call binding the contract method 0x88462d07.
//
// Solidity: function isRejectedSeigs(address rollupConfig) view returns(bool rejectedSeigs)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) IsRejectedSeigs(opts *bind.CallOpts, rollupConfig common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "isRejectedSeigs", rollupConfig)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsRejectedSeigs is a free data retrieval call binding the contract method 0x88462d07.
//
// Solidity: function isRejectedSeigs(address rollupConfig) view returns(bool rejectedSeigs)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) IsRejectedSeigs(rollupConfig common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsRejectedSeigs(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// IsRejectedSeigs is a free data retrieval call binding the contract method 0x88462d07.
//
// Solidity: function isRejectedSeigs(address rollupConfig) view returns(bool rejectedSeigs)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) IsRejectedSeigs(rollupConfig common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.IsRejectedSeigs(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// L1Bridge is a free data retrieval call binding the contract method 0xb30347c0.
//
// Solidity: function l1Bridge(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) L1Bridge(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "l1Bridge", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// L1Bridge is a free data retrieval call binding the contract method 0xb30347c0.
//
// Solidity: function l1Bridge(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) L1Bridge(arg0 common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.L1Bridge(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// L1Bridge is a free data retrieval call binding the contract method 0xb30347c0.
//
// Solidity: function l1Bridge(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) L1Bridge(arg0 common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.L1Bridge(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// L2TON is a free data retrieval call binding the contract method 0x4b7aa5d4.
//
// Solidity: function l2TON(address rollupConfig) view returns(address l2TonAddress)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) L2TON(opts *bind.CallOpts, rollupConfig common.Address) (common.Address, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "l2TON", rollupConfig)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// L2TON is a free data retrieval call binding the contract method 0x4b7aa5d4.
//
// Solidity: function l2TON(address rollupConfig) view returns(address l2TonAddress)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) L2TON(rollupConfig common.Address) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.L2TON(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// L2TON is a free data retrieval call binding the contract method 0x4b7aa5d4.
//
// Solidity: function l2TON(address rollupConfig) view returns(address l2TonAddress)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) L2TON(rollupConfig common.Address) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.L2TON(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) Layer2Manager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "layer2Manager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) Layer2Manager() (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.Layer2Manager(&_L1BridgeRegistryV12.CallOpts)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) Layer2Manager() (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.Layer2Manager(&_L1BridgeRegistryV12.CallOpts)
}

// Layer2TVL is a free data retrieval call binding the contract method 0xc81ae6db.
//
// Solidity: function layer2TVL(address rollupConfig) view returns(uint256 amount)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) Layer2TVL(opts *bind.CallOpts, rollupConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "layer2TVL", rollupConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Layer2TVL is a free data retrieval call binding the contract method 0xc81ae6db.
//
// Solidity: function layer2TVL(address rollupConfig) view returns(uint256 amount)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) Layer2TVL(rollupConfig common.Address) (*big.Int, error) {
	return _L1BridgeRegistryV12.Contract.Layer2TVL(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// Layer2TVL is a free data retrieval call binding the contract method 0xc81ae6db.
//
// Solidity: function layer2TVL(address rollupConfig) view returns(uint256 amount)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) Layer2TVL(rollupConfig common.Address) (*big.Int, error) {
	return _L1BridgeRegistryV12.Contract.Layer2TVL(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) PauseProxy(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "pauseProxy")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) PauseProxy() (bool, error) {
	return _L1BridgeRegistryV12.Contract.PauseProxy(&_L1BridgeRegistryV12.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) PauseProxy() (bool, error) {
	return _L1BridgeRegistryV12.Contract.PauseProxy(&_L1BridgeRegistryV12.CallOpts)
}

// Portal is a free data retrieval call binding the contract method 0xa2cc0979.
//
// Solidity: function portal(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) Portal(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "portal", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Portal is a free data retrieval call binding the contract method 0xa2cc0979.
//
// Solidity: function portal(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) Portal(arg0 common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.Portal(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// Portal is a free data retrieval call binding the contract method 0xa2cc0979.
//
// Solidity: function portal(address ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) Portal(arg0 common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.Portal(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) ProxyImplementation(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "proxyImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.ProxyImplementation(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.ProxyImplementation(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// RegisteredNames is a free data retrieval call binding the contract method 0x25b9535f.
//
// Solidity: function registeredNames(bytes32 ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) RegisteredNames(opts *bind.CallOpts, arg0 [32]byte) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "registeredNames", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// RegisteredNames is a free data retrieval call binding the contract method 0x25b9535f.
//
// Solidity: function registeredNames(bytes32 ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RegisteredNames(arg0 [32]byte) (bool, error) {
	return _L1BridgeRegistryV12.Contract.RegisteredNames(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// RegisteredNames is a free data retrieval call binding the contract method 0x25b9535f.
//
// Solidity: function registeredNames(bytes32 ) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) RegisteredNames(arg0 [32]byte) (bool, error) {
	return _L1BridgeRegistryV12.Contract.RegisteredNames(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// RejectRollupConfig is a free data retrieval call binding the contract method 0x2977c31f.
//
// Solidity: function rejectRollupConfig(address rollupConfig) view returns(bool rejectedSeigs)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) RejectRollupConfig(opts *bind.CallOpts, rollupConfig common.Address) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "rejectRollupConfig", rollupConfig)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// RejectRollupConfig is a free data retrieval call binding the contract method 0x2977c31f.
//
// Solidity: function rejectRollupConfig(address rollupConfig) view returns(bool rejectedSeigs)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RejectRollupConfig(rollupConfig common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.RejectRollupConfig(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// RejectRollupConfig is a free data retrieval call binding the contract method 0x2977c31f.
//
// Solidity: function rejectRollupConfig(address rollupConfig) view returns(bool rejectedSeigs)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) RejectRollupConfig(rollupConfig common.Address) (bool, error) {
	return _L1BridgeRegistryV12.Contract.RejectRollupConfig(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// RollupConfigWithDisputeGameFactory is a free data retrieval call binding the contract method 0xebbbfdb5.
//
// Solidity: function rollupConfigWithDisputeGameFactory(address ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) RollupConfigWithDisputeGameFactory(opts *bind.CallOpts, arg0 common.Address) (common.Address, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "rollupConfigWithDisputeGameFactory", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// RollupConfigWithDisputeGameFactory is a free data retrieval call binding the contract method 0xebbbfdb5.
//
// Solidity: function rollupConfigWithDisputeGameFactory(address ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RollupConfigWithDisputeGameFactory(arg0 common.Address) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.RollupConfigWithDisputeGameFactory(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// RollupConfigWithDisputeGameFactory is a free data retrieval call binding the contract method 0xebbbfdb5.
//
// Solidity: function rollupConfigWithDisputeGameFactory(address ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) RollupConfigWithDisputeGameFactory(arg0 common.Address) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.RollupConfigWithDisputeGameFactory(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// RollupConfigWithPortal is a free data retrieval call binding the contract method 0x3cb731d6.
//
// Solidity: function rollupConfigWithPortal(address ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) RollupConfigWithPortal(opts *bind.CallOpts, arg0 common.Address) (common.Address, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "rollupConfigWithPortal", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// RollupConfigWithPortal is a free data retrieval call binding the contract method 0x3cb731d6.
//
// Solidity: function rollupConfigWithPortal(address ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RollupConfigWithPortal(arg0 common.Address) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.RollupConfigWithPortal(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// RollupConfigWithPortal is a free data retrieval call binding the contract method 0x3cb731d6.
//
// Solidity: function rollupConfigWithPortal(address ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) RollupConfigWithPortal(arg0 common.Address) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.RollupConfigWithPortal(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// RollupInfo is a free data retrieval call binding the contract method 0xd3c215d8.
//
// Solidity: function rollupInfo(address ) view returns(uint8 rollupType, address l2TON, bool rejectedSeigs, bool rejectedL2Deposit, string name)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) RollupInfo(opts *bind.CallOpts, arg0 common.Address) (struct {
	RollupType        uint8
	L2TON             common.Address
	RejectedSeigs     bool
	RejectedL2Deposit bool
	Name              string
}, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "rollupInfo", arg0)

	outstruct := new(struct {
		RollupType        uint8
		L2TON             common.Address
		RejectedSeigs     bool
		RejectedL2Deposit bool
		Name              string
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.RollupType = *abi.ConvertType(out[0], new(uint8)).(*uint8)
	outstruct.L2TON = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	outstruct.RejectedSeigs = *abi.ConvertType(out[2], new(bool)).(*bool)
	outstruct.RejectedL2Deposit = *abi.ConvertType(out[3], new(bool)).(*bool)
	outstruct.Name = *abi.ConvertType(out[4], new(string)).(*string)

	return *outstruct, err

}

// RollupInfo is a free data retrieval call binding the contract method 0xd3c215d8.
//
// Solidity: function rollupInfo(address ) view returns(uint8 rollupType, address l2TON, bool rejectedSeigs, bool rejectedL2Deposit, string name)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RollupInfo(arg0 common.Address) (struct {
	RollupType        uint8
	L2TON             common.Address
	RejectedSeigs     bool
	RejectedL2Deposit bool
	Name              string
}, error) {
	return _L1BridgeRegistryV12.Contract.RollupInfo(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// RollupInfo is a free data retrieval call binding the contract method 0xd3c215d8.
//
// Solidity: function rollupInfo(address ) view returns(uint8 rollupType, address l2TON, bool rejectedSeigs, bool rejectedL2Deposit, string name)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) RollupInfo(arg0 common.Address) (struct {
	RollupType        uint8
	L2TON             common.Address
	RejectedSeigs     bool
	RejectedL2Deposit bool
	Name              string
}, error) {
	return _L1BridgeRegistryV12.Contract.RollupInfo(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// RollupType is a free data retrieval call binding the contract method 0x391e3b37.
//
// Solidity: function rollupType(address rollupConfig) view returns(uint8 rollupType_)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) RollupType(opts *bind.CallOpts, rollupConfig common.Address) (uint8, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "rollupType", rollupConfig)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// RollupType is a free data retrieval call binding the contract method 0x391e3b37.
//
// Solidity: function rollupType(address rollupConfig) view returns(uint8 rollupType_)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RollupType(rollupConfig common.Address) (uint8, error) {
	return _L1BridgeRegistryV12.Contract.RollupType(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// RollupType is a free data retrieval call binding the contract method 0x391e3b37.
//
// Solidity: function rollupType(address rollupConfig) view returns(uint8 rollupType_)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) RollupType(rollupConfig common.Address) (uint8, error) {
	return _L1BridgeRegistryV12.Contract.RollupType(&_L1BridgeRegistryV12.CallOpts, rollupConfig)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) SeigManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "seigManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) SeigManager() (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.SeigManager(&_L1BridgeRegistryV12.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) SeigManager() (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.SeigManager(&_L1BridgeRegistryV12.CallOpts)
}

// SeigniorageCommittee is a free data retrieval call binding the contract method 0x35583e6c.
//
// Solidity: function seigniorageCommittee() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) SeigniorageCommittee(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "seigniorageCommittee")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SeigniorageCommittee is a free data retrieval call binding the contract method 0x35583e6c.
//
// Solidity: function seigniorageCommittee() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) SeigniorageCommittee() (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.SeigniorageCommittee(&_L1BridgeRegistryV12.CallOpts)
}

// SeigniorageCommittee is a free data retrieval call binding the contract method 0x35583e6c.
//
// Solidity: function seigniorageCommittee() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) SeigniorageCommittee() (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.SeigniorageCommittee(&_L1BridgeRegistryV12.CallOpts)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) SelectorImplementation(opts *bind.CallOpts, arg0 [4]byte) (common.Address, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "selectorImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.SelectorImplementation(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.SelectorImplementation(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _L1BridgeRegistryV12.Contract.SupportsInterface(&_L1BridgeRegistryV12.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _L1BridgeRegistryV12.Contract.SupportsInterface(&_L1BridgeRegistryV12.CallOpts, interfaceId)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) Ton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "ton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) Ton() (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.Ton(&_L1BridgeRegistryV12.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) Ton() (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.Ton(&_L1BridgeRegistryV12.CallOpts)
}

// TypeRegistrant is a free data retrieval call binding the contract method 0xc2b4d5fc.
//
// Solidity: function typeRegistrant(uint8 ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Caller) TypeRegistrant(opts *bind.CallOpts, arg0 uint8) (common.Address, error) {
	var out []interface{}
	err := _L1BridgeRegistryV12.contract.Call(opts, &out, "typeRegistrant", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// TypeRegistrant is a free data retrieval call binding the contract method 0xc2b4d5fc.
//
// Solidity: function typeRegistrant(uint8 ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) TypeRegistrant(arg0 uint8) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.TypeRegistrant(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// TypeRegistrant is a free data retrieval call binding the contract method 0xc2b4d5fc.
//
// Solidity: function typeRegistrant(uint8 ) view returns(address)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12CallerSession) TypeRegistrant(arg0 uint8) (common.Address, error) {
	return _L1BridgeRegistryV12.Contract.TypeRegistrant(&_L1BridgeRegistryV12.CallOpts, arg0)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) AddAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "addAdmin", account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.AddAdmin(&_L1BridgeRegistryV12.TransactOpts, account)
}

// AddAdmin is a paid mutator transaction binding the contract method 0x70480275.
//
// Solidity: function addAdmin(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) AddAdmin(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.AddAdmin(&_L1BridgeRegistryV12.TransactOpts, account)
}

// AddManager is a paid mutator transaction binding the contract method 0x2d06177a.
//
// Solidity: function addManager(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) AddManager(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "addManager", account)
}

// AddManager is a paid mutator transaction binding the contract method 0x2d06177a.
//
// Solidity: function addManager(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) AddManager(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.AddManager(&_L1BridgeRegistryV12.TransactOpts, account)
}

// AddManager is a paid mutator transaction binding the contract method 0x2d06177a.
//
// Solidity: function addManager(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) AddManager(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.AddManager(&_L1BridgeRegistryV12.TransactOpts, account)
}

// AddRegistrant is a paid mutator transaction binding the contract method 0xbbfcfc1e.
//
// Solidity: function addRegistrant(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) AddRegistrant(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "addRegistrant", account)
}

// AddRegistrant is a paid mutator transaction binding the contract method 0xbbfcfc1e.
//
// Solidity: function addRegistrant(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) AddRegistrant(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.AddRegistrant(&_L1BridgeRegistryV12.TransactOpts, account)
}

// AddRegistrant is a paid mutator transaction binding the contract method 0xbbfcfc1e.
//
// Solidity: function addRegistrant(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) AddRegistrant(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.AddRegistrant(&_L1BridgeRegistryV12.TransactOpts, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.GrantRole(&_L1BridgeRegistryV12.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.GrantRole(&_L1BridgeRegistryV12.TransactOpts, role, account)
}

// RegisterRollupConfig is a paid mutator transaction binding the contract method 0x1d4c9c88.
//
// Solidity: function registerRollupConfig(address rollupConfig, uint8 _type, address _l2TON, string _name) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RegisterRollupConfig(opts *bind.TransactOpts, rollupConfig common.Address, _type uint8, _l2TON common.Address, _name string) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "registerRollupConfig", rollupConfig, _type, _l2TON, _name)
}

// RegisterRollupConfig is a paid mutator transaction binding the contract method 0x1d4c9c88.
//
// Solidity: function registerRollupConfig(address rollupConfig, uint8 _type, address _l2TON, string _name) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RegisterRollupConfig(rollupConfig common.Address, _type uint8, _l2TON common.Address, _name string) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfig(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON, _name)
}

// RegisterRollupConfig is a paid mutator transaction binding the contract method 0x1d4c9c88.
//
// Solidity: function registerRollupConfig(address rollupConfig, uint8 _type, address _l2TON, string _name) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RegisterRollupConfig(rollupConfig common.Address, _type uint8, _l2TON common.Address, _name string) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfig(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON, _name)
}

// RegisterRollupConfig0 is a paid mutator transaction binding the contract method 0x6e91948d.
//
// Solidity: function registerRollupConfig(address rollupConfig, uint8 _type, address _l2TON) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RegisterRollupConfig0(opts *bind.TransactOpts, rollupConfig common.Address, _type uint8, _l2TON common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "registerRollupConfig0", rollupConfig, _type, _l2TON)
}

// RegisterRollupConfig0 is a paid mutator transaction binding the contract method 0x6e91948d.
//
// Solidity: function registerRollupConfig(address rollupConfig, uint8 _type, address _l2TON) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RegisterRollupConfig0(rollupConfig common.Address, _type uint8, _l2TON common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfig0(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON)
}

// RegisterRollupConfig0 is a paid mutator transaction binding the contract method 0x6e91948d.
//
// Solidity: function registerRollupConfig(address rollupConfig, uint8 _type, address _l2TON) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RegisterRollupConfig0(rollupConfig common.Address, _type uint8, _l2TON common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfig0(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON)
}

// RegisterRollupConfigByManager is a paid mutator transaction binding the contract method 0x2f02c3e0.
//
// Solidity: function registerRollupConfigByManager(address rollupConfig, uint8 _type, address _l2TON) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RegisterRollupConfigByManager(opts *bind.TransactOpts, rollupConfig common.Address, _type uint8, _l2TON common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "registerRollupConfigByManager", rollupConfig, _type, _l2TON)
}

// RegisterRollupConfigByManager is a paid mutator transaction binding the contract method 0x2f02c3e0.
//
// Solidity: function registerRollupConfigByManager(address rollupConfig, uint8 _type, address _l2TON) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RegisterRollupConfigByManager(rollupConfig common.Address, _type uint8, _l2TON common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfigByManager(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON)
}

// RegisterRollupConfigByManager is a paid mutator transaction binding the contract method 0x2f02c3e0.
//
// Solidity: function registerRollupConfigByManager(address rollupConfig, uint8 _type, address _l2TON) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RegisterRollupConfigByManager(rollupConfig common.Address, _type uint8, _l2TON common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfigByManager(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON)
}

// RegisterRollupConfigByManager0 is a paid mutator transaction binding the contract method 0x3163b4b5.
//
// Solidity: function registerRollupConfigByManager(address rollupConfig, uint8 _type, address _l2TON, string _name) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RegisterRollupConfigByManager0(opts *bind.TransactOpts, rollupConfig common.Address, _type uint8, _l2TON common.Address, _name string) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "registerRollupConfigByManager0", rollupConfig, _type, _l2TON, _name)
}

// RegisterRollupConfigByManager0 is a paid mutator transaction binding the contract method 0x3163b4b5.
//
// Solidity: function registerRollupConfigByManager(address rollupConfig, uint8 _type, address _l2TON, string _name) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RegisterRollupConfigByManager0(rollupConfig common.Address, _type uint8, _l2TON common.Address, _name string) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfigByManager0(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON, _name)
}

// RegisterRollupConfigByManager0 is a paid mutator transaction binding the contract method 0x3163b4b5.
//
// Solidity: function registerRollupConfigByManager(address rollupConfig, uint8 _type, address _l2TON, string _name) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RegisterRollupConfigByManager0(rollupConfig common.Address, _type uint8, _l2TON common.Address, _name string) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfigByManager0(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON, _name)
}

// RegisterRollupConfigByType is a paid mutator transaction binding the contract method 0x24a04ae3.
//
// Solidity: function registerRollupConfigByType(address rollupConfig, uint8 _type, address _l2TON) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RegisterRollupConfigByType(opts *bind.TransactOpts, rollupConfig common.Address, _type uint8, _l2TON common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "registerRollupConfigByType", rollupConfig, _type, _l2TON)
}

// RegisterRollupConfigByType is a paid mutator transaction binding the contract method 0x24a04ae3.
//
// Solidity: function registerRollupConfigByType(address rollupConfig, uint8 _type, address _l2TON) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RegisterRollupConfigByType(rollupConfig common.Address, _type uint8, _l2TON common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfigByType(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON)
}

// RegisterRollupConfigByType is a paid mutator transaction binding the contract method 0x24a04ae3.
//
// Solidity: function registerRollupConfigByType(address rollupConfig, uint8 _type, address _l2TON) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RegisterRollupConfigByType(rollupConfig common.Address, _type uint8, _l2TON common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfigByType(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON)
}

// RegisterRollupConfigByType0 is a paid mutator transaction binding the contract method 0x6fec3a49.
//
// Solidity: function registerRollupConfigByType(address rollupConfig, uint8 _type, address _l2TON, string _name) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RegisterRollupConfigByType0(opts *bind.TransactOpts, rollupConfig common.Address, _type uint8, _l2TON common.Address, _name string) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "registerRollupConfigByType0", rollupConfig, _type, _l2TON, _name)
}

// RegisterRollupConfigByType0 is a paid mutator transaction binding the contract method 0x6fec3a49.
//
// Solidity: function registerRollupConfigByType(address rollupConfig, uint8 _type, address _l2TON, string _name) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RegisterRollupConfigByType0(rollupConfig common.Address, _type uint8, _l2TON common.Address, _name string) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfigByType0(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON, _name)
}

// RegisterRollupConfigByType0 is a paid mutator transaction binding the contract method 0x6fec3a49.
//
// Solidity: function registerRollupConfigByType(address rollupConfig, uint8 _type, address _l2TON, string _name) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RegisterRollupConfigByType0(rollupConfig common.Address, _type uint8, _l2TON common.Address, _name string) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RegisterRollupConfigByType0(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, _type, _l2TON, _name)
}

// RejectCandidateAddOn is a paid mutator transaction binding the contract method 0x4b49264c.
//
// Solidity: function rejectCandidateAddOn(address rollupConfig) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RejectCandidateAddOn(opts *bind.TransactOpts, rollupConfig common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "rejectCandidateAddOn", rollupConfig)
}

// RejectCandidateAddOn is a paid mutator transaction binding the contract method 0x4b49264c.
//
// Solidity: function rejectCandidateAddOn(address rollupConfig) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RejectCandidateAddOn(rollupConfig common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RejectCandidateAddOn(&_L1BridgeRegistryV12.TransactOpts, rollupConfig)
}

// RejectCandidateAddOn is a paid mutator transaction binding the contract method 0x4b49264c.
//
// Solidity: function rejectCandidateAddOn(address rollupConfig) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RejectCandidateAddOn(rollupConfig common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RejectCandidateAddOn(&_L1BridgeRegistryV12.TransactOpts, rollupConfig)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RemoveAdmin(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "removeAdmin", account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RemoveAdmin(&_L1BridgeRegistryV12.TransactOpts, account)
}

// RemoveAdmin is a paid mutator transaction binding the contract method 0x1785f53c.
//
// Solidity: function removeAdmin(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RemoveAdmin(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RemoveAdmin(&_L1BridgeRegistryV12.TransactOpts, account)
}

// RemoveManager is a paid mutator transaction binding the contract method 0xac18de43.
//
// Solidity: function removeManager(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RemoveManager(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "removeManager", account)
}

// RemoveManager is a paid mutator transaction binding the contract method 0xac18de43.
//
// Solidity: function removeManager(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RemoveManager(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RemoveManager(&_L1BridgeRegistryV12.TransactOpts, account)
}

// RemoveManager is a paid mutator transaction binding the contract method 0xac18de43.
//
// Solidity: function removeManager(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RemoveManager(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RemoveManager(&_L1BridgeRegistryV12.TransactOpts, account)
}

// RemoveRegistrant is a paid mutator transaction binding the contract method 0x8cfc9347.
//
// Solidity: function removeRegistrant(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RemoveRegistrant(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "removeRegistrant", account)
}

// RemoveRegistrant is a paid mutator transaction binding the contract method 0x8cfc9347.
//
// Solidity: function removeRegistrant(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RemoveRegistrant(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RemoveRegistrant(&_L1BridgeRegistryV12.TransactOpts, account)
}

// RemoveRegistrant is a paid mutator transaction binding the contract method 0x8cfc9347.
//
// Solidity: function removeRegistrant(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RemoveRegistrant(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RemoveRegistrant(&_L1BridgeRegistryV12.TransactOpts, account)
}

// RenounceManager is a paid mutator transaction binding the contract method 0xf8b91abe.
//
// Solidity: function renounceManager() returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RenounceManager(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "renounceManager")
}

// RenounceManager is a paid mutator transaction binding the contract method 0xf8b91abe.
//
// Solidity: function renounceManager() returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RenounceManager() (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RenounceManager(&_L1BridgeRegistryV12.TransactOpts)
}

// RenounceManager is a paid mutator transaction binding the contract method 0xf8b91abe.
//
// Solidity: function renounceManager() returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RenounceManager() (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RenounceManager(&_L1BridgeRegistryV12.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RenounceOwnership() (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RenounceOwnership(&_L1BridgeRegistryV12.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RenounceOwnership(&_L1BridgeRegistryV12.TransactOpts)
}

// RenounceRegistrant is a paid mutator transaction binding the contract method 0x35556fe3.
//
// Solidity: function renounceRegistrant() returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RenounceRegistrant(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "renounceRegistrant")
}

// RenounceRegistrant is a paid mutator transaction binding the contract method 0x35556fe3.
//
// Solidity: function renounceRegistrant() returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RenounceRegistrant() (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RenounceRegistrant(&_L1BridgeRegistryV12.TransactOpts)
}

// RenounceRegistrant is a paid mutator transaction binding the contract method 0x35556fe3.
//
// Solidity: function renounceRegistrant() returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RenounceRegistrant() (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RenounceRegistrant(&_L1BridgeRegistryV12.TransactOpts)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "renounceRole", role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RenounceRole(&_L1BridgeRegistryV12.TransactOpts, role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RenounceRole(&_L1BridgeRegistryV12.TransactOpts, role, account)
}

// RestoreCandidateAddOn is a paid mutator transaction binding the contract method 0x4fb1aee6.
//
// Solidity: function restoreCandidateAddOn(address rollupConfig, bool rejectedL2Deposit) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RestoreCandidateAddOn(opts *bind.TransactOpts, rollupConfig common.Address, rejectedL2Deposit bool) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "restoreCandidateAddOn", rollupConfig, rejectedL2Deposit)
}

// RestoreCandidateAddOn is a paid mutator transaction binding the contract method 0x4fb1aee6.
//
// Solidity: function restoreCandidateAddOn(address rollupConfig, bool rejectedL2Deposit) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RestoreCandidateAddOn(rollupConfig common.Address, rejectedL2Deposit bool) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RestoreCandidateAddOn(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, rejectedL2Deposit)
}

// RestoreCandidateAddOn is a paid mutator transaction binding the contract method 0x4fb1aee6.
//
// Solidity: function restoreCandidateAddOn(address rollupConfig, bool rejectedL2Deposit) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RestoreCandidateAddOn(rollupConfig common.Address, rejectedL2Deposit bool) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RestoreCandidateAddOn(&_L1BridgeRegistryV12.TransactOpts, rollupConfig, rejectedL2Deposit)
}

// RevokeManager is a paid mutator transaction binding the contract method 0x377e32e6.
//
// Solidity: function revokeManager(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RevokeManager(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "revokeManager", account)
}

// RevokeManager is a paid mutator transaction binding the contract method 0x377e32e6.
//
// Solidity: function revokeManager(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RevokeManager(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RevokeManager(&_L1BridgeRegistryV12.TransactOpts, account)
}

// RevokeManager is a paid mutator transaction binding the contract method 0x377e32e6.
//
// Solidity: function revokeManager(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RevokeManager(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RevokeManager(&_L1BridgeRegistryV12.TransactOpts, account)
}

// RevokeRegistrant is a paid mutator transaction binding the contract method 0xd00491c6.
//
// Solidity: function revokeRegistrant(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RevokeRegistrant(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "revokeRegistrant", account)
}

// RevokeRegistrant is a paid mutator transaction binding the contract method 0xd00491c6.
//
// Solidity: function revokeRegistrant(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RevokeRegistrant(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RevokeRegistrant(&_L1BridgeRegistryV12.TransactOpts, account)
}

// RevokeRegistrant is a paid mutator transaction binding the contract method 0xd00491c6.
//
// Solidity: function revokeRegistrant(address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RevokeRegistrant(account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RevokeRegistrant(&_L1BridgeRegistryV12.TransactOpts, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RevokeRole(&_L1BridgeRegistryV12.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.RevokeRole(&_L1BridgeRegistryV12.TransactOpts, role, account)
}

// SetAddresses is a paid mutator transaction binding the contract method 0x363bf964.
//
// Solidity: function setAddresses(address _layer2Manager, address _seigManager, address _ton) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) SetAddresses(opts *bind.TransactOpts, _layer2Manager common.Address, _seigManager common.Address, _ton common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "setAddresses", _layer2Manager, _seigManager, _ton)
}

// SetAddresses is a paid mutator transaction binding the contract method 0x363bf964.
//
// Solidity: function setAddresses(address _layer2Manager, address _seigManager, address _ton) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) SetAddresses(_layer2Manager common.Address, _seigManager common.Address, _ton common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.SetAddresses(&_L1BridgeRegistryV12.TransactOpts, _layer2Manager, _seigManager, _ton)
}

// SetAddresses is a paid mutator transaction binding the contract method 0x363bf964.
//
// Solidity: function setAddresses(address _layer2Manager, address _seigManager, address _ton) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) SetAddresses(_layer2Manager common.Address, _seigManager common.Address, _ton common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.SetAddresses(&_L1BridgeRegistryV12.TransactOpts, _layer2Manager, _seigManager, _ton)
}

// SetSeigniorageCommittee is a paid mutator transaction binding the contract method 0x1c564985.
//
// Solidity: function setSeigniorageCommittee(address _seigniorageCommittee) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) SetSeigniorageCommittee(opts *bind.TransactOpts, _seigniorageCommittee common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "setSeigniorageCommittee", _seigniorageCommittee)
}

// SetSeigniorageCommittee is a paid mutator transaction binding the contract method 0x1c564985.
//
// Solidity: function setSeigniorageCommittee(address _seigniorageCommittee) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) SetSeigniorageCommittee(_seigniorageCommittee common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.SetSeigniorageCommittee(&_L1BridgeRegistryV12.TransactOpts, _seigniorageCommittee)
}

// SetSeigniorageCommittee is a paid mutator transaction binding the contract method 0x1c564985.
//
// Solidity: function setSeigniorageCommittee(address _seigniorageCommittee) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) SetSeigniorageCommittee(_seigniorageCommittee common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.SetSeigniorageCommittee(&_L1BridgeRegistryV12.TransactOpts, _seigniorageCommittee)
}

// SetTypeRegistrant is a paid mutator transaction binding the contract method 0xfe3cca74.
//
// Solidity: function setTypeRegistrant(uint8 _type, address _registrant) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) SetTypeRegistrant(opts *bind.TransactOpts, _type uint8, _registrant common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "setTypeRegistrant", _type, _registrant)
}

// SetTypeRegistrant is a paid mutator transaction binding the contract method 0xfe3cca74.
//
// Solidity: function setTypeRegistrant(uint8 _type, address _registrant) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) SetTypeRegistrant(_type uint8, _registrant common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.SetTypeRegistrant(&_L1BridgeRegistryV12.TransactOpts, _type, _registrant)
}

// SetTypeRegistrant is a paid mutator transaction binding the contract method 0xfe3cca74.
//
// Solidity: function setTypeRegistrant(uint8 _type, address _registrant) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) SetTypeRegistrant(_type uint8, _registrant common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.SetTypeRegistrant(&_L1BridgeRegistryV12.TransactOpts, _type, _registrant)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) TransferAdmin(opts *bind.TransactOpts, newAdmin common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "transferAdmin", newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.TransferAdmin(&_L1BridgeRegistryV12.TransactOpts, newAdmin)
}

// TransferAdmin is a paid mutator transaction binding the contract method 0x75829def.
//
// Solidity: function transferAdmin(address newAdmin) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) TransferAdmin(newAdmin common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.TransferAdmin(&_L1BridgeRegistryV12.TransactOpts, newAdmin)
}

// UpgradeToType3 is a paid mutator transaction binding the contract method 0x16bf20a3.
//
// Solidity: function upgradeToType3(address rollupConfig) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Transactor) UpgradeToType3(opts *bind.TransactOpts, rollupConfig common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.contract.Transact(opts, "upgradeToType3", rollupConfig)
}

// UpgradeToType3 is a paid mutator transaction binding the contract method 0x16bf20a3.
//
// Solidity: function upgradeToType3(address rollupConfig) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Session) UpgradeToType3(rollupConfig common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.UpgradeToType3(&_L1BridgeRegistryV12.TransactOpts, rollupConfig)
}

// UpgradeToType3 is a paid mutator transaction binding the contract method 0x16bf20a3.
//
// Solidity: function upgradeToType3(address rollupConfig) returns()
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12TransactorSession) UpgradeToType3(rollupConfig common.Address) (*types.Transaction, error) {
	return _L1BridgeRegistryV12.Contract.UpgradeToType3(&_L1BridgeRegistryV12.TransactOpts, rollupConfig)
}

// L1BridgeRegistryV12AddedBridgeIterator is returned from FilterAddedBridge and is used to iterate over the raw logs and unpacked data for AddedBridge events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12AddedBridgeIterator struct {
	Event *L1BridgeRegistryV12AddedBridge // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12AddedBridgeIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12AddedBridge)
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
		it.Event = new(L1BridgeRegistryV12AddedBridge)
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
func (it *L1BridgeRegistryV12AddedBridgeIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12AddedBridgeIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12AddedBridge represents a AddedBridge event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12AddedBridge struct {
	RollupConfig common.Address
	Bridge       common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterAddedBridge is a free log retrieval operation binding the contract event 0x43251870f9292d3c0a61a78baa68c9f29d70ea868008a66d8afdb4d574f2c231.
//
// Solidity: event AddedBridge(address rollupConfig, address bridge)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterAddedBridge(opts *bind.FilterOpts) (*L1BridgeRegistryV12AddedBridgeIterator, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "AddedBridge")
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12AddedBridgeIterator{contract: _L1BridgeRegistryV12.contract, event: "AddedBridge", logs: logs, sub: sub}, nil
}

// WatchAddedBridge is a free log subscription operation binding the contract event 0x43251870f9292d3c0a61a78baa68c9f29d70ea868008a66d8afdb4d574f2c231.
//
// Solidity: event AddedBridge(address rollupConfig, address bridge)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchAddedBridge(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12AddedBridge) (event.Subscription, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "AddedBridge")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12AddedBridge)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "AddedBridge", log); err != nil {
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

// ParseAddedBridge is a log parse operation binding the contract event 0x43251870f9292d3c0a61a78baa68c9f29d70ea868008a66d8afdb4d574f2c231.
//
// Solidity: event AddedBridge(address rollupConfig, address bridge)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseAddedBridge(log types.Log) (*L1BridgeRegistryV12AddedBridge, error) {
	event := new(L1BridgeRegistryV12AddedBridge)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "AddedBridge", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12AddedDisputeGameFactoryIterator is returned from FilterAddedDisputeGameFactory and is used to iterate over the raw logs and unpacked data for AddedDisputeGameFactory events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12AddedDisputeGameFactoryIterator struct {
	Event *L1BridgeRegistryV12AddedDisputeGameFactory // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12AddedDisputeGameFactoryIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12AddedDisputeGameFactory)
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
		it.Event = new(L1BridgeRegistryV12AddedDisputeGameFactory)
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
func (it *L1BridgeRegistryV12AddedDisputeGameFactoryIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12AddedDisputeGameFactoryIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12AddedDisputeGameFactory represents a AddedDisputeGameFactory event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12AddedDisputeGameFactory struct {
	RollupConfig       common.Address
	DisputeGameFactory common.Address
	Raw                types.Log // Blockchain specific contextual infos
}

// FilterAddedDisputeGameFactory is a free log retrieval operation binding the contract event 0x3c9b8697ca510228b73978a625da9cbb8f30a3a20b3bc5117129fa976b81c7c6.
//
// Solidity: event AddedDisputeGameFactory(address rollupConfig, address disputeGameFactory)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterAddedDisputeGameFactory(opts *bind.FilterOpts) (*L1BridgeRegistryV12AddedDisputeGameFactoryIterator, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "AddedDisputeGameFactory")
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12AddedDisputeGameFactoryIterator{contract: _L1BridgeRegistryV12.contract, event: "AddedDisputeGameFactory", logs: logs, sub: sub}, nil
}

// WatchAddedDisputeGameFactory is a free log subscription operation binding the contract event 0x3c9b8697ca510228b73978a625da9cbb8f30a3a20b3bc5117129fa976b81c7c6.
//
// Solidity: event AddedDisputeGameFactory(address rollupConfig, address disputeGameFactory)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchAddedDisputeGameFactory(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12AddedDisputeGameFactory) (event.Subscription, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "AddedDisputeGameFactory")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12AddedDisputeGameFactory)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "AddedDisputeGameFactory", log); err != nil {
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

// ParseAddedDisputeGameFactory is a log parse operation binding the contract event 0x3c9b8697ca510228b73978a625da9cbb8f30a3a20b3bc5117129fa976b81c7c6.
//
// Solidity: event AddedDisputeGameFactory(address rollupConfig, address disputeGameFactory)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseAddedDisputeGameFactory(log types.Log) (*L1BridgeRegistryV12AddedDisputeGameFactory, error) {
	event := new(L1BridgeRegistryV12AddedDisputeGameFactory)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "AddedDisputeGameFactory", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12AddedPortalIterator is returned from FilterAddedPortal and is used to iterate over the raw logs and unpacked data for AddedPortal events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12AddedPortalIterator struct {
	Event *L1BridgeRegistryV12AddedPortal // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12AddedPortalIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12AddedPortal)
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
		it.Event = new(L1BridgeRegistryV12AddedPortal)
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
func (it *L1BridgeRegistryV12AddedPortalIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12AddedPortalIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12AddedPortal represents a AddedPortal event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12AddedPortal struct {
	RollupConfig common.Address
	Portal       common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterAddedPortal is a free log retrieval operation binding the contract event 0xf8bdba0336133f3634bf70846cd60e94e3b9dd7ce3a59c5831262cfdb636d006.
//
// Solidity: event AddedPortal(address rollupConfig, address portal)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterAddedPortal(opts *bind.FilterOpts) (*L1BridgeRegistryV12AddedPortalIterator, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "AddedPortal")
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12AddedPortalIterator{contract: _L1BridgeRegistryV12.contract, event: "AddedPortal", logs: logs, sub: sub}, nil
}

// WatchAddedPortal is a free log subscription operation binding the contract event 0xf8bdba0336133f3634bf70846cd60e94e3b9dd7ce3a59c5831262cfdb636d006.
//
// Solidity: event AddedPortal(address rollupConfig, address portal)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchAddedPortal(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12AddedPortal) (event.Subscription, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "AddedPortal")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12AddedPortal)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "AddedPortal", log); err != nil {
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

// ParseAddedPortal is a log parse operation binding the contract event 0xf8bdba0336133f3634bf70846cd60e94e3b9dd7ce3a59c5831262cfdb636d006.
//
// Solidity: event AddedPortal(address rollupConfig, address portal)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseAddedPortal(log types.Log) (*L1BridgeRegistryV12AddedPortal, error) {
	event := new(L1BridgeRegistryV12AddedPortal)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "AddedPortal", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12RegisteredRollupConfigIterator is returned from FilterRegisteredRollupConfig and is used to iterate over the raw logs and unpacked data for RegisteredRollupConfig events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RegisteredRollupConfigIterator struct {
	Event *L1BridgeRegistryV12RegisteredRollupConfig // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12RegisteredRollupConfigIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12RegisteredRollupConfig)
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
		it.Event = new(L1BridgeRegistryV12RegisteredRollupConfig)
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
func (it *L1BridgeRegistryV12RegisteredRollupConfigIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12RegisteredRollupConfigIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12RegisteredRollupConfig represents a RegisteredRollupConfig event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RegisteredRollupConfig struct {
	RollupConfig common.Address
	Type         uint8
	L2TON        common.Address
	Name         string
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterRegisteredRollupConfig is a free log retrieval operation binding the contract event 0x79025bb0223ed3a500c1098338b784302bcf993c87487625036460907a45939e.
//
// Solidity: event RegisteredRollupConfig(address rollupConfig, uint8 type_, address l2TON, string name)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterRegisteredRollupConfig(opts *bind.FilterOpts) (*L1BridgeRegistryV12RegisteredRollupConfigIterator, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "RegisteredRollupConfig")
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12RegisteredRollupConfigIterator{contract: _L1BridgeRegistryV12.contract, event: "RegisteredRollupConfig", logs: logs, sub: sub}, nil
}

// WatchRegisteredRollupConfig is a free log subscription operation binding the contract event 0x79025bb0223ed3a500c1098338b784302bcf993c87487625036460907a45939e.
//
// Solidity: event RegisteredRollupConfig(address rollupConfig, uint8 type_, address l2TON, string name)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchRegisteredRollupConfig(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12RegisteredRollupConfig) (event.Subscription, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "RegisteredRollupConfig")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12RegisteredRollupConfig)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RegisteredRollupConfig", log); err != nil {
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

// ParseRegisteredRollupConfig is a log parse operation binding the contract event 0x79025bb0223ed3a500c1098338b784302bcf993c87487625036460907a45939e.
//
// Solidity: event RegisteredRollupConfig(address rollupConfig, uint8 type_, address l2TON, string name)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseRegisteredRollupConfig(log types.Log) (*L1BridgeRegistryV12RegisteredRollupConfig, error) {
	event := new(L1BridgeRegistryV12RegisteredRollupConfig)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RegisteredRollupConfig", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12RejectedCandidateAddOnIterator is returned from FilterRejectedCandidateAddOn and is used to iterate over the raw logs and unpacked data for RejectedCandidateAddOn events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RejectedCandidateAddOnIterator struct {
	Event *L1BridgeRegistryV12RejectedCandidateAddOn // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12RejectedCandidateAddOnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12RejectedCandidateAddOn)
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
		it.Event = new(L1BridgeRegistryV12RejectedCandidateAddOn)
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
func (it *L1BridgeRegistryV12RejectedCandidateAddOnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12RejectedCandidateAddOnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12RejectedCandidateAddOn represents a RejectedCandidateAddOn event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RejectedCandidateAddOn struct {
	RollupConfig common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterRejectedCandidateAddOn is a free log retrieval operation binding the contract event 0x0d294c5651970c5fab6bc6f2c023263af93bc2c381b1dc76215156cc95ea675d.
//
// Solidity: event RejectedCandidateAddOn(address rollupConfig)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterRejectedCandidateAddOn(opts *bind.FilterOpts) (*L1BridgeRegistryV12RejectedCandidateAddOnIterator, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "RejectedCandidateAddOn")
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12RejectedCandidateAddOnIterator{contract: _L1BridgeRegistryV12.contract, event: "RejectedCandidateAddOn", logs: logs, sub: sub}, nil
}

// WatchRejectedCandidateAddOn is a free log subscription operation binding the contract event 0x0d294c5651970c5fab6bc6f2c023263af93bc2c381b1dc76215156cc95ea675d.
//
// Solidity: event RejectedCandidateAddOn(address rollupConfig)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchRejectedCandidateAddOn(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12RejectedCandidateAddOn) (event.Subscription, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "RejectedCandidateAddOn")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12RejectedCandidateAddOn)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RejectedCandidateAddOn", log); err != nil {
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

// ParseRejectedCandidateAddOn is a log parse operation binding the contract event 0x0d294c5651970c5fab6bc6f2c023263af93bc2c381b1dc76215156cc95ea675d.
//
// Solidity: event RejectedCandidateAddOn(address rollupConfig)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseRejectedCandidateAddOn(log types.Log) (*L1BridgeRegistryV12RejectedCandidateAddOn, error) {
	event := new(L1BridgeRegistryV12RejectedCandidateAddOn)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RejectedCandidateAddOn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12RestoredCandidateAddOnIterator is returned from FilterRestoredCandidateAddOn and is used to iterate over the raw logs and unpacked data for RestoredCandidateAddOn events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RestoredCandidateAddOnIterator struct {
	Event *L1BridgeRegistryV12RestoredCandidateAddOn // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12RestoredCandidateAddOnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12RestoredCandidateAddOn)
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
		it.Event = new(L1BridgeRegistryV12RestoredCandidateAddOn)
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
func (it *L1BridgeRegistryV12RestoredCandidateAddOnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12RestoredCandidateAddOnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12RestoredCandidateAddOn represents a RestoredCandidateAddOn event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RestoredCandidateAddOn struct {
	RollupConfig common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterRestoredCandidateAddOn is a free log retrieval operation binding the contract event 0xbc89b42e2b372c8e9e1d48bb5dc897d26927cbe07da9bff7d167d0dbef68e9b3.
//
// Solidity: event RestoredCandidateAddOn(address rollupConfig)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterRestoredCandidateAddOn(opts *bind.FilterOpts) (*L1BridgeRegistryV12RestoredCandidateAddOnIterator, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "RestoredCandidateAddOn")
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12RestoredCandidateAddOnIterator{contract: _L1BridgeRegistryV12.contract, event: "RestoredCandidateAddOn", logs: logs, sub: sub}, nil
}

// WatchRestoredCandidateAddOn is a free log subscription operation binding the contract event 0xbc89b42e2b372c8e9e1d48bb5dc897d26927cbe07da9bff7d167d0dbef68e9b3.
//
// Solidity: event RestoredCandidateAddOn(address rollupConfig)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchRestoredCandidateAddOn(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12RestoredCandidateAddOn) (event.Subscription, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "RestoredCandidateAddOn")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12RestoredCandidateAddOn)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RestoredCandidateAddOn", log); err != nil {
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

// ParseRestoredCandidateAddOn is a log parse operation binding the contract event 0xbc89b42e2b372c8e9e1d48bb5dc897d26927cbe07da9bff7d167d0dbef68e9b3.
//
// Solidity: event RestoredCandidateAddOn(address rollupConfig)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseRestoredCandidateAddOn(log types.Log) (*L1BridgeRegistryV12RestoredCandidateAddOn, error) {
	event := new(L1BridgeRegistryV12RestoredCandidateAddOn)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RestoredCandidateAddOn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12RoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RoleAdminChangedIterator struct {
	Event *L1BridgeRegistryV12RoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12RoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12RoleAdminChanged)
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
		it.Event = new(L1BridgeRegistryV12RoleAdminChanged)
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
func (it *L1BridgeRegistryV12RoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12RoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12RoleAdminChanged represents a RoleAdminChanged event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*L1BridgeRegistryV12RoleAdminChangedIterator, error) {

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

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12RoleAdminChangedIterator{contract: _L1BridgeRegistryV12.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12RoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12RoleAdminChanged)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseRoleAdminChanged(log types.Log) (*L1BridgeRegistryV12RoleAdminChanged, error) {
	event := new(L1BridgeRegistryV12RoleAdminChanged)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12RoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RoleGrantedIterator struct {
	Event *L1BridgeRegistryV12RoleGranted // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12RoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12RoleGranted)
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
		it.Event = new(L1BridgeRegistryV12RoleGranted)
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
func (it *L1BridgeRegistryV12RoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12RoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12RoleGranted represents a RoleGranted event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*L1BridgeRegistryV12RoleGrantedIterator, error) {

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

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12RoleGrantedIterator{contract: _L1BridgeRegistryV12.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12RoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12RoleGranted)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseRoleGranted(log types.Log) (*L1BridgeRegistryV12RoleGranted, error) {
	event := new(L1BridgeRegistryV12RoleGranted)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12RoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RoleRevokedIterator struct {
	Event *L1BridgeRegistryV12RoleRevoked // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12RoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12RoleRevoked)
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
		it.Event = new(L1BridgeRegistryV12RoleRevoked)
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
func (it *L1BridgeRegistryV12RoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12RoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12RoleRevoked represents a RoleRevoked event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12RoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*L1BridgeRegistryV12RoleRevokedIterator, error) {

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

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12RoleRevokedIterator{contract: _L1BridgeRegistryV12.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12RoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12RoleRevoked)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseRoleRevoked(log types.Log) (*L1BridgeRegistryV12RoleRevoked, error) {
	event := new(L1BridgeRegistryV12RoleRevoked)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12SetAddressesIterator is returned from FilterSetAddresses and is used to iterate over the raw logs and unpacked data for SetAddresses events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12SetAddressesIterator struct {
	Event *L1BridgeRegistryV12SetAddresses // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12SetAddressesIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12SetAddresses)
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
		it.Event = new(L1BridgeRegistryV12SetAddresses)
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
func (it *L1BridgeRegistryV12SetAddressesIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12SetAddressesIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12SetAddresses represents a SetAddresses event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12SetAddresses struct {
	Layer2Manager common.Address
	SeigManager   common.Address
	Ton           common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterSetAddresses is a free log retrieval operation binding the contract event 0xbbfb274df95bebde0669697bf0d15986b4ad73e11c495ae4e2d08d1bc5c90bad.
//
// Solidity: event SetAddresses(address _layer2Manager, address _seigManager, address _ton)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterSetAddresses(opts *bind.FilterOpts) (*L1BridgeRegistryV12SetAddressesIterator, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "SetAddresses")
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12SetAddressesIterator{contract: _L1BridgeRegistryV12.contract, event: "SetAddresses", logs: logs, sub: sub}, nil
}

// WatchSetAddresses is a free log subscription operation binding the contract event 0xbbfb274df95bebde0669697bf0d15986b4ad73e11c495ae4e2d08d1bc5c90bad.
//
// Solidity: event SetAddresses(address _layer2Manager, address _seigManager, address _ton)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchSetAddresses(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12SetAddresses) (event.Subscription, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "SetAddresses")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12SetAddresses)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "SetAddresses", log); err != nil {
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

// ParseSetAddresses is a log parse operation binding the contract event 0xbbfb274df95bebde0669697bf0d15986b4ad73e11c495ae4e2d08d1bc5c90bad.
//
// Solidity: event SetAddresses(address _layer2Manager, address _seigManager, address _ton)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseSetAddresses(log types.Log) (*L1BridgeRegistryV12SetAddresses, error) {
	event := new(L1BridgeRegistryV12SetAddresses)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "SetAddresses", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12SetBlockingL2DepositIterator is returned from FilterSetBlockingL2Deposit and is used to iterate over the raw logs and unpacked data for SetBlockingL2Deposit events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12SetBlockingL2DepositIterator struct {
	Event *L1BridgeRegistryV12SetBlockingL2Deposit // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12SetBlockingL2DepositIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12SetBlockingL2Deposit)
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
		it.Event = new(L1BridgeRegistryV12SetBlockingL2Deposit)
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
func (it *L1BridgeRegistryV12SetBlockingL2DepositIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12SetBlockingL2DepositIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12SetBlockingL2Deposit represents a SetBlockingL2Deposit event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12SetBlockingL2Deposit struct {
	RollupConfig      common.Address
	RejectedL2Deposit bool
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterSetBlockingL2Deposit is a free log retrieval operation binding the contract event 0x86092b164c4e590c975cbda3041ef6cb41f3b7b98257bd51fc1858a57d7d3486.
//
// Solidity: event SetBlockingL2Deposit(address rollupConfig, bool rejectedL2Deposit)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterSetBlockingL2Deposit(opts *bind.FilterOpts) (*L1BridgeRegistryV12SetBlockingL2DepositIterator, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "SetBlockingL2Deposit")
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12SetBlockingL2DepositIterator{contract: _L1BridgeRegistryV12.contract, event: "SetBlockingL2Deposit", logs: logs, sub: sub}, nil
}

// WatchSetBlockingL2Deposit is a free log subscription operation binding the contract event 0x86092b164c4e590c975cbda3041ef6cb41f3b7b98257bd51fc1858a57d7d3486.
//
// Solidity: event SetBlockingL2Deposit(address rollupConfig, bool rejectedL2Deposit)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchSetBlockingL2Deposit(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12SetBlockingL2Deposit) (event.Subscription, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "SetBlockingL2Deposit")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12SetBlockingL2Deposit)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "SetBlockingL2Deposit", log); err != nil {
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

// ParseSetBlockingL2Deposit is a log parse operation binding the contract event 0x86092b164c4e590c975cbda3041ef6cb41f3b7b98257bd51fc1858a57d7d3486.
//
// Solidity: event SetBlockingL2Deposit(address rollupConfig, bool rejectedL2Deposit)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseSetBlockingL2Deposit(log types.Log) (*L1BridgeRegistryV12SetBlockingL2Deposit, error) {
	event := new(L1BridgeRegistryV12SetBlockingL2Deposit)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "SetBlockingL2Deposit", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12SetSeigniorageCommitteeIterator is returned from FilterSetSeigniorageCommittee and is used to iterate over the raw logs and unpacked data for SetSeigniorageCommittee events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12SetSeigniorageCommitteeIterator struct {
	Event *L1BridgeRegistryV12SetSeigniorageCommittee // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12SetSeigniorageCommitteeIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12SetSeigniorageCommittee)
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
		it.Event = new(L1BridgeRegistryV12SetSeigniorageCommittee)
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
func (it *L1BridgeRegistryV12SetSeigniorageCommitteeIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12SetSeigniorageCommitteeIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12SetSeigniorageCommittee represents a SetSeigniorageCommittee event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12SetSeigniorageCommittee struct {
	SeigniorageCommittee common.Address
	Raw                  types.Log // Blockchain specific contextual infos
}

// FilterSetSeigniorageCommittee is a free log retrieval operation binding the contract event 0x1c7847585b331d5fb688c03d1dc8e73e13231744377f3b1e2f5c26e548c621c1.
//
// Solidity: event SetSeigniorageCommittee(address _seigniorageCommittee)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterSetSeigniorageCommittee(opts *bind.FilterOpts) (*L1BridgeRegistryV12SetSeigniorageCommitteeIterator, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "SetSeigniorageCommittee")
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12SetSeigniorageCommitteeIterator{contract: _L1BridgeRegistryV12.contract, event: "SetSeigniorageCommittee", logs: logs, sub: sub}, nil
}

// WatchSetSeigniorageCommittee is a free log subscription operation binding the contract event 0x1c7847585b331d5fb688c03d1dc8e73e13231744377f3b1e2f5c26e548c621c1.
//
// Solidity: event SetSeigniorageCommittee(address _seigniorageCommittee)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchSetSeigniorageCommittee(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12SetSeigniorageCommittee) (event.Subscription, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "SetSeigniorageCommittee")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12SetSeigniorageCommittee)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "SetSeigniorageCommittee", log); err != nil {
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

// ParseSetSeigniorageCommittee is a log parse operation binding the contract event 0x1c7847585b331d5fb688c03d1dc8e73e13231744377f3b1e2f5c26e548c621c1.
//
// Solidity: event SetSeigniorageCommittee(address _seigniorageCommittee)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseSetSeigniorageCommittee(log types.Log) (*L1BridgeRegistryV12SetSeigniorageCommittee, error) {
	event := new(L1BridgeRegistryV12SetSeigniorageCommittee)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "SetSeigniorageCommittee", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12TypeRegistrantSetIterator is returned from FilterTypeRegistrantSet and is used to iterate over the raw logs and unpacked data for TypeRegistrantSet events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12TypeRegistrantSetIterator struct {
	Event *L1BridgeRegistryV12TypeRegistrantSet // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12TypeRegistrantSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12TypeRegistrantSet)
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
		it.Event = new(L1BridgeRegistryV12TypeRegistrantSet)
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
func (it *L1BridgeRegistryV12TypeRegistrantSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12TypeRegistrantSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12TypeRegistrantSet represents a TypeRegistrantSet event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12TypeRegistrantSet struct {
	RollupType uint8
	Registrant common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterTypeRegistrantSet is a free log retrieval operation binding the contract event 0x5b08f1dcee4a3108c9cff08aa6ffa020e2e1454b49d4072a1358582f2c3e49fb.
//
// Solidity: event TypeRegistrantSet(uint8 indexed rollupType, address indexed registrant)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterTypeRegistrantSet(opts *bind.FilterOpts, rollupType []uint8, registrant []common.Address) (*L1BridgeRegistryV12TypeRegistrantSetIterator, error) {

	var rollupTypeRule []interface{}
	for _, rollupTypeItem := range rollupType {
		rollupTypeRule = append(rollupTypeRule, rollupTypeItem)
	}
	var registrantRule []interface{}
	for _, registrantItem := range registrant {
		registrantRule = append(registrantRule, registrantItem)
	}

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "TypeRegistrantSet", rollupTypeRule, registrantRule)
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12TypeRegistrantSetIterator{contract: _L1BridgeRegistryV12.contract, event: "TypeRegistrantSet", logs: logs, sub: sub}, nil
}

// WatchTypeRegistrantSet is a free log subscription operation binding the contract event 0x5b08f1dcee4a3108c9cff08aa6ffa020e2e1454b49d4072a1358582f2c3e49fb.
//
// Solidity: event TypeRegistrantSet(uint8 indexed rollupType, address indexed registrant)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchTypeRegistrantSet(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12TypeRegistrantSet, rollupType []uint8, registrant []common.Address) (event.Subscription, error) {

	var rollupTypeRule []interface{}
	for _, rollupTypeItem := range rollupType {
		rollupTypeRule = append(rollupTypeRule, rollupTypeItem)
	}
	var registrantRule []interface{}
	for _, registrantItem := range registrant {
		registrantRule = append(registrantRule, registrantItem)
	}

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "TypeRegistrantSet", rollupTypeRule, registrantRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12TypeRegistrantSet)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "TypeRegistrantSet", log); err != nil {
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

// ParseTypeRegistrantSet is a log parse operation binding the contract event 0x5b08f1dcee4a3108c9cff08aa6ffa020e2e1454b49d4072a1358582f2c3e49fb.
//
// Solidity: event TypeRegistrantSet(uint8 indexed rollupType, address indexed registrant)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseTypeRegistrantSet(log types.Log) (*L1BridgeRegistryV12TypeRegistrantSet, error) {
	event := new(L1BridgeRegistryV12TypeRegistrantSet)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "TypeRegistrantSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// L1BridgeRegistryV12UpgradedToType3Iterator is returned from FilterUpgradedToType3 and is used to iterate over the raw logs and unpacked data for UpgradedToType3 events raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12UpgradedToType3Iterator struct {
	Event *L1BridgeRegistryV12UpgradedToType3 // Event containing the contract specifics and raw log

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
func (it *L1BridgeRegistryV12UpgradedToType3Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(L1BridgeRegistryV12UpgradedToType3)
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
		it.Event = new(L1BridgeRegistryV12UpgradedToType3)
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
func (it *L1BridgeRegistryV12UpgradedToType3Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *L1BridgeRegistryV12UpgradedToType3Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// L1BridgeRegistryV12UpgradedToType3 represents a UpgradedToType3 event raised by the L1BridgeRegistryV12 contract.
type L1BridgeRegistryV12UpgradedToType3 struct {
	RollupConfig       common.Address
	PreviousType       uint8
	Portal             common.Address
	DisputeGameFactory common.Address
	Raw                types.Log // Blockchain specific contextual infos
}

// FilterUpgradedToType3 is a free log retrieval operation binding the contract event 0x34af3f27468cc2af45779565c78a86d5211cc0e460fc07a21eebea51f3ad54c9.
//
// Solidity: event UpgradedToType3(address rollupConfig, uint8 previousType, address portal, address disputeGameFactory)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) FilterUpgradedToType3(opts *bind.FilterOpts) (*L1BridgeRegistryV12UpgradedToType3Iterator, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.FilterLogs(opts, "UpgradedToType3")
	if err != nil {
		return nil, err
	}
	return &L1BridgeRegistryV12UpgradedToType3Iterator{contract: _L1BridgeRegistryV12.contract, event: "UpgradedToType3", logs: logs, sub: sub}, nil
}

// WatchUpgradedToType3 is a free log subscription operation binding the contract event 0x34af3f27468cc2af45779565c78a86d5211cc0e460fc07a21eebea51f3ad54c9.
//
// Solidity: event UpgradedToType3(address rollupConfig, uint8 previousType, address portal, address disputeGameFactory)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) WatchUpgradedToType3(opts *bind.WatchOpts, sink chan<- *L1BridgeRegistryV12UpgradedToType3) (event.Subscription, error) {

	logs, sub, err := _L1BridgeRegistryV12.contract.WatchLogs(opts, "UpgradedToType3")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(L1BridgeRegistryV12UpgradedToType3)
				if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "UpgradedToType3", log); err != nil {
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

// ParseUpgradedToType3 is a log parse operation binding the contract event 0x34af3f27468cc2af45779565c78a86d5211cc0e460fc07a21eebea51f3ad54c9.
//
// Solidity: event UpgradedToType3(address rollupConfig, uint8 previousType, address portal, address disputeGameFactory)
func (_L1BridgeRegistryV12 *L1BridgeRegistryV12Filterer) ParseUpgradedToType3(log types.Log) (*L1BridgeRegistryV12UpgradedToType3, error) {
	event := new(L1BridgeRegistryV12UpgradedToType3)
	if err := _L1BridgeRegistryV12.contract.UnpackLog(event, "UpgradedToType3", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
