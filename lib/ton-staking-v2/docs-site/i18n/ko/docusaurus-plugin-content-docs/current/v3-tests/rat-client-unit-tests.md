---
id: rat-client-unit-tests
title: RAT Client 유닛 테스트
sidebar_position: 6
---

# RAT Client 유닛 테스트 (60개)

RAT Client Go 패키지의 유닛 테스트입니다.

**위치**: `clients/rat-client-type3/pkg/`

## 테스트 패키지 구성

| 카테고리 | 테스트 수 | 파일 | 주요 테스트 |
|---------|---------|------|-----------|
| **Evidence** | 11개 | evidence/state_leaf_test.go | Adjacent leaves 생성, 검증 로직 |
| **L2 Sync** | 32개 | l2sync/syncer_test.go | L2 블록 동기화, OutputRootProof 조회 |
| **Submitter** | 8개 | submitter/adjacent_submitter_test.go | 증거 제출, ABI 인코딩 |
| **Event Monitor** | 9개 | client/event_monitor_test.go | L1 이벤트 구독, 필터링 |

---

## Evidence Package (11개)

### Adjacent Leaves 탐색 알고리즘

**테스트 목표**: State trie에서 divergence를 탐지하는 binary search 알고리즘 검증

| 테스트 | 설명 |
|--------|------|
| TestFindAdjacentLeaves_Basic | 기본 adjacent leaves 탐색 |
| TestFindAdjacentLeaves_BinarySearch | Binary search 알고리즘 정확성 |
| TestFindAdjacentLeaves_EdgeCases | 경계 조건 (첫/마지막 leaf) |
| TestFindAdjacentLeaves_NoMatch | Divergence 없는 경우 |

### Divergence Witness 생성

**테스트 목표**: 두 state root 간 차이를 증명하는 witness 생성

| 테스트 | 설명 |
|--------|------|
| TestGenerateWitness_SingleAccount | 단일 계정 변경 |
| TestGenerateWitness_MultipleAccounts | 다중 계정 변경 |
| TestGenerateWitness_ComplexState | 복잡한 state 변경 |

### OutputRootProof 구조 검증

**테스트 목표**: OutputRootProof 구조 및 계산 검증

| 테스트 | 설명 |
|--------|------|
| TestOutputRootProof_Calculation | OutputRoot 계산 정확성 |
| TestOutputRootProof_Encoding | ABI 인코딩/디코딩 |
| TestOutputRootProof_Components | 각 컴포넌트 검증 (version, stateRoot, messagePasserStorageRoot, blockHash) |

### Merkle Proof 생성

**테스트 목표**: State trie Merkle proof 생성 및 검증

| 테스트 | 설명 |
|--------|------|
| TestMerkleProof_Generation | Merkle proof 생성 |

---

## L2 Sync Package (32개)

### L2 블록 헤더 조회

**테스트 목표**: L2 geth로부터 블록 헤더 조회

| 테스트 | 설명 |
|--------|------|
| TestSyncer_GetBlockHeader_Latest | 최신 블록 조회 |
| TestSyncer_GetBlockHeader_ByNumber | 특정 블록 번호 조회 |
| TestSyncer_GetBlockHeader_ByHash | 블록 해시로 조회 |
| TestSyncer_GetBlockHeader_NotFound | 존재하지 않는 블록 |
| TestSyncer_GetBlockHeader_Retry | 재시도 로직 |

### State Root 추출

**테스트 목표**: 블록 헤더에서 state root 추출

| 테스트 | 설명 |
|--------|------|
| TestSyncer_ExtractStateRoot_Valid | 유효한 state root |
| TestSyncer_ExtractStateRoot_Genesis | Genesis 블록 |
| TestSyncer_ExtractStateRoot_Empty | 빈 블록 |

### MessagePasser Storage Root 계산

**테스트 목표**: L2ToL1MessagePasser 컨트랙트의 storage root 계산

| 테스트 | 설명 |
|--------|------|
| TestSyncer_GetMessagePasserStorageRoot_Basic | 기본 storage root 조회 |
| TestSyncer_GetMessagePasserStorageRoot_EmptyStorage | 빈 storage |
| TestSyncer_GetMessagePasserStorageRoot_MultipleSlots | 다중 슬롯 |
| TestSyncer_GetMessagePasserStorageRoot_CacheHit | 캐시 히트 |

### OutputRootProof 생성

**테스트 목표**: 전체 OutputRootProof 구조 생성

| 테스트 | 설명 |
|--------|------|
| TestSyncer_GenerateOutputRootProof_Valid | 유효한 proof 생성 |
| TestSyncer_GenerateOutputRootProof_Components | 각 필드 검증 |
| TestSyncer_GenerateOutputRootProof_Encoding | ABI 인코딩 |
| TestSyncer_GenerateOutputRootProof_VersionByte | Version 바이트 검증 |

### debug_accountRange API 호출

**테스트 목표**: geth debug API로 state trie 조회

| 테스트 | 설명 |
|--------|------|
| TestSyncer_DebugAccountRange_Basic | 기본 계정 범위 조회 |
| TestSyncer_DebugAccountRange_Pagination | 페이지네이션 |
| TestSyncer_DebugAccountRange_EmptyRange | 빈 범위 |
| TestSyncer_DebugAccountRange_AllAccounts | 전체 계정 조회 |
| TestSyncer_DebugAccountRange_RLP | RLP 인코딩 검증 |

### eth_getProof API 호출

**테스트 목표**: 표준 JSON-RPC로 Merkle proof 조회

| 테스트 | 설명 |
|--------|------|
| TestSyncer_GetProof_Account | 계정 proof |
| TestSyncer_GetProof_Storage | Storage proof |
| TestSyncer_GetProof_NonExistent | 존재하지 않는 계정 |
| TestSyncer_GetProof_EmptyAccount | 빈 계정 |

### 동기화 및 캐싱

**테스트 목표**: 블록 동기화 및 캐시 관리

| 테스트 | 설명 |
|--------|------|
| TestSyncer_Sync_Basic | 기본 동기화 |
| TestSyncer_Sync_Backfill | 과거 블록 채우기 |
| TestSyncer_Sync_Reorg | Reorg 처리 |
| TestSyncer_Cache_Eviction | 캐시 축출 정책 |
| TestSyncer_Cache_Concurrent | 동시성 제어 |

### 에러 처리

**테스트 목표**: 네트워크 오류 및 재시도 로직

| 테스트 | 설명 |
|--------|------|
| TestSyncer_Error_NetworkFailure | 네트워크 실패 |
| TestSyncer_Error_Timeout | 타임아웃 |
| TestSyncer_Error_InvalidResponse | 잘못된 응답 |
| TestSyncer_Error_RetryExhausted | 재시도 소진 |
| TestSyncer_Error_Recovery | 오류 복구 |

---

## Submitter Package (8개)

### StateLeafEvidence ABI 인코딩

**테스트 목표**: Solidity ABI 호환 인코딩

| 테스트 | 설명 |
|--------|------|
| TestSubmitter_EncodeEvidence_Basic | 기본 증거 인코딩 |
| TestSubmitter_EncodeEvidence_LargeProof | 대형 proof 인코딩 |
| TestSubmitter_EncodeEvidence_EmptyProof | 빈 proof 처리 |

### submitEvidence 트랜잭션 생성

**테스트 목표**: L1 트랜잭션 생성 및 서명

| 테스트 | 설명 |
|--------|------|
| TestSubmitter_SubmitEvidence_Transaction | 트랜잭션 생성 |
| TestSubmitter_SubmitEvidence_Nonce | Nonce 관리 |
| TestSubmitter_SubmitEvidence_GasEstimation | 가스 추정 |

### Gas Estimation

**테스트 목표**: 증거 제출 가스 비용 추정

| 테스트 | 설명 |
|--------|------|
| TestSubmitter_EstimateGas_SmallProof | 작은 proof 가스 |
| TestSubmitter_EstimateGas_LargeProof | 큰 proof 가스 (~277k) |

---

## Event Monitor Package (9개)

### AttentionTestTriggered 이벤트 구독

**테스트 목표**: L1 RAT 이벤트 실시간 구독

| 테스트 | 설명 |
|--------|------|
| TestMonitor_Subscribe_Basic | 기본 구독 |
| TestMonitor_Subscribe_MultipleEvents | 다중 이벤트 |
| TestMonitor_Subscribe_FilterByValidator | 검증자 필터링 |

### 이벤트 필터링

**테스트 목표**: 특정 검증자 주소 필터링

| 테스트 | 설명 |
|--------|------|
| TestMonitor_Filter_ValidatorAddress | 주소 필터 |
| TestMonitor_Filter_L2Address | L2 주소 필터 |
| TestMonitor_Filter_CombinedFilters | 복합 필터 |

### 블록 범위 쿼리

**테스트 목표**: 과거 이벤트 조회

| 테스트 | 설명 |
|--------|------|
| TestMonitor_QueryRange_Historical | 과거 이벤트 |
| TestMonitor_QueryRange_Pagination | 페이지네이션 |

### 재연결 로직

**테스트 목표**: WebSocket 재연결

| 테스트 | 설명 |
|--------|------|
| TestMonitor_Reconnect_AfterDisconnect | 재연결 |

---

## 실행 방법

### 전체 테스트 실행

```bash
cd clients/rat-client-type3
go test ./pkg/...
```

### 패키지별 실행

```bash
# Evidence 패키지
go test ./pkg/evidence/...

# L2 Sync 패키지
go test ./pkg/l2sync/...

# Submitter 패키지
go test ./pkg/submitter/...

# Event Monitor 패키지
go test ./pkg/client/...
```

### 커버리지 측정

```bash
go test -cover ./pkg/...
```

### 상세 로그

```bash
go test -v ./pkg/...
```

---

## 테스트 환경 구성

### Mock 서버

유닛 테스트는 실제 L1/L2 노드 없이 mock 서버 사용:

```go
// L2 geth mock
mockL2 := NewMockL2Client()
mockL2.On("BlockByNumber", ...).Return(...)

// L1 mock
mockL1 := NewMockL1Client()
mockL1.On("FilterLogs", ...).Return(...)
```

### 테스트 데이터

고정된 테스트 데이터 사용:
- 알려진 state root
- 사전 계산된 Merkle proof
- 고정된 블록 헤더

---

## 다음 단계

- [Go E2E 테스트](e2e-tests.md) - op-e2e 통합 테스트
- [V3 모드 테스트](v3-mode-tests.md) - Solidity 테스트
- [테스트 개요로 돌아가기](overview.md)
