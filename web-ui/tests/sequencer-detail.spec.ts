import { test, expect, type Page } from '@playwright/test';
import { ethers } from 'ethers';
import { injectMockWallet } from './wallet-mock';

const L1_RPC = 'http://localhost:8546';
let addr: Record<string, any>;
let optAddr: Record<string, string>;

test.beforeEach(async ({ page }) => {
  await injectMockWallet(page);
});

const LAYER2_MANAGER_ABI = [
  'function operatorOfRollupConfig(address) view returns (address)',
  'function candidateAddOnOfOperator(address) view returns (address)',
  'function getBridgedTonByLayer(address) view returns (uint256)',
];
const OPERATOR_MANAGER_ABI = [
  'function manager() view returns (address)',
];
const SEIG_MANAGER_ABI = [
  'function stakeOf(address, address) view returns (uint256)',
  'function minimumAmount() view returns (uint256)',
  'function checkCurrentEligibility(address) view returns (bool, uint256, uint256)',
];
const LAYER2_REGISTRY_ABI = [
  'function layer2s(address) view returns (bool)',
];
const WTON_ABI = [
  'function balanceOf(address) view returns (uint256)',
];

function sysConfig(): string {
  return addr.systemConfig || optAddr.SystemConfigProxy;
}
function l1() {
  return new ethers.JsonRpcProvider(L1_RPC);
}
async function goTab(page: Page, tabText: string) {
  await page.locator(`text=${tabText}`).first().click();
  await page.waitForTimeout(3000);
}

test.beforeAll(async ({ request }) => {
  const [a, o] = await Promise.all([
    request.get('http://localhost:5173/addresses.json'),
    request.get('http://localhost:5173/optimism-addresses.json'),
  ]);
  addr = await a.json();
  optAddr = await o.json();
});

test.describe('Sequencer Detail Page', () => {
  test('sequencer address matches OperatorManager.manager()', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Sequencer');

    const provider = l1();
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);
    const operatorManager = await lm.operatorOfRollupConfig(sysConfig());
    if (operatorManager === ethers.ZeroAddress) { test.skip(); return; }

    const omContract = new ethers.Contract(operatorManager, OPERATOR_MANAGER_ABI, provider);
    const manager = await omContract.manager();

    await page.waitForSelector('text=Sequencer Information', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Sequencer Information' });
    const text = (await section.textContent())!.toLowerCase();

    expect(text).toContain(manager.toLowerCase());
    expect(text).toContain(operatorManager.toLowerCase());
  });

  test('CandidateAddOn address matches on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Sequencer');

    const provider = l1();
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);
    const operatorManager = await lm.operatorOfRollupConfig(sysConfig());
    if (operatorManager === ethers.ZeroAddress) { test.skip(); return; }

    const candidateAddOn = await lm.candidateAddOnOfOperator(operatorManager);

    await page.waitForSelector('text=Sequencer Information', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Sequencer Information' });
    const text = (await section.textContent())!.toLowerCase();
    expect(text).toContain(candidateAddOn.toLowerCase());
  });

  test('OperatorManager staked amount matches stakeOf(candidateAddOn, operatorManager)', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Sequencer');

    const provider = l1();
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);
    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, provider);

    const operatorManager = await lm.operatorOfRollupConfig(sysConfig());
    if (operatorManager === ethers.ZeroAddress) { test.skip(); return; }
    const candidateAddOn = await lm.candidateAddOnOfOperator(operatorManager);

    const staked = await seig.stakeOf(candidateAddOn, operatorManager);
    const stakedFormatted = parseFloat(ethers.formatUnits(staked, 27)).toFixed(2);

    await page.waitForSelector('text=Sequencer Information', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Sequencer Information' });
    const text = (await section.textContent())!;
    expect(text).toContain(stakedFormatted);
  });

  test('eligibility status matches checkCurrentEligibility()', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Sequencer');

    const provider = l1();
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);
    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, provider);

    const operatorManager = await lm.operatorOfRollupConfig(sysConfig());
    if (operatorManager === ethers.ZeroAddress) { test.skip(); return; }
    const candidateAddOn = await lm.candidateAddOnOfOperator(operatorManager);

    let isEligible = false;
    let requiredStake = 0n;
    let currentStake = 0n;
    try {
      const result = await seig.checkCurrentEligibility(candidateAddOn);
      isEligible = result[0];
      requiredStake = result[1];
      currentStake = result[2];
    } catch {
      // checkCurrentEligibility may not be available
    }

    await page.waitForSelector('text=Sequencer Information', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Sequencer Information' });
    const text = (await section.textContent())!;

    if (isEligible) {
      expect(text).toContain('Eligible');
    } else {
      expect(text).toContain('Not Eligible');
    }

    // Required stake
    const reqFormatted = parseFloat(ethers.formatUnits(requiredStake, 27)).toFixed(2);
    expect(text).toContain(reqFormatted);

    // Current stake from eligibility
    const curFormatted = parseFloat(ethers.formatUnits(currentStake, 27)).toFixed(2);
    expect(text).toContain(curFormatted);
  });

  test('Bridged TON matches getBridgedTonByLayer()', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Sequencer');

    const provider = l1();
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);

    const operatorManager = await lm.operatorOfRollupConfig(sysConfig());
    if (operatorManager === ethers.ZeroAddress) { test.skip(); return; }
    const candidateAddOn = await lm.candidateAddOnOfOperator(operatorManager);

    const bridgedTon = await lm.getBridgedTonByLayer(candidateAddOn);
    const formatted = parseFloat(ethers.formatEther(bridgedTon)).toFixed(2);

    await page.waitForSelector('text=Sequencer Information', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Sequencer Information' });
    const text = (await section.textContent())!;
    expect(text).toContain(formatted);
  });

  test('minimum sequencer stake matches SeigManager.minimumAmount()', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Sequencer');

    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, l1());
    const minAmount = await seig.minimumAmount();
    const formatted = parseFloat(ethers.formatUnits(minAmount, 27)).toFixed(2);

    await page.waitForSelector('text=Sequencer Information', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Sequencer Information' });
    const text = (await section.textContent())!;
    expect(text).toContain(formatted);
  });

  test('Layer2Registry status matches on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Sequencer');

    const provider = l1();
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);
    const registry = new ethers.Contract(addr.layer2RegistryProxy, LAYER2_REGISTRY_ABI, provider);

    const operatorManager = await lm.operatorOfRollupConfig(sysConfig());
    if (operatorManager === ethers.ZeroAddress) { test.skip(); return; }
    const candidateAddOn = await lm.candidateAddOnOfOperator(operatorManager);
    const isRegistered = await registry.layer2s(candidateAddOn);

    await page.waitForSelector('text=Sequencer Information', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Sequencer Information' });
    const text = (await section.textContent())!;

    if (isRegistered) {
      expect(text).toContain('Registered');
    } else {
      expect(text).toContain('Not Registered');
    }
  });
});
