# Local Testing Guide (V3)

로컬에서 V3 통합 DelegateStaking을 테스트하는 가이드입니다.

## 사전 요구사항

- Foundry 설치 (`forge`, `anvil`, `cast`)
- Node.js 18+

## 1. Anvil 실행

새 터미널에서 Anvil 실행:

```bash
anvil
```

기본 계정들이 생성됩니다:
- Account #0 (Deployer): `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- Account #1 (Sequencer1): `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
- Account #2 (Sequencer2): `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`

## 2. V3 환경 배포

```bash
forge script script/DeployLocalV3.s.sol --rpc-url http://localhost:8545 --broadcast
```

배포 결과에서 컨트랙트 주소를 확인합니다:

```
========== DEPLOYMENT SUMMARY ==========
TOKEN ADDRESSES:
  TON:                   0x5FbDB2315678afecb367f032d93F642f64180aa3
  WTON:                  0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

V3 INFRASTRUCTURE:
  SeigManager:           0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  Layer2Manager:         0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9

DELEGATE STAKING:
  DelegateStakingV3:     0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
  DelegateTrigger:       0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
==========================================
```

## 3. 상호작용 스크립트

### 시퀀서 등록

```bash
# 환경변수 설정 (배포 결과에서 주소 확인)
export STAKING=0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
export LAYER2=<layer2_address_from_deployment>
export OPERATOR_MANAGER=<operator_manager_from_deployment>
export COMMISSION=1000  # 10%

# 시퀀서 등록 (Account #1 사용)
forge script script/InteractV3.s.sol:RegisterSequencer --rpc-url http://localhost:8545 --broadcast
```

### TON 스테이킹

```bash
export STAKING=0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
export TON=0x5FbDB2315678afecb367f032d93F642f64180aa3
export SEQUENCER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
export AMOUNT=1000000000000000000000  # 1000 TON

forge script script/InteractV3.s.sol:StakeTON --rpc-url http://localhost:8545 --broadcast
```

### 시뇨리지 트리거

```bash
export STAKING=0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
export SEQUENCER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

forge script script/InteractV3.s.sol:TriggerSeigniorage --rpc-url http://localhost:8545 --broadcast
```

### 보상 수령

```bash
export STAKING=0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
export WTON=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export SEQUENCER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

forge script script/InteractV3.s.sol:ClaimRewards --rpc-url http://localhost:8545 --broadcast
```

## 4. Cast로 직접 상호작용

### 잔액 확인

```bash
# TON 잔액
cast call $TON "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# WTON 잔액
cast call $WTON "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### 스테이킹 정보 조회

```bash
# 시퀀서 정보
cast call $STAKING "getSequencerInfo(address)" $SEQUENCER

# 스테이커 정보
cast call $STAKING "getStakeInfo(address,address)" $STAKER $SEQUENCER

# 대기 중인 보상
cast call $STAKING "pendingRewards(address,address)(uint256)" $STAKER $SEQUENCER
```

### 직접 트랜잭션 전송

```bash
# TON 승인
cast send $TON "approve(address,uint256)" $STAKING 1000000000000000000000 --private-key $PRIVATE_KEY

# 스테이킹
cast send $STAKING "stake(address,uint256)" $SEQUENCER 1000000000000000000000 --private-key $PRIVATE_KEY
```

## 5. Mock V3 컴포넌트

배포된 Mock 컨트랙트들:

| 컴포넌트 | 설명 |
|---------|------|
| `MockSeigManagerV3` | V3 SeigManager 시뮬레이션 (자격 요건, 시뇨리지 계산) |
| `MockLayer2ManagerV3` | L2 등록 및 OperatorManager 생성 |
| `MockOperatorManagerV3` | 시뇨리지 청구 처리 |

### BridgedTON 업데이트 (시뇨리지 계산용)

```bash
cast send $SEIG_MANAGER "updateBridgedTON(address,uint256)" $LAYER2 100000000000000000000000 --private-key $PRIVATE_KEY
```

### StakedTON 업데이트 (자격 요건용)

```bash
cast send $SEIG_MANAGER "updateStakedTON(address,uint256)" $LAYER2 10000000000000000000000 --private-key $PRIVATE_KEY
```

## 6. 테스트 실행

```bash
# 전체 V3 테스트
forge test --match-path "test/DelegateStakingV3.t.sol" -vvv

# 특정 테스트
forge test --match-test test_Stake -vvv
```

## 7. 문제 해결

### 트랜잭션 실패
- `cast call`로 함수 호출하여 revert 메시지 확인
- 권한 확인 (operator, owner 등)
- 충분한 잔액/승인 확인

### 주소 불일치
- 배포 로그에서 실제 주소 확인
- 환경변수가 올바르게 설정되었는지 확인

### 시뇨리지 트리거 실패
- OperatorManager에 WTON 잔액 확인
- DelegateStaking이 OperatorManager의 authorized claimer인지 확인

---

## 8. V3 Upgradeable 버전 테스트 (권장)

UUPS Upgradeable 버전 (`DelegateStakingV3Upgradeable`)을 테스트하려면 다음 스크립트를 사용합니다.

### 환경 배포

```bash
# Anvil 실행 (별도 터미널)
anvil

# V3 Upgradeable 환경 배포
forge script script/DeployLocalV3Upgradeable.s.sol --rpc-url http://localhost:8545 --broadcast
```

배포 결과:

```
====================================================================
           V3 UPGRADEABLE DEPLOYMENT SUMMARY
====================================================================
 Network: localhost (Anvil)    Chain ID: 31337
--------------------------------------------------------------------
 TOKENS
   TON:
      0x5FbDB2315678afecb367f032d93F642f64180aa3
   WTON:
      0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
--------------------------------------------------------------------
 DELEGATE STAKING (UUPS UPGRADEABLE)
   Implementation:
      0x...
   Proxy:
      0x...
====================================================================
```

### 상호작용 스크립트

#### 전체 흐름 테스트 (권장)

```bash
forge script script/InteractV3Upgradeable.s.sol:FullFlowTest --rpc-url http://localhost:8545 --broadcast
```

이 스크립트는 다음을 자동으로 테스트합니다:
1. 초기 상태 확인
2. User1이 Sequencer1에 1000 TON 스테이킹
3. 시뇨리지 트리거
4. 보상 수령
5. 커미션 수령
6. 언스테이크 요청
7. 인출 (unbonding 이후)

#### 개별 스크립트

```bash
# TON 스테이킹
forge script script/InteractV3Upgradeable.s.sol:StakeTON --rpc-url http://localhost:8545 --broadcast

# 시뇨리지 트리거
forge script script/InteractV3Upgradeable.s.sol:TriggerSeigniorage --rpc-url http://localhost:8545 --broadcast

# 보상 수령
forge script script/InteractV3Upgradeable.s.sol:ClaimRewards --rpc-url http://localhost:8545 --broadcast

# 언스테이크
forge script script/InteractV3Upgradeable.s.sol:Unstake --rpc-url http://localhost:8545 --broadcast

# 인출
forge script script/InteractV3Upgradeable.s.sol:Withdraw --rpc-url http://localhost:8545 --broadcast

# 리델리게이션
forge script script/InteractV3Upgradeable.s.sol:Redelegate --rpc-url http://localhost:8545 --broadcast

# 커미션 수령 (시퀀서)
forge script script/InteractV3Upgradeable.s.sol:ClaimCommission --rpc-url http://localhost:8545 --broadcast

# 상태 조회
forge script script/InteractV3Upgradeable.s.sol:ViewState --rpc-url http://localhost:8545 --broadcast
```

### 기본 주소 (Anvil 결정적 배포)

DeployLocalV3Upgradeable.s.sol은 항상 동일한 주소에 배포됩니다:

| 역할 | 주소 |
|-----|------|
| Deployer (#0) | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` |
| Sequencer1 (#1) | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` |
| Sequencer2 (#2) | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` |
| User1 (#3) | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` |
| User2 (#4) | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` |

### 업그레이드 테스트

```bash
# 업그레이드 가능 테스트
forge test --match-path "test/DelegateStakingV3Upgradeable.t.sol" --match-test "Upgrade" -vvv
```
