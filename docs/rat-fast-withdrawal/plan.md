# Fast Withdrawal 개발 계획서

**작성일**: 2026-02-02
**버전**: 1.2
**상태**: Phase 1-2 완료 (Smart Contracts + Go Clients)
**최종 업데이트**: 2026-02-03

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [개발 범위](#2-개발-범위)
3. [기술 스택](#3-기술-스택)
4. [개발 단계별 계획](#4-개발-단계별-계획)
5. [세부 태스크 목록](#5-세부-태스크-목록)
6. [의존성 및 리스크](#6-의존성-및-리스크)
7. [테스트 전략](#7-테스트-전략)
8. [배포 계획](#8-배포-계획)

---

## 1. 프로젝트 개요

### 1.1 목표

기존 Optimism의 7일 출금 대기 시간을 **수 분 내 즉시 출금**으로 단축하는 Fast Withdrawal 시스템 구현

### 1.2 핵심 메커니즘

```
사용자 출금 요청
       ↓
검증자 전원(100%) BLS 서명
       ↓
Aggregator 서명 집약 & L1 제출
       ↓
즉시 출금 실행 (3-5분)
```

### 1.3 보안 모델

- **만장일치 합의**: 모든 활성 검증자의 BLS 서명 필요
- **1-of-N 정직성**: 1명의 정직한 검증자가 부정 출금 차단
- **Fallback 보장**: 실패 시 자동으로 7일 일반 출금 전환

### 1.4 주요 산출물

| 산출물 | 설명 |
|--------|------|
| `FastWithdrawal.sol` | L1 메인 컨트랙트 |
| `BLS12381.sol` | BLS 서명 검증 라이브러리 |
| `RAT.sol` 수정 | BLS 공개키 등록 기능 추가 |
| `fw-validator` | 검증자용 libp2p 노드 (Go) |
| `fw-aggregator` | 서명 수집/제출 서비스 (Go) |

---

## 2. 개발 범위

### 2.1 In Scope

#### Smart Contracts (Solidity)

| 컨트랙트 | 기능 | 신규/수정 |
|----------|------|----------|
| `FastWithdrawal.sol` | 출금 요청, BLS 검증, 실행, 수수료 분배 | 신규 |
| `BLS12381.sol` | BLS12-381 서명 검증 라이브러리 | 신규 |
| `RAT.sol` | BLS 공개키 등록, PoP 검증 | 수정 |
| `RATStorage.sol` | BLS 공개키 저장 필드 추가 | 수정 |
| `IStakingV3.sol` | Fast Withdrawal 인터페이스 | 신규 |

#### Go Clients

| 컴포넌트 | 위치 | 기능 |
|----------|------|------|
| Validator Node | `clients/fast-withdrawal/validator/` | libp2p + BLS 서명 생성 |
| Aggregator | `clients/fast-withdrawal/aggregator/` | 서명 수집 + L1 제출 |

#### 코드 재사용 (rat-client-type3)

| 컴포넌트 | 재사용 목적 |
|----------|-------------|
| `pkg/verification/output_root.go` | OutputRootProof 검증 |
| `pkg/evidence/state_leaf_evidence.go` | Merkle proof 검증 |
| `pkg/l2sync/state_rpc.go` | L2 state 조회 |

### 2.2 Out of Scope

- OptimismPortal2 직접 수정 (연동만 구현)
- UI/Frontend 개발
- Cross-chain Fast Withdrawal
- 부분 합의 (90%, 95% 등) 지원

---

## 3. 기술 스택

### 3.1 Smart Contracts

| 항목 | 기술 |
|------|------|
| 언어 | Solidity ^0.8.20 |
| 프레임워크 | Foundry |
| 테스트 | Forge Test |
| BLS 라이브러리 | EIP-2537 precompiles 또는 순수 Solidity |

### 3.2 Go Clients

| 항목 | 기술 |
|------|------|
| 언어 | Go 1.22+ |
| P2P | libp2p v0.32+ |
| Pubsub | go-libp2p-pubsub (GossipSub) |
| DHT | go-libp2p-kad-dht |
| BLS | go-ethereum/crypto/bls12381 또는 herumi/bls-eth-go-binary |
| Ethereum | go-ethereum |

### 3.3 인프라

| 항목 | 기술 |
|------|------|
| 로컬 테스트 | Anvil + op-stack devnet |
| 테스트넷 | Sepolia |
| 모니터링 | Prometheus + Grafana |
| 로깅 | Structured JSON logging |

---

## 4. 개발 단계별 계획

### 4.1 전체 일정 (15주) - 현재 진행 상황

```
Phase 1: 기반 구축        [Week 1-3]   ████████✅✅✅ (완료)
  - BLS 라이브러리 ✅
  - RATFastWithdrawal.sol ✅
  - RATFastWithdrawalLib.sol ✅
  - 43개 테스트 통과 ✅

Phase 2: 핵심 기능 구현   [Week 4-7]   ████████✅✅✅✅✅✅✅✅ (완료)
  - Validator Node ✅ (완료 - 빌드 성공)
  - Aggregator ✅ (완료 - 빌드 성공)

Phase 3: 통합 테스트      [Week 8-10]  ░░░░░░░░░░░░░░░░░░░░⬜️⬜️⬜️⬜️ (다음 단계)
Phase 4: 테스트넷 배포    [Week 11-12] ░░░░░░░░░░░░░░░░░░░░░░░░░░⬜️⬜️
Phase 5: 메인넷 준비      [Week 13-15] ░░░░░░░░░░░░░░░░░░░░░░░░░░░░⬜️⬜️
```

**현재 상태** (2026-02-03):
- ✅ Phase 1 완료: Smart Contracts 완전 구현
- ✅ Phase 2 완료: Go Clients (Validator + Aggregator) 완전 구현
- 📍 **다음 작업**: Phase 3 통합 테스트 환경 구축

### Phase 2 완료 내역 (Go Clients)

#### Validator Node (`clients/fast-withdrawal/validator/`)
- **cmd/main.go**: CLI 진입점, 전체 Validator 로직 통합
- **pkg/config/config.go**: YAML 설정 로드 및 검증
- **pkg/p2p/node.go**: libp2p 노드, DHT discovery, GossipSub
- **pkg/signer/bls.go**: herumi/bls-eth-go-binary 기반 BLS 서명
- **pkg/handler/handler.go**: SignatureRequest 검증 및 응답
- **pkg/verifier/**: Type3 검증 (OutputRootProof, DisputeGame)
- **config.example.yaml**: 설정 템플릿
- 빌드 바이너리: 46MB

#### Aggregator (`clients/fast-withdrawal/aggregator/`)
- **cmd/main.go**: CLI 진입점, 전체 Aggregator 로직 통합
- **pkg/config/config.go**: YAML 설정 로드 및 검증
- **pkg/monitor/l1_monitor.go**: L1 이벤트 감시 (ABI decoding)
- **pkg/p2p/network.go**: libp2p 네트워크, SignatureRequest 브로드캐스트
- **pkg/collector/collector.go**: 서명 수집 및 off-chain BLS 검증
- **pkg/collector/aggregator.go**: BLS 서명 집약, *big.Int bitmap (무제한 검증자)
- **pkg/submitter/submitter.go**: L1 트랜잭션 제출 (ABI encoding)
- **pkg/contracts/rat.go**: RAT 컨트랙트 바인딩 (검증자 세트 로드)
- **pkg/l2proof/provider.go**: L2 OutputRootProof, WithdrawalProof 생성
- **pkg/l2proof/types.go**: 증명 타입 정의
- **config.example.yaml**: 설정 템플릿
- 빌드 바이너리: 47MB

#### 주요 개선사항 적용
- ✅ BLS 서명 off-chain 검증 (수집 시점)
- ✅ *big.Int bitmap으로 64명+ 검증자 지원
- ✅ 실제 ABI encoding/decoding
- ✅ RAT 컨트랙트에서 검증자 세트 로드
- ✅ L2ToL1MessagePasser 기반 증명 생성

---

### Phase 1: 기반 구축 (Week 1-3)

#### Week 1: BLS 라이브러리 및 RAT 수정

**목표**: BLS 서명 검증 기반 완성

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 1.1.1 | `BLS12381.sol` 기본 구조 작성 | Contract | 1일 |
| 1.1.2 | G1/G2 Point 파싱 구현 | Contract | 1일 |
| 1.1.3 | BLS 서명 검증 함수 구현 | Contract | 2일 |
| 1.1.4 | 공개키 집약(aggregation) 구현 | Contract | 1일 |
| 1.1.5 | `RATStorage.sol` BLS 필드 추가 | Contract | 0.5일 |
| 1.1.6 | `RAT.sol` registerValidator 수정 (PoP 검증) | Contract | 1일 |
| 1.1.7 | `RAT.sol` BLS 공개키 조회 함수 추가 | Contract | 0.5일 |
| 1.1.8 | BLS 관련 단위 테스트 | Contract | 2일 |

**산출물**:
- `src/libraries/BLS12381.sol`
- `src/validator/RAT.sol` (수정)
- `src/validator/RATStorage.sol` (수정)
- `test/BLS12381.t.sol`

#### Week 2: FastWithdrawal 컨트랙트

**목표**: 메인 컨트랙트 구현

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 1.2.1 | `FastWithdrawal.sol` 기본 구조 | Contract | 0.5일 |
| 1.2.2 | State variables 및 구조체 정의 | Contract | 0.5일 |
| 1.2.3 | `calculateFee()` 구현 | Contract | 0.5일 |
| 1.2.4 | `requestFastWithdrawal()` 구현 | Contract | 1일 |
| 1.2.5 | `executeWithdrawalWithProof()` 구현 | Contract | 2일 |
| 1.2.6 | Validator snapshot 로직 구현 | Contract | 0.5일 |
| 1.2.7 | 수수료 분배 로직 구현 | Contract | 1일 |
| 1.2.8 | 거버넌스 함수 구현 (pause, setters) | Contract | 0.5일 |
| 1.2.9 | FastWithdrawal 단위 테스트 | Contract | 2일 |

**산출물**:
- `src/withdrawal/FastWithdrawal.sol`
- `src/withdrawal/interfaces/IFastWithdrawal.sol`
- `test/FastWithdrawal.t.sol`

#### Week 3: Go 기반 구축

**목표**: libp2p 네트워크 및 BLS 서명 기반

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 1.3.1 | 프로젝트 구조 생성 | Go | 0.5일 |
| 1.3.2 | go.mod 의존성 설정 (rat-client-type3 연결) | Go | 0.5일 |
| 1.3.3 | libp2p 노드 기본 설정 | Go | 1일 |
| 1.3.4 | DHT discovery 구현 | Go | 1일 |
| 1.3.5 | GossipSub pubsub 구현 | Go | 1일 |
| 1.3.6 | BLS 키 생성/로드 구현 | Go | 1일 |
| 1.3.7 | BLS 서명 생성 구현 | Go | 0.5일 |
| 1.3.8 | PoP 생성 함수 구현 | Go | 0.5일 |
| 1.3.9 | 메시지 프로토콜 정의 (protobuf) | Go | 1일 |
| 1.3.10 | libp2p 통합 테스트 | Go | 1일 |

**산출물**:
- `clients/fast-withdrawal/validator/pkg/p2p/`
- `clients/fast-withdrawal/validator/pkg/signer/`
- `clients/fast-withdrawal/proto/messages.proto`

---

### Phase 2: 핵심 기능 구현 (Week 4-7)

#### Week 4-5: Validator Node

**목표**: 출금 요청 검증 및 서명 생성

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 2.1.1 | Config 구조 및 로딩 | Go | 0.5일 |
| 2.1.2 | L1 클라이언트 연결 | Go | 0.5일 |
| 2.1.3 | L2 클라이언트 연결 (op-geth) | Go | 0.5일 |
| 2.1.4 | SignatureRequest 핸들러 구현 | Go | 1일 |
| 2.1.5 | On-chain 요청 검증 로직 | Go | 1일 |
| 2.1.6 | Type3Verifier 구현 (rat-client-type3 재사용) | Go | 2일 |
| 2.1.7 | DisputeGame 상태 확인 로직 | Go | 1일 |
| 2.1.8 | OutputRootProof 검증 연동 | Go | 1일 |
| 2.1.9 | L2 출금 존재 확인 (Merkle proof) | Go | 1일 |
| 2.1.10 | BLS 서명 생성 및 응답 발행 | Go | 0.5일 |
| 2.1.11 | main.go 및 CLI 구현 | Go | 0.5일 |
| 2.1.12 | Validator Node 단위 테스트 | Go | 1일 |

**산출물**: ✅ 완료
- `clients/fast-withdrawal/validator/cmd/main.go` ✅
- `clients/fast-withdrawal/validator/pkg/config/config.go` ✅
- `clients/fast-withdrawal/validator/pkg/p2p/node.go` ✅
- `clients/fast-withdrawal/validator/pkg/signer/bls.go` ✅
- `clients/fast-withdrawal/validator/pkg/handler/handler.go` ✅
- `clients/fast-withdrawal/validator/pkg/verifier/` ✅
- `clients/fast-withdrawal/validator/config.example.yaml` ✅

#### Week 6-7: Aggregator Service

**목표**: 서명 수집 및 L1 제출

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 2.2.1 | Config 구조 및 로딩 | Go | 0.5일 |
| 2.2.2 | L1 이벤트 모니터 구현 | Go | 1일 |
| 2.2.3 | WithdrawalRequested 이벤트 파싱 | Go | 0.5일 |
| 2.2.4 | Validator set 조회 로직 | Go | 0.5일 |
| 2.2.5 | SignatureRequest 브로드캐스터 구현 | Go | 1일 |
| 2.2.6 | SignatureResponse 수신 핸들러 | Go | 1일 |
| 2.2.7 | 서명 검증 (off-chain) | Go | 0.5일 |
| 2.2.8 | 서명 수집 상태 관리 | Go | 1일 |
| 2.2.9 | 만장일치 확인 로직 | Go | 0.5일 |
| 2.2.10 | BLS 서명 집약 구현 | Go | 1일 |
| 2.2.11 | Bitmap 생성 로직 | Go | 0.5일 |
| 2.2.12 | L1 트랜잭션 제출 (executeWithdrawalWithProof) | Go | 1일 |
| 2.2.13 | 가스 가격 최적화 및 재시도 로직 | Go | 0.5일 |
| 2.2.14 | Timeout 및 실패 처리 | Go | 0.5일 |
| 2.2.15 | main.go 및 CLI 구현 | Go | 0.5일 |
| 2.2.16 | Aggregator 단위 테스트 | Go | 1일 |

**산출물**: ✅ 완료
- `clients/fast-withdrawal/aggregator/cmd/main.go` ✅
- `clients/fast-withdrawal/aggregator/pkg/config/config.go` ✅
- `clients/fast-withdrawal/aggregator/pkg/monitor/l1_monitor.go` ✅
- `clients/fast-withdrawal/aggregator/pkg/p2p/network.go` ✅
- `clients/fast-withdrawal/aggregator/pkg/collector/collector.go` ✅
- `clients/fast-withdrawal/aggregator/pkg/collector/aggregator.go` ✅
- `clients/fast-withdrawal/aggregator/pkg/submitter/submitter.go` ✅
- `clients/fast-withdrawal/aggregator/pkg/contracts/rat.go` ✅
- `clients/fast-withdrawal/aggregator/pkg/l2proof/provider.go` ✅
- `clients/fast-withdrawal/aggregator/pkg/l2proof/types.go` ✅
- `clients/fast-withdrawal/aggregator/config.example.yaml` ✅

---

### Phase 3: 통합 테스트 (Week 8-10)

#### Week 8: 로컬 통합 환경

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 3.1.1 | Local devnet 설정 (Anvil + op-stack) | DevOps | 1일 |
| 3.1.2 | 컨트랙트 배포 스크립트 | Contract | 0.5일 |
| 3.1.3 | 검증자 등록 스크립트 (BLS 키 포함) | Go | 0.5일 |
| 3.1.4 | Validator Node 3개 실행 환경 | DevOps | 1일 |
| 3.1.5 | Aggregator 실행 환경 | DevOps | 0.5일 |
| 3.1.6 | Docker Compose 구성 | DevOps | 1일 |

#### Week 9: E2E 테스트 시나리오

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 3.2.1 | Happy path 테스트: 즉시 출금 성공 | QA | 1일 |
| 3.2.2 | 수수료 계산 검증 | QA | 0.5일 |
| 3.2.3 | 수수료 분배 검증 (Aggregator + Validators) | QA | 0.5일 |
| 3.2.4 | Validator snapshot 동작 검증 | QA | 0.5일 |
| 3.2.5 | Fallback 테스트: 응답 기간 초과 | QA | 1일 |
| 3.2.6 | Edge case: 검증자 1명 오프라인 | QA | 0.5일 |
| 3.2.7 | Edge case: 잘못된 BLS 서명 | QA | 0.5일 |
| 3.2.8 | Edge case: 중복 실행 시도 | QA | 0.5일 |
| 3.2.9 | 거버넌스 기능 테스트 (pause, resume) | QA | 0.5일 |
| 3.2.10 | 부하 테스트: 동시 출금 요청 | QA | 1일 |

#### Week 10: 보안 검토 및 최적화

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 3.3.1 | 코드 리뷰 (Smart Contract) | Security | 2일 |
| 3.3.2 | 코드 리뷰 (Go Clients) | Security | 1일 |
| 3.3.3 | Rogue key attack 방지 검증 | Security | 0.5일 |
| 3.3.4 | Replay attack 방지 검증 | Security | 0.5일 |
| 3.3.5 | Gas 최적화 | Contract | 1일 |
| 3.3.6 | 문서 업데이트 | Doc | 1일 |

---

### Phase 4: 테스트넷 배포 (Week 11-12)

#### Week 11: Sepolia 배포

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 4.1.1 | Sepolia 컨트랙트 배포 | Contract | 0.5일 |
| 4.1.2 | 컨트랙트 검증 (Etherscan) | Contract | 0.5일 |
| 4.1.3 | Validator Node 3-5개 배포 | DevOps | 1일 |
| 4.1.4 | Aggregator 배포 | DevOps | 0.5일 |
| 4.1.5 | Bootstrap peer 설정 | DevOps | 0.5일 |
| 4.1.6 | 모니터링 설정 (Prometheus + Grafana) | DevOps | 1일 |
| 4.1.7 | 알림 설정 (PagerDuty/Slack) | DevOps | 0.5일 |

#### Week 12: Public 테스트

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 4.2.1 | 테스트넷 사용자 가이드 작성 | Doc | 1일 |
| 4.2.2 | Faucet 연동 (테스트 토큰) | DevOps | 0.5일 |
| 4.2.3 | Public 테스트 진행 | QA | 3일 |
| 4.2.4 | 버그 수정 | All | 1일 |
| 4.2.5 | 성능 메트릭 수집 및 분석 | DevOps | 0.5일 |

---

### Phase 5: 메인넷 준비 (Week 13-15)

#### Week 13-14: 보안 감사

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 5.1.1 | 외부 감사 업체 선정 | PM | - |
| 5.1.2 | 감사 자료 준비 (문서, 테스트 케이스) | All | 2일 |
| 5.1.3 | 감사 진행 | External | 5-10일 |
| 5.1.4 | 감사 결과 대응 (Critical/High) | Contract | 2-3일 |
| 5.1.5 | 감사 결과 대응 (Medium/Low) | Contract | 1-2일 |

#### Week 15: 메인넷 런칭

| 태스크 | 설명 | 담당 | 예상 시간 |
|--------|------|------|----------|
| 5.2.1 | 경제 파라미터 최종 결정 | PM | 0.5일 |
| 5.2.2 | 메인넷 컨트랙트 배포 | Contract | 0.5일 |
| 5.2.3 | 컨트랙트 검증 및 소유권 설정 | Contract | 0.5일 |
| 5.2.4 | Validator 온보딩 가이드 | Doc | 1일 |
| 5.2.5 | Validator 노드 배포 (파트너) | DevOps | 2일 |
| 5.2.6 | 프로덕션 모니터링 대시보드 | DevOps | 1일 |
| 5.2.7 | 런칭 공지 및 문서 공개 | PM | 0.5일 |

---

## 5. 세부 태스크 목록

### 5.1 Smart Contract 태스크

```
src/
├── libraries/
│   └── BLS12381.sol                    # [P0] BLS 서명 검증
├── withdrawal/
│   ├── FastWithdrawal.sol              # [P0] 메인 컨트랙트
│   └── interfaces/
│       └── IFastWithdrawal.sol         # [P1] 인터페이스
└── validator/
    ├── RAT.sol                         # [P0] BLS 공개키 등록 추가
    └── RATStorage.sol                  # [P0] BLS 필드 추가

test/
├── BLS12381.t.sol                      # [P0] BLS 단위 테스트
├── FastWithdrawal.t.sol                # [P0] FastWithdrawal 테스트
└── integration/
    └── FastWithdrawalE2E.t.sol         # [P1] E2E 테스트

script/
├── DeployFastWithdrawal.s.sol          # [P1] 배포 스크립트
└── RegisterValidatorWithBLS.s.sol      # [P1] 검증자 등록 스크립트
```

### 5.2 Go Client 태스크

```
clients/fast-withdrawal/
├── validator/
│   ├── cmd/
│   │   └── main.go                     # [P0] CLI 진입점
│   ├── pkg/
│   │   ├── config/
│   │   │   └── config.go               # [P0] 설정 관리
│   │   ├── p2p/
│   │   │   ├── node.go                 # [P0] libp2p 노드
│   │   │   ├── discovery.go            # [P0] DHT discovery
│   │   │   └── pubsub.go               # [P0] GossipSub
│   │   ├── signer/
│   │   │   ├── bls.go                  # [P0] BLS 서명
│   │   │   └── keystore.go             # [P0] 키 관리
│   │   ├── handler/
│   │   │   └── handler.go              # [P0] 요청 핸들러
│   │   └── verifier/
│   │       ├── interface.go            # [P0] Verifier 인터페이스
│   │       ├── type3.go                # [P0] Type3 검증 (재사용)
│   │       └── factory.go              # [P1] Verifier 팩토리
│   ├── go.mod
│   ├── config.example.yaml
│   └── README.md
│
└── aggregator/
    ├── cmd/
    │   └── main.go                     # [P0] CLI 진입점
    ├── pkg/
    │   ├── config/
    │   │   └── config.go               # [P0] 설정 관리
    │   ├── monitor/
    │   │   └── l1_monitor.go           # [P0] L1 이벤트 감시
    │   ├── p2p/
    │   │   ├── network.go              # [P0] libp2p 네트워크
    │   │   └── broadcaster.go          # [P0] 브로드캐스터
    │   ├── collector/
    │   │   ├── signature.go            # [P0] 서명 수집
    │   │   └── aggregator.go           # [P0] BLS 집약
    │   └── submitter/
    │       └── proof.go                # [P0] L1 제출
    ├── go.mod
    ├── config.example.yaml
    └── README.md
```

---

## 6. 의존성 및 리스크

### 6.1 기술 의존성

| 의존성 | 설명 | 리스크 | 완화 방안 |
|--------|------|--------|----------|
| EIP-2537 | BLS precompiles | 메인넷 미지원 시 가스 비용 증가 | 순수 Solidity 또는 zkSNARK 대안 |
| rat-client-type3 | 검증 로직 재사용 | API 변경 시 수정 필요 | 버전 고정, 인터페이스 추상화 |
| libp2p | P2P 네트워킹 | 네트워크 불안정 | Bootstrap peer 다중화, 재연결 로직 |
| go-ethereum BLS | Go BLS 라이브러리 | 라이브러리 버그 | herumi/bls-eth-go-binary 대안 |

### 6.2 운영 리스크

| 리스크 | 영향도 | 발생 확률 | 완화 방안 |
|--------|--------|----------|----------|
| 검증자 오프라인 | 높음 | 중간 | Fallback 메커니즘, 검증자 인센티브 |
| BLS 키 분실 | 높음 | 낮음 | 키 백업 가이드, 다중 서명 옵션 (미래) |
| Aggregator 장애 | 중간 | 중간 | 다중 Aggregator 운영, 자동 복구 |
| libp2p 네트워크 분할 | 중간 | 낮음 | 다중 bootstrap, 모니터링 |

### 6.3 보안 리스크

| 리스크 | 영향도 | 완화 방안 |
|--------|--------|----------|
| Rogue key attack | Critical | PoP (Proof of Possession) 필수 |
| Replay attack | High | chainId + nonce 포함 |
| Front-running | Medium | Commit-reveal 검토 (미래) |
| Eclipse attack | Medium | 다중 bootstrap peer |

---

## 7. 테스트 전략

### 7.1 테스트 레벨

```
┌─────────────────────────────────────────────────────────────┐
│ Level 4: Production Monitoring                              │
│ - 실시간 메트릭, 알림, 대시보드                              │
├─────────────────────────────────────────────────────────────┤
│ Level 3: E2E Integration Tests                              │
│ - 전체 시스템 플로우, 시나리오 테스트                        │
├─────────────────────────────────────────────────────────────┤
│ Level 2: Integration Tests                                  │
│ - 컴포넌트 간 상호작용, 컨트랙트-클라이언트 연동            │
├─────────────────────────────────────────────────────────────┤
│ Level 1: Unit Tests                                         │
│ - 개별 함수, 모듈 테스트                                    │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 테스트 시나리오

#### Happy Path
1. 사용자가 Fast Withdrawal 요청 (수수료 지불)
2. Aggregator가 이벤트 감지, 서명 요청 브로드캐스트
3. 모든 Validator가 검증 후 BLS 서명 제공
4. Aggregator가 서명 집약, L1 제출
5. 컨트랙트가 BLS 검증, 출금 실행
6. 수수료가 Aggregator + Validators에게 분배

#### Failure Paths
- 수수료 부족 → 요청 거부
- 검증자 부족 (< minValidatorCount) → 요청 거부
- 1명 이상 서명 미제출 → Timeout 후 Fallback
- 잘못된 BLS 서명 → 트랜잭션 revert
- 중복 실행 → AlreadyExecuted 에러
- 응답 기간 초과 → Fallback to regular withdrawal

### 7.3 테스트 커버리지 목표

| 컴포넌트 | 목표 커버리지 |
|----------|--------------|
| Smart Contracts | > 95% |
| Go Validator | > 80% |
| Go Aggregator | > 80% |
| E2E Scenarios | 100% (정의된 시나리오) |

---

## 8. 배포 계획

### 8.1 배포 환경

| 환경 | 용도 | 인프라 |
|------|------|--------|
| Local | 개발 테스트 | Anvil + Docker |
| Devnet | 통합 테스트 | op-stack devnet |
| Testnet | Public 테스트 | Sepolia |
| Mainnet | 프로덕션 | Ethereum Mainnet |

### 8.2 배포 체크리스트

#### Smart Contract 배포
- [ ] 컨트랙트 컴파일 및 크기 확인
- [ ] 배포 파라미터 검증
- [ ] 테스트넷 배포 및 검증
- [ ] Etherscan 소스 검증
- [ ] 소유권/권한 설정
- [ ] 메인넷 배포

#### Go Client 배포
- [ ] 바이너리 빌드 (linux/amd64)
- [ ] Docker 이미지 빌드
- [ ] 설정 파일 준비
- [ ] BLS 키 생성 및 안전한 저장
- [ ] 검증자 등록 트랜잭션
- [ ] 노드 실행 및 피어 연결 확인

### 8.3 롤백 계획

| 상황 | 롤백 방안 |
|------|----------|
| 컨트랙트 버그 발견 | `pauseFastWithdrawalVerification()` 호출 |
| Go Client 버그 | 이전 버전으로 롤백, 재시작 |
| 경제 파라미터 문제 | 거버넌스로 파라미터 조정 |
| 전체 시스템 장애 | Fallback으로 일반 출금 유도 |

---

## 부록

### A. 설정 파라미터 기본값

```yaml
# FastWithdrawal Contract
minValidatorsForFastWithdrawal: 3        # 테스트넷: 3, 메인넷: 10
fastWithdrawalResponsePeriod: 300        # 5분
minFastWithdrawalFee: 0.01 ether         # 최소 고정 수수료
fastWithdrawalFeeRate: 50                # 0.5% (50 basis points)
submissionFee: 0.005 ether               # Aggregator 가스비 보상
```

### B. 주요 이벤트

```solidity
event WithdrawalRequested(bytes32 indexed requestId, address indexed user, uint256 amount, uint256 timestamp);
event FastWithdrawalExecuted(bytes32 indexed requestId, address indexed user, uint256 amount);
event FastWithdrawalTimeout(bytes32 indexed requestId, address indexed user);
event FastWithdrawalConvertedToRegular(bytes32 indexed requestId, address indexed user);
event FeesDistributed(bytes32 indexed requestId, uint256 totalFee, uint256 validatorCount, uint256 feePerValidator);
event SubmissionFeePaid(bytes32 indexed requestId, address indexed aggregator, uint256 submissionFee);
```

### C. libp2p 토픽 및 메시지

```
Topic: /tokamak/rat/withdrawal/1.0.0

SignatureRequest {
    requestId: bytes32
    user: address
    amount: uint256
    chainId: uint256
    deadline: uint256
    rollupType: uint8
    gameIndex: uint256      // Type 3
    outputRoot: bytes32     // Type 3
}

SignatureResponse {
    requestId: bytes32
    validator: address
    signature: bytes (96 bytes BLS)
    pubKey: bytes (48 bytes)
}
```
