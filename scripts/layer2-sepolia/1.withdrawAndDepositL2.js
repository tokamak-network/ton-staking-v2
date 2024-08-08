const { ethers } = require("hardhat");
const DepositManagerV1_1_Json = require('../../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')

const depositManager_address = "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"
const titan_layer_address = "0xeA2c15fdf4cE802Ba188e7D4460D979E9df5fD51"

async function withdrawAndDepositL2() {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0]
    const deployerAddress = await deployer.getAddress()

    console.log('deployer ', deployerAddress)

    const depositManager = new ethers.Contract(depositManager_address,  DepositManagerV1_1_Json.abi, deployer)

    const amount_1ton = ethers.BigNumber.from("1"+"0".repeat(28));

    const receipt = await depositManager.connect(deployer).withdrawAndDepositL2(
        titan_layer_address, amount_1ton)

    console.log(receipt)
}

const main = async () => {
  await withdrawAndDepositL2()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});