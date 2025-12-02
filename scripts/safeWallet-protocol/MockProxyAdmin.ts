import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const MockProxyAdmin = await ethers.getContractFactory("MockProxyAdmin");
    const mockProxyAdmin = await MockProxyAdmin.deploy();

    await mockProxyAdmin.deployed();

    console.log("MockProxyAdmin deployed to:", mockProxyAdmin.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
