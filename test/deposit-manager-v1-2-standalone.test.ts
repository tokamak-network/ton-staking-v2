import { expect } from './shared/expect'
import { ethers, getNamedAccounts } from 'hardhat'
import { BigNumber, Signer, Contract } from 'ethers'
import hre from 'hardhat'
import { jsonFixtures } from './shared/fixtures'
import DepositManagerProxy_Json from './abi/DepositManagerProxy.json'
import DepositManager_Dune_Json from './abi/DepositManager_Dune.json'
import {encodeFunctionSignature} from 'web3-eth-abi'

const STAKING_DECIMALS = 27; // Staking uses 27 decimals

function roundDown(val: BigNumber, decimals: number) {
    return ethers.utils.formatUnits(val, decimals).split(".")[0]
}

async function execAllowance(contract: any, fromSigner: Signer, toAddress: string, amount: BigNumber) {
    let allowance = await contract.allowance(await fromSigner.getAddress(), toAddress);
    if (allowance.lt(amount)) {
        await contract.connect(fromSigner).approve(toAddress, amount);
    }
}

// Helper: Get actual stake balance (may be slightly less due to rounding)
async function getActualStakeBalance(seigManager: Contract, layer2: string, account: Signer): Promise<BigNumber> {
    return await seigManager["stakeOf(address,address)"](layer2, await account.getAddress());
}

// Helper: Setup deposit (transfer WTON, approve, deposit)
async function setupDeposit(
    wton: Contract,
    depositManager: Contract,
    deployer: Signer,
    account: Signer,
    layer2: string,
    amount: BigNumber
) {
    await wton.connect(deployer).transfer(await account.getAddress(), amount);
    await execAllowance(wton, account, depositManager.address, amount);
    await depositManager.connect(account)["deposit(address,uint256)"](layer2, amount);
}

// Helper: Setup withdrawal request (get actual balance and request withdrawal)
async function setupWithdrawal(
    depositManager: Contract,
    seigManager: Contract,
    account: Signer,
    layer2: string,
    requestedAmount: BigNumber
): Promise<BigNumber> {
    const actualStakeBalance = await getActualStakeBalance(seigManager, layer2, account);
    const withdrawalAmount = actualStakeBalance.lt(requestedAmount) ? actualStakeBalance : requestedAmount;
    await depositManager.connect(account)["requestWithdrawal(address,uint256)"](layer2, withdrawalAmount);
    return withdrawalAmount;
}

// Helper: Find event log in receipt
function findEventInReceipt(contract: Contract, receipt: any, eventName: string) {
    const eventTopic = contract.interface.getEventTopic(eventName);
    const eventLog = receipt.logs.find((x: any) => x.topics[0] === eventTopic);
    return eventLog ? contract.interface.parseLog(eventLog) : null;
}

// Helper: Compare stake balance with tolerance (add 1 wei for rounding)
function expectStakeBalance(actual: BigNumber, expected: BigNumber) {
    expect(roundDown(actual.add(1), STAKING_DECIMALS)).to.be.eq(roundDown(expected, STAKING_DECIMALS));
}

describe('DepositManagerV1_2 - Standalone Tests', () => {
    let deployer: Signer, addr1: Signer, addr2: Signer;
    let depositManagerV1_2: Contract;
    let depositManagerProxy: Contract;
    let wton: Contract;
    let seigManagerV2: Contract;
    let layer2Registry: Contract;
    let layer2Info: any;

    before('deploy contracts and upgrade to V1_2', async () => {
        [deployer, addr1, addr2] = await ethers.getSigners();

        // Get deployed contract addresses from hardhat config
        const {
            DepositManager, SeigManager, L2Registry, TON, WTON, DAOCommitteeProxy,
            CandidateFactory, DaoCommitteeAdminAddress,
            level19Address, level19Admin
        } = await getNamedAccounts();

        // Get contract ABIs
        const contractJson = await jsonFixtures();

        // Create contract instances from deployed addresses
        // Use DepositManagerProxy ABI for proxy
        depositManagerProxy = new ethers.Contract(DepositManager, DepositManagerProxy_Json.abi, deployer);
        wton = new ethers.Contract(WTON, contractJson.WTON.abi, deployer);
        seigManagerV2 = new ethers.Contract(SeigManager, contractJson.SeigManager.abi, deployer);
        layer2Registry = new ethers.Contract(L2Registry, contractJson.L2Registry.abi, deployer);

        // Upgrade DepositManager to V1_2 using selector-based upgrade
        const DepositManagerV1_2Factory = await ethers.getContractFactory("DepositManagerV1_2");
        const depositManagerV1_2Imp = await DepositManagerV1_2Factory.deploy();

        // DepositManagerProxy의 admin은 DAOCommitteeProxy입니다
        // DAOCommitteeProxy를 impersonate하여 upgrade
        await hre.network.provider.send("hardhat_impersonateAccount", [DAOCommitteeProxy]);
        await hre.network.provider.send("hardhat_setBalance", [
            DAOCommitteeProxy,
            "0x10000000000000000000000000",
        ]);
        const depositManagerAdmin = await hre.ethers.getSigner(DAOCommitteeProxy);

        // Register DepositManagerV1_2 as implementation
        // Check which index is available (try index 1, 2, 3, etc.)
        let implementationIndex = 3;
        // Try to find an unused index or use a new one
        // For DepositManagerV1_2, we can use index 1 if it's available, or use a higher index
        // In production, index 0 is usually the main implementation, so we use index 1 for V1_2
        await depositManagerProxy.connect(depositManagerAdmin).setImplementation2(
            depositManagerV1_2Imp.address,
            implementationIndex,
            true
        );

        // Set selector implementations for redeposit functions only
        const selector1 = encodeFunctionSignature("redeposit(address)");
        const selector2 = encodeFunctionSignature("redepositMulti(address,uint256)");
        const redepositSelectors = [selector1, selector2];

        await depositManagerProxy.connect(depositManagerAdmin).setSelectorImplementations2(
            redepositSelectors,
            depositManagerV1_2Imp.address
        );

        // Use DepositManager_Dune.json ABI which includes all functions and events
        // including WithdrawalRequestCanceled event from DepositManagerV1_2
        depositManagerV1_2 = new ethers.Contract(DepositManager, DepositManager_Dune_Json.abi, deployer);

        // Mint WTON for testing (using DAOCommitteeProxy as minter)
        const daoAdmin = await hre.ethers.getSigner(DAOCommitteeProxy);
        await wton.connect(daoAdmin).mint(await deployer.getAddress(), ethers.utils.parseEther("10000" + "0".repeat(9)));

        // Use fixed level layer2 address
        const layer2Address = "0x0F42D1C40b95DF7A1478639918fc358B4aF5298D";
        layer2Info = {
            operatorAdmin: level19Admin,
            layer2: layer2Address,
            operator: level19Admin
        };

        // Verify layer2 is registered in Layer2Registry (should already be registered in forked environment)
        const isRegistered = await layer2Registry.layer2s(layer2Address);
        if (!isRegistered) {
            throw new Error(`Layer2 ${layer2Address} is not registered in Layer2Registry. Please use an existing registered layer2.`);
        }
    });

    describe('Unit Tests: WithdrawalRequestCanceled Event', () => {
        let wtonAmount: BigNumber;
        let withdrawalAmount: BigNumber;
        let layer2: string;
        let account: Signer;

        before('setup deposit and withdrawal request', async () => {
            layer2 = layer2Info.layer2;
            account = addr1;
            wtonAmount = ethers.utils.parseEther("100" + "0".repeat(9));

            await setupDeposit(wton, depositManagerV1_2, deployer, account, layer2, wtonAmount);
            withdrawalAmount = await setupWithdrawal(depositManagerV1_2, seigManagerV2, account, layer2, wtonAmount);
        });

        it('should emit WithdrawalRequestCanceled event when redeposit is called', async () => {
            const tx = await depositManagerV1_2.connect(account).redeposit(layer2);
            const receipt = await tx.wait();

            const canceledEvent = findEventInReceipt(depositManagerV1_2, receipt, 'WithdrawalRequestCanceled');
            expect(canceledEvent).to.not.be.null;
            expect(canceledEvent?.name).to.be.eq('WithdrawalRequestCanceled');
            expect(canceledEvent?.args).to.not.be.undefined;

            if (canceledEvent && canceledEvent.args) {
                const depositorAddress = typeof canceledEvent.args.depositor === 'string'
                    ? canceledEvent.args.depositor
                    : canceledEvent.args.depositor.toString();
                const accountAddress = (await account.getAddress()).toLowerCase();

                expect(canceledEvent.args.layer2.toLowerCase()).to.be.eq(layer2.toLowerCase());
                expect(depositorAddress.toLowerCase()).to.be.eq(accountAddress);
                expect(canceledEvent.args.amount).to.be.eq(withdrawalAmount);
            }
        });

        it('should emit both Deposited and WithdrawalRequestCanceled events', async () => {
            const newWtonAmount = ethers.utils.parseEther("50" + "0".repeat(9));
            await setupDeposit(wton, depositManagerV1_2, deployer, account, layer2, newWtonAmount);
            await setupWithdrawal(depositManagerV1_2, seigManagerV2, account, layer2, newWtonAmount);

            const tx = await depositManagerV1_2.connect(account).redeposit(layer2);
            const receipt = await tx.wait();

            const depositedEvent = findEventInReceipt(depositManagerV1_2, receipt, 'Deposited');
            const canceledEvent = findEventInReceipt(depositManagerV1_2, receipt, 'WithdrawalRequestCanceled');

            expect(depositedEvent).to.not.be.null;
            expect(canceledEvent).to.not.be.null;

            if (depositedEvent && canceledEvent) {
                expect(depositedEvent.args.amount).to.be.eq(newWtonAmount);
                expect(canceledEvent.args.amount).to.be.eq(newWtonAmount);
                expect(depositedEvent.args.layer2.toLowerCase()).to.be.eq(canceledEvent.args.layer2.toLowerCase());
                expect(depositedEvent.args.depositor.toLowerCase()).to.be.eq(canceledEvent.args.depositor.toLowerCase());
            }
        });

        it('should emit WithdrawalRequestCanceled event for redepositMulti', async () => {
            const amount1 = ethers.utils.parseEther("10" + "0".repeat(9));
            const amount2 = ethers.utils.parseEther("20" + "0".repeat(9));
            const totalAmount = amount1.add(amount2);

            await setupDeposit(wton, depositManagerV1_2, deployer, account, layer2, totalAmount);

            const actualStakeBalanceMulti = await getActualStakeBalance(seigManagerV2, layer2, account);
            const withdrawalAmount1 = actualStakeBalanceMulti.lt(amount1) ? actualStakeBalanceMulti : amount1;
            const remainingBalance = actualStakeBalanceMulti.sub(withdrawalAmount1);
            const withdrawalAmount2 = remainingBalance.lt(amount2) ? remainingBalance : amount2;

            await depositManagerV1_2.connect(account)["requestWithdrawal(address,uint256)"](layer2, withdrawalAmount1);
            await depositManagerV1_2.connect(account)["requestWithdrawal(address,uint256)"](layer2, withdrawalAmount2);

            const tx = await depositManagerV1_2.connect(account).redepositMulti(layer2, 2);
            const receipt = await tx.wait();

            const canceledEvent = findEventInReceipt(depositManagerV1_2, receipt, 'WithdrawalRequestCanceled');
            expect(canceledEvent).to.not.be.null;

            if (canceledEvent) {
                const expectedAmount = withdrawalAmount1.add(withdrawalAmount2);
                expect(canceledEvent.args.amount).to.be.eq(expectedAmount);
            }
        });
    });

    describe('E2E Tests: Deposit -> RequestWithdrawal -> Redeposit Flow', () => {
        let layer2: string;
        let account: Signer;
        let wtonAmount: BigNumber;

        before('setup', async () => {
            layer2 = layer2Info.layer2;
            account = addr2;
            wtonAmount = ethers.utils.parseEther("200" + "0".repeat(9));
        });

        it('should correctly track net pending withdrawals after redeposit', async () => {
            await setupDeposit(wton, depositManagerV1_2, deployer, account, layer2, wtonAmount);

            const stakedAfterDeposit = await getActualStakeBalance(seigManagerV2, layer2, account);
            expectStakeBalance(stakedAfterDeposit, wtonAmount);

            const pendingUnstakedBefore = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());
            const withdrawalAmount = await setupWithdrawal(depositManagerV1_2, seigManagerV2, account, layer2, wtonAmount);

            const pendingUnstakedAfterRequest = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());
            expect(pendingUnstakedAfterRequest).to.be.eq(pendingUnstakedBefore.add(withdrawalAmount));

            const stakedBeforeRedeposit = await getActualStakeBalance(seigManagerV2, layer2, account);
            const pendingUnstakedBeforeRedeposit = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());

            const tx = await depositManagerV1_2.connect(account).redeposit(layer2);
            const receipt = await tx.wait();

            const canceledEvent = findEventInReceipt(depositManagerV1_2, receipt, 'WithdrawalRequestCanceled');
            expect(canceledEvent).to.not.be.null;

            const stakedAfterRedeposit = await getActualStakeBalance(seigManagerV2, layer2, account);
            const pendingUnstakedAfterRedeposit = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());

            expectStakeBalance(stakedAfterRedeposit, stakedBeforeRedeposit.add(withdrawalAmount));
            expect(pendingUnstakedAfterRedeposit).to.be.eq(pendingUnstakedBeforeRedeposit.sub(withdrawalAmount));
        });

        it('should allow calculating net pending withdrawals correctly', async () => {
            const testAmount = ethers.utils.parseEther("150" + "0".repeat(9));

            await setupDeposit(wton, depositManagerV1_2, deployer, account, layer2, testAmount);
            const testWithdrawalAmount = await setupWithdrawal(depositManagerV1_2, seigManagerV2, account, layer2, testAmount);

            const pendingBefore = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());
            await depositManagerV1_2.connect(account).redeposit(layer2);
            const pendingAfter = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());

            expect(pendingAfter).to.be.eq(pendingBefore.sub(testWithdrawalAmount));
        });

        it('should distinguish between fresh deposit and redeposit events', async () => {
            const freshDepositAmount = ethers.utils.parseEther("75" + "0".repeat(9));
            const redepositAmount = ethers.utils.parseEther("25" + "0".repeat(9));

            // Fresh deposit: transfer, approve, and deposit
            await wton.connect(deployer).transfer(await account.getAddress(), freshDepositAmount);
            await execAllowance(wton, account, depositManagerV1_2.address, freshDepositAmount);
            const freshDepositTx = await depositManagerV1_2.connect(account)["deposit(address,uint256)"](
                layer2,
                freshDepositAmount
            );
            const freshDepositReceipt = await freshDepositTx.wait();

            const freshDepositedEvent = findEventInReceipt(depositManagerV1_2, freshDepositReceipt, 'Deposited');
            const freshCanceledEvent = findEventInReceipt(depositManagerV1_2, freshDepositReceipt, 'WithdrawalRequestCanceled');

            expect(freshDepositedEvent).to.not.be.null;
            expect(freshCanceledEvent).to.be.null;

            await setupDeposit(wton, depositManagerV1_2, deployer, account, layer2, redepositAmount);
            await setupWithdrawal(depositManagerV1_2, seigManagerV2, account, layer2, redepositAmount);

            const redepositTx = await depositManagerV1_2.connect(account).redeposit(layer2);
            const redepositReceipt = await redepositTx.wait();

            const redepositDepositedEvent = findEventInReceipt(depositManagerV1_2, redepositReceipt, 'Deposited');
            const redepositCanceledEvent = findEventInReceipt(depositManagerV1_2, redepositReceipt, 'WithdrawalRequestCanceled');

            expect(redepositDepositedEvent).to.not.be.null;
            expect(redepositCanceledEvent).to.not.be.null;
        });
    });
});
