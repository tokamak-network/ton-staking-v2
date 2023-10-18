import { expect } from './shared/expect'
import { ethers, deployments, getNamedAccounts, network } from 'hardhat'
import { BigNumber, Signer } from 'ethers'
import { mine } from "@nomicfoundation/hardhat-network-helpers"

import {
        tonStakingV2Fixture,
        deployedTonStakingV2Fixture,
        lastSeigBlock,
        globalWithdrawalDelay,
        seigManagerInfo,
        jsonFixtures } from './shared/fixtures'

import { TonStakingV2Fixtures, JSONFixture, SnapshotInfo, SnapshotLayer, CalculatedSeig } from './shared/fixtureInterfaces'
import { padLeft } from 'web3-utils'
import { marshalString, unmarshalString } from './shared/marshal';

import { readContracts, deployedContracts } from "./common_func"
import { calcSeigniorage , calcSeigniorageWithTonStakingV2Fixtures } from "./common_seig_func"

function roundDown(val:BigNumber, decimals:number) {
    return ethers.utils.formatUnits(val, decimals).split(".")[0]
}

async function execAllowance(contract: any, fromSigner: Signer, toAddress: string, amount: BigNumber) {
    let allowance = await contract.allowance(fromSigner.address, toAddress);
    if (allowance.lt(amount)) {
        await contract.connect(fromSigner).approve(toAddress, amount);
    }
}

function logSnapshots(infos:Array<SnapshotInfo> ) {
    console.log('< logSnapshots > ')

    let i = 0;
    infos.forEach((e) => {
        console.log('------ ' , i ,'---------' )
        console.log(' account :' , e.account)
        console.log(' snapshotId :' , e.snapshotId)
        console.log(' totTotalSupply :' , ethers.utils.formatUnits(e.totTotalSupply, 27), "WTON")
        console.log(' accountBalanceOfTotal :' , ethers.utils.formatUnits(e.accountBalanceOfTotal, 27), "WTON")
        console.log(' snapshotLayers :' , e.snapshotLayers)
        i++
    })
}

async function checkSnapshots(deployed:TonStakingV2Fixtures, jsonInfo: JSONFixture, infos:Array<SnapshotInfo>) {
    let i = 0;

    for (i = 0; i < infos.length ; i++) {
        let element = infos[i]
        let stakedAcount = await deployed.seigManagerV2["stakeOfAt(address,uint256)"](element.account, element.snapshotId)
        let stakeOfTotal = await deployed.seigManagerV2["stakeOfTotalAt(uint256)"](element.snapshotId)
        expect(stakedAcount).to.be.eq(element.accountBalanceOfTotal)
        expect(stakeOfTotal).to.be.eq(element.totTotalSupply)

        for(let j=0; j < element.snapshotLayers.length; j++) {
            let layer2 = element.snapshotLayers[j]
            let stakeOfLayerAccount = await deployed.seigManagerV2["stakeOfAt(address,address,uint256)"](layer2.layerAddress, element.account, element.snapshotId)
            let coinage = new ethers.Contract((await deployed.seigManagerV2.coinages(layer2.layerAddress)), jsonInfo.RefactorCoinageSnapshot.abi, ethers.provider)
            let stakeOfLayerTotal = await coinage.totalSupplyAt(element.snapshotId)

            expect(stakeOfLayerAccount).to.be.eq(layer2.accountBalance)
            expect(stakeOfLayerTotal).to.be.eq(layer2.totalSupply)
        }
    }
}

//-----------------------------------------
// Test process ( using nvm use v16.10.0)
// 1. First terminal : npx hardhat node --fork https://mainnet.infura.io/v3/000000  --fork-block-number xxxxx
//                        fork-block-number must be greater than 18169346 (lastSeigBlock)
// 2. Second terminal : npx hardhat deploy --reset --network local
// 3. Second terminal : npx hardhat test test/0.test.sample.ts --network local


describe('TON Staking V2 Test', () => {
    let networkName: string
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: TonStakingV2Fixtures
    let jsonInfo: JSONFixture
    let contractInfos : any;

    let layer2Info_level19 : any;
    let layer2Info_tokamak : any;
    let Operator : any;
    let Candidate : any;
    let snapshotInfos : Array<SnapshotInfo>


    before('create fixture loader', async () => {
        networkName = network.name;
        console.log('networkName', networkName)

        jsonInfo = await jsonFixtures()
        // deployed = await deployedTonStakingV2Fixture()
        deployed = await tonStakingV2Fixture()

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
            coinageContract: null,
            commissionRate: ethers.constants.Zero,
            isCommissionRateNegative: false
        }

        layer2Info_tokamak = {
            operatorAdmin: deployed.tokamakAdmin,
            isLayer2Candidate: false,
            name: "tokamak_V2",
            committee: deployed.daoCommittee.address,
            layer2: null,
            operator: null,
            layerContract: null,
            coinageContract: null,
            commissionRate: ethers.BigNumber.from("25000000000000000000000000"),
            isCommissionRateNegative: false
        }

        snapshotInfos = []

    })

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

    describe('setCommissionRate ', () => {
        it('Operator can execute setCommissionRate ', async () => {
            await expect(
                deployed.seigManagerV2.connect(addr1).setCommissionRate(
                    layer2Info_tokamak.layer2,
                    layer2Info_tokamak.commissionRate,
                    layer2Info_tokamak.isCommissionRateNegative
                )
            ).to.be.reverted;
        })

        it('onlyOwner can execute setCommissionRateOnlyOwner ', async () => {
            await deployed.seigManagerProxy.connect(deployer).upgradeTo(deployed.seigManagerMigrationImp.address);
            const seigManagerMigration = new ethers.Contract(
                deployed.seigManagerV2.address,
                jsonInfo.SeigManagerMigration.abi,
                deployer
            );
            await expect(
                seigManagerMigration.connect(addr1).setCommissionRateOnlyOwner(
                    layer2Info_tokamak.layer2,
                    layer2Info_tokamak.commissionRate,
                    layer2Info_tokamak.isCommissionRateNegative
                )
            ).to.be.reverted;


        })

        it('setCommissionRateOnlyOwner ', async () => {

            const seigManagerMigration = new ethers.Contract(
                deployed.seigManagerV2.address,
                jsonInfo.SeigManagerMigration.abi,
                deployer
            );

            const receipt = await (await seigManagerMigration.connect(deployer).setCommissionRateOnlyOwner(
                layer2Info_tokamak.layer2,
                layer2Info_tokamak.commissionRate,
                layer2Info_tokamak.isCommissionRateNegative
            )).wait()
            const topic = seigManagerMigration.interface.getEventTopic('CommissionRateSet');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManagerMigration.interface.parseLog(log);

            expect(deployedEvent.args.layer2).to.be.eq(layer2Info_tokamak.layer2)
            expect(deployedEvent.args.newRate).to.be.eq(layer2Info_tokamak.commissionRate)
            expect(await seigManagerMigration.commissionRates(layer2Info_tokamak.layer2)).to.be.eq(layer2Info_tokamak.commissionRate)
            expect(await seigManagerMigration.isCommissionRateNegative(layer2Info_tokamak.layer2)).to.be.eq(layer2Info_tokamak.isCommissionRateNegative)

            await deployed.seigManagerProxy.connect(deployer).upgradeTo(deployed.seigManagerV2Imp.address);

        })

    })

    describe('basic functions ', () => {

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

            await (await deployed.TON.connect(account)["approveAndCall(address,uint256,bytes)"](
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

            let stakedAcount = await deployed.seigManagerV2["stakeOf(address)"](account.address)
            let stakeOfTotal = await deployed.seigManagerV2["stakeOfTotal()"]()

            let coinage = new ethers.Contract((await deployed.seigManagerV2.coinages(layer2)), jsonInfo.RefactorCoinageSnapshot.abi, ethers.provider)
            let stakeOfLayerTotal = await coinage.totalSupply()

            expect(stakedB).to.be.eq(stakedAcount)
            expect(stakedB).to.be.eq(stakeOfTotal)
            expect(stakedB).to.be.eq(stakeOfLayerTotal)

        })

        it('snapshot()', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr1

            let snapshotInfo: SnapshotInfo = {
                account: account.address,
                snapshotId: BigNumber.from("0"),
                totTotalSupply: BigNumber.from("0"),
                snapshotLayers: [],
                accountBalanceOfTotal: BigNumber.from("0")
            }

            snapshotInfo.totTotalSupply = await deployed.seigManagerV2.stakeOfTotal()
            snapshotInfo.accountBalanceOfTotal = await deployed.seigManagerV2["stakeOf(address)"](account.address)

            let coinage = new ethers.Contract((await deployed.seigManagerV2.coinages(layer2)), jsonInfo.RefactorCoinageSnapshot.abi, ethers.provider)
            let snapshotLayer: SnapshotLayer = {layerAddress:layer2, totalSupply: ethers.constants.Zero, accountBalance: ethers.constants.Zero}
            snapshotLayer.accountBalance = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
            snapshotLayer.totalSupply = await coinage.totalSupply()

            snapshotInfo.snapshotLayers.push(snapshotLayer)

            const receipt = await (await deployed.seigManagerV2.connect(account).onSnapshot()).wait()
            const topic = deployed.seigManagerV2.interface.getEventTopic('OnSnapshot');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);

            snapshotInfo.snapshotId = deployedEvent.args.snapshotId
            snapshotInfos.push(snapshotInfo)
            await checkSnapshots(deployed, jsonInfo, snapshotInfos)
        });

        it('deposit to tokamak using deposit(address,address,uint256) ', async () => {
            let layer2 = layer2Info_tokamak.layer2
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            // await deployed.WTON.connect(deployer).transfer(addr1.address, wtonAmount);
            let stakeOfTotalPrev = await deployed.seigManagerV2["stakeOfTotal()"]()
            let stakedAcountPrev = await deployed.seigManagerV2["stakeOf(address)"](account.address)

            const beforeSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, deployer, deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            await (await deployed.depositManagerV2.connect(deployer)["deposit(address,address,uint256)"](
                layer2,
                account.address,
                wtonAmount
            )).wait()

            const afterSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )

            let stakedAcount = await deployed.seigManagerV2["stakeOf(address)"](account.address)
            let stakeOfTotal = await deployed.seigManagerV2["stakeOfTotal()"]()

            let coinage = new ethers.Contract((await deployed.seigManagerV2.coinages(layer2)), jsonInfo.RefactorCoinageSnapshot.abi, ethers.provider)
            let stakeOfLayerTotal = await coinage.totalSupply()

            expect(stakedB).to.be.eq(stakeOfLayerTotal)
            expect(stakeOfTotal).to.be.gt(stakedB)
            expect(stakedAcount).to.be.gt(stakedB)
            expect(stakedAcount).to.be.eq(stakedAcountPrev.add(wtonAmount))
            expect(stakeOfTotal).to.be.eq(stakeOfTotalPrev.add(wtonAmount))
        })

        it('snapshot()', async () => {
            let layer2s = [layer2Info_level19.layer2, layer2Info_tokamak.layer2]
            let account = addr1

            let snapshotInfo: SnapshotInfo = {
                account: account.address,
                snapshotId: BigNumber.from("0"),
                totTotalSupply: BigNumber.from("0"),
                snapshotLayers: [],
                accountBalanceOfTotal: BigNumber.from("0")
            }

            snapshotInfo.totTotalSupply = await deployed.seigManagerV2.stakeOfTotal()
            snapshotInfo.accountBalanceOfTotal = await deployed.seigManagerV2["stakeOf(address)"](account.address)

            for(let i = 0; i < layer2s.length; i++) {
                let layer2 = layer2s[i]
                let coinage = new ethers.Contract((await deployed.seigManagerV2.coinages(layer2)), jsonInfo.RefactorCoinageSnapshot.abi, ethers.provider)
                let snapshotLayer: SnapshotLayer = {layerAddress:layer2, totalSupply: ethers.constants.Zero, accountBalance: ethers.constants.Zero}
                snapshotLayer.accountBalance = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
                snapshotLayer.totalSupply = await coinage.totalSupply()

                snapshotInfo.snapshotLayers.push(snapshotLayer)
            }

            const receipt = await (await deployed.seigManagerV2.connect(account).onSnapshot()).wait()
            const topic = deployed.seigManagerV2.interface.getEventTopic('OnSnapshot');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);

            snapshotInfo.snapshotId = deployedEvent.args.snapshotId
            snapshotInfos.push(snapshotInfo)
            // logSnapshots(snapshotInfos);
            await checkSnapshots(deployed, jsonInfo, snapshotInfos)
        });

        it('updateSeigniorage to level19', async () => {

            layer2Info_level19.layerContract = new ethers.Contract(layer2Info_level19.layer2, jsonInfo.Candidate.abi, ethers.provider)
            let layer2 = layer2Info_level19
            let account = addr1

            let wtonAmount = ethers.utils.parseEther("1000"+"0".repeat(9))

            await execAllowance(deployed.WTON, deployer, deployed.depositManagerV2.address, wtonAmount);

            await (await deployed.depositManagerV2.connect(deployer)["deposit(address,address,uint256)"](
                layer2.layer2,
                layer2.operator,
                wtonAmount
            )).wait();

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2.layer2, account.address)
            let powerTonBalance = await deployed.WTON.balanceOf(deployed.powerTonAddress);

            let block = await ethers.provider.getBlock('latest')
            let blockNumber =  block.number+1
            let toBlock = BigNumber.from(''+blockNumber)
            let calcSeigs: CalculatedSeig = await calcSeigniorageWithTonStakingV2Fixtures(deployed, jsonInfo, toBlock.toNumber(), layer2.layer2)

            // console.log('calcSeigs' , calcSeigs)

            const receipt = await (await layer2.layerContract.connect(account).updateSeigniorage()).wait()

            const topic = deployed.seigManagerV2.interface.getEventTopic('UpdatedSeigniorage');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);
            // console.log(deployedEvent.args)

            const topic1 = deployed.seigManagerV2.interface.getEventTopic('AddedSeigAtLayer');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = deployed.seigManagerV2.interface.parseLog(log1);
            // console.log("AddedSeigAtLayer", deployedEvent1.args)

            expect(deployedEvent.args.layer2).to.be.eq(layer2.layer2)
            expect(deployedEvent.args.blockNumber).to.be.eq(toBlock)
            expect(deployedEvent.args.prevTotal).to.be.eq(calcSeigs.coinageTotalSupply)

            expect(deployedEvent.args.oldCoinageFactor).to.be.eq(calcSeigs.coinageFactor)

            expect(roundDown(deployedEvent.args.nextTotal, 6)).to.be.eq(
                roundDown(calcSeigs.nextLayerTotalSupply, 6)
            )

            expect(roundDown(deployedEvent.args.nextTotFactor,3)).to.be.eq(
                roundDown(calcSeigs.newTotFactor, 3)
            )
            expect(roundDown(deployedEvent.args.nextCoinageFactor,6)).to.be.eq(
                roundDown(calcSeigs.newCoinageFactor, 6)
            )

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2.layer2, account.address)

            expect(stakedB).to.be.gt(stakedA)
            expect(await deployed.WTON.balanceOf(deployed.powerTonAddress)).to.be.gt(powerTonBalance)

        })

        it('snapshot()', async () => {
            let layer2s = [layer2Info_level19.layer2, layer2Info_tokamak.layer2]
            let account = addr1

            let snapshotInfo: SnapshotInfo = {
                account: account.address,
                snapshotId: BigNumber.from("0"),
                totTotalSupply: BigNumber.from("0"),
                snapshotLayers: [],
                accountBalanceOfTotal: BigNumber.from("0")
            }

            snapshotInfo.totTotalSupply = await deployed.seigManagerV2.stakeOfTotal()
            snapshotInfo.accountBalanceOfTotal = await deployed.seigManagerV2["stakeOf(address)"](account.address)

            for(let i = 0; i < layer2s.length; i++) {
                let layer2 = layer2s[i]
                let coinage = new ethers.Contract((await deployed.seigManagerV2.coinages(layer2)), jsonInfo.RefactorCoinageSnapshot.abi, ethers.provider)
                let snapshotLayer: SnapshotLayer = {layerAddress:layer2, totalSupply: ethers.constants.Zero, accountBalance: ethers.constants.Zero}
                snapshotLayer.accountBalance = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
                snapshotLayer.totalSupply = await coinage.totalSupply()

                snapshotInfo.snapshotLayers.push(snapshotLayer)
            }

            const receipt = await (await deployed.seigManagerV2.connect(account).onSnapshot()).wait()
            const topic = deployed.seigManagerV2.interface.getEventTopic('OnSnapshot');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);

            snapshotInfo.snapshotId = deployedEvent.args.snapshotId
            snapshotInfos.push(snapshotInfo)
            // logSnapshots(snapshotInfos);
            await checkSnapshots(deployed, jsonInfo, snapshotInfos)
        });

        it('updateSeigniorage to tokamak', async () => {

            layer2Info_tokamak.layerContract = new ethers.Contract(layer2Info_tokamak.layer2, jsonInfo.Candidate.abi, ethers.provider)
            let layer2 = layer2Info_tokamak
            let account = addr1

            let wtonAmount = ethers.utils.parseEther("1000"+"0".repeat(9))

            await execAllowance(deployed.WTON, deployer, deployed.depositManagerV2.address, wtonAmount);

            await (await deployed.depositManagerV2.connect(deployer)["deposit(address,address,uint256)"](
                layer2.layer2,
                layer2.operator,
                wtonAmount
            )).wait();

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2.layer2, account.address)
            let powerTonBalance = await deployed.WTON.balanceOf(deployed.powerTonAddress);

            let block = await ethers.provider.getBlock('latest')
            let blockNumber =  block.number+1
            let toBlock = BigNumber.from(''+blockNumber)
            let calcSeigs: CalculatedSeig = await calcSeigniorageWithTonStakingV2Fixtures(deployed, jsonInfo, toBlock.toNumber(), layer2.layer2)

            // console.log('calcSeigs' , calcSeigs)

            const receipt = await (await layer2.layerContract.connect(account).updateSeigniorage()).wait()
            const topic = deployed.seigManagerV2.interface.getEventTopic('UpdatedSeigniorage');

            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);
            // console.log(deployedEvent.args)

            const topic1 = deployed.seigManagerV2.interface.getEventTopic('AddedSeigAtLayer');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = deployed.seigManagerV2.interface.parseLog(log1);
            // console.log("AddedSeigAtLayer", deployedEvent1.args)

            expect(deployedEvent.args.layer2).to.be.eq(layer2.layer2)
            expect(deployedEvent.args.blockNumber).to.be.eq(toBlock)
            expect(deployedEvent.args.prevTotal).to.be.eq(calcSeigs.coinageTotalSupply)

            expect(deployedEvent.args.oldCoinageFactor).to.be.eq(calcSeigs.coinageFactor)

            expect(roundDown(deployedEvent.args.nextTotal, 6)).to.be.eq(
                roundDown(calcSeigs.nextLayerTotalSupply, 6)
            )

            expect(roundDown(deployedEvent.args.nextTotFactor,3)).to.be.eq(
                roundDown(calcSeigs.newTotFactor, 3)
            )
            expect(roundDown(deployedEvent.args.nextCoinageFactor,6)).to.be.eq(
                roundDown(calcSeigs.newCoinageFactor, 6)
            )

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2.layer2, account.address)

            expect(stakedB).to.be.gt(stakedA)
            expect(await deployed.WTON.balanceOf(deployed.powerTonAddress)).to.be.gt(powerTonBalance)

        })

        it('snapshot()', async () => {
            let layer2s = [layer2Info_level19.layer2, layer2Info_tokamak.layer2]
            let account = addr1

            let snapshotInfo: SnapshotInfo = {
                account: account.address,
                snapshotId: BigNumber.from("0"),
                totTotalSupply: BigNumber.from("0"),
                snapshotLayers: [],
                accountBalanceOfTotal: BigNumber.from("0")
            }

            snapshotInfo.totTotalSupply = await deployed.seigManagerV2.stakeOfTotal()
            snapshotInfo.accountBalanceOfTotal = await deployed.seigManagerV2["stakeOf(address)"](account.address)

            for(let i = 0; i < layer2s.length; i++) {
                let layer2 = layer2s[i]
                let coinage = new ethers.Contract((await deployed.seigManagerV2.coinages(layer2)), jsonInfo.RefactorCoinageSnapshot.abi, ethers.provider)
                let snapshotLayer: SnapshotLayer = {layerAddress:layer2, totalSupply: ethers.constants.Zero, accountBalance: ethers.constants.Zero}
                snapshotLayer.accountBalance = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
                snapshotLayer.totalSupply = await coinage.totalSupply()

                snapshotInfo.snapshotLayers.push(snapshotLayer)
            }

            const receipt = await (await deployed.seigManagerV2.connect(account).onSnapshot()).wait()
            const topic = deployed.seigManagerV2.interface.getEventTopic('OnSnapshot');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);

            snapshotInfo.snapshotId = deployedEvent.args.snapshotId
            snapshotInfos.push(snapshotInfo)
            // logSnapshots(snapshotInfos);
            await checkSnapshots(deployed, jsonInfo, snapshotInfos)
        });

        it('deposit to level19 using deposit(address,address,uint256) ', async () => {
            let layer2 = layer2Info_level19.layer2
            let account = addr2
            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            // await deployed.WTON.connect(deployer).transfer(addr1.address, wtonAmount);
            let stakeOfTotalPrev = await deployed.seigManagerV2["stakeOfTotal()"]()
            let stakedAcountPrev = await deployed.seigManagerV2["stakeOf(address)"](account.address)

            const beforeSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, deployer, deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            await (await deployed.depositManagerV2.connect(deployer)["deposit(address,address,uint256)"](
                layer2,
                account.address,
                wtonAmount
            )).wait()

            const afterSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

            expect(roundDown(stakedB.add(ethers.BigNumber.from("4")),2)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 2)
            )

            let stakedAcount = await deployed.seigManagerV2["stakeOf(address)"](account.address)
            let stakeOfTotal = await deployed.seigManagerV2["stakeOfTotal()"]()

            let coinage = new ethers.Contract((await deployed.seigManagerV2.coinages(layer2)), jsonInfo.RefactorCoinageSnapshot.abi, ethers.provider)
            let stakeOfLayerTotal = await coinage.totalSupply()

            expect(stakedB).to.be.lte(stakeOfLayerTotal)
            expect(stakeOfTotal).to.be.gt(stakedB)
            expect(stakedAcount).to.be.gte(stakedB)
            expect(roundDown(stakedAcount.add(ethers.BigNumber.from("4")),2)).to.be.eq(
                roundDown(stakedAcountPrev.add(wtonAmount), 2)
            )

            expect(roundDown(stakeOfTotal.add(ethers.BigNumber.from("4")),2)).to.be.eq(
                roundDown(stakeOfTotalPrev.add(wtonAmount), 2)
            )
        })

        it('updateSeigniorage to level19', async () => {

            layer2Info_level19.layerContract = new ethers.Contract(layer2Info_level19.layer2, jsonInfo.Candidate.abi, ethers.provider)
            let layer2 = layer2Info_level19
            let account = addr2

            let wtonAmount = ethers.utils.parseEther("1000"+"0".repeat(9))

            await execAllowance(deployed.WTON, deployer, deployed.depositManagerV2.address, wtonAmount);

            await (await deployed.depositManagerV2.connect(deployer)["deposit(address,address,uint256)"](
                layer2.layer2,
                layer2.operator,
                wtonAmount
            )).wait();

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2.layer2, account.address)
            let powerTonBalance = await deployed.WTON.balanceOf(deployed.powerTonAddress);

            let block = await ethers.provider.getBlock('latest')
            let blockNumber =  block.number+1
            let toBlock = BigNumber.from(''+blockNumber)
            let calcSeigs: CalculatedSeig = await calcSeigniorageWithTonStakingV2Fixtures(deployed, jsonInfo, toBlock.toNumber(), layer2.layer2)

            // console.log('calcSeigs' , calcSeigs)

            const receipt = await (await layer2.layerContract.connect(account).updateSeigniorage()).wait()

            const topic = deployed.seigManagerV2.interface.getEventTopic('UpdatedSeigniorage');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);
            // console.log(deployedEvent.args)

            const topic1 = deployed.seigManagerV2.interface.getEventTopic('AddedSeigAtLayer');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = deployed.seigManagerV2.interface.parseLog(log1);
            // console.log("AddedSeigAtLayer", deployedEvent1.args)

            expect(deployedEvent.args.layer2).to.be.eq(layer2.layer2)
            expect(deployedEvent.args.blockNumber).to.be.eq(toBlock)
            expect(deployedEvent.args.prevTotal).to.be.eq(calcSeigs.coinageTotalSupply)

            expect(deployedEvent.args.oldCoinageFactor).to.be.eq(calcSeigs.coinageFactor)

            expect(roundDown(deployedEvent.args.nextTotal, 6)).to.be.eq(
                roundDown(calcSeigs.nextLayerTotalSupply, 6)
            )

            expect(roundDown(deployedEvent.args.nextTotFactor,3)).to.be.eq(
                roundDown(calcSeigs.newTotFactor, 3)
            )
            expect(roundDown(deployedEvent.args.nextCoinageFactor,6)).to.be.eq(
                roundDown(calcSeigs.newCoinageFactor, 6)
            )

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2.layer2, account.address)

            expect(stakedB).to.be.gt(stakedA)
            expect(await deployed.WTON.balanceOf(deployed.powerTonAddress)).to.be.gt(powerTonBalance)

        })

        it('snapshot()', async () => {
            let layer2s = [layer2Info_level19.layer2, layer2Info_tokamak.layer2]
            let account = addr2

            let snapshotInfo: SnapshotInfo = {
                account: account.address,
                snapshotId: BigNumber.from("0"),
                totTotalSupply: BigNumber.from("0"),
                snapshotLayers: [],
                accountBalanceOfTotal: BigNumber.from("0")
            }

            snapshotInfo.totTotalSupply = await deployed.seigManagerV2.stakeOfTotal()
            snapshotInfo.accountBalanceOfTotal = await deployed.seigManagerV2["stakeOf(address)"](account.address)

            for(let i = 0; i < layer2s.length; i++) {
                let layer2 = layer2s[i]
                let coinage = new ethers.Contract((await deployed.seigManagerV2.coinages(layer2)), jsonInfo.RefactorCoinageSnapshot.abi, ethers.provider)
                let snapshotLayer: SnapshotLayer = {layerAddress:layer2, totalSupply: ethers.constants.Zero, accountBalance: ethers.constants.Zero}
                snapshotLayer.accountBalance = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
                snapshotLayer.totalSupply = await coinage.totalSupply()

                snapshotInfo.snapshotLayers.push(snapshotLayer)
            }

            const receipt = await (await deployed.seigManagerV2.connect(account).onSnapshot()).wait()
            const topic = deployed.seigManagerV2.interface.getEventTopic('OnSnapshot');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);

            snapshotInfo.snapshotId = deployedEvent.args.snapshotId
            snapshotInfos.push(snapshotInfo)
            // logSnapshots(snapshotInfos);
            await checkSnapshots(deployed, jsonInfo, snapshotInfos)
        });

    })

})
