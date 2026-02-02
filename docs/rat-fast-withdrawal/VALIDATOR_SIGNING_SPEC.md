# RAT Fast Withdrawal - 검증자 서명 명세

## 개요

RAT 검증자들이 Fast Withdrawal 요청에 서명할 때 사용하는 메시지 구조 및 검증 절차를 정의합니다.

---

## 1. 서명 메시지 구조

### 1.1 메시지 포맷

```solidity
bytes32 message = keccak256(abi.encodePacked(
    "TOKAMAK_FAST_WITHDRAWAL",   // Domain separator
    withdrawalHash,               // bytes32: 출금 트랜잭션 해시
    stateRoot,                    // bytes32: L2 State Root
    leafA,                        // bytes32: 인접 리프 A
    leafB,                        // bytes32: 인접 리프 B
    systemConfig,                 // address: L2 SystemConfig 주소
    chainId                       // uint256: L1 체인 ID
));
```

### 1.2 필드 설명

| 필드 | 타입 | 설명 | 출처 |
|-----|------|------|------|
| `Domain Separator` | string | `"TOKAMAK_FAST_WITHDRAWAL"` | 고정값 |
| `withdrawalHash` | bytes32 | 출금 트랜잭션의 해시 | OptimismPortal2 이벤트 |
| `stateRoot` | bytes32 | L2 상태 루트 | OptimismPortal2 이벤트 |
| `leafA` | bytes32 | 인접 리프 A (State Root 증명용) | 검증자 계산 |
| `leafB` | bytes32 | 인접 리프 B (State Root 증명용) | 검증자 계산 |
| `systemConfig` | address | L2 SystemConfig 주소 | OptimismPortal2 이벤트 |
| `chainId` | uint256 | L1 체인 ID (1: mainnet, 5: goerli) | block.chainid |

---

## 2. 검증자의 오프체인 검증 절차

### 2.1 이벤트 감지

**1단계: OptimismPortal2의 FastWithdrawalRequested 이벤트 감지**

```solidity
event FastWithdrawalRequested(
    bytes32 indexed withdrawalHash,
    address indexed user,
    uint256 amount,
    bytes32 stateRoot,
    uint256 feePaid,
    uint256 deadline
);
```

**이벤트에서 추출하는 정보:**
- `withdrawalHash`: 서명할 출금 해시
- `stateRoot`: 검증할 L2 상태 루트
- `user`: 출금 요청자 (검증용)
- `amount`: 출금 금액 (검증용)

### 2.2 L2 상태 검증

**2단계: L2 노드에서 실제 상태 확인**

```typescript
// L2 노드에 stateRoot가 실제로 존재하는지 확인
const stateRootExists = await l2Provider.getBlock(blockNumber);
if (stateRootExists.stateRoot !== eventStateRoot) {
    // 서명 거부
    return false;
}
```

**3단계: 출금 트랜잭션 검증**

```typescript
// 출금 트랜잭션이 L2에서 실제로 발생했는지 확인
const withdrawal = await l2Provider.getTransaction(withdrawalTxHash);
if (!withdrawal || withdrawal.to !== L2_BRIDGE_ADDRESS) {
    // 서명 거부
    return false;
}
```

**4단계: 사용자 잔액 확인**

```typescript
// 사용자가 실제로 출금할 잔액이 있는지 확인
const balance = await l2Token.balanceOf(user);
if (balance < amount) {
    // 서명 거부
    return false;
}
```

### 2.3 인접 리프 증명 생성

**5단계: State Trie에서 인접 리프 찾기**

```typescript
// State Root에 대한 인접 리프 증명 생성
const proof = await generateAdjacentLeavesProof(
    stateRoot,
    l2Provider
);

const leafA = proof.leafA;
const leafB = proof.leafB;
const proofsA = proof.proofsA;
const proofsB = proof.proofsB;
```

**인접 리프 증명의 목적:**
- State Root가 임의로 생성된 것이 아니라 실제 Merkle Patricia Trie의 루트임을 증명
- 두 개의 인접한 리프가 존재 → Trie 구조가 유효함

---

## 3. BLS 서명 생성

### 3.1 메시지 해시 계산

```typescript
import { keccak256, defaultAbiCoder } from 'ethers/lib/utils';

const messageHash = keccak256(
    defaultAbiCoder.encode(
        ['string', 'bytes32', 'bytes32', 'bytes32', 'bytes32', 'address', 'uint256'],
        [
            'TOKAMAK_FAST_WITHDRAWAL',
            withdrawalHash,
            stateRoot,
            leafA,
            leafB,
            systemConfig,
            chainId
        ]
    )
);
```

### 3.2 BLS 서명

```typescript
import { sign } from '@noble/bls12-381';

// 검증자의 BLS 비밀키로 서명
const signature = await sign(messageHash, validatorSecretKey);

// 서명 결과 (96 bytes)
console.log('BLS Signature:', signature);
```

---

## 4. 보안 검증 항목

### 4.1 필수 검증 항목

검증자는 다음 항목을 **모두** 확인해야 합니다:

| 순번 | 검증 항목 | 목적 |
|-----|----------|------|
| 1 | `stateRoot` 존재 확인 | L2 노드에서 실제 블록의 State Root인지 |
| 2 | `withdrawalHash` 유효성 | 실제 출금 트랜잭션인지 |
| 3 | 사용자 잔액 확인 | 충분한 잔액이 있는지 |
| 4 | 이중 출금 체크 | 이미 처리된 출금인지 |
| 5 | 출금 금액 한도 | 비정상적으로 큰 금액인지 |
| 6 | State Root 타임스탬프 | 너무 오래된 State Root인지 |
| 7 | 인접 리프 유효성 | leafA, leafB가 실제로 인접한지 |

### 4.2 거부해야 하는 경우

다음 경우 **서명을 거부**해야 합니다:

```typescript
// 1. State Root가 L2에 존재하지 않음
if (!await verifyStateRoot(stateRoot)) {
    return reject("Invalid stateRoot");
}

// 2. 출금 트랜잭션이 없음
if (!await verifyWithdrawal(withdrawalHash)) {
    return reject("Withdrawal not found");
}

// 3. 잔액 부족
if (userBalance < withdrawalAmount) {
    return reject("Insufficient balance");
}

// 4. 이미 처리된 출금
if (await isProcessed(withdrawalHash)) {
    return reject("Already processed");
}

// 5. 인접 리프 증명 실패
if (!verifyAdjacentLeaves(stateRoot, leafA, leafB)) {
    return reject("Invalid adjacent leaves proof");
}
```

---

## 5. Aggregator의 서명 수집

### 5.1 서명 수집 절차

```typescript
// 1. 모든 활성 검증자에게 서명 요청
const validators = await ratContract.getL2Validators(systemConfig);
const signatures: Map<string, Uint8Array> = new Map();

for (const validator of validators) {
    // 각 검증자에게 서명 요청 (오프체인 통신)
    const signature = await requestSignature(validator, messageHash);
    if (signature) {
        signatures.set(validator, signature);
    }
}

// 2. 만장일치 확인
if (signatures.size !== validators.length) {
    throw new Error(`Not unanimous: ${signatures.size}/${validators.length}`);
}
```

### 5.2 BLS 서명 집계

```typescript
import { aggregateSignatures } from '@noble/bls12-381';

// 모든 서명 집계
const signatureArray = Array.from(signatures.values());
const aggregatedSignature = aggregateSignatures(signatureArray);

console.log('Aggregated Signature:', aggregatedSignature);
```

### 5.3 비트맵 생성

```typescript
// 서명한 검증자 비트맵 생성
let validatorBitmap = BigInt(0);

for (let i = 0; i < validators.length; i++) {
    const validator = validators[i];
    if (signatures.has(validator)) {
        validatorBitmap |= (BigInt(1) << BigInt(i));
    }
}

console.log('Validator Bitmap:', validatorBitmap.toString());
```

---

## 6. RAT 컨트랙트 호출

### 6.1 트랜잭션 구성

```typescript
const tx = await ratContract.verifyAndExecuteFastWithdrawal(
    {
        nonce: withdrawal.nonce,
        sender: withdrawal.sender,
        target: withdrawal.target,
        value: withdrawal.value,
        gasLimit: withdrawal.gasLimit,
        data: withdrawal.data
    },
    {
        withdrawalHash: withdrawalHash,
        systemConfig: systemConfig,
        stateRoot: stateRoot,
        validatorBitmap: validatorBitmap,
        leafA: leafA,
        leafB: leafB,
        proofsA: proofsA,
        proofsB: proofsB
    },
    aggregatedSignature
);

await tx.wait();
console.log('Fast Withdrawal executed!');
```

---

## 7. 검증 흐름 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                    검증자 서명 프로세스                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [1] OptimismPortal2                                            │
│      └─ FastWithdrawalRequested 이벤트 발생                     │
│            ↓                                                    │
│  [2] 검증자 (오프체인)                                           │
│      ├─ 이벤트 감지                                             │
│      ├─ L2 상태 검증                                            │
│      │   ├─ State Root 존재 확인                                │
│      │   ├─ 출금 트랜잭션 확인                                  │
│      │   ├─ 사용자 잔액 확인                                    │
│      │   └─ 이중 출금 체크                                      │
│      ├─ 인접 리프 증명 생성                                     │
│      └─ BLS 서명 생성                                           │
│            ↓                                                    │
│  [3] Aggregator                                                 │
│      ├─ 모든 검증자 서명 수집                                    │
│      ├─ 만장일치 확인                                           │
│      ├─ BLS 서명 집계                                           │
│      └─ RAT.verifyAndExecuteFastWithdrawal() 호출              │
│            ↓                                                    │
│  [4] RAT Contract                                               │
│      ├─ 메시지 해시 재계산                                      │
│      ├─ BLS 서명 검증                                           │
│      ├─ 인접 리프 증명 검증                                     │
│      └─ OptimismPortal2 호출                                    │
│            ├─ setWithdrawalVerified()                          │
│            └─ fastWithdrawalFinalize()                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. 보안 고려사항

### 8.1 Replay Attack 방지

| 메커니즘 | 설명 |
|---------|------|
| `chainId` 포함 | 다른 체인에서 서명 재사용 방지 |
| `withdrawalHash` 포함 | 특정 출금에만 유효 |
| `systemConfig` 포함 | 특정 L2에만 유효 |
| `processedWithdrawals` 체크 | RAT에서 중복 처리 방지 |

### 8.2 State Root 유효성

- **인접 리프 증명**: State Root가 실제 Merkle Patricia Trie의 루트임을 증명
- **L2 노드 확인**: 검증자가 직접 L2 노드에서 State Root 존재 확인
- **타임스탬프 체크**: 너무 오래된 State Root는 거부

### 8.3 1-of-N 보안 모델

- **단 한 명의 정직한 검증자**만 있어도 악의적 출금 차단 가능
- 만장일치 요구 → 모든 검증자가 동의해야 Fast Withdrawal 실행
- 한 명이라도 거부 → 7일 일반 출금으로 fallback

---

## 9. 검증자 구현 예제

### 9.1 Full Node 모니터링

```typescript
// OptimismPortal2 이벤트 리스너
portal.on('FastWithdrawalRequested', async (
    withdrawalHash,
    user,
    amount,
    stateRoot,
    feePaid,
    deadline
) => {
    console.log('Fast Withdrawal Requested:', {
        withdrawalHash,
        user,
        amount,
        stateRoot
    });

    // 검증 및 서명
    const shouldSign = await validateWithdrawal({
        withdrawalHash,
        user,
        amount,
        stateRoot,
        systemConfig: portal.address
    });

    if (shouldSign) {
        // 인접 리프 증명 생성
        const proof = await generateAdjacentLeavesProof(stateRoot);
        
        // 메시지 생성 및 서명
        const message = constructMessage({
            withdrawalHash,
            stateRoot,
            leafA: proof.leafA,
            leafB: proof.leafB,
            systemConfig: portal.address,
            chainId: await provider.getNetwork().chainId
        });
        
        const signature = await signMessage(message, validatorSecretKey);
        
        // Aggregator에게 서명 전송
        await sendSignatureToAggregator({
            withdrawalHash,
            signature,
            proof
        });
    }
});
```

---

## 10. 테스트 시나리오

### 10.1 정상 케이스

```typescript
test('Valid fast withdrawal with unanimous consensus', async () => {
    // 1. 출금 요청
    await portal.proveAndRequestFastWithdrawal(tx, ...);
    
    // 2. 검증자 서명
    const signatures = await collectSignatures(withdrawalHash);
    
    // 3. Fast Withdrawal 실행
    await rat.verifyAndExecuteFastWithdrawal(...);
    
    // 4. 출금 완료 확인
    expect(await portal.fastFinalizedWithdrawals(hash)).to.be.true;
});
```

### 10.2 거부 케이스

```typescript
test('Reject withdrawal with insufficient signatures', async () => {
    // 한 명이 서명 거부
    const signatures = await collectSignatures(withdrawalHash, { skipValidator: 0 });
    
    // Fast Withdrawal 실패 예상
    await expect(
        rat.verifyAndExecuteFastWithdrawal(...)
    ).to.be.revertedWith('FastWithdrawalNotUnanimousError');
});
```

---

*Last Updated: 2026-02-02*
