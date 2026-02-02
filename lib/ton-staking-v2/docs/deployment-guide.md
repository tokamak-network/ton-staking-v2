# TON Staking V3 배포 가이드

## 배포 후 필수 설정

### 1. 동적 롤업 타입 등록

V3 시스템이 정상 작동하려면 **배포 직후** L1BridgeRegistry에 롤업 타입을 등록해야 합니다.

#### 왜 필요한가?

- `DepositManager.withdrawAndDepositL2()`: 타입별 bridge pattern 확인
- `SeigManager`: V3 시뇨리지 적격 타입 확인 (bitmap)
- 기존 TYPE 1, 2, 3도 등록해야 함

#### 등록 방법

**Foundry Script 사용:**

```solidity
// script/PostDeploySetup.s.sol
L1BridgeRegistryV1_2 registry = L1BridgeRegistryV1_2(registryProxy);

// TYPE 1: Optimism Legacy (Titan 등) - V2 mode only
registry.addRollupType(
    1,                                          // type
    "Optimism Legacy",                          // name
    bytes4(keccak256("l1StandardBridge()")),   // tvlContractGetter (0x078f29cf)
    0,                                          // BRIDGE_PATTERN_ERC20
    false                                       // V3 eligible = false (V2 only)
);

// TYPE 2: Optimism Bedrock (Thanos 등) - V2 mode only
registry.addRollupType(
    2,
    "Optimism Bedrock",
    bytes4(keccak256("optimismPortal()")),     // tvlContractGetter (0x0a49cb03)
    1,                                          // BRIDGE_PATTERN_NATIVE
    false                                       // V3 eligible = false (V2 only)
);

// TYPE 3: Bedrock with DisputeGame - V3 eligible
registry.addRollupType(
    3,
    "Optimism Bedrock DisputeGame",
    bytes4(keccak256("optimismPortal()")),
    1,                                          // BRIDGE_PATTERN_NATIVE
    true                                        // V3 eligible = true
);
```

**Cast 명령어 사용:**

```bash
# TYPE 1 등록 (V2 mode only)
cast send $REGISTRY_PROXY \
  "addRollupType(uint8,string,bytes4,uint8,bool)" \
  1 \
  "Optimism Legacy" \
  0x078f29cf \
  0 \
  false \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# TYPE 2 등록 (V2 mode only)
cast send $REGISTRY_PROXY \
  "addRollupType(uint8,string,bytes4,uint8,bool)" \
  2 \
  "Optimism Bedrock" \
  0x0a49cb03 \
  1 \
  false \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# TYPE 3 등록 (V3 eligible)
cast send $REGISTRY_PROXY \
  "addRollupType(uint8,string,bytes4,uint8,bool)" \
  3 \
  "Optimism Bedrock DisputeGame" \
  0x0a49cb03 \
  1 \
  true \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

#### 등록 확인

```bash
# TYPE 1이 V3 eligible인지 확인
cast call $REGISTRY_PROXY "isValidRollupType(uint8)(bool)" 1

# Bitmap 확인 (bit 3만 set되어야 함)
cast call $REGISTRY_PROXY "getV3SeigniorageEligibleTypes()(uint256)"
# 예상 결과: 8 (0b1000 = TYPE 3 only)

# TYPE 1 설정 확인
cast call $REGISTRY_PROXY "getRollupTypeConfig(uint8)((bytes4,uint8,string))" 1
```

---

## 새로운 롤업 타입 추가 (TYPE 4+)

### 예시: Arbitrum Orbit 지원

```solidity
// Arbitrum은 다른 함수명 사용
registry.addRollupType(
    4,
    "ArbitrumOrbit",
    bytes4(keccak256("bridge()")),             // Arbitrum의 bridge getter
    2,                                          // BRIDGE_PATTERN_CUSTOM (새 패턴 필요)
    true                                        // V3 eligible
);
```

**주의사항:**
- BRIDGE_PATTERN_CUSTOM (2)를 사용하는 경우, `DepositManager` 수정 필요
- 새로운 bridge 함수 시그니처는 DepositManager에 로직 추가 필요

---

## 타입 설정 변경

### V3 시뇨리지 적격 여부만 변경

```solidity
// TYPE 1을 V3 시뇨리지에서 제외 (TYPE 자체는 유지)
registry.updateRollupType(
    1,
    "Optimism Legacy",
    bytes4(keccak256("l1StandardBridge()")),
    0,
    false  // V3 eligible = false
);
```

### 전체 설정 변경

```solidity
// TYPE 2의 tvlContractGetter 변경 (예: 프로토콜 업그레이드)
registry.updateRollupType(
    2,
    "Optimism Bedrock V2",                     // 이름 변경
    bytes4(keccak256("newPortalGetter()")),    // 새 getter
    1,
    true
);
```

---

## 배포 순서

1. ✅ V3 컨트랙트 배포 (`DeployV3Full.s.sol`)
2. ✅ 권한 설정 (Manager, Admin 등)
3. **✅ 롤업 타입 등록 (이 단계 필수!)**
4. ✅ 기존 롤업 마이그레이션 (필요시)
5. ✅ 테스트 롤업 등록 확인

---

## 문제 해결

### `EvmError: Revert` 발생 시

**증상:**
```bash
DepositManager.withdrawAndDepositL2() 호출 시 revert
```

**원인:**
- 롤업 타입이 등록되지 않음
- `getBridgePattern(type)` 호출 시 빈 값 반환

**해결:**
```bash
# 타입 등록 여부 확인
cast call $REGISTRY_PROXY "rollupTypeConfig(uint8)((bytes4,uint8,string))" 2

# tvlContractGetter가 0x00000000이면 등록 안 된 것
# 위 "등록 방법" 섹션 참고하여 등록
```

### Bitmap이 0으로 나오는 경우

**증상:**
```bash
cast call $REGISTRY_PROXY "getV3SeigniorageEligibleTypes()(uint256)"
# 결과: 0
```

**원인:**
- `addRollupType` 호출 시 `_v3Eligible=false`로 했거나
- 아직 타입을 등록하지 않음

**해결:**
```bash
# v3Eligible=true로 재등록 또는 업데이트
cast send $REGISTRY_PROXY \
  "updateRollupType(uint8,string,bytes4,uint8,bool)" \
  1 "Optimism Legacy" 0x078f29cf 0 true
```

---

## Function Selector 참조

주요 함수의 selector 값:

```solidity
// Optimism SystemConfig
l1StandardBridge()      = 0x078f29cf
optimismPortal()        = 0x0a49cb03
disputeGameFactory()    = 0x793c7d19

// 직접 계산
bytes4(keccak256("functionName()"))
```

---

## 체크리스트

배포 완료 후 다음을 확인하세요:

- [ ] TYPE 1, 2, 3이 등록되었는가?
- [ ] `isValidRollupType(1/2/3)` 모두 true 반환하는가?
- [ ] `getV3SeigniorageEligibleTypes()` 가 14 (0b1110) 반환하는가?
- [ ] 테스트 롤업으로 `withdrawAndDepositL2()` 호출 성공하는가?
- [ ] 기존 등록된 롤업들이 정상 작동하는가?
