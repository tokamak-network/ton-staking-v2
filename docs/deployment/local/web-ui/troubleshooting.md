# Web UI - 문제 해결

Web UI 사용 중 발생할 수 있는 일반적인 문제와 해결 방법입니다.

---

## 🚫 설치 및 실행 문제

### npm install 실패

**증상**:
```
npm ERR! code ERESOLVE
npm ERR! ERESOLVE unable to resolve dependency tree
```

**원인**: Node.js 버전 호환성 문제

**해결**:
```bash
# 1. Node.js 버전 확인
node --version

# 2. Node.js 20.19+ 또는 22.12+ 설치 권장
# macOS (nvm 사용)
nvm install 20
nvm use 20

# 3. package-lock.json 삭제 후 재설치
rm package-lock.json
rm -rf node_modules
npm install
```

---

### npm run dev 실패

**증상**:
```
Error: Cannot find module 'vite'
```

**해결**:
```bash
# 의존성 재설치
npm install

# 캐시 정리 후 재설치
npm cache clean --force
npm install
```

---

### 포트 5173이 이미 사용 중

**증상**:
```
Port 5173 is in use, trying another one...
```

**해결**:
```bash
# 1. 5173 포트 사용 중인 프로세스 확인
lsof -i :5173

# 2. 프로세스 종료
kill -9 <PID>

# 3. 또는 다른 포트 사용
npm run dev -- --port 5174
```

---

## 🔌 지갑 연결 문제

### MetaMask 연결 안됨

**증상**: "Connect Wallet" 버튼 클릭 시 아무 반응 없음

**원인**: MetaMask가 설치되지 않았거나 브라우저에서 비활성화됨

**해결**:
1. MetaMask 설치 확인
   - Chrome: [Chrome Web Store](https://chrome.google.com/webstore)
2. MetaMask 활성화 확인
   - 브라우저 확장 프로그램 관리에서 확인
3. 페이지 새로고침 (Ctrl/Cmd + R)

---

### 네트워크 추가 실패

**증상**:
```
Chain ID 900 already exists
```

**해결**:
```bash
# MetaMask에서 기존 네트워크 삭제
1. MetaMask 열기
2. 네트워크 드롭다운 클릭
3. "TON Staking V3 Local" 네트워크 설정
4. "네트워크 삭제" 클릭
5. Web UI에서 다시 "Connect Wallet" 클릭
```

---

### 지갑 연결 후 데이터 안 보임

**증상**: 지갑 연결은 되었지만 잔액이 0으로 표시

**원인**: L1 네트워크에 연결되지 않음

**확인**:
```bash
# 로컬 네트워크 상태 확인
make devnet-info

# L1 RPC 접근 가능 확인
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545
```

**해결**:
```bash
# 로컬 네트워크 재시작
make devnet-stop
make devnet-start
```

---

## 📊 데이터 표시 문제

### "L2 not reachable" 경고

**증상**: L2 Information 탭에서 "L2 not reachable" 메시지

**원인**: L2 네트워크가 실행 중이 아니거나 응답하지 않음

**확인**:
```bash
# L2 블록 번호 확인
cast block-number --rpc-url http://localhost:9545

# L2 컨테이너 상태 확인
docker ps --filter "name=ton-staking-l2"
```

**해결**:
```bash
# L2 컨테이너 재시작
docker-compose restart l2-execution l2-node

# 또는 전체 재시작
make devnet-stop
make devnet-start
```

---

### 잔액이 0으로 표시

**증상**: 연결된 지갑의 TON/WTON 잔액이 0

**원인**: 테스트 계정이 아닌 다른 계정 사용

**해결**:
```bash
# 1. TON이 할당된 테스트 계정 사용
# Account #1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

# 2. MetaMask에서 테스트 계정 가져오기
# Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# 3. 잔액 확인
TON=$(jq -r '.ton' .devnet/addresses.json)
DEPLOYER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
cast call $TON "balanceOf(address)(uint256)" $DEPLOYER --rpc-url http://localhost:8545
```

---

### Validator 목록이 비어있음

**증상**: "No validators registered yet" 메시지

**원인**: 아직 Validator가 등록되지 않음 (정상)

**정보**: 현재 로컬 환경에서는 Validator가 자동으로 등록되지 않습니다. 이는 정상 상태입니다.

---

### Dispute Games가 비어있음

**증상**: "No dispute games created yet" 메시지

**원인**: 아직 Dispute Game이 생성되지 않음 (정상)

**정보**: Dispute Game은 L2에서 상태 루트가 제출될 때 생성됩니다. 초기 상태에서는 비어있을 수 있습니다.

---

## 💎 스테이킹 문제

### "CandidateAddOn not found" 경고

**증상**: TON Staking 탭에서 경고 메시지

**원인**: Operator가 등록되지 않음

**해결**: 이 문제는 L2 등록이 필요합니다. 현재 자동 등록이 구현되지 않았으므로 수동 등록이 필요합니다.

**임시 조치**: Operator 탭에서 OperatorManager 및 CandidateAddOn 주소를 확인하세요.

---

### Approve 트랜잭션 실패

**증상**:
```
Transaction reverted: ERC20: insufficient allowance
```

**원인**: MetaMask에서 트랜잭션을 거부했거나 가스가 부족

**해결**:
1. MetaMask 팝업 확인 및 승인
2. 가스 한도 확인 (기본값 사용 권장)
3. 네트워크 연결 확인

---

### Deposit 트랜잭션 실패

**증상**:
```
Transaction failed: execution reverted
```

**원인**: WTON 잔액 부족 또는 Approve 미실행

**해결**:
```bash
# 1. WTON 잔액 확인
WTON=$(jq -r '.wton' .devnet/addresses.json)
YOUR_ADDRESS="<your_address>"
cast call $WTON "balanceOf(address)(uint256)" $YOUR_ADDRESS --rpc-url http://localhost:8545

# 2. TON을 WTON으로 스왑
# (Web UI에 스왑 기능이 없으므로 수동 스크립트 필요)
```

---

## 🌉 Bridge 문제

### ETH Deposit 실패

**증상**: "Bridge failed" 에러

**원인**: L2 네트워크가 작동하지 않거나 Bridge 컨트랙트 문제

**확인**:
```bash
# L2 네트워크 상태 확인
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:9545

# Portal 상태 확인
PORTAL=$(jq -r '.optimismPortal' .devnet/addresses.json)
cast call $PORTAL "paused()(bool)" --rpc-url http://localhost:8545
```

**해결**:
- Portal이 paused 상태면 테스트 불가능
- L2 네트워크 재시작: `docker-compose restart l2-execution l2-node`

---

### TON Deposit 실패

**증상**: Approve는 성공했지만 Deposit 실패

**원인**: L2 TON 주소가 올바르지 않거나 Bridge 설정 문제

**확인**:
```bash
# Rollup Info에서 L2 TON 주소 확인
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

cast call $L1_BRIDGE_REGISTRY \
  "getRollupInfo(address)(uint8,address,bool,bool,string)" \
  $SYSTEM_CONFIG \
  --rpc-url http://localhost:8545
```

---

### L2 Withdraw 작동 안함

**증상**: "Please connect to L2 network" 메시지 또는 트랜잭션 실패

**원인**: MetaMask가 L2 네트워크에 연결되지 않음

**해결**:
```bash
# 1. MetaMask에서 수동으로 L2 네트워크로 전환
Network: Add Network
Chain ID: 901
RPC URL: http://localhost:9545
Currency Symbol: ETH

# 2. L2 네트워크로 전환 후 Withdraw 시도

# 주의: L2에 ETH가 있어야 함 (먼저 Deposit 필요)
```

**현재 제한사항**: Web UI는 L2 네트워크 자동 전환을 지원하지 않습니다.

---

## 🔄 자동 업데이트 문제

### 데이터가 업데이트 안됨

**증상**: 트랜잭션 후에도 잔액이 변경되지 않음

**원인**: 자동 업데이트 주기(10초) 대기 필요

**해결**:
1. 10초 대기
2. 또는 페이지 새로고침 (F5)
3. 또는 다른 탭으로 이동 후 다시 돌아오기

---

### Console 에러 발생

**증상**: 브라우저 Console에 반복적인 에러 메시지

**원인**: RPC 연결 실패 또는 컨트랙트 호출 실패

**확인**:
```bash
# 브라우저 개발자 도구 열기 (F12)
# Console 탭에서 에러 메시지 확인
```

**일반적인 에러**:
- `Failed to fetch`: RPC 서버 연결 실패 → 로컬 네트워크 확인
- `Execution reverted`: 컨트랙트 함수 호출 실패 → 함수 파라미터 확인
- `Network error`: 네트워크 문제 → 로컬 네트워크 재시작

---

## 🐛 알려진 버그

### 1. Seigniorage 탭 접근 불가

**상태**: ❌ 구현되어 있지만 UI 메뉴에 없음

**원인**: `activeTab === 'seigniorage'` 조건이 누락됨

**임시 조치**: 현재 사용 불가능 (향후 수정 예정)

---

### 2. Balances 탭 접근 불가

**상태**: ❌ 구현되어 있지만 UI 메뉴에 없음

**원인**: `activeTab === 'balances'` 조건이 누락됨

**대안**: 각 기능 탭에서 관련 잔액 확인 가능

---

### 3. L2 Withdraw 자동 네트워크 전환 미지원

**상태**: ⚠️ 수동 네트워크 전환 필요

**원인**: MetaMask API 제한

**임시 조치**: 사용자가 수동으로 L2 네트워크로 전환

---

## 🔍 디버깅 팁

### 1. 브라우저 Console 확인

모든 에러 메시지는 브라우저 Console에 표시됩니다:

```bash
# 개발자 도구 열기
F12 또는 Cmd+Option+I (Mac)

# Console 탭 선택
# 에러 메시지 확인
```

### 2. 네트워크 탭 확인

트랜잭션 실패 원인을 확인하려면:

```bash
# Network 탭 열기
# "eth_sendTransaction" 또는 "eth_call" 요청 찾기
# Response 확인
```

### 3. RPC 직접 호출

문제가 Web UI인지 컨트랙트인지 확인:

```bash
# curl로 RPC 직접 호출
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545
```

### 4. 로그 확인

로컬 네트워크 로그 확인:

```bash
# L1 로그
docker-compose logs -f l1

# L2 로그
docker-compose logs -f l2-execution
docker-compose logs -f l2-node
```

---

## 📞 추가 도움

문제가 해결되지 않으면:

1. **로컬 네트워크 완전 재시작**
   ```bash
   docker-compose down -v
   rm -rf .devnet
   make devnet-allocs-offline
   make devnet-start
   ```

2. **Web UI 재시작**
   ```bash
   # Ctrl+C로 종료
   npm run dev
   ```

3. **브라우저 캐시 삭제**
   - Chrome: Cmd+Shift+Delete
   - 쿠키 및 캐시 삭제

4. **GitHub Issues 문의**
   - https://github.com/tokamak-network/ton-staking-v2/issues
   - 에러 메시지 및 스크린샷 첨부

---

## 관련 문서

- **[시작하기](./getting-started.md)** - 설치 및 실행 방법
- **[기능 가이드](./features.md)** - 각 기능 상세 설명
- **[로컬 환경 문제 해결](../QUICKSTART.md#문제-해결)** - 로컬 네트워크 문제
