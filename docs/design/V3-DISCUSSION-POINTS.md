# Delegate Staking MVP - V3 개발팀 논의 사항

**작성일**: 2026-01-28
**목적**: ton-staking-v3 개발팀과 MVP 통합 논의

---

## 1. 개발 완료 현황

### 1.1 MVP 구현 요약

| 항목 | 상태 | 비고 |
|------|------|------|
| DelegateStakingMVP.sol | ✅ 완료 | 433 LOC |
| 테스트 스위트 | ✅ 완료 | 38개 테스트 통과 |
| 인터페이스 | ✅ 완료 | IDelegateStakingMVP.sol |

### 1.2 MVP 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                 Sequencer Trust Model (MVP)                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  SeigManager ──WTON──► OperatorManager                       │
│                              │                               │
│                              ▼                               │
│                    Sequencer가 claimERC20()                  │
│                              │                               │
│                              ▼                               │
│  DelegateStakingMVP ◄──────WTON────── Sequencer 수동 전송    │
│       │                                                      │
│       ├─► accRewardPerShare 업데이트 (MasterChef 패턴)       │
│       │                                                      │
│       └─► Delegator들 claimRewards() → WTON 보상 수령        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 주요 기능

**Sequencer 함수:**
- `registerSequencer(layer2, commission)` - Sequencer 등록
- `receiveReward(amount)` - 보상 입금 (WTON)
- `claimCommission()` - 커미션 청구

**Delegator 함수:**
- `stake(sequencer, amount)` - TON 스테이킹
- `unstake(sequencer, amount)` - 언스테이크 요청
- `withdraw(sequencer)` - 출금 (unbonding 후)
- `claimRewards(sequencer)` - WTON 보상 청구

---

## 2. V3 팀과 논의 필요 사항

### 2.1 보상 수령 메커니즘 (가장 중요)

**현재 MVP 방식 (Sequencer Trust Model):**
```
V3 Protocol → OperatorManager → Sequencer Wallet → DelegateStakingMVP
```

**질문:**
1. **프로토콜 수정 가능 여부**: `operatorOfLayer[layer2]`를 DelegateStaking 컨트랙트로 설정할 수 있나요?
2. **OperatorManager 확장**: receiveReward 시 자동으로 DelegateStaking에 전달하는 로직 추가 가능한가요?
3. **Alternative**: 프로토콜 수정 없이 안전하게 보상을 받을 다른 방법이 있나요?

**제안된 옵션:**

| 옵션 | 설명 | V3 수정 필요 |
|------|------|-------------|
| A. 직접 수령 | DelegateStaking이 operator 역할 | Layer2Manager 수정 |
| B. OperatorManager 확장 | 보상 자동 전달 | OperatorManager 수정 |
| C. 현재 MVP 방식 | Sequencer 수동 전달 | 없음 |
| D. Approve 모델 | Sequencer가 approve, 누구나 전달 | 없음 |

### 2.2 Bridged TON 증가 메커니즘

**MVP 현재 방식:**
- TON은 L1 DelegateStakingMVP 컨트랙트에 보관
- Sequencer가 별도로 L2 브릿지하여 B_i 증가

**질문:**
1. **자동 브릿지 지원**: DelegateStaking → L2 Vault 자동 브릿지 인터페이스 제공 가능한가요?
2. **TVL 반영 시점**: 브릿지 후 `layer2TVL()`에 언제 반영되나요?
3. **Vault 구조**: Sequencer별 L2 Vault 표준 구조가 있나요?

### 2.3 자격 요건 (Eligibility) 연동

**현재 이해:**
```
T_i ≥ max(θ × B_i, D_sequencer)
```

**질문:**
1. **자격 조회 API**: `checkCurrentEligibility(layer2)` 정확한 반환 값과 의미는?
2. **위임 증가 시 주의**: B_i 증가 시 T_i 요구량도 증가하는데, Sequencer에게 경고하는 메커니즘이 있나요?
3. **자격 상실 시**: 자격 상실 시 기존 보상은 어떻게 처리되나요?

### 2.4 출금 대기 기간 (DTD)

**MVP 현재 방식:**
- 단순 unbondingPeriod (기본 7일) 후 출금

**질문:**
1. **실제 DTD**: L2 → L1 브릿지 시 실제 대기 기간은?
2. **검증 메커니즘**: 출금 검증 (Optimism fraud proof 등) 연동 필요한가요?
3. **긴급 출금**: Full Version에서 긴급 출금 메커니즘 지원 계획?

---

## 3. 기술적 확인 사항

### 3.1 컨트랙트 주소 (Mainnet)

| 컨트랙트 | 주소 | 확인 필요 |
|----------|------|-----------|
| TON | ? | ✓ |
| WTON | ? | ✓ |
| SeigManager | ? | ✓ |
| Layer2Manager | ? | ✓ |
| L1BridgeRegistry | ? | ✓ |

### 3.2 토큰 단위 검증

**현재 이해:**
```
TON:  18 decimals
WTON: 27 decimals (RAY)
```

**질문:**
1. 위 단위가 정확한가요?
2. TON ↔ WTON 변환 시 `* 1e9` / `/ 1e9` 사용이 맞나요?

### 3.3 V3 함수 시그니처 확인

```solidity
// 사용 예정 함수들
SeigManager.checkCurrentEligibility(layer2) → (bool, uint256, uint256)
SeigManager.getSequencerStaked(layer2) → uint256
Layer2Manager.operatorOfLayer(layer2) → address
L1BridgeRegistry.layer2TVL(systemConfig) → uint256
```

**질문:** 위 시그니처가 현재 V3와 일치하나요?

---

## 4. 향후 로드맵 협의

### 4.1 Full Version 고려사항

| 기능 | MVP | Full Version | V3 지원 필요? |
|------|-----|--------------|---------------|
| TON 보관 | L1 컨트랙트 | L2 Vault | ✓ |
| 보상 수령 | Sequencer 수동 | 프로토콜 직접 | ✓ |
| 브릿지 | Sequencer 별도 | 자동 브릿지 | ✓ |
| 출금 | 단순 unbonding | DTD 14일 + 검증 | ✓ |

### 4.2 프로토콜 수정 요청 (있다면)

**Option A 선택 시 필요한 수정:**
```solidity
// Layer2ManagerV3.sol
function setDelegateStaking(address layer2, address delegateStaking) external;

// 또는 기존 operatorOfLayer 설정 권한 확장
```

**Option B 선택 시 필요한 수정:**
```solidity
// OperatorManagerV1_2.sol
function setRewardReceiver(address receiver) external;
function claimAndForward() external;
```

---

## 5. 테스트 및 검증 계획

### 5.1 Fork 테스트 계획

```bash
# Mainnet fork 테스트
forge test --fork-url $MAINNET_RPC --match-contract IntegrationTest
```

**테스트 시나리오:**
1. 실제 V3 컨트랙트와 연동
2. Eligibility 조회 및 검증
3. 보상 분배 시뮬레이션

### 5.2 테스트넷 배포 계획

- Sepolia 또는 Titan Sepolia
- V3 테스트넷 컨트랙트 연동

**질문:** V3 테스트넷 컨트랙트 주소 제공 가능한가요?

---

## 6. 일정 및 협업

### 6.1 제안 일정

| 단계 | 예상 기간 | 의존성 |
|------|----------|--------|
| V3 팀 논의 | 1주 | - |
| 통합 방식 결정 | - | 논의 결과 |
| Fork 테스트 | 1주 | 컨트랙트 주소 |
| 테스트넷 배포 | 1주 | 테스트넷 주소 |

### 6.2 필요 자료 요청

1. V3 컨트랙트 주소 (Mainnet, Testnet)
2. L2 브릿지 인터페이스 문서
3. OperatorManager 확장 가이드 (Option B 선택 시)

---

## 7. 부록: 코드 참조

### 7.1 MVP 주요 파일

```
delegate-staking/
├── src/
│   ├── DelegateStakingMVP.sol       # MVP 구현
│   └── interfaces/
│       └── IDelegateStakingMVP.sol  # 인터페이스
├── test/
│   ├── DelegateStakingMVP.t.sol     # 테스트 (38개)
│   └── mocks/
│       └── WTONMock.sol             # WTON 모의 (27 decimals)
└── docs/
    ├── DEVELOPMENT-CONSIDERATIONS.md
    └── ton-staking-v3-analysis.md   # V3 분석 문서
```

### 7.2 핵심 로직 (보상 분배)

```solidity
// DelegateStakingMVP.sol:152-179
function receiveReward(uint256 amount) external override nonReentrant {
    // Sequencer가 WTON 보상을 입금
    wton.safeTransferFrom(msg.sender, address(this), amount);

    // 커미션 계산
    uint256 commission = (amount * info.commission) / 10000;
    uint256 distributed = amount - commission;

    // MasterChef 패턴으로 분배
    if (info.totalStaked > 0) {
        info.accRewardPerShare += (distributed * RAY) / info.totalStaked;
    }
}
```

---

*이 문서는 V3 개발팀과의 기술 논의를 위해 작성되었습니다.*
