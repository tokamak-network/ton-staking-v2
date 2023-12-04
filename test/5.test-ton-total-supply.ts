import { expect } from './shared/expect'
import { ethers, network } from 'hardhat'
import { BigNumber, Signer } from 'ethers'
import { mine } from "@nomicfoundation/hardhat-network-helpers"

import {
        lastSeigBlock,
        globalWithdrawalDelay,
        seigManagerInfo,
        jsonFixtures,
        newTonStakingV2MainnetFixture2} from './shared/fixtures'

import { NewTonStakingV2Fixtures2, JSONFixture } from './shared/fixtureInterfaces'
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
const layers = [
    {"oldLayer":"0x39a13a796a3cd9f480c28259230d2ef0a7026033","newLayer":"0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF","operator":"0xea8e2ec08dcf4971bdcdfffe21439995378b44f3","name":"tokamak1"},
    {"oldLayer":"0x41fb4bad6fba9e9b6e45f3f96ba3ad7ec2ff5b3c","newLayer":"0x44e3605d0ed58FD125E9C47D1bf25a4406c13b57","operator":"0x566b98a715ef8f60a93a208717d9182310ac3867","name":"DXM Corp"},
    {"oldLayer":"0xbc8896ebb2e3939b1849298ef8da59e09946cf66","newLayer":"0x2B67D8D4E61b68744885E243EfAF988f1Fc66E2D","operator":"0x8dfcbc1df9933c8725618015d10b7b6de2d2c6f8","name":"DSRV"},
    {"oldLayer":"0xb9d336596ea2662488641c4ac87960bfdcb94c6e","newLayer":"0x36101b31e74c5E8f9a9cec378407Bbb776287761","operator":"0xcc2f386adca481a00d614d5aa77a30984f264a07","name":"Talken"},
    {"oldLayer":"0xcc38c7aaf2507da52a875e93f57451e58e8c6372","newLayer":"0x2c25A6be0e6f9017b5bf77879c487eed466F2194","operator":"0x247a0829c63c5b40dc6b21cf412f80227dc7fb76","name":"staked"},
    {"oldLayer":"0x42ccf0769e87cb2952634f607df1c7d62e0bbc52","newLayer":"0x0F42D1C40b95DF7A1478639918fc358B4aF5298D","operator":"0xd1820b18be7f6429f1f44104e4e15d16fb199a43","name":"level"},
    {"oldLayer":"0x17602823b5fe43a65ad7122946a73b019e77fd33","newLayer":"0xbc602C1D9f3aE99dB4e9fD3662CE3D02e593ec5d","operator":"0xba33eddfd3e4e155a6da10281d9069bf44743228","name":"decipher"},
    {"oldLayer":"0x2000fc16911fc044130c29c1aa49d3e0b101716a","newLayer":"0xC42cCb12515b52B59c02eEc303c887C8658f5854","operator":"0xfc9c403993bea576c28ac901bd62640bff8b057a","name":"DeSpread"},
    {"oldLayer":"0x97d0a5880542ab0e699c67e7f4ff61f2e5200484","newLayer":"0xf3CF23D896Ba09d8EcdcD4655d918f71925E3FE5","operator":"0x887af02970781a088962dbaa299a1eba8d573321","name":"Danal Fintech"},
    {"oldLayer":"0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764","newLayer":"0x06D34f65869Ec94B3BA8c0E08BCEb532f65005E2","operator":"0x42adfaae7db56b294225ddcfebef48b337b34b23","name":"Hammer DAO"}
]

const testAddress = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"

describe('Fork Simple Staking Test', () => {
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: NewTonStakingV2Fixtures2
    let jsonInfo: JSONFixture
    let layer2Info_1 : any;
    let layer2Info_2 : any;
    let Operator : any;
    let Candidate : any;
    let snapshotInfo : any;

    let pastDepositor: Signer;
    let wtonHave: Signer;
    let tonHave: Signer;
    let daoAdmin: Signer;

    before('create fixture loader', async () => {
        deployed = await newTonStakingV2MainnetFixture2(true, testAddress)
        jsonInfo = await jsonFixtures()

        deployer = deployed.deployer;
        addr1 = deployed.addr1;
        addr2 = deployed.addr2;
        layer2Info_1 = {
            operatorAdmin: layers[0].operator,
            isLayer2Candidate: false,
            name: layers[0].name,
            committee: deployed.daoCommittee.address,
            layer2: layers[0].newLayer,
            operator: layers[0].operator,
            layerContract: null,
            coinageContract: null
        }

        layer2Info_2 = {
            operatorAdmin: layers[1].operator,
            isLayer2Candidate: false,
            name: layers[1].name,
            committee: deployed.daoCommittee.address,
            layer2:  layers[1].newLayer,
            operator: layers[1].operator,
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

        let pastAddr = "0x3bFda92Fa3bC0AB080Cac3775147B6318b1C5115"

        await hre.network.provider.send("hardhat_impersonateAccount", [
            pastAddr,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            pastAddr,
            "0x10000000000000000000000000",
        ]);
        pastDepositor = await hre.ethers.getSigner(pastAddr);

        let wtonhaveAddr = "0x735985022e5EF7BeFA272986FdFB7dE6aC675ed8"

        await hre.network.provider.send("hardhat_impersonateAccount", [
            wtonhaveAddr,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            wtonhaveAddr,
            "0x10000000000000000000000000",
        ]);
        wtonHave = await hre.ethers.getSigner(wtonhaveAddr);

        let tonHaveAddr = "0x6855B8EcF02F27EcdeFf72f409C9CCB631009CB8"

        await hre.network.provider.send("hardhat_impersonateAccount", [
            tonHaveAddr,
        ]);

        tonHave = await hre.ethers.getSigner(tonHaveAddr);

        let daoAddr = deployed.daoCommitteeProxy.address

        await hre.network.provider.send("hardhat_impersonateAccount", [
            daoAddr,
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            daoAddr,
            "0x10000000000000000000000000",
          ]);

        daoAdmin = await hre.ethers.getSigner(daoAddr);

    })

    // deposit, unstake, withdraw , updateSeignorage
    describe('basic functions ', () => {

        it('deposit to layer1 using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)

            let account = pastDepositor
            let tonAmount = ethers.utils.parseEther("1")

            // await deployed.TON.connect(deployer).transfer(account.address, tonAmount);

            const beforeBalance = await deployed.TON.balanceOf(account.address);
            // console.log("beforeTONBalance :", beforeBalance);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_1.layer2, account.address)
            // console.log("stakedA :", stakedA);

            const data = marshalString(
                [deployed.depositManagerV2.address, layer2Info_1.layer2]
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

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 1)
            )
        })


        it('deposit to layer2 using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)

            let account = pastDepositor
            let tonAmount = ethers.utils.parseEther("1")

            // await deployed.TON.connect(deployer).transfer(account.address, tonAmount);

            const beforeBalance = await deployed.TON.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_2.layer2, account.address)

            const data = marshalString(
                [deployed.depositManagerV2.address, layer2Info_2.layer2]
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

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_2.layer2, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 1)
            )
        })

        it('deposit to layer1 using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)

            let account = pastDepositor

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await deployed.WTON.connect(wtonHave).transfer(account.address, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, account, deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            await (await deployed.depositManagerV2.connect(account)["deposit(address,uint256)"](
                layer2Info_1.layer2,
                wtonAmount
            )).wait()

            const afterBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            // expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
            //     roundDown(stakedA.add(wtonAmount), 3)
            // )
        })

        it('deposit to tokamak using deposit(address,address,uint256) ', async () => {
            // console.log(deployed.seigManagerV2)
            // let account = deployer
            let account = pastDepositor
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await deployed.WTON.connect(wtonHave).transfer(account.address, wtonAmount);

            const beforeSenderBalance = await deployed.WTON.balanceOf(account.address);
            // console.log("beforeSenderBalance :", beforeSenderBalance);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, account, deployed.depositManagerV2.address, wtonAmount);
            // await deployed.WTON.connect(account).approve(deployed.depositManagerV2.address, wtonAmount);

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_2.layer2, addr1.address)

            await (await deployed.depositManagerV2.connect(pastDepositor)["deposit(address,address,uint256)"](
                layer2Info_2.layer2,
                addr1.address,
                wtonAmount
            )).wait()

            const afterSenderBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_2.layer2, addr1.address)

            expect(roundDown(stakedB.add(ethers.BigNumber.from("3")),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )
        })
        /*
        it('deposit to layer2 using deposit(address,address[],uint256[]) ', async () => {
            // console.log(deployed.seigManagerV2)

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            let wtonAmount1 = ethers.utils.parseEther("3"+"0".repeat(9))
            let wtonAmount2 = ethers.utils.parseEther("7"+"0".repeat(9))
            // await deployed.WTON.connect(deployer).transfer(addr1.address, wtonAmount);

            const beforeSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, deployer, deployed.depositManagerV2.address, wtonAmount);

            let stakedA1 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_2.layer2, addr1.address)
            let stakedA2 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_2.layer2, addr2.address)

            await (await deployed.depositManagerV2.connect(deployer)["deposit(address,address[],uint256[])"](
                layer2Info_2.layer2,
                [addr1.address, addr2.address],
                [wtonAmount1, wtonAmount2]
            )).wait()

            const afterSenderBalance = await deployed.WTON.balanceOf(deployer.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB1 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_2.layer2, addr1.address)
            let stakedB2 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_2.layer2, addr2.address)

            expect(roundDown(stakedB1.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA1.add(wtonAmount1), 1)
            )
            expect(roundDown(stakedB2.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA2.add(wtonAmount2), 1)
            )
        })
        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");

        });
        */

        it('set layerContract', async () => {

            layer2Info_1.layerContract = new ethers.Contract(
                layer2Info_1.layer2, jsonInfo.Candidate.abi, deployer
            );

        });
        it('updateSeigniorage to layer1', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)

            let block1 = await ethers.provider.getBlock('latest');
            let totalSupplyOfTon = await deployed.seigManagerV2["totalSupplyOfTon()"]()
            console.log('block number :', block1.number, ' tonTotalSupply', totalSupplyOfTon)

            let totalSupplyOfTon_1 = await deployed.seigManagerV2["totalSupplyOfTon_1()"]()
            console.log('block number :', block1.number, ' tonTotalSupply_1', totalSupplyOfTon_1)

            let totalSupplyOfTon_2 = await deployed.seigManagerV2["totalSupplyOfTon_2()"]()
            console.log('block number :', block1.number, ' totalSupplyOfTon_2', totalSupplyOfTon_2)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

            let powerTonBalance = await deployed.WTON.balanceOf(deployed.powerTonAddress);
            await (await layer2Info_1.layerContract.connect(pastDepositor).updateSeigniorage()).wait()

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

            expect(stakedB).to.be.gt(stakedA)
            expect(await deployed.WTON.balanceOf(deployed.powerTonAddress)).to.be.gt(powerTonBalance)

            let block2 = await ethers.provider.getBlock('latest');
            let totalSupplyOfTon_after = await deployed.seigManagerV2["totalSupplyOfTon()"]()
            console.log('block number :', block2.number, ' totalSupplyOfTon', totalSupplyOfTon_after)

            let totalSupplyOfTon_1_after = await deployed.seigManagerV2["totalSupplyOfTon_1()"]()
            console.log('block number :', block2.number, ' totalSupplyOfTon_1', totalSupplyOfTon_1_after)

            let totalSupplyOfTon_2_after = await deployed.seigManagerV2["totalSupplyOfTon_2()"]()
            console.log('block number :', block2.number, ' totalSupplyOfTon_2', totalSupplyOfTon_2_after)

            console.log('totalSupplyOfTon_after.sub(totalSupplyOfTon) :', totalSupplyOfTon_after.sub(totalSupplyOfTon))
            console.log('totalSupplyOfTon_1_after.sub(totalSupplyOfTon_1):', totalSupplyOfTon_1_after.sub(totalSupplyOfTon_1))
            console.log('totalSupplyOfTon_2_after.sub(totalSupplyOfTon_2):', totalSupplyOfTon_2_after.sub(totalSupplyOfTon_2))

            let seigPerBlock =  await deployed.seigManagerV2.seigPerBlock();
            console.log('seigPerBlock', seigPerBlock)

            expect(totalSupplyOfTon_after.sub(totalSupplyOfTon)).to.be.eq(seigPerBlock)
        })
        /*
        it('requestWithdrawal to layer1', async () => {

            let layer2 = layer2Info_1.layer2
            let account = deployer
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            const beforeBalance = await deployed.WTON.balanceOf(account.address)

            let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
            let pendingUnstakedA = await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await deployed.depositManagerV2.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await deployed.depositManagerV2.pendingUnstakedAccount(account.address)

            await (await deployed.depositManagerV2.connect(account)["requestWithdrawal(address,uint256)"](
                layer2Info_1.layer2,
                wtonAmount
            )).wait()

            const afterBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

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

        it('processRequest to layer1 will be fail when delay time didn\'t pass.', async () => {
            let layer2 = layer2Info_1.layer2
            let account = deployer

            await expect(
                    deployed.depositManagerV2.connect(account)["processRequest(address,bool)"](
                    layer2,
                    true
                )
            ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

        });

        it('processRequest to layer1.', async () => {
            let layer2 = layer2Info_1.layer2
            let account = deployer
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
        */
    });
     /*
    describe('updateSeigniorage', () => {

        it('deposit to layer2 using deposit(address,address,uint256) ', async () => {
            let layer2 = layer2Info_2.layer2
            let operator = layer2Info_2.operatorAdmin
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

        it('deposit to layer1', async () => {
            let layer2 = layer2Info_1.layer2
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
    */

    // describe('snapshot functions', () => {
    //     it('deposit to layer1', async () => {
    //         let layer2 = layer2Info_1.layer2
    //         let account = deployer
    //         let tonAmount = ethers.utils.parseEther("1")
    //         await deployed.TON.connect(deployer).transfer(account.address, tonAmount);

    //         const beforeBalance = await deployed.TON.balanceOf(account.address);
    //         expect(beforeBalance).to.be.gte(tonAmount)

    //         let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

    //         const data = marshalString(
    //             [deployed.depositManagerV2.address, layer2]
    //               .map(unmarshalString)
    //               .map(str => padLeft(str, 64))
    //               .join(''),
    //         );

    //         await (await deployed.TON.connect(account).approveAndCall(
    //             deployed.WTON.address,
    //             tonAmount,
    //             data,
    //             {from: account.address}
    //         )).wait()

    //         const afterBalance = await deployed.TON.balanceOf(account.address);
    //         expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

    //         let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

    //         let wtonAmount = tonAmount.mul(ethers.BigNumber.from("1"+"0".repeat(9)))
    //         expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
    //             roundDown(stakedA.add(wtonAmount), 1)
    //         )

    //     })

    //     it('snapshot()', async () => {
    //         let layer2 = layer2Info_1.layer2
    //         let account = deployer
    //         snapshotInfo.account = account.address
    //         snapshotInfo.totTotalSupply = await deployed.seigManagerV2.stakeOfTotal()
    //         snapshotInfo.accountBalanceOfLayer2 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
    //         snapshotInfo.accountBalanceOfTotal = await deployed.seigManagerV2["stakeOf(address)"](account.address)

    //         const receipt = await (await deployed.seigManagerV2.connect(account).onSnapshot()).wait()
    //         const topic = deployed.seigManagerV2.interface.getEventTopic('OnSnapshot');
    //         const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
    //         const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);

    //         snapshotInfo.snapshotId = deployedEvent.args.snapshotId

    //     });

    //     it('deposit to layer1  ', async () => {
    //         let layer2 = layer2Info_1.layer2
    //         let account = deployer

    //         let wtonAmount = ethers.utils.parseEther("1"+"0".repeat(9))
    //         await deployed.WTON.connect(deployer).transfer(account.address, wtonAmount);

    //         const beforeBalance = await deployed.WTON.balanceOf(account.address);
    //         expect(beforeBalance).to.be.gte(wtonAmount)

    //         await execAllowance(deployed.WTON, account, deployed.depositManagerV2.address, wtonAmount);

    //         let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

    //         await (await deployed.depositManagerV2.connect(account)["deposit(address,uint256)"](
    //             layer2,
    //             wtonAmount
    //         )).wait()

    //         const afterBalance = await deployed.WTON.balanceOf(account.address);
    //         expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

    //         let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)

    //         expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
    //             roundDown(stakedA.add(wtonAmount), 1)
    //         )
    //     })

    //     it('snapshot data is accurate ', async () => {
    //         let layer2 = layer2Info_1.layer2
    //         let account = deployer

    //         let accountBalanceOfTotal= await deployed.seigManagerV2["stakeOf(address)"](account.address)
    //         let totTotalSupply= await deployed.seigManagerV2["stakeOfTotal()"]()

    //         let accountBalanceOfTotalAt = await deployed.seigManagerV2["stakeOfAt(address,uint256)"](account.address, snapshotInfo.snapshotId)
    //         let totTotalSupplyAt = await deployed.seigManagerV2["stakeOfTotalAt(uint256)"](snapshotInfo.snapshotId)

    //         expect(accountBalanceOfTotal).to.be.gt(accountBalanceOfTotalAt)
    //         expect(totTotalSupply).to.be.gt(totTotalSupplyAt)

    //         expect(accountBalanceOfTotalAt).to.be.eq(snapshotInfo.accountBalanceOfTotal)
    //         expect(totTotalSupplyAt).to.be.eq(snapshotInfo.totTotalSupply)

    //     });

    //     /*
    //     it('requestWithdrawal to layer1', async () => {

    //         let layer2 = layer2Info_1.layer2
    //         let account = addr1
    //         let wtonAmount = ethers.utils.parseEther("50"+"0".repeat(9))

    //         const beforeBalance = await deployed.WTON.balanceOf(account.address)

    //         let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
    //         let pendingUnstakedA = await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
    //         let pendingUnstakedLayer2A = await deployed.depositManagerV2.pendingUnstakedLayer2(layer2)
    //         let pendingUnstakedAccountA = await deployed.depositManagerV2.pendingUnstakedAccount(account.address)

    //         await (await deployed.depositManagerV2.connect(account)["requestWithdrawal(address,uint256)"](
    //             layer2Info_1.layer2,
    //             wtonAmount
    //         )).wait();

    //         const afterBalance = await deployed.WTON.balanceOf(account.address);
    //         expect(afterBalance).to.be.eq(beforeBalance)

    //         let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

    //         expect(roundDown(stakedA.sub(ethers.constants.Two),1)).to.be.eq(
    //             roundDown(stakedB.add(wtonAmount), 1)
    //         )

    //         expect(
    //             await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
    //         ).to.be.eq(pendingUnstakedA.add(wtonAmount))

    //         expect(
    //             await deployed.depositManagerV2.pendingUnstakedLayer2(layer2 )
    //         ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

    //         expect(
    //             await deployed.depositManagerV2.pendingUnstakedAccount(account.address)
    //         ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

    //     })

    //     it('snapshot()', async () => {
    //         let layer2 = layer2Info_1.layer2
    //         let account = addr1
    //         snapshotInfo.account = account.address
    //         snapshotInfo.totTotalSupply = await deployed.seigManagerV2.stakeOfTotal()
    //         snapshotInfo.accountBalanceOfLayer2 = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
    //         snapshotInfo.accountBalanceOfTotal = await deployed.seigManagerV2["stakeOf(address)"](account.address)

    //         const receipt = await (await deployed.seigManagerV2.connect(account).onSnapshot()).wait()
    //         const topic = deployed.seigManagerV2.interface.getEventTopic('OnSnapshot');
    //         const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
    //         const deployedEvent = deployed.seigManagerV2.interface.parseLog(log);

    //         snapshotInfo.snapshotId = deployedEvent.args.snapshotId
    //     });

    //     it('requestWithdrawal to layer1', async () => {

    //         let layer2 = layer2Info_1.layer2
    //         let account = addr1
    //         let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

    //         const beforeBalance = await deployed.WTON.balanceOf(account.address)

    //         let stakedA = await deployed.seigManagerV2["stakeOf(address,address)"](layer2, account.address)
    //         let pendingUnstakedA = await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
    //         let pendingUnstakedLayer2A = await deployed.depositManagerV2.pendingUnstakedLayer2(layer2)
    //         let pendingUnstakedAccountA = await deployed.depositManagerV2.pendingUnstakedAccount(account.address)

    //         await deployed.depositManagerV2.connect(account)["requestWithdrawal(address,uint256)"](
    //             layer2Info_1.layer2,
    //             wtonAmount
    //         );

    //         const afterBalance = await deployed.WTON.balanceOf(account.address);
    //         expect(afterBalance).to.be.eq(beforeBalance)

    //         let stakedB = await deployed.seigManagerV2["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

    //         expect(roundDown(stakedA.sub(ethers.constants.Two),2)).to.be.eq(
    //             roundDown(stakedB.add(wtonAmount), 2)
    //         )

    //         expect(
    //             await deployed.depositManagerV2.pendingUnstaked(layer2, account.address)
    //         ).to.be.eq(pendingUnstakedA.add(wtonAmount))

    //         expect(
    //             await deployed.depositManagerV2.pendingUnstakedLayer2(layer2 )
    //         ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

    //         expect(
    //             await deployed.depositManagerV2.pendingUnstakedAccount(account.address)
    //         ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

    //     })

    //     it('snapshot data is accurate ', async () => {
    //         let layer2 = layer2Info_1.layer2
    //         let account = addr1

    //         let accountBalanceOfTotal= await deployed.seigManagerV2["stakeOf(address)"](account.address)
    //         let totTotalSupply= await deployed.seigManagerV2["stakeOfTotal()"]()

    //         let accountBalanceOfTotalAt = await deployed.seigManagerV2["stakeOfAt(address,uint256)"](account.address, snapshotInfo.snapshotId)
    //         let totTotalSupplyAt = await deployed.seigManagerV2["stakeOfTotalAt(uint256)"](snapshotInfo.snapshotId)

    //         expect(accountBalanceOfTotal).to.be.lt(accountBalanceOfTotalAt)
    //         expect(totTotalSupply).to.be.lt(totTotalSupplyAt)

    //         expect(accountBalanceOfTotalAt).to.be.eq(snapshotInfo.accountBalanceOfTotal)
    //         expect(totTotalSupplyAt).to.be.eq(snapshotInfo.totTotalSupply)

    //     });
    //     */

    // });


});