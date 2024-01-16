import { expect } from '../shared/expect'
import { ethers, network, getNamedAccounts } from 'hardhat'

import { Signer, BigNumber } from 'ethers'
import { padLeft } from 'web3-utils'
import { marshalString, unmarshalString } from '../shared/marshal';

import { stakedTonSyncFixture } from '../shared/fixtures'
import { StakedTonSyncFixture } from '../shared/fixtureInterfaces'

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

describe('L1StakedTonToL2', () => {
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: StakedTonSyncFixture
    let seigManagerV2: SeigManagerV1_2
    let testAddress: string;
    let tester: Signer;
    let snapshotInfo : any;
    let addrSnapshotInfos : any;
    let layerAddress : string;
    let distributeEvents : any;

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

    describe('# L2DividendPoolForTon', () => {
        it('Only owner can initialize.', async () => {

            await expect(deployed.l2DividendPoolForTon.connect(addr1).initialize(
                 deployed.l2SeigManager.address
                )
            ).to.be.revertedWith("Accessible: Caller is not an admin")
        })

        it('Only owner can initialize.', async () => {
            await (await deployed.l2DividendPoolForTon.connect(deployer).initialize(
                deployed.l2SeigManager.address
            )).wait();

           await expect(await deployed.l2DividendPoolForTon.l2SeigManager()).to.be.eq(deployed.l2SeigManager.address);

        })

    });

    describe('# SeigManager', () => {
        it('UpgradeTo SeigManagerV1_2', async () => {
            const SeigManagerProxy = (
                new ethers.Contract( deployed.seigManagerV1.address, SeigManagerProxyAbi.abi,  deployer)) as SeigManagerProxy

            await (await SeigManagerProxy.connect(deployed.daoAdmin).upgradeTo(deployed.seigManagerV2Imp.address)).wait()

            expect(await SeigManagerProxy.implementation()).to.be.eq(deployed.seigManagerV2Imp.address)

            seigManagerV2 = (await ethers.getContractAt(SeigManagerV1_2_Abi.abi, deployed.seigManagerV1.address, deployer)) as SeigManagerV1_2
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

        //     let stakedA = await deployed.seigManagerV1["stakeOf(address)"](testAddress)
        //     console.log('stakedA', stakedA)

        //     let data = '0x0c4a118cd6aaffa1dc3e18a86d1f3c1218a3451d0f42d1c40b95df7a1478639918fc358b4af5298d000000000000000000000000000000000000000bc195fbf58ed6ffefa0bd79ad'

        //     await (await deployed.l1StakedTonInL2["register(bytes)"](data)).wait()

        //     let L2BalanceOf = await deployed.l2SeigManager["balanceOf(address)"](testAddress)

        //     console.log('L2BalanceOf', L2BalanceOf)
        // });

        it('deposit to level19  ', async () => {
            const { level19Address } = await getNamedAccounts();
            let account = tester

            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(account.address, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, account, deployed.depositManager.address, wtonAmount);

            let stakedA = await seigManagerV2["stakeOf(address,address)"](level19Address, account.address)
            // console.log('stakedA', stakedA)

            await deployed.depositManager.connect(account)["deposit(address,uint256)"](
                level19Address,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManagerV2["stakeOf(address,address)"](level19Address, account.address)
            // console.log('stakedB', stakedB)

            let L2BalanceOf = await deployed.l2SeigManager["balanceOf(address,address)"](level19Address, testAddress)
            // console.log('L2BalanceOf', L2BalanceOf)
            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
            expect(roundDown(stakedB,6)).to.be.eq(roundDown(L2BalanceOf, 6))


            let stakedL1 = await seigManagerV2["stakeOf(address)"](testAddress)
            let balanceOfL2 = await deployed.l2SeigManager["balanceOf(address)"](testAddress)
            expect(roundDown(stakedL1,6)).to.be.eq(roundDown(balanceOfL2, 6))
        })

        it('updateSeigniorage to layer1', async () => {
            const { level19Address, powerTonAddress } = await getNamedAccounts();

            let stakedA = await seigManagerV2["stakeOf(address,address)"](level19Address, testAddress)
            // console.log('stakedA', stakedA)

            let powerTonBalance = await deployed.WTON.balanceOf(powerTonAddress);
            await (await seigManagerV2.connect(deployer).updateSeigniorageLayer(level19Address)).wait()

            let stakedB = await seigManagerV2["stakeOf(address,address)"](level19Address, testAddress)
            // console.log('stakedB', stakedB)
            let L2BalanceOf = await deployed.l2SeigManager["balanceOf(address,address)"](level19Address, testAddress)
            // console.log('L2BalanceOf', L2BalanceOf)

            expect(stakedB).to.be.gt(stakedA)
            expect(await deployed.WTON.balanceOf(powerTonAddress)).to.be.gt(powerTonBalance)
            expect(roundDown(stakedB,6)).to.be.eq(roundDown(L2BalanceOf, 6))

            let stakedL1 = await seigManagerV2["stakeOf(address)"](testAddress)
            let balanceOfL2 = await deployed.l2SeigManager["balanceOf(address)"](testAddress)
            expect(roundDown(stakedL1,6)).to.be.eq(roundDown(balanceOfL2, 6))

        })


        it('requestWithdrawal to layer1', async () => {
            const { level19Address } = await getNamedAccounts();

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

            const beforeBalance = await deployed.WTON.balanceOf(testAddress)

            let stakedA = await seigManagerV2["stakeOf(address,address)"](level19Address, testAddress)
            // console.log('stakedA', stakedA)

            let pendingUnstakedA = await deployed.depositManager.pendingUnstaked(level19Address, testAddress)
            let pendingUnstakedLayer2A = await deployed.depositManager.pendingUnstakedLayer2(level19Address)
            let pendingUnstakedAccountA = await deployed.depositManager.pendingUnstakedAccount(testAddress)

            await deployed.depositManager.connect(tester)["requestWithdrawal(address,uint256)"](
                level19Address,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(testAddress);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await seigManagerV2["stakeOf(address,address)"](level19Address, testAddress)
            // console.log('stakedB', stakedB)
            expect(roundDown(stakedA.sub(ethers.constants.Two),2)).to.be.eq(
                roundDown(stakedB.add(wtonAmount), 2)
            )

            expect(
                await deployed.depositManager.pendingUnstaked(level19Address, testAddress)
            ).to.be.eq(pendingUnstakedA.add(wtonAmount))

            expect(
                await deployed.depositManager.pendingUnstakedLayer2(level19Address )
            ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

            expect(
                await deployed.depositManager.pendingUnstakedAccount(testAddress)
            ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

            let balanceOf = await deployed.l2SeigManager["balanceOf(address,address)"](level19Address, testAddress)
            // console.log('balanceOf', balanceOf)
            expect(roundDown(stakedB,6)).to.be.eq(roundDown(balanceOf, 6))


            let stakedL1 = await seigManagerV2["stakeOf(address)"](testAddress)
            let balanceOfL2 = await deployed.l2SeigManager["balanceOf(address)"](testAddress)
            expect(roundDown(stakedL1,6)).to.be.eq(roundDown(balanceOfL2, 6))

        })

        it('register', async () => {
            let stakeOf = await seigManagerV2["stakeOf(address)"](testAddress)
            // console.log('stakeOf', stakeOf)
            await (await deployed.l1StakedTonToL2.connect(deployer)["register(address)"](
                testAddress
            )).wait();

            let balanceOf = await deployed.l2SeigManager["balanceOf(address)"](testAddress)
            // console.log('balanceOf', balanceOf)
            expect(roundDown(stakeOf,6)).to.be.eq(roundDown(balanceOf, 6))
        })

    });



    describe('snapshot functions', () => {

        it('deposit to level19  ', async () => {

            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(testAddress, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(testAddress);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, tester, deployed.depositManager.address, wtonAmount);

            let stakedA = await seigManagerV2["stakeOf(address,address)"](layerAddress, testAddress)

            await deployed.depositManager.connect(tester)["deposit(address,uint256)"](
                layerAddress,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(testAddress);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManagerV2["stakeOf(address,address)"](layerAddress, testAddress)
            // console.log('stakedB', stakedB)

            let L2BalanceOf = await deployed.l2SeigManager["balanceOf(address)"](testAddress)
            // console.log('L2BalanceOf', L2BalanceOf)
            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
            expect(roundDown(stakedB,6)).to.be.eq(roundDown(L2BalanceOf, 6))
        })

        it('snapshot()', async () => {

            snapshotInfo.account = testAddress
            snapshotInfo.totTotalSupply = await deployed.l2SeigManager['totalSupply()']()
            snapshotInfo.accountBalanceOfLayer2 = await deployed.l2SeigManager["balanceOf(address,address)"](layerAddress, testAddress)
            snapshotInfo.accountBalanceOfTotal = await deployed.l2SeigManager["balanceOf(address)"](testAddress)

            const receipt = await (await deployed.l2SeigManager.connect(tester).onSnapshot()).wait()
            const topic = deployed.l2SeigManager.interface.getEventTopic('OnSnapshot');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.l2SeigManager.interface.parseLog(log);

            snapshotInfo.snapshotId = deployedEvent.args.snapshotId

        });

        it('deposit to level19  ', async () => {

            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(testAddress, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(testAddress);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, tester, deployed.depositManager.address, wtonAmount);

            let stakedA = await seigManagerV2["stakeOf(address,address)"](layerAddress, testAddress)

            await deployed.depositManager.connect(tester)["deposit(address,uint256)"](
                layerAddress,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(testAddress);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManagerV2["stakeOf(address,address)"](layerAddress, testAddress)
            // console.log('stakedB', stakedB)

            let L2BalanceOf = await deployed.l2SeigManager["balanceOf(address)"](testAddress)
            // console.log('L2BalanceOf', L2BalanceOf)
            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )
            expect(roundDown(stakedB,6)).to.be.eq(roundDown(L2BalanceOf, 6))
        })


        it('snapshot data is accurate ', async () => {

            let accountBalanceOfTotal= await deployed.l2SeigManager["balanceOf(address)"](testAddress)
            let totTotalSupply= await deployed.l2SeigManager["totalSupply()"]()

            let accountBalanceOfTotalAt = await deployed.l2SeigManager["balanceOfAt(address,uint256)"](testAddress, snapshotInfo.snapshotId)
            let totTotalSupplyAt = await deployed.l2SeigManager["totalSupplyAt(uint256)"](snapshotInfo.snapshotId)

            expect(accountBalanceOfTotal).to.be.gt(accountBalanceOfTotalAt)
            expect(totTotalSupply).to.be.gt(totTotalSupplyAt)

            expect(accountBalanceOfTotalAt).to.be.eq(snapshotInfo.accountBalanceOfTotal)
            expect(totTotalSupplyAt).to.be.eq(snapshotInfo.totTotalSupply)

        });


        it('requestWithdrawal to layer1', async () => {

            let wtonAmount = ethers.utils.parseEther("50"+"0".repeat(9))

            const beforeBalance = await deployed.WTON.balanceOf(testAddress)

            let stakedA = await seigManagerV2["stakeOf(address,address)"](layerAddress, testAddress)
            // console.log('stakedA', stakedA)

            let pendingUnstakedA = await deployed.depositManager.pendingUnstaked(layerAddress, testAddress)
            let pendingUnstakedLayer2A = await deployed.depositManager.pendingUnstakedLayer2(layerAddress)
            let pendingUnstakedAccountA = await deployed.depositManager.pendingUnstakedAccount(testAddress)

            await deployed.depositManager.connect(tester)["requestWithdrawal(address,uint256)"](
                layerAddress,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(testAddress);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await seigManagerV2["stakeOf(address,address)"](layerAddress, testAddress)
            // console.log('stakedB', stakedB)
            expect(roundDown(stakedA.sub(ethers.constants.Two),2)).to.be.eq(
                roundDown(stakedB.add(wtonAmount), 2)
            )

            expect(
                await deployed.depositManager.pendingUnstaked(layerAddress, testAddress)
            ).to.be.eq(pendingUnstakedA.add(wtonAmount))

            expect(
                await deployed.depositManager.pendingUnstakedLayer2(layerAddress )
            ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

            expect(
                await deployed.depositManager.pendingUnstakedAccount(testAddress)
            ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

            let balanceOf = await deployed.l2SeigManager["balanceOf(address,address)"](layerAddress, testAddress)
            // console.log('balanceOf', balanceOf)
            expect(roundDown(stakedB,6)).to.be.eq(roundDown(balanceOf, 6))

        })

        it('snapshot()', async () => {

            snapshotInfo.account = testAddress
            snapshotInfo.totTotalSupply = await deployed.l2SeigManager['totalSupply()']()
            snapshotInfo.accountBalanceOfLayer2 = await deployed.l2SeigManager["balanceOf(address,address)"](layerAddress, testAddress)
            snapshotInfo.accountBalanceOfTotal = await deployed.l2SeigManager["balanceOf(address)"](testAddress)

            const receipt = await (await deployed.l2SeigManager.connect(tester).onSnapshot()).wait()
            const topic = deployed.l2SeigManager.interface.getEventTopic('OnSnapshot');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.l2SeigManager.interface.parseLog(log);

            snapshotInfo.snapshotId = deployedEvent.args.snapshotId

        });


        it('requestWithdrawal to layer1', async () => {

            let wtonAmount = ethers.utils.parseEther("50"+"0".repeat(9))
            const beforeBalance = await deployed.WTON.balanceOf(testAddress)

            let stakedA = await seigManagerV2["stakeOf(address,address)"](layerAddress, testAddress)
            // console.log('stakedA', stakedA)

            let pendingUnstakedA = await deployed.depositManager.pendingUnstaked(layerAddress, testAddress)
            let pendingUnstakedLayer2A = await deployed.depositManager.pendingUnstakedLayer2(layerAddress)
            let pendingUnstakedAccountA = await deployed.depositManager.pendingUnstakedAccount(testAddress)

            await deployed.depositManager.connect(tester)["requestWithdrawal(address,uint256)"](
                layerAddress,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(testAddress);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await seigManagerV2["stakeOf(address,address)"](layerAddress, testAddress)
            // console.log('stakedB', stakedB)
            expect(roundDown(stakedA.sub(ethers.constants.Two),2)).to.be.eq(
                roundDown(stakedB.add(wtonAmount), 2)
            )

            expect(
                await deployed.depositManager.pendingUnstaked(layerAddress, testAddress)
            ).to.be.eq(pendingUnstakedA.add(wtonAmount))

            expect(
                await deployed.depositManager.pendingUnstakedLayer2(layerAddress )
            ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

            expect(
                await deployed.depositManager.pendingUnstakedAccount(testAddress)
            ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

            let balanceOf = await deployed.l2SeigManager["balanceOf(address,address)"](layerAddress, testAddress)
            // console.log('balanceOf', balanceOf)
            expect(roundDown(stakedB,6)).to.be.eq(roundDown(balanceOf, 6))

        })

        it('snapshot data is accurate ', async () => {

            let accountBalanceOfTotal= await deployed.l2SeigManager["balanceOf(address)"](testAddress)
            let totTotalSupply= await deployed.l2SeigManager["totalSupply()"]()

            let accountBalanceOfTotalAt = await deployed.l2SeigManager["balanceOfAt(address,uint256)"](testAddress, snapshotInfo.snapshotId)
            let totTotalSupplyAt = await deployed.l2SeigManager["totalSupplyAt(uint256)"](snapshotInfo.snapshotId)

            expect(accountBalanceOfTotal).to.be.lt(accountBalanceOfTotalAt)
            expect(totTotalSupply).to.be.lt(totTotalSupplyAt)

            expect(accountBalanceOfTotalAt).to.be.eq(snapshotInfo.accountBalanceOfTotal)
            expect(totTotalSupplyAt).to.be.eq(snapshotInfo.totTotalSupply)

        });

    });


    describe('# register', () => {
        it('register', async () => {
            let stakeOf = await seigManagerV2["stakeOf(address)"](testAddress)
            // console.log('stakeOf', stakeOf)
            await (await deployed.l1StakedTonToL2.connect(deployer)["register(address)"](
                testAddress
            )).wait();

            let balanceOf = await deployed.l2SeigManager["balanceOf(address)"](testAddress)
            // console.log('balanceOf', balanceOf)
            expect(roundDown(stakeOf,6)).to.be.eq(roundDown(balanceOf, 6))

        })
    });


    describe('# airdrop : dividend pool ', () => {

        it('deposit to level19 : addr1 ', async () => {
            let user = addr1
            let userAddress = addr1.address
            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(userAddress, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(userAddress);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, user, deployed.depositManager.address, wtonAmount);

            let stakedA = await seigManagerV2["stakeOf(address,address)"](layerAddress, userAddress)

            await deployed.depositManager.connect(user)["deposit(address,uint256)"](
                layerAddress,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(userAddress);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManagerV2["stakeOf(address,address)"](layerAddress, userAddress)
            let L2BalanceOf = await deployed.l2SeigManager["balanceOf(address)"](userAddress)
            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
            expect(roundDown(stakedB,6)).to.be.eq(roundDown(L2BalanceOf, 6))
        })


        it('deposit to level19 : addr2 ', async () => {
            let user = addr2
            let userAddress = addr2.address
            let wtonAmount = ethers.utils.parseEther("200"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(userAddress, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(userAddress);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, user, deployed.depositManager.address, wtonAmount);

            let stakedA = await seigManagerV2["stakeOf(address,address)"](layerAddress, userAddress)

            await deployed.depositManager.connect(user)["deposit(address,uint256)"](
                layerAddress,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(userAddress);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManagerV2["stakeOf(address,address)"](layerAddress, userAddress)
            let L2BalanceOf = await deployed.l2SeigManager["balanceOf(address)"](userAddress)
            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
            expect(roundDown(stakedB,6)).to.be.eq(roundDown(L2BalanceOf, 6))
        })

        it('snapshot() ', async () => {
            let addr1SnapshotInfo = {
                account: addr1,
                snapshotId: null,
                totTotalSupply: ethers.constants.Zero,
                accountBalanceOfLayer2: ethers.constants.Zero,
                accountBalanceOfTotal: ethers.constants.Zero,
            }
            let addr2SnapshotInfo = {
                account: addr2,
                snapshotId: null,
                totTotalSupply: ethers.constants.Zero,
                accountBalanceOfLayer2: ethers.constants.Zero,
                accountBalanceOfTotal: ethers.constants.Zero,
            }
            addrSnapshotInfos = {
                addr1: addr1SnapshotInfo,
                addr2: addr2SnapshotInfo
            }

            addrSnapshotInfos.addr1.totTotalSupply = await deployed.l2SeigManager['totalSupply()']()
            addrSnapshotInfos.addr2.totTotalSupply = await deployed.l2SeigManager['totalSupply()']()

            addrSnapshotInfos.addr1.accountBalanceOfLayer2 = await deployed.l2SeigManager["balanceOf(address,address)"](layerAddress, addr1.address)
            addrSnapshotInfos.addr2.accountBalanceOfLayer2 = await deployed.l2SeigManager["balanceOf(address,address)"](layerAddress, addr2.address)

            addrSnapshotInfos.addr1.accountBalanceOfTotal = await deployed.l2SeigManager["balanceOf(address)"](addr1.address)
            addrSnapshotInfos.addr2.accountBalanceOfTotal = await deployed.l2SeigManager["balanceOf(address)"](addr2.address)

            const receipt = await (await deployed.l2SeigManager.connect(tester).onSnapshot()).wait()
            const topic = deployed.l2SeigManager.interface.getEventTopic('OnSnapshot');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.l2SeigManager.interface.parseLog(log);

            addrSnapshotInfos.addr1.snapshotId = deployedEvent.args.snapshotId
            addrSnapshotInfos.addr2.snapshotId = deployedEvent.args.snapshotId

            expect(roundDown(
                addrSnapshotInfos.addr2.accountBalanceOfTotal.div(ethers.constants.Two), 1))
                .to.be.eq(roundDown(addrSnapshotInfos.addr1.accountBalanceOfTotal, 1))

        });

        it('distribute : TestERC20 ', async () => {
            let amount = ethers.utils.parseEther("1000")
            const TestERC20_ = await ethers.getContractFactory('TestERC20', {
                signer: deployer
              })
            const token1 = (await TestERC20_.connect(deployer).deploy()) as TestERC20
            token1.mint(testAddress, amount)

            await execAllowance(token1, tester, deployed.l2DividendPoolForTon.address, amount);

            const receipt = await (await deployed.l2DividendPoolForTon.connect(tester).distribute(
                token1.address, amount
            )).wait()
            const topic = deployed.l2DividendPoolForTon.interface.getEventTopic('Distributed');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.l2DividendPoolForTon.interface.parseLog(log);

            distributeEvents.push({
                token: deployedEvent.args.token,
                snapshotId: deployedEvent.args.snapshotId,
                amount : deployedEvent.args.amount
            })

            // console.log('distributeEvents', distributeEvents)
        })

        it('validate distribution events', async () => {
            let index = 0;
            let snapshotId = distributeEvents[index].snapshotId

            let totalSupply = await deployed.l2SeigManager['totalSupplyAt(uint256)'](snapshotId)
            let balanceAddr1 = await deployed.l2SeigManager['balanceOfAt(address,uint256)'](addr1.address, snapshotId)
            let balanceAddr2 = await deployed.l2SeigManager['balanceOfAt(address,uint256)'](addr2.address, snapshotId)

            expect(roundDown(
                balanceAddr2.div(ethers.constants.Two), 1))
                .to.be.eq(roundDown(balanceAddr1, 1))

        })

        it('deposit to level19 : addr1 ', async () => {
            let user = addr1
            let userAddress = addr1.address
            let wtonAmount = ethers.utils.parseEther("100"+"0".repeat(9))
            await deployed.WTON.connect(deployer).transfer(userAddress, wtonAmount);

            const beforeBalance = await deployed.WTON.balanceOf(userAddress);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(deployed.WTON, user, deployed.depositManager.address, wtonAmount);

            let stakedA = await seigManagerV2["stakeOf(address,address)"](layerAddress, userAddress)

            await deployed.depositManager.connect(user)["deposit(address,uint256)"](
                layerAddress,
                wtonAmount
            );

            const afterBalance = await deployed.WTON.balanceOf(userAddress);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManagerV2["stakeOf(address,address)"](layerAddress, userAddress)
            let L2BalanceOf = await deployed.l2SeigManager["balanceOf(address)"](userAddress)
            expect(roundDown(stakedB.add(ethers.constants.Zero), 1)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 1)
            )
            expect(roundDown(stakedB,6)).to.be.eq(roundDown(L2BalanceOf, 6))
        })

        it('validate claimable amount for distribution', async () => {
            let index = 0;
            let snapshotId = distributeEvents[index].snapshotId
            let token = await ethers.getContractAt("TestERC20", distributeEvents[index].token, deployer);
            let amount = distributeEvents[index].amount

            let totalSupply = await deployed.l2SeigManager['totalSupplyAt(uint256)'](snapshotId)
            let balanceAddr1 = await deployed.l2SeigManager['balanceOfAt(address,uint256)'](addr1.address, snapshotId)
            let balanceAddr2 = await deployed.l2SeigManager['balanceOfAt(address,uint256)'](addr2.address, snapshotId)

            let claimable1 = await deployed.l2DividendPoolForTon.claimable(distributeEvents[index].token, addr1.address)
            let claimable2 = await deployed.l2DividendPoolForTon.claimable(distributeEvents[index].token, addr2.address)

            expect(balanceAddr1.mul(ethers.utils.parseEther("1")).div(totalSupply)).to.be.eq(
                claimable1.mul(ethers.utils.parseEther("1")).div(amount)
            )

            expect(balanceAddr2.mul(ethers.utils.parseEther("1")).div(totalSupply)).to.be.eq(
                claimable2.mul(ethers.utils.parseEther("1")).div(amount)
            )
        })
        it('claim', async () => {
            let index = 0;
            let snapshotId = distributeEvents[index].snapshotId
            let token = await ethers.getContractAt("TestERC20", distributeEvents[index].token, deployer);
            let amount = distributeEvents[index].amount

            let prevBalance1Token = await token.balanceOf(addr1.address)
            let prevBalance2Token = await token.balanceOf(addr2.address)

            let totalSupply = await deployed.l2SeigManager['totalSupplyAt(uint256)'](snapshotId)
            let balanceAddr1 = await deployed.l2SeigManager['balanceOfAt(address,uint256)'](addr1.address, snapshotId)
            let balanceAddr2 = await deployed.l2SeigManager['balanceOfAt(address,uint256)'](addr2.address, snapshotId)

            let claimable1 = await deployed.l2DividendPoolForTon.claimable(distributeEvents[index].token, addr1.address)
            let claimable2 = await deployed.l2DividendPoolForTon.claimable(distributeEvents[index].token, addr2.address)

            expect(balanceAddr1.mul(ethers.utils.parseEther("1")).div(totalSupply)).to.be.eq(
                claimable1.mul(ethers.utils.parseEther("1")).div(amount)
            )

            expect(balanceAddr2.mul(ethers.utils.parseEther("1")).div(totalSupply)).to.be.eq(
                claimable2.mul(ethers.utils.parseEther("1")).div(amount)
            )

            await (await deployed.l2DividendPoolForTon.connect(addr1).claim(distributeEvents[index].token)).wait()
            await (await deployed.l2DividendPoolForTon.connect(addr2).claim(distributeEvents[index].token)).wait()

            expect(await token.balanceOf(addr1.address)).to.be.eq(claimable1.add(prevBalance1Token))
            expect(await token.balanceOf(addr2.address)).to.be.eq(claimable2.add(prevBalance2Token))
        })

    })

});

