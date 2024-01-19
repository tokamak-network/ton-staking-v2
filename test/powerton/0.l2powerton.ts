import { expect } from '../shared/expect'
import { ethers, network, getNamedAccounts } from 'hardhat'

import { Signer, BigNumber } from 'ethers'
import { padLeft } from 'web3-utils'
import { marshalString, unmarshalString } from '../shared/marshal';

import { l2PowerTonFixture } from '../shared/fixtures'
import { PowerTonFixture } from '../shared/fixtureInterfaces'

import { TestERC20 } from "../../typechain-types/contracts/test/TestERC20"
import { SeigManagerProxy } from "../../typechain-types/contracts/stake/managers/SeigManagerProxy"
import { SeigManagerV1_2 } from "../../typechain-types/contracts/stake/managers/SeigManagerV1_2.sol"

import SeigManagerAbi from "../../artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json"
import SeigManagerV1_2_Abi from "../../artifacts/contracts/stake/managers/SeigManagerV1_2.sol/SeigManagerV1_2.json"
import SeigManagerProxyAbi from "../../artifacts/contracts/stake/managers/SeigManagerProxy.sol/SeigManagerProxy.json"
import DepositManagerAbi from "../../artifacts/contracts/stake/managers/DepositManager.sol/DepositManager.json"
import L2DividendPoolForTon_Abi from "../../artifacts/contracts/L2/airdrop/L2DividendPoolForTon.sol/L2DividendPoolForTon.json"

function roundDown(val:BigNumber, decimals:number) {
    return ethers.utils.formatUnits(val, decimals).split(".")[0]
}

async function execAllowance(contract: any, fromSigner: Signer, toAddress: string, amount: BigNumber) {
    let allowance = await contract.allowance(fromSigner.address, toAddress);
    if (allowance.lt(amount)) {
        await contract.connect(fromSigner).approve(toAddress, amount);
    }
}

describe('L2PowerTon Test', () => {
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: PowerTonFixture
    let seigManagerV2: SeigManagerV1_2
    let testAddress: string;
    let tester: Signer;
    let snapshotInfo : any;
    let addrSnapshotInfos : any;
    let layerAddress : string;
    let distributeEvents : any;

    before('create fixture loader', async () => {
        deployed = await l2PowerTonFixture(true)

        deployer = deployed.deployer;
        addr1 = deployed.addr1;
        addr2 = deployed.addr2;

        testAddress = "0x0c4a118Cd6aAffA1dC3e18A86D1f3c1218a3451d"
        await network.provider.send("hardhat_impersonateAccount", [
            testAddress,
        ]);
        await network.provider.send("hardhat_setBalance", [
            testAddress,
            "0x10000000000000000000000000",
          ]);
        await network.provider.send("hardhat_setBalance", [
            addr1.address,
            "0x10000000000000000000000000",
        ]);
        await network.provider.send("hardhat_setBalance", [
            addr2.address,
            "0x10000000000000000000000000",
        ]);
        tester = await ethers.getSigner(testAddress)

        snapshotInfo = {
            account: null,
            snapshotId: null,
            totTotalSupply: ethers.constants.Zero,
            accountBalanceOfLayer2: ethers.constants.Zero,
            accountBalanceOfTotal: ethers.constants.Zero,
        }

        addrSnapshotInfos = {
            addr1: snapshotInfo,
            addr2: snapshotInfo
        }

        const { level19Address } = await getNamedAccounts();
        layerAddress = level19Address

        distributeEvents = []

    })

    describe('# L2PowerTon: initialize ', () => {

        it('Only owner can initialize.', async () => {
            const { SeigManagerAddress, L2RegistryAddress } = await getNamedAccounts();
            const minGasLimit = 200000
            await expect(deployed.l1StakedTonToL2.connect(addr1).initialize(
                deployer.address,
                SeigManagerAddress,
                L2RegistryAddress,
                deployed.addressManager.address,
                minGasLimit
                )
            ).to.be.revertedWith("Accessible: Caller is not an admin")
        })

        it('Only owner can initialize.', async () => {
            const { SeigManagerAddress, L2RegistryAddress } = await getNamedAccounts();
            const minGasLimit = 300000
            await (await deployed.l1StakedTonToL2.connect(deployer).initialize(
                addr1.address,
                SeigManagerAddress,
                L2RegistryAddress,
                deployed.addressManager.address,
                minGasLimit
            )).wait();

           await expect(await deployed.l1StakedTonToL2.manager()).to.be.eq(addr1.address);
           await expect(await deployed.l1StakedTonToL2.seigManager()).to.be.eq(SeigManagerAddress);
           await expect(await deployed.l1StakedTonToL2.registry()).to.be.eq(L2RegistryAddress);
           await expect(await deployed.l1StakedTonToL2.addressManager()).to.be.eq(deployed.addressManager.address);
           await expect(await deployed.l1StakedTonToL2.minGasLimit()).to.be.eq(minGasLimit);

        })

    });

});

