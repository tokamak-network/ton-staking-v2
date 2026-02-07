# Web UI 빠른 점검 가이드

> 5분 안에 Web UI의 핵심 기능을 빠르게 점검하는 가이드

---

## 🚀 빠른 시작

### 1단계: 환경 실행 확인 (30초)

```bash
# L1/L2 노드 확인
docker ps --filter "name=ton-staking" --format "{{.Names}}: {{.Status}}" | grep healthy

# 기대 출력:
# ton-staking-l1: Up X minutes (healthy)
# ton-staking-l2-execution: Up X minutes (healthy)
# ton-staking-l2-node: Up X minutes (healthy)
```

✅ 3개 컨테이너 모두 `healthy` 상태여야 함

---

### 2단계: Config 검증 (10초)

```bash
./scripts/verify-webui-config.sh
```

✅ "ALL VERIFICATIONS PASSED" 메시지 확인

---

### 3단계: Web UI 실행 (30초)

```bash
cd web-ui
npm run dev
```

✅ 브라우저에서 http://localhost:5173 접속

---

### 4단계: 핵심 기능 점검 (3분)

#### [ ] 지갑 연결 (30초)

1. "Connect Wallet" 클릭
2. MetaMask에서 네트워크 추가 승인 (Chain ID 900)
3. 계정 연결 승인
4. 헤더에 "🟢 Connected: 0xABCD...5678" 표시 확인

#### [ ] Overview 탭 (30초)

- [ ] L1 Status: 🟢 Online
- [ ] L1 Block: 숫자 표시 (10초 후 증가 확인)
- [ ] L2 Status: 🟢 Online
- [ ] V3 Migrated: ✅ Yes
- [ ] 모든 컨트랙트 주소 표시됨

#### [ ] Operator 탭 (30초)

- [ ] Operator Address 표시
- [ ] OperatorManager 주소 표시 (등록된 경우)
- [ ] Sequencer Collateral 금액 표시

#### [ ] Balances 탭 (30초)

- [ ] ETH, TON, WTON, Staked 잔액 카드 4개 표시
- [ ] "Get 100 ETH" 버튼 클릭 → 성공 메시지
- [ ] 30초 후 ETH 잔액 증가 확인

#### [ ] L2 Information 탭 (30초)

- [ ] L2 Chain ID: 901
- [ ] L2 Block Number 표시
- [ ] Portal Paused: ✅ No (Active)
- [ ] 모든 주소 필드 채워져 있음

---

## ✅ 성공 기준

**모든 항목 체크되면 통과**:
- ✅ 환경 실행 중 (L1 + L2 healthy)
- ✅ Config 검증 통과
- ✅ Web UI 접속 가능
- ✅ 지갑 연결 성공
- ✅ 5개 탭 모두 데이터 표시

---

## ❌ 실패 시 조치

### Config 검증 실패
```bash
# 주소 불일치 시
cp .devnet/addresses.json .devnet/addresses.json.backup
# web-ui/src/config.ts를 수정하여 주소 일치시킴
./scripts/verify-webui-config.sh  # 재확인
```

### 지갑 연결 실패
- MetaMask 설치 확인
- 네트워크 수동 추가:
  - Network Name: TON Staking V3 Local
  - RPC URL: http://localhost:8545
  - Chain ID: 900
  - Currency Symbol: ETH

### 데이터 표시 안 됨
```bash
# 노드 재시작
make devnet-stop
make devnet-start

# 브라우저 새로고침 (Ctrl+Shift+R)
```

---

## 📊 상세 점검

더 자세한 점검이 필요하면:
- [상세 체크리스트](./WEB-UI-DETAILED-CHECKLIST.md) - 모든 페이지, 모든 필드 검증
- [검증 체크리스트](./VERIFICATION-CHECKLIST.md) - 전체 시스템 검증

---

## 🛠️ 추가 도구

### 자동 검증 스크립트
```bash
# Config 검증
./scripts/verify-webui-config.sh

# 전체 시스템 검증
./scripts/verify-all.sh

# 시스템 상태
./scripts/check-system-status.sh
```

### 브라우저 개발자 도구
```javascript
// 콘솔에서 실행하여 현재 데이터 확인
console.log('Contract Addresses:', CONFIG.contracts);
console.log('Chain ID:', CONFIG.chainId);
console.log('RPC URL:', CONFIG.rpcUrl);
```

---

**빠른 체크 완료 시간**: 약 5분  
**상세 체크 완료 시간**: 약 30-60분 (WEB-UI-DETAILED-CHECKLIST.md 참조)
