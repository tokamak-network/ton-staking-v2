const { ethers } = require("hardhat");
const DepositManagerV1_1_Json = require('../../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')
const L1BridgeRegistryV1_1_Json = require('../../artifacts/contracts/layer2/L1BridgeRegistryV1_1.sol/L1BridgeRegistryV1_1.json')
const Layer2ManagerV1_1_Json = require('../../artifacts/contracts/layer2/Layer2ManagerV1_1.sol/Layer2ManagerV1_1.json')
const SeigManager_Json = require('../../test/abi/SeigManagerV1.json')

const tester = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";

async function rejectCandidates() {

    console.log('\n==== rejectCandidates ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    let deployerAddress = await deployer.getAddress()

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     tester,
    // ]);
    // await hre.network.provider.send("hardhat_setBalance", [
    //     tester,
    //     "0x10000000000000000000000000",
    // ]);
    // deployer = await hre.ethers.getSigner(tester);
    // deployerAddress = tester

    // console.log('deployer ', deployerAddress)
    let L1BridgeRegistryProxyOldAddress = "0x58813D18b019F670d43be0D80Af968C99cc82c05"
    let Layer2ManagerOldAddress = "0x0fDb12aF5Fece558d17237E2D252EC5dbA25396b"
    let SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
    let seigniorageCommitteeAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
    let TitanSepolia = "0x1cA73f6E80674E571dc7a8128ba370b8470D4D87"
    let ThanosSepolia = "0xB8209Cc81f0A8Ccdb09238bB1313A039e6BFf741"
    let TokamakArbitrum = "0x78907DE91f579945762c69B0A200564F0BB1E0bE"
    let DemoStakingv2 = "0x95d8AA4C202D469b1A75dc1294D92e0002FD0c1b"
    let DemoKaiden = "0x76Ef1000AE7665f92d0310F077Ac7667399bfd6f"
    let dao_victor = "0x5aaa5d924AA373e36c80587c0726C0D8d4CC7039"

    const l1BridgeRegistryOld = new ethers.Contract(L1BridgeRegistryProxyOldAddress,  L1BridgeRegistryV1_1_Json.abi, deployer)
    const Layer2ManagerOld = new ethers.Contract(Layer2ManagerOldAddress,  Layer2ManagerV1_1_Json.abi, deployer)
    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)

    let seigniorageCommittee1 = await l1BridgeRegistryOld.seigniorageCommittee()
    // console.log('seigniorageCommittee', seigniorageCommittee1)
    await (await l1BridgeRegistryOld.connect(deployer).setSeigniorageCommittee(seigniorageCommitteeAddress)).wait()
    seigniorageCommittee1 = await l1BridgeRegistryOld.seigniorageCommittee()
    console.log('seigniorageCommittee', seigniorageCommittee1)

    let totalLayer2TVL = await seigManager.totalLayer2TVL()
    console.log('totalLayer2TVL', totalLayer2TVL)

    let rollup = TitanSepolia
    let info = await Layer2ManagerOld.rollupConfigInfo(rollup)
    if (info.status == 1) {
        await (await l1BridgeRegistryOld.connect(deployer).rejectCandidateAddOn(rollup)).wait()
        totalLayer2TVL = await seigManager.totalLayer2TVL()
        // console.log('totalLayer2TVL reject TitanSepolia', totalLayer2TVL)
    }

    // =========
    rollup = ThanosSepolia
    info = await Layer2ManagerOld.rollupConfigInfo(rollup)
    if (info.status == 1) {
        await (await l1BridgeRegistryOld.connect(deployer).rejectCandidateAddOn(rollup)).wait()
        totalLayer2TVL = await seigManager.totalLayer2TVL()
        // console.log('totalLayer2TVL reject ThanosSepolia', totalLayer2TVL)
    }
    // =========
    rollup = TokamakArbitrum
    info = await Layer2ManagerOld.rollupConfigInfo(rollup)
    if (info.status == 1) {
        await (await l1BridgeRegistryOld.connect(deployer).rejectCandidateAddOn(rollup)).wait()

        totalLayer2TVL = await seigManager.totalLayer2TVL()
        // console.log('totalLayer2TVL reject TokamakArbitrum', totalLayer2TVL)
    }

    // =========
    rollup = DemoStakingv2
    info = await Layer2ManagerOld.rollupConfigInfo(rollup)

    if (info.status == 1) {
        await (await l1BridgeRegistryOld.connect(deployer).rejectCandidateAddOn(rollup)).wait()

        totalLayer2TVL = await seigManager.totalLayer2TVL()
        // console.log('totalLayer2TVL reject DemoStakingv2', totalLayer2TVL)
    }

    rollup = DemoKaiden
    info = await Layer2ManagerOld.rollupConfigInfo(rollup)

    if (info.status == 1) {
        await (await l1BridgeRegistryOld.connect(deployer).rejectCandidateAddOn(rollup)).wait()
        totalLayer2TVL = await seigManager.totalLayer2TVL()
        // console.log('totalLayer2TVL reject DemoKaiden', totalLayer2TVL)
    }

    rollup = dao_victor
    info = await Layer2ManagerOld.rollupConfigInfo(rollup)
    if (info.status == 1) {
        await (await l1BridgeRegistryOld.connect(deployer).rejectCandidateAddOn(rollup)).wait()
        totalLayer2TVL = await seigManager.totalLayer2TVL()
        // console.log('totalLayer2TVL reject dao_victor', totalLayer2TVL)
    }

    totalLayer2TVL = await seigManager.totalLayer2TVL()
    console.log('totalLayer2TVL', totalLayer2TVL)
    await (await l1BridgeRegistryOld.connect(deployer).setSeigniorageCommittee(ethers.constants.AddressZero)).wait()

}

async function initialze() {

    console.log('\n==== initialze ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    let deployerAddress = await deployer.getAddress()
    let SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     tester,
    // ]);
    // await hre.network.provider.send("hardhat_setBalance", [
    //     tester,
    //     "0x10000000000000000000000000",
    // ]);
    // deployer = await hre.ethers.getSigner(tester);
    // deployerAddress = tester

    // console.log('deployer ', deployerAddress)
    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)

    await (await seigManager.connect(deployer).setL1BridgeRegistry(ethers.constants.AddressZero)).wait()
    await (await seigManager.connect(deployer).setLayer2Manager(ethers.constants.AddressZero)).wait()
    await (await seigManager.connect(deployer).setLayer2StartBlock(ethers.constants.Zero)).wait()
    await (await seigManager.connect(deployer).resetL2RewardPerUint()).wait()

    console.log("layer2Manager", await seigManager.layer2Manager())
    console.log("l1BridgeRegistry", await seigManager.l1BridgeRegistry())
    console.log("layer2StartBlock", await seigManager.layer2StartBlock())
    console.log("l2RewardPerUint", await seigManager.l2RewardPerUint())
    console.log("totalLayer2TVL", await seigManager.totalLayer2TVL())

}

const main = async () => {

    await rejectCandidates()
    await initialze()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});