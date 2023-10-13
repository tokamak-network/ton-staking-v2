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

            expect(await deployed.coinageFactoryV2.autoCoinageLogic()).to.be.eq(deployed.refactorCoinageSnapshot.address)

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
            await (await deployed.TON.connect(deployer).transfer(addr1.address, tonAmount)).wait()

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
            await (await deployed.WTON.connect(deployer).transfer(addr1.address, wtonAmount)).wait()

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

            await (await deployed.TON.connect(addr1).approveAndCall(
                deployed.WTON.address,
                tonAmount,
                data,
                {from: addr1.address}
            )).wait()

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

            await (await deployed.TON.connect(addr1).approveAndCall(
                deployed.WTON.address,
                tonAmount,
                data,
                {from: addr1.address}
            )).wait()

            const afterBalance = await deployed.TON.balanceOf(addr1.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_tokamak.layer2, addr1.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 1)
            )
        })

        it('deposit to level19 using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)

            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(addr1.address, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(addr1.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, addr1, deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_level19.layer2, addr1.address)

            await (await deployed.depositManagerV2.connect(addr1)["deposit(address,uint256)"](
                layer2Info_level19.layer2,
                wtonAmount
            )).wait()

            const afterBalance = await deployed.WTON.balanceOf(addr1.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_level19.layer2, addr1.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
        })

        it('deposit to tokamak using deposit(address,address,uint256) ', async () => {
            // console.log(deployed.seigManagerV2)

            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            // await deployed.WTON.connect(deployer).transfer(addr1.address, wtonAmount);

            const beforeSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, deployer, deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_tokamak.layer2, addr1.address)

            await (await deployed.depositManagerV2.connect(deployer)["deposit(address,address,uint256)"](
                layer2Info_tokamak.layer2,
                addr1.address,
                wtonAmount
            )).wait()

            const afterSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_tokamak.layer2, addr1.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
        })

        it('deposit to tokamak using deposit(address,address[],uint256[]) ', async () => {
            // console.log(deployed.seigManagerV2)

            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            let wtonAmount1 = ethers.utils.parseEther("30"+"0".repeat(9))
            let wtonAmount2 = ethers.utils.parseEther("70"+"0".repeat(9))
            // await deployed.WTON.connect(deployer).transfer(addr1.address, wtonAmount);

            const beforeSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, deployer, deployed.depositManagerV2.address, wtonAmount);

            let stakedA1 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_tokamak.layer2, addr1.address)
            let stakedA2 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_tokamak.layer2, addr2.address)

            await (await deployed.depositManagerV2.connect(deployer)["deposit(address,address[],uint256[])"](
                layer2Info_tokamak.layer2,
                [addr1.address, addr2.address],
                [wtonAmount1, wtonAmount2]
            )).wait()

            const afterSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB1 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_tokamak.layer2, addr1.address)
            let stakedB2 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_tokamak.layer2, addr2.address)

            expect(roundDown(stakedB1.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA1.add(wtonAmount1), 1)
            )
            expect(roundDown(stakedB2.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA2.add(wtonAmount2), 1)
            )
        })

        it('updateSeigniorage to level19 will be fail when minimumAmount is insufficient.', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");

            layer2Info_level19.layerContract = new ethers.Contract(
                layer2Info_level19.layer2, jsonInfo.Candidate.abi, deployer
            );

            await expect(
                layer2Info_level19.layerContract.connect(addr1).updateSeigniorage()
            ).to.be.rejectedWith("minimumAmount is insufficient")

        });

        it('updateSeigniorage to level19', async () => {
            let wtonAmount = ethers.utils.parseEther("1000"+"0".repeat(9))

            await execAllowance(deployed.WTON, deployer, deployed.depositManagerV2.address, wtonAmount);

            await (await deployed.depositManagerV2.connect(deployer)["deposit(address,address,uint256)"](
                layer2Info_level19.layer2,
                layer2Info_level19.operator,
                wtonAmount
            )).wait();

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_level19.layer2, addr1.address)

            let powerTonBalance = await deployed.WTON.balanceOf(deployed.powerTonAddress);
            await (await layer2Info_level19.layerContract.connect(addr1).updateSeigniorage()).wait()

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_level19.layer2, addr1.address)

            expect(stakedB).to.be.gt(stakedA)
            expect(await deployed.WTON.balanceOf(deployed.powerTonAddress)).to.be.gt(powerTonBalance)
        })

        it('requestWithdrawal to level19', async () => {

            let layer2 = layer2Info_level19.layer2
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("50"+"0".repeat(9))

            const beforeBalance = await deployed.WTON.balanceOf(account.address)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
            let pendingUnstakedA = await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await deployed.depositManagerV2.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await deployed.depositManagerV2.pendingUnstakedAccount(account.address)

            await (await deployed.depositManagerV2.connect(account)["requestWithdrawal(address,uint256)"](
                layer2Info_level19.layer2,
                wtonAmount
            )).wait()

            const afterBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_level19.layer2, account.address)

            expect(roundDown(stakedA.sub(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedB.add(wtonAmount), 1)
            )

            expect(
                await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
            ).to.be.eq(pendingUnstakedA.add(wtonAmount))

            expect(
                await deployed.depositManagerV2.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

            expect(
                await deployed.depositManagerV2.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

        })

        it('processRequest to level19 will be fail when delay time didn\'t pass.', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1

            await expect(
                    deployed.depositManagerV2.connect(account)["processRequest(address,bool)"](
                    layer2,
                    true
                )
            ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

        });

        it('processRequest to level19.', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1
            const beforeBalance = await deployed.TON.balanceOf(account.address)
            let pendingUnstakedA = await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await deployed.depositManagerV2.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await deployed.depositManagerV2.pendingUnstakedAccount(account.address)

            let accUnstakedA = await deployed.depositManagerV2.accUnstaked(layer2, account.address)
            let accUnstakedLayer2A = await deployed.depositManagerV2.accUnstakedLayer2(layer2)
            let accUnstakedAccountA = await deployed.depositManagerV2.accUnstakedAccount(account.address)


            let globalWithdrawalDelay = await deployed.depositManagerV2.globalWithdrawalDelay()

            await mine(globalWithdrawalDelay, { interval: 12 });

            await (await  deployed.depositManagerV2.connect(account)["processRequest(address,bool)"](
                layer2,
                true
            )).wait()

            const afterBalance = await deployed.TON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.add(pendingUnstakedA.div(BigNumber.from("1"+"0".repeat(9)))))

            expect(
                await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
            ).to.be.eq(ethers.constants.Zero)

            expect(
                await deployed.depositManagerV2.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.sub(pendingUnstakedA))

            expect(
                await deployed.depositManagerV2.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.sub(pendingUnstakedA))

            expect(
                await deployed.depositManagerV2.accUnstaked(layer2, account.address)
            ).to.be.eq(accUnstakedA.add(pendingUnstakedA))

            expect(
                await deployed.depositManagerV2.accUnstakedLayer2(layer2 )
            ).to.be.eq(accUnstakedLayer2A.add(pendingUnstakedA))

            expect(
                await deployed.depositManagerV2.accUnstakedAccount(account.address)
            ).to.be.eq(accUnstakedAccountA.add(pendingUnstakedA))

        });

    });

    describe('updateSeigniorage', () => {

        it('deposit to tokamak using deposit(address,address,uint256) ', async () => {
            let layer2 = layer2Info_tokamak.layer2
            let operator = layer2Info_tokamak.operatorAdmin
            let wtonAmount = ethers.utils.parseEther("1000"+"0".repeat(9))
            const beforeSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, deployer, deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, operator)

            await (await deployed.depositManagerV2.connect(deployer)["deposit(address,address,uint256)"](
                layer2,
                operator,
                wtonAmount
            )).wait()

            const afterSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, operator)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
        })

        // 업데이트 시뇨리지를 모든 레이어를 한번에 , 한 트랜잭션에 실행 할 수 없다.
        // tot 업데이트를 매번 실행하기 때문에 이미 tot 업데이트를 했으므로.
        it('updateSeigniorageAll ', async () => {

            let num = await deployed.layer2RegistryV2.numLayer2s();
            let i = 0
            for(i = 0; i < num.toNumber() ; i++){
                await mine(3, { interval: 12 });
                let layer2 = await deployed.layer2RegistryV2.layer2ByIndex(i);
                await (await deployed.seigManagerV2.connect(deployer)["updateSeigniorageLayer(address)"](layer2)).wait()
            }

        });

        it('deposit to level19', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1
            let tonAmount = ethers.utils.parseEther("100")
            await deployed.TON.connect(deployer).transfer(account.address, tonAmount);

            const beforeBalance = await deployed.TON.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            const data = marshalString(
                [deployed.depositManagerV2.address, layer2]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
            );

            await (await deployed.TON.connect(account).approveAndCall(
                deployed.WTON.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()

            const afterBalance = await deployed.TON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            let wtonAmount = tonAmount.mul(ethers.BigNumber.from("1"+"0".repeat(9)))
            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )

        })

    })


    describe('snapshot functions', () => {
        it('deposit to level19', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1
            let tonAmount = ethers.utils.parseEther("100")
            await deployed.TON.connect(deployer).transfer(account.address, tonAmount);

            const beforeBalance = await deployed.TON.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            const data = marshalString(
                [deployed.depositManagerV2.address, layer2]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
            );

            await (await deployed.TON.connect(account).approveAndCall(
                deployed.WTON.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()

            const afterBalance = await deployed.TON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            let wtonAmount = tonAmount.mul(ethers.BigNumber.from("1"+"0".repeat(9)))
            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )

        })

        it('snapshot()', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1
            snapshotInfo.account = account.address
            snapshotInfo.totTotalSupply = await deployed.seigManagerV2.stakeOfTotal()
            snapshotInfo.accountBalanceOfLayer2 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
            snapshotInfo.accountBalanceOfTotal = await deployed.seigManagerV2["stakeOf(address)"](account.address)

            const receipt = await (await deployed.seigManagerV2.connect(account).onSnapshot()).wait()
            const topic = deployed.seigManagerV2.interface.getEventTopic('OnSnapshot');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);

            snapshotInfo.snapshotId = deployedEvent.args.snapshotId

        });

        it('deposit to level19  ', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1

            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(account.address, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, account, deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            await (await deployed.depositManagerV2.connect(account)["deposit(address,uint256)"](
                layer2,
                wtonAmount
            )).wait()

            const afterBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
        })

        it('snapshot data is accurate ', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1

            let accountBalanceOfTotal= await deployed.seigManagerV2["stakeOf(address)"](account.address)
            let totTotalSupply= await deployed.seigManagerV2["stakeOfTotal()"]()

            let accountBalanceOfTotalAt = await deployed.seigManagerV2["stakeOfAt(address,uint256)"](account.address, snapshotInfo.snapshotId)
            let totTotalSupplyAt = await deployed.seigManagerV2["stakeOfTotalAt(uint256)"](snapshotInfo.snapshotId)

            expect(accountBalanceOfTotal).to.be.gt(accountBalanceOfTotalAt)
            expect(totTotalSupply).to.be.gt(totTotalSupplyAt)

            expect(accountBalanceOfTotalAt).to.be.eq(snapshotInfo.accountBalanceOfTotal)
            expect(totTotalSupplyAt).to.be.eq(snapshotInfo.totTotalSupply)

        });


        it('requestWithdrawal to level19', async () => {

            let layer2 = layer2Info_level19.layer2
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("50"+"0".repeat(9))

            const beforeBalance = await deployed.WTON.balanceOf(account.address)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
            let pendingUnstakedA = await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await deployed.depositManagerV2.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await deployed.depositManagerV2.pendingUnstakedAccount(account.address)

            await (await deployed.depositManagerV2.connect(account)["requestWithdrawal(address,uint256)"](
                layer2Info_level19.layer2,
                wtonAmount
            )).wait();

            const afterBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_level19.layer2, account.address)

            expect(roundDown(stakedA.sub(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedB.add(wtonAmount), 1)
            )

            expect(
                await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
            ).to.be.eq(pendingUnstakedA.add(wtonAmount))

            expect(
                await deployed.depositManagerV2.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

            expect(
                await deployed.depositManagerV2.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

        })

        it('snapshot()', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1
            snapshotInfo.account = account.address
            snapshotInfo.totTotalSupply = await deployed.seigManagerV2.stakeOfTotal()
            snapshotInfo.accountBalanceOfLayer2 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
            snapshotInfo.accountBalanceOfTotal = await deployed.seigManagerV2["stakeOf(address)"](account.address)

            const receipt = await (await deployed.seigManagerV2.connect(account).onSnapshot()).wait()
            const topic = deployed.seigManagerV2.interface.getEventTopic('OnSnapshot');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);

            snapshotInfo.snapshotId = deployedEvent.args.snapshotId
        });

        it('requestWithdrawal to level19', async () => {

            let layer2 = layer2Info_level19.layer2
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

            const beforeBalance = await deployed.WTON.balanceOf(account.address)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
            let pendingUnstakedA = await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await deployed.depositManagerV2.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await deployed.depositManagerV2.pendingUnstakedAccount(account.address)

            await deployed.depositManagerV2.connect(account)["requestWithdrawal(address,uint256)"](
                layer2Info_level19.layer2,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_level19.layer2, account.address)

            expect(roundDown(stakedA.sub(ethers.constants.Two),2)).to.be.eq(
                roundDown(stakedB.add(wtonAmount), 2)
            )

            expect(
                await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
            ).to.be.eq(pendingUnstakedA.add(wtonAmount))

            expect(
                await deployed.depositManagerV2.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

            expect(
                await deployed.depositManagerV2.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

        })

        it('snapshot data is accurate ', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1

            let accountBalanceOfTotal= await deployed.seigManagerV2["stakeOf(address)"](account.address)
            let totTotalSupply= await deployed.seigManagerV2["stakeOfTotal()"]()

            let accountBalanceOfTotalAt = await deployed.seigManagerV2["stakeOfAt(address,uint256)"](account.address, snapshotInfo.snapshotId)
            let totTotalSupplyAt = await deployed.seigManagerV2["stakeOfTotalAt(uint256)"](snapshotInfo.snapshotId)

            expect(accountBalanceOfTotal).to.be.lt(accountBalanceOfTotalAt)
            expect(totTotalSupply).to.be.lt(totTotalSupplyAt)

            expect(accountBalanceOfTotalAt).to.be.eq(snapshotInfo.accountBalanceOfTotal)
            expect(totTotalSupplyAt).to.be.eq(snapshotInfo.totTotalSupply)

        });


    });


});
