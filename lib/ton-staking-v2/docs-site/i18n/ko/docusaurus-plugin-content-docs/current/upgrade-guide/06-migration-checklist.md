---
id: upgrade-migration-checklist
sidebar_position: 6
---

# 마이그레이션 체크리스트

## 사용자 대응

### 일반 스테이커
- [ ] V3 시뇨리지 분배 대상 변경 안내 (공지 필수)
- [ ] 검증자 참여 방법 및 혜택 안내
- [ ] FAQ 작성 및 배포

### 시퀀서
- [ ] 새로운 자격 조건 안내
- [ ] Bridged TON 기반 분배 안내
- [ ] 담보금 통합에 따른 자본 효율성 개선 안내
- [ ] 시뇨리지 계산 방식 변경 안내
- [ ] 슬래싱 정책 변경 안내

### 검증자 (신규)
- [ ] 검증자 등록 절차 안내
- [ ] RAT 메커니즘 설명
- [ ] 보상 계산 방식 안내
- [ ] `relaxedValidatorCheck` 정책 안내
- [ ] 검증자 가이드 문서 작성

## 배포 전 준비사항

### 컨트랙트 배포
- [ ] SeigManagerV3_1 배포
- [ ] SeigManagerV3_2 배포 (V2 호환 레이어)
- [ ] RAT 배포
- [ ] ValidatorRewardV1 배포
- [ ] DepositManagerV3 배포
- [ ] Layer2ManagerV3 배포
- [ ] L1BridgeRegistryV1_2 배포

### Selector Routing 설정 (SeigManagerProxy)
- [ ] SeigManagerV3_1 selector 등록
  - [ ] `setValidatorReward(address)`
  - [ ] `setDaoDistributionRatio(uint256)`
  - [ ] `setMinStakingRatio(uint256)`
  - [ ] `setValidatorDistributionRatio(uint256)`
  - [ ] `setHalfSaturationPoint(uint256)`
  - [ ] `migrateToV3()`
  - [ ] `onBridgedTonChange()`
  - [ ] `updateSeigniorage()` (오버라이드)
  - [ ] `updateSeigniorageLayer(address)` (오버라이드)

### 주소 및 권한 설정
- [ ] SeigManager에 RAT 주소 설정 (`setRATContract`)
- [ ] SeigManager에 ValidatorReward 주소 설정 (`setValidatorReward`)
- [ ] SeigManager에 Layer2Manager 주소 설정
- [ ] SeigManager에 L1BridgeRegistry 주소 설정
- [ ] RAT 권한 설정 (`onlyRAT` modifier 동작 확인)
- [ ] ValidatorReward 권한 설정

### 파라미터 설정
- [ ] `daoDistributionRatio` (d) 설정 (예: 0.2e27 = 20%)
- [ ] `minStakingRatio` (θ) 설정 (예: 0.1e27 = 10%)
- [ ] `validatorDistributionRatio` (α) 설정 (예: 0.2e27 = 20%)
- [ ] `halfSaturationPoint` (k) 설정 (예: 10,000,000e27 TON)
- [ ] `relaxedValidatorCheck = true` 설정 (초기값)
- [ ] RAT 파라미터 설정
  - [ ] `ratTriggerProbability` (π_a)
  - [ ] `slashingPenalty` (C_off)
  - [ ] `minimumThreshold` (D_min)
  - [ ] `evidenceSubmissionPeriod`

### V3 마이그레이션 실행
- [ ] `migrateToV3()` 호출 (DAO 거버넌스)
- [ ] `v3Migrated = true` 확인

## 배포 후 검증사항

### 기능 검증
- [ ] 시퀀서 스테이킹 조회 정상 동작 확인
- [ ] 검증자 담보금 조회 정상 동작 확인
- [ ] RAT coinage 전송 정상 동작 확인
- [ ] 시뇨리지 자격 체크 정상 동작 확인
- [ ] `relaxedValidatorCheck` flag 동작 확인
- [ ] **시뇨리지 분배 대상 변경** 확인 (L2 운영자/검증자에게만 분배)
- [ ] 시퀀서 시뇨리지 수령 확인
- [ ] 검증자 시뇨리지 분배 확인
- [ ] 미분배분(L - y) DAO 귀속 확인

### 보안 검증
- [ ] RAT 권한 체크 동작 확인 (`onlyRAT`)
- [ ] Coinage burn/mint 권한 확인
- [ ] 슬래싱 로직 테스트 (testnet)
- [ ] DAO 거버넌스 권한 확인
- [ ] V3 마이그레이션 권한 확인
- [ ] Selector routing 정상 동작 확인

### 시나리오 테스트
- [ ] V2 → V3 전환 시나리오
- [ ] 검증자 등록 시나리오
- [ ] RAT 트리거 및 응답 시나리오
- [ ] RAT 타임아웃 시나리오
- [ ] 시퀀서 슬래싱 시나리오
- [ ] 자격 미달 L2 시나리오
- [ ] 검증자 없는 L2 시나리오

## 운영 계획

### 1단계: 초기 운영 (검증자 유치)
- `relaxedValidatorCheck = true` (완화된 기준)
- 최소 담보금: C_off (낮은 진입 장벽)
- 모니터링: 검증자 수, 네트워크 보안 지표, RAT 응답률

### 2단계: 성장기 (보안 강화)
- DAO 거버넌스로 `relaxedValidatorCheck = false` 전환
- 최소 담보금: D_validator = C_off + Δ_validator
