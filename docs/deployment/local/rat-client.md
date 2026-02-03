# RAT Client 가이드

RAT (Randomized Attention Test) Client를 사용하여 Validator를 실행하는 방법을 설명합니다.

## 목차

1. [RAT란?](#rat란)
2. [시작하기](#시작하기)
3. [Validator 등록](#validator-등록)
4. [RAT Client 실행](#rat-client-실행)
5. [모니터링](#모니터링)
6. [문제 해결](#문제-해결)

## RAT란?

RAT (Randomized Attention Test)는 TON Staking V3에서 Validator가 실제로 네트워크를 모니터링하고 있는지 검증하는 메커니즘입니다.

### 주요 개념

- **Validator**: L2 네트워크를 모니터링하고 RAT에 응답하는 참여자
- **Challenge**: RAT 컨트랙트가 Validator에게 제시하는 테스트
- **Response**: Validator가 Challenge에 대한 증거를 제출
- **Reward**: 성공적으로 응답한 Validator에게 지급되는 보상
- **Slashing**: 응답 실패 시 스테이킹된 금액 일부 차감

## 시작하기

### 요구사항

- **Go** 1.22 이상
- **Anvil** 실행 중인 로컬 노드
- **Private Key** (Validator 계정)
- **ETH 및 TON** 잔액 (가스비 및 스테이킹용)

### 설치 확인

```bash
go version  # Go 1.22+
cast block-number --rpc-url http://localhost:8545  # Anvil 실행 확인
```

## Validator 등록

RAT Client를 실행하기 전에 먼저 Validator로 등록해야 합니다.

### 1. 환경 변수 설정

```bash
export RPC_URL="http://localhost:8545"
export RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
export SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

# Validator 계정 (Account #2)
export VALIDATOR_PRIVATE_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
export VALIDATOR_ADDRESS="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
```

### 2. Validator 등록

```bash
# 1 ETH를 스테이킹하여 Validator 등록
cast send $RAT \
  "registerValidator(address,uint256)" \
  $SYSTEM_CONFIG \
  1000000000000000000 \
  --private-key $VALIDATOR_PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --value 1000000000000000000
```

### 3. 등록 확인

```bash
# Validator 등록 상태 확인
cast call $RAT \
  "isRegisteredValidator(address,address)(bool)" \
  $SYSTEM_CONFIG \
  $VALIDATOR_ADDRESS \
  --rpc-url $RPC_URL

# Validator 정보 조회
cast call $RAT \
  "getValidatorInfo(address,address)" \
  $SYSTEM_CONFIG \
  $VALIDATOR_ADDRESS \
  --rpc-url $RPC_URL
```

## RAT Client 실행

### 1. 설정 파일 생성

```bash
cd clients/rat-client-type3
cp config.example.yaml config.yaml
```

`config.yaml` 편집:

```yaml
# L1 RPC URL
l1_rpc_url: "http://localhost:8545"

# L2 RPC URL (로컬 테스트에서는 L1과 동일)
l2_rpc_url: "http://localhost:8545"

# Validator Private Key
private_key: "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

# RAT Contract Address
rat_contract: "0xE5BD5bDC03371fB239956dbbF40bD185D6c2ea28"

# SystemConfig Address (L2 identifier)
system_config: "0x577AcB7fA48878245a854ba51eD051a5B47cF83f"

# Batch Inbox Address
batch_inbox: "0xff00000000000000000000000000000000000000"

# Batcher Address
batcher_address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# DisputeGameFactory Address
dispute_game_factory: "0x52d01b38b78b559142B04CC19F5cC50D5C03dbAc"

# L1BridgeRegistry Address
l1_bridge_registry: "0x2dE080e97B0caE9825375D31f5D0eD5751fDf16D"

# Polling interval (seconds)
poll_interval: 10

# Log level (debug, info, warn, error)
log_level: "info"
```

### 2. RAT Client 빌드

```bash
make rat-client-build
```

### 3. RAT Client 실행

```bash
# 방법 A: Make 명령 사용
make rat-client-run

# 방법 B: 직접 실행
cd clients/rat-client-type3
./bin/rat-client-type3 \
  --config config.yaml
```

### 실행 확인

RAT Client가 정상 실행되면 다음과 같은 로그가 출력됩니다:

```
INFO[0000] Starting RAT Client Type 3
INFO[0000] L1 RPC: http://localhost:8545
INFO[0000] L2 RPC: http://localhost:8545
INFO[0000] Validator: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
INFO[0000] Monitoring SystemConfig: 0x577AcB7fA48878245a854ba51eD051a5B47cF83f
INFO[0010] Checking for RAT challenges...
INFO[0010] No active challenges found
```

## 모니터링

### RAT Client 로그

RAT Client는 다음과 같은 이벤트를 로그로 출력합니다:

- **Challenge 감지**: 새로운 RAT Challenge 발견
- **증거 수집**: L2 상태 증거 수집 시작
- **Response 제출**: RAT에 응답 제출
- **Reward 수령**: 보상 수령 성공
- **Error**: 오류 발생

### Cast를 사용한 모니터링

```bash
# 활성 Challenge 확인
cast logs \
  --from-block latest \
  --address $RAT \
  "ChallengeCreated(uint256 indexed challengeId, address indexed systemConfig, uint256 targetBlock)" \
  --rpc-url $RPC_URL

# Response 제출 확인
cast logs \
  --from-block latest \
  --address $RAT \
  "ResponseSubmitted(uint256 indexed challengeId, address indexed validator, bool success)" \
  --rpc-url $RPC_URL

# Reward 지급 확인
cast logs \
  --from-block latest \
  --address $RAT \
  "RewardClaimed(address indexed validator, uint256 amount)" \
  --rpc-url $RPC_URL
```

### Validator 통계

```bash
# Validator 정보 조회
cast call $RAT \
  "getValidatorInfo(address,address)" \
  $SYSTEM_CONFIG \
  $VALIDATOR_ADDRESS \
  --rpc-url $RPC_URL

# Validator 보상 확인
VALIDATOR_REWARD=$(jq -r '.validatorRewardProxy' .devnet/addresses.json)
cast call $VALIDATOR_REWARD \
  "pendingReward(address)(uint256)" \
  $VALIDATOR_ADDRESS \
  --rpc-url $RPC_URL
```

## 고급 설정

### 여러 L2 모니터링

여러 L2를 동시에 모니터링하려면 각 L2마다 별도의 RAT Client 인스턴스를 실행해야 합니다:

```bash
# L2 #1
./bin/rat-client-type3 --config config-l2-1.yaml &

# L2 #2
./bin/rat-client-type3 --config config-l2-2.yaml &
```

### 자동 재시작 (Systemd)

프로덕션 환경에서는 systemd를 사용하여 RAT Client를 자동으로 재시작할 수 있습니다:

```ini
# /etc/systemd/system/rat-client.service
[Unit]
Description=TON Staking V3 RAT Client
After=network.target

[Service]
Type=simple
User=validator
WorkingDirectory=/path/to/ton-staking-v2/clients/rat-client-type3
ExecStart=/path/to/ton-staking-v2/clients/rat-client-type3/bin/rat-client-type3 --config config.yaml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

활성화:

```bash
sudo systemctl enable rat-client
sudo systemctl start rat-client
sudo systemctl status rat-client
```

## 문제 해결

### "Failed to connect to L1 RPC" 오류

**원인**: Anvil 노드가 실행되지 않았거나 RPC URL이 잘못됨

**해결**:
```bash
# Anvil 실행 확인
ps aux | grep anvil

# RPC 연결 테스트
cast block-number --rpc-url http://localhost:8545

# Anvil 재시작
./scripts/start-local-devnet.sh
```

### "Validator not registered" 오류

**원인**: Validator가 등록되지 않음

**해결**:
위의 "Validator 등록" 섹션을 참고하여 등록합니다.

### "Insufficient balance" 오류

**원인**: ETH 잔액 부족 (가스비용)

**해결**:
```bash
# ETH 잔액 확인
cast balance $VALIDATOR_ADDRESS --rpc-url $RPC_URL

# 테스트 계정에서 ETH 전송
cast send $VALIDATOR_ADDRESS \
  --value 1ether \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --rpc-url $RPC_URL
```

### "Failed to collect evidence" 오류

**원인**: L2 RPC 연결 실패 또는 타겟 블록 데이터 없음

**해결**:
1. L2 RPC URL 확인
2. 타겟 블록이 존재하는지 확인:
   ```bash
   cast block <BLOCK_NUMBER> --rpc-url http://localhost:8545
   ```

### RAT Client가 응답하지 않음

**증상**: 로그가 출력되지 않거나 멈춤

**해결**:
1. **로그 레벨 증가**:
   ```yaml
   log_level: "debug"
   ```
2. **RAT Client 재시작**:
   ```bash
   # Ctrl+C로 종료 후 재실행
   make rat-client-run
   ```

## 테스트

### RAT Client 단위 테스트

```bash
make rat-client-test
```

### E2E 테스트

전체 E2E 테스트를 실행하여 RAT 시스템을 검증합니다:

```bash
# Genesis 생성 (처음 한 번)
make devnet-allocs-offline

# E2E 테스트 실행
make test-e2e
```

## 성능 최적화

### 권장 설정

로컬 개발 환경:
```yaml
poll_interval: 5  # 5초마다 확인 (빠른 테스트)
log_level: "debug"  # 상세 로그
```

프로덕션 환경:
```yaml
poll_interval: 30  # 30초마다 확인 (서버 부하 감소)
log_level: "info"  # 필수 로그만
```

### 리소스 사용량

- **CPU**: 낮음 (대부분 대기 상태)
- **Memory**: ~50MB
- **Network**: 낮음 (RPC 호출만)

## 다음 단계

- [웹 UI 가이드](./web-ui.md) - 웹 인터페이스 사용
- [모니터링 가이드](./monitoring.md) - 시스템 상태 모니터링

## 참고 자료

- [RAT 상세 스펙](../../specs-kr/04-rat-specification.md)
- [Validator 가이드](../../specs-kr/actors/03-validator.md)
- [Go 문서](https://go.dev/doc/)
