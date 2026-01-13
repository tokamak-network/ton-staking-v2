# Slashing 메커니즘 상세 설명

## 1. 개요

Slashing 메커니즘은 Tokamak Network에서 악의적이거나 부정확한 행동을 한 Operator(시퀀서)의 스테이킹 자산을 몰수하고, 이를 발견한 Challenger에게 보상을 제공하는 시스템입니다.

### 1.1 핵심 목적

1. **네트워크 보안**: 악의적인 Operator의 경제적 손실을 통해 정직한 행동 유도
2. **Challenger 인센티브**: Fraud Proof를 제출한 Challenger에게 경제적 보상 제공
3. **자동화된 집행**: Permissionless 방식으로 누구나 슬래싱을 실행 가능

### 1.2 관련 컨트랙트

| 컨트랙트 | 역할 |
|---------|------|
| **Layer2Manager_Slashing** | DisputeGame 검증 및 슬래싱 트리거 |
| **DepositManager_Slashing** | 스테이킹 회계 처리 및 보상 분배 |
| **SeigManager_Slashing** | Coinage 및 TOT 토큰 소각 |

---

## 2. Slashing 프로세스

### 2.1 전체 흐름

```
1. Operator가 잘못된 Output Root 제출
   │
2. Challenger가 Fraud Proof 제출
   │
3. DisputeGame 진행 및 해결
   │ (GameStatus.CHALLENGER_WINS)
   │
4. Layer2Manager_Slashing.slashingCandidate() 호출
   │ - DisputeGame 검증
   │ - Challenger 주소 추출
   │
5. DepositManager_Slashing.slash() 호출
   │ - 스테이킹 회계 초기화
   │ - 보상 계산 및 지급
   │
6. SeigManager_Slashing.onSlash() 호출
   │ - Coinage 토큰 소각
   │ - TOT 토큰 소각
   │
7. 완료
   └─► Operator 스테이킹 제거
   └─► Challenger 보상 지급
```

### 2.2 단계별 상세 설명

#### 2.2.1 DisputeGame 검증 (Layer2Manager_Slashing)

**함수**: `slashingCandidate(address _operator, GameType _gameType, Claim _rootClaim, bytes calldata _extraData, address _disputeGame)`

**검증 단계**:

1. **Operator 주소 검증**
   ```solidity
   require(_operator != address(0), "ZeroAddressError");
   ```

2. **DisputeGameFactory 주소 확인**
   
   각 Operator는 고유의 `rollupConfig` 주소를 가지고 있으며, 이를 통해 해당 Operator의 DisputeGameFactory 주소를 조회합니다.
   즉, **Operator마다 서로 다른 DisputeGameFactory를 사용합니다.**.
   
   ```solidity
   address disputeGameFactory = ISystemConfig(operatorInfo[_operator].rollupConfig)
       .disputeGameFactory();
   require(disputeGameFactory != address(0), "ZeroAddressError");
   ```
   
   - `operatorInfo[_operator].rollupConfig`: Operator별 고유 RollupConfig 주소
   - 각 Operator는 자신의 L2 체인에 맞는 DisputeGameFactory를 사용

3. **DisputeGame 등록 여부 확인**
   ```solidity
   (IDisputeGame disputeGame, ) = IDisputeGameFactory(disputeGameFactory).games(
       _gameType,
       _rootClaim,
       _extraData
   );
   require(address(disputeGame) == _disputeGame, "wrong dispute game Address");
   ```

4. **DisputeGame 상태 확인**
   ```solidity
   GameStatus status = IDisputeGame(disputeGame).status();
   require(status == GameStatus.CHALLENGER_WINS, "StatusError");
   ```

5. **Challenger 주소 추출**
   ```solidity
   address challenger = _getWinningChallenger(_disputeGame);
   require(challenger != address(0), "invalid challenger");
   ```

   - `_getWinningChallenger()`: DisputeGame의 `claimData(0).counteredBy`에서 Challenger 주소 추출
   - `claimData(0)`은 루트 클레임이며, `counteredBy`는 이를 격파한 Challenger의 주소

#### 2.2.2 스테이킹 회계 처리 (DepositManager_Slashing)

**함수**: `slash(address layer2, address operator, address challenger)`

**처리 단계**:

1. **Operator 검증**
   ```solidity
   require(operator == ILayer2(layer2).operator(), "operator is not an operator");
   require(challenger != address(0), "invalid challenger address");
   ```

2. **슬래싱 금액 확인**
   ```solidity
   uint256 slashedAmount = _accStaked[layer2][operator];
   require(slashedAmount > 0, "no staked amount to slash");
   ```

3. **보상 금액 계산**
   ```solidity
   uint256 rewardAmount = 0;
   if (slashingRewardRate > 0) {
       // 100% = 10000 단위로 계산
       rewardAmount = (slashedAmount * slashingRewardRate) / 10000;
   }
   ```

   - `slashingRewardRate`: 슬래싱 금액 중 Challenger에게 지급할 비율 (기본값: 10% = 1000)
   - 예시: slashedAmount = 1000 WTON, slashingRewardRate = 1000 → rewardAmount = 100 WTON

4. **회계 장부 초기화**
   ```solidity
   _accStaked[layer2][operator] = 0;
   _accStakedLayer2[layer2] = _accStakedLayer2[layer2] - slashedAmount;
   _accStakedAccount[operator] = _accStakedAccount[operator] - slashedAmount;
   ```

5. **SeigManager에 슬래싱 처리 요청**
   ```solidity
   require(ISeigManager(_seigManager).onSlash(layer2, operator), "fail onSlash");
   ```

6. **Challenger에게 보상 지급**
   ```solidity
   if (rewardAmount > 0) {
       IERC20(_wton).safeTransfer(challenger, rewardAmount);
       emit ChallengerRewarded(layer2, challenger, rewardAmount);
   }
   ```

#### 2.2.3 토큰 소각 (SeigManager_Slashing)

**함수**: `onSlash(address layer2, address operator)`

**소각 메커니즘**:

Operator의 전체 스테이킹 금액(원금 + 누적 시뇨리지)을 Coinage 및 TOT 토큰에서 소각합니다.

**소각 공식**:

```
v = operator의 coinages[layer2] 잔액
⍺ = (tot.balanceOf(layer2) - coinages[layer2].totalSupply()) × (v / coinages[layer2].totalSupply())

소각량:
- coinages[layer2]: v
- tot: v + ⍺
```

**구현**:

```solidity
function onSlash(address layer2, address operator) external onlyDepositManager returns (bool) {
    uint256 operatorAmount = _coinages[layer2].balanceOf(operator);

    // burn {v + ⍺} {tot} tokens from the layer2 contract
    uint256 totAmount = _uncommittedOperatorSeigniorage(layer2, operatorAmount);
    _tot.burnFrom(layer2, operatorAmount + totAmount);

    // burn {v} {coinages[layer2]} tokens from the operator
    _coinages[layer2].burnFrom(operator, operatorAmount);

    emit Slashed(layer2, operator);

    return true;
}
```

**⍺ 계산 함수**:

```solidity
function _uncommittedOperatorSeigniorage(
    address layer2,
    uint256 amount
) internal view returns (uint256) {
    uint256 coinageTotalSupply = _coinages[layer2].totalSupply();
    uint256 totBalance = _tot.balanceOf(layer2);

    // 오차 보정: 1e-9 WTON 이하 차이는 0으로 처리
    if (coinageTotalSupply >= totBalance && coinageTotalSupply - totBalance < WEI_UNIT) {
        return 0;
    }

    return FullMath.rdiv(
        FullMath.rmul(totBalance - coinageTotalSupply, amount),
        coinageTotalSupply
    );
}
```

---

## 3. 주요 파라미터

### 3.1 slashingRewardRate

**설명**: 슬래싱 금액 중 Challenger에게 지급할 비율

**단위**: 10000 = 100%

**설정 함수**: `DepositManager_Slashing.setSlashingRewardRate(uint256 newRate)`

**제약 조건**:
```solidity
require(newRate <= 10000, "rate exceeds 100%");
```

**권장값**: 1000 (10%)

**예시**:
| slashingRewardRate | 슬래싱 금액 | Challenger 보상 | DAO/소각 |
|-------------------|------------|----------------|----------|
| 1000 (10%) | 1000 WTON | 100 WTON | 900 WTON |
| 2000 (20%) | 1000 WTON | 200 WTON | 800 WTON |
| 5000 (50%) | 1000 WTON | 500 WTON | 500 WTON |

---

## 4. 권한 및 접근 제어

### 4.1 함수별 권한

| 함수 | 컨트랙트 | 권한 | 설명 |
|------|---------|------|------|
| `slashingCandidate()` | Layer2Manager_Slashing | **Permissionless** | 누구나 호출 가능 |
| `slash()` | DepositManager_Slashing | `onlyLayer2Manager` | Layer2Manager만 호출 가능 |
| `onSlash()` | SeigManager_Slashing | `onlyDepositManager` | DepositManager만 호출 가능 |
| `setSlashingRewardRate()` | DepositManager_Slashing | `onlyOwner` | Owner(DAO)만 호출 가능 |

### 4.2 Modifier 정의

```solidity
// DepositManager_Slashing
modifier onlyLayer2Manager() {
    require(msg.sender == layer2Manager, "not layer2Manager");
    _;
}

// SeigManager_Slashing
modifier onlyDepositManager() {
    require(msg.sender == _depositManager, "not onlyDepositManager");
    _;
}
```

---

## 5. 이벤트

### 5.1 Layer2Manager_Slashing

```solidity
event CandidateSlashed(
    address indexed operator,
    address indexed challenger,
    address disputeGame
);
```

**발생 시점**: `slashingCandidate()` 성공 시

**파라미터**:
- `operator`: 슬래싱된 Operator 주소
- `challenger`: 보상을 받을 Challenger 주소
- `disputeGame`: 해당 DisputeGame 주소

### 5.2 DepositManager_Slashing

```solidity
event Slashed(
    address indexed layer2,
    address indexed operator,
    address indexed challenger,
    uint256 slashedAmount,
    uint256 rewardAmount
);

event ChallengerRewarded(
    address indexed layer2,
    address indexed challenger,
    uint256 amount
);

event SlashingRewardRateSet(uint256 newRate);
```

**Slashed 이벤트**:
- `layer2`: Layer2 주소 (CandidateAddOn)
- `operator`: 슬래싱된 Operator 주소
- `challenger`: Challenger 주소
- `slashedAmount`: 총 슬래싱 금액
- `rewardAmount`: Challenger에게 지급된 보상

**ChallengerRewarded 이벤트**:
- `layer2`: Layer2 주소
- `challenger`: Challenger 주소
- `amount`: 지급된 보상 금액

**SlashingRewardRateSet 이벤트**:
- `newRate`: 새로운 보상 비율

### 5.3 SeigManager_Slashing

```solidity
event Slashed(address layer2, address operator);
```

**발생 시점**: `onSlash()` 성공 시

**파라미터**:
- `layer2`: Layer2 주소
- `operator`: 슬래싱된 Operator 주소

---

## 6. 에러 처리

### 6.1 Layer2Manager_Slashing

```solidity
error ZeroAddressError();
error StatusError();
error SlashingError();
```

**ZeroAddressError**:
- Operator 주소가 0x0인 경우
- DisputeGameFactory 주소를 가져오지 못한 경우
- Challenger 주소가 0x0인 경우

**StatusError**:
- DisputeGame 상태가 `CHALLENGER_WINS`가 아닌 경우

**SlashingError**:
- `DepositManager.slash()` 호출이 실패한 경우

### 6.2 DepositManager_Slashing

```solidity
require(operator == ILayer2(layer2).operator(), "operator is not an operator");
require(challenger != address(0), "invalid challenger address");
require(slashedAmount > 0, "no staked amount to slash");
require(ISeigManager(_seigManager).onSlash(layer2, operator), "fail onSlash");
```

### 6.3 SeigManager_Slashing

```solidity
require(msg.sender == _depositManager, "not onlyDepositManager");
```

---

## 7. 보안 고려사항

### 7.1 재진입 공격 방지

**DepositManager_Slashing**:
- 회계 장부를 먼저 초기화한 후 외부 호출 수행 (Checks-Effects-Interactions 패턴)
```solidity
// 1. 회계 장부 초기화 (Effects)
_accStaked[layer2][operator] = 0;
_accStakedLayer2[layer2] = _accStakedLayer2[layer2] - slashedAmount;
_accStakedAccount[operator] = _accStakedAccount[operator] - slashedAmount;

// 2. 외부 호출 (Interactions)
require(ISeigManager(_seigManager).onSlash(layer2, operator), "fail onSlash");
IERC20(_wton).safeTransfer(challenger, rewardAmount);
```

### 7.2 권한 검증

- `onSlash()`: DepositManager만 호출 가능
- `slash()`: Layer2Manager만 호출 가능
- `setSlashingRewardRate()`: Owner(DAO)만 호출 가능

### 7.3 DisputeGame 검증

- DisputeGameFactory에 등록된 게임인지 확인
- 게임 상태가 `CHALLENGER_WINS`인지 확인
- Challenger 주소가 유효한지 확인

### 7.4 오차 보정

**SeigManager_Slashing**:
- RAY 단위 연산의 오차를 1e-9 WTON 이하로 보정
```solidity
if (coinageTotalSupply >= totBalance && coinageTotalSupply - totBalance < WEI_UNIT) {
    return 0;
}
```

---



## 9. 가스 최적화

### 9.1 회계 장부 일괄 업데이트

```solidity
// 한 번에 모든 회계 장부 업데이트
_accStaked[layer2][operator] = 0;
_accStakedLayer2[layer2] = _accStakedLayer2[layer2] - slashedAmount;
_accStakedAccount[operator] = _accStakedAccount[operator] - slashedAmount;
```

### 9.2 조건부 보상 지급

```solidity
// slashingRewardRate가 0이면 보상 계산 및 지급 생략
if (slashingRewardRate > 0) {
    rewardAmount = (slashedAmount * slashingRewardRate) / 10000;
}

if (rewardAmount > 0) {
    IERC20(_wton).safeTransfer(challenger, rewardAmount);
    emit ChallengerRewarded(layer2, challenger, rewardAmount);
}
```

### 9.3 오차 보정 조기 리턴

```solidity
// 오차가 작으면 조기 리턴
if (coinageTotalSupply >= totBalance && coinageTotalSupply - totBalance < WEI_UNIT) {
    return 0;
}
```

---

## 8. 업그레이드 고려사항

### 8.1 Proxy 패턴

모든 Slashing 컨트랙트는 Proxy 패턴을 사용하여 업그레이드 가능:

```solidity
contract SeigManager_Slashing is
    ProxyStorage,
    AuthControlSeigManager,
    SeigManagerStorage,
    SeigManagerV1_1Storage,
    SeigManagerV1_3Storage,
    SeigManagerV1_4Storage
```

### 8.2 Storage 레이아웃 주의사항

- 새로운 Storage 변수는 기존 변수 뒤에 추가
- 기존 변수의 타입이나 순서 변경 금지
- 새로운 버전의 Storage 컨트랙트 생성 (예: `DepositManagerV1_2Storage`)

### 8.3 호환성 유지

- 기존 이벤트 시그니처 유지
- 기존 함수 시그니처 유지 (오버로딩 가능)
- 기존 권한 체계 유지

---

## 9. 참고 자료

### 9.1 컨트랙트 파일

- `src/layer2/Layer2Manager_Slashing.sol`
- `src/stake/managers/DepositManager_Slashing.sol`
- `src/stake/managers/SeigManager_Slashing.sol`

### 9.2 테스트 파일

- `test/slashing/SlashingTest.t.sol`
- `test/slashing/SlashingE2E_Functional.t.sol`
- `test/slashing/SlashingE2E_Revert.t.sol`

### 9.3 인터페이스

- `src/stake/interfaces/ISeigManager.sol`
- `src/stake/interfaces/IIDepositManager.sol`
- `src/layer2/interfaces/IDisputeGame.sol`
- `src/layer2/interfaces/IDisputeGameFactory.sol`
- `src/layer2/interfaces/IFaultDisputeGame.sol`
