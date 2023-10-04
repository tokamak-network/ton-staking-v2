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

    // 새로운 버전 확인
    describe('New SeigManager ', () => {
        it('check storages', async () => {
            expect(await deployed.seigManagerV2.factory()).to.be.eq(deployed.coinageFactoryV2.address)
            expect(await deployed.seigManagerV2.registry()).to.be.eq(deployed.layer2RegistryProxy.address)
            expect(await deployed.seigManagerV2.depositManager()).to.be.eq(deployed.depositManagerV2.address)
            expect(await deployed.seigManagerV2.ton()).to.be.eq(deployed.TON.address)
            expect(await deployed.seigManagerV2.wton()).to.be.eq(deployed.WTON.address)


            expect(await deployed.seigManagerV2.powerton()).to.be.eq(deployed.powerTonAddress)
            expect(await deployed.seigManagerV2.minimumAmount()).to.be.eq(seigManagerInfo.minimumAmount)
            expect(await deployed.seigManagerV2.powerTONSeigRate()).to.be.eq(seigManagerInfo.powerTONSeigRate)
            expect(await deployed.seigManagerV2.daoSeigRate()).to.be.eq(seigManagerInfo.daoSeigRate)
            expect(await deployed.seigManagerV2.relativeSeigRate()).to.be.eq(seigManagerInfo.relativeSeigRate)
            expect(await deployed.seigManagerV2.paused()).to.be.eq(false)

            expect(await deployed.seigManagerV2.tot()).to.be.not.eq(ethers.constants.AddressZero)
            expect(await deployed.seigManagerV2.seigPerBlock()).to.be.eq(seigManagerInfo.seigPerBlock)
            expect(await deployed.seigManagerV2.lastSeigBlock()).to.be.eq(lastSeigBlock)

        })
    });

    describe('New DepositManager ', () => {
        it('check storages', async () => {
            expect(await deployed.depositManagerV2.wton()).to.be.eq(deployed.WTON.address)
            expect(await deployed.depositManagerV2.registry()).to.be.eq(deployed.layer2RegistryV2.address)
            expect(await deployed.depositManagerV2.seigManager()).to.be.eq(deployed.seigManagerV2.address)
            expect(await deployed.depositManagerV2.globalWithdrawalDelay()).to.be.eq(globalWithdrawalDelay)

        })
    });

    describe('New Layer2Registry ', () => {
        it('check storages', async () => {
            expect(await deployed.layer2RegistryV2.numLayer2s()).to.be.eq(ethers.constants.Zero)

        })
    });

    // 기존 디파짓 매니저 실행이 안되는것 확인
    describe('DepositManager v1 ', () => {
        it('deposit will be reverted ', async () => {
            let layer2Address = deployed.level19Address
            let tonAmount = ethers.utils.parseEther("100")
            await deployed.TON.connect(deployer).transfer(addr1.address, tonAmount);

            const data = marshalString(
                [deployed.depositManagerV1.address, layer2Address]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
              );

              await expect(
                 deployed.TON.connect(addr1).approveAndCall(
                    deployed.WTON.address,
                    tonAmount,
                    data,
                    {from: addr1.address}
                )).to.be.reverted;
        });

        it('deposit(address,uint256) will be reverted ', async () => {
            let layer2Address = deployed.level19Address
            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(addr1.address, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(addr1.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, addr1, deployed.depositManagerV2.address, wtonAmount);

            await expect(
                deployed.depositManagerV2.connect(addr1)["deposit(address,uint256)"](
                    layer2Address,
                    wtonAmount
                )
            ).to.be.reverted;

        });

    });

    // candidate 생성
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
            const deployedEvent = deployed.daoCommittee.interface.parseLog(log);
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
            const deployedEvent = deployed.daoCommittee.interface.parseLog(log);
            layer2Info_tokamak.layer2 =  deployedEvent.args.candidateContract;
            layer2Info_tokamak.operator =  deployedEvent.args.candidate;
            expect(deployedEvent.args.memo).to.be.eq(layer2Info_tokamak.name)
            expect(layer2Info_tokamak.operator).to.be.eq(layer2Info_tokamak.operatorAdmin)
            expect(await deployed.layer2RegistryV2.numLayer2s()).to.be.eq(BigNumber.from("2"))

        })
    });

    // deposit, unstake, withdraw , updateSeignorage
    describe('basic functions ', () => {
        it('deposit to level19 using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)

            let tonAmount = ethers.utils.parseEther("100")
            await deployed.TON.connect(deployer).transfer(addr1.address, tonAmount);

            const beforeBalance = await deployed.TON.balanceOf(addr1.address);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_level19.layer2, addr1.address)

            const data = marshalString(
                [deployed.depositManagerV2.address, layer2Info_level19.layer2]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
              );

            await deployed.TON.connect(addr1).approveAndCall(
                deployed.WTON.address,
                tonAmount,
                data,
                {from: addr1.address}
            );

            const afterBalance = await deployed.TON.balanceOf(addr1.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_level19.layer2, addr1.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 1)
            )
        })

        it('deposit to tokamak using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)

            let tonAmount = ethers.utils.parseEther("100")
            await deployed.TON.connect(deployer).transfer(addr1.address, tonAmount);

            const beforeBalance = await deployed.TON.balanceOf(addr1.address);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_tokamak.layer2, addr1.address)

            const data = marshalString(
                [deployed.depositManagerV2.address, layer2Info_tokamak.layer2]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
              );

            await deployed.TON.connect(addr1).approveAndCall(
                deployed.WTON.address,
                tonAmount,
                data,
                {from: addr1.address}
            );

            const afterBalance = await deployed.TON.balanceOf(addr1.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_tokamak.layer2, addr1.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 1)
            )
        })

        it('deposit to level19  ', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1

            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(account.address, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, account, deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            await deployed.depositManagerV2.connect(account)["deposit(address,uint256)"](
                layer2,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
        })

        it('deposit to level19  ', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1

            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(account.address, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, account, deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            await deployed.depositManagerV2.connect(account)["deposit(address,uint256)"](
                layer2,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
        })


        it('deposit to level19  ', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1

            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(account.address, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, account, deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            await deployed.depositManagerV2.connect(account)["deposit(address,uint256)"](
                layer2,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
        })


    });


});
