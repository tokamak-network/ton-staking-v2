import Artifact__SystemConfig from  "../tasks/abi/LegacySystemConfig.json"
import { task } from 'hardhat/config'

task('create-rollup-config', 'Deploys LegacySystemConfig')
  .addParam("l1BridgeRegisterAddress", "The l1BridgeRegister Address")
  .addParam("l1CrossDomainMessengerAddress", "The l1CrossDomainMessenger Address")
  .addParam("l1StandardBridgeAddress", "The l1StandardBridge Address")
  .addParam("optimismPortalAddress", "The OptimismPortal Address")
  .addParam("name", "Your candidate's name")
  .setAction(async (taskArgs, hre) => {
    console.log(taskArgs)

    const LegacySystemConfig = await hre.ethers.getContractFactory('LegacySystemConfig')
    const systemConfig = await LegacySystemConfig.deploy()
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
    const tx = await systemConfig.setAddresses(
      taskArgs.name, addresses, taskArgs.l1BridgeRegisterAddress
    );
    await tx.wait();

    // console.log('LegacySystemConfig setAddresses :', tx.hash)

  })
