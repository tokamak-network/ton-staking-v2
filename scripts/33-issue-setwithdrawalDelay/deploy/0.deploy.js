const { ethers } = require("hardhat");

async function deployDepositManager_setWithdrawalDelay() {

    const DepositManager_setWithdrawalDelayDep = await ethers.getContractFactory("DepositManager_setWithdrawalDelay");
    const DepositManager_setWithdrawalDelay = await DepositManager_setWithdrawalDelayDep.deploy();
    await DepositManager_setWithdrawalDelay.deployed()

    // console.log('tx' , tx)
    console.log('DepositManager_setWithdrawalDelay' , DepositManager_setWithdrawalDelay.address)

}

const main = async () => {
  await deployDepositManager_setWithdrawalDelay()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});