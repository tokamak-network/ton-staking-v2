import { expect } from '../shared/expect'
import { ethers, network, getNamedAccounts } from 'hardhat'

import { Signer } from 'ethers'
import { padLeft } from 'web3-utils'
import { marshalString, unmarshalString } from '../shared/marshal';

import { stakedTonSyncFixture } from '../shared/fixtures'
import { StakedTonSyncFixture } from '../shared/fixtureInterfaces'


import { SeigManagerProxy } from "../../typechain-types/contracts/stake/managers/SeigManagerProxy"
import { SeigManager1 } from "../../typechain-types/contracts/stake/managers/SeigManager1.sol"

import SeigManagerAbi from "../../artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json"
import SeigManager1Abi from "../../artifacts/contracts/stake/managers/SeigManager1.sol/SeigManager1.json"
import SeigManagerProxyAbi from "../../artifacts/contracts/stake/managers/SeigManagerProxy.sol/SeigManagerProxy.json"
import DepositManagerAbi from "../../artifacts/contracts/stake/managers/DepositManager.sol/DepositManager.json"

function roundDown(val:BigNumber, decimals:number) {
    return ethers.utils.formatUnits(val, decimals).split(".")[0]
}

async function execAllowance(contract: any, fromSigner: Signer, toAddress: string, amount: BigNumber) {
    let allowance = await contract.allowance(fromSigner.address, toAddress);
    if (allowance.lt(amount)) {
        await contract.connect(fromSigner).approve(toAddress, amount);
    }
}

describe('L1StakedTonToL2', () => {
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: StakedTonSyncFixture
    let seigManagerV2: SeigManager1
    let testAddress: string;
    let tester: Signer;

    before('create fixture loader', async () => {
        deployed = await stakedTonSyncFixture(true)

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
        tester = await ethers.getSigner(testAddress)
    })

    describe('# initialize ', () => {

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

    describe('# setL1StakedTonInL2', () => {
        it('Only owner can setL1StakedTonInL2.', async () => {
            await expect(deployed.l1StakedTonToL2.connect(addr1).setL1StakedTonInL2(
                deployed.l1StakedTonInL2.address
                )
            ).to.be.revertedWith("Accessible: Caller is not an admin")
        })

        it('Only owner can setL1StakedTonInL2.', async () => {
            await (await deployed.l1StakedTonToL2.connect(deployer).setL1StakedTonInL2(
                deployed.l1StakedTonInL2.address
            )).wait();

           await expect(await deployed.l1StakedTonToL2.l1StakedTonInL2()).to.be.eq(deployed.l1StakedTonInL2.address);
        })
    });

    describe('# L1StakedTonInL2', () => {
        it('Only owner can initialize.', async () => {

            await expect(deployed.l1StakedTonInL2.connect(addr1).initialize(
                 deployed.l2Messenger.address,
                 deployed.l1StakedTonToL2.address,
                 deployed.l2SeigManager.address
                )
            ).to.be.revertedWith("Accessible: Caller is not an admin")
        })

        it('Only owner can initialize.', async () => {
            await (await deployed.l1StakedTonInL2.connect(deployer).initialize(
                deployed.l2Messenger.address,
                deployed.l1StakedTonToL2.address,
                deployed.l2SeigManager.address
            )).wait();

           await expect(await deployed.l1StakedTonInL2.l2CrossDomainMessenger()).to.be.eq(deployed.l2Messenger.address);
           await expect(await deployed.l1StakedTonInL2.l1Register()).to.be.eq(deployed.l1StakedTonToL2.address);
           await expect(await deployed.l1StakedTonInL2.l2SeigManager()).to.be.eq(deployed.l2SeigManager.address);
        })

        it('Only owner can setL1Register.', async () => {
            await expect(deployed.l1StakedTonInL2.connect(addr1).setL1Register(
                deployed.l1StakedTonToL2.address
                )
            ).to.be.revertedWith("Accessible: Caller is not an admin")
        })

        it('Only owner can setL1Register.', async () => {

            await (await deployed.l1StakedTonInL2.connect(deployer).setL1Register(
                ethers.constants.AddressZero
                )
            ).wait()

            await (await deployed.l1StakedTonInL2.connect(deployer).setL1Register(
                deployed.l1StakedTonToL2.address
                )
            ).wait()

            await expect(await deployed.l1StakedTonInL2.l1Register()).to.be.eq(deployed.l1StakedTonToL2.address);
        })

        it('Only owner can setL2SeigManager.', async () => {
            await expect(deployed.l1StakedTonInL2.connect(addr1).setL2SeigManager(
                deployed.l2SeigManager.address
                )
            ).to.be.revertedWith("Accessible: Caller is not an admin")
        })

        it('Only owner can setL2SeigManager.', async () => {

            await (await deployed.l1StakedTonInL2.connect(deployer).setL2SeigManager(
                ethers.constants.AddressZero
                )
            ).wait()

            await (await deployed.l1StakedTonInL2.connect(deployer).setL2SeigManager(
                deployed.l2SeigManager.address
            )).wait();

           await expect(await deployed.l1StakedTonInL2.l2SeigManager()).to.be.eq(deployed.l2SeigManager.address);
        })

    });

    describe('# L2SeigManager', () => {
        it('Only owner can initialize.', async () => {

            await expect(deployed.l2SeigManager.connect(addr1).initialize(
                 deployed.l1StakedTonInL2.address,
                 deployed.l2Messenger.address
                )
            ).to.be.revertedWith("AuthControl: Caller is not an admin")
        })

        it('Only owner can initialize.', async () => {
            await (await deployed.l2SeigManager.connect(deployer).initialize(
                deployed.l1StakedTonInL2.address,
                deployed.l2Messenger.address
            )).wait();

           await expect(await deployed.l2SeigManager.l2CrossDomainMessenger()).to.be.eq(deployed.l2Messenger.address);
           await expect(await deployed.l2SeigManager.l1StakedTonInL2()).to.be.eq(deployed.l1StakedTonInL2.address);

        })


        it('Only owner can addLayers.', async () => {
            const {  level19Address } = await getNamedAccounts();
            await expect(deployed.l2SeigManager.connect(addr1).addLayers(
                 [level19Address]
                )
            ).to.be.revertedWith("AuthControl: Caller is not an admin")
        })

        it('Only owner can addLayers.', async () => {
            let numLayer2s = await deployed.l2Registry.numLayer2s()
            let layers = []
            let num = numLayer2s.toNumber()

            for (let i = 0; i < num; i++){
                layers.push(await deployed.l2Registry.layer2ByIndex(i))
            }
            console.log(layers)
            await (await deployed.l2SeigManager.connect(deployer).addLayers(
                layers
            )).wait();
        })

    });

    describe('# SeigManager', () => {
        it('UpgradeTo SeigManager1', async () => {
            const SeigManagerProxy = (
                new ethers.Contract( deployed.seigManagerV1.address, SeigManagerProxyAbi.abi,  deployer)) as SeigManagerProxy

            await (await SeigManagerProxy.connect(deployed.daoAdmin).upgradeTo(deployed.seigManagerV2Imp.address)).wait()

            expect(await SeigManagerProxy.implementation()).to.be.eq(deployed.seigManagerV2Imp.address)

            seigManagerV2 = (await ethers.getContractAt(SeigManager1Abi.abi, deployed.seigManagerV1.address, deployer)) as SeigManager1
        })

        it('Only owner can setL1StakedTonToL2.', async () => {

            await expect(seigManagerV2.connect(addr1).setL1StakedTonToL2(
                 deployed.l1StakedTonToL2.address
                )
            ).to.be.revertedWith("AuthControl: Caller is not an admin")
        })

        it('Only owner can initialize.', async () => {
            await (await seigManagerV2.connect(deployed.daoAdmin).setL1StakedTonToL2(
                deployed.l1StakedTonToL2.address
            )).wait();

           await expect(await seigManagerV2.l1StakedTonToL2()).to.be.eq(deployed.l1StakedTonToL2.address);
        })

        // it('register ', async () => {
        //     let data = '0x0c4a118cd6aaffa1dc3e18a86d1f3c1218a3451df3b17fdb808c7d0df9acd24da34700ce069007df000000000000000000000000000000000000000000000000000000000000000044e3605d0ed58fd125e9c47d1bf25a4406c13b5700000000000000000000000000000000000000000000000000000000000000002b67d8d4e61b68744885e243efaf988f1fc66e2d000000000000000000000000000000000000000000000000000000000000000036101b31e74c5e8f9a9cec378407bbb77628776100000000000000000000000000000000000000000000000000000000000000002c25a6be0e6f9017b5bf77879c487eed466f219400000000000000000000000000000000000000000000000000000000000000000f42d1c40b95df7a1478639918fc358b4af5298d000000000000000000000000000000000000000bc195fbf58ed6ffefa0bd79adbc602c1d9f3ae99db4e9fd3662ce3d02e593ec5d0000000000000000000000000000000000000000000000000000000000000000c42ccb12515b52b59c02eec303c887c8658f58540000000000000000000000000000000000000000000000000000000000000000f3cf23d896ba09d8ecdcd4655d918f71925e3fe5000000000000000000000000000000000000000000000000000000000000000006d34f65869ec94b3ba8c0e08bceb532f65005e20000000000000000000000000000000000000000000000000000000000000000'

        //     await (await deployed.l1StakedTonInL2["register(bytes)"](data)).wait()

        // });

        it('deposit to level19 using approveAndCall', async () => {
            const { DepositManager, level19Address, WTON } = await getNamedAccounts();

            let tonAmount = ethers.utils.parseEther("100")
            await deployed.TON.connect(deployer).transfer(testAddress, tonAmount);

            const beforeBalance = await deployed.TON.balanceOf(testAddress);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await deployed.seigManagerV1["stakeOf(address,address)"](level19Address, testAddress)
            const data = marshalString(
                [DepositManager, level19Address]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
              );

            await (await deployed.TON.connect(tester).approveAndCall(
                WTON,
                tonAmount,
                data,
                {from: testAddress}
            )).wait();

            const afterBalance = await deployed.TON.balanceOf(testAddress);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await deployed.seigManagerV1["stakeOf(address,address)"](level19Address, testAddress)
            console.log('stakedB', stakedB)
            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 1)
            )

            let L2BalanceOf = await deployed.l2SeigManager["balanceOf(address)"](testAddress)

            console.log('L2BalanceOf', L2BalanceOf)
        })

    });

    // describe('# register', () => {
    //     it('register', async () => {
    //         let stakeOf = await seigManagerV2["stakeOf(address)"](testAddress)
    //         console.log('stakeOf', stakeOf)
    //         await (await deployed.l1StakedTonToL2.connect(deployer)["register(address)"](
    //             testAddress
    //         )).wait();

    //         let balanceOf = await deployed.l2SeigManager["balanceOf(address)"](testAddress)
    //         console.log('balanceOf', balanceOf)
    //         await expect(stakeOf).to.be.eq(balanceOf);
    //     })
    // });


    // describe('# deposit', () => {

    //     it('deposit to level19 using approveAndCall', async () => {
    //         const { DepositManager, level19Address, WTON } = await getNamedAccounts();

    //         let tonAmount = ethers.utils.parseEther("100")
    //         await deployed.TON.connect(deployer).transfer(testAddress, tonAmount);

    //         const beforeBalance = await deployed.TON.balanceOf(testAddress);
    //         expect(beforeBalance).to.be.gte(tonAmount)

    //         let stakedA = await seigManagerV2["stakeOf(address,address)"](level19Address, testAddress)
    //         console.log('stakedA', stakedA)
    //         const data = marshalString(
    //             [DepositManager, level19Address]
    //               .map(unmarshalString)
    //               .map(str => padLeft(str, 64))
    //               .join(''),
    //           );

    //         await (await deployed.TON.connect(tester).approveAndCall(
    //             WTON,
    //             tonAmount,
    //             data,
    //             {from: testAddress}
    //         )).wait();

    //         const afterBalance = await deployed.TON.balanceOf(testAddress);
    //         expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

    //         let stakedB = await seigManagerV2["stakeOf(address,address)"](level19Address, testAddress)
    //         console.log('stakedB', stakedB)

    //         let balanceOf = await deployed.l2SeigManager["balanceOf(address)"](testAddress)
    //                 console.log('balanceOf', balanceOf)

    //         expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
    //             roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 1)
    //         )
    //     })

    // });


    describe('# unstake', () => {

    });

    describe('# updateSeigniorage', () => {

    });

});

