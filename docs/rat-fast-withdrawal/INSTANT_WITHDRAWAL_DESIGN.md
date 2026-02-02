# Instant Withdrawal with RAT: 기술 설계

## 목차

1. [시스템 아키텍처](#시스템-아키텍처)
2. [데이터 플로우](#데이터-플로우)
3. [상태 전이](#상태-전이)
4. [프로토콜 상세](#프로토콜-상세)
5. [데이터 구조 설계](#데이터-구조-설계)
6. [주요 함수 로직](#주요-함수-로직)
7. [오프체인 컴포넌트](#오프체인-컴포넌트)
8. [엣지 케이스 처리](#엣지-케이스-처리)

---

## 시스템 아키텍처

### 전체 구조

```
┌─────────────────────────────────────────────────────────┐
│                    L1 (Ethereum)                         │
│                                                          │
│  ┌──────────────────┐         ┌──────────────────────┐ │
│  │ OptimismPortal2  │         │   RAT Contract       │ │
│  │  - 출금 요청     │◄────────┤   - 검증자 관리      │ │
│  │  - 즉시 finalize │         │   - BLS 검증         │ │
│  └──────────────────┘         │   - 수수료 분배      │ │
│         ▲                      └──────────────────────┘ │
└─────────┼───────────────────────────────────────────────┘
          │                               
          │                               
    ┌─────┴──────────┐          ┌────────────────────────┐
    │  User (Wallet) │          │  Aggregator Service    │
    │  - 출금 개시   │          │  - 서명 수집           │
    │  - 수수료 지불 │          │  - BLS 집계            │
    │  - finalize    │          │  - 온체인 제출         │
    └────────────────┘          └────────────────────────┘
                                         ▲
                                         │
                              ┌──────────┴──────────┐
                              │ Communication Layer │
                              │  (P2P / API)        │
                              └──────────┬──────────┘
                                         ▲
                    ┌────────────────────┼─────────────────┐
                    │                    │                 │
              ┌─────┴─────┐       ┌─────┴─────┐     ┌────┴─────┐
              │Validator 1│       │Validator 2│ ... │Validator │
              │- L2 Node  │       │- L2 Node  │     │  100     │
              │- BLS Key  │       │- BLS Key  │     │- L2 Node │
              └───────────┘       └───────────┘     └──────────┘
```

### 컴포넌트 역할

**L1 Contracts:**
```
OptimismPortal2:
├─ 출금 요청 관리
├─ RAT 빠른 출금 트리거
└─ Finality 확인 후 출금 실행

RAT Contract:
├─ 검증자 등록 및 BLS 키 관리
├─ InstantVerification 생성
├─ BLS 집계 서명 검증
├─ Adjacent Leaves 증명 검증
└─ 수수료 분배
```

**Off-chain:**
```
Validator Client:
├─ L1 이벤트 감지
├─ State Root 검증
├─ Adjacent Leaves 찾기
├─ BLS 서명 생성
└─ 통신 레이어로 브로드캐스트

Aggregator Service:
├─ 검증자 서명 수집
├─ BLS 서명 집계
├─ Adjacent Leaves 증명 준비
└─ 온체인 제출
```

---

## 데이터 플로우

### 전체 프로세스

```
Phase 1: L2 출금 개시
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User (L2) → L2ToL1MessagePasser.initiateWithdrawal(100 ETH)
  └─ 출금 메시지 기록


Phase 2: L1 출금 증명
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User (L1) → OptimismPortal2.proveWithdrawalTransaction()
  ├─ Output Root 검증
  └─ ProvenWithdrawal 기록


Phase 3: 빠른 출금 요청 (선택)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User → OptimismPortal2.requestInstantFinalization{value: fee}()
  ├─ 수수료 계산: max($50, amount × 0.05%)
  └─ RAT.requestInstantVerification() 호출
     ├─ 전체 검증자 목록 조회
     ├─ StateRoot 추출
     ├─ 서명 메시지 생성
     ├─ InstantVerification 생성
     ├─ Bond 선차감 없음 (수수료 인센티브만 사용)
     └─ 이벤트: InstantVerificationRequested


Phase 4: 검증자 응답 (Off-chain, 병렬)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
각 Validator (100명):
  1. 이벤트 감지
  2. State Root 검증 (로컬 L2 노드)
  3. Adjacent Leaves 찾기 (~1초)
  4. BLS 서명 생성
  5. P2P/API 브로드캐스트


Phase 5: 집계 및 제출
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Aggregator:
  1. 100개 서명 수집 (5-10분)
  2. BLS 집계 (~1초)
  3. Adjacent Leaves 증명 준비 (1개)
  4. RAT.submitAggregatedEvidence() 제출


Phase 6: 온체인 검증
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RAT Contract:
  1. BLS 집계 서명 검증 (~130k gas)
     └─ "100명 전원 서명 확인"
  2. Adjacent Leaves 증명 검증 (~50k gas)
     └─ "State Root 정확성 보장"
  3. 검증 완료
     ├─ withdrawalVerified = true
     └─ 수수료 분배 (검증자 + Aggregator)


Phase 7: 즉시 출금
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User → OptimismPortal2.finalizeWithdrawalTransaction()
  └─ RAT 검증 확인 → 즉시 실행 ✅

Total Time: 5-10분
Total Cost: max($50, amount × 0.05%)
```

---

## 상태 전이

### InstantVerification 상태

```
                requestInstantVerification()
                          │
                          ▼
                ┌──────────────────┐
                │    Requested     │
                │   (Created)      │
                └──────────────────┘
                          │
            ┌─────────────┴─────────────┐
            │                           │
     [10분 내 전원 응답]        [10분 초과]
            │                           │
            ▼                           ▼
    ┌────────────────┐       ┌─────────────────┐
    │   Verified     │       │     Failed      │
    │  (Completed)   │       │  (Timed Out)    │
    └────────────────┘       └─────────────────┘
         │                           │
         ├─ verified = true          ├─ verified = false
         ├─ 수수료 분배             ├─ 수수료 환불
         └─ 즉시 출금               └─ 7일 대기 폴백
                                    
참고: Bond 선차감 없음 (수수료 인센티브만)
```

---

## 프로토콜 상세

### Adjacent Leaves 증명

**핵심 개념:**
```
State Root가 정확한지 증명하려면?
→ State Trie에 "존재함"을 증명

방법:
1. Trie에서 인접한 두 leaf 찾기
2. 두 leaf 모두 Merkle proof로 검증
3. 사이에 다른 leaf 없음 증명 (divergence)
→ State Root 정확성 수학적 보장!
```

**검증 단계:**
```solidity
function _verifyAdjacentLeaves(
    bytes32 stateRoot,
    bytes32 leafA,
    bytes32 leafB,
    bytes[] calldata proofsA,
    bytes[] calldata proofsB
) internal view returns (bool) {
    // 1. leafA ∈ Tree(stateRoot)
    require(MerkleTrie.verify(leafA, proofsA, stateRoot));
    
    // 2. leafB ∈ Tree(stateRoot)
    require(MerkleTrie.verify(leafB, proofsB, stateRoot));
    
    // 3. leafA < leafB (순서)
    require(leafA < leafB);
    
    // 4. 완벽한 인접성 (divergence)
    require(_checkDivergence(proofsA, proofsB));
    
    return true;
}
```

**보안 보장:**
```
가짜 State Root 0xFAKE로 시도 시:
├─ 0xFAKE Trie 존재하지 않음
├─ Merkle Proof 생성 불가
└─ 검증 실패 ❌

Merkle Collision 시도:
├─ 확률: 2^-256
└─ 불가능 ❌

결론: "존재하는" State Trie만 증명 가능!
```

---

### BLS 서명 집계

**기본 원리:**
```
BLS12-381 Pairing:

개별 서명:
├─ σ_i = H(m)^sk_i  (G2 point)
└─ 각자의 비밀키로 서명

집계:
├─ σ_agg = σ_1 + σ_2 + ... + σ_100
├─ pk_agg = pk_1 + pk_2 + ... + pk_100
└─ 크기: 개별 서명과 동일! (96 bytes)

검증:
└─ e(H(m), pk_agg) == e(σ_agg, G1)
   └─ 성공 → 100명 전원 서명 확인!
```

**가스 비용:**
```
BLS 검증:
├─ hashToG2: ~30k gas
├─ Pairing check: ~100k gas
└─ Total: ~130k gas

검증자 수 무관:
├─ 100명: 130k gas
├─ 1,000명: 130k gas ← O(1)!
└─ 10,000명: 130k gas
```

---

### 수수료 분배

**하이브리드 계산:**
```solidity
function calculateInstantFinalizationFee(uint256 withdrawalAmount)
    public view returns (uint256)
{
    uint256 minFee = 50 ether;  // $50
    uint256 rateFee = (withdrawalAmount * 5) / 10000;  // 0.05%
    
    return rateFee > minFee ? rateFee : minFee;
}
```

**분배 로직:**
```solidity
function _distributeRewards(bytes32 withdrawalHash) internal {
    InstantVerification storage v = instantVerifications[withdrawalHash];
    
    // 가스비 차감
    uint256 gasCost = tx.gasprice * 180000;
    uint256 remaining = v.fee - gasCost;
    
    // 분배
    uint256 validatorReward = (remaining * 90) / 100;
    uint256 aggregatorReward = (remaining * 10) / 100 + gasCost;
    
    // 검증자 균등 분배
    uint256 perValidator = validatorReward / v.allValidators.length;
    for (uint256 i = 0; i < v.allValidators.length; i++) {
        pendingRewards[v.allValidators[i]] += perValidator;
    }
    
    // Aggregator 지급
    payable(msg.sender).transfer(aggregatorReward);
}
```

**예시 (100 ETH 출금):**
```
수수료: $150
가스비: $7.20
잔여: $142.80

분배:
├─ 검증자 90%: $128.52 → 각자 $1.29
└─ Aggregator 10% + 가스: $21.48
```

---

## 데이터 구조 설계

### InstantVerification

```solidity
struct InstantVerification {
    // 출금 정보
    bytes32 withdrawalHash;      // 출금 해시
    address requester;           // 요청자
    uint256 fee;                 // 수수료
    uint256 deadline;            // 타임아웃 (10분)
    
    // State Root 정보
    bytes32 stateRoot;           // 검증할 State Root
    address gameAddress;         // DisputeGame 주소
    bytes32 gameId;              // Game 식별자
    
    // 검증자 정보
    address[] allValidators;     // 전체 검증자 목록
    bytes32 messageHash;         // BLS 서명 메시지
    
    // 상태
    bool completed;              // 완료 여부
}

mapping(bytes32 => InstantVerification) public instantVerifications;
mapping(bytes32 => bool) public withdrawalVerified;
```

### ValidatorRegistration 확장

```solidity
struct ValidatorRegistration {
    // 기존 필드들...
    uint256 lockedForRAT;
    uint64 latestTestDeadline;
    uint32 validatorIndex;
    bool isActive;
    
    // 빠른 출금 추가 필드
    bytes blsPublicKey;             // BLS G1 공개키 (48 bytes)
    bool blsKeyRegistered;          // 등록 여부
    uint256 instantWithdrawalCount; // 참여 횟수 (통계)
}

// BLS 공개키 매핑 (빠른 조회용)
mapping(address => BLS.PublicKey) public validatorBLSKeys;
```

---

## 주요 함수 로직

### requestInstantVerification()

```solidity
function requestInstantVerification(
    bytes32 gameId,
    bytes32 withdrawalHash,
    address systemConfig,
    address requester,
    uint256 withdrawalAmount
) external payable {
    
    // 1. 수수료 검증
    uint256 requiredFee = calculateInstantFinalizationFee(withdrawalAmount);
    require(msg.value >= requiredFee, "Insufficient fee");
    
    // 2. 검증자 목록 조회 (전체 활성 검증자)
    ValidatorPool storage pool = validatorPools[systemConfig];
    require(pool.activeCount > 0, "No validators");
    
    address[] memory allValidators = new address[](pool.activeCount);
    for (uint256 i = 0; i < pool.activeCount; i++) {
        allValidators[i] = pool.validators[i];
        // BLS 키 등록 확인
        require(
            validatorRegistrations[systemConfig][allValidators[i]].blsKeyRegistered,
            "Validator BLS key not registered"
        );
    }
    
    // 3. StateRoot 추출
    address gameAddress = getGameAddress(gameId);
    bytes32 stateRoot = _extractStateRoot(gameAddress);
    
    // 4. 서명 메시지 생성
    bytes32 messageHash = keccak256(abi.encode(
        withdrawalHash,
        gameId,
        systemConfig,
        block.chainid,
        stateRoot
    ));
    
    // 5. InstantVerification 생성
    InstantVerification storage v = instantVerifications[withdrawalHash];
    v.withdrawalHash = withdrawalHash;
    v.requester = requester;
    v.fee = msg.value;
    v.deadline = block.timestamp + evidenceSubmissionPeriod;
    v.stateRoot = stateRoot;
    v.gameAddress = gameAddress;
    v.allValidators = allValidators;
    v.messageHash = messageHash;
    v.completed = false;
    
    // 6. Bond 선차감 없음
    // 빠른 출금은 수수료 인센티브만 사용
    // 게임이론상 응답이 지배 전략
    
    // 7. 이벤트
    emit InstantVerificationRequested(
        withdrawalHash,
        allValidators,
        messageHash,
        stateRoot,
        v.deadline
    );
}
```

---

### submitAggregatedEvidence()

```solidity
function submitAggregatedEvidence(
    bytes32 withdrawalHash,
    BLS.Signature calldata aggregatedSignature,
    bytes32 leafA,
    bytes32 leafB,
    bytes[] calldata proofsA,
    bytes[] calldata proofsB
) external {
    
    InstantVerification storage v = instantVerifications[withdrawalHash];
    
    // 1. 상태 검증
    require(!v.completed, "Already completed");
    require(block.timestamp <= v.deadline, "Deadline passed");
    
    // 2. BLS 집계 서명 검증 (~130k gas)
    BLS.PublicKey memory aggregatedPubKey = _getAggregatedPublicKey(
        v.allValidators
    );
    
    require(
        BLS.verify(aggregatedPubKey, v.messageHash, aggregatedSignature),
        "Invalid signature"
    );
    
    // 3. Adjacent Leaves 증명 검증 (~50k gas)
    require(
        _verifyAdjacentLeaves(v.stateRoot, leafA, leafB, proofsA, proofsB),
        "Invalid proof"
    );
    
    // 4. 완료 처리
    v.completed = true;
    withdrawalVerified[withdrawalHash] = true;
    
    // 5. 수수료 분배
    _distributeRewards(withdrawalHash);
    
    emit WithdrawalVerified(withdrawalHash, v.allValidators.length);
}
```

---

### refundFee()

```solidity
function refundFee(bytes32 withdrawalHash) external {
    
    InstantVerification storage v = instantVerifications[withdrawalHash];
    
    require(v.requester == msg.sender, "Not requester");
    require(!v.completed, "Already completed");
    require(block.timestamp > v.deadline, "Not timed out");
    
    // 환불
    uint256 refund = v.fee;
    v.fee = 0;
    payable(msg.sender).transfer(refund);
    
    emit FeeRefunded(withdrawalHash, msg.sender, refund);
}
```

---

## 오프체인 컴포넌트

### Validator Client

**핵심 로직:**
```typescript
class InstantWithdrawalListener {
  async handleInstantVerification(request) {
    // 1. State Root 검증
    const isValid = await this.verifyStateRoot(request.stateRoot);
    if (!isValid) return;
    
    // 2. Adjacent Leaves 찾기
    const proof = await this.findAdjacentLeaves(request.stateRoot);
    
    // 3. BLS 서명 생성
    const signature = await this.signMessage(request.messageHash);
    
    // 4. 브로드캐스트
    await this.broadcastSignature({
      withdrawalHash: request.withdrawalHash,
      signature,
      proof
    });
  }
  
  async findAdjacentLeaves(stateRoot: string) {
    const accounts = await this.l2Provider.send('debug_accountRange', [
      stateRoot,
      '0x0000000000000000000000000000000000000000',
      100,
      true  // includeProof
    ]);
    
    const mid = Math.floor(accounts.length / 2);
    return {
      leafA: accounts[mid].key,
      leafB: accounts[mid + 1].key,
      proofsA: accounts[mid].proof,
      proofsB: accounts[mid + 1].proof
    };
  }
}
```

---

### Aggregator Service

**핵심 로직:**
```typescript
class SignatureCollector {
  handleSignature(signature: ValidatorSignatureMessage) {
    const request = this.pendingRequests.get(signature.withdrawalHash);
    
    // 검증자 확인
    if (!request.validators.has(signature.validator)) return;
    
    // 추가
    request.collectedSignatures.push(signature);
    
    // 증명 저장 (첫 번째 것 사용)
    if (!request.adjacentLeavesProof && signature.proof) {
      request.adjacentLeavesProof = signature.proof;
    }
    
    // 전부 모였으면 제출
    if (request.collectedSignatures.length === request.requiredCount) {
      this.submitRequest(signature.withdrawalHash);
    }
  }
  
  async submitRequest(withdrawalHash: string) {
    const request = this.pendingRequests.get(withdrawalHash);
    
    // BLS 집계
    const aggregatedSig = await this.aggregateSignatures(
      request.collectedSignatures.map(s => s.blsSignature)
    );
    
    // 온체인 제출
    const tx = await this.ratContract.submitAggregatedEvidence(
      withdrawalHash,
      aggregatedSig,
      request.adjacentLeavesProof.leafA,
      request.adjacentLeavesProof.leafB,
      request.adjacentLeavesProof.proofsA,
      request.adjacentLeavesProof.proofsB
    );
    
    await tx.wait();
  }
}
```

---

## 엣지 케이스 처리

### Case 1: 타임아웃

**처리:**
```
95명 응답, 5명 미응답, 10분 초과

1. withdrawalVerified = false
2. 사용자: refundFee() 호출 → 전액 환불
3. 미응답 5명: 수수료 못 받음 (그게 페널티)
4. 일반 출금으로 폴백 (7일)

참고:
└─ Bond 선차감 없으므로 복구/Slashing 없음
└─ 수수료 못 받는 것이 자연스러운 페널티
```

### Case 2: 가스 급등

**방어:**
```solidity
function submitAggregatedEvidence(...) external {
    uint256 estimatedGas = 180000 * tx.gasprice;
    require(v.fee > estimatedGas * 2, "Fee too low");
    // ...
}
```

### Case 3: Aggregator 부재

**해결:**
```
다중 Aggregator:
├─ 여러 Aggregator 경쟁
├─ 먼저 제출한 사람이 보상
└─ 사용자도 직접 제출 가능
```

---

## 구현 체크리스트

### Phase 1: 스마트 컨트랙트 (2-3주)

- [ ] BLS 라이브러리 통합
- [ ] InstantVerification struct 추가
- [ ] ValidatorRegistration 확장
- [ ] registerValidatorWithBLS() 구현
- [ ] calculateInstantFinalizationFee() 구현
- [ ] requestInstantVerification() 구현
- [ ] submitAggregatedEvidence() 구현
- [ ] refundFee() 구현
- [ ] _extractStateRoot() 구현
- [ ] _verifyAdjacentLeaves() 구현
- [ ] _distributeRewards() 구현
- [ ] 단위 테스트
- [ ] 통합 테스트

### Phase 2: 오프체인 인프라 (3-4주)

- [ ] Validator Client
  - [ ] 이벤트 리스너
  - [ ] State Root 검증
  - [ ] Adjacent Leaves 찾기
  - [ ] BLS 서명 생성
  - [ ] 통신 레이어
- [ ] Aggregator Service
  - [ ] 서명 수집
  - [ ] BLS 집계
  - [ ] 온체인 제출
  - [ ] API/P2P 통신
- [ ] E2E 테스트

### Phase 3: 감사 및 배포 (4주)

- [ ] 스마트 컨트랙트 감사
- [ ] 암호학 검증
- [ ] 경제 시뮬레이션
- [ ] Mainnet 배포

---

## 미해결 질문

1. **StateRoot 추출**: Optimism팀과 협의 필요
   - DisputeGame에서 stateRoot 추출 방법
2. **BLS 라이브러리**: EIP-2537 vs Solidity 라이브러리
   - 현재 사용 가능한 라이브러리 선택
3. **P2P vs API**: Phase 1은 API, Phase 2는 P2P
   - 초기 구현은 중앙화된 API
   - 나중에 P2P로 마이그레이션

---

이 설계는 실제 구현 가능한 수준의 기술 명세를 제공합니다. 🎯
