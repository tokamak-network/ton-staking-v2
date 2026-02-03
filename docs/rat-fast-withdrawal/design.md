# TON Staking V3 + Fast Withdrawal Integration Design

**작성일**: 2026-02-01
**버전**: 2.2
**상태**: Phase 1-2 완료 (Smart Contract + Go Client)
**최종 업데이트**: 2026-02-03

## 목차

1. [개요](#1-개요)
2. [시스템 아키텍처](#2-시스템-아키텍처)
3. [프로젝트 구조 및 코드 재사용](#3-프로젝트-구조-및-코드-재사용)
4. [컴포넌트 설계](#4-컴포넌트-설계)
5. [데이터 플로우](#5-데이터-플로우)
6. [보안 및 경제 모델](#6-보안-및-경제-모델)
7. [구현 로드맵](#7-구현-로드맵)

---

## 1. 개요

### 1.1 목표

기존 TON Staking V3 검증자 시스템에 **Fast Withdrawal** 기능을 추가하여:
- 사용자가 일반 출금(7일 대기) 대신 **즉시 출금** 가능
- 검증자들이 libp2p 네트워크로 BLS 서명 제공
- Aggregator가 서명 수집하여 L1에 제출
- **만장일치(unanimous consensus)** 기반 실행

### 1.2 기존 시스템 개요

**현재 검증자 역할**:
- L2 full archive node 운영 (op-geth + op-node follower mode)
- RAT (Randomized Attention Test) 응답
- State leaf evidence 제출 (adjacent leaves 증명)
- 검증자 담보금: coinage 기반 스테이킹

**기존 인프라**:
```
Validator Infrastructure (현재)
├── op-node (follower mode) - L1 batch data 재구성
├── op-geth (archive + debug) - L2 state 저장
└── RAT Client Type3 (Go) - State leaf evidence 생성
```

### 1.3 추가할 시스템

**Fast Withdrawal 시스템**:
```
Validator Infrastructure (추가)
├── [기존] op-node, op-geth, RAT Client Type3
└── [신규] Fast Withdrawal Validator (libp2p)
    ├── BLS 서명 생성
    ├── Withdrawal request 수신 (pubsub)
    ├── Type 3 출금 검증 (RAT Client 코드 재사용)
    └── 서명 응답 전송

Aggregator Service (신규)
├── L1 이벤트 모니터링 (FastWithdrawal 컨트랙트)
├── libp2p Network (서명 요청 브로드캐스트)
├── BLS 서명 수집 및 집약
└── L1 트랜잭션 제출

L1 Smart Contracts (신규)
└── FastWithdrawal.sol - BLS 검증 및 출금 실행
```

### 1.4 지원 Rollup 타입

**현재 지원**:
- ✅ **RollupType 3**: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
  - DisputeGame 기반 출금
  - Adjacent Leaves 증명 검증 (StateRoot as Target)
  - 기존 RAT Client Type3 로직 재사용 가능

**미지원 (현재)**:
- ❌ **Type 1**: TOKAMAK (Legacy) - RAT 미사용
- ❌ **Type 2**: OPTIMISM_BEDROCK - RAT 미사용

**미래 확장**:
- 🔮 **Type 4+**: 새로운 롤업 타입 추가 가능
- 확장 가능한 아키텍처 (인터페이스 기반)

### 1.5 현재 구현 상태 (2026-02-03)

#### ✅ 완료된 항목:
- **Smart Contracts**:
  - ✅ `BLS12381.sol` - BLS12-381 서명 검증 라이브러리 (EIP-2537 precompiles)
  - ✅ `RATFastWithdrawal.sol` - Fast Withdrawal 메인 로직
  - ✅ `RATFastWithdrawalLib.sol` - Adjacent Leaves 검증 라이브러리
  - ✅ `RAT.sol` + `RATStorage.sol` - BLS 공개키 등록/조회 기능
  - ✅ 43개 Solidity 테스트 통과
  - ✅ E2E 테스트 (FastWithdrawalE2E.t.sol, FastWithdrawalE2EFork.t.sol)

- **핵심 기능**:
  - ✅ BLS 집계 서명 검증
  - ✅ Adjacent Leaves 증명 검증 (DivergenceWitness)
  - ✅ 만장일치(unanimous) 합의
  - ✅ 수수료 분배 (Aggregator + Validators)
  - ✅ Game Claim Check (DisputeGame 분쟁 감지)
  - ✅ OptimismPortal2 연동 인터페이스

#### ✅ Go Clients (완료):
- **Validator Node** (`clients/fast-withdrawal/validator/`):
  - ✅ cmd/main.go - CLI 진입점, 전체 Validator 로직 통합
  - ✅ pkg/config/config.go - YAML 설정 로드 및 검증
  - ✅ pkg/p2p/node.go - libp2p 노드, DHT discovery, GossipSub
  - ✅ pkg/signer/bls.go - herumi/bls-eth-go-binary 기반 BLS 서명
  - ✅ pkg/handler/handler.go - SignatureRequest 검증 및 응답
  - ✅ pkg/verifier/ - Type3 검증 (OutputRootProof, DisputeGame)
  - ✅ config.example.yaml - 설정 템플릿
  - ✅ 빌드 바이너리: 46MB

- **Aggregator Service** (`clients/fast-withdrawal/aggregator/`):
  - ✅ cmd/main.go - CLI 진입점, 전체 Aggregator 로직 통합
  - ✅ pkg/config/config.go - YAML 설정 로드 및 검증
  - ✅ pkg/monitor/l1_monitor.go - L1 이벤트 감시 (ABI decoding)
  - ✅ pkg/p2p/network.go - libp2p 네트워크, SignatureRequest 브로드캐스트
  - ✅ pkg/collector/collector.go - 서명 수집 및 off-chain BLS 검증
  - ✅ pkg/collector/aggregator.go - BLS 서명 집약, *big.Int bitmap (무제한 검증자)
  - ✅ pkg/submitter/submitter.go - L1 트랜잭션 제출 (ABI encoding)
  - ✅ pkg/contracts/rat.go - RAT 컨트랙트 바인딩 (검증자 세트 로드)
  - ✅ pkg/l2proof/provider.go - L2 OutputRootProof, WithdrawalProof 생성
  - ✅ pkg/l2proof/types.go - 증명 타입 정의
  - ✅ config.example.yaml - 설정 템플릿
  - ✅ 빌드 바이너리: 47MB

#### 🚧 작업 필요:
- **배포 및 운영**:
  - ❌ Devnet/Testnet 배포
  - ❌ 배포 스크립트
  - ❌ 운영 가이드
  - ❌ 통합 테스트 (E2E)

---

## 2. 시스템 아키텍처

### 2.1 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                         L1 (Ethereum)                           │
│                                                                 │
│  ┌──────────────────┐         ┌─────────────────────┐         │
│  │ FastWithdrawal   │◄────────│  RAT Contract       │         │
│  │ Contract (NEW)   │         │  - Validator Set    │         │
│  │ - BLS verify     │         │  - BLS Public Keys  │         │
│  │ - Execute        │         └─────────────────────┘         │
│  └──────────────────┘                                           │
│         ▲                                                       │
│         │ submitAggregatedProof(signature, bitmap)              │
│         │                                                       │
└─────────┼───────────────────────────────────────────────────────┘
          │
          │
┌─────────┴───────────────────────────────────────────────────────┐
│                    Aggregator Service (NEW)                     │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Withdrawal Request Monitor                              │  │
│  │  - Watch FastWithdrawal.WithdrawalRequested events       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│                          ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  libp2p Network                                          │  │
│  │  - Topic: /tokamak/rat/withdrawal/1.0.0                  │  │
│  │  - DHT: tokamak-rat-validators                           │  │
│  │  - Broadcast SignatureRequest                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│                          ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Signature Collection Manager                            │  │
│  │  - Query validator set from RAT contract                 │  │
│  │  - Collect BLS signatures (100% required)                │  │
│  │  - Aggregate BLS signatures                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│                          ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Proof Submitter                                         │  │
│  │  - Submit to L1 FastWithdrawal contract                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          │
                          │ libp2p pubsub
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Validator Infrastructure (EXTENDED)            │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  [기존] RAT Client Type3                                 │  │
│  │  - op-geth debug API 사용                                │  │
│  │  - Adjacent leaves 증거 생성                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  [신규] libp2p Validator Node (NEW)                      │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │  libp2p Node                                       │ │  │
│  │  │  - PeerID: validator-{address}                     │ │  │
│  │  │  - DHT: tokamak-rat-validators                     │ │  │
│  │  │  - Subscribe: /tokamak/rat/withdrawal/1.0.0        │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  │          │                                              │  │
│  │          ▼                                              │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │  Withdrawal Request Handler                        │ │  │
│  │  │  - Receive SignatureRequest via pubsub             │ │  │
│  │  │  - Validate request (on-chain 조회)                │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  │          │                                              │  │
│  │          ▼                                              │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │  BLS Signer                                        │ │  │
│  │  │  - Load BLS private key                            │ │  │
│  │  │  - Sign: hash(requestId, user, amount, chainId)    │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  │          │                                              │  │
│  │          ▼                                              │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │  Response Publisher                                │ │  │
│  │  │  - Publish SignatureResponse to pubsub             │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 통합 포인트

#### 2.2.1 RAT Contract 확장

**기존 기능**:
- 검증자 등록/탈퇴
- RAT 테스트 트리거
- State leaf evidence 검증

**추가 기능**:
- BLS 공개키 등록 (Proof of Possession)
- BLS 공개키 조회 API
- FastWithdrawal 컨트랙트와 연동

#### 2.2.2 검증자 인프라 확장

**기존**:
```
Validator = op-node + op-geth + RAT Client
```

**확장**:
```
Validator = [기존] + libp2p Node + BLS Signer
```

**동작 원리**:
- RAT Client: L2 state 증명 (Liveness)
- libp2p Node: Fast withdrawal 서명 (추가 서비스)
- 두 프로세스는 **독립적**으로 실행
- 동일한 validator 주소 사용

---

## 3. 프로젝트 구조 및 코드 재사용

### 3.1 디렉토리 구조

```
ton-staking-v2/
├── src/                                    # Solidity Contracts
│   ├── validator/
│   │   ├── RAT.sol                         # 기존 RAT 로직
│   │   ├── RATFastWithdrawal.sol           # ✅ Fast Withdrawal 구현 (Proxy Selector)
│   │   ├── RATStorage.sol                  # ✅ BLS 공개키 필드 추가
│   │   └── libraries/
│   │       └── Type3EvidenceVerifier.sol
│   └── libraries/                          # ✅ 공통 라이브러리
│       ├── BLS12381.sol                    # ✅ BLS 서명 검증 (EIP-2537)
│       ├── RATFastWithdrawalLib.sol        # ✅ Adjacent Leaves 검증
│       └── AdjacentLeavesVerifier.sol      # ✅ DivergenceWitness 검증
│
├── clients/                                # Go Clients
│   ├── README.md                           # ⭐ 업데이트: RAT + Fast Withdrawal
│   │
│   ├── rat-client-type3/                   # ✅ 기존: RAT Client
│   │   ├── cmd/main.go
│   │   ├── pkg/
│   │   │   ├── bindings/
│   │   │   ├── client/
│   │   │   ├── derivation/
│   │   │   ├── evidence/                   # ⭐ Fast Withdrawal에서 재사용
│   │   │   │   ├── state_leaf_evidence.go  # Merkle proof 검증
│   │   │   │   └── ...
│   │   │   ├── l2sync/                     # ⭐ Fast Withdrawal에서 재사용
│   │   │   │   ├── state_rpc.go            # L2 state 조회
│   │   │   │   ├── divergence.go
│   │   │   │   └── ...
│   │   │   ├── monitor/
│   │   │   ├── submitter/
│   │   │   └── verification/               # ⭐ Fast Withdrawal에서 재사용
│   │   │       ├── output_root.go          # OutputRootProof 검증
│   │   │       ├── opnode_verifier.go
│   │   │       └── ...
│   │   ├── go.mod
│   │   ├── config.example.yaml
│   │   └── README.md
│   │
│   └── fast-withdrawal/                    # 🆕 신규: Fast Withdrawal
│       ├── README.md                       # Fast Withdrawal 개요
│       │
│       ├── validator/                      # 검증자용 libp2p 노드
│       │   ├── cmd/
│       │   │   └── main.go
│       │   ├── pkg/
│       │   │   ├── p2p/                    # libp2p 네트워크
│       │   │   │   ├── node.go
│       │   │   │   ├── discovery.go
│       │   │   │   └── pubsub.go
│       │   │   ├── signer/                 # BLS 서명
│       │   │   │   ├── bls.go
│       │   │   │   └── keystore.go
│       │   │   ├── handler/                # 출금 요청 처리
│       │   │   │   └── handler.go
│       │   │   └── verifier/               # Type별 검증
│       │   │       ├── interface.go        # 공통 인터페이스
│       │   │       ├── type3.go            # ⭐ rat-client-type3 재사용
│       │   │       └── factory.go          # Verifier 생성
│       │   ├── go.mod                      # ⭐ rat-client-type3 의존
│       │   ├── config.example.yaml
│       │   └── README.md
│       │
│       └── aggregator/                     # Aggregator 서비스
│           ├── cmd/
│           │   └── main.go
│           ├── pkg/
│           │   ├── monitor/                # L1 이벤트 모니터링
│           │   │   └── l1_monitor.go
│           │   ├── p2p/                    # libp2p 네트워크
│           │   │   ├── network.go
│           │   │   └── broadcaster.go
│           │   ├── collector/              # 서명 수집 및 집약
│           │   │   ├── signature.go
│           │   │   └── aggregator.go
│           │   └── submitter/              # L1 제출
│           │       └── proof.go
│           ├── go.mod
│           ├── config.example.yaml
│           └── README.md
│
└── docs/
    ├── specs-kr/
    │   ├── 13-rat-client-specification.md
    │   └── ...
    └── rat-fastwithdrwal/
        ├── libp2p-bls-aggregator-design.md
        └── integration-design.md           # 📄 이 문서
```

### 3.2 코드 재사용 전략

#### 3.2.1 rat-client-type3 재사용 컴포넌트

Fast Withdrawal Validator는 기존 RAT Client Type3의 검증 로직을 재사용합니다:

| RAT Client Type3 컴포넌트 | Fast Withdrawal에서 재사용 | 목적 |
|-------------------------|------------------------|------|
| `pkg/verification/output_root.go` | ✅ Type3Verifier | OutputRootProof 검증 |
| `pkg/verification/opnode_verifier.go` | ✅ Type3Verifier | OpNode 기반 검증 |
| `pkg/evidence/state_leaf_evidence.go` | ✅ Type3Verifier | Merkle proof 검증 |
| `pkg/l2sync/state_rpc.go` | ✅ Type3Verifier | L2 state 조회 (debug API) |
| `pkg/l2sync/divergence.go` | ⚠️ 간접 사용 | Merkle trie 유틸리티 |

**재사용 이유**:
- ✅ **검증 로직 일관성**: RAT와 Fast Withdrawal이 동일한 L2 state 검증
- ✅ **코드 중복 방지**: 이미 검증된 로직 재사용
- ✅ **유지보수 용이**: 한 곳만 수정하면 양쪽에 반영

#### 3.2.2 go.mod 의존성 설정

```go
// clients/fast-withdrawal/validator/go.mod

module github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator

go 1.22

require (
    github.com/ethereum/go-ethereum v1.13.0
    github.com/libp2p/go-libp2p v0.32.0
    github.com/libp2p/go-libp2p-pubsub v0.10.0
    github.com/libp2p/go-libp2p-kad-dht v0.25.0

    // ⭐ 기존 RAT Client를 내부 모듈로 의존
    github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3 v0.0.0
)

// ⭐ 로컬 경로로 replace (개발 환경)
replace github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3 => ../../rat-client-type3
```

#### 3.2.3 Type3Verifier 구현 예시

```go
// clients/fast-withdrawal/validator/pkg/verifier/type3.go

package verifier

import (
    "context"

    // ⭐ 기존 RAT Client 패키지 import
    ratevidence "github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/evidence"
    ratl2sync "github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/l2sync"
    ratverification "github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/verification"
)

type Type3Verifier struct {
    l2Client     *ethclient.Client
    opNodeClient *opnode.Client

    // ⭐ 기존 RAT Client 컴포넌트 재사용
    outputRootVerifier *ratverification.OutputRootVerifier
    l2Sync            *ratl2sync.StateSynchronizer
    disputeGameFactory *contracts.DisputeGameFactory
}

func NewType3Verifier(
    l1Client *ethclient.Client,
    l2Client *ethclient.Client,
    opNodeClient *opnode.Client,
    config *Config,
) (*Type3Verifier, error) {
    // ⭐ 기존 RAT Client의 OutputRootVerifier 초기화
    outputRootVerifier := ratverification.NewOutputRootVerifier(
        l2Client,
        opNodeClient,
    )

    // ⭐ 기존 RAT Client의 L2Sync 초기화
    l2Sync := ratl2sync.NewStateSynchronizer(l2Client)

    disputeGameFactory, err := contracts.NewDisputeGameFactory(
        config.DisputeGameFactoryAddr,
        l1Client,
    )
    if err != nil {
        return nil, err
    }

    return &Type3Verifier{
        l2Client:           l2Client,
        opNodeClient:       opNodeClient,
        outputRootVerifier: outputRootVerifier,
        l2Sync:            l2Sync,
        disputeGameFactory: disputeGameFactory,
    }, nil
}

func (v *Type3Verifier) ValidateWithdrawal(
    ctx context.Context,
    req *SignatureRequest,
) error {
    // 1. DisputeGame 상태 확인
    game, err := v.disputeGameFactory.Games(&bind.CallOpts{}, req.GameIndex)
    if err != nil {
        return fmt.Errorf("failed to get game: %w", err)
    }

    if game.Status != CHALLENGER_WINS && game.Status != DEFENDER_WINS {
        return errors.New("game not resolved")
    }

    // 2. ⭐ 기존 RAT Client의 OutputRootProof 검증 로직 재사용
    outputRootProof, err := v.outputRootVerifier.VerifyOutputRoot(
        ctx,
        req.BlockNumber,
        req.OutputRoot,
    )
    if err != nil {
        return fmt.Errorf("invalid output root: %w", err)
    }

    // 3. L2에서 출금 트랜잭션 존재 확인
    withdrawalExists, err := v.verifyWithdrawalInL2(
        ctx,
        req,
        outputRootProof,
    )
    if err != nil {
        return err
    }

    if !withdrawalExists {
        return errors.New("withdrawal not found in L2")
    }

    return nil
}

func (v *Type3Verifier) verifyWithdrawalInL2(
    ctx context.Context,
    req *SignatureRequest,
    outputRootProof *ratverification.OutputRootProof,
) (bool, error) {
    // L2ToL1MessagePasser predeploy
    messagePasserAddr := common.HexToAddress("0x4200000000000000000000000000000000000016")

    // Withdrawal hash 계산
    withdrawalHash := crypto.Keccak256Hash(
        req.User.Bytes(),
        req.Amount.Bytes(),
        // ... 기타 withdrawal 데이터
    )

    // ⭐ L2 RPC로 storage proof 조회
    proof, err := v.l2Client.GetProof(
        ctx,
        messagePasserAddr,
        []string{withdrawalHash.Hex()},
        big.NewInt(int64(req.BlockNumber)),
    )
    if err != nil {
        return false, err
    }

    // ⭐ 기존 RAT Client의 Merkle proof 검증 함수 재사용
    valid := ratevidence.VerifyStorageProof(
        proof,
        outputRootProof.MessagePasserStorageRoot,
    )

    return valid, nil
}
```

### 3.3 책임 분리

```
┌─────────────────────────────────────────────────────────────┐
│ rat-client-type3                                            │
├─────────────────────────────────────────────────────────────┤
│ 목적: RAT 응답                                              │
│                                                             │
│ - L1 AttentionTestTriggered 이벤트 모니터링                │
│ - Adjacent Leaves 찾기 (debug_accountRange)                │
│ - StateLeafEvidence 생성                                    │
│ - DivergenceWitness 계산                                    │
│ - L1 RAT.submitEvidence() 제출                             │
│                                                             │
│ 재사용 가능 컴포넌트:                                        │
│ ✅ pkg/verification/ - OutputRootProof 검증                │
│ ✅ pkg/evidence/ - Merkle proof 검증                        │
│ ✅ pkg/l2sync/ - L2 state 조회                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ fast-withdrawal/validator                                   │
├─────────────────────────────────────────────────────────────┤
│ 목적: Fast Withdrawal 서명                                  │
│                                                             │
│ - libp2p pubsub으로 SignatureRequest 수신                  │
│ - Type3Verifier로 출금 요청 검증 (⭐ RAT Client 재사용)     │
│ - BLS 개인키로 서명 생성                                    │
│ - libp2p pubsub으로 SignatureResponse 발행                 │
│                                                             │
│ 의존성:                                                     │
│ ⭐ rat-client-type3 (검증 로직 재사용)                      │
│ + libp2p (네트워킹)                                         │
│ + BLS 라이브러리 (서명)                                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ fast-withdrawal/aggregator                                  │
├─────────────────────────────────────────────────────────────┤
│ 목적: 서명 수집 및 L1 제출                                  │
│                                                             │
│ - L1 WithdrawalRequested 이벤트 모니터링                    │
│ - libp2p pubsub으로 SignatureRequest 브로드캐스트          │
│ - SignatureResponse 수집 (만장일치 확인)                    │
│ - BLS 서명 집약                                             │
│ - L1 FastWithdrawal.executeWithdrawal() 제출               │
│                                                             │
│ 의존성:                                                     │
│ + libp2p (네트워킹)                                         │
│ + BLS 라이브러리 (집약)                                     │
│ + Ethereum client (L1 트랜잭션)                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.4 검증자 인프라 구성

```
Validator 서버:
├── op-node (follower mode)      # L1 batch data 재구성
├── op-geth (archive + debug)    # L2 state 저장
├── rat-client-type3             # RAT 응답 (독립 프로세스)
│   └── 포트: 없음 (L1 이벤트 기반)
└── fw-validator                 # Fast Withdrawal 서명 (독립 프로세스)
    ├── 포트: 9000 (libp2p)
    └── 의존: rat-client-type3의 검증 코드

별도 서버 (또는 동일 서버):
└── fw-aggregator                # Aggregator 서비스
    └── 포트: 9001 (libp2p)
```

**배포 스크립트 예시**:
```bash
# RAT Client 시작
cd clients/rat-client-type3
./bin/rat-client --config config.yaml &

# Fast Withdrawal Validator 시작
cd clients/fast-withdrawal/validator
./bin/fw-validator --config config.yaml &

# Fast Withdrawal Aggregator 시작 (별도 서버 권장)
cd clients/fast-withdrawal/aggregator
./bin/fw-aggregator --config config.yaml &
```

---

## 4. 컴포넌트 설계

### 3.1 Solidity Smart Contracts (✅ 구현 완료)

#### 3.1.1 RAT Storage 수정 (✅ 완료)

**파일**: `src/validator/RATStorage.sol`

**추가된 Storage** (✅ 이미 적용됨):
```solidity
// RATStorage.sol
struct ValidatorRegistration {
    uint256 lockedForRAT;           // DEPRECATED in V3
    uint256 pendingRewards;         // DEPRECATED
    uint64 latestTestDeadline;
    uint32 validatorIndex;
    bool isActive;
    bytes blsPublicKey;             // ✅ ADDED: BLS 공개키 (128 bytes uncompressed)
}

// Fast Withdrawal 관련 설정
uint256 public minValidatorsForFastWithdrawal;  // ✅ ADDED
uint256 public aggregatorFeeRate;                // ✅ ADDED (RAY 단위)
mapping(bytes32 => bool) public processedWithdrawals; // ✅ ADDED
```

**추가 함수**:
```solidity
/**
 * @notice Register validator with BLS public key
 * @param systemConfig L2 system config address
 * @param blsPublicKey BLS public key (48 bytes, G1 point)
 * @param blsProofOfPossession Proof of Possession (96 bytes, prevents rogue key attack)
 */
function registerValidator(
    address systemConfig,
    bytes calldata blsPublicKey,
    bytes calldata blsProofOfPossession
) external ifFree whenNotPaused;

/**
 * @notice Get validator's BLS public key
 * @param validator Validator address
 * @param systemConfig System config address
 * @return BLS public key (48 bytes)
 */
function getValidatorBLSPublicKey(
    address validator,
    address systemConfig
) external view returns (bytes memory);

/**
 * @notice Batch get validators' BLS public keys (gas-efficient)
 * @param validators Array of validator addresses
 * @param systemConfig System config address
 * @return Array of BLS public keys
 */
function getBatchValidatorBLSPublicKeys(
    address[] calldata validators,
    address systemConfig
) external view returns (bytes[] memory);
```

**BLS Proof of Possession 검증**:
```solidity
// 검증자가 BLS 개인키를 실제로 소유하고 있는지 증명
// Rogue Key Attack 방지

function registerValidator(
    address systemConfig,
    bytes calldata blsPublicKey,
    bytes calldata blsProofOfPossession
) external {
    // ... 기존 로직 ...

    // BLS PoP 검증
    bytes32 popMessage = keccak256(abi.encodePacked(
        "BLS_POP",
        block.chainid,
        msg.sender,
        blsPublicKey
    ));

    require(
        BLS12381.verifySignature(
            popMessage,
            blsProofOfPossession,
            BLS12381.parseG1Point(blsPublicKey)
        ),
        "Invalid BLS proof of possession"
    );

    // BLS 공개키 저장
    validatorRegistrations[systemConfig][msg.sender].blsPublicKey = blsPublicKey;

    // ... 기존 등록 로직 ...
}
```

#### 3.1.2 RATFastWithdrawal Contract (✅ 구현 완료)

**파일**: `src/validator/RATFastWithdrawal.sol` (✅ 이미 구현됨)

**주요 특징**:
- **Proxy Selector Routing**: RAT.sol과 함께 동일한 프록시 주소에서 사용
- **RATStorage 상속**: RAT.sol과 동일한 메모리 레이아웃 유지
- **BLS 공개키 관리**: 검증자별 BLS 공개키 등록/조회
- **Fast Withdrawal 검증**: BLS 집계 서명 + Adjacent Leaves 증명

**핵심 함수** (현재 구현):
```solidity
contract RATFastWithdrawal is ProxyStorage, AccessibleCommon, RATStorage {
    using BLS12381 for *;

    // ==========================================
    // State Variables
    // ==========================================

    IRAT public immutable ratContract;
    address public immutable systemConfig;

    uint256 public minValidatorCount;      // 최소 검증자 수 (fast withdrawal 활성화 조건)
    uint256 public minFixedFee;            // 최소 고정 수수료
    uint256 public feeRateBasisPoints;     // 비율 수수료 (10000 = 100%)
    uint256 public aggregatorExtraFeeBps;  // Aggregator 추가 수수료
    uint256 public fastWithdrawalWindow;   // 빠른 출금 시도 기간 (예: 1 hours)

    struct WithdrawalRequest {
        address user;
        uint256 amount;
        uint256 timestamp;
        bool executed;
        uint256 feePaid;
        address feeRecipient;           // Aggregator 주소
        uint256 fastWithdrawalDeadline;
    }

    mapping(bytes32 => WithdrawalRequest) public requests;

    // ==========================================
    // Events
    // ==========================================

    event WithdrawalRequested(
        bytes32 indexed requestId,
        address indexed user,
        uint256 amount,
        uint256 feePaid,
        uint256 deadline,
        uint256 timestamp
    );

    event FastWithdrawalExecuted(
        bytes32 indexed requestId,
        address indexed user,
        uint256 amount,
        uint256 validatorFee,
        uint256 aggregatorFee,
        address aggregator
    );

    event FallbackToRegularWithdrawal(
        bytes32 indexed requestId,
        address indexed user,
        uint256 amount,
        uint256 feeRefunded
    );

    // ==========================================
    // Functions
    // ==========================================

    /**
     * @notice Calculate required fee for fast withdrawal
     * @param amount Withdrawal amount
     * @return Total fee required
     */
    function calculateFee(uint256 amount) public view returns (uint256) {
        uint256 percentageFee = (amount * feeRateBasisPoints) / 10000;
        return percentageFee > minFixedFee ? percentageFee : minFixedFee;
    }

    /**
     * @notice Request fast withdrawal with fee
     * @param amount Amount to withdraw
     * @return requestId Request identifier
     */
    function requestWithdrawal(uint256 amount) external payable returns (bytes32) {
        uint256 requiredFee = calculateFee(amount);
        require(msg.value >= requiredFee, "Insufficient fee");

        bytes32 requestId = keccak256(abi.encodePacked(
            msg.sender,
            amount,
            block.timestamp,
            block.number
        ));

        uint256 deadline = block.timestamp + fastWithdrawalWindow;

        requests[requestId] = WithdrawalRequest({
            user: msg.sender,
            amount: amount,
            timestamp: block.timestamp,
            executed: false,
            feePaid: requiredFee,
            feeRecipient: address(0),
            fastWithdrawalDeadline: deadline
        });

        // 초과 수수료 환불
        if (msg.value > requiredFee) {
            payable(msg.sender).transfer(msg.value - requiredFee);
        }

        emit WithdrawalRequested(
            requestId,
            msg.sender,
            amount,
            requiredFee,
            deadline,
            block.timestamp
        );

        return requestId;
    }

    /**
     * @notice Execute fast withdrawal with aggregated BLS signature
     * @param requestId Withdrawal request ID
     * @param aggregatedSignature Aggregated BLS signature from ALL validators
     * @param validatorBitmap Bitmap indicating which validators signed (must be 100%)
     */
    function executeWithdrawal(
        bytes32 requestId,
        bytes calldata aggregatedSignature,
        uint256 validatorBitmap
    ) external {
        WithdrawalRequest storage request = requests[requestId];
        require(!request.executed, "Already executed");
        require(request.user != address(0), "Request not found");

        // 빠른 출금 마감 시간 확인
        require(
            block.timestamp <= request.fastWithdrawalDeadline,
            "Fast withdrawal deadline passed"
        );

        // RAT에서 활성 검증자 목록 가져오기
        address[] memory validators = ratContract.getL2Validators(systemConfig);
        uint256 validatorCount = validators.length;

        // Fast withdrawal 활성화 조건
        require(
            validatorCount >= minValidatorCount,
            "Insufficient validators"
        );

        // UNANIMOUS CONSENSUS: 모든 검증자 서명 필요 (100%)
        require(
            countSetBits(validatorBitmap) == validatorCount,
            "Unanimous consensus required"
        );

        // 메시지 생성
        bytes32 messageHash = keccak256(abi.encodePacked(
            "TOKAMAK_FAST_WITHDRAWAL",
            requestId,
            request.user,
            request.amount,
            block.chainid
        ));

        // RAT에서 BLS 공개키 일괄 조회
        bytes[] memory blsPubKeys = ratContract.getBatchValidatorBLSPublicKeys(
            validators,
            systemConfig
        );

        // BLS 공개키 집약
        BLS12381.G1Point[] memory pubKeyPoints = new BLS12381.G1Point[](validatorCount);
        for (uint256 i = 0; i < validatorCount; i++) {
            require(
                (validatorBitmap >> i) & 1 == 1,
                "Missing signature"
            );
            require(
                blsPubKeys[i].length == 48,
                "Validator missing BLS key"
            );
            pubKeyPoints[i] = BLS12381.parseG1Point(blsPubKeys[i]);
        }

        BLS12381.G1Point memory aggregatedPubKey = BLS12381.aggregateG1Points(
            pubKeyPoints,
            validatorCount
        );

        // BLS 집약 서명 검증
        require(
            BLS12381.verifySignature(
                messageHash,
                aggregatedSignature,
                aggregatedPubKey
            ),
            "Invalid aggregated signature"
        );

        // 수수료 분배
        uint256 totalFee = request.feePaid;
        uint256 aggregatorFee = (totalFee * aggregatorExtraFeeBps) / 10000;
        uint256 validatorFee = totalFee - aggregatorFee;

        // Aggregator에게 수수료 지급
        request.feeRecipient = msg.sender;
        payable(msg.sender).transfer(aggregatorFee);

        // 검증자들에게 수수료 분배 (균등 분배)
        uint256 feePerValidator = validatorFee / validatorCount;
        for (uint256 i = 0; i < validatorCount; i++) {
            payable(validators[i]).transfer(feePerValidator);
        }

        // 출금 실행
        request.executed = true;
        payable(request.user).transfer(request.amount);

        emit FastWithdrawalExecuted(
            requestId,
            request.user,
            request.amount,
            validatorFee,
            aggregatorFee,
            msg.sender
        );
    }

    /**
     * @notice Fallback to regular withdrawal if fast withdrawal fails
     * @param requestId Withdrawal request ID
     */
    function fallbackToRegularWithdrawal(bytes32 requestId) external {
        WithdrawalRequest storage request = requests[requestId];
        require(!request.executed, "Already executed");
        require(request.user == msg.sender, "Not request owner");

        // 빠른 출금 마감 시간 경과 확인
        require(
            block.timestamp > request.fastWithdrawalDeadline,
            "Fast withdrawal still available"
        );

        // 일반 출금 프로세스 시작 (OptimismPortal 연동)
        // TODO: OptimismPortal.initiateWithdrawal() 호출

        // 수수료 환불
        uint256 feeRefund = request.feePaid;
        request.executed = true;
        payable(msg.sender).transfer(feeRefund);

        emit FallbackToRegularWithdrawal(
            requestId,
            msg.sender,
            request.amount,
            feeRefund
        );
    }

    function countSetBits(uint256 bitmap) internal pure returns (uint256) {
        uint256 count = 0;
        while (bitmap > 0) {
            count += bitmap & 1;
            bitmap >>= 1;
        }
        return count;
    }
}
```

#### 3.1.3 BLS12381 Library

**파일**: `src/libraries/BLS12381.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BLS12381
 * @notice BLS12-381 signature verification library
 * @dev Uses precompiled contracts for BLS operations
 */
library BLS12381 {
    struct G1Point {
        bytes data; // 48 bytes (compressed)
    }

    struct G2Point {
        bytes data; // 96 bytes (compressed)
    }

    /**
     * @notice Parse G1 point from bytes
     */
    function parseG1Point(bytes memory data) internal pure returns (G1Point memory) {
        require(data.length == 48, "Invalid G1 point length");
        return G1Point(data);
    }

    /**
     * @notice Aggregate G1 points (public keys)
     */
    function aggregateG1Points(
        G1Point[] memory points,
        uint256 count
    ) internal view returns (G1Point memory) {
        require(count > 0, "No points to aggregate");

        // BLS12-381 G1 addition precompile (0x0b)
        // TODO: 실제 precompile 주소 및 호출 방식 구현
        bytes memory aggregated = points[0].data;

        for (uint256 i = 1; i < count; i++) {
            // G1 addition: aggregated += points[i]
            aggregated = _g1Add(aggregated, points[i].data);
        }

        return G1Point(aggregated);
    }

    /**
     * @notice Verify BLS signature
     * @param message Message hash (32 bytes)
     * @param signature BLS signature on G2 (96 bytes)
     * @param pubkey BLS public key on G1 (48 bytes)
     * @return Valid signature
     */
    function verifySignature(
        bytes32 message,
        bytes calldata signature,
        G1Point memory pubkey
    ) internal view returns (bool) {
        require(signature.length == 96, "Invalid signature length");

        // BLS12-381 pairing check precompile (0x10)
        // e(pubkey, H(message)) == e(G1, signature)
        // TODO: 실제 precompile 호출 구현

        return _blsPairingCheck(pubkey.data, message, signature);
    }

    // Internal helpers (precompile wrappers)
    function _g1Add(bytes memory a, bytes memory b) private view returns (bytes memory) {
        // TODO: Call BLS12-381 G1 addition precompile
        return a; // Placeholder
    }

    function _blsPairingCheck(
        bytes memory pubkey,
        bytes32 message,
        bytes calldata signature
    ) private view returns (bool) {
        // TODO: Call BLS12-381 pairing check precompile
        return true; // Placeholder
    }
}
```

**참고**: Ethereum은 아직 BLS12-381 precompile을 네이티브로 지원하지 않습니다. 실제 구현 시:
- EIP-2537 precompiles 사용 (테스트넷에서 활성화됨)
- 또는 순수 Solidity BLS 라이브러리 사용 (가스 비용 높음)
- 또는 zkSNARK로 BLS 검증 (권장)

### 3.2 Go Components

#### 3.2.1 libp2p Validator Node

**패키지**: `clients/fast-withdrawal/validator/`

**파일 구조**:
```
clients/fast-withdrawal/validator/
├── cmd/main.go
├── pkg/
│   ├── p2p/
│   │   ├── node.go           # libp2p node setup
│   │   ├── discovery.go      # DHT discovery
│   │   └── pubsub.go         # Pubsub topics
│   ├── handler/
│   │   ├── request.go        # Withdrawal request handler
│   │   └── validator.go      # Request validation
│   ├── signer/
│   │   ├── bls.go            # BLS signing
│   │   └── keystore.go       # Key management
│   └── config/
│       └── config.go
└── README.md
```

**핵심 구현** (`pkg/p2p/node.go`):
```go
package p2p

import (
    "context"
    "github.com/libp2p/go-libp2p"
    dht "github.com/libp2p/go-libp2p-kad-dht"
    pubsub "github.com/libp2p/go-libp2p-pubsub"
    "github.com/libp2p/go-libp2p/core/host"
    "github.com/libp2p/go-libp2p/core/peer"
)

const (
    DHTNamespace         = "/tokamak-rat-validators"
    WithdrawalRequestTopic = "/tokamak/rat/withdrawal/1.0.0"
)

type ValidatorNode struct {
    host            host.Host
    dht             *dht.IpfsDHT
    pubsub          *pubsub.PubSub
    withdrawalTopic *pubsub.Topic
    validatorAddr   common.Address
}

func NewValidatorNode(
    ctx context.Context,
    listenAddr string,
    validatorAddr common.Address,
    bootstrapPeers []multiaddr.Multiaddr,
) (*ValidatorNode, error) {
    // Create libp2p host
    h, err := libp2p.New(
        libp2p.ListenAddrStrings(listenAddr),
    )
    if err != nil {
        return nil, err
    }

    // Setup DHT
    kadDHT, err := dht.New(ctx, h)
    if err != nil {
        return nil, err
    }

    // Bootstrap DHT
    if err := kadDHT.Bootstrap(ctx); err != nil {
        return nil, err
    }

    // Connect to bootstrap peers
    for _, peerAddr := range bootstrapPeers {
        peerInfo, err := peer.AddrInfoFromP2pAddr(peerAddr)
        if err != nil {
            continue
        }
        if err := h.Connect(ctx, *peerInfo); err != nil {
            log.Warn("Failed to connect to bootstrap peer", "peer", peerInfo.ID)
        }
    }

    // Setup pubsub
    ps, err := pubsub.NewGossipSub(ctx, h)
    if err != nil {
        return nil, err
    }

    // Join withdrawal topic
    topic, err := ps.Join(WithdrawalRequestTopic)
    if err != nil {
        return nil, err
    }

    // Advertise in DHT
    routingDiscovery := discovery.NewRoutingDiscovery(kadDHT)
    discovery.Advertise(ctx, routingDiscovery, DHTNamespace)

    return &ValidatorNode{
        host:            h,
        dht:             kadDHT,
        pubsub:          ps,
        withdrawalTopic: topic,
        validatorAddr:   validatorAddr,
    }, nil
}

func (vn *ValidatorNode) SubscribeWithdrawalRequests(
    ctx context.Context,
    handler func(*SignatureRequest) error,
) error {
    sub, err := vn.withdrawalTopic.Subscribe()
    if err != nil {
        return err
    }

    go func() {
        for {
            msg, err := sub.Next(ctx)
            if err != nil {
                log.Error("Failed to read pubsub message", "error", err)
                continue
            }

            // Parse signature request
            var req SignatureRequest
            if err := json.Unmarshal(msg.Data, &req); err != nil {
                log.Error("Failed to unmarshal request", "error", err)
                continue
            }

            // Handle request
            if err := handler(&req); err != nil {
                log.Error("Failed to handle request", "error", err)
            }
        }
    }()

    return nil
}

func (vn *ValidatorNode) PublishSignature(
    ctx context.Context,
    response *SignatureResponse,
) error {
    responseBytes, err := json.Marshal(response)
    if err != nil {
        return err
    }

    return vn.withdrawalTopic.Publish(ctx, responseBytes)
}
```

**BLS Signer** (`pkg/signer/bls.go`):
```go
package signer

import (
    bls "github.com/ethereum/go-ethereum/crypto/bls12381"
)

type BLSSigner struct {
    privateKey *bls.SecretKey
    publicKey  *bls.PublicKey
}

func NewBLSSigner(privateKeyHex string) (*BLSSigner, error) {
    privKeyBytes, err := hex.DecodeString(privateKeyHex)
    if err != nil {
        return nil, err
    }

    privKey, err := bls.SecretKeyFromBytes(privKeyBytes)
    if err != nil {
        return nil, err
    }

    pubKey := bls.PrivateKeyToPublicKey(privKey)

    return &BLSSigner{
        privateKey: privKey,
        publicKey:  pubKey,
    }, nil
}

func (bs *BLSSigner) Sign(message []byte) ([]byte, error) {
    signature := bls.Sign(bs.privateKey, message)
    return bls.SignatureToBytes(signature), nil
}

func (bs *BLSSigner) PublicKey() []byte {
    return bls.PublicKeyToBytes(bs.publicKey)
}

func (bs *BLSSigner) GenerateProofOfPossession(
    validatorAddr common.Address,
    chainID *big.Int,
) ([]byte, error) {
    // PoP 메시지 생성
    popMessage := crypto.Keccak256(
        []byte("BLS_POP"),
        chainID.Bytes(),
        validatorAddr.Bytes(),
        bs.PublicKey(),
    )

    // BLS 서명
    signature := bls.Sign(bs.privateKey, popMessage)
    return bls.SignatureToBytes(signature), nil
}
```

#### 3.2.2 Aggregator Service

**패키지**: `clients/fast-withdrawal/aggregator/`

**파일 구조**:
```
clients/fast-withdrawal/aggregator/
├── cmd/main.go
├── pkg/
│   ├── monitor/
│   │   └── l1_monitor.go     # FastWithdrawal 이벤트 감지
│   ├── p2p/
│   │   ├── network.go        # libp2p network
│   │   └── broadcaster.go    # 서명 요청 브로드캐스트
│   ├── collector/
│   │   ├── signature.go      # 서명 수집
│   │   └── aggregator.go     # BLS 집약
│   ├── submitter/
│   │   └── proof.go          # L1 제출
│   └── config/
│       └── config.go
└── README.md
```

**Signature Collector** (`pkg/collector/signature.go`):
```go
package collector

type SignatureCollector struct {
    mu               sync.RWMutex
    requests         map[[32]byte]*RequestState
    validatorSet     []common.Address
    validatorInfo    map[common.Address]*ValidatorInfo
    l1Client         *ethclient.Client
    ratContract      *contracts.RAT
}

type RequestState struct {
    Request       *SignatureRequest
    Signatures    map[common.Address]*BLSSignature
    RequiredCount uint64  // 100% of validators
    ReceivedCount uint64
    Completed     bool
    SubmittedTxHash common.Hash
}

type ValidatorInfo struct {
    Address   common.Address
    BLSPubKey []byte
    Stake     *big.Int
    Active    bool
}

func (sc *SignatureCollector) RefreshValidatorSet(systemConfig common.Address) error {
    // RAT 컨트랙트에서 활성 검증자 조회
    validators, err := sc.ratContract.GetL2Validators(&bind.CallOpts{}, systemConfig)
    if err != nil {
        return err
    }

    sc.mu.Lock()
    defer sc.mu.Unlock()

    sc.validatorSet = validators

    // BLS 공개키 일괄 조회
    pubKeys, err := sc.ratContract.GetBatchValidatorBLSPublicKeys(&bind.CallOpts{}, validators, systemConfig)
    if err != nil {
        return err
    }

    // Validator info 저장
    for i, validator := range validators {
        sc.validatorInfo[validator] = &ValidatorInfo{
            Address:   validator,
            BLSPubKey: pubKeys[i],
            Active:    true,
        }
    }

    log.Info("Validator set refreshed", "count", len(validators))
    return nil
}

func (sc *SignatureCollector) AddSignature(
    requestId [32]byte,
    validator common.Address,
    signature *BLSSignature,
) error {
    sc.mu.Lock()
    defer sc.mu.Unlock()

    state := sc.requests[requestId]
    if state == nil {
        return errors.New("request not found")
    }

    // 검증자 유효성 확인
    validatorInfo := sc.validatorInfo[validator]
    if validatorInfo == nil || !validatorInfo.Active {
        return errors.New("validator not active")
    }

    // BLS 서명 검증
    message := state.Request.GetSigningMessage()
    if !verifyBLSSignature(validatorInfo.BLSPubKey, message, signature) {
        return errors.New("invalid BLS signature")
    }

    // 서명 추가
    state.Signatures[validator] = signature
    state.ReceivedCount++

    log.Info("Signature collected",
        "requestId", hex.EncodeToString(requestId[:]),
        "validator", validator.Hex(),
        "progress", fmt.Sprintf("%d/%d", state.ReceivedCount, state.RequiredCount))

    // 만장일치 확인 (100%)
    if state.ReceivedCount == state.RequiredCount {
        log.Info("UNANIMOUS consensus reached!",
            "requestId", hex.EncodeToString(requestId[:]),
            "validators", state.RequiredCount)
        state.Completed = true
        return sc.submitAggregatedProof(requestId)
    }

    return nil
}

func (sc *SignatureCollector) submitAggregatedProof(requestId [32]byte) error {
    state := sc.requests[requestId]

    // BLS 서명 집약
    var signatures []*bls.Signature
    for _, validator := range sc.validatorSet {
        sig := state.Signatures[validator]
        if sig != nil {
            blsSig, _ := bls.SignatureFromBytes(sig.Signature)
            signatures = append(signatures, blsSig)
        }
    }

    aggregatedSig := bls.AggregateSignatures(signatures)
    aggregatedSigBytes := bls.SignatureToBytes(aggregatedSig)

    // Bitmap 생성 (모든 비트 1)
    bitmap := new(big.Int)
    for i := 0; i < len(sc.validatorSet); i++ {
        bitmap.SetBit(bitmap, i, 1)
    }

    // L1에 제출
    tx, err := sc.fastWithdrawalContract.ExecuteWithdrawal(
        sc.transactOpts,
        requestId,
        aggregatedSigBytes,
        bitmap,
    )
    if err != nil {
        return err
    }

    state.SubmittedTxHash = tx.Hash()
    log.Info("Aggregated proof submitted", "txHash", tx.Hash().Hex())

    return nil
}
```

---

## 5. 데이터 플로우

### 5.1 사용자 출금 요청 → 즉시 출금 실행

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. 사용자: 즉시 출금 요청                                        │
├─────────────────────────────────────────────────────────────────┤
│ User → FastWithdrawal.requestWithdrawal(amount)                 │
│   - 수수료 지불 (calculateFee(amount))                          │
│   - requestId 생성                                              │
│   - WithdrawalRequested 이벤트 발생                             │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Aggregator: L1 이벤트 감지                                    │
├─────────────────────────────────────────────────────────────────┤
│ Aggregator Monitor:                                             │
│   - WithdrawalRequested 이벤트 구독                             │
│   - requestId, user, amount, deadline 파싱                      │
│   - RAT 컨트랙트에서 validator set 조회                         │
│   - L1BridgeRegistry에서 rollupType 확인 (Type 3)              │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Aggregator: 서명 요청 브로드캐스트                            │
├─────────────────────────────────────────────────────────────────┤
│ libp2p Broadcast:                                               │
│   - Topic: /tokamak/rat/withdrawal/1.0.0                        │
│   - Message: SignatureRequest {                                 │
│       requestId, user, amount, chainId, deadline,               │
│       rollupType: 3,                            ⭐ Type 3       │
│       gameIndex, outputRoot                     ⭐ Type 3 데이터│
│     }                                                            │
│   - 모든 검증자에게 전파 (gossipsub)                            │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼ (libp2p pubsub)
┌─────────────────────────────────────────────────────────────────┐
│ 4. Validator: 서명 요청 수신 및 Type 3 검증 ⭐                   │
├─────────────────────────────────────────────────────────────────┤
│ Validator Node (각 검증자):                                     │
│   1. SignatureRequest 수신                                      │
│                                                                 │
│   2. L1 On-chain 검증:                                          │
│      - FastWithdrawal.requests[requestId] 조회                  │
│      - 요청 존재 여부, deadline, amount 검증                    │
│      - 자신이 활성 검증자인지 확인 (RAT 조회)                   │
│                                                                 │
│   3. ⭐ Type 3 출금 검증 (rat-client-type3 로직 재사용):        │
│      ┌───────────────────────────────────────────────────────┐ │
│      │ Type3Verifier.ValidateWithdrawal()                    │ │
│      │                                                        │ │
│      │ a) DisputeGame 상태 확인:                              │ │
│      │    - game.Status == RESOLVED                          │ │
│      │    - game.RootClaim == req.OutputRoot                 │ │
│      │                                                        │ │
│      │ b) OutputRootProof 검증 (⭐ RAT Client 재사용):        │ │
│      │    outputRootVerifier.VerifyOutputRoot(               │ │
│      │        blockNumber, outputRoot                         │ │
│      │    )                                                   │ │
│      │    - L2 block header 조회                             │ │
│      │    - MessagePasser storage root 검증                  │ │
│      │    - OpNode 또는 L2 RPC로 검증                        │ │
│      │                                                        │ │
│      │ c) L2 출금 트랜잭션 존재 확인 (⭐ RAT Client 재사용):  │ │
│      │    - L2ToL1MessagePasser 조회 (eth_getProof)         │ │
│      │    - Merkle proof 검증 (ratevidence.VerifyProof)     │ │
│      │    - Storage slot 확인                                │ │
│      └───────────────────────────────────────────────────────┘ │
│                                                                 │
│   4. 검증 성공 → BLS 서명 생성:                                 │
│      message = keccak256(                                       │
│        "TOKAMAK_FAST_WITHDRAWAL_TYPE3",          ⭐ Type 3      │
│        requestId, user, amount, chainId,                        │
│        gameIndex, outputRoot                     ⭐ Type 3 데이터│
│      )                                                           │
│      signature = BLS_Sign(privateKey, message)                  │
│                                                                 │
│   5. SignatureResponse 발행:                                    │
│      - Topic: /tokamak/rat/withdrawal/1.0.0                     │
│      - Message: SignatureResponse {                             │
│          requestId, validator, signature, pubKey                │
│        }                                                         │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼ (libp2p pubsub)
┌─────────────────────────────────────────────────────────────────┐
│ 5. Aggregator: 서명 수집                                         │
├─────────────────────────────────────────────────────────────────┤
│ Signature Collector:                                            │
│   - SignatureResponse 수신                                      │
│   - 서명 검증 (오프체인 BLS verify)                             │
│   - Map에 저장: signatures[validator] = signature               │
│   - 진행률 체크: receivedCount / requiredCount                  │
│                                                                 │
│ Unanimous Consensus Check:                                      │
│   - receivedCount == requiredCount (100%)                       │
│   - 모든 검증자 서명 수집 완료                                  │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. Aggregator: BLS 서명 집약                                     │
├─────────────────────────────────────────────────────────────────┤
│ BLS Aggregation:                                                │
│   1. 모든 서명을 G2 point로 변환                                │
│   2. Point addition: aggregatedSig = Σ signatures               │
│   3. Bitmap 생성: 모든 비트 1 (100% 참여)                       │
│   4. AggregatedProof 구성:                                      │
│      - aggregatedSignature (96 bytes)                           │
│      - validatorBitmap (uint256)                                │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. Aggregator: L1 트랜잭션 제출                                  │
├─────────────────────────────────────────────────────────────────┤
│ Proof Submitter:                                                │
│   FastWithdrawal.executeWithdrawal(                             │
│     requestId,                                                  │
│     aggregatedSignature,                                        │
│     validatorBitmap                                             │
│   )                                                             │
│   - Gas price 최적화                                            │
│   - 재시도 로직                                                 │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 8. L1 Contract: 검증 및 출금 실행                                │
├─────────────────────────────────────────────────────────────────┤
│ FastWithdrawal.executeWithdrawal():                             │
│   1. Request 존재 및 미실행 확인                                │
│   2. Deadline 확인 (fastWithdrawalDeadline 이내)                │
│   3. Validator set 조회 (RAT.getL2Validators)                   │
│   4. Validator count 확인 (>= minValidatorCount)                │
│   5. Unanimous consensus 확인 (bitmap == 100%)                  │
│   6. BLS 공개키 조회 (RAT.getBatchValidatorBLSPublicKeys)       │
│   7. BLS 공개키 집약 (aggregateG1Points)                        │
│   8. BLS 서명 검증 (verifySignature)                            │
│   9. 수수료 분배:                                               │
│      - Aggregator: aggregatorExtraFeeBps                        │
│      - Validators: 균등 분배                                    │
│   10. 출금 실행: user.transfer(amount)                          │
│   11. 이벤트: FastWithdrawalExecuted                            │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 9. 사용자: 즉시 출금 완료                                        │
├─────────────────────────────────────────────────────────────────┤
│ User 계정에 amount 수령                                         │
│ 총 소요 시간: ~수분 (L1 블록 생성 시간 + 서명 수집 시간)        │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Type 3 검증 상세 플로우

검증자가 출금 요청을 검증하는 상세 과정 (기존 RAT Client 로직 재사용):

```
┌─────────────────────────────────────────────────────────────────┐
│ Type3Verifier.ValidateWithdrawal(req)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Step 1: DisputeGame 상태 확인                                   │
│ ────────────────────────────────────────                        │
│ game := disputeGameFactory.Games(req.GameIndex)                 │
│ require(game.Status == RESOLVED)                                │
│ require(game.RootClaim == req.OutputRoot)                       │
│                                                                 │
│ Step 2: OutputRootProof 검증 (⭐ rat-client-type3 재사용)       │
│ ────────────────────────────────────────────────────────────    │
│ // 기존 RAT Client의 OutputRootVerifier 사용                   │
│ outputRootProof := outputRootVerifier.VerifyOutputRoot(         │
│     ctx,                                                        │
│     req.BlockNumber,                                            │
│     req.OutputRoot,                                             │
│ )                                                               │
│                                                                 │
│ 내부 동작:                                                      │
│   a) L2 block header 조회 (eth_getBlockByNumber)               │
│      - stateRoot 확인                                           │
│      - blockHash 확인                                           │
│                                                                 │
│   b) L2ToL1MessagePasser storage root 조회                      │
│      - eth_getProof(MessagePasserAddr, [], blockNumber)        │
│      - messagePasserStorageRoot 추출                            │
│                                                                 │
│   c) OutputRoot 계산 및 검증                                    │
│      computedRoot := keccak256(                                 │
│          version,                                               │
│          stateRoot,                                             │
│          messagePasserStorageRoot,                              │
│          blockHash                                              │
│      )                                                           │
│      require(computedRoot == req.OutputRoot)                    │
│                                                                 │
│   d) (선택) OpNode로 추가 검증                                  │
│      opNodeProof := opNodeClient.optimism_outputAtBlock()      │
│      // L1 batch data 기반 trustless 검증                      │
│                                                                 │
│ Step 3: L2 출금 트랜잭션 존재 확인 (⭐ rat-client-type3 재사용) │
│ ────────────────────────────────────────────────────────────    │
│ // Withdrawal hash 계산                                         │
│ withdrawalHash := keccak256(                                    │
│     nonce,                                                      │
│     sender := req.User,                                         │
│     target := L1 recipient,                                     │
│     value := req.Amount,                                        │
│     gasLimit,                                                   │
│     data                                                        │
│ )                                                               │
│                                                                 │
│ // L2 RPC로 storage proof 조회                                 │
│ proof := l2Client.GetProof(                                     │
│     MessagePasserAddr,                                          │
│     [withdrawalHash],                                           │
│     blockNumber                                                 │
│ )                                                               │
│                                                                 │
│ // ⭐ 기존 RAT Client의 Merkle proof 검증 함수 사용             │
│ valid := ratevidence.VerifyStorageProof(                        │
│     proof,                                                      │
│     outputRootProof.MessagePasserStorageRoot,                   │
│ )                                                               │
│ require(valid == true)                                          │
│                                                                 │
│ Step 4: 검증 완료                                               │
│ ────────────────────────────────────────────────────────────    │
│ return nil  // 검증 성공                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**코드 재사용 요약**:

| 검증 단계 | 재사용 컴포넌트 | 파일 |
|----------|---------------|------|
| OutputRootProof 검증 | `OutputRootVerifier` | `rat-client-type3/pkg/verification/output_root.go` |
| OpNode 검증 (선택) | `OpNodeVerifier` | `rat-client-type3/pkg/verification/opnode_verifier.go` |
| Merkle Proof 검증 | `VerifyStorageProof` | `rat-client-type3/pkg/evidence/state_leaf_evidence.go` |
| L2 RPC 조회 | `eth_getProof` wrapper | `rat-client-type3/pkg/l2sync/state_rpc.go` |

### 5.3 Fallback: 일반 출금

만약 Fast Withdrawal이 실패하면 (서명 수집 실패, deadline 경과 등):

```
┌─────────────────────────────────────────────────────────────────┐
│ 사용자: Fallback 호출                                            │
├─────────────────────────────────────────────────────────────────┤
│ FastWithdrawal.fallbackToRegularWithdrawal(requestId)           │
│   - deadline 경과 확인                                          │
│   - OptimismPortal.initiateWithdrawal() 호출                    │
│   - 수수료 환불                                                 │
│   - 일반 출금 프로세스 시작 (7일 challenge period)              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. 보안 및 경제 모델

### 6.0 검증자의 이중 책임

검증자는 두 가지 독립적인 역할을 수행합니다:

```
┌─────────────────────────────────────────────────────────────────┐
│ 검증자 역할 1: RAT 응답 (Liveness 증명)                         │
├─────────────────────────────────────────────────────────────────┤
│ 프로세스: rat-client-type3                                      │
│                                                                 │
│ 트리거: AttentionTestTriggered 이벤트                           │
│ 목적: Full archive node 운영 증명                               │
│ 증명: State Leaf Evidence (Adjacent Leaves)                     │
│ 제출: RAT.submitEvidence()                                      │
│ 페널티: 미제출 시 슬래싱 (C_off)                                │
│                                                                 │
│ 사용 로직:                                                      │
│ ✅ pkg/verification/ - OutputRootProof 검증                    │
│ ✅ pkg/evidence/ - Merkle proof 생성                            │
│ ✅ pkg/l2sync/ - Adjacent leaves 찾기                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 검증자 역할 2: Fast Withdrawal 서명 (추가 서비스)               │
├─────────────────────────────────────────────────────────────────┤
│ 프로세스: fast-withdrawal/validator                             │
│                                                                 │
│ 트리거: WithdrawalRequested 이벤트 (libp2p pubsub)             │
│ 목적: 출금 요청의 유효성 보증                                   │
│ 증명: BLS 서명                                                  │
│ 제출: libp2p pubsub (Aggregator가 집약하여 L1 제출)            │
│ 인센티브: Fast Withdrawal 수수료 분배 (참여 선택)               │
│                                                                 │
│ 재사용 로직 (rat-client-type3에서):                             │
│ ✅ pkg/verification/ - OutputRootProof 검증 (동일)             │
│ ✅ pkg/evidence/ - Merkle proof 검증 (동일)                     │
│ ✅ pkg/l2sync/ - L2 state 조회 (동일)                          │
│                                                                 │
│ + 추가 기능:                                                    │
│ 🆕 libp2p 네트워킹                                              │
│ 🆕 BLS 서명 생성                                                │
└─────────────────────────────────────────────────────────────────┘
```

**독립성**:
- RAT 응답과 Fast Withdrawal 서명은 **독립적**
- Fast Withdrawal 참여는 **선택 사항** (추가 수익 기회)
- 한쪽이 실패해도 다른 쪽에 영향 없음

**검증 로직 일관성**:
- 두 역할 모두 동일한 L2 state 검증 로직 사용
- 코드 재사용으로 일관성 보장
- 유지보수 간소화

---

### 6.1 보안 고려사항

#### 6.1.1 BLS Proof of Possession

**목적**: Rogue Key Attack 방지

**메커니즘**:
- 검증자 등록 시 BLS 개인키 소유 증명 필수
- PoP = BLS_Sign(privateKey, keccak256("BLS_POP", chainId, validatorAddress, publicKey))
- 온체인에서 암호학적 검증

**효과**:
- 타인의 BLS 공개키 도용 불가능
- 검증자가 실제로 BLS 개인키를 보유해야만 등록 가능

#### 6.1.2 Unanimous Consensus (만장일치)

**이유**:
```
검증자 수가 적은 경우 (예: 3명):
- 2/3 다수결 방식: 2명만 공모하면 부정 출금 가능
- 만장일치 방식: 1명이라도 거부하면 실패 → 보안성 극대화

경제적 인센티브:
- 모든 검증자가 수수료 받음 → 참여 동기 높음
- 부정 출금 시도 시 1명이라도 거부 → 자신의 평판 및 담보금 보호
```

**트레이드오프**:
- 장점: 최대 보안성, 단순한 구현
- 단점: 1명의 오프라인 검증자가 있으면 Fast Withdrawal 실패
- 완화: Fallback to regular withdrawal

#### 6.1.3 Validator Liveness

**문제**: 검증자가 오프라인이면 Fast Withdrawal 실패

**해결책**:
1. **최소 검증자 수 요구** (`minValidatorCount`):
   - Fast Withdrawal 활성화 조건
   - 예: minValidatorCount = 5
   - 검증자 < 5명이면 Fast Withdrawal 비활성화

2. **Fallback 메커니즘**:
   - Fast withdrawal deadline (예: 1시간)
   - Deadline 경과 후 일반 출금으로 전환
   - 수수료 환불

3. **검증자 인센티브**:
   - Fast Withdrawal 수수료 분배
   - 오프라인 시 수수료 손실 → Liveness 유지 동기

#### 6.1.4 libp2p Network Security

**DHT Sybil Attack**:
- 공격자가 대량의 peer 생성하여 네트워크 교란
- **완화**: Validator PeerID를 L1 주소 기반으로 생성 → L1에서 검증 가능

**Message Flooding**:
- 공격자가 대량의 invalid 서명 요청 전송
- **완화**: Aggregator가 L1 이벤트 기반으로만 요청 생성 → Validator가 on-chain 검증

**Eclipse Attack**:
- 공격자가 검증자를 네트워크에서 고립
- **완화**: Multiple bootstrap nodes, DHT discovery

### 6.2 경제 모델

#### 6.2.1 수수료 구조

**고정 수수료 vs 비율 수수료**:
```solidity
function calculateFee(uint256 amount) public view returns (uint256) {
    uint256 percentageFee = (amount * feeRateBasisPoints) / 10000;
    return percentageFee > minFixedFee ? percentageFee : minFixedFee;
}
```

**예시**:
- `minFixedFee = 0.001 ETH` (최소 고정비)
- `feeRateBasisPoints = 50` (0.5%)
- `aggregatorExtraFeeBps = 20` (0.2%)

| 출금 금액 | 비율 수수료 (0.5%) | 실제 수수료 | Aggregator 몫 (0.2%) | Validator 총합 |
|-----------|-------------------|-------------|---------------------|---------------|
| 0.1 ETH   | 0.0005 ETH        | 0.001 ETH   | 0.0002 ETH          | 0.0008 ETH    |
| 1 ETH     | 0.005 ETH         | 0.005 ETH   | 0.001 ETH           | 0.004 ETH     |
| 10 ETH    | 0.05 ETH          | 0.05 ETH    | 0.01 ETH            | 0.04 ETH      |

#### 6.2.2 Validator 수익

**수익원**:
1. **RAT 보상**: α·S_i / |V_i| (기존 시뇨리지)
2. **Fast Withdrawal 수수료**: Fee / validatorCount (신규)

**예상 수익 (가정)**:
- L2 검증자 5명
- Fast withdrawal 수수료: 0.005 ETH/tx
- 일 100건 → 검증자당 0.1 ETH/day 추가 수입
- 월 3 ETH 추가 (ETH $3000 가정: $9000/월)

**ROI 개선**:
- 기존: RAT 보상만
- 추가: Fast withdrawal 수수료 → 검증자 참여 동기 증가

#### 6.2.3 Aggregator 수익

**수익원**:
- `aggregatorExtraFeeBps` (예: 0.2%)
- 일 100건 × 0.001 ETH = 0.1 ETH/day
- 월 3 ETH

**비용**:
- L1 가스비 (executeWithdrawal 호출)
- 인프라 비용 (서버, 네트워크)

**경쟁 시장**:
- 여러 Aggregator 운영 가능
- 수수료 경쟁 → 사용자 이익

---

## 7. 구현 로드맵

### Phase 1: 기반 구축 (2-3주) ✅ 완료

**Week 1-2: Smart Contract 개발** ✅
- [x] `RAT.sol` 수정: BLS 공개키 등록 기능
- [x] `BLS12381.sol` 라이브러리 구현 (EIP-2537 precompiles)
- [x] `RATFastWithdrawal.sol` 컨트랙트 구현
- [x] Unit tests (Foundry) - 43개 테스트 통과

**Week 3: Go libp2p 기반 구축** ✅
- [x] libp2p Validator Node 구조 설계
- [x] BLS Signer 구현 (herumi/bls-eth-go-binary)
- [x] p2p network 기본 설정 (DHT, pubsub)

### Phase 2: 핵심 기능 구현 (3-4주) ✅ 완료

**Week 4-5: Validator Node 완성** ✅
- [x] Withdrawal request handler
- [x] On-chain validation (Type3Verifier)
- [x] Signature generation and publishing
- [x] config.example.yaml, 빌드 바이너리 46MB

**Week 6-7: Aggregator Service 완성** ✅
- [x] L1 event monitor (ABI decoding)
- [x] Signature request broadcaster
- [x] Signature collector (off-chain BLS 검증)
- [x] BLS aggregation (*big.Int bitmap - 무제한 검증자)
- [x] Proof submitter (ABI encoding)
- [x] L2ProofProvider (OutputRootProof, WithdrawalProof)
- [x] config.example.yaml, 빌드 바이너리 47MB

### Phase 3: 통합 및 테스트 (2-3주) 🚧 다음 단계

**Week 8-9: End-to-End Integration**
- [ ] Local testnet 배포 (Anvil)
- [ ] Validator + Aggregator 통합 테스트
- [ ] Fast withdrawal 플로우 검증
- [ ] Fallback 메커니즘 테스트

**Week 10: Security Audit Prep**
- [ ] Code review
- [ ] Security checklist
- [ ] Gas optimization
- [ ] Documentation

### Phase 4: Public Testnet 배포 (2주)

**Week 11-12: Sepolia 배포**
- [ ] Smart contracts 배포
- [ ] Validator nodes 실행 (3-5개)
- [ ] Aggregator 실행
- [ ] Public testing
- [ ] Bug fixes

### Phase 5: Mainnet 준비 (2-3주)

**Week 13-14: Audit & Optimization**
- [ ] External security audit
- [ ] Gas optimization final pass
- [ ] Economic parameter tuning

**Week 15: Mainnet Launch**
- [ ] Mainnet deployment
- [ ] Validator onboarding
- [ ] Monitoring dashboard
- [ ] Documentation & guides

---

## 부록

### A. 설정 파일 예시

#### A.1 Validator Config

```yaml
# validator-config.yaml
validator:
  address: "0x..."
  private_key_path: "/secure/validator-key.json"
  bls_private_key_path: "/secure/bls-key.json"

l1:
  rpc_url: "https://eth-mainnet.alchemyapi.io/v2/..."
  rat_contract: "0x..."

l2:
  rpc_url: "http://localhost:8545"  # Self-hosted op-geth

libp2p:
  listen_addr: "/ip4/0.0.0.0/tcp/9000"
  bootstrap_peers:
    - "/ip4/1.2.3.4/tcp/9000/p2p/12D3KooW..."
    - "/ip4/5.6.7.8/tcp/9000/p2p/12D3KooX..."

fast_withdrawal:
  enabled: true
  max_request_age: "1h"
  signature_timeout: "30s"

logging:
  level: "info"
  format: "json"
```

#### A.2 Aggregator Config

```yaml
# aggregator-config.yaml
aggregator:
  private_key_path: "/secure/aggregator-key.json"

l1:
  rpc_url: "https://eth-mainnet.alchemyapi.io/v2/..."
  fast_withdrawal_contract: "0x..."
  rat_contract: "0x..."

libp2p:
  listen_addr: "/ip4/0.0.0.0/tcp/9001"
  bootstrap_peers:
    - "/ip4/1.2.3.4/tcp/9000/p2p/12D3KooW..."

collection:
  unanimous_required: true
  timeout: "5m"
  max_concurrent_requests: 100

submission:
  max_gas_price: "100 gwei"
  gas_limit: 500000
  retry_count: 3

logging:
  level: "info"
  format: "json"
```

### B. 성능 지표

**Fast Withdrawal 시간**:
- 서명 수집: 10-30초 (네트워크 latency)
- BLS 집약: <1초
- L1 트랜잭션 확인: ~12초 (1 block)
- **총 시간: 1-2분**

**Gas 비용 (예상)**:
- `executeWithdrawal()`: ~300,000 gas
  - BLS 검증: ~150,000 gas
  - Storage 업데이트: ~50,000 gas
  - Token transfer: ~50,000 gas
  - 기타: ~50,000 gas
- ETH 가격 $3000, Gas 30 gwei 가정: ~$27

**확장성**:
- Validator 수: 10-50명 권장
- 동시 withdrawal: 제한 없음 (독립적 처리)
- libp2p 네트워크: 수천 노드 지원

### C. 참고 자료

**기술 스택**:
- Solidity: ^0.8.20
- Go: 1.21+
- libp2p: go-libp2p v0.32+
- BLS: go-ethereum/crypto/bls12381

**외부 참조**:
- [EIP-2537: BLS12-381 Precompiles](https://eips.ethereum.org/EIPS/eip-2537)
- [libp2p Specs](https://github.com/libp2p/specs)
- [Optimism Output Root](https://github.com/ethereum-optimism/specs)
- [TON Staking V3 Specs](./01-system-overview.md)

---
