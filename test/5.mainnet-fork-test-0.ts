import { expect } from './shared/expect'
import { ethers, network } from 'hardhat'
import { BigNumber, Signer } from 'ethers'
import { mine } from "@nomicfoundation/hardhat-network-helpers"

import {
        newTonStakingV2MainnetFixture,
        lastSeigBlock,
        globalWithdrawalDelay,
        seigManagerInfo,
        jsonFixtures } from './shared/fixtures'

import { NewTonStakingV2Fixtures, JSONFixture } from './shared/fixtureInterfaces'
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
    {"oldLayer":"0x39a13a796a3cd9f480c28259230d2ef0a7026033","newLayer":"0xbb641462a2e678c560b85beae7ed4bf265c590f3","operator":"0xea8e2ec08dcf4971bdcdfffe21439995378b44f3","name":"tokamak1"},
    {"oldLayer":"0x41fb4bad6fba9e9b6e45f3f96ba3ad7ec2ff5b3c","newLayer":"0xe35abc8d34afddeae9ea2a84f76dd301ef25f536","operator":"0x566b98a715ef8f60a93a208717d9182310ac3867","name":"DXM Corp"},
    {"oldLayer":"0xbc8896ebb2e3939b1849298ef8da59e09946cf66","newLayer":"0x10242ba40c33ac28a842450a519e8f4e21c2cc7b","operator":"0x8dfcbc1df9933c8725618015d10b7b6de2d2c6f8","name":"DSRV"},
    {"oldLayer":"0xb9d336596ea2662488641c4ac87960bfdcb94c6e","newLayer":"0x9282a77f0a9bfd97ff68ae7bc791534a3edb4b1d","operator":"0xcc2f386adca481a00d614d5aa77a30984f264a07","name":"Talken"},
    {"oldLayer":"0xcc38c7aaf2507da52a875e93f57451e58e8c6372","newLayer":"0x9696403f92bb0eaa1db723d3a528506a4ad3b5f0","operator":"0x247a0829c63c5b40dc6b21cf412f80227dc7fb76","name":"staked"},
    {"oldLayer":"0x42ccf0769e87cb2952634f607df1c7d62e0bbc52","newLayer":"0x6041ec019c4c9f9b865d267e3ab18b66b45a1499","operator":"0xd1820b18be7f6429f1f44104e4e15d16fb199a43","name":"level19"},
    {"oldLayer":"0x17602823b5fe43a65ad7122946a73b019e77fd33","newLayer":"0x71336155ae27b687975069c9cdbac26734271854","operator":"0xba33eddfd3e4e155a6da10281d9069bf44743228","name":"decipher"},
    {"oldLayer":"0x2000fc16911fc044130c29c1aa49d3e0b101716a","newLayer":"0xe8dc4aff6ea03a214e737e615098e250b6fb945e","operator":"0xfc9c403993bea576c28ac901bd62640bff8b057a","name":"DeSpread"},
    {"oldLayer":"0x97d0a5880542ab0e699c67e7f4ff61f2e5200484","newLayer":"0x8b18be97df416a32bd98ebddd406e14e473fdc3d","operator":"0x887af02970781a088962dbaa299a1eba8d573321","name":"Danal Fintech"},
    {"oldLayer":"0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764","newLayer":"0x8de5c2277ebc639a0ea5a3766084c9e8c984798f","operator":"0x42adfaae7db56b294225ddcfebef48b337b34b23","name":"Hammer DAO"}
]

describe('Fork Simple Staking Test #1', () => {
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: NewTonStakingV2Fixtures
    let jsonInfo: JSONFixture
    let layer2Info_1 : any;
    let layer2Info_2 : any;
    let Operator : any;
    let Candidate : any;
    let snapshotInfo : any;

    before('create fixture loader', async () => {
        deployed = await newTonStakingV2MainnetFixture(true)
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

    })

    // deposit, unstake, withdraw , updateSeignorage
    describe('change logic ', () => {

        it('change logic', async () => {

        });

    });


});