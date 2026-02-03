# Web UI 브라우저 테스트 체크리스트

> **목적**: 브라우저에서 Web UI의 모든 기능을 실제로 테스트

**테스트 방법**: 브라우저에서 직접 클릭하고 확인

---

## 🚀 사전 준비

### [ ] 1. Web UI 실행
```bash
cd web-ui
npm run dev
```
- 브라우저에서 http://localhost:5173 접속

### [ ] 2. MetaMask 설치 및 설정
- MetaMask 브라우저 확장 프로그램 설치
- 테스트 계정 import (Private Key 사용)

**추천 테스트 계정**:
```
Account: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
```

---

## 📋 테스트 순서

### STEP 1: 지갑 연결 (필수)

#### [ ] 1-1. Connect Wallet 버튼 클릭
- "Connect Your Wallet" 화면 표시 확인
- "Connect Wallet" 버튼 존재 확인

#### [ ] 1-2. MetaMask 연결
- MetaMask 팝업 표시
- 계정 선택
- "Connect" 승인

#### [ ] 1-3. 네트워크 추가
- "Add Network" 팝업 표시 (Chain ID 900이 없을 경우)
- 네트워크 정보 확인:
  - Network Name: TON Staking V3 Local
  - RPC URL: http://localhost:8545
  - Chain ID: 900
  - Currency: ETH
- "Add" 또는 "Switch" 클릭

#### [ ] 1-4. 연결 확인
- 헤더에 "🟢 Connected: 0x90F7..." 표시
- Dashboard 화면으로 전환

**✅ 지갑 연결 성공 후 다음 단계 진행**

---

### STEP 2: Overview 탭 검증

#### [ ] 2-1. Node Status 카드
- [ ] L1 Status: 🟢 Online
- [ ] L1 Block: 숫자 표시 (10초마다 증가)
- [ ] L1 Chain ID: 900
- [ ] L2 Status: 🟢 Online
- [ ] L2 Block: 숫자 표시
- [ ] L2 Chain ID: 901 ✅

#### [ ] 2-2. Rollup Information 카드
- [ ] SystemConfig: 주소 표시
- [ ] Rollup Type: "Optimism Bedrock DisputeGame"
- [ ] L2 TON: 주소 표시
- [ ] Name: "Devnet L2"
- [ ] Rejected Seigs: ✅ No
- [ ] Rejected L2 Deposit: ✅ No ← **버그 수정됨**

#### [ ] 2-3. System Parameters 카드
- [ ] V3 Migrated: ✅ Yes
- [ ] Total Validators: 0
- [ ] Active Validators: 0
- [ ] Min Collateral: 60.00 WTON

#### [ ] 2-4. Contracts 카드
- [ ] TON Staking V3 Core Contracts (9개 주소 표시)
- [ ] Optimism Stack Contracts (2-4개 주소 표시)

---

### STEP 3: Balances 탭 - Faucet 테스트 ⭐

#### [ ] 3-1. Your Token Balances 확인
**테스트 전 잔액 기록**:
- ETH: __________ ETH
- TON: __________ TON
- WTON: __________ WTON
- Staked: __________ WTON

#### [ ] 3-2. Get 100 ETH 버튼
1. [ ] "⚡ Get 100 ETH" 버튼 클릭
2. [ ] 버튼이 "⏳ Sending..."으로 변경
3. [ ] MetaMask 트랜잭션 승인 팝업 표시
4. [ ] "Confirm" 클릭
5. [ ] 트랜잭션 대기 (2-5초)
6. [ ] "✅ Successfully sent 100 ETH!" alert 표시
7. [ ] ETH 잔액 자동 갱신 확인 (+100 ETH)

**결과**: ETH = __________ (이전 + 100)

#### [ ] 3-3. Get 10,000 TON 버튼
1. [ ] "🪙 Get 10,000 TON" 버튼 클릭
2. [ ] 버튼이 "⏳ Minting..."으로 변경
3. [ ] MetaMask 트랜잭션 승인
4. [ ] "✅ Successfully minted 10,000 TON!" alert 표시
5. [ ] **TON 잔액 확인** (+10,000 TON)

**예상 결과**: TON = 이전 잔액 + 10,000
**실제 결과**: TON = __________

**🐛 만약 TON이 0으로 표시된다면**:
- [ ] 브라우저 Console (F12) 열기
- [ ] Error 메시지 확인
- [ ] "Failed to load user balances" 에러가 있는지 확인
- [ ] 지갑이 제대로 연결되었는지 확인 (헤더에 주소 표시)

#### [ ] 3-4. Get 10,000 WTON 버튼
1. [ ] "💎 Get 10,000 WTON" 버튼 클릭
2. [ ] MetaMask 승인
3. [ ] "✅ Successfully minted 10,000 WTON!" alert 표시
4. [ ] **WTON 잔액 확인** (+10,000 WTON)

**예상 결과**: WTON = 이전 잔액 + 10,000
**실제 결과**: WTON = __________

---

### STEP 4: Token Swap 테스트

#### [ ] 4-1. TON → WTON Swap
**사전 조건**: TON 잔액 > 0

1. [ ] 입력 필드에 "100" 입력
2. [ ] "🪙→💎 TON to WTON" 버튼 클릭
3. [ ] MetaMask에서 Approve 트랜잭션 승인
4. [ ] 승인 완료 후 Swap 트랜잭션 자동 시작
5. [ ] "✅ Successfully swapped 100 TON to WTON!" alert
6. [ ] 잔액 확인:
   - TON: -100
   - WTON: +100

#### [ ] 4-2. WTON → TON Swap
1. [ ] 입력 필드에 "50" 입력
2. [ ] "💎→🪙 WTON to TON" 버튼 클릭
3. [ ] MetaMask 승인
4. [ ] "✅ Successfully swapped 50 WTON to TON!" alert
5. [ ] 잔액 확인:
   - TON: +50
   - WTON: -50

---

### STEP 5: Operator 탭 검증

#### [ ] 5-1. Operator Information 카드
- [ ] Operator Address: 주소 표시
- [ ] OperatorManager: 주소 표시
- [ ] CandidateAddOn: 주소 표시
- [ ] Sequencer Collateral: 1001.00 WTON 표시
- [ ] Layer2Registry Status: ✅ Registered

#### [ ] 5-2. Add Sequencer Collateral
**사전 조건**: WTON 잔액 > 0

1. [ ] 입력 필드에 "100" 입력
2. [ ] "Add Collateral" 버튼 클릭
3. [ ] MetaMask Approve 승인
4. [ ] MetaMask Deposit 승인
5. [ ] "✅ Collateral added successfully!" alert
6. [ ] Sequencer Collateral 증가 확인 (1001 → 1101)

---

### STEP 6: TON Staking 탭 테스트

#### [ ] 6-1. Deposit (Stake) WTON
**사전 조건**: WTON 잔액 > 0

1. [ ] 입력 필드에 "100" 입력
2. [ ] "💎 Stake" 버튼 클릭
3. [ ] MetaMask Approve 승인
4. [ ] MetaMask Deposit 승인
5. [ ] "✅ Staking successful!" alert
6. [ ] Your Staked Amount 증가 확인

#### [ ] 6-2. Request Withdrawal
**사전 조건**: Staked Amount > 0

1. [ ] 입력 필드에 "50" 입력
2. [ ] "📤 Request Withdrawal" 버튼 클릭
3. [ ] MetaMask 승인
4. [ ] "✅ Withdrawal requested successfully!" alert
5. [ ] Pending Unstaked 증가 확인
6. [ ] Pending Requests 숫자 증가

#### [ ] 6-3. Process Withdrawal
**사전 조건**: Pending Requests > 0

1. [ ] 입력 필드에 "1" 입력
2. [ ] "✅ Process Withdrawal" 버튼 클릭
3. [ ] MetaMask 승인
4. [ ] "✅ Withdrawal processed successfully!" alert
5. [ ] WTON 잔액 증가 확인
6. [ ] Pending Requests 감소

---

### STEP 7: Seigniorage 탭 테스트

#### [ ] 7-1. Layer2 주소 입력
1. [ ] CandidateAddOn 주소 복사 (Operator 탭에서)
2. [ ] Seigniorage 탭으로 이동
3. [ ] 입력 필드에 주소 붙여넣기
4. [ ] "🔍 Query" 버튼 클릭

#### [ ] 7-2. 데이터 표시 확인
- [ ] Layer2 Registration Status 카드 표시
- [ ] Operator Manager Information 카드 표시
- [ ] Seigniorage Issuance Factors 카드 (8개 파라미터)
- [ ] Update History 카드
- [ ] Reward Per Unit 카드
- [ ] Bridged TON & Required Stake 카드
- [ ] Eligibility Checklist 카드 (5개 조건)

#### [ ] 7-3. Update Seigniorage
1. [ ] "🔄 Update Seigniorage" 버튼 클릭
2. [ ] MetaMask 승인
3. [ ] 트랜잭션 완료 대기
4. [ ] 성공 alert 확인

---

### STEP 8: L2 Information 탭 검증

#### [ ] 8-1. L2 Network Information
- [ ] L2 Chain ID: 901 (녹색)
- [ ] L2 Block Number: 숫자 표시
- [ ] L2 RPC URL: http://localhost:9545

#### [ ] 8-2. Proposer & Batcher
- [ ] Batcher Hash 표시
- [ ] Unsafe Block Signer 표시

#### [ ] 8-3. Portal Status
- [ ] Paused: ✅ No (Active)
- [ ] Portal TON Balance 표시
- [ ] Portal ETH Balance 표시

---

### STEP 9: Bridge to L2 탭 테스트

#### [ ] 9-1. Bridge ETH to L2
**⚠️ 주의**: L2 네트워크로 전환됩니다

1. [ ] 입력 필드에 "1" 입력
2. [ ] "⬇️ Deposit ETH to L2" 버튼 클릭
3. [ ] MetaMask 승인
4. [ ] "✅ ETH deposit to L2 successful!" alert
5. [ ] 1분 대기 (L2 confirmation)

#### [ ] 9-2. Bridge TON to L2
1. [ ] 입력 필드에 "10" 입력
2. [ ] "⬇️ Deposit TON to L2" 버튼 클릭
3. [ ] MetaMask Approve 승인
4. [ ] MetaMask Bridge 승인
5. [ ] 성공 alert 확인

---

### STEP 10: Dispute Games 탭

#### [ ] 10-1. Games 테이블
- [ ] "No dispute games created yet" 또는 게임 목록 표시
- [ ] 게임이 있다면: #, Type, Proxy Address, Created At 컬럼 확인

---

### STEP 11: 🔄 Refresh Data 버튼

#### [ ] 11-1. 자동 갱신
- [ ] 10초 대기
- [ ] 블록 번호가 자동으로 증가하는지 확인

#### [ ] 11-2. 수동 갱신
- [ ] 하단 "🔄 Refresh Data" 버튼 클릭
- [ ] 버튼이 "🔄 Refreshing..."으로 변경
- [ ] 데이터 갱신 확인
- [ ] 버튼이 "🔄 Refresh Data"로 복귀

---

## 🐛 버그 발견 시 기록

### 버그 #1: _______________
**발견 위치**: _______________
**재현 방법**:
1. 
2. 
3. 

**예상 동작**: _______________
**실제 동작**: _______________
**브라우저 Console 에러**: _______________

---

## ✅ 테스트 결과 요약

### 통과한 기능
- [ ] 지갑 연결
- [ ] Overview 탭
- [ ] Balances 탭 - Faucet
- [ ] Balances 탭 - Token Swap
- [ ] Operator 탭
- [ ] TON Staking 탭
- [ ] Seigniorage 탭
- [ ] L2 Information 탭
- [ ] Bridge to L2 탭
- [ ] Dispute Games 탭
- [ ] 자동/수동 갱신

### 발견된 버그 수: __________

### 전체 평가
- ✅ **모든 기능 정상 작동**
- ⚠️ **일부 기능 문제 있음** (위 버그 참조)
- ❌ **주요 기능 실패**

---

## 📝 CLI 검증 (브라우저 테스트 대신)

브라우저 테스트가 불가능한 경우 CLI로 검증:

```bash
# Faucet 기능 검증
./scripts/test-webui-functions.sh

# 잔액 확인
TEST_ACCOUNT="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
TON=$(jq -r '.ton' .devnet/addresses.json)
WTON=$(jq -r '.wton' .devnet/addresses.json)

cast call $TON "balanceOf(address)(uint256)" $TEST_ACCOUNT --rpc-url http://localhost:8545
cast call $WTON "balanceOf(address)(uint256)" $TEST_ACCOUNT --rpc-url http://localhost:8545
```

---

**테스트 일시**: _______________
**테스터**: _______________
**결과**: ✅ / ⚠️ / ❌
