---
id: actors-sequencer
sidebar_position: 3
---

# 시퀀서

## 정의

L2 롤업의 트랜잭션 순서를 결정하고 배치를 제출하는 운영자입니다.

## 역할

- L2 트랜잭션 순서 결정
- 배치 데이터를 L1에 제출
- Output Root 제출 (DisputeGame 생성)
- 기존 스테이킹 시스템(coinage)에 담보금 예치

## 보상

```
시퀀서 보상 = o_i = (1 - α) · S_i

여기서:
- S_i = L2 i의 시뇨리지 = y(x) · (B̃_i / x)
- α = 검증자 분배 비율 (예: 20%)
```

## 리스크

**Fraud 발생 시 담보금 전액 슬래싱**

```
시퀀서 담보금 = D_sequencer = H_max · C_max + Δ_sequencer

슬래싱 시:
- 챌린저 보상: C_max + Δ/n (각 챌린저에게)
- 나머지: DAO Treasury
```

## 자격 조건

```
T_i ≥ max(θ · B_i, H_max · C_max + Δ_sequencer)

여기서:
- T_i = 시퀀서 스테이킹 금액 (SeigManager.getSequencerStaked(layer2))
- θ · B_i = 시뇨리지 자격 조건 (백서 Rule 4)
- H_max · C_max + Δ_sequencer = Fraud Proof 비용 커버 (백서 Formula 1)

파라미터:
- θ = 최소 스테이킹 비율 (예: 10%)
- B_i = Bridged TON
- H_max = 최대 동시 챌린저 수
- C_max = 단일 Fraud Proof 최대 비용
- Δ_sequencer = 시퀀서 추가 보상
```

## 상호작용

```
┌────────────────────────────────────────────────────────────┐
│                         시퀀서                              │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 담보금 예치 (기존 스테이킹 사용):                     │   │
│  │   DepositManager.deposit(layer2, amount)             │   │
│  │   → SeigManager.getSequencerStaked(layer2)로 담보금 조회│
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 운영:                                                │   │
│  │   1. L2 트랜잭션 수집 및 순서 결정                    │   │
│  │   2. 배치 데이터 L1 제출                              │   │
│  │   3. Output Root 제출 (DisputeGameFactory.create)    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 시뇨리지 분배 (V3):                                   │   │
│  │   SeigManager.updateSeigniorage() 호출 시            │   │
│  │   → 자격 조건 충족 시 (T_i ≥ max(θ·B_i, D_seq))      │   │
│  │   → 시퀀서 보상: o_i = (1-α) · S_i                   │   │
│  │   → WTON 민팅 → Layer2Manager → OperatorManager     │   │
│  │   ※ V3: 일반 스테이커 시뇨리지 없음                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 보상 수령:                                           │   │
│  │   OperatorManager.claimERC20(wton, amount)           │   │
│  │   → OperatorManager에 누적된 WTON 수령               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 스테이킹 금액 출금:                                   │   │
│  │   DepositManager.requestWithdrawal(layer2, amount)   │   │
│  │   (2주 대기 후 processRequest)                       │   │
│  │   ※ 담보금(max(θ·B_i, D_seq)) 이하로 출금 불가       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## 시퀀서 여정 가이드

신규 시퀀서가 V3 시스템에 참여하는 전체 프로세스입니다.

### 신규 시퀀서 참여 플로우

**1단계: L2 등록**

```solidity
// 1. L1BridgeRegistry를 통해 L2 등록
L1BridgeRegistry.registerRollupConfig(
    systemConfig,  // rollupConfig 주소
    type,          // 1=TOKAMAK, 2=BEDROCK, 3=BEDROCK_WITH_DISPUTE_GAME
    l2TON,         // L2 TON 주소
    "L2 Name"
);

// 2. Layer2Manager를 통해 CandidateAddOn(시퀀서) 등록 및 초기 담보금 예치
// 방법 A: TON으로 예치
Layer2Manager.registerCandidateAddOn(
    systemConfig,
    initialAmount,  // TON 단위 (minimumInitialDepositAmount 이상)
    true,           // flagTon = true
    "memo"
);

// 방법 B: WTON으로 예치
Layer2Manager.registerCandidateAddOn(
    systemConfig,
    initialAmount,  // WTON 단위 (RAY)
    false,          // flagTon = false
    "memo"
);

// 또는 TON.approveAndCall 사용
TON.approveAndCall(
    Layer2Manager,
    initialAmount,
    abi.encode(systemConfig, "memo")
);
```

**2단계: V3 자격 확인**

**방법 A: 함수 직접 호출 (view 함수)**
```solidity
// 현재 자격 상태 조회
(bool eligible, uint256 required, uint256 current) = 
    SeigManager.checkCurrentEligibility(layer2);

// eligible: 현재 자격 여부
// required: 필요한 담보금 = max(θ × B_i, D_sequencer)
// current: 현재 스테이킹 금액
```

**방법 B: 이벤트 모니터링 (권장)**
```solidity
// EligibilityChanged 이벤트 구독
event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);

// 발생 시점:
// - onBridgedTonChange() 시 (TYPE 3)
// - onDeposit() / onWithdraw() 시
// - updateSeigniorage() 시
```

**3단계: 시뇨리지 자격 미달 시 추가 예치 (선택)**

V3에서는 자격 조건을 만족해야 시뇨리지를 받습니다:
- `T_i ≥ max(θ·B_i, D_sequencer)`
- 초기 등록 시 `minimumInitialDepositAmount`만으로는 자격 부족 가능
- 특히 Bridged TON(B_i)이 증가하면 필요 담보금도 증가

```solidity
if (!eligible) {
    // 부족 금액 계산
    uint256 shortage = required - current;
    
    // 추가 예치하여 자격 회복
    DepositManager.deposit(layer2, shortage);
    
    // onDeposit() 자동 호출 → 자격 재평가
    // 또는 다음 updateSeigniorage() 시 자격 체크
}
```

**참고**: 자격 미달 상태에서도:
- L2는 정상 운영됨 (블록 생산 가능)
- 시뇨리지만 받지 못함 (`effectiveBridgedTON = 0`)

**4단계: 시뇨리지 받기**

시뇨리지는 두 단계로 분배됩니다:

```solidity
// 1단계: SeigManager에서 OperatorManager로 자동 전송
//        (누구나 updateSeigniorage() 호출 가능)
SeigManager.updateSeigniorage();
// ↓
// Layer2Manager.transferL2Seigniorage() 호출
// ↓
// OperatorManager에 WTON 전송

// 2단계: OperatorManager에서 시퀀서로 클레임
//        (owner 또는 manager만 호출 가능)
OperatorManager.claimERC20(WTON_ADDRESS, amount);
// ↓
// manager 주소로 WTON 전송
```

### 슬래싱 및 복구

**슬래싱 발생**:

```
1. 잘못된 Output Root 제출
   ↓
2. 챌린저가 Fraud Proof 제출
   ↓
3. DisputeGame 해결 (DEFENDER_WINS 아닌 상태)
   ↓
4. 누구나 slashSequencerByGame(gameAddress) 호출
   ↓
5. 전체 담보금 몰수 (coinage.burnFrom)
   - 챌린저 보상: C_max + Δ/n
   - 나머지: DAO Treasury
   ↓
6. 이벤트: SequencerSlashed
```

**복구 불가능**:
- 슬래싱 시 전체 담보금 손실
- L2 재등록 필요
- 신규 시퀀서로 처음부터 시작
