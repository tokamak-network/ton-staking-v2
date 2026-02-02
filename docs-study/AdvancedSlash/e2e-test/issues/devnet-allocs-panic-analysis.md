# Devnet Allocs 생성 중 Revision ID Revert Panic 분석 보고서

## 1. 이슈 개요
`WinningChallengerTracker` 통합 후 전체 시스템 검증을 위해 `make devnet-allocs-offline` 실행 시, Optimism의 `devnet-allocs` 도구에서 예외(Panic)가 발생하여 제네시스 파일 생성이 중단됨.

*   **발생 명령어**: `make devnet-allocs-offline` (내부적으로 `cd lib/optimism && just devnet-allocs` 호출)
*   **에러 메시지**: `Unexpected panic in script execution: revision id 33 cannot be reverted`
*   **발생 단계**: `deploy-implementations` 단계

## 2. 분석 결과

### 2.1 기존 이슈와의 차이점
*   **이전 이슈 (#2)**: `NotABlueprint()` 에러. 이는 `deployFromBlueprint()` 헬퍼 함수 도입으로 `OPContractsManager.sol` 수준에서 해결됨을 확인함.
*   **현재 이슈**: `revision id 33 cannot be reverted`. 이는 솔리디티 코드가 아닌 Go 기반의 EVM 시뮬레이터(`op-chain-ops/script`)에서 상태 스냅샷을 되돌리는 과정 중 발생하는 저수준 에러임.

### 2.2 기술적 원인 추정
1.  **스냅샷 불일치**: `deploy-implementations` 스크립트 실행 중 여러 컨트랙트를 배포하면서 생성된 저널(Journal) ID와 시뮬레이터가 관리하는 스냅샷 ID가 일치하지 않음.
2.  **Go-Geth 환경 문제**: `lib/optimism/op-chain-ops/script/script.go`의 `recover()` 로직에서 이 에러를 잡으려 시도하지만, 실제로는 패닉이 상위로 전파됨.
3.  **커밋 상태**: 현재 `lib/optimism`은 `039c2878b` (feat: add devnet-allocs tool) 커밋에 머물러 있으며, 해당 툴의 초기 구현 단계에서의 버그일 가능성이 높음.

### 2.3 Slashing E2E 테스트 현황
*   **위치**: `op-e2e/slashing/`
*   **주요 파일**:
    *   `slashing_test.go`: 기본 슬래싱 시나리오 (3개)
    *   `slashing_helpers.go`: 헬퍼 함수들
    *   `slashing_challenger_test.go`: 실제 챌린저 에이전트 연동 테스트 (3개)
    *   `multi_challenger_test.go`: 다중 챌린저 보상 분배 테스트 (7개)
*   **상태**: 제네시스 파일(`genesis-l1-staking-v3.json`) 생성 실패로 인해 테스트 실행 불가.

## 3. 향후 작업 계획

1.  **Panic 디버깅**:
    *   `lib/optimism/op-chain-ops/script/script.go`의 revert 로직 조사.
    *   `OPContractsManager.sol`에서 특정 배포 호출이 스냅샷을 깨뜨리는지 확인.
2.  **임시 우회 방안**:
    *   문제가 발생하는 구현체 배포 순서를 조정하거나, 필요 없는 배포 단계를 스킵하여 스냅샷 횟수 줄이기.
3.  **전체 통합 테스트**:
    *   Allocs 생성 성공 시, `op-e2e/slashing/` 내의 모든 테스트를 실행하여 `WinningChallengerTracker` 로직 검증.
