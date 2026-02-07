# Web-UI 검증 보고서

**검증 일시**: 2026-02-03 20:58 KST
**검증 환경**: macOS Darwin 24.4.0
**검증 방법**: CLI cast 명령어로 컨트랙트 데이터 직접 조회

---

## 검증 결과 요약

### 시스템 상태
| 항목 | 값 | 상태 |
|------|-----|------|
| L1 Block | ~4100 | ✅ 정상 |
| L1 Chain ID | 900 | ✅ 정상 |
| L2 Block | ~573000 | ✅ 정상 |
| L2 Chain ID | 901 | ✅ 정상 |

### Rollup Information
| 항목 | 값 | 상태 |
|------|-----|------|
| SystemConfig | `0x577AcB7fA48878245a854ba51eD051a5B47cF83f` | ✅ |
| Rollup Type | 3 (Optimism Bedrock DisputeGame) | ✅ |
| L2 TON | `0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E` | ✅ |
| Name | "Devnet L2" | ✅ |
| Rejected Seigs | false | ✅ |
| Rejected L2 Deposit | false | ✅ |

### System Parameters
| 항목 | 값 | 상태 |
|------|-----|------|
| V3 Migrated | true | ✅ |
| Total Validators | 0 | ✅ |
| Active Validators | 0 | ✅ |
| Min Collateral | 60.00 WTON | ✅ |

### Operator Information (버그 수정됨)
| 항목 | 값 | 상태 |
|------|-----|------|
| Operator Address | `0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc` | ✅ |
| OperatorManager | `0x97F06B72fa7D6ea5B8BE8BDE4B67e272128Ac7B7` | ✅ |
| CandidateAddOn | `0x0D6603a87508bE29859B120C4688315ef95f275a` | ✅ |
| Sequencer Collateral | **1001.00 WTON** | ✅ |
| Layer2 Registered | true | ✅ |

### L2 Information
| 항목 | 값 | 상태 |
|------|-----|------|
| Batcher Hash | `0x000...70997970c51812dc3a010c7d01b50e0d17dc79c8` | ✅ |
| Unsafe Block Signer | `0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc` | ✅ |
| Gas Limit | 60,000,000 | ✅ |
| L1 Standard Bridge | `0x95E1bDf199beb2D11174C9f15CB2D0D1D165bCF7` | ✅ |
| Optimism Portal | `0xbF6531954Aa355f478e54fEDff94D9D9E7008D79` | ✅ |

### Portal Status
| 항목 | 값 | 상태 |
|------|-----|------|
| Guardian | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | ✅ |
| Paused | false | ✅ |

### Dispute Games
| 항목 | 값 | 상태 |
|------|-----|------|
| Game Count | 0 | ✅ (No games yet) |

### User Balances (Test Account: 0x90F79bf...)
| 항목 | 값 | 상태 |
|------|-----|------|
| ETH | ~10,100 ETH | ✅ |
| TON | 120,000 TON | ✅ |
| WTON | 110,000 WTON | ✅ |

---

## 버그 수정 내역

### 1. Operator 로딩 로직 버그 (App.tsx:279-338)

**문제**:
`rollupConfigInfo(systemConfig)`이 `(status, candidateAddOn)`을 반환하는데,
코드에서 `configInfo[1]`을 `operatorManager`로 잘못 해석함.

**수정 전**:
```typescript
const configInfo = await layer2Manager.rollupConfigInfo(CONFIG.contracts.systemConfig);
const operator = await layer2Manager.operatorOfRollupConfig(CONFIG.contracts.systemConfig);
const operatorManager = configInfo[1]; // 잘못됨 - 이것은 candidateAddOn
```

**수정 후**:
```typescript
// operatorOfRollupConfig returns OperatorManager address
const operatorManager = await layer2Manager.operatorOfRollupConfig(CONFIG.contracts.systemConfig);
// Then get CandidateAddOn from OperatorManager
candidateAddOn = await layer2Manager.candidateAddOnOfOperator(operatorManager);
```

**영향**:
- Operator 탭의 모든 데이터가 이제 정확하게 표시됨
- Sequencer Collateral이 0이 아닌 **1001.00 WTON**으로 올바르게 표시됨
- Layer2 Registry 상태가 정확하게 표시됨

---

## 검증 명령어

### Node Status 검증
```bash
cast chain-id --rpc-url http://localhost:8545  # Expected: 900
cast chain-id --rpc-url http://localhost:9545  # Expected: 901
cast block-number --rpc-url http://localhost:8545
cast block-number --rpc-url http://localhost:9545
```

### Rollup Information 검증
```bash
L1_BRIDGE_REGISTRY="0x2dE080e97B0caE9825375D31f5D0eD5751fDf16D"
SYSTEM_CONFIG="0x577AcB7fA48878245a854ba51eD051a5B47cF83f"
cast call $L1_BRIDGE_REGISTRY "getRollupInfo(address)(uint8,address,bool,bool,string)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
```

### Operator Information 검증
```bash
LAYER2_MANAGER="0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44"
SYSTEM_CONFIG="0x577AcB7fA48878245a854ba51eD051a5B47cF83f"

# OperatorManager
OPERATOR_MANAGER=$(cast call $LAYER2_MANAGER "operatorOfRollupConfig(address)(address)" $SYSTEM_CONFIG --rpc-url http://localhost:8545)

# CandidateAddOn
CANDIDATE_ADDON=$(cast call $LAYER2_MANAGER "candidateAddOnOfOperator(address)(address)" $OPERATOR_MANAGER --rpc-url http://localhost:8545)

# Sequencer Collateral
SEIG_MANAGER="0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe"
cast call $SEIG_MANAGER "stakeOf(address,address)(uint256)" $CANDIDATE_ADDON $OPERATOR_MANAGER --rpc-url http://localhost:8545
# Expected: 1001000000000000000000000000000 (1001 WTON)
```

---

## 결론

✅ **모든 핵심 데이터 검증 완료**

- Node Status: 정상
- Rollup Information: 정상
- System Parameters: 정상
- Operator Information: **버그 수정 후 정상**
- L2 Information: 정상
- Portal Status: 정상
- Dispute Games: 정상 (0개)
- User Balances: 정상

**Web-UI는 이제 실제 컨트랙트 데이터를 정확하게 표시합니다.**
