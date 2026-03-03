# 6. API 명세 요약

[← 목차로 돌아가기](./README.md) | [← 이전: 데이터 구조](./05-data-structure.md)

---

## 6.1 LotteryCandidate 함수 명세

### 사용자 함수 (누구나 호출 가능)

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `depositTON` | `uint256 tonAmount` | `bool` | TON 예치 (사전 approve 필요) |
| `depositWTON` | `uint256 wtonAmount` | `bool` | WTON 예치 (사전 approve 필요) |
| `onApprove` | `address owner, address spender, uint256 amount, bytes data` | `bool` | TON의 `approveAndCall` 콜백 (예치 자동 처리) |
| `enterLottery` | - | `bool` | 현재 라운드 복권 참가 (잔액에서 참가비 차감) |
| `requestWithdrawal` | `uint256 amount` | `bool` | 출금 요청 (WTON 단위, 27 decimals) |
| `processWithdrawal` | `uint256 n` | `bool` | n개의 대기 중인 출금 요청 처리 |
| `updateSeigniorage` | - | `bool` | 시뇨리지 업데이트 및 전체 예치자에게 분배 |

### 오퍼레이터 전용 함수 (`onlyOperator`)

> 오퍼레이터 = `candidate` 주소 (초기화 시 설정된 운영자)

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `drawWinner` | - | `address winner` | 현재 라운드 당첨자 추첨, 라운드 진행 |
| `setEntryFee` | `uint256 _entryFee` | - | 다음 라운드부터 적용될 참가비 설정 |
| `changeMember` | `uint256 _memberIndex` | `bool` | DAO 위원회 멤버 슬롯 도전 |
| `retireMember` | - | `bool` | DAO 위원회 은퇴 (블랙리스트 등록) |
| `castVote` | `uint256 _agendaID, uint256 _vote, string _comment` | - | 안건 투표 (0=기권, 1=찬성, 2=반대) |
| `claimActivityReward` | - | - | DAO 활동 보상 WTON 청구 |

### 관리자 전용 함수 (`onlyOwner`)

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `initialize` | `address _candidate, bool _isLayer2Candidate, string _memo, address _committee, address _seigManager, address _depositManager, address _ton, address _wton, uint256 _entryFee` | - | 초기화 (1회만 호출 가능) |
| `setSeigManager` | `address _seigManager` | - | SeigManager 주소 변경 |
| `setCommittee` | `address _committee` | - | Committee 주소 변경 |
| `setDepositManager` | `address _depositManager` | - | DepositManager 주소 변경 |
| `setTon` | `address _ton` | - | TON 토큰 주소 변경 |
| `setWton` | `address _wton` | - | WTON 토큰 주소 변경 |
| `setMemo` | `string _memo` | - | 메모 변경 |

### 읽기 전용 함수 (View)

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `balanceOf` | `address account` | `uint256` | 사용자 내부 WTON 잔액 (27 decimals) |
| `totalStaked` | - | `uint256` | Coinage 총 공급량 |
| `totalDeposited` | - | `uint256` | 전체 내부 예치 합계 |
| `getDepositors` | - | `address[]` | 전체 예치자 주소 목록 |
| `getDepositorCount` | - | `uint256` | 예치자 수 |
| `getRoundParticipants` | `uint256 round` | `address[]` | 라운드 참가자 주소 목록 |
| `getRoundParticipantCount` | `uint256 round` | `uint256` | 라운드 참가자 수 |
| `roundEntered` | `uint256 round, address account` | `bool` | 특정 계정의 라운드 참가 여부 |
| `roundWinner` | `uint256 round` | `address` | 라운드 당첨자 주소 |
| `roundDrawn` | `uint256 round` | `bool` | 라운드 추첨 완료 여부 |
| `roundPrizePool` | `uint256 round` | `uint256` | 라운드 상금 풀 (WTON, 27 decimals) |
| `currentRound` | - | `uint256` | 현재 라운드 번호 |
| `entryFee` | - | `uint256` | 현재 참가비 (WTON, 27 decimals) |
| `candidate` | - | `address` | 오퍼레이터 주소 |
| `operator` | - | `address` | `address(this)` 반환 (ILayer2) |
| `isLayer2` | - | `bool` | 항상 `true` (ILayer2) |
| `isCandidateContract` | - | `bool` | 항상 `true` |

---

## 6.2 이벤트 명세

| 이벤트 | 파라미터 | 발생 시점 |
|--------|----------|----------|
| `Deposited` | `address indexed account, uint256 amount` | 예치 완료 시 |
| `LotteryEntered` | `uint256 indexed round, address indexed account, uint256 entryFee` | 복권 참가 시 |
| `LotteryWinnerDrawn` | `uint256 indexed round, address indexed winner, uint256 prizeAmount` | 당첨자 추첨 시 |
| `SeigniorageReceived` | `uint256 amount` | 시뇨리지 수신 시 |
| `SeigniorageDistributed` | `uint256 totalAmount, uint256 depositorCount` | 시뇨리지 분배 완료 시 |
| `WithdrawalRequested` | `address indexed account, uint256 amount, uint256 requestIndex` | 출금 요청 시 |
| `WithdrawalProcessed` | `address indexed account, uint256 amount, uint256 requestIndex` | 출금 처리 완료 시 |
| `EntryFeeUpdated` | `uint256 newEntryFee, uint256 effectiveFromRound` | 참가비 변경 설정 시 |
| `TonUpdated` | `address ton` | TON 주소 변경 시 |
| `WtonUpdated` | `address wton` | WTON 주소 변경 시 |
| `DepositManagerUpdated` | `address depositManager` | DepositManager 주소 변경 시 |

---

## 6.3 DAOCommittee_V1 LotteryCandidate 관련 함수

| 함수 | 접근 제어 | 설명 |
|------|----------|------|
| `createLotteryCandidate(string memo)` | 누구나 | LotteryCandidate 생성 (Factory를 통해 프록시 배포 + 초기화) |
| `changeMember(uint256 _memberIndex)` | 후보 컨트랙트만 | 기존 멤버보다 높은 스테이킹으로 위원회 멤버 교체 |
| `retireMember()` | 멤버 컨트랙트만 | 위원회 은퇴 (블랙리스트에 자동 등록) |
| `castVote(uint256 _agendaID, uint256 _vote, string _comment)` | 멤버 컨트랙트만 | 안건 투표 |
| `claimActivityReward(address _receiver)` | 멤버 컨트랙트만 | 활동 보상 WTON 청구 (DAO Vault에서 지급) |

---

## 6.4 프론트엔드 ABI 커버리지

**파일:** `demo-frontend/src/contracts/abi.ts`

프론트엔드에 정의된 ABI 함수와 실제 사용 여부:

| 함수 | ABI 정의 | UI 구현 |
|------|---------|---------|
| `depositTON` | O | O (`DepositForm.tsx`) |
| `depositWTON` | O | X (ABI만 존재) |
| `enterLottery` | O | O (`LotteryActions.tsx`) |
| `drawWinner` | O | O (`LotteryActions.tsx`) |
| `updateSeigniorage` | O | O (`SeignioragePanel.tsx`) |
| `requestWithdrawal` | O | **X (UI 미구현)** |
| `processWithdrawal` | O | **X (UI 미구현)** |
| `setEntryFee` | O | X (ABI만 존재) |
| `balanceOf` | O | O (여러 컴포넌트) |
| `totalDeposited` | O | O |
| `currentRound` | O | O |
| `entryFee` | O | O |
| 기타 View 함수들 | O | O |

---

[다음: 배포 및 운영 →](./07-deployment-operations.md)
