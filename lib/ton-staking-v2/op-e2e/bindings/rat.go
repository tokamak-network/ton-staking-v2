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

// RATConfigParams is an auto generated low-level Go binding around an user-defined struct.
type RATConfigParams struct {
	RatTriggerProbability    *big.Int
	EvidenceSubmissionPeriod *big.Int
	SlashingPenalty          *big.Int
	ValidatorBuffer          *big.Int
	MinimumThreshold         *big.Int
	MaxValidatorsPerL2       *big.Int
	ChallengeGameDuration    *big.Int
	SafetyBuffer             *big.Int
	Treasury                 common.Address
	AttentionCost            *big.Int
	RelaxedValidatorCheck    bool
}

// RATInitParams is an auto generated low-level Go binding around an user-defined struct.
type RATInitParams struct {
	SeigManager      common.Address
	Wton             common.Address
	Ton              common.Address
	Layer2Manager    common.Address
	L1BridgeRegistry common.Address
	Owner            common.Address
}

// RATABI is the input ABI used to generate the binding from.
const RATABI = "[{\"type\":\"function\",\"name\":\"accumulatedSlashings\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"activeTestCount\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"attentionCost\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"attentionTests\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"validatorAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"gameAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"bondAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"authorizedTrigger\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"batchToTestId\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"challengeGameDuration\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deactivateValidator\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"evidenceSubmissionPeriod\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"factoryByGame\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"gameToTestId\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getActiveValidatorCount\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAttentionTest\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"validatorAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"bondAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAttentionTestStatus\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAvailableCollateral\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCoffWithRelaxedCheck\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getDynamicCoff\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getDynamicMinimumCollateral\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getL2Validators\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinimumCollateral\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinimumCollateralWithRelaxedCheck\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRATCoinageBalance\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorCount\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorDeposit\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorMinCollateralForLayer2\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorRegistration\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"collateral\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validatorIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"isActive\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structRATInitParams\",\"components\":[{\"name\":\"seigManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"wton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"layer2Manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"l1BridgeRegistry\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isValidatorActive\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1BridgeRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"latestDeadlineTest\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2Manager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxValidatorsPerL2\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minimumThreshold\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ratTriggerProbability\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"registerValidator\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"relaxedValidatorCheck\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"resolveClaim\",\"inputs\":[{\"name\":\"_claimant\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safetyBuffer\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"seigManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setAttentionCost\",\"inputs\":[{\"name\":\"cost\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setAuthorizedTrigger\",\"inputs\":[{\"name\":\"trigger\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setChallengeGameDuration\",\"inputs\":[{\"name\":\"duration\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setConfig\",\"inputs\":[{\"name\":\"config\",\"type\":\"tuple\",\"internalType\":\"structRATConfigParams\",\"components\":[{\"name\":\"ratTriggerProbability\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"evidenceSubmissionPeriod\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"slashingPenalty\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validatorBuffer\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"minimumThreshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxValidatorsPerL2\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"challengeGameDuration\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"safetyBuffer\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"attentionCost\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"relaxedValidatorCheck\",\"type\":\"bool\",\"internalType\":\"bool\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setEvidenceSubmissionPeriod\",\"inputs\":[{\"name\":\"period\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setL1BridgeRegistry\",\"inputs\":[{\"name\":\"_l1BridgeRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMaxValidatorsPerL2\",\"inputs\":[{\"name\":\"maxValidators\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMinimumThreshold\",\"inputs\":[{\"name\":\"threshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setPaused\",\"inputs\":[{\"name\":\"_paused\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setRatTriggerProbability\",\"inputs\":[{\"name\":\"probability\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setRelaxedValidatorCheck\",\"inputs\":[{\"name\":\"relaxed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSafetyBuffer\",\"inputs\":[{\"name\":\"buffer\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSlashingPenalty\",\"inputs\":[{\"name\":\"penalty\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTreasury\",\"inputs\":[{\"name\":\"_treasury\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setValidatorBuffer\",\"inputs\":[{\"name\":\"buffer\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setValidatorReward\",\"inputs\":[{\"name\":\"_validatorReward\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slashingPenalty\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"submitEvidence\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"evidence\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"treasury\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"triggerAttentionTest\",\"inputs\":[{\"name\":\"gameAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"blockHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"validateSlashingPenalty\",\"inputs\":[{\"name\":\"n\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorBuffer\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorIndexes\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorRegistrations\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"lockedForRAT\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"pendingRewards\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"latestTestDeadline\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"validatorIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"isActive\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorReward\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorSystemConfigs\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdrawSlashingsToTreasury\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"wton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"AccumulatedSlashingsReset\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AttentionTestTriggered\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"gameAddress\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"indexed\":false,\"internalType\":\"uint32\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BondRestored\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"restoredAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositAdded\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EvidenceSubmitted\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"indexed\":false,\"internalType\":\"uint32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MaxValidatorsPerL2Updated\",\"inputs\":[{\"name\":\"newMaxValidators\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RelaxedValidatorCheckUpdated\",\"inputs\":[{\"name\":\"relaxed\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SlashingsWithdrawn\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"treasury\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorDeactivated\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorReactivated\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"collateral\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRegistered\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"depositAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"registrationId\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRestored\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorSlashed\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"slashedAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"removedFromSet\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false}]"

// RATBin is the compiled bytecode used for deploying new contracts.
var RATBin = "0x608060405234801561001057600080fd5b50613853806100206000396000f3fe608060405234801561001057600080fd5b506004361061039c5760003560e01c806375b94133116101eb578063cdf7cf1311610110578063f0f44260116100a8578063f0f4426014610986578063f120484e14610999578063f2fde38b146109ac578063f5ee070f146109bf578063f7107b44146109d2578063f92879db146109db578063f9560e4514610a10578063f983386b14610a39578063f9d271b814610a4c57600080fd5b8063cdf7cf13146108d6578063cf8f9110146108f6578063cfa424ea14610909578063d0d6b9b514610912578063d2e5bc7214610925578063d8c0ba5914610938578063ddef8e8514610940578063e1705cb614610960578063e54f62371461097357600080fd5b80639fca5169116101835780639fca51691461083f578063a0bfe1c614610852578063a4acc3ff14610865578063acccb08f14610878578063ba50b87914610881578063c0a08bde14610894578063c6be2df8146108a7578063cc48b947146108ba578063cd156819146108cd57600080fd5b806375b94133146107b657806375da30d0146107ce57806389f1ea64146107d75780638ca61113146107e05780638d62d949146107f35780638da5cb5b146108065780638dc3b28e146108195780638ffe8eaa1461058b57806394d645a81461082c57600080fd5b80633aace7f5116102d15780635c975abb116102695780635c975abb146106f457806361d027b314610708578063625924331461071b57806367058d29146107445780636a5ec2b8146107575780636ad83f911461076a5780636fb7f5581461077d5780636fc641e81461079057806371e0cdc7146107a357600080fd5b80633aace7f51461059e57806340dd80f8146105b157806341faedf5146105c457806344f1c99d146105cd5780634a859247146105ed5780634ad60241146106865780634e4a9a1b146106995780634eecc645146106c457806351567bc2146106eb57600080fd5b806316b5d5bd1161034457806316b5d5bd1461047357806316c38b3c146104935780631a693f5b146104a65780632c9e3798146104c65780632d6f4969146104cf578063319ad327146104e257806336c63d4614610565578063370e9e181461057857806339b62bd11461058b57600080fd5b80624fe2b4146103a157806303225879146103b6578063068c2e6e146103de5780630bec5691146103fe5780630c1da8df146104375780630caebb611461044a5780630fab007314610453578063117f45f914610460575b600080fd5b6103b46103af366004613260565b610a5f565b005b6103c96103c43660046132b9565b610c9d565b60405190151581526020015b60405180910390f35b6103f16103ec3660046132f2565b610cd5565b6040516103d5919061330f565b61042961040c36600461335c565b600560209081526000928352604080842090915290825290205481565b6040519081526020016103d5565b6103b46104453660046132f2565b610d4b565b61042960115481565b601c546103c99060ff1681565b6103b461046e3660046132f2565b610d97565b601554610486906001600160a01b031681565b6040516103d59190613391565b6103b46104a13660046133b3565b610de9565b6104b96104b43660046133d0565b610e31565b6040516103d59190613421565b61042960095481565b6104296104dd3660046132f2565b610e4f565b6105506104f03660046133d0565b6004602081905260009182526040909120805460018201546002830154600384015494840154600585015460068601546007909601546001600160a01b039586169786861697600160a01b90960463ffffffff1696909416949060ff1689565b6040516103d59998979695949392919061342f565b6103b46105733660046133d0565b610e6e565b6103b46105863660046132f2565b610e9d565b6104296105993660046132b9565b610ee9565b6104296105ac3660046132f2565b610eff565b6104296105bf3660046132f2565b610f2f565b61042960105481565b6104296105db3660046132f2565b60076020526000908152604090205481565b6106486105fb3660046132b9565b600060208181529281526040808220909352908152208054600182015460029092015490919067ffffffffffffffff811690600160401b810463ffffffff1690600160601b900460ff1685565b60408051958652602086019490945267ffffffffffffffff9092169284019290925263ffffffff90911660608301521515608082015260a0016103d5565b6103b46106943660046133d0565b611031565b6104296106a73660046132b9565b600260209081526000928352604080842090915290825290205481565b6106d76106d23660046133d0565b611060565b6040516103d5989796959493929190613494565b610429600c5481565b6019546103c990600160a81b900460ff1681565b601954610486906001600160a01b031681565b6104866107293660046132f2565b601b602052600090815260409020546001600160a01b031681565b6103b46107523660046133d0565b6110e2565b6104296107653660046132f2565b611111565b6103b46107783660046133d0565b611141565b601254610486906001600160a01b031681565b61042961079e3660046132b9565b611170565b6103b46107b13660046132f2565b611251565b601c546104869061010090046001600160a01b031681565b610429600d5481565b610429600a5481565b6103b46107ee3660046133d0565b6114aa565b601354610486906001600160a01b031681565b601754610486906001600160a01b031681565b6104866108273660046134ef565b6114d9565b6103b461083a3660046132f2565b611511565b6103b461084d3660046132f2565b611685565b6103b46108603660046133d0565b611854565b6103b46108733660046133b3565b6118da565b610429600f5481565b6103b461088f3660046132f2565b611945565b6103b46108a23660046133d0565b611ad4565b6104296108b53660046132f2565b611b03565b601454610486906001600160a01b031681565b61042960185481565b6104296108e43660046132f2565b60066020526000908152604090205481565b601a54610486906001600160a01b031681565b610429600e5481565b6103c96109203660046133d0565b611b33565b6103b46109333660046133d0565b611b8d565b610429611be8565b61042961094e3660046132f2565b60086020526000908152604090205481565b601654610486906001600160a01b031681565b6103b461098136600461351b565b611bf9565b6103b46109943660046132f2565b611e0d565b6104296109a73660046132f2565b611e59565b6103b46109ba3660046132f2565b611e89565b6103b46109cd3660046135ab565b611f1a565b610429600b5481565b6109ee6109e93660046132b9565b612089565b6040805193845263ffffffff90921660208401521515908201526060016103d5565b610429610a1e3660046132f2565b6001600160a01b031660009081526001602052604090205490565b6103b4610a473660046133d0565b6120e8565b6103b4610a5a3660046135c3565b612117565b601a5484906001600160a01b0316610a8a57604051633785806960e11b815260040160405180910390fd5b601a5460405163ebbbfdb560e01b81526000916001600160a01b03169063ebbbfdb590610abb903390600401613391565b602060405180830381865afa158015610ad8573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610afc91906135d6565b90506001600160a01b038116610b2557604051633785806960e11b815260040160405180910390fd5b816001600160a01b0316816001600160a01b031614610b5757604051633785806960e11b815260040160405180910390fd5b601954600160a81b900460ff1615610b8a5760405162461bcd60e51b8152600401610b81906135f3565b60405180910390fd5b6000676765c793fa10079d601b1b8442604051602001610bb4929190918252602082015260400190565b6040516020818303038152906040528051906020012060001c610bd79190613629565b9050600c548110610be85750610c94565b6001600160a01b0387166000908152600160208190526040822090810154909103610c14575050610c94565b6001600160a01b038816600090815260056020908152604080832063ffffffff8b1684529091529020548015610c5d576040516303e3427560e01b815260040160405180910390fd5b6000610c698a8861235f565b90506001600160a01b038116610c825750505050610c94565b610c8f8b8b8b8b85612403565b505050505b50505050505050565b6001600160a01b0381811660009081526020818152604080832093861683529290522060020154600160601b900460ff165b92915050565b6001600160a01b038116600090815260016020908152604091829020805483518184028101840190945280845260609392830182828015610d3f57602002820191906000526020600020905b81546001600160a01b03168152600190910190602001808311610d21575b50505050509050919050565b6017546001600160a01b03163314610d755760405162461bcd60e51b8152600401610b819061363d565b601a80546001600160a01b0319166001600160a01b0392909216919091179055565b6017546001600160a01b03163314610dc15760405162461bcd60e51b8152600401610b819061363d565b601c80546001600160a01b0390921661010002610100600160a81b0319909216919091179055565b6017546001600160a01b03163314610e135760405162461bcd60e51b8152600401610b819061363d565b60198054911515600160a81b0260ff60a81b19909216919091179055565b6000818152600460205260408120610e48816124ef565b9392505050565b6001600160a01b03166000908152600160208190526040909120015490565b6017546001600160a01b03163314610e985760405162461bcd60e51b8152600401610b819061363d565b600f55565b6017546001600160a01b03163314610ec75760405162461bcd60e51b8152600401610b819061363d565b601680546001600160a01b0319166001600160a01b0392909216919091179055565b600080610ef684846125c3565b50949350505050565b6001600160a01b038116600090815260016020819052604082200154808203610f26575060015b610e48816126d1565b601554604051631bb3313560e01b815260009182916001600160a01b0390911690631bb3313590610f64908690600401613391565b602060405180830381865afa158015610f81573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610fa591906135d6565b90506001600160a01b038116610fbe5750600092915050565b6012546040516367265c3b60e11b81526001600160a01b039091169063ce4cb87690610ff09084903090600401613660565b602060405180830381865afa15801561100d573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610e48919061367a565b6017546001600160a01b0316331461105b5760405162461bcd60e51b8152600401610b819061363d565b601155565b600081815260046020819052604082208054600182015460038301549383015460058401546006850154879687968796879687968796879694956001600160a01b039485169594841694600160a01b90940463ffffffff1693909291906110c6886124ef565b9850985098509850985098509850985050919395975091939597565b6017546001600160a01b0316331461110c5760405162461bcd60e51b8152600401610b819061363d565b600d55565b6001600160a01b038116600090815260016020819052604082200154808203611138575060015b610e48816126e9565b6017546001600160a01b0316331461116b5760405162461bcd60e51b8152600401610b819061363d565b600b55565b60155460405163177d7ecf60e21b815260009182916001600160a01b0390911690635df5fb3c906111a5908790600401613391565b6040805180830381865afa1580156111c1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906111e59190613693565b5090506001600160a01b038116611200576000915050610ccf565b6001600160a01b0381811660009081526020818152604080832093871683529290522060020154600160601b900460ff16156112475761123f81610eff565b915050610ccf565b5060009392505050565b6019546001600160a01b031661129c5760405162461bcd60e51b815260206004820152601060248201526f1d1c99585cdd5c9e481b9bdd081cd95d60821b6044820152606401610b81565b6011546010546001600160a01b0383166000908152600760205260408120549092916112c7916136d8565b6112d191906136d8565b905080421161131e5760405162461bcd60e51b81526020600482015260196024820152781c195b991a5b99c81d195cdd1cc81b9bdd08195e1c1a5c9959603a1b6044820152606401610b81565b600061132983612708565b6012546040516367265c3b60e11b81529192506000916001600160a01b039091169063ce4cb876906113619085903090600401613660565b602060405180830381865afa15801561137e573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906113a2919061367a565b9050600081116113ef5760405162461bcd60e51b81526020600482015260186024820152776e6f20736c617368696e677320746f20776974686472617760401b6044820152606401610b81565b601254601954604051630172415760e41b81526001600160a01b03928316926317241570926114289287929091169086906004016136eb565b600060405180830381600087803b15801561144257600080fd5b505af1158015611456573d6000803e3d6000fd5b50506019546040518481526001600160a01b0391821693508582169250908716907fae1cbfa544938580fc41f97c3cd461450c2a221c16dad6d1896e350c51c2b5f89060200160405180910390a450505050565b6017546001600160a01b031633146114d45760405162461bcd60e51b8152600401610b819061363d565b601055565b600360205281600052604060002081815481106114f557600080fd5b6000918252602090912001546001600160a01b03169150829050565b336000908152601b60205260409020546001600160a01b03166115315750565b336000908152600860205260409020548061154a575050565b600081815260046020526040902080546001600160a01b0384811691161461157157505050565b6001600782015460ff16600581111561158c5761158c6133e9565b1461159657505050565b60105481600601546115a891906136d8565b4211156115b457505050565b60078101805460ff1916600417905560018101546000906115dd906001600160a01b0316612708565b90506115ee818584600401546127a7565b60018201546001600160a01b039081166000818152602081815260408083209489168352939052919091209061162690868385612809565b60018301546004840154604080516001600160a01b0386811682526020820193909352928216929188169187917f2327e8a868d6be4a9d13dc1c06ddedf7ac7f3e7ed53803bf31da5c7349f82f01910160405180910390a45050505050565b601954600160a01b900460ff16156116af5760405162461bcd60e51b8152600401610b819061370f565b6019805460ff60a01b1916600160a01b1790819055600160a81b900460ff16156116eb5760405162461bcd60e51b8152600401610b81906135f3565b601260009054906101000a90046001600160a01b03166001600160a01b031663067ccc0a6040518163ffffffff1660e01b8152600401602060405180830381865afa15801561173e573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611762919061372f565b61177f57604051636f7049f560e01b815260040160405180910390fd5b6001600160a01b0381166117a65760405163e867588d60e01b815260040160405180910390fd5b6001600160a01b03811660009081526020818152604080832033845290915290206002810154600160601b900460ff16156117f45760405163173f3ea160e21b815260040160405180910390fd5b60008061180133856125c3565b91509150600061181085610eff565b905080831015611833576040516305f593dd60e11b815260040160405180910390fd5b6118403386868686612a01565b50506019805460ff60a01b19169055505050565b6017546001600160a01b0316331461187e5760405162461bcd60e51b8152600401610b819061363d565b6000811161189e5760405162461bcd60e51b8152600401610b819061374c565b600e8190556040518181527fa03f0d48c0ef0e0b6916f6c0f9e415d7319a1ea4a09ca66e68f473939ee2b10c906020015b60405180910390a150565b6017546001600160a01b031633146119045760405162461bcd60e51b8152600401610b819061363d565b601c805460ff19168215159081179091556040519081527ffe0f8833f7cc6034e316816ad11b5e0f8ba6cb0bb01b25978652e8bb02b682ff906020016118cf565b601954600160a01b900460ff161561196f5760405162461bcd60e51b8152600401610b819061370f565b6019805460ff60a01b1916600160a01b1790556001600160a01b03811660009081526020818152604080832033845290915290206002810154600160601b900460ff166119cf57604051634385fe5160e11b815260040160405180910390fd5b601c5461010090046001600160a01b031615611a4e57601c5460405163010ba6ff60e41b81526101009091046001600160a01b0316906310ba6ff090611a1b9033908690600401613660565b600060405180830381600087803b158015611a3557600080fd5b505af1158015611a49573d6000803e3d6000fd5b505050505b611a588233612bdf565b60028101805464ffffffffff60401b191690556000611a7683612708565b9050806001600160a01b0316836001600160a01b0316336001600160a01b03167f36a712493202476d322fa302e9c27e6632bd4dbbe9840b0043a538893cb5422060405160405180910390a450506019805460ff60a01b1916905550565b6017546001600160a01b03163314611afe5760405162461bcd60e51b8152600401610b819061363d565b600955565b6001600160a01b038116600090815260016020819052604082200154808203611b2a575060015b610e4881612d5b565b6000600c5460001480611b44575081155b15611b5157506000919050565b676765c793fa10079d601b1b82600954611b6b9190613783565b611b759190613783565b600c54600a54611b859190613783565b101592915050565b6017546001600160a01b03163314611bb75760405162461bcd60e51b8152600401610b819061363d565b676765c793fa10079d601b1b811115611be35760405163818a07b160e01b815260040160405180910390fd5b600c55565b6000611bf46001612dc8565b905090565b601954600160a01b900460ff1615611c235760405162461bcd60e51b8152600401610b819061370f565b6019805460ff60a01b1916600160a01b1790819055600160a81b900460ff1615611c5f5760405162461bcd60e51b8152600401610b81906135f3565b6001600160a01b038416600090815260056020908152604080832063ffffffff8716845290915290205480611ca75760405163dc87ad5960e01b815260040160405180910390fd5b600081815260046020526040902080546001600160a01b03163314611cdf5760405163911feff760e01b815260040160405180910390fd5b6001600782015460ff166005811115611cfa57611cfa6133e9565b14611d1857604051634136d4f760e01b815260040160405180910390fd5b8060060154421115611d3d5760405163022e778360e61b815260040160405180910390fd5b611d4c81600301548585612dd6565b60078101805460ff191660031790556000611d6687612708565b9050611d77813384600401546127a7565b6001600160a01b03871660009081526020818152604080832033808552925290912090611da79089908385612809565b604080516001600160a01b03848116825263ffffffff8a1660208301528a1691339187917fd5071c9f488cc0aa883e3bc1547c20c8466a9639cfed6db4c47ea8371d174c12910160405180910390a450506019805460ff60a01b19169055505050505050565b6017546001600160a01b03163314611e375760405162461bcd60e51b8152600401610b819061363d565b601980546001600160a01b0319166001600160a01b0392909216919091179055565b6001600160a01b038116600090815260016020819052604082200154808203611e80575060015b610e4881612dc8565b6017546001600160a01b03163314611eb35760405162461bcd60e51b8152600401610b819061363d565b6001600160a01b038116611ef85760405162461bcd60e51b815260206004820152600c60248201526b7a65726f206164647265737360a01b6044820152606401610b81565b601780546001600160a01b0319166001600160a01b0392909216919091179055565b6012546001600160a01b031615611f695760405162461bcd60e51b8152602060048201526013602482015272185b1c9958591e481a5b9a5d1a585b1a5e9959606a1b6044820152606401610b81565b611f7660208201826132f2565b601280546001600160a01b0319166001600160a01b0392909216919091179055611fa660408201602083016132f2565b601380546001600160a01b0319166001600160a01b0392909216919091179055611fd660608201604083016132f2565b601480546001600160a01b0319166001600160a01b039290921691909117905561200660808201606083016132f2565b601580546001600160a01b0319166001600160a01b039290921691909117905561203660a08201608083016132f2565b601a80546001600160a01b0319166001600160a01b039290921691909117905561206660c0820160a083016132f2565b601780546001600160a01b0319166001600160a01b039290921691909117905550565b6001600160a01b038082166000908152602081815260408083209386168352929052908120819081906120bc86866125c3565b50600291909101549096600160401b820463ffffffff169650600160601b90910460ff16945092505050565b6017546001600160a01b031633146121125760405162461bcd60e51b8152600401610b819061363d565b600a55565b6017546001600160a01b031633146121415760405162461bcd60e51b8152600401610b819061363d565b80351580159061215d5750676765c793fa10079d601b1b813511155b61219f5760405162461bcd60e51b8152602060048201526013602482015272696e76616c69642070726f626162696c69747960681b6044820152606401610b81565b60008160200135116121ed5760405162461bcd60e51b81526020600482015260176024820152761a5b9d985b1a5908195d9a59195b98d9481c195c9a5bd9604a1b6044820152606401610b81565b600081604001351161223c5760405162461bcd60e51b8152602060048201526018602482015277696e76616c696420736c617368696e672070656e616c747960401b6044820152606401610b81565b61224e606082013560408301356136d8565b8160800135101561229d5760405162461bcd60e51b81526020600482015260196024820152781a5b9d985b1a59081b5a5b9a5b5d5b481d1a1c995cda1bdb19603a1b6044820152606401610b81565b60008160a00135116122c15760405162461bcd60e51b8152600401610b819061374c565b8035600c556020810135600f556040810135600a556060810135600b556080810135600d5560a0810135600e5560c081013560105560e0810135601155612310610120820161010083016132f2565b601980546001600160a01b0319166001600160a01b039290921691909117905561012081013560095561234b610160820161014083016133b3565b601c805460ff191691151591909117905550565b6001600160a01b0382166000908152600160205260408120805480830361238b57600092505050610ccf565b60008185426040516020016123aa929190918252602082015260400190565b6040516020818303038152906040528051906020012060001c6123cd9190613629565b90508260000181815481106123e4576123e461379a565b6000918252602090912001546001600160a01b03169695505050505050565b6001600160a01b038085166000908152602081815260408083209385168352929052908120908061243484886125c3565b91509150600061244388610e4f565b905080600003612451575060015b600061245c826126e9565b90508360000361247c5761247289878786612e19565b50505050506124e8565b808410156124875750825b601c5460009060ff1661249c57600b5461249f565b60005b6124a8846126e9565b6124b291906136d8565b9050806124bf83876137b0565b10156124d1576124d18a888887612e19565b506124e28a8a8a8a8a868b8a612ef7565b50505050505b5050505050565b60006003600783015460ff16600581111561250c5761250c6133e9565b148061253057506004600783015460ff16600581111561252e5761252e6133e9565b145b8061255357506005600783015460ff166005811115612551576125516133e9565b145b1561256357506007015460ff1690565b6001600783015460ff16600581111561257e5761257e6133e9565b036125b857601054826006015461259591906136d8565b4211156125a457506005919050565b81600601544211156125b857506002919050565b506007015460ff1690565b601554604051631bb3313560e01b815260009182916001600160a01b0390911690631bb33135906125f8908690600401613391565b602060405180830381865afa158015612615573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061263991906135d6565b90506001600160a01b038116612654575060009050806126ca565b6012546040516367265c3b60e11b81526001600160a01b039091169063ce4cb876906126869084908890600401613660565b602060405180830381865afa1580156126a3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906126c7919061367a565b91505b9250929050565b6000600b546126df83612d5b565b610ccf91906136d8565b601c5460009060ff16156126ff575050600a5490565b610ccf82612d5b565b601554604051631bb3313560e01b815260009182916001600160a01b0390911690631bb331359061273d908690600401613391565b602060405180830381865afa15801561275a573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061277e91906135d6565b90506001600160a01b038116610ccf5760405163764efddb60e01b815260040160405180910390fd5b60125460405163735dd74b60e01b81526001600160a01b039091169063735dd74b906127db908690869086906004016136eb565b600060405180830381600087803b1580156127f557600080fd5b505af1158015610c94573d6000803e3d6000fd5b6002820154600160601b900460ff166129fb57600061282884866125c3565b509050600061283686610e4f565b905080600003612844575060015b601c5460009060ff1661285957600b5461285c565b60005b612865836126e9565b61286f91906136d8565b9050808310610c94576001600160a01b038781166000908152600160208181526040832080548084018255818552918420820180546001600160a01b031916958c1695909517909455908301805491926128c8836137c3565b90915550506002808801805460ff60601b1963ffffffff8516600160401b021664ffffffffff60401b1990911617600160601b1790556001600160a01b03808b166000908152602092835260408082208c8416835290935291909120829055601c546101009004161561299e57601c5460405163b9c2437560e01b81526101009091046001600160a01b03169063b9c243759061296b908b908d90600401613660565b600060405180830381600087803b15801561298557600080fd5b505af1158015612999573d6000803e3d6000fd5b505050505b856001600160a01b0316896001600160a01b0316896001600160a01b03167f99b9d8dec460eecfed8de638ceef05e3aa56696d3166cea3029fce48847a9e1b886040516129ed91815260200190565b60405180910390a450505050505b50505050565b6001600160a01b03841660009081526001602052604090208054600e548110612a3d5760405163ad8f042960e01b815260040160405180910390fd5b81546001808201845560008481526020812090920180546001600160a01b0319166001600160a01b038b161790558301805491612a79836137c3565b90915550506002808601805460ff60601b1963ffffffff8516600160401b021664ffffffffff60401b1990911617600160601b1790556001600160a01b038088166000818152602093845260408082208c851683528552808220869055600385528120805460018101825590825293902090920180546001600160a01b031916909217909155601c5461010090041615612b7657601c5460405163e44d3ccd60e01b81526101009091046001600160a01b03169063e44d3ccd90612b43908a908a90600401613660565b600060405180830381600087803b158015612b5d57600080fd5b505af1158015612b71573d6000803e3d6000fd5b505050505b826001600160a01b0316866001600160a01b0316886001600160a01b03167f317f78b7f1495be7f160c255693f09ccbd5367aa7acd721aa14eb14308da785c8785604051612bce929190918252602082015260400190565b60405180910390a450505050505050565b6001600160a01b038083166000908152600160208181526040808420600283528185209587168552949091528220548354909291612c1c916137b0565b9050808214612ce1576000836000018281548110612c3c57612c3c61379a565b60009182526020909120015484546001600160a01b0390911691508190859085908110612c6b57612c6b61379a565b600091825260208083209190910180546001600160a01b0319166001600160a01b0394851617905588831680835260028083526040808520969095168085529583528484208890559083528282528383209483529390522001805463ffffffff60401b1916600160401b63ffffffff8516021790555b8254839080612cf257612cf26137dc565b600082815260208120820160001990810180546001600160a01b031916905590910190915560018401805491612d27836137f2565b9091555050506001600160a01b03938416600090815260026020908152604080832095909616825293909352505090812055565b600a54600954600c5460009291908115801590612d785750600081115b15612dbf57600081676765c793fa10079d601b1b612d968886613783565b612da09190613783565b612daa9190613809565b905083811115612dbd5795945050505050565b505b50909392505050565b6000600b546126df836126e9565b80612e145760405162461bcd60e51b815260206004820152600e60248201526d456d7074792065766964656e636560901b6044820152606401610b81565b505050565b601c5461010090046001600160a01b031615612e9857601c5460405163010ba6ff60e41b81526101009091046001600160a01b0316906310ba6ff090612e659086908890600401613660565b600060405180830381600087803b158015612e7f57600080fd5b505af1158015612e93573d6000803e3d6000fd5b505050505b612ea28484612bdf565b60028201805464ffffffffff60401b191690556040516001600160a01b0380831691868216918616907f36a712493202476d322fa302e9c27e6632bd4dbbe9840b0043a538893cb5422090600090a450505050565b6040516bffffffffffffffffffffffff19606089811b821660208401526001600160e01b031960e08a901b16603484015286901b16603882015242604c820152600090606c016040516020818303038152906040528051906020012090506000600f5442612f6591906136d8565b6001600160a01b038b166000908152601b6020526040902080546001600160a01b03191633179055600285015490915067ffffffffffffffff9081169082161115612fca5760028401805467ffffffffffffffff191667ffffffffffffffff83161790555b604051806101200160405280876001600160a01b031681526020018a6001600160a01b031681526020018963ffffffff1681526020018b6001600160a01b031681526020018881526020018681526020014281526020018281526020016001600581111561303a5761303a6133e9565b9052600083815260046020818152604092839020845181546001600160a01b039182166001600160a01b031991821617835592860151600180840180549789015163ffffffff16600160a01b026001600160c01b0319909816928416929092179690961790556060860151600283018054919092169316929092179091556080840151600382015560a08401519181019190915560c083015160058083019190915560e0840151600683015561010084015160078301805493949193909260ff1990911691908490811115613111576131116133e9565b021790555050506001600160a01b038916600081815260056020908152604080832063ffffffff8d1684528252808320869055928252600790522054811115613170576001600160a01b03891660009081526007602052604090208190555b6001600160a01b038a1660009081526008602052604090208290556131968387876131fb565b604080516001600160a01b038c8116825263ffffffff8b166020830152918101839052818b169188169084907fcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c389060600160405180910390a450505050505050505050565b601254604051633862a49b60e11b81526001600160a01b03909116906370c54936906127db908690869086906004016136eb565b6001600160a01b038116811461324457600080fd5b50565b803563ffffffff8116811461325b57600080fd5b919050565b600080600080600060a0868803121561327857600080fd5b85356132838161322f565b945060208601356132938161322f565b93506132a160408701613247565b94979396509394606081013594506080013592915050565b600080604083850312156132cc57600080fd5b82356132d78161322f565b915060208301356132e78161322f565b809150509250929050565b60006020828403121561330457600080fd5b8135610e488161322f565b6020808252825182820181905260009190848201906040850190845b818110156133505783516001600160a01b03168352928401929184019160010161332b565b50909695505050505050565b6000806040838503121561336f57600080fd5b823561337a8161322f565b915061338860208401613247565b90509250929050565b6001600160a01b0391909116815260200190565b801515811461324457600080fd5b6000602082840312156133c557600080fd5b8135610e48816133a5565b6000602082840312156133e257600080fd5b5035919050565b634e487b7160e01b600052602160045260246000fd5b6006811061341d57634e487b7160e01b600052602160045260246000fd5b9052565b60208101610ccf82846133ff565b6001600160a01b038a81168252898116602083015263ffffffff89166040830152871660608201526080810186905260a0810185905260c0810184905260e0810183905261012081016134866101008301846133ff565b9a9950505050505050505050565b6001600160a01b0389811682528816602082015263ffffffff87166040820152606081018690526080810185905260a0810184905260c0810183905261010081016134e260e08301846133ff565b9998505050505050505050565b6000806040838503121561350257600080fd5b823561350d8161322f565b946020939093013593505050565b6000806000806060858703121561353157600080fd5b843561353c8161322f565b935061354a60208601613247565b9250604085013567ffffffffffffffff8082111561356757600080fd5b818701915087601f83011261357b57600080fd5b81358181111561358a57600080fd5b88602082850101111561359c57600080fd5b95989497505060200194505050565b600060c082840312156135bd57600080fd5b50919050565b600061016082840312156135bd57600080fd5b6000602082840312156135e857600080fd5b8151610e488161322f565b6020808252600690820152651c185d5cd95960d21b604082015260600190565b634e487b7160e01b600052601260045260246000fd5b60008261363857613638613613565b500690565b6020808252600990820152683737ba1037bbb732b960b91b604082015260600190565b6001600160a01b0392831681529116602082015260400190565b60006020828403121561368c57600080fd5b5051919050565b600080604083850312156136a657600080fd5b82516136b18161322f565b60208401519092506132e78161322f565b634e487b7160e01b600052601160045260246000fd5b80820180821115610ccf57610ccf6136c2565b6001600160a01b039384168152919092166020820152604081019190915260600190565b6020808252600690820152651b1bd8dad95960d21b604082015260600190565b60006020828403121561374157600080fd5b8151610e48816133a5565b6020808252601a908201527f696e76616c6964206d617856616c696461746f72735065724c32000000000000604082015260600190565b8082028115828204841417610ccf57610ccf6136c2565b634e487b7160e01b600052603260045260246000fd5b81810381811115610ccf57610ccf6136c2565b6000600182016137d5576137d56136c2565b5060010190565b634e487b7160e01b600052603160045260246000fd5b600081613801576138016136c2565b506000190190565b60008261381857613818613613565b50049056fea264697066735822122058914a54ec111867ea1afcd3ec02eea02906a8c4cd1e8aa96087d4b7ef5ecadf64736f6c63430008130033"

// DeployRAT deploys a new Ethereum contract, binding an instance of RAT to it.
func DeployRAT(auth *bind.TransactOpts, backend bind.ContractBackend) (common.Address, *types.Transaction, *RAT, error) {
	parsed, err := abi.JSON(strings.NewReader(RATABI))
	if err != nil {
		return common.Address{}, nil, nil, err
	}

	address, tx, contract, err := bind.DeployContract(auth, parsed, common.FromHex(RATBin), backend)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &RAT{RATCaller: RATCaller{contract: contract}, RATTransactor: RATTransactor{contract: contract}, RATFilterer: RATFilterer{contract: contract}}, nil
}

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

// RATSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type RATSession struct {
	Contract     *RAT              // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// RATCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type RATCallerSession struct {
	Contract *RATCaller    // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// RATTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type RATTransactorSession struct {
	Contract     *RATTransactor    // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// RATRaw is an auto generated low-level Go binding around an Ethereum contract.
type RATRaw struct {
	Contract *RAT // Generic contract binding to access the raw methods on
}

// RATCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type RATCallerRaw struct {
	Contract *RATCaller // Generic read-only contract binding to access the raw methods on
}

// RATTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type RATTransactorRaw struct {
	Contract *RATTransactor // Generic write-only contract binding to access the raw methods on
}

// NewRAT creates a new instance of RAT, bound to a specific deployed contract.
func NewRAT(address common.Address, backend bind.ContractBackend) (*RAT, error) {
	contract, err := bindRAT(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &RAT{RATCaller: RATCaller{contract: contract}, RATTransactor: RATTransactor{contract: contract}, RATFilterer: RATFilterer{contract: contract}}, nil
}

// NewRATCaller creates a new read-only instance of RAT, bound to a specific deployed contract.
func NewRATCaller(address common.Address, caller bind.ContractCaller) (*RATCaller, error) {
	contract, err := bindRAT(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &RATCaller{contract: contract}, nil
}

// NewRATTransactor creates a new write-only instance of RAT, bound to a specific deployed contract.
func NewRATTransactor(address common.Address, transactor bind.ContractTransactor) (*RATTransactor, error) {
	contract, err := bindRAT(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &RATTransactor{contract: contract}, nil
}

// NewRATFilterer creates a new log filterer instance of RAT, bound to a specific deployed contract.
func NewRATFilterer(address common.Address, filterer bind.ContractFilterer) (*RATFilterer, error) {
	contract, err := bindRAT(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &RATFilterer{contract: contract}, nil
}

// bindRAT binds a generic wrapper to an already deployed contract.
func bindRAT(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(RATABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RAT *RATRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RAT.Contract.RATCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RAT *RATRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RAT.Contract.RATTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RAT *RATRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RAT.Contract.RATTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RAT *RATCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RAT.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RAT *RATTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RAT.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RAT *RATTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RAT.Contract.contract.Transact(opts, method, params...)
}

// AccumulatedSlashings is a free data retrieval call binding the contract method 0xcd156819.
//
// Solidity: function accumulatedSlashings() view returns(uint256)
func (_RAT *RATCaller) AccumulatedSlashings(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "accumulatedSlashings")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AccumulatedSlashings is a free data retrieval call binding the contract method 0xcd156819.
//
// Solidity: function accumulatedSlashings() view returns(uint256)
func (_RAT *RATSession) AccumulatedSlashings() (*big.Int, error) {
	return _RAT.Contract.AccumulatedSlashings(&_RAT.CallOpts)
}

// AccumulatedSlashings is a free data retrieval call binding the contract method 0xcd156819.
//
// Solidity: function accumulatedSlashings() view returns(uint256)
func (_RAT *RATCallerSession) AccumulatedSlashings() (*big.Int, error) {
	return _RAT.Contract.AccumulatedSlashings(&_RAT.CallOpts)
}

// ActiveTestCount is a free data retrieval call binding the contract method 0xcdf7cf13.
//
// Solidity: function activeTestCount(address ) view returns(uint256)
func (_RAT *RATCaller) ActiveTestCount(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "activeTestCount", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ActiveTestCount is a free data retrieval call binding the contract method 0xcdf7cf13.
//
// Solidity: function activeTestCount(address ) view returns(uint256)
func (_RAT *RATSession) ActiveTestCount(arg0 common.Address) (*big.Int, error) {
	return _RAT.Contract.ActiveTestCount(&_RAT.CallOpts, arg0)
}

// ActiveTestCount is a free data retrieval call binding the contract method 0xcdf7cf13.
//
// Solidity: function activeTestCount(address ) view returns(uint256)
func (_RAT *RATCallerSession) ActiveTestCount(arg0 common.Address) (*big.Int, error) {
	return _RAT.Contract.ActiveTestCount(&_RAT.CallOpts, arg0)
}

// AttentionCost is a free data retrieval call binding the contract method 0x2c9e3798.
//
// Solidity: function attentionCost() view returns(uint256)
func (_RAT *RATCaller) AttentionCost(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "attentionCost")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AttentionCost is a free data retrieval call binding the contract method 0x2c9e3798.
//
// Solidity: function attentionCost() view returns(uint256)
func (_RAT *RATSession) AttentionCost() (*big.Int, error) {
	return _RAT.Contract.AttentionCost(&_RAT.CallOpts)
}

// AttentionCost is a free data retrieval call binding the contract method 0x2c9e3798.
//
// Solidity: function attentionCost() view returns(uint256)
func (_RAT *RATCallerSession) AttentionCost() (*big.Int, error) {
	return _RAT.Contract.AttentionCost(&_RAT.CallOpts)
}

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
//
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, address gameAddress, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATCaller) AttentionTests(opts *bind.CallOpts, arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	GameAddress      common.Address
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "attentionTests", arg0)

	outstruct := new(struct {
		ValidatorAddress common.Address
		SystemConfig     common.Address
		BatchIndex       uint32
		GameAddress      common.Address
		BatchHash        [32]byte
		BondAmount       *big.Int
		CreatedAt        *big.Int
		Deadline         *big.Int
		Status           uint8
	})

	outstruct.ValidatorAddress = out[0].(common.Address)
	outstruct.SystemConfig = out[1].(common.Address)
	outstruct.BatchIndex = out[2].(uint32)
	outstruct.GameAddress = out[3].(common.Address)
	outstruct.BatchHash = out[4].([32]byte)
	outstruct.BondAmount = out[5].(*big.Int)
	outstruct.CreatedAt = out[6].(*big.Int)
	outstruct.Deadline = out[7].(*big.Int)
	outstruct.Status = out[8].(uint8)

	return *outstruct, err

}

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
//
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, address gameAddress, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATSession) AttentionTests(arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	GameAddress      common.Address
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	return _RAT.Contract.AttentionTests(&_RAT.CallOpts, arg0)
}

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
//
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, address gameAddress, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATCallerSession) AttentionTests(arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	GameAddress      common.Address
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	return _RAT.Contract.AttentionTests(&_RAT.CallOpts, arg0)
}

// AuthorizedTrigger is a free data retrieval call binding the contract method 0xe1705cb6.
//
// Solidity: function authorizedTrigger() view returns(address)
func (_RAT *RATCaller) AuthorizedTrigger(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "authorizedTrigger")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// AuthorizedTrigger is a free data retrieval call binding the contract method 0xe1705cb6.
//
// Solidity: function authorizedTrigger() view returns(address)
func (_RAT *RATSession) AuthorizedTrigger() (common.Address, error) {
	return _RAT.Contract.AuthorizedTrigger(&_RAT.CallOpts)
}

// AuthorizedTrigger is a free data retrieval call binding the contract method 0xe1705cb6.
//
// Solidity: function authorizedTrigger() view returns(address)
func (_RAT *RATCallerSession) AuthorizedTrigger() (common.Address, error) {
	return _RAT.Contract.AuthorizedTrigger(&_RAT.CallOpts)
}

// BatchToTestId is a free data retrieval call binding the contract method 0x0bec5691.
//
// Solidity: function batchToTestId(address , uint32 ) view returns(bytes32)
func (_RAT *RATCaller) BatchToTestId(opts *bind.CallOpts, arg0 common.Address, arg1 uint32) ([32]byte, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "batchToTestId", arg0, arg1)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// BatchToTestId is a free data retrieval call binding the contract method 0x0bec5691.
//
// Solidity: function batchToTestId(address , uint32 ) view returns(bytes32)
func (_RAT *RATSession) BatchToTestId(arg0 common.Address, arg1 uint32) ([32]byte, error) {
	return _RAT.Contract.BatchToTestId(&_RAT.CallOpts, arg0, arg1)
}

// BatchToTestId is a free data retrieval call binding the contract method 0x0bec5691.
//
// Solidity: function batchToTestId(address , uint32 ) view returns(bytes32)
func (_RAT *RATCallerSession) BatchToTestId(arg0 common.Address, arg1 uint32) ([32]byte, error) {
	return _RAT.Contract.BatchToTestId(&_RAT.CallOpts, arg0, arg1)
}

// ChallengeGameDuration is a free data retrieval call binding the contract method 0x41faedf5.
//
// Solidity: function challengeGameDuration() view returns(uint256)
func (_RAT *RATCaller) ChallengeGameDuration(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "challengeGameDuration")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ChallengeGameDuration is a free data retrieval call binding the contract method 0x41faedf5.
//
// Solidity: function challengeGameDuration() view returns(uint256)
func (_RAT *RATSession) ChallengeGameDuration() (*big.Int, error) {
	return _RAT.Contract.ChallengeGameDuration(&_RAT.CallOpts)
}

// ChallengeGameDuration is a free data retrieval call binding the contract method 0x41faedf5.
//
// Solidity: function challengeGameDuration() view returns(uint256)
func (_RAT *RATCallerSession) ChallengeGameDuration() (*big.Int, error) {
	return _RAT.Contract.ChallengeGameDuration(&_RAT.CallOpts)
}

// EvidenceSubmissionPeriod is a free data retrieval call binding the contract method 0xacccb08f.
//
// Solidity: function evidenceSubmissionPeriod() view returns(uint256)
func (_RAT *RATCaller) EvidenceSubmissionPeriod(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "evidenceSubmissionPeriod")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// EvidenceSubmissionPeriod is a free data retrieval call binding the contract method 0xacccb08f.
//
// Solidity: function evidenceSubmissionPeriod() view returns(uint256)
func (_RAT *RATSession) EvidenceSubmissionPeriod() (*big.Int, error) {
	return _RAT.Contract.EvidenceSubmissionPeriod(&_RAT.CallOpts)
}

// EvidenceSubmissionPeriod is a free data retrieval call binding the contract method 0xacccb08f.
//
// Solidity: function evidenceSubmissionPeriod() view returns(uint256)
func (_RAT *RATCallerSession) EvidenceSubmissionPeriod() (*big.Int, error) {
	return _RAT.Contract.EvidenceSubmissionPeriod(&_RAT.CallOpts)
}

// FactoryByGame is a free data retrieval call binding the contract method 0x62592433.
//
// Solidity: function factoryByGame(address ) view returns(address)
func (_RAT *RATCaller) FactoryByGame(opts *bind.CallOpts, arg0 common.Address) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "factoryByGame", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// FactoryByGame is a free data retrieval call binding the contract method 0x62592433.
//
// Solidity: function factoryByGame(address ) view returns(address)
func (_RAT *RATSession) FactoryByGame(arg0 common.Address) (common.Address, error) {
	return _RAT.Contract.FactoryByGame(&_RAT.CallOpts, arg0)
}

// FactoryByGame is a free data retrieval call binding the contract method 0x62592433.
//
// Solidity: function factoryByGame(address ) view returns(address)
func (_RAT *RATCallerSession) FactoryByGame(arg0 common.Address) (common.Address, error) {
	return _RAT.Contract.FactoryByGame(&_RAT.CallOpts, arg0)
}

// GameToTestId is a free data retrieval call binding the contract method 0xddef8e85.
//
// Solidity: function gameToTestId(address ) view returns(bytes32)
func (_RAT *RATCaller) GameToTestId(opts *bind.CallOpts, arg0 common.Address) ([32]byte, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "gameToTestId", arg0)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GameToTestId is a free data retrieval call binding the contract method 0xddef8e85.
//
// Solidity: function gameToTestId(address ) view returns(bytes32)
func (_RAT *RATSession) GameToTestId(arg0 common.Address) ([32]byte, error) {
	return _RAT.Contract.GameToTestId(&_RAT.CallOpts, arg0)
}

// GameToTestId is a free data retrieval call binding the contract method 0xddef8e85.
//
// Solidity: function gameToTestId(address ) view returns(bytes32)
func (_RAT *RATCallerSession) GameToTestId(arg0 common.Address) ([32]byte, error) {
	return _RAT.Contract.GameToTestId(&_RAT.CallOpts, arg0)
}

// GetActiveValidatorCount is a free data retrieval call binding the contract method 0x2d6f4969.
//
// Solidity: function getActiveValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetActiveValidatorCount(opts *bind.CallOpts, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getActiveValidatorCount", systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetActiveValidatorCount is a free data retrieval call binding the contract method 0x2d6f4969.
//
// Solidity: function getActiveValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetActiveValidatorCount(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetActiveValidatorCount(&_RAT.CallOpts, systemConfig)
}

// GetActiveValidatorCount is a free data retrieval call binding the contract method 0x2d6f4969.
//
// Solidity: function getActiveValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetActiveValidatorCount(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetActiveValidatorCount(&_RAT.CallOpts, systemConfig)
}

// GetAttentionTest is a free data retrieval call binding the contract method 0x4eecc645.
//
// Solidity: function getAttentionTest(bytes32 testId) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATCaller) GetAttentionTest(opts *bind.CallOpts, testId [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getAttentionTest", testId)

	outstruct := new(struct {
		ValidatorAddress common.Address
		SystemConfig     common.Address
		BatchIndex       uint32
		BatchHash        [32]byte
		BondAmount       *big.Int
		CreatedAt        *big.Int
		Deadline         *big.Int
		Status           uint8
	})

	outstruct.ValidatorAddress = out[0].(common.Address)
	outstruct.SystemConfig = out[1].(common.Address)
	outstruct.BatchIndex = out[2].(uint32)
	outstruct.BatchHash = out[3].([32]byte)
	outstruct.BondAmount = out[4].(*big.Int)
	outstruct.CreatedAt = out[5].(*big.Int)
	outstruct.Deadline = out[6].(*big.Int)
	outstruct.Status = out[7].(uint8)

	return *outstruct, err

}

// GetAttentionTest is a free data retrieval call binding the contract method 0x4eecc645.
//
// Solidity: function getAttentionTest(bytes32 testId) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATSession) GetAttentionTest(testId [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	return _RAT.Contract.GetAttentionTest(&_RAT.CallOpts, testId)
}

// GetAttentionTest is a free data retrieval call binding the contract method 0x4eecc645.
//
// Solidity: function getAttentionTest(bytes32 testId) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATCallerSession) GetAttentionTest(testId [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}, error) {
	return _RAT.Contract.GetAttentionTest(&_RAT.CallOpts, testId)
}

// GetAttentionTestStatus is a free data retrieval call binding the contract method 0x1a693f5b.
//
// Solidity: function getAttentionTestStatus(bytes32 testId) view returns(uint8)
func (_RAT *RATCaller) GetAttentionTestStatus(opts *bind.CallOpts, testId [32]byte) (uint8, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getAttentionTestStatus", testId)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// GetAttentionTestStatus is a free data retrieval call binding the contract method 0x1a693f5b.
//
// Solidity: function getAttentionTestStatus(bytes32 testId) view returns(uint8)
func (_RAT *RATSession) GetAttentionTestStatus(testId [32]byte) (uint8, error) {
	return _RAT.Contract.GetAttentionTestStatus(&_RAT.CallOpts, testId)
}

// GetAttentionTestStatus is a free data retrieval call binding the contract method 0x1a693f5b.
//
// Solidity: function getAttentionTestStatus(bytes32 testId) view returns(uint8)
func (_RAT *RATCallerSession) GetAttentionTestStatus(testId [32]byte) (uint8, error) {
	return _RAT.Contract.GetAttentionTestStatus(&_RAT.CallOpts, testId)
}

// GetAvailableCollateral is a free data retrieval call binding the contract method 0x8ffe8eaa.
//
// Solidity: function getAvailableCollateral(address validator, address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetAvailableCollateral(opts *bind.CallOpts, validator common.Address, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getAvailableCollateral", validator, systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetAvailableCollateral is a free data retrieval call binding the contract method 0x8ffe8eaa.
//
// Solidity: function getAvailableCollateral(address validator, address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetAvailableCollateral(validator common.Address, systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetAvailableCollateral(&_RAT.CallOpts, validator, systemConfig)
}

// GetAvailableCollateral is a free data retrieval call binding the contract method 0x8ffe8eaa.
//
// Solidity: function getAvailableCollateral(address validator, address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetAvailableCollateral(validator common.Address, systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetAvailableCollateral(&_RAT.CallOpts, validator, systemConfig)
}

// GetCoffWithRelaxedCheck is a free data retrieval call binding the contract method 0x6a5ec2b8.
//
// Solidity: function getCoffWithRelaxedCheck(address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetCoffWithRelaxedCheck(opts *bind.CallOpts, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getCoffWithRelaxedCheck", systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCoffWithRelaxedCheck is a free data retrieval call binding the contract method 0x6a5ec2b8.
//
// Solidity: function getCoffWithRelaxedCheck(address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetCoffWithRelaxedCheck(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetCoffWithRelaxedCheck(&_RAT.CallOpts, systemConfig)
}

// GetCoffWithRelaxedCheck is a free data retrieval call binding the contract method 0x6a5ec2b8.
//
// Solidity: function getCoffWithRelaxedCheck(address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetCoffWithRelaxedCheck(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetCoffWithRelaxedCheck(&_RAT.CallOpts, systemConfig)
}

// GetDynamicCoff is a free data retrieval call binding the contract method 0xc6be2df8.
//
// Solidity: function getDynamicCoff(address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetDynamicCoff(opts *bind.CallOpts, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getDynamicCoff", systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetDynamicCoff is a free data retrieval call binding the contract method 0xc6be2df8.
//
// Solidity: function getDynamicCoff(address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetDynamicCoff(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetDynamicCoff(&_RAT.CallOpts, systemConfig)
}

// GetDynamicCoff is a free data retrieval call binding the contract method 0xc6be2df8.
//
// Solidity: function getDynamicCoff(address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetDynamicCoff(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetDynamicCoff(&_RAT.CallOpts, systemConfig)
}

// GetDynamicMinimumCollateral is a free data retrieval call binding the contract method 0x3aace7f5.
//
// Solidity: function getDynamicMinimumCollateral(address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetDynamicMinimumCollateral(opts *bind.CallOpts, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getDynamicMinimumCollateral", systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetDynamicMinimumCollateral is a free data retrieval call binding the contract method 0x3aace7f5.
//
// Solidity: function getDynamicMinimumCollateral(address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetDynamicMinimumCollateral(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetDynamicMinimumCollateral(&_RAT.CallOpts, systemConfig)
}

// GetDynamicMinimumCollateral is a free data retrieval call binding the contract method 0x3aace7f5.
//
// Solidity: function getDynamicMinimumCollateral(address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetDynamicMinimumCollateral(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetDynamicMinimumCollateral(&_RAT.CallOpts, systemConfig)
}

// GetL2Validators is a free data retrieval call binding the contract method 0x068c2e6e.
//
// Solidity: function getL2Validators(address systemConfig) view returns(address[])
func (_RAT *RATCaller) GetL2Validators(opts *bind.CallOpts, systemConfig common.Address) ([]common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getL2Validators", systemConfig)

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetL2Validators is a free data retrieval call binding the contract method 0x068c2e6e.
//
// Solidity: function getL2Validators(address systemConfig) view returns(address[])
func (_RAT *RATSession) GetL2Validators(systemConfig common.Address) ([]common.Address, error) {
	return _RAT.Contract.GetL2Validators(&_RAT.CallOpts, systemConfig)
}

// GetL2Validators is a free data retrieval call binding the contract method 0x068c2e6e.
//
// Solidity: function getL2Validators(address systemConfig) view returns(address[])
func (_RAT *RATCallerSession) GetL2Validators(systemConfig common.Address) ([]common.Address, error) {
	return _RAT.Contract.GetL2Validators(&_RAT.CallOpts, systemConfig)
}

// GetMinimumCollateral is a free data retrieval call binding the contract method 0xd8c0ba59.
//
// Solidity: function getMinimumCollateral() view returns(uint256)
func (_RAT *RATCaller) GetMinimumCollateral(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getMinimumCollateral")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMinimumCollateral is a free data retrieval call binding the contract method 0xd8c0ba59.
//
// Solidity: function getMinimumCollateral() view returns(uint256)
func (_RAT *RATSession) GetMinimumCollateral() (*big.Int, error) {
	return _RAT.Contract.GetMinimumCollateral(&_RAT.CallOpts)
}

// GetMinimumCollateral is a free data retrieval call binding the contract method 0xd8c0ba59.
//
// Solidity: function getMinimumCollateral() view returns(uint256)
func (_RAT *RATCallerSession) GetMinimumCollateral() (*big.Int, error) {
	return _RAT.Contract.GetMinimumCollateral(&_RAT.CallOpts)
}

// GetMinimumCollateralWithRelaxedCheck is a free data retrieval call binding the contract method 0xf120484e.
//
// Solidity: function getMinimumCollateralWithRelaxedCheck(address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetMinimumCollateralWithRelaxedCheck(opts *bind.CallOpts, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getMinimumCollateralWithRelaxedCheck", systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMinimumCollateralWithRelaxedCheck is a free data retrieval call binding the contract method 0xf120484e.
//
// Solidity: function getMinimumCollateralWithRelaxedCheck(address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetMinimumCollateralWithRelaxedCheck(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetMinimumCollateralWithRelaxedCheck(&_RAT.CallOpts, systemConfig)
}

// GetMinimumCollateralWithRelaxedCheck is a free data retrieval call binding the contract method 0xf120484e.
//
// Solidity: function getMinimumCollateralWithRelaxedCheck(address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetMinimumCollateralWithRelaxedCheck(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetMinimumCollateralWithRelaxedCheck(&_RAT.CallOpts, systemConfig)
}

// GetRATCoinageBalance is a free data retrieval call binding the contract method 0x40dd80f8.
//
// Solidity: function getRATCoinageBalance(address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetRATCoinageBalance(opts *bind.CallOpts, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getRATCoinageBalance", systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetRATCoinageBalance is a free data retrieval call binding the contract method 0x40dd80f8.
//
// Solidity: function getRATCoinageBalance(address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetRATCoinageBalance(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetRATCoinageBalance(&_RAT.CallOpts, systemConfig)
}

// GetRATCoinageBalance is a free data retrieval call binding the contract method 0x40dd80f8.
//
// Solidity: function getRATCoinageBalance(address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetRATCoinageBalance(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetRATCoinageBalance(&_RAT.CallOpts, systemConfig)
}

// GetValidatorCount is a free data retrieval call binding the contract method 0xf9560e45.
//
// Solidity: function getValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetValidatorCount(opts *bind.CallOpts, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getValidatorCount", systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetValidatorCount is a free data retrieval call binding the contract method 0xf9560e45.
//
// Solidity: function getValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetValidatorCount(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetValidatorCount(&_RAT.CallOpts, systemConfig)
}

// GetValidatorCount is a free data retrieval call binding the contract method 0xf9560e45.
//
// Solidity: function getValidatorCount(address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetValidatorCount(systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetValidatorCount(&_RAT.CallOpts, systemConfig)
}

// GetValidatorDeposit is a free data retrieval call binding the contract method 0x39b62bd1.
//
// Solidity: function getValidatorDeposit(address validator, address systemConfig) view returns(uint256)
func (_RAT *RATCaller) GetValidatorDeposit(opts *bind.CallOpts, validator common.Address, systemConfig common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getValidatorDeposit", validator, systemConfig)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetValidatorDeposit is a free data retrieval call binding the contract method 0x39b62bd1.
//
// Solidity: function getValidatorDeposit(address validator, address systemConfig) view returns(uint256)
func (_RAT *RATSession) GetValidatorDeposit(validator common.Address, systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetValidatorDeposit(&_RAT.CallOpts, validator, systemConfig)
}

// GetValidatorDeposit is a free data retrieval call binding the contract method 0x39b62bd1.
//
// Solidity: function getValidatorDeposit(address validator, address systemConfig) view returns(uint256)
func (_RAT *RATCallerSession) GetValidatorDeposit(validator common.Address, systemConfig common.Address) (*big.Int, error) {
	return _RAT.Contract.GetValidatorDeposit(&_RAT.CallOpts, validator, systemConfig)
}

// GetValidatorMinCollateralForLayer2 is a free data retrieval call binding the contract method 0x6fc641e8.
//
// Solidity: function getValidatorMinCollateralForLayer2(address layer2, address validator) view returns(uint256)
func (_RAT *RATCaller) GetValidatorMinCollateralForLayer2(opts *bind.CallOpts, layer2 common.Address, validator common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getValidatorMinCollateralForLayer2", layer2, validator)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetValidatorMinCollateralForLayer2 is a free data retrieval call binding the contract method 0x6fc641e8.
//
// Solidity: function getValidatorMinCollateralForLayer2(address layer2, address validator) view returns(uint256)
func (_RAT *RATSession) GetValidatorMinCollateralForLayer2(layer2 common.Address, validator common.Address) (*big.Int, error) {
	return _RAT.Contract.GetValidatorMinCollateralForLayer2(&_RAT.CallOpts, layer2, validator)
}

// GetValidatorMinCollateralForLayer2 is a free data retrieval call binding the contract method 0x6fc641e8.
//
// Solidity: function getValidatorMinCollateralForLayer2(address layer2, address validator) view returns(uint256)
func (_RAT *RATCallerSession) GetValidatorMinCollateralForLayer2(layer2 common.Address, validator common.Address) (*big.Int, error) {
	return _RAT.Contract.GetValidatorMinCollateralForLayer2(&_RAT.CallOpts, layer2, validator)
}

// GetValidatorRegistration is a free data retrieval call binding the contract method 0xf92879db.
//
// Solidity: function getValidatorRegistration(address validator, address systemConfig) view returns(uint256 collateral, uint32 validatorIndex, bool isActive)
func (_RAT *RATCaller) GetValidatorRegistration(opts *bind.CallOpts, validator common.Address, systemConfig common.Address) (struct {
	Collateral     *big.Int
	ValidatorIndex uint32
	IsActive       bool
}, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getValidatorRegistration", validator, systemConfig)

	outstruct := new(struct {
		Collateral     *big.Int
		ValidatorIndex uint32
		IsActive       bool
	})

	outstruct.Collateral = out[0].(*big.Int)
	outstruct.ValidatorIndex = out[1].(uint32)
	outstruct.IsActive = out[2].(bool)

	return *outstruct, err

}

// GetValidatorRegistration is a free data retrieval call binding the contract method 0xf92879db.
//
// Solidity: function getValidatorRegistration(address validator, address systemConfig) view returns(uint256 collateral, uint32 validatorIndex, bool isActive)
func (_RAT *RATSession) GetValidatorRegistration(validator common.Address, systemConfig common.Address) (struct {
	Collateral     *big.Int
	ValidatorIndex uint32
	IsActive       bool
}, error) {
	return _RAT.Contract.GetValidatorRegistration(&_RAT.CallOpts, validator, systemConfig)
}

// GetValidatorRegistration is a free data retrieval call binding the contract method 0xf92879db.
//
// Solidity: function getValidatorRegistration(address validator, address systemConfig) view returns(uint256 collateral, uint32 validatorIndex, bool isActive)
func (_RAT *RATCallerSession) GetValidatorRegistration(validator common.Address, systemConfig common.Address) (struct {
	Collateral     *big.Int
	ValidatorIndex uint32
	IsActive       bool
}, error) {
	return _RAT.Contract.GetValidatorRegistration(&_RAT.CallOpts, validator, systemConfig)
}

// IsValidatorActive is a free data retrieval call binding the contract method 0x03225879.
//
// Solidity: function isValidatorActive(address validator, address systemConfig) view returns(bool)
func (_RAT *RATCaller) IsValidatorActive(opts *bind.CallOpts, validator common.Address, systemConfig common.Address) (bool, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "isValidatorActive", validator, systemConfig)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsValidatorActive is a free data retrieval call binding the contract method 0x03225879.
//
// Solidity: function isValidatorActive(address validator, address systemConfig) view returns(bool)
func (_RAT *RATSession) IsValidatorActive(validator common.Address, systemConfig common.Address) (bool, error) {
	return _RAT.Contract.IsValidatorActive(&_RAT.CallOpts, validator, systemConfig)
}

// IsValidatorActive is a free data retrieval call binding the contract method 0x03225879.
//
// Solidity: function isValidatorActive(address validator, address systemConfig) view returns(bool)
func (_RAT *RATCallerSession) IsValidatorActive(validator common.Address, systemConfig common.Address) (bool, error) {
	return _RAT.Contract.IsValidatorActive(&_RAT.CallOpts, validator, systemConfig)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_RAT *RATCaller) L1BridgeRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "l1BridgeRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_RAT *RATSession) L1BridgeRegistry() (common.Address, error) {
	return _RAT.Contract.L1BridgeRegistry(&_RAT.CallOpts)
}

// L1BridgeRegistry is a free data retrieval call binding the contract method 0xcf8f9110.
//
// Solidity: function l1BridgeRegistry() view returns(address)
func (_RAT *RATCallerSession) L1BridgeRegistry() (common.Address, error) {
	return _RAT.Contract.L1BridgeRegistry(&_RAT.CallOpts)
}

// LatestDeadlineTest is a free data retrieval call binding the contract method 0x44f1c99d.
//
// Solidity: function latestDeadlineTest(address ) view returns(uint256)
func (_RAT *RATCaller) LatestDeadlineTest(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "latestDeadlineTest", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LatestDeadlineTest is a free data retrieval call binding the contract method 0x44f1c99d.
//
// Solidity: function latestDeadlineTest(address ) view returns(uint256)
func (_RAT *RATSession) LatestDeadlineTest(arg0 common.Address) (*big.Int, error) {
	return _RAT.Contract.LatestDeadlineTest(&_RAT.CallOpts, arg0)
}

// LatestDeadlineTest is a free data retrieval call binding the contract method 0x44f1c99d.
//
// Solidity: function latestDeadlineTest(address ) view returns(uint256)
func (_RAT *RATCallerSession) LatestDeadlineTest(arg0 common.Address) (*big.Int, error) {
	return _RAT.Contract.LatestDeadlineTest(&_RAT.CallOpts, arg0)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_RAT *RATCaller) Layer2Manager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "layer2Manager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_RAT *RATSession) Layer2Manager() (common.Address, error) {
	return _RAT.Contract.Layer2Manager(&_RAT.CallOpts)
}

// Layer2Manager is a free data retrieval call binding the contract method 0x16b5d5bd.
//
// Solidity: function layer2Manager() view returns(address)
func (_RAT *RATCallerSession) Layer2Manager() (common.Address, error) {
	return _RAT.Contract.Layer2Manager(&_RAT.CallOpts)
}

// MaxValidatorsPerL2 is a free data retrieval call binding the contract method 0xcfa424ea.
//
// Solidity: function maxValidatorsPerL2() view returns(uint256)
func (_RAT *RATCaller) MaxValidatorsPerL2(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "maxValidatorsPerL2")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxValidatorsPerL2 is a free data retrieval call binding the contract method 0xcfa424ea.
//
// Solidity: function maxValidatorsPerL2() view returns(uint256)
func (_RAT *RATSession) MaxValidatorsPerL2() (*big.Int, error) {
	return _RAT.Contract.MaxValidatorsPerL2(&_RAT.CallOpts)
}

// MaxValidatorsPerL2 is a free data retrieval call binding the contract method 0xcfa424ea.
//
// Solidity: function maxValidatorsPerL2() view returns(uint256)
func (_RAT *RATCallerSession) MaxValidatorsPerL2() (*big.Int, error) {
	return _RAT.Contract.MaxValidatorsPerL2(&_RAT.CallOpts)
}

// MinimumThreshold is a free data retrieval call binding the contract method 0x75da30d0.
//
// Solidity: function minimumThreshold() view returns(uint256)
func (_RAT *RATCaller) MinimumThreshold(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "minimumThreshold")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MinimumThreshold is a free data retrieval call binding the contract method 0x75da30d0.
//
// Solidity: function minimumThreshold() view returns(uint256)
func (_RAT *RATSession) MinimumThreshold() (*big.Int, error) {
	return _RAT.Contract.MinimumThreshold(&_RAT.CallOpts)
}

// MinimumThreshold is a free data retrieval call binding the contract method 0x75da30d0.
//
// Solidity: function minimumThreshold() view returns(uint256)
func (_RAT *RATCallerSession) MinimumThreshold() (*big.Int, error) {
	return _RAT.Contract.MinimumThreshold(&_RAT.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_RAT *RATCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_RAT *RATSession) Owner() (common.Address, error) {
	return _RAT.Contract.Owner(&_RAT.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_RAT *RATCallerSession) Owner() (common.Address, error) {
	return _RAT.Contract.Owner(&_RAT.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_RAT *RATCaller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_RAT *RATSession) Paused() (bool, error) {
	return _RAT.Contract.Paused(&_RAT.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_RAT *RATCallerSession) Paused() (bool, error) {
	return _RAT.Contract.Paused(&_RAT.CallOpts)
}

// RatTriggerProbability is a free data retrieval call binding the contract method 0x51567bc2.
//
// Solidity: function ratTriggerProbability() view returns(uint256)
func (_RAT *RATCaller) RatTriggerProbability(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "ratTriggerProbability")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// RatTriggerProbability is a free data retrieval call binding the contract method 0x51567bc2.
//
// Solidity: function ratTriggerProbability() view returns(uint256)
func (_RAT *RATSession) RatTriggerProbability() (*big.Int, error) {
	return _RAT.Contract.RatTriggerProbability(&_RAT.CallOpts)
}

// RatTriggerProbability is a free data retrieval call binding the contract method 0x51567bc2.
//
// Solidity: function ratTriggerProbability() view returns(uint256)
func (_RAT *RATCallerSession) RatTriggerProbability() (*big.Int, error) {
	return _RAT.Contract.RatTriggerProbability(&_RAT.CallOpts)
}

// RelaxedValidatorCheck is a free data retrieval call binding the contract method 0x0fab0073.
//
// Solidity: function relaxedValidatorCheck() view returns(bool)
func (_RAT *RATCaller) RelaxedValidatorCheck(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "relaxedValidatorCheck")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// RelaxedValidatorCheck is a free data retrieval call binding the contract method 0x0fab0073.
//
// Solidity: function relaxedValidatorCheck() view returns(bool)
func (_RAT *RATSession) RelaxedValidatorCheck() (bool, error) {
	return _RAT.Contract.RelaxedValidatorCheck(&_RAT.CallOpts)
}

// RelaxedValidatorCheck is a free data retrieval call binding the contract method 0x0fab0073.
//
// Solidity: function relaxedValidatorCheck() view returns(bool)
func (_RAT *RATCallerSession) RelaxedValidatorCheck() (bool, error) {
	return _RAT.Contract.RelaxedValidatorCheck(&_RAT.CallOpts)
}

// SafetyBuffer is a free data retrieval call binding the contract method 0x0caebb61.
//
// Solidity: function safetyBuffer() view returns(uint256)
func (_RAT *RATCaller) SafetyBuffer(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "safetyBuffer")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// SafetyBuffer is a free data retrieval call binding the contract method 0x0caebb61.
//
// Solidity: function safetyBuffer() view returns(uint256)
func (_RAT *RATSession) SafetyBuffer() (*big.Int, error) {
	return _RAT.Contract.SafetyBuffer(&_RAT.CallOpts)
}

// SafetyBuffer is a free data retrieval call binding the contract method 0x0caebb61.
//
// Solidity: function safetyBuffer() view returns(uint256)
func (_RAT *RATCallerSession) SafetyBuffer() (*big.Int, error) {
	return _RAT.Contract.SafetyBuffer(&_RAT.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_RAT *RATCaller) SeigManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "seigManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_RAT *RATSession) SeigManager() (common.Address, error) {
	return _RAT.Contract.SeigManager(&_RAT.CallOpts)
}

// SeigManager is a free data retrieval call binding the contract method 0x6fb7f558.
//
// Solidity: function seigManager() view returns(address)
func (_RAT *RATCallerSession) SeigManager() (common.Address, error) {
	return _RAT.Contract.SeigManager(&_RAT.CallOpts)
}

// SlashingPenalty is a free data retrieval call binding the contract method 0x89f1ea64.
//
// Solidity: function slashingPenalty() view returns(uint256)
func (_RAT *RATCaller) SlashingPenalty(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "slashingPenalty")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// SlashingPenalty is a free data retrieval call binding the contract method 0x89f1ea64.
//
// Solidity: function slashingPenalty() view returns(uint256)
func (_RAT *RATSession) SlashingPenalty() (*big.Int, error) {
	return _RAT.Contract.SlashingPenalty(&_RAT.CallOpts)
}

// SlashingPenalty is a free data retrieval call binding the contract method 0x89f1ea64.
//
// Solidity: function slashingPenalty() view returns(uint256)
func (_RAT *RATCallerSession) SlashingPenalty() (*big.Int, error) {
	return _RAT.Contract.SlashingPenalty(&_RAT.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_RAT *RATCaller) Ton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "ton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_RAT *RATSession) Ton() (common.Address, error) {
	return _RAT.Contract.Ton(&_RAT.CallOpts)
}

// Ton is a free data retrieval call binding the contract method 0xcc48b947.
//
// Solidity: function ton() view returns(address)
func (_RAT *RATCallerSession) Ton() (common.Address, error) {
	return _RAT.Contract.Ton(&_RAT.CallOpts)
}

// Treasury is a free data retrieval call binding the contract method 0x61d027b3.
//
// Solidity: function treasury() view returns(address)
func (_RAT *RATCaller) Treasury(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "treasury")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Treasury is a free data retrieval call binding the contract method 0x61d027b3.
//
// Solidity: function treasury() view returns(address)
func (_RAT *RATSession) Treasury() (common.Address, error) {
	return _RAT.Contract.Treasury(&_RAT.CallOpts)
}

// Treasury is a free data retrieval call binding the contract method 0x61d027b3.
//
// Solidity: function treasury() view returns(address)
func (_RAT *RATCallerSession) Treasury() (common.Address, error) {
	return _RAT.Contract.Treasury(&_RAT.CallOpts)
}

// ValidateSlashingPenalty is a free data retrieval call binding the contract method 0xd0d6b9b5.
//
// Solidity: function validateSlashingPenalty(uint256 n) view returns(bool)
func (_RAT *RATCaller) ValidateSlashingPenalty(opts *bind.CallOpts, n *big.Int) (bool, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validateSlashingPenalty", n)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ValidateSlashingPenalty is a free data retrieval call binding the contract method 0xd0d6b9b5.
//
// Solidity: function validateSlashingPenalty(uint256 n) view returns(bool)
func (_RAT *RATSession) ValidateSlashingPenalty(n *big.Int) (bool, error) {
	return _RAT.Contract.ValidateSlashingPenalty(&_RAT.CallOpts, n)
}

// ValidateSlashingPenalty is a free data retrieval call binding the contract method 0xd0d6b9b5.
//
// Solidity: function validateSlashingPenalty(uint256 n) view returns(bool)
func (_RAT *RATCallerSession) ValidateSlashingPenalty(n *big.Int) (bool, error) {
	return _RAT.Contract.ValidateSlashingPenalty(&_RAT.CallOpts, n)
}

// ValidatorBuffer is a free data retrieval call binding the contract method 0xf7107b44.
//
// Solidity: function validatorBuffer() view returns(uint256)
func (_RAT *RATCaller) ValidatorBuffer(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validatorBuffer")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ValidatorBuffer is a free data retrieval call binding the contract method 0xf7107b44.
//
// Solidity: function validatorBuffer() view returns(uint256)
func (_RAT *RATSession) ValidatorBuffer() (*big.Int, error) {
	return _RAT.Contract.ValidatorBuffer(&_RAT.CallOpts)
}

// ValidatorBuffer is a free data retrieval call binding the contract method 0xf7107b44.
//
// Solidity: function validatorBuffer() view returns(uint256)
func (_RAT *RATCallerSession) ValidatorBuffer() (*big.Int, error) {
	return _RAT.Contract.ValidatorBuffer(&_RAT.CallOpts)
}

// ValidatorIndexes is a free data retrieval call binding the contract method 0x4e4a9a1b.
//
// Solidity: function validatorIndexes(address , address ) view returns(uint256)
func (_RAT *RATCaller) ValidatorIndexes(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validatorIndexes", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ValidatorIndexes is a free data retrieval call binding the contract method 0x4e4a9a1b.
//
// Solidity: function validatorIndexes(address , address ) view returns(uint256)
func (_RAT *RATSession) ValidatorIndexes(arg0 common.Address, arg1 common.Address) (*big.Int, error) {
	return _RAT.Contract.ValidatorIndexes(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorIndexes is a free data retrieval call binding the contract method 0x4e4a9a1b.
//
// Solidity: function validatorIndexes(address , address ) view returns(uint256)
func (_RAT *RATCallerSession) ValidatorIndexes(arg0 common.Address, arg1 common.Address) (*big.Int, error) {
	return _RAT.Contract.ValidatorIndexes(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 lockedForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive)
func (_RAT *RATCaller) ValidatorRegistrations(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address) (struct {
	LockedForRAT       *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
}, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validatorRegistrations", arg0, arg1)

	outstruct := new(struct {
		LockedForRAT       *big.Int
		PendingRewards     *big.Int
		LatestTestDeadline uint64
		ValidatorIndex     uint32
		IsActive           bool
	})

	outstruct.LockedForRAT = out[0].(*big.Int)
	outstruct.PendingRewards = out[1].(*big.Int)
	outstruct.LatestTestDeadline = out[2].(uint64)
	outstruct.ValidatorIndex = out[3].(uint32)
	outstruct.IsActive = out[4].(bool)

	return *outstruct, err

}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 lockedForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive)
func (_RAT *RATSession) ValidatorRegistrations(arg0 common.Address, arg1 common.Address) (struct {
	LockedForRAT       *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
}, error) {
	return _RAT.Contract.ValidatorRegistrations(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 lockedForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive)
func (_RAT *RATCallerSession) ValidatorRegistrations(arg0 common.Address, arg1 common.Address) (struct {
	LockedForRAT       *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
}, error) {
	return _RAT.Contract.ValidatorRegistrations(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorReward is a free data retrieval call binding the contract method 0x75b94133.
//
// Solidity: function validatorReward() view returns(address)
func (_RAT *RATCaller) ValidatorReward(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validatorReward")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ValidatorReward is a free data retrieval call binding the contract method 0x75b94133.
//
// Solidity: function validatorReward() view returns(address)
func (_RAT *RATSession) ValidatorReward() (common.Address, error) {
	return _RAT.Contract.ValidatorReward(&_RAT.CallOpts)
}

// ValidatorReward is a free data retrieval call binding the contract method 0x75b94133.
//
// Solidity: function validatorReward() view returns(address)
func (_RAT *RATCallerSession) ValidatorReward() (common.Address, error) {
	return _RAT.Contract.ValidatorReward(&_RAT.CallOpts)
}

// ValidatorSystemConfigs is a free data retrieval call binding the contract method 0x8dc3b28e.
//
// Solidity: function validatorSystemConfigs(address , uint256 ) view returns(address)
func (_RAT *RATCaller) ValidatorSystemConfigs(opts *bind.CallOpts, arg0 common.Address, arg1 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validatorSystemConfigs", arg0, arg1)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ValidatorSystemConfigs is a free data retrieval call binding the contract method 0x8dc3b28e.
//
// Solidity: function validatorSystemConfigs(address , uint256 ) view returns(address)
func (_RAT *RATSession) ValidatorSystemConfigs(arg0 common.Address, arg1 *big.Int) (common.Address, error) {
	return _RAT.Contract.ValidatorSystemConfigs(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorSystemConfigs is a free data retrieval call binding the contract method 0x8dc3b28e.
//
// Solidity: function validatorSystemConfigs(address , uint256 ) view returns(address)
func (_RAT *RATCallerSession) ValidatorSystemConfigs(arg0 common.Address, arg1 *big.Int) (common.Address, error) {
	return _RAT.Contract.ValidatorSystemConfigs(&_RAT.CallOpts, arg0, arg1)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_RAT *RATCaller) Wton(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "wton")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_RAT *RATSession) Wton() (common.Address, error) {
	return _RAT.Contract.Wton(&_RAT.CallOpts)
}

// Wton is a free data retrieval call binding the contract method 0x8d62d949.
//
// Solidity: function wton() view returns(address)
func (_RAT *RATCallerSession) Wton() (common.Address, error) {
	return _RAT.Contract.Wton(&_RAT.CallOpts)
}

// DeactivateValidator is a paid mutator transaction binding the contract method 0xba50b879.
//
// Solidity: function deactivateValidator(address systemConfig) returns()
func (_RAT *RATTransactor) DeactivateValidator(opts *bind.TransactOpts, systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "deactivateValidator", systemConfig)
}

// DeactivateValidator is a paid mutator transaction binding the contract method 0xba50b879.
//
// Solidity: function deactivateValidator(address systemConfig) returns()
func (_RAT *RATSession) DeactivateValidator(systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.Contract.DeactivateValidator(&_RAT.TransactOpts, systemConfig)
}

// DeactivateValidator is a paid mutator transaction binding the contract method 0xba50b879.
//
// Solidity: function deactivateValidator(address systemConfig) returns()
func (_RAT *RATTransactorSession) DeactivateValidator(systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.Contract.DeactivateValidator(&_RAT.TransactOpts, systemConfig)
}

// Initialize is a paid mutator transaction binding the contract method 0xf5ee070f.
//
// Solidity: function initialize((address,address,address,address,address,address) params) returns()
func (_RAT *RATTransactor) Initialize(opts *bind.TransactOpts, params RATInitParams) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "initialize", params)
}

// Initialize is a paid mutator transaction binding the contract method 0xf5ee070f.
//
// Solidity: function initialize((address,address,address,address,address,address) params) returns()
func (_RAT *RATSession) Initialize(params RATInitParams) (*types.Transaction, error) {
	return _RAT.Contract.Initialize(&_RAT.TransactOpts, params)
}

// Initialize is a paid mutator transaction binding the contract method 0xf5ee070f.
//
// Solidity: function initialize((address,address,address,address,address,address) params) returns()
func (_RAT *RATTransactorSession) Initialize(params RATInitParams) (*types.Transaction, error) {
	return _RAT.Contract.Initialize(&_RAT.TransactOpts, params)
}

// RegisterValidator is a paid mutator transaction binding the contract method 0x9fca5169.
//
// Solidity: function registerValidator(address systemConfig) returns()
func (_RAT *RATTransactor) RegisterValidator(opts *bind.TransactOpts, systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "registerValidator", systemConfig)
}

// RegisterValidator is a paid mutator transaction binding the contract method 0x9fca5169.
//
// Solidity: function registerValidator(address systemConfig) returns()
func (_RAT *RATSession) RegisterValidator(systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.Contract.RegisterValidator(&_RAT.TransactOpts, systemConfig)
}

// RegisterValidator is a paid mutator transaction binding the contract method 0x9fca5169.
//
// Solidity: function registerValidator(address systemConfig) returns()
func (_RAT *RATTransactorSession) RegisterValidator(systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.Contract.RegisterValidator(&_RAT.TransactOpts, systemConfig)
}

// ResolveClaim is a paid mutator transaction binding the contract method 0x94d645a8.
//
// Solidity: function resolveClaim(address _claimant) returns()
func (_RAT *RATTransactor) ResolveClaim(opts *bind.TransactOpts, _claimant common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "resolveClaim", _claimant)
}

// ResolveClaim is a paid mutator transaction binding the contract method 0x94d645a8.
//
// Solidity: function resolveClaim(address _claimant) returns()
func (_RAT *RATSession) ResolveClaim(_claimant common.Address) (*types.Transaction, error) {
	return _RAT.Contract.ResolveClaim(&_RAT.TransactOpts, _claimant)
}

// ResolveClaim is a paid mutator transaction binding the contract method 0x94d645a8.
//
// Solidity: function resolveClaim(address _claimant) returns()
func (_RAT *RATTransactorSession) ResolveClaim(_claimant common.Address) (*types.Transaction, error) {
	return _RAT.Contract.ResolveClaim(&_RAT.TransactOpts, _claimant)
}

// SetAttentionCost is a paid mutator transaction binding the contract method 0xc0a08bde.
//
// Solidity: function setAttentionCost(uint256 cost) returns()
func (_RAT *RATTransactor) SetAttentionCost(opts *bind.TransactOpts, cost *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setAttentionCost", cost)
}

// SetAttentionCost is a paid mutator transaction binding the contract method 0xc0a08bde.
//
// Solidity: function setAttentionCost(uint256 cost) returns()
func (_RAT *RATSession) SetAttentionCost(cost *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetAttentionCost(&_RAT.TransactOpts, cost)
}

// SetAttentionCost is a paid mutator transaction binding the contract method 0xc0a08bde.
//
// Solidity: function setAttentionCost(uint256 cost) returns()
func (_RAT *RATTransactorSession) SetAttentionCost(cost *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetAttentionCost(&_RAT.TransactOpts, cost)
}

// SetAuthorizedTrigger is a paid mutator transaction binding the contract method 0x370e9e18.
//
// Solidity: function setAuthorizedTrigger(address trigger) returns()
func (_RAT *RATTransactor) SetAuthorizedTrigger(opts *bind.TransactOpts, trigger common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setAuthorizedTrigger", trigger)
}

// SetAuthorizedTrigger is a paid mutator transaction binding the contract method 0x370e9e18.
//
// Solidity: function setAuthorizedTrigger(address trigger) returns()
func (_RAT *RATSession) SetAuthorizedTrigger(trigger common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetAuthorizedTrigger(&_RAT.TransactOpts, trigger)
}

// SetAuthorizedTrigger is a paid mutator transaction binding the contract method 0x370e9e18.
//
// Solidity: function setAuthorizedTrigger(address trigger) returns()
func (_RAT *RATTransactorSession) SetAuthorizedTrigger(trigger common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetAuthorizedTrigger(&_RAT.TransactOpts, trigger)
}

// SetChallengeGameDuration is a paid mutator transaction binding the contract method 0x8ca61113.
//
// Solidity: function setChallengeGameDuration(uint256 duration) returns()
func (_RAT *RATTransactor) SetChallengeGameDuration(opts *bind.TransactOpts, duration *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setChallengeGameDuration", duration)
}

// SetChallengeGameDuration is a paid mutator transaction binding the contract method 0x8ca61113.
//
// Solidity: function setChallengeGameDuration(uint256 duration) returns()
func (_RAT *RATSession) SetChallengeGameDuration(duration *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetChallengeGameDuration(&_RAT.TransactOpts, duration)
}

// SetChallengeGameDuration is a paid mutator transaction binding the contract method 0x8ca61113.
//
// Solidity: function setChallengeGameDuration(uint256 duration) returns()
func (_RAT *RATTransactorSession) SetChallengeGameDuration(duration *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetChallengeGameDuration(&_RAT.TransactOpts, duration)
}

// SetConfig is a paid mutator transaction binding the contract method 0xf9d271b8.
//
// Solidity: function setConfig((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address,uint256,bool) config) returns()
func (_RAT *RATTransactor) SetConfig(opts *bind.TransactOpts, config RATConfigParams) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setConfig", config)
}

// SetConfig is a paid mutator transaction binding the contract method 0xf9d271b8.
//
// Solidity: function setConfig((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address,uint256,bool) config) returns()
func (_RAT *RATSession) SetConfig(config RATConfigParams) (*types.Transaction, error) {
	return _RAT.Contract.SetConfig(&_RAT.TransactOpts, config)
}

// SetConfig is a paid mutator transaction binding the contract method 0xf9d271b8.
//
// Solidity: function setConfig((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address,uint256,bool) config) returns()
func (_RAT *RATTransactorSession) SetConfig(config RATConfigParams) (*types.Transaction, error) {
	return _RAT.Contract.SetConfig(&_RAT.TransactOpts, config)
}

// SetEvidenceSubmissionPeriod is a paid mutator transaction binding the contract method 0x36c63d46.
//
// Solidity: function setEvidenceSubmissionPeriod(uint256 period) returns()
func (_RAT *RATTransactor) SetEvidenceSubmissionPeriod(opts *bind.TransactOpts, period *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setEvidenceSubmissionPeriod", period)
}

// SetEvidenceSubmissionPeriod is a paid mutator transaction binding the contract method 0x36c63d46.
//
// Solidity: function setEvidenceSubmissionPeriod(uint256 period) returns()
func (_RAT *RATSession) SetEvidenceSubmissionPeriod(period *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetEvidenceSubmissionPeriod(&_RAT.TransactOpts, period)
}

// SetEvidenceSubmissionPeriod is a paid mutator transaction binding the contract method 0x36c63d46.
//
// Solidity: function setEvidenceSubmissionPeriod(uint256 period) returns()
func (_RAT *RATTransactorSession) SetEvidenceSubmissionPeriod(period *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetEvidenceSubmissionPeriod(&_RAT.TransactOpts, period)
}

// SetL1BridgeRegistry is a paid mutator transaction binding the contract method 0x0c1da8df.
//
// Solidity: function setL1BridgeRegistry(address _l1BridgeRegistry) returns()
func (_RAT *RATTransactor) SetL1BridgeRegistry(opts *bind.TransactOpts, _l1BridgeRegistry common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setL1BridgeRegistry", _l1BridgeRegistry)
}

// SetL1BridgeRegistry is a paid mutator transaction binding the contract method 0x0c1da8df.
//
// Solidity: function setL1BridgeRegistry(address _l1BridgeRegistry) returns()
func (_RAT *RATSession) SetL1BridgeRegistry(_l1BridgeRegistry common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetL1BridgeRegistry(&_RAT.TransactOpts, _l1BridgeRegistry)
}

// SetL1BridgeRegistry is a paid mutator transaction binding the contract method 0x0c1da8df.
//
// Solidity: function setL1BridgeRegistry(address _l1BridgeRegistry) returns()
func (_RAT *RATTransactorSession) SetL1BridgeRegistry(_l1BridgeRegistry common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetL1BridgeRegistry(&_RAT.TransactOpts, _l1BridgeRegistry)
}

// SetMaxValidatorsPerL2 is a paid mutator transaction binding the contract method 0xa0bfe1c6.
//
// Solidity: function setMaxValidatorsPerL2(uint256 maxValidators) returns()
func (_RAT *RATTransactor) SetMaxValidatorsPerL2(opts *bind.TransactOpts, maxValidators *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setMaxValidatorsPerL2", maxValidators)
}

// SetMaxValidatorsPerL2 is a paid mutator transaction binding the contract method 0xa0bfe1c6.
//
// Solidity: function setMaxValidatorsPerL2(uint256 maxValidators) returns()
func (_RAT *RATSession) SetMaxValidatorsPerL2(maxValidators *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetMaxValidatorsPerL2(&_RAT.TransactOpts, maxValidators)
}

// SetMaxValidatorsPerL2 is a paid mutator transaction binding the contract method 0xa0bfe1c6.
//
// Solidity: function setMaxValidatorsPerL2(uint256 maxValidators) returns()
func (_RAT *RATTransactorSession) SetMaxValidatorsPerL2(maxValidators *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetMaxValidatorsPerL2(&_RAT.TransactOpts, maxValidators)
}

// SetMinimumThreshold is a paid mutator transaction binding the contract method 0x67058d29.
//
// Solidity: function setMinimumThreshold(uint256 threshold) returns()
func (_RAT *RATTransactor) SetMinimumThreshold(opts *bind.TransactOpts, threshold *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setMinimumThreshold", threshold)
}

// SetMinimumThreshold is a paid mutator transaction binding the contract method 0x67058d29.
//
// Solidity: function setMinimumThreshold(uint256 threshold) returns()
func (_RAT *RATSession) SetMinimumThreshold(threshold *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetMinimumThreshold(&_RAT.TransactOpts, threshold)
}

// SetMinimumThreshold is a paid mutator transaction binding the contract method 0x67058d29.
//
// Solidity: function setMinimumThreshold(uint256 threshold) returns()
func (_RAT *RATTransactorSession) SetMinimumThreshold(threshold *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetMinimumThreshold(&_RAT.TransactOpts, threshold)
}

// SetPaused is a paid mutator transaction binding the contract method 0x16c38b3c.
//
// Solidity: function setPaused(bool _paused) returns()
func (_RAT *RATTransactor) SetPaused(opts *bind.TransactOpts, _paused bool) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setPaused", _paused)
}

// SetPaused is a paid mutator transaction binding the contract method 0x16c38b3c.
//
// Solidity: function setPaused(bool _paused) returns()
func (_RAT *RATSession) SetPaused(_paused bool) (*types.Transaction, error) {
	return _RAT.Contract.SetPaused(&_RAT.TransactOpts, _paused)
}

// SetPaused is a paid mutator transaction binding the contract method 0x16c38b3c.
//
// Solidity: function setPaused(bool _paused) returns()
func (_RAT *RATTransactorSession) SetPaused(_paused bool) (*types.Transaction, error) {
	return _RAT.Contract.SetPaused(&_RAT.TransactOpts, _paused)
}

// SetRatTriggerProbability is a paid mutator transaction binding the contract method 0xd2e5bc72.
//
// Solidity: function setRatTriggerProbability(uint256 probability) returns()
func (_RAT *RATTransactor) SetRatTriggerProbability(opts *bind.TransactOpts, probability *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setRatTriggerProbability", probability)
}

// SetRatTriggerProbability is a paid mutator transaction binding the contract method 0xd2e5bc72.
//
// Solidity: function setRatTriggerProbability(uint256 probability) returns()
func (_RAT *RATSession) SetRatTriggerProbability(probability *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetRatTriggerProbability(&_RAT.TransactOpts, probability)
}

// SetRatTriggerProbability is a paid mutator transaction binding the contract method 0xd2e5bc72.
//
// Solidity: function setRatTriggerProbability(uint256 probability) returns()
func (_RAT *RATTransactorSession) SetRatTriggerProbability(probability *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetRatTriggerProbability(&_RAT.TransactOpts, probability)
}

// SetRelaxedValidatorCheck is a paid mutator transaction binding the contract method 0xa4acc3ff.
//
// Solidity: function setRelaxedValidatorCheck(bool relaxed) returns()
func (_RAT *RATTransactor) SetRelaxedValidatorCheck(opts *bind.TransactOpts, relaxed bool) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setRelaxedValidatorCheck", relaxed)
}

// SetRelaxedValidatorCheck is a paid mutator transaction binding the contract method 0xa4acc3ff.
//
// Solidity: function setRelaxedValidatorCheck(bool relaxed) returns()
func (_RAT *RATSession) SetRelaxedValidatorCheck(relaxed bool) (*types.Transaction, error) {
	return _RAT.Contract.SetRelaxedValidatorCheck(&_RAT.TransactOpts, relaxed)
}

// SetRelaxedValidatorCheck is a paid mutator transaction binding the contract method 0xa4acc3ff.
//
// Solidity: function setRelaxedValidatorCheck(bool relaxed) returns()
func (_RAT *RATTransactorSession) SetRelaxedValidatorCheck(relaxed bool) (*types.Transaction, error) {
	return _RAT.Contract.SetRelaxedValidatorCheck(&_RAT.TransactOpts, relaxed)
}

// SetSafetyBuffer is a paid mutator transaction binding the contract method 0x4ad60241.
//
// Solidity: function setSafetyBuffer(uint256 buffer) returns()
func (_RAT *RATTransactor) SetSafetyBuffer(opts *bind.TransactOpts, buffer *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setSafetyBuffer", buffer)
}

// SetSafetyBuffer is a paid mutator transaction binding the contract method 0x4ad60241.
//
// Solidity: function setSafetyBuffer(uint256 buffer) returns()
func (_RAT *RATSession) SetSafetyBuffer(buffer *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetSafetyBuffer(&_RAT.TransactOpts, buffer)
}

// SetSafetyBuffer is a paid mutator transaction binding the contract method 0x4ad60241.
//
// Solidity: function setSafetyBuffer(uint256 buffer) returns()
func (_RAT *RATTransactorSession) SetSafetyBuffer(buffer *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetSafetyBuffer(&_RAT.TransactOpts, buffer)
}

// SetSlashingPenalty is a paid mutator transaction binding the contract method 0xf983386b.
//
// Solidity: function setSlashingPenalty(uint256 penalty) returns()
func (_RAT *RATTransactor) SetSlashingPenalty(opts *bind.TransactOpts, penalty *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setSlashingPenalty", penalty)
}

// SetSlashingPenalty is a paid mutator transaction binding the contract method 0xf983386b.
//
// Solidity: function setSlashingPenalty(uint256 penalty) returns()
func (_RAT *RATSession) SetSlashingPenalty(penalty *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetSlashingPenalty(&_RAT.TransactOpts, penalty)
}

// SetSlashingPenalty is a paid mutator transaction binding the contract method 0xf983386b.
//
// Solidity: function setSlashingPenalty(uint256 penalty) returns()
func (_RAT *RATTransactorSession) SetSlashingPenalty(penalty *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetSlashingPenalty(&_RAT.TransactOpts, penalty)
}

// SetTreasury is a paid mutator transaction binding the contract method 0xf0f44260.
//
// Solidity: function setTreasury(address _treasury) returns()
func (_RAT *RATTransactor) SetTreasury(opts *bind.TransactOpts, _treasury common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setTreasury", _treasury)
}

// SetTreasury is a paid mutator transaction binding the contract method 0xf0f44260.
//
// Solidity: function setTreasury(address _treasury) returns()
func (_RAT *RATSession) SetTreasury(_treasury common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetTreasury(&_RAT.TransactOpts, _treasury)
}

// SetTreasury is a paid mutator transaction binding the contract method 0xf0f44260.
//
// Solidity: function setTreasury(address _treasury) returns()
func (_RAT *RATTransactorSession) SetTreasury(_treasury common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetTreasury(&_RAT.TransactOpts, _treasury)
}

// SetValidatorBuffer is a paid mutator transaction binding the contract method 0x6ad83f91.
//
// Solidity: function setValidatorBuffer(uint256 buffer) returns()
func (_RAT *RATTransactor) SetValidatorBuffer(opts *bind.TransactOpts, buffer *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setValidatorBuffer", buffer)
}

// SetValidatorBuffer is a paid mutator transaction binding the contract method 0x6ad83f91.
//
// Solidity: function setValidatorBuffer(uint256 buffer) returns()
func (_RAT *RATSession) SetValidatorBuffer(buffer *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetValidatorBuffer(&_RAT.TransactOpts, buffer)
}

// SetValidatorBuffer is a paid mutator transaction binding the contract method 0x6ad83f91.
//
// Solidity: function setValidatorBuffer(uint256 buffer) returns()
func (_RAT *RATTransactorSession) SetValidatorBuffer(buffer *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.SetValidatorBuffer(&_RAT.TransactOpts, buffer)
}

// SetValidatorReward is a paid mutator transaction binding the contract method 0x117f45f9.
//
// Solidity: function setValidatorReward(address _validatorReward) returns()
func (_RAT *RATTransactor) SetValidatorReward(opts *bind.TransactOpts, _validatorReward common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "setValidatorReward", _validatorReward)
}

// SetValidatorReward is a paid mutator transaction binding the contract method 0x117f45f9.
//
// Solidity: function setValidatorReward(address _validatorReward) returns()
func (_RAT *RATSession) SetValidatorReward(_validatorReward common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetValidatorReward(&_RAT.TransactOpts, _validatorReward)
}

// SetValidatorReward is a paid mutator transaction binding the contract method 0x117f45f9.
//
// Solidity: function setValidatorReward(address _validatorReward) returns()
func (_RAT *RATTransactorSession) SetValidatorReward(_validatorReward common.Address) (*types.Transaction, error) {
	return _RAT.Contract.SetValidatorReward(&_RAT.TransactOpts, _validatorReward)
}

// SubmitEvidence is a paid mutator transaction binding the contract method 0xe54f6237.
//
// Solidity: function submitEvidence(address systemConfig, uint32 batchIndex, bytes evidence) returns()
func (_RAT *RATTransactor) SubmitEvidence(opts *bind.TransactOpts, systemConfig common.Address, batchIndex uint32, evidence []byte) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "submitEvidence", systemConfig, batchIndex, evidence)
}

// SubmitEvidence is a paid mutator transaction binding the contract method 0xe54f6237.
//
// Solidity: function submitEvidence(address systemConfig, uint32 batchIndex, bytes evidence) returns()
func (_RAT *RATSession) SubmitEvidence(systemConfig common.Address, batchIndex uint32, evidence []byte) (*types.Transaction, error) {
	return _RAT.Contract.SubmitEvidence(&_RAT.TransactOpts, systemConfig, batchIndex, evidence)
}

// SubmitEvidence is a paid mutator transaction binding the contract method 0xe54f6237.
//
// Solidity: function submitEvidence(address systemConfig, uint32 batchIndex, bytes evidence) returns()
func (_RAT *RATTransactorSession) SubmitEvidence(systemConfig common.Address, batchIndex uint32, evidence []byte) (*types.Transaction, error) {
	return _RAT.Contract.SubmitEvidence(&_RAT.TransactOpts, systemConfig, batchIndex, evidence)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_RAT *RATTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_RAT *RATSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _RAT.Contract.TransferOwnership(&_RAT.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_RAT *RATTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _RAT.Contract.TransferOwnership(&_RAT.TransactOpts, newOwner)
}

// TriggerAttentionTest is a paid mutator transaction binding the contract method 0x004fe2b4.
//
// Solidity: function triggerAttentionTest(address gameAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, bytes32 blockHash) returns()
func (_RAT *RATTransactor) TriggerAttentionTest(opts *bind.TransactOpts, gameAddress common.Address, systemConfig common.Address, batchIndex uint32, batchHash [32]byte, blockHash [32]byte) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "triggerAttentionTest", gameAddress, systemConfig, batchIndex, batchHash, blockHash)
}

// TriggerAttentionTest is a paid mutator transaction binding the contract method 0x004fe2b4.
//
// Solidity: function triggerAttentionTest(address gameAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, bytes32 blockHash) returns()
func (_RAT *RATSession) TriggerAttentionTest(gameAddress common.Address, systemConfig common.Address, batchIndex uint32, batchHash [32]byte, blockHash [32]byte) (*types.Transaction, error) {
	return _RAT.Contract.TriggerAttentionTest(&_RAT.TransactOpts, gameAddress, systemConfig, batchIndex, batchHash, blockHash)
}

// TriggerAttentionTest is a paid mutator transaction binding the contract method 0x004fe2b4.
//
// Solidity: function triggerAttentionTest(address gameAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, bytes32 blockHash) returns()
func (_RAT *RATTransactorSession) TriggerAttentionTest(gameAddress common.Address, systemConfig common.Address, batchIndex uint32, batchHash [32]byte, blockHash [32]byte) (*types.Transaction, error) {
	return _RAT.Contract.TriggerAttentionTest(&_RAT.TransactOpts, gameAddress, systemConfig, batchIndex, batchHash, blockHash)
}

// WithdrawSlashingsToTreasury is a paid mutator transaction binding the contract method 0x71e0cdc7.
//
// Solidity: function withdrawSlashingsToTreasury(address systemConfig) returns()
func (_RAT *RATTransactor) WithdrawSlashingsToTreasury(opts *bind.TransactOpts, systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "withdrawSlashingsToTreasury", systemConfig)
}

// WithdrawSlashingsToTreasury is a paid mutator transaction binding the contract method 0x71e0cdc7.
//
// Solidity: function withdrawSlashingsToTreasury(address systemConfig) returns()
func (_RAT *RATSession) WithdrawSlashingsToTreasury(systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.Contract.WithdrawSlashingsToTreasury(&_RAT.TransactOpts, systemConfig)
}

// WithdrawSlashingsToTreasury is a paid mutator transaction binding the contract method 0x71e0cdc7.
//
// Solidity: function withdrawSlashingsToTreasury(address systemConfig) returns()
func (_RAT *RATTransactorSession) WithdrawSlashingsToTreasury(systemConfig common.Address) (*types.Transaction, error) {
	return _RAT.Contract.WithdrawSlashingsToTreasury(&_RAT.TransactOpts, systemConfig)
}

// RATAccumulatedSlashingsResetIterator is returned from FilterAccumulatedSlashingsReset and is used to iterate over the raw logs and unpacked data for AccumulatedSlashingsReset events raised by the RAT contract.
type RATAccumulatedSlashingsResetIterator struct {
	Event *RATAccumulatedSlashingsReset // Event containing the contract specifics and raw log

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
func (it *RATAccumulatedSlashingsResetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATAccumulatedSlashingsReset)
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
		it.Event = new(RATAccumulatedSlashingsReset)
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
func (it *RATAccumulatedSlashingsResetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATAccumulatedSlashingsResetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATAccumulatedSlashingsReset represents a AccumulatedSlashingsReset event raised by the RAT contract.
type RATAccumulatedSlashingsReset struct {
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterAccumulatedSlashingsReset is a free log retrieval operation binding the contract event 0xcf37a3aec7e6ba6e02f61913533b0be478985ae4ec96c4be36170fd79bea90fc.
//
// Solidity: event AccumulatedSlashingsReset(uint256 amount)
func (_RAT *RATFilterer) FilterAccumulatedSlashingsReset(opts *bind.FilterOpts) (*RATAccumulatedSlashingsResetIterator, error) {

	logs, sub, err := _RAT.contract.FilterLogs(opts, "AccumulatedSlashingsReset")
	if err != nil {
		return nil, err
	}
	return &RATAccumulatedSlashingsResetIterator{contract: _RAT.contract, event: "AccumulatedSlashingsReset", logs: logs, sub: sub}, nil
}

// WatchAccumulatedSlashingsReset is a free log subscription operation binding the contract event 0xcf37a3aec7e6ba6e02f61913533b0be478985ae4ec96c4be36170fd79bea90fc.
//
// Solidity: event AccumulatedSlashingsReset(uint256 amount)
func (_RAT *RATFilterer) WatchAccumulatedSlashingsReset(opts *bind.WatchOpts, sink chan<- *RATAccumulatedSlashingsReset) (event.Subscription, error) {

	logs, sub, err := _RAT.contract.WatchLogs(opts, "AccumulatedSlashingsReset")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATAccumulatedSlashingsReset)
				if err := _RAT.contract.UnpackLog(event, "AccumulatedSlashingsReset", log); err != nil {
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

// ParseAccumulatedSlashingsReset is a log parse operation binding the contract event 0xcf37a3aec7e6ba6e02f61913533b0be478985ae4ec96c4be36170fd79bea90fc.
//
// Solidity: event AccumulatedSlashingsReset(uint256 amount)
func (_RAT *RATFilterer) ParseAccumulatedSlashingsReset(log types.Log) (*RATAccumulatedSlashingsReset, error) {
	event := new(RATAccumulatedSlashingsReset)
	if err := _RAT.contract.UnpackLog(event, "AccumulatedSlashingsReset", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATAttentionTestTriggeredIterator is returned from FilterAttentionTestTriggered and is used to iterate over the raw logs and unpacked data for AttentionTestTriggered events raised by the RAT contract.
type RATAttentionTestTriggeredIterator struct {
	Event *RATAttentionTestTriggered // Event containing the contract specifics and raw log

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

// RATAttentionTestTriggered represents a AttentionTestTriggered event raised by the RAT contract.
type RATAttentionTestTriggered struct {
	TestId       [32]byte
	Validator    common.Address
	SystemConfig common.Address
	GameAddress  common.Address
	BatchIndex   uint32
	Deadline     *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterAttentionTestTriggered is a free log retrieval operation binding the contract event 0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38.
//
// Solidity: event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline)
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

// WatchAttentionTestTriggered is a free log subscription operation binding the contract event 0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38.
//
// Solidity: event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline)
func (_RAT *RATFilterer) WatchAttentionTestTriggered(opts *bind.WatchOpts, sink chan<- *RATAttentionTestTriggered, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _RAT.contract.WatchLogs(opts, "AttentionTestTriggered", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATAttentionTestTriggered)
				if err := _RAT.contract.UnpackLog(event, "AttentionTestTriggered", log); err != nil {
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

// ParseAttentionTestTriggered is a log parse operation binding the contract event 0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38.
//
// Solidity: event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline)
func (_RAT *RATFilterer) ParseAttentionTestTriggered(log types.Log) (*RATAttentionTestTriggered, error) {
	event := new(RATAttentionTestTriggered)
	if err := _RAT.contract.UnpackLog(event, "AttentionTestTriggered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATBondRestoredIterator is returned from FilterBondRestored and is used to iterate over the raw logs and unpacked data for BondRestored events raised by the RAT contract.
type RATBondRestoredIterator struct {
	Event *RATBondRestored // Event containing the contract specifics and raw log

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
func (it *RATBondRestoredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATBondRestored)
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
		it.Event = new(RATBondRestored)
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
func (it *RATBondRestoredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATBondRestoredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATBondRestored represents a BondRestored event raised by the RAT contract.
type RATBondRestored struct {
	TestId         [32]byte
	Validator      common.Address
	SystemConfig   common.Address
	Layer2         common.Address
	RestoredAmount *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterBondRestored is a free log retrieval operation binding the contract event 0x2327e8a868d6be4a9d13dc1c06ddedf7ac7f3e7ed53803bf31da5c7349f82f01.
//
// Solidity: event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint256 restoredAmount)
func (_RAT *RATFilterer) FilterBondRestored(opts *bind.FilterOpts, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (*RATBondRestoredIterator, error) {

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

	logs, sub, err := _RAT.contract.FilterLogs(opts, "BondRestored", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATBondRestoredIterator{contract: _RAT.contract, event: "BondRestored", logs: logs, sub: sub}, nil
}

// WatchBondRestored is a free log subscription operation binding the contract event 0x2327e8a868d6be4a9d13dc1c06ddedf7ac7f3e7ed53803bf31da5c7349f82f01.
//
// Solidity: event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint256 restoredAmount)
func (_RAT *RATFilterer) WatchBondRestored(opts *bind.WatchOpts, sink chan<- *RATBondRestored, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _RAT.contract.WatchLogs(opts, "BondRestored", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATBondRestored)
				if err := _RAT.contract.UnpackLog(event, "BondRestored", log); err != nil {
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

// ParseBondRestored is a log parse operation binding the contract event 0x2327e8a868d6be4a9d13dc1c06ddedf7ac7f3e7ed53803bf31da5c7349f82f01.
//
// Solidity: event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint256 restoredAmount)
func (_RAT *RATFilterer) ParseBondRestored(log types.Log) (*RATBondRestored, error) {
	event := new(RATBondRestored)
	if err := _RAT.contract.UnpackLog(event, "BondRestored", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATDepositAddedIterator is returned from FilterDepositAdded and is used to iterate over the raw logs and unpacked data for DepositAdded events raised by the RAT contract.
type RATDepositAddedIterator struct {
	Event *RATDepositAdded // Event containing the contract specifics and raw log

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
func (it *RATDepositAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATDepositAdded)
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
		it.Event = new(RATDepositAdded)
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
func (it *RATDepositAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATDepositAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATDepositAdded represents a DepositAdded event raised by the RAT contract.
type RATDepositAdded struct {
	Validator    common.Address
	SystemConfig common.Address
	Amount       *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterDepositAdded is a free log retrieval operation binding the contract event 0x63d8d7d5e63e9840ec91a12a160d27b7cfab294f6ba070b7359692acfe6b03bf.
//
// Solidity: event DepositAdded(address indexed validator, address indexed systemConfig, uint256 amount)
func (_RAT *RATFilterer) FilterDepositAdded(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address) (*RATDepositAddedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "DepositAdded", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATDepositAddedIterator{contract: _RAT.contract, event: "DepositAdded", logs: logs, sub: sub}, nil
}

// WatchDepositAdded is a free log subscription operation binding the contract event 0x63d8d7d5e63e9840ec91a12a160d27b7cfab294f6ba070b7359692acfe6b03bf.
//
// Solidity: event DepositAdded(address indexed validator, address indexed systemConfig, uint256 amount)
func (_RAT *RATFilterer) WatchDepositAdded(opts *bind.WatchOpts, sink chan<- *RATDepositAdded, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "DepositAdded", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATDepositAdded)
				if err := _RAT.contract.UnpackLog(event, "DepositAdded", log); err != nil {
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

// ParseDepositAdded is a log parse operation binding the contract event 0x63d8d7d5e63e9840ec91a12a160d27b7cfab294f6ba070b7359692acfe6b03bf.
//
// Solidity: event DepositAdded(address indexed validator, address indexed systemConfig, uint256 amount)
func (_RAT *RATFilterer) ParseDepositAdded(log types.Log) (*RATDepositAdded, error) {
	event := new(RATDepositAdded)
	if err := _RAT.contract.UnpackLog(event, "DepositAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATEvidenceSubmittedIterator is returned from FilterEvidenceSubmitted and is used to iterate over the raw logs and unpacked data for EvidenceSubmitted events raised by the RAT contract.
type RATEvidenceSubmittedIterator struct {
	Event *RATEvidenceSubmitted // Event containing the contract specifics and raw log

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
func (it *RATEvidenceSubmittedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATEvidenceSubmitted)
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
		it.Event = new(RATEvidenceSubmitted)
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
func (it *RATEvidenceSubmittedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATEvidenceSubmittedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATEvidenceSubmitted represents a EvidenceSubmitted event raised by the RAT contract.
type RATEvidenceSubmitted struct {
	TestId       [32]byte
	Validator    common.Address
	SystemConfig common.Address
	Layer2       common.Address
	BatchIndex   uint32
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterEvidenceSubmitted is a free log retrieval operation binding the contract event 0xd5071c9f488cc0aa883e3bc1547c20c8466a9639cfed6db4c47ea8371d174c12.
//
// Solidity: event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint32 batchIndex)
func (_RAT *RATFilterer) FilterEvidenceSubmitted(opts *bind.FilterOpts, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (*RATEvidenceSubmittedIterator, error) {

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

	logs, sub, err := _RAT.contract.FilterLogs(opts, "EvidenceSubmitted", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATEvidenceSubmittedIterator{contract: _RAT.contract, event: "EvidenceSubmitted", logs: logs, sub: sub}, nil
}

// WatchEvidenceSubmitted is a free log subscription operation binding the contract event 0xd5071c9f488cc0aa883e3bc1547c20c8466a9639cfed6db4c47ea8371d174c12.
//
// Solidity: event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint32 batchIndex)
func (_RAT *RATFilterer) WatchEvidenceSubmitted(opts *bind.WatchOpts, sink chan<- *RATEvidenceSubmitted, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _RAT.contract.WatchLogs(opts, "EvidenceSubmitted", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATEvidenceSubmitted)
				if err := _RAT.contract.UnpackLog(event, "EvidenceSubmitted", log); err != nil {
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

// ParseEvidenceSubmitted is a log parse operation binding the contract event 0xd5071c9f488cc0aa883e3bc1547c20c8466a9639cfed6db4c47ea8371d174c12.
//
// Solidity: event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint32 batchIndex)
func (_RAT *RATFilterer) ParseEvidenceSubmitted(log types.Log) (*RATEvidenceSubmitted, error) {
	event := new(RATEvidenceSubmitted)
	if err := _RAT.contract.UnpackLog(event, "EvidenceSubmitted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATMaxValidatorsPerL2UpdatedIterator is returned from FilterMaxValidatorsPerL2Updated and is used to iterate over the raw logs and unpacked data for MaxValidatorsPerL2Updated events raised by the RAT contract.
type RATMaxValidatorsPerL2UpdatedIterator struct {
	Event *RATMaxValidatorsPerL2Updated // Event containing the contract specifics and raw log

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
func (it *RATMaxValidatorsPerL2UpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATMaxValidatorsPerL2Updated)
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
		it.Event = new(RATMaxValidatorsPerL2Updated)
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
func (it *RATMaxValidatorsPerL2UpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATMaxValidatorsPerL2UpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATMaxValidatorsPerL2Updated represents a MaxValidatorsPerL2Updated event raised by the RAT contract.
type RATMaxValidatorsPerL2Updated struct {
	NewMaxValidators *big.Int
	Raw              types.Log // Blockchain specific contextual infos
}

// FilterMaxValidatorsPerL2Updated is a free log retrieval operation binding the contract event 0xa03f0d48c0ef0e0b6916f6c0f9e415d7319a1ea4a09ca66e68f473939ee2b10c.
//
// Solidity: event MaxValidatorsPerL2Updated(uint256 newMaxValidators)
func (_RAT *RATFilterer) FilterMaxValidatorsPerL2Updated(opts *bind.FilterOpts) (*RATMaxValidatorsPerL2UpdatedIterator, error) {

	logs, sub, err := _RAT.contract.FilterLogs(opts, "MaxValidatorsPerL2Updated")
	if err != nil {
		return nil, err
	}
	return &RATMaxValidatorsPerL2UpdatedIterator{contract: _RAT.contract, event: "MaxValidatorsPerL2Updated", logs: logs, sub: sub}, nil
}

// WatchMaxValidatorsPerL2Updated is a free log subscription operation binding the contract event 0xa03f0d48c0ef0e0b6916f6c0f9e415d7319a1ea4a09ca66e68f473939ee2b10c.
//
// Solidity: event MaxValidatorsPerL2Updated(uint256 newMaxValidators)
func (_RAT *RATFilterer) WatchMaxValidatorsPerL2Updated(opts *bind.WatchOpts, sink chan<- *RATMaxValidatorsPerL2Updated) (event.Subscription, error) {

	logs, sub, err := _RAT.contract.WatchLogs(opts, "MaxValidatorsPerL2Updated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATMaxValidatorsPerL2Updated)
				if err := _RAT.contract.UnpackLog(event, "MaxValidatorsPerL2Updated", log); err != nil {
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

// ParseMaxValidatorsPerL2Updated is a log parse operation binding the contract event 0xa03f0d48c0ef0e0b6916f6c0f9e415d7319a1ea4a09ca66e68f473939ee2b10c.
//
// Solidity: event MaxValidatorsPerL2Updated(uint256 newMaxValidators)
func (_RAT *RATFilterer) ParseMaxValidatorsPerL2Updated(log types.Log) (*RATMaxValidatorsPerL2Updated, error) {
	event := new(RATMaxValidatorsPerL2Updated)
	if err := _RAT.contract.UnpackLog(event, "MaxValidatorsPerL2Updated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATRelaxedValidatorCheckUpdatedIterator is returned from FilterRelaxedValidatorCheckUpdated and is used to iterate over the raw logs and unpacked data for RelaxedValidatorCheckUpdated events raised by the RAT contract.
type RATRelaxedValidatorCheckUpdatedIterator struct {
	Event *RATRelaxedValidatorCheckUpdated // Event containing the contract specifics and raw log

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
func (it *RATRelaxedValidatorCheckUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATRelaxedValidatorCheckUpdated)
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
		it.Event = new(RATRelaxedValidatorCheckUpdated)
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
func (it *RATRelaxedValidatorCheckUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATRelaxedValidatorCheckUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATRelaxedValidatorCheckUpdated represents a RelaxedValidatorCheckUpdated event raised by the RAT contract.
type RATRelaxedValidatorCheckUpdated struct {
	Relaxed bool
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRelaxedValidatorCheckUpdated is a free log retrieval operation binding the contract event 0xfe0f8833f7cc6034e316816ad11b5e0f8ba6cb0bb01b25978652e8bb02b682ff.
//
// Solidity: event RelaxedValidatorCheckUpdated(bool relaxed)
func (_RAT *RATFilterer) FilterRelaxedValidatorCheckUpdated(opts *bind.FilterOpts) (*RATRelaxedValidatorCheckUpdatedIterator, error) {

	logs, sub, err := _RAT.contract.FilterLogs(opts, "RelaxedValidatorCheckUpdated")
	if err != nil {
		return nil, err
	}
	return &RATRelaxedValidatorCheckUpdatedIterator{contract: _RAT.contract, event: "RelaxedValidatorCheckUpdated", logs: logs, sub: sub}, nil
}

// WatchRelaxedValidatorCheckUpdated is a free log subscription operation binding the contract event 0xfe0f8833f7cc6034e316816ad11b5e0f8ba6cb0bb01b25978652e8bb02b682ff.
//
// Solidity: event RelaxedValidatorCheckUpdated(bool relaxed)
func (_RAT *RATFilterer) WatchRelaxedValidatorCheckUpdated(opts *bind.WatchOpts, sink chan<- *RATRelaxedValidatorCheckUpdated) (event.Subscription, error) {

	logs, sub, err := _RAT.contract.WatchLogs(opts, "RelaxedValidatorCheckUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATRelaxedValidatorCheckUpdated)
				if err := _RAT.contract.UnpackLog(event, "RelaxedValidatorCheckUpdated", log); err != nil {
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

// ParseRelaxedValidatorCheckUpdated is a log parse operation binding the contract event 0xfe0f8833f7cc6034e316816ad11b5e0f8ba6cb0bb01b25978652e8bb02b682ff.
//
// Solidity: event RelaxedValidatorCheckUpdated(bool relaxed)
func (_RAT *RATFilterer) ParseRelaxedValidatorCheckUpdated(log types.Log) (*RATRelaxedValidatorCheckUpdated, error) {
	event := new(RATRelaxedValidatorCheckUpdated)
	if err := _RAT.contract.UnpackLog(event, "RelaxedValidatorCheckUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATSlashingsWithdrawnIterator is returned from FilterSlashingsWithdrawn and is used to iterate over the raw logs and unpacked data for SlashingsWithdrawn events raised by the RAT contract.
type RATSlashingsWithdrawnIterator struct {
	Event *RATSlashingsWithdrawn // Event containing the contract specifics and raw log

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
func (it *RATSlashingsWithdrawnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATSlashingsWithdrawn)
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
		it.Event = new(RATSlashingsWithdrawn)
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
func (it *RATSlashingsWithdrawnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATSlashingsWithdrawnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATSlashingsWithdrawn represents a SlashingsWithdrawn event raised by the RAT contract.
type RATSlashingsWithdrawn struct {
	SystemConfig common.Address
	Layer2       common.Address
	Treasury     common.Address
	Amount       *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterSlashingsWithdrawn is a free log retrieval operation binding the contract event 0xae1cbfa544938580fc41f97c3cd461450c2a221c16dad6d1896e350c51c2b5f8.
//
// Solidity: event SlashingsWithdrawn(address indexed systemConfig, address indexed layer2, address indexed treasury, uint256 amount)
func (_RAT *RATFilterer) FilterSlashingsWithdrawn(opts *bind.FilterOpts, systemConfig []common.Address, layer2 []common.Address, treasury []common.Address) (*RATSlashingsWithdrawnIterator, error) {

	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}
	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}
	var treasuryRule []interface{}
	for _, treasuryItem := range treasury {
		treasuryRule = append(treasuryRule, treasuryItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "SlashingsWithdrawn", systemConfigRule, layer2Rule, treasuryRule)
	if err != nil {
		return nil, err
	}
	return &RATSlashingsWithdrawnIterator{contract: _RAT.contract, event: "SlashingsWithdrawn", logs: logs, sub: sub}, nil
}

// WatchSlashingsWithdrawn is a free log subscription operation binding the contract event 0xae1cbfa544938580fc41f97c3cd461450c2a221c16dad6d1896e350c51c2b5f8.
//
// Solidity: event SlashingsWithdrawn(address indexed systemConfig, address indexed layer2, address indexed treasury, uint256 amount)
func (_RAT *RATFilterer) WatchSlashingsWithdrawn(opts *bind.WatchOpts, sink chan<- *RATSlashingsWithdrawn, systemConfig []common.Address, layer2 []common.Address, treasury []common.Address) (event.Subscription, error) {

	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}
	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}
	var treasuryRule []interface{}
	for _, treasuryItem := range treasury {
		treasuryRule = append(treasuryRule, treasuryItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "SlashingsWithdrawn", systemConfigRule, layer2Rule, treasuryRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATSlashingsWithdrawn)
				if err := _RAT.contract.UnpackLog(event, "SlashingsWithdrawn", log); err != nil {
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

// ParseSlashingsWithdrawn is a log parse operation binding the contract event 0xae1cbfa544938580fc41f97c3cd461450c2a221c16dad6d1896e350c51c2b5f8.
//
// Solidity: event SlashingsWithdrawn(address indexed systemConfig, address indexed layer2, address indexed treasury, uint256 amount)
func (_RAT *RATFilterer) ParseSlashingsWithdrawn(log types.Log) (*RATSlashingsWithdrawn, error) {
	event := new(RATSlashingsWithdrawn)
	if err := _RAT.contract.UnpackLog(event, "SlashingsWithdrawn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATValidatorDeactivatedIterator is returned from FilterValidatorDeactivated and is used to iterate over the raw logs and unpacked data for ValidatorDeactivated events raised by the RAT contract.
type RATValidatorDeactivatedIterator struct {
	Event *RATValidatorDeactivated // Event containing the contract specifics and raw log

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
func (it *RATValidatorDeactivatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATValidatorDeactivated)
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
		it.Event = new(RATValidatorDeactivated)
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
func (it *RATValidatorDeactivatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATValidatorDeactivatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATValidatorDeactivated represents a ValidatorDeactivated event raised by the RAT contract.
type RATValidatorDeactivated struct {
	Validator    common.Address
	SystemConfig common.Address
	Layer2       common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterValidatorDeactivated is a free log retrieval operation binding the contract event 0x36a712493202476d322fa302e9c27e6632bd4dbbe9840b0043a538893cb54220.
//
// Solidity: event ValidatorDeactivated(address indexed validator, address indexed systemConfig, address indexed layer2)
func (_RAT *RATFilterer) FilterValidatorDeactivated(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address, layer2 []common.Address) (*RATValidatorDeactivatedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}
	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorDeactivated", validatorRule, systemConfigRule, layer2Rule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorDeactivatedIterator{contract: _RAT.contract, event: "ValidatorDeactivated", logs: logs, sub: sub}, nil
}

// WatchValidatorDeactivated is a free log subscription operation binding the contract event 0x36a712493202476d322fa302e9c27e6632bd4dbbe9840b0043a538893cb54220.
//
// Solidity: event ValidatorDeactivated(address indexed validator, address indexed systemConfig, address indexed layer2)
func (_RAT *RATFilterer) WatchValidatorDeactivated(opts *bind.WatchOpts, sink chan<- *RATValidatorDeactivated, validator []common.Address, systemConfig []common.Address, layer2 []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}
	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorDeactivated", validatorRule, systemConfigRule, layer2Rule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATValidatorDeactivated)
				if err := _RAT.contract.UnpackLog(event, "ValidatorDeactivated", log); err != nil {
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

// ParseValidatorDeactivated is a log parse operation binding the contract event 0x36a712493202476d322fa302e9c27e6632bd4dbbe9840b0043a538893cb54220.
//
// Solidity: event ValidatorDeactivated(address indexed validator, address indexed systemConfig, address indexed layer2)
func (_RAT *RATFilterer) ParseValidatorDeactivated(log types.Log) (*RATValidatorDeactivated, error) {
	event := new(RATValidatorDeactivated)
	if err := _RAT.contract.UnpackLog(event, "ValidatorDeactivated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATValidatorReactivatedIterator is returned from FilterValidatorReactivated and is used to iterate over the raw logs and unpacked data for ValidatorReactivated events raised by the RAT contract.
type RATValidatorReactivatedIterator struct {
	Event *RATValidatorReactivated // Event containing the contract specifics and raw log

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
func (it *RATValidatorReactivatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATValidatorReactivated)
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
		it.Event = new(RATValidatorReactivated)
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
func (it *RATValidatorReactivatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATValidatorReactivatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATValidatorReactivated represents a ValidatorReactivated event raised by the RAT contract.
type RATValidatorReactivated struct {
	Validator    common.Address
	SystemConfig common.Address
	Layer2       common.Address
	Collateral   *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterValidatorReactivated is a free log retrieval operation binding the contract event 0x99b9d8dec460eecfed8de638ceef05e3aa56696d3166cea3029fce48847a9e1b.
//
// Solidity: event ValidatorReactivated(address indexed validator, address indexed systemConfig, address indexed layer2, uint256 collateral)
func (_RAT *RATFilterer) FilterValidatorReactivated(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address, layer2 []common.Address) (*RATValidatorReactivatedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}
	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorReactivated", validatorRule, systemConfigRule, layer2Rule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorReactivatedIterator{contract: _RAT.contract, event: "ValidatorReactivated", logs: logs, sub: sub}, nil
}

// WatchValidatorReactivated is a free log subscription operation binding the contract event 0x99b9d8dec460eecfed8de638ceef05e3aa56696d3166cea3029fce48847a9e1b.
//
// Solidity: event ValidatorReactivated(address indexed validator, address indexed systemConfig, address indexed layer2, uint256 collateral)
func (_RAT *RATFilterer) WatchValidatorReactivated(opts *bind.WatchOpts, sink chan<- *RATValidatorReactivated, validator []common.Address, systemConfig []common.Address, layer2 []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}
	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorReactivated", validatorRule, systemConfigRule, layer2Rule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATValidatorReactivated)
				if err := _RAT.contract.UnpackLog(event, "ValidatorReactivated", log); err != nil {
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

// ParseValidatorReactivated is a log parse operation binding the contract event 0x99b9d8dec460eecfed8de638ceef05e3aa56696d3166cea3029fce48847a9e1b.
//
// Solidity: event ValidatorReactivated(address indexed validator, address indexed systemConfig, address indexed layer2, uint256 collateral)
func (_RAT *RATFilterer) ParseValidatorReactivated(log types.Log) (*RATValidatorReactivated, error) {
	event := new(RATValidatorReactivated)
	if err := _RAT.contract.UnpackLog(event, "ValidatorReactivated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATValidatorRegisteredIterator is returned from FilterValidatorRegistered and is used to iterate over the raw logs and unpacked data for ValidatorRegistered events raised by the RAT contract.
type RATValidatorRegisteredIterator struct {
	Event *RATValidatorRegistered // Event containing the contract specifics and raw log

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
func (it *RATValidatorRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATValidatorRegistered)
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
		it.Event = new(RATValidatorRegistered)
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
func (it *RATValidatorRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATValidatorRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATValidatorRegistered represents a ValidatorRegistered event raised by the RAT contract.
type RATValidatorRegistered struct {
	Validator      common.Address
	SystemConfig   common.Address
	Layer2         common.Address
	DepositAmount  *big.Int
	RegistrationId *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterValidatorRegistered is a free log retrieval operation binding the contract event 0x317f78b7f1495be7f160c255693f09ccbd5367aa7acd721aa14eb14308da785c.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, address indexed layer2, uint256 depositAmount, uint256 registrationId)
func (_RAT *RATFilterer) FilterValidatorRegistered(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address, layer2 []common.Address) (*RATValidatorRegisteredIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}
	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorRegistered", validatorRule, systemConfigRule, layer2Rule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorRegisteredIterator{contract: _RAT.contract, event: "ValidatorRegistered", logs: logs, sub: sub}, nil
}

// WatchValidatorRegistered is a free log subscription operation binding the contract event 0x317f78b7f1495be7f160c255693f09ccbd5367aa7acd721aa14eb14308da785c.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, address indexed layer2, uint256 depositAmount, uint256 registrationId)
func (_RAT *RATFilterer) WatchValidatorRegistered(opts *bind.WatchOpts, sink chan<- *RATValidatorRegistered, validator []common.Address, systemConfig []common.Address, layer2 []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}
	var layer2Rule []interface{}
	for _, layer2Item := range layer2 {
		layer2Rule = append(layer2Rule, layer2Item)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorRegistered", validatorRule, systemConfigRule, layer2Rule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATValidatorRegistered)
				if err := _RAT.contract.UnpackLog(event, "ValidatorRegistered", log); err != nil {
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

// ParseValidatorRegistered is a log parse operation binding the contract event 0x317f78b7f1495be7f160c255693f09ccbd5367aa7acd721aa14eb14308da785c.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, address indexed layer2, uint256 depositAmount, uint256 registrationId)
func (_RAT *RATFilterer) ParseValidatorRegistered(log types.Log) (*RATValidatorRegistered, error) {
	event := new(RATValidatorRegistered)
	if err := _RAT.contract.UnpackLog(event, "ValidatorRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATValidatorRestoredIterator is returned from FilterValidatorRestored and is used to iterate over the raw logs and unpacked data for ValidatorRestored events raised by the RAT contract.
type RATValidatorRestoredIterator struct {
	Event *RATValidatorRestored // Event containing the contract specifics and raw log

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
func (it *RATValidatorRestoredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATValidatorRestored)
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
		it.Event = new(RATValidatorRestored)
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
func (it *RATValidatorRestoredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATValidatorRestoredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATValidatorRestored represents a ValidatorRestored event raised by the RAT contract.
type RATValidatorRestored struct {
	Validator    common.Address
	SystemConfig common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterValidatorRestored is a free log retrieval operation binding the contract event 0xacf682cec5d019e69bf9a11a0ee8d582373446ed7815c383edf30b5b40056699.
//
// Solidity: event ValidatorRestored(address indexed validator, address indexed systemConfig)
func (_RAT *RATFilterer) FilterValidatorRestored(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address) (*RATValidatorRestoredIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorRestored", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorRestoredIterator{contract: _RAT.contract, event: "ValidatorRestored", logs: logs, sub: sub}, nil
}

// WatchValidatorRestored is a free log subscription operation binding the contract event 0xacf682cec5d019e69bf9a11a0ee8d582373446ed7815c383edf30b5b40056699.
//
// Solidity: event ValidatorRestored(address indexed validator, address indexed systemConfig)
func (_RAT *RATFilterer) WatchValidatorRestored(opts *bind.WatchOpts, sink chan<- *RATValidatorRestored, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorRestored", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATValidatorRestored)
				if err := _RAT.contract.UnpackLog(event, "ValidatorRestored", log); err != nil {
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

// ParseValidatorRestored is a log parse operation binding the contract event 0xacf682cec5d019e69bf9a11a0ee8d582373446ed7815c383edf30b5b40056699.
//
// Solidity: event ValidatorRestored(address indexed validator, address indexed systemConfig)
func (_RAT *RATFilterer) ParseValidatorRestored(log types.Log) (*RATValidatorRestored, error) {
	event := new(RATValidatorRestored)
	if err := _RAT.contract.UnpackLog(event, "ValidatorRestored", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RATValidatorSlashedIterator is returned from FilterValidatorSlashed and is used to iterate over the raw logs and unpacked data for ValidatorSlashed events raised by the RAT contract.
type RATValidatorSlashedIterator struct {
	Event *RATValidatorSlashed // Event containing the contract specifics and raw log

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
func (it *RATValidatorSlashedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RATValidatorSlashed)
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
		it.Event = new(RATValidatorSlashed)
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
func (it *RATValidatorSlashedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RATValidatorSlashedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RATValidatorSlashed represents a ValidatorSlashed event raised by the RAT contract.
type RATValidatorSlashed struct {
	TestId         [32]byte
	Validator      common.Address
	SystemConfig   common.Address
	Layer2         common.Address
	SlashedAmount  *big.Int
	RemovedFromSet bool
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterValidatorSlashed is a free log retrieval operation binding the contract event 0x309a2ca0abe55907f1becd1cb4b5e81142d1db88840c88483d4ce8c2b420aad8.
//
// Solidity: event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint256 slashedAmount, bool removedFromSet)
func (_RAT *RATFilterer) FilterValidatorSlashed(opts *bind.FilterOpts, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (*RATValidatorSlashedIterator, error) {

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

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorSlashed", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorSlashedIterator{contract: _RAT.contract, event: "ValidatorSlashed", logs: logs, sub: sub}, nil
}

// WatchValidatorSlashed is a free log subscription operation binding the contract event 0x309a2ca0abe55907f1becd1cb4b5e81142d1db88840c88483d4ce8c2b420aad8.
//
// Solidity: event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint256 slashedAmount, bool removedFromSet)
func (_RAT *RATFilterer) WatchValidatorSlashed(opts *bind.WatchOpts, sink chan<- *RATValidatorSlashed, testId [][32]byte, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorSlashed", testIdRule, validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RATValidatorSlashed)
				if err := _RAT.contract.UnpackLog(event, "ValidatorSlashed", log); err != nil {
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

// ParseValidatorSlashed is a log parse operation binding the contract event 0x309a2ca0abe55907f1becd1cb4b5e81142d1db88840c88483d4ce8c2b420aad8.
//
// Solidity: event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint256 slashedAmount, bool removedFromSet)
func (_RAT *RATFilterer) ParseValidatorSlashed(log types.Log) (*RATValidatorSlashed, error) {
	event := new(RATValidatorSlashed)
	if err := _RAT.contract.UnpackLog(event, "ValidatorSlashed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
