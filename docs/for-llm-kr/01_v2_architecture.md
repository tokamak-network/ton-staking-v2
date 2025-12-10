# V2 아키텍처 분석

## 1. V2 핵심 컨트랙트 구조

```
contracts/
├── stake/
│   ├── managers/
│   │   ├── SeigManagerV1_3.sol       ← V3에서 업그레이드 (SeigManagerV1_4)
│   │   ├── DepositManagerV1_2.sol    ← V3에서 업그레이드 (DepositManagerV1_3)
│   │   └── *Storage*.sol             ← V3 스토리지 추가
│   ├── tokens/
│   │   └── RefactorCoinageSnapshot.sol (변경 없음)
│   └── Layer2Registry.sol            (변경 없음)
├── layer2/
│   ├── Layer2ManagerV1_1.sol         ← V3에서 업그레이드 (Layer2ManagerV1_2)
│   ├── OperatorManagerV1_1.sol       (변경 없음)
│   └── L1BridgeRegistryV1_1.sol      ← V3에서 업그레이드 (L1BridgeRegistryV1_2)
├── dao/
│   ├── CandidateAddOnV1_1.sol        (변경 없음)
│   └── DAOCommittee_V1.sol           (변경 없음)
└── [V3 신규]
    └── validator/
        ├── ValidatorPoolV1.sol       ← 신규 (RAT 검증자 보상)
        └── ValidatorPoolStorage.sol
```

---

## 2. V2 시뇨리지 분배 흐름 (기존 - V3에서 폐기)

```
[V2 - 폐기됨]
updateSeigniorage() 호출 시:
1. maxSeig = (currentBlock - lastSeigBlock) × seigPerBlock
2. stakedSeig = maxSeig × (WTON총량 / TON총발행량)
3. L2별 분배 = TVL 비례

→ V3에서 완전히 새로운 분배 공식으로 대체됨
```

---

## 3. V2 두 가지 시뇨리지 분배 시스템

V2는 **두 가지 시뇨리지 분배 시스템**을 운영합니다:

### 3.1 스테이커 시뇨리지: Coinage Factor 방식 (_tot, _coinages)

```solidity
// _tot: 전체 스테이킹 풀의 "가상 잔액" 관리
// _coinages[layer2]: 각 L2 스테이커들의 "가상 잔액" 관리

// 1. updateSeigniorage 호출 시 _tot의 factor 증가
//    → 모든 스테이커의 잔액이 자동으로 늘어남 (리베이스 효과)
uint256 prevTotalSupply = _tot.totalSupply();
uint256 nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
_tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

// 2. 특정 L2가 commit() 호출 시, _tot에서 자신의 지분 정산
//    → 그동안 누적된 시뇨리지를 한번에 받음
uint256 prevTotalSupply = coinage.totalSupply();
uint256 nextTotalSupply = _tot.balanceOf(msg.sender);  // _tot에서 추적
uint256 seigs = nextTotalSupply - prevTotalSupply;     // 받을 시뇨리지

// 3. 해당 L2의 coinage factor도 업데이트
coinage.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, coinage.factor()));

// 4. 실제 WTON 민트 (DepositManager로)
IWTON(wton).mint(address(_depositManager), seigs);
```

**Coinage 특징:**
- `factor`: 잔액 승수. factor가 커지면 동일 원금의 실제 잔액이 증가
- `_tot`: 전체 풀. 매 블록 시뇨리지 발생 시 factor 증가
- `_coinages[layer2]`: L2별 풀. 해당 L2가 commit할 때 _tot에서 정산

### 3.2 L2 시퀀서 시뇨리지: RewardPerUint 방식 (l2RewardPerUint + initialDebt)

```solidity
// 1. 전체 L2 시뇨리지 계산 (TVL 비례)
l2TotalSeigs = maxSeig × (totalLayer2TVL / totalTONSupply)

// 2. 단위당 보상 누적 (선형 증가)
l2RewardPerUint += (l2TotalSeigs × WEI_UNIT) / totalLayer2TVL

// 3. L2별 보상 계산 (누적 - 초기부채)
layer2Seigs = (l2RewardPerUint × layer2Tvl_i) / WEI_UNIT - initialDebt_i

// 4. 초기부채 갱신 (다음 청구 기준점)
initialDebt_i = (l2RewardPerUint × newLayer2Tvl_i) / WEI_UNIT
```

**RewardPerUint 특징:**
- `l2RewardPerUint`: TVL 1단위당 누적 보상 (시간이 지나면서 계속 증가)
- `initialDebt`: 참여 시점의 누적값 스냅샷 (이미 받은 것으로 간주)
- **선형 비례**: TVL이 2배면 보상도 2배

### 3.3 V2 두 시스템 비교

| 구분 | Coinage (_tot, _coinages) | RewardPerUint (l2RewardPerUint) |
|------|---------------------------|--------------------------------|
| **대상** | 스테이커 (TON 예치자) | L2 시퀀서 |
| **분배 기준** | 스테이킹 지분 | L2 TVL |
| **메커니즘** | Factor 승수 방식 | 누적 단위 보상 방식 |
| **정산 시점** | L2가 commit할 때 | L2가 updateSeigniorage할 때 |
| **민트 대상** | DepositManager | Layer2Manager |

---

## 4. V2 → V3 스토리지 변경

V2는 3개의 스토리지 컨트랙트를 상속합니다. V3에서의 변경사항을 표시합니다.

```solidity
// ============================================
// SeigManagerStorage (기본 스토리지) - V3 변경사항
// ============================================

// --- 상수 (유지) ---
uint256 constant public RAY = 1e27;
uint256 constant public MAX_VALID_COMMISSION = RAY;
uint256 constant public MIN_VALID_COMMISSION = 0.01e27;

// --- 기본 컨트랙트 주소 ---
address internal _registry;        // ✅ 유지
address internal _depositManager;  // ✅ 유지
address internal _powerton;        // ⚪ V3: 미사용
address public dao;                // ✅ 유지

// --- 토큰 관련 (유지) ---
address internal _ton;             // ✅ 유지
address internal _wton;            // ✅ 유지
address public factory;            // ✅ 유지

// --- Coinage 관련 (V3에서 변경 없음) ---
RefactorCoinageSnapshotI internal _tot;                          // ✅ 유지 (변경 없음)
mapping (address => RefactorCoinageSnapshotI) internal _coinages; // ✅ 유지 (변경 없음)
mapping (address => uint256) internal _lastCommitBlock;           // ✅ 유지

// --- 시뇨리지 기본 ---
uint256 internal _seigPerBlock;    // ✅ 유지
uint256 internal _lastSeigBlock;   // ✅ 유지

// --- 일시정지 관련 (유지) ---
uint256 internal _pausedBlock;
uint256 internal _unpausedBlock;
bool public paused;

// --- 커미션 관련 ---
mapping (address => uint256) internal _commissionRates;          // ⚪ V3: 미사용
mapping (address => bool) internal _isCommissionRateNegative;    // ⚪ V3: 미사용
uint256 public adjustCommissionDelay;                            // ⚪ V3: 미사용
// ... 기타 커미션 관련 매핑들 미사용

// --- V2 분배율 ---
uint256 public powerTONSeigRate;   // ⚪ V3: 미사용
uint256 public daoSeigRate;        // ⚪ V3: 미사용 (V3는 daoDistributionRatio 사용)
uint256 public relativeSeigRate;   // ✅ V3: 전환 파라미터로 재사용 (r)
// 참고: stakedSeigFactor (λ)는 SeigManagerV1_4Storage에 추가됨

uint256 public accRelativeSeig;    // ⚪ V3: 미사용
uint256 public minimumAmount;      // ✅ 유지
uint256 public lastSnapshotId;     // ✅ 유지

// ============================================
// SeigManagerV1_1Storage - V3 변경사항
// ============================================
uint256 constant public SEIG_START_MAINNET = 10837698;           // ✅ 유지
uint256 constant public INITIAL_TOTAL_SUPPLY_MAINNET = 50000000000000000000000000000000000; // ✅ 유지
uint256 constant public BURNT_AMOUNT_MAINNET = 178111666909855730000000000000000;           // ✅ 유지

uint256 public seigStartBlock;     // ✅ 유지
uint256 public initialTotalSupply; // ✅ 유지
uint256 public burntAmountAtDAO;   // ✅ 유지

// ============================================
// SeigManagerV1_3Storage - V3 변경사항
// ============================================
struct Layer2Reward {
    uint256 layer2Tvl;       // ⚪ V3: 미사용 (V3는 bridgedTONInfo 사용)
    uint256 initialDebt;     // ⚪ V3: 미사용
    uint256 startBlock;      // ⚪ V3: 미사용
}

address public l1BridgeRegistry;   // ✅ 유지
address public layer2Manager;      // ✅ 유지
uint256 public layer2StartBlock;   // ✅ 유지
uint256 public l2RewardPerUint;    // ⚪ V3: 미사용 (V3는 bridgedTONRewardPerUint 사용)
uint256 public totalLayer2TVL;     // ⚪ V3: 미사용 (V3는 totalEffectiveBridgedTON 사용)

mapping(address => Layer2Reward) public layer2RewardInfo;  // ⚪ V3: 미사용 (V3는 bridgedTONInfo 사용)
mapping(address => uint256[]) public layer2PauseBlocks;    // ✅ 유지
mapping(address => mapping(uint256 => uint256)) public layer2UnpauseBlocks; // ✅ 유지

bool internal _lock;  // ✅ 유지

// ============================================
// SeigManagerV1_4Storage (V3 신규 추가)
// ============================================
// → 02_v3_distribution.md 및 04_implementation.md 에서 상세 정의
```

---

## 5. V3 스토리지 변경 요약

| 기존 스토리지 | V3 상태 | 비고 |
|------------|---------|------|
| `_tot` | ✅ 유지 | 변경 없음 |
| `_coinages` | ✅ 유지 | 변경 없음 |
| `_powerton` | ⚪ 미사용 | 스토리지 슬롯 유지, V3에서 사용 안함 |
| `powerTONSeigRate` | ⚪ 미사용 | 스토리지 슬롯 유지, V3에서 사용 안함 |
| `relativeSeigRate` | ✅ 재사용 | V3 전환 파라미터 r로 활용 |
| `l2RewardPerUint` | ⚪ 미사용 | 스토리지 슬롯 유지, V3에서 사용 안함 |
| `totalLayer2TVL` | ⚪ 미사용 | 스토리지 슬롯 유지, V3에서 사용 안함 |
| `layer2RewardInfo` | ⚪ 미사용 | 스토리지 슬롯 유지, V3에서 사용 안함 |

| SeigManagerV1_4Storage (신규) | 설명 |
|------------------------------|------|
| `daoDistributionRatio` | d: DAO 분배율 |
| `minStakingRatio` | θ: 최소 스테이킹 비율 |
| `validatorDistributionRatio` | α: 검증자 분배율 |
| `halfSaturationPoint` | k: 반포화점 |
| `bridgedTONRewardPerUint` | Bridged TON 단위당 누적 보상 |
| `totalEffectiveBridgedTON` | x: 전체 유효 Bridged TON |
| `bridgedTONInfo` | L2별 Bridged TON 정보 매핑 |
| `validatorPool` | ValidatorPool 컨트랙트 주소 |
| `stakedSeigFactor` | λ: 지분 시뇨리지 비율 (전환용) |

---

## 6. V3 핵심 변경: 스테이커 시뇨리지 역할 변경

| 구분 | V2 | V3 |
|------|-----|-----|
| **`_tot`, `_coinages`** | 사용 | ✅ **변경 없음** |
| **스테이커 시뇨리지** | `setFactor()`로 분배 | V3 분배에서 점진적 제외 (기존 로직 유지) |
| **스테이킹의 역할** | 시뇨리지 분배량 결정 | 자격 조건(S_i ≥ θ·B_i) 확인용 |

- 기존 스토리지 슬롯 구조는 **변경하지 않음** (프록시 패턴 호환)
- V3 신규 변수는 **SeigManagerV1_4Storage**에 추가
- `_tot`, `_coinages` 관련 함수는 **변경하지 않음**

백서 인용:
> "In TON Staking V3, the distribution amount is determined based on each L2's Bridged TON.
> **L1 staking does not determine the distribution amount; rather, it functions as a minimum requirement to receive seigniorage.**"

| 수혜자 | V2 | V3 |
|--------|-----|-----|
| **스테이커** | ✅ Coinage factor 시뇨리지 | 점진적 감소 후 V3 분배 대상 아님 (자격 조건으로 사용) |
| **L2 시퀀서** | ✅ TVL 비례 | ✅ Bridged TON 비례 |
| **검증자** | ❌ 없음 | ✅ α·y(x)/n |
| **DAO** | ✅ daoSeigRate | ✅ d·A₂ + 미분배분 |
