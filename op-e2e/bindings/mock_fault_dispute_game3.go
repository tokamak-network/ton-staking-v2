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
)

// MockFaultDisputeGame3ABI is the input ABI used to generate the binding from.
const MockFaultDisputeGame3ABI = `[{"type":"constructor","inputs":[{"name":"gameType_","type":"uint32","internalType":"GameType"},{"name":"rootClaim_","type":"bytes32","internalType":"Claim"},{"name":"extraData_","type":"bytes","internalType":"bytes"},{"name":"creator_","type":"address","internalType":"address"}],"stateMutability":"nonpayable"},{"type":"function","name":"MAX_GAME_DEPTH","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"SPLIT_DEPTH","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"actualGameCreator","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"claimData","inputs":[{"name":"","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"parentIndex","type":"uint32","internalType":"uint32"},{"name":"counteredBy","type":"address","internalType":"address"},{"name":"claimant","type":"address","internalType":"address"},{"name":"bond","type":"uint128","internalType":"uint128"},{"name":"claim","type":"bytes32","internalType":"Claim"},{"name":"position","type":"uint128","internalType":"Position"},{"name":"clock","type":"uint128","internalType":"Clock"}],"stateMutability":"view"},{"type":"function","name":"claimDataLen","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"createdAt","inputs":[],"outputs":[{"name":"","type":"uint64","internalType":"Timestamp"}],"stateMutability":"view"},{"type":"function","name":"credit","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"extraData","inputs":[],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"view"},{"type":"function","name":"forceResolveClaim","inputs":[{"name":"_claimIndex","type":"uint256","internalType":"uint256"},{"name":"_winner","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"gameCreator","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"pure"},{"type":"function","name":"gameData","inputs":[],"outputs":[{"name":"","type":"uint32","internalType":"GameType"},{"name":"","type":"bytes32","internalType":"Claim"},{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"view"},{"type":"function","name":"gameType","inputs":[],"outputs":[{"name":"","type":"uint32","internalType":"GameType"}],"stateMutability":"view"},{"type":"function","name":"getSubgames","inputs":[{"name":"_claimIndex","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"view"},{"type":"function","name":"getWinningChallengers","inputs":[],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getWinningChallengersCount","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"initialize","inputs":[],"outputs":[],"stateMutability":"payable"},{"type":"function","name":"isWinningChallenger","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"l1Head","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"Hash"}],"stateMutability":"pure"},{"type":"function","name":"move","inputs":[{"name":"_challengeIndex","type":"uint256","internalType":"uint256"},{"name":"_claim","type":"bytes32","internalType":"Claim"},{"name":"_isAttack","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"payable"},{"type":"function","name":"resolve","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"enum GameStatus"}],"stateMutability":"nonpayable"},{"type":"function","name":"resolveClaim","inputs":[{"name":"_claimIndex","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"resolvedAt","inputs":[],"outputs":[{"name":"","type":"uint64","internalType":"Timestamp"}],"stateMutability":"view"},{"type":"function","name":"resolvedSubgames","inputs":[{"name":"","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"rootClaim","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"Claim"}],"stateMutability":"view"},{"type":"function","name":"setStatus","inputs":[{"name":"_status","type":"uint8","internalType":"enum GameStatus"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"status","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"enum GameStatus"}],"stateMutability":"view"},{"type":"function","name":"step","inputs":[{"name":"_claimIndex","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"subgames","inputs":[{"name":"","type":"uint256","internalType":"uint256"},{"name":"","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"event","name":"Move","inputs":[{"name":"parentIndex","type":"uint256","indexed":true,"internalType":"uint256"},{"name":"claim","type":"bytes32","indexed":true,"internalType":"Claim"},{"name":"claimant","type":"address","indexed":true,"internalType":"address"}],"anonymous":false},{"type":"event","name":"Resolved","inputs":[{"name":"status","type":"uint8","indexed":true,"internalType":"enum GameStatus"}],"anonymous":false},{"type":"error","name":"AlreadyInitialized","inputs":[]},{"type":"error","name":"ClaimAlreadyResolved","inputs":[]},{"type":"error","name":"DuplicateStep","inputs":[]},{"type":"error","name":"GameNotInProgress","inputs":[]},{"type":"error","name":"InvalidParentIndex","inputs":[]},{"type":"error","name":"OutOfOrderResolution","inputs":[]}]`

// MockFaultDisputeGame3Bin is the compiled bytecode used for deploying new contracts.
var MockFaultDisputeGame3Bin = "0x60e06040523480156200001157600080fd5b5060405162001ae938038062001ae98339810160408190526200003491620000a7565b63ffffffff841660805260a0839052600062000051838262000245565b506001600160a01b031660c05250506001805460ff60801b191690555062000311565b634e487b7160e01b600052604160045260246000fd5b80516001600160a01b0381168114620000a257600080fd5b919050565b60008060008060808587031215620000be57600080fd5b845163ffffffff81168114620000d357600080fd5b60208681015160408801519296509450906001600160401b0380821115620000fa57600080fd5b818801915088601f8301126200010f57600080fd5b81518181111562000124576200012462000074565b604051601f8201601f19908116603f011681019083821181831017156200014f576200014f62000074565b816040528281528b868487010111156200016857600080fd5b600093505b828410156200018c57848401860151818501870152928501926200016d565b6000868483010152809750505050505050620001ab606086016200008a565b905092959194509250565b600181811c90821680620001cb57607f821691505b602082108103620001ec57634e487b7160e01b600052602260045260246000fd5b50919050565b601f8211156200024057600081815260208120601f850160051c810160208610156200021b5750805b601f850160051c820191505b818110156200023c5782815560010162000227565b5050505b505050565b81516001600160401b0381111562000261576200026162000074565b6200027981620002728454620001b6565b84620001f2565b602080601f831160018114620002b15760008415620002985750858301515b600019600386901b1c1916600185901b1785556200023c565b600085815260208120601f198616915b82811015620002e257888601518255948401946001909101908401620002c1565b5085821015620003015787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b60805160a05160c05161177e6200036b600039600081816101ff0152818161067e01528181610d63015261135401526000818161045201528181610d9f01526110020152600081816104190152610fe1015261177e6000f3fe6080604052600436106101775760003560e01c80636361506d116100cc578063c6f0308c1161007a578063c6f0308c14610476578063cf09e0d0146104ea578063d5d44d801461050b578063e9da9c2814610538578063fa24f7431461055a578063fdffbb281461057e578063fe2bbeb21461059e57600080fd5b80636361506d1461038f5780637b9737d9146103a35780638129fc1c146103d05780638980e0cc146103d8578063aec26d4c146103ed578063bbdc02db14610402578063bcef3b551461044357600080fd5b80632e49d78b116101295780632e49d78b146102b157806337b1b229146102d15780633991bd4e146102e55780633a1cde75146103255780634778efe814610345578063609d33341461035a578063632247ea1461037c57600080fd5b806319effeb41461017c578063200d2ed2146101c25780632077dd09146101f057806321d427941461023757806324185bc6146102595780632810e1d61461027c5780632ad69aeb14610291575b600080fd5b34801561018857600080fd5b506001546101a490600160401b900467ffffffffffffffff1681565b60405167ffffffffffffffff90911681526020015b60405180910390f35b3480156101ce57600080fd5b506001546101e390600160801b900460ff1681565b6040516101b99190611478565b3480156101fc57600080fd5b507f00000000000000000000000000000000000000000000000000000000000000005b6040516001600160a01b0390911681526020016101b9565b34801561024357600080fd5b506102576102523660046114bc565b6105ce565b005b34801561026557600080fd5b5061026e601e81565b6040519081526020016101b9565b34801561028857600080fd5b506101e36106c5565b34801561029d57600080fd5b5061026e6102ac3660046114e8565b610842565b3480156102bd57600080fd5b506102576102cc36600461150a565b610873565b3480156102dd57600080fd5b50600061021f565b3480156102f157600080fd5b50610315610300366004611532565b60066020526000908152604090205460ff1681565b60405190151581526020016101b9565b34801561033157600080fd5b5061025761034036600461154d565b6108a0565b34801561035157600080fd5b5061026e604981565b34801561036657600080fd5b5061036f610975565b6040516101b991906115ac565b61025761038a3660046115bf565b610a07565b34801561039b57600080fd5b50600061026e565b3480156103af57600080fd5b506103c36103be36600461154d565b610c7c565b6040516101b991906115fd565b610257610cde565b3480156103e457600080fd5b5060025461026e565b3480156103f957600080fd5b5060075461026e565b34801561040e57600080fd5b5060405163ffffffff7f00000000000000000000000000000000000000000000000000000000000000001681526020016101b9565b34801561044f57600080fd5b507f000000000000000000000000000000000000000000000000000000000000000061026e565b34801561048257600080fd5b5061049661049136600461154d565b610f06565b6040805163ffffffff90981688526001600160a01b03968716602089015295909416948601949094526001600160801b039182166060860152608085015291821660a08401521660c082015260e0016101b9565b3480156104f657600080fd5b506001546101a49067ffffffffffffffff1681565b34801561051757600080fd5b5061026e610526366004611532565b60056020526000908152604090205481565b34801561054457600080fd5b5061054d610f79565b6040516101b99190611641565b34801561056657600080fd5b5061056f610fda565b6040516101b993929190611682565b34801561058a57600080fd5b5061025761059936600461154d565b6110ba565b3480156105aa57600080fd5b506103156105b936600461154d565b60046020526000908152604090205460ff1681565b6000828152600460205260409020805460ff1916600117905560028054839081106105fb576105fb6116b0565b60009182526020909120600160059092020101546001600160a01b03828116911614610627578061062a565b60005b6002838154811061063d5761063d6116b0565b600091825260209091206005909102018054640100000000600160c01b031916600160201b6001600160a01b03938416021790558116158015906106b357507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316816001600160a01b031614155b156106c1576106c181611352565b5050565b600080600154600160801b900460ff1660028111156106e6576106e6611462565b146107045760405163067fe19560e41b815260040160405180910390fd5b6000805260046020527f17ef568e3e12ab5b9c7254a8d58478811de00f9e6eb34345acd53bf8fd09d3ec5460ff1661074f57604051634d03b32360e11b815260040160405180910390fd5b60006001600160a01b0316600260008154811061076e5761076e6116b0565b6000918252602090912060059091020154600160201b90046001600160a01b03161461079b57600161079e565b60025b6001805460ff60801b1916600160801b8360028111156107c0576107c0611462565b02179055506001805467ffffffffffffffff60401b1916600160401b4267ffffffffffffffff16021790819055600160801b900460ff16600281111561080857610808611462565b6040517f5e186f09b9c93491f14e277eea7faa5de6a2d4bda75a79af7a3684fbfb42da6090600090a250600154600160801b900460ff1690565b6003602052816000526040600020818154811061085e57600080fd5b90600052602060002001600091509150505481565b6001805482919060ff60801b1916600160801b83600281111561089857610898611462565b021790555050565b6000600154600160801b900460ff1660028111156108c0576108c0611462565b146108de5760405163067fe19560e41b815260040160405180910390fd5b60025481106109005760405163281eb66160e11b815260040160405180910390fd5b600060028281548110610915576109156116b0565b600091825260209091206005909102018054909150600160201b90046001600160a01b03161561095857604051639071e6af60e01b815260040160405180910390fd5b8054640100000000600160c01b03191633600160201b0217905550565b606060008054610984906116c6565b80601f01602080910402602001604051908101604052809291908181526020018280546109b0906116c6565b80156109fd5780601f106109d2576101008083540402835291602001916109fd565b820191906000526020600020905b8154815290600101906020018083116109e057829003601f168201915b5050505050905090565b6000600154600160801b900460ff166002811115610a2757610a27611462565b14610a455760405163067fe19560e41b815260040160405180910390fd5b6002548310610a675760405163281eb66160e11b815260040160405180910390fd5b600060028481548110610a7c57610a7c6116b0565b600091825260208083206040805160e0810182526005909402909101805463ffffffff80821686526001600160a01b03600160201b9092048216948601949094526001820154169184019190915260028101546001600160801b0390811660608501526003820154608085015260049091015480821660a08501819052600160801b90910490911660c0840152919350610b199190859061141816565b600280546040805160e08101825263ffffffff8a1681526000602082015233918101919091526001600160801b03348116606083015260808201899052841660a08201529293509160c08101426001600160801b0390811690915282546001808201855560009485526020808620855160059094020180548683015163ffffffff9095166001600160c01b031990911617600160201b6001600160a01b039586160217815560408087015182850180546001600160a01b031916919096161790945560608601516002820180546001600160801b031916918716919091179055608086015160038083019190915560a087015160c090970151968616600160801b9790961696909602949094176004909401939093558a8552928252808420805493840181558452908320909101839055513391879189917f9b3245740ec3b155098a55be84957a4da13eaf7f14a8bc6f53126c0b9350f2be91a4505050505050565b600081815260036020908152604091829020805483518184028101840190945280845260609392830182828015610cd257602002820191906000526020600020905b815481526020019060010190808311610cbe575b50505050509050919050565b600154600160881b900460ff1615610d085760405162dc149f60e41b815260040160405180910390fd5b60018054600160881b71ff000000000000000000ffffffffffffffff199091164267ffffffffffffffff8116919091179190911782556040805160e08101825263ffffffff8082526000602083018181526001600160a01b037f00000000000000000000000000000000000000000000000000000000000000008116958501958652346001600160801b03908116606087019081527f00000000000000000000000000000000000000000000000000000000000000006080880190815260a088018b815299831660c08901908152600280549c8d01815590965296516005909a027f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace8101805495518516600160201b026001600160c01b03199096169b9097169a909a179390931790945594517f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5acf88018054919096166001600160a01b03199091161790945592517f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ad0860180549183166001600160801b031990921691909117905590517f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ad1850155915190518216600160801b029116177f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ad290910155565b60028181548110610f1657600080fd5b60009182526020909120600590910201805460018201546002830154600384015460049094015463ffffffff84169550600160201b9093046001600160a01b03908116949216926001600160801b03918216929180821691600160801b90041687565b606060078054806020026020016040519081016040528092919081815260200182805480156109fd57602002820191906000526020600020905b81546001600160a01b03168152600190910190602001808311610fb3575050505050905090565b60008060607f00000000000000000000000000000000000000000000000000000000000000007f0000000000000000000000000000000000000000000000000000000000000000600080805461102f906116c6565b80601f016020809104026020016040519081016040528092919081815260200182805461105b906116c6565b80156110a85780601f1061107d576101008083540402835291602001916110a8565b820191906000526020600020905b81548152906001019060200180831161108b57829003601f168201915b50505050509050925092509250909192565b6000600154600160801b900460ff1660028111156110da576110da611462565b146110f85760405163067fe19560e41b815260040160405180910390fd5b60008181526004602052604090205460ff16156111285760405163f1a9458160e01b815260040160405180910390fd5b60006002828154811061113d5761113d6116b0565b60009182526020808320858452600390915260409092208054600590920290920192508015801561116d57508315155b156111d6578254600160201b90046001600160a01b03166000811561119257816111a1565b60018501546001600160a01b03165b90506111ad8186611420565b6111b681611352565b50505060009283525050600460205260409020805460ff19166001179055565b60006001600160801b03815b838110156112d15760008582815481106111fe576111fe6116b0565b6000918252602080832090910154808352600490915260409091205490915060ff1661123d57604051634d03b32360e11b815260040160405180910390fd5b600060028281548110611252576112526116b0565b600091825260209091206005909102018054909150600160201b90046001600160a01b0316158015611294575060048101546001600160801b03908116908516115b156112bc57600181015460048201546001600160a01b0390911695506001600160801b031693505b505080806112c990611716565b9150506111e2565b506000868152600460205260408120805460ff191660011790556001600160a01b03831615611300578261130f565b60018601546001600160a01b03165b905061131b8187611420565b61132481611352565b505083546001600160a01b03909116600160201b02640100000000600160c01b031990911617909255505050565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316816001600160a01b03160361138e5750565b6001600160a01b03811660009081526006602052604090205460ff16156113b25750565b6001600160a01b03166000818152600660205260408120805460ff191660019081179091556007805491820181559091527fa66cc928b5edb82af9bd49922954155ab7b0942694bea4ce44661d9a8736c6880180546001600160a01b0319169091179055565b151760011b90565b60028101546001600160a01b038316600090815260056020526040812080546001600160801b039093169290919061145990849061172f565b90915550505050565b634e487b7160e01b600052602160045260246000fd5b602081016003831061149a57634e487b7160e01b600052602160045260246000fd5b91905290565b80356001600160a01b03811681146114b757600080fd5b919050565b600080604083850312156114cf57600080fd5b823591506114df602084016114a0565b90509250929050565b600080604083850312156114fb57600080fd5b50508035926020909101359150565b60006020828403121561151c57600080fd5b81356003811061152b57600080fd5b9392505050565b60006020828403121561154457600080fd5b61152b826114a0565b60006020828403121561155f57600080fd5b5035919050565b6000815180845260005b8181101561158c57602081850181015186830182015201611570565b506000602082860101526020601f19601f83011685010191505092915050565b60208152600061152b6020830184611566565b6000806000606084860312156115d457600080fd5b8335925060208401359150604084013580151581146115f257600080fd5b809150509250925092565b6020808252825182820181905260009190848201906040850190845b8181101561163557835183529284019291840191600101611619565b50909695505050505050565b6020808252825182820181905260009190848201906040850190845b818110156116355783516001600160a01b03168352928401929184019160010161165d565b63ffffffff841681528260208201526060604082015260006116a76060830184611566565b95945050505050565b634e487b7160e01b600052603260045260246000fd5b600181811c908216806116da57607f821691505b6020821081036116fa57634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052601160045260246000fd5b60006001820161172857611728611700565b5060010190565b8082018082111561174257611742611700565b9291505056fea2646970667358221220cee723f5b245dbb04101be549f57bd984bbef2c5cc3ba051b2e67963dc5d7f5064736f6c63430008130033"

// DeployMockFaultDisputeGame3 deploys a new Ethereum contract, binding an instance of MockFaultDisputeGame3 to it.
func DeployMockFaultDisputeGame3(auth *bind.TransactOpts, backend bind.ContractBackend, gameType_ uint32, rootClaim_ [32]byte, extraData_ []byte, creator_ common.Address) (common.Address, *types.Transaction, *MockFaultDisputeGame3, error) {
	parsed, err := abi.JSON(strings.NewReader(MockFaultDisputeGame3ABI))
	if err != nil {
		return common.Address{}, nil, nil, err
	}

	address, tx, contract, err := bind.DeployContract(auth, parsed, common.FromHex(MockFaultDisputeGame3Bin), backend, gameType_, rootClaim_, extraData_, creator_)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &MockFaultDisputeGame3{MockFaultDisputeGame3Caller: MockFaultDisputeGame3Caller{contract: contract}, MockFaultDisputeGame3Transactor: MockFaultDisputeGame3Transactor{contract: contract}, MockFaultDisputeGame3Filterer: MockFaultDisputeGame3Filterer{contract: contract}}, nil
}

// MockFaultDisputeGame3 is an auto generated Go binding around an Ethereum contract.
type MockFaultDisputeGame3 struct {
	MockFaultDisputeGame3Caller     // Read-only binding to the contract
	MockFaultDisputeGame3Transactor // Write-only binding to the contract
	MockFaultDisputeGame3Filterer   // Log filterer for contract events
}

// MockFaultDisputeGame3Caller is an auto generated read-only Go binding around an Ethereum contract.
type MockFaultDisputeGame3Caller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockFaultDisputeGame3Transactor is an auto generated write-only Go binding around an Ethereum contract.
type MockFaultDisputeGame3Transactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockFaultDisputeGame3Filterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MockFaultDisputeGame3Filterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockFaultDisputeGame3Session is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MockFaultDisputeGame3Session struct {
	Contract     *MockFaultDisputeGame3 // Generic contract binding to set the session for
	CallOpts     bind.CallOpts          // Call options to use throughout this session
	TransactOpts bind.TransactOpts      // Transaction auth options to use throughout this session
}

// MockFaultDisputeGame3CallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MockFaultDisputeGame3CallerSession struct {
	Contract *MockFaultDisputeGame3Caller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts                // Call options to use throughout this session
}

// MockFaultDisputeGame3TransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MockFaultDisputeGame3TransactorSession struct {
	Contract     *MockFaultDisputeGame3Transactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts                // Transaction auth options to use throughout this session
}

// MockFaultDisputeGame3Raw is an auto generated low-level Go binding around an Ethereum contract.
type MockFaultDisputeGame3Raw struct {
	Contract *MockFaultDisputeGame3 // Generic contract binding to access the raw methods on
}

// MockFaultDisputeGame3CallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MockFaultDisputeGame3CallerRaw struct {
	Contract *MockFaultDisputeGame3Caller // Generic read-only contract binding to access the raw methods on
}

// MockFaultDisputeGame3TransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MockFaultDisputeGame3TransactorRaw struct {
	Contract *MockFaultDisputeGame3Transactor // Generic write-only contract binding to access the raw methods on
}

// NewMockFaultDisputeGame3 creates a new instance of MockFaultDisputeGame3, bound to a specific deployed contract.
func NewMockFaultDisputeGame3(address common.Address, backend bind.ContractBackend) (*MockFaultDisputeGame3, error) {
	contract, err := bindMockFaultDisputeGame3(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MockFaultDisputeGame3{MockFaultDisputeGame3Caller: MockFaultDisputeGame3Caller{contract: contract}, MockFaultDisputeGame3Transactor: MockFaultDisputeGame3Transactor{contract: contract}, MockFaultDisputeGame3Filterer: MockFaultDisputeGame3Filterer{contract: contract}}, nil
}

// NewMockFaultDisputeGame3Caller creates a new read-only instance of MockFaultDisputeGame3, bound to a specific deployed contract.
func NewMockFaultDisputeGame3Caller(address common.Address, caller bind.ContractCaller) (*MockFaultDisputeGame3Caller, error) {
	contract, err := bindMockFaultDisputeGame3(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MockFaultDisputeGame3Caller{contract: contract}, nil
}

// NewMockFaultDisputeGame3Transactor creates a new write-only instance of MockFaultDisputeGame3, bound to a specific deployed contract.
func NewMockFaultDisputeGame3Transactor(address common.Address, transactor bind.ContractTransactor) (*MockFaultDisputeGame3Transactor, error) {
	contract, err := bindMockFaultDisputeGame3(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MockFaultDisputeGame3Transactor{contract: contract}, nil
}

// NewMockFaultDisputeGame3Filterer creates a new log filterer instance of MockFaultDisputeGame3, bound to a specific deployed contract.
func NewMockFaultDisputeGame3Filterer(address common.Address, filterer bind.ContractFilterer) (*MockFaultDisputeGame3Filterer, error) {
	contract, err := bindMockFaultDisputeGame3(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MockFaultDisputeGame3Filterer{contract: contract}, nil
}

// bindMockFaultDisputeGame3 binds a generic wrapper to an already deployed contract.
func bindMockFaultDisputeGame3(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(MockFaultDisputeGame3ABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Raw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockFaultDisputeGame3.Contract.MockFaultDisputeGame3Caller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default receive function.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Raw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.Contract.MockFaultDisputeGame3Transactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Raw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.Contract.MockFaultDisputeGame3Transactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3CallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockFaultDisputeGame3.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default receive function.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3TransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3TransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.Contract.contract.Transact(opts, method, params...)
}

// MAXGAMEDEPTH is a free data retrieval call binding the contract method 0xfa24f743.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) MAXGAMEDEPTH(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "MAX_GAME_DEPTH")
	if err != nil {
		return *new(*big.Int), err
	}
	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	return out0, err
}

// SPLITDEPTH is a free data retrieval call binding the contract method 0xec5e6308.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) SPLITDEPTH(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "SPLIT_DEPTH")
	if err != nil {
		return *new(*big.Int), err
	}
	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	return out0, err
}

// ActualGameCreator is a free data retrieval call binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) ActualGameCreator(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "actualGameCreator")
	if err != nil {
		return *new(common.Address), err
	}
	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	return out0, err
}

// ClaimDataLen is a free data retrieval call binding the contract method 0x8980e0cc.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) ClaimDataLen(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "claimDataLen")
	if err != nil {
		return *new(*big.Int), err
	}
	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	return out0, err
}

// CreatedAt is a free data retrieval call binding the contract method 0xcf09e0d0.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) CreatedAt(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "createdAt")
	if err != nil {
		return *new(uint64), err
	}
	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)
	return out0, err
}

// Credit is a free data retrieval call binding the contract method 0xd5d44d80.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) Credit(opts *bind.CallOpts, addr common.Address) (*big.Int, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "credit", addr)
	if err != nil {
		return *new(*big.Int), err
	}
	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	return out0, err
}

// ExtraData is a free data retrieval call binding the contract method 0x609d3334.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) ExtraData(opts *bind.CallOpts) ([]byte, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "extraData")
	if err != nil {
		return *new([]byte), err
	}
	out0 := *abi.ConvertType(out[0], new([]byte)).(*[]byte)
	return out0, err
}

// GameCreator is a free data retrieval call binding the contract method 0x37b1b229.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) GameCreator(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "gameCreator")
	if err != nil {
		return *new(common.Address), err
	}
	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	return out0, err
}

// GameType is a free data retrieval call binding the contract method 0xbbdc02db.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) GameType(opts *bind.CallOpts) (uint32, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "gameType")
	if err != nil {
		return *new(uint32), err
	}
	out0 := *abi.ConvertType(out[0], new(uint32)).(*uint32)
	return out0, err
}

// GetSubgames is a free data retrieval call binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) GetSubgames(opts *bind.CallOpts, _claimIndex *big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "getSubgames", _claimIndex)
	if err != nil {
		return *new([]*big.Int), err
	}
	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)
	return out0, err
}

// GetWinningChallengers is a free data retrieval call binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) GetWinningChallengers(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "getWinningChallengers")
	if err != nil {
		return *new([]common.Address), err
	}
	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)
	return out0, err
}

// GetWinningChallengersCount is a free data retrieval call binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) GetWinningChallengersCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "getWinningChallengersCount")
	if err != nil {
		return *new(*big.Int), err
	}
	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	return out0, err
}

// IsWinningChallenger is a free data retrieval call binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) IsWinningChallenger(opts *bind.CallOpts, addr common.Address) (bool, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "isWinningChallenger", addr)
	if err != nil {
		return *new(bool), err
	}
	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)
	return out0, err
}

// L1Head is a free data retrieval call binding the contract method 0x6361506d.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) L1Head(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "l1Head")
	if err != nil {
		return *new([32]byte), err
	}
	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)
	return out0, err
}

// ResolvedAt is a free data retrieval call binding the contract method 0x19effeb4.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) ResolvedAt(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "resolvedAt")
	if err != nil {
		return *new(uint64), err
	}
	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)
	return out0, err
}

// ResolvedSubgames is a free data retrieval call binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) ResolvedSubgames(opts *bind.CallOpts, index *big.Int) (bool, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "resolvedSubgames", index)
	if err != nil {
		return *new(bool), err
	}
	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)
	return out0, err
}

// RootClaim is a free data retrieval call binding the contract method 0xbcef3b55.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) RootClaim(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "rootClaim")
	if err != nil {
		return *new([32]byte), err
	}
	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)
	return out0, err
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Caller) Status(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _MockFaultDisputeGame3.contract.Call(opts, &out, "status")
	if err != nil {
		return *new(uint8), err
	}
	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)
	return out0, err
}

// ForceResolveClaim is a paid mutator transaction binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Transactor) ForceResolveClaim(opts *bind.TransactOpts, _claimIndex *big.Int, _winner common.Address) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.contract.Transact(opts, "forceResolveClaim", _claimIndex, _winner)
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Transactor) Initialize(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.contract.Transact(opts, "initialize")
}

// Move is a paid mutator transaction binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Transactor) Move(opts *bind.TransactOpts, _challengeIndex *big.Int, _claim [32]byte, _isAttack bool) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.contract.Transact(opts, "move", _challengeIndex, _claim, _isAttack)
}

// Resolve is a paid mutator transaction binding the contract method 0x2810e1d6.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Transactor) Resolve(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.contract.Transact(opts, "resolve")
}

// ResolveClaim is a paid mutator transaction binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Transactor) ResolveClaim(opts *bind.TransactOpts, _claimIndex *big.Int) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.contract.Transact(opts, "resolveClaim", _claimIndex)
}

// SetStatus is a paid mutator transaction binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Transactor) SetStatus(opts *bind.TransactOpts, _status uint8) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.contract.Transact(opts, "setStatus", _status)
}

// Step is a paid mutator transaction binding the contract method.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Transactor) Step(opts *bind.TransactOpts, _claimIndex *big.Int) (*types.Transaction, error) {
	return _MockFaultDisputeGame3.contract.Transact(opts, "step", _claimIndex)
}

// MockFaultDisputeGame3MoveIterator is returned from FilterMove and is used to iterate over the raw logs and unpacked data for Move events raised by the MockFaultDisputeGame3 contract.
type MockFaultDisputeGame3MoveIterator struct {
	Event *MockFaultDisputeGame3Move // Event containing the contract specifics and raw log

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
func (it *MockFaultDisputeGame3MoveIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockFaultDisputeGame3Move)
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
		it.Event = new(MockFaultDisputeGame3Move)
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
func (it *MockFaultDisputeGame3MoveIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockFaultDisputeGame3MoveIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockFaultDisputeGame3Move represents a Move event raised by the MockFaultDisputeGame3 contract.
type MockFaultDisputeGame3Move struct {
	ParentIndex *big.Int
	Claim       [32]byte
	Claimant    common.Address
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterMove is a free log retrieval operation binding the contract event.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Filterer) FilterMove(opts *bind.FilterOpts, parentIndex []*big.Int, claim [][32]byte, claimant []common.Address) (*MockFaultDisputeGame3MoveIterator, error) {

	var parentIndexRule []interface{}
	for _, parentIndexItem := range parentIndex {
		parentIndexRule = append(parentIndexRule, parentIndexItem)
	}
	var claimRule []interface{}
	for _, claimItem := range claim {
		claimRule = append(claimRule, claimItem)
	}
	var claimantRule []interface{}
	for _, claimantItem := range claimant {
		claimantRule = append(claimantRule, claimantItem)
	}

	logs, sub, err := _MockFaultDisputeGame3.contract.FilterLogs(opts, "Move", parentIndexRule, claimRule, claimantRule)
	if err != nil {
		return nil, err
	}
	return &MockFaultDisputeGame3MoveIterator{contract: _MockFaultDisputeGame3.contract, event: "Move", logs: logs, sub: sub}, nil
}

// WatchMove is a free log subscription operation binding the contract event.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Filterer) WatchMove(opts *bind.WatchOpts, sink chan<- *MockFaultDisputeGame3Move, parentIndex []*big.Int, claim [][32]byte, claimant []common.Address) (event.Subscription, error) {

	var parentIndexRule []interface{}
	for _, parentIndexItem := range parentIndex {
		parentIndexRule = append(parentIndexRule, parentIndexItem)
	}
	var claimRule []interface{}
	for _, claimItem := range claim {
		claimRule = append(claimRule, claimItem)
	}
	var claimantRule []interface{}
	for _, claimantItem := range claimant {
		claimantRule = append(claimantRule, claimantItem)
	}

	logs, sub, err := _MockFaultDisputeGame3.contract.WatchLogs(opts, "Move", parentIndexRule, claimRule, claimantRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockFaultDisputeGame3Move)
				if err := _MockFaultDisputeGame3.contract.UnpackLog(event, "Move", log); err != nil {
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

// ParseMove is a log parse operation binding the contract event.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Filterer) ParseMove(log types.Log) (*MockFaultDisputeGame3Move, error) {
	event := new(MockFaultDisputeGame3Move)
	if err := _MockFaultDisputeGame3.contract.UnpackLog(event, "Move", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockFaultDisputeGame3ResolvedIterator is returned from FilterResolved and is used to iterate over the raw logs and unpacked data for Resolved events raised by the MockFaultDisputeGame3 contract.
type MockFaultDisputeGame3ResolvedIterator struct {
	Event *MockFaultDisputeGame3Resolved // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event.
func (it *MockFaultDisputeGame3ResolvedIterator) Next() bool {
	if it.fail != nil {
		return false
	}
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockFaultDisputeGame3Resolved)
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
		it.Event = new(MockFaultDisputeGame3Resolved)
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
func (it *MockFaultDisputeGame3ResolvedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process.
func (it *MockFaultDisputeGame3ResolvedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockFaultDisputeGame3Resolved represents a Resolved event raised by the MockFaultDisputeGame3 contract.
type MockFaultDisputeGame3Resolved struct {
	Status uint8
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterResolved is a free log retrieval operation binding the contract event.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Filterer) FilterResolved(opts *bind.FilterOpts, status []uint8) (*MockFaultDisputeGame3ResolvedIterator, error) {
	var statusRule []interface{}
	for _, statusItem := range status {
		statusRule = append(statusRule, statusItem)
	}

	logs, sub, err := _MockFaultDisputeGame3.contract.FilterLogs(opts, "Resolved", statusRule)
	if err != nil {
		return nil, err
	}
	return &MockFaultDisputeGame3ResolvedIterator{contract: _MockFaultDisputeGame3.contract, event: "Resolved", logs: logs, sub: sub}, nil
}

// WatchResolved is a free log subscription operation binding the contract event.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Filterer) WatchResolved(opts *bind.WatchOpts, sink chan<- *MockFaultDisputeGame3Resolved, status []uint8) (event.Subscription, error) {
	var statusRule []interface{}
	for _, statusItem := range status {
		statusRule = append(statusRule, statusItem)
	}

	logs, sub, err := _MockFaultDisputeGame3.contract.WatchLogs(opts, "Resolved", statusRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				event := new(MockFaultDisputeGame3Resolved)
				if err := _MockFaultDisputeGame3.contract.UnpackLog(event, "Resolved", log); err != nil {
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

// ParseResolved is a log parse operation binding the contract event.
func (_MockFaultDisputeGame3 *MockFaultDisputeGame3Filterer) ParseResolved(log types.Log) (*MockFaultDisputeGame3Resolved, error) {
	event := new(MockFaultDisputeGame3Resolved)
	if err := _MockFaultDisputeGame3.contract.UnpackLog(event, "Resolved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
