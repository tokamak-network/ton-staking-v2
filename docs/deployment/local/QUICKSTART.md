# TON Staking V3 로컬 환경 빠른 시작

이 가이드를 따라 5분 안에 TON Staking V3 로컬 개발 환경을 구축하고 테스트할 수 있습니다.

## 전체 흐름

```
1. 사전 준비 (도구 설치)
   ↓
2. 저장소 클론 및 빌드
   ↓
3. Genesis 생성 (오프라인 배포 시뮬레이션)
   ↓
4. 로컬 네트워크 시작 (L1 + L2)
   ↓
5. 배포 확인 및 테스트
```

---

## 1단계: 사전 준비

### 필수 도구 설치

**Foundry 설치** (forge, anvil, cast)
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

**Docker Desktop 설치**
- macOS/Windows: [Docker Desktop 다운로드](https://www.docker.com/products/docker-desktop)
- Linux: Docker Engine + Docker Compose 설치

**jq 설치**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Arch Linux
sudo pacman -S jq
```

### 설치 확인

```bash
forge --version    # ✓ forge 0.2.0+
docker --version   # ✓ Docker version 20.0.0+
jq --version       # ✓ jq-1.6+
```

모든 도구가 정상적으로 설치되었는지 확인하세요.

---

## 2단계: 저장소 클론 및 빌드

```bash
# 1. 저장소 클론
git clone https://github.com/tokamak-network/ton-staking-v2.git
cd ton-staking-v2

# 2. 브랜치 체크아웃
git checkout ton-staking-v3/deploy-local

# 3. 서브모듈 설치
git submodule update --init --recursive

# 4. 컨트랙트 빌드
forge build
```

**예상 시간**: 1-2분

**문제 발생 시**:
- 서브모듈 설치 실패: `rm -rf lib && git submodule update --init --recursive`
- 빌드 실패: [문제 해결](#문제-해결) 섹션 참조

---

## 3단계: Genesis 생성

Genesis 파일은 L1 네트워크의 초기 상태를 정의합니다. 모든 TON Staking 컨트랙트와 테스트 계정이 사전 배포된 상태로 생성됩니다.

```bash
make devnet-allocs-offline
```

**생성되는 파일**:
- `.devnet/genesis-l1-staking-v3.json` - Anvil이 로드할 genesis 파일
- `.devnet/addresses.json` - 배포된 컨트랙트 주소 목록
- `.devnet/allocs-l1-staking-v3.json` - 원시 allocation 데이터

**예상 시간**: 30초 - 1분

**배포되는 컨트랙트**:
- TON, WTON 토큰
- SeigManagerV3_1 (시뇨리지 관리)
- DepositManagerV3 (스테이킹 관리)
- Layer2ManagerV3 (L2 관리)
- L1BridgeRegistryV1_2 (브리지 TVL)
- RAT (Validator 테스트)
- ValidatorRewardV1 (보상 풀)
- Optimism L1 컨트랙트 (SystemConfig, OptimismPortal 등)

---

## 4단계: 로컬 네트워크 시작

Docker Compose를 사용하여 L1(Geth)과 L2(Optimism) 환경을 시작합니다.

```bash
make devnet-start
```

**실행되는 서비스**:
- `l1`: Geth with Clique PoA (L1 Ethereum, Chain ID 900, Port 8545)
- `l2-execution`: op-geth (L2 실행 레이어, Debug Mode, Chain ID 901, Port 9545)
- `l2-node`: op-node (롤업 노드, Port 7545)
- `l2-batcher`: 트랜잭션 배치 제출
- `l2-proposer`: 상태 루트 제출

**Note**: L1은 Geth를 사용합니다. Anvil은 블록 해시를 blockTag로 지원하지 않아 op-node와 호환되지 않습니다.

**예상 시간**: 2-3분

**정상 작동 확인**:
```bash
# 새 터미널에서 실행
make devnet-info
```

출력 예시:
```
=== TON Staking V3 Devnet Information ===

Container Status:
NAME                          STATUS
ton-staking-l1                Up (healthy)
ton-staking-l2-execution      Up (healthy)

RPC Endpoints:
  L1 (Geth):           http://localhost:8545
  L2 (op-geth):        http://localhost:9545  (debug API enabled)

Block Numbers:
  L1: 5
  L2: 0
```

**L2 Debug API 확인**:
```bash
# debug_accountRange 사용 가능 확인 (RAT Client용)
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"debug_accountRange","params":["latest",null,10,false,false,false],"id":1}' \
  http://localhost:9545 | jq '.result.accounts | length'
```

---

## 5단계: 배포 확인 및 테스트

### 5-1. 네트워크 연결 확인

```bash
# L1 체인 ID 확인
cast chain-id --rpc-url http://localhost:8545
# 출력: 900

# L2 체인 ID 확인
cast chain-id --rpc-url http://localhost:9545
# 출력: 901
```

### 5-2. 컨트랙트 배포 확인

```bash
# 컨트랙트 주소 확인
cat .devnet/addresses.json | jq '{ton, wton, seigManagerProxy, depositManagerProxy}'
```

출력 예시:
```json
{
  "ton": "0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E",
  "wton": "0x2B2fE3204CcB8282ac6bC31d485cB6aa010d193a",
  "seigManagerProxy": "0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe",
  "depositManagerProxy": "0x90118d110B07ABB82Ba8980D1c5cC96EeA810d2C"
}
```

### 5-3. 계정 잔액 확인

```bash
export RPC_URL="http://localhost:8545"
export TON=$(jq -r '.ton' .devnet/addresses.json)
export DEPLOYER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

# TON 잔액 확인 (curl 사용 - cast보다 안정적)
export DATA=$(cast calldata "balanceOf(address)" $DEPLOYER)
curl -s -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$TON\",\"data\":\"$DATA\"},\"latest\"],\"id\":1}" \
  $RPC_URL | jq -r '.result' | xargs cast --to-dec | xargs cast from-wei

# 출력: 100000.000000000000000000
```

### 5-4. 자동 테스트 실행

```bash
./scripts/test-local-devnet.sh
```

이 스크립트는 다음을 테스트합니다:
- L1/L2 네트워크 연결
- 모든 컨트랙트 배포 확인
- 계정 잔액 확인
- 기본 트랜잭션 (TON approve)

---

## 테스트 시나리오

### 시나리오 1: TON 잔액 조회

```bash
export RPC_URL="http://localhost:8545"
export TON=$(jq -r '.ton' .devnet/addresses.json)
export DEPLOYER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

# calldata 생성
export DATA=$(cast calldata "balanceOf(address)" $DEPLOYER)

# RPC 호출
curl -s -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$TON\",\"data\":\"$DATA\"},\"latest\"],\"id\":1}" \
  $RPC_URL | jq -r '.result' | xargs cast --to-dec

# 출력: 100000000000000000000000 (100,000 TON in wei)
```

### 시나리오 2: WTON 컨트랙트 조회

```bash
export WTON=$(jq -r '.wton' .devnet/addresses.json)

# WTON name 조회
export DATA=$(cast calldata "name()")
curl -s -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$WTON\",\"data\":\"$DATA\"},\"latest\"],\"id\":1}" \
  $RPC_URL | jq -r '.result' | xxd -r -p | strings

# 출력: Wrapped TON
```

### 시나리오 3: 모든 컨트랙트 확인

```bash
# 배포 확인 스크립트
cat > check-deployment.sh << 'EOF'
#!/bin/bash
RPC_URL="http://localhost:8545"

echo "=== TON Staking V3 Deployment Verification ==="
echo ""

# 컨트랙트 목록
CONTRACTS=(
  "ton:TON Token"
  "wton:WTON Token"
  "seigManagerProxy:SeigManager V3"
  "depositManagerProxy:DepositManager V3"
  "layer2ManagerProxy:Layer2Manager V3"
  "ratProxy:RAT Contract"
  "systemConfig:SystemConfig"
)

for contract in "${CONTRACTS[@]}"; do
  IFS=':' read -r key name <<< "$contract"
  addr=$(jq -r ".$key" .devnet/addresses.json)
  
  code=$(curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$addr\",\"latest\"],\"id\":1}" \
    $RPC_URL | jq -r '.result')
  
  if [ "$code" != "0x" ]; then
    echo "✓ $name: $addr"
  else
    echo "✗ $name: NOT DEPLOYED"
  fi
done
EOF

chmod +x check-deployment.sh
./check-deployment.sh
```

---

## 환경 관리

### 로그 확인

```bash
# 모든 서비스 로그
docker-compose logs -f

# L1만
docker-compose logs -f l1

# L2 execution만
docker-compose logs -f l2-execution

# 특정 시점 이후 로그 (마지막 100줄)
docker-compose logs --tail=100 l1
```

### 환경 중지

```bash
# 서비스 중지 (데이터 보존)
make devnet-stop

# 또는
docker-compose stop
```

### 환경 재시작

```bash
# Genesis 유지한 채 재시작
make devnet-start

# 또는 수동으로
docker-compose up -d l1 l2-execution
```

### 완전 초기화

```bash
# 컨테이너와 볼륨 모두 삭제
docker-compose down -v

# Genesis 재생성
rm -rf .devnet
make devnet-allocs-offline

# 재시작
make devnet-start
```

---

## 테스트 계정

Genesis에 사전 할당된 테스트 계정:

### Account #0 - Batcher/Proposer
```
Address:     0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
Balance:     10,000 ETH
Role:        Optimism Batcher 및 Proposer
```

### Account #1 - Deployer/Staker
```
Address:     0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
Balance:     10,000 ETH + 100,000 TON
Role:        TON Staking 배포자 및 테스트 스테이커
```

### Account #2 - Validator
```
Address:     0x90F79bf6EB2c4f870365E785982E1f101E93b906
Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
Balance:     10,000 ETH
Role:        Validator 노드 운영자
```

### Account #3 - Proposer
```
Address:     0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
Private Key: 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
Balance:     10,000 ETH
Role:        L2 Proposer
```

### Account #4 - Challenger
```
Address:     0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
Private Key: 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
Balance:     10,000 ETH
Role:        Fault Proof Challenger
```

---

## 문제 해결

### Docker가 실행되지 않음

**증상**:
```
Cannot connect to the Docker daemon
```

**해결**:
```bash
# macOS/Windows: Docker Desktop 시작
open -a Docker

# Linux: Docker 서비스 시작
sudo systemctl start docker
```

### Genesis 파일 생성 실패

**증상**:
```
Error: Compiler run failed
```

**해결**:
```bash
# 서브모듈 재설치
rm -rf lib/optimism lib/tokamak-dao-contracts
git submodule update --init --recursive

# 빌드 재시도
forge clean
forge build
```

### 포트가 이미 사용 중

**증상**:
```
Error: port 8545 is already allocated
```

**해결**:
```bash
# 포트 사용 중인 프로세스 확인
lsof -i :8545
lsof -i :9545

# 프로세스 종료 또는 기존 devnet 중지
make devnet-stop
docker-compose down -v
```

### cast 명령 오류

**증상**:
```
Error: server returned an error response: unknown field 'input'
```

**해결**:
Anvil과 cast의 버전 호환성 문제입니다. curl을 사용한 직접 RPC 호출을 권장합니다:

```bash
# cast 대신 curl 사용
export DATA=$(cast calldata "balanceOf(address)" $ADDRESS)
curl -s -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$CONTRACT\",\"data\":\"$DATA\"},\"latest\"],\"id\":1}" \
  http://localhost:8545
```

### L2 블록이 생성되지 않음

**증상**:
```bash
cast block-number --rpc-url http://localhost:9545
# 출력: 0 (계속 0)
```

**원인**:
op-node가 SystemConfig의 `unsafeBlockSigner` 설정을 찾지 못해 시작되지 않습니다.

**현재 상태**:
- L1은 정상 작동 (모든 TON Staking 기능 사용 가능)
- L2 execution은 실행 중이지만 블록 생성 안 됨
- op-node 수정 필요 (향후 개선 예정)

### 트랜잭션 Nonce 오류

**증상**:
```
nonce too low / nonce too high
```

**해결**:
```bash
# Anvil 재시작으로 상태 초기화
docker-compose restart l1

# 또는 완전 재시작
docker-compose down -v
make devnet-start
```

---

## 다음 단계

로컬 환경 구축 완료 후:

1. **컨트랙트 이해하기**: [구현 상세](./IMPLEMENTATION.md) 문서 읽기
2. **스테이킹 테스트**: Layer2 등록 및 TON 스테이킹 (가이드 작성 예정)
3. **Validator 실행**: RAT Client 설정 (가이드 작성 예정)
4. **모니터링**: 실시간 상태 모니터링 (가이드 작성 예정)

## 요약

```bash
# 전체 과정 요약
cd ~/projects
git clone https://github.com/tokamak-network/ton-staking-v2.git
cd ton-staking-v2
git checkout ton-staking-v3/deploy-local
git submodule update --init --recursive
forge build

make devnet-allocs-offline  # Genesis 생성
make devnet-start           # 환경 시작
make devnet-info            # 확인

# 테스트
./scripts/test-local-devnet.sh

# 종료
make devnet-stop
```

## 도움말

- 기술 상세: [IMPLEMENTATION.md](./IMPLEMENTATION.md)
- 문제 보고: [GitHub Issues](https://github.com/tokamak-network/ton-staking-v2/issues)
- 메인 문서: [README.md](./README.md)
