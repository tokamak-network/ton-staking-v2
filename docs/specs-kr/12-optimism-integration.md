# TON Staking V3 Optimism 통합

이 문서는 Optimism L2와 TON Staking V3 시스템(RAT, SeigManager)의 통합 구현을 설명합니다.

---

## 수정/생성된 파일 (Optimism 측)

### 새로운 인터페이스

| 파일 | 설명 |
|------|------|
| `interfaces/L1/IRAT.sol` | TON Staking V3 RAT 인터페이스 |
| `interfaces/L1/ISeigManager.sol` | TON Staking V3 SeigManager 인터페이스 |

### 수정된 파일

| 파일 | 변경 사항 |
|------|---------|
| `src/dispute/DisputeGameFactory.sol` | RAT 트리거 호출 추가 |
| `src/dispute/FaultDisputeGame.sol` | RAT 콜백 호출 추가 |
| `src/L1/OptimismPortal2.sol` | Bridged TON 변경 알림 추가 |

---

## 1. IRAT 인터페이스

```solidity
// interfaces/L1/IRAT.sol
interface IRAT {
    /// @notice RAT 테스트 트리거 (DisputeGameFactory가 호출)
    /// @param gameAddress 새로 생성된 FaultDisputeGame 주소
    /// @param systemConfig L2의 SystemConfig 주소 (L2 식별자)
    /// @param batchIndex 배치/게임 인덱스
    /// @param batchHash 배치 해시 또는 Output Root
    /// @param blockHash 블록 해시 (랜덤 검증자 선택용)
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;

    /// @notice 클레임 해결 시 호출 (FaultDisputeGame이 호출)
    /// @param claimant 게임에서 승리한 주소
    function resolveClaim(address claimant) external;
}
```

---

## 2. DisputeGameFactory - RAT 트리거

### 추가된 상태 변수

```solidity
/// @notice RAT 컨트랙트 주소 (TON Staking V3 RAT)
address public rat;

/// @notice RAT L2 식별을 위한 SystemConfig 주소
address public systemConfig;
```

### 추가된 함수

```solidity
/// @notice RAT 컨트랙트 주소 설정
/// @dev owner만 호출 가능
/// @param _rat RAT 컨트랙트 주소
function setRAT(address _rat) external onlyOwner;

/// @notice SystemConfig 주소 설정
/// @dev owner만 호출 가능
/// @param _systemConfig 이 L2의 SystemConfig 주소
function setSystemConfig(address _systemConfig) external onlyOwner;
```

### create() 함수에서 RAT 트리거

```solidity
// 게임 생성 후 RAT 트리거
// RAT는 gameAddress를 저장하여 resolveClaim()에서 인증 확인
if (rat != address(0) && _gameType.raw() == GameTypes.CANNON.raw()) {
    try IRAT(rat).triggerAttentionTest(
        address(proxy_),                     // gameAddress
        systemConfig,                        // L2 식별자
        uint32(_disputeGameList.length - 1), // batchIndex
        Claim.unwrap(_rootClaim),            // batchHash
        parentHash                           // blockHash
    ) { } catch { }
}
```

**위치**: `DisputeGameFactory.sol` Line 203-211

**특징**:
- CANNON 게임 타입에서만 트리거
- try-catch로 래핑 (RAT 실패 시에도 게임 생성은 성공)
- RAT가 설정되지 않으면 스킵

---

## 3. FaultDisputeGame - RAT 콜백

### 추가된 상태 변수

```solidity
/// @notice RAT 컨트랙트 주소
address public rat;
```

### 초기화

```solidity
/// @notice RAT 주소와 함께 초기화
/// @param _rat RAT 컨트랙트 주소
function initialize(address _rat) public payable virtual {
    _initialize(_rat);
}

/// @notice RAT 없이 초기화 (기존 호환성)
function initialize() public payable virtual {
    _initialize(address(0));
}

/// @notice 내부 초기화 함수
function _initialize(address _rat) internal virtual {
    // ... 기존 로직 ...
    
    // RAT 주소 설정
    if (_rat != address(0)) rat = _rat;
}
```

**위치**: `FaultDisputeGame.sol` Line 290-376

**calldata 길이**:
- RAT 없음: 122 bytes
- RAT 있음: 154 bytes (32 bytes RAT 주소 추가)

### RAT 콜백

```solidity
/// @notice RAT resolveClaim 함수를 안전하게 호출
/// @param claimant 클레임 승자
function resolveClaimRat(address claimant) internal {
    if (rat != address(0)) {
        try IRAT(rat).resolveClaim(claimant) { } catch { }
    }
}
```

**위치**: `FaultDisputeGame.sol` Line 943-947

**호출 시점**:
- Uncontested 클레임 해결 시 (Line 794)
- L2 블록 번호 챌린지 성공 시 (Line 855)
- 일반 클레임 해결 시 (Line 862)

---

## 4. ISeigManager 인터페이스

```solidity
// interfaces/L1/ISeigManager.sol
interface ISeigManager {
    /// @notice Bridged TON 잔액 변경 시 호출
    /// @dev OptimismPortal2가 호출
    ///      msg.sender로부터 rollupConfig를 역추적
    function onBridgedTonChange() external;
}
```

**중요**: 
- 파라미터 없음 (문서와 다름!)
- SeigManager가 `msg.sender`(OptimismPortal)로부터 rollupConfig 조회
- `rollupConfigWithPortal[msg.sender]`로 L2 식별

---

## 5. OptimismPortal2 - Bridged TON 알림

### 추가된 상태 변수

```solidity
/// @notice SeigManager 컨트랙트 주소 (TON Staking V3)
address public seigManager;
```

### 추가된 함수

```solidity
/// @notice SeigManager 주소 설정
/// @dev ProxyAdmin owner만 호출 가능
/// @param _seigManager SeigManager 컨트랙트 주소
function setSeigManager(address _seigManager) external {
    require(msg.sender == address(proxyAdmin.owner()));
    seigManager = _seigManager;
}
```

**위치**: `OptimismPortal2.sol` Line 391-394

### Bridged TON 변경 알림

```solidity
/// @notice SeigManager에 Bridged TON 잔액 변경 알림
/// @dev TON 입출금 완료 후 호출
///      SeigManager가 없거나 함수가 revert해도 트랜잭션은 계속 진행
function _notifySeigManager() internal {
    if (seigManager != address(0)) {
        // Low-level call로 revert 방지
        try ISeigManager(seigManager).onBridgedTonChange() {} catch {}
    }
}
```

**위치**: `OptimismPortal2.sol` Line 400-406

### 호출 시점

| 이벤트 | 위치 | 설명 |
|-------|------|------|
| TON 입금 (L1→L2) | Line 714 | `depositTransaction` 완료 후 |
| TON 출금 (L2→L1) | Line 817 | `finalizeWithdrawalTransaction` 완료 후 |

**동작 흐름**:
```
1. 사용자가 OptimismPortal2를 통해 TON 입출금
   ↓
2. 트랜잭션 처리 완료
   ↓
3. _notifySeigManager() 호출
   ↓
4. SeigManager.onBridgedTonChange() 호출
   ↓
5. SeigManager가 msg.sender(Portal)로 L2 식별
   - rollupConfig = rollupConfigWithPortal[msg.sender]
   - layer2 = getLayer2BySystemConfig(rollupConfig)
   ↓
6. _updateEligibilityInternal(layer2) 호출
   - Bridged TON 변경에 따른 자격 재평가
```

---

## 6. 검증 흐름

### RAT 게임 검증

```
triggerAttentionTest(gameAddress, systemConfig, ...) 호출 시:
├── msg.sender = DisputeGameFactory
├── trustedFactories[systemConfig] == msg.sender 검증
└── gameToTestId[gameAddress] = testId 저장

resolveClaim(claimant) 호출 시:
├── msg.sender = FaultDisputeGame
└── gameToTestId[msg.sender] 존재 확인
```

**검증 위치**: `RAT.sol`
- `onlyValidFactory` modifier: DisputeGameFactory 검증
- `factoryByGame[msg.sender]`: FaultDisputeGame 검증

### Bridged TON 검증

```
onBridgedTonChange() 호출 시:
├── msg.sender = OptimismPortal2
├── rollupConfig = rollupConfigWithPortal[msg.sender]
└── layer2 = getLayer2BySystemConfig(rollupConfig)
```

**검증 위치**: `SeigManagerV3_1.sol` Line 309-313

---

## 7. 배포 설정

### DisputeGameFactory 설정

```solidity
// Owner 호출
disputeGameFactory.setRAT(ratAddress);
disputeGameFactory.setSystemConfig(systemConfigAddress);
```

### OptimismPortal2 설정

```solidity
// ProxyAdmin owner 호출
optimismPortal2.setSeigManager(seigManagerAddress);
```

### L1BridgeRegistry 설정

```solidity
// SeigManager, Layer2Manager 등에서 역참조용 매핑 등록
l1BridgeRegistry.rollupConfigWithPortal[optimismPortal2] = systemConfig;
l1BridgeRegistry.rollupConfigWithDisputeGameFactory[disputeGameFactory] = systemConfig;
```

**참고**: L1BridgeRegistry의 매핑은 L2 등록 시 자동으로 설정됨

---

## 8. 안전성

모든 외부 호출은 원본 트랜잭션 실패에 영향을 주지 않음:

| 함수 | 안전 장치 | 위치 |
|------|----------|------|
| `triggerAttentionTest` | try-catch | DisputeGameFactory.sol:203 |
| `resolveClaim` | try-catch | FaultDisputeGame.sol:945 |
| `onBridgedTonChange` | try-catch | OptimismPortal2.sol:404 |

**설계 원칙**:
- RAT/SeigManager가 설정되지 않으면 (zero address) 호출 스킵
- 호출 실패 시에도 원본 트랜잭션은 계속 진행
- Optimism 핵심 기능은 TON Staking V3와 독립적으로 동작

---

## 9. 실제 구현과 문서 차이점

### 이전 설계 (문서)

```solidity
// L1StandardBridge가 SeigManager 호출
function onBridgedTonChange(address rollupConfig, uint256 totalTONTVL) external;
```

### 실제 구현 (코드)

```solidity
// OptimismPortal2가 SeigManager 호출
function onBridgedTonChange() external;  // 파라미터 없음
```

**변경 이유**:
1. **OptimismPortal2가 TON 입출금의 실제 진입점**
   - L1StandardBridge는 ERC20 전용
   - OptimismPortal2가 Native TON 처리

2. **msg.sender 기반 L2 식별**
   - 파라미터로 전달하면 위조 가능
   - msg.sender로 Portal 확인 → 역매핑으로 rollupConfig 조회
   - 더 안전한 구조

3. **TVL 계산은 SeigManager 책임**
   - SeigManager가 L1BridgeRegistry를 통해 TVL 조회
   - Portal은 알림만 담당 (관심사 분리)

---

## 10. 관련 코드 위치

### Optimism (packages/contracts-bedrock)

| 파일 | 주요 변경 | 라인 |
|------|----------|------|
| `src/dispute/DisputeGameFactory.sol` | RAT 트리거 | 74-78, 203-211, 309-318 |
| `src/dispute/FaultDisputeGame.sol` | RAT 콜백 | 234, 290-376, 794, 855, 862, 943-947 |
| `src/L1/OptimismPortal2.sol` | SeigManager 알림 | 129-131, 391-406, 714, 817 |
| `interfaces/L1/IRAT.sol` | RAT 인터페이스 | - |
| `interfaces/L1/ISeigManager.sol` | SeigManager 인터페이스 | - |

### TON Staking V3

| 파일 | 주요 로직 | 라인 |
|------|----------|------|
| `src/validator/RAT.sol` | triggerAttentionTest | 554-577 |
| `src/validator/RAT.sol` | resolveClaim | 680-730 |
| `src/stake/managers/SeigManagerV3_1.sol` | onBridgedTonChange | 306-317 |
| `src/layer2/L1BridgeRegistryV1_2.sol` | Portal/Factory 매핑 | - |

---

## 11. 테스트

### Optimism 측 통합 테스트

```solidity
// DisputeGameFactory 테스트
- RAT 트리거 정상 동작
- RAT 없을 때 정상 동작
- try-catch 정상 동작

// FaultDisputeGame 테스트
- RAT 콜백 정상 동작
- RAT 없을 때 정상 동작
- calldata 길이 검증

// OptimismPortal2 테스트
- SeigManager 알림 정상 동작
- SeigManager 없을 때 정상 동작
- try-catch 정상 동작
```

### TON Staking V3 측 통합 테스트

```solidity
// RAT 테스트
- 잘못된 Factory 호출 차단
- 정상 게임 검증
- 랜덤 검증자 선택

// SeigManager 테스트
- 잘못된 Portal 호출 무시
- 정상 자격 업데이트
- Bridged TON 변경 감지
```

테스트 파일:
- `test/v3/v3mode/RAT.t.sol`
- `test/v3/v3mode/EligibilityTransition.t.sol`
