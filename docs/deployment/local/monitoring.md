# 모니터링 및 대시보드

TON Staking V3 로컬 환경의 상태를 실시간으로 모니터링하는 방법을 설명합니다.

## 목차

1. [웹 UI 대시보드](#웹-ui-대시보드)
2. [CLI 도구를 사용한 모니터링](#cli-도구를-사용한-모니터링)
3. [Cast 명령어 치트시트](#cast-명령어-치트시트)
4. [로그 모니터링](#로그-모니터링)
5. [성능 메트릭](#성능-메트릭)

## 웹 UI 대시보드

### 시작하기

```bash
cd web-ui
npm install
npm run dev
```

웹 브라우저에서 `http://localhost:5173` 을 열어 대시보드에 접속합니다.

### 기능

- **실시간 잔액 조회**: TON, WTON, Staked 잔액
- **스테이킹 인터페이스**: 간편한 TON 스테이킹
- **L2 목록**: 등록된 모든 L2 조회
- **컨트랙트 주소**: 모든 배포된 컨트랙트 주소 확인
- **네트워크 정보**: Chain ID, RPC URL 등

### MetaMask 연결

1. MetaMask 설치 (미설치 시)
2. 웹 UI에서 "Connect Wallet" 클릭
3. 네트워크 추가/전환 승인
4. 계정 연결 승인

### 테스트 계정 가져오기

웹 UI의 "Test Accounts" 섹션에서 Private Key를 복사하여 MetaMask에 가져올 수 있습니다.

## CLI 도구를 사용한 모니터링

### Cast를 사용한 실시간 모니터링

```bash
# 주소 변수 설정
export RPC_URL="http://localhost:8545"
export TON=$(jq -r '.ton' .devnet/addresses.json)
export WTON=$(jq -r '.wton' .devnet/addresses.json)
export SEIG_MANAGER=$(jq -r '.seigManagerProxy' .devnet/addresses.json)
export DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' .devnet/addresses.json)
export LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' .devnet/addresses.json)
export RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
```

## Cast 명령어 치트시트

### 기본 정보 조회

```bash
# Chain ID 확인
cast chain-id --rpc-url $RPC_URL

# 최신 블록 번호
cast block-number --rpc-url $RPC_URL

# 계정 잔액 (ETH)
cast balance 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --rpc-url $RPC_URL
```

### TON/WTON 조회

```bash
# TON 총 공급량
cast call $TON "totalSupply()(uint256)" --rpc-url $RPC_URL | \
  xargs -I {} cast --to-unit {} ether

# 계정의 TON 잔액
cast call $TON \
  "balanceOf(address)(uint256)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  --rpc-url $RPC_URL | \
  xargs -I {} cast --to-unit {} ether

# 계정의 WTON 잔액
cast call $WTON \
  "balanceOf(address)(uint256)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  --rpc-url $RPC_URL | \
  xargs -I {} cast --to-unit {} ether
```

### 스테이킹 정보

```bash
# 등록된 L2 개수
cast call $LAYER2_MANAGER "numLayer2s()(uint256)" --rpc-url $RPC_URL

# 첫 번째 L2 주소 조회
cast call $LAYER2_MANAGER "layer2s(uint256)(address)" 0 --rpc-url $RPC_URL

# L2 정보 조회
LAYER2_ADDRESS=$(cast call $LAYER2_MANAGER "layer2s(uint256)(address)" 0 --rpc-url $RPC_URL)
cast call $LAYER2_MANAGER \
  "layer2Info(address)" \
  $LAYER2_ADDRESS \
  --rpc-url $RPC_URL

# 특정 L2에 스테이킹된 금액
cast call $DEPOSIT_MANAGER \
  "stakeOf(address,address)(uint256)" \
  $LAYER2_ADDRESS \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  --rpc-url $RPC_URL | \
  xargs -I {} cast --to-unit {} ether
```

### Validator 정보

```bash
# Validator 등록 확인
cast call $RAT \
  "isRegisteredValidator(address,address)(bool)" \
  $LAYER2_ADDRESS \
  0x90F79bf6EB2c4f870365E785982E1f101E93b906 \
  --rpc-url $RPC_URL

# Validator 정보 조회
cast call $RAT \
  "getValidatorInfo(address,address)" \
  $LAYER2_ADDRESS \
  0x90F79bf6EB2c4f870365E785982E1f101E93b906 \
  --rpc-url $RPC_URL
```

### 이벤트 로그 조회

```bash
# TON Transfer 이벤트
cast logs \
  --from-block 0 \
  --address $TON \
  "Transfer(address indexed from, address indexed to, uint256 value)" \
  --rpc-url $RPC_URL

# Deposit 이벤트
cast logs \
  --from-block 0 \
  --address $DEPOSIT_MANAGER \
  "Deposited(address indexed layer2, address indexed depositor, uint256 amount)" \
  --rpc-url $RPC_URL
```

## 로그 모니터링

### Anvil 로그 실시간 보기

Anvil을 별도 터미널에서 실행하여 로그를 실시간으로 확인할 수 있습니다:

```bash
./scripts/start-local-devnet.sh
```

### 트랜잭션 추적

```bash
# 트랜잭션 상세 정보
cast tx <TX_HASH> --rpc-url $RPC_URL

# 트랜잭션 receipt
cast receipt <TX_HASH> --rpc-url $RPC_URL

# 트랜잭션 디버깅
cast run <TX_HASH> --rpc-url $RPC_URL
```

## 성능 메트릭

### 자동 모니터링 스크립트

다음 스크립트를 사용하여 주요 메트릭을 주기적으로 확인할 수 있습니다:

```bash
#!/bin/bash
# scripts/monitor-stats.sh

RPC_URL="http://localhost:8545"
TON=$(jq -r '.ton' .devnet/addresses.json)
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' .devnet/addresses.json)

while true; do
  clear
  echo "=== TON Staking V3 Monitoring ==="
  echo ""
  
  echo "Block Number:"
  cast block-number --rpc-url $RPC_URL
  echo ""
  
  echo "TON Total Supply:"
  cast call $TON "totalSupply()(uint256)" --rpc-url $RPC_URL | \
    xargs -I {} cast --to-unit {} ether
  echo ""
  
  echo "Registered L2s:"
  cast call $LAYER2_MANAGER "numLayer2s()(uint256)" --rpc-url $RPC_URL
  echo ""
  
  echo "Last updated: $(date)"
  sleep 5
done
```

실행:

```bash
chmod +x scripts/monitor-stats.sh
./scripts/monitor-stats.sh
```

### Grafana + Prometheus (고급)

더 강력한 모니터링을 원한다면 Grafana와 Prometheus를 설정할 수 있습니다:

1. **Anvil 메트릭 익스포터 실행**
```bash
# 미래 구현 예정
```

2. **Prometheus 설정**
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'anvil'
    static_configs:
      - targets: ['localhost:9090']
```

3. **Grafana 대시보드**
- TON/WTON 총 공급량
- 스테이킹 비율
- L2 등록 수
- 트랜잭션 처리량

## 모니터링 체크리스트

### 시작 시 확인

- [ ] Anvil 노드가 실행 중인가?
- [ ] Genesis 파일이 로드되었는가?
- [ ] 모든 컨트랙트가 배포되었는가?
- [ ] RPC 엔드포인트가 응답하는가?

### 정기 확인

- [ ] 블록이 생성되고 있는가?
- [ ] 트랜잭션이 정상 처리되는가?
- [ ] 가스비가 적절한가?
- [ ] 이벤트 로그가 정상 발생하는가?

### 문제 발생 시

1. **Anvil 로그 확인**
2. **트랜잭션 revert 원인 파악**
3. **Cast를 사용한 상태 조회**
4. **필요 시 Anvil 재시작**

## 유용한 별칭 (Alias)

`.bashrc` 또는 `.zshrc`에 추가:

```bash
# TON Staking V3 Aliases
alias ton-rpc='cast --rpc-url http://localhost:8545'
alias ton-balance='cast call $(jq -r ".ton" .devnet/addresses.json) "balanceOf(address)(uint256)"'
alias ton-l2-count='cast call $(jq -r ".layer2ManagerProxy" .devnet/addresses.json) "numLayer2s()(uint256)" --rpc-url http://localhost:8545'
alias ton-block='cast block-number --rpc-url http://localhost:8545'
```

사용:

```bash
ton-block  # 현재 블록 번호
ton-l2-count  # L2 개수
```

## 추가 리소스

- [Cast 문서](https://book.getfoundry.sh/reference/cast/)
- [Anvil 문서](https://book.getfoundry.sh/reference/anvil/)
- [Foundry 치트시트](https://github.com/foundry-rs/foundry/tree/master/crates/cast)
