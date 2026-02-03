# Local Testing Results (V3)

이 문서는 `LOCAL-TESTING.md` 가이드에 따라 수행한 로컬 테스트 결과를 기록합니다.

## 테스트 환경

- **Network**: Anvil (localhost:8545)
- **Chain ID**: 31337
- **Date**: 2025-02-02

## 배포된 컨트랙트 주소

| 컨트랙트 | 주소 |
|---------|------|
| TON | `0x5FbDB2315678afecb367f032d93F642f64180aa3` |
| WTON | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` |
| SeigManager | `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9` |
| Layer2Manager | `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9` |
| DelegateStakingV3 | `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853` |
| DelegateTrigger | `0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6` |

### L2 설정

| 항목 | L2 #1 |
|-----|-------|
| Layer2 Address | `0x3976501Cb193647c8dE461E11CF6625d0c071c4F` |
| Sequencer | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` |
| OperatorManager | `0x856e4424f806D16E8CBC702B3c0F2ede5468eae5` |

## 테스트 시나리오 및 결과

### 1. 초기 잔액 확인 ✅

```bash
# Deployer TON 잔액
cast call $TON "balanceOf(address)(uint256)" $DEPLOYER
# Result: 1,000,000 TON

# Sequencer1 TON 잔액
cast call $TON "balanceOf(address)(uint256)" $SEQUENCER1
# Result: 1,000,000 TON
```

### 2. 시퀀서 등록 ✅

```bash
cast send $STAKING "registerSequencer(address,address,uint256)" \
  $LAYER2_1 $OPERATOR_MANAGER1 1000 \
  --private-key $SEQUENCER1_PK
```

- **수수료율**: 10% (1000 basis points)
- **트랜잭션**: `0x96b3a24beade3e7fa24b98009b311fc0dfdf1af3e5edf4397b3276d80b719460`
- **결과**: Success

### 3. TON 스테이킹 ✅

```bash
# Step 1: 승인
cast send $TON "approve(address,uint256)" $STAKING 1000000000000000000000 \
  --private-key $DEPLOYER_PK

# Step 2: 스테이킹
cast send $STAKING "stake(address,uint256)" $SEQUENCER1 1000000000000000000000 \
  --private-key $DEPLOYER_PK
```

- **스테이킹 금액**: 1,000 TON
- **트랜잭션**: `0x82058cf7366dff80c050d7cc052c626c480f169561f2200603479c716f5d067c`
- **결과**: Success

### 4. 스테이킹 정보 확인 ✅

```bash
cast call $STAKING "getTotalStaked()(uint256)"
# Result: 1,000 TON (1e21 wei)

cast call $STAKING "pendingRewards(address,address)(uint256)" $DEPLOYER $SEQUENCER1
# Result: 0 (아직 보상 없음)
```

### 5. Auto-Trigger 활성화 ✅

```bash
cast send $STAKING "setAutoTrigger(bool)" true \
  --private-key $SEQUENCER1_PK
```

- **결과**: Success

### 6. 시뇨리지 트리거 ✅

```bash
cast send $STAKING "triggerSeigniorage(address)" $SEQUENCER1 \
  --private-key $DEPLOYER_PK
```

- **트랜잭션**: `0x150570e6f3adc07dbef753c4a4df4fd9b9f7b675f2359436674e032dbe210731`
- **이벤트 발생**:
  - WTON Transfer (OperatorManager → Staking)
  - RewardsClaimed
  - SeigniorageTriggered
- **결과**: Success

### 7. 보상 확인 및 수령 ✅

```bash
# 대기 중인 보상 확인
cast call $STAKING "pendingRewards(address,address)(uint256)" $DEPLOYER $SEQUENCER1
# Result: 900,000,000,000,000,000,000,000,000,000,000 (9e32 wei = 900,000 WTON)

# 보상 수령
cast send $STAKING "claimRewards(address)" $SEQUENCER1 \
  --private-key $DEPLOYER_PK
```

- **수령 전 WTON 잔액**: 1,000,000 WTON (1e33 wei)
- **수령 후 WTON 잔액**: 1,900,000 WTON (1.9e33 wei)
- **수령한 보상**: 900,000 WTON (시뇨리지의 90%, 10% 수수료 제외)
- **결과**: Success

### 8. 시퀀서 수수료 수령 ✅

```bash
cast send $STAKING "claimCommission()" \
  --private-key $SEQUENCER1_PK
```

- **트랜잭션**: `0x14df3bf6e83e5e40f012a95d8b98ffcd2346d5d023dea3df43f27c49eb690e72`
- **수령한 수수료**: 100,000 WTON (시뇨리지의 10%)
- **결과**: Success

### 9. 언스테이킹 ✅

```bash
cast send $STAKING "unstake(address,uint256)" $SEQUENCER1 500000000000000000000 \
  --private-key $DEPLOYER_PK
```

- **언스테이킹 금액**: 500 TON
- **결과**: Success

### 10. Unbonding Period 전 출금 시도 ✅ (예상대로 실패)

```bash
cast send $STAKING "withdraw(address)" $SEQUENCER1 \
  --private-key $DEPLOYER_PK
```

- **결과**: `UnstakingPeriodNotElapsed` 에러 발생 (예상된 동작)

### 11. Unbonding Period 후 출금 ✅

```bash
# 7일 시간 앞으로 이동
cast rpc anvil_increaseTime 604801
cast rpc anvil_mine 1

# 출금
cast send $STAKING "withdraw(address)" $SEQUENCER1 \
  --private-key $DEPLOYER_PK
```

- **출금 전 TON 잔액**: 999,000 TON
- **출금 후 TON 잔액**: 999,500 TON
- **출금 금액**: 500 TON
- **결과**: Success

## 최종 잔액 요약

| 계정 | 토큰 | 잔액 | 비고 |
|-----|------|------|------|
| Deployer | TON | 999,500 | 1M - 1000 스테이킹 + 500 출금 |
| Deployer | WTON | 1,900,000 | 1M + 900K 보상 |
| Sequencer1 | TON | 1,000,000 | 변동 없음 |
| Sequencer1 | WTON | 100,000 | 수수료 수령 |
| Staking Contract | TON | 500 | 남은 스테이킹 |

## 테스트 결과 요약

| # | 시나리오 | 상태 | 비고 |
|---|---------|------|------|
| 1 | 초기 잔액 확인 | ✅ Pass | |
| 2 | 시퀀서 등록 | ✅ Pass | 10% 수수료 |
| 3 | TON 스테이킹 | ✅ Pass | 1000 TON |
| 4 | 스테이킹 정보 확인 | ✅ Pass | |
| 5 | Auto-Trigger 활성화 | ✅ Pass | |
| 6 | 시뇨리지 트리거 | ✅ Pass | |
| 7 | 보상 수령 | ✅ Pass | 900K WTON |
| 8 | 시퀀서 수수료 수령 | ✅ Pass | 100K WTON |
| 9 | 언스테이킹 | ✅ Pass | 500 TON |
| 10 | Unbonding 전 출금 | ✅ Pass | 예상대로 실패 |
| 11 | Unbonding 후 출금 | ✅ Pass | 500 TON |

**전체 결과: 11/11 테스트 통과** 🎉

## 사용된 명령어 참조

### 환경 변수 설정

```bash
# 컨트랙트 주소
export STAKING=0xa513E6E4b8f2a923D98304ec87F64353C4D5C853
export TON=0x5FbDB2315678afecb367f032d93F642f64180aa3
export WTON=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

# 계정
export DEPLOYER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export SEQUENCER1=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
export LAYER2_1=0x3976501Cb193647c8dE461E11CF6625d0c071c4F
export OPERATOR_MANAGER1=0x856e4424f806D16E8CBC702B3c0F2ede5468eae5

# Private Keys (Anvil defaults)
export DEPLOYER_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export SEQUENCER1_PK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

### 조회 명령어

```bash
# 총 스테이킹 금액
cast call $STAKING "getTotalStaked()(uint256)" --rpc-url http://localhost:8545

# 대기 중인 보상
cast call $STAKING "pendingRewards(address,address)(uint256)" $DEPLOYER $SEQUENCER1 --rpc-url http://localhost:8545

# TON 잔액
cast call $TON "balanceOf(address)(uint256)" $DEPLOYER --rpc-url http://localhost:8545

# WTON 잔액
cast call $WTON "balanceOf(address)(uint256)" $DEPLOYER --rpc-url http://localhost:8545
```
