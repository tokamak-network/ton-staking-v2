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

### 🟢 이슈 #2: devnet-allocs 생성 중 NotABlueprint() Panic (해결 완료)
*   **현상**: `just devnet-allocs` 실행 시 `DeployImplementations` 단계에서 예외 발생(`revision id 33 cannot be reverted`).
    > **참고**: 기존 문서에 `make devnet-allocs-offline`으로 기록되어 있었으나, 현재 `lib/optimism`에는 해당 타겟이 없음. 올바른 명령어는 `just devnet-allocs`.
*   **원인**: `OPContractsManager`가 `Blueprint.deployFrom(addr1, addr2, ...)` (2-address 버전)을 무조건적으로 호출함. 현재 `FaultDisputeGame`의 initcode 크기(22,216 bytes)가 Blueprint 라이브러리의 분할 임계값(23,500 bytes)보다 작아 두 번째 Blueprint 주소가 `address(0)`이 됨. `Blueprint.parseBlueprintPreamble(address(0).code)` 호출 시 코드가 없어 `NotABlueprint()` 에러 발생.
*   **해결**: `OPContractsManagerBase`에 `deployFromBlueprint()` 헬퍼 함수 추가. 두 번째 Blueprint 주소가 `address(0)`인 경우 1-address 버전을, 아닌 경우 2-address 버전의 `Blueprint.deployFrom`을 호출하도록 수정.
*   **적용 위치**:
    - `OPContractsManagerGameTypeAdder.addGameType()` - line 501
    - `OPContractsManagerUpgrader.deployAndSetNewGameImpl()` - line 936, 948
    - `OPContractsManagerDeployer.deploy()` - line 1078, 1103
    - `OPContractsManagerInteropDeployer` - SuperPermissionedDisputeGame, SuperFaultDisputeGame 배포
*   **검증**: `just devnet-allocs` 실행 성공, `.devnet/` 디렉토리에 allocs 파일 정상 생성 확인.
*   **상태**: **✅ 해결 완료** (2025-02-02)

---

## 🚀 3. 다음 세션을 위한 작업 가이드

> **주제: op-e2e 테스트를 통한 전체 통합 시나리오 확인**
>
> **현재 진행 상황:**
> 1. ✅ `NotABlueprint()` 에러 해결 완료 - `deployFromBlueprint()` 헬퍼 함수 도입.
> 2. ✅ `just devnet-allocs` 실행 성공, allocs 파일 생성 확인.
> 3. ✅ `FaultDisputeGame` 코드 크기 최적화 완료 (22.2KB).
>
> **당면 과제:**
> - `op-e2e` 테스트를 통한 전체 통합 시나리오 확인.
> - WinningChallengerTracker 연동 테스트 수행.
> - RAT (Randomized Attention Test) 통합 테스트.
>
> **참고 경로:**
> - `lib/optimism/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol`
> - `lib/optimism/packages/contracts-bedrock/src/L1/OPContractsManager.sol`
> - `lib/optimism/packages/contracts-bedrock/src/libraries/Blueprint.sol`
> - `lib/optimism/op-e2e/` - E2E 테스트 디렉토리
