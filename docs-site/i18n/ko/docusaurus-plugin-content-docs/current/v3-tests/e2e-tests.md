---
id: e2e-tests
title: Go E2E 테스트
sidebar_position: 5
---

# Go E2E 테스트 (7개)

op-e2e 패키지의 통합 테스트로, L1-L2 전체 스택 검증을 수행합니다.

**위치**: `op-e2e/faultproofs/`

## 시스템 테스트 (3개)

### 기본 시스템 검증

| ID | 테스트 함수 | 파일 | 설명 | 실행 시간 |
|----|------------|------|------|----------|
| SYS-001 | TestTONStakingSystemStartup | rat_system_test.go | 컨트랙트 배포 검증 | ~1s |
| SYS-002 | TestAccountBalances | rat_system_test.go | Genesis 잔액 검증 | ~1s |
| SYS-003 | TestRATContractCall | rat_system_test.go | RAT 컨트랙트 호출 검증 | ~1s |

**커버리지:**
- ✅ L1 컨트랙트 배포 확인
- ✅ Genesis 계정 잔액 확인
- ✅ RAT 컨트랙트 기본 호출

---

## RAT 시나리오 테스트 (3개)

### RAT 전체 플로우 검증

| ID | 테스트 함수 | 파일 | 설명 | 실행 시간 |
|----|------------|------|------|----------|
| RAT-E2E-001 | TestSimpleRAT_ValidatorRegistration | rat_challenge_test.go | Validator 등록 플로우 | ~4s |
| RAT-E2E-002 | TestSimpleRAT_GameCreation | rat_challenge_test.go | DisputeGame 생성 및 RAT 트리거 | ~6s |
| RAT-E2E-003 | TestSimpleRAT_ChallengerWins | rat_challenge_test.go | Challenger 승리 전체 시나리오 | ~20s |

**커버리지:**
- ✅ 검증자 등록 및 담보금 예치
- ✅ DisputeGame 생성
- ✅ RAT 자동 트리거
- ✅ 증거 미제출 시 슬래싱
- ✅ Challenger 보상 지급

---

## RAT Client E2E 테스트 (1개)

### 완전한 통합 테스트

| ID | 테스트 함수 | 파일 | 설명 | 실행 시간 |
|----|------------|------|------|----------|
| RAT-CLIENT-E2E-001 | TestRATClient_EvidenceSubmission_E2E | rat_state_root_test.go | RAT Client 전체 통합 테스트 | ~71s |

**테스트 환경:**
- **L1 환경**: Isolated Anvil with genesis (모든 컨트랙트 사전 배포)
- **L2 환경**: Isolated geth dev mode with archive state

**테스트 단계:**

1. **L2 트랜잭션 생성 및 state 변경**
   - L2에서 트랜잭션 실행
   - State trie 변경 발생

2. **OutputRootProof 계산**
   ```go
   type OutputRootProof struct {
       Version                  [32]byte
       StateRoot                [32]byte
       MessagePasserStorageRoot [32]byte
       BlockHash                [32]byte
   }
   ```

3. **Validator 등록 (prerequisite)**
   - RAT 컨트랙트에 검증자 등록
   - 충분한 담보금 예치

4. **DisputeGame 생성 (RAT 자동 트리거)**
   - DisputeGameFactory를 통해 게임 생성
   - RAT 자동 트리거 확인

5. **RAT Client subprocess 실행**
   - Go 클라이언트 프로세스 시작
   - L1 이벤트 구독 및 처리

6. **Adjacent Leaves 증거 생성 (debug API 사용)**
   - `debug_accountRange` API 호출
   - Divergence witness 생성
   - State leaf proof 추출

7. **StateLeafEvidence 온체인 제출**
   - ABI 인코딩된 증거 제출
   - 트랜잭션 전송 및 확인

8. **Type 3 Evidence Verifier 검증**
   - OutputRootProof 검증
   - State trie proof 검증
   - 최종 승인

9. **Gas 사용량 측정**
   - 증거 제출 가스: ~277k gas

**커버리지:**
- ✅ L1 (Anvil) + L2 (geth) 통합
- ✅ OutputRootProof 계산 및 검증
- ✅ DisputeGame 생성 및 RAT 트리거
- ✅ RAT Client subprocess 실행
- ✅ Adjacent leaves 실제 증거 생성 (debug API)
- ✅ StateLeafEvidence 온체인 제출 및 검증
- ✅ Type 3 Evidence Verifier 통합

---

## 실행 방법

### 전체 테스트 실행

```bash
cd op-e2e
make test
```

### 특정 테스트 실행

```bash
# 시스템 테스트만
GOWORK=off go test -v -run TestTONStakingSystemStartup ./faultproofs

# RAT 시나리오 테스트
GOWORK=off go test -v -run TestSimpleRAT ./faultproofs

# RAT Client E2E 테스트
GOWORK=off go test -v -run TestRATClient_EvidenceSubmission_E2E ./faultproofs
```

### 실행 시간

- **전체 7개 테스트**: ~80초
- **시스템 테스트 (3개)**: ~3초
- **RAT 시나리오 (3개)**: ~30초
- **RAT Client E2E (1개)**: ~71초

---

## 테스트 환경 구성

### 필수 요구사항

- Go 1.21+
- Foundry (anvil)
- geth (dev mode)

### 환경 변수

```bash
# op-e2e 테스트는 자동으로 환경 구성
# 수동 설정 불필요
```

### 디버깅

```bash
# 로그 출력 활성화
GOWORK=off go test -v -run TestRATClient ./faultproofs 2>&1 | tee test.log

# 특정 로그 레벨
LOG_LEVEL=debug go test -v -run TestRATClient ./faultproofs
```

---

## 주요 검증 항목

### L1 컨트랙트 검증
- SeigManager 배포 및 초기화
- RAT 컨트랙트 배포 및 설정
- ValidatorReward 연결 확인
- L1BridgeRegistry 설정

### L2 통합 검증
- L2 geth 노드 정상 실행
- Archive state 활성화 확인
- debug API 접근 가능 확인

### RAT 플로우 검증
- 검증자 등록 및 담보금 관리
- DisputeGame 생성 및 RAT 트리거
- 증거 제출 및 검증
- 슬래싱 및 보상 지급

### 가스 효율성
- 증거 제출 가스: ~277k
- 검증자 등록 가스: 측정됨
- RAT 트리거 가스: 측정됨

---

## 다음 단계

- [RAT Client 유닛 테스트](rat-client-unit-tests.md) - RAT Client Go 유닛 테스트
- [V3 모드 테스트](v3-mode-tests.md) - Solidity 통합 테스트
- [테스트 개요로 돌아가기](overview.md)
