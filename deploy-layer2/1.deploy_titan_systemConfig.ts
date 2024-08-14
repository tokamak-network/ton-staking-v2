import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from "hardhat-deploy/types";

import { LegacySystemConfig } from "../typechain-types/contracts/layer2/LegacySystemConfig"

const deployTitanSystemConfig: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)
    const { deployer, titanL2TON } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const deploySigner = await hre.ethers.getSigner(deployer);
    console.log(deployer)

    if (hre.network.name == "hardhat" || hre.network.name == "local") {

        await hre.network.provider.send("hardhat_setBalance", [
            deployer,
            "0x10000000000000000000000000",
          ]);
    }

    const deployedSimpleStakingV2 = await hre.deployments.get("L1BridgeRegistryProxy");

    const name = "Titan_Test1"
    let l2Ton = titanL2TON
    let l1BridgeRegistry = deployedSimpleStakingV2.address

    //==== LegacySystemConfig =================================
     const LegacySystemConfigDeployment = await deploy("LegacySystemConfig", {
        from: deployer,
        args: [],
        log: true
    });

    const {
        titanL1StandardBridge,
        titanL1CrossDomainMessenger,
        titanL1ERC721Bridge,
        titanL2OutputOracle,
        titanOptimismPortal,
        titanOptimismMintableERC20Factory } = await hre.getNamedAccounts();

    const legacySystemConfig = (await hre.ethers.getContractAt(
        LegacySystemConfigDeployment.abi,
        LegacySystemConfigDeployment.address
    )) as LegacySystemConfig;

    let addesses = {
        l1CrossDomainMessenger: titanL1CrossDomainMessenger,
        l1ERC721Bridge: titanL1ERC721Bridge,
        l1StandardBridge: titanL1StandardBridge,
        l2OutputOracle: titanL2OutputOracle,
        optimismPortal: titanOptimismPortal,
        optimismMintableERC20Factory: titanOptimismMintableERC20Factory,
    }

    let l1CrossDomainMessenger = await legacySystemConfig.l1CrossDomainMessenger()
    if (l1CrossDomainMessenger != addesses.l1CrossDomainMessenger) {
        await (await legacySystemConfig.connect(deploySigner).setAddresses(
            name,
            addesses,
            l2Ton,
            l1BridgeRegistry
        )).wait()
    }
}

export default deployTitanSystemConfig;
deployTitanSystemConfig.tags = ['TitanSystemConfig'];