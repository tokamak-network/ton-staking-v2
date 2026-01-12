# Trustless Verification Architecture

## 핵심 원칙: L1 Data Only

**RAT 클라이언트는 L2 RPC를 신뢰하지 않습니다.**

사용자가 직접 운영하지 않는 제3자 L2 RPC (Infura, Alchemy 등)는:
- ✅ 거짓말을 **시도**할 수 있습니다
- ❌ 하지만 **검증을 통과하는 거짓말**은 암호학적으로 불가능합니다
- ⚠️ 하지만 **응답 거부/지연**으로 RAT를 방해할 수 있습니다

**따라서**: 진정한 trustless 검증을 위해서는 **L1 배치 데이터만으로 L2 상태를 완전히 재구성**해야 합니다.

## 3단계 Verification Strategy

### Strategy 1: Stateless Executor (Primary) ⭐⭐⭐

**100% Trustless - L2 RPC 완전 불필요!**

```
┌─────────────────────────────────────────┐
│ Background Sync (24/7 실행)             │
│                                         │
│ 1. L1에서 배치 가져오기                │
│    → batchInbox 트랜잭션 모니터링      │
│    → calldata/blob 디코딩              │
│                                         │
│ 2. 로컬에서 트랜잭션 실행               │
│    → EVM 직접 실행                     │
│    → State DB 업데이트                 │
│                                         │
│ 3. State Root 계산                     │
│    → 로컬 State Trie 계산              │
│    → L2 RPC 완전 불필요!               │
└─────────────────────────────────────────┘

RAT 발생 시:
- 이미 동기화된 state 사용
- 검증 시간: 1-5분 ⚡
- 100% trustless ✅
```

**구현**: `pkg/derivation/stateless_executor.go`

**장점**:
- ✅ 100% trustless (L1 consensus만 신뢰)
- ✅ 가장 빠른 검증 (1-5분)
- ✅ L2 RPC 응답 거부 공격 불가능
- ✅ 완전한 독립성

**단점**:
- 초기 동기화: 수일~수주
- 디스크 공간: 1-5 TB
- 24/7 백그라운드 실행 필요
- 운영 복잡도 증가

**권장 대상**:
- 대형 Validator (기관투자자)
- 높은 보안 요구사항
- 장기 운영 계획

### Strategy 2: Proof-Verified L2 RPC (Fallback)

**Trustless with Cooperation - L2 RPC 협조 필요**

```
┌─────────────────────────────────────────┐
│ RAT 발생 시                             │
│                                         │
│ 1. L1에서 finalized state root 가져오기│
│    → DisputeGameFactory 조회           │
│    → 100% trustless ✅                 │
│                                         │
│ 2. L2 RPC에 state proof 요청           │
│    → eth_getProof(address, block)      │
│    → Account + Storage Merkle proof    │
│                                         │
│ 3. Merkle Proof 검증                   │
│    → trie.VerifyProof()                │
│    → L1 state root에 대조              │
│    → 거짓말 감지 ✅                    │
│                                         │
│ 4. 검증된 데이터로 실행                │
│    → Proof 통과한 데이터만 사용        │
│    → State root 계산                   │
└─────────────────────────────────────────┘

검증 시간: 10-30분 ⚡
```

**구현**: `pkg/derivation/proof_verified_state.go`

**장점**:
- ✅ 거짓 데이터 감지 (Merkle proof 검증)
- ✅ 빠른 검증 (10-30분)
- ✅ 초기 동기화 불필요
- ✅ 디스크 공간 최소

**단점**:
- ⚠️ L2 RPC 협조 필요
- ⚠️ 응답 거부/지연 공격 취약
- ⚠️ RAT timeout 가능

**권장 대상**:
- 소규모 Validator
- 빠른 검증 우선
- Stateless executor 백업용

### Strategy 3: Checkpoint-Based (Emergency)

**100% Trustless - Checkpoint부터 실행**

```
┌─────────────────────────────────────────┐
│ RAT 발생 시                             │
│                                         │
│ 1. Nearest finalized checkpoint 찾기   │
│    → DisputeGameFactory 조회           │
│    → L1에 finalized된 state root       │
│                                         │
│ 2. Checkpoint부터 target까지 실행      │
│    → L1 배치만 사용                    │
│    → 수백~수천 블록 실행               │
│                                         │
│ 3. State root 계산                     │
│    → 100% trustless ✅                 │
└─────────────────────────────────────────┘

검증 시간: 1-2시간 (checkpoint 거리에 따라)
```

**구현**: `pkg/verification/hybrid_verifier.go`

**장점**:
- ✅ 100% trustless
- ✅ L2 RPC 불필요
- ✅ 초기 동기화 불필요

**단점**:
- 느림 (1-2시간)
- Checkpoint 간격에 따라 시간 변동

**권장 대상**:
- Emergency fallback
- L2 RPC 완전 신뢰 불가 상황

## Hybrid Verifier: 최선의 전략 자동 선택

```go
type HybridVerifier struct {
    statelessExecutor   *StatelessExecutor   // Primary
    proofVerifier       *TrustlessVerifier   // Fallback
    checkpointVerifier  *CheckpointVerifier  // Emergency
}

func (v *HybridVerifier) VerifyBatch(targetBlock) {
    // 1차 시도: Stateless Executor (가장 빠르고 trustless)
    if statelessExecutor.IsSynced(targetBlock) {
        return statelessExecutor.Verify()  // 1-5분 ⚡⚡
    }

    // 2차 시도: Catch-up이 가능한가?
    if statelessExecutor.EstimateCatchUpTime() < 20 min {
        statelessExecutor.CatchUp(targetBlock)
        return statelessExecutor.Verify()  // 10-30분 ⚡
    }

    // 3차 시도: L2 RPC with Proof
    result, err := proofVerifier.VerifyWithProof()
    if err == nil {
        return result  // 10-30분 ⚡
    }

    // 4차 시도: Checkpoint-based
    return checkpointVerifier.ExecuteFromCheckpoint()  // 1-2시간 🐌

    // 모두 실패 → DisputeGame (7일)
}
```

## L2 RPC 공격 시나리오와 방어

### 시나리오 1: 거짓 데이터 제공

```
공격: L2 RPC가 잘못된 balance/storage 제공
방어: Merkle Proof 검증 실패 → 즉시 감지
결과: ✅ 공격 실패
```

### 시나리오 2: 위조 Proof 제공

```
공격: L2 RPC가 위조된 Merkle proof 제공
방어: trie.VerifyProof() 실패 → SHA3 pre-image attack 필요 (불가능)
결과: ✅ 공격 실패 (암호학적으로 불가능)
```

### 시나리오 3: 응답 거부/지연 ⚠️

```
공격: L2 RPC가 응답 안 함 또는 매우 느리게 응답
방어: Timeout → 다른 strategy로 fallback
결과: ⚠️ RAT 지연 가능, 하지만 bond 안전
      → Stateless executor로 fallback
      → 또는 DisputeGame 참여 (7일)
```

### 시나리오 4: 선택적 응답 (교묘한 공격)

```
공격: 900/1000 accounts는 정상 응답, 100개만 응답 거부
방어: Timeout 감지 → Stateless executor로 전환
결과: ⚠️ RAT 지연, 하지만 검증 완료 가능
```

## 최종 방어선: DisputeGame

모든 strategy가 실패해도 bond는 안전합니다:

```
RAT Timeout 시:
┌─────────────────────────────────────┐
│ 1. Bond는 LOCKED (슬래싱 안 됨!)   │
│                                     │
│ 2. FaultDisputeGame 참여            │
│    → 7일간 bisection game          │
│    → L2 RPC 완전 불필요            │
│    → L1 data만으로 검증            │
│                                     │
│ 3. Validator 승리 시:              │
│    → resolveClaim() 호출           │
│    → Bond 복구 ✅                  │
│                                     │
│ 4. Validator 패배 시:              │
│    → Bond 슬래싱 (실제 fraud)      │
└─────────────────────────────────────┘
```

**핵심**: RAT timeout은 bond 손실로 이어지지 않습니다!

## 운영 권장사항

### 소규모 Validator (개인)

```yaml
strategy: hybrid
primary: proof_verified_l2rpc
fallback: checkpoint_based

l2_rpc_urls:
  - https://mainnet.optimism.io  # Primary
  - https://opt-mainnet.g.alchemy.com  # Backup
  - https://optimism.publicnode.com  # Backup

allow_dispute_game_fallback: true
```

**예상 결과**:
- 90% 케이스: 10-30분 안에 RAT 완료
- 10% 케이스 (L2 RPC 문제): DisputeGame 참여 (7일)
- Bond 손실 위험: 없음 (honest validator)

### 대형 Validator (기관)

```yaml
strategy: hybrid
primary: stateless_executor  # 100% trustless!
fallback: proof_verified_l2rpc

stateless_executor:
  enable_background_sync: true
  sync_start_block: 0  # Genesis부터 동기화
  state_db_path: /data/l2-state  # 5TB 디스크

l2_rpc_urls:
  - https://your-own-archive-node.com  # Self-hosted
```

**예상 결과**:
- 99% 케이스: 1-5분 안에 RAT 완료 (Stateless)
- 1% 케이스 (sync 중): 10-30분 (L2 RPC fallback)
- Bond 손실 위험: 없음

## Security Guarantees

### 암호학적 보장

1. **Merkle Proof 위조 불가능**
   - SHA3/Keccak256 pre-image resistance
   - Collision resistance: 2^256 난이도

2. **L1 Consensus 신뢰**
   - Ethereum L1의 finality 보장
   - 51% attack 필요 (사실상 불가능)

3. **Deterministic Execution**
   - EVM 실행은 결정론적
   - 동일 input → 동일 output 보장

### 운영적 보장

1. **Bond Safety**
   - RAT timeout으로 bond 손실 없음
   - DisputeGame으로 최종 방어

2. **Multiple Fallbacks**
   - 3단계 verification strategy
   - 하나 실패해도 다음 시도

3. **No Single Point of Failure**
   - L2 RPC 장애 → Stateless executor
   - Stateless executor 문제 → Checkpoint
   - 모두 실패 → DisputeGame (7일)

## 결론

**사용자님 지적이 정확합니다**: L2 RPC를 신뢰하면 안 됩니다.

**해결책**:
1. **Primary**: Stateless Executor로 L1 데이터만으로 L2 상태 재구성 (100% trustless)
2. **Fallback**: Proof-verified L2 RPC (빠르지만 협조 필요)
3. **Emergency**: Checkpoint-based execution (느리지만 trustless)
4. **Ultimate**: DisputeGame (7일, 100% trustless, bond 보장)

**Trade-off**:
- 100% Trustless vs 빠른 검증 vs 낮은 운영 비용
- 3가지를 동시에 만족 불가능
- Hybrid 방식으로 상황에 따라 최선의 전략 선택

**최종 보장**: 정직한 Validator는 **절대** bond를 잃지 않습니다.
