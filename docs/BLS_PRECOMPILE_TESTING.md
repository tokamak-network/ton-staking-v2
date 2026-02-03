# EIP-2537 BLS Precompile Testing Guide

## Overview

EIP-2537 BLS12-381 precompiles are now available on Ethereum mainnet after the Pectra upgrade (deployed May 7, 2025).

However, **Foundry's local EVM does not yet implement EIP-2537 precompiles**, so fork tests will skip precompile-dependent tests gracefully.

## Testing Approaches

### 1. Local Fork Tests (Limited)

Fork tests will detect that precompiles are not available and skip tests gracefully:

```bash
forge test --match-contract BLS12381MainnetForkTest -vv
```

**Expected Output:**
```
NOTE: EIP-2537 precompiles NOT available in Foundry's local EVM
These tests will be skipped. Deploy to actual Sepolia for full testing.
```

### 2. Direct Network Testing (Recommended)

To test BLS precompiles on actual Ethereum mainnet:

#### Using Cast (Quick Check)

```bash
# Test BLS12_G1ADD precompile (address 0x0b) on mainnet
cast call 0x000000000000000000000000000000000000000b \
  "0x$(printf '0%.0s' {1..512})" \
  --rpc-url https://ethereum-rpc.publicnode.com
```

If precompiles are available, you'll get a 128-byte response (all zeros for identity input).

#### Using Forge Script (Comprehensive)

```bash
# Run BLS precompile tests on Ethereum mainnet
forge script script/TestBLSOnMainnet.s.sol \
  --rpc-url https://ethereum-rpc.publicnode.com \
  -vvv
```

**Note:** This runs read-only tests, no transactions are broadcast. Uses public RPC endpoint.

## Precompile Addresses (EIP-2537)

| Precompile | Address | Function |
|------------|---------|----------|
| BLS12_G1ADD | 0x0b | Add two G1 points |
| BLS12_G1MUL | 0x0c | Multiply G1 point by scalar |
| BLS12_G1MSM | 0x0d | G1 multi-scalar multiplication |
| BLS12_G2ADD | 0x0e | Add two G2 points |
| BLS12_G2MUL | 0x0f | Multiply G2 point by scalar |
| BLS12_G2MSM | 0x10 | G2 multi-scalar multiplication |
| BLS12_PAIRING | 0x11 | Pairing check |
| BLS12_MAP_FP_TO_G1 | 0x12 | Map field element to G1 |
| BLS12_MAP_FP2_TO_G2 | 0x13 | Map Fp2 element to G2 |

## Network Availability

### Ethereum Mainnet
- **Status:** ✅ Available (Production)
- **Deployed:** May 7, 2025 (Pectra upgrade)
- **RPC:** `https://ethereum-rpc.publicnode.com`
- **Recommended for:** Production testing, stability

### Sepolia Testnet
- **Status:** ✅ Available
- **Deployed:** March 5, 2025 (Pectra upgrade)
- **RPC:** `https://ethereum-sepolia-rpc.publicnode.com`
- **Recommended for:** Development, experimentation

### Foundry Local EVM
- **Status:** ❌ Not yet implemented
- **Workaround:** Fork mainnet or deploy to actual network for testing

## Troubleshooting

### Fork Tests Show "Precompiles Not Available"

This is **expected behavior**. Foundry's local EVM doesn't yet support EIP-2537. The tests are designed to skip gracefully.

**Solution:** Use actual network testing with forge script (see above).

### "PrecompileNotAvailable" Error

If you get this error on mainnet/testnet, check:

1. Network is post-Pectra (May 7, 2025+)
2. RPC endpoint is working correctly
3. Block number is recent (not an old historical block)

### Testing on Local Development Network

If you need local testing:

1. **Recommended:** Fork mainnet with Foundry (tests will skip gracefully)
2. Use Geth with EIP-2537 enabled for full local support
3. Deploy mocked precompiles for unit testing
4. Use actual mainnet/Sepolia for integration tests

## Example: Testing BLS Signature Verification

```solidity
// Hash message to G2
bytes32 messageHash = keccak256("TOKAMAK_FAST_WITHDRAWAL");
BLS12381.G2Point memory hashedMsg = BLS12381.hashToG2(messageHash);

// Aggregate validator public keys (G1 points)
BLS12381.G1Point memory aggregatedPubkey = BLS12381.aggregateG1Points(
    pubkeys, 
    validatorCount
);

// Aggregate signatures (G2 points)
BLS12381.G2Point memory aggregatedSig = BLS12381.aggregateG2Points(
    signatures, 
    signatureCount
);

// Verify aggregated signature
bool valid = BLS12381.verifyAggregatedSignature(
    aggregatedPubkey,
    aggregatedSig,
    messageHash
);
```

## Gas Costs (Approximate)

| Operation | Gas Cost |
|-----------|----------|
| G1 Add | ~500 gas |
| G2 Add | ~800 gas |
| G1 MSM (per point) | ~12,000 gas |
| G2 MSM (per point) | ~45,000 gas |
| Pairing (per pair) | ~43,000 gas |
| Map to G2 | ~75,000 gas |
| Hash to G2 (full) | ~150,000 gas |

## References

- [EIP-2537 Specification](https://eips.ethereum.org/EIPS/eip-2537)
- [BLS12-381 Curve](https://hackmd.io/@benjaminion/bls12-381)
- [Ethereum Pectra Upgrade](https://blog.ethereum.org/2025/05/07/pectra-mainnet-announcement)
- [RFC 9380: Hash to Curve](https://datatracker.ietf.org/doc/html/rfc9380)

## Support

For issues or questions:
- Check test logs for skip messages
- Verify network compatibility
- Use actual Sepolia for integration testing
- Consult EIP-2537 specification for expected behavior
