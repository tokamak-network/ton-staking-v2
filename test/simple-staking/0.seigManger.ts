import { expect } from '../shared/expect'
import { ethers, network, getNamedAccounts } from 'hardhat'
import { BigNumber, Signer } from 'ethers'
import { mine } from "@nomicfoundation/hardhat-network-helpers"

import {
        lastSeigBlock,
        globalWithdrawalDelay,
        seigManagerInfo,
        jsonFixtures,
        simpleStakeFixture} from '../shared/fixtures'

import { SimpleStakeFixture, JSONFixture } from '../shared/fixtureInterfaces'
import { padLeft } from 'web3-utils'
import { marshalString, unmarshalString } from '../shared/marshal';

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
    {"oldLayer":"0x42ccf0769e87cb2952634f607df1c7d62e0bbc52","newLayer":"0x0F42D1C40b95DF7A1478639918fc358B4aF5298D","operator":"0xd1820b18be7f6429f1f44104e4e15d16fb199a43","name":"level"},
    {"oldLayer":"0x39a13a796a3cd9f480c28259230d2ef0a7026033","newLayer":"0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF","operator":"0xea8e2ec08dcf4971bdcdfffe21439995378b44f3","name":"tokamak1"},
    {"oldLayer":"0x41fb4bad6fba9e9b6e45f3f96ba3ad7ec2ff5b3c","newLayer":"0x44e3605d0ed58FD125E9C47D1bf25a4406c13b57","operator":"0x566b98a715ef8f60a93a208717d9182310ac3867","name":"DXM Corp"},
    {"oldLayer":"0xbc8896ebb2e3939b1849298ef8da59e09946cf66","newLayer":"0x2B67D8D4E61b68744885E243EfAF988f1Fc66E2D","operator":"0x8dfcbc1df9933c8725618015d10b7b6de2d2c6f8","name":"DSRV"},
    {"oldLayer":"0xcc38c7aaf2507da52a875e93f57451e58e8c6372","newLayer":"0x2c25A6be0e6f9017b5bf77879c487eed466F2194","operator":"0x247a0829c63c5b40dc6b21cf412f80227dc7fb76","name":"staked"},
    {"oldLayer":"0x17602823b5fe43a65ad7122946a73b019e77fd33","newLayer":"0xbc602C1D9f3aE99dB4e9fD3662CE3D02e593ec5d","operator":"0xba33eddfd3e4e155a6da10281d9069bf44743228","name":"decipher"},
    {"oldLayer":"0x2000fc16911fc044130c29c1aa49d3e0b101716a","newLayer":"0xC42cCb12515b52B59c02eEc303c887C8658f5854","operator":"0xfc9c403993bea576c28ac901bd62640bff8b057a","name":"DeSpread"},
    {"oldLayer":"0x97d0a5880542ab0e699c67e7f4ff61f2e5200484","newLayer":"0xf3CF23D896Ba09d8EcdcD4655d918f71925E3FE5","operator":"0x887af02970781a088962dbaa299a1eba8d573321","name":"Danal Fintech"},
    {"oldLayer":"0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764","newLayer":"0x06D34f65869Ec94B3BA8c0E08BCEb532f65005E2","operator":"0x42adfaae7db56b294225ddcfebef48b337b34b23","name":"Hammer DAO"},
    {"oldLayer":"0xb9d336596ea2662488641c4ac87960bfdcb94c6e","newLayer":"0x36101b31e74c5E8f9a9cec378407Bbb776287761","operator":"0xcc2f386adca481a00d614d5aa77a30984f264a07","name":"Talken"}
]

const testAddress = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"

describe('SeigManager', () => {
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: SimpleStakeFixture
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
        deployed = await simpleStakeFixture(true)
        jsonInfo = await jsonFixtures()
        const { DAOCommitteeProxy} = await getNamedAccounts();

        deployer = deployed.deployer;
        addr1 = deployed.addr1;
        addr2 = deployed.addr2;
        layer2Info_1 = {
            operatorAdmin: layers[0].operator,
            isLayer2Candidate: false,
            name: layers[0].name,
            layer2: layers[0].newLayer,
            operator: layers[0].operator,
            layerContract: null,
            coinageContract: null
        }

        layer2Info_2 = {
            operatorAdmin: layers[1].operator,
            isLayer2Candidate: false,
            name: layers[1].name,
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

        await hre.network.provider.send("hardhat_impersonateAccount", [
            DAOCommitteeProxy,
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            DAOCommitteeProxy,
            "0x10000000000000000000000000",
          ]);

        daoAdmin = await hre.ethers.getSigner(DAOCommitteeProxy);

    })

    // deposit, unstake, withdraw , updateSeignorage
    describe('deposit ', () => {

        it('level: The operator stakes the minimum collateral.', async () => {

            let layerContract = new ethers.Contract(layer2Info_1.layer2, jsonInfo.Candidate.abi, pastDepositor)
            let operator = await layerContract.operator()

            let wtonAmount = ethers.utils.parseEther("1001"+"0".repeat(9))
            const beforeBalance = await deployed.WTON.balanceOf(wtonHave.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await (await deployed.WTON.connect(wtonHave).approve(
                deployed.depositManager.address,
                wtonAmount
            )).wait()

            let stakedA = await deployed.seigManager["stakeOf(address,address)"](layer2Info_1.layer2, operator)

            await (await deployed.depositManager.connect(wtonHave)["deposit(address,address,uint256)"](
                layer2Info_1.layer2,
                operator,
                wtonAmount
            )).wait()

            const afterBalance = await deployed.WTON.balanceOf(wtonHave.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await deployed.seigManager["stakeOf(address,address)"](layer2Info_1.layer2, operator)

            // console.log('stakedB',stakedB)

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )

            expect(stakedB).to.be.gt(ethers.utils.parseEther("1000"+"0".repeat(9)))
        })

        it('level: If the operator stakes the minimum collateral, you can deposit.', async () => {

            let account = pastDepositor
            let tonAmount = ethers.utils.parseEther("1")
            const beforeBalance = await deployed.TON.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(tonAmount)
            // console.log('beforeBalance ', beforeBalance)
            let layerContract = new ethers.Contract(layer2Info_1.layer2, jsonInfo.Candidate.abi, pastDepositor)
            let operator = await layerContract.operator()
            expect(
                await deployed.seigManager["stakeOf(address,address)"](layer2Info_1.layer2, operator)
            ).to.be.gt(ethers.constants.Zero)

            let stakedA = await deployed.seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)
            // console.log("stakedA :", stakedA);

            const data = marshalString(
                [deployed.depositManager.address, layer2Info_1.layer2]
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

            let stakedB = await deployed.seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)
            // console.log("stakedB :", stakedB);

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 3)
            )
        })

    });

});