# 컨트랙트 구조

## LotteryCandidate

경로: `src/dao/LotteryCandidate.sol`

- 사용자의 TON/WTON 예치금을 관리하며 내부적으로 개별 잔액(`_balances`)을 추적합니다.
- 실제 자산은 `LotteryCandidate` 컨트랙트 주소 명의로 `DepositManager`에 통합 예치됩니다.
- **Lottery**: 라운드마다 설정된 참여 비용(`entryFee`)을 지불하고 참여합니다. 당첨자가 해당 라운드의 모든 참여비를 자신의 내부 잔액으로 가져갑니다 (Winner-takes-all).
- **시뇨리지 분배**: `SeigManager` 호출을 통해 발생하는 시뇨리지(네트워크 보상)를 감지하고, 현재 모든 예치자의 잔액 비율에 따라 내부 잔액에 가산합니다.
- **출금 관리**: 사용자가 출금을 요청하면 내부 잔액에서 차감 후 `DepositManager`에 출금을 신청하며, 대기 시간 이후 실제 자산을 수령할 수 있습니다.

### 주요 함수

- `depositTON(uint256 tonAmount)`: TON을 입금하여 WTON으로 변환 후 예치 및 내부 잔액 가산.
- `depositWTON(uint256 wtonAmount)`: WTON을 직접 예치 및 내부 잔액 가산.
- `enterLottery()`: 현재 라운드 참여 비용을 잔액에서 차감하고 참여 등록.
- `drawWinner()`: 현재 라운드 당첨자 추첨 및 상금(Prize Pool)을 당첨자의 내부 잔액에 지급 (operator 전용).
- `updateSeigniorage()`: `SeigManager`의 시뇨리지를 갱신하고, 증가한 코이니지(coinage) 만큼 모든 예치자에게 비례 분배합니다.
- `setEntryFee(uint256 fee)`: 다음 라운드부터 적용될 참여 비용 설정 (operator 전용).
- `requestWithdrawal(uint256 amount)`: 내부 잔액에서 출금 신청. 실제 자금은 `DepositManager`의 출금 지연 시간 이후 수령 가능.
- `processWithdrawal(uint256 n)`: 완료된 출금 요청을 처리하여 실제 WTON을 사용자에게 전송.
- `balanceOf(address account)`: 사용자의 현재 내부 잔액 조회.
- `totalStaked()`: 현재 후보에 스테이킹된 전체 코이니지(coinage) 공급량을 반환합니다.
- `operator()`: `SeigManager`와의 연동을 위해 `LotteryCandidate` 컨트랙트 자신을 반환합니다. 실제 운영 권한은 `candidate` 주소가 가집니다.

## LotteryCandidateFactory

경로: `src/dao/factory/LotteryCandidateFactory.sol`

- `defaultEntryFee`를 관리하며, 새로운 `LotteryCandidate` 생성 시 초기 참여 비용으로 설정합니다.

## DAOCommittee 확장

경로: `src/dao/DAOCommittee_V1.sol`

- `createLotteryCandidate(string memo)`를 통해 Factory를 호출하여 새로운 후보를 생성합니다.
