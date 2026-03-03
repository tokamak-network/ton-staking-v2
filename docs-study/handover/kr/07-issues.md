# 7. 해결된 이슈 & 제약사항

## 해결된 주요 이슈

### 이슈 1: FaultDisputeGame EVM 24KB 제한 초과

- **현상**: WinningChallenger 추적 로직(mapping + array + view 함수) 추가 시 컨트랙트 사이즈 24,907 bytes로 EIP-170 제한 초과
- **원인**: RAT 관련 로직 + WinningChallengerTracker 연동 로직으로 인한 바이트코드 증가
- **해결**:
  1. WinningChallengerTracker를 **외부 컨트랙트로 분리** (1,203 bytes)
  2. `foundry.toml`에서 FaultDisputeGame에 한해 `optimizer_runs`를 999,999 → **200**으로 하향
  3. FaultDisputeGame 내 view 함수(`getWinningChallengers` 등) 제거
- **결과**: 24,102 bytes (마진 +474 bytes)

---

### 이슈 2: devnet-allocs NotABlueprint Panic

- **현상**: `just devnet-allocs` 실행 시 `DeployImplementations` 단계에서 `NotABlueprint()` 에러
- **원인**: FaultDisputeGame initcode 크기(22,216 bytes)가 Blueprint 분할 임계값(23,500 bytes)보다 작아 두 번째 Blueprint 주소가 `address(0)`이 됨. `Blueprint.deployFrom(addr1, address(0))` 호출 시 빈 코드에서 에러 발생.
- **해결**: `OPContractsManagerBase`에 `deployFromBlueprint()` 헬퍼 함수 추가. 두 번째 Blueprint 주소가 `address(0)`인 경우 1-address 버전 호출.
- **적용 위치**:
  - `OPContractsManagerGameTypeAdder.addGameType()` - line 501
  - `OPContractsManagerUpgrader.deployAndSetNewGameImpl()` - line 936, 948
  - `OPContractsManagerDeployer.deploy()` - line 1078, 1103
  - `OPContractsManagerInteropDeployer` - SuperPermissionedDisputeGame, SuperFaultDisputeGame
- **검증**: `just devnet-allocs` 실행 성공, `.devnet/` 디렉토리에 allocs 파일 정상 생성

---

### 이슈 3: V3 마이그레이션 미수행

- **현상**: `TestSlashing_ReRegistrationAfterSlashing` 테스트 실패. `V2DelegatecallFailedError (0x1b53d9e5)` 발생.
- **원인**: Genesis 파일에서 `v3Migrated = false` 상태. 배포 스크립트 수정은 완료했으나 Genesis 재생성 전.
- **호출 스택**: `CandidateAddOn.updateSeigniorage()` → `SeigManager.updateSeigniorage()` → `SeigManagerV3_1._updateSeigniorageV2Delegatecall()` → `SeigManagerV3_2.updateSeigniorageV2()` [delegatecall] FAIL
- **해결**: `DeployV3WithSlashingForDevnet.s.sol`에 V3 마이그레이션 로직 추가:
  - `_setupV3ParameterSelectors()`: V3 setter 셀렉터 등록
  - `_setV3Parameters()`: V3 파라미터 설정 (k, θ, d, α 등)
  - `_migrateToV3()`: V3 활성화
- **상태**: 배포 스크립트 수정 완료. Genesis 재생성(`just devnet-allocs`) 후 정상 동작 예상.

---

### 이슈 4: getStakeBalance 호환성

- **현상**: V3에서 `DepositManager.accStaked()` deprecated
- **해결**: `op-e2e/slashing/slashing_helpers.go`에서 `SeigManager.stakeOf()` 사용으로 변경

---

## 알려진 제약사항

| # | 제약 | 설명 |
|---|------|------|
| 1 | **사이즈 마진** | FaultDisputeGame이 +474 bytes 여유만 있음. 추가 로직 삽입 시 사이즈 초과 주의 |
| 2 | **Go Workspace** | `lib/optimism` 패키지 사용 테스트는 `op-e2e/go.work` 필요. Mock 테스트는 `GOWORK=off` |
| 3 | **Kona prestate** | lib/optimism의 faultproofs 테스트 시 Kona prestate 파일 필요 (Alphabet은 dummy OK) |
| 4 | **Docker** | Full Optimism devnet 테스트 시 Docker Desktop 실행 필요 |
| 5 | **Genesis 재생성** | 컨트랙트 변경 후 반드시 `just devnet-allocs` 재실행 필요 |
| 6 | **V3 마이그레이션** | Genesis에서 `v3Migrated = true` 상태여야 `updateSeigniorage()` 정상 동작 |
| 7 | **Multi-Challenger 해상도** | MockFaultDisputeGame3에서 다수 Challenger가 attack할 때, 두 번째 claim이 첫 번째와 충돌 가능. 실제 FaultDisputeGame에서는 정상 |
| 8 | **최소 스테이크** | Operator 등록에 Genesis에 설정된 `minimumAmount` 이상의 스테이크 필요 |

---

다음: [08-file-map.md](./08-file-map.md)
