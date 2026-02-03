# TON Staking V3 로컬 환경 - 검증 체크리스트

이 문서는 AI 봇 또는 개발자가 로컬 환경 구축 후 전체 시스템을 체계적으로 검증할 수 있는 체크리스트입니다.

---

## 🎯 검증 목적

- ✅ 로컬 환경이 올바르게 구축되었는지 확인
- ✅ 모든 컨트랙트가 정상 배포되었는지 확인
- ✅ Web UI의 모든 데이터가 정확한지 확인
- ✅ 각 기능이 실제로 작동하는지 확인

---

## 📋 사전 준비 체크리스트

### [ ] 1. 필수 도구 설치 확인

```bash
# Foundry 설치 확인
forge --version
# 출력 예상: forge 0.2.0 (...)

# Docker 실행 확인
docker --version
# 출력 예상: Docker version 20.0.0+

# jq 설치 확인
jq --version
# 출력 예상: jq-1.6
```

**검증 방법**: 위 명령어 실행 시 모두 버전 정보가 표시되어야 함

**실패 시**: [QUICKSTART.md의 1단계](./QUICKSTART.md#1단계-사전-준비) 참조

---

## 🏗️ 로컬 환경 구축 체크리스트

### [ ] 2. Genesis 파일 생성 확인

```bash
make devnet-allocs-offline
```

**검증 항목**:
- [ ] `.devnet/genesis-l1-staking-v3.json` 파일 생성됨
- [ ] `.devnet/addresses.json` 파일 생성됨
- [ ] 파일 크기가 2MB 이상 (정상: 2.0M)
- [ ] 109개의 컨트랙트가 포함됨

**검증 명령어**:
```bash
# 파일 존재 확인
ls -lh .devnet/genesis-l1-staking-v3.json
ls -lh .devnet/addresses.json

# 컨트랙트 개수 확인
jq '.alloc | length' .devnet/allocs-l1-staking-v3.json
# 출력 예상: 111

# RAT 주소 확인
jq -r '.ratProxy' .devnet/addresses.json
# 출력 예상: 0xE5BD5bDC03371fB239956dbbF40bD185D6c2ea28
```

**실패 시**: Genesis 파일 재생성
```bash
rm -rf .devnet
make devnet-allocs-offline
```

---

### [ ] 3. 로컬 네트워크 시작 확인

```bash
make devnet-start
```

**검증 항목**:
- [ ] L1 컨테이너 시작됨 (`ton-staking-l1`)
- [ ] L2 execution 시작됨 (`ton-staking-l2-execution`)
- [ ] L2 node 시작됨 (`ton-staking-l2-node`)
- [ ] Batcher 시작됨 (`ton-staking-l2-batcher`)
- [ ] Proposer 시작됨 (`ton-staking-l2-proposer`)
- [ ] 모든 컨테이너가 `healthy` 상태

**검증 명령어**:
```bash
# 컨테이너 상태 확인
docker ps --filter "name=ton-staking" --format "table {{.Names}}\t{{.Status}}"

# 예상 출력:
# NAMES                      STATUS
# ton-staking-l1             Up X minutes (healthy)
# ton-staking-l2-execution   Up X minutes (healthy)
# ton-staking-l2-node        Up X minutes (healthy)
# ton-staking-l2-batcher     Up X minutes
# ton-staking-l2-proposer    Up X minutes
```

**실패 시**: 컨테이너 재시작
```bash
make devnet-stop
make devnet-start
```

---

### [ ] 4. 네트워크 연결 확인

```bash
make devnet-info
```

**검증 항목**:
- [ ] L1 RPC 접근 가능 (`http://localhost:8545`)
- [ ] L2 RPC 접근 가능 (`http://localhost:9545`)
- [ ] L1 Chain ID: 900
- [ ] L2 Chain ID: 901
- [ ] L1 블록 생성 중 (Block > 0)
- [ ] L2 블록 생성 중 (Block > 0)

**검증 명령어**:
```bash
# L1 연결 및 Chain ID 확인
cast chain-id --rpc-url http://localhost:8545
# 출력 예상: 900

# L2 연결 및 Chain ID 확인
cast chain-id --rpc-url http://localhost:9545
# 출력 예상: 901

# L1 블록 번호 확인
cast block-number --rpc-url http://localhost:8545
# 출력 예상: > 0 (예: 150)

# L2 블록 번호 확인
cast block-number --rpc-url http://localhost:9545
# 출력 예상: > 0 (예: 50000)
```

**실패 시**: 
- L1 실패: Docker 로그 확인 `docker-compose logs l1`
- L2 실패: L2 로그 확인 `docker-compose logs l2-execution`

---

## 📜 컨트랙트 배포 검증 체크리스트

### [ ] 5. 핵심 토큰 컨트랙트 확인

```bash
TON=$(jq -r '.ton' .devnet/addresses.json)
WTON=$(jq -r '.wton' .devnet/addresses.json)
```

**검증 항목**:
- [ ] TON 컨트랙트 배포됨
- [ ] TON name: "TON"
- [ ] TON symbol: "TON"
- [ ] WTON 컨트랙트 배포됨
- [ ] WTON name: "Wrapped TON"

**검증 명령어**:
```bash
# TON 확인
cast call $TON "name()(string)" --rpc-url http://localhost:8545
# 출력 예상: "TON"

cast call $TON "symbol()(string)" --rpc-url http://localhost:8545
# 출력 예상: "TON"

# WTON 확인
cast call $WTON "name()(string)" --rpc-url http://localhost:8545
# 출력 예상: "Wrapped TON"
```

---

### [ ] 6. V3 Manager 컨트랙트 확인

```bash
SEIG=$(jq -r '.seigManagerProxy' .devnet/addresses.json)
DEPOSIT=$(jq -r '.depositManagerProxy' .devnet/addresses.json)
LAYER2=$(jq -r '.layer2ManagerProxy' .devnet/addresses.json)
```

**검증 항목**:
- [ ] SeigManagerV3_1 배포됨
- [ ] V3 Migration 완료 (`v3Migrated == true`)
- [ ] DepositManagerV3 배포됨
- [ ] Layer2ManagerV3 배포됨

**검증 명령어**:
```bash
# V3 Migration 확인
cast call $SEIG "v3Migrated()(bool)" --rpc-url http://localhost:8545
# 출력 예상: true

# SeigManager의 TON 주소 확인
cast call $SEIG "ton()(address)" --rpc-url http://localhost:8545
# 출력 예상: $TON 주소와 동일

# DepositManager의 TON 주소 확인
cast call $DEPOSIT "ton()(address)" --rpc-url http://localhost:8545
# 출력 예상: $TON 주소와 동일
```

---

### [ ] 7. RAT 컨트랙트 확인

```bash
RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
```

**검증 항목**:
- [ ] RAT 컨트랙트 배포됨
- [ ] Validator count 조회 가능
- [ ] Minimum collateral 조회 가능

**검증 명령어**:
```bash
# RAT 배포 확인
cast code $RAT --rpc-url http://localhost:8545 | head -c 20
# 출력 예상: 0x... (코드가 존재)

# Validator 수 확인
cast call $RAT "getValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# 출력 예상: 0 이상의 숫자

# 최소 담보금 확인
cast call $RAT "getDynamicMinimumCollateral(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# 출력 예상: 큰 숫자 (예: 60000000000000000000000000000)
```

---

### [ ] 8. Optimism 컨트랙트 확인

```bash
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
DISPUTE_FACTORY=$(jq -r '.disputeGameFactory' .devnet/addresses.json)
```

**검증 항목**:
- [ ] SystemConfig 배포됨
- [ ] Batcher Hash 설정됨
- [ ] Unsafe Block Signer 설정됨
- [ ] DisputeGameFactory 배포됨
- [ ] L1 Standard Bridge 설정됨
- [ ] Optimism Portal 설정됨

**검증 명령어**:
```bash
# Batcher Hash 확인
cast call $SYSTEM_CONFIG "batcherHash()(bytes32)" --rpc-url http://localhost:8545
# 출력 예상: 0x00000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266

# Unsafe Block Signer 확인
cast call $SYSTEM_CONFIG "unsafeBlockSigner()(address)" --rpc-url http://localhost:8545
# 출력 예상: 0x... (주소)

# L1 Bridge 확인
L1_BRIDGE=$(cast call $SYSTEM_CONFIG "l1StandardBridge()(address)" --rpc-url http://localhost:8545)
echo "L1 Bridge: $L1_BRIDGE"
# 출력 예상: 0x... (주소)

# Portal 확인
PORTAL=$(cast call $SYSTEM_CONFIG "optimismPortal()(address)" --rpc-url http://localhost:8545)
echo "Optimism Portal: $PORTAL"
# 출력 예상: 0x... (주소)

# Portal 상태 확인
cast call $PORTAL "paused()(bool)" --rpc-url http://localhost:8545
# 출력 예상: false (활성화됨)
```

---

## 💰 계정 잔액 검증 체크리스트

### [ ] 9. 테스트 계정 잔액 확인

```bash
DEPLOYER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
VALIDATOR1="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
```

**검증 항목**:
- [ ] Deployer ETH 잔액: 10,000 ETH
- [ ] Deployer TON 잔액: 100,000 TON
- [ ] Validator1 ETH 잔액: 10,000 ETH

**검증 명령어**:
```bash
# Deployer ETH 확인
ETH_BAL=$(cast balance $DEPLOYER --rpc-url http://localhost:8545)
ETH_FORMATTED=$(cast from-wei $ETH_BAL)
echo "Deployer ETH: $ETH_FORMATTED ETH"
# 출력 예상: 10000.0 ETH

# Deployer TON 확인
TON_BAL=$(cast call $TON "balanceOf(address)(uint256)" $DEPLOYER --rpc-url http://localhost:8545)
TON_FORMATTED=$(cast from-wei $TON_BAL)
echo "Deployer TON: $TON_FORMATTED TON"
# 출력 예상: 100000.0 TON

# Validator1 ETH 확인
VAL_ETH=$(cast balance $VALIDATOR1 --rpc-url http://localhost:8545)
VAL_ETH_FORMATTED=$(cast from-wei $VAL_ETH)
echo "Validator1 ETH: $VAL_ETH_FORMATTED ETH"
# 출력 예상: 10000.0 ETH
```

---

## 🌐 Web UI 검증 체크리스트

### [ ] 10. Web UI 설치 및 실행

```bash
cd web-ui
npm install
npm run dev
```

**검증 항목**:
- [ ] `npm install` 성공 (에러 없음)
- [ ] `npm run dev` 성공
- [ ] 개발 서버가 포트 5173에서 실행됨
- [ ] 브라우저에서 `http://localhost:5173` 접근 가능

**검증 방법**:
```bash
# 개발 서버 실행 후 새 터미널에서
curl -I http://localhost:5173
# 출력 예상: HTTP/1.1 200 OK
```

---

### [ ] 11. Web UI 빌드 확인

```bash
npm run build
```

**검증 항목**:
- [ ] TypeScript 컴파일 성공 (에러 없음)
- [ ] Vite 빌드 성공
- [ ] `dist/` 폴더 생성됨
- [ ] `dist/index.html` 존재
- [ ] `dist/assets/` 폴더에 번들 파일 생성됨

**검증 명령어**:
```bash
# 빌드 후 파일 확인
ls -lh dist/
ls -lh dist/assets/

# index.html 존재 확인
test -f dist/index.html && echo "✓ index.html exists" || echo "✗ index.html missing"
```

---

### [ ] 12. Web UI 데이터 정확성 검증

**자동 검증 스크립트 실행**:
```bash
cd /Users/zena/gitwork/ton-staking-v2
./scripts/verify-webui-data.sh
```

**또는 수동 검증**:

#### config.ts 주소 일치 확인
```bash
# TON 주소 비교
DEVNET_TON=$(jq -r '.ton' .devnet/addresses.json)
CONFIG_TON=$(grep "ton:" web-ui/src/config.ts | grep -o '0x[a-fA-F0-9]\{40\}' | head -1)

if [ "$DEVNET_TON" == "$CONFIG_TON" ]; then
  echo "✓ TON address matches"
else
  echo "✗ TON address mismatch!"
  echo "  devnet: $DEVNET_TON"
  echo "  config: $CONFIG_TON"
fi
```

#### RPC URL 확인
```bash
# config.ts의 RPC URL 확인
grep "rpcUrl:" web-ui/src/config.ts
# 출력 예상: rpcUrl: 'http://localhost:8545',

grep "l2RpcUrl:" web-ui/src/config.ts
# 출력 예상: l2RpcUrl: 'http://localhost:9545',
```

---

### [ ] 13. Web UI 기능 동작 검증 (브라우저)

브라우저에서 `http://localhost:5173` 접속 후:

#### Overview 탭
- [ ] L1 Status: 🟢 Online
- [ ] L1 Block: 숫자 표시 (증가하는지 확인)
- [ ] L2 Status: 🟢 Online
- [ ] L2 Block: 숫자 표시
- [ ] Rollup Type: "Optimism Bedrock DisputeGame"
- [ ] V3 Migrated: ✅ Yes
- [ ] 모든 컨트랙트 주소가 표시됨

#### Operator 탭
- [ ] Operator Address 표시됨
- [ ] OperatorManager 주소 표시됨
- [ ] Sequencer Collateral 금액 표시
- [ ] "Add Collateral" 입력 필드 및 버튼 존재

#### Validators 탭
- [ ] Validator 목록 표시 (또는 "No validators registered yet")
- [ ] 테이블 헤더: Address, Deposit, Available, RAT Status, Active

#### L2 Information 탭
- [ ] L2 Chain ID: 901
- [ ] L2 Block Number 표시
- [ ] Batcher Hash 표시
- [ ] Unsafe Block Signer 표시
- [ ] Portal 상태 표시
- [ ] Portal TON Balance 표시

#### Bridge to L2 탭
- [ ] "Bridge ETH to L2" 섹션 존재
- [ ] "Bridge TON to L2" 섹션 존재
- [ ] L1/L2 TON 주소 표시
- [ ] 입력 필드 및 버튼 존재

#### Dispute Games 탭
- [ ] 게임 목록 표시 (또는 "No dispute games created yet")
- [ ] 테이블 헤더: #, Type, Proxy Address, Created At

---

### [ ] 14. Web UI 지갑 연결 테스트 (선택)

MetaMask가 설치된 경우:

- [ ] "Connect Wallet" 버튼 클릭
- [ ] MetaMask 팝업 표시됨
- [ ] 네트워크 추가 승인 (Chain ID 900)
- [ ] 계정 연결 승인
- [ ] 연결된 주소가 헤더에 표시됨
- [ ] 지갑 잔액 표시됨 (ETH, TON, WTON)

---

## 🔄 자동화된 전체 검증

위의 모든 체크리스트를 자동으로 실행하는 통합 스크립트:

```bash
./scripts/verify-all.sh
```

이 스크립트는:
1. ✅ 사전 준비 확인
2. ✅ 로컬 환경 구축 확인
3. ✅ 컨트랙트 배포 확인
4. ✅ 계정 잔액 확인
5. ✅ Web UI 빌드 확인
6. ✅ Web UI 데이터 정확성 확인

모든 검증을 순서대로 실행하고 결과를 요약합니다.

---

## 📊 검증 결과 요약 템플릿

검증 완료 후 다음 형식으로 결과를 기록하세요:

```
## 검증 완료 리포트

**날짜**: 2026-02-03
**검증자**: AI Bot / 개발자명
**환경**: macOS / Linux / Windows

### 사전 준비
- [✓] Foundry 설치
- [✓] Docker 실행 중
- [✓] jq 설치

### 로컬 환경
- [✓] Genesis 생성
- [✓] 네트워크 시작
- [✓] L1/L2 연결 확인

### 컨트랙트
- [✓] TON/WTON 배포
- [✓] V3 Managers 배포
- [✓] RAT 배포
- [✓] Optimism 컨트랙트 배포

### 계정
- [✓] Deployer 잔액 확인
- [✓] Validator 잔액 확인

### Web UI
- [✓] 설치 및 실행
- [✓] 빌드 성공
- [✓] 데이터 정확성
- [✓] 기능 동작

### 총 검증 항목: 45
### 성공: 45
### 실패: 0

**결론**: ✅ 모든 검증 통과 - 시스템 정상 작동
```

---

## 🚨 검증 실패 시 조치

### 일반적인 해결 방법

1. **컨테이너 재시작**
   ```bash
   make devnet-stop
   make devnet-start
   ```

2. **완전 초기화 후 재구축**
   ```bash
   docker-compose down -v
   rm -rf .devnet
   make devnet-allocs-offline
   make devnet-start
   ```

3. **Web UI 재빌드**
   ```bash
   cd web-ui
   rm -rf node_modules dist
   npm install
   npm run build
   ```

### 특정 문제 해결

- **Genesis 생성 실패**: [QUICKSTART.md - 문제 해결](./QUICKSTART.md#문제-해결) 참조
- **컨테이너 시작 실패**: Docker 로그 확인 `docker-compose logs`
- **Web UI 빌드 실패**: [web-ui/troubleshooting.md](./web-ui/troubleshooting.md) 참조

---

## 📞 추가 지원

검증 중 문제가 발생하면:
- **문서**: [QUICKSTART.md](./QUICKSTART.md), [STATUS.md](./STATUS.md)
- **GitHub Issues**: https://github.com/tokamak-network/ton-staking-v2/issues
