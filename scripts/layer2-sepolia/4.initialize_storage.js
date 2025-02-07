const { ethers } = require("hardhat");
const DepositManagerV1_1_Json = require('../../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')
const L1BridgeRegistryV1_1_Json = require('../../artifacts/contracts/layer2/L1BridgeRegistryV1_1.sol/L1BridgeRegistryV1_1.json')
const Layer2ManagerV1_1_Json = require('../../artifacts/contracts/layer2/Layer2ManagerV1_1.sol/Layer2ManagerV1_1.json')
const SeigManager_Json = require('../../test/abi/SeigManagerV1.json')

const tester = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
const seigniorageCommittee_ = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let seigniorageCommittee

async function rejectCandidates() {

    console.log('\n==== rejectCandidates ===== ')
    // const accounts = await ethers.getSigners()
    // let deployer = accounts[0]
    // let deployerAddress = await deployer.getAddress()

    await hre.network.provider.send("hardhat_impersonateAccount", [
        tester,
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
        tester,
        "0x10000000000000000000000000",
    ]);
    deployer = await hre.ethers.getSigner(tester);
    deployerAddress = tester

    console.log('deployer ', deployerAddress)

    //--
    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     seigniorageCommittee_,
    // ]);
    // await hre.network.provider.send("hardhat_setBalance", [
    //     seigniorageCommittee_,
    //     "0x10000000000000000000000000",
    // ]);
    // seigniorageCommittee = await hre.ethers.getSigner(seigniorageCommittee_);

    // console.log('seigniorageCommittee ', seigniorageCommittee_)

    let L1BridgeRegistryProxyOldAddress = "0x3268e4D8276c58A806E83B3B080Cf29514A837cf"
    let Layer2ManagerOldAddress = "0xab303E7CBFd19C998268e19d830770e215AbDF7F"
    let SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
    let seigniorageCommitteeAddress = tester
    let TitanSepolia = "0x501C74df1aDEb8024738D880B01306a92d6e722d"

    const l1BridgeRegistryOld = new ethers.Contract(L1BridgeRegistryProxyOldAddress,  L1BridgeRegistryV1_1_Json.abi, deployer)
    const Layer2ManagerOld = new ethers.Contract(Layer2ManagerOldAddress,  Layer2ManagerV1_1_Json.abi, deployer)
    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)

    let isAdmin = await l1BridgeRegistryOld.isAdmin(deployerAddress)
    console.log('isAdmin', isAdmin)


    let seigniorageCommittee1 = await l1BridgeRegistryOld.seigniorageCommittee()
    console.log('seigniorageCommittee', seigniorageCommittee1)

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

    totalLayer2TVL = await seigManager.totalLayer2TVL()
    console.log('totalLayer2TVL', totalLayer2TVL)
    await (await l1BridgeRegistryOld.connect(deployer).setSeigniorageCommittee(ethers.constants.AddressZero)).wait()

    seigniorageCommittee1 = await l1BridgeRegistryOld.seigniorageCommittee()
    console.log('seigniorageCommittee', seigniorageCommittee1)

}

async function initialze() {

    console.log('\n==== initialze ===== ')
    // const accounts = await ethers.getSigners()
    // let deployer = accounts[0]
    // let deployerAddress = await deployer.getAddress()
    let SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        tester,
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
        tester,
        "0x10000000000000000000000000",
    ]);
    deployer = await hre.ethers.getSigner(tester);
    deployerAddress = tester

    console.log('deployer ', deployerAddress)

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