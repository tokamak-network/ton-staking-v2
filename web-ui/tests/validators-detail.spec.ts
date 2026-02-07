import { test, expect, type Page } from '@playwright/test';
import { ethers } from 'ethers';
import { injectMockWallet } from './wallet-mock';

const L1_RPC = 'http://localhost:8546';
let addr: Record<string, any>;
let optAddr: Record<string, string>;

test.beforeEach(async ({ page }) => {
  await injectMockWallet(page);
});

const RAT_ABI = [
  'function getValidatorCount(address) view returns (uint256)',
  'function getActiveValidatorCount(address) view returns (uint256)',
  'function getDynamicMinimumCollateral(address) view returns (uint256)',
  'function getL2Validators(address) view returns (address[])',
  'function getValidatorDeposit(address, address) view returns (uint256)',
  'function getAvailableCollateral(address, address) view returns (uint256)',
  'function isValidatorActive(address, address) view returns (bool)',
  'function getValidatorRegistration(address, address) view returns (uint256, uint32, bool)',
  'function slashingPenalty() view returns (uint256)',
  'function validatorBuffer() view returns (uint256)',
  'function relaxedValidatorCheck() view returns (bool)',
  'function maxValidatorsPerL2() view returns (uint256)',
  'function evidenceSubmissionPeriod() view returns (uint256)',
  'function attentionCost() view returns (uint256)',
  'function getMinimumCollateral() view returns (uint256)',
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

// ============================================================
// Validator Configuration Section
// ============================================================
test.describe('Validator Configuration', () => {
  test('slashingPenalty (C_off) matches on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, l1());
    const penalty = await rat.slashingPenalty();
    const formatted = parseFloat(ethers.formatUnits(penalty, 27)).toFixed(2);

    await page.waitForSelector('text=Validator Configuration', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Validator Configuration' });
    const text = (await section.textContent())!;
    expect(text).toContain(formatted);
  });

  test('validatorBuffer matches on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, l1());
    const buffer = await rat.validatorBuffer();
    const formatted = parseFloat(ethers.formatUnits(buffer, 27)).toFixed(2);

    await page.waitForSelector('text=Validator Configuration', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Validator Configuration' });
    const text = (await section.textContent())!;
    expect(text).toContain(formatted);
  });

  test('relaxedValidatorCheck mode matches on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, l1());
    const relaxed = await rat.relaxedValidatorCheck();

    await page.waitForSelector('text=Validator Configuration', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Validator Configuration' });
    const text = (await section.textContent())!;

    if (relaxed) expect(text).toContain('Relaxed');
    else expect(text).toContain('Strict');
  });

  test('maxValidatorsPerL2 matches on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, l1());
    const maxVal = await rat.maxValidatorsPerL2();

    await page.waitForSelector('text=Validator Configuration', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Validator Configuration' });
    const text = (await section.textContent())!;

    if (Number(maxVal) === 0) expect(text).toContain('Unlimited');
    else expect(text).toContain(Number(maxVal).toString());
  });

  test('evidenceSubmissionPeriod matches on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, l1());
    const period = await rat.evidenceSubmissionPeriod();

    await page.waitForSelector('text=Validator Configuration', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Validator Configuration' });
    const text = (await section.textContent())!;
    expect(text).toContain(Number(period).toString());
  });
});

// ============================================================
// Validator Table - each row matches on-chain
// ============================================================
test.describe('Validator Table', () => {
  test('correct number of validators listed', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, l1());
    const validators = await rat.getL2Validators(sysConfig());

    if (validators.length === 0) {
      await expect(page.locator('text=No validators registered yet')).toBeVisible();
      return;
    }

    await page.waitForSelector('.validators-table tbody tr', { timeout: 10_000 });
    const rows = page.locator('.validators-table tbody tr');
    expect(await rows.count()).toBe(validators.length);
  });

  test('each validator deposit amount matches getValidatorDeposit()', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const provider = l1();
    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, provider);
    const validators = await rat.getL2Validators(sysConfig());
    if (validators.length === 0) { test.skip(); return; }

    await page.waitForSelector('.validators-table tbody tr', { timeout: 10_000 });
    const rows = page.locator('.validators-table tbody tr');

    for (let i = 0; i < validators.length; i++) {
      const valAddr = validators[i] as string;
      const deposit = await rat.getValidatorDeposit(valAddr, sysConfig());
      const depositFormatted = parseFloat(ethers.formatUnits(deposit, 27)).toFixed(2);

      const row = rows.nth(i);
      const rowText = (await row.textContent())!;
      expect(rowText).toContain(depositFormatted);
    }
  });

  test('each validator available collateral matches getAvailableCollateral()', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const provider = l1();
    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, provider);
    const validators = await rat.getL2Validators(sysConfig());
    if (validators.length === 0) { test.skip(); return; }

    await page.waitForSelector('.validators-table tbody tr', { timeout: 10_000 });
    const rows = page.locator('.validators-table tbody tr');

    for (let i = 0; i < validators.length; i++) {
      const valAddr = validators[i] as string;
      const available = await rat.getAvailableCollateral(valAddr, sysConfig());
      const formatted = parseFloat(ethers.formatUnits(available, 27)).toFixed(2);

      const row = rows.nth(i);
      const rowText = (await row.textContent())!;
      expect(rowText).toContain(formatted);
    }
  });

  test('each validator active status matches isValidatorActive()', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const provider = l1();
    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, provider);
    const validators = await rat.getL2Validators(sysConfig());
    if (validators.length === 0) { test.skip(); return; }

    await page.waitForSelector('.validators-table tbody tr', { timeout: 10_000 });
    const rows = page.locator('.validators-table tbody tr');

    for (let i = 0; i < validators.length; i++) {
      const valAddr = validators[i] as string;
      const isActive = await rat.isValidatorActive(valAddr, sysConfig());

      const row = rows.nth(i);
      const rowText = (await row.textContent())!;
      if (isActive) expect(rowText).toContain('Active');
      else expect(rowText).toContain('Inactive');
    }
  });

  test('each validator WTON balance matches on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const provider = l1();
    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, provider);
    const wton = new ethers.Contract(addr.wton, WTON_ABI, provider);
    const validators = await rat.getL2Validators(sysConfig());
    if (validators.length === 0) { test.skip(); return; }

    await page.waitForSelector('.validators-table tbody tr', { timeout: 10_000 });
    const rows = page.locator('.validators-table tbody tr');

    for (let i = 0; i < validators.length; i++) {
      const valAddr = validators[i] as string;
      const bal = await wton.balanceOf(valAddr);
      const formatted = parseFloat(ethers.formatUnits(bal, 27)).toFixed(4);

      const row = rows.nth(i);
      const rowText = (await row.textContent())!;
      expect(rowText).toContain(formatted);
    }
  });
});

// ============================================================
// Validator Reward Contract
// ============================================================
test.describe('Validator Reward Contract', () => {
  test('ValidatorReward address displayed correctly', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    await page.waitForSelector('text=Validator Reward Contract', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Validator Reward Contract' });
    const text = (await section.textContent())!.toLowerCase();
    expect(text).toContain(addr.validatorRewardProxy.toLowerCase());
  });

  test('ValidatorReward WTON balance matches on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const wton = new ethers.Contract(addr.wton, WTON_ABI, l1());
    const bal = await wton.balanceOf(addr.validatorRewardProxy);
    const formatted = parseFloat(ethers.formatUnits(bal, 27)).toFixed(4);

    await page.waitForSelector('text=Validator Reward Contract', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Validator Reward Contract' });
    const text = (await section.textContent())!;
    expect(text).toContain(formatted);
  });
});
