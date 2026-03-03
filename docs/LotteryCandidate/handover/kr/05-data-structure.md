# 5. 데이터 구조

[← 목차로 돌아가기](./README.md) | [← 이전: 핵심 비즈니스 로직](./04-business-logic.md)

---

## 5.1 스토리지 스키마 (LotteryCandidateStorage)

**파일:** `src/dao/LotteryCandidateStorage.sol`

### 프록시 스토리지 (ProxyStorage에서 상속)

| 변수명 | 타입 | 설명 |
|--------|------|------|
| `pauseProxy` | `bool` | 프록시 일시정지 플래그 |
| `proxyImplementation` | `mapping(uint256 => address)` | 인덱스별 구현체 주소 |
| `aliveImplementation` | `mapping(address => bool)` | 구현체 활성 상태 |
| `selectorImplementation` | `mapping(bytes4 => address)` | 함수 셀렉터별 구현체 라우팅 |

### 후보 기본 정보

| 변수명 | 타입 | 설명 |
|--------|------|------|
| `_supportedInterfaces` | `mapping(bytes4 => bool)` | ERC165 인터페이스 지원 맵 |
| `isLayer2Candidate` | `bool` | Layer2 후보 여부 |
| `candidate` | `address` | 오퍼레이터 주소 |
| `memo` | `string` | 후보 설명/메모 |
| `committee` | `address` | DAOCommitteeProxy 주소 |
| `seigManager` | `address` | SeigManager 주소 |

### 외부 연동 주소

| 변수명 | 타입 | 설명 |
|--------|------|------|
| `depositManager` | `address` | DepositManager 컨트랙트 주소 |
| `ton` | `address` | TON 토큰 컨트랙트 주소 |
| `wton` | `address` | WTON 토큰 컨트랙트 주소 |

### 내부 잔액 추적

| 변수명 | 타입 | 단위 | 설명 |
|--------|------|------|------|
| `_balances` | `mapping(address => uint256)` | WTON (27 decimals) | 사용자별 내부 잔액 |
| `totalDeposited` | `uint256` | WTON (27 decimals) | 전체 예치 합계 (`_balances`의 총합) |
| `_depositors` | `address[]` | - | 예치자 주소 목록 (삭제 안 됨) |
| `_isDepositor` | `mapping(address => bool)` | - | 예치자 등록 여부 |

### 복권 시스템

| 변수명 | 타입 | 단위 | 설명 |
|--------|------|------|------|
| `currentRound` | `uint256` | - | 현재 복권 라운드 번호 |
| `_roundParticipants` | `mapping(uint256 => address[])` | - | 라운드별 참가자 주소 배열 |
| `_roundEntered` | `mapping(uint256 => mapping(address => bool))` | - | 라운드별 참가 여부 |
| `_roundWinner` | `mapping(uint256 => address)` | - | 라운드별 당첨자 주소 |
| `_roundDrawn` | `mapping(uint256 => bool)` | - | 라운드별 추첨 완료 여부 |
| `entryFee` | `uint256` | WTON (27 decimals) | 현재 라운드 참가비 |
| `pendingEntryFee` | `uint256` | WTON (27 decimals) | 다음 라운드에 적용될 참가비 |
| `hasPendingEntryFee` | `bool` | - | 대기 중인 참가비 존재 여부 |
| `_roundPrizePool` | `mapping(uint256 => uint256)` | WTON (27 decimals) | 라운드별 누적 상금 풀 |

### 출금 관리

| 변수명 | 타입 | 설명 |
|--------|------|------|
| `withdrawalRequests` | `WithdrawalRequest[]` | 출금 요청 큐 (FIFO) |
| `lastProcessedRequestIndex` | `uint256` | 마지막으로 처리된 요청의 인덱스 |

### 시뇨리지 추적

| 변수명 | 타입 | 단위 | 설명 |
|--------|------|------|------|
| `lastCoinageTotalSupply` | `uint256` | WTON (27 decimals) | 마지막 기록된 Coinage 총 공급량 |

---

## 5.2 WithdrawalRequest 구조체

```solidity
struct WithdrawalRequest {
    address user;           // 출금 요청자 주소
    uint256 amount;         // 출금 금액 (WTON, 27 decimals)
    uint256 requestBlock;   // 요청이 생성된 블록 번호
    bool processed;         // 처리 완료 여부
}
```

---

## 5.3 DAOCommittee 스토리지 (LotteryCandidate 관련)

**파일:** `src/dao/StorageStateCommitteeV2.sol`

| 변수명 | 타입 | 설명 |
|--------|------|------|
| `lotteryCandidateFactory` | `address` | LotteryCandidateFactory 컨트랙트 주소 |
| `blacklist` | `mapping(address => bool)` | 블랙리스트된 후보 컨트랙트 |
| `cooldown` | `mapping(address => uint256)` | 후보별 쿨다운 타임스탬프 |
| `cooldownTime` | `uint256` | 쿨다운 기간 (초 단위) |

**파일:** `src/dao/StorageStateCommittee.sol`

| 변수명 | 타입 | 설명 |
|--------|------|------|
| `candidates` | `address[]` | 전체 등록된 후보 주소 배열 |
| `members` | `address[]` | 현재 위원회 멤버 배열 (슬롯별) |
| `maxMember` | `uint256` | 최대 위원회 멤버 수 |
| `_candidateInfos` | `mapping(address => CandidateInfo)` | 후보별 상세 정보 |
| `activityRewardPerSecond` | `uint256` | 초당 활동 보상 (WTON) |

---

## 5.4 상태 관리 방식

### 온체인 상태
- 모든 상태는 이더리움 L1 블록체인에 저장
- 프록시 패턴으로 구현체 업그레이드 가능 (스토리지 레이아웃 보존 필수)

### 잔액 이중 추적 구조

```
┌──────────────────────────────┐
│ DepositManager               │
│  └── Coinage Token           │  ← 실제 자산 (LotteryCandidate 명의)
│       totalSupply = 전체 풀   │
└──────────────────────────────┘
              ▲
              │ 1:1 대응 (타이밍에 따라 일시적 불일치 가능)
              ▼
┌──────────────────────────────┐
│ LotteryCandidate             │
│  _balances[userA] = 100e27   │  ← 내부 장부 (개별 사용자 지분)
│  _balances[userB] = 200e27   │
│  totalDeposited   = 300e27   │
└──────────────────────────────┘
```

### 프론트엔드 캐싱
- TanStack React Query가 온체인 데이터 캐싱 담당
- `useReadContracts` 훅으로 배치 읽기(multicall)
- 수동 `refetch()` 버튼으로 최신 데이터 갱신

---

## 5.5 프록시 스토리지 레이아웃 주의사항

```
슬롯 순서:
  ProxyStorage 변수들
  └── AccessibleCommon 변수들 (AccessControl 포함)
      └── LotteryCandidateStorage 변수들
```

> **중요:** 업그레이드 시 기존 변수 사이에 새 변수를 삽입하면 안 된다.
> 새 변수는 반드시 `LotteryCandidateStorage` 파일의 **맨 아래**에 추가해야 한다.
> 그렇지 않으면 스토리지 슬롯이 밀려서 기존 데이터가 손상된다.

---

[다음: API 명세 →](./06-api-specification.md)
