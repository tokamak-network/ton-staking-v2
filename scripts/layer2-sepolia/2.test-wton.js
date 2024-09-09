const { ethers } = require("hardhat");
const DepositManagerV1_1_Json = require('../../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')
const WTON_Json = require('../../test/abi/WTON.json')
const TON_Json = require('../../test/abi/TON.json')

const depositManager_address = "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"
const titan_layer_address = "0xeA2c15fdf4cE802Ba188e7D4460D979E9df5fD51"
const wton_address = "0x79e0d92670106c85e9067b56b8f674340dca0bbd"
const ton_address = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044"

async function swapFromTONAndTransfer() {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0]
    const deployerAddress = await deployer.getAddress()

    const wton = new ethers.Contract(wton_address,  WTON_Json.abi, deployer)
    const ton = new ethers.Contract(ton_address,  TON_Json.abi, deployer)

    console.log('deployer ', deployerAddress)
    console.log('wton ', wton.address)

    let balanceWton = await wton.balanceOf(deployerAddress)

    let balanceTon = await ton.balanceOf(deployerAddress)

    console.log('balanceWton ', balanceWton)

    console.log('balanceTon ', balanceTon)

    // const amount_1ton = ethers.BigNumber.from("1"+"0".repeat(28));

    // const receipt = await depositManager.connect(deployer).withdrawAndDepositL2(
    //     titan_layer_address, amount_1ton)

    // console.log(receipt)
}

const main = async () => {
  await swapFromTONAndTransfer()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});