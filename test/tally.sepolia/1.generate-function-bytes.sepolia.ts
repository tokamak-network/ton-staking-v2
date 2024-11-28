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

describe('Generate Function Bytes', () => {
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

    describe('Generate', () => {
        it('DAOVault.claimERC20 (WTON) ', async () => {

            const iface = new ethers.utils.Interface(DAOVault_ABI);
            const toAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
            const amount = ethers.utils.parseUnits("1000",27)

            const functionBytes = iface.encodeFunctionData("claimERC20", [deployed.WTON.address, toAddress, amount])
            console.log("claimERC20(token,to,amount)", functionBytes)
        })

    });

});
