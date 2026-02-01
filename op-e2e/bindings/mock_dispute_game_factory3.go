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

// MockDisputeGameFactory3Bin is the compiled bytecode used for deploying new contracts.
var MockDisputeGameFactory3Bin = "0x608060405234801561001057600080fd5b50611e81806100206000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c80634c5848d1146100465780635f0150cb1461008c57806382ecf2f6146100c7575b600080fd5b61006f61005436600461021e565b6000602081905290815260409020546001600160a01b031681565b6040516001600160a01b0390911681526020015b60405180910390f35b61009f61009a366004610237565b6100da565b604080516001600160a01b03909316835267ffffffffffffffff909116602083015201610083565b61006f6100d5366004610237565b610130565b6000806000868686866040516020016100f694939291906102f2565b60408051808303601f1901815291815281516020928301206000908152918290528120546001600160a01b03169890975095505050505050565b6000808585858560405160200161014a94939291906102f2565b6040516020818303038152906040528051906020012090506000868686863360405161017590610211565b610183959493929190610322565b604051809103906000f08015801561019f573d6000803e3d6000fd5b506000838152602081815260409182902080546001600160a01b0319166001600160a01b038516908117909155915189815292935063ffffffff8a16927f5b565efe82411da98814f356d0e7bcb8f0219b8d970307c5afb4a6903a8b2e35910160405180910390a39695505050505050565b611ae98061036383390190565b60006020828403121561023057600080fd5b5035919050565b6000806000806060858703121561024d57600080fd5b843563ffffffff8116811461026157600080fd5b935060208501359250604085013567ffffffffffffffff8082111561028557600080fd5b818701915087601f83011261029957600080fd5b8135818111156102a857600080fd5b8860208285010111156102ba57600080fd5b95989497505060200194505050565b81835281816020850137506000828201602090810191909152601f909101601f19169091010190565b63ffffffff851681528360208201526060604082015260006103186060830184866102c9565b9695505050505050565b63ffffffff861681528460208201526080604082015260006103486080830185876102c9565b905060018060a01b0383166060830152969550505050505056fe60e06040523480156200001157600080fd5b5060405162001ae938038062001ae98339810160408190526200003491620000a7565b63ffffffff841660805260a0839052600062000051838262000245565b506001600160a01b031660c05250506001805460ff60801b191690555062000311565b634e487b7160e01b600052604160045260246000fd5b80516001600160a01b0381168114620000a257600080fd5b919050565b60008060008060808587031215620000be57600080fd5b845163ffffffff81168114620000d357600080fd5b60208681015160408801519296509450906001600160401b0380821115620000fa57600080fd5b818801915088601f8301126200010f57600080fd5b81518181111562000124576200012462000074565b604051601f8201601f19908116603f011681019083821181831017156200014f576200014f62000074565b816040528281528b868487010111156200016857600080fd5b600093505b828410156200018c57848401860151818501870152928501926200016d565b6000868483010152809750505050505050620001ab606086016200008a565b905092959194509250565b600181811c90821680620001cb57607f821691505b602082108103620001ec57634e487b7160e01b600052602260045260246000fd5b50919050565b601f8211156200024057600081815260208120601f850160051c810160208610156200021b5750805b601f850160051c820191505b818110156200023c5782815560010162000227565b5050505b505050565b81516001600160401b0381111562000261576200026162000074565b6200027981620002728454620001b6565b84620001f2565b602080601f831160018114620002b15760008415620002985750858301515b600019600386901b1c1916600185901b1785556200023c565b600085815260208120601f198616915b82811015620002e257888601518255948401946001909101908401620002c1565b5085821015620003015787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b60805160a05160c05161177e6200036b600039600081816101ff0152818161067e01528181610d63015261135401526000818161045201528181610d9f01526110020152600081816104190152610fe1015261177e6000f3fe6080604052600436106101775760003560e01c80636361506d116100cc578063c6f0308c1161007a578063c6f0308c14610476578063cf09e0d0146104ea578063d5d44d801461050b578063e9da9c2814610538578063fa24f7431461055a578063fdffbb281461057e578063fe2bbeb21461059e57600080fd5b80636361506d1461038f5780637b9737d9146103a35780638129fc1c146103d05780638980e0cc146103d8578063aec26d4c146103ed578063bbdc02db14610402578063bcef3b551461044357600080fd5b80632e49d78b116101295780632e49d78b146102b157806337b1b229146102d15780633991bd4e146102e55780633a1cde75146103255780634778efe814610345578063609d33341461035a578063632247ea1461037c57600080fd5b806319effeb41461017c578063200d2ed2146101c25780632077dd09146101f057806321d427941461023757806324185bc6146102595780632810e1d61461027c5780632ad69aeb14610291575b600080fd5b34801561018857600080fd5b506001546101a490600160401b900467ffffffffffffffff1681565b60405167ffffffffffffffff90911681526020015b60405180910390f35b3480156101ce57600080fd5b506001546101e390600160801b900460ff1681565b6040516101b99190611478565b3480156101fc57600080fd5b507f00000000000000000000000000000000000000000000000000000000000000005b6040516001600160a01b0390911681526020016101b9565b34801561024357600080fd5b506102576102523660046114bc565b6105ce565b005b34801561026557600080fd5b5061026e601e81565b6040519081526020016101b9565b34801561028857600080fd5b506101e36106c5565b34801561029d57600080fd5b5061026e6102ac3660046114e8565b610842565b3480156102bd57600080fd5b506102576102cc36600461150a565b610873565b3480156102dd57600080fd5b50600061021f565b3480156102f157600080fd5b50610315610300366004611532565b60066020526000908152604090205460ff1681565b60405190151581526020016101b9565b34801561033157600080fd5b5061025761034036600461154d565b6108a0565b34801561035157600080fd5b5061026e604981565b34801561036657600080fd5b5061036f610975565b6040516101b991906115ac565b61025761038a3660046115bf565b610a07565b34801561039b57600080fd5b50600061026e565b3480156103af57600080fd5b506103c36103be36600461154d565b610c7c565b6040516101b991906115fd565b610257610cde565b3480156103e457600080fd5b5060025461026e565b3480156103f957600080fd5b5060075461026e565b34801561040e57600080fd5b5060405163ffffffff7f00000000000000000000000000000000000000000000000000000000000000001681526020016101b9565b34801561044f57600080fd5b507f000000000000000000000000000000000000000000000000000000000000000061026e565b34801561048257600080fd5b5061049661049136600461154d565b610f06565b6040805163ffffffff90981688526001600160a01b03968716602089015295909416948601949094526001600160801b039182166060860152608085015291821660a08401521660c082015260e0016101b9565b3480156104f657600080fd5b506001546101a49067ffffffffffffffff1681565b34801561051757600080fd5b5061026e610526366004611532565b60056020526000908152604090205481565b34801561054457600080fd5b5061054d610f79565b6040516101b99190611641565b34801561056657600080fd5b5061056f610fda565b6040516101b993929190611682565b34801561058a57600080fd5b5061025761059936600461154d565b6110ba565b3480156105aa57600080fd5b506103156105b936600461154d565b60046020526000908152604090205460ff1681565b6000828152600460205260409020805460ff1916600117905560028054839081106105fb576105fb6116b0565b60009182526020909120600160059092020101546001600160a01b03828116911614610627578061062a565b60005b6002838154811061063d5761063d6116b0565b600091825260209091206005909102018054640100000000600160c01b031916600160201b6001600160a01b03938416021790558116158015906106b357507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316816001600160a01b031614155b156106c1576106c181611352565b5050565b600080600154600160801b900460ff1660028111156106e6576106e6611462565b146107045760405163067fe19560e41b815260040160405180910390fd5b6000805260046020527f17ef568e3e12ab5b9c7254a8d58478811de00f9e6eb34345acd53bf8fd09d3ec5460ff1661074f57604051634d03b32360e11b815260040160405180910390fd5b60006001600160a01b0316600260008154811061076e5761076e6116b0565b6000918252602090912060059091020154600160201b90046001600160a01b03161461079b57600161079e565b60025b6001805460ff60801b1916600160801b8360028111156107c0576107c0611462565b02179055506001805467ffffffffffffffff60401b1916600160401b4267ffffffffffffffff16021790819055600160801b900460ff16600281111561080857610808611462565b6040517f5e186f09b9c93491f14e277eea7faa5de6a2d4bda75a79af7a3684fbfb42da6090600090a250600154600160801b900460ff1690565b6003602052816000526040600020818154811061085e57600080fd5b90600052602060002001600091509150505481565b6001805482919060ff60801b1916600160801b83600281111561089857610898611462565b021790555050565b6000600154600160801b900460ff1660028111156108c0576108c0611462565b146108de5760405163067fe19560e41b815260040160405180910390fd5b60025481106109005760405163281eb66160e11b815260040160405180910390fd5b600060028281548110610915576109156116b0565b600091825260209091206005909102018054909150600160201b90046001600160a01b03161561095857604051639071e6af60e01b815260040160405180910390fd5b8054640100000000600160c01b03191633600160201b0217905550565b606060008054610984906116c6565b80601f01602080910402602001604051908101604052809291908181526020018280546109b0906116c6565b80156109fd5780601f106109d2576101008083540402835291602001916109fd565b820191906000526020600020905b8154815290600101906020018083116109e057829003601f168201915b5050505050905090565b6000600154600160801b900460ff166002811115610a2757610a27611462565b14610a455760405163067fe19560e41b815260040160405180910390fd5b6002548310610a675760405163281eb66160e11b815260040160405180910390fd5b600060028481548110610a7c57610a7c6116b0565b600091825260208083206040805160e0810182526005909402909101805463ffffffff80821686526001600160a01b03600160201b9092048216948601949094526001820154169184019190915260028101546001600160801b0390811660608501526003820154608085015260049091015480821660a08501819052600160801b90910490911660c0840152919350610b199190859061141816565b600280546040805160e08101825263ffffffff8a1681526000602082015233918101919091526001600160801b03348116606083015260808201899052841660a08201529293509160c08101426001600160801b0390811690915282546001808201855560009485526020808620855160059094020180548683015163ffffffff9095166001600160c01b031990911617600160201b6001600160a01b039586160217815560408087015182850180546001600160a01b031916919096161790945560608601516002820180546001600160801b031916918716919091179055608086015160038083019190915560a087015160c090970151968616600160801b9790961696909602949094176004909401939093558a8552928252808420805493840181558452908320909101839055513391879189917f9b3245740ec3b155098a55be84957a4da13eaf7f14a8bc6f53126c0b9350f2be91a4505050505050565b600081815260036020908152604091829020805483518184028101840190945280845260609392830182828015610cd257602002820191906000526020600020905b815481526020019060010190808311610cbe575b50505050509050919050565b600154600160881b900460ff1615610d085760405162dc149f60e41b815260040160405180910390fd5b60018054600160881b71ff000000000000000000ffffffffffffffff199091164267ffffffffffffffff8116919091179190911782556040805160e08101825263ffffffff8082526000602083018181526001600160a01b037f00000000000000000000000000000000000000000000000000000000000000008116958501958652346001600160801b03908116606087019081527f00000000000000000000000000000000000000000000000000000000000000006080880190815260a088018b815299831660c08901908152600280549c8d01815590965296516005909a027f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace8101805495518516600160201b026001600160c01b03199096169b9097169a909a179390931790945594517f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5acf88018054919096166001600160a01b03199091161790945592517f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ad0860180549183166001600160801b031990921691909117905590517f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ad1850155915190518216600160801b029116177f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ad290910155565b60028181548110610f1657600080fd5b60009182526020909120600590910201805460018201546002830154600384015460049094015463ffffffff84169550600160201b9093046001600160a01b03908116949216926001600160801b03918216929180821691600160801b90041687565b606060078054806020026020016040519081016040528092919081815260200182805480156109fd57602002820191906000526020600020905b81546001600160a01b03168152600190910190602001808311610fb3575050505050905090565b60008060607f00000000000000000000000000000000000000000000000000000000000000007f0000000000000000000000000000000000000000000000000000000000000000600080805461102f906116c6565b80601f016020809104026020016040519081016040528092919081815260200182805461105b906116c6565b80156110a85780601f1061107d576101008083540402835291602001916110a8565b820191906000526020600020905b81548152906001019060200180831161108b57829003601f168201915b50505050509050925092509250909192565b6000600154600160801b900460ff1660028111156110da576110da611462565b146110f85760405163067fe19560e41b815260040160405180910390fd5b60008181526004602052604090205460ff16156111285760405163f1a9458160e01b815260040160405180910390fd5b60006002828154811061113d5761113d6116b0565b60009182526020808320858452600390915260409092208054600590920290920192508015801561116d57508315155b156111d6578254600160201b90046001600160a01b03166000811561119257816111a1565b60018501546001600160a01b03165b90506111ad8186611420565b6111b681611352565b50505060009283525050600460205260409020805460ff19166001179055565b60006001600160801b03815b838110156112d15760008582815481106111fe576111fe6116b0565b6000918252602080832090910154808352600490915260409091205490915060ff1661123d57604051634d03b32360e11b815260040160405180910390fd5b600060028281548110611252576112526116b0565b600091825260209091206005909102018054909150600160201b90046001600160a01b0316158015611294575060048101546001600160801b03908116908516115b156112bc57600181015460048201546001600160a01b0390911695506001600160801b031693505b505080806112c990611716565b9150506111e2565b506000868152600460205260408120805460ff191660011790556001600160a01b03831615611300578261130f565b60018601546001600160a01b03165b905061131b8187611420565b61132481611352565b505083546001600160a01b03909116600160201b02640100000000600160c01b031990911617909255505050565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316816001600160a01b03160361138e5750565b6001600160a01b03811660009081526006602052604090205460ff16156113b25750565b6001600160a01b03166000818152600660205260408120805460ff191660019081179091556007805491820181559091527fa66cc928b5edb82af9bd49922954155ab7b0942694bea4ce44661d9a8736c6880180546001600160a01b0319169091179055565b151760011b90565b60028101546001600160a01b038316600090815260056020526040812080546001600160801b039093169290919061145990849061172f565b90915550505050565b634e487b7160e01b600052602160045260246000fd5b602081016003831061149a57634e487b7160e01b600052602160045260246000fd5b91905290565b80356001600160a01b03811681146114b757600080fd5b919050565b600080604083850312156114cf57600080fd5b823591506114df602084016114a0565b90509250929050565b600080604083850312156114fb57600080fd5b50508035926020909101359150565b60006020828403121561151c57600080fd5b81356003811061152b57600080fd5b9392505050565b60006020828403121561154457600080fd5b61152b826114a0565b60006020828403121561155f57600080fd5b5035919050565b6000815180845260005b8181101561158c57602081850181015186830182015201611570565b506000602082860101526020601f19601f83011685010191505092915050565b60208152600061152b6020830184611566565b6000806000606084860312156115d457600080fd5b8335925060208401359150604084013580151581146115f257600080fd5b809150509250925092565b6020808252825182820181905260009190848201906040850190845b8181101561163557835183529284019291840191600101611619565b50909695505050505050565b6020808252825182820181905260009190848201906040850190845b818110156116355783516001600160a01b03168352928401929184019160010161165d565b63ffffffff841681528260208201526060604082015260006116a76060830184611566565b95945050505050565b634e487b7160e01b600052603260045260246000fd5b600181811c908216806116da57607f821691505b6020821081036116fa57634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052601160045260246000fd5b60006001820161172857611728611700565b5060010190565b8082018082111561174257611742611700565b9291505056fea2646970667358221220cee723f5b245dbb04101be549f57bd984bbef2c5cc3ba051b2e67963dc5d7f5064736f6c63430008130033a26469706673582212201546f0ec101707b6f32db8bca1db12545af7ddf97a47bcd84c76a3bf7de2f05d64736f6c63430008130033"

// MockDisputeGameFactory3MetaData contains all meta data concerning the MockDisputeGameFactory3 contract.
var MockDisputeGameFactory3MetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"create\",\"inputs\":[{\"name\":\"_gameType\",\"type\":\"uint32\",\"internalType\":\"GameType\"},{\"name\":\"_rootClaim\",\"type\":\"bytes32\",\"internalType\":\"Claim\"},{\"name\":\"_extraData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"game\",\"type\":\"address\",\"internalType\":\"contract IDisputeGame\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"gameRegistry\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"games\",\"inputs\":[{\"name\":\"_gameType\",\"type\":\"uint32\",\"internalType\":\"GameType\"},{\"name\":\"_rootClaim\",\"type\":\"bytes32\",\"internalType\":\"Claim\"},{\"name\":\"_extraData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"proxy\",\"type\":\"address\",\"internalType\":\"contract IDisputeGame\"},{\"name\":\"timestamp\",\"type\":\"uint64\",\"internalType\":\"Timestamp\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"DisputeGameCreated\",\"inputs\":[{\"name\":\"game\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"gameType\",\"type\":\"uint32\",\"indexed\":true,\"internalType\":\"GameType\"},{\"name\":\"rootClaim\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"Claim\"}],\"anonymous\":false}]",
	Bin: MockDisputeGameFactory3Bin,
}

// MockDisputeGameFactory3ABI is the input ABI used to generate the binding from.
const MockDisputeGameFactory3ABI = "[{\"type\":\"function\",\"name\":\"create\",\"inputs\":[{\"name\":\"_gameType\",\"type\":\"uint32\",\"internalType\":\"GameType\"},{\"name\":\"_rootClaim\",\"type\":\"bytes32\",\"internalType\":\"Claim\"},{\"name\":\"_extraData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"game\",\"type\":\"address\",\"internalType\":\"contract IDisputeGame\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"gameRegistry\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"games\",\"inputs\":[{\"name\":\"_gameType\",\"type\":\"uint32\",\"internalType\":\"GameType\"},{\"name\":\"_rootClaim\",\"type\":\"bytes32\",\"internalType\":\"Claim\"},{\"name\":\"_extraData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"proxy\",\"type\":\"address\",\"internalType\":\"contract IDisputeGame\"},{\"name\":\"timestamp\",\"type\":\"uint64\",\"internalType\":\"Timestamp\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"DisputeGameCreated\",\"inputs\":[{\"name\":\"game\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"gameType\",\"type\":\"uint32\",\"indexed\":true,\"internalType\":\"GameType\"},{\"name\":\"rootClaim\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"Claim\"}],\"anonymous\":false}]"

// DeployMockDisputeGameFactory3 deploys a new Ethereum contract, binding an instance of MockDisputeGameFactory3 to it.
func DeployMockDisputeGameFactory3(auth *bind.TransactOpts, backend bind.ContractBackend) (common.Address, *types.Transaction, *MockDisputeGameFactory3, error) {
	parsed, err := abi.JSON(strings.NewReader(MockDisputeGameFactory3ABI))
	if err != nil {
		return common.Address{}, nil, nil, err
	}

	address, tx, contract, err := bind.DeployContract(auth, parsed, common.FromHex(MockDisputeGameFactory3Bin), backend)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &MockDisputeGameFactory3{MockDisputeGameFactory3Caller: MockDisputeGameFactory3Caller{contract: contract}, MockDisputeGameFactory3Transactor: MockDisputeGameFactory3Transactor{contract: contract}, MockDisputeGameFactory3Filterer: MockDisputeGameFactory3Filterer{contract: contract}}, nil
}

// MockDisputeGameFactory3 is an auto generated Go binding around an Ethereum contract.
type MockDisputeGameFactory3 struct {
	MockDisputeGameFactory3Caller     // Read-only binding to the contract
	MockDisputeGameFactory3Transactor // Write-only binding to the contract
	MockDisputeGameFactory3Filterer   // Log filterer for contract events
}

// MockDisputeGameFactory3Caller is an auto generated read-only Go binding around an Ethereum contract.
type MockDisputeGameFactory3Caller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockDisputeGameFactory3Transactor is an auto generated write-only Go binding around an Ethereum contract.
type MockDisputeGameFactory3Transactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockDisputeGameFactory3Filterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MockDisputeGameFactory3Filterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockDisputeGameFactory3Session is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MockDisputeGameFactory3Session struct {
	Contract     *MockDisputeGameFactory3 // Generic contract binding to set the session for
	CallOpts     bind.CallOpts            // Call options to use throughout this session
	TransactOpts bind.TransactOpts        // Transaction auth options to use throughout this session
}

// MockDisputeGameFactory3CallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MockDisputeGameFactory3CallerSession struct {
	Contract *MockDisputeGameFactory3Caller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts                  // Call options to use throughout this session
}

// MockDisputeGameFactory3TransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MockDisputeGameFactory3TransactorSession struct {
	Contract     *MockDisputeGameFactory3Transactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts                  // Transaction auth options to use throughout this session
}

// MockDisputeGameFactory3Raw is an auto generated low-level Go binding around an Ethereum contract.
type MockDisputeGameFactory3Raw struct {
	Contract *MockDisputeGameFactory3 // Generic contract binding to access the raw methods on
}

// MockDisputeGameFactory3CallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MockDisputeGameFactory3CallerRaw struct {
	Contract *MockDisputeGameFactory3Caller // Generic read-only contract binding to access the raw methods on
}

// MockDisputeGameFactory3TransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MockDisputeGameFactory3TransactorRaw struct {
	Contract *MockDisputeGameFactory3Transactor // Generic write-only contract binding to access the raw methods on
}

// NewMockDisputeGameFactory3 creates a new instance of MockDisputeGameFactory3, bound to a specific deployed contract.
func NewMockDisputeGameFactory3(address common.Address, backend bind.ContractBackend) (*MockDisputeGameFactory3, error) {
	contract, err := bindMockDisputeGameFactory3(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MockDisputeGameFactory3{MockDisputeGameFactory3Caller: MockDisputeGameFactory3Caller{contract: contract}, MockDisputeGameFactory3Transactor: MockDisputeGameFactory3Transactor{contract: contract}, MockDisputeGameFactory3Filterer: MockDisputeGameFactory3Filterer{contract: contract}}, nil
}

// NewMockDisputeGameFactory3Caller creates a new read-only instance of MockDisputeGameFactory3, bound to a specific deployed contract.
func NewMockDisputeGameFactory3Caller(address common.Address, caller bind.ContractCaller) (*MockDisputeGameFactory3Caller, error) {
	contract, err := bindMockDisputeGameFactory3(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MockDisputeGameFactory3Caller{contract: contract}, nil
}

// NewMockDisputeGameFactory3Transactor creates a new write-only instance of MockDisputeGameFactory3, bound to a specific deployed contract.
func NewMockDisputeGameFactory3Transactor(address common.Address, transactor bind.ContractTransactor) (*MockDisputeGameFactory3Transactor, error) {
	contract, err := bindMockDisputeGameFactory3(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MockDisputeGameFactory3Transactor{contract: contract}, nil
}

// NewMockDisputeGameFactory3Filterer creates a new log filterer instance of MockDisputeGameFactory3, bound to a specific deployed contract.
func NewMockDisputeGameFactory3Filterer(address common.Address, filterer bind.ContractFilterer) (*MockDisputeGameFactory3Filterer, error) {
	contract, err := bindMockDisputeGameFactory3(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MockDisputeGameFactory3Filterer{contract: contract}, nil
}

// bindMockDisputeGameFactory3 binds a generic wrapper to an already deployed contract.
func bindMockDisputeGameFactory3(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(MockDisputeGameFactory3ABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3Raw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockDisputeGameFactory3.Contract.MockDisputeGameFactory3Caller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3Raw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockDisputeGameFactory3.Contract.MockDisputeGameFactory3Transactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3Raw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockDisputeGameFactory3.Contract.MockDisputeGameFactory3Transactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3CallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockDisputeGameFactory3.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3TransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockDisputeGameFactory3.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3TransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockDisputeGameFactory3.Contract.contract.Transact(opts, method, params...)
}

// GameRegistry is a free data retrieval call binding the contract method.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3Caller) GameRegistry(opts *bind.CallOpts, key [32]byte) (common.Address, error) {
	var out []interface{}
	err := _MockDisputeGameFactory3.contract.Call(opts, &out, "gameRegistry", key)
	if err != nil {
		return *new(common.Address), err
	}
	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	return out0, err
}

// Games is a free data retrieval call binding the contract method.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3Caller) Games(opts *bind.CallOpts, _gameType uint32, _rootClaim [32]byte, _extraData []byte) (struct {
	Proxy     common.Address
	Timestamp uint64
}, error) {
	var out []interface{}
	err := _MockDisputeGameFactory3.contract.Call(opts, &out, "games", _gameType, _rootClaim, _extraData)

	outstruct := new(struct {
		Proxy     common.Address
		Timestamp uint64
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Proxy = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.Timestamp = *abi.ConvertType(out[1], new(uint64)).(*uint64)

	return *outstruct, err
}

// Create is a paid mutator transaction binding the contract method.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3Transactor) Create(opts *bind.TransactOpts, _gameType uint32, _rootClaim [32]byte, _extraData []byte) (*types.Transaction, error) {
	return _MockDisputeGameFactory3.contract.Transact(opts, "create", _gameType, _rootClaim, _extraData)
}

// MockDisputeGameFactory3DisputeGameCreatedIterator is returned from FilterDisputeGameCreated and is used to iterate over the raw logs and unpacked data for DisputeGameCreated events raised by the MockDisputeGameFactory3 contract.
type MockDisputeGameFactory3DisputeGameCreatedIterator struct {
	Event *MockDisputeGameFactory3DisputeGameCreated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event.
func (it *MockDisputeGameFactory3DisputeGameCreatedIterator) Next() bool {
	if it.fail != nil {
		return false
	}
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockDisputeGameFactory3DisputeGameCreated)
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
		it.Event = new(MockDisputeGameFactory3DisputeGameCreated)
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
func (it *MockDisputeGameFactory3DisputeGameCreatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process.
func (it *MockDisputeGameFactory3DisputeGameCreatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockDisputeGameFactory3DisputeGameCreated represents a DisputeGameCreated event raised by the MockDisputeGameFactory3 contract.
type MockDisputeGameFactory3DisputeGameCreated struct {
	Game      common.Address
	GameType  uint32
	RootClaim [32]byte
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterDisputeGameCreated is a free log retrieval operation binding the contract event.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3Filterer) FilterDisputeGameCreated(opts *bind.FilterOpts, game []common.Address, gameType []uint32) (*MockDisputeGameFactory3DisputeGameCreatedIterator, error) {
	var gameRule []interface{}
	for _, gameItem := range game {
		gameRule = append(gameRule, gameItem)
	}
	var gameTypeRule []interface{}
	for _, gameTypeItem := range gameType {
		gameTypeRule = append(gameTypeRule, gameTypeItem)
	}

	logs, sub, err := _MockDisputeGameFactory3.contract.FilterLogs(opts, "DisputeGameCreated", gameRule, gameTypeRule)
	if err != nil {
		return nil, err
	}
	return &MockDisputeGameFactory3DisputeGameCreatedIterator{contract: _MockDisputeGameFactory3.contract, event: "DisputeGameCreated", logs: logs, sub: sub}, nil
}

// WatchDisputeGameCreated is a free log subscription operation binding the contract event.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3Filterer) WatchDisputeGameCreated(opts *bind.WatchOpts, sink chan<- *MockDisputeGameFactory3DisputeGameCreated, game []common.Address, gameType []uint32) (event.Subscription, error) {
	var gameRule []interface{}
	for _, gameItem := range game {
		gameRule = append(gameRule, gameItem)
	}
	var gameTypeRule []interface{}
	for _, gameTypeItem := range gameType {
		gameTypeRule = append(gameTypeRule, gameTypeItem)
	}

	logs, sub, err := _MockDisputeGameFactory3.contract.WatchLogs(opts, "DisputeGameCreated", gameRule, gameTypeRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				event := new(MockDisputeGameFactory3DisputeGameCreated)
				if err := _MockDisputeGameFactory3.contract.UnpackLog(event, "DisputeGameCreated", log); err != nil {
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

// ParseDisputeGameCreated is a log parse operation binding the contract event.
func (_MockDisputeGameFactory3 *MockDisputeGameFactory3Filterer) ParseDisputeGameCreated(log types.Log) (*MockDisputeGameFactory3DisputeGameCreated, error) {
	event := new(MockDisputeGameFactory3DisputeGameCreated)
	if err := _MockDisputeGameFactory3.contract.UnpackLog(event, "DisputeGameCreated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
