# Debug API 사용 가이드 (debug_accountRange)

## 개요

RAT client가 adjacent leaves를 찾기 위해 geth의 **`debug_accountRange`** RPC를 사용합니다.

## debug_accountRange란?

Ethereum/Optimism geth의 debug API 중 하나로, state trie의 account range를 조회합니다.

### RPC Spec

```
debug_accountRange(blockHash, startKey, maxResults, noCode, noStorage, incompletes)
```

**Parameters**:
- `blockHash`: Block hash (또는 "latest")
- `startKey`: 시작 key (bytes32, optional)
- `maxResults`: 최대 결과 수
- `noCode`: Code 제외 여부
- `noStorage`: Storage 제외 여부
- `incompletes`: Incomplete accounts 포함 여부

**Returns**:
```json
{
  "accounts": {
    "0x1000...": {
      "balance": "0x...",
      "nonce": 1,
      "root": "0x...",
      "codeHash": "0x..."
    },
    "0x1234...": {...},
    "0x1500...": {...}
  },
  "next": "0x2000..."  // 다음 범위의 시작 key
}
```

## RAT Client에서의 사용

### 1. Adjacent Leaves 검색 알고리즘

```go
// 1. Target (stateRoot) 조회
target := stateRoot  // 0x1234567890abcdef...

// 2. Target 이전의 leaves 조회
result1 := debug_accountRange(
    blockHash,
    startKey: nil,      // 처음부터
    maxResults: 1000,
    noCode: true,
    noStorage: true,
    incompletes: false,
)

// 3. Target보다 작은 key 중 가장 큰 것 찾기
var leafA *Account
for key, account := range result1.Accounts {
    if key < target && (leafA == nil || key > leafA.Key) {
        leafA = &Account{Key: key, Value: account}
    }
}

// 4. Target 이후의 leaves 조회
result2 := debug_accountRange(
    blockHash,
    startKey: target,   // Target부터 시작
    maxResults: 10,
    noCode: true,
    noStorage: true,
    incompletes: false,
)

// 5. Target보다 큰 key 중 가장 작은 것 찾기
var leafB *Account
for key, account := range result2.Accounts {
    if key > target {
        leafB = &Account{Key: key, Value: account}
        break  // 첫 번째가 가장 작음 (정렬되어 있음)
    }
}

// 6. Adjacent 확인
if leafA != nil && leafB != nil && leafA.Key < target && target < leafB.Key {
    // Found adjacent leaves!
}
```

### 2. 실제 Go 구현

```go
// clients/rat-client-type3/pkg/state/adjacent_finder.go

import (
    "context"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

type AdjacentFinder struct {
    client *ethclient.Client
}

type AccountRange struct {
    Accounts map[common.Hash]Account `json:"accounts"`
    Next     common.Hash              `json:"next"`
}

type Account struct {
    Balance  *big.Int    `json:"balance"`
    Nonce    uint64      `json:"nonce"`
    Root     common.Hash `json:"root"`
    CodeHash common.Hash `json:"codeHash"`
}

func (f *AdjacentFinder) FindAdjacentLeaves(
    ctx context.Context,
    blockHash common.Hash,
    target common.Hash,
) (*AdjacentLeaves, error) {

    // Query account range before target
    var result1 AccountRange
    err := f.client.Client().CallContext(
        ctx,
        &result1,
        "debug_accountRange",
        blockHash,
        nil,           // startKey = nil (from beginning)
        1000,          // maxResults
        true,          // noCode
        true,          // noStorage
        false,         // incompletes
    )
    if err != nil {
        return nil, fmt.Errorf("failed to query account range: %w", err)
    }

    // Find leafA (largest key < target)
    var leafA *common.Hash
    var leafAValue Account
    for key, account := range result1.Accounts {
        if key.Big().Cmp(target.Big()) < 0 {
            if leafA == nil || key.Big().Cmp(leafA.Big()) > 0 {
                keyCopy := key
                leafA = &keyCopy
                leafAValue = account
            }
        }
    }

    // Query account range after target
    var result2 AccountRange
    err = f.client.Client().CallContext(
        ctx,
        &result2,
        "debug_accountRange",
        blockHash,
        target,        // startKey = target
        10,            // maxResults (only need first one after target)
        true,          // noCode
        true,          // noStorage
        false,         // incompletes
    )
    if err != nil {
        return nil, fmt.Errorf("failed to query account range after target: %w", err)
    }

    // Find leafB (smallest key > target)
    var leafB *common.Hash
    var leafBValue Account
    for key, account := range result2.Accounts {
        if key.Big().Cmp(target.Big()) > 0 {
            leafB = &key
            leafBValue = account
            break  // First one is the smallest (results are sorted)
        }
    }

    if leafA == nil || leafB == nil {
        return nil, fmt.Errorf("could not find adjacent leaves")
    }

    // Generate Merkle proofs
    proofA, err := f.getProof(ctx, *leafA, blockHash)
    if err != nil {
        return nil, fmt.Errorf("failed to get proof for leafA: %w", err)
    }

    proofB, err := f.getProof(ctx, *leafB, blockHash)
    if err != nil {
        return nil, fmt.Errorf("failed to get proof for leafB: %w", err)
    }

    return &AdjacentLeaves{
        LeafAKey:   *leafA,
        LeafAValue: encodeAccount(leafAValue),
        LeafAProof: proofA,
        LeafBKey:   *leafB,
        LeafBValue: encodeAccount(leafBValue),
        LeafBProof: proofB,
    }, nil
}

func (f *AdjacentFinder) getProof(
    ctx context.Context,
    address common.Hash,
    blockHash common.Hash,
) ([][]byte, error) {
    // Use eth_getProof RPC
    var result struct {
        AccountProof []string `json:"accountProof"`
    }

    err := f.client.Client().CallContext(
        ctx,
        &result,
        "eth_getProof",
        common.BytesToAddress(address.Bytes()),
        []string{},  // storage keys (empty for account proof)
        blockHash.Hex(),
    )
    if err != nil {
        return nil, err
    }

    // Convert hex strings to bytes
    proofs := make([][]byte, len(result.AccountProof))
    for i, hexProof := range result.AccountProof {
        proofs[i] = common.FromHex(hexProof)
    }

    return proofs, nil
}

func encodeAccount(acc Account) []byte {
    // RLP encode account
    return rlp.Encode(&[]interface{}{
        acc.Nonce,
        acc.Balance,
        acc.Root,
        acc.CodeHash,
    })
}
```

## geth 설정

### E2E 테스트에서의 설정

```bash
geth --datadir /tmp/l2 \
  --http --http.port 9545 \
  --http.api "eth,web3,net,debug" \  # debug API 활성화!
  --dev --dev.period 2 \
  --gcmode archive \                 # 모든 state 보존
  --allow-insecure-unlock
```

**중요**:
- `--http.api "debug"`: debug_accountRange 사용 가능
- `--gcmode archive`: 모든 historical state 보존

### Production 설정

```bash
op-geth --datadir /data/l2 \
  --http --http.port 9545 \
  --http.api "eth,web3,net,debug" \  # debug API 활성화
  --gcmode archive \                 # Archive mode 필수!
  --syncmode full \
  --snapshot=false \                 # Snapshot 비활성화 (optional)
  --txlookuplimit=0                  # 모든 tx 인덱싱
```

## 테스트

### curl로 직접 테스트

```bash
# L2 geth 시작 후

# 1. Latest block hash 조회
BLOCK_HASH=$(cast block latest --rpc-url http://localhost:9545 -j | jq -r .hash)

# 2. debug_accountRange 호출
curl http://localhost:9545 \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"debug_accountRange\",
    \"params\":[
      \"$BLOCK_HASH\",
      null,
      100,
      true,
      true,
      false
    ],
    \"id\":1
  }" | jq .

# 예상 출력:
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "accounts": {
      "0x0000000000000000000000000000000000000001": {
        "balance": "0x56bc75e2d63100000",
        "nonce": 0,
        "root": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
        "codeHash": "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
      },
      "0x0000000000000000000000000000000000000002": {
        "balance": "0x56bc75e2d63100000",
        "nonce": 0,
        "root": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
        "codeHash": "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
      }
    },
    "next": "0x0000000000000000000000000000000000000003"
  }
}
```

### Go 테스트 코드

```go
func TestDebugAccountRange(t *testing.T) {
    client, err := ethclient.Dial("http://localhost:9545")
    require.NoError(t, err)

    // Get latest block
    block, err := client.BlockByNumber(context.Background(), nil)
    require.NoError(t, err)

    // Query account range
    var result struct {
        Accounts map[common.Hash]interface{} `json:"accounts"`
        Next     common.Hash                  `json:"next"`
    }

    err = client.Client().CallContext(
        context.Background(),
        &result,
        "debug_accountRange",
        block.Hash(),
        nil,    // startKey
        100,    // maxResults
        true,   // noCode
        true,   // noStorage
        false,  // incompletes
    )
    require.NoError(t, err)

    t.Logf("Found %d accounts", len(result.Accounts))
    for key := range result.Accounts {
        t.Logf("Account: %s", key.Hex())
    }
}
```

## 성능 고려사항

### 1. maxResults 설정

```go
// 너무 작음: 여러 번 호출 필요
maxResults := 10

// 너무 큼: 메모리 부담, 느림
maxResults := 100000

// 권장: 1000-5000
maxResults := 1000
```

### 2. Pagination

```go
func (f *AdjacentFinder) ScanStateTree(ctx context.Context, blockHash common.Hash) error {
    var startKey *common.Hash

    for {
        var result AccountRange
        err := f.client.Client().CallContext(
            ctx,
            &result,
            "debug_accountRange",
            blockHash,
            startKey,      // 이전 결과의 next
            1000,
            true,
            true,
            false,
        )
        if err != nil {
            return err
        }

        // Process accounts...
        for key, account := range result.Accounts {
            // ...
        }

        // Check if done
        if result.Next == (common.Hash{}) {
            break
        }

        // Continue from next
        startKey = &result.Next
    }

    return nil
}
```

### 3. Caching

```go
type StateCache struct {
    cache map[common.Hash]AccountRange
    mu    sync.RWMutex
}

func (c *StateCache) Get(blockHash common.Hash, startKey common.Hash) (*AccountRange, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()

    cacheKey := crypto.Keccak256Hash(blockHash.Bytes(), startKey.Bytes())
    result, ok := c.cache[cacheKey]
    return &result, ok
}
```

## 문제 해결

### debug API가 비활성화된 경우

```
Error: method debug_accountRange does not exist/is not available
```

**해결**:
```bash
geth --http.api "eth,web3,net,debug"  # debug 추가!
```

### Archive mode가 아닌 경우

```
Error: missing trie node
```

**해결**:
```bash
geth --gcmode archive  # Archive mode 활성화!
```

### 너무 많은 결과

```
Error: result set too large
```

**해결**:
```go
maxResults := 1000  # 줄이기
```

## E2E 테스트에서의 검증

```bash
# 1. E2E 환경 시작
./scripts/run-e2e-test-final.sh

# 2. 다른 터미널에서 debug_accountRange 테스트
BLOCK=$(cast block latest --rpc-url http://localhost:9545 -j | jq -r .hash)

curl http://localhost:9545 \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"debug_accountRange\",
    \"params\":[\"$BLOCK\", null, 100, true, true, false],
    \"id\":1
  }" | jq .result.accounts

# 3. RAT Client 실행 (자동으로 debug_accountRange 사용)
cd clients/rat-client-type3
./bin/rat-client --config config.test.yaml

# 로그에서 확인:
# INFO Found adjacent leaves via debug_accountRange  leafA=0x1000 leafB=0x1500 target=0x1234
```

## 결론

`debug_accountRange`는 RAT client가 adjacent leaves를 효율적으로 찾는 핵심 API입니다.

✅ **geth 설정**: `--http.api "debug"`, `--gcmode archive`
✅ **Go 구현**: `ethclient`의 `CallContext` 사용
✅ **성능**: Pagination, caching 고려
✅ **E2E 테스트**: 이미 활성화되어 있음

현재 E2E 스크립트는 이미 debug API를 활성화하고 있으므로 바로 사용 가능합니다! 🎉
