# WinningChallengerTracker 통합 구현

> **작성일**: 2026-02-01  
> **상태**: ✅ 완료

## 개요

FaultDisputeGame이 WinningChallengerTracker를 사용하여 승리한 Challenger를 추적할 수 있도록 전체 배포 파이프라인을 수정했습니다.

## 수정 흐름

```
DisputeGameFactory.create()
    │
    ├─> FaultDisputeGame.initialize(rat, winningChallengerTracker)
    │       └─> FaultDisputeGame.winningChallengerTracker = _winningChallengerTracker
    │
    └─> game.resolve()
            └─> FaultDisputeGame._recordWinningChallenger(recipient)
                    └─> WinningChallengerTracker.recordWinner(game, winner, gameCreator)
```

## 수정된 파일

### Solidity Contracts

| 파일 | 변경 내용 |
|------|-----------|
| `interfaces/dispute/IInitializable.sol` | `initialize(address, address)` 시그니처 추가 |
| `src/dispute/DisputeGameFactory.sol` | `winningChallengerTracker` 상태 변수, `setWinningChallengerTracker()`, `create()` 수정 |
| `interfaces/dispute/IDisputeGameFactory.sol` | `winningChallengerTracker()`, `setWinningChallengerTracker()` 추가 |
| `src/L1/OPContractsManager.sol` | DeployInput에 `winningChallengerTrackerAddress` 추가, 배포 시 설정 |
| `interfaces/L1/IOPContractsManager.sol` | DeployInput에 `winningChallengerTrackerAddress` 추가 |
| `scripts/deploy/DeployOPChain.s.sol` | `winningChallengerTrackerAddress` 필드 추가 |
| `scripts/deploy/DeployConfig.s.sol` | `winningChallengerTrackerAddress` 필드 및 JSON 읽기 |
| `scripts/deploy/Deploy.s.sol` | DeployInput에 `winningChallengerTrackerAddress` 전달 |

### Go Pipeline

| 파일 | 변경 내용 |
|------|-----------|
| `op-deployer/pkg/deployer/state/chain_intent.go` | `WinningChallengerTrackerAddress` 필드 추가 |
| `op-deployer/pkg/deployer/opcm/opchain.go` | `WinningChallengerTrackerAddress` 필드 추가 |
| `op-deployer/pkg/deployer/pipeline/opchain.go` | 디폴트 값 및 전달 로직 |
| `op-chain-ops/cmd/devnet-allocs/main.go` | `deployWinningChallengerTracker: true` 옵션 |

## 코드 변경 상세

### 1. DisputeGameFactory.sol

```solidity
// 상태 변수 추가 (라인 80-81)
address public winningChallengerTracker;

// create() 함수 수정 (라인 183-188)
if (_gameType.raw() == GameTypes.CANNON.raw() && (rat != address(0) || winningChallengerTracker != address(0))) {
    IInitializable(address(proxy_)).initialize{ value: msg.value }(rat, winningChallengerTracker);
} else {
    proxy_.initialize{ value: msg.value }();
}

// setter 함수 추가 (라인 324-327)
function setWinningChallengerTracker(address _winningChallengerTracker) external onlyOwner {
    winningChallengerTracker = _winningChallengerTracker;
}
```

### 2. OPContractsManager.sol

```solidity
// DeployInput struct 수정 (라인 1720-1724)
struct DeployInput {
    // ... existing fields ...
    address ratAddress;
    address winningChallengerTrackerAddress;  // 추가
}

// deploy() 함수에서 WinningChallengerTracker 설정 (라인 1176-1179)
if (_input.winningChallengerTrackerAddress != address(0)) {
    IDisputeGameFactory(address(output.disputeGameFactoryProxy))
        .setWinningChallengerTracker(_input.winningChallengerTrackerAddress);
}
```

### 3. Go ChainProofParams

```go
// chain_intent.go
type ChainProofParams struct {
    // ... existing fields ...
    RatAddress                      common.Address
    WinningChallengerTrackerAddress common.Address  // 추가
}
```

### 4. devnet-allocs

```go
// main.go GlobalDeployOverrides
"deployWinningChallengerTracker": true,
```

## 빌드 확인

```bash
# Solidity 컴파일
cd lib/optimism/packages/contracts-bedrock && forge build --skip test
# ✅ Compiler run successful!

# Go 빌드
cd lib/optimism/op-deployer && go build ./...
# ✅ 성공

cd lib/optimism/op-chain-ops && go build ./cmd/devnet-allocs
# ✅ 성공
```

## E2E 테스트에서 사용법

### 방법 1: 수동 설정 (테스트용)

```go
// 1. WinningChallengerTracker 배포
trackerAddr, _, tracker, _ := bindings.DeployWinningChallengerTracker(auth, client)

// 2. DisputeGameFactory에 설정
disputeGameFactory.SetWinningChallengerTracker(auth, trackerAddr)

// 3. 이후 생성되는 DisputeGame은 자동으로 tracker 사용
```

### 방법 2: Pipeline 배포 (프로덕션)

```go
// ChainProofParams에 주소 설정
proofParams := state.ChainProofParams{
    WinningChallengerTrackerAddress: trackerAddr,
}

// op-deployer가 자동으로 DisputeGameFactory에 설정
```

## 다음 단계

1. **WinningChallengerTracker Go 바인딩 생성**
   ```bash
   abigen --abi=... --pkg=bindings --out=winning_challenger_tracker.go
   ```

2. **E2E 테스트 업데이트**
   - 실제 FaultDisputeGame 사용하는 테스트 작성
   - Mock 대신 실제 컨트랙트로 전환

3. **슬래싱 통합 테스트**
   - Layer2Manager.slashingCandidate() 호출
   - game.getWinningChallengers() 조회
   - DepositManager.slash() 실행
   - WTON 보상 분배 검증

## 관련 파일

- `src/dispute/WinningChallengerTracker.sol` - Tracker 구현체
- `src/dispute/IWinningChallengerTracker.sol` - 인터페이스
- `src/dispute/FaultDisputeGame.sol` - _recordWinningChallenger() 호출
