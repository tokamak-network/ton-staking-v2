import { expect } from './shared/expect'
import { ethers, network } from 'hardhat'
import { BigNumber, Signer } from 'ethers'
import { mine } from "@nomicfoundation/hardhat-network-helpers"
import {
        tonStakingV2Fixture,
        lastSeigBlock,
        globalWithdrawalDelay,
        seigManagerInfo,
        jsonFixtures } from './shared/fixtures'

import { TonStakingV2Fixtures, JSONFixture } from './shared/fixtureInterfaces'
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

describe('New Simple Staking Test', () => {
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: TonStakingV2Fixtures
    let jsonInfo: JSONFixture
    let layer2Info_level19 : any;
    let layer2Info_tokamak : any;
    let Operator : any;
    let Candidate : any;
    let snapshotInfo : any;

    before('create fixture loader', async () => {
        deployed = await tonStakingV2Fixture()
        jsonInfo = await jsonFixtures()
        deployer = deployed.deployer;
        addr1 = deployed.addr1;
        addr2 = deployed.addr2;
        layer2Info_level19 = {
            operatorAdmin: deployed.level19Admin,
            isLayer2Candidate: false,
            name: "level19_V2",
            committee: deployed.daoCommittee.address,
            layer2: null,
            operator: null,
            layerContract: null,
            coinageContract: null
        }

        layer2Info_tokamak = {
            operatorAdmin: deployed.tokamakAdmin,
            isLayer2Candidate: false,
            name: "tokamak_V2",
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
    describe('candidate ', () => {
      it('create candidate of level19 by daoCommitteeAdmin', async () => {
          const receipt = await (await deployed.daoCommittee.connect(
              deployed.daoCommitteeAdmin
          )["createCandidate(string,address)"](
              layer2Info_level19.name,
              layer2Info_level19.operatorAdmin,
          )).wait()
          // console.log(receipt)
          const topic = deployed.daoCommittee.interface.getEventTopic('CandidateContractCreated');
          const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
          const deployedEvent = deployed.daoCommittee.interface.parseLog(log!);
          layer2Info_level19.layer2 =  deployedEvent.args.candidateContract;
          layer2Info_level19.operator =  deployedEvent.args.candidate;
          expect(deployedEvent.args.memo).to.be.eq(layer2Info_level19.name)
          expect(layer2Info_level19.operator).to.be.eq(layer2Info_level19.operatorAdmin)
          expect(await deployed.layer2RegistryV2.numLayer2s()).to.be.eq(ethers.constants.One)
      })
      it('create candidate of tokamak ', async () => {
          const receipt = await (await deployed.daoCommittee.connect(
              deployed.daoCommitteeAdmin
          )["createCandidate(string,address)"](
              layer2Info_tokamak.name,
              layer2Info_tokamak.operatorAdmin,
          )).wait()
          const topic = deployed.daoCommittee.interface.getEventTopic('CandidateContractCreated');
          const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
          const deployedEvent = deployed.daoCommittee.interface.parseLog(log!);
          layer2Info_tokamak.layer2 =  deployedEvent.args.candidateContract;
          layer2Info_tokamak.operator =  deployedEvent.args.candidate;
          expect(deployedEvent.args.memo).to.be.eq(layer2Info_tokamak.name)
          expect(layer2Info_tokamak.operator).to.be.eq(layer2Info_tokamak.operatorAdmin)
          expect(await deployed.layer2RegistryV2.numLayer2s()).to.be.eq(BigNumber.from("2"))
      })
    });
    ////================================
    let addr2candidateContract: any;
    describe('=======ChangeMember by Anyone=======', () => {
      it('can create candidate by anyone', async () => {
        const receipt = await (await deployed.daoCommittee.connect(
            addr2
        )["createCandidate(string)"](
            "test"
        )).wait()
        const topic = deployed.daoCommittee.interface.getEventTopic('CandidateContractCreated');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = deployed.daoCommittee.interface.parseLog(log!);
        let addr2candidateContractAddress =  deployedEvent.args.candidateContract;
        const addr2operator =  deployedEvent.args.candidate;
        expect(deployedEvent.args.memo).to.be.eq("test")
        expect(addr2operator).to.be.eq(addr2.address)
        expect(await deployed.layer2RegistryV2.numLayer2s()).to.be.eq(BigNumber.from("3"))

        //set addr2candidateContract
        const Candidate = await ethers.getContractFactory("Candidate");
        addr2candidateContract = await Candidate.attach(addr2candidateContractAddress);
      })
      it('set fakeSeigManager and changeMember', async () => {
        //deploy fakeSeigManager
        const FakeSeigManager = await ethers.getContractFactory("FakeSeigManager");
        const fakeSeigManager = await FakeSeigManager.deploy();
        await fakeSeigManager.deployed();

        let receipt = await (await addr2candidateContract.connect(addr2)["initialize(address,bool,string,address,address)"](
          addr2.address,
          false,
          "test",
          deployed.daoCommittee.address,
          fakeSeigManager.address
        )).wait()

        //ChangedMember
        receipt = await (await addr2candidateContract.connect(addr2)["changeMember(uint256)"](
          1
        )).wait()
        const topic = deployed.daoCommittee.interface.getEventTopic('ChangedMember');
        const log = receipt.logs.find((x:any) => x.topics.indexOf(topic) >= 0);
        const changeMemberEvent = deployed.daoCommittee.interface.parseLog(log!);

        expect(changeMemberEvent.args.prevMember).to.be.eq(layer2Info_level19.operatorAdmin)
        expect(changeMemberEvent.args.newMember).to.be.eq(addr2.address)
      })
    })
  })