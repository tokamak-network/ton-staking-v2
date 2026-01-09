# TON Staking V3 RAT Clients

This directory contains RAT (Randomized Attention Test) client implementations for different rollup types.

## Overview

RAT clients are **type-specific** - each rollup type requires its own client implementation because:
- Different batch formats (e.g., Optimism Bedrock vs Arbitrum)
- Different state derivation logic
- Different proof formats
- Different contract interfaces

## Directory Structure

```
clients/
├── rat-client-type3/        # Type 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
│   ├── cmd/
│   ├── pkg/
│   ├── README.md
│   └── go.mod
├── rat-client-type4/        # Type 4: Future rollup type (TBD)
└── rat-client-type5/        # Type 5: Future rollup type (TBD)
```

## Rollup Types

From `src/layer2/L1BridgeRegistryV1_2.sol`:

```solidity
enum TYPE_ROLLUPCONFIG {
    NONE,                                    // 0 - Not registered
    LEGARCY,                                 // 1 - TOKAMAK (Legacy) - No RAT
    OPTIMISM_BEDROCK,                        // 2 - Optimism Bedrock - No RAT
    OPTIMISM_BEDROCK_WITH_DISPUTE_GAME       // 3 - Optimism Bedrock + DisputeGame + RAT
}
```

- **Type 1, 2**: Do not use RAT
- **Type 3**: Uses RAT (current implementation)
- **Type 4+**: Future types with RAT support

## Quick Start

### Build RAT Client Type 3

```bash
# From project root
make rat-client-build

# Or directly
cd clients/rat-client-type3
go build -o bin/rat-client-type3 ./cmd
```

### Configure

```bash
cd clients/rat-client-type3
cp config.example.yaml config.yaml
# Edit config.yaml with your settings
```

### Run

```bash
# From project root
make rat-client-run

# Or with CLI flags
./clients/rat-client-type3/bin/rat-client-type3 \
  --l1-rpc https://mainnet.infura.io/v3/YOUR_KEY \
  --l2-rpc https://optimism-mainnet.infura.io/v3/YOUR_KEY \
  --private-key 0x... \
  --rat-contract 0x... \
  --system-config 0x... \
  --batch-inbox 0xff03000000000000000000000000000000000000 \
  --batcher-address 0x... \
  --dispute-game-factory 0x... \
  --l1-bridge-registry 0x...
```

## Architecture

Each RAT client follows the same general architecture but with type-specific implementations:

```
1. Monitor L1 for AttentionTestTriggered events
   ↓
2. Fetch L1 batch data (type-specific format)
   ↓
3. Decode batches (type-specific decoding)
   ↓
4. Execute batches to derive L2 state (type-specific EVM)
   ↓
5. Compute output root (type-specific format)
   ↓
6. Generate Merkle proof evidence (type-specific proofs)
   ↓
7. Submit to RAT contract (type-specific Evidence struct)
```

## Development

### Adding a New Rollup Type

To add support for a new rollup type (e.g., Type 4):

1. **Create new directory**:
   ```bash
   mkdir clients/rat-client-type4
   ```

2. **Implement type-specific components**:
   - Batch fetcher (fetch from L1 DA)
   - Batch decoder (decode type-specific format)
   - State executor (execute with type-specific rules)
   - Evidence generator (generate type-specific proofs)

3. **Add Solidity verifier**:
   ```solidity
   // src/validator/libraries/Type4EvidenceVerifier.sol
   library Type4EvidenceVerifier {
       struct Evidence { /* type-specific */ }
       function verify(...) internal pure returns (bool) { /* type-specific */ }
   }
   ```

4. **Update RAT.sol**:
   ```solidity
   if (rollupType == 4) {
       return Type4EvidenceVerifier.verify(batchHash, evidenceData);
   }
   ```

5. **Add Makefile targets**:
   ```makefile
   RAT_CLIENT_TYPE4_DIR := clients/rat-client-type4
   rat-client-type4-build:
       cd $(RAT_CLIENT_TYPE4_DIR) && go build ...
   ```

## Testing

### Unit Tests

```bash
# Test RAT client Type 3
make rat-client-test

# Or directly
cd clients/rat-client-type3
go test ./pkg/...
```

### Integration Tests

```bash
# Run E2E tests with RAT client
make devnet-allocs-offline
make test-e2e
```

## Documentation

- [RAT Client Type 3 README](./rat-client-type3/README.md)
- [RAT Implementation Plan](../docs/rat-client-implementation-plan.md)
- [RAT Contract Documentation](../docs/deployment/contracts.md)
- [E2E Tests](../docs/test/e2e-tests.md)

## Security

All RAT clients implement **trustless verification**:
- ✅ Derive L2 state from L1 batch data
- ✅ Do NOT trust L2 node for state roots
- ✅ Generate Merkle proofs for on-chain verification
- ✅ Verify all data against L1

See [Trustless Verification Flow](./rat-client-type3/README.md#trustless-verification-flow) for details.

## License

MIT
