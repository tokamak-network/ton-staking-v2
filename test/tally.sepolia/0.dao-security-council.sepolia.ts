import hre from 'hardhat'
import { expect } from '../shared/expect'
import { ethers, network } from 'hardhat'
import { BigNumber, Signer } from 'ethers'
import { mine } from "@nomicfoundation/hardhat-network-helpers"
import { encodeFunctionSignature } from "web3-eth-abi";
import { DAOCommittee_SecurityCouncil } from "../../typechain-types/contracts/dao/DAOCommittee_SecurityCouncil"

import {
    daoSepoliaFixture,
        lastSeigBlock,
        globalWithdrawalDelay,
        seigManagerInfo,
        jsonFixtures } from '../shared/fixtures'

import { DaoFixtures, JSONFixture } from '../shared/fixtureInterfaces'
import { padLeft } from 'web3-utils'
import { marshalString, unmarshalString } from '../shared/marshal';
const DAOVault_ABI = [
    {"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"claimERC20","outputs":[],"stateMutability":"nonpayable","type":"function"},
    {"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"claimTON","outputs":[],"stateMutability":"nonpayable","type":"function"},
    {"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"claimWTON","outputs":[],"stateMutability":"nonpayable","type":"function"},
];

function roundDown(val:BigNumber, decimals:number) {
    return ethers.utils.formatUnits(val, decimals).split(".")[0]
}

async function execAllowance(contract: any, fromSigner: Signer, toAddress: string, amount: BigNumber) {
    let allowance = await contract.allowance(fromSigner.address, toAddress);
    if (allowance.lt(amount)) {
        await contract.connect(fromSigner).approve(toAddress, amount);
    }
}

describe('DAO-Security-Council', () => {
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: DaoFixtures
    let jsonInfo: JSONFixture
    let layer2Info_level19 : any;
    let layer2Info_tokamak : any;
    let Operator : any;
    let Candidate : any;
    let snapshotInfo : any;

    before('create fixture loader', async () => {
        deployed = await daoSepoliaFixture()
        jsonInfo = await jsonFixtures()

        deployer = deployed.deployer;
        addr1 = deployed.addr1;
        addr2 = deployed.addr2;

    })

    describe('upgrade dao', () => {
        it('upgrade dao to execute for a security-council ', async () => {
            // console.log("test")
            const index = 2;
            const daoCommitteeSc = (await (await ethers.getContractFactory("DAOCommittee_SecurityCouncil")).connect(deployer).deploy()) as DAOCommittee_SecurityCouncil;

            const selector1 = encodeFunctionSignature("setSecurityCouncil(address)");
            const selector2 = encodeFunctionSignature("setTimelockController(address)");
            const selector3 = encodeFunctionSignature("timelockController()");
            const selector4 = encodeFunctionSignature("securityCouncil()");
            const selector5 = encodeFunctionSignature("executeTransactions(address[],bytes[],uint256[])");
            const selector6 = encodeFunctionSignature("executeTransaction(address,bytes,uint256)");

            const selectors = [selector1,selector2,selector3,selector4,selector5,selector6]
            // console.log('selectors', selectors)

            await (await deployed.daoCommitteeProxy.connect(deployed.daoCommitteeAdmin).setImplementation2(
                daoCommitteeSc.address,
                index,
                true)
            ).wait()

            await (await deployed.daoCommitteeProxy.connect(deployed.daoCommitteeAdmin).setSelectorImplementations2(
                selectors,
                daoCommitteeSc.address)
            ).wait()

            expect(await deployed.daoCommitteeProxy.selectorImplementation(selector1)).to.be.eq(daoCommitteeSc.address)
            expect(await deployed.daoCommitteeProxy.selectorImplementation(selector2)).to.be.eq(daoCommitteeSc.address)
            expect(await deployed.daoCommitteeProxy.selectorImplementation(selector3)).to.be.eq(daoCommitteeSc.address)
            expect(await deployed.daoCommitteeProxy.selectorImplementation(selector4)).to.be.eq(daoCommitteeSc.address)
            expect(await deployed.daoCommitteeProxy.selectorImplementation(selector5)).to.be.eq(daoCommitteeSc.address)
            expect(await deployed.daoCommitteeProxy.selectorImplementation(selector6)).to.be.eq(daoCommitteeSc.address)
        })
    });

    describe('executeTransaction', () => {
        it('DAOVault.claimERC20 (WTON) ', async () => {
            const { daoVaultAddress } = await hre.getNamedAccounts();

            let balanceBefore = await deployed.WTON.balanceOf(daoVaultAddress)
            let amount = ethers.utils.parseUnits("100", 27)
            expect(balanceBefore).to.be.gt(amount)

            const toAddress = await deployer.getAddress()
            const iface = new ethers.utils.Interface(DAOVault_ABI);
            const functionBytes = iface.encodeFunctionData("claimERC20", [deployed.WTON.address, toAddress, amount])
            await (
                await deployed.daoCommitteeForSecurityCouncil.connect(deployed.SecurityCouncil).
                    executeTransaction(
                        daoVaultAddress,
                        functionBytes,
                        ethers.constants.Zero
                    )
            ).wait()

            let balanceAfter= await deployed.WTON.balanceOf(daoVaultAddress)
            expect(balanceAfter).to.be.eq(balanceBefore.sub(amount))
        })

        it('DAOVault.claimERC20 (WTON) : Failed if claim exceeds the WTON balance in DAOVault', async () => {
            const { daoVaultAddress } = await hre.getNamedAccounts();

            let balanceBefore = await deployed.WTON.balanceOf(daoVaultAddress)
            let amount = balanceBefore.add(ethers.constants.One)

            const toAddress = await deployer.getAddress()
            const iface = new ethers.utils.Interface(DAOVault_ABI);
            const functionBytes = iface.encodeFunctionData("claimERC20", [deployed.WTON.address, toAddress, amount])
            await expect (
                  deployed.daoCommitteeForSecurityCouncil.connect(deployed.SecurityCouncil).
                    executeTransaction(
                        daoVaultAddress,
                        functionBytes,
                        ethers.constants.Zero
                    )
            ).to.be.revertedWith("DAOCommittee_SecurityCouncil: Failed to execute")

        })

        it('DAOVault.claimERC20 (TON) : Failed ', async () => {
            const { daoVaultAddress } = await hre.getNamedAccounts();

            let amount = await ethers.constants.One
            const toAddress = await deployer.getAddress()
            const iface = new ethers.utils.Interface(DAOVault_ABI);
            const functionBytes = iface.encodeFunctionData("claimERC20", [deployed.TON.address, toAddress, amount])
            await expect (
                  deployed.daoCommitteeForSecurityCouncil.connect(deployed.SecurityCouncil).
                    executeTransaction(
                        daoVaultAddress,
                        functionBytes,
                        ethers.constants.Zero
                    )
            ).to.be.revertedWith("DisallowedFunctionCallError")

        })

        it('DAOVault.claimTON : Failed ', async () => {
            const { daoVaultAddress } = await hre.getNamedAccounts();

            let amount = await ethers.constants.One
            const toAddress = await deployer.getAddress()
            const iface = new ethers.utils.Interface(DAOVault_ABI);
            const functionBytes = iface.encodeFunctionData("claimTON", [toAddress, amount])
            await expect (
                  deployed.daoCommitteeForSecurityCouncil.connect(deployed.SecurityCouncil).
                    executeTransaction(
                        daoVaultAddress,
                        functionBytes,
                        ethers.constants.Zero
                    )
            ).to.be.revertedWith("DisallowedFunctionCallError")

        })

        it('DAOVault.claimWTON ', async () => {
            const { daoVaultAddress } = await hre.getNamedAccounts();

            let balanceBefore = await deployed.WTON.balanceOf(daoVaultAddress)
            let amount = ethers.utils.parseUnits("100", 27)
            expect(balanceBefore).to.be.gt(amount)

            const toAddress = await deployer.getAddress()
            const iface = new ethers.utils.Interface(DAOVault_ABI);
            const functionBytes = iface.encodeFunctionData("claimWTON", [toAddress, amount])

            await (
                await deployed.daoCommitteeForSecurityCouncil.connect(deployed.SecurityCouncil).
                    executeTransaction(
                        daoVaultAddress,
                        functionBytes,
                        ethers.constants.Zero
                    )
            ).wait()

            let balanceAfter= await deployed.WTON.balanceOf(daoVaultAddress)
            expect(balanceAfter).to.be.eq(balanceBefore.sub(amount))
        })

        it('DAOVault.claimWTON : Failed if claim exceeds the WTON balance in DAOVault ', async () => {
            const { daoVaultAddress } = await hre.getNamedAccounts();

            let balanceBefore = await deployed.WTON.balanceOf(daoVaultAddress)
            let amount = balanceBefore.add(ethers.constants.One)

            const toAddress = await deployer.getAddress()
            const iface = new ethers.utils.Interface(DAOVault_ABI);
            const functionBytes = iface.encodeFunctionData("claimWTON", [toAddress, amount])
            await expect (
                  deployed.daoCommitteeForSecurityCouncil.connect(deployed.SecurityCouncil).
                    executeTransaction(
                        daoVaultAddress,
                        functionBytes,
                        ethers.constants.Zero
                    )
            ).to.be.revertedWith("DisallowedFunctionCallError")
        })

    });

});
