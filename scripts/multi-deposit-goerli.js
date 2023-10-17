const hre = require("hardhat");
const { ethers } = hre;

const SeigManagerAbi = require("../abi/SeigManager.json").abi;

const WTONAbi = require("../abi/WTON.json").abi;
const DepositManagerAbi = require("../abi/DepositManager.json").abi;
const RefactorCoinageSnapshot = require("../abi/RefactorCoinageSnapshot.json").abi;
/*
[{"oldLayer":"0xaeb5675424c4bd3074ba363bfffdb0e2c0a1011b","newLayer":"0xe7B2ad512660FA25D6a48eB0Bfcf0aC330362619","operator":"0xd4335a175c36c0922f6a368b83f9f6671bf07606","name":"TokamakOperator"},
{"oldLayer":"0xc811b0eca34f154e10afba0178ca037e4fb159c4","newLayer":"0x6B883D1258F9604c82d7B459BAcf5c5EA2fa820B","operator":"0xf0b595d10a92a5a9bc3ffea7e79f5d266b6035ea","name":"ContractTeam_DAO"},
{"oldLayer":"0xa6ccdb6b2384bbf35cfb190ce41667a1f0dbdc53","newLayer":"0x40065623fEFD449CFbd6eA9070e4ADBdFcFCafF6","operator":"0x195c1d13fc588c0b1ca8a78dd5771e0ee5a2eae4","name":"ContractTeam_DAO2"}]
*/

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log('deployer', deployer.address)
    let amount = ethers.utils.parseEther("1"+"0".repeat(9))
    let allowanceAmount = ethers.utils.parseEther("10000"+"0".repeat(9))

    let WTON = '0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6'
    let seigManager = '0x8829Cb37CbbF32404B372113F9Fc3F6cd965c474'
    let depositManager = '0xA0458d8af8a25A18959b9cB607c33Bc4973f7849'
    let layer2 = '0xe7B2ad512660FA25D6a48eB0Bfcf0aC330362619' // 특정 레이어 주소

    let WTONContract = new ethers.Contract(WTON, WTONAbi, deployer)
    let DepositManagerContract = new ethers.Contract(depositManager, DepositManagerAbi, deployer)
    let SeigManagerContract = new ethers.Contract(seigManager, SeigManagerAbi, deployer)

    let balanceOfWton = await WTONContract.balanceOf(deployer.address)
    console.log('balanceOfWton', ethers.utils.formatUnits(balanceOfWton, 27), " WTON")

    let allowance = await WTONContract.allowance(deployer.address, depositManager)
    if(allowance.lt(allowanceAmount)){
      await (await WTONContract.connect(deployer).approve(depositManager,allowanceAmount)).wait()
    }

    let stakeOf = await SeigManagerContract["stakeOf(address,address)"](layer2, deployer.address)
    console.log('stakeOf', ethers.utils.formatUnits(stakeOf, 27), " WTON")


    let coinage = await SeigManagerContract.coinages(layer2)
    let coinagesContract = new ethers.Contract(coinage, RefactorCoinageSnapshot, deployer)

    let balanceOfAddr1 = await coinagesContract.balanceOf(deployer.address)
    console.log('balanceOfAddr1', ethers.utils.formatUnits(balanceOfAddr1, 27), " WTON")


    let accounts =[]
    let amounts = []

    for(let i = 0; i< 40 ; i++) {
      accounts.push(deployer.address)
      amounts.push(amount)
    }

    // 갖고 있는 잔액의 절반을 없앰
    await (await DepositManagerContract.connect(deployer)["deposit(address,address[],uint256[])"](
      layer2,
      accounts,
      amounts)
    ).wait()

    let balanceOfAddr2 = await coinagesContract.balanceOf(deployer.address)
    console.log('balanceOfAddr2', ethers.utils.formatUnits(balanceOfAddr2, 27), " WTON")

    let stakeOf2 = await SeigManagerContract["stakeOf(address,address)"](layer2, deployer.address)
    console.log('stakeOf', ethers.utils.formatUnits(stakeOf2, 27), " WTON")
    // npx hardhat node --fork https://mainnet.infura.io/v3/e4b3b2781dd34bc4817a1221b8a3b50a  --fork-block-number 9880271


  }

  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
