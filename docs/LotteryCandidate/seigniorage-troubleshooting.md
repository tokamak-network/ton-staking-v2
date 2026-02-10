# LotteryCandidate 시뇨리지 분배 트러블슈팅

`Claim Seigniorage` 버튼을 클릭했을 때 트랜잭션은 성공하지만 실제 시뇨리지가 업데이트되지 않는 현상에 대한 원인 분석 및 해결 방법입니다.

## 현상
- 사용자가 "Claim Seigniorage"를 실행하면 MetaMask 트랜잭션은 성공(Success)으로 표시됨.
- 하지만 `LotteryCandidate`에 예치된 잔액이나 전체 예치 풀(`Total Deposited`)의 숫자가 변하지 않음.

## 원인 분석

### 1. SeigManager의 "Silent Success" 설계
`SeigManagerV3_2.updateSeigniorageV2()` 함수는 시뇨리지를 분배할 조건이 충족되지 않아도 `revert`하지 않고 `true`를 반환하도록 설계되어 있습니다.

```solidity
// SeigManagerV3_2.sol
function updateSeigniorageV2() external returns (bool) {
    // ...
    uint256 prevTotalSupply = coinage.totalSupply();
    uint256 nextTotalSupply = _tot.balanceOf(msg.sender);

    // 시뇨리지가 발생하지 않았으면 그냥 true 반환 (Silent Success)
    if (prevTotalSupply >= nextTotalSupply) {
        emit Comitted(msg.sender);
        return true; 
    }
    // ...
}
```

### 2. 블록 간격(Block Span) 부족
시뇨리지는 마지막 업데이트 블록(`_lastSeigBlock`)과 현재 블록 간의 차이에 비례하여 발생합니다.
- **원인**: 데모 환경이나 로컬 테스트에서 `updateSeigniorage`를 호출한 직후 또는 배포 직후에 다시 호출하면, 블록이 충분히 생성되지 않아 발생할 시뇨리지가 0이 됩니다.
- **계산식**: `maxSeig = span * seigPerBlock` (span이 0이면 결과도 0)

### 3. V2 모드 첫 번째 호출의 특성 (First-Call Trap)
V2 모드에서 특정 Candidate에 대해 `updateSeigniorage`를 처음 호출할 때는 실제 분배가 일어나지 않고 **시작 블록(`startBlock`)을 설정**하는 과정만 수행됩니다.
- **테스트 코드에서의 확인**: `V2ModeTestBase.sol`의 `_initializeLayer2Seigniorage()` 함수를 보면, 첫 호출 후 반드시 블록을 넘겨야 다음 호출부터 시뇨리지가 들어오는 것을 알 수 있습니다.

### 4. 오퍼레이터 최소 스테이킹 요구사항
`LotteryCandidate`는 스스로가 `Operator` 역할을 합니다. `SeigManager` 설정에 따라 오퍼레이터가 최소 스테이킹 금액(`minimumAmount`) 미만을 보유하고 있으면 시뇨리지 업데이트가 거절됩니다.
- **테스트 환경**: 100 WTON
- **데모/메인넷 환경**: 1000.1 WTON

## 해결 방법

### 데모 환경 (Anvil)
`run-lottery-demo.sh` 스크립트는 배포 후 자동으로 `updateSeigniorage()`를 한 번 호출하여 `startBlock`을 설정합니다. 따라서 데모 시작 후 바로 시뇨리지 분배가 작동합니다.

수동으로 문제를 해결해야 하는 경우:
1. **블록 생성 기다리기**: Anvil이 1초마다 블록을 생성하도록 설정되어 있다면(`--block-time 1`), 최소 1~2개 이상의 블록이 생성된 후 버튼을 누르세요.
2. **초기화 호출**: 배포 후 처음 한 번은 `Claim Seigniorage`를 눌러 시작 블록을 설정해야 합니다. 그 다음 블록부터 실제 보상이 쌓입니다.
3. **오퍼레이터 잔액 확인**: 오퍼레이터 계정으로 최소 1001 TON 이상이 예치되어 있는지 확인하세요. (데모 스크립트는 자동으로 이를 수행합니다.)

### 테스트 환경 (Foundry)
- `vm.roll(block.number + 10)` 등을 사용하여 명시적으로 블록을 진행시킨 후 `updateSeigniorage`를 호출해야 합니다.

## 요약
트랜잭션이 성공하는 것은 `SeigManager`가 요청을 정상적으로 접수했음을 의미하며, 잔액이 변하지 않는 것은 **발생한 시뇨리지 양이 0**이기 때문입니다. 이는 버그가 아니라 블록 생성 기반의 보상 로직에 따른 정상적인 동작입니다.
