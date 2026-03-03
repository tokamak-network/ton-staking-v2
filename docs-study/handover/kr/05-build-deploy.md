# 5. 빌드 & 배포 파이프라인

## Solidity 컴파일

```bash
# TON Staking V2 컨트랙트
forge build

# Optimism 컨트랙트
cd lib/optimism/packages/contracts-bedrock
forge build --skip test
```

### FaultDisputeGame 사이즈 최적화

`foundry.toml`에서 FaultDisputeGame에 한해 `optimizer_runs = 200`으로 설정됨 (기본값 999,999).

| 컨트랙트 | 사이즈 | 마진 |
|----------|--------|------|
| FaultDisputeGame (기존) | ~24,907 bytes | -331 (초과) |
| FaultDisputeGame (수정 후) | 24,102 bytes | **+474** |
| WinningChallengerTracker | 1,203 bytes | +23,373 |

> **주의**: +474 bytes 여유만 있으므로, FaultDisputeGame에 추가 로직 삽입 시 사이즈 초과에 주의.

---

## Go 파이프라인

WinningChallengerTracker 주소를 배포 파이프라인에 전달하기 위해 수정된 파일:

### ChainProofParams (Intent)

```go
// op-deployer/pkg/deployer/state/chain_intent.go
type ChainProofParams struct {
    RatAddress                      common.Address
    WinningChallengerTrackerAddress common.Address  // 추가
}
```

### DeployOPChainInput

```go
// op-deployer/pkg/deployer/opcm/opchain.go
type DeployOPChainInput struct {
    // ...
    RatAddress                      common.Address
    WinningChallengerTrackerAddress common.Address  // 추가
}
```

### Pipeline 전달

```go
// op-deployer/pkg/deployer/pipeline/opchain.go
func makeDCI(...) opcm.DeployOPChainInput {
    return opcm.DeployOPChainInput{
        // ...
        WinningChallengerTrackerAddress: intent.WinningChallengerTrackerAddress,
    }
}
```

### Devnet Allocs

```go
// op-chain-ops/cmd/devnet-allocs/main.go
GlobalDeployOverrides: map[string]any{
    "deployWinningChallengerTracker": true,
}
```

### OPContractsManager

```solidity
// lib/optimism/.../src/L1/OPContractsManager.sol
// DeployInput에 winningChallengerTrackerAddress 추가
// deploy() 함수에서 DisputeGameFactory에 자동 설정
```

---

## Devnet Allocs 생성

```bash
cd lib/optimism
just devnet-allocs
```

> **주의**: `make devnet-allocs-offline`은 lib/optimism에 해당 타겟이 없을 수 있음. 올바른 명령어는 `just devnet-allocs`.

### Blueprint 이슈 해결

Devnet allocs 생성 시 FaultDisputeGame initcode 크기가 Blueprint 분할 임계값(23,500 bytes)보다 작으면 두 번째 Blueprint 주소가 `address(0)`이 되어 `NotABlueprint()` 에러 발생.

**해결**: `OPContractsManagerBase`에 `deployFromBlueprint()` 헬퍼 함수를 추가하여, 두 번째 Blueprint 주소가 `address(0)`인 경우 1-address 버전 호출하도록 수정.

적용 위치:
- `OPContractsManagerGameTypeAdder.addGameType()`
- `OPContractsManagerUpgrader.deployAndSetNewGameImpl()`
- `OPContractsManagerDeployer.deploy()`
- `OPContractsManagerInteropDeployer` (SuperPermissionedDisputeGame, SuperFaultDisputeGame)

---

## 배포 스크립트

**파일**: `script/DeployV3WithSlashingForDevnet.s.sol`

V3 마이그레이션 로직이 포함된 Devnet 배포 스크립트:

```solidity
function run() public override {
    // ... 기존 배포 로직 ...

    // V3 Migration (after all setup is complete)
    _setupV3ParameterSelectors();  // V3 setter 셀렉터 등록
    _setV3Parameters();            // V3 파라미터 설정
    _migrateToV3();                // V3 마이그레이션 실행

    vm.stopBroadcast();
}
```

**배포된 주소 파일**: `deployments/v3-devnet-slashing.json`

---

다음: [06-testing.md](./06-testing.md)
