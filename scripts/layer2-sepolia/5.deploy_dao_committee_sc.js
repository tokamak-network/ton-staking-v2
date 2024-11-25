const { ethers } = require("hardhat");
const { encodeFunctionSignature } = require("web3-eth-abi");

const DAOCommitteeProxy2_Json = require('../../test/abi/DAOCommitteeProxy2.json')
const DAOCommittee_SecurityCouncil_Json = require('../../test/abi/DAOCommittee_SecurityCouncil.json')

// sepolia
const depositManagerProxy_address = "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"
const dao_address = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
const dao_logic_index = 2
const TokamakTimelockController_address = "0x079cC994fA06C916bA74a5714B6f7672Bd6F7567"
const SecurityCouncil_address = "0xb62Cff55292EC561e76B823ce126A806874a392E"
const adminAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"

async function deployDAOCommittee_SecurityCouncil() {

    const accounts = await ethers.getSigners()
    const deployer = accounts[0]
    const deployerAddress = await deployer.getAddress()

    console.log("deployer", deployerAddress)
    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     adminAddress,
    // ]);
    // await hre.network.provider.send("hardhat_setBalance", [
    //     adminAddress,
    //     "0x10000000000000000000000000",
    // ]);
    // deployer = await hre.ethers.getSigner(adminAddress);

    const daoProxy = new ethers.Contract(dao_address,  DAOCommitteeProxy2_Json.abi, deployer)

    //==== DAOCommittee_SecurityCouncil =================================
    // const DAOCommittee_SecurityCouncilDep = await ethers.getContractFactory("DAOCommittee_SecurityCouncil");
    // const DAOCommittee_SecurityCouncil = await DAOCommittee_SecurityCouncilDep.deploy();
    // await DAOCommittee_SecurityCouncil.deployed()

    // // console.log('tx' , tx)
    // console.log('DAOCommittee_SecurityCouncil' , DAOCommittee_SecurityCouncil.address)
    // const DAOCommittee_SecurityCouncil_address = DAOCommittee_SecurityCouncil.address
    const DAOCommittee_SecurityCouncil_address = "0xDB86F93e01ba0424aEECfA2C1D87680a5614d8d2"
    const selector1 = encodeFunctionSignature("setSecurityCouncil(address)");
    const selector2 = encodeFunctionSignature("setTimelockController(address)");
    const selector3 = encodeFunctionSignature("timelockController()");
    const selector4 = encodeFunctionSignature("securityCouncil()");
    const selector5 = encodeFunctionSignature("executeTransactions(address[],bytes[],uint256[])");
    const selector6 = encodeFunctionSignature("executeTransaction(address,bytes,uint256)");

    const selectors = [selector1,selector2,selector3,selector4,selector5,selector6]
    console.log('selectors', selectors)
    await (await daoProxy.connect(deployer).setImplementation2(
        DAOCommittee_SecurityCouncil_address,
        dao_logic_index,
        true)
    ).wait()

    await (await daoProxy.connect(deployer).setSelectorImplementations2(
        selectors,
        DAOCommittee_SecurityCouncil_address)
    ).wait()

    let selectorLogic = await daoProxy.selectorImplementation(selector3)
    console.log('timelockController() logic', selectorLogic)

    const daoSC = new ethers.Contract(dao_address,  DAOCommittee_SecurityCouncil_Json.abi, deployer)

    await (await daoSC.connect(deployer).setTimelockController(TokamakTimelockController_address)).wait()
    await (await daoSC.connect(deployer).setSecurityCouncil(SecurityCouncil_address)).wait()

    let timelockController = await daoSC.timelockController()
    console.log('timelockController', timelockController)
    let securityCouncil = await daoSC.securityCouncil()
    console.log('securityCouncil', securityCouncil)
}

const main = async () => {
  await deployDAOCommittee_SecurityCouncil()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
