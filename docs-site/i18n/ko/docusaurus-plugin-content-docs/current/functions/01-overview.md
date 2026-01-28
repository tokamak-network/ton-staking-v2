---
id: functions-overview
sidebar_position: 1
---

# 함수 스펙 개요

이 섹션에서는 TON Staking V3 컨트랙트의 모든 함수에 대한 상세 스펙을 제공합니다.

## 빠른 참조

| 컨트랙트 | 주요 함수 | 목적 |
|----------|-----------|------|
| **SeigManager** | `updateSeigniorage`, `checkCurrentEligibility`, `migrateToV3` | 시뇨리지 계산 및 분배 |
| **DepositManager** | `deposit`, `requestWithdrawal`, `processRequest` | TON/WTON 스테이킹 관리 |
| **Layer2Manager** | `getBridgedTon`, `getLayer2BySystemConfig` | L2 등록 및 Bridged TON 조회 |
| **L1BridgeRegistry** | `layer2Tvl`, `registerRollupConfig`, `upgradeToType3` | 브릿지/포털 등록, TVL 조회 |
| **RAT** | `registerValidator`, `triggerAttentionTest`, `submitEvidence` | 밸리데이터 등록, RAT 테스트 |
| **ValidatorReward** | `distributeL2Rewards`, `claimAllRewards` | 밸리데이터 보상 분배 |
| **SeigManager (Slashing)** | `slashSequencerByGame` | 시퀀서 슬래싱 |
| **OperatorManagerFactory** | `createOperatorManager` | 오퍼레이터 매니저 배포 |

## 거버넌스 파라미터

### SeigManager 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|----------|------|------|------|
| `daoDistributionRatio` | `setDaoDistributionRatio(d)` | 0 < d < 1 | RAY |
| `minStakingRatio` | `setMinStakingRatio(θ)` | 0 < θ ≤ 1 | RAY |
| `validatorDistributionRatio` | `setValidatorDistributionRatio(α)` | 0 < α < 1 | RAY |
| `halfSaturationPoint` | `setHalfSaturationPoint(k)` | k > 0 | RAY (TON) |

### RAT 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|----------|------|------|------|
| `slashingPenalty` | `setSlashingPenalty(C_off)` | C_off > 0 | TON |
| `validatorBuffer` | `setValidatorBuffer(Δ)` | Δ ≥ 0 | TON |
| `ratTriggerProbability` | `setRatTriggerProbability(π_a)` | 0 < π_a ≤ 1 | RAY |
| `minimumThreshold` | `setMinimumThreshold(D_min)` | D_min > 0 | TON |
| `evidenceSubmissionPeriod` | `setEvidenceSubmissionPeriod(t)` | t > 0 | seconds |
| `validatorReward` | `setValidatorReward(addr)` | addr != 0 | address |

### ValidatorReward 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|----------|------|------|------|
| `seigManager` | `setSeigManager(addr)` | addr != 0 | address |
| `ratContract` | `setRatContract(addr)` | addr != 0 | address |

### 시퀀서 슬래싱 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|----------|------|------|------|
| `maxFraudProofCost` | `setMaxFraudProofCost(C_max)` | C_max > 0 | WTON |
| `sequencerAdditionalReward` | `setSequencerAdditionalReward(Δ)` | Δ ≥ 0 | WTON |
| `maxChallengers` | `setMaxChallengers(H_max)` | H_max > 0 | count |

## 관련 문서

- [시스템 개요](../01-system-overview.md)
- [시스템 아키텍처](../02-system-architecture.md)
- [컨트랙트 구조](../03-contract-structure.md)
- [컨트랙트 역할](../04-contract-roles.md)
- [행위자](../actors/actors-overview.md)
