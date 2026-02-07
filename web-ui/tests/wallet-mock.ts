/**
 * Mock window.ethereum provider for Playwright tests.
 *
 * Injects a minimal EIP-1193 provider that auto-connects the test account
 * and proxies JSON-RPC calls to the local L1 devnet.
 */

import { type Page } from '@playwright/test';

const TESTER = '0x976EA74026E726554dB657fA54763abd0C3a0aa9';
const L1_RPC = 'http://localhost:8546';
const CHAIN_ID_HEX = '0x384'; // 900

/**
 * Call this before every `page.goto()` to inject the mock wallet.
 * The mock will make the app think MetaMask is connected.
 */
export async function injectMockWallet(page: Page) {
  await page.addInitScript(`
    (() => {
      const TESTER = '${TESTER}';
      const CHAIN_ID_HEX = '${CHAIN_ID_HEX}';
      const L1_RPC = '${L1_RPC}';

      const listeners = {};

      window.ethereum = {
        isMetaMask: true,
        chainId: CHAIN_ID_HEX,
        selectedAddress: TESTER,
        networkVersion: '900',

        on(event, cb) {
          if (!listeners[event]) listeners[event] = [];
          listeners[event].push(cb);
          return this;
        },

        removeListener(event, cb) {
          if (listeners[event]) {
            listeners[event] = listeners[event].filter(fn => fn !== cb);
          }
          return this;
        },

        removeAllListeners(event) {
          if (event) delete listeners[event];
          else Object.keys(listeners).forEach(k => delete listeners[k]);
          return this;
        },

        async request({ method, params }) {
          switch (method) {
            case 'eth_accounts':
            case 'eth_requestAccounts':
              return [TESTER];

            case 'eth_chainId':
              return CHAIN_ID_HEX;

            case 'net_version':
              return '900';

            case 'wallet_switchEthereumChain':
            case 'wallet_addEthereumChain':
              return null;

            default: {
              // Proxy all other calls to the local RPC
              const res = await fetch(L1_RPC, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  jsonrpc: '2.0',
                  id: Date.now(),
                  method,
                  params: params || [],
                }),
              });
              const json = await res.json();
              if (json.error) {
                const err = new Error(json.error.message || 'RPC error');
                err.code = json.error.code;
                err.data = json.error.data;
                throw err;
              }
              return json.result;
            }
          }
        },
      };
    })();
  `);
}
