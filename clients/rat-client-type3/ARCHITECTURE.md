# RAT Client vs Optimism Challenger Architecture

## 핵심 질문: "L2 노드가 문제면 Challenger도 어떻게 판단하나?"

### Optimism의 답: op-program + Cannon/Asterisc

Optimism은 **L2 RPC에 의존하지 않는 완전 trustless challenger**를 구현했습니다:

```
┌─────────────────────────────────────────────────────┐
│ Optimism Challenger Architecture                   │
├─────────────────────────────────────────────────────┤
│                                                     │
│ 1. op-program (Fault Proof Program)                │
│    ├─ L1 데이터만 사용 (NO L2 RPC!)                 │
│    ├─ Preimage Oracle 패턴                         │
│    ├─ L1에서 배치 가져오기                          │
│    ├─ 배치 실행 (EVM)                              │
│    └─ State root 계산                              │
│                                                     │
│ 2. op-program-host                                 │
│    ├─ L1 RPC 연결                                  │
│    ├─ Beacon chain API (blobs)                    │
│    ├─ L2 RPC 연결 (선택적, pre-fetching 최적화)     │
│    ├─ Preimage 제공                                │
│    └─ KV store 캐싱                                │
│                                                     │
│ 3. Cannon/Asterisc (MIPS Emulator)                │
│    ├─ op-program을 MIPS로 컴파일                   │
│    ├─ Instruction-by-instruction execution        │
│    ├─ Deterministic state tracking                │
│    └─ On-chain verification (single step proof)   │
│                                                     │
│ 4. op-challenger                                   │
│    ├─ Dispute game 모니터링                        │
│    ├─ Interactive bisection                        │
│    ├─ Cannon으로 trace 생성                        │
│    └─ On-chain move 제출                           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### L2 RPC의 역할 (Optimism)

**중요**: L2 RPC는 **선택적 최적화**일 뿐입니다!

```go
// op-program/host/host.go

// L2 sources - OPTIONAL for pre-fetching
sources, err := prefetcher.NewRetryingL2SourcesFromURLs(
    ctx, logger, cfg.Rollups, cfg.L2URLs, cfg.L2ExperimentalURLs
)

// L2 RPC 없이도 작동 가능!
// L1 데이터만으로 모든 것을 derive
```

**L2 RPC가 하는 일**:
1. Pre-fetching 최적화 (빠른 execution)
2. State hint 제공 (어떤 데이터가 필요한지)
3. **검증 없음! (모든 데이터는 L1에서 검증)**

**L2 RPC가 없어도**:
1. op-program은 여전히 작동
2. L1 데이터만으로 state derive
3. 느릴 뿐, trustless는 유지

### Preimage Oracle 패턴

```
┌─────────────────┐         ┌─────────────────┐
│  op-program     │  Hint   │  op-program-    │
│  (Client)       │────────>│  host           │
│                 │         │                 │
│  "블록 #100의    │         │  L1 RPC에서     │
│   state root가  │         │  데이터 가져오기 │
│   필요해"        │         │                 │
│                 │<────────│  Preimage 제공   │
│                 │ Data    │                 │
└─────────────────┘         └─────────────────┘

Client는 무엇이 필요한지만 알려줌
Host가 데이터를 가져와서 제공
```

### MIPS Emulation (Cannon)

**왜 MIPS를 사용하는가?**

```
문제: Go 프로그램을 on-chain에서 검증 불가능
     → EVM에서 Go 실행 불가

해결: MIPS로 컴파일
     → MIPS는 단순한 instruction set
     → EVM에서 single instruction 검증 가능
     → Deterministic execution

Bisection Game:
1. Proposer: "Step 1M에서 state X"
2. Challenger: "아니야, state Y"
3. Bisection: "Step 500K는?"
4. ... 반복 ...
5. 최종: Single instruction 차이
6. On-chain: 그 instruction 실행 → 누가 맞나 검증
```

## RAT Client vs Optimism Challenger

### 공통점
- L1 배치 데이터 사용
- State root 계산
- Trustless verification 목표

### 차이점

| | RAT Client | Optimism Challenger |
|---|---|---|
| **L2 RPC 의존성** | 필수 (proof verification) | 선택적 (최적화) |
| **검증 방식** | eth_getProof + Merkle | MIPS execution |
| **시간** | 10-30분 | 7일 (bisection) |
| **복잡도** | 중간 | 높음 |
| **On-chain 검증** | Merkle proof | Single instruction |
| **목적** | Fast path (validator liveness) | Slow path (final safety) |

### RAT Client의 Trade-off

**장점**:
✅ 빠름 (10-30분 vs 7일)
✅ 저렴 (1 tx vs 수십 tx)
✅ 단순 (Merkle proof vs bisection)

**단점**:
❌ L2 RPC 필수 (협조 필요)
❌ L2 RPC 비협조 시 실패

**설계 의도**:
- RAT은 "validator liveness test"
- 대부분(99%) 빠른 경로
- 실패 시 DisputeGame으로 폴백

## Optimism의 완전 Trustless 구현

### op-program이 L2 RPC 없이 작동하는 방법

```go
// op-program/client/l1/client.go
// L1 Oracle - L1 데이터만 사용

type Oracle struct {
    l1Head       common.Hash
    l1Node       L1Node
    blobsFetcher BlobsFetcher
}

func (o *Oracle) HeaderByBlockHash(blockHash common.Hash) BlockInfo {
    // Hint to host: "이 블록 데이터 필요"
    o.hint.Hint(BlockHeaderHint(blockHash))

    // Preimage oracle에서 가져오기 (host가 L1에서 가져옴)
    rlpHeader := o.oracle.Get(preimage.Keccak256Key(blockHash))

    // RLP decode
    header := DecodeRLP(rlpHeader)

    return header
}

// op-program/client/l2/engine.go
// L2 Engine - L1 데이터로 state derive

type OracleEngine struct {
    backend   CachingEngineBackend
    rollupCfg *rollup.Config
}

func (o *OracleEngine) ExecuteBatch(batch Batch) (StateRoot, error) {
    // 1. L1 attributes deposit tx 생성
    l1AttrTx := CreateL1AttributesTx(batch)

    // 2. 모든 트랜잭션 실행
    for _, tx := range batch.Transactions {
        // State access 시:
        // → Hint: "account 0x123 필요"
        // → Host: eth_getProof로 가져오기 (L2 RPC)
        // → Program: Merkle proof 검증
        // → 검증 성공 → 사용
        ExecuteTransaction(tx)
    }

    // 3. State root 계산
    return ComputeStateRoot()
}
```

### L2 RPC가 거짓말하면?

```
시나리오: L2 RPC가 거짓 account balance 제공

1. op-program-host:
   result = eth_getProof(address)
   // { balance: 100 ETH (거짓), proof: [...] }

2. op-program (client):
   VerifyMerkleProof(proof, stateRoot)
   // → 실패! proof가 stateRoot와 맞지 않음

3. 결과:
   → Program crashes
   → Challenger가 dispute game에서 진다
   → L2 RPC 거짓말은 challenger에게 불리

4. 해결:
   → 다른 L2 RPC 사용
   → 또는 L2 RPC 없이 실행 (느리지만 가능)
```

**핵심**: L2 RPC는 **도우미**일 뿐, **검증자는 아님**

## 결론

### Optimism Challenger의 핵심 설계

```
L2 RPC 역할:
├─ 최적화 (빠른 execution)
├─ Hint 제공 (어떤 데이터 필요한지)
└─ 선택적 (없어도 작동)

진짜 검증:
├─ L1 데이터 (trustless)
├─ Merkle proof (cryptographic)
├─ MIPS execution (deterministic)
└─ On-chain verification (final)
```

### RAT Client가 배울 점

현재 RAT client:
```
❌ L2 RPC 필수 (Merkle proof 필요)
❌ L2 RPC 비협조 → 실패
```

개선 가능성:
```
✅ L2 RPC를 선택적으로 (pre-fetching)
✅ L2 RPC 없이도 작동 (느리지만 가능)
✅ Optimism의 preimage oracle 패턴 차용
```

하지만 RAT의 목적:
```
RAT = Validator liveness test (빠른 경로)
DisputeGame = Final safety (느린 but trustless)

→ RAT은 L2 RPC 의존 OK
→ 실패 시 DisputeGame으로 폴백
→ 2-tier 설계가 목적
```

## 참고 파일

- `op-program/client/program.go` - Main program entry
- `op-program/client/l2/engine.go` - EVM execution
- `op-program/host/host.go` - Preimage oracle host
- `op-challenger/game/fault/trace/cannon/provider.go` - MIPS trace provider
- `op-preimage/` - Preimage oracle protocol
