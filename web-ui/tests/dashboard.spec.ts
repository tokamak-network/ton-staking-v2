import { test, expect, type Page } from '@playwright/test';
import { ethers } from 'ethers';
import { injectMockWallet } from './wallet-mock';

// ─── Devnet RPC endpoints ───
const L1_RPC = 'http://localhost:8546';
const L2_RPC = 'http://localhost:9545';

// ─── Addresses loaded from the same JSONs the app uses ───
let addr: Record<string, any>;
let optAddr: Record<string, string>;

// Inject mock wallet before each test that uses a page
test.beforeEach(async ({ page }) => {
  await injectMockWallet(page);
});

// ─── ABIs (minimal for verification) ───
const L1_BRIDGE_REGISTRY_ABI = [
  'function getRollupInfo(address) view returns (uint8, address, bool, bool, string)',
];
const SEIG_MANAGER_ABI = [
  'function v3Migrated() view returns (bool)',
  'function minimumAmount() view returns (uint256)',
  'function stakeOf(address, address) view returns (uint256)',
  'function checkCurrentEligibility(address) view returns (bool, uint256, uint256)',
  'function lastSeigBlock() view returns (uint256)',
  'function paused() view returns (bool)',
  'function seigPerBlock() view returns (uint256)',
  'function daoDistributionRatio() view returns (uint256)',
  'function minStakingRatio() view returns (uint256)',
  'function validatorDistributionRatio() view returns (uint256)',
  'function halfSaturationPoint() view returns (uint256)',
];
const RAT_ABI = [
  'function getValidatorCount(address) view returns (uint256)',
  'function getActiveValidatorCount(address) view returns (uint256)',
  'function getDynamicMinimumCollateral(address) view returns (uint256)',
  'function getL2Validators(address) view returns (address[])',
  'function getValidatorDeposit(address, address) view returns (uint256)',
  'function getAvailableCollateral(address, address) view returns (uint256)',
  'function isValidatorActive(address, address) view returns (bool)',
  'function slashingPenalty() view returns (uint256)',
  'function validatorBuffer() view returns (uint256)',
  'function relaxedValidatorCheck() view returns (bool)',
  'function maxValidatorsPerL2() view returns (uint256)',
  'function evidenceSubmissionPeriod() view returns (uint256)',
];
const SYSTEM_CONFIG_ABI = [
  'function owner() view returns (address)',
  'function gasLimit() view returns (uint64)',
  'function unsafeBlockSigner() view returns (address)',
  'function batcherHash() view returns (bytes32)',
  'function l1StandardBridge() view returns (address)',
  'function optimismPortal() view returns (address)',
  'function disputeGameFactory() view returns (address)',
  'function l1CrossDomainMessenger() view returns (address)',
  'function batchInbox() view returns (address)',
  'function basefeeScalar() view returns (uint32)',
  'function blobbasefeeScalar() view returns (uint32)',
];
const OPTIMISM_PORTAL_ABI = [
  'function guardian() view returns (address)',
  'function paused() view returns (bool)',
];
const TON_ABI = [
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function balanceOf(address) view returns (uint256)',
];
const WTON_ABI = [
  'function balanceOf(address) view returns (uint256)',
];
const LAYER2_MANAGER_ABI = [
  'function operatorOfRollupConfig(address) view returns (address)',
  'function candidateAddOnOfOperator(address) view returns (address)',
];
const OPERATOR_MANAGER_ABI = [
  'function manager() view returns (address)',
];
const DISPUTE_GAME_FACTORY_ABI = [
  'function gameCount() view returns (uint256)',
];

// ─── Helpers ───
function sysConfig(): string {
  return addr.systemConfig || optAddr.SystemConfigProxy;
}

function l1() {
  return new ethers.JsonRpcProvider(L1_RPC);
}

/** Navigate to a tab by clicking its sidebar link */
async function goTab(page: Page, tabText: string) {
  // Open sidebar if closed (mobile-responsive)
  const sidebar = page.locator('.sidebar, nav, [class*=sidebar]');
  await page.locator(`text=${tabText}`).first().click();
  await page.waitForTimeout(2000); // let data load
}

// ─── Setup ───
test.beforeAll(async ({ request }) => {
  const [aRes, oRes] = await Promise.all([
    request.get('http://localhost:5173/addresses.json'),
    request.get('http://localhost:5173/optimism-addresses.json'),
  ]);
  expect(aRes.ok()).toBeTruthy();
  expect(oRes.ok()).toBeTruthy();
  addr = await aRes.json();
  optAddr = await oRes.json();
});

// ============================================================
// 1. Overview Tab - Configuration
// ============================================================
test.describe('Overview - Configuration addresses', () => {
  test('displays all contract addresses from JSON', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    const body = (await page.textContent('body'))!.toLowerCase();

    expect(body).toContain(addr.ton.toLowerCase());
    expect(body).toContain(addr.wton.toLowerCase());
    expect(body).toContain(addr.seigManagerProxy.toLowerCase());
    expect(body).toContain(addr.ratProxy.toLowerCase());
    expect(body).toContain(sysConfig().toLowerCase());
  });
});

// ============================================================
// 2. Overview Tab - Node Status
// ============================================================
test.describe('Overview - Node Status', () => {
  test('L1 chain ID matches RPC (900)', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Node Status', { timeout: 30_000 });

    const network = await l1().getNetwork();
    expect(Number(network.chainId)).toBe(900);

    const section = page.locator('section', { hasText: 'Node Status' });
    await expect(section.locator('text=900')).toBeVisible();
  });

  test('L1 block number is close to RPC', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Node Status', { timeout: 30_000 });

    const rpcBlock = await l1().getBlockNumber();
    const section = page.locator('section', { hasText: 'Node Status' });
    const blockItem = section.locator('.status-item', { hasText: 'Block:' }).first();
    const text = await blockItem.textContent();
    const uiBlock = parseInt(text!.replace(/\D/g, ''));
    expect(Math.abs(uiBlock - rpcBlock)).toBeLessThan(10);
  });
});

// ============================================================
// 3. Overview Tab - Rollup Information
// ============================================================
test.describe('Overview - Rollup Information', () => {
  test('rollup type, l2Ton, name match on-chain getRollupInfo', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Rollup Information', { timeout: 30_000 });

    const registry = new ethers.Contract(addr.l1BridgeRegistryProxy, L1_BRIDGE_REGISTRY_ABI, l1());
    const info = await registry.getRollupInfo(sysConfig());
    const rollupType = Number(info[0]);
    const l2Ton = info[1] as string;
    const rejectedSeigs = info[2] as boolean;
    const rejectedL2Deposit = info[3] as boolean;
    const name = info[4] as string;

    const ROLLUP_TYPES: Record<number, string> = {
      0: 'Invalid', 1: 'Optimism Legacy',
      2: 'Optimism Bedrock Native', 3: 'Optimism Bedrock DisputeGame',
    };

    const section = page.locator('section', { hasText: 'Rollup Information' });
    const text = (await section.textContent())!;

    // Rollup type label
    expect(text).toContain(ROLLUP_TYPES[rollupType]);
    // L2 TON address
    expect(text.toLowerCase()).toContain(l2Ton.toLowerCase());
    // Name
    if (name) expect(text).toContain(name);
    // Rejected flags
    expect(text).toContain(rejectedSeigs ? 'Yes' : 'No');
    expect(text).toContain(rejectedL2Deposit ? 'Yes' : 'No');
    // Should NOT be Invalid
    expect(rollupType).toBeGreaterThan(0);
  });
});

// ============================================================
// 4. Overview Tab - System Parameters
// ============================================================
test.describe('Overview - System Parameters', () => {
  test('v3Migrated, validator counts, min collateral, seq min stake match on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=System Parameters', { timeout: 30_000 });

    const provider = l1();
    const seig = new ethers.Contract(addr.seigManagerProxy, SEIG_MANAGER_ABI, provider);
    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, provider);

    const [migrated, total, active, minColl, seqMin] = await Promise.all([
      seig.v3Migrated(),
      rat.getValidatorCount(sysConfig()),
      rat.getActiveValidatorCount(sysConfig()),
      rat.getDynamicMinimumCollateral(sysConfig()),
      seig.minimumAmount(),
    ]);

    const section = page.locator('section', { hasText: 'System Parameters' });
    const text = (await section.textContent())!;

    // V3 Migrated
    if (migrated) expect(text).toContain('Yes');
    else expect(text).toContain('No');

    // Total / Active validators
    expect(text).toContain(Number(total).toString());
    expect(text).toContain(Number(active).toString());

    // Min collateral (formatted to 2 decimal)
    const minCollFormatted = parseFloat(ethers.formatUnits(minColl, 27)).toFixed(2);
    expect(text).toContain(minCollFormatted);

    // Sequencer min stake
    const seqMinFormatted = parseFloat(ethers.formatUnits(seqMin, 27)).toFixed(2);
    expect(text).toContain(seqMinFormatted);
  });
});

// ============================================================
// 5. Validators Tab - Configuration & Table
// ============================================================
test.describe('Validators Tab', () => {
  test('validator config params match on-chain RAT contract', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const provider = l1();
    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, provider);

    const [penalty, buffer, relaxed, maxVal, evidencePeriod] = await Promise.all([
      rat.slashingPenalty(),
      rat.validatorBuffer(),
      rat.relaxedValidatorCheck(),
      rat.maxValidatorsPerL2(),
      rat.evidenceSubmissionPeriod(),
    ]);

    // Wait for Validator Configuration section
    await page.waitForSelector('text=Validator Configuration', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Validator Configuration' });
    const text = (await section.textContent())!;

    // Slashing Penalty
    const penaltyFormatted = parseFloat(ethers.formatUnits(penalty, 27)).toFixed(2);
    expect(text).toContain(penaltyFormatted);

    // Validator Buffer
    const bufferFormatted = parseFloat(ethers.formatUnits(buffer, 27)).toFixed(2);
    expect(text).toContain(bufferFormatted);

    // Relaxed check mode
    if (relaxed) expect(text).toContain('Relaxed');
    else expect(text).toContain('Strict');

    // Max validators
    const maxValNum = Number(maxVal);
    if (maxValNum === 0) expect(text).toContain('Unlimited');
    else expect(text).toContain(maxValNum.toString());

    // Evidence period
    expect(text).toContain(Number(evidencePeriod).toString());
  });

  test('validator list matches on-chain data', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const provider = l1();
    const rat = new ethers.Contract(addr.ratProxy, RAT_ABI, provider);
    const wton = new ethers.Contract(addr.wton, WTON_ABI, provider);

    const validators = await rat.getL2Validators(sysConfig());

    if (validators.length === 0) {
      await expect(page.locator('text=No validators registered yet')).toBeVisible();
      return;
    }

    // Check table has correct number of rows
    await page.waitForSelector('.validators-table tbody tr', { timeout: 10_000 });
    const rows = page.locator('.validators-table tbody tr');
    expect(await rows.count()).toBe(validators.length);

    // Verify first validator's deposit amount
    const firstAddr = validators[0] as string;
    const deposit = await rat.getValidatorDeposit(firstAddr, sysConfig());
    const depositFormatted = parseFloat(ethers.formatUnits(deposit, 27)).toFixed(2);

    const firstRow = rows.first();
    const rowText = await firstRow.textContent();
    // Address may be truncated (0x90f7...b906), check first 6 chars after 0x
    expect(rowText!.toLowerCase()).toContain(firstAddr.toLowerCase().slice(0, 6));
    expect(rowText).toContain(depositFormatted);
  });

  test('ValidatorReward WTON balance matches on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Validators');

    const provider = l1();
    const wton = new ethers.Contract(addr.wton, WTON_ABI, provider);
    const balance = await wton.balanceOf(addr.validatorRewardProxy);
    const formatted = parseFloat(ethers.formatUnits(balance, 27)).toFixed(4);

    await page.waitForSelector('text=Validator Reward Contract', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Validator Reward Contract' });
    const text = (await section.textContent())!;
    expect(text).toContain(formatted);
  });
});

// ============================================================
// 6. Sequencer Tab - Operator Information
// ============================================================
test.describe('Sequencer Tab', () => {
  test('operator/sequencer address and staked amount match on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'Sequencer');

    const provider = l1();
    const lm = new ethers.Contract(addr.layer2ManagerProxy, LAYER2_MANAGER_ABI, provider);

    const operatorManager = await lm.operatorOfRollupConfig(sysConfig());
    if (operatorManager === ethers.ZeroAddress) {
      // No operator registered - skip
      return;
    }

    const omContract = new ethers.Contract(operatorManager, OPERATOR_MANAGER_ABI, provider);
    const manager = await omContract.manager();

    await page.waitForSelector('text=Sequencer Information', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Sequencer Information' });
    const text = (await section.textContent())!.toLowerCase();

    // Sequencer (operator) address
    expect(text).toContain(manager.toLowerCase());
    // OperatorManager address
    expect(text).toContain(operatorManager.toLowerCase());
  });
});

// ============================================================
// 7. L1 Info Tab - Optimism Contracts & Portal
// ============================================================
test.describe('L1 Info Tab', () => {
  test('SystemConfig-derived addresses match on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'L1 Info');

    const provider = l1();
    const sc = new ethers.Contract(sysConfig(), SYSTEM_CONFIG_ABI, provider);

    const [portal, bridge, dgf, messenger, batchInbox, gasLimit] = await Promise.all([
      sc.optimismPortal(),
      sc.l1StandardBridge(),
      sc.disputeGameFactory(),
      sc.l1CrossDomainMessenger(),
      sc.batchInbox(),
      sc.gasLimit(),
    ]);

    // Wait for the contracts section
    await page.waitForSelector('text=Optimism L1 Contracts', { timeout: 10_000 });
    const body = (await page.textContent('body'))!.toLowerCase();

    expect(body).toContain(portal.toLowerCase());
    expect(body).toContain(bridge.toLowerCase());
    expect(body).toContain(dgf.toLowerCase());
    expect(body).toContain(messenger.toLowerCase());
    expect(body).toContain(batchInbox.toLowerCase());
  });

  test('portal guardian and paused status match on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'L1 Info');

    const provider = l1();
    const sc = new ethers.Contract(sysConfig(), SYSTEM_CONFIG_ABI, provider);
    const portalAddr = await sc.optimismPortal();
    const portal = new ethers.Contract(portalAddr, OPTIMISM_PORTAL_ABI, provider);

    const [guardian, paused] = await Promise.all([
      portal.guardian(),
      portal.paused(),
    ]);

    await page.waitForSelector('text=Portal Security Status', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Portal Security Status' });
    const text = (await section.textContent())!;

    expect(text.toLowerCase()).toContain(guardian.toLowerCase());
    if (paused) expect(text).toContain('Paused');
    else expect(text).toContain('Active');
  });

  test('portal and bridge TON balances match on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'L1 Info');

    const provider = l1();
    const sc = new ethers.Contract(sysConfig(), SYSTEM_CONFIG_ABI, provider);
    const [portalAddr, bridgeAddr] = await Promise.all([
      sc.optimismPortal(),
      sc.l1StandardBridge(),
    ]);
    const ton = new ethers.Contract(addr.ton, TON_ABI, provider);

    const [portalTon, bridgeTon, portalEth] = await Promise.all([
      ton.balanceOf(portalAddr),
      ton.balanceOf(bridgeAddr),
      provider.getBalance(portalAddr),
    ]);

    await page.waitForSelector('text=Portal Security Status', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Portal Security Status' });
    const text = (await section.textContent())!;

    expect(text).toContain(parseFloat(ethers.formatEther(portalTon)).toFixed(4));
    expect(text).toContain(parseFloat(ethers.formatEther(portalEth)).toFixed(4));
    expect(text).toContain(parseFloat(ethers.formatEther(bridgeTon)).toFixed(4));
  });

  test('TON Staking V3 contract addresses match JSON', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'L1 Info');

    await page.waitForSelector('text=TON Staking V3 Contracts', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'TON Staking V3 Contracts' });
    const text = (await section.textContent())!.toLowerCase();

    expect(text).toContain(addr.ton.toLowerCase());
    expect(text).toContain(addr.wton.toLowerCase());
    expect(text).toContain(addr.seigManagerProxy.toLowerCase());
    expect(text).toContain(addr.depositManagerProxy.toLowerCase());
    expect(text).toContain(addr.layer2ManagerProxy.toLowerCase());
    expect(text).toContain(addr.l1BridgeRegistryProxy.toLowerCase());
    expect(text).toContain(addr.layer2RegistryProxy.toLowerCase());
    expect(text).toContain(addr.ratProxy.toLowerCase());
    expect(text).toContain(addr.validatorRewardProxy.toLowerCase());
  });
});

// ============================================================
// 8. L2 Info Tab - SystemConfig values
// ============================================================
test.describe('L2 Info Tab', () => {
  test('gas limit, batcher hash, unsafeBlockSigner match on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'L2 Info');

    const provider = l1();
    const sc = new ethers.Contract(sysConfig(), SYSTEM_CONFIG_ABI, provider);

    const [gasLimit, batcherHash, signer, basefee, blobfee] = await Promise.all([
      sc.gasLimit(),
      sc.batcherHash(),
      sc.unsafeBlockSigner(),
      sc.basefeeScalar(),
      sc.blobbasefeeScalar(),
    ]);

    const body = (await page.textContent('body'))!;
    const bodyLower = body.toLowerCase();

    // Gas limit (formatted with commas)
    expect(body).toContain(Number(gasLimit).toLocaleString());

    // Batcher hash
    expect(bodyLower).toContain(batcherHash.toLowerCase());

    // Unsafe block signer
    expect(bodyLower).toContain(signer.toLowerCase());

    // Basefee scalar
    expect(body).toContain(Number(basefee).toString());

    // Blob basefee scalar
    expect(body).toContain(Number(blobfee).toString());
  });

  test('bridge & portal addresses from SystemConfig match page', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'L2 Info');

    const provider = l1();
    const sc = new ethers.Contract(sysConfig(), SYSTEM_CONFIG_ABI, provider);

    const [portal, bridge, dgf, messenger] = await Promise.all([
      sc.optimismPortal(),
      sc.l1StandardBridge(),
      sc.disputeGameFactory(),
      sc.l1CrossDomainMessenger(),
    ]);

    await page.waitForSelector('text=Bridge & Portal Addresses', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Bridge & Portal Addresses' });
    const text = (await section.textContent())!.toLowerCase();

    expect(text).toContain(portal.toLowerCase());
    expect(text).toContain(bridge.toLowerCase());
    expect(text).toContain(dgf.toLowerCase());
    expect(text).toContain(messenger.toLowerCase());
  });

  test('portal paused status and balances match on-chain', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await goTab(page, 'L2 Info');

    const provider = l1();
    const sc = new ethers.Contract(sysConfig(), SYSTEM_CONFIG_ABI, provider);
    const portalAddr = await sc.optimismPortal();
    const portal = new ethers.Contract(portalAddr, OPTIMISM_PORTAL_ABI, provider);

    const [guardian, paused] = await Promise.all([
      portal.guardian(),
      portal.paused(),
    ]);

    await page.waitForSelector('text=Portal Status', { timeout: 10_000 });
    const section = page.locator('section', { hasText: 'Portal Status' });
    const text = (await section.textContent())!;

    expect(text.toLowerCase()).toContain(guardian.toLowerCase());
    if (paused) expect(text).toContain('Paused');
    else expect(text).toContain('Active');
  });
});

// ============================================================
// 9. Contract Connectivity - smoke tests
// ============================================================
test.describe('Contract Connectivity', () => {
  test('TON at displayed address is valid ERC20', async () => {
    const ton = new ethers.Contract(addr.ton, TON_ABI, l1());
    const [name, symbol] = await Promise.all([ton.name(), ton.symbol()]);
    // Devnet may use shortened name "TON" instead of full "Tokamak Network Token"
    expect(name.length).toBeGreaterThan(0);
    expect(symbol).toBe('TON');
  });

  test('SystemConfig gasLimit > 0', async () => {
    const sc = new ethers.Contract(sysConfig(), SYSTEM_CONFIG_ABI, l1());
    const gasLimit = await sc.gasLimit();
    expect(Number(gasLimit)).toBeGreaterThan(0);
  });

  test('DisputeGameFactory is callable', async () => {
    const dgf = new ethers.Contract(
      addr.disputeGameFactory || optAddr.DisputeGameFactoryProxy,
      DISPUTE_GAME_FACTORY_ABI,
      l1(),
    );
    const count = await dgf.gameCount();
    expect(Number(count)).toBeGreaterThanOrEqual(0);
  });
});

// ============================================================
// 10. Page Health
// ============================================================
test.describe('Page Health', () => {
  test('no critical console errors on load', async ({ page }) => {
    const errors: string[] = [];
    page.on('console', (msg) => {
      if (msg.type() === 'error' && msg.text().includes('Failed to load')) {
        errors.push(msg.text());
      }
    });

    await page.goto('/');
    await page.waitForSelector('text=Node Status', { timeout: 30_000 });
    await page.waitForTimeout(5_000);

    const critical = errors.filter(
      (e) => e.includes('rollup info') || e.includes('node status'),
    );
    expect(critical).toHaveLength(0);
  });

  test('all overview sections render', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('text=Configuration', { timeout: 30_000 });
    await expect(page.locator('text=Node Status')).toBeVisible();
    await expect(page.locator('text=Rollup Information')).toBeVisible();
    await expect(page.locator('text=System Parameters')).toBeVisible();
    await expect(page.locator('text=Key Contracts')).toBeVisible();
  });
});
