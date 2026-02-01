# Sequencer Delegate Staking 설계 문서

> **Version**: 1.0  
> **Date**: 2026-01-21  
> **Status**: Draft

---

## 1. 개요

### 1.1 배경

Tokamak Network V3에서는 시뇨리지 분배 기준이 **Bridged TON**으로 변경됩니다. 기존 V2에서는 일반 사용자가 직접 L1에 스테이킹하여 보상을 받을 수 있었으나, V3에서는 Sequencer와 Validator만 직접적인 보상 수령 대상이 됩니다.

이로 인해 일반 사용자가 스테이킹에 참여할 수 있는 경로가 사라지게 되며, 이를 해결하기 위한 **Delegate Staking** 메커니즘을 제안합니다.

### 1.2 목적

- 일반 사용자가 TON을 Sequencer에게 위임하여 간접적으로 시뇨리지 보상을 받을 수 있는 구조 제공
- V3의 Bridged TON 기반 시뇨리지 분배 구조와 자연스럽게 연동
- Sequencer 신뢰 최소화를 위한 Permissionless 보상 분배

### 1.3 V2 vs V3 비교

| 항목 | V2 | V3 |
|------|-----|-----|
| 스테이킹 주체 | 일반 사용자 직접 스테이킹 | Sequencer만 스테이킹 |
| 보상 기준 | L1 스테이킹 양 비례 | Bridged TON (L2 브릿지된 TON) |
| 사용자 참여 | Staker로서 직접 참여 | 직접 참여 불가 |
| 시뇨리지 분배 | Staker ↔ Sequencer ↔ DAO | Sequencer ↔ Validator ↔ DAO |

---

## 2. 시스템 아키텍처

### 2.1 전체 구조

```
                                    L1 (Ethereum)
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                         ┌─────────────────────────┐                         │
│                         │    V3 Seigniorage       │                         │
│                         │    Distribution         │                         │
│                         └───────────┬─────────────┘                         │
│                                     │ 시뇨리지                               │
│                                     ▼                                        │
│   ┌─────────┐         ┌─────────────────────────────┐                       │
│   │  User   │──TON───►│   SequencerDelegateStaking  │◄──── 보상 수령        │
│   │(Delegator)        │         Contract            │                       │
│   └─────────┘         └─────────────┬───────────────┘                       │
│        ▲                            │                                        │
│        │                            │ Bridge                                 │
│        │ rewards                    ▼                                        │
│        │              ┌─────────────────────────────┐                       │
│        │              │        L2 Bridge            │                       │
│        │              │       (Canonical)           │                       │
│        │              └─────────────┬───────────────┘                       │
│        │                            │                                        │
└────────┼────────────────────────────┼────────────────────────────────────────┘
         │                            │
         │                            │
─────────┼────────────────────────────┼─────────────────────────────────────────
         │                            │
         │                    L2 (Tokamak L2)                                   
         │                            │                                        
         │              ┌─────────────▼───────────────┐                       
         │              │     Sequencer Vault         │                       
         │              │   (Bridged TON 보관)        │                       
         │              │                             │                       
         │              │  • 출금 권한: L1 Contract만 │                       
         │              │  • Sequencer 사용 불가      │                       
         │              └─────────────────────────────┘                       
         │                            │                                        
         │                            ▼                                        
         │                   Bridged TON (B_i) 증가                            
         │                            │                                        
         │                            ▼                                        
         └─────────────── 시뇨리지 S_i 증가 ──────────┘                        
```

### 2.2 핵심 컴포넌트

| 컴포넌트 | 위치 | 역할 |
|----------|------|------|
| SequencerDelegateStaking | L1 | 위임 관리, 보상 분배, 출금 처리 |
| L2 Bridge | L1 ↔ L2 | TON 브릿지 |
| Sequencer Vault | L2 | 위임된 TON 보관 (락업) |

---

## 3. V3 시뇨리지 연동

### 3.1 V3 시뇨리지 공식

```
S_i = y(x) · B̃_i / x

여기서:
- y(x) = L · x / (k + x)     // 포화 함수 (Hyperbolic Saturation)
- x = Σ B̃_i                  // 전체 eligible L2의 Bridged TON 합계
- B̃_i = 1_i · B_i            // eligible L2의 Bridged TON
- 1_i = 1 if T_i ≥ θ · B_i   // 최소 스테이킹 요건 충족 시

Sequencer 보상: o_i = (1 - α) · S_i
Validator 보상: v_j = Σ (α · S_i / |V_i|)
```

### 3.2 위임의 효과

```
위임 증가 → L2로 브릿지 → B_i (Bridged TON) 증가 → S_i (시뇨리지) 증가
```

**주의**: Sequencer는 최소 스테이킹 요건 `T_i ≥ θ · B_i`를 충족해야 시뇨리지 수령 가능

---

## 4. 상세 설계

### 4.1 Sequencer 관리

#### 4.1.1 등록

| 항목 | 설명 |
|------|------|
| 등록 권한 | Sequencer 본인만 가능 |
| 필수 정보 | L2 Vault 주소, Commission 비율 |
| Commission 범위 | 제한 없음 (0-100%) |

```solidity
function registerSequencer(address l2Vault, uint256 commission) external;
```

#### 4.1.2 탈퇴

| 항목 | 설명 |
|------|------|
| 탈퇴 조건 | 위임자 전원 출금 완료 후 |
| 검증 | `totalDelegated == 0` |

```solidity
function deregisterSequencer() external;
// requires: sequencers[msg.sender].totalDelegated == 0
```

#### 4.1.3 Commission 변경

| 항목 | 설명 |
|------|------|
| 변경 권한 | Sequencer 본인 |
| 적용 시점 | 다음 distribute() 호출 시 |

### 4.2 위임 (Delegation)

#### 4.2.1 위임 흐름

```
1. User가 delegate(sequencer, amount) 호출
2. Contract가 TON 수령
3. Contract가 L2 Bridge를 통해 Sequencer Vault로 브릿지
4. 위임 정보 기록 (delegator, sequencer, amount)
5. Sequencer의 totalDelegated 증가
```

#### 4.2.2 위임 조건

| 항목 | 값 |
|------|-----|
| 최소 위임 금액 | 1,000 TON |
| 위임 상한선 | 없음 |

#### 4.2.3 재위임 (Redelegate)

| 항목 | 설명 |
|------|------|
| 조건 | 기존에 위임 중인 Sequencer 간에만 가능 |
| DTD 대기 | 없음 (즉시 이동) |
| 용도 | Sequencer 간 위임 비율 조정 |

```solidity
function redelegate(address fromSequencer, address toSequencer, uint256 amount) external;
// requires: delegations[msg.sender][fromSequencer].amount > 0
// requires: delegations[msg.sender][toSequencer].amount > 0
```

### 4.3 출금 (Undelegation)

#### 4.3.1 출금 흐름

```
Day 0:  requestUndelegate() 호출
        └─► L2 Vault에서 출금 요청 시작
        └─► pendingWithdrawal 기록

Day 1-14: DTD (Dispute Time Delay) 대기
          └─► 이 기간 동안 Challenge 가능

Day 14+: withdraw() 호출 가능
         └─► L1에서 TON 수령
```

#### 4.3.2 출금 조건

| 항목 | 값 |
|------|-----|
| DTD 기간 | 14일 |
| Fast Withdrawal | 미지원 |
| 부분 출금 | 가능 |

### 4.4 보상 분배

#### 4.4.1 보상 수령

```
V3 Protocol ──시뇨리지──► SequencerDelegateStaking Contract
                                    │
                                    ▼
                         pendingRewards[sequencer] += amount
```

- V3에서 Sequencer 보상 수령 주소를 DelegateContract로 설정
- 보상이 자동으로 `pendingRewards`에 누적

#### 4.4.2 분배 메커니즘 (MasterChef 패턴)

```solidity
// 상태 변수
mapping(address => uint256) public pendingRewards;      // 미분배 보상
mapping(address => uint256) public accRewardPerShare;   // 누적 보상 per share

// 분배 함수 (누구나 호출 가능)
function distribute(address sequencer) external {
    uint256 amount = pendingRewards[sequencer];
    pendingRewards[sequencer] = 0;
    
    uint256 commission = amount * sequencers[sequencer].commission / 10000;
    uint256 delegatorRewards = amount - commission;
    
    // Commission → Sequencer
    ton.transfer(sequencer, commission);
    
    // 위임자 보상 → 장부 업데이트
    accRewardPerShare[sequencer] += delegatorRewards * PRECISION / totalDelegated;
}

// 청구 함수
function claimRewards(address sequencer) external {
    // 미분배 보상 있으면 먼저 분배
    if (pendingRewards[sequencer] > 0) {
        _distribute(sequencer);
    }
    
    // 내 몫 계산 및 전송
    uint256 reward = _calculateReward(msg.sender, sequencer);
    ton.transfer(msg.sender, reward);
}
```

#### 4.4.3 보상 계산

```
내 보상 = (내 위임량 × accRewardPerShare / PRECISION) - rewardDebt
```

### 4.5 슬래싱

#### 4.5.1 슬래싱 정책

| 항목 | 설명 |
|------|------|
| 슬래싱 대상 | Sequencer 담보 (D_sequencer)만 |
| 위임자 영향 | 없음 (위임된 TON 보호) |

#### 4.5.2 슬래싱 시나리오

```
Sequencer가 Fraud Proof에서 패배
        │
        ▼
D_sequencer 슬래싱 (V3 프로토콜에서 처리)
        │
        ▼
위임된 TON (L2 Vault) → 영향 없음
        │
        ▼
위임자는 정상적으로 출금 가능
```

---

## 5. Sequencer Vault (L2)

### 5.1 역할

- 위임된 TON 보관
- Bridged TON (B_i) 기여
- 출금 요청 처리

### 5.2 권한 구조

| 작업 | 권한 |
|------|------|
| 입금 | L2 Bridge (브릿지 완료 시) |
| 출금 | DelegateContract만 (L1 → L2 메시지) |
| 기타 사용 | 불가 (DeFi, 전송 등) |

### 5.3 설계 원칙

```solidity
contract SequencerVault {
    address public immutable delegateContract;  // L1 DelegateContract 주소
    address public immutable sequencer;
    
    // 출금은 DelegateContract의 L2 메시지만 허용
    function withdraw(address to, uint256 amount) external onlyDelegateContract {
        ton.transfer(to, amount);
    }
    
    // Sequencer도 임의 출금 불가
    // DeFi 등 외부 사용 불가
}
```

---

## 6. 데이터 구조

### 6.1 Sequencer 정보

```solidity
struct SequencerInfo {
    bool isRegistered;           // 등록 여부
    address l2Vault;             // L2 Vault 주소
    uint256 commission;          // 수수료 (basis points, 10000 = 100%)
    uint256 totalDelegated;      // 총 위임받은 양
    uint256 accRewardPerShare;   // 누적 보상 per share
}
```

### 6.2 위임 정보

```solidity
struct DelegationInfo {
    uint256 amount;                  // 위임 금액
    uint256 rewardDebt;              // 보상 계산용
    uint256 pendingWithdrawal;       // 출금 대기 금액
    uint256 withdrawalRequestTime;   // 출금 요청 시간
}
```

---

## 7. 함수 명세

### 7.1 Sequencer 함수

| 함수 | 설명 | 권한 |
|------|------|------|
| `registerSequencer(l2Vault, commission)` | Sequencer 등록 | Sequencer |
| `deregisterSequencer()` | Sequencer 탈퇴 | Sequencer |
| `updateCommission(commission)` | Commission 변경 | Sequencer |

### 7.2 위임자 함수

| 함수 | 설명 | 권한 |
|------|------|------|
| `delegate(sequencer, amount)` | TON 위임 | 누구나 |
| `requestUndelegate(sequencer, amount)` | 출금 요청 | 위임자 |
| `withdraw()` | 출금 완료 | 위임자 |
| `redelegate(from, to, amount)` | 재위임 | 위임자 |
| `claimRewards(sequencer)` | 보상 청구 | 위임자 |

### 7.3 공용 함수

| 함수 | 설명 | 권한 |
|------|------|------|
| `distribute(sequencer)` | 보상 분배 | 누구나 |

---

## 8. 이벤트

```solidity
event SequencerRegistered(address indexed sequencer, address l2Vault, uint256 commission);
event SequencerDeregistered(address indexed sequencer);
event CommissionUpdated(address indexed sequencer, uint256 oldCommission, uint256 newCommission);

event Delegated(address indexed delegator, address indexed sequencer, uint256 amount);
event UndelegationRequested(address indexed delegator, address indexed sequencer, uint256 amount);
event Withdrawn(address indexed delegator, uint256 amount);
event Redelegated(address indexed delegator, address indexed from, address indexed to, uint256 amount);

event RewardsDistributed(address indexed sequencer, uint256 totalAmount, uint256 commission);
event RewardsClaimed(address indexed delegator, address indexed sequencer, uint256 amount);
```

---

## 9. 보안 고려사항

### 9.1 Reentrancy

- 모든 외부 호출 전 상태 변경 (Checks-Effects-Interactions)
- ReentrancyGuard 적용

### 9.2 Sequencer Vault 보안

- 출금 권한을 DelegateContract로 제한
- Sequencer의 임의 사용 방지

### 9.3 보상 분배 정확성

- MasterChef 패턴의 정밀도 손실 최소화 (PRECISION = 1e18)
- 오버플로우 방지 (Solidity 0.8+)

### 9.4 Bridge 리스크

- Canonical Bridge 사용 (검증된 브릿지)
- 점진적 위임 권장

---

## 10. 미결정 사항

| 항목 | 상태 | 비고 |
|------|------|------|
| L2 Bridge 인터페이스 | 확인 필요 | Tokamak L2 브릿지 스펙 확인 |
| V3 보상 수령 주소 설정 | 가정 | 컨트랙트 주소 설정 가능 가정 |
| Sequencer Vault 배포 주체 | 미정 | Sequencer vs Protocol |

---

## 11. 향후 고려사항

### 11.1 Fast Withdrawal

- 현재: 미지원
- 향후: 유동성 풀 기반 Fast Withdrawal 추가 가능

### 11.2 Liquid Staking

- 현재: 미지원
- 향후: stTON 토큰 발행하여 DeFi 통합 가능

### 11.3 다중 Sequencer 위임

- 현재: 지원 (여러 Sequencer에 분산 위임)
- 고려: 자동 리밸런싱 기능

---

## 부록 A: 용어 정의

| 용어 | 정의 |
|------|------|
| Bridged TON (B_i) | L2에 브릿지된 TON 총량 |
| DTD | Dispute Time Delay, 출금 대기 기간 |
| Commission | Sequencer가 보상에서 가져가는 수수료 비율 |
| accRewardPerShare | 위임 단위당 누적 보상 (MasterChef 패턴) |
| rewardDebt | 이미 반영된 보상 (중복 수령 방지) |

## 부록 B: 참고 문서

- [Tokamak Economics Whitepaper V3](./Tokamak_Economics_Whitepaper_V3.pdf)
- [Staking V2 Documentation](./StakingV2.md)
