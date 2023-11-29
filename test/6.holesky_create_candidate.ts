import { expect } from './shared/expect'
import { ethers, network } from 'hardhat'
import { BigNumber, Signer } from 'ethers'
import { mine } from "@nomicfoundation/hardhat-network-helpers"

import {
    tonStakingV2HolskyFixture,
        lastSeigBlock,
        globalWithdrawalDelay,
        seigManagerInfo,
        jsonFixtures } from './shared/fixtures'

import { TonStakingV2HoleskyFixtures, JSONFixture } from './shared/fixtureInterfaces'
import { padLeft } from 'web3-utils'
import { marshalString, unmarshalString } from './shared/marshal';

function roundDown(val:BigNumber, decimals:number) {
    return ethers.utils.formatUnits(val, decimals).split(".")[0]
}

async function execAllowance(contract: any, fromSigner: Signer, toAddress: string, amount: BigNumber) {
    let allowance = await contract.allowance(fromSigner.address, toAddress);
    if (allowance.lt(amount)) {
        await contract.connect(fromSigner).approve(toAddress, amount);
    }
}

describe('Candidate Test', () => {
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: TonStakingV2HoleskyFixtures
    let jsonInfo: JSONFixture
    let layer2Info_1 : any;
    let layer2Info_2 : any;
    let layer2Info_num1 : any;
    let layer2Info_num2 : any;
    let layer2Info_num3 : any;
    let snapshotInfo : any;


    before('create fixture loader', async () => {
        deployed = await tonStakingV2HolskyFixture()
        jsonInfo = await jsonFixtures()

        deployer = deployed.deployer;
        addr1 = deployed.addr1;
        addr2 = deployed.addr2;

        layer2Info_num1 = {
            operatorAdmin: "0x43700f09B582eE2BFcCe4b5Db40ee41B4649D977",
            isLayer2Candidate: false,
            name: "TokamakOperator_v2",
            committee: deployed.daoCommittee.address,
            layer2: null,
            operator: null,
            layerContract: null,
            coinageContract: null
        }

        layer2Info_num2 = {
            operatorAdmin: "0xc1eba383D94c6021160042491A5dfaF1d82694E6",
            isLayer2Candidate: false,
            name: "ContractTeam_DAO_v2",
            committee: deployed.daoCommittee.address,
            layer2: null,
            operator: null,
            layerContract: null,
            coinageContract: null
        }

        layer2Info_num3 = {
            operatorAdmin: "0xf3D37602D501DC27e1bDbc841f174aDf337909D2",
            isLayer2Candidate: false,
            name: "ContractTeam_DAO2_v2",
            committee: deployed.daoCommittee.address,
            layer2: null,
            operator: null,
            layerContract: null,
            coinageContract: null
        }

        snapshotInfo = {
            account: null,
            snapshotId: null,
            totTotalSupply: ethers.constants.Zero,
            accountBalanceOfLayer2: ethers.constants.Zero,
            accountBalanceOfTotal: ethers.constants.Zero,
        }

    })

    // candidate 생성
    describe('candidate ', () => {
        it('create candidate of TokamakOperator_v2 by daoCommitteeAdmin', async () => {

            const receipt = await (await deployed.daoCommittee.connect(
                deployed.admin
            )["createCandidate(string,address)"](
                layer2Info_num1.name,
                layer2Info_num1.operatorAdmin,
            )).wait()

            // console.log(receipt)
            const topic = deployed.daoCommittee.interface.getEventTopic('CandidateContractCreated');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.daoCommittee.interface.parseLog(log);
            layer2Info_num1.layer2 =  deployedEvent.args.candidateContract;
            layer2Info_num1.operator =  deployedEvent.args.candidate;
            expect(deployedEvent.args.memo).to.be.eq(layer2Info_num1.name)
            expect(layer2Info_num1.operator).to.be.eq(layer2Info_num1.operatorAdmin)
            expect(await deployed.layer2RegistryV2.numLayer2s()).to.be.eq(ethers.constants.One)

        })

        it('create candidate of ContractTeam_DAO_v2 ', async () => {

            const receipt = await (await deployed.daoCommittee.connect(
                deployed.admin
            )["createCandidate(string,address)"](
                layer2Info_num2.name,
                layer2Info_num2.operatorAdmin,
            )).wait()

            const topic = deployed.daoCommittee.interface.getEventTopic('CandidateContractCreated');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.daoCommittee.interface.parseLog(log);
            layer2Info_num2.layer2 =  deployedEvent.args.candidateContract;
            layer2Info_num2.operator =  deployedEvent.args.candidate;
            expect(deployedEvent.args.memo).to.be.eq(layer2Info_num2.name)
            expect(layer2Info_num2.operator).to.be.eq(layer2Info_num2.operatorAdmin)
            expect(await deployed.layer2RegistryV2.numLayer2s()).to.be.eq(BigNumber.from("2"))

        })

        it('create candidate of ContractTeam_DAO2_v2 ', async () => {

            const receipt = await (await deployed.daoCommittee.connect(
                deployed.admin
            )["createCandidate(string,address)"](
                layer2Info_num2.name,
                layer2Info_num2.operatorAdmin,
            )).wait()

            const topic = deployed.daoCommittee.interface.getEventTopic('CandidateContractCreated');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.daoCommittee.interface.parseLog(log);
            layer2Info_num2.layer2 =  deployedEvent.args.candidateContract;
            layer2Info_num2.operator =  deployedEvent.args.candidate;
            expect(deployedEvent.args.memo).to.be.eq(layer2Info_num2.name)
            expect(layer2Info_num2.operator).to.be.eq(layer2Info_num2.operatorAdmin)
            expect(await deployed.layer2RegistryV2.numLayer2s()).to.be.eq(BigNumber.from("2"))

        })

    });

});