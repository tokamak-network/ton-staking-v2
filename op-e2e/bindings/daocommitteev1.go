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

// StorageStateCommitteeCandidateInfo is an auto generated low-level Go binding around an user-defined struct.
type StorageStateCommitteeCandidateInfo struct {
	CandidateContract common.Address
	IndexMembers      *big.Int
	MemberJoinedTime  *big.Int
	RewardPeriod      *big.Int
	ClaimedTimestamp  *big.Int
}

// StorageStateCommitteeV2CandidateInfo2 is an auto generated low-level Go binding around an user-defined struct.
type StorageStateCommitteeV2CandidateInfo2 struct {
	CandidateContract common.Address
	NewCandidate      common.Address
	IndexMembers      *big.Int
	MemberJoinedTime  *big.Int
	RewardPeriod      *big.Int
	ClaimedTimestamp  *big.Int
}

// DAOCommitteeV1MetaData contains all meta data concerning the DAOCommitteeV1 contract.
var DAOCommitteeV1MetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"activityRewardPerSecond\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"agendaManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIDAOAgendaManager\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"aliveImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfOnCandidate\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfOnCandidateContract\",\"inputs\":[{\"name\":\"_candidateContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"blacklist\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"candidateAddOnFactory\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"candidateContract\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"candidateFactory\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractICandidateFactory\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"candidateInfos\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structStorageStateCommittee.CandidateInfo\",\"components\":[{\"name\":\"candidateContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"indexMembers\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"memberJoinedTime\",\"type\":\"uint128\",\"internalType\":\"uint128\"},{\"name\":\"rewardPeriod\",\"type\":\"uint128\",\"internalType\":\"uint128\"},{\"name\":\"claimedTimestamp\",\"type\":\"uint128\",\"internalType\":\"uint128\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"candidates\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"candidatesLength\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"castVote\",\"inputs\":[{\"name\":\"_agendaID\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_vote\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_comment\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeMember\",\"inputs\":[{\"name\":\"_memberIndex\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimActivityReward\",\"inputs\":[{\"name\":\"_receiver\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cooldown\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"cooldownTime\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"createCandidate\",\"inputs\":[{\"name\":\"_memo\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"createCandidateAddOn\",\"inputs\":[{\"name\":\"_memo\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"_operatorManagerAddress\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"createCandidateOwner\",\"inputs\":[{\"name\":\"_memo\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"_operatorAddress\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"currentAgendaStatus\",\"inputs\":[{\"name\":\"_agendaID\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"agendaResult\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"agendaStatus\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"daoVault\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIDAOVault\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"executeAgenda\",\"inputs\":[{\"name\":\"_agendaID\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getClaimableActivityReward\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getOldCandidateInfos\",\"inputs\":[{\"name\":\"_oldCandidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structStorageStateCommitteeV2.CandidateInfo2\",\"components\":[{\"name\":\"candidateContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newCandidate\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"indexMembers\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"memberJoinedTime\",\"type\":\"uint128\",\"internalType\":\"uint128\"},{\"name\":\"rewardPeriod\",\"type\":\"uint128\",\"internalType\":\"uint128\"},{\"name\":\"claimedTimestamp\",\"type\":\"uint128\",\"internalType\":\"uint128\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleMember\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleMemberCount\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isCandidate\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isExistCandidate\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isExist\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isMember\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2Manager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2Registry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractILayer2Registry\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxMember\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"members\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"onApprove\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"operatorAmountCheck\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"operatorAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"operatorCheck\",\"inputs\":[{\"name\":\"candidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"operatorAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseProxy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"privateLayer2\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxyImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"quorum\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"registerLayer2CandidateByOwner\",\"inputs\":[{\"name\":\"_operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_memo\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeFromBlacklist\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"retireMember\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"seigManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISeigManager\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"selectorImplementation\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setAgendaStatus\",\"inputs\":[{\"name\":\"_agendaID\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_status\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_result\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMemoOnCandidate\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_memo\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMemoOnCandidateContract\",\"inputs\":[{\"name\":\"_candidateContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_memo\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalSupplyOnCandidate\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"totalsupply\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalSupplyOnCandidateContract\",\"inputs\":[{\"name\":\"_candidateContract\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"totalsupply\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"updateSeigniorage\",\"inputs\":[{\"name\":\"_candidate\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"wton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"AgendaCreated\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"targets\",\"type\":\"address[]\",\"indexed\":false,\"internalType\":\"address[]\"},{\"name\":\"noticePeriodSeconds\",\"type\":\"uint128\",\"indexed\":false,\"internalType\":\"uint128\"},{\"name\":\"votingPeriodSeconds\",\"type\":\"uint128\",\"indexed\":false,\"internalType\":\"uint128\"},{\"name\":\"atomicExecute\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AgendaExecuted\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"target\",\"type\":\"address[]\",\"indexed\":false,\"internalType\":\"address[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AgendaVoteCasted\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"voting\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"comment\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CandidateContractCreated\",\"inputs\":[{\"name\":\"candidate\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"candidateContract\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"memo\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ChangedMember\",\"inputs\":[{\"name\":\"slotIndex\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"prevMember\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"newMember\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ChangedMemo\",\"inputs\":[{\"name\":\"candidateContract\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"newMemo\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ClaimedActivityReward\",\"inputs\":[{\"name\":\"candidate\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Layer2Registered\",\"inputs\":[{\"name\":\"candidate\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"candidateContract\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"memo\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MemberBlacklisted\",\"inputs\":[{\"name\":\"member\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ClaimTONError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ClaimWTONError\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CreateCandiateError\",\"inputs\":[{\"name\":\"x\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"PermissionError\",\"inputs\":[]}]",
}

// DAOCommitteeV1ABI is the input ABI used to generate the binding from.
// Deprecated: Use DAOCommitteeV1MetaData.ABI instead.
var DAOCommitteeV1ABI = DAOCommitteeV1MetaData.ABI

// DAOCommitteeV1 is an auto generated Go binding around an Ethereum contract.
type DAOCommitteeV1 struct {
	DAOCommitteeV1Caller     // Read-only binding to the contract
	DAOCommitteeV1Transactor // Write-only binding to the contract
	DAOCommitteeV1Filterer   // Log filterer for contract events
}

// DAOCommitteeV1Caller is an auto generated read-only Go binding around an Ethereum contract.
type DAOCommitteeV1Caller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DAOCommitteeV1Transactor is an auto generated write-only Go binding around an Ethereum contract.
type DAOCommitteeV1Transactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DAOCommitteeV1Filterer is an auto generated log filtering Go binding around an Ethereum contract events.
type DAOCommitteeV1Filterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// DAOCommitteeV1Session is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type DAOCommitteeV1Session struct {
	Contract     *DAOCommitteeV1   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// DAOCommitteeV1CallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type DAOCommitteeV1CallerSession struct {
	Contract *DAOCommitteeV1Caller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// DAOCommitteeV1TransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type DAOCommitteeV1TransactorSession struct {
	Contract     *DAOCommitteeV1Transactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// DAOCommitteeV1Raw is an auto generated low-level Go binding around an Ethereum contract.
type DAOCommitteeV1Raw struct {
	Contract *DAOCommitteeV1 // Generic contract binding to access the raw methods on
}

// DAOCommitteeV1CallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type DAOCommitteeV1CallerRaw struct {
	Contract *DAOCommitteeV1Caller // Generic read-only contract binding to access the raw methods on
}

// DAOCommitteeV1TransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type DAOCommitteeV1TransactorRaw struct {
	Contract *DAOCommitteeV1Transactor // Generic write-only contract binding to access the raw methods on
}

// NewDAOCommitteeV1 creates a new instance of DAOCommitteeV1, bound to a specific deployed contract.
func NewDAOCommitteeV1(address common.Address, backend bind.ContractBackend) (*DAOCommitteeV1, error) {
	contract, err := bindDAOCommitteeV1(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1{DAOCommitteeV1Caller: DAOCommitteeV1Caller{contract: contract}, DAOCommitteeV1Transactor: DAOCommitteeV1Transactor{contract: contract}, DAOCommitteeV1Filterer: DAOCommitteeV1Filterer{contract: contract}}, nil
}

// NewDAOCommitteeV1Caller creates a new read-only instance of DAOCommitteeV1, bound to a specific deployed contract.
func NewDAOCommitteeV1Caller(address common.Address, caller bind.ContractCaller) (*DAOCommitteeV1Caller, error) {
	contract, err := bindDAOCommitteeV1(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1Caller{contract: contract}, nil
}

// NewDAOCommitteeV1Transactor creates a new write-only instance of DAOCommitteeV1, bound to a specific deployed contract.
func NewDAOCommitteeV1Transactor(address common.Address, transactor bind.ContractTransactor) (*DAOCommitteeV1Transactor, error) {
	contract, err := bindDAOCommitteeV1(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1Transactor{contract: contract}, nil
}

// NewDAOCommitteeV1Filterer creates a new log filterer instance of DAOCommitteeV1, bound to a specific deployed contract.
func NewDAOCommitteeV1Filterer(address common.Address, filterer bind.ContractFilterer) (*DAOCommitteeV1Filterer, error) {
	contract, err := bindDAOCommitteeV1(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1Filterer{contract: contract}, nil
}

// bindDAOCommitteeV1 binds a generic wrapper to an already deployed contract.
func bindDAOCommitteeV1(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := DAOCommitteeV1MetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_DAOCommitteeV1 *DAOCommitteeV1Raw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _DAOCommitteeV1.Contract.DAOCommitteeV1Caller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_DAOCommitteeV1 *DAOCommitteeV1Raw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.DAOCommitteeV1Transactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_DAOCommitteeV1 *DAOCommitteeV1Raw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.DAOCommitteeV1Transactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_DAOCommitteeV1 *DAOCommitteeV1CallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _DAOCommitteeV1.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) DEFAULTADMINROLE() ([32]byte, error) {
	return _DAOCommitteeV1.Contract.DEFAULTADMINROLE(&_DAOCommitteeV1.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _DAOCommitteeV1.Contract.DEFAULTADMINROLE(&_DAOCommitteeV1.CallOpts)
}

// ActivityRewardPerSecond is a free data retrieval call binding the contract method 0x7f331636.
//
// Solidity: function activityRewardPerSecond() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) ActivityRewardPerSecond(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "activityRewardPerSecond")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ActivityRewardPerSecond is a free data retrieval call binding the contract method 0x7f331636.
//
// Solidity: function activityRewardPerSecond() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) ActivityRewardPerSecond() (*big.Int, error) {
	return _DAOCommitteeV1.Contract.ActivityRewardPerSecond(&_DAOCommitteeV1.CallOpts)
}

// ActivityRewardPerSecond is a free data retrieval call binding the contract method 0x7f331636.
//
// Solidity: function activityRewardPerSecond() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) ActivityRewardPerSecond() (*big.Int, error) {
	return _DAOCommitteeV1.Contract.ActivityRewardPerSecond(&_DAOCommitteeV1.CallOpts)
}

// AgendaManager is a free data retrieval call binding the contract method 0x27fd92fd.
//
// Solidity: function agendaManager() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) AgendaManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "agendaManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// AgendaManager is a free data retrieval call binding the contract method 0x27fd92fd.
//
// Solidity: function agendaManager() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) AgendaManager() (common.Address, error) {
	return _DAOCommitteeV1.Contract.AgendaManager(&_DAOCommitteeV1.CallOpts)
}

// AgendaManager is a free data retrieval call binding the contract method 0x27fd92fd.
//
// Solidity: function agendaManager() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) AgendaManager() (common.Address, error) {
	return _DAOCommitteeV1.Contract.AgendaManager(&_DAOCommitteeV1.CallOpts)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) AliveImplementation(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "aliveImplementation", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) AliveImplementation(arg0 common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.AliveImplementation(&_DAOCommitteeV1.CallOpts, arg0)
}

// AliveImplementation is a free data retrieval call binding the contract method 0x550d01a3.
//
// Solidity: function aliveImplementation(address ) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) AliveImplementation(arg0 common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.AliveImplementation(&_DAOCommitteeV1.CallOpts, arg0)
}

// BalanceOfOnCandidate is a free data retrieval call binding the contract method 0xd525f04f.
//
// Solidity: function balanceOfOnCandidate(address _candidate, address _account) view returns(uint256 amount)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) BalanceOfOnCandidate(opts *bind.CallOpts, _candidate common.Address, _account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "balanceOfOnCandidate", _candidate, _account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOfOnCandidate is a free data retrieval call binding the contract method 0xd525f04f.
//
// Solidity: function balanceOfOnCandidate(address _candidate, address _account) view returns(uint256 amount)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) BalanceOfOnCandidate(_candidate common.Address, _account common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.BalanceOfOnCandidate(&_DAOCommitteeV1.CallOpts, _candidate, _account)
}

// BalanceOfOnCandidate is a free data retrieval call binding the contract method 0xd525f04f.
//
// Solidity: function balanceOfOnCandidate(address _candidate, address _account) view returns(uint256 amount)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) BalanceOfOnCandidate(_candidate common.Address, _account common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.BalanceOfOnCandidate(&_DAOCommitteeV1.CallOpts, _candidate, _account)
}

// BalanceOfOnCandidateContract is a free data retrieval call binding the contract method 0x16f7f982.
//
// Solidity: function balanceOfOnCandidateContract(address _candidateContract, address _account) view returns(uint256 amount)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) BalanceOfOnCandidateContract(opts *bind.CallOpts, _candidateContract common.Address, _account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "balanceOfOnCandidateContract", _candidateContract, _account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOfOnCandidateContract is a free data retrieval call binding the contract method 0x16f7f982.
//
// Solidity: function balanceOfOnCandidateContract(address _candidateContract, address _account) view returns(uint256 amount)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) BalanceOfOnCandidateContract(_candidateContract common.Address, _account common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.BalanceOfOnCandidateContract(&_DAOCommitteeV1.CallOpts, _candidateContract, _account)
}

// BalanceOfOnCandidateContract is a free data retrieval call binding the contract method 0x16f7f982.
//
// Solidity: function balanceOfOnCandidateContract(address _candidateContract, address _account) view returns(uint256 amount)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) BalanceOfOnCandidateContract(_candidateContract common.Address, _account common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.BalanceOfOnCandidateContract(&_DAOCommitteeV1.CallOpts, _candidateContract, _account)
}

// Blacklist is a free data retrieval call binding the contract method 0xf9f92be4.
//
// Solidity: function blacklist(address ) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) Blacklist(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "blacklist", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Blacklist is a free data retrieval call binding the contract method 0xf9f92be4.
//
// Solidity: function blacklist(address ) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) Blacklist(arg0 common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.Blacklist(&_DAOCommitteeV1.CallOpts, arg0)
}

// Blacklist is a free data retrieval call binding the contract method 0xf9f92be4.
//
// Solidity: function blacklist(address ) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) Blacklist(arg0 common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.Blacklist(&_DAOCommitteeV1.CallOpts, arg0)
}

// CandidateAddOnFactory is a free data retrieval call binding the contract method 0x75362819.
//
// Solidity: function candidateAddOnFactory() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) CandidateAddOnFactory(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "candidateAddOnFactory")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// CandidateAddOnFactory is a free data retrieval call binding the contract method 0x75362819.
//
// Solidity: function candidateAddOnFactory() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CandidateAddOnFactory() (common.Address, error) {
	return _DAOCommitteeV1.Contract.CandidateAddOnFactory(&_DAOCommitteeV1.CallOpts)
}

// CandidateAddOnFactory is a free data retrieval call binding the contract method 0x75362819.
//
// Solidity: function candidateAddOnFactory() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) CandidateAddOnFactory() (common.Address, error) {
	return _DAOCommitteeV1.Contract.CandidateAddOnFactory(&_DAOCommitteeV1.CallOpts)
}

// CandidateContract is a free data retrieval call binding the contract method 0x651d08cd.
//
// Solidity: function candidateContract(address _candidate) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) CandidateContract(opts *bind.CallOpts, _candidate common.Address) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "candidateContract", _candidate)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// CandidateContract is a free data retrieval call binding the contract method 0x651d08cd.
//
// Solidity: function candidateContract(address _candidate) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CandidateContract(_candidate common.Address) (common.Address, error) {
	return _DAOCommitteeV1.Contract.CandidateContract(&_DAOCommitteeV1.CallOpts, _candidate)
}

// CandidateContract is a free data retrieval call binding the contract method 0x651d08cd.
//
// Solidity: function candidateContract(address _candidate) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) CandidateContract(_candidate common.Address) (common.Address, error) {
	return _DAOCommitteeV1.Contract.CandidateContract(&_DAOCommitteeV1.CallOpts, _candidate)
}

// CandidateFactory is a free data retrieval call binding the contract method 0xb5dd1158.
//
// Solidity: function candidateFactory() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) CandidateFactory(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "candidateFactory")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// CandidateFactory is a free data retrieval call binding the contract method 0xb5dd1158.
//
// Solidity: function candidateFactory() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CandidateFactory() (common.Address, error) {
	return _DAOCommitteeV1.Contract.CandidateFactory(&_DAOCommitteeV1.CallOpts)
}

// CandidateFactory is a free data retrieval call binding the contract method 0xb5dd1158.
//
// Solidity: function candidateFactory() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) CandidateFactory() (common.Address, error) {
	return _DAOCommitteeV1.Contract.CandidateFactory(&_DAOCommitteeV1.CallOpts)
}

// CandidateInfos is a free data retrieval call binding the contract method 0x2e011c1e.
//
// Solidity: function candidateInfos(address _candidate) view returns((address,uint256,uint128,uint128,uint128))
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) CandidateInfos(opts *bind.CallOpts, _candidate common.Address) (StorageStateCommitteeCandidateInfo, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "candidateInfos", _candidate)

	if err != nil {
		return *new(StorageStateCommitteeCandidateInfo), err
	}

	out0 := *abi.ConvertType(out[0], new(StorageStateCommitteeCandidateInfo)).(*StorageStateCommitteeCandidateInfo)

	return out0, err

}

// CandidateInfos is a free data retrieval call binding the contract method 0x2e011c1e.
//
// Solidity: function candidateInfos(address _candidate) view returns((address,uint256,uint128,uint128,uint128))
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CandidateInfos(_candidate common.Address) (StorageStateCommitteeCandidateInfo, error) {
	return _DAOCommitteeV1.Contract.CandidateInfos(&_DAOCommitteeV1.CallOpts, _candidate)
}

// CandidateInfos is a free data retrieval call binding the contract method 0x2e011c1e.
//
// Solidity: function candidateInfos(address _candidate) view returns((address,uint256,uint128,uint128,uint128))
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) CandidateInfos(_candidate common.Address) (StorageStateCommitteeCandidateInfo, error) {
	return _DAOCommitteeV1.Contract.CandidateInfos(&_DAOCommitteeV1.CallOpts, _candidate)
}

// Candidates is a free data retrieval call binding the contract method 0x3477ee2e.
//
// Solidity: function candidates(uint256 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) Candidates(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "candidates", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Candidates is a free data retrieval call binding the contract method 0x3477ee2e.
//
// Solidity: function candidates(uint256 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) Candidates(arg0 *big.Int) (common.Address, error) {
	return _DAOCommitteeV1.Contract.Candidates(&_DAOCommitteeV1.CallOpts, arg0)
}

// Candidates is a free data retrieval call binding the contract method 0x3477ee2e.
//
// Solidity: function candidates(uint256 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) Candidates(arg0 *big.Int) (common.Address, error) {
	return _DAOCommitteeV1.Contract.Candidates(&_DAOCommitteeV1.CallOpts, arg0)
}

// CandidatesLength is a free data retrieval call binding the contract method 0x773b7f65.
//
// Solidity: function candidatesLength() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) CandidatesLength(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "candidatesLength")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// CandidatesLength is a free data retrieval call binding the contract method 0x773b7f65.
//
// Solidity: function candidatesLength() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CandidatesLength() (*big.Int, error) {
	return _DAOCommitteeV1.Contract.CandidatesLength(&_DAOCommitteeV1.CallOpts)
}

// CandidatesLength is a free data retrieval call binding the contract method 0x773b7f65.
//
// Solidity: function candidatesLength() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) CandidatesLength() (*big.Int, error) {
	return _DAOCommitteeV1.Contract.CandidatesLength(&_DAOCommitteeV1.CallOpts)
}

// Cooldown is a free data retrieval call binding the contract method 0xb222e0c2.
//
// Solidity: function cooldown(address ) view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) Cooldown(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "cooldown", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Cooldown is a free data retrieval call binding the contract method 0xb222e0c2.
//
// Solidity: function cooldown(address ) view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) Cooldown(arg0 common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.Cooldown(&_DAOCommitteeV1.CallOpts, arg0)
}

// Cooldown is a free data retrieval call binding the contract method 0xb222e0c2.
//
// Solidity: function cooldown(address ) view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) Cooldown(arg0 common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.Cooldown(&_DAOCommitteeV1.CallOpts, arg0)
}

// CooldownTime is a free data retrieval call binding the contract method 0xb319c6b7.
//
// Solidity: function cooldownTime() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) CooldownTime(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "cooldownTime")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// CooldownTime is a free data retrieval call binding the contract method 0xb319c6b7.
//
// Solidity: function cooldownTime() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CooldownTime() (*big.Int, error) {
	return _DAOCommitteeV1.Contract.CooldownTime(&_DAOCommitteeV1.CallOpts)
}

// CooldownTime is a free data retrieval call binding the contract method 0xb319c6b7.
//
// Solidity: function cooldownTime() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) CooldownTime() (*big.Int, error) {
	return _DAOCommitteeV1.Contract.CooldownTime(&_DAOCommitteeV1.CallOpts)
}

// CurrentAgendaStatus is a free data retrieval call binding the contract method 0xd71b8dc0.
//
// Solidity: function currentAgendaStatus(uint256 _agendaID) view returns(uint256 agendaResult, uint256 agendaStatus)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) CurrentAgendaStatus(opts *bind.CallOpts, _agendaID *big.Int) (struct {
	AgendaResult *big.Int
	AgendaStatus *big.Int
}, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "currentAgendaStatus", _agendaID)

	outstruct := new(struct {
		AgendaResult *big.Int
		AgendaStatus *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.AgendaResult = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.AgendaStatus = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// CurrentAgendaStatus is a free data retrieval call binding the contract method 0xd71b8dc0.
//
// Solidity: function currentAgendaStatus(uint256 _agendaID) view returns(uint256 agendaResult, uint256 agendaStatus)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CurrentAgendaStatus(_agendaID *big.Int) (struct {
	AgendaResult *big.Int
	AgendaStatus *big.Int
}, error) {
	return _DAOCommitteeV1.Contract.CurrentAgendaStatus(&_DAOCommitteeV1.CallOpts, _agendaID)
}

// CurrentAgendaStatus is a free data retrieval call binding the contract method 0xd71b8dc0.
//
// Solidity: function currentAgendaStatus(uint256 _agendaID) view returns(uint256 agendaResult, uint256 agendaStatus)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) CurrentAgendaStatus(_agendaID *big.Int) (struct {
	AgendaResult *big.Int
	AgendaStatus *big.Int
}, error) {
	return _DAOCommitteeV1.Contract.CurrentAgendaStatus(&_DAOCommitteeV1.CallOpts, _agendaID)
}

// DaoVault is a free data retrieval call binding the contract method 0x5903bd6c.
//
// Solidity: function daoVault() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) DaoVault(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "daoVault")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// DaoVault is a free data retrieval call binding the contract method 0x5903bd6c.
//
// Solidity: function daoVault() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) DaoVault() (common.Address, error) {
	return _DAOCommitteeV1.Contract.DaoVault(&_DAOCommitteeV1.CallOpts)
}

// DaoVault is a free data retrieval call binding the contract method 0x5903bd6c.
//
// Solidity: function daoVault() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) DaoVault() (common.Address, error) {
	return _DAOCommitteeV1.Contract.DaoVault(&_DAOCommitteeV1.CallOpts)
}

// GetClaimableActivityReward is a free data retrieval call binding the contract method 0x9932e94c.
//
// Solidity: function getClaimableActivityReward(address _candidate) view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) GetClaimableActivityReward(opts *bind.CallOpts, _candidate common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "getClaimableActivityReward", _candidate)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetClaimableActivityReward is a free data retrieval call binding the contract method 0x9932e94c.
//
// Solidity: function getClaimableActivityReward(address _candidate) view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) GetClaimableActivityReward(_candidate common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.GetClaimableActivityReward(&_DAOCommitteeV1.CallOpts, _candidate)
}

// GetClaimableActivityReward is a free data retrieval call binding the contract method 0x9932e94c.
//
// Solidity: function getClaimableActivityReward(address _candidate) view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) GetClaimableActivityReward(_candidate common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.GetClaimableActivityReward(&_DAOCommitteeV1.CallOpts, _candidate)
}

// GetOldCandidateInfos is a free data retrieval call binding the contract method 0x14d3535e.
//
// Solidity: function getOldCandidateInfos(address _oldCandidate) view returns((address,address,uint256,uint128,uint128,uint128))
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) GetOldCandidateInfos(opts *bind.CallOpts, _oldCandidate common.Address) (StorageStateCommitteeV2CandidateInfo2, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "getOldCandidateInfos", _oldCandidate)

	if err != nil {
		return *new(StorageStateCommitteeV2CandidateInfo2), err
	}

	out0 := *abi.ConvertType(out[0], new(StorageStateCommitteeV2CandidateInfo2)).(*StorageStateCommitteeV2CandidateInfo2)

	return out0, err

}

// GetOldCandidateInfos is a free data retrieval call binding the contract method 0x14d3535e.
//
// Solidity: function getOldCandidateInfos(address _oldCandidate) view returns((address,address,uint256,uint128,uint128,uint128))
func (_DAOCommitteeV1 *DAOCommitteeV1Session) GetOldCandidateInfos(_oldCandidate common.Address) (StorageStateCommitteeV2CandidateInfo2, error) {
	return _DAOCommitteeV1.Contract.GetOldCandidateInfos(&_DAOCommitteeV1.CallOpts, _oldCandidate)
}

// GetOldCandidateInfos is a free data retrieval call binding the contract method 0x14d3535e.
//
// Solidity: function getOldCandidateInfos(address _oldCandidate) view returns((address,address,uint256,uint128,uint128,uint128))
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) GetOldCandidateInfos(_oldCandidate common.Address) (StorageStateCommitteeV2CandidateInfo2, error) {
	return _DAOCommitteeV1.Contract.GetOldCandidateInfos(&_DAOCommitteeV1.CallOpts, _oldCandidate)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _DAOCommitteeV1.Contract.GetRoleAdmin(&_DAOCommitteeV1.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _DAOCommitteeV1.Contract.GetRoleAdmin(&_DAOCommitteeV1.CallOpts, role)
}

// GetRoleMember is a free data retrieval call binding the contract method 0x9010d07c.
//
// Solidity: function getRoleMember(bytes32 role, uint256 index) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) GetRoleMember(opts *bind.CallOpts, role [32]byte, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "getRoleMember", role, index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetRoleMember is a free data retrieval call binding the contract method 0x9010d07c.
//
// Solidity: function getRoleMember(bytes32 role, uint256 index) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) GetRoleMember(role [32]byte, index *big.Int) (common.Address, error) {
	return _DAOCommitteeV1.Contract.GetRoleMember(&_DAOCommitteeV1.CallOpts, role, index)
}

// GetRoleMember is a free data retrieval call binding the contract method 0x9010d07c.
//
// Solidity: function getRoleMember(bytes32 role, uint256 index) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) GetRoleMember(role [32]byte, index *big.Int) (common.Address, error) {
	return _DAOCommitteeV1.Contract.GetRoleMember(&_DAOCommitteeV1.CallOpts, role, index)
}

// GetRoleMemberCount is a free data retrieval call binding the contract method 0xca15c873.
//
// Solidity: function getRoleMemberCount(bytes32 role) view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) GetRoleMemberCount(opts *bind.CallOpts, role [32]byte) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "getRoleMemberCount", role)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetRoleMemberCount is a free data retrieval call binding the contract method 0xca15c873.
//
// Solidity: function getRoleMemberCount(bytes32 role) view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) GetRoleMemberCount(role [32]byte) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.GetRoleMemberCount(&_DAOCommitteeV1.CallOpts, role)
}

// GetRoleMemberCount is a free data retrieval call binding the contract method 0xca15c873.
//
// Solidity: function getRoleMemberCount(bytes32 role) view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) GetRoleMemberCount(role [32]byte) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.GetRoleMemberCount(&_DAOCommitteeV1.CallOpts, role)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.HasRole(&_DAOCommitteeV1.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.HasRole(&_DAOCommitteeV1.CallOpts, role, account)
}

// IsCandidate is a free data retrieval call binding the contract method 0xd51b9e93.
//
// Solidity: function isCandidate(address _candidate) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) IsCandidate(opts *bind.CallOpts, _candidate common.Address) (bool, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "isCandidate", _candidate)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsCandidate is a free data retrieval call binding the contract method 0xd51b9e93.
//
// Solidity: function isCandidate(address _candidate) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) IsCandidate(_candidate common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.IsCandidate(&_DAOCommitteeV1.CallOpts, _candidate)
}

// IsCandidate is a free data retrieval call binding the contract method 0xd51b9e93.
//
// Solidity: function isCandidate(address _candidate) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) IsCandidate(_candidate common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.IsCandidate(&_DAOCommitteeV1.CallOpts, _candidate)
}

// IsExistCandidate is a free data retrieval call binding the contract method 0x561a1dab.
//
// Solidity: function isExistCandidate(address _candidate) view returns(bool isExist)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) IsExistCandidate(opts *bind.CallOpts, _candidate common.Address) (bool, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "isExistCandidate", _candidate)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsExistCandidate is a free data retrieval call binding the contract method 0x561a1dab.
//
// Solidity: function isExistCandidate(address _candidate) view returns(bool isExist)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) IsExistCandidate(_candidate common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.IsExistCandidate(&_DAOCommitteeV1.CallOpts, _candidate)
}

// IsExistCandidate is a free data retrieval call binding the contract method 0x561a1dab.
//
// Solidity: function isExistCandidate(address _candidate) view returns(bool isExist)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) IsExistCandidate(_candidate common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.IsExistCandidate(&_DAOCommitteeV1.CallOpts, _candidate)
}

// IsMember is a free data retrieval call binding the contract method 0xa230c524.
//
// Solidity: function isMember(address _candidate) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) IsMember(opts *bind.CallOpts, _candidate common.Address) (bool, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "isMember", _candidate)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsMember is a free data retrieval call binding the contract method 0xa230c524.
//
// Solidity: function isMember(address _candidate) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) IsMember(_candidate common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.IsMember(&_DAOCommitteeV1.CallOpts, _candidate)
}

// IsMember is a free data retrieval call binding the contract method 0xa230c524.
//
// Solidity: function isMember(address _candidate) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) IsMember(_candidate common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.IsMember(&_DAOCommitteeV1.CallOpts, _candidate)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) Layer2Manager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "layer2Manager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) Layer2Manager() (common.Address, error) {
	return _DAOCommitteeV1.Contract.Layer2Manager(&_DAOCommitteeV1.CallOpts)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) Layer2Manager() (common.Address, error) {
	return _DAOCommitteeV1.Contract.Layer2Manager(&_DAOCommitteeV1.CallOpts)
}

// Layer2Registry is a free data retrieval call binding the contract method 0xcf2a239c.
//
// Solidity: function layer2Registry() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) Layer2Registry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "layer2Registry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Layer2Registry is a free data retrieval call binding the contract method 0xcf2a239c.
//
// Solidity: function layer2Registry() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) Layer2Registry() (common.Address, error) {
	return _DAOCommitteeV1.Contract.Layer2Registry(&_DAOCommitteeV1.CallOpts)
}

// Layer2Registry is a free data retrieval call binding the contract method 0xcf2a239c.
//
// Solidity: function layer2Registry() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) Layer2Registry() (common.Address, error) {
	return _DAOCommitteeV1.Contract.Layer2Registry(&_DAOCommitteeV1.CallOpts)
}

// MaxMember is a free data retrieval call binding the contract method 0x03e3c9ac.
//
// Solidity: function maxMember() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) MaxMember(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "maxMember")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxMember is a free data retrieval call binding the contract method 0x03e3c9ac.
//
// Solidity: function maxMember() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) MaxMember() (*big.Int, error) {
	return _DAOCommitteeV1.Contract.MaxMember(&_DAOCommitteeV1.CallOpts)
}

// MaxMember is a free data retrieval call binding the contract method 0x03e3c9ac.
//
// Solidity: function maxMember() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) MaxMember() (*big.Int, error) {
	return _DAOCommitteeV1.Contract.MaxMember(&_DAOCommitteeV1.CallOpts)
}

// Members is a free data retrieval call binding the contract method 0x5daf08ca.
//
// Solidity: function members(uint256 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) Members(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "members", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Members is a free data retrieval call binding the contract method 0x5daf08ca.
//
// Solidity: function members(uint256 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) Members(arg0 *big.Int) (common.Address, error) {
	return _DAOCommitteeV1.Contract.Members(&_DAOCommitteeV1.CallOpts, arg0)
}

// Members is a free data retrieval call binding the contract method 0x5daf08ca.
//
// Solidity: function members(uint256 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) Members(arg0 *big.Int) (common.Address, error) {
	return _DAOCommitteeV1.Contract.Members(&_DAOCommitteeV1.CallOpts, arg0)
}

// OperatorAmountCheck is a free data retrieval call binding the contract method 0xb84cabe2.
//
// Solidity: function operatorAmountCheck(address layer2, address operator) view returns(uint256 operatorAmount)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) OperatorAmountCheck(opts *bind.CallOpts, layer2 common.Address, operator common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "operatorAmountCheck", layer2, operator)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OperatorAmountCheck is a free data retrieval call binding the contract method 0xb84cabe2.
//
// Solidity: function operatorAmountCheck(address layer2, address operator) view returns(uint256 operatorAmount)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) OperatorAmountCheck(layer2 common.Address, operator common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.OperatorAmountCheck(&_DAOCommitteeV1.CallOpts, layer2, operator)
}

// OperatorAmountCheck is a free data retrieval call binding the contract method 0xb84cabe2.
//
// Solidity: function operatorAmountCheck(address layer2, address operator) view returns(uint256 operatorAmount)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) OperatorAmountCheck(layer2 common.Address, operator common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.OperatorAmountCheck(&_DAOCommitteeV1.CallOpts, layer2, operator)
}

// OperatorCheck is a free data retrieval call binding the contract method 0x5a74b3b8.
//
// Solidity: function operatorCheck(address candidate) view returns(uint256 operatorAmount)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) OperatorCheck(opts *bind.CallOpts, candidate common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "operatorCheck", candidate)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OperatorCheck is a free data retrieval call binding the contract method 0x5a74b3b8.
//
// Solidity: function operatorCheck(address candidate) view returns(uint256 operatorAmount)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) OperatorCheck(candidate common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.OperatorCheck(&_DAOCommitteeV1.CallOpts, candidate)
}

// OperatorCheck is a free data retrieval call binding the contract method 0x5a74b3b8.
//
// Solidity: function operatorCheck(address candidate) view returns(uint256 operatorAmount)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) OperatorCheck(candidate common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.OperatorCheck(&_DAOCommitteeV1.CallOpts, candidate)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) PauseProxy(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "pauseProxy")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) PauseProxy() (bool, error) {
	return _DAOCommitteeV1.Contract.PauseProxy(&_DAOCommitteeV1.CallOpts)
}

// PauseProxy is a free data retrieval call binding the contract method 0x63a8fd89.
//
// Solidity: function pauseProxy() view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) PauseProxy() (bool, error) {
	return _DAOCommitteeV1.Contract.PauseProxy(&_DAOCommitteeV1.CallOpts)
}

// PrivateLayer2 is a free data retrieval call binding the contract method 0xb40525eb.
//
// Solidity: function privateLayer2(address ) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) PrivateLayer2(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "privateLayer2", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PrivateLayer2 is a free data retrieval call binding the contract method 0xb40525eb.
//
// Solidity: function privateLayer2(address ) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) PrivateLayer2(arg0 common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.PrivateLayer2(&_DAOCommitteeV1.CallOpts, arg0)
}

// PrivateLayer2 is a free data retrieval call binding the contract method 0xb40525eb.
//
// Solidity: function privateLayer2(address ) view returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) PrivateLayer2(arg0 common.Address) (bool, error) {
	return _DAOCommitteeV1.Contract.PrivateLayer2(&_DAOCommitteeV1.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) ProxyImplementation(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "proxyImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _DAOCommitteeV1.Contract.ProxyImplementation(&_DAOCommitteeV1.CallOpts, arg0)
}

// ProxyImplementation is a free data retrieval call binding the contract method 0xb911135f.
//
// Solidity: function proxyImplementation(uint256 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) ProxyImplementation(arg0 *big.Int) (common.Address, error) {
	return _DAOCommitteeV1.Contract.ProxyImplementation(&_DAOCommitteeV1.CallOpts, arg0)
}

// Quorum is a free data retrieval call binding the contract method 0x1703a018.
//
// Solidity: function quorum() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) Quorum(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "quorum")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Quorum is a free data retrieval call binding the contract method 0x1703a018.
//
// Solidity: function quorum() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) Quorum() (*big.Int, error) {
	return _DAOCommitteeV1.Contract.Quorum(&_DAOCommitteeV1.CallOpts)
}

// Quorum is a free data retrieval call binding the contract method 0x1703a018.
//
// Solidity: function quorum() view returns(uint256)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) Quorum() (*big.Int, error) {
	return _DAOCommitteeV1.Contract.Quorum(&_DAOCommitteeV1.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) SeigManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "seigManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) SeigManager() (common.Address, error) {
	return _DAOCommitteeV1.Contract.SeigManager(&_DAOCommitteeV1.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) SeigManager() (common.Address, error) {
	return _DAOCommitteeV1.Contract.SeigManager(&_DAOCommitteeV1.CallOpts)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) SelectorImplementation(opts *bind.CallOpts, arg0 [4]byte) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "selectorImplementation", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _DAOCommitteeV1.Contract.SelectorImplementation(&_DAOCommitteeV1.CallOpts, arg0)
}

// SelectorImplementation is a free data retrieval call binding the contract method 0x50d2a276.
//
// Solidity: function selectorImplementation(bytes4 ) view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) SelectorImplementation(arg0 [4]byte) (common.Address, error) {
	return _DAOCommitteeV1.Contract.SelectorImplementation(&_DAOCommitteeV1.CallOpts, arg0)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) Ton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "ton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) Ton() (common.Address, error) {
	return _DAOCommitteeV1.Contract.Ton(&_DAOCommitteeV1.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) Ton() (common.Address, error) {
	return _DAOCommitteeV1.Contract.Ton(&_DAOCommitteeV1.CallOpts)
}

// TotalSupplyOnCandidate is a free data retrieval call binding the contract method 0xad6675dc.
//
// Solidity: function totalSupplyOnCandidate(address _candidate) view returns(uint256 totalsupply)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) TotalSupplyOnCandidate(opts *bind.CallOpts, _candidate common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "totalSupplyOnCandidate", _candidate)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalSupplyOnCandidate is a free data retrieval call binding the contract method 0xad6675dc.
//
// Solidity: function totalSupplyOnCandidate(address _candidate) view returns(uint256 totalsupply)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) TotalSupplyOnCandidate(_candidate common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.TotalSupplyOnCandidate(&_DAOCommitteeV1.CallOpts, _candidate)
}

// TotalSupplyOnCandidate is a free data retrieval call binding the contract method 0xad6675dc.
//
// Solidity: function totalSupplyOnCandidate(address _candidate) view returns(uint256 totalsupply)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) TotalSupplyOnCandidate(_candidate common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.TotalSupplyOnCandidate(&_DAOCommitteeV1.CallOpts, _candidate)
}

// TotalSupplyOnCandidateContract is a free data retrieval call binding the contract method 0x78767d33.
//
// Solidity: function totalSupplyOnCandidateContract(address _candidateContract) view returns(uint256 totalsupply)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) TotalSupplyOnCandidateContract(opts *bind.CallOpts, _candidateContract common.Address) (*big.Int, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "totalSupplyOnCandidateContract", _candidateContract)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalSupplyOnCandidateContract is a free data retrieval call binding the contract method 0x78767d33.
//
// Solidity: function totalSupplyOnCandidateContract(address _candidateContract) view returns(uint256 totalsupply)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) TotalSupplyOnCandidateContract(_candidateContract common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.TotalSupplyOnCandidateContract(&_DAOCommitteeV1.CallOpts, _candidateContract)
}

// TotalSupplyOnCandidateContract is a free data retrieval call binding the contract method 0x78767d33.
//
// Solidity: function totalSupplyOnCandidateContract(address _candidateContract) view returns(uint256 totalsupply)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) TotalSupplyOnCandidateContract(_candidateContract common.Address) (*big.Int, error) {
	return _DAOCommitteeV1.Contract.TotalSupplyOnCandidateContract(&_DAOCommitteeV1.CallOpts, _candidateContract)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Caller) Wton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _DAOCommitteeV1.contract.Call(opts, &out, "wton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) Wton() (common.Address, error) {
	return _DAOCommitteeV1.Contract.Wton(&_DAOCommitteeV1.CallOpts)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1CallerSession) Wton() (common.Address, error) {
	return _DAOCommitteeV1.Contract.Wton(&_DAOCommitteeV1.CallOpts)
}

// CastVote is a paid mutator transaction binding the contract method 0x24f99b1e.
//
// Solidity: function castVote(uint256 _agendaID, uint256 _vote, string _comment) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) CastVote(opts *bind.TransactOpts, _agendaID *big.Int, _vote *big.Int, _comment string) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "castVote", _agendaID, _vote, _comment)
}

// CastVote is a paid mutator transaction binding the contract method 0x24f99b1e.
//
// Solidity: function castVote(uint256 _agendaID, uint256 _vote, string _comment) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CastVote(_agendaID *big.Int, _vote *big.Int, _comment string) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.CastVote(&_DAOCommitteeV1.TransactOpts, _agendaID, _vote, _comment)
}

// CastVote is a paid mutator transaction binding the contract method 0x24f99b1e.
//
// Solidity: function castVote(uint256 _agendaID, uint256 _vote, string _comment) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) CastVote(_agendaID *big.Int, _vote *big.Int, _comment string) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.CastVote(&_DAOCommitteeV1.TransactOpts, _agendaID, _vote, _comment)
}

// ChangeMember is a paid mutator transaction binding the contract method 0x11f19e04.
//
// Solidity: function changeMember(uint256 _memberIndex) returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) ChangeMember(opts *bind.TransactOpts, _memberIndex *big.Int) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "changeMember", _memberIndex)
}

// ChangeMember is a paid mutator transaction binding the contract method 0x11f19e04.
//
// Solidity: function changeMember(uint256 _memberIndex) returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) ChangeMember(_memberIndex *big.Int) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.ChangeMember(&_DAOCommitteeV1.TransactOpts, _memberIndex)
}

// ChangeMember is a paid mutator transaction binding the contract method 0x11f19e04.
//
// Solidity: function changeMember(uint256 _memberIndex) returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) ChangeMember(_memberIndex *big.Int) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.ChangeMember(&_DAOCommitteeV1.TransactOpts, _memberIndex)
}

// ClaimActivityReward is a paid mutator transaction binding the contract method 0x6becff27.
//
// Solidity: function claimActivityReward(address _receiver) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) ClaimActivityReward(opts *bind.TransactOpts, _receiver common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "claimActivityReward", _receiver)
}

// ClaimActivityReward is a paid mutator transaction binding the contract method 0x6becff27.
//
// Solidity: function claimActivityReward(address _receiver) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) ClaimActivityReward(_receiver common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.ClaimActivityReward(&_DAOCommitteeV1.TransactOpts, _receiver)
}

// ClaimActivityReward is a paid mutator transaction binding the contract method 0x6becff27.
//
// Solidity: function claimActivityReward(address _receiver) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) ClaimActivityReward(_receiver common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.ClaimActivityReward(&_DAOCommitteeV1.TransactOpts, _receiver)
}

// CreateCandidate is a paid mutator transaction binding the contract method 0x5fba7a56.
//
// Solidity: function createCandidate(string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) CreateCandidate(opts *bind.TransactOpts, _memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "createCandidate", _memo)
}

// CreateCandidate is a paid mutator transaction binding the contract method 0x5fba7a56.
//
// Solidity: function createCandidate(string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CreateCandidate(_memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.CreateCandidate(&_DAOCommitteeV1.TransactOpts, _memo)
}

// CreateCandidate is a paid mutator transaction binding the contract method 0x5fba7a56.
//
// Solidity: function createCandidate(string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) CreateCandidate(_memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.CreateCandidate(&_DAOCommitteeV1.TransactOpts, _memo)
}

// CreateCandidateAddOn is a paid mutator transaction binding the contract method 0x4892afd3.
//
// Solidity: function createCandidateAddOn(string _memo, address _operatorManagerAddress) returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) CreateCandidateAddOn(opts *bind.TransactOpts, _memo string, _operatorManagerAddress common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "createCandidateAddOn", _memo, _operatorManagerAddress)
}

// CreateCandidateAddOn is a paid mutator transaction binding the contract method 0x4892afd3.
//
// Solidity: function createCandidateAddOn(string _memo, address _operatorManagerAddress) returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CreateCandidateAddOn(_memo string, _operatorManagerAddress common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.CreateCandidateAddOn(&_DAOCommitteeV1.TransactOpts, _memo, _operatorManagerAddress)
}

// CreateCandidateAddOn is a paid mutator transaction binding the contract method 0x4892afd3.
//
// Solidity: function createCandidateAddOn(string _memo, address _operatorManagerAddress) returns(address)
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) CreateCandidateAddOn(_memo string, _operatorManagerAddress common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.CreateCandidateAddOn(&_DAOCommitteeV1.TransactOpts, _memo, _operatorManagerAddress)
}

// CreateCandidateOwner is a paid mutator transaction binding the contract method 0x42414e77.
//
// Solidity: function createCandidateOwner(string _memo, address _operatorAddress) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) CreateCandidateOwner(opts *bind.TransactOpts, _memo string, _operatorAddress common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "createCandidateOwner", _memo, _operatorAddress)
}

// CreateCandidateOwner is a paid mutator transaction binding the contract method 0x42414e77.
//
// Solidity: function createCandidateOwner(string _memo, address _operatorAddress) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) CreateCandidateOwner(_memo string, _operatorAddress common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.CreateCandidateOwner(&_DAOCommitteeV1.TransactOpts, _memo, _operatorAddress)
}

// CreateCandidateOwner is a paid mutator transaction binding the contract method 0x42414e77.
//
// Solidity: function createCandidateOwner(string _memo, address _operatorAddress) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) CreateCandidateOwner(_memo string, _operatorAddress common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.CreateCandidateOwner(&_DAOCommitteeV1.TransactOpts, _memo, _operatorAddress)
}

// ExecuteAgenda is a paid mutator transaction binding the contract method 0x216f486b.
//
// Solidity: function executeAgenda(uint256 _agendaID) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) ExecuteAgenda(opts *bind.TransactOpts, _agendaID *big.Int) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "executeAgenda", _agendaID)
}

// ExecuteAgenda is a paid mutator transaction binding the contract method 0x216f486b.
//
// Solidity: function executeAgenda(uint256 _agendaID) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) ExecuteAgenda(_agendaID *big.Int) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.ExecuteAgenda(&_DAOCommitteeV1.TransactOpts, _agendaID)
}

// ExecuteAgenda is a paid mutator transaction binding the contract method 0x216f486b.
//
// Solidity: function executeAgenda(uint256 _agendaID) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) ExecuteAgenda(_agendaID *big.Int) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.ExecuteAgenda(&_DAOCommitteeV1.TransactOpts, _agendaID)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.GrantRole(&_DAOCommitteeV1.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.GrantRole(&_DAOCommitteeV1.TransactOpts, role, account)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address , uint256 , bytes data) returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) OnApprove(opts *bind.TransactOpts, owner common.Address, arg1 common.Address, arg2 *big.Int, data []byte) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "onApprove", owner, arg1, arg2, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address , uint256 , bytes data) returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) OnApprove(owner common.Address, arg1 common.Address, arg2 *big.Int, data []byte) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.OnApprove(&_DAOCommitteeV1.TransactOpts, owner, arg1, arg2, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address , uint256 , bytes data) returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) OnApprove(owner common.Address, arg1 common.Address, arg2 *big.Int, data []byte) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.OnApprove(&_DAOCommitteeV1.TransactOpts, owner, arg1, arg2, data)
}

// RegisterLayer2CandidateByOwner is a paid mutator transaction binding the contract method 0x440b69ad.
//
// Solidity: function registerLayer2CandidateByOwner(address _operator, address _layer2, string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) RegisterLayer2CandidateByOwner(opts *bind.TransactOpts, _operator common.Address, _layer2 common.Address, _memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "registerLayer2CandidateByOwner", _operator, _layer2, _memo)
}

// RegisterLayer2CandidateByOwner is a paid mutator transaction binding the contract method 0x440b69ad.
//
// Solidity: function registerLayer2CandidateByOwner(address _operator, address _layer2, string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) RegisterLayer2CandidateByOwner(_operator common.Address, _layer2 common.Address, _memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.RegisterLayer2CandidateByOwner(&_DAOCommitteeV1.TransactOpts, _operator, _layer2, _memo)
}

// RegisterLayer2CandidateByOwner is a paid mutator transaction binding the contract method 0x440b69ad.
//
// Solidity: function registerLayer2CandidateByOwner(address _operator, address _layer2, string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) RegisterLayer2CandidateByOwner(_operator common.Address, _layer2 common.Address, _memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.RegisterLayer2CandidateByOwner(&_DAOCommitteeV1.TransactOpts, _operator, _layer2, _memo)
}

// RemoveFromBlacklist is a paid mutator transaction binding the contract method 0x537df3b6.
//
// Solidity: function removeFromBlacklist(address _candidate) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) RemoveFromBlacklist(opts *bind.TransactOpts, _candidate common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "removeFromBlacklist", _candidate)
}

// RemoveFromBlacklist is a paid mutator transaction binding the contract method 0x537df3b6.
//
// Solidity: function removeFromBlacklist(address _candidate) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) RemoveFromBlacklist(_candidate common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.RemoveFromBlacklist(&_DAOCommitteeV1.TransactOpts, _candidate)
}

// RemoveFromBlacklist is a paid mutator transaction binding the contract method 0x537df3b6.
//
// Solidity: function removeFromBlacklist(address _candidate) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) RemoveFromBlacklist(_candidate common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.RemoveFromBlacklist(&_DAOCommitteeV1.TransactOpts, _candidate)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "renounceRole", role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.RenounceRole(&_DAOCommitteeV1.TransactOpts, role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address account) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) RenounceRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.RenounceRole(&_DAOCommitteeV1.TransactOpts, role, account)
}

// RetireMember is a paid mutator transaction binding the contract method 0xc4ef9c00.
//
// Solidity: function retireMember() returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) RetireMember(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "retireMember")
}

// RetireMember is a paid mutator transaction binding the contract method 0xc4ef9c00.
//
// Solidity: function retireMember() returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) RetireMember() (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.RetireMember(&_DAOCommitteeV1.TransactOpts)
}

// RetireMember is a paid mutator transaction binding the contract method 0xc4ef9c00.
//
// Solidity: function retireMember() returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) RetireMember() (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.RetireMember(&_DAOCommitteeV1.TransactOpts)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.RevokeRole(&_DAOCommitteeV1.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.RevokeRole(&_DAOCommitteeV1.TransactOpts, role, account)
}

// SetAgendaStatus is a paid mutator transaction binding the contract method 0x805aca20.
//
// Solidity: function setAgendaStatus(uint256 _agendaID, uint256 _status, uint256 _result) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) SetAgendaStatus(opts *bind.TransactOpts, _agendaID *big.Int, _status *big.Int, _result *big.Int) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "setAgendaStatus", _agendaID, _status, _result)
}

// SetAgendaStatus is a paid mutator transaction binding the contract method 0x805aca20.
//
// Solidity: function setAgendaStatus(uint256 _agendaID, uint256 _status, uint256 _result) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) SetAgendaStatus(_agendaID *big.Int, _status *big.Int, _result *big.Int) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.SetAgendaStatus(&_DAOCommitteeV1.TransactOpts, _agendaID, _status, _result)
}

// SetAgendaStatus is a paid mutator transaction binding the contract method 0x805aca20.
//
// Solidity: function setAgendaStatus(uint256 _agendaID, uint256 _status, uint256 _result) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) SetAgendaStatus(_agendaID *big.Int, _status *big.Int, _result *big.Int) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.SetAgendaStatus(&_DAOCommitteeV1.TransactOpts, _agendaID, _status, _result)
}

// SetMemoOnCandidate is a paid mutator transaction binding the contract method 0xc7cac42c.
//
// Solidity: function setMemoOnCandidate(address _candidate, string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) SetMemoOnCandidate(opts *bind.TransactOpts, _candidate common.Address, _memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "setMemoOnCandidate", _candidate, _memo)
}

// SetMemoOnCandidate is a paid mutator transaction binding the contract method 0xc7cac42c.
//
// Solidity: function setMemoOnCandidate(address _candidate, string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) SetMemoOnCandidate(_candidate common.Address, _memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.SetMemoOnCandidate(&_DAOCommitteeV1.TransactOpts, _candidate, _memo)
}

// SetMemoOnCandidate is a paid mutator transaction binding the contract method 0xc7cac42c.
//
// Solidity: function setMemoOnCandidate(address _candidate, string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) SetMemoOnCandidate(_candidate common.Address, _memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.SetMemoOnCandidate(&_DAOCommitteeV1.TransactOpts, _candidate, _memo)
}

// SetMemoOnCandidateContract is a paid mutator transaction binding the contract method 0x607cf734.
//
// Solidity: function setMemoOnCandidateContract(address _candidateContract, string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) SetMemoOnCandidateContract(opts *bind.TransactOpts, _candidateContract common.Address, _memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "setMemoOnCandidateContract", _candidateContract, _memo)
}

// SetMemoOnCandidateContract is a paid mutator transaction binding the contract method 0x607cf734.
//
// Solidity: function setMemoOnCandidateContract(address _candidateContract, string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1Session) SetMemoOnCandidateContract(_candidateContract common.Address, _memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.SetMemoOnCandidateContract(&_DAOCommitteeV1.TransactOpts, _candidateContract, _memo)
}

// SetMemoOnCandidateContract is a paid mutator transaction binding the contract method 0x607cf734.
//
// Solidity: function setMemoOnCandidateContract(address _candidateContract, string _memo) returns()
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) SetMemoOnCandidateContract(_candidateContract common.Address, _memo string) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.SetMemoOnCandidateContract(&_DAOCommitteeV1.TransactOpts, _candidateContract, _memo)
}

// UpdateSeigniorage is a paid mutator transaction binding the contract method 0x89ea4300.
//
// Solidity: function updateSeigniorage(address _candidate) returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Transactor) UpdateSeigniorage(opts *bind.TransactOpts, _candidate common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.contract.Transact(opts, "updateSeigniorage", _candidate)
}

// UpdateSeigniorage is a paid mutator transaction binding the contract method 0x89ea4300.
//
// Solidity: function updateSeigniorage(address _candidate) returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1Session) UpdateSeigniorage(_candidate common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.UpdateSeigniorage(&_DAOCommitteeV1.TransactOpts, _candidate)
}

// UpdateSeigniorage is a paid mutator transaction binding the contract method 0x89ea4300.
//
// Solidity: function updateSeigniorage(address _candidate) returns(bool)
func (_DAOCommitteeV1 *DAOCommitteeV1TransactorSession) UpdateSeigniorage(_candidate common.Address) (*types.Transaction, error) {
	return _DAOCommitteeV1.Contract.UpdateSeigniorage(&_DAOCommitteeV1.TransactOpts, _candidate)
}

// DAOCommitteeV1AgendaCreatedIterator is returned from FilterAgendaCreated and is used to iterate over the raw logs and unpacked data for AgendaCreated events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1AgendaCreatedIterator struct {
	Event *DAOCommitteeV1AgendaCreated // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1AgendaCreatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1AgendaCreated)
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
		it.Event = new(DAOCommitteeV1AgendaCreated)
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
func (it *DAOCommitteeV1AgendaCreatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1AgendaCreatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1AgendaCreated represents a AgendaCreated event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1AgendaCreated struct {
	From                common.Address
	Id                  *big.Int
	Targets             []common.Address
	NoticePeriodSeconds *big.Int
	VotingPeriodSeconds *big.Int
	AtomicExecute       bool
	Raw                 types.Log // Blockchain specific contextual infos
}

// FilterAgendaCreated is a free log retrieval operation binding the contract event 0xcd47bcad760e912d146723a314cc78b8570ee76ec8bdd4b60335087f6c2f47d7.
//
// Solidity: event AgendaCreated(address indexed from, uint256 indexed id, address[] targets, uint128 noticePeriodSeconds, uint128 votingPeriodSeconds, bool atomicExecute)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterAgendaCreated(opts *bind.FilterOpts, from []common.Address, id []*big.Int) (*DAOCommitteeV1AgendaCreatedIterator, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "AgendaCreated", fromRule, idRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1AgendaCreatedIterator{contract: _DAOCommitteeV1.contract, event: "AgendaCreated", logs: logs, sub: sub}, nil
}

// WatchAgendaCreated is a free log subscription operation binding the contract event 0xcd47bcad760e912d146723a314cc78b8570ee76ec8bdd4b60335087f6c2f47d7.
//
// Solidity: event AgendaCreated(address indexed from, uint256 indexed id, address[] targets, uint128 noticePeriodSeconds, uint128 votingPeriodSeconds, bool atomicExecute)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchAgendaCreated(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1AgendaCreated, from []common.Address, id []*big.Int) (event.Subscription, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "AgendaCreated", fromRule, idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1AgendaCreated)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "AgendaCreated", log); err != nil {
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

// ParseAgendaCreated is a log parse operation binding the contract event 0xcd47bcad760e912d146723a314cc78b8570ee76ec8bdd4b60335087f6c2f47d7.
//
// Solidity: event AgendaCreated(address indexed from, uint256 indexed id, address[] targets, uint128 noticePeriodSeconds, uint128 votingPeriodSeconds, bool atomicExecute)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseAgendaCreated(log types.Log) (*DAOCommitteeV1AgendaCreated, error) {
	event := new(DAOCommitteeV1AgendaCreated)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "AgendaCreated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1AgendaExecutedIterator is returned from FilterAgendaExecuted and is used to iterate over the raw logs and unpacked data for AgendaExecuted events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1AgendaExecutedIterator struct {
	Event *DAOCommitteeV1AgendaExecuted // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1AgendaExecutedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1AgendaExecuted)
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
		it.Event = new(DAOCommitteeV1AgendaExecuted)
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
func (it *DAOCommitteeV1AgendaExecutedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1AgendaExecutedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1AgendaExecuted represents a AgendaExecuted event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1AgendaExecuted struct {
	Id     *big.Int
	Target []common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterAgendaExecuted is a free log retrieval operation binding the contract event 0x785146be3266678a3f4ea454b310ff1f8c91d0ad9a7997bcd0619940d4d67fe6.
//
// Solidity: event AgendaExecuted(uint256 indexed id, address[] target)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterAgendaExecuted(opts *bind.FilterOpts, id []*big.Int) (*DAOCommitteeV1AgendaExecutedIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "AgendaExecuted", idRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1AgendaExecutedIterator{contract: _DAOCommitteeV1.contract, event: "AgendaExecuted", logs: logs, sub: sub}, nil
}

// WatchAgendaExecuted is a free log subscription operation binding the contract event 0x785146be3266678a3f4ea454b310ff1f8c91d0ad9a7997bcd0619940d4d67fe6.
//
// Solidity: event AgendaExecuted(uint256 indexed id, address[] target)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchAgendaExecuted(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1AgendaExecuted, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "AgendaExecuted", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1AgendaExecuted)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "AgendaExecuted", log); err != nil {
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

// ParseAgendaExecuted is a log parse operation binding the contract event 0x785146be3266678a3f4ea454b310ff1f8c91d0ad9a7997bcd0619940d4d67fe6.
//
// Solidity: event AgendaExecuted(uint256 indexed id, address[] target)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseAgendaExecuted(log types.Log) (*DAOCommitteeV1AgendaExecuted, error) {
	event := new(DAOCommitteeV1AgendaExecuted)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "AgendaExecuted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1AgendaVoteCastedIterator is returned from FilterAgendaVoteCasted and is used to iterate over the raw logs and unpacked data for AgendaVoteCasted events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1AgendaVoteCastedIterator struct {
	Event *DAOCommitteeV1AgendaVoteCasted // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1AgendaVoteCastedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1AgendaVoteCasted)
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
		it.Event = new(DAOCommitteeV1AgendaVoteCasted)
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
func (it *DAOCommitteeV1AgendaVoteCastedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1AgendaVoteCastedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1AgendaVoteCasted represents a AgendaVoteCasted event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1AgendaVoteCasted struct {
	From    common.Address
	Id      *big.Int
	Voting  *big.Int
	Comment string
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterAgendaVoteCasted is a free log retrieval operation binding the contract event 0xfa0761008653bc7bf9fa040fb7e07672ad3e17a976eb452c44e81dd782a6214b.
//
// Solidity: event AgendaVoteCasted(address indexed from, uint256 indexed id, uint256 voting, string comment)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterAgendaVoteCasted(opts *bind.FilterOpts, from []common.Address, id []*big.Int) (*DAOCommitteeV1AgendaVoteCastedIterator, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "AgendaVoteCasted", fromRule, idRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1AgendaVoteCastedIterator{contract: _DAOCommitteeV1.contract, event: "AgendaVoteCasted", logs: logs, sub: sub}, nil
}

// WatchAgendaVoteCasted is a free log subscription operation binding the contract event 0xfa0761008653bc7bf9fa040fb7e07672ad3e17a976eb452c44e81dd782a6214b.
//
// Solidity: event AgendaVoteCasted(address indexed from, uint256 indexed id, uint256 voting, string comment)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchAgendaVoteCasted(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1AgendaVoteCasted, from []common.Address, id []*big.Int) (event.Subscription, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "AgendaVoteCasted", fromRule, idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1AgendaVoteCasted)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "AgendaVoteCasted", log); err != nil {
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

// ParseAgendaVoteCasted is a log parse operation binding the contract event 0xfa0761008653bc7bf9fa040fb7e07672ad3e17a976eb452c44e81dd782a6214b.
//
// Solidity: event AgendaVoteCasted(address indexed from, uint256 indexed id, uint256 voting, string comment)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseAgendaVoteCasted(log types.Log) (*DAOCommitteeV1AgendaVoteCasted, error) {
	event := new(DAOCommitteeV1AgendaVoteCasted)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "AgendaVoteCasted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1CandidateContractCreatedIterator is returned from FilterCandidateContractCreated and is used to iterate over the raw logs and unpacked data for CandidateContractCreated events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1CandidateContractCreatedIterator struct {
	Event *DAOCommitteeV1CandidateContractCreated // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1CandidateContractCreatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1CandidateContractCreated)
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
		it.Event = new(DAOCommitteeV1CandidateContractCreated)
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
func (it *DAOCommitteeV1CandidateContractCreatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1CandidateContractCreatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1CandidateContractCreated represents a CandidateContractCreated event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1CandidateContractCreated struct {
	Candidate         common.Address
	CandidateContract common.Address
	Memo              string
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterCandidateContractCreated is a free log retrieval operation binding the contract event 0x7cf8db18d9a5c7f44156bfabdbb59ac982a8a004e461ca1b87ee71a5cdfbc5ef.
//
// Solidity: event CandidateContractCreated(address indexed candidate, address indexed candidateContract, string memo)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterCandidateContractCreated(opts *bind.FilterOpts, candidate []common.Address, candidateContract []common.Address) (*DAOCommitteeV1CandidateContractCreatedIterator, error) {

	var candidateRule []interface{}
	for _, candidateItem := range candidate {
		candidateRule = append(candidateRule, candidateItem)
	}
	var candidateContractRule []interface{}
	for _, candidateContractItem := range candidateContract {
		candidateContractRule = append(candidateContractRule, candidateContractItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "CandidateContractCreated", candidateRule, candidateContractRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1CandidateContractCreatedIterator{contract: _DAOCommitteeV1.contract, event: "CandidateContractCreated", logs: logs, sub: sub}, nil
}

// WatchCandidateContractCreated is a free log subscription operation binding the contract event 0x7cf8db18d9a5c7f44156bfabdbb59ac982a8a004e461ca1b87ee71a5cdfbc5ef.
//
// Solidity: event CandidateContractCreated(address indexed candidate, address indexed candidateContract, string memo)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchCandidateContractCreated(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1CandidateContractCreated, candidate []common.Address, candidateContract []common.Address) (event.Subscription, error) {

	var candidateRule []interface{}
	for _, candidateItem := range candidate {
		candidateRule = append(candidateRule, candidateItem)
	}
	var candidateContractRule []interface{}
	for _, candidateContractItem := range candidateContract {
		candidateContractRule = append(candidateContractRule, candidateContractItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "CandidateContractCreated", candidateRule, candidateContractRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1CandidateContractCreated)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "CandidateContractCreated", log); err != nil {
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

// ParseCandidateContractCreated is a log parse operation binding the contract event 0x7cf8db18d9a5c7f44156bfabdbb59ac982a8a004e461ca1b87ee71a5cdfbc5ef.
//
// Solidity: event CandidateContractCreated(address indexed candidate, address indexed candidateContract, string memo)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseCandidateContractCreated(log types.Log) (*DAOCommitteeV1CandidateContractCreated, error) {
	event := new(DAOCommitteeV1CandidateContractCreated)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "CandidateContractCreated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1ChangedMemberIterator is returned from FilterChangedMember and is used to iterate over the raw logs and unpacked data for ChangedMember events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1ChangedMemberIterator struct {
	Event *DAOCommitteeV1ChangedMember // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1ChangedMemberIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1ChangedMember)
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
		it.Event = new(DAOCommitteeV1ChangedMember)
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
func (it *DAOCommitteeV1ChangedMemberIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1ChangedMemberIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1ChangedMember represents a ChangedMember event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1ChangedMember struct {
	SlotIndex  *big.Int
	PrevMember common.Address
	NewMember  common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterChangedMember is a free log retrieval operation binding the contract event 0x663b98adf1afa777e36528b3293a057803f87ed00d2d2518dccfe5d7a6e99ccf.
//
// Solidity: event ChangedMember(uint256 indexed slotIndex, address prevMember, address indexed newMember)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterChangedMember(opts *bind.FilterOpts, slotIndex []*big.Int, newMember []common.Address) (*DAOCommitteeV1ChangedMemberIterator, error) {

	var slotIndexRule []interface{}
	for _, slotIndexItem := range slotIndex {
		slotIndexRule = append(slotIndexRule, slotIndexItem)
	}

	var newMemberRule []interface{}
	for _, newMemberItem := range newMember {
		newMemberRule = append(newMemberRule, newMemberItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "ChangedMember", slotIndexRule, newMemberRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1ChangedMemberIterator{contract: _DAOCommitteeV1.contract, event: "ChangedMember", logs: logs, sub: sub}, nil
}

// WatchChangedMember is a free log subscription operation binding the contract event 0x663b98adf1afa777e36528b3293a057803f87ed00d2d2518dccfe5d7a6e99ccf.
//
// Solidity: event ChangedMember(uint256 indexed slotIndex, address prevMember, address indexed newMember)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchChangedMember(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1ChangedMember, slotIndex []*big.Int, newMember []common.Address) (event.Subscription, error) {

	var slotIndexRule []interface{}
	for _, slotIndexItem := range slotIndex {
		slotIndexRule = append(slotIndexRule, slotIndexItem)
	}

	var newMemberRule []interface{}
	for _, newMemberItem := range newMember {
		newMemberRule = append(newMemberRule, newMemberItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "ChangedMember", slotIndexRule, newMemberRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1ChangedMember)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "ChangedMember", log); err != nil {
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

// ParseChangedMember is a log parse operation binding the contract event 0x663b98adf1afa777e36528b3293a057803f87ed00d2d2518dccfe5d7a6e99ccf.
//
// Solidity: event ChangedMember(uint256 indexed slotIndex, address prevMember, address indexed newMember)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseChangedMember(log types.Log) (*DAOCommitteeV1ChangedMember, error) {
	event := new(DAOCommitteeV1ChangedMember)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "ChangedMember", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1ChangedMemoIterator is returned from FilterChangedMemo and is used to iterate over the raw logs and unpacked data for ChangedMemo events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1ChangedMemoIterator struct {
	Event *DAOCommitteeV1ChangedMemo // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1ChangedMemoIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1ChangedMemo)
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
		it.Event = new(DAOCommitteeV1ChangedMemo)
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
func (it *DAOCommitteeV1ChangedMemoIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1ChangedMemoIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1ChangedMemo represents a ChangedMemo event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1ChangedMemo struct {
	CandidateContract common.Address
	NewMemo           string
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterChangedMemo is a free log retrieval operation binding the contract event 0xda033346b344f4675799a7ab4d837f0deb62d4afcdcaba4613913b4c25838cb3.
//
// Solidity: event ChangedMemo(address candidateContract, string newMemo)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterChangedMemo(opts *bind.FilterOpts) (*DAOCommitteeV1ChangedMemoIterator, error) {

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "ChangedMemo")
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1ChangedMemoIterator{contract: _DAOCommitteeV1.contract, event: "ChangedMemo", logs: logs, sub: sub}, nil
}

// WatchChangedMemo is a free log subscription operation binding the contract event 0xda033346b344f4675799a7ab4d837f0deb62d4afcdcaba4613913b4c25838cb3.
//
// Solidity: event ChangedMemo(address candidateContract, string newMemo)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchChangedMemo(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1ChangedMemo) (event.Subscription, error) {

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "ChangedMemo")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1ChangedMemo)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "ChangedMemo", log); err != nil {
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

// ParseChangedMemo is a log parse operation binding the contract event 0xda033346b344f4675799a7ab4d837f0deb62d4afcdcaba4613913b4c25838cb3.
//
// Solidity: event ChangedMemo(address candidateContract, string newMemo)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseChangedMemo(log types.Log) (*DAOCommitteeV1ChangedMemo, error) {
	event := new(DAOCommitteeV1ChangedMemo)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "ChangedMemo", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1ClaimedActivityRewardIterator is returned from FilterClaimedActivityReward and is used to iterate over the raw logs and unpacked data for ClaimedActivityReward events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1ClaimedActivityRewardIterator struct {
	Event *DAOCommitteeV1ClaimedActivityReward // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1ClaimedActivityRewardIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1ClaimedActivityReward)
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
		it.Event = new(DAOCommitteeV1ClaimedActivityReward)
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
func (it *DAOCommitteeV1ClaimedActivityRewardIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1ClaimedActivityRewardIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1ClaimedActivityReward represents a ClaimedActivityReward event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1ClaimedActivityReward struct {
	Candidate common.Address
	Receiver  common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterClaimedActivityReward is a free log retrieval operation binding the contract event 0xb15377c434dc1922cc2eb7d8950640960a05f0cf6d5dc9442de8414a9da2b308.
//
// Solidity: event ClaimedActivityReward(address indexed candidate, address receiver, uint256 amount)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterClaimedActivityReward(opts *bind.FilterOpts, candidate []common.Address) (*DAOCommitteeV1ClaimedActivityRewardIterator, error) {

	var candidateRule []interface{}
	for _, candidateItem := range candidate {
		candidateRule = append(candidateRule, candidateItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "ClaimedActivityReward", candidateRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1ClaimedActivityRewardIterator{contract: _DAOCommitteeV1.contract, event: "ClaimedActivityReward", logs: logs, sub: sub}, nil
}

// WatchClaimedActivityReward is a free log subscription operation binding the contract event 0xb15377c434dc1922cc2eb7d8950640960a05f0cf6d5dc9442de8414a9da2b308.
//
// Solidity: event ClaimedActivityReward(address indexed candidate, address receiver, uint256 amount)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchClaimedActivityReward(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1ClaimedActivityReward, candidate []common.Address) (event.Subscription, error) {

	var candidateRule []interface{}
	for _, candidateItem := range candidate {
		candidateRule = append(candidateRule, candidateItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "ClaimedActivityReward", candidateRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1ClaimedActivityReward)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "ClaimedActivityReward", log); err != nil {
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

// ParseClaimedActivityReward is a log parse operation binding the contract event 0xb15377c434dc1922cc2eb7d8950640960a05f0cf6d5dc9442de8414a9da2b308.
//
// Solidity: event ClaimedActivityReward(address indexed candidate, address receiver, uint256 amount)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseClaimedActivityReward(log types.Log) (*DAOCommitteeV1ClaimedActivityReward, error) {
	event := new(DAOCommitteeV1ClaimedActivityReward)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "ClaimedActivityReward", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1Layer2RegisteredIterator is returned from FilterLayer2Registered and is used to iterate over the raw logs and unpacked data for Layer2Registered events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1Layer2RegisteredIterator struct {
	Event *DAOCommitteeV1Layer2Registered // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1Layer2RegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1Layer2Registered)
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
		it.Event = new(DAOCommitteeV1Layer2Registered)
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
func (it *DAOCommitteeV1Layer2RegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1Layer2RegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1Layer2Registered represents a Layer2Registered event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1Layer2Registered struct {
	Candidate         common.Address
	CandidateContract common.Address
	Memo              string
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterLayer2Registered is a free log retrieval operation binding the contract event 0x0f401d1bd976f5304ef9cfa87aeb24d777c0e205fb87bbae1dc0f0293ba7976a.
//
// Solidity: event Layer2Registered(address indexed candidate, address indexed candidateContract, string memo)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterLayer2Registered(opts *bind.FilterOpts, candidate []common.Address, candidateContract []common.Address) (*DAOCommitteeV1Layer2RegisteredIterator, error) {

	var candidateRule []interface{}
	for _, candidateItem := range candidate {
		candidateRule = append(candidateRule, candidateItem)
	}
	var candidateContractRule []interface{}
	for _, candidateContractItem := range candidateContract {
		candidateContractRule = append(candidateContractRule, candidateContractItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "Layer2Registered", candidateRule, candidateContractRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1Layer2RegisteredIterator{contract: _DAOCommitteeV1.contract, event: "Layer2Registered", logs: logs, sub: sub}, nil
}

// WatchLayer2Registered is a free log subscription operation binding the contract event 0x0f401d1bd976f5304ef9cfa87aeb24d777c0e205fb87bbae1dc0f0293ba7976a.
//
// Solidity: event Layer2Registered(address indexed candidate, address indexed candidateContract, string memo)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchLayer2Registered(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1Layer2Registered, candidate []common.Address, candidateContract []common.Address) (event.Subscription, error) {

	var candidateRule []interface{}
	for _, candidateItem := range candidate {
		candidateRule = append(candidateRule, candidateItem)
	}
	var candidateContractRule []interface{}
	for _, candidateContractItem := range candidateContract {
		candidateContractRule = append(candidateContractRule, candidateContractItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "Layer2Registered", candidateRule, candidateContractRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1Layer2Registered)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "Layer2Registered", log); err != nil {
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

// ParseLayer2Registered is a log parse operation binding the contract event 0x0f401d1bd976f5304ef9cfa87aeb24d777c0e205fb87bbae1dc0f0293ba7976a.
//
// Solidity: event Layer2Registered(address indexed candidate, address indexed candidateContract, string memo)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseLayer2Registered(log types.Log) (*DAOCommitteeV1Layer2Registered, error) {
	event := new(DAOCommitteeV1Layer2Registered)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "Layer2Registered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1MemberBlacklistedIterator is returned from FilterMemberBlacklisted and is used to iterate over the raw logs and unpacked data for MemberBlacklisted events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1MemberBlacklistedIterator struct {
	Event *DAOCommitteeV1MemberBlacklisted // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1MemberBlacklistedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1MemberBlacklisted)
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
		it.Event = new(DAOCommitteeV1MemberBlacklisted)
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
func (it *DAOCommitteeV1MemberBlacklistedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1MemberBlacklistedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1MemberBlacklisted represents a MemberBlacklisted event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1MemberBlacklisted struct {
	Member    common.Address
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterMemberBlacklisted is a free log retrieval operation binding the contract event 0xf2f5dcb091f4d2c9dbd9481195a0713490b6db6f9df5dc695d1195b915769bc1.
//
// Solidity: event MemberBlacklisted(address indexed member, uint256 timestamp)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterMemberBlacklisted(opts *bind.FilterOpts, member []common.Address) (*DAOCommitteeV1MemberBlacklistedIterator, error) {

	var memberRule []interface{}
	for _, memberItem := range member {
		memberRule = append(memberRule, memberItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "MemberBlacklisted", memberRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1MemberBlacklistedIterator{contract: _DAOCommitteeV1.contract, event: "MemberBlacklisted", logs: logs, sub: sub}, nil
}

// WatchMemberBlacklisted is a free log subscription operation binding the contract event 0xf2f5dcb091f4d2c9dbd9481195a0713490b6db6f9df5dc695d1195b915769bc1.
//
// Solidity: event MemberBlacklisted(address indexed member, uint256 timestamp)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchMemberBlacklisted(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1MemberBlacklisted, member []common.Address) (event.Subscription, error) {

	var memberRule []interface{}
	for _, memberItem := range member {
		memberRule = append(memberRule, memberItem)
	}

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "MemberBlacklisted", memberRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1MemberBlacklisted)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "MemberBlacklisted", log); err != nil {
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

// ParseMemberBlacklisted is a log parse operation binding the contract event 0xf2f5dcb091f4d2c9dbd9481195a0713490b6db6f9df5dc695d1195b915769bc1.
//
// Solidity: event MemberBlacklisted(address indexed member, uint256 timestamp)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseMemberBlacklisted(log types.Log) (*DAOCommitteeV1MemberBlacklisted, error) {
	event := new(DAOCommitteeV1MemberBlacklisted)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "MemberBlacklisted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1RoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1RoleAdminChangedIterator struct {
	Event *DAOCommitteeV1RoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1RoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1RoleAdminChanged)
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
		it.Event = new(DAOCommitteeV1RoleAdminChanged)
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
func (it *DAOCommitteeV1RoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1RoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1RoleAdminChanged represents a RoleAdminChanged event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1RoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*DAOCommitteeV1RoleAdminChangedIterator, error) {

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

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1RoleAdminChangedIterator{contract: _DAOCommitteeV1.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1RoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1RoleAdminChanged)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseRoleAdminChanged(log types.Log) (*DAOCommitteeV1RoleAdminChanged, error) {
	event := new(DAOCommitteeV1RoleAdminChanged)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1RoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1RoleGrantedIterator struct {
	Event *DAOCommitteeV1RoleGranted // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1RoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1RoleGranted)
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
		it.Event = new(DAOCommitteeV1RoleGranted)
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
func (it *DAOCommitteeV1RoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1RoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1RoleGranted represents a RoleGranted event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1RoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*DAOCommitteeV1RoleGrantedIterator, error) {

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

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1RoleGrantedIterator{contract: _DAOCommitteeV1.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1RoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1RoleGranted)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseRoleGranted(log types.Log) (*DAOCommitteeV1RoleGranted, error) {
	event := new(DAOCommitteeV1RoleGranted)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// DAOCommitteeV1RoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1RoleRevokedIterator struct {
	Event *DAOCommitteeV1RoleRevoked // Event containing the contract specifics and raw log

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
func (it *DAOCommitteeV1RoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(DAOCommitteeV1RoleRevoked)
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
		it.Event = new(DAOCommitteeV1RoleRevoked)
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
func (it *DAOCommitteeV1RoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *DAOCommitteeV1RoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// DAOCommitteeV1RoleRevoked represents a RoleRevoked event raised by the DAOCommitteeV1 contract.
type DAOCommitteeV1RoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*DAOCommitteeV1RoleRevokedIterator, error) {

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

	logs, sub, err := _DAOCommitteeV1.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &DAOCommitteeV1RoleRevokedIterator{contract: _DAOCommitteeV1.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *DAOCommitteeV1RoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _DAOCommitteeV1.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(DAOCommitteeV1RoleRevoked)
				if err := _DAOCommitteeV1.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_DAOCommitteeV1 *DAOCommitteeV1Filterer) ParseRoleRevoked(log types.Log) (*DAOCommitteeV1RoleRevoked, error) {
	event := new(DAOCommitteeV1RoleRevoked)
	if err := _DAOCommitteeV1.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
