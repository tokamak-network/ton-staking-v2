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

// RATABI is the input ABI used to generate the binding from.
const RATABI = "[{\"type\":\"function\",\"name\":\"accumulatedSlashings\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"activeTestCount\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"attentionCost\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"attentionTests\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"validatorAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"bondAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"authorizedTrigger\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"batchToTestId\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"challengeGameDuration\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deactivateValidator\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"evidenceSubmissionPeriod\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"factoryByGame\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"gameToTestId\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getActiveValidatorCount\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAttentionTest\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"validatorAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"bondAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAttentionTestStatus\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAvailableCollateral\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCoffWithRelaxedCheck\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getDynamicCoff\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getDynamicMinimumCollateral\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getL2Validators\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinimumCollateral\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinimumCollateralWithRelaxedCheck\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRATCoinageBalance\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorCount\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorDeposit\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorMinCollateralForLayer2\",\"inputs\":[{\"name\":\"layer2\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorRegistration\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"collateral\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validatorIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"isActive\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"_seigManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_wton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_ton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_layer2Manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_ratTriggerProbability\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_evidenceSubmissionPeriod\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_slashingPenalty\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_validatorBuffer\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_minimumThreshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_maxValidatorsPerL2\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_challengeGameDuration\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_safetyBuffer\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isValidatorActive\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1BridgeRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"latestDeadlineTest\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2Manager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxValidatorsPerL2\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minimumThreshold\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ratTriggerProbability\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"registerValidator\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerValidatorV2Compat\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"depositAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"relaxedValidatorCheck\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"resolveClaim\",\"inputs\":[{\"name\":\"_claimant\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safetyBuffer\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"seigManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setAttentionCost\",\"inputs\":[{\"name\":\"cost\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setAuthorizedTrigger\",\"inputs\":[{\"name\":\"trigger\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setChallengeGameDuration\",\"inputs\":[{\"name\":\"duration\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setEvidenceSubmissionPeriod\",\"inputs\":[{\"name\":\"period\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setL1BridgeRegistry\",\"inputs\":[{\"name\":\"_l1BridgeRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMaxValidatorsPerL2\",\"inputs\":[{\"name\":\"maxValidators\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMinimumThreshold\",\"inputs\":[{\"name\":\"threshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setPaused\",\"inputs\":[{\"name\":\"_paused\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setRatTriggerProbability\",\"inputs\":[{\"name\":\"probability\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setRelaxedValidatorCheck\",\"inputs\":[{\"name\":\"relaxed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSafetyBuffer\",\"inputs\":[{\"name\":\"buffer\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSlashingPenalty\",\"inputs\":[{\"name\":\"penalty\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTreasury\",\"inputs\":[{\"name\":\"_treasury\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setValidatorBuffer\",\"inputs\":[{\"name\":\"buffer\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slashingPenalty\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"submitEvidence\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"evidence\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"treasury\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"triggerAttentionTest\",\"inputs\":[{\"name\":\"gameAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"blockHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"validateSlashingPenalty\",\"inputs\":[{\"name\":\"n\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorBuffer\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorIndexes\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorRegistrations\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"lockedForRAT\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"pendingRewards\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"latestTestDeadline\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"validatorIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"isActive\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorSystemConfigs\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdrawSlashingsToTreasury\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"wton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"AccumulatedSlashingsReset\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AttentionTestTriggered\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"gameAddress\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"indexed\":false,\"internalType\":\"uint32\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BondRestored\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"restoredAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositAdded\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EvidenceSubmitted\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"indexed\":false,\"internalType\":\"uint32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MaxValidatorsPerL2Updated\",\"inputs\":[{\"name\":\"newMaxValidators\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RelaxedValidatorCheckUpdated\",\"inputs\":[{\"name\":\"relaxed\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SlashingsWithdrawn\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"treasury\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorDeactivated\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorReactivated\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"collateral\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRegistered\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"depositAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"registrationId\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRestored\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorSlashed\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"layer2\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"slashedAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"removedFromSet\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false}]"

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
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATCaller) AttentionTests(opts *bind.CallOpts, arg0 [32]byte) (struct {
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
	err := _RAT.contract.Call(opts, &out, "attentionTests", arg0)

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

// AttentionTests is a free data retrieval call binding the contract method 0x319ad327.
//
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATSession) AttentionTests(arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
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
// Solidity: function attentionTests(bytes32 ) view returns(address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)
func (_RAT *RATCallerSession) AttentionTests(arg0 [32]byte) (struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
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

// Initialize is a paid mutator transaction binding the contract method 0xd3394564.
//
// Solidity: function initialize(address _seigManager, address _wton, address _ton, address _layer2Manager, address _owner, uint256 _ratTriggerProbability, uint256 _evidenceSubmissionPeriod, uint256 _slashingPenalty, uint256 _validatorBuffer, uint256 _minimumThreshold, uint256 _maxValidatorsPerL2, uint256 _challengeGameDuration, uint256 _safetyBuffer) returns()
func (_RAT *RATTransactor) Initialize(opts *bind.TransactOpts, _seigManager common.Address, _wton common.Address, _ton common.Address, _layer2Manager common.Address, _owner common.Address, _ratTriggerProbability *big.Int, _evidenceSubmissionPeriod *big.Int, _slashingPenalty *big.Int, _validatorBuffer *big.Int, _minimumThreshold *big.Int, _maxValidatorsPerL2 *big.Int, _challengeGameDuration *big.Int, _safetyBuffer *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "initialize", _seigManager, _wton, _ton, _layer2Manager, _owner, _ratTriggerProbability, _evidenceSubmissionPeriod, _slashingPenalty, _validatorBuffer, _minimumThreshold, _maxValidatorsPerL2, _challengeGameDuration, _safetyBuffer)
}

// Initialize is a paid mutator transaction binding the contract method 0xd3394564.
//
// Solidity: function initialize(address _seigManager, address _wton, address _ton, address _layer2Manager, address _owner, uint256 _ratTriggerProbability, uint256 _evidenceSubmissionPeriod, uint256 _slashingPenalty, uint256 _validatorBuffer, uint256 _minimumThreshold, uint256 _maxValidatorsPerL2, uint256 _challengeGameDuration, uint256 _safetyBuffer) returns()
func (_RAT *RATSession) Initialize(_seigManager common.Address, _wton common.Address, _ton common.Address, _layer2Manager common.Address, _owner common.Address, _ratTriggerProbability *big.Int, _evidenceSubmissionPeriod *big.Int, _slashingPenalty *big.Int, _validatorBuffer *big.Int, _minimumThreshold *big.Int, _maxValidatorsPerL2 *big.Int, _challengeGameDuration *big.Int, _safetyBuffer *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.Initialize(&_RAT.TransactOpts, _seigManager, _wton, _ton, _layer2Manager, _owner, _ratTriggerProbability, _evidenceSubmissionPeriod, _slashingPenalty, _validatorBuffer, _minimumThreshold, _maxValidatorsPerL2, _challengeGameDuration, _safetyBuffer)
}

// Initialize is a paid mutator transaction binding the contract method 0xd3394564.
//
// Solidity: function initialize(address _seigManager, address _wton, address _ton, address _layer2Manager, address _owner, uint256 _ratTriggerProbability, uint256 _evidenceSubmissionPeriod, uint256 _slashingPenalty, uint256 _validatorBuffer, uint256 _minimumThreshold, uint256 _maxValidatorsPerL2, uint256 _challengeGameDuration, uint256 _safetyBuffer) returns()
func (_RAT *RATTransactorSession) Initialize(_seigManager common.Address, _wton common.Address, _ton common.Address, _layer2Manager common.Address, _owner common.Address, _ratTriggerProbability *big.Int, _evidenceSubmissionPeriod *big.Int, _slashingPenalty *big.Int, _validatorBuffer *big.Int, _minimumThreshold *big.Int, _maxValidatorsPerL2 *big.Int, _challengeGameDuration *big.Int, _safetyBuffer *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.Initialize(&_RAT.TransactOpts, _seigManager, _wton, _ton, _layer2Manager, _owner, _ratTriggerProbability, _evidenceSubmissionPeriod, _slashingPenalty, _validatorBuffer, _minimumThreshold, _maxValidatorsPerL2, _challengeGameDuration, _safetyBuffer)
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

// RegisterValidatorV2Compat is a paid mutator transaction binding the contract method 0x6ff2189a.
//
// Solidity: function registerValidatorV2Compat(address systemConfig, uint256 depositAmount) returns()
func (_RAT *RATTransactor) RegisterValidatorV2Compat(opts *bind.TransactOpts, systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "registerValidatorV2Compat", systemConfig, depositAmount)
}

// RegisterValidatorV2Compat is a paid mutator transaction binding the contract method 0x6ff2189a.
//
// Solidity: function registerValidatorV2Compat(address systemConfig, uint256 depositAmount) returns()
func (_RAT *RATSession) RegisterValidatorV2Compat(systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.RegisterValidatorV2Compat(&_RAT.TransactOpts, systemConfig, depositAmount)
}

// RegisterValidatorV2Compat is a paid mutator transaction binding the contract method 0x6ff2189a.
//
// Solidity: function registerValidatorV2Compat(address systemConfig, uint256 depositAmount) returns()
func (_RAT *RATTransactorSession) RegisterValidatorV2Compat(systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.RegisterValidatorV2Compat(&_RAT.TransactOpts, systemConfig, depositAmount)
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
