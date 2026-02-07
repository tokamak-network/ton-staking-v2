import { test } from '@playwright/test';
import { injectMockWallet } from './wallet-mock';

test('screenshot', async ({ page }) => {
  await injectMockWallet(page);
  await page.goto('/', { waitUntil: 'networkidle' });
  await page.waitForTimeout(5000);
  await page.screenshot({ path: 'tests/debug-screenshot.png', fullPage: true });
  const text = await page.textContent('body');
  console.log('BODY TEXT (first 3000):', text?.substring(0, 3000));
});
