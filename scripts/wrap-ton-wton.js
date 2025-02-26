const hre = require("hardhat");


const Web3EthAbi = require('web3-eth-abi');
const Ton_Json = require( '../test/abi/TON.json')
const Wton_Json = require( '../test/abi/WTON.json')

const { ethers } = hre;

    // mainnet
    let ton = '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5'
    let wton = '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2'
    let swapProxy = '0x30e65B3A6e6868F044944Aa0e9C5d52F8dcb138d'

    // sepolia
    // let ton = '0xa30fe40285b8f5c0457dbc3b7c8a280373c40044'
    // let wton = '0x79e0d92670106c85e9067b56b8f674340dca0bbd	'
    // let swapProxy = '0x690f994b82f001059e24d79292c3c476854b767a'

    async function wrap(){
      const [deployer] = await ethers.getSigners();

      let tonContract = new ethers.Contract(ton, Ton_Json.abi, deployer)
      // let wtonContract = new ethers.Contract(wton, Wton_Json, deployer)
      let tonAmount = ethers.BigNumber.from("1000000000000000000")

      // TON애 호출하는 함수 : 톤을 승인하고, spender의 onApprove를 호출합니다 .
      // function approveAndCall(address spender, uint256 amount, bytes memory data) public returns (bool) {


      // WTON 에서 호출하는 함수 :  swapProxy 컨트랙 호출, 아무일도 안하는 컨트랙
      const data = Web3EthAbi.encodeParameters(
          ["address", "address"],
          [swapProxy, swapProxy]
      )

      const functionBytecode = tonContract.interface.encodeFunctionData("approveAndCall",
        [
          wton,  // spender
          tonAmount,   // amount
          data,
        ]
      )

      console.log(functionBytecode)

    }

  async function main() {

    await wrap()
  }

  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
