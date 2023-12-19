import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deploySeigManagerV1: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)

    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const deploySigner = await hre.ethers.getSigner(deployer);

    // //==== DAOCommitteeOwnerTestBed =================================
    // const DAOCommitteeOwnerTestBedDeployment = await deploy("DAOCommitteeOwnerTestBed", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    //==== DAOCommitteeExtendImpl =================================

    const SeigManagerV1Deployment = await deploy("SeigManagerV1", {
        from: deployer,
        args: [],
        log: true
    });

    //==== verify =================================
    if (hre.network.name != "hardhat") {
        await hre.run("etherscan-verify", {
            network: hre.network.name
        });
    }
};

export default deploySeigManagerV1;
