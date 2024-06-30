import { expect } from '../shared/expect'
import { ethers, network, getNamedAccounts} from 'hardhat'

import { mine } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumber, Signer, utils, Contract } from 'ethers'
import { padLeft } from 'web3-utils'

import {encodeFunctionSignature, encodeParameters} from 'web3-eth-abi'
import { marshalString, unmarshalString } from '../shared/marshal'
import { gasUsedFunctions, exportLogs } from '../shared/logUtils'

import Ton_Json from '../../abi/TON.json'
import Wton_Json from '../../abi/WTON.json'
import DAOCommitteeProxy_Json from '../../abi/DAOCommitteeProxy.json'
import DAOAgendaManager_Json from '../../abi/DAOAgendaManager.json'

import DAOCommitteeExtend_Json from '../../artifacts/contracts/dao/DAOCommitteeExtend.sol/DAOCommitteeExtend.json'
import SeigManager_Json from '../../artifacts/contracts/stake/managers/SeigManagerV1_2.sol/SeigManagerV1_2.json'
import DepositManager_Json from '../../artifacts/contracts/stake/managers/DepositManager.sol/DepositManager.json'
import DAOCandidate_Json from '../../abi/Candidate.json'
import SeigManagerProxy_Json from '../../artifacts/contracts/stake/managers/SeigManagerProxy.sol/SeigManagerProxy.json'

import {SeigManagerV1_2_onTransfer} from "../../typechain-types/contracts/stake/managers/SeigManagerV1_2_onTransfer.sol/SeigManagerV1_2_onTransfer"

let logs: Array<any> = []

/** mainnet */
const TON_ADDRESS="0x2be5e8c109e2197D077D13A82dAead6a9b3433C5"
const WTON_ADDRESS="0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2"
const DAOCommitteeProxy_ADDRESS="0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
const DepositManager_ADDRESS="0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e"
const SeigManager_ADDRESS="0x0b55a0f463b6defb81c6063973763951712d0e5f"
const AgendaManager_ADDRESS="0xcD4421d082752f363E1687544a09d5112cD4f484"

const DAOCandidate_LEVEL="0x0F42D1C40b95DF7A1478639918fc358B4aF5298D"
const DAOCandidate_TOKAMAK="0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF"
const DAOCandidate_Hammer="0x06D34f65869Ec94B3BA8c0E08BCEb532f65005E2"
const DAOCandidate_LEVEL_Operator="0xd1820b18be7f6429f1f44104e4e15d16fb199a43"
const DAOCandidate_TOKAMAK_Operator="0xea8e2ec08dcf4971bdcdfffe21439995378b44f3"
const DAOCandidate_Hammer_Operator="0x42adfaae7db56b294225ddcfebef48b337b34b23"

const BlackList_1_ADDRESS = "0xf0252f0D3D16e01C2D909566eA4Bf9Cb0e9B42C4"
const BlackList_2_ADDRESS = "0xd7E81990a68Cbb46a9a595232eE67D6b3B7cdB73"
// 0xf0252f0D3D16e01C2D909566eA4Bf9Cb0e9B42C4
// 0xd7E81990a68Cbb46a9a595232eE67D6b3B7cdB73

let tonHolderAddress = "0x2Db13E39eaf889A433E0CB23C38520419eC37202"
let wtonHolderAddress = "0x630D7e837F695432EAa0A4FaC037d386301909C8"

describe('BlackList', () => {

    let deployer: Signer, user1: Signer,  user2: Signer,  user3: Signer
    let daoOwner: Signer;
    let daoMember_level : any;
    let daoMember_tokamak : any;
    let daoMember_hammer : any;

    let tonContract: Contract, wtonContract: Contract
    let daoContract: Contract
    let depositManager: Contract, seigManager: Contract, seigManagerProxy:Contract
    let seigManagerV1_2_onTransfer: Contract, agendaManager: Contract

    let wtonHolder:Signer, tonHolder:Signer
    let blacklist1: Signer, blacklist2: Signer

    let tonTransferUsedGas = {
        before: ethers.constants.Zero,
        after: ethers.constants.Zero
    }
    let wtonTransferUsedGas = {
        before: ethers.constants.Zero,
        after: ethers.constants.Zero
    }

    before('set contracts and signers', async () => {

        const accounts = await ethers.getSigners();
        deployer = accounts[0]
        user1 = accounts[1]
        user2 = accounts[2]
        user3 = accounts[3]

        daoMember_level = {
            layer2: DAOCandidate_LEVEL,
            operator: DAOCandidate_LEVEL_Operator,
            layerContract: null,
            operatorSigner: null
        }
        daoMember_tokamak = {
            layer2: DAOCandidate_TOKAMAK,
            operator: DAOCandidate_TOKAMAK_Operator,
            layerContract: null,
            operatorSigner: null
        }
        daoMember_hammer = {
            layer2: DAOCandidate_Hammer,
            operator: DAOCandidate_Hammer_Operator,
            layerContract: null,
            operatorSigner: null
        }

        tonContract = new ethers.Contract(TON_ADDRESS, Ton_Json.abi,  deployer)
        wtonContract = new ethers.Contract(WTON_ADDRESS,  Wton_Json.abi, deployer)
        daoContract = new ethers.Contract(DAOCommitteeProxy_ADDRESS,  DAOCommitteeExtend_Json.abi, deployer)
        agendaManager = new ethers.Contract(AgendaManager_ADDRESS,  DAOAgendaManager_Json.abi, deployer)

        depositManager = new ethers.Contract(DepositManager_ADDRESS,  DepositManager_Json.abi, deployer)
        seigManager = new ethers.Contract(SeigManager_ADDRESS,  SeigManager_Json.abi, deployer)
        seigManagerProxy = new ethers.Contract(SeigManager_ADDRESS,  SeigManagerProxy_Json.abi, deployer)
        daoMember_level.layerContract = new ethers.Contract(daoMember_level.layer2,  DAOCandidate_Json.abi, deployer)
        daoMember_tokamak.layerContract = new ethers.Contract(daoMember_tokamak.layer2,  DAOCandidate_Json.abi, deployer)
        daoMember_hammer.layerContract = new ethers.Contract(daoMember_hammer.layer2,  DAOCandidate_Json.abi, deployer)

        await network.provider.send("hardhat_impersonateAccount", [daoMember_level.operator ]);
        await network.provider.send("hardhat_impersonateAccount", [daoMember_tokamak.operator ]);
        await network.provider.send("hardhat_impersonateAccount", [daoMember_hammer.operator ]);
        await network.provider.send("hardhat_impersonateAccount", [tonHolderAddress ]);
        await network.provider.send("hardhat_impersonateAccount", [wtonHolderAddress ]);
        await network.provider.send("hardhat_impersonateAccount", [BlackList_1_ADDRESS ]);
        await network.provider.send("hardhat_impersonateAccount", [BlackList_2_ADDRESS ]);

        await network.provider.send("hardhat_setBalance", [ daoMember_level.operator, "0x10000000000000000000000000", ]);
        await network.provider.send("hardhat_setBalance", [ daoMember_tokamak.operator, "0x10000000000000000000000000", ]);
        await network.provider.send("hardhat_setBalance", [ daoMember_hammer.operator, "0x10000000000000000000000000", ]);
        await network.provider.send("hardhat_setBalance", [ tonHolderAddress, "0x10000000000000000000000000", ]);
        await network.provider.send("hardhat_setBalance", [ wtonHolderAddress, "0x10000000000000000000000000", ]);
        await network.provider.send("hardhat_setBalance", [ BlackList_1_ADDRESS, "0x10000000000000000000000000", ]);
        await network.provider.send("hardhat_setBalance", [ BlackList_2_ADDRESS, "0x10000000000000000000000000", ]);

        daoMember_level.operatorSigner = await ethers.getSigner(daoMember_level.operator);
        daoMember_tokamak.operatorSigner = await ethers.getSigner(daoMember_tokamak.operator);
        daoMember_hammer.operatorSigner = await ethers.getSigner(daoMember_hammer.operator);
        tonHolder = await ethers.getSigner(tonHolderAddress);
        wtonHolder = await ethers.getSigner(wtonHolderAddress);
        blacklist1 = await ethers.getSigner(BlackList_1_ADDRESS);
        blacklist2 = await ethers.getSigner(BlackList_2_ADDRESS);
    })

    describe('# SeigManagerV1_2_onTransfer', () => {

        it('deploy', async () => {
            seigManagerV1_2_onTransfer = (await (await ethers.getContractFactory("SeigManagerV1_2_onTransfer")).connect(deployer).deploy()) as SeigManagerV1_2_onTransfer;
        });
    })

    describe('# TON ', () => {
        it('Transfer TON to blacklist ', async () => {
            const receipt = await (await tonContract.connect(blacklist2).transfer(
                blacklist1.address, ethers.utils.parseEther("100"))).wait()

            tonTransferUsedGas.before = receipt.gasUsed

            logs.push(gasUsedFunctions('TON', 'transfer', 'Before blacklist blocking', receipt))
        })

        it('Transfer WTON to blacklist ', async () => {
            // let balance = await wtonContract.balanceOf(wtonHolder.address)
            // console.log('balance', ethers.utils.formatUnits(balance, 27))

            const receipt = await (await wtonContract.connect(wtonHolder).transfer(
                blacklist1.address, ethers.utils.parseEther("100000000000"))).wait()

            wtonTransferUsedGas.before = receipt.gasUsed
            logs.push(gasUsedFunctions('WTON', 'transfer', 'Before blacklist blocking', receipt))
        })

        it('Transfer WTON to blacklist ', async () => {

            const receipt = await (await wtonContract.connect(wtonHolder).transfer(
                blacklist2.address, ethers.utils.parseEther("100000000000"))).wait()

            wtonTransferUsedGas.before = wtonTransferUsedGas.before.add(receipt.gasUsed).div(ethers.constants.Two)
            logs.push(gasUsedFunctions('WTON', 'transfer', 'Before blacklist blocking', receipt))
        })

    })

    // SeigManagerV1_2_onTransfer 로직 반영 안건만들기
    describe('# Agenda', () => {

        it('create Agenda ', async () => {
            const noticePeriod = await agendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await agendaManager.minimumVotingPeriodSeconds();
            const agendaFee = await agendaManager.createAgendaFees();
            let targets = [];
            let functionBytecodes = [];

            //============================
            //===== transactions 1 : register logic
            let index = 1
            expect(await seigManagerProxy.implementation2(index)).to.be.eq(ethers.constants.AddressZero)
            let functionBytecode1 = seigManagerProxy.interface.encodeFunctionData("setImplementation2(address,uint256,bool)", [
                seigManagerV1_2_onTransfer.address, index, true
            ])
            targets.push(seigManagerProxy.address)
            functionBytecodes.push(functionBytecode1)

            //============================
            //===== transactions 2 : register logic
            const selector1 = encodeFunctionSignature("onTransfer(address,address,uint256)");
            const selector2 = encodeFunctionSignature("addBlackList(address[])");
            const selector3 = encodeFunctionSignature("deleteBlackList(address[])");
            let selectors = [ selector1, selector2, selector3 ];
            let functionBytecode2 = seigManagerProxy.interface.encodeFunctionData("setSelectorImplementations2(bytes4[],address)", [
                selectors, seigManagerV1_2_onTransfer.address
            ])

            targets.push(seigManagerProxy.address)
            functionBytecodes.push(functionBytecode2)

            //============================
            //===== transactions 3 : put on a blacklist
            let blacklists = [BlackList_1_ADDRESS, BlackList_2_ADDRESS]
            let functionBytecode3 = seigManagerV1_2_onTransfer.interface.encodeFunctionData("addBlackList(address[])", [
                blacklists
            ])
            targets.push(seigManagerProxy.address)
            functionBytecodes.push(functionBytecode3)



            //============================
            //===== transactions 4 : set TON's callbackEnabled to true
            let functionBytecode4 = tonContract.interface.encodeFunctionData("enableCallback(bool)", [
                true
            ])
            targets.push(tonContract.address)
            functionBytecodes.push(functionBytecode4)

            //============================
            //===== transactions 5 : set WTON's callbackEnabled to true
            let functionBytecode5 = wtonContract.interface.encodeFunctionData("enableCallback(bool)", [
                true
            ])
            targets.push(wtonContract.address)
            functionBytecodes.push(functionBytecode5)


            //============================
            //===== transactions 6 : set TON's SeigManager

            // console.log(tonContract.interface)

            // let functionBytecode6 = tonContract.interface.encodeFunctionData("setSeigManager(address)", [
            //     SeigManager_ADDRESS
            // ])
            // targets.push(tonContract.address)
            // functionBytecodes.push(functionBytecode6)

            //============================
            //===== transactions 7 : set WTON's SeigManager
            let functionBytecode7 = wtonContract.interface.encodeFunctionData("setSeigManager(address)", [
                SeigManager_ADDRESS
            ])
            targets.push(wtonContract.address)
            functionBytecodes.push(functionBytecode7)

            //============================
            //--- agendaManager : make agenda
            const param = encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets,
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    true,
                    functionBytecodes
                ]
            )

            let beforeBalance = await tonContract.balanceOf(tonHolder.address);
            expect(beforeBalance).to.be.gt(agendaFee)

            let numAgendas = (await agendaManager.numAgendas()) ;
            const receipt = await (await tonContract.connect(tonHolder).approveAndCall(
                DAOCommitteeProxy_ADDRESS,
                agendaFee.toString(),
                param
            )).wait()

            expect(await agendaManager.numAgendas()).to.be.eq(numAgendas.add(ethers.constants.One))
            logs.push(gasUsedFunctions('TON', 'approveAndCall', 'ton.approve and agendaManager.newAgenda', receipt))
        });

        it('noticePeriod : evm_mine', async () => {

            let agendaId = (await agendaManager.numAgendas()).sub(ethers.constants.One) ;

            expect(await agendaManager.isVotableStatus(agendaId)).to.be.eq(false)
            const noticePeriod = await agendaManager.minimumNoticePeriodSeconds();

            ethers.provider.send("evm_increaseTime", [noticePeriod.toNumber()])
            ethers.provider.send("evm_mine");
            expect(await agendaManager.isVotableStatus(agendaId)).to.be.eq(true)

        });

        it('Voting ', async () => {
            let agendaId = (await agendaManager.numAgendas()).sub(ethers.constants.One) ;
            expect(await agendaManager.isVotableStatus(agendaId)).to.be.eq(true)


            const receipt1 = await (await daoMember_level.layerContract.connect(daoMember_level.operatorSigner).castVote(
                agendaId, 1, 'yes'
            )).wait()

            const receipt2 = await (await daoMember_hammer.layerContract.connect(daoMember_hammer.operatorSigner).castVote(
                agendaId, 0, 'no'
            )).wait()

            const receipt3 = await (await daoMember_tokamak.layerContract.connect(daoMember_tokamak.operatorSigner).castVote(
                agendaId, 1, 'yes'
            )).wait()

            logs.push(gasUsedFunctions('DAOCandiate', 'castVote', 'yes', receipt1))
            logs.push(gasUsedFunctions('DAOCandiate', 'castVote', 'no', receipt2))
            logs.push(gasUsedFunctions('DAOCandiate', 'castVote', 'yes', receipt3))

        })

        it('votingPeriod : evm_mine ', async () => {
            let agendaId = (await agendaManager.numAgendas()).sub(ethers.constants.One) ;

            const votingPeriod = await agendaManager.minimumVotingPeriodSeconds();

            ethers.provider.send("evm_increaseTime", [votingPeriod.toNumber()])
            ethers.provider.send("evm_mine");
            expect(await agendaManager.isVotableStatus(agendaId)).to.be.eq(false)
        })

        it('Executing ', async () => {
            let agendaId = (await agendaManager.numAgendas()).sub(ethers.constants.One) ;
            expect(await agendaManager.canExecuteAgenda(agendaId)).to.be.eq(true)
            const receipt = await (await daoContract.connect(tonHolder).executeAgenda(agendaId)).wait()
            logs.push(gasUsedFunctions('DAOCommittee', 'executeAgenda', '', receipt))

            let voterInfos1 = await agendaManager.voterInfos(agendaId, daoMember_level.operator)  ;
            expect(voterInfos1.vote).to.be.eq(ethers.constants.One)
            let voterInfo2 = await agendaManager.voterInfos(agendaId, daoMember_tokamak.operator)  ;
            expect(voterInfo2.vote).to.be.eq(ethers.constants.One)
            let voterInfos3 = await agendaManager.voterInfos(agendaId, daoMember_hammer.operator)  ;
            expect(voterInfos3.vote).to.be.eq(ethers.constants.Zero)
        })
    })

    describe('# Block TON transmission of blacklist ', () => {
        it('Transfer TON to blacklist ', async () => {

            let ton_callbackEnabled = await tonContract.callbackEnabled()
            console.log('ton_callbackEnabled', ton_callbackEnabled);

            let ton_seigManager = await tonContract.seigManager()
            console.log('ton_seigManager', ton_seigManager);

            // await seigManager.connect(tonHolder).onTransfer(tonHolder.address, blacklist1.address, ethers.utils.parseEther("1"))

            // await tonContract.connect(tonHolder).transfer(blacklist1.address, ethers.utils.parseEther("100"))
            // expect(
            //     await tonContract.connect(tonHolder).transfer(blacklist1.address, ethers.utils.parseEther("100"))
            // ).to.be.revertedWith("err")


            // logs.push(gasUsedFunctions('TON', 'transfer', 'Before blacklist blocking', receipt))
        })

        it('Transfer WTON to blacklist ', async () => {

            let wton_callbackEnabled = await wtonContract.callbackEnabled()
            console.log('wton_callbackEnabled', wton_callbackEnabled);

            let wton_seigManager = await wtonContract.seigManager()
            console.log('wton_seigManager', wton_seigManager);

            await expect(
                wtonContract.connect(wtonHolder).transfer(blacklist1.address, ethers.utils.parseEther("100"))
            ).to.be.revertedWith('BlackList_Error')

            await expect(
                wtonContract.connect(wtonHolder).transfer(blacklist2.address, ethers.utils.parseEther("100"))
            ).to.be.revertedWith("BlackList_Error")

            const receipt = await (await wtonContract.connect(wtonHolder).transfer(tonHolder.address, ethers.utils.parseEther("100"))).wait()

            logs.push(gasUsedFunctions('WTON', 'transfer', 'After blacklist blocking', receipt))
        })


        // const BlackList_1_ADDRESS = "0xf0252f0D3D16e01C2D909566eA4Bf9Cb0e9B42C4"
        // const BlackList_2_ADDRESS = "0xd7E81990a68Cbb46a9a595232eE67D6b3B7cdB73"
        // // 0xf0252f0D3D16e01C2D909566eA4Bf9Cb0e9B42C4
        // // 0xd7E81990a68Cbb46a9a595232eE67D6b3B7cdB73

        // let tonHolderAddress = "0x2Db13E39eaf889A433E0CB23C38520419eC37202"
        // let wtonHolderAddress = "0x630D7e837F695432EAa0A4FaC037d386301909C8"





    })

    describe('# log', () => {
        it(" used gas",  async () => {
            const filePath = './outputFile/log-blacklist.txt';
            exportLogs(logs,filePath, 10)

            // console.log("tonTransferUsedGas", tonTransferUsedGas)
            // console.log("wtonTransferUsedGas", wtonTransferUsedGas)
        })
    })

})
