import { test, expect, type Page } from '@playwright/test';
import { ethers } from 'ethers';
import { injectMockWallet } from './wallet-mock';

const L1_RPC = 'http://localhost:8546';
let addr: Record<string, any>;
let optAddr: Record<string, string>;

test.beforeEach(async ({ page }) => {
  await injectMockWallet(page);
});

const SEIG_MANAGER_ABI = [
  'function lastSeigBlock() view returns (uint256)',
  'function paused() view returns (bool)',
  'function seigPerBlock() view returns (uint256)',
  'function daoDistributionRatio() view returns (uint256)',
  'function minStakingRatio() view returns (uint256)',
  'function validatorDistributionRatio() view returns (uint256)',
  'function halfSaturationPoint() view returns (uint256)',
  'function getEffectiveBridgedTon(address) view returns (uint256)',
  'function totalEffectiveBridgedTON() view returns (uint256)',
  'function claimableL2Seigniorage(address) view returns (uint256)',
  'function checkCurrentEligibility(address) view returns (bool, uint256, uint256)',
  'function bridgedTONRewardPerUint() view returns (uint256)',
  'function validatorRewardPerUint() view returns (uint256)',
];
const LAYER2_MANAGER_ABI = [
  'function operatorOfRollupConfig(address) view returns (address)',
  'function candidateAddOnOfOperator(address) view returns (address)',
  'function getBridgedTonByLayer(address) view returns (uint256)',
  'function getRollupConfig(address) view returns (address)',
  'function statusLayer2(address) view returns (uint8)',
];
const LAYER2_REGISTRY_ABI = [
  'function layer2s(address) view returns (bool)',
];
const OPERATOR_MANAGER_ABI = [
  'function manager() view returns (address)',
];
const WTON_ABI = [
  'function balanceOf(address) view returns (uint256)',
];
const SYSTEM_CONFIG_ABI = [
  'function unsafeBlockSigner() view returns (address)',
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

/** Get the CandidateAddOn address for the registered L2 */
async function getCandidateAddOn(): Promise<string> {
  const provider = l1();
  const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);
  const operatorManager = await lm.operatorOfRollupConfig(sysConfig());
  if (operatorManager === ethers.ZeroAddress) throw new Error('No operator');
  return await lm.candidateAddOnOfOperator(operatorManager);
}

/** Navigate to seigniorage tab and query with candidateAddOn */
async function goSeigniorageAndQuery(page: Page, candidateAddOn: string) {
  await page.goto('/');
  await page.waitForSelector('text=Configuration', { timeout: 30_000 });
  await goTab(page, 'Seigniorage');

  // Fill in the Layer2 address and query
  const input = page.locator('#layer2-address-input');
  await input.fill(candidateAddOn);
  await page.locator('button', { hasText: 'Query' }).click();
  await page.waitForTimeout(5000); // wait for data to load
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
// Layer2 Registration Status
// ============================================================
test.describe('Seigniorage - Registration Status', () => {
  test('isRegistered and layer2Status match on-chain', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const provider = l1();
    const registry = new ethers.Contract(addr.layer2RegistryProxy, LAYER2_REGISTRY_ABI, provider);
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);

    const isRegistered = await registry.layer2s(candidateAddOn);
    // The rollupConfig is sysConfig() since the candidateAddOn was derived from it
    const rollupConfig = sysConfig();
    let status = 0;
    try {
      status = Number(await lm.statusLayer2(rollupConfig));
    } catch { /* may not be available */ }

    const section = page.locator('section', { hasText: 'Layer2 Registration Status' });
    const text = (await section.textContent())!;

    if (isRegistered) expect(text).toContain('Yes');
    else expect(text).toContain('No');

    if (status === 1) expect(text).toContain('Active');
    else if (status === 0) expect(text).toContain('Not Registered');
    else if (status === 2) expect(text).toContain('Paused');

    // RollupConfig address displayed
    expect(text.toLowerCase()).toContain(rollupConfig.toLowerCase());
  });
});

// ============================================================
// Operator Manager Information
// ============================================================
test.describe('Seigniorage - Operator Manager Info', () => {
  test('operatorManager address and manager() match on-chain', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const provider = l1();
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);
    // Use sysConfig() as rollupConfig (since candidateAddOn was derived from it)
    const rollupConfig = sysConfig();
    const operatorManager = await lm.operatorOfRollupConfig(rollupConfig);
    let manager = ethers.ZeroAddress;
    if (operatorManager !== ethers.ZeroAddress) {
      const omContract = new ethers.Contract(operatorManager, OPERATOR_MANAGER_ABI, provider);
      manager = await omContract.manager();
    }

    const section = page.locator('section', { hasText: 'Operator Manager Information' });
    const text = (await section.textContent())!.toLowerCase();

    expect(text).toContain(operatorManager.toLowerCase());
    expect(text).toContain(manager.toLowerCase());
  });

  test('OperatorManager WTON balance matches on-chain', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const provider = l1();
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);
    const rollupConfig = sysConfig();
    const operatorManager = await lm.operatorOfRollupConfig(rollupConfig);
    const wton = new ethers.Contract(addr.wton, WTON_ABI, provider);
    const bal = await wton.balanceOf(operatorManager);
    const formatted = parseFloat(ethers.formatUnits(bal, 27)).toFixed(4);

    const section = page.locator('section', { hasText: 'Operator Manager Information' });
    const text = (await section.textContent())!;
    expect(text).toContain(formatted);
  });

  test('systemConfigSigner matches unsafeBlockSigner()', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const provider = l1();
    const rollupConfig = sysConfig();
    const sc = new ethers.Contract(rollupConfig, SYSTEM_CONFIG_ABI, l1());
    const signerAddr = await sc.unsafeBlockSigner();

    const section = page.locator('section', { hasText: 'Operator Manager Information' });
    const text = (await section.textContent())!.toLowerCase();
    expect(text).toContain(signerAddr.toLowerCase());
  });
});

// ============================================================
// Seigniorage Issuance Factors
// ============================================================
test.describe('Seigniorage - Issuance Factors', () => {
  test('seigPerBlock matches on-chain', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, l1());
    const val = await seig.seigPerBlock();
    const formatted = parseFloat(ethers.formatUnits(val, 27)).toFixed(4);

    const section = page.locator('section', { hasText: 'Seigniorage Issuance Factors' });
    const text = (await section.textContent())!;
    expect(text).toContain(formatted);
  });

  test('distribution ratios match on-chain', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, l1());
    const [dao, minStaking, validator] = await Promise.all([
      seig.daoDistributionRatio(),
      seig.minStakingRatio(),
      seig.validatorDistributionRatio(),
    ]);

    const daoPercent = (Number(dao) / 1e27 * 100).toFixed(2);
    const minPercent = (Number(minStaking) / 1e27 * 100).toFixed(2);
    const valPercent = (Number(validator) / 1e27 * 100).toFixed(2);

    const section = page.locator('section', { hasText: 'Seigniorage Issuance Factors' });
    const text = (await section.textContent())!;

    expect(text).toContain(daoPercent + '%');
    expect(text).toContain(minPercent + '%');
    expect(text).toContain(valPercent + '%');
  });

  test('halfSaturationPoint matches on-chain', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, l1());
    const val = await seig.halfSaturationPoint();
    const formatted = parseFloat(ethers.formatEther(val)).toLocaleString();

    const section = page.locator('section', { hasText: 'Seigniorage Issuance Factors' });
    const text = (await section.textContent())!;
    expect(text).toContain(formatted);
  });

  test('bridgedTon and effectiveBridgedTon match on-chain', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const provider = l1();
    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, provider);
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);

    const [bridged, effective, totalEffective] = await Promise.all([
      lm.getBridgedTonByLayer(candidateAddOn),
      seig.getEffectiveBridgedTon(candidateAddOn),
      seig.totalEffectiveBridgedTON(),
    ]);

    const section = page.locator('section', { hasText: 'Seigniorage Issuance Factors' });
    const text = (await section.textContent())!;

    expect(text).toContain(parseFloat(ethers.formatEther(bridged)).toFixed(4));
    expect(text).toContain(parseFloat(ethers.formatEther(effective)).toFixed(4));
    expect(text).toContain(parseFloat(ethers.formatEther(totalEffective)).toFixed(4));
  });
});

// ============================================================
// Seigniorage Update History
// ============================================================
test.describe('Seigniorage - Update History', () => {
  test('lastSeigBlock and paused status match on-chain', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, l1());
    const [lastBlock, isPaused] = await Promise.all([
      seig.lastSeigBlock(),
      seig.paused(),
    ]);

    const section = page.locator('section', { hasText: 'Seigniorage Update History' });
    const text = (await section.textContent())!;

    expect(text).toContain(lastBlock.toString());
    if (isPaused) expect(text).toContain('Cannot Update');
    else expect(text).toContain('Can Update');
  });

  test('blocks since last update is correct', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const provider = l1();
    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, provider);
    const lastBlock = await seig.lastSeigBlock();
    const currentBlock = await provider.getBlockNumber();
    const diff = currentBlock - Number(lastBlock);

    const section = page.locator('section', { hasText: 'Seigniorage Update History' });
    const text = (await section.textContent())!;
    // Allow +-10 blocks tolerance for timing (parallel test execution causes block advancement)
    const displayedDiff = parseInt(text.match(/(\d+) blocks/)?.[1] || '0');
    expect(Math.abs(displayedDiff - diff)).toBeLessThan(10);
  });
});

// ============================================================
// Reward Per Unit Tracking
// ============================================================
test.describe('Seigniorage - Reward Per Unit', () => {
  test('bridgedTONRewardPerUint and validatorRewardPerUint match on-chain', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, l1());
    const [bridgedRpu, validatorRpu] = await Promise.all([
      seig.bridgedTONRewardPerUint(),
      seig.validatorRewardPerUint(),
    ]);

    const bridgedFormatted = parseFloat(ethers.formatUnits(bridgedRpu, 27)).toFixed(9);
    const validatorFormatted = parseFloat(ethers.formatUnits(validatorRpu, 27)).toFixed(9);

    const section = page.locator('section', { hasText: 'Reward Per Unit Tracking' });
    const text = (await section.textContent())!;
    expect(text).toContain(bridgedFormatted);
    expect(text).toContain(validatorFormatted);
  });
});

// ============================================================
// Bridged TON & Required Stake
// ============================================================
test.describe('Seigniorage - Bridged TON & Stake', () => {
  test('required/current stake and eligibility match checkCurrentEligibility()', async ({ page }) => {
    let candidateAddOn: string;
    try { candidateAddOn = await getCandidateAddOn(); } catch { test.skip(); return; }

    await goSeigniorageAndQuery(page, candidateAddOn);

    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, l1());

    let isEligible = false;
    let required = 0n;
    let current = 0n;
    try {
      const result = await seig.checkCurrentEligibility(candidateAddOn);
      isEligible = result[0];
      required = result[1];
      current = result[2];
    } catch {
      // may not be available
    }

    const section = page.locator('section', { hasText: 'Eligibility Checklist' });
    const text = (await section.textContent())!;

    if (isEligible) expect(text).toContain('ELIGIBLE');
    else expect(text).toContain('NOT ELIGIBLE');

    // UI displays with 2 decimal places
    expect(text).toContain(parseFloat(ethers.formatUnits(required, 27)).toFixed(2));
    expect(text).toContain(parseFloat(ethers.formatUnits(current, 27)).toFixed(2));
  });
});
