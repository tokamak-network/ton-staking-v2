# Optimism RAT 연동 가이드

이 문서는 Optimism 개발자가 TON Staking V3의 RAT(Randomized Attention Test) 시스템과 연동하기 위해 구현해야 하는 내용을 정리합니다.

---

## 요약: Optimism에서 구현해야 하는 것

Optimism에서 TON V3와 연동하기 위해 다음 함수 호출을 추가해야 합니다:

### A. L2 등록 (Rollup Type)

TON V3에서 L2를 등록할 때 타입을 지정합니다. DisputeGame을 지원하는 L2는 **Type 3**으로 등록합니다.

| Rollup Type | 설명 | Native TON | TON 보관 위치 | DisputeGameFactory |
|-------------|------|:----------:|:------------:|:------------------:|
| **Type 1 (Legacy)** | Optimism Legacy with Native TON | ✅ | L1StandardBridge | 미사용 |
| **Type 2 (Bedrock)** | Bedrock with Native TON | ✅ | OptimismPortal | 미사용 |
| **Type 3 (Bedrock with DG)** | Bedrock with Native TON + DisputeGame | ✅ | OptimismPortal | **자동 등록** |

> **Native TON**: 모든 타입이 L2에서 TON을 네이티브 토큰으로 사용합니다.
> - Type 1: TON은 L1StandardBridge에 보관
> - Type 2/3: TON은 OptimismPortal에 보관

```solidity
// L1BridgeRegistryV1_2.sol
function registerRollupConfig(
    address rollupConfig,  // SystemConfig 주소
    uint8 _type,           // 3 = OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
    address _l2TON,
    string calldata _name
) external onlyRegistrant;
```

**Type 3 등록 시 자동으로 저장되는 정보:**
1. `l1Bridge[bridge] = true` - L1StandardBridge 등록
2. `portal[portal] = true` - OptimismPortal 등록
3. `disputeGameFactory[rollupConfig] = true` - DisputeGameFactory 등록 여부
4. `rollupConfigWithDisputeGameFactory[factory] = rollupConfig` - 역방향 매핑 (factory → rollupConfig)

```solidity
// L1BridgeRegistryV1_2Storage.sol
contract L1BridgeRegistryV1_2Storage {
    /// @notice rollupConfig => DisputeGameFactory 등록여부
    mapping(address => bool) public disputeGameFactory;

    /// @notice DisputeGameFactory => rollupConfig (역방향 매핑)
    mapping(address => address) public rollupConfigWithDisputeGameFactory;
}
```

**역방향 매핑 용도**: RAT에서 `triggerAttentionTest` 호출 시 factory 주소로 rollupConfig를 조회하여 L2를 식별합니다.

### B. RAT (Randomized Attention Test) 연동

| 컴포넌트 | 호출할 함수 | 시점 |
|---------|------------|------|
| **DisputeGameFactory** | `IRAT.triggerAttentionTest(...)` | DisputeGame 생성 시 |
| **FaultDisputeGame** | `IRAT.resolveClaim(winner)` | 챌린저 승리 시 |

### C. Bridged TON (TVL) 변경 알림 (타입 3 전용)

**타입 3만 지원**: OptimismPortal이 SeigManager를 직접 호출합니다.

| L2 타입 | TON 보관 위치 | 호출할 함수 | 시뇨리지 제공 (신규백서) |
|--------|-------------|------------|------|
| **Type 1 (Legacy)** | L1StandardBridge | - | 미지원 |
| **Type 2 (Bedrock)** | OptimismPortal | - | 미지원 |
| **Type 3 (Bedrock with DG)** | OptimismPortal | `ISeigManager.onBridgedTONChange()` | **지원** |

> **중요 사항**:
> - **타입 3만 지원**: 타입 1/2 롤업은 이 함수를 사용하지 않습니다
> - **호출자 식별**: SeigManager가 `msg.sender`(OptimismPortal)로부터 rollupConfig를 조회
> - **트리거 함수**: revert 대신 early return 사용 - 호출자 트랜잭션 실패 방지

### D. 시퀀서 슬래싱

**Optimism 수정 불필요!** - TON V3에서 게임 상태를 직접 조회하여 Permissionless 방식으로 처리

| 호출 방식 | 설명 |
|---------|------|
| 누구나 `SeigManager.slashSequencerByGame(gameAddress)` 호출 | TON V3가 FaultDisputeGame에서 `status()`, `claimData` 등 조회하여 검증 |

---

## 1. 개요

### 1.1 RAT란?

RAT(Randomized Attention Test)는 L2 검증자(Validator)들이 실제로 L2 상태를 모니터링하고 있는지 확인하는 무작위 테스트입니다.

**동작 흐름:**
1. DisputeGame 생성 시 RAT가 확률적으로 트리거됨
2. 해당 L2에 등록된 검증자 중 1명이 무작위 선택됨
3. 선택된 검증자는 증거 제출 기간 내에 증거를 제출해야 함
4. 미응답 시 담보금(C_off) 슬래싱

### 1.2 Optimism에서 구현해야 하는 것

| 컴포넌트 | 구현 내용 |
|---------|----------|
| **DisputeGameFactory** | RAT 트리거 호출 (`triggerAttentionTest`) |
| **FaultDisputeGame** | 챌린지 승리 시 RAT 콜백 (`resolveClaim`) |
| **IRAT 인터페이스** | TON V3 RAT 인터페이스 정의 |

---

## 2. IRAT 인터페이스

Optimism에서 사용할 RAT 인터페이스입니다. **gameAddress 파라미터 없이** Optimism 서브모듈과 동일한 인터페이스를 사용합니다.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title IRAT
/// @notice TON Staking V3 RAT 인터페이스 (Optimism 연동용)
interface IRAT {
    /// @notice RAT 테스트 트리거
    /// @dev DisputeGame 생성 시 DisputeGameFactory에서 호출
    /// @param systemConfig L2의 SystemConfig 주소 (L2 식별자)
    /// @param batchIndex 배치/게임 인덱스
    /// @param batchHash 배치 해시 또는 Output Root
    /// @param blockHash 블록 해시 (검증자 랜덤 선택용)
    function triggerAttentionTest(
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;

    /// @notice 챌린지 승리 시 담보금 복구
    /// @dev FaultDisputeGame에서 게임 해결 시 호출
    /// @dev RAT은 msg.sender(게임)의 systemConfig()를 호출하여 테스트 조회
    /// @param _claimant 게임에서 이긴 주소 (챌린저)
    function resolveClaim(address _claimant) external;
}
```

### 2.1 인터페이스 설계

| 함수 | Optimism 서브모듈 | TON V3 IRAT |
|------|------------------|-------------|
| `triggerAttentionTest` | `(address systemConfig, uint32 batchIndex, bytes32 batchHash, bytes32 blockHash)` | **동일** |
| `resolveClaim` | `(address _claimant)` | **동일** |

**파라미터 설명:**

| 파라미터 | 용도 |
|---------|------|
| `systemConfig` | RAT이 **어느 L2의 검증자 풀**에서 검증자를 선택할지 결정 (L2 식별자) |
| `batchIndex` | 테스트 ID 생성에 사용 |
| `batchHash` | 검증자가 제출해야 할 증거의 기준값 (Output Root) |
| `blockHash` | 검증자 랜덤 선택에 사용 |

### 2.2 resolveClaim에서 테스트 조회 방식

`gameAddress` 파라미터 없이 테스트를 찾는 방법:

1. `resolveClaim(claimant)` 호출 시 `msg.sender` = FaultDisputeGame 주소
2. RAT이 `msg.sender.systemConfig()` 호출하여 L2 식별
3. `activeTestByValidator[systemConfig][claimant]`로 테스트 조회

> **중요**: 이 방식이 동작하려면 **FaultDisputeGame에 `systemConfig()` 뷰 함수가 필수**입니다. (섹션 4.1 참조)

---

## 3. DisputeGameFactory 수정

### 3.1 RAT 트리거 호출

DisputeGame 생성 시 RAT를 트리거해야 합니다.

```solidity
// DisputeGameFactory.sol

import { IRAT } from "interfaces/L1/IRAT.sol";

contract DisputeGameFactory {
    /// @notice RAT 컨트랙트 주소
    address public rat;

    /// @notice 이 Factory가 담당하는 L2의 SystemConfig 주소
    address public systemConfig;

    /// @notice RAT 컨트랙트 설정
    function setRAT(address _rat) external onlyOwner {
        rat = _rat;
    }

    function create(
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData
    ) external returns (IDisputeGame proxy_) {
        // 기존 Dispute Game 생성 로직
        proxy_ = _createGame(_gameType, _rootClaim, _extraData);

        // 게임 수 증가
        gameCount++;

        // ★ RAT 트리거 (실패해도 게임 생성은 성공해야 함)
        if (rat != address(0)) {
            try IRAT(rat).triggerAttentionTest(
                address(proxy_),                   // gameAddress (생성된 게임 주소)
                systemConfig,                      // systemConfig (L2 식별자)
                uint32(gameCount - 1),             // batchIndex (게임 인덱스)
                Claim.unwrap(_rootClaim),          // batchHash (Output Root)
                blockhash(block.number - 1)        // blockHash (검증자 선택용)
            ) {
                // 성공
            } catch {
                // RAT 트리거 실패해도 게임 생성은 계속 진행
                // (검증자가 없거나, 확률 미충족 등)
            }
        }

        return proxy_;
    }
}
```

### 3.2 게임 주소가 필요한 이유

게임 주소는 **나중에 챌린저가 승리했을 때 담보금 정산**에 사용됩니다.

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. 게임 생성 시 (DisputeGameFactory.create)                         │
│     triggerAttentionTest(gameAddress, systemConfig, ...)            │
│     → RAT 컨트랙트에서 gameToTestId[gameAddress] = testId 저장      │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
                         (시간 경과)
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│  2. 챌린저 승리 시 (FaultDisputeGame.resolveClaim)                   │
│     RAT(rat).resolveClaim(winner)                                   │
│     → msg.sender = 게임 주소                                        │
│     → RAT 컨트랙트에서 gameToTestId[msg.sender]로 testId 조회       │
│     → 해당 테스트의 검증자에게 담보금 복구                           │
└─────────────────────────────────────────────────────────────────────┘
```

**RAT 컨트랙트 내부 처리:**

```solidity
// RAT.sol (TON V3)

function triggerAttentionTest(
    address gameAddress,
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external {
    // ... 검증자 선택 및 C_off 선차감 ...

    bytes32 testId = keccak256(abi.encodePacked(systemConfig, batchIndex));

    // ★ 게임 주소 → testId 매핑 저장 (resolveClaim에서 사용)
    gameToTestId[gameAddress] = testId;

    // ...
}

function resolveClaim(address _claimant) external {
    // msg.sender = FaultDisputeGame 주소
    bytes32 testId = gameToTestId[msg.sender];
    if (testId == bytes32(0)) return;

    // testId로 테스트 정보 조회 후 담보금 복구
    // ...
}
```

---

## 4. FaultDisputeGame 수정

### 4.1 systemConfig() 뷰 함수 추가 (필수)

**RAT이 resolveClaim에서 테스트를 찾기 위해 FaultDisputeGame에서 systemConfig를 조회합니다.**

```solidity
// FaultDisputeGame.sol

contract FaultDisputeGame {
    /// @notice 이 게임이 속한 L2의 SystemConfig 주소
    /// @dev RAT.resolveClaim()에서 호출하여 테스트 조회에 사용
    address public systemConfig;

    /// @notice 초기화 시 systemConfig 설정
    function initialize(address _rat, address _systemConfig) public payable virtual {
        rat = _rat;
        systemConfig = _systemConfig;  // ★ 추가
        _initialize();
    }
}
```

> **중요**: 현재 FaultDisputeGame에는 `systemConfig()` 함수가 없습니다. RAT 연동을 위해 반드시 추가해야 합니다.

### 4.2 챌린지 승리 시 RAT 콜백

검증자가 챌린저로서 FaultDisputeGame에서 승리하면, RAT 컨트랙트에 콜백하여 담보금을 복구합니다.

```solidity
// FaultDisputeGame.sol

import { IRAT } from "interfaces/L1/IRAT.sol";

contract FaultDisputeGame {
    /// @notice RAT 컨트랙트 주소
    address public rat;

    /// @notice 이 게임이 속한 L2의 SystemConfig 주소
    address public systemConfig;

    /// @notice 챌린지 승리 시 RAT 콜백
    /// @param claimant 게임에서 이긴 주소
    function _resolveClaimRat(address claimant) internal {
        if (rat != address(0)) {
            // RAT 콜백 (실패해도 게임 해결은 계속)
            try IRAT(rat).resolveClaim(claimant) {
                // 성공: 검증자 담보금 복구됨
            } catch {
                // 실패: RAT 테스트가 없거나 이미 처리됨
            }
        }
    }

    /// @notice 클레임 해결 (기존 함수 수정)
    function resolveClaim(uint256 _claimIndex, uint256 _numToResolve) external {
        // ... 기존 게임 해결 로직 ...

        // 본드 분배
        _distributeBond(winner, subgameRootClaim);

        // ★ RAT 콜백 추가
        _resolveClaimRat(winner);
    }
}
```

### 4.3 RAT resolveClaim 동작

```
┌─────────────────────────────────────────────────────────────┐
│  FaultDisputeGame.resolveClaim()                             │
│                                                              │
│  1. 게임 해결 로직 실행                                       │
│  2. 승자(winner) 결정                                        │
│  3. 본드 분배: _distributeBond(winner, ...)                  │
│  4. RAT 콜백: _resolveClaimRat(winner)                       │
│     └─→ IRAT(rat).resolveClaim(winner)                      │
│         └─→ RAT 컨트랙트에서:                                │
│             - msg.sender = 게임 주소                         │
│             - game.systemConfig() 호출하여 L2 식별           │
│             - activeTestByValidator[systemConfig][winner]로  │
│               테스트 조회                                    │
│             - winner가 선택된 검증자면 담보금 복구           │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. SystemConfig 요구사항

### 5.1 SystemConfig가 L2 식별자인 이유

TON V3에서는 여러 L2(Titan, Thanos 등)가 존재하며, 각 L2는 고유한 SystemConfig 주소를 가집니다.

```
L2 식별 구조:
┌─────────────────┬──────────────────────────────┐
│ L2 이름         │ SystemConfig 주소             │
├─────────────────┼──────────────────────────────┤
│ Titan           │ 0x1234...                    │
│ Thanos          │ 0x5678...                    │
│ 새로운 L2       │ 0x9abc...                    │
└─────────────────┴──────────────────────────────┘
```

### 5.2 DisputeGameFactory와 SystemConfig 연결

각 L2의 DisputeGameFactory는 해당 L2의 SystemConfig 주소를 알아야 합니다.

```solidity
contract DisputeGameFactory {
    /// @notice 이 Factory가 담당하는 L2의 SystemConfig
    address public systemConfig;

    /// @notice 초기화 시 SystemConfig 설정
    function initialize(address _systemConfig, ...) external {
        systemConfig = _systemConfig;
        // ...
    }
}
```

---

## 6. 연동 시퀀스 다이어그램

### 6.1 RAT 트리거 흐름

```
┌──────────────┐     ┌─────────────────────┐     ┌──────────────┐
│ L2 Proposer  │     │ DisputeGameFactory  │     │     RAT      │
└──────┬───────┘     └──────────┬──────────┘     └──────┬───────┘
       │                        │                       │
       │  create(gameType,      │                       │
       │  rootClaim, extraData) │                       │
       │───────────────────────>│                       │
       │                        │                       │
       │                        │  triggerAttentionTest │
       │                        │  (systemConfig,       │
       │                        │   batchIndex,         │
       │                        │   batchHash,          │
       │                        │   blockHash)          │
       │                        │──────────────────────>│
       │                        │                       │
       │                        │                       │ 확률 체크
       │                        │                       │ 검증자 선택
       │                        │                       │ C_off 선차감
       │                        │                       │
       │                        │      success/fail     │
       │                        │<──────────────────────│
       │                        │                       │
       │      game proxy        │                       │
       │<───────────────────────│                       │
       │                        │                       │
```

### 6.2 챌린지 승리 후 복구 흐름

```
┌──────────────┐     ┌─────────────────────┐     ┌──────────────┐
│  Challenger  │     │   FaultDisputeGame  │     │     RAT      │
└──────┬───────┘     └──────────┬──────────┘     └──────┬───────┘
       │                        │                       │
       │  resolveClaim(index,   │                       │
       │  numToResolve)         │                       │
       │───────────────────────>│                       │
       │                        │                       │
       │                        │  게임 해결            │
       │                        │  승자 결정            │
       │                        │  본드 분배            │
       │                        │                       │
       │                        │  resolveClaim         │
       │                        │  (winner = challenger)│
       │                        │──────────────────────>│
       │                        │                       │
       │                        │                       │ testId 조회
       │                        │                       │ 검증자 확인
       │                        │                       │ C_off 복구
       │                        │                       │
       │                        │      success          │
       │                        │<──────────────────────│
       │                        │                       │
       │      resolved          │                       │
       │<───────────────────────│                       │
       │                        │                       │
```

---

## 7. 테스트 체크리스트

### 7.1 DisputeGameFactory 테스트

- [ ] `create()` 호출 시 `triggerAttentionTest` 호출 확인
- [ ] RAT 트리거 실패해도 게임 생성 성공 확인
- [ ] `rat` 주소가 zero일 때 정상 동작 확인
- [ ] 올바른 파라미터 전달 확인 (systemConfig, batchIndex, batchHash, blockHash)

### 7.2 FaultDisputeGame 테스트

- [ ] `resolveClaim()` 호출 시 RAT 콜백 확인
- [ ] RAT 콜백 실패해도 게임 해결 성공 확인
- [ ] 올바른 승자 주소 전달 확인

### 7.3 통합 테스트

- [ ] DisputeGame 생성 → RAT 트리거 → 검증자 선택 확인
- [ ] 증거 제출 → 담보금 복구 확인
- [ ] 챌린지 승리 → resolveClaim → 담보금 복구 확인
- [ ] 미응답 → 담보금 슬래싱 확인

---

## 8. 배포 순서

1. **TON V3 측 배포**
   - RAT 컨트랙트 배포
   - Layer2Manager에 RAT 주소 설정
   - 각 L2의 SystemConfig 등록

2. **Optimism 측 배포**
   - DisputeGameFactory 업그레이드 (RAT 트리거 추가)
   - FaultDisputeGame 업그레이드 (RAT 콜백 추가)
   - RAT 주소 설정

3. **연동 확인**
   - 테스트넷에서 E2E 테스트
   - DisputeGame 생성 → RAT 트리거 확인
   - 챌린지 승리 → 담보금 복구 확인

---

## 9. FAQ

### Q1: RAT가 없는 기존 시스템과 호환되나요?

네. `rat` 주소가 zero이면 RAT 관련 로직이 스킵됩니다.

### Q2: RAT 트리거가 실패하면 어떻게 되나요?

DisputeGame 생성은 정상적으로 완료됩니다. RAT는 별도의 기능이므로 실패해도 핵심 기능에 영향이 없습니다.

### Q3: 검증자가 없는 L2에서는 어떻게 되나요?

RAT가 트리거되지 않습니다. `triggerAttentionTest` 내부에서 활성 검증자가 없으면 조기 리턴합니다.

### Q4: SystemConfig 대신 다른 식별자를 사용할 수 있나요?

TON V3 RAT는 SystemConfig 주소를 L2 식별자로 사용합니다. 다른 식별자를 사용하려면 RAT 컨트랙트 수정이 필요합니다.

---

## 10. Bridged TON (TVL) 변경 알림 (타입 3 전용)

TON이 L1 ↔ L2 간 브리지를 통해 이동할 때, TON V3 시뇨리지 분배 시스템에 알려야 합니다.

> **중요 - V3 시뇨리지 대상**:
> - **타입 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)만 V3 시뇨리지 분배 대상**입니다
> - 타입 1/2 롤업은 V3 백서 기준 시뇨리지를 받지 않습니다
> - 따라서 `onBridgedTONChange`는 타입 3만 호출합니다

### 10.1 ISeigManager 인터페이스 (타입 3 전용)

```solidity
/// @title ISeigManager (TON V3용)
/// @notice Bridged TON 변경 알림 인터페이스 (타입 3 전용)
interface ISeigManager {
    /// @notice L2의 Bridged TON(TVL) 변경 시 호출 (타입 3 전용)
    /// @dev OptimismPortal에서 TON 입금/출금 완료 후 직접 호출
    ///      msg.sender(OptimismPortal)로부터 rollupConfig를 자동 조회
    ///      트리거 함수이므로 revert 대신 early return 사용
    function onBridgedTONChange() external;
}
```

> **참고**:
> - SeigManager가 `msg.sender`(OptimismPortal)로부터 `L1BridgeRegistry.rollupConfigWithPortal()`을 통해 rollupConfig를 자동 조회
> - 트리거 함수이므로 모든 오류 상황에서 revert 대신 early return

### 10.2 타입 3 (Bedrock with DisputeGame): OptimismPortal 수정

```solidity
// OptimismPortal.sol (타입 3 전용)

import { ISeigManager } from "interfaces/L1/ISeigManager.sol";

contract OptimismPortal {
    /// @notice SeigManager 주소 (TON V3)
    address public seigManager;

    /// @notice TON 입금/출금 완료 후 (타입 3 전용)
    /// @dev SeigManager를 직접 호출, msg.sender(this)로 rollupConfig 자동 조회됨
    function _notifyBridgedTONChange() internal {
        if (seigManager != address(0)) {
            // try-catch로 감싸서 실패해도 브리지 동작은 계속
            try ISeigManager(seigManager).onBridgedTONChange() {
                // 성공
            } catch {
                // 실패해도 브리지 동작은 계속 진행
            }
        }
    }

    /// @notice TON 입금 시 호출
    function depositTransaction(...) external {
        // ... 기존 입금 로직 ...

        // ★ Bridged TON 변경 알림
        _notifyBridgedTONChange();
    }

    /// @notice TON 출금 완료 시 호출
    function finalizeWithdrawalTransaction(...) external {
        // ... 기존 출금 로직 ...

        // ★ Bridged TON 변경 알림
        _notifyBridgedTONChange();
    }
}

### 10.3 Bridged TON 변경 시퀀스 (타입 3)

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────┐
│    User     │     │ OptimismPortal  │     │ SeigManager  │
└──────┬──────┘     └────────┬────────┘     └──────┬───────┘
       │                     │                     │
       │  depositTransaction │                     │
       │────────────────────>│                     │
       │                     │                     │
       │                     │  TON 수신           │
       │                     │  (포탈에 TON 보관)   │
       │                     │                     │
       │                     │  onBridgedTONChange │
       │                     │  ()                 │
       │                     │────────────────────>│
       │                     │                     │
       │                     │                     │ 1. rollupConfigWithPortal(msg.sender)
       │                     │                     │    → rollupConfig 조회
       │                     │                     │
       │                     │                     │ 2. rollupType == 3 검증
       │                     │                     │    (아니면 early return)
       │                     │                     │
       │                     │                     │ 3. getLayer2BySystemConfig(rollupConfig)
       │                     │                     │    → layer2 조회
       │                     │                     │
       │                     │                     │ 4. _updateEligibilityInternal(layer2)
       │                     │                     │    - 자격 조건 재평가
       │                     │                     │    - totalEffectiveBridgedTON 갱신
       │                     │                     │
       │    success          │                     │
       │<────────────────────│                     │
```

### 10.4 왜 필요한가?

TON V3 시뇨리지 분배는 **Bridged TON (B_i)** 기반입니다 (타입 3 전용):

- **자격 조건**: `S_i ≥ θ · B_i` (스테이킹 ≥ 최소비율 × Bridged TON)
- **시뇨리지 분배**: `y(x)` 함수에서 `x = Σ B̃_i` (유효 Bridged TON 합계)

Bridged TON이 변경되면:
1. L2의 자격 조건이 변경될 수 있음
2. 전체 시뇨리지 분배 비율이 변경될 수 있음

> **타입 1/2 롤업**: V3 백서 기준 시뇨리지 분배 대상이 아니므로 `onBridgedTONChange`를 호출하지 않습니다.

---

## 11. 시퀀서 슬래싱 (Permissionless 방식)

Fraud Proof가 성공하면 시퀀서(오퍼레이터)의 담보금을 슬래싱합니다.

> **설계 결정**: 게임 내에서 직접 `slashSequencer`를 호출하면 가스비가 증가하고 게임 로직과 결합도가 높아집니다. 대신 **Permissionless 방식**으로 게임 종료 후 누구나 슬래싱을 트리거할 수 있게 합니다.

### 11.1 Optimism에서 필요한 것: 없음

**Optimism 컨트랙트 수정 불필요!**

FaultDisputeGame은 이미 다음 정보를 제공합니다:
- `status()`: 게임 상태 (`CHALLENGER_WINS`, `DEFENDER_WINS`, `IN_PROGRESS`)
- `resolvedAt`: 게임 해결 시간
- `claimData`: 클레임 정보 (챌린저 주소 포함)
- `rootClaim()`: 루트 클레임

TON V3의 SeigManager가 이 정보를 직접 조회하여 슬래싱을 검증합니다.

### 11.2 ISeigManager 슬래싱 인터페이스 (TON V3 측)

```solidity
interface ISeigManager {
    /// @notice 시퀀서 슬래싱 (Permissionless)
    /// @dev 누구나 호출 가능, 게임 결과를 온체인에서 검증
    /// @param gameAddress FaultDisputeGame 주소
    function slashSequencerByGame(address gameAddress) external;
}
```

### 11.3 TON V3 SeigManager 구현 예시

```solidity
// SeigManager.sol (TON V3)

import { IFaultDisputeGame } from "@optimism/interfaces/dispute/IFaultDisputeGame.sol";

contract SeigManager {
    /// @notice 게임 주소 → L2 매핑 (DisputeGameFactory 등록 시 설정)
    mapping(address => address) public gameToLayer2;

    /// @notice 이미 슬래싱된 게임
    mapping(address => bool) public slashedGames;

    /// @notice 시퀀서 슬래싱 (Permissionless)
    /// @param gameAddress FaultDisputeGame 주소
    function slashSequencerByGame(address gameAddress) external {
        // 이미 슬래싱됨
        require(!slashedGames[gameAddress], "Already slashed");

        // 게임 → L2 매핑 확인
        address layer2 = gameToLayer2[gameAddress];
        require(layer2 != address(0), "Unknown game");

        // ★ 게임 상태 직접 조회 (Optimism 컨트랙트에서)
        IFaultDisputeGame game = IFaultDisputeGame(gameAddress);

        // 챌린저 승리 확인
        require(game.status() == GameStatus.CHALLENGER_WINS, "Challenger did not win");

        // 게임이 해결되었는지 확인
        require(game.resolvedAt().raw() > 0, "Game not resolved");

        // 슬래싱 실행
        slashedGames[gameAddress] = true;
        _executeSlashing(layer2, gameAddress);
    }

    function _executeSlashing(address layer2, address gameAddress) internal {
        // 챌린저 정보 추출 (게임에서 조회)
        address[] memory challengers = _extractChallengers(gameAddress);

        // 시퀀서 담보금 슬래싱
        // 챌린저 보상 분배
        // L2 자격 재평가
        // ...
    }
}
```

### 11.4 슬래싱 시퀀스 (Permissionless)

```
┌──────────────┐     ┌─────────────────────┐
│  Challenger  │     │   FaultDisputeGame  │
└──────┬───────┘     └──────────┬──────────┘
       │                        │
       │  resolve()             │
       │───────────────────────>│
       │                        │
       │                        │  게임 해결
       │                        │  status = CHALLENGER_WINS
       │      resolved          │
       │<───────────────────────│
       │                        │


       (시간 경과 - 오프체인 모니터링)


┌──────────────┐     ┌─────────────────────┐     ┌──────────────┐
│   Anyone     │     │   FaultDisputeGame  │     │ SeigManager  │
└──────┬───────┘     └──────────┬──────────┘     └──────┬───────┘
       │                        │                       │
       │  slashSequencerByGame(gameAddress)             │
       │───────────────────────────────────────────────>│
       │                        │                       │
       │                        │  game.status()        │
       │                        │<──────────────────────│
       │                        │                       │
       │                        │  CHALLENGER_WINS      │
       │                        │──────────────────────>│
       │                        │                       │
       │                        │                       │ 시퀀서 담보금 슬래싱
       │                        │                       │ 챌린저 보상 분배
       │                        │                       │
       │      success           │                       │
       │<───────────────────────────────────────────────│
```

### 11.5 장점

| 항목 | 온체인 콜백 방식 | Permissionless 방식 |
|-----|----------------|-------------------|
| **Optimism 수정** | 필요 (FaultDisputeGame) | **불필요** |
| **가스비** | 게임 해결 시 증가 | 별도 트랜잭션 |
| **결합도** | 높음 | **낮음** |
| **호출 주체** | 게임 컨트랙트 | 누구나 (봇, 챌린저 등) |
| **타이밍** | 게임 해결 즉시 | 게임 해결 후 언제든 |

### 11.6 슬래싱 결과

- **시퀀서**: 담보금 일부/전부 슬래싱
- **챌린저들**: 슬래싱된 금액에서 보상 분배 (최대 H_max명)
- **L2**: 자격 조건 재평가 (담보금 감소로 자격 상실 가능)
- **슬래싱 트리거자**: 가스비 부담 (선택적으로 인센티브 제공 가능)

---

## 12. 테스트 체크리스트 (전체)

### 12.1 RAT 테스트 (Optimism 측)

- [ ] `create()` 호출 시 `triggerAttentionTest` 호출 확인
- [ ] RAT 트리거 실패해도 게임 생성 성공 확인
- [ ] 챌린저 승리 시 `resolveClaim` 콜백 확인
- [ ] 올바른 파라미터 전달 확인

### 12.2 Bridged TON 테스트 (타입 3 전용 - Optimism 측)

- [ ] TON 입금 시 `SeigManager.onBridgedTONChange()` 호출 확인
- [ ] TON 출금 시 `SeigManager.onBridgedTONChange()` 호출 확인
- [ ] 콜백 실패해도 브리지 동작 성공 확인
- [ ] 타입 3 롤업에서만 호출 확인 (타입 1/2는 미호출)

### 12.3 슬래싱 테스트 (TON V3 측 - Optimism 수정 불필요)

- [ ] `slashSequencerByGame(gameAddress)` 호출 시 게임 상태 조회 확인
- [ ] `CHALLENGER_WINS` 상태에서만 슬래싱 성공 확인
- [ ] 챌린저 목록 추출 및 보상 분배 확인
- [ ] 중복 슬래싱 방지 확인

---

## 13. 참고 문서

- TON Staking V3 외부 인터페이스: `docs/for-llm-kr/13_external_interfaces.md`
- TON Staking V3 RAT 구현 설계: `docs/for-llm-kr/07_rat_implementation.md`
- Bridged TON 추적 시스템: `docs/for-llm-kr/06_bridged_ton_tracking.md`
- Optimism RAT 배포 가이드: `lib/optimism/op-challenger/scripts/docs/rat/rat-deployment-implementation.md`
