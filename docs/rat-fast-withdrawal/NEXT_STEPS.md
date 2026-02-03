# Fast Withdrawal 다음 작업 계획

**작성일**: 2026-02-03
**현재 상태**: Smart Contracts 완료, Go Clients 미착수

---

## 현재까지 완료된 작업 ✅

### Smart Contracts (Phase 1 완료)
- ✅ `BLS12381.sol` - BLS12-381 서명 검증 라이브러리 (EIP-2537 precompiles)
- ✅ `RATFastWithdrawal.sol` - Fast Withdrawal 메인 컨트랙트
- ✅ `RATFastWithdrawalLib.sol` - Adjacent Leaves 증명 라이브러리
- ✅ `AdjacentLeavesVerifier.sol` - DivergenceWitness 검증
- ✅ `RATStorage.sol` - BLS 공개키 필드 추가
- ✅ 43개 Solidity 테스트 통과
- ✅ E2E 테스트 (FastWithdrawalE2E.t.sol, FastWithdrawalE2EFork.t.sol)

### 핵심 기능
- ✅ BLS 집계 서명 검증 (`verifyAndExecuteFastWithdrawal`)
- ✅ Adjacent Leaves 증명 검증 (StateRoot as Target)
- ✅ 만장일치(unanimous) 합의 검증
- ✅ 수수료 분배 (Aggregator + Validators)
- ✅ Game Claim Check (DisputeGame 분쟁 감지)
- ✅ OptimismPortal2 연동 인터페이스

---

## 다음 우선순위 작업 🎯

### Priority 1: Validator Node 구현 (Week 4-5)

**목표**: 검증자가 Fast Withdrawal 요청을 받아서 BLS 서명을 생성하는 libp2p 노드 구현

#### 1.1 프로젝트 구조 생성
```bash
# 디렉토리 생성
mkdir -p clients/fast-withdrawal/validator/{cmd,pkg/{config,p2p,signer,handler,verifier}}
cd clients/fast-withdrawal/validator
```

**파일 구조**:
```
clients/fast-withdrawal/validator/
├── cmd/
│   └── main.go                 # CLI 진입점
├── pkg/
│   ├── config/
│   │   └── config.go           # 설정 관리
│   ├── p2p/
│   │   ├── node.go             # libp2p 노드
│   │   ├── discovery.go        # DHT discovery
│   │   └── pubsub.go           # GossipSub
│   ├── signer/
│   │   ├── bls.go              # BLS 서명 생성
│   │   └── keystore.go         # BLS 키 관리
│   ├── handler/
│   │   └── handler.go          # SignatureRequest 핸들러
│   └── verifier/
│       ├── interface.go        # Verifier 인터페이스
│       └── type3.go            # Type3 검증 (rat-client-type3 재사용)
├── go.mod
├── config.example.yaml
└── README.md
```

#### 1.2 핵심 태스크

**Task 1: go.mod 및 의존성 설정** (0.5일)
```bash
cd clients/fast-withdrawal/validator
go mod init github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator

# 주요 의존성
go get github.com/libp2p/go-libp2p@v0.32.0
go get github.com/libp2p/go-libp2p-pubsub@v0.10.0
go get github.com/libp2p/go-libp2p-kad-dht@v0.25.0
go get github.com/ethereum/go-ethereum@v1.13.0

# rat-client-type3 재사용을 위한 replace
# go.mod에 추가:
# replace github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3 => ../../rat-client-type3
```

**Task 2: Config 구조 정의** (0.5일)
```go
// pkg/config/config.go
package config

type Config struct {
    // Validator Identity
    ValidatorAddress  string `yaml:"validator_address"`
    BLSPrivateKey     string `yaml:"bls_private_key"`     // 또는 keystore 경로
    
    // L1 Connection
    L1RPC             string `yaml:"l1_rpc"`
    RATContract       string `yaml:"rat_contract"`
    
    // L2 Connection (Type3 검증용)
    L2RPC             string `yaml:"l2_rpc"`              // op-geth with debug API
    OpNodeRPC         string `yaml:"opnode_rpc"`          // optional
    
    // libp2p Network
    ListenAddr        string   `yaml:"listen_addr"`       // "/ip4/0.0.0.0/tcp/9000"
    BootstrapPeers    []string `yaml:"bootstrap_peers"`
    DHTNamespace      string   `yaml:"dht_namespace"`     // "/tokamak-rat-validators"
    WithdrawalTopic   string   `yaml:"withdrawal_topic"`  // "/tokamak/rat/withdrawal/1.0.0"
    
    // Logging
    LogLevel          string `yaml:"log_level"`
}
```

**Task 3: libp2p Node 구현** (2일)
```go
// pkg/p2p/node.go
package p2p

import (
    "github.com/libp2p/go-libp2p"
    dht "github.com/libp2p/go-libp2p-kad-dht"
    pubsub "github.com/libp2p/go-libp2p-pubsub"
)

type ValidatorNode struct {
    host            host.Host
    dht             *dht.IpfsDHT
    pubsub          *pubsub.PubSub
    withdrawalTopic *pubsub.Topic
    validatorAddr   common.Address
}

func NewValidatorNode(ctx context.Context, cfg *config.Config) (*ValidatorNode, error) {
    // 1. libp2p host 생성
    // 2. DHT 설정 및 bootstrap
    // 3. GossipSub pubsub 설정
    // 4. withdrawal topic 구독
}

func (vn *ValidatorNode) SubscribeWithdrawalRequests(handler func(*SignatureRequest) error) error {
    // pubsub에서 SignatureRequest 수신
}

func (vn *ValidatorNode) PublishSignature(response *SignatureResponse) error {
    // SignatureResponse를 pubsub에 발행
}
```

**Task 4: BLS Signer 구현** (1.5일)
```go
// pkg/signer/bls.go
package signer

import (
    bls "github.com/ethereum/go-ethereum/crypto/bls12381"
)

type BLSSigner struct {
    privateKey *bls.SecretKey
    publicKey  *bls.PublicKey
}

func NewBLSSigner(privateKeyHex string) (*BLSSigner, error) {
    // BLS 개인키 로드
}

func (bs *BLSSigner) Sign(message []byte) ([]byte, error) {
    // BLS 서명 생성 (G2 signature)
}

func (bs *BLSSigner) PublicKey() []byte {
    // BLS 공개키 반환 (G1, 128 bytes uncompressed)
}

func (bs *BLSSigner) GenerateProofOfPossession(
    validatorAddr common.Address,
    chainID *big.Int,
) ([]byte, error) {
    // PoP 서명 생성 (등록 시 필요)
    // message = keccak256("BLS_POP", chainID, validatorAddr, publicKey)
}
```

**Task 5: SignatureRequest Handler** (1.5일)
```go
// pkg/handler/handler.go
package handler

type RequestHandler struct {
    signer      *signer.BLSSigner
    verifier    verifier.WithdrawalVerifier  // Type3Verifier
    l1Client    *ethclient.Client
    ratContract *contracts.RAT
}

func (h *RequestHandler) HandleSignatureRequest(req *SignatureRequest) error {
    // 1. On-chain 요청 검증 (RAT contract 조회)
    // 2. Type3 검증 (OutputRootProof, DisputeGame 상태)
    // 3. L2 출금 존재 확인
    // 4. BLS 서명 생성
    // 5. SignatureResponse 발행
}
```

**Task 6: Type3 Verifier (rat-client-type3 재사용)** (2일)
```go
// pkg/verifier/type3.go
package verifier

import (
    // ⭐ 기존 RAT Client 재사용
    ratverification "github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/verification"
    ratl2sync "github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/l2sync"
)

type Type3Verifier struct {
    l2Client           *ethclient.Client
    opNodeClient       *opnode.Client
    outputRootVerifier *ratverification.OutputRootVerifier
    disputeGameFactory *contracts.DisputeGameFactory
}

func (v *Type3Verifier) ValidateWithdrawal(ctx context.Context, req *SignatureRequest) error {
    // 1. DisputeGame 상태 확인 (resolved? claims?)
    // 2. OutputRootProof 검증 (재사용)
    // 3. L2 출금 트랜잭션 존재 확인 (eth_getProof)
    // 4. Merkle proof 검증 (재사용)
}
```

**Task 7: main.go 및 CLI** (0.5일)
```go
// cmd/main.go
package main

func main() {
    // 1. Config 로드
    // 2. ValidatorNode 초기화
    // 3. BLSSigner 초기화
    // 4. RequestHandler 초기화
    // 5. SubscribeWithdrawalRequests
    // 6. 무한 루프 (signal handling)
}
```

**Task 8: 테스트** (1일)
- 단위 테스트 (BLS signer, config)
- 통합 테스트 (libp2p 통신)
- Mock 테스트 (Type3 verifier)

#### 1.3 예상 기간
**Total: 10일 (2주)**

---

### Priority 2: Aggregator Service 구현 (Week 6-7)

**목표**: L1 이벤트를 감지하고 서명을 수집하여 L1에 제출하는 서비스

#### 2.1 프로젝트 구조
```
clients/fast-withdrawal/aggregator/
├── cmd/
│   └── main.go
├── pkg/
│   ├── config/
│   │   └── config.go
│   ├── monitor/
│   │   └── l1_monitor.go       # L1 이벤트 감지
│   ├── p2p/
│   │   ├── network.go          # libp2p network
│   │   └── broadcaster.go      # SignatureRequest 브로드캐스트
│   ├── collector/
│   │   ├── signature.go        # 서명 수집
│   │   └── aggregator.go       # BLS 집약
│   └── submitter/
│       └── proof.go            # L1 트랜잭션 제출
├── go.mod
├── config.example.yaml
└── README.md
```

#### 2.2 핵심 태스크

**Task 1: L1 이벤트 모니터** (1일)
```go
// pkg/monitor/l1_monitor.go
package monitor

// FastWithdrawalRequested 이벤트 감지
// OptimismPortal2 또는 FastWithdrawal 컨트랙트에서 발생
func (m *L1Monitor) WatchWithdrawalRequests() {
    // event FastWithdrawalRequested(
    //     bytes32 indexed requestId,
    //     address indexed user,
    //     uint256 amount,
    //     bytes32 stateRoot,
    //     uint256 deadline
    // );
}
```

**Task 2: SignatureRequest 브로드캐스터** (1일)
```go
// pkg/p2p/broadcaster.go
package p2p

func (b *Broadcaster) BroadcastSignatureRequest(req *SignatureRequest) error {
    // libp2p pubsub으로 브로드캐스트
    // Topic: /tokamak/rat/withdrawal/1.0.0
}
```

**Task 3: 서명 수집 관리자** (2일)
```go
// pkg/collector/signature.go
package collector

type SignatureCollector struct {
    requests      map[bytes32]*RequestState
    validatorSet  []common.Address
}

type RequestState struct {
    Request       *SignatureRequest
    Signatures    map[common.Address]*BLSSignature
    RequiredCount uint64  // 100% validators
    ReceivedCount uint64
    Completed     bool
}

func (sc *SignatureCollector) AddSignature(requestId bytes32, sig *BLSSignature) error {
    // 1. 서명 검증 (off-chain)
    // 2. 서명 저장
    // 3. 만장일치 확인 (100%)
    // 4. 완료되면 submitAggregatedProof 호출
}
```

**Task 4: BLS 집약** (1일)
```go
// pkg/collector/aggregator.go
package collector

func (a *BLSAggregator) AggregateSignatures(signatures []*BLSSignature) ([]byte, error) {
    // BLS 서명 집약 (G2 point addition)
}

func (a *BLSAggregator) CreateValidatorBitmap(validators []common.Address) uint256 {
    // 모든 비트 1로 설정 (만장일치)
}
```

**Task 5: L1 제출** (1.5일)
```go
// pkg/submitter/proof.go
package submitter

func (s *Submitter) SubmitAggregatedProof(
    requestId bytes32,
    aggregatedSignature []byte,
    validatorBitmap uint256,
) error {
    // RAT.verifyAndExecuteFastWithdrawal() 호출
    // - 가스 가격 최적화
    // - 재시도 로직
    // - 에러 처리
}
```

**Task 6: 테스트** (1.5일)

#### 2.3 예상 기간
**Total: 8일 (1.5주)**

---

### Priority 3: 통합 테스트 (Week 8-10)

#### 3.1 로컬 Devnet 구성 (Week 8)
```bash
# Docker Compose 구성
services:
  anvil:
    # L1 (Ethereum)
  
  op-geth:
    # L2 execution
  
  op-node:
    # L2 consensus
  
  validator-1:
    # Fast Withdrawal Validator Node
  
  validator-2:
  
  validator-3:
  
  aggregator:
    # Aggregator Service
```

#### 3.2 E2E 시나리오 테스트 (Week 9)
1. Happy path: 전체 플로우 성공
2. Validator offline: 만장일치 실패
3. Invalid signature: 서명 검증 실패
4. Timeout: Fallback to regular withdrawal
5. Multiple requests: 동시 처리

#### 3.3 보안 검토 (Week 10)
- Rogue key attack 방지 (PoP 검증)
- Replay attack 방지 (chainId + nonce)
- Eclipse attack 방지 (다중 bootstrap)

---

## 세부 실행 계획

### Week 4-5: Validator Node

#### Day 1-2
- [ ] 프로젝트 구조 생성
- [ ] go.mod 설정 및 의존성 추가
- [ ] Config 구조 정의
- [ ] libp2p 노드 기본 설정

#### Day 3-4
- [ ] DHT discovery 구현
- [ ] GossipSub pubsub 구현
- [ ] withdrawal topic 구독

#### Day 5-6
- [ ] BLS 키 관리 (keystore)
- [ ] BLS 서명 생성
- [ ] PoP 생성

#### Day 7-8
- [ ] SignatureRequest 핸들러
- [ ] Type3Verifier 구현 (재사용)
- [ ] L2 출금 검증

#### Day 9-10
- [ ] main.go 및 CLI
- [ ] 단위 테스트
- [ ] 통합 테스트

### Week 6-7: Aggregator

#### Day 1-2
- [ ] 프로젝트 구조 생성
- [ ] L1 이벤트 모니터

#### Day 3-4
- [ ] SignatureRequest 브로드캐스터
- [ ] SignatureResponse 수신

#### Day 5-6
- [ ] 서명 수집 상태 관리
- [ ] BLS 서명 집약

#### Day 7-8
- [ ] L1 트랜잭션 제출
- [ ] 가스 최적화 및 재시도

### Week 8-10: 통합 테스트

#### Week 8
- [ ] Docker Compose 구성
- [ ] 로컬 devnet 설정
- [ ] 배포 스크립트

#### Week 9
- [ ] E2E 시나리오 테스트
- [ ] 버그 수정

#### Week 10
- [ ] 보안 검토
- [ ] 문서 업데이트

---

## 의존성 및 차단 요소

### 필수 의존성
1. **rat-client-type3**: Type3 검증 로직 재사용
   - 현재 stable 버전 사용
   - 인터페이스 변경 시 대응 필요

2. **EIP-2537 Precompiles**: BLS 서명 검증
   - Testnet에서 활성화 확인 필요
   - Fallback: 순수 Go BLS 라이브러리

3. **libp2p**: P2P 네트워킹
   - 버전: v0.32+
   - Bootstrap peer 사전 구성 필요

### 리스크
1. **BLS 라이브러리 호환성**: go-ethereum vs herumi/bls
   - Mitigation: 두 라이브러리 모두 지원하도록 인터페이스 추상화

2. **libp2p 네트워크 불안정**: 연결 끊김, 메시지 손실
   - Mitigation: 재연결 로직, 타임아웃 처리

3. **Type3Verifier API 변경**: rat-client-type3 업데이트 시
   - Mitigation: 버전 고정, 인터페이스 래핑

---

## 성공 기준

### Validator Node
- [ ] libp2p 네트워크 정상 연결
- [ ] SignatureRequest 수신 및 처리
- [ ] BLS 서명 생성 및 발행
- [ ] Type3 검증 정상 동작
- [ ] 단위 테스트 커버리지 > 80%

### Aggregator
- [ ] L1 이벤트 감지
- [ ] 서명 수집 (100% 만장일치)
- [ ] BLS 집약 정상 동작
- [ ] L1 트랜잭션 제출 성공
- [ ] 단위 테스트 커버리지 > 80%

### 통합 테스트
- [ ] E2E 시나리오 100% 통과
- [ ] 로컬 devnet에서 전체 플로우 성공
- [ ] 보안 검토 통과

---

## 다음 단계 요약

**즉시 시작 가능한 작업**:
1. ✅ `clients/fast-withdrawal/validator/` 디렉토리 생성
2. ✅ `go.mod` 초기화 및 의존성 추가
3. ✅ `pkg/config/config.go` 작성
4. ✅ `pkg/p2p/node.go` libp2p 노드 구현 시작

**첫 주 목표**:
- Validator Node 기본 구조 완성
- libp2p 통신 테스트 성공
- BLS 서명 생성 검증

**2주 후 목표**:
- Validator Node 완전 구현
- rat-client-type3 재사용 검증
- E2E 테스트 준비

---

**작성자**: AI Assistant
**검토 필요**: 개발팀
**다음 리뷰**: Validator Node 완료 후 (약 2주 후)
