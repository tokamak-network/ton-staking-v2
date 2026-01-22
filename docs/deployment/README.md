# TON Staking V3 배포 가이드

이 문서는 TON Staking V3 시스템을 새로운 체인에 처음부터 배포하는 방법을 설명합니다.

> **V3 업그레이드 표시 범례**
> - 🆕 **V3 신규**: V3에서 새로 추가된 컨트랙트/기능
> - 🔄 **V3 변경**: V3에서 수정/업그레이드된 부분
> - ⚠️ **V3 주의**: V3 업그레이드시 특별히 주의해야 할 사항

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [contracts.md](./contracts.md) | 컨트랙트별 상세 설명 (다중 구현체 패턴 등) |
| [scripts.md](./scripts.md) | 배포 스크립트 사용법, 파라미터, 메인넷 주소 |

---

## 배포 개요

### 배포 컨트랙트 목록 (메인넷 기준)

#### 1. 토큰 컨트랙트 (프록시 없음)
| 컨트랙트 | 설명 |
|----------|------|
| TON | 네이티브 TON 토큰 (ERC20) |
| WTON | Wrapped TON (ERC20) |

#### 2. 코어 인프라 (프록시 없음)
| 컨트랙트 | 설명 |
|----------|------|
| RefactorCoinageSnapshot | 코이니지 로직 |
| CoinageFactory | 코이니지 생성 팩토리 |

#### 3. 핵심 매니저 (프록시 패턴)
| 프록시 | 구현체 | V3 |
|--------|--------|-----|
| SeigManagerProxy | **SeigManagerV1_2** (기본) + **V3_1, V3_2** | 🆕 V3 추가 |
| DepositManagerProxy | **DepositManagerV3** | 🆕 단일 구현체 |
| Layer2RegistryProxy | Layer2Registry | - |
| Layer2ManagerProxy | **Layer2ManagerV3** | 🆕 단일 구현체 |
| L1BridgeRegistryProxy | **L1BridgeRegistryV1_2** | 🔄 단일 구현체 |

#### 4. 오퍼레이터
| 컨트랙트 | 설명 | V3 |
|----------|------|-----|
| OperatorManagerFactory | 오퍼레이터 매니저 생성 | 🔄 V1_2 기본 |
| OperatorManagerV1_2 | **V3 단일 구현체** | 🆕 |

#### 5. 🆕 V3 신규 컨트랙트 (프록시 패턴)
| 프록시 | 구현체 | 설명 |
|--------|--------|------|
| RATProxy | RAT | Randomized Attention Test |
| ValidatorRewardProxy | ValidatorRewardV1 | 검증자 보상 분배 |

---

## 사전 요구사항

### 필수 도구
- Foundry (forge, anvil) v0.2.0 이상
- Node.js v18+ (선택사항, 테스트용)
- Go 1.22+ (E2E 테스트용)

### 환경 변수
```bash
export PRIVATE_KEY=0x...
export RPC_URL=http://localhost:8545
```

---

## 배포 순서

배포는 **의존성 순서**를 반드시 지켜야 합니다.

### Phase 1: 토큰 배포

```
1. TON (ERC20)
2. WTON (Wrapped TON) - setTON(ton) 호출
```

### Phase 2: 코이니지 인프라

```
3. RefactorCoinageSnapshot (로직 컨트랙트)
4. CoinageFactory - setAutoCoinageLogic(coinageLogic)
```

### Phase 3: 레지스트리

```
5. Layer2Registry (Proxy + Implementation)
```

### Phase 4: 매니저 프록시 배포

```
6. SeigManagerProxy
7. DepositManagerProxy
8. Layer2ManagerProxy
9. L1BridgeRegistryProxy
```

### Phase 5: 매니저 구현체 배포 및 초기화

```
10. SeigManager
    - upgradeTo(seigManagerV1_2)
    - initialize(...)
    - setData(...)
    - V3_1, V3_2 Selector Routing

11. DepositManagerV3 (단일 구현체)
    - upgradeTo(depositManagerV3)
    - initialize(...)

12. Layer2ManagerV3 (단일 구현체)
    - upgradeTo(layer2ManagerV3)

13. L1BridgeRegistryV1_2 (단일 구현체)
    - upgradeTo(l1BridgeRegistryV1_2)
```

### Phase 5.5: Minter 권한 설정

```
14. Layer2Registry.addMinter(seigManagerProxy)
15. WTON.addMinter(seigManagerProxy)
```

### Phase 6: OperatorManagerFactory

```
16. OperatorManagerV1_2 (단일 구현체) - V3 기본 구현체
17. OperatorManagerFactory(operatorManagerV1_2Impl)
```

### Phase 7: V3 신규 컨트랙트

```
18. RAT (Proxy + Implementation)
    - initialize(RATInitParams) - 구조체로 모든 파라미터 전달

19. ValidatorReward (Proxy + Implementation)
    - initialize(seigManager, wton, rat, owner)
```

### Phase 8: Cross-Reference 설정

```
20. SeigManager.setLayer2Manager(layer2Manager)
21. SeigManager.setValidatorReward(validatorReward)
22. SeigManager.setRAT(ratProxy)

23. Layer2ManagerV3.setAddresses(...)

24. L1BridgeRegistryV1_2.setAddresses(...)

25. OperatorManagerFactory.setAddresses(...)
26. DepositManagerV3.setAddresses(l1BridgeRegistry, layer2Manager)
```

---

## TYPE 3 업그레이드 절차

기존 TYPE 1/2 롤업이 DisputeGame을 도입하여 TYPE 3로 업그레이드하려면:

```solidity
// Step 1: L1BridgeRegistry에서 TYPE 업그레이드
L1BridgeRegistry(l1BridgeRegistryProxy).upgradeToType3(rollupConfig);

// Step 2: 시퀀서 담보금 예치 (기존 스테이킹 시스템 사용)
// 시퀀서는 DepositManagerV3를 통해 스테이킹합니다.
DepositManagerV3(depositManagerProxy).deposit(layer2, operator, amount);

// 담보금 조회
SeigManager(seigManagerProxy).getSequencerStaked(layer2);
```

---

## 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                    TON Staking V3 Architecture                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     │
│  │     TON      │     │     WTON     │     │  Coinage     │     │
│  │   (ERC20)    │◄───►│   (ERC20)    │◄───►│   Factory    │     │
│  └──────────────┘     └──────────────┘     └──────────────┘     │
│         │                    │                    │              │
│         ▼                    ▼                    ▼              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    SeigManager                           │    │
│  │           (시뇨리지 계산 및 분배 핵심 로직)               │    │
│  │         V3: 시퀀서/검증자 담보금 = coinage 스테이킹       │    │
│  └─────────────────────────────────────────────────────────┘    │
│         │                    │                    │              │
│         ▼                    ▼                    ▼              │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     │
│  │   Deposit    │     │   Layer2     │     │ L1Bridge     │     │
│  │   Manager    │     │   Manager    │     │  Registry    │     │
│  └──────────────┘     └──────────────┘     └──────────────┘     │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    V3 New Contracts                      │    │
│  │  ┌──────────────────────┐ ┌──────────────────────┐      │    │
│  │  │         RAT          │ │   ValidatorReward    │      │    │
│  │  │  (Randomized         │ │   (검증자 보상 분배)  │      │    │
│  │  │   Attention Test)    │ │                      │      │    │
│  │  └──────────────────────┘ └──────────────────────┘      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```
