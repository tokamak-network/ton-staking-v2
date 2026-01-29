---
id: actors-dao
sidebar_position: 6
---

# DAO

## 정의

Tokamak Network의 거버넌스 주체입니다 (DAOCommittee).

## 역할

- 시스템 파라미터 설정
- 컨트랙트 업그레이드
- V3 마이그레이션 실행
- 비상 조치 (일시정지 등)
- **RAT 몰수 담보금 회수 및 DAO 이름으로 스테이킹** (V3 신규)

## 보상

```
DAO 보상 = d · A + (L - y(x)) + Σ(검증자 없는 L2의 α·S_i) + RAT 몰수 담보금
           ───────────────────────────────────────────────────────   ─────────────────
           시뇨리지 기반 보상                                         페널티 기반 수입

여기서:
- d · A = 고정 분배 (SeigManagerV3_1에서 처리)
- L - y(x) = 미분배분 (SeigManagerV3_1에서 처리)
- α·S_i (|V_i|=0) = 검증자 없는 L2의 검증자 몫 (ValidatorRewardV1에서 처리)
- RAT 몰수 담보금 = 검증자 미응답 시 몰수된 C_off (RAT에서 회수)
  * 출처: 검증자의 스테이킹 담보금 (시뇨리지와 무관한 페널티)
  * 상세 프로세스는 아래 참조
```

### 구현 세부사항

| 보상 출처 | 처리 컨트랙트 | 대상 주소 | 청구 방법 | 출처 유형 |
|-----------|---------------|-----------|----------|----------|
| 고정 분배 (d · A) | `SeigManagerV3_1._distributeV3Seigniorage()` | `SeigManager.dao` (daoVault) | 자동 전송 | 시뇨리지 (신규 발행) |
| 미분배분 (L - y(x)) | `SeigManagerV3_1._distributeV3Seigniorage()` | `SeigManager.dao` (daoVault) | 자동 전송 | 시뇨리지 (신규 발행) |
| 검증자 없는 L2 (α·S_i) | `ValidatorRewardV1.distributeL2Rewards()` | `SeigManager.dao` (daoVault) | 자동 전송 | 시뇨리지 (신규 발행) |
| RAT 몰수 담보금 | `RAT.withdrawSlashingsToTreasury()` | RAT.treasury | 수동 호출 필요 | **검증자 스테이킹 (페널티)** |

> **참고**: 
> - `SeigManager.dao`는 daoVault 주소를 저장합니다.
> - **RAT 몰수 담보금은 시뇨리지가 아닌 검증자의 기존 스테이킹 담보금(coinage)에서 차감된 페널티입니다.** 상세 프로세스는 아래 참조.

## RAT 몰수 담보금 회수 (V3 신규)

검증자가 RAT에 응답하지 않으면 담보금(C_off)이 먼저 RAT 컨트랙트 명의로 스테이킹 이전됩니다. 챌린지 기간이 경과하여 완전 몰수가 확정되면, DAO가 이를 Treasury 명의로 회수할 수 있습니다.

**중요**: RAT 몰수 담보금은 **시뇨리지(신규 발행)가 아니라 검증자의 기존 스테이킹 담보금에서 차감된 페널티**입니다.

### 3단계 프로세스

**1단계: 선차감 (RAT 트리거 시)**
```
triggerAttentionTest() 호출 시 자동 처리:
- 검증자 명의 coinage에서 C_off 차감
- RAT 컨트랙트 명의 coinage로 이전
```

**2단계: 복구 또는 유지 (챌린지 기간)**
```
검증자 응답 시:
- submitEvidence() 성공 → RAT 명의 → 검증자 명의로 반환
- 미응답 → RAT 명의로 유지 (챌린지 기간 동안)
```

**3단계: DAO 회수 (완전 몰수 확정 후)**
```solidity
// DAO가 수동 호출
RAT.withdrawSlashingsToTreasury(systemConfig);

// 호출 조건:
// - latestDeadlineTest + challengeGameDuration + safetyBuffer 경과
// - RAT 컨트랙트 명의로 스테이킹된 해당 L2 coinage 잔액 > 0

// 처리 결과:
// - RAT 명의 coinage → Treasury 명의 coinage로 이전
// - Treasury는 해당 L2의 스테이킹 지분 획득
// - 향후 시뇨리지 분배 시 Treasury도 보상 수령 가능
// - DAO는 DepositManager.requestWithdrawal()로 언스테이킹 가능
```

### 타이밍 및 효과

| 단계 | 시점 | 상태 | 복구 가능 여부 |
|------|------|------|---------------|
| 선차감 | RAT 트리거 시 즉시 | 검증자 → RAT 명의 | ✅ 가능 (증거 제출 또는 Fraud Proof) |
| 챌린지 기간 | `latestDeadlineTest` ~ `+ challengeGameDuration` | RAT 명의로 유지 | ✅ 가능 |
| DAO 회수 가능 | `+ challengeGameDuration + safetyBuffer` 경과 후 | RAT → Treasury 명의 | ❌ 불가능 (완전 몰수) |

**최종 효과**:
- Treasury는 해당 L2의 스테이킹 지분 보유 → 시뇨리지 수령 가능
- DAO는 추가적인 수입원 확보
- 원하는 시점에 `DepositManager.requestWithdrawal()` 및 `processRequest()`로 TON/WTON 인출 가능

## 권한

| 함수 | 설명 |
|------|------|
| `setDaoDistributionRatio(d)` | DAO 분배 비율 설정 |
| `setMinStakingRatio(θ)` | 최소 스테이킹 비율 설정 |
| `setValidatorDistributionRatio(α)` | 검증자 분배 비율 설정 |
| `setHalfSaturationPoint(k)` | 반포화점 설정 |
| `setSlashingPenalty(C_off)` | 슬래싱 페널티 설정 |
| `setRatTriggerProbability(π_a)` | RAT 트리거 확률 설정 |
| `setEvidenceSubmissionPeriod(period)` | 증거 제출 기간 설정 |
| `migrateToV3()` | V3 모드 활성화 |
| `pause()` / `unpause()` | 시스템 일시정지/재개 |
| `withdrawSlashingsToTreasury(systemConfig)` | RAT 몰수 담보금 회수 |
