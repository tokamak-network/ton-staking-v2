import '@nomiclabs/hardhat-ethers'
import { ethers } from 'ethers'
import { task, types } from 'hardhat/config'
// import { HardhatRuntimeEnvironment } from 'hardhat/types'
import L1BridgeRegistryV1_1_ABI from "./abi/L1BridgeRegistryV1_1.json"
import Layer2ManagerV1_1_ABI from "./abi/Layer2ManagerV1_1.json"
import TON_ABI from "./abi/TON.json"
import CandidateAddOn_ABI from "./abi/CandidateAddOnV1_1.json"
import OperatorManager_ABI from "./abi/OperatorManagerV1_1.json"

task("l1bridge-register-rollup-config-manager", "Register RollupConfig by onlyManager")
  .addParam("l1BridgeRegisterAddress", "The l1BridgeRegister Address")
  .addParam("rollupConfig", "The RollupConfig Address")
  .addParam("type", "type, 0: legacy, 1: bedrock ton native token")
  .addParam("l2Ton", "L2 TON Address")
  .setAction(async (taskArgs, hre) => {
    console.log(taskArgs)

    const [deployer] = await hre.ethers.getSigners()
    console.log('deployer: ',deployer.address)

    const l1BridgeRegister  = new ethers.Contract(
      taskArgs.l1BridgeRegisterAddress, L1BridgeRegistryV1_1_ABI.abi, hre.ethers.provider)

    const tx = await l1BridgeRegister.connect(deployer).registerRollupConfigByManager(
      taskArgs.rollupConfig, taskArgs.type, taskArgs.l2Ton
    );

    console.log('registerRollupConfigByManager tx: ',tx.hash)
    await tx.wait();

    const rollupType = await l1BridgeRegister.rollupType( taskArgs.rollupConfig );
    const l1Bridge = await l1BridgeRegister.l1Bridge( taskArgs.rollupConfig );
    const portal = await l1BridgeRegister.portal( taskArgs.rollupConfig );
    const l2TON = await l1BridgeRegister.rollupType( taskArgs.rollupConfig );

    console.log('l1Bridge   : ',l1Bridge)
    console.log('rollupType : ', rollupType)
    console.log('l2TON      : ', l2TON)
    console.log('portal     : ',portal)

  });


task("l1bridge-register-rollup-config", "Register RollupConfig")
  .addParam("l1BridgeRegisterAddress", "The l1BridgeRegister Address")
  .addParam("rollupConfig", "The RollupConfig Address")
  .addParam("type", "type, 0: legacy, 1: bedrock ton native token")
  .addParam("l2Ton", "L2 TON Address")
  .setAction(async (taskArgs, hre) => {
    console.log(taskArgs)

      const [deployer] = await hre.ethers.getSigners()
      console.log('deployer: ',deployer.address)

    const l1BridgeRegister  = new ethers.Contract(
      taskArgs.l1BridgeRegisterAddress, L1BridgeRegistryV1_1_ABI.abi,  hre.ethers.provider)

    const tx = await l1BridgeRegister.registerRollupConfigByManager(
      taskArgs.rollupConfig, taskArgs.type, taskArgs.l2Ton
    );

    console.log('tx: ',tx)

    await tx.wait();
});


task("rollup-config-create-and-register", "Register RollupConfig by onlyManager")
  .addParam("l1BridgeRegisterAddress", "The l1BridgeRegister Address")
  .addParam("l1CrossDomainMessengerAddress", "The l1CrossDomainMessenger Address")
  .addParam("l1StandardBridgeAddress", "The l1StandardBridge Address")
  .addParam("optimismPortalAddress", "The OptimismPortal Address")
  .addParam("type", "type, 0: legacy, 1: bedrock ton native token")
  .addParam("l2Ton", "L2 TON Address")
  .addParam("name", "Your candidate's name")
  .addParam("amount", "transferred amount, it must be greater than 1000.1 TON")
  .addParam("tonAddress", "The TON Address")
  .addParam("layer2ManagerAddress", "The Layer2Manager Address")
  .setAction(async (taskArgs, hre) => {
    console.log(taskArgs)

    let tonMinterAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
    let tonHaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
    await hre.network.provider.send("hardhat_impersonateAccount", [
      tonHaveAddr,
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
      tonHaveAddr,
        "0x10000000000000000000000000",
    ]);
    await hre.network.provider.send("hardhat_impersonateAccount", [
      tonMinterAddress,
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
        tonMinterAddress,
        "0x10000000000000000000000000",
    ]);
    const tonMinter = await hre.ethers.getSigner(tonMinterAddress);
    const deployer = await hre.ethers.getSigner(tonHaveAddr);


    // const [deployer] = await hre.ethers.getSigners()
    // console.log('deployer: ',deployer.address)
    // const tonMinter = deployer

    const LegacySystemConfig = await hre.ethers.getContractFactory('LegacySystemConfig')
    const systemConfig = await LegacySystemConfig.connect(deployer).deploy()
    await systemConfig.deployed()
    console.log('LegacySystemConfig deployed to:', systemConfig.address)

    let addresses = {
        l1CrossDomainMessenger: taskArgs.l1CrossDomainMessengerAddress,
        l1ERC721Bridge: hre.ethers.constants.AddressZero,
        l1StandardBridge: taskArgs.l1StandardBridgeAddress,
        l2OutputOracle: hre.ethers.constants.AddressZero,
        optimismPortal: taskArgs.optimismPortalAddress,
        optimismMintableERC20Factory: hre.ethers.constants.AddressZero
    }

    const tx1 = await systemConfig.connect(deployer).setAddresses(
      taskArgs.name, addresses, taskArgs.l1BridgeRegisterAddress
    );
    await tx1.wait();

    //-----------------------
    const l1BridgeRegister  = new ethers.Contract(
      taskArgs.l1BridgeRegisterAddress, L1BridgeRegistryV1_1_ABI.abi, deployer)

    const tx = await l1BridgeRegister.connect(tonMinter).registerRollupConfigByManager(
      systemConfig.address, taskArgs.type, taskArgs.l2Ton
    );

    console.log('registerRollupConfigByManager tx: ',tx.hash)
    await tx.wait();

    const l1StandardBridge = await systemConfig.l1StandardBridge();
    console.log('l1StandardBridge   : ',l1StandardBridge)

    const optimismPortal = await systemConfig.optimismPortal();
    console.log('optimismPortal   : ',optimismPortal)

    const l1CrossDomainMessenger = await systemConfig.l1CrossDomainMessenger();
    console.log('l1CrossDomainMessenger   : ',l1CrossDomainMessenger)

    //-----------------------
    const rollupConfig = systemConfig.address

    const rollupType = await l1BridgeRegister.rollupType(systemConfig.address);
      console.log('rollupType   : ',rollupType)

    const l1Bridge = await l1BridgeRegister.connect(deployer).l1Bridge(l1StandardBridge);
    console.log('l1Bridge   : ',l1Bridge)

    const portal = await l1BridgeRegister.connect(deployer).portal(optimismPortal);
    console.log('portal     : ',portal)

    const l2TON = await l1BridgeRegister.connect(deployer).l2TON( rollupConfig );
    console.log('l2TON      : ', l2TON)


    //--------------------------
    const amount = ethers.BigNumber.from(taskArgs.amount)

    const layer2Manager  = new ethers.Contract(taskArgs.layer2ManagerAddress, Layer2ManagerV1_1_ABI.abi, deployer)
    const ton  = new ethers.Contract(taskArgs.tonAddress, TON_ABI.abi,  deployer)
    const minAmount = await layer2Manager.minimumInitialDepositAmount();

    if (amount.lt(minAmount)) {
      console.log("The amount value must be greater than ", ethers.utils.formatEther(minAmount) ," TON" );
      return;
    }

    const balanceTon = await ton.balanceOf(deployer.address)
    if (balanceTon.lt(amount)) {
      console.log("Your TON Balance is insufficient." );
      return;
    }

    let allowance = await ton.allowance(deployer.address, layer2Manager.address)
    if(allowance.lt(amount)){
      await (await ton.connect(deployer).approve(layer2Manager.address, amount)).wait()
    }

    const tx2 = await layer2Manager.connect(deployer).registerCandidateAddOn(
      rollupConfig, amount, true, taskArgs.name
    );
    console.log('registerCandidateAddOn tx: ',tx2.hash)
    const receipt = await tx2.wait();

  const topic = layer2Manager.interface.getEventTopic('RegisteredCandidateAddOn');
  const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
  const deployedEvent = layer2Manager.interface.parseLog(log);
  const candidateAddOnAddress = deployedEvent.args.candidateAddOn
  const candidateAddOn  = new ethers.Contract(candidateAddOnAddress, CandidateAddOn_ABI.abi,  deployer)
  const operatorManagerAddress = await candidateAddOn.operator()
  const operatorManager  = new ethers.Contract(operatorManagerAddress, OperatorManager_ABI.abi,  deployer)
  const manager  = await operatorManager.manager()

  console.log('rollupConfig     : ', deployedEvent.args.rollupConfig)
  console.log('candidateAddOn   : ', candidateAddOnAddress)
  console.log('operatorManager  : ', operatorManagerAddress)
  console.log('operatorManager\'s manager  : ', manager)

});

