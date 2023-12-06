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


describe("DAOAgenda Test", () => {

    let daoCommitteeAdmin;
    let daoCommitteeProxy;
    let daoCommitteeDAOVaultLogic;
    let daoCommitteeOwnerLogic;
    let ton;
    let wton;

    let daoCommittee;
    let daoCommitteeOwner;
    let daoagendaManager;
    let daovault;

    let testAddr = "f0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";
    let tonAddr = "2be5e8c109e2197D077D13A82dAead6a9b3433C5";
    let wtonAddr = "c4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2";

    let member1;
    let member2;
    let member3;

    let member1Contract;
    let member2Contract;
    let member3Contract;

    let member1Addr = "0x39a13a796a3cd9f480c28259230d2ef0a7026033"
    let member2Addr = "0xd1820b18be7f6429f1f44104e4e15d16fb199a43"
    let member3Addr = "0x42adfaae7db56b294225ddcfebef48b337b34b23"

    let member1ContractAddr = "0x576c7a48fcef1c70db632bb1504d9a5c0d0190d3"
    // let member2ContractAddr = "0x42ccf0769e87cb2952634f607df1c7d62e0bbc52"
    let member2ContractAddr = "0x0F42D1C40b95DF7A1478639918fc358B4aF5298D"
    // let member3ContractAddr = "0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764"
    let member3ContractAddr = "0x06D34f65869Ec94B3BA8c0E08BCEb532f65005E2"

    let beforeclaimAmount;
    let afterclaimAmount;

    let wtonCheck = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";

    let sendether = "0xDE0B6B3A7640000"

    let zeroAddr = "0x0000000000000000000000000000000000000000";
    let oneAddr = "0x0000000000000000000000000000000000000001";
    let twoAddr = "0x0000000000000000000000000000000000000002";
    let tosAddr = "0x409c4D8cd5d2924b9bc5509230d16a61289c8153";

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
        await hre.network.provider.send("hardhat_impersonateAccount", [
            daoAdminAddress,
        ]);
        daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member1Addr,
        ]);
        member1 = await hre.ethers.getSigner(member1Addr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member2Addr,
        ]);
        member2 = await hre.ethers.getSigner(member2Addr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member3Addr,
        ]);
        member3 = await hre.ethers.getSigner(member3Addr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            member1ContractAddr,
        ]);
        member1Contract = await hre.ethers.getSigner(member1ContractAddr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member2ContractAddr,
        ]);
        member2Contract = await hre.ethers.getSigner(member2ContractAddr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member3ContractAddr,
        ]);
        member3Contract = await hre.ethers.getSigner(member3ContractAddr);
        
        await hre.network.provider.send("hardhat_setBalance", [
            member1ContractAddr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            member2ContractAddr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            member3ContractAddr,
            sendether
        ]);
    })

    describe("Setting the DAOCommitteeDAOVault", () => {
        it("Deploy the DAOCommitteeDAOVault", async () => {
            const DAOCommitteeDAOVaultDep = await ethers.getContractFactory("DAOCommitteeDAOVault");
            daoCommitteeDAOVaultLogic = await DAOCommitteeDAOVaultDep.deploy();
            await daoCommitteeDAOVaultLogic.deployed();
            console.log('daoCommitteeDAOVaultLogic' , daoCommitteeDAOVaultLogic.address)
        })

        it("Set TON", async () => {
            ton = new ethers.Contract(
                oldContractInfo.TON,
                TonABI,
                daoCommitteeAdmin
            )
        })

        it("Set WTON", async () => {
            wton = new ethers.Contract(
                oldContractInfo.WTON,
                WtonABI,
                daoCommitteeAdmin
            )
        })

        it("TON Admin Test", async () => {
            let balanceOfZero = await ton.balanceOf(ethers.constants.AddressZero)
            let balanceOfdaoAdminAddress = await ton.balanceOf(daoAdminAddress)
            // console.log('balanceOfZero' , balanceOfZero)
            // console.log('balanceOfdaoAdminAddress' , balanceOfdaoAdminAddress)

            await (await ton.connect(daoCommitteeAdmin).transfer(
                '0x0000000000000000000000000000000000000001',
                ethers.BigNumber.from("1")
            )).wait()

            balanceOfdaoAdminAddress = await ton.balanceOf(daoAdminAddress)
            // console.log('balanceOfdaoAdminAddress' , balanceOfdaoAdminAddress)
        })

        it("Set DAOProxy", async () => {
            daoCommitteeProxy = new ethers.Contract(
                oldContractInfo.DAOCommitteeProxy,
                DAOCommitteeProxyABI,
                daoCommitteeAdmin
            )
        })

        it("pauseProxy check", async () => {
            let pauseProxy = await daoCommitteeProxy.pauseProxy()
            console.log('pauseProxy', pauseProxy)

            if (pauseProxy == true) {
                await (await daoCommitteeProxy.connect(daoCommitteeAdmin).setProxyPause(false)).wait()
            }
            pauseProxy = await daoCommitteeProxy.pauseProxy()
            console.log('pauseProxy', pauseProxy)
        })

        it("DAO upgradeTo newLogic", async () => {
            let imp1 = await daoCommitteeProxy.implementation()
            console.log('imp1', imp1)

            if(imp1.toLowerCase() != daoCommitteeDAOVaultLogic.address.toLowerCase()) {
                await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(
                    daoCommitteeDAOVaultLogic.address)).wait()
            }

            let imp2 = await daoCommitteeProxy.implementation()
            console.log('imp2', imp2)
            console.log('upgradeTo done')
        })

        it("set DAO NewLogic", async () => {
            daoCommittee = new ethers.Contract(
                daoCommitteeProxy.address,
                DAOCommitteeDAOVaultABI,
                daoCommitteeAdmin
            )
        })

        it("set DAOAgendaManager", async () => {
            daoagendaManager = new ethers.Contract(
                oldContractInfo.DAOAgendaManager,
                DAOAgendaManagerABI,
                daoCommitteeAdmin
            )
        })
    })

    describe("setTON, setWTON test", () => {
        it("Deploy the DAOCommitteeOwner", async () => {
            const DAOCommitteeOwnerDep = await ethers.getContractFactory("DAOCommitteeOwner");
            daoCommitteeOwnerLogic = await DAOCommitteeOwnerDep.deploy();
            await daoCommitteeOwnerLogic.deployed();
            console.log('daoCommitteeOwnerLogic' , daoCommitteeOwnerLogic.address)
        })

        it("DAO upgradeTo newLogic", async () => {
            let imp1 = await daoCommitteeProxy.implementation()
            console.log('imp1', imp1)

            if(imp1.toLowerCase() != daoCommitteeOwnerLogic.address.toLowerCase()) {
                await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(
                    daoCommitteeOwnerLogic.address)).wait()
            }

            let imp2 = await daoCommitteeProxy.implementation()
            console.log('imp2', imp2)
            console.log('upgradeTo done')
        })

        it("set DAO Owner logic", async () => {
            daoCommitteeOwner = new ethers.Contract(
                daoCommitteeProxy.address,
                DAOCommitteeOwnerABI,
                daoCommitteeAdmin
            )
        })

        it("set DAOVault", async () => {
            daovault = new ethers.Contract(
                oldContractInfo.DAOVault,
                DAOVaultABI,
                daoCommitteeAdmin
            )
        })

        it("setTargetSetTON Test", async () => {
            //DAOVault setTON 주소 확인
            let beforeTON = await daovault.ton();
            // console.log(beforeTON)
            expect(beforeTON).to.be.equal(oldContractInfo.TON)
            
            //DAOlogic에서 변경 실행
            await daoCommitteeOwner.connect(daoCommitteeAdmin).setTargetSetTON(
                daovault.address,
                twoAddr
            )

            //DAOVault setTON 주소 확인
            let afterTON = await daovault.ton();
            // console.log(afterTON)
            expect(afterTON).to.be.equal(twoAddr)
        })

        it("setTargetSetWTON Test", async () => {
            let beforeWTON = await daovault.wton();
            expect(beforeWTON).to.be.equal(oldContractInfo.WTON)

            await daoCommitteeOwner.connect(daoCommitteeAdmin).setTargetSetWTON(
                daovault.address,
                twoAddr
            ) 

            let afterWTON = await daovault.wton();
            expect(afterWTON).to.be.equal(twoAddr)
        })

        it("setWTON Test", async () => {
            let beforeWTON = await daoCommitteeOwner.wton();
            expect(beforeWTON).to.be.equal(zeroAddr)

            await daoCommitteeOwner.connect(daoCommitteeAdmin).setWton(
                oldContractInfo.WTON
            )

            let afterWTON = await daoCommitteeOwner.wton();
            expect(afterWTON).to.be.equal(oldContractInfo.WTON)
        })
    })

    describe("Agenda Test", () => {
        it("DAO upgradeTo DAOVaultLogic", async () => {
            let imp1 = await daoCommitteeProxy.implementation()
            console.log('imp1', imp1)

            if(imp1.toLowerCase() != daoCommitteeDAOVaultLogic.address.toLowerCase()) {
                await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(
                    daoCommitteeDAOVaultLogic.address)).wait()
            }

            let imp2 = await daoCommitteeProxy.implementation()
            expect(imp2).to.be.equal(daoCommitteeDAOVaultLogic.address)
            // console.log('imp2', imp2)
            console.log('upgradeTo done')
        })

        it("DAOVault Agenda claimTON Test", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();

            const agendaFee = await daoagendaManager.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];

            const selector1 = Web3EthAbi.encodeFunctionSignature("claimTON(address,uint256)");
            // console.log("selector1 : ", selector1);
            // console.log("selector1.length : ", selector1.length);
            const claimAmount = 100000000000000000000

            const data1 = padLeft(testAddr.toString(), 64);
            // console.log("data1 : ", data1);
            const data2 = padLeft(claimAmount.toString(16), 64);
            // console.log("data2 : ", data2)
            const data3 = data1 + data2
            // console.log("data3 : ", data3);

            const functionBytecode1 = selector1.concat(data3)
            // console.log("functionBytecode1 :", functionBytecode1);
            // console.log("functionBytecode1.length :", functionBytecode1.length);

            targets.push(oldContractInfo.DAOVault);
            functionBytecodes.push(functionBytecode1)

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

            const beforeBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            if (agendaFee.gt(beforeBalance))
                    await (await ton.connect(daoCommitteeAdmin).mint(daoCommitteeAdmin.address, agendaFee)).wait();

            let agendaID = (await daoagendaManager.numAgendas()).sub(1);


            // await ton.connect(daoCommitteeAdmin).approveAndCall(
            //     daoCommitteeProxy.address,
            //     agendaFee,
            //     param
            // );

            await expect(
                ton.connect(daoCommitteeAdmin).approveAndCall(
                    daoCommitteeProxy.address,
                    agendaFee,
                    param
            )).to.be.reverted;

        })

        it("DAOVault Agenda claimERC20 Test, if address is TON Addr", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();

            const agendaFee = await daoagendaManager.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];

            const selector1 = Web3EthAbi.encodeFunctionSignature("claimERC20(address,address,uint256)");
            // console.log("selector1 : ", selector1);
            // console.log("selector1.length : ", selector1.length);
            const claimAmount = 100000000000000000000

            const data1 = padLeft(tonAddr.toString(), 64);
            // console.log("data1 : ", data1);
            const data2 = padLeft(testAddr.toString(), 64);
            // console.log("data2 : ", data2)
            const data3 = padLeft(claimAmount.toString(16), 64);
            // console.log("data3 : ", data3);
            const data4 = data1 + data2 + data3
            // console.log("data4 : ", data4);

            const functionBytecode1 = selector1.concat(data4)
            // console.log("functionBytecode1 :", functionBytecode1);

            targets.push(oldContractInfo.DAOVault);
            functionBytecodes.push(functionBytecode1)
            // console.log("functionBytecode1.length :", functionBytecode1.length);

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

            const beforeBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            if (agendaFee.gt(beforeBalance))
                    await (await ton.connect(daoCommitteeAdmin).mint(daoCommitteeAdmin.address, agendaFee)).wait();

            let agendaID = (await daoagendaManager.numAgendas()).sub(1);


            // await ton.connect(daoCommitteeAdmin).approveAndCall(
            //     daoCommitteeProxy.address,
            //     agendaFee,
            //     param
            // );

            await expect(
                ton.connect(daoCommitteeAdmin).approveAndCall(
                    daoCommitteeProxy.address,
                    agendaFee,
                    param
            )).to.be.reverted;
        })

        it("DAOVault Agenda claimERC20 Test, if address is WTON addr", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();

            const agendaFee = await daoagendaManager.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];

            const selector1 = Web3EthAbi.encodeFunctionSignature("claimERC20(address,address,uint256)");
            // console.log("selector1 : ", selector1);
            // console.log("selector1.length : ", selector1.length);
            const claimAmount = 100000000000000000000

            const data1 = padLeft(wtonAddr.toString(), 64);
            // console.log("data1 : ", data1);
            const data2 = padLeft(testAddr.toString(), 64);
            // console.log("data2 : ", data2)
            const data3 = padLeft(claimAmount.toString(16), 64);
            // console.log("data3 : ", data3);
            const data4 = data1 + data2 + data3
            // console.log("data4 : ", data4);

            const functionBytecode1 = selector1.concat(data4)
            // console.log("functionBytecode1 :", functionBytecode1);

            targets.push(oldContractInfo.DAOVault);
            functionBytecodes.push(functionBytecode1)
            // console.log("functionBytecode1.length :", functionBytecode1.length);

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

            const beforeBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            if (agendaFee.gt(beforeBalance))
                    await (await ton.connect(daoCommitteeAdmin).mint(daoCommitteeAdmin.address, agendaFee)).wait();

            let agendaID = (await daoagendaManager.numAgendas()).sub(1);


            await ton.connect(daoCommitteeAdmin).approveAndCall(
                daoCommitteeProxy.address,
                agendaFee,
                param
            );

            // await expect(
            //     ton.connect(daoCommitteeAdmin).approveAndCall(
            //         daoCommitteeProxy.address,
            //         agendaFee,
            //         param
            // )).to.be.reverted;
        })

        it("DAOVault Agenda claimWTON Test if amount is over that DAOVault Have wton", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();

            const agendaFee = await daoagendaManager.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];

            const selector1 = Web3EthAbi.encodeFunctionSignature("claimWTON(address,uint256)");
            // console.log("selector1 : ", selector1);
            // console.log("selector1.length : ", selector1.length);
            // const claimAmount = 10000000000000000000000000
            const claimAmount = 20280309787867133590443242000000000

            const data1 = padLeft(testAddr.toString(), 64);
            // console.log("data1 : ", data1);
            const data2 = padLeft(claimAmount.toString(16), 64);
            // console.log("data2 : ", data2)
            const data3 = data1 + data2
            // console.log("data3 : ", data3);

            const functionBytecode1 = selector1.concat(data3)
            // console.log("functionBytecode1 :", functionBytecode1);
            // console.log("functionBytecode1.length :", functionBytecode1.length);

            targets.push(oldContractInfo.DAOVault);
            functionBytecodes.push(functionBytecode1)

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

            const beforeBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            if (agendaFee.gt(beforeBalance))
                    await (await ton.connect(daoCommitteeAdmin).mint(daoCommitteeAdmin.address, agendaFee)).wait();

            let agendaID = (await daoagendaManager.numAgendas()).sub(1);


            // await ton.connect(daoCommitteeAdmin).approveAndCall(
            //     daoCommitteeProxy.address,
            //     agendaFee,
            //     param
            // );

            await expect(
                ton.connect(daoCommitteeAdmin).approveAndCall(
                    daoCommitteeProxy.address,
                    agendaFee,
                    param
            )).to.be.reverted;
        })

        it("DAOVault Agenda claimWTON Test if amount is little (down DAOVault Have WTON)", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();

            const agendaFee = await daoagendaManager.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];

            const selector1 = Web3EthAbi.encodeFunctionSignature("claimWTON(address,uint256)");
            // console.log("selector1 : ", selector1);
            // console.log("selector1.length : ", selector1.length);
            const claimAmount = 10000000000000000000000000000
            // const claimAmount = 20280309787867133590443242000000000

            const data1 = padLeft(testAddr.toString(), 64);
            // console.log("data1 : ", data1);
            const data2 = padLeft(claimAmount.toString(16), 64);
            // console.log("data2 : ", data2)
            const data3 = data1 + data2
            // console.log("data3 : ", data3);

            const functionBytecode1 = selector1.concat(data3)
            // console.log("functionBytecode1 :", functionBytecode1);
            // console.log("functionBytecode1.length :", functionBytecode1.length);

            targets.push(oldContractInfo.DAOVault);
            functionBytecodes.push(functionBytecode1)

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

            const beforeBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            if (agendaFee.gt(beforeBalance))
                    await (await ton.connect(daoCommitteeAdmin).mint(daoCommitteeAdmin.address, agendaFee)).wait();

            let agendaID = (await daoagendaManager.numAgendas()).sub(1);

            // await ton.connect(daoCommitteeAdmin).approveAndCall(
            //     daoCommitteeProxy.address,
            //     agendaFee,
            //     param
            // );

            await expect(
                ton.connect(daoCommitteeAdmin).approveAndCall(
                    daoCommitteeProxy.address,
                    agendaFee,
                    param
            )).to.be.reverted;
        })
    })

    describe("claimActivityReward Test", () => {
        it("member1 getClaimableActivityReward check", async () => {
            beforeclaimAmount = await daoCommittee.getClaimableActivityReward(member1.address);
            console.log("claimAmount1 : ", beforeclaimAmount);
            expect(beforeclaimAmount).to.be.gt(0)
        })

        it("member2 getClaimableActivityReward check", async () => {
            let claimAmount = await daoCommittee.getClaimableActivityReward(member2.address);
            console.log("claimAmount2 : ", claimAmount);
            expect(claimAmount).to.be.gt(0)
        })

        it("member3 getClaimableActivityReward check", async () => {
            let claimAmount = await daoCommittee.getClaimableActivityReward(member3.address);
            console.log("claimAmount3 : ", claimAmount);
            expect(claimAmount).to.be.gt(0)
        })

        it("increase Time", async () => {
            await ethers.provider.send("evm_increaseTime", [60])   // add 60 seconds
            await ethers.provider.send("evm_mine")      // mine the next block
        })

        it("Is the member being applied properly getClaimableActivityReward check", async () => {
            afterclaimAmount = await daoCommittee.getClaimableActivityReward(member1.address);
            console.log("afterClaim : ", afterclaimAmount);
            expect(afterclaimAmount).to.be.gt(beforeclaimAmount)
        })

        it("claimActivityReward Test", async () => {
            let beforeWTON = await wton.balanceOf(wtonCheck)
            expect(beforeWTON).to.be.equal(0);


            let beforeDAOVault = await wton.balanceOf(oldContractInfo.DAOVault)
            let claimAmount = await daoCommittee.getClaimableActivityReward(member3.address);
            let wtonClaimAmount = await daoCommittee._toRAY(claimAmount)
            console.log("beforeDAOVault :", beforeDAOVault);
            console.log("wtonClaimAmount :", wtonClaimAmount);
            expect(beforeDAOVault).to.be.gt(wtonClaimAmount)
            
            // console.log("claimReward in");
            const topic = daoCommittee.interface.getEventTopic('ClaimedActivityReward');
            const receipt = await (await daoCommittee.connect(member3Contract).claimActivityReward(wtonCheck)).wait();
            // console.log("claimReward out");

            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = daoCommittee.interface.parseLog(log);
            
            // console.log("deployedEvent.args :", deployedEvent.args);
            let claimWTONAmount = deployedEvent.args.amount;
            console.log("claimWTONAmount :", claimWTONAmount);

            let afterclaimAmount = await daoCommittee.getClaimableActivityReward(member3.address);
            expect(afterclaimAmount).to.be.equal(0)
            
            let afterWTON = await wton.balanceOf(wtonCheck)
            // console.log("afterWTON :", afterWTON);
            expect(afterWTON).to.be.equal(claimWTONAmount);

            let afterDAOVault = await wton.balanceOf(oldContractInfo.DAOVault)
            let calculAmount = beforeDAOVault.sub(claimWTONAmount)
            
            // console.log("afterDAOVault :", afterDAOVault);
            // console.log("calculAmount :", calculAmount);

            expect(afterDAOVault).to.be.equal(calculAmount)
        })
    })
})
