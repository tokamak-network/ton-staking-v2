# WinningChallengerTracker 통합 작업 로그

WinningChallengerTracker를 Optimism Dispute 시스템에 통합하는 과정에서 발생한 기술적 이슈와 해결 방안을 기록합니다.

---

## 📋 1. 작업 요약
WinningChallengerTracker 연동을 위해 컨트랙트, 인터페이스, Go 빌드 시스템 및 테스트 환경 전반에 걸친 수정을 진행했습니다.

| 구분 | 주요 변경 사항 | 관련 파일 |
| :--- | :--- | :--- |
| **Contract** | Tracker 주소 관리 및 초기화 로직 구현 | `DisputeGameFactory.sol`, `FaultDisputeGame.sol` |
| **Interface** | `initialize` 시그니처 업데이트 및 Getter 추가 | `IInitializable.sol`, `IDisputeGameFactory.sol` |
| **DevOps** | 코드 크기 초과 문제 해결을 위한 최적화 설정 | `foundry.toml` |
| **E2E Test** | Go 기반의 시스템 헬퍼 및 바인딩 생성 | `ton_system.go`, `winning_challenger_tracker.go` |

---

## ⚠️ 2. 주요 이슈 및 해결 과정

### 🔴 이슈 #1: FaultDisputeGame 코드 크기 초과 (Max Code Size Exceeded)
*   **현상**: `FaultDisputeGame`이 EIP-170의 24KB 제한을 약 1.7KB 초과하여 배포에 실패함.
*   **원인**: `WinningChallengerTracker` 연동 로직 및 `RAT` 관련 로직 추가로 인한 바이트코드 증가.
*   **해결**: `foundry.toml`에서 `FaultDisputeGame.sol`에 한해 `optimizer_runs`를 **999,999**에서 **200**으로 하향 조정. 최종 22.2KB로 축소 성공.

### 🟡 이슈 #2: devnet-allocs 생성 중 NotABlueprint() Panic
*   **현상**: `make devnet-allocs-offline` 실행 시 `DeployImplementations` 단계에서 예외 발생(`revision id 33 cannot be reverted`).
*   **원인**: `OPContractsManager`는 Blueprint(ERC-5202) 형식을 기대하지만, 배포된 바이트코드 서두에서 `0xFE71` 프리앰블을 찾지 못함.
*   **상태**: **분석 중**. `DisputeGameFactory`의 초기화 방식 변경이 Blueprint 배포 메커니즘에 의도치 않은 영향을 주었는지 조사 필요.

---

## 🚀 3. 다음 세션을 위한 작업 가이드

> **주제: WinningChallengerTracker 통합 및 devnet-allocs 디버깅**
>
> **현재 진행 상황:**
> 1. 컨트랙트(`FaultDisputeGame`, `DisputeGameFactory`) 수정 및 `forge build` 성공.
> 2. `foundry.toml` 최적화(runs=200)로 코드 크기 이슈 해결.
> 3. `lib/optimism` Go 의존성 빌드 완료.
>
> **당면 과제:**
> - `make devnet-allocs-offline` 중 `NotABlueprint()` 에러 해결.
> - `OPContractsManager`의 Blueprint 배포 방식과 충돌 지점 파악.
> - `op-e2e` 테스트 시나리오 검증.
>
> **참고 경로:**
> - `lib/optimism/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol`
> - `lib/optimism/packages/contracts-bedrock/src/L1/OPContractsManager.sol`