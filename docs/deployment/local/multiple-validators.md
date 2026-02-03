# 여러 Validator 동시 실행 가이드

로컬 개발 환경에서 여러 Validator(RAT Client)를 동시에 실행하여 테스트하는 방법을 설명합니다.

## 목차

1. [개요](#개요)
2. [빠른 시작](#빠른-시작)
3. [개별 제어](#개별-제어)
4. [Validator 등록](#validator-등록)
5. [모니터링](#모니터링)
6. [문제 해결](#문제-해결)

## 개요

TON Staking V3 로컬 환경은 기본적으로 3개의 RAT Client를 실행할 수 있습니다:

| RAT Client | Validator 계정 | Private Key | 주소 |
|-----------|---------------|-------------|------|
| RAT Client #1 | Account #2 | 0x5de41...ab365a | 0x90F79...a4e5 |
| RAT Client #2 | Account #3 | 0x7c852...b007a6 | 0x15d34...6A65 |
| RAT Client #3 | Account #4 | 0x47e17...a34926a | 0x99655...A4dc |

각 RAT Client는:
- 독립적인 Docker 컨테이너로 실행
- 서로 다른 Validator 계정 사용
- 동일한 L1/L2 RPC에 연결
- 동시에 RAT Challenge에 응답

## 빠른 시작

### 1. Devnet 시작

먼저 L1 + L2 환경을 시작합니다:

```bash
make devnet-start
```

### 2. 모든 Validator 등록

3개의 Validator를 모두 등록합니다:

```bash
# 환경 변수 설정
export RPC_URL="http://localhost:8545"
export RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
export SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

# Validator #1 등록 (Account #2)
cast send $RAT \
  "registerValidator(address,uint256)" \
  $SYSTEM_CONFIG \
  1000000000000000000 \
  --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a \
  --rpc-url $RPC_URL \
  --value 1000000000000000000

# Validator #2 등록 (Account #3)
cast send $RAT \
  "registerValidator(address,uint256)" \
  $SYSTEM_CONFIG \
  1000000000000000000 \
  --private-key 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6 \
  --rpc-url $RPC_URL \
  --value 1000000000000000000

# Validator #3 등록 (Account #4)
cast send $RAT \
  "registerValidator(address,uint256)" \
  $SYSTEM_CONFIG \
  1000000000000000000 \
  --private-key 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a \
  --rpc-url $RPC_URL \
  --value 1000000000000000000
```

### 3. 모든 RAT Client 시작

```bash
make rat-clients-start
```

또는:

```bash
./scripts/manage-rat-clients.sh start all
```

### 4. 상태 확인

```bash
make rat-clients-status
```

출력 예시:
```
=== RAT Client Status ===

NAME                          STATUS
ton-staking-rat-client-1      Up 2 minutes
ton-staking-rat-client-2      Up 2 minutes
ton-staking-rat-client-3      Up 2 minutes

Validator Accounts:
  RAT Client #1: 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (Account #2)
  RAT Client #2: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 (Account #3)
  RAT Client #3: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc (Account #4)
```

## 개별 제어

### 특정 RAT Client만 시작

```bash
# RAT Client #1만 시작
make rat-client-start-1

# RAT Client #2만 시작
make rat-client-start-2

# RAT Client #3만 시작
make rat-client-start-3
```

또는:

```bash
./scripts/manage-rat-clients.sh start 1
./scripts/manage-rat-clients.sh start 2
./scripts/manage-rat-clients.sh start 3
```

### 특정 RAT Client만 중지

```bash
# RAT Client #1만 중지
make rat-client-stop-1

# RAT Client #2만 중지
make rat-client-stop-2

# 모두 중지
make rat-clients-stop
```

### 특정 RAT Client 재시작

```bash
./scripts/manage-rat-clients.sh restart 1
./scripts/manage-rat-clients.sh restart 2
./scripts/manage-rat-clients.sh restart all
```

## Validator 등록

### 등록 스크립트

편의를 위해 모든 Validator를 한 번에 등록하는 스크립트를 만들 수 있습니다:

```bash
#!/bin/bash
# scripts/register-all-validators.sh

export RPC_URL="http://localhost:8545"
export RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
export SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

VALIDATORS=(
  "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"  # Account #2
  "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"  # Account #3
  "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"  # Account #4
)

for i in "${!VALIDATORS[@]}"; do
  echo "Registering Validator #$((i+1))..."
  cast send $RAT \
    "registerValidator(address,uint256)" \
    $SYSTEM_CONFIG \
    1000000000000000000 \
    --private-key ${VALIDATORS[$i]} \
    --rpc-url $RPC_URL \
    --value 1000000000000000000
  
  if [ $? -eq 0 ]; then
    echo "✓ Validator #$((i+1)) registered"
  else
    echo "✗ Failed to register Validator #$((i+1))"
  fi
  echo ""
done

echo "All validators registered!"
```

실행:

```bash
chmod +x scripts/register-all-validators.sh
./scripts/register-all-validators.sh
```

### 등록 확인

```bash
export RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
export SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

# Validator #1
cast call $RAT \
  "isRegisteredValidator(address,address)(bool)" \
  $SYSTEM_CONFIG \
  0x90F79bf6EB2c4f870365E785982E1f101E93b906 \
  --rpc-url http://localhost:8545

# Validator #2
cast call $RAT \
  "isRegisteredValidator(address,address)(bool)" \
  $SYSTEM_CONFIG \
  0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 \
  --rpc-url http://localhost:8545

# Validator #3
cast call $RAT \
  "isRegisteredValidator(address,address)(bool)" \
  $SYSTEM_CONFIG \
  0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc \
  --rpc-url http://localhost:8545
```

## 모니터링

### 로그 확인

```bash
# RAT Client #1 로그
make rat-client-logs-1

# RAT Client #2 로그
make rat-client-logs-2

# RAT Client #3 로그
make rat-client-logs-3
```

또는 Docker Compose 직접 사용:

```bash
# 모든 RAT Client 로그
docker-compose logs -f rat-client-1 rat-client-2 rat-client-3

# 특정 RAT Client 로그
docker-compose logs -f rat-client-1
```

### Challenge 응답 모니터링

모든 Validator의 Challenge 응답을 확인:

```bash
# Challenge 생성 이벤트
cast logs \
  --from-block latest \
  --address $(jq -r '.ratProxy' .devnet/addresses.json) \
  "ChallengeCreated(uint256 indexed challengeId, address indexed systemConfig, uint256 targetBlock)" \
  --rpc-url http://localhost:8545

# Response 제출 이벤트
cast logs \
  --from-block latest \
  --address $(jq -r '.ratProxy' .devnet/addresses.json) \
  "ResponseSubmitted(uint256 indexed challengeId, address indexed validator, bool success)" \
  --rpc-url http://localhost:8545
```

### Validator 통계

각 Validator의 통계 확인:

```bash
#!/bin/bash
# Check all validator stats

RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

VALIDATORS=(
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906"  # Validator #1
  "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"  # Validator #2
  "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"  # Validator #3
)

for i in "${!VALIDATORS[@]}"; do
  echo "Validator #$((i+1)): ${VALIDATORS[$i]}"
  cast call $RAT \
    "getValidatorInfo(address,address)" \
    $SYSTEM_CONFIG \
    ${VALIDATORS[$i]} \
    --rpc-url http://localhost:8545
  echo ""
done
```

## 테스트 시나리오

### 시나리오 1: 모든 Validator가 응답

1. 모든 RAT Client 시작
2. Challenge 생성 트리거
3. 모든 Validator가 응답하는지 확인

```bash
# 모든 RAT Client 시작
make rat-clients-start

# 로그 모니터링
docker-compose logs -f rat-client-1 rat-client-2 rat-client-3
```

### 시나리오 2: 일부 Validator만 응답

1. RAT Client #1, #2만 시작
2. RAT Client #3는 중지 상태
3. Challenge 발생 시 #1, #2만 응답

```bash
# #1, #2만 시작
make rat-client-start-1
make rat-client-start-2

# #3는 중지 상태 유지
make rat-client-stop-3
```

### 시나리오 3: Validator 추가/제거

동적으로 Validator 추가/제거:

```bash
# 처음에 #1만 실행
make rat-client-start-1

# 나중에 #2 추가
make rat-client-start-2

# #1 제거
make rat-client-stop-1

# #3 추가
make rat-client-start-3
```

## 문제 해결

### RAT Client가 시작되지 않음

**증상**: `docker-compose up` 실패

**확인사항**:
1. Devnet이 실행 중인지 확인
   ```bash
   make devnet-info
   ```
2. Dockerfile 빌드 확인
   ```bash
   cd clients/rat-client-type3
   docker build -t rat-client-local .
   ```

### Validator가 응답하지 않음

**증상**: Challenge가 생성되었지만 응답 없음

**확인사항**:
1. Validator가 등록되었는지 확인
   ```bash
   cast call $RAT "isRegisteredValidator(address,address)(bool)" ...
   ```
2. RAT Client 로그 확인
   ```bash
   make rat-client-logs-1
   ```
3. L1/L2 RPC 연결 확인
   ```bash
   cast block-number --rpc-url http://localhost:8545
   cast block-number --rpc-url http://localhost:9545
   ```

### 메모리 부족

**증상**: Docker 컨테이너가 자주 재시작됨

**해결방법**:
1. Docker Desktop 메모리 증가 (Settings > Resources > Memory)
2. 필요한 RAT Client만 실행
   ```bash
   # 1개만 실행
   make rat-client-start-1
   ```

### 로그가 너무 많음

**해결방법**:
1. 로그 레벨 변경 (docker-compose.yml)
   ```yaml
   environment:
     - LOG_LEVEL=warn  # info에서 warn으로 변경
   ```
2. 특정 RAT Client만 모니터링
   ```bash
   docker-compose logs -f rat-client-1
   ```

## 성능 최적화

### 리소스 사용량

각 RAT Client당:
- **CPU**: 낮음 (~5%)
- **Memory**: ~50MB
- **Network**: 낮음

3개 모두 실행 시:
- **Total Memory**: ~150MB
- **Total CPU**: ~15%

### Poll Interval 조정

빠른 테스트를 위해 poll interval 감소:

```yaml
# docker-compose.yml
environment:
  - POLL_INTERVAL=5  # 5초로 변경 (기본 10초)
```

프로덕션 환경:
```yaml
environment:
  - POLL_INTERVAL=30  # 30초로 증가
```

## 다음 단계

- [RAT Client 상세 가이드](./rat-client.md)
- [모니터링 가이드](./monitoring.md)
- [웹 UI 가이드](./web-ui.md)

## 참고 자료

- [Docker Compose 문서](https://docs.docker.com/compose/)
- [RAT 스펙](../../specs-kr/04-rat-specification.md)
- [Validator 가이드](../../specs-kr/actors/03-validator.md)
