# TON Staking V3 Advanced Slashing E2E 테스트 프레임워크 개발 스펙

## 프로젝트 개요

**프로젝트명**: TON Staking V3 Advanced Slashing E2E 테스트 프레임워크  
**개발 기간**: 2026-01 ~ 2026-02 (약 2개월)  
**역할**: 풀스택 개발 (기획, 설계, 개발, 테스트)  
**규모**: 52개 E2E 테스트 케이스, 10+ 테스트 파일, 2가지 테스트 환경 구축

---

## 프로젝트 배경

TON Staking V3의 Advanced Slashing 기능은 Optimism의 FaultDisputeGame을 활용하여 잘못된 L2 상태를 제출한 Operator를 슬래싱하는 메커니즘입니다. 이 기능의 신뢰성을 보장하기 위해 실제 운영 환경과 유사한 E2E 테스트 프레임워크가 필요했습니다.

---

## 기술 스택

### Backend/Infrastructure
- **Go 1.22+**: 테스트 프레임워크 개발
- **Solidity**: 스마트 컨트랙트 (FaultDisputeGame, TON Staking V3)
- **Anvil**: 로컬 L1 블록체인 노드
- **Optimism Devnet**: Full L1+L2+op-node+batcher 환경

### Testing Framework
- **Go Testing**: 표준 테스트 프레임워크
- **Go Workspace**: 다중 모듈 의존성 관리
- **Makefile**: 테스트 자동화 및 빌드 관리

### 주요 라이브러리
- `github.com/ethereum-optimism/optimism`: Optimism E2E 테스트 인프라
- `github.com/ethereum/go-ethereum`: 이더리움 클라이언트
- `github.com/stretchr/testify`: 테스트 어설션

---

## 주요 개발 내용

### 1. 이중 테스트 환경 구축

#### 1.1 경량화 테스트 환경 (Anvil 기반)
- **목적**: 빠른 슬래싱 로직 검증 및 CI/CD 통합
- **인프라**: Anvil (L1만)
- **특징**: 
  - 실제 FaultDisputeGame.sol 사용
  - 수동 Challenger 조작 (`rat.AttackClaim`, `rat.ResolveGame`)
  - 41개 테스트 케이스, ~2분 실행 시간
- **파일**: `op-e2e/slashing/*_test.go` (10개 파일)

#### 1.2 실제 운영 환경 테스트 (Full Optimism Devnet)
- **목적**: 실제 op-challenger 서비스 통합 검증
- **인프라**: Full Optimism devnet (L1+L2+op-node+batcher)
- **특징**:
  - 실제 FaultDisputeGame.sol + 실제 op-challenger 서비스
  - 자동 Challenger 실행 (`game.StartChallenger()`)
  - 11개 테스트 케이스, ~90초 per test
- **파일**: `op-e2e/slashing/slashing_challenger_test.go`, `multi_challenger_test.go`

### 2. 테스트 카테고리화 및 체계화

총 52개 테스트를 6개 카테고리로 분류하여 유지보수성 향상:

| 카테고리 | 테스트 수 | 파일 | 설명 |
|---------|----------|------|------|
| **Edge Cases** | 6개 | `edge_cases_test.go` | 경계 조건 및 예외 상황 검증 |
| **Delegator Protection** | 4개 | `delegator_protection_test.go` | 위임자 자산 보호 검증 |
| **Complex Scenarios** | 5개 | `complex_scenarios_test.go` | 복잡한 시나리오 검증 |
| **Permission & Security** | 7개 | `permission_security_test.go` | 권한 및 보안 검증 |
| **Slashing Integration** | 4개 | `slashing_integration_test.go` | 슬래싱 연동 검증 |
| **Reward Distribution** | 6개 | `reward_distribution_test.go` | 보상 분배 검증 |
| **Real Challenger** | 11개 | `slashing_challenger_test.go`, `multi_challenger_test.go` | 실제 op-challenger 통합 |
| **기본 테스트** | 9개 | `slashing_test.go` | 기본 기능 검증 |

### 3. 핵심 기능 구현

#### 3.1 Multi-Challenger 보상 분배 시스템
- **문제**: 다수의 Challenger가 동시에 DisputeGame에 참여할 때 승리한 Challenger 추적 및 보상 균등 분배
- **해결**:
  - FaultDisputeGame 내부에 Winning Challenger 추적 기능 구현
  - `getWinningChallengers()`, `isWinningChallenger()` 함수 추가
  - 슬래싱 보상을 승리한 Challenger들에게 균등 분배하는 로직 구현
- **성과**: 3명 이상의 Challenger가 참여해도 정확한 보상 분배 검증 완료

#### 3.2 Go Workspace 통합
- **문제**: Optimism 라이브러리(`lib/optimism`)와 TON 프로젝트 간 의존성 관리
- **해결**:
  - `go.work` 파일을 통한 Go Workspace 설정
  - 로컬 `lib/optimism` 모듈과 원격 의존성 통합
  - Makefile에서 `GOWORK=off` 제거하여 workspace 모드 활성화
- **성과**: 모든 테스트가 Optimism 최신 코드와 통합되어 실행 가능

#### 3.3 테스트 헬퍼 프레임워크 구축
- **파일**: `op-e2e/slashing/slashing_helpers.go`, `real_game_helpers.go`
- **주요 기능**:
  - `StartRealGameTestEnv()`: Full Optimism devnet + TON 슬래싱 통합 환경
  - `connectSlashingContracts()`: 슬래싱 관련 컨트랙트 연결
  - `registerOperatorWithCandidateAddOn()`: Operator 등록 헬퍼
  - `executeSlashing()`: 슬래싱 실행 헬퍼
- **성과**: 테스트 코드 중복 제거, 재사용성 향상

### 4. Makefile 자동화

```makefile
# 전체 테스트 실행
make test-slashing-all              # 41개 테스트, ~2분

# 카테고리별 실행
make test-edge-cases               # Edge Cases (6개)
make test-delegator-protection     # Delegator Protection (4개)
make test-complex-scenarios        # Complex Scenarios (5개)
make test-permission-security      # Permission & Security (7개)
make test-slashing-integration     # Slashing Integration (4개)
make test-reward-distribution      # Reward Distribution (6개)

# 실제 op-challenger 테스트
make test-real-challenger          # 실제 FaultDisputeGame (5개)
make test-multi-challenger         # Multi-Challenger (6개)
```

---

## 해결한 기술적 도전 과제

### 1. Mock에서 실제 컨트랙트로 전환
- **초기**: MockFaultDisputeGame3 사용
- **문제**: 실제 운영 환경과 차이 발생
- **해결**: 실제 FaultDisputeGame.sol로 완전 전환
- **성과**: 실제 운영 환경과 동일한 조건에서 테스트 가능

### 2. Go Workspace 의존성 문제 해결
- **문제**: `GOWORK=off` 사용 시 로컬 `lib/optimism` 모듈을 찾지 못함
- **원인**: `real_game_helpers.go`가 Optimism 패키지에 의존
- **해결**: 모든 테스트 명령어에서 `GOWORK=off` 제거, Go workspace 모드 사용
- **성과**: 모든 카테고리별 테스트 정상 작동

### 3. 다중 Challenger 보상 분배 정밀도
- **문제**: 나눗셈 나머지 처리 및 정밀도 손실
- **해결**: 첫 번째 Challenger에게 나머지 지급, WTON 잔액 검증
- **성과**: 10^35 WTON 단위에서도 정확한 분배 검증 완료

### 4. Full Optimism Devnet 통합
- **도전**: L1+L2+op-node+batcher 전체 시스템 통합
- **해결**: `faultproofs.StartFaultDisputeSystem()` 활용
- **성과**: 실제 op-challenger 서비스와 통합 테스트 가능

---

## 개발 성과

### 정량적 성과
- ✅ **52개 E2E 테스트 케이스** 구현 및 통과
- ✅ **10개 테스트 파일** 작성
- ✅ **2가지 테스트 환경** 구축 (경량화 + 실제 운영)
- ✅ **6개 카테고리**로 체계화
- ✅ **100% 테스트 통과율** 달성

### 정성적 성과
- ✅ **실제 운영 환경 검증**: Full Optimism devnet 통합으로 실제 op-challenger 동작 검증
- ✅ **빠른 피드백**: 경량화 환경으로 CI/CD 통합 가능 (~2분)
- ✅ **유지보수성 향상**: 카테고리별 분류 및 헬퍼 함수 재사용
- ✅ **문서화**: 상세한 구현 보고서 및 사용 가이드 작성

---

## 기술적 하이라이트

### 1. 아키텍처 설계
- 이중 테스트 환경으로 속도와 정확성 모두 확보
- 카테고리별 분류로 테스트 목적 명확화
- 헬퍼 함수 재사용으로 코드 중복 제거

### 2. 통합 테스트 전략
- Mock → 실제 컨트랙트 전환으로 신뢰성 향상
- Go Workspace를 통한 다중 모듈 의존성 관리
- Makefile 자동화로 개발자 경험 개선

### 3. 엣지 케이스 처리
- 고액 스테이킹(10^35 WTON) 정밀도 검증
- 다중 Challenger 보상 분배 나머지 처리
- Delegator 자산 보호 검증

---

## 사용 기술 및 도구

- **언어**: Go, Solidity
- **프레임워크**: Go Testing, Optimism E2E Framework
- **인프라**: Anvil, Optimism Devnet
- **도구**: Makefile, Go Workspace
- **라이브러리**: go-ethereum, Optimism op-e2e

---

## 참고 문서

- [real-challenger-implementation-report.md](./real-challenger-implementation-report.md)
- [real-faultdisputegame-migration-complete.md](./real-faultdisputegame-migration-complete.md)
- [dispute-game-depth-bond-analysis.md](./dispute-game-depth-bond-analysis.md)
