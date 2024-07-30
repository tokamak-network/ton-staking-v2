const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");

const { expect, assert } = chai;
chai.use(solidity);
require("chai").should();

const Web3EthAbi = require('web3-eth-abi');
const { padLeft } = require('web3-utils');

const networkName = "mainnet"

const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'

const goerliPowerTonAdmin = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const mainnetPowerTonAdmin = "0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1"

let daoAgendaMangerAddress = "0xcD4421d082752f363E1687544a09d5112cD4f484"; //DAOAgendaManager Address

const TonABI = require("../../abi/TON.json").abi;
const WtonABI = require("../../abi/WTON.json").abi;
const DAOCommitteeExtendABI = require("../../abi/DAOCommitteeExtend.json").abi;
const DAOCommitteeOwnerABI = require("../../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOCommitteeDAOVaultABI = require("../../artifacts/contracts/dao/DAOCommitteeDAOVault.sol/DAOCommitteeDAOVault.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const SeigManagerProxyABI = require("../../artifacts/contracts/stake/managers/SeigManagerProxy.sol/SeigManagerProxy.json").abi;
const SeigManagerABI = require("../../artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json").abi;

const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const DAOVaultABI = require("../../abi/DAOVault.json").abi;

const DepositManagerProxy_Json = require('../abi/DepositManagerProxy.json')


describe("DAOAgenda Test", () => {

    let daoCommitteeAdmin;
    let daoCommitteeProxy;
    let deployer;
    let depositManagerProxy;
    let ton;
    let wton;

    let daoCommittee;
    let daoCommitteeOwner, daoCommitteeSigner;
    let daoagendaManager;

    let tonHaveAddr = "0x7897ccD146b97639c0Dd99A17383e0b11681996E"

    // mainnet network
    const oldContractInfo = {
        TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
        WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
        Layer2Registry: "0x0b3E174A2170083e770D5d4Cf56774D221b7063e",
        DepositManager: "0x56E465f654393fa48f007Ed7346105c7195CEe43",
        CoinageFactory: "0x5b40841eeCfB429452AB25216Afc1e1650C07747",
        OldDAOVaultMock: "",
        SeigManager: "0x710936500aC59e8551331871Cbad3D33d5e0D909",
        PowerTON: "0x970298189050aBd4dc4F119ccae14ee145ad9371",
        DAOVault: "0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303",
        DAOAgendaManager: "0xcD4421d082752f363E1687544a09d5112cD4f484",
        CandidateFactory: "0xE6713aF11aDB0cFD3C60e15b23E43f5548C32942",
        DAOCommittee: "0xd1A3fDDCCD09ceBcFCc7845dDba666B7B8e6D1fb",
        DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
    }
    const nowContractInfo = {
        TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
        WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
        Layer2Registry: "0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b",
        DepositManager: "0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e",
        CoinageFactory: "",
        SeigManager: "0x0b55a0f463b6defb81c6063973763951712d0e5f",
    }

    before('create fixture loader', async () => {
        const accounts = await ethers.getSigners();
        deployer = accounts[0]

        await hre.network.provider.send("hardhat_impersonateAccount", [
            daoAdminAddress,
        ]);
        daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);
        await hre.network.provider.send("hardhat_impersonateAccount", [
            tonHaveAddr,
        ]);
        tonHave = await hre.ethers.getSigner(tonHaveAddr);


        await hre.network.provider.send("hardhat_impersonateAccount", [
            oldContractInfo.DAOCommitteeProxy,
        ]);

        await network.provider.send("hardhat_setBalance", [
            oldContractInfo.DAOCommitteeProxy,
            "0x10000000000000000000000000",
        ]);
        daoCommitteeSigner = await hre.ethers.getSigner(oldContractInfo.DAOCommitteeProxy);

    })

    describe("Setting the DAOCommitteeDAOVault", () => {

        it("Set TON", async () => {
            ton = new ethers.Contract(
                oldContractInfo.TON,
                TonABI,
                deployer
            )
        })

        it("set DAOAgendaManager", async () => {
            daoagendaManager = new ethers.Contract(
                oldContractInfo.DAOAgendaManager,
                DAOAgendaManagerABI,
                deployer
            )
        })

        it("set depositManager", async () => {
            depositManagerProxy = new ethers.Contract(nowContractInfo.DepositManager,  DepositManagerProxy_Json.abi, deployer)

        })

    })

    describe("daoagendaManager Test", () => {
        it("set depositManager", async () => {
            const selector1 = Web3EthAbi.encodeFunctionSignature("setWithdrawalDelay(address,uint256)");
            const logicAddress = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5"

            const receipt0 = await (await depositManagerProxy.connect(daoCommitteeSigner).setImplementation2(logicAddress, 1, true)).wait()
            console.log(receipt0)

            const receipt = await (await depositManagerProxy.connect(daoCommitteeSigner).setSelectorImplementations2([selector1], logicAddress)).wait()
            console.log(receipt)
        })
    })


    describe("Agenda Test", () => {

        it("DAOVault Agenda claimTON Test", async () => {


            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();

            const agendaFee = await daoagendaManager.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];
            const logicAddress = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5"
            //--------------
            const selector0 = Web3EthAbi.encodeFunctionSignature("setImplementation2(address,uint256,bool)");

            const functionBytecode0 = depositManagerProxy.interface.encodeFunctionData(
                "setImplementation2", [logicAddress,1,true])
                // console.log("functionBytecode1 :", functionBytecode1);

            targets.push(nowContractInfo.DepositManager);
            functionBytecodes.push(functionBytecode0)
            //--------------
            const selector1 = Web3EthAbi.encodeFunctionSignature("setWithdrawalDelay(address,uint256)");
            const functionBytecode1 = depositManagerProxy.interface.encodeFunctionData(
                "setSelectorImplementations2", [[selector1],logicAddress])
                // console.log("functionBytecode1 :", functionBytecode1);

            targets.push(nowContractInfo.DepositManager);
            functionBytecodes.push(functionBytecode1)

            //--------------
            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets,
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    false,
                    functionBytecodes
                ]
            )
            console.log("param :", param);
            // const beforeBalance = await ton.balanceOf(tonHave.address);
            // let agendaID = (await daoagendaManager.numAgendas()).sub(1);

            await ton.connect(tonHave).approveAndCall(
                oldContractInfo.DAOCommitteeProxy,
                agendaFee,
                param
            );

            // const afterBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            // expect(afterBalance).to.be.lt(beforeBalance2);
            // expect(beforeBalance2.sub(afterBalance)).to.be.equal(agendaFee)

            // agendaID = (await daoagendaManager.numAgendas()).sub(1);
            // //const executionInfo = await agendaManager.executionInfos(agendaID);
            // const executionInfo = await daoagendaManager.getExecutionInfo(agendaID);
            // // console.log("executionInfo :", executionInfo);
            // expect(executionInfo[0][0]).to.be.equal(daoagendaManager.address);
            // expect(executionInfo[1][0]).to.be.equal(functionBytecode);

        })

    })

})
