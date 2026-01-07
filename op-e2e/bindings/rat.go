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
const RATABI = "[{\"type\":\"function\",\"name\":\"accumulatedSlashings\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"activeTestCount\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addDeposit\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"attentionCost\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"attentionTests\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"validatorAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"bondAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"authorizedTrigger\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"batchToTestId\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deactivateValidator\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"emergencyWithdraw\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"evidenceSubmissionPeriod\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"factoryByGame\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"gameToTestId\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getActiveValidatorCount\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAttentionTest\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"validatorAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"bondAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumRATStorage.AttentionTestStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getL2Validators\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinimumCollateral\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorCount\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorDeposit\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorRegistration\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"depositedAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalBondForRAT\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validatorIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"isActive\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"_seigManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_wton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_ton\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_layer2Manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_ratTriggerProbability\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isValidatorActive\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"l1BridgeRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"layer2Manager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxValidatorsPerL2\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minimumThreshold\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"onApprove\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ratTriggerProbability\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"registerValidator\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"depositAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resolveClaim\",\"inputs\":[{\"name\":\"_claimant\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"seigManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setAttentionCost\",\"inputs\":[{\"name\":\"cost\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setAuthorizedTrigger\",\"inputs\":[{\"name\":\"trigger\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setEvidenceSubmissionPeriod\",\"inputs\":[{\"name\":\"period\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setL1BridgeRegistry\",\"inputs\":[{\"name\":\"_l1BridgeRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMaxValidatorsPerL2\",\"inputs\":[{\"name\":\"maxValidators\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMinimumThreshold\",\"inputs\":[{\"name\":\"threshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setPaused\",\"inputs\":[{\"name\":\"_paused\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setRatTriggerProbability\",\"inputs\":[{\"name\":\"probability\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSlashingPenalty\",\"inputs\":[{\"name\":\"penalty\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTreasury\",\"inputs\":[{\"name\":\"_treasury\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setValidatorBuffer\",\"inputs\":[{\"name\":\"buffer\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slashingPenalty\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"submitEvidence\",\"inputs\":[{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"evidence\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"treasury\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"triggerAttentionTest\",\"inputs\":[{\"name\":\"gameAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"batchHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"blockHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"validateSlashingPenalty\",\"inputs\":[{\"name\":\"n\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorBuffer\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorIndexes\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorRegistrations\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"depositedAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalBondForRAT\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"pendingRewards\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"latestTestDeadline\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"validatorIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"isActive\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatorSystemConfigs\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdrawSlashingsToTreasury\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"wton\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"AttentionTestTriggered\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"gameAddress\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"indexed\":false,\"internalType\":\"uint32\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BondRestored\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"restoredAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositAdded\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EvidenceSubmitted\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"batchIndex\",\"type\":\"uint32\",\"indexed\":false,\"internalType\":\"uint32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MaxValidatorsPerL2Updated\",\"inputs\":[{\"name\":\"newMaxValidators\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorDeactivated\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"returnedAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRegistered\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"depositAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"registrationId\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRestored\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorSlashed\",\"inputs\":[{\"name\":\"testId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"systemConfig\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"slashedAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"removedFromSet\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false}]"

// RATBin is the compiled bytecode used for deploying new contracts.
var RATBin = "0x608080604052346100165761264e908161001c8239f35b600080fdfe60806040908082526004908136101561001757600080fd5b600092833560e01c9182624fe2b414611679575081630322587914611627578163068c2e6e146115795781630bec56911461152a5781630c1da8df146114e2578163116c4fcc1461146d57816316b5d5bd1461144457816316c38b3c146113f15781632c9e3798146113d25781632d6f496914611397578163319ad32714610f5057816333026bb61461128d57816336c63d461461125e578163370e9e181461121657816339b62bd1146111cf5781634273ca16146110975781634a859247146110075781634e4a9a1b14610fbe5781634eecc64514610f5057816351567bc214610f315781635c975abb14610f0a57816361d027b314610ee15781636259243314610ea657816367058d2914610e775781636ad83f9114610e485781636fb7f55814610e1f57816375da30d014610e0057816389f1ea6414610de15781638d62d94914610db85781638da5cb5b14610d8f5781638dc3b28e14610d3657816394d645a814610d1457816395b6ef0c14610b9f57816395ccea6714610b5a5781639abee7d014610aaa578163a0bfe1c614610a4e578163acccb08f14610a2f578163ba50b8791461087c578163c0a08bde1461084d578163cc48b94714610824578163cd15681914610805578163cdf7cf13146107cd578163cf8f9110146107a4578163cfa424ea14610785578163d0d6b9b51461075b578163d2e5bc7214610707578163d8c0ba59146106dc578163ddef8e85146106a4578163e1705cb61461067b578163e54f62371461045d578163f0f4426014610412578163f2fde38b1461038a578163f7107b441461036b578163f92879db146102f6578163f9560e45146102be575063f983386b1461028d57600080fd5b346102ba5760203660031901126102ba576102b360018060a01b036014541633146125e0565b3560095580f35b5080fd5b8390346102ba5760203660031901126102ba5760209181906001600160a01b036102e661177f565b1681526001845220549051908152f35b8390346102ba57806003193601126102ba5760ff8160809361031661177f565b6001600160a01b038061032761179a565b16835282602052838320911682526020522080549260036001830154920154918151948552602085015263ffffffff82821c169084015260601c1615156060820152f35b8390346102ba57816003193601126102ba57602090600a549051908152f35b9190503461040e57602036600319011261040e576103a661177f565b60145491906001600160a01b03906103c133838616146125e0565b169283156103dc5750506001600160a01b0319161760145580f35b906020606492519162461bcd60e51b8352820152600c60248201526b7a65726f206164647265737360a01b6044820152fd5b8280fd5b833461045a57602036600319011261045a5761042c61177f565b6014546001600160a01b03919061044690831633146125e0565b1660018060a01b0319601654161760165580f35b80fd5b9190503461040e57606036600319011261040e5761047961177f565b906104826117b0565b906044356001600160401b038111610677576104a19036908301611828565b5050601654936104b760ff8660a01c1615611966565b60ff60a01b19948516600160a01b1760168190556104db9060a81c60ff161561199b565b60018060a01b0390818516948588526020926005845263ffffffff838a20961695868a5284528289205494851561066957858a52808552838a2091825416330361065b57600682019060ff825416818110156106485761063a576005830154421161062c5750907fbf3ee2cdebc8d0e701d8f6bbed66db69a46f2cdeda4b1bf0eee3dab7b99114c994939291888b528a8552838b20338c5285526003848c209201610588815484546118ac565b83555461059a60018401918254611c4f565b9055600160ff19825416179055878a5260068452828a206105bb8154611c42565b905560ff600382015460601c16158061061f575b6105e7575b5050519384523393a46016541660165580f35b6105f2913390612563565b85337facf682cec5d019e69bf9a11a0ee8d582373446ed7815c383edf30b5b400566998a80a338806105d4565b508054600c5411156105cf565b845163022e778360e61b8152fd5b8451634136d4f760e01b8152fd5b634e487b7160e01b8c526021825260248cfd5b835163911feff760e01b8152fd5b835163dc87ad5960e01b8152fd5b8580fd5b8390346102ba57816003193601126102ba5760135490516001600160a01b039091168152602090f35b8390346102ba5760203660031901126102ba5760209181906001600160a01b036106cc61177f565b1681526007845220549051908152f35b8390346102ba57816003193601126102ba57602090610700600954600a54906118ac565b9051908152f35b9190503461040e57602036600319011261040e5780359161073360018060a01b036014541633146125e0565b6b033b2e3c9fd0803ce8000000831161074e575050600b5580f35b5163818a07b160e01b8152fd5b9050823461045a57602036600319011261045a575061077c602092356118b9565b90519015158152f35b8390346102ba57816003193601126102ba57602090600d549051908152f35b8390346102ba57816003193601126102ba5760175490516001600160a01b039091168152602090f35b8390346102ba5760203660031901126102ba5760209181906001600160a01b036107f561177f565b1681526006845220549051908152f35b8390346102ba57816003193601126102ba576020906015549051908152f35b8390346102ba57816003193601126102ba5760115490516001600160a01b039091168152602090f35b5050346102ba5760203660031901126102ba5761087560018060a01b036014541633146125e0565b3560085580f35b9190503461040e5760209081600319360112610a2b5761089a61177f565b91601654936108af60ff8660a01c1615611966565b60ff60a01b19948516600160a01b176016556001600160a01b039384168087528683528187203388528352818720600381018054929691959192909190606081901c60ff1615610a1c576001600160401b031642106109e55750907fffcfa539e16382bc2fe8c1cd58e64186127bdc0dc70c50e2ba88beac80f1059a93929188600187018054806109cd575b50505060ff60601b19815416905585885260018352818820600181016109618154611c42565b9055610974600287549201918254611c4f565b90556002855495898155866109b9575b018881549155806109a3575b5050519283523392a36016541660165580f35b6109b291339060105416611c5c565b3880610990565b6109c887338560115416611c5c565b610984565b6109d9906015546118ac565b6015555588388061093b565b835162461bcd60e51b8152908101859052601160248201527070656e64696e672052415420746573747360781b6044820152606490fd5b508351634385fe5160e11b8152fd5b8380fd5b8390346102ba57816003193601126102ba57602090600e549051908152f35b9190503461040e57602036600319011261040e577fa03f0d48c0ef0e0b6916f6c0f9e415d7319a1ea4a09ca66e68f473939ee2b10c916020913590610a9e60018060a01b036014541633146125e0565b81600d5551908152a180f35b90503461040e578060031936011261040e57610ac461177f565b6024359160165493610adc60ff8660a01c1615611966565b60ff60a01b19948516600160a01b176016819055610b009060a81c60ff161561199b565b6001600160a01b039183831615610b4d578415610b4057505090610b3083610b36949360115416309033906119d0565b33611ce4565b6016541660165580f35b51636e0ccc0760e01b8152fd5b5163e867588d60e01b8152fd5b8390346102ba5736600319011261045a57610b9c610b7661177f565b6014546001600160a01b039190610b9090831633146125e0565b60243591339116611c5c565b80f35b90503461040e5760c036600319011261040e57610bba61177f565b90610bc361179a565b6001600160a01b0391906044358381169190829003610d105760643592848416809403610d0c5760843595858716809703610d085760a43597600f5492878416610ccf5789151580610cb9575b15610c805750509085929160018060a01b031996879116911617600f55168360105416176010558260115416176011558160125416176012556014541617601455600b55610e10600e5568056bc75e2d6310000080600955600a55683635c9adc5dea00000600c556064600d5580f35b906020606492519162461bcd60e51b83528201526013602482015272696e76616c69642070726f626162696c69747960681b6044820152fd5b506b033b2e3c9fd0803ce80000008a1115610c10565b906020606492519162461bcd60e51b83528201526013602482015272185b1c9958591e481a5b9a5d1a585b1a5e9959606a1b6044820152fd5b8880fd5b8780fd5b8680fd5b833461045a57602036600319011261045a57610b9c610d3161177f565b6122e6565b8390346102ba57806003193601126102ba57610d5061177f565b6001600160a01b03908116835260036020528183208054602435949085101561045a5750602093610d8091611855565b90549060031b1c169051908152f35b8390346102ba57816003193601126102ba5760145490516001600160a01b039091168152602090f35b8390346102ba57816003193601126102ba5760105490516001600160a01b039091168152602090f35b8390346102ba57816003193601126102ba576020906009549051908152f35b8390346102ba57816003193601126102ba57602090600c549051908152f35b8390346102ba57816003193601126102ba57600f5490516001600160a01b039091168152602090f35b5050346102ba5760203660031901126102ba57610e7060018060a01b036014541633146125e0565b35600a5580f35b5050346102ba5760203660031901126102ba57610e9f60018060a01b036014541633146125e0565b35600c5580f35b8390346102ba5760203660031901126102ba576020916001600160a01b0390829082610ed061177f565b168152601885522054169051908152f35b8390346102ba57816003193601126102ba5760165490516001600160a01b039091168152602090f35b8390346102ba57816003193601126102ba5760209060ff60165460a81c1690519015158152f35b8390346102ba57816003193601126102ba57602090600b549051908152f35b9050823461045a57602036600319011261045a5781610fba918435815284602052209160018060a01b0392838154169460018201549060028301546003840154918401549260ff6006600587015496015416955198899863ffffffff8360a01c16921690896117c3565b0390f35b8390346102ba57806003193601126102ba5780602092610fdc61177f565b610fe461179a565b6001600160a01b0391821683526002865283832091168252845220549051908152f35b8390346102ba57806003193601126102ba5760ff8160c09361102761177f565b61102f61179a565b9060018060a01b03809116835282602052838320911682526020522063ffffffff8154936001830154906003600285015494015493849282519788526020880152818701526001600160401b03821660608701521c16608084015260601c16151560a0820152f35b9050823461045a57608036600319011261045a576110b361177f565b926110bc61179a565b506064356001600160401b03811161040e576110db9036908301611828565b90601654936110f060ff8660a01c1615611966565b60ff60a01b19948516600160a01b1760168190556111149060a81c60ff161561199b565b6011546001600160a01b039390841633036111a1576020811061116f5760201161045a5750351690811561116157506020936111539160443591611ce4565b601654166016555160018152f35b835163e867588d60e01b8152fd5b865162461bcd60e51b8152602081870152600c60248201526b696e76616c6964206461746160a01b6044820152606490fd5b865162461bcd60e51b8152602081870152600860248201526737b7363c902a27a760c11b6044820152606490fd5b8390346102ba57806003193601126102ba57806020926111ed61177f565b6001600160a01b03806111fe61179a565b16835282865283832091168252845220549051908152f35b833461045a57602036600319011261045a5761123061177f565b6014546001600160a01b03919061124a90831633146125e0565b1660018060a01b0319601354161760135580f35b5050346102ba5760203660031901126102ba5761128660018060a01b036014541633146125e0565b35600e5580f35b90503461040e578060031936011261040e576112a761177f565b9060243590601654936112c060ff8660a01c1615611966565b60ff60a01b19948516600160a01b176016556001600160a01b0393841680875260208781528388203389529052828720600381015491959092909160601c60ff161561138957841561137b57508361131f9160115416309033906119d0565b61132a8382546118ac565b905582855260016020526002818620016113458382546118ac565b9055519081527f63d8d7d5e63e9840ec91a12a160d27b7cfab294f6ba070b7359692acfe6b03bf60203392a36016541660165580f35b8351636e0ccc0760e01b8152fd5b8351634385fe5160e11b8152fd5b8390346102ba5760203660031901126102ba5760209160019082906001600160a01b036113c261177f565b1681528285522001549051908152f35b8390346102ba57816003193601126102ba576020906008549051908152f35b5050346102ba5760203660031901126102ba57358015158091036102ba5761142460018060a01b036014541633146125e0565b6016805460ff60a81b191660a89290921b60ff60a81b1691909117905580f35b8390346102ba57816003193601126102ba5760125490516001600160a01b039091168152602090f35b8383346102ba57816003193601126102ba576016546001600160a01b03919082169081156114ac575090610b9c91601554918460155560115416611c5c565b606490602086519162461bcd60e51b8352820152601060248201526f1d1c99585cdd5c9e481b9bdd081cd95d60821b6044820152fd5b833461045a57602036600319011261045a576114fc61177f565b6014546001600160a01b03919061151690831633146125e0565b1660018060a01b0319601754161760175580f35b8390346102ba57806003193601126102ba578060209261154861177f565b6115506117b0565b6001600160a01b0390911682526005855282822063ffffffff9091168252845220549051908152f35b8390346102ba576020918260031936011261045a576001600160a01b0390816115a061177f565b16815260019182855283822094845191828288549182815201908198865283862090865b81811061161257505050836115da910384611945565b855195828701938388525180945286019693905b8382106115fb5786880387f35b8451811688529682019693820193908501906115ee565b825485168452928501929188019188016115c4565b8390346102ba57806003193601126102ba5760ff60038260209461164961177f565b6001600160a01b038061165a61179a565b16835282885283832091168252865220015460601c1690519015158152f35b8492503461040e5760a036600319011261040e5761169561177f565b9061169e61179a565b926044359163ffffffff83168303610677576017546001600160a01b03919082169081156117715750602060249184519283809263ebbbfdb560e01b8252338d8301525afa90811561176757879161172d575b50161561171e5750610b9c93945061171160ff60165460a81c161561199b565b6084359260643592611ed4565b51633785806960e11b81528590fd5b90506020813d821161175f575b8161174760209383611945565b81010312610d1057518181168103610d1057886116f1565b3d915061173a565b83513d89823e3d90fd5b633785806960e11b81528890fd5b600435906001600160a01b038216820361179557565b600080fd5b602435906001600160a01b038216820361179557565b6024359063ffffffff8216820361179557565b959391989796949263ffffffff9161010088019a60018060a01b0380921689521660208801521660408601526060850152608084015260a083015260c082015260048210156118125760e00152565b634e487b7160e01b600052602160045260246000fd5b9181601f84011215611795578235916001600160401b038311611795576020838186019501011161179557565b805482101561186d5760005260206000200190600090565b634e487b7160e01b600052603260045260246000fd5b8181029291811591840414171561189657565b634e487b7160e01b600052601160045260246000fd5b9190820180921161189657565b600b548015801561190c575b611905576118d86118e191600954611883565b91600854611883565b906b033b2e3c9fd0803ce80000009182810292818404149015171561189657101590565b5050600090565b5081156118c5565b608081019081106001600160401b0382111761192f57604052565b634e487b7160e01b600052604160045260246000fd5b90601f801991011681019081106001600160401b0382111761192f57604052565b1561196d57565b60405162461bcd60e51b81526020600482015260066024820152651b1bd8dad95960d21b6044820152606490fd5b156119a257565b60405162461bcd60e51b81526020600482015260066024820152651c185d5cd95960d21b6044820152606490fd5b6040516323b872dd60e01b60208201526001600160a01b03928316602482015292909116604483015260648083019390935291815260a08101918183106001600160401b0384111761192f57611a2892604052611a2a565b565b60018060a01b031690604051604081016001600160401b03908281108282111761192f576040526020938483527f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c6564858401526000808587829751910182855af1903d15611b63573d928311611b4f5790611ac493929160405192611ab788601f19601f8401160185611945565b83523d868885013e611b6e565b805180611ad2575b50505050565b818491810103126102ba578201519081159182150361045a5750611af857808080611acc565b6084906040519062461bcd60e51b82526004820152602a60248201527f5361666545524332303a204552433230206f7065726174696f6e20646964206e6044820152691bdd081cdd58d8d9595960b21b6064820152fd5b634e487b7160e01b85526041600452602485fd5b90611ac49392506060915b91929015611bd05750815115611b82575090565b3b15611b8b5790565b60405162461bcd60e51b815260206004820152601d60248201527f416464726573733a2063616c6c20746f206e6f6e2d636f6e74726163740000006044820152606490fd5b825190915015611be35750805190602001fd5b6040519062461bcd60e51b82528160208060048301528251908160248401526000935b828510611c29575050604492506000838284010152601f80199101168101030190fd5b8481018201518686016044015293810193859350611c06565b8015611896576000190190565b9190820391821161189657565b60405163a9059cbb60e01b60208201526001600160a01b039092166024830152604480830193909352918152611a2891611c9582611914565b611a2a565b8054600160401b81101561192f57611cb791600182018155611855565b819291549060031b9160018060a01b03809116831b921b1916179055565b60001981146118965760010190565b90929160018060a01b03908185169260008481526020908082526040938482209584169586835283528482209860038a019260ff845460601c16611ec357611d31600954600a54906118ac565b95611d3e8c5494856118ac565b968710611eb257898252600186528782209315611dc85750505090837fc15d937eb6e674346338dc7e284a3337f4c01fe4c05be6f30e06f054fc5aecfe96979899600284600163ffffffff9601611d958154611cd5565b905501611da38382546118ac565b905555805460ff60601b1916600160601b1781555b54841c16908351928352820152a3565b919a9092805492600d548015159081611ea7575b50611e965793611e91938160027fc15d937eb6e674346338dc7e284a3337f4c01fe4c05be6f30e06f054fc5aecfe9c9d9e9f958186611e238f989b63ffffffff9d9c611c9a565b60018101611e318154611cd5565b905501611e3f8d82546118ac565b90558b81556001810183905501558554600160601b64ffffffffff60401b1990911663ffffffff60401b89841660401b16171786558c8252600288528282208c83528852828220556003875220611c9a565b611db8565b885163ad8f042960e01b8152600490fd5b905084101538611ddc565b87516369cf0eaf60e01b8152600490fd5b865163173f3ea160e21b8152600490fd5b6001600160a01b03808216600090815260186020908152604080832080546001600160a01b03191633179055928516825260019081905291902001549294909392156122cd576005602052604060002063ffffffff86166000526020526040600020546122d457611f459082612470565b936001600160a01b038516156122cd576001600160a01b0382811660009081526020818152604080832093891683529290522060038101549490606086901c60ff16156122c4576009549581548781106122bc575b87611fa491611c4f565b9384835560018301611fb78982546118ac565b905560405160208101906bffffffffffffffffffffffff19808960601b16835263ffffffff60e01b8460e01b1660348301528b60601b16603882015242604c820152604c815261200681611914565b51902096612016600e54426118ac565b936001600160401b03938486169085811682116122a4575b5050600096600c541161224e575b506040519283610100810110906101008501111761192f57610100830160405260018060a01b038a16835260018060a01b038716602084015263ffffffff8216604084015260608301528760808301524260a08301528260c0830152600060e083015286600052600460205260e06006604060002060018060a01b0385511660018060a01b03198254161781556001810160018060a01b0360208701511681549063ffffffff60a01b604089015160a01b16916001600160401b0360c01b1617179055606085015160028201556080850151600382015560a0850151600482015560c08501516005820155019201519160048310156118125763ffffffff9260ff8019835416911617905560018060a01b038616600052600560205260406000208282166000526020528660406000205560018060a01b0386166000526006602052604060002061218d8154611cd5565b905560018060a01b0384166000526007602052866040600020556040519360018060a01b03168452166020830152604082015260018060a01b03831690847fcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38606060018060a01b038a1693a46122035750505050565b60408051938452600160208501526001600160a01b0391821694909116927fb0568c5aad28a0ca5cd06a651d52c0017dfc3af0941a4cb05a6bce87aef1bfe89190a438808080611acc565b90955060ff60601b19600382015416600382015560018060a01b038716600052600160205261229960026040600020926001840161228c8154611c42565b9055549201918254611c4f565b90556001943861203c565b67ffffffffffffffff1916176003820155388061202e565b965086611f9a565b50505050505050565b5050505050565b6040516303e3427560e01b8152600490fd5b6000903382526020916018835260018060a01b0390604093828583205416156122cd576007815284822054928315612468578383526004825285832090808254169581811680970361245e57600683019485549560ff8716600481101561244a5761243e5760017f8b828ea68e5478964e1ee2efd72993bba0df811816b25542cd3e02acb778f24b9760ff19161790556001840191838354168252600686528982206123928154611c42565b9055838354168252818652898220898352865260038a8320950154946123b98682546118ac565b808255600182016123cb888254611c4f565b905560ff600383015460601c16159081612431575b506123f3575b50505054169551908152a4565b6124009185855416612563565b877facf682cec5d019e69bf9a11a0ee8d582373446ed7815c383edf30b5b40056699848454169280a33880806123e6565b9050600c541115386123e0565b50505050505050505050565b634e487b7160e01b83526021600452602483fd5b5050505050505050565b505050505050565b9060018060a01b0380921690600092828452602060018152604092838620906001820154801561255957855191848301908152428784015260609244848201528381526124bc81611914565b51902006908254958897895b8881106124dc575050505050505050505090565b818b528a8752828b2060ff8c856124f3858b611855565b9054600391821b1c8d168352938b529020820154861c1661251e575b5061251990611cd5565b6124c8565b858b929b1461253b575061253461251991611cd5565b999061250f565b99979a50505050505090506125509250611855565b9054911b1c1690565b5050505050505090565b916125db611a28936003830190600160601b60ff60601b1983541617825560018060a01b03166000526001602052604060002092600184016125a58154611cd5565b9055546125b7600285019182546118ac565b90558254815463ffffffff60401b191660409190911b63ffffffff60401b16179055565b611c9a565b156125e757565b60405162461bcd60e51b81526020600482015260096024820152683737ba1037bbb732b960b91b6044820152606490fdfea2646970667358221220ff0ef92cb8ff9815282461110e37155a5a353991b3266e3da5d869270abb9cc964736f6c63430008130033"

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

// GetValidatorRegistration is a free data retrieval call binding the contract method 0xf92879db.
//
// Solidity: function getValidatorRegistration(address validator, address systemConfig) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint32 validatorIndex, bool isActive)
func (_RAT *RATCaller) GetValidatorRegistration(opts *bind.CallOpts, validator common.Address, systemConfig common.Address) (struct {
	DepositedAmount *big.Int
	TotalBondForRAT *big.Int
	ValidatorIndex  uint32
	IsActive        bool
}, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "getValidatorRegistration", validator, systemConfig)

	outstruct := new(struct {
		DepositedAmount *big.Int
		TotalBondForRAT *big.Int
		ValidatorIndex  uint32
		IsActive        bool
	})

	outstruct.DepositedAmount = out[0].(*big.Int)
	outstruct.TotalBondForRAT = out[1].(*big.Int)
	outstruct.ValidatorIndex = out[2].(uint32)
	outstruct.IsActive = out[3].(bool)

	return *outstruct, err

}

// GetValidatorRegistration is a free data retrieval call binding the contract method 0xf92879db.
//
// Solidity: function getValidatorRegistration(address validator, address systemConfig) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint32 validatorIndex, bool isActive)
func (_RAT *RATSession) GetValidatorRegistration(validator common.Address, systemConfig common.Address) (struct {
	DepositedAmount *big.Int
	TotalBondForRAT *big.Int
	ValidatorIndex  uint32
	IsActive        bool
}, error) {
	return _RAT.Contract.GetValidatorRegistration(&_RAT.CallOpts, validator, systemConfig)
}

// GetValidatorRegistration is a free data retrieval call binding the contract method 0xf92879db.
//
// Solidity: function getValidatorRegistration(address validator, address systemConfig) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint32 validatorIndex, bool isActive)
func (_RAT *RATCallerSession) GetValidatorRegistration(validator common.Address, systemConfig common.Address) (struct {
	DepositedAmount *big.Int
	TotalBondForRAT *big.Int
	ValidatorIndex  uint32
	IsActive        bool
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
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive)
func (_RAT *RATCaller) ValidatorRegistrations(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address) (struct {
	DepositedAmount    *big.Int
	TotalBondForRAT    *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
}, error) {
	var out []interface{}
	err := _RAT.contract.Call(opts, &out, "validatorRegistrations", arg0, arg1)

	outstruct := new(struct {
		DepositedAmount    *big.Int
		TotalBondForRAT    *big.Int
		PendingRewards     *big.Int
		LatestTestDeadline uint64
		ValidatorIndex     uint32
		IsActive           bool
	})

	outstruct.DepositedAmount = out[0].(*big.Int)
	outstruct.TotalBondForRAT = out[1].(*big.Int)
	outstruct.PendingRewards = out[2].(*big.Int)
	outstruct.LatestTestDeadline = out[3].(uint64)
	outstruct.ValidatorIndex = out[4].(uint32)
	outstruct.IsActive = out[5].(bool)

	return *outstruct, err

}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive)
func (_RAT *RATSession) ValidatorRegistrations(arg0 common.Address, arg1 common.Address) (struct {
	DepositedAmount    *big.Int
	TotalBondForRAT    *big.Int
	PendingRewards     *big.Int
	LatestTestDeadline uint64
	ValidatorIndex     uint32
	IsActive           bool
}, error) {
	return _RAT.Contract.ValidatorRegistrations(&_RAT.CallOpts, arg0, arg1)
}

// ValidatorRegistrations is a free data retrieval call binding the contract method 0x4a859247.
//
// Solidity: function validatorRegistrations(address , address ) view returns(uint256 depositedAmount, uint256 totalBondForRAT, uint256 pendingRewards, uint64 latestTestDeadline, uint32 validatorIndex, bool isActive)
func (_RAT *RATCallerSession) ValidatorRegistrations(arg0 common.Address, arg1 common.Address) (struct {
	DepositedAmount    *big.Int
	TotalBondForRAT    *big.Int
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

// AddDeposit is a paid mutator transaction binding the contract method 0x33026bb6.
//
// Solidity: function addDeposit(address systemConfig, uint256 amount) returns()
func (_RAT *RATTransactor) AddDeposit(opts *bind.TransactOpts, systemConfig common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "addDeposit", systemConfig, amount)
}

// AddDeposit is a paid mutator transaction binding the contract method 0x33026bb6.
//
// Solidity: function addDeposit(address systemConfig, uint256 amount) returns()
func (_RAT *RATSession) AddDeposit(systemConfig common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.AddDeposit(&_RAT.TransactOpts, systemConfig, amount)
}

// AddDeposit is a paid mutator transaction binding the contract method 0x33026bb6.
//
// Solidity: function addDeposit(address systemConfig, uint256 amount) returns()
func (_RAT *RATTransactorSession) AddDeposit(systemConfig common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.AddDeposit(&_RAT.TransactOpts, systemConfig, amount)
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

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address token, uint256 amount) returns()
func (_RAT *RATTransactor) EmergencyWithdraw(opts *bind.TransactOpts, token common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "emergencyWithdraw", token, amount)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address token, uint256 amount) returns()
func (_RAT *RATSession) EmergencyWithdraw(token common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.EmergencyWithdraw(&_RAT.TransactOpts, token, amount)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address token, uint256 amount) returns()
func (_RAT *RATTransactorSession) EmergencyWithdraw(token common.Address, amount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.EmergencyWithdraw(&_RAT.TransactOpts, token, amount)
}

// Initialize is a paid mutator transaction binding the contract method 0x95b6ef0c.
//
// Solidity: function initialize(address _seigManager, address _wton, address _ton, address _layer2Manager, address _owner, uint256 _ratTriggerProbability) returns()
func (_RAT *RATTransactor) Initialize(opts *bind.TransactOpts, _seigManager common.Address, _wton common.Address, _ton common.Address, _layer2Manager common.Address, _owner common.Address, _ratTriggerProbability *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "initialize", _seigManager, _wton, _ton, _layer2Manager, _owner, _ratTriggerProbability)
}

// Initialize is a paid mutator transaction binding the contract method 0x95b6ef0c.
//
// Solidity: function initialize(address _seigManager, address _wton, address _ton, address _layer2Manager, address _owner, uint256 _ratTriggerProbability) returns()
func (_RAT *RATSession) Initialize(_seigManager common.Address, _wton common.Address, _ton common.Address, _layer2Manager common.Address, _owner common.Address, _ratTriggerProbability *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.Initialize(&_RAT.TransactOpts, _seigManager, _wton, _ton, _layer2Manager, _owner, _ratTriggerProbability)
}

// Initialize is a paid mutator transaction binding the contract method 0x95b6ef0c.
//
// Solidity: function initialize(address _seigManager, address _wton, address _ton, address _layer2Manager, address _owner, uint256 _ratTriggerProbability) returns()
func (_RAT *RATTransactorSession) Initialize(_seigManager common.Address, _wton common.Address, _ton common.Address, _layer2Manager common.Address, _owner common.Address, _ratTriggerProbability *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.Initialize(&_RAT.TransactOpts, _seigManager, _wton, _ton, _layer2Manager, _owner, _ratTriggerProbability)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_RAT *RATTransactor) OnApprove(opts *bind.TransactOpts, owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "onApprove", owner, spender, amount, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_RAT *RATSession) OnApprove(owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _RAT.Contract.OnApprove(&_RAT.TransactOpts, owner, spender, amount, data)
}

// OnApprove is a paid mutator transaction binding the contract method 0x4273ca16.
//
// Solidity: function onApprove(address owner, address spender, uint256 amount, bytes data) returns(bool)
func (_RAT *RATTransactorSession) OnApprove(owner common.Address, spender common.Address, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _RAT.Contract.OnApprove(&_RAT.TransactOpts, owner, spender, amount, data)
}

// RegisterValidator is a paid mutator transaction binding the contract method 0x9abee7d0.
//
// Solidity: function registerValidator(address systemConfig, uint256 depositAmount) returns()
func (_RAT *RATTransactor) RegisterValidator(opts *bind.TransactOpts, systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "registerValidator", systemConfig, depositAmount)
}

// RegisterValidator is a paid mutator transaction binding the contract method 0x9abee7d0.
//
// Solidity: function registerValidator(address systemConfig, uint256 depositAmount) returns()
func (_RAT *RATSession) RegisterValidator(systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.RegisterValidator(&_RAT.TransactOpts, systemConfig, depositAmount)
}

// RegisterValidator is a paid mutator transaction binding the contract method 0x9abee7d0.
//
// Solidity: function registerValidator(address systemConfig, uint256 depositAmount) returns()
func (_RAT *RATTransactorSession) RegisterValidator(systemConfig common.Address, depositAmount *big.Int) (*types.Transaction, error) {
	return _RAT.Contract.RegisterValidator(&_RAT.TransactOpts, systemConfig, depositAmount)
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

// WithdrawSlashingsToTreasury is a paid mutator transaction binding the contract method 0x116c4fcc.
//
// Solidity: function withdrawSlashingsToTreasury() returns()
func (_RAT *RATTransactor) WithdrawSlashingsToTreasury(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RAT.contract.Transact(opts, "withdrawSlashingsToTreasury")
}

// WithdrawSlashingsToTreasury is a paid mutator transaction binding the contract method 0x116c4fcc.
//
// Solidity: function withdrawSlashingsToTreasury() returns()
func (_RAT *RATSession) WithdrawSlashingsToTreasury() (*types.Transaction, error) {
	return _RAT.Contract.WithdrawSlashingsToTreasury(&_RAT.TransactOpts)
}

// WithdrawSlashingsToTreasury is a paid mutator transaction binding the contract method 0x116c4fcc.
//
// Solidity: function withdrawSlashingsToTreasury() returns()
func (_RAT *RATTransactorSession) WithdrawSlashingsToTreasury() (*types.Transaction, error) {
	return _RAT.Contract.WithdrawSlashingsToTreasury(&_RAT.TransactOpts)
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
	RestoredAmount *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterBondRestored is a free log retrieval operation binding the contract event 0x8b828ea68e5478964e1ee2efd72993bba0df811816b25542cd3e02acb778f24b.
//
// Solidity: event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 restoredAmount)
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

// WatchBondRestored is a free log subscription operation binding the contract event 0x8b828ea68e5478964e1ee2efd72993bba0df811816b25542cd3e02acb778f24b.
//
// Solidity: event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 restoredAmount)
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

// ParseBondRestored is a log parse operation binding the contract event 0x8b828ea68e5478964e1ee2efd72993bba0df811816b25542cd3e02acb778f24b.
//
// Solidity: event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 restoredAmount)
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
	BatchIndex   uint32
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterEvidenceSubmitted is a free log retrieval operation binding the contract event 0xbf3ee2cdebc8d0e701d8f6bbed66db69a46f2cdeda4b1bf0eee3dab7b99114c9.
//
// Solidity: event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex)
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

// WatchEvidenceSubmitted is a free log subscription operation binding the contract event 0xbf3ee2cdebc8d0e701d8f6bbed66db69a46f2cdeda4b1bf0eee3dab7b99114c9.
//
// Solidity: event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex)
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

// ParseEvidenceSubmitted is a log parse operation binding the contract event 0xbf3ee2cdebc8d0e701d8f6bbed66db69a46f2cdeda4b1bf0eee3dab7b99114c9.
//
// Solidity: event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex)
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
	Validator      common.Address
	SystemConfig   common.Address
	ReturnedAmount *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterValidatorDeactivated is a free log retrieval operation binding the contract event 0xffcfa539e16382bc2fe8c1cd58e64186127bdc0dc70c50e2ba88beac80f1059a.
//
// Solidity: event ValidatorDeactivated(address indexed validator, address indexed systemConfig, uint256 returnedAmount)
func (_RAT *RATFilterer) FilterValidatorDeactivated(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address) (*RATValidatorDeactivatedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorDeactivated", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorDeactivatedIterator{contract: _RAT.contract, event: "ValidatorDeactivated", logs: logs, sub: sub}, nil
}

// WatchValidatorDeactivated is a free log subscription operation binding the contract event 0xffcfa539e16382bc2fe8c1cd58e64186127bdc0dc70c50e2ba88beac80f1059a.
//
// Solidity: event ValidatorDeactivated(address indexed validator, address indexed systemConfig, uint256 returnedAmount)
func (_RAT *RATFilterer) WatchValidatorDeactivated(opts *bind.WatchOpts, sink chan<- *RATValidatorDeactivated, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorDeactivated", validatorRule, systemConfigRule)
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

// ParseValidatorDeactivated is a log parse operation binding the contract event 0xffcfa539e16382bc2fe8c1cd58e64186127bdc0dc70c50e2ba88beac80f1059a.
//
// Solidity: event ValidatorDeactivated(address indexed validator, address indexed systemConfig, uint256 returnedAmount)
func (_RAT *RATFilterer) ParseValidatorDeactivated(log types.Log) (*RATValidatorDeactivated, error) {
	event := new(RATValidatorDeactivated)
	if err := _RAT.contract.UnpackLog(event, "ValidatorDeactivated", log); err != nil {
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
	DepositAmount  *big.Int
	RegistrationId *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterValidatorRegistered is a free log retrieval operation binding the contract event 0xc15d937eb6e674346338dc7e284a3337f4c01fe4c05be6f30e06f054fc5aecfe.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount, uint256 registrationId)
func (_RAT *RATFilterer) FilterValidatorRegistered(opts *bind.FilterOpts, validator []common.Address, systemConfig []common.Address) (*RATValidatorRegisteredIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.FilterLogs(opts, "ValidatorRegistered", validatorRule, systemConfigRule)
	if err != nil {
		return nil, err
	}
	return &RATValidatorRegisteredIterator{contract: _RAT.contract, event: "ValidatorRegistered", logs: logs, sub: sub}, nil
}

// WatchValidatorRegistered is a free log subscription operation binding the contract event 0xc15d937eb6e674346338dc7e284a3337f4c01fe4c05be6f30e06f054fc5aecfe.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount, uint256 registrationId)
func (_RAT *RATFilterer) WatchValidatorRegistered(opts *bind.WatchOpts, sink chan<- *RATValidatorRegistered, validator []common.Address, systemConfig []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}
	var systemConfigRule []interface{}
	for _, systemConfigItem := range systemConfig {
		systemConfigRule = append(systemConfigRule, systemConfigItem)
	}

	logs, sub, err := _RAT.contract.WatchLogs(opts, "ValidatorRegistered", validatorRule, systemConfigRule)
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

// ParseValidatorRegistered is a log parse operation binding the contract event 0xc15d937eb6e674346338dc7e284a3337f4c01fe4c05be6f30e06f054fc5aecfe.
//
// Solidity: event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount, uint256 registrationId)
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
	SlashedAmount  *big.Int
	RemovedFromSet bool
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterValidatorSlashed is a free log retrieval operation binding the contract event 0xb0568c5aad28a0ca5cd06a651d52c0017dfc3af0941a4cb05a6bce87aef1bfe8.
//
// Solidity: event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 slashedAmount, bool removedFromSet)
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

// WatchValidatorSlashed is a free log subscription operation binding the contract event 0xb0568c5aad28a0ca5cd06a651d52c0017dfc3af0941a4cb05a6bce87aef1bfe8.
//
// Solidity: event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 slashedAmount, bool removedFromSet)
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

// ParseValidatorSlashed is a log parse operation binding the contract event 0xb0568c5aad28a0ca5cd06a651d52c0017dfc3af0941a4cb05a6bce87aef1bfe8.
//
// Solidity: event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 slashedAmount, bool removedFromSet)
func (_RAT *RATFilterer) ParseValidatorSlashed(log types.Log) (*RATValidatorSlashed, error) {
	event := new(RATValidatorSlashed)
	if err := _RAT.contract.UnpackLog(event, "ValidatorSlashed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
