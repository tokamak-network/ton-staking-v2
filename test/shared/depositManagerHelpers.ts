import { expect } from './expect'
import { ethers } from 'hardhat'
import { BigNumber, Signer, Contract } from 'ethers'

export const STAKING_DECIMALS = 27; // Staking uses 27 decimals

/**
 * Round down a BigNumber value by removing decimal places
 */
export function roundDown(val: BigNumber, decimals: number): string {
    return ethers.utils.formatUnits(val, decimals).split(".")[0]
}

/**
 * Execute allowance approval if current allowance is less than required amount
 */
export async function execAllowance(
    contract: any,
    fromSigner: Signer,
    toAddress: string,
    amount: BigNumber
): Promise<void> {
    const allowance = await contract.allowance(await fromSigner.getAddress(), toAddress);
    if (allowance.lt(amount)) {
        await contract.connect(fromSigner).approve(toAddress, amount);
    }
}

/**
 * Get actual stake balance (may be slightly less due to rounding)
 */
export async function getActualStakeBalance(
    seigManager: Contract,
    layer2: string,
    account: Signer
): Promise<BigNumber> {
    return await seigManager["stakeOf(address,address)"](layer2, await account.getAddress());
}

/**
 * Setup deposit: transfer WTON, approve, and deposit
 */
export async function setupDeposit(
    wton: Contract,
    depositManager: Contract,
    deployer: Signer,
    account: Signer,
    layer2: string,
    amount: BigNumber
): Promise<void> {
    await wton.connect(deployer).transfer(await account.getAddress(), amount);
    await execAllowance(wton, account, depositManager.address, amount);
    await depositManager.connect(account)["deposit(address,uint256)"](layer2, amount);
}

/**
 * Setup withdrawal request: get actual balance and request withdrawal
 * Returns the actual withdrawal amount (may be less than requested due to rounding)
 */
export async function setupWithdrawal(
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

/**
 * Find event log in receipt
 */
export function findEventInReceipt(contract: Contract, receipt: any, eventName: string) {
    const eventTopic = contract.interface.getEventTopic(eventName);
    const eventLog = receipt.logs.find((x: any) => x.topics[0] === eventTopic);
    return eventLog ? contract.interface.parseLog(eventLog) : null;
}

/**
 * Compare stake balance with tolerance (add 1 wei for rounding)
 */
export function expectStakeBalance(actual: BigNumber, expected: BigNumber): void {
    expect(roundDown(actual.add(1), STAKING_DECIMALS)).to.be.eq(roundDown(expected, STAKING_DECIMALS));
}

