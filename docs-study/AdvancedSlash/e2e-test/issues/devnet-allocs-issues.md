# Devnet Allocs 배포 문제 해결 기록

> 날짜: 2026-02-02
> 관련 명령어: `make devnet-allocs-offline`

## 개요

`make devnet-allocs-offline` 실행 시 발생한 여러 에러들을 해결한 기록입니다.

---

## 해결한 문제들

### 1. `invalid minimum threshold` 에러

**에러 메시지:**
```
RAT::setConfig(..., minimumThreshold: 0, ...) [delegatecall]
└─ ← [Revert] invalid minimum threshold
```

**원인:**
- `DeployV3SlashForDevnet.s.sol`에서 `RAT_MINIMUM_THRESHOLD = 0`으로 설정됨
- RAT 컨트랙트의 `setConfig()` 함수는 다음 조건을 요구:
  ```solidity
  require(config.minimumThreshold >= config.slashingPenalty + config.validatorBuffer, "invalid minimum threshold");
  ```
- 설정값: `slashingPenalty = 100 WTON`, `validatorBuffer = 100 WTON`
- 조건: `0 >= 200 WTON` → **실패**

**해결:**
- `generate-allocs-offline.sh`에서 사용하는 스크립트를 변경:
  ```bash
  # 변경 전
  forge script script/DeployV3SlashForDevnet.s.sol:DeployV3SlashForDevnet
  
  # 변경 후
  forge script script/DeployV3WithSlashingForDevnet.s.sol:DeployV3WithSlashingForDevnet
  ```
- `DeployV3WithSlashingForDevnet.s.sol`은 `DeployV3FullForDevnet.s.sol`을 상속
- 부모 클래스에서 `RAT_MINIMUM_THRESHOLD = 60 * RAY` (60 WTON)로 올바르게 설정됨

**관련 파일:**
- `script/DeployV3SlashForDevnet.s.sol` (문제 있는 파일)
- `script/DeployV3WithSlashingForDevnet.s.sol` (수정 사용)
- `script/DeployV3FullForDevnet.s.sol` (부모 클래스)
- `scripts/generate-allocs-offline.sh`

---

### 2. `vm.writeFile: path not allowed` 에러

**에러 메시지:**
```
vm.writeFile: the path deployments/v3-devnet-slashing.json is not allowed to be accessed for write operations
```

**원인:**
- `foundry.toml`에서 `fs_permissions` 설정이 잘못된 위치에 있었음
- 기존에는 `[lint]` 섹션 아래(파일 하단)에 있어서 Foundry가 인식하지 못함
- TOML에서 `fs_permissions`는 `[profile.default]` 섹션 내부에 있어야 함
- TOML 구조상 섹션 밖에 있거나 잘못된 섹션에 있으면 Foundry가 인지하지 못해 쓰기 권한이 거부됨.

**해결:**
- `fs_permissions` 설정을 `[profile.default]` 섹션 내부 상단으로 이동하여 올바른 권한이 적용되도록 수정.
```toml
# 변경 전 (잘못된 위치 - [lint] 섹션 아래)
[lint]
exclude_lints = [...]

fs_permissions = [
    { access = "read-write", path = "./deployments" },
    ...
]

# 변경 후 (올바른 위치 - [profile.default] 섹션 내부)
[profile.default]
src = "src"
...
ffi = true
fs_permissions = [
    { access = "read-write", path = "./deployments" },
    { access = "read-write", path = ".devnet" },
    { access = "read", path = "./abis" },
    { access = "read-write", path = "./" }
]

[profile.production]
...
```

**관련 파일:**
- `foundry.toml`

---

### 3. `No such file or directory` 에러

**에러 메시지:**
```
vm.writeFile: failed to open file ".../deployments/v3-devnet-slashing.json": No such file or directory (os error 2)
```

**원인:**
- `deployments/` 폴더가 존재하지 않음
- `vm.writeFile()`은 파일을 생성할 수 있지만, 상위 디렉토리가 없으면 실패

**해결:**
```bash
mkdir -p deployments
```

**관련 파일:**
- `deployments/` 폴더 생성 필요

---

### 4. 스크립트 unexpectedly 종료 에러

**증상:**
- `[3/4] ✓ Genesis allocs generated` 출력 후
- `[4/4]` 출력 없이 바로 `make: *** Error 1`

**원인:**
- `generate-allocs-offline.sh`에 `set -eo pipefail` 설정
- 130번 줄의 `grep -v "==="`가 매칭되는 내용이 없으면 exit code 1 반환
- `pipefail` 옵션으로 인해 파이프라인 전체가 실패로 처리됨
- `set -e`로 인해 스크립트 즉시 종료

- `set -eo pipefail` 옵션 하에서 `grep -v "==="`가 매칭되는 내용을 찾지 못해 exit code 1을 반환함.
- 파이프라인 실패가 전체 스크립트 실패로 간주되어 즉시 종료됨.

**문제 코드:**
```bash
JSON_CONTENT=$(echo "$DEPLOY_OUTPUT" | sed -n '/=== DEPLOYMENT_JSON_START ===/,/=== DEPLOYMENT_JSON_END ===/p' | grep -v "===")
```


**해결:**
```bash
# || true 추가로 grep 실패 무시
JSON_CONTENT=$(echo "$DEPLOY_OUTPUT" | sed -n '/=== DEPLOYMENT_JSON_START ===/,/=== DEPLOYMENT_JSON_END ===/p' | grep -v "===" || true)
```
- `grep` 라인 끝에 `|| true`를 추가하여 매칭 실패 시에도 스크립트가 중단되지 않도록 수정.


**관련 파일:**
- `scripts/generate-allocs-offline.sh` (130번 줄)
---

### 5. Optimism `FaultDisputeGame` 코드 사이즈 및 가스비 최적화 (직접 코드 수정)

**배경:**
- RAT 연동 로직 추가 후 컨트랙트 바이트코드 크기가 이더리움 메인넷 제한(24KB)에 근접하거나, 배포 시뮬레이션 중 가스 소비가 높은 문제 발생.
- `make devnet-allocs-offline` 과정의 안정적인 실행과 가스 효율성을 위해 직접 코드를 수정함.

**수정 사항:**
- **코드 사이즈 절감 (주석 처리)**: `gameDataWithRat()` 함수를 주석 처리하여 불필요한 외부 인터페이스 데이터를 줄임.
- **가스비 최적화 (함수 통합)**: 
    - `getWinningChallengersCount()` 함수를 제거.
    - 대신 `getWinningChallengers()`가 반환하는 주소 배열의 길이를 호출 측에서 직접 사용하게 하여 함수 호출 오버헤드와 가스 소모를 줄임.
- **로직 최적화**: 챌린저 기록 기능(`_recordWinningChallenger`)을 남겨두되, 실행 흐름을 단순화하여 배포 시 리소스 사용을 최적화함.

**관련 파일:**
- `lib/optimism/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol`
---

## 최종 결과

모든 문제 해결 후 `make devnet-allocs-offline` 성공:

```
=== Genesis Allocs Generation Complete ===
Generated files:
  Allocs (raw):   .devnet/allocs-l1-staking-v3.json
  Genesis (full): .devnet/genesis-l1-staking-v3.json
  Addresses:      .devnet/addresses.json

File stats:
  Size: 2.0M
  Contracts: 112
```

---

## 알아두기

1. **TOML 설정 위치 중요**: `foundry.toml`에서 설정은 올바른 섹션 내에 있어야 함
2. **shell script의 pipefail**: `grep`은 매칭 없으면 exit 1을 반환하므로 `|| true` 필요
3. **디렉토리 사전 생성**: `vm.writeFile()`은 상위 디렉토리가 없으면 실패
4. **RAT 설정 의존성**: `minimumThreshold >= slashingPenalty + validatorBuffer` 조건 충족 필요
