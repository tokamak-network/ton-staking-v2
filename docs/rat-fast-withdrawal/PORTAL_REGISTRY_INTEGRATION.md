# RAT Fast Withdrawal - Portal 레지스트리 통합

## 개요

RAT 컨트랙트는 여러 L2가 공유하는 컨트랙트이므로, 각 L2의 OptimismPortal 주소를 직접 저장하지 않고 Layer2Manager를 통해 동적으로 조회합니다.

---

## 아키텍처 변경

### Before (설계 오류)

```solidity
// ❌ 잘못된 설계: Portal 주소를 RAT에 직접 저장
mapping(address => address) public optimismPortals;

function setOptimismPortal(address systemConfig, address portal) external onlyOwner {
    optimismPortals[systemConfig] = portal;
}
```

**문제점:**
1. **중복 저장**: Layer2Manager에 이미 있는 정보를 RAT에도 저장
2. **동기화 문제**: Layer2Manager에서 Portal 주소가 변경되어도 RAT은 모름
3. **관리 복잡성**: 새 L2 추가 시 RAT 설정도 별도로 필요
4. **보안 취약점**: 검증 없이 임의의 Portal 주소 설정 가능

### After (올바른 설계)

```solidity
// ✅ 올바른 설계: Layer2Manager에서 동적으로 조회
function _getOptimismPortal(address systemConfig) internal view returns (address portal) {
    (bool result, , address _portal, , , , , ) = 
        ILayer2Manager(layer2Manager).checkL1BridgeDetail(systemConfig);
    
    if (!result) {
        return address(0);
    }
    
    return _portal;
}
```

**장점:**
1. **Single Source of Truth**: Layer2Manager가 유일한 정보원
2. **자동 동기화**: Layer2Manager 변경 시 자동 반영
3. **간소화된 관리**: 새 L2 추가 시 Layer2Manager만 설정
4. **보안 강화**: Layer2Manager가 검증한 Portal만 사용

---

## Layer2Manager 인터페이스

### checkL1BridgeDetail

```solidity
function checkL1BridgeDetail(address _rollupConfig) external view returns (
    bool result,           // L2가 등록되었고 유효한지
    address l1Bridge,      // L1 브리지 주소
    address portal,        // OptimismPortal2 주소 ← RAT이 사용
    address l2Ton,         // L2 TON 토큰 주소
    uint8 _type,           // Rollup 타입
    uint8 status,          // Layer2 상태
    bool rejectedSeigs,    // 시뇨리지 거부 여부
    bool rejectedL2Deposit // L2 예치 거부 여부
);
```

**RAT에서 사용하는 필드:**
- `result`: L2 유효성 체크
- `portal`: OptimismPortal2 주소

---

## RAT 구현

### 1. Portal 조회 함수

```solidity
/// @notice SystemConfig에서 OptimismPortal 주소 조회
/// @dev Layer2Manager를 통해 동적으로 Portal 주소를 가져옴 (여러 L2 지원)
/// @param systemConfig L2의 SystemConfig 주소 (rollupConfig)
/// @return portal OptimismPortal2 주소, 없으면 address(0)
function _getOptimismPortal(address systemConfig) internal view returns (address portal) {
    // Layer2Manager.checkL1BridgeDetail()로 Portal 주소 조회
    (bool result, , address _portal, , , , , ) = 
        ILayer2Manager(layer2Manager).checkL1BridgeDetail(systemConfig);
    
    if (!result) {
        return address(0);
    }
    
    return _portal;
}
```

### 2. 사용 예시

#### 2.1 사전 검증

```solidity
function _validateFastWithdrawalPreconditions(
    FastWithdrawalInput calldata input,
    Types.WithdrawalTransaction calldata _tx
) internal view {
    if (!fastWithdrawalEnabled) revert FastWithdrawalDisabledError();
    
    // Portal 주소 조회 (Layer2Manager에서 동적으로 가져옴)
    address portal = _getOptimismPortal(input.systemConfig);
    if (portal == address(0)) revert FastWithdrawalPortalNotSetError();
    
    // ... 나머지 검증
}
```

#### 2.2 Fast Withdrawal 실행

```solidity
function _executeFastWithdrawal(
    FastWithdrawalInput calldata input,
    Types.WithdrawalTransaction calldata _tx
) internal {
    processedWithdrawals[input.withdrawalHash] = true;

    // Portal 주소 조회 (Layer2Manager에서 가져옴)
    address portal = _getOptimismPortal(input.systemConfig);
    
    // Portal 호출
    IOptimismPortal2ForRAT(portal).setWithdrawalVerified(input.withdrawalHash);
    IOptimismPortal2ForRAT(portal).fastWithdrawalFinalize(_tx);

    // 수수료 분배
    _distributeFastWithdrawalFees(msg.sender);

    emit FastWithdrawalExecuted(input.withdrawalHash, _tx.sender, _tx.value, msg.sender);
}
```

---

## 가스 최적화

### 최적화 전 (중복 조회)

```solidity
function _validateFastWithdrawalPreconditions(...) {
    address portal = _getOptimismPortal(input.systemConfig); // SLOAD
    if (portal == address(0)) revert;
}

function _executeFastWithdrawal(...) {
    address portal = _getOptimismPortal(input.systemConfig); // SLOAD (중복!)
    IOptimismPortal2ForRAT(portal).setWithdrawalVerified(...);
}
```

### 최적화 후 (필요 시 캐싱)

```solidity
// 검증 단계에서는 존재 여부만 확인
function _validateFastWithdrawalPreconditions(...) {
    address portal = _getOptimismPortal(input.systemConfig);
    if (portal == address(0)) revert FastWithdrawalPortalNotSetError();
}

// 실행 단계에서 다시 조회 (검증 통과했으므로 안전)
function _executeFastWithdrawal(...) {
    // 이미 검증했으므로 address(0) 체크 불필요
    address portal = _getOptimismPortal(input.systemConfig);
    IOptimismPortal2ForRAT(portal).setWithdrawalVerified(...);
}
```

**트레이드오프:**
- 장점: 코드 단순성, 안전성
- 단점: 중복 외부 호출 (~2,600 gas 추가)
- 결론: 안전성과 단순성이 가스 비용보다 중요

---

## L2 등록 흐름

### 1. Layer2Manager에 L2 등록

```solidity
// 1. L1BridgeRegistry에 L2 정보 등록
l1BridgeRegistry.registerL2(
    systemConfig,
    rollupType,
    l1Bridge,
    portal,
    l2Ton
);

// 2. Layer2Manager에 Layer2 등록
layer2Manager.registerLayer2(
    operator,
    systemConfig,
    ...
);
```

### 2. RAT에서 자동으로 사용 가능

```solidity
// RAT은 별도 설정 없이 즉시 사용 가능
// Layer2Manager에서 자동으로 Portal 주소 조회
address portal = _getOptimismPortal(systemConfig);
// portal != address(0) 이면 Fast Withdrawal 사용 가능
```

---

## 보안 고려사항

### 1. Portal 주소 검증

**Layer2Manager가 검증 책임:**
- L1BridgeRegistry의 등록 정보 사용
- 관리자만 L2 등록 가능
- 잘못된 Portal 주소는 등록 단계에서 차단

**RAT의 책임:**
- Layer2Manager 결과 신뢰
- Portal이 없으면 Fast Withdrawal 거부

### 2. 악의적 Portal 방지

```solidity
// Layer2Manager 등록 시 검증
require(portal.code.length > 0, "Invalid portal");
require(portal.supportsInterface(type(IOptimismPortal2).interfaceId), "Not portal");
```

### 3. Portal 변경 시나리오

**시나리오:** L2가 Portal 주소를 업그레이드하는 경우

```solidity
// 1. Layer2Manager에서 Portal 주소 업데이트
layer2Manager.updatePortal(systemConfig, newPortal);

// 2. RAT은 다음 Fast Withdrawal부터 자동으로 새 Portal 사용
// (별도 설정 불필요)
```

---

## 테스트 시나리오

### 1. 정상 케이스: Portal 주소 조회

```solidity
test('Get portal address from Layer2Manager', async () => {
    // Given: Layer2Manager에 L2 등록
    await layer2Manager.registerL2(operator, systemConfig, portal);
    
    // When: RAT에서 Portal 조회
    const portalAddress = await rat._getOptimismPortal(systemConfig);
    
    // Then: 올바른 Portal 주소 반환
    expect(portalAddress).to.equal(portal);
});
```

### 2. 에러 케이스: 미등록 L2

```solidity
test('Revert when L2 not registered', async () => {
    // Given: 등록되지 않은 systemConfig
    const unknownConfig = '0x...';
    
    // When/Then: Portal 조회 시 address(0) 반환
    const portal = await rat._getOptimismPortal(unknownConfig);
    expect(portal).to.equal(ethers.constants.AddressZero);
    
    // Fast Withdrawal 시도 시 에러
    await expect(
        rat.verifyAndExecuteFastWithdrawal(...)
    ).to.be.revertedWith('FastWithdrawalPortalNotSetError');
});
```

### 3. 동기화 케이스: Portal 주소 변경

```solidity
test('Auto-sync when portal address changes', async () => {
    // Given: 기존 Portal 주소
    await layer2Manager.registerL2(operator, systemConfig, oldPortal);
    
    // When: Portal 주소 업데이트
    await layer2Manager.updatePortal(systemConfig, newPortal);
    
    // Then: RAT이 자동으로 새 Portal 사용
    const portal = await rat._getOptimismPortal(systemConfig);
    expect(portal).to.equal(newPortal);
});
```

---

## 마이그레이션 가이드

### 기존 코드에서 마이그레이션

#### Before (삭제할 코드)

```solidity
// ❌ 제거: Portal 저장소
mapping(address => address) public optimismPortals;

// ❌ 제거: Portal 설정 함수
function setOptimismPortal(address systemConfig, address portal) external onlyOwner {
    optimismPortals[systemConfig] = portal;
    emit OptimismPortalSet(systemConfig, portal);
}

// ❌ 제거: 이벤트
event OptimismPortalSet(address indexed systemConfig, address indexed portal);
```

#### After (추가할 코드)

```solidity
// ✅ 추가: Portal 조회 함수
function _getOptimismPortal(address systemConfig) internal view returns (address portal) {
    (bool result, , address _portal, , , , , ) = 
        ILayer2Manager(layer2Manager).checkL1BridgeDetail(systemConfig);
    
    if (!result) {
        return address(0);
    }
    
    return _portal;
}
```

#### 사용처 변경

```solidity
// Before
address portal = optimismPortals[systemConfig];

// After
address portal = _getOptimismPortal(systemConfig);
```

---

## 정리

### 핵심 변경사항

| 항목 | Before | After |
|-----|--------|-------|
| Portal 저장 | RAT에 저장 | Layer2Manager에서 조회 |
| 설정 필요 | 각 L2마다 setOptimismPortal() 호출 | 불필요 (자동) |
| 동기화 | 수동 (Portal 변경 시 RAT도 업데이트) | 자동 |
| 보안 | RAT owner가 검증 책임 | Layer2Manager가 검증 |

### 장점

✅ **Single Source of Truth**: Layer2Manager가 유일한 정보원  
✅ **자동 동기화**: Portal 변경 시 자동 반영  
✅ **간소화된 관리**: 새 L2 추가 시 RAT 설정 불필요  
✅ **보안 강화**: Layer2Manager의 검증 활용  
✅ **확장성**: 새 Rollup 타입 추가 시 RAT 수정 불필요  

### 가스 비용

- **Portal 조회**: ~2,600 gas (외부 view 호출)
- **Fast Withdrawal 전체**: ~200,000 gas (BLS 검증 포함)
- **조회 비용 비율**: ~1.3% (무시 가능)

---

*Last Updated: 2026-02-02*
