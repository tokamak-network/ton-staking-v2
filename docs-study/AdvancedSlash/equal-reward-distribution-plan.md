# 구현 계획 - 모든 챌린저에 대한 균등 보상 분배

이 계획은 슬래싱 보상을 최초의 챌린저 한 명 대신, 루트 클레임에 도전한 **모든 챌린저들에게 균등하게 분배**하기 위해 필요한 변경 사항을 설명합니다.

## 사용자 검토 필요 사항

> [!IMPORTANT]
> **"챌린저"의 정의**: 여기서 "모든 챌린저"란 루트 클레임(Claim Index 0)에 대해 직접적인 반박(Depth 1 Claims)을 생성한 모든 주소를 의미합니다. 이는 루트에 대한 모든 도전이 분쟁 해결에 기여했다고 가정합니다.
> **가스 비용**: 다수의 챌린저에게 보상을 분배할 경우 `slashingCandidate` 함수의 가스 비용이 증가합니다. 챌린저 수가 지나치게 많으면 트랜잭션이 가스 한도를 초과할 수 있습니다. 추후 챌린저 수 제한이 필요할 수 있으나, 현재는 합리적인 수준으로 가정합니다.

## 변경 제안

### [Optimism/Dispute]

#### [수정] [FaultDisputeGame.sol](file:///Users/harvey/Desktop/onther/event/migration/ton-staking-v2/lib/optimism/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol)
- `getChallengers()` (또는 `getChildClaimants(uint256)`) 뷰 함수를 추가하여 `address[]`를 반환하도록 합니다.
- 이 함수는 `subgames[0]` (루트 클레임의 자식 클레임들)을 순회하며 `claimant` 주소들을 수집합니다.

#### [수정] [IFaultDisputeGame.sol](file:///Users/harvey/Desktop/onther/event/migration/ton-staking-v2/src/layer2/interfaces/IFaultDisputeGame.sol)
- 인터페이스에 `getChallengers()` 함수 정의를 추가합니다.

### [Layer2]

#### [수정] [Layer2Manager_Slashing.sol](file:///Users/harvey/Desktop/onther/event/migration/ton-staking-v2/src/layer2/Layer2Manager_Slashing.sol)
- `_getWinningChallenger` 함수를 `_getChallengers`로 변경합니다.
- `slashingCandidate` 함수에서 `_getChallengers`를 호출하여 챌린저 목록(`address[]`)을 가져옵니다.
- `depositManager.slash` 호출 시 단일 주소 대신 `address[]` 배열을 전달하도록 수정합니다.

### [Stake/Managers]

#### [수정] [DepositManager_Slashing.sol](file:///Users/harvey/Desktop/onther/event/migration/ton-staking-v2/src/stake/managers/DepositManager_Slashing.sol)
- `slash` 함수의 시그니처를 `address challenger` 대신 `address[] memory challengers`를 받도록 수정합니다.
- 챌린저 1인당 보상 계산: `totalReward / challengers.length`
- `challengers` 배열을 순회하며 각 챌린저에게 `rewardPerChallenger`만큼 WTON을 전송합니다.
- `ChallengerRewarded` 이벤트를 각 챌린저마다 발생시키거나 다중 챌린저를 지원하도록 업데이트합니다.

#### [수정] [IIDepositManager.sol](file:///Users/harvey/Desktop/onther/event/migration/ton-staking-v2/src/stake/interfaces/IIDepositManager.sol)
- `slash` 함수의 인터페이스를 수정합니다.

## 검증 계획

### 자동화 테스트
- 새로운 테스트 파일 `test/v3/v3mode/BasicSlashing/SlashingMultiChallengerRewardTest.t.sol` 생성.
- **테스트 케이스 1: 다중 챌린저**:
    - 게임 설정.
    - 챌린저 A가 루트 공격.
    - 챌린저 B가 루트 공격.
    - 챌린저 C가 루트 공격.
    - 게임 해결 (루트 무효화).
    - `slashingCandidate` 실행.
    - A, B, C가 각각 `TotalReward / 3`만큼 수령했는지 검증.
- **테스트 케이스 2: 단일 챌린저**:
    - 기존 동작과의 하위 호환성 검증 (1명이 100% 수령).
- **실행 명령어**:
    ```bash
    forge test --match-path test/v3/v3mode/BasicSlashing/SlashingMultiChallengerRewardTest.t.sol -vvv
    ```
