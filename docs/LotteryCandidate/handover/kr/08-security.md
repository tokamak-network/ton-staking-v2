# 8. 보안 고려사항

[← 목차로 돌아가기](./README.md) | [← 이전: 배포 및 운영](./07-deployment-operations.md)

---

## 8.1 난수 생성 취약점 (심각도: 높음 - 메인넷)

**파일:** `src/dao/LotteryCandidate.sol` - `drawWinner()` 함수

```solidity
uint256 randomIndex = uint256(keccak256(abi.encodePacked(
    block.prevrandao, block.timestamp, round, participants.length
))) % participants.length;
```

### 위험
- `block.prevrandao`와 `block.timestamp`는 블록 생성자(밸리데이터)가 영향을 줄 수 있는 값이다
- 밸리데이터가 참가자인 경우, 자신에게 유리한 블록을 선택적으로 생성할 수 있다
- MEV(Miner Extractable Value) 봇이 추첨 트랜잭션을 프론트러닝할 수 있다

### 현재 상태
- **데모/테스트 환경:** 문제없음 (Anvil 로컬 체인)
- **메인넷 배포:** 반드시 교체 필요

### 권장 해결 방안
- **Chainlink VRF v2.5** 통합
- 2-트랜잭션 패턴: 추첨 요청(`requestRandomWords`) → 콜백 수신(`fulfillRandomWords`)
- VRF 사용 시 `drawWinner()` 함수를 `requestDraw()` + `fulfillDraw()` 로 분리해야 함

---

## 8.2 접근 제어

| 역할 | 제어 방식 | 권한 범위 |
|------|----------|----------|
| **Owner (관리자)** | `AccessibleCommon` (`DEFAULT_ADMIN_ROLE`) | 초기화, 주소 설정, 프록시 업그레이드 |
| **Operator (오퍼레이터)** | `onlyOperator` (`msg.sender == candidate`) | 복권 추첨, 참가비 설정, DAO 거버넌스 |
| **일반 사용자** | 제한 없음 | 예치, 출금 요청, 복권 참가, 시뇨리지 업데이트 |

### 주의점
- `candidate` 변수에 저장된 주소가 오퍼레이터
- `operator()` 함수는 `address(this)`를 반환 (ILayer2 인터페이스 구현용)
- 오퍼레이터 변경 불가 (`changeOperator()`는 항상 revert)

---

## 8.3 프록시 업그레이드 보안

- `upgradeTo()`, `setImplementation2()`, `setSelectorImplementations2()`는 `onlyOwner`로 제한
- **스토리지 슬롯 충돌 주의:**
  - 새 변수는 반드시 `LotteryCandidateStorage.sol` 파일의 맨 아래에 추가
  - 기존 변수의 순서나 타입을 변경하면 안 됨
  - 변수를 삭제하면 안 됨 (주석 처리 후 빈 슬롯으로 유지)
- `pauseProxy` 설정 시 모든 delegatecall이 revert됨

---

## 8.4 재진입 공격 (Reentrancy)

### 위험 지점: `processWithdrawal()`
- WTON `transfer()` 호출 후 상태 변경(`processed = true`, `lastProcessedRequestIndex++`)

### 현재 완화 요소
- WTON은 표준 ERC20이므로 transfer 시 콜백 없음 → 재진입 위험 낮음
- `require(!req.processed)` 가드가 이중 처리 방지

### 권장 사항
- 커스텀 토큰이나 ERC777 토큰 사용 시 Checks-Effects-Interactions 패턴 준수 확인
- 필요 시 OpenZeppelin `ReentrancyGuard` 추가 검토

---

## 8.5 시뇨리지 분배 정밀도

- WTON은 27 decimals (`1e27 = 1 WTON`)로 높은 정밀도
- 시뇨리지 분배 시 나눗셈으로 인한 dust(먼지) 발생
  - `share = increase * _balances[depositor] / totalDeposited`
  - 나머지(dust)는 마지막 예치자에게 할당
- 테스트에서 `assertApproxEqAbs`로 1~2 wei 오차 허용 확인 완료

---

## 8.6 오퍼레이터 최소 스테이킹 요건

- LotteryCandidate는 `address(this)`가 `DepositManager`에서의 예치 주체
- `SeigManager.minimumAmount()` 이상의 스테이킹이 필요
  - 테스트: 100 WTON
  - 데모: 1001 TON (1001e27 WTON)
  - 메인넷: **확인 필요**
- 최소 금액 미달 시 `updateSeigniorage()`가 실행은 되지만 보상 분배 안 됨 (Silent Success)

---

## 8.7 프론트엔드 보안

- 프라이빗 키가 `.env.example`에 포함되어 있으나 Anvil 기본 키임
- `.gitignore`에 `.env` 포함 확인 필요
- 프론트엔드는 순수 클라이언트 사이드 → 서버 비밀 노출 위험 없음
- 단, `deployment.json`에 컨트랙트 주소가 포함되므로 메인넷 배포 시 관리 주의

---

[다음: Known Issues →](./09-known-issues.md)
