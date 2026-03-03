# 8. 전체 파일 맵

## Solidity 컨트랙트 (핵심)

| 파일 경로 | 상태 | 역할 |
|-----------|------|------|
| `lib/optimism/.../src/dispute/WinningChallengerTracker.sol` | 신규 | 승자 추적 컨트랙트 |
| `lib/optimism/.../src/dispute/IWinningChallengerTracker.sol` | 신규 | 인터페이스 |
| `lib/optimism/.../src/dispute/FaultDisputeGame.sol` | 수정 | Dispute 게임 핵심 |
| `lib/optimism/.../src/dispute/DisputeGameFactory.sol` | 수정 | 게임 팩토리 |
| `lib/optimism/.../interfaces/dispute/IInitializable.sol` | 수정 | initialize 시그니처 추가 |
| `lib/optimism/.../interfaces/dispute/IDisputeGameFactory.sol` | 수정 | tracker getter/setter 추가 |
| `lib/optimism/.../src/L1/OPContractsManager.sol` | 수정 | 배포 매니저 |
| `lib/optimism/.../interfaces/L1/IOPContractsManager.sol` | 수정 | DeployInput 수정 |
| `lib/optimism/.../src/libraries/Blueprint.sol` | 참조 | Blueprint 배포 로직 (이슈 #2 관련) |

> **참고**: `lib/optimism/...` = `lib/optimism/packages/contracts-bedrock`

## Solidity 컨트랙트 (TON Staking)

| 파일 경로 | 상태 | 역할 |
|-----------|------|------|
| `src/layer2/Layer2Manager_Slashing.sol` | 수정 | 슬래싱 후보 검증 및 실행 |
| `src/stake/managers/DepositManager_Slashing.sol` | 수정 | 슬래싱 실행 및 보상 분배 |
| `src/stake/managers/SeigManager_Slashing.sol` | 수정 | 시뇨리지 슬래싱 처리 |
| `src/layer2/interfaces/IFaultDisputeGame.sol` | 수정 | DisputeGame 인터페이스 |
| `src/stake/interfaces/IIDepositManager.sol` | 수정 | DepositManager 인터페이스 |

## Mock 컨트랙트 (테스트용)

| 파일 경로 | 역할 |
|-----------|------|
| `src/mocks/MockFaultDisputeGame2.sol` | 단순 게임 Mock (기존) |
| `src/mocks/MockFaultDisputeGame3.sol` | 실제 게임 흐름 시뮬레이션 Mock |
| `src/mocks/MockDisputeGameFactory3.sol` | Mock 게임 팩토리 |
| `src/mocks/MockSystemConfig.sol` | setDisputeGameFactory() 함수 추가 |

---

## Go 파이프라인

| 파일 경로 | 역할 |
|-----------|------|
| `lib/optimism/op-deployer/pkg/deployer/state/chain_intent.go` | ChainProofParams에 Tracker 주소 |
| `lib/optimism/op-deployer/pkg/deployer/opcm/opchain.go` | DeployOPChainInput에 Tracker 주소 |
| `lib/optimism/op-deployer/pkg/deployer/pipeline/opchain.go` | Pipeline 전달 로직 |
| `lib/optimism/op-chain-ops/cmd/devnet-allocs/main.go` | Devnet allocs 생성 옵션 |
| `lib/optimism/packages/contracts-bedrock/scripts/deploy/DeployOPChain.s.sol` | 배포 스크립트 |
| `lib/optimism/packages/contracts-bedrock/scripts/deploy/DeployConfig.s.sol` | 배포 설정 |
| `lib/optimism/packages/contracts-bedrock/scripts/deploy/Deploy.s.sol` | 메인 배포 |

---

## Foundry 테스트

| 파일 경로 | 테스트 수 | 내용 |
|-----------|----------|------|
| `test/v3/v3mode/AdvancedSlashing/BaseAdvancedSlashingTest.sol` | - | 베이스 테스트 |
| `test/v3/v3mode/AdvancedSlashing/SingleChallengerTest.t.sol` | 4 | 단일 챌린저 |
| `test/v3/v3mode/AdvancedSlashing/MultiChallengerEqualDistributionTest.t.sol` | 5 | 균등 분배 |
| `test/v3/v3mode/AdvancedSlashing/WinnerTrackingTest.t.sol` | 5 | 승자 추적 |
| `test/v3/v3mode/AdvancedSlashing/RemainderDistributionTest.t.sol` | 5 | 나머지 분배 |
| `test/v3/v3mode/AdvancedSlashing/RealisticGameFlowTest.t.sol` | 5 | 실제 게임 흐름 |

---

## E2E 테스트

| 파일 경로 | 역할 |
|-----------|------|
| `op-e2e/system/ton_system.go` | TON 시스템 래퍼 |
| `op-e2e/slashing/slashing_helpers.go` | 공통 헬퍼 함수 |
| `op-e2e/slashing/real_game_helpers.go` | Full Optimism + TON 헬퍼 |
| `op-e2e/slashing/slashing_test.go` | 기본 슬래싱 테스트 |
| `op-e2e/slashing/slashing_challenger_test.go` | Real Challenger 테스트 (5개) |
| `op-e2e/slashing/multi_challenger_test.go` | Multi-Challenger 테스트 (6개) |
| `op-e2e/slashing/slashing_integration_test.go` | 슬래싱 연동 테스트 (4개) |
| `op-e2e/slashing/reward_distribution_test.go` | 보상 분배 테스트 (6개) |
| `op-e2e/slashing/edge_cases_test.go` | Edge Cases 테스트 (6개) |
| `op-e2e/slashing/delegator_protection_test.go` | Delegator 보호 테스트 (4개) |
| `op-e2e/slashing/complex_scenarios_test.go` | 복합 시나리오 테스트 (5개) |
| `op-e2e/slashing/permission_security_test.go` | 권한/보안 테스트 (7개) |
| `op-e2e/Makefile` | 테스트 실행 타겟 |
| `op-e2e/go.work` | Go workspace 설정 |

---

## 배포 스크립트

| 파일 경로 | 역할 |
|-----------|------|
| `script/DeployV3WithSlashingForDevnet.s.sol` | Devnet 배포 (V3 마이그레이션 포함) |
| `deployments/v3-devnet-slashing.json` | 배포된 컨트랙트 주소 |
| `.devnet/addresses.json` | Devnet allocs 결과 주소 |
| `lib/optimism/packages/contracts-bedrock/foundry.toml` | 컴파일 최적화 설정 |

---

## 기존 설계/구현 문서

| 문서 경로 | 설명 |
|-----------|------|
| `docs-study/AdvancedSlash/advanced-slash-architecture.md` | 전체 아키텍처 설계서 |
| `docs-study/AdvancedSlash/implementation-summary.md` | 구현 완료 문서 |
| `docs-study/AdvancedSlash/winning-challenger-tracking-plan.md` | Tracking 구현 계획 |
| `docs-study/AdvancedSlash/distributeBond-winner-analysis.md` | 승자 판정 분석 |
| `docs-study/AdvancedSlash/e2e-test/` | E2E 테스트 문서 모음 |
| `docs-study/AdvancedSlash/test/` | Foundry 테스트 문서 |
| `docs-study/AdvancedSlash/anotherOption/` | 보상 분배 대안 옵션 |
| `docs-study/AdvancedSlash/en/` | 영문 문서 |

---

다음: [09-quickstart.md](./09-quickstart.md)
