# TON Staking V3 컨트랙트 분석 가이드

> **목적**: Delegate Staking 서비스 개발을 위한 ton-staking-v2(V3) 컨트랙트 구조 파악
> **작성일**: 2026-01-26

---

## 목차

1. [시스템 개요](#1-시스템-개요)
2. [컨트랙트 구조](#2-컨트랙트-구조)
3. [핵심 컨트랙트 분석](#3-핵심-컨트랙트-분석)
4. [시뇨리지 분배 흐름](#4-시뇨리지-분배-흐름)
5. [Delegate Staking 연동 포인트](#5-delegate-staking-연동-포인트)
6. [주요 함수 레퍼런스](#6-주요-함수-레퍼런스)
7. [단위 변환 가이드](#7-단위-변환-가이드)

---

## 1. 시스템 개요

### 1.1 V3 경제 모델 요약

```
전체 시뇨리지 (A)
│
├─► DAO 고정분: S_DAO = d × A
│
└─► L2 분배 가능량: L = (1-d) × A
    │
    └─► 쌍곡선 함수: y(x) = L × (x / (k + x))
        │
        ├─► L2별 시뇨리지: S_i = y(x) × (B̃_i / x)
        │   │
        │   ├─► 시퀀서 보상: o_i = (1-α) × S_i
        │   │
        │   └─► 검증자 보상: v_j = α × S_i / |V_i|
        │
        └─► 미분배분: L - y(x) → DAO Treasury
```

### 1.2 핵심 파라미터

| 파라미터 | 기호 | 설명 | 컨트랙트 변수 |
|----------|------|------|---------------|
| DAO 분배 비율 | d | DAO에 고정 할당되는 비율 | `daoDistributionRatio` |
| 최소 스테이킹 비율 | θ | 시뇨리지 자격 조건 | `minStakingRatio` |
| 검증자 분배 비율 | α | 검증자 풀 할당 비율 | `validatorDistributionRatio` |
| 반포화점 | k | 쌍곡선 중간점 | `halfSaturationPoint` |
| 최대 챌린저 수 | H_max | Fraud Proof 비용 계산 | `maxChallengers` |
| Fraud Proof 비용 | C_max | 단일 챌린지 비용 | `maxFraudProofCost` |

### 1.3 자격 조건 (Eligibility)

L2가 시뇨리지를 받으려면:

```
T_i ≥ max(θ × B_i, H_max × C_max + Δ_seq)

여기서:
- T_i = 시퀀서 스테이킹 금액
- B_i = Bridged TON (L2에 브릿지된 TON)
- θ × B_i = 시뇨리지 자격 조건
- H_max × C_max + Δ_seq = Fraud Proof 비용 커버
```

---

## 2. 컨트랙트 구조

### 2.1 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                         L1 (Ethereum)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐     ┌─────────────────┐                    │
│  │  TON (ERC20)    │     │  WTON (ERC20)   │                    │
│  │  18 decimals    │────►│  27 decimals    │                    │
│  └─────────────────┘     └────────┬────────┘                    │
│                                   │                             │
│                    ┌──────────────┼──────────────┐              │
│                    │              │              │              │
│                    ▼              ▼              ▼              │
│  ┌─────────────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  DepositManagerV3   │  │ SeigManager  │  │    RAT       │    │
│  │  (스테이킹 관리)      │  │   V3_1       │  │ (검증자 관리) │    │
│  └──────────┬──────────┘  │ (시뇨리지)    │  └──────────────┘    │
│             │             └──────┬───────┘                      │
│             │                    │                              │
│             ▼                    ▼                              │
│  ┌─────────────────────────────────────────┐                    │
│  │           Layer2ManagerV3               │                    │
│  │         (L2 등록, 보상 전송)              │                    │
│  └──────────────────┬──────────────────────┘                    │ 
│                     │                                           │
│                     ▼                                           │
│  ┌─────────────────────────────────────────┐                    │
│  │        L1BridgeRegistryV1_2             │                    │
│  │    (브릿지 등록, Bridged TON 조회)        │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 컨트랙트별 역할

| 컨트랙트 | 파일 경로 | 핵심 역할 |
|----------|----------|----------|
| **SeigManagerV3_1** | `src/stake/managers/SeigManagerV3_1.sol` | 시뇨리지 계산 및 분배 |
| **SeigManagerV3_2** | `src/stake/managers/SeigManagerV3_2.sol` | V2 레거시 로직 (delegatecall) |
| **DepositManagerV3** | `src/stake/managers/DepositManagerV3.sol` | TON/WTON 스테이킹 관리 |
| **Layer2ManagerV3** | `src/layer2/Layer2ManagerV3.sol` | L2 등록, 보상 전송 |
| **L1BridgeRegistryV1_2** | `src/layer2/L1BridgeRegistryV1_2.sol` | 브릿지 등록, TVL 조회 |
| **RAT** | `src/validator/RAT.sol` | 검증자 등록, 어텐션 테스트 |
| **ValidatorRewardV1** | `src/validator/ValidatorRewardV1.sol` | 검증자 보상 분배 |

### 2.3 상속 구조

```
SeigManagerV3_1
├── ProxyStorage           (프록시 패턴 기본)
├── AuthControlSeigManager (접근 제어)
├── SeigManagerStorage     (V1 스토리지)
├── SeigManagerV1_1Storage (V1.1 스토리지)
├── DSMath                 (수학 라이브러리)
├── SeigManagerV1_3Storage (V1.3 스토리지)
├── SeigManagerV1_4Storage (V3 핵심 스토리지) ← 가장 중요!
└── ISeigManagerV3         (V3 인터페이스)
```

---

## 3. 핵심 컨트랙트 분석

### 3.1 SeigManagerV3_1 구조

```
src/stake/managers/SeigManagerV3_1.sol (932 lines)
│
├── [Line 1-47] Imports & Custom Errors
│   ├── FullMath, DSMath (수학 라이브러리)
│   ├── IWTON, ILayer2Manager 등 (인터페이스)
│   └── Custom Errors (NotMigratedError, OnlyRatError 등)
│
├── [Line 49-117] Contract Declaration & Modifiers
│   ├── 상속: ProxyStorage, SeigManagerStorage, ...
│   ├── 상수: WEI_UNIT(1e18), GWEI_UNIT(1e9), RAY_UNIT(1e27)
│   └── Modifiers: whenNotPaused, onlyDepositManager, whenV3Active
│
├── [Line 119-148] Events
│   ├── Comitted (커밋 완료)
│   ├── SeigGiven2 (시뇨리지 분배)
│   └── EligibilityChanged (자격 변경)
│
├── [Line 150-211] Governance Functions
│   ├── setDaoDistributionRatio(ratio)
│   ├── setMinStakingRatio(ratio)
│   ├── setValidatorDistributionRatio(ratio)
│   └── setHalfSaturationPoint(k)
│
├── [Line 253-302] Callback Functions (V3)
│   ├── onBridgedTonChange() ← 브릿지 변경 시 호출
│   └── onStakingChange(layer2) ← 스테이킹 변경 시 호출
│
├── [Line 304-393] View Functions (V3)
│   ├── checkCurrentEligibility(layer2) ← 자격 확인
│   ├── getSequencerStaked(layer2) ← 담보금 조회
│   ├── hyperbolicSaturation(x, L) ← 쌍곡선 계산
│   ├── calculateL2Seigniorage(layer2, totalY, totalX)
│   └── estimateL2Seigniorage(layer2) ← 예상 보상
│
├── [Line 467-534] Seigniorage Functions
│   ├── updateSeigniorage() ← 진입점
│   ├── _updateSeigniorageV3() ← V3 로직
│   └── _updateSeigniorageV2Delegatecall() ← V2 위임
│
├── [Line 536-622] Internal V3 Distribution
│   ├── _increaseTotV3() ← 총 시뇨리지 계산
│   ├── _distributeV3Seigniorage(A) ← 핵심 분배 로직
│   ├── _distributeL2Rewards(y, x) ← L2별 보상
│   └── _mintDaoReward(sDao, L, y) ← DAO 민팅
│
├── [Line 693-735] RAT Integration
│   ├── transferCoinageToRat() ← RAT 선차감
│   ├── transferCoinageFromRat() ← RAT 복구
│   └── transferCoinageFromRatTo() ← 슬래싱 확정
│
└── [Line 741-932] DepositManager Callbacks & View Functions
    ├── onDeposit() ← 예치 콜백
    ├── onWithdraw() ← 출금 콜백
    └── stakeOf(), stakeOfTotal() 등 조회 함수
```

### 3.2 SeigManagerV1_4Storage (V3 스토리지)

```solidity
// src/stake/managers/SeigManagerV1_4Storage.sol

// ═══════════════════════════════════════════════════════════════
// V3 핵심 파라미터
// ═══════════════════════════════════════════════════════════════

uint256 public daoDistributionRatio;     // d: DAO 분배 비율 (RAY)
uint256 public minStakingRatio;          // θ: 최소 스테이킹 비율 (RAY)
uint256 public validatorDistributionRatio; // α: 검증자 분배 비율 (RAY)
uint256 public halfSaturationPoint;       // k: 반포화점 (RAY)

// ═══════════════════════════════════════════════════════════════
// Bridged TON 관련
// ═══════════════════════════════════════════════════════════════

uint256 public totalEffectiveBridgedTON;  // x = Σ B̃_i (전체 유효 Bridged TON)

struct BridgedTONInfo {
    uint256 currentBridgedTON;    // B_i: 현재 Bridged TON
    uint256 effectiveBridgedTON;  // B̃_i: 유효 Bridged TON (자격 없으면 0)
    uint256 initialDebt;          // 초기부채 (MasterChef 패턴)
    uint256 startBlock;           // 참여 시작 블록
    bool isEligible;              // 자격 여부
}

mapping(address => BridgedTONInfo) public bridgedTONInfo;  // layer2 → 정보

// ═══════════════════════════════════════════════════════════════
// Fraud Proof 파라미터
// ═══════════════════════════════════════════════════════════════

uint256 public maxChallengers;            // H_max
uint256 public maxFraudProofCost;         // C_max
uint256 public sequencerAdditionalReward; // Δ_seq

// ═══════════════════════════════════════════════════════════════
// 마이그레이션 & RAT
// ═══════════════════════════════════════════════════════════════

bool public v3Migrated;           // V3 마이그레이션 완료 여부
address public ratContract;       // RAT 컨트랙트 주소
address public v2Logic;           // V2 로직 컨트랙트 (delegatecall용)
```

### 3.3 Layer2ManagerV3 핵심 부분

```solidity
// src/layer2/Layer2ManagerV3.sol

// ═══════════════════════════════════════════════════════════════
// 핵심 매핑
// ═══════════════════════════════════════════════════════════════

mapping(address => address) public operatorOfLayer;  // layer2 → operator 주소
// ⭐ 시뇨리지 보상이 이 주소로 전송됨!

// ═══════════════════════════════════════════════════════════════
// 보상 전송 함수 (SeigManager에서만 호출)
// ═══════════════════════════════════════════════════════════════

function transferL2Seigniorage(address layer2, uint256 amount)
    external
    onlySeigManger
{
    address operator = operatorOfLayer[layer2];
    require(operator != address(0), "wrong operator");

    // ⭐ 여기서 operator 주소로 WTON 전송!
    IERC20(wton).safeTransfer(operator, amount);

    emit TransferWTON(layer2, operator, amount);
}

// ═══════════════════════════════════════════════════════════════
// Bridged TON 조회
// ═══════════════════════════════════════════════════════════════

function getBridgedTonByLayer(address layer2) external view returns (uint256) {
    (address rollupConfig, ) = layerInfo(layer2);
    return getBridgedTon(rollupConfig);
}

function getBridgedTon(address rollupConfig) public view returns (uint256) {
    return IL1BridgeRegistry(l1BridgeRegistry).layer2Tvl(rollupConfig);
}
```

---

## 4. 시뇨리지 분배 흐름

### 4.1 전체 흐름도

```
┌─────────────────────────────────────────────────────────────────┐
│  1. updateSeigniorage() 호출 (누군가 트리거)                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. V3 마이그레이션 확인                                         │
│     └─► v3Migrated == true ? V3 로직 : V2 로직(delegatecall)    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. _increaseTotV3() - 총 시뇨리지 계산                          │
│     ├─► span = block.number - lastSeigBlock                     │
│     └─► A = span × seigPerBlock                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. _distributeV3Seigniorage(A)                                 │
│     ├─► sDao = A × d              (DAO 고정분)                  │
│     ├─► L = A - sDao              (L2 분배 가능량)              │
│     └─► y = L × x / (k + x)       (쌍곡선 적용)                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. _distributeL2Rewards(y, x)                                  │
│     ├─► l2Total = y × B̃_i / x     (이 L2 몫)                   │
│     ├─► valReward = l2Total × α   (검증자 몫)                   │
│     └─► seqReward = l2Total - valReward (시퀀서 몫)             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. 토큰 민팅 & 전송                                             │
│     ├─► WTON.mint(layer2Manager, seqReward)                     │
│     ├─► Layer2Manager.transferL2Seigniorage(layer2, seqReward)  │
│     │       └─► WTON.transfer(operatorOfLayer[layer2], amount)  │
│     │                              ↑                             │
│     │                    ⭐ 여기가 보상 수령 지점!               │
│     │                                                           │
│     ├─► WTON.mint(validatorReward, valReward)                   │
│     └─► WTON.mint(dao, sDao + (L - y))                          │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 핵심 함수 코드 분석

#### `_distributeV3Seigniorage()`

```solidity
function _distributeV3Seigniorage(uint256 a2)
    internal
    returns (uint256 l2TotalSeigs, uint256 layer2Seigs)
{
    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 1: DAO 고정분 계산                                  │
    // │ 공식: S_DAO = d × A                                     │
    // └─────────────────────────────────────────────────────────┘
    uint256 sDao = (a2 * daoDistributionRatio) / RAY_UNIT;
    //              └── A     └── d (1e27 단위)    └── 정규화

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 2: L2 분배 가능량 계산                              │
    // │ 공식: L = (1-d) × A = A - S_DAO                         │
    // └─────────────────────────────────────────────────────────┘
    uint256 L = a2 - sDao;

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 3: 유효 Bridged TON이 있으면 쌍곡선 분배           │
    // └─────────────────────────────────────────────────────────┘
    if (totalEffectiveBridgedTON > 0) {
        // 공식: y(x) = L × (x / (k + x))
        uint256 y = (L * totalEffectiveBridgedTON) /
                    (halfSaturationPoint + totalEffectiveBridgedTON);
        //           └── L    └── x                └── k        └── x

        l2TotalSeigs = y;
        layer2Seigs = _distributeL2Rewards(y, totalEffectiveBridgedTON);

        // DAO에 고정분 + 미분배분 민팅
        _mintDaoReward(sDao, L, y);
        // └── 총 DAO = sDao + (L - y)

    } else {
        // 유효 L2 없으면 전부 DAO로
        _mintDaoReward(sDao, L, 0);
    }
}
```

#### `_distributeL2Rewards()`

```solidity
function _distributeL2Rewards(uint256 y, uint256 totalEffective)
    internal
    returns (uint256 layer2Seigs)
{
    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 1: 자격 확인                                        │
    // └─────────────────────────────────────────────────────────┘
    (address rollupConfig, bool allowed) = _allowIssuanceLayer2Seigs(msg.sender);
    if (!allowed || _isPauseL2Seigniorage(msg.sender)) return 0;

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 2: 이 L2의 Bridged TON 정보 조회                    │
    // └─────────────────────────────────────────────────────────┘
    BridgedTONInfo storage info = bridgedTONInfo[msg.sender];
    if (!info.isEligible || info.effectiveBridgedTON == 0) return 0;

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 3: 이 L2의 시뇨리지 계산                            │
    // │ 공식: S_i = y(x) × (B̃_i / x)                            │
    // └─────────────────────────────────────────────────────────┘
    uint256 l2Total = (y * info.effectiveBridgedTON) / totalEffective;
    //                └── y(x)  └── B̃_i                └── x

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 4: 검증자/시퀀서 분리                               │
    // │ 공식: validator = α × S_i                               │
    // │       sequencer = (1-α) × S_i                           │
    // └─────────────────────────────────────────────────────────┘
    uint256 totalValReward = (l2Total * validatorDistributionRatio) / RAY_UNIT;
    layer2Seigs = l2Total - totalValReward;  // 시퀀서 몫

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 5: 시퀀서 보상 전송                                 │
    // │ ⭐ 핵심: layer2Manager → operatorOfLayer[layer2]        │
    // └─────────────────────────────────────────────────────────┘
    if (layer2Seigs > 0) {
        IWTON(_wton).mint(layer2Manager, layer2Seigs);
        ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
    }

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 6: 검증자 풀 보상 전송                              │
    // └─────────────────────────────────────────────────────────┘
    if (totalValReward > 0 && validatorReward != address(0)) {
        IWTON(_wton).mint(validatorReward, totalValReward);
        IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, totalValReward);
    }
}
```

#### `checkCurrentEligibility()`

```solidity
function checkCurrentEligibility(address layer2)
    public
    view
    returns (bool eligible, uint256 requiredStake, uint256 currentStake)
{
    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 1: 현재 시퀀서 스테이킹 금액 조회                    │
    // │ T_i = 시퀀서의 coinage 잔액                              │
    // └─────────────────────────────────────────────────────────┘
    currentStake = getSequencerStaked(layer2);

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 2: V3 마이그레이션 확인                             │
    // └─────────────────────────────────────────────────────────┘
    if (!v3Migrated) {
        return (false, 0, currentStake);
    }

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 3: rollupType 3만 V3 자격 적용                      │
    // │ (Type 1, 2는 V2 방식 유지)                               │
    // └─────────────────────────────────────────────────────────┘
    // ... rollupType 체크 로직 ...

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 4: Bridged TON 조회                                 │
    // │ B_i = 이 L2에 브릿지된 TON                               │
    // └─────────────────────────────────────────────────────────┘
    uint256 bridgedTon = ILayer2Manager(layer2Manager).getBridgedTonByLayer(layer2);

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 5: 최소 담보금 계산                                 │
    // │ 공식: required = max(θ × B_i, H_max × C_max + Δ_seq)    │
    // └─────────────────────────────────────────────────────────┘

    // 시뇨리지 자격 조건: θ × B_i
    uint256 minForSeigniorage = (bridgedTon * GWEI_UNIT * minStakingRatio) / RAY_UNIT;
    //                          └── B_i(TON) └── TON→WTON  └── θ         └── 정규화

    // Fraud Proof 비용 조건: H_max × C_max + Δ_seq
    uint256 minForFraudProof = maxChallengers * maxFraudProofCost + sequencerAdditionalReward;

    // 둘 중 큰 값
    requiredStake = minForSeigniorage > minForFraudProof ? minForSeigniorage : minForFraudProof;

    // ┌─────────────────────────────────────────────────────────┐
    // │ Step 6: 자격 판정                                        │
    // │ T_i ≥ required ?                                        │
    // └─────────────────────────────────────────────────────────┘
    eligible = currentStake >= requiredStake;
}
```

---

## 5. Delegate Staking 연동 포인트

### 5.1 보상 수령 방안

현재 V3 구조:
```
SeigManager → Layer2Manager → operatorOfLayer[layer2] (= Sequencer)
```

Delegate Staking 연동 옵션:

| 방안 | 설명 | 구현 난이도 | 신뢰성 |
|------|------|------------|--------|
| **A. Operator 변경** | DelegateStaking 컨트랙트를 operator로 등록 | 프로토콜 수정 필요 | 높음 |
| **B. 수동 전송** | Sequencer가 받은 보상을 컨트랙트에 전송 | 낮음 | 낮음 (신뢰 필요) |
| **C. Reward Receiver** | 보상 수령자 설정 기능 추가 | 프로토콜 수정 필요 | 높음 |

### 5.2 Bridged TON 증가 방법

```solidity
// DelegateStaking에서 TON을 L2 Vault로 브릿지하면:
// 1. L2의 Bridged TON (B_i) 증가
// 2. S_i = y(x) × (B̃_i / x) 증가
// 3. Sequencer 보상 증가

interface IL1Bridge {
    function depositERC20To(
        address _l1Token,      // TON 주소
        address _l2Token,      // L2 TON 주소
        address _to,           // 수신자 (L2 Vault)
        uint256 _amount,       // 금액
        uint32 _minGasLimit,   // 가스 리밋
        bytes calldata _extraData
    ) external;
}
```

### 5.3 호출해야 할 View 함수

```solidity
// 1. 자격 확인
(bool eligible, uint256 required, uint256 current) =
    seigManager.checkCurrentEligibility(layer2);

// 2. Bridged TON 조회
uint256 bridgedTon = layer2Manager.getBridgedTonByLayer(layer2);

// 3. 예상 보상 조회
uint256 estimated = seigManager.estimateL2Seigniorage(layer2);

// 4. 시퀀서 담보금 조회
uint256 staked = seigManager.getSequencerStaked(layer2);

// 5. 전체 유효 Bridged TON
uint256 totalEffective = seigManager.totalEffectiveBridgedTON();
```

### 5.4 구독해야 할 이벤트

```solidity
// SeigManagerV3_1 이벤트
event V3SeigniorageDistributed(
    uint256 totalSeigniorage,
    uint256 l2MaxAllocation,
    uint256 totalDistributed,
    uint256 daoAmount,
    uint256 validatorPoolAmount
);

event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);

// Layer2ManagerV3 이벤트
event TransferWTON(
    address layer2,
    address to,      // ← 보상 수령자
    uint256 amount
);
```

---

## 6. 주요 함수 레퍼런스

### 6.1 SeigManagerV3_1

| 함수 | 타입 | 설명 |
|------|------|------|
| `updateSeigniorage()` | external | 시뇨리지 분배 트리거 |
| `checkCurrentEligibility(layer2)` | view | 자격 조건 확인 |
| `getSequencerStaked(layer2)` | view | 시퀀서 담보금 조회 |
| `estimateL2Seigniorage(layer2)` | view | 예상 보상 조회 |
| `hyperbolicSaturation(x, L)` | view | 쌍곡선 계산 |
| `onBridgedTonChange()` | external | 브릿지 변경 콜백 |
| `onStakingChange(layer2)` | external | 스테이킹 변경 콜백 |

### 6.2 Layer2ManagerV3

| 함수 | 타입 | 설명 |
|------|------|------|
| `transferL2Seigniorage(layer2, amount)` | external | 보상 전송 (SeigManager만) |
| `getBridgedTonByLayer(layer2)` | view | Bridged TON 조회 |
| `layerInfo(layer2)` | view | L2 설정 정보 |
| `operatorOfLayer(layer2)` | view | operator 주소 조회 |

### 6.3 L1BridgeRegistryV1_2

| 함수 | 타입 | 설명 |
|------|------|------|
| `layer2Tvl(rollupConfig)` | view | TVL (Bridged TON) 조회 |
| `rollupType(rollupConfig)` | view | 롤업 타입 (1,2,3) |

---

## 7. 단위 변환 가이드

### 7.1 토큰 단위

| 토큰 | Decimals | 단위 | 변환 |
|------|----------|------|------|
| TON | 18 | WEI | 1 TON = 1e18 wei |
| WTON | 27 | RAY | 1 WTON = 1e27 ray |

```
TON → WTON: amount * 1e9 (GWEI_UNIT)
WTON → TON: amount / 1e9
```

### 7.2 비율 단위

| 변수 | 단위 | 예시 |
|------|------|------|
| `daoDistributionRatio` | RAY (1e27) | 10% = 0.1 × 1e27 |
| `minStakingRatio` | RAY (1e27) | 10% = 0.1 × 1e27 |
| `validatorDistributionRatio` | RAY (1e27) | 20% = 0.2 × 1e27 |

### 7.3 코드 예시

```solidity
// 비율 계산
uint256 RAY = 1e27;
uint256 daoRatio = 10 * RAY / 100;  // 10%

// TON → WTON 변환
uint256 tonAmount = 1000 * 1e18;  // 1000 TON
uint256 wtonAmount = tonAmount * 1e9;  // 1000 WTON (in RAY)

// 비율 적용
uint256 daoShare = (totalAmount * daoRatio) / RAY;
```

---

## 부록: 파일 위치 참조

```
ton-staking-v2/
├── src/
│   ├── stake/
│   │   ├── managers/
│   │   │   ├── SeigManagerV3_1.sol      ← V3 메인
│   │   │   ├── SeigManagerV3_2.sol      ← V2 레거시
│   │   │   ├── SeigManagerV1_4Storage.sol ← V3 스토리지
│   │   │   └── DepositManagerV3.sol
│   │   └── interfaces/
│   │       └── ISeigManagerV3.sol       ← V3 인터페이스
│   ├── layer2/
│   │   ├── Layer2ManagerV3.sol
│   │   ├── L1BridgeRegistryV1_2.sol
│   │   └── interfaces/
│   │       ├── ILayer2Manager.sol
│   │       └── IL1Bridge.sol            ← 브릿지 인터페이스
│   └── validator/
│       ├── RAT.sol
│       └── ValidatorRewardV1.sol
└── docs/
    └── specs-kr/
        ├── 01-system-overview.md
        └── 07-economics-whitepaper-summary.md
```

---

## 다음 단계

1. [ ] `SeigManagerV3_1.sol` 전체 읽기
2. [ ] `test/v3/` 테스트 코드 분석
3. [ ] `forge test --match-path "test/v3/*" -vvvv` 실행하며 추적
4. [ ] Delegate Staking 연동 방안 결정
5. [ ] 프로토콜 팀에 보상 수령 주소 변경 가능 여부 확인
