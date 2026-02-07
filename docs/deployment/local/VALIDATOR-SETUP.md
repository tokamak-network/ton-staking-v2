# Validator 설정 및 RAT Client 실행 가이드

이 가이드는 TON Staking V3 로컬 환경에서 Validator를 설정하고 RAT Client를 실행하는 방법을 설명합니다.

## 사전 요구사항

- 로컬 devnet 실행 중 ([QUICKSTART.md](./QUICKSTART.md) 참조)
- Go 1.21 이상 설치
- 충분한 TON 잔액 (Validator당 최소 10,000 TON 권장)

## Validator 등록 절차

TON Staking V3에서 Validator가 되기 위한 단계:

```
1. L2 등록 (Layer2Manager)
   ↓
2. TON 스테이킹 (DepositManager)
   ↓
3. Validator 등록 (RAT)
   ↓
4. RAT Client 실행
```

## 1단계: L2 등록

SystemConfig를 Layer2로 등록합니다.

```bash
export RPC_URL="http://localhost:8545"
export LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' .devnet/addresses.json)
export SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
export DEPLOYER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

# L2 등록 상태 확인
cast call $LAYER2_MANAGER \
  "statusLayer2(address)(uint8)" \
  $SYSTEM_CONFIG \
  --rpc-url $RPC_URL

# 0이면 미등록, 1이면 등록됨
# 미등록이면 등록 필요 (registerCandidateAddOn 함수 사용 - 복잡)
```

**⚠️ 현재 이슈**: `registerCandidateAddOn` 함수는 복잡한 파라미터가 필요하여 별도 스크립트가 필요합니다.

**임시 해결책**: Genesis 배포 시 SystemConfig가 자동 등록되도록 DeployAll 스크립트 수정 (향후 개선)

## 2단계: TON 스테이킹

각 Validator가 TON을 스테이킹합니다.

### 최소 담보금 확인

```bash
export RAT=$(jq -r '.ratProxy' .devnet/addresses.json)

# 최소 담보금 조회
cast call $RAT \
  "getDynamicMinimumCollateral(address)(uint256)" \
  $SYSTEM_CONFIG \
  --rpc-url $RPC_URL
```

**현재 값**: 약 60,000,000,000 TON (로컬 테스트용으로 너무 높음)

**임시 해결책**: RAT 파라미터를 조정하거나, 충분한 TON을 스테이킹

### Deployer가 Validator들에게 TON 전송

```bash
export TON=$(jq -r '.ton' .devnet/addresses.json)
export DEPLOYER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

# Validator 계정들
VALIDATORS=(
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906"
  "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
  "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"
)

# 각 Validator에게 20,000 TON 전송
for validator in "${VALIDATORS[@]}"; do
  echo "Transferring 20,000 TON to $validator"
  cast send $TON \
    "transfer(address,uint256)" \
    $validator \
    20000000000000000000000 \
    --private-key $DEPLOYER_KEY \
    --rpc-url $RPC_URL
done
```

### TON Approve 및 스테이킹

```bash
export DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' .devnet/addresses.json)

# Validator 1
VALIDATOR1_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

# Approve
cast send $TON \
  "approve(address,uint256)" \
  $DEPOSIT_MANAGER \
  15000000000000000000000 \
  --private-key $VALIDATOR1_KEY \
  --rpc-url $RPC_URL

# Deposit
cast send $DEPOSIT_MANAGER \
  "deposit(address,uint256)" \
  $SYSTEM_CONFIG \
  15000000000000000000000 \
  --private-key $VALIDATOR1_KEY \
  --rpc-url $RPC_URL
```

## 3단계: Validator 등록

RAT에 Validator로 등록합니다.

```bash
# Validator 1 등록
cast send $RAT \
  "registerValidator(address)" \
  $SYSTEM_CONFIG \
  --private-key $VALIDATOR1_KEY \
  --rpc-url $RPC_URL

# 등록 확인
cast call $RAT \
  "isRegisteredValidator(address,address)(bool)" \
  $SYSTEM_CONFIG \
  0x90F79bf6EB2c4f870365E785982E1f101E93b906 \
  --rpc-url $RPC_URL
```

## 4단계: RAT Client 설정

### Config 파일 생성

```bash
cd clients/rat-client-type3
```

**Validator 1 Config** (`config-validator1.yaml`):

```yaml
l1:
  rpc_url: "http://localhost:8545"
  beacon_url: ""  # 로컬 테스트에서는 불필요

rpc:
  urls:
    - "http://localhost:9545"  # L2 execution
  opnode:
    max_wait_time: 5m
    check_interval: 10s

contracts:
  rat_contract: "0xE5BD5bDC03371fB239956dbbF40bD185D6c2ea28"
  system_config: "0x577AcB7fA48878245a854ba51eD051a5B47cF83f"
  dispute_game_factory: "0x52d01b38b78b559142B04CC19F5cC50D5C03dbAc"
  l1_bridge_registry: "0x2dE080e97B0caE9825375D31f5D0eD5751fDf16D"
  batch_inbox: "0xff00000000000000000000000000000000000901"
  batcher_address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

validator:
  private_key: "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
  address: "0x90F79bf6EB2c4f870365E785982E1f101E93b906"

rat:
  poll_interval: 12s
  deadline_buffer: 10m
  max_gas_price: 100
  max_pending_tx: 5

verification:
  enable_proof_verification: false  # L2가 완전히 동작하지 않으므로 비활성화
  rpc_timeout: 20m

logging:
  level: info
  format: text

metrics:
  enabled: true
  addr: "0.0.0.0"
  port: 7300

verification_mode: l2rpc
```

Validator 2, 3도 동일한 방식으로 설정 파일 생성 (포트와 키만 변경)

## 5단계: RAT Client 실행

### 빌드

```bash
cd clients/rat-client-type3
go build -o bin/rat-client cmd/main.go
```

### 실행

**터미널 1 - Validator 1**:
```bash
cd clients/rat-client-type3
./bin/rat-client --config config-validator1.yaml
```

**터미널 2 - Validator 2**:
```bash
cd clients/rat-client-type3
./bin/rat-client --config config-validator2.yaml
```

**터미널 3 - Validator 3**:
```bash
cd clients/rat-client-type3
./bin/rat-client --config config-validator3.yaml
```

## 예상 로그

```
INFO[0000] Starting RAT Client
INFO[0000] L1 RPC: http://localhost:8545
INFO[0000] Validator: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
INFO[0000] Monitoring SystemConfig: 0x577AcB7fA48878245a854ba51eD051a5B47cF83f
INFO[0012] Checking for RAT challenges...
INFO[0012] No active challenges found
```

## 알려진 제한사항

### 1. L2 등록 복잡성
- `registerCandidateAddOn` 함수는 많은 파라미터가 필요
- 로컬 테스트를 위해 Genesis에서 자동 등록 필요

### 2. 높은 최소 담보금
- 현재 최소 담보금: ~60B TON
- 로컬 테스트용으로 조정 필요

### 3. L2 블록 생성 안 됨
- op-node가 작동하지 않아 L2 블록 생성 안 됨
- RAT Challenge는 L2 상태 변화 시 발생하므로 현재는 Challenge가 생성되지 않음

### 4. RAT Client 검증 모드
- `l2rpc` 모드: L2 geth의 debug API 필요
- `opnode` 모드: op-node 필요 (현재 작동 안 함)
- `verification_mode: stateless` 권장 (L1만 사용, 향후 지원)

## 문제 해결

### "InsufficientCollateralError"
- 담보금 부족
- 더 많은 TON 스테이킹 필요

### "NotMigratedError"
- V3 마이그레이션 미완료
- Genesis에서 자동 마이그레이션되어야 함

### "L2 not registered"
- SystemConfig가 Layer2로 등록되지 않음
- `registerCandidateAddOn` 호출 또는 Genesis 수정 필요

### RAT Client 연결 실패
- L1 RPC URL 확인
- Anvil 실행 상태 확인: `cast block-number --rpc-url http://localhost:8545`

## 개선 필요 사항

1. **DeployAll 스크립트 개선**:
   - SystemConfig를 Layer2로 자동 등록
   - RAT 파라미터를 로컬 테스트용으로 조정 (낮은 담보금)
   - 테스트 Validator들에게 충분한 TON 배분

2. **간소화된 등록 스크립트**:
   - 원클릭으로 Validator 등록하는 스크립트
   - 3개 Validator 자동 설정 스크립트

3. **SystemConfig 초기화**:
   - op-node가 작동하도록 `unsafeBlockSigner` 설정
   - L2 블록 생성 활성화

## 참고 자료

- [RAT 상세 가이드](./rat-client.md)
- [QUICKSTART 가이드](./QUICKSTART.md)
- [구현 상세](./IMPLEMENTATION.md)
