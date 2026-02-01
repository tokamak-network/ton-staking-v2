# Slashing E2E 시나리오 3 워크스루: 슬래싱 후 재 스테이킹

## 목표
검증자가 슬래싱된 후 재 스테이킹을 통해 복구하는 전체 생명주기를 검증합니다.
주요 검증 포인트:
1.  **슬래싱 실행**: 운영자 스테이크가 0으로 감소.
2.  **시뇨리지 중단**: 스테이크가 0일 때 보상이 발생하지 않음.
3.  **재 스테이킹**: 운영자가 *동일한* 후보자에게 WTON을 다시 예치할 수 있음.
4.  **재개**: 재 스테이킹 후 시뇨리지 발생이 정상적으로 재개되는지 검증.

## 구현 세부사항

### 테스트 케이스: `TestSlashing_ReRegistrationAfterSlashing`
위치: `op-e2e/slashing/slashing_test.go`.

#### 주요 단계:
1.  **운영자 등록**: 10,000 TON 스테이크로 표준 등록.
2.  **슬래싱 실행**:
    *   Fault Dispute Game 생성.
    *   챌린저가 효율적으로 승리.
    *   `Layer2Manager`가 `DepositManager`를 통해 슬래싱 실행.
    *   **검증**: 운영자 스테이크가 0이 됨.
3.  **발생 없음 확인**:
    *   14일 경과.
    *   **검증**: 스테이크가 여전히 0임.
4.  **재 스테이킹**:
    *   운영자(검증자)가 TON을 WTON으로 스왑.
    *   **설정**: `reStakeAmount`를 10,000 WTON (27 decimals)로 조정하여 `SeigManager` 요구사항 (RAY)에 맞춤.
    *   **동작**: `DepositManager.Deposit1(candidateAddOn, operatorManager, amount)` 호출.
    *   **검증**: 스테이크 잔액이 >= 10,000 WTON으로 복구됨.
5.  **재개 확인**:
    *   **블록 전진**: 시뇨리지 생성을 위해 1000 블록 채굴 (`AdvanceBlocks`).
    *   **업데이트 트리거**: `CandidateAddOn.updateSeigniorage()`를 명시적으로 호출하여 코이니지 상태 업데이트.
    *   **검증**: 운영자의 총 스테이크(원금 + 시뇨리지)가 재 예치된 원금보다 큰지 확인.
    *   *참고*: `SeigManager.stakeOf`를 조회하는 `getStakeWithSeigniorage` 헬퍼를 사용하여 누적된 보상(시뇨리지)을 포함하여 정확히 확인.

### 도전 과제 및 해결책

#### 1. 예치 금액 정밀도
*   **문제**: `minimum amount is required` revert.
*   **원인**: 테스트가 WTON 금액으로 `10,000 * 10^18` (TON decimals)를 전송했습니다. `SeigManager`는 검사를 위해 WTON/RAY (27 decimals)를 기대합니다.
*   **해결**: `reStakeAmount`를 `10^27` 스케일링을 사용하도록 업데이트했습니다. 적절한 변환 로직 구현.

#### 2. 검증자 vs 운영자 계정
*   **문제**: `OperatorCollateral is insufficient`.
*   **원인**: 초기 시도는 `Deposit` (msg.sender)를 사용했으나, 로직상 `Deposit1`을 사용하여 `operatorManager`를 타겟팅해야 했습니다.
*   **해결**: `Deposit1(layer2, operatorManager, amount)`를 사용하여 운영자 컨트랙트에 올바르게 신용을 부여했습니다.

#### 3. 시뇨리지 업데이트 Revert (중요 수정)
*   **문제**: `CandidateAddOn.updateSeigniorage()` 트랜잭션이 revert됨.
*   **원인**: `SeigManager`에 `l1BridgeRegistry` 주소 설정이 누락되어 있었습니다. `updateSeigniorage` 로직이 `l1BridgeRegistry`에서 `layer2TVL`을 조회하려다 0번 주소 호출로 실패했습니다.
*   **해결**: `DeployV3SlashForDevnet.s.sol` (및 `DeployV3FullSlash.s.sol`) 배포 스크립트에 `SeigManager.setL1BridgeRegistry(l1BridgeRegistryProxy)` 설정을 명시적으로 추가하고 Genesis를 재생성했습니다.

#### 4. 시뇨리지 검증
*   **문제**: `accStaked`를 사용한 초기 검사는 원금만 추적하므로 증가를 보이지 않았음.
*   **원인**: `accStaked` (DepositManager)는 시뇨리지를 반영하지 않음. `SeigManager.stakeOf`를 사용해야 함.
*   **해결**: `SeigManager.stakeOf`를 raw ABI 바인딩으로 조회하는 `getStakeWithSeigniorage` 헬퍼 함수를 구현하여 시뇨리지 증가를 확인했습니다.

## 검증 결과

### 테스트 실행
```bash
go test -v ./slashing -run TestSlashing_ReRegistrationAfterSlashing
```

### 출력 로그 (요약)
```
slashing_test.go:356: ✓ Operator stake is 0
slashing_test.go:370: ✓ No seigniorage accrued (stake remains 0)
slashing_test.go:413: ✓ Re-staked 10000000000000000000000000000000 WTON to OperatorManager
slashing_test.go:515: ✓ Mined 1000 blocks
slashing_test.go:505: [OK] Seigniorage update called successfully
slashing_test.go:462: Operator Stake with Seigniorage (After 1000 Blocks): 10000000001991759693818378540000
slashing_test.go:470: ✓ Seigniorage increased: 1991759693818378540000
slashing_test.go:471: [OK] Re-registered operator can earn seigniorage
slashing_test.go:473: ✅ Test Passed: Re-staking and seigniorage verification complete
```

## 결론
시나리오 3은 **완료**되었습니다. 시스템은 슬래싱(스테이크 제로화)을 올바르게 처리하고, 재 스테이킹을 허용하며, 시뇨리지 분배가 성공적으로 재개됨을 확인했습니다.
