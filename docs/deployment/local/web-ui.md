# 웹 UI 가이드

TON Staking V3 로컬 환경을 위한 웹 인터페이스 사용 가이드입니다.

## 목차

1. [시작하기](#시작하기)
2. [기능 소개](#기능-소개)
3. [MetaMask 설정](#metamask-설정)
4. [사용 방법](#사용-방법)
5. [문제 해결](#문제-해결)

## 시작하기

### 1. Anvil 노드 시작

먼저 로컬 Anvil 노드를 시작합니다:

```bash
# 프로젝트 루트에서
./scripts/start-local-devnet.sh
```

### 2. 웹 UI 실행

새 터미널에서:

```bash
cd web-ui
npm install  # 처음 한 번만
npm run dev
```

### 3. 브라우저에서 접속

```
http://localhost:5173
```

## 기능 소개

### 대시보드

웹 UI는 다음과 같은 기능을 제공합니다:

#### 1. 월렛 연결
- MetaMask 연결
- 네트워크 자동 추가/전환
- 계정 주소 표시

#### 2. 잔액 조회
- **TON 잔액**: 스테이킹 가능한 TON 토큰
- **WTON 잔액**: Wrapped TON 토큰
- **Staked**: 현재 스테이킹된 금액

#### 3. 스테이킹 인터페이스
- L2 선택
- TON 금액 입력
- 원클릭 스테이킹 (Approve + Deposit)

#### 4. 정보 패널
- 네트워크 정보
- 등록된 L2 개수
- 컨트랙트 주소

## MetaMask 설정

### 자동 설정 (권장)

1. 웹 UI에서 "Connect Wallet" 클릭
2. MetaMask에서 네트워크 추가 승인
3. 계정 연결 승인

웹 UI가 자동으로 다음 네트워크를 추가합니다:

```
Network Name: TON Staking V3 Local
RPC URL: http://localhost:8545
Chain ID: 900
Currency Symbol: ETH
```

### 수동 설정

MetaMask에서 직접 네트워크를 추가할 수도 있습니다:

1. MetaMask 열기
2. 네트워크 드롭다운 클릭
3. "Add network" → "Add network manually"
4. 다음 정보 입력:
   - **Network name**: TON Staking V3 Local
   - **RPC URL**: http://localhost:8545
   - **Chain ID**: 900
   - **Currency symbol**: ETH

### 테스트 계정 가져오기

웹 UI의 "Test Accounts" 섹션에서 원하는 계정의 "Show Private Key" 버튼을 클릭합니다.

Private Key를 복사한 후 MetaMask에 가져오기:

1. MetaMask에서 계정 아이콘 클릭
2. "Import Account" 선택
3. Private Key 붙여넣기
4. "Import" 클릭

#### 추천 계정

**Account #1 - TON Staking Deployer**
- TON: 1,000,000 TON 보유
- ETH: 10,000 ETH 보유
- 스테이킹 테스트에 적합

## 사용 방법

### 1. 월렛 연결

![Connect Wallet](./images/connect-wallet.png)

1. "Connect Wallet" 버튼 클릭
2. MetaMask에서 네트워크 추가 승인 (처음 한 번)
3. 계정 연결 승인

### 2. L2 등록 (최초 1회)

스테이킹하기 전에 먼저 L2를 등록해야 합니다.

**방법 A: Cast 사용 (권장)**

```bash
# SystemConfig 주소
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

# Layer2Manager 주소
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' .devnet/addresses.json)

# L2 등록 (Account #1의 private key 사용)
cast send $LAYER2_MANAGER \
  "registerLayer2(address)" \
  $SYSTEM_CONFIG \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
  --rpc-url http://localhost:8545
```

**방법 B: 웹 UI에서 직접 (향후 기능)**

현재 웹 UI에는 L2 등록 기능이 없으므로 Cast를 사용해야 합니다.

### 3. TON 스테이킹

![Stake TON](./images/stake-ton.png)

1. **L2 선택**: 드롭다운에서 스테이킹할 L2 선택
2. **금액 입력**: 스테이킹할 TON 금액 입력
3. **Stake 버튼 클릭**
4. **MetaMask에서 승인**:
   - 첫 번째 트랜잭션: TON Approve
   - 두 번째 트랜잭션: Deposit
5. **완료 대기**: 트랜잭션이 완료되면 잔액이 자동 업데이트됩니다

### 4. 잔액 확인

스테이킹 후 대시보드에서 잔액 변화를 확인할 수 있습니다:

- **TON**: 감소 (스테이킹한 금액만큼)
- **Staked**: 증가 (스테이킹한 금액만큼)

## 고급 기능

### TON ↔ WTON 스왑

현재 웹 UI에는 스왑 기능이 없으므로 Cast를 사용합니다:

```bash
WTON=$(jq -r '.wton' .devnet/addresses.json)

# TON → WTON (1000 TON)
cast send $WTON \
  "swapFromTON(uint256)" \
  1000000000000000000000 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
  --rpc-url http://localhost:8545

# WTON → TON (1000 WTON)
cast send $WTON \
  "swapToTON(uint256)" \
  1000000000000000000000 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
  --rpc-url http://localhost:8545
```

### 출금 (Unstaking)

현재 웹 UI에는 출금 기능이 없으므로 Cast를 사용합니다:

```bash
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' .devnet/addresses.json)
LAYER2_ADDRESS=$(cast call $(jq -r '.layer2ManagerProxy' .devnet/addresses.json) "layer2s(uint256)(address)" 0 --rpc-url http://localhost:8545)

# 1. 출금 요청 (100 TON)
cast send $DEPOSIT_MANAGER \
  "requestWithdrawal(address,uint256)" \
  $LAYER2_ADDRESS \
  100000000000000000000 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
  --rpc-url http://localhost:8545

# 2. 출금 처리 (대기 기간 후)
cast send $DEPOSIT_MANAGER \
  "processWithdrawal(address,uint256)" \
  $LAYER2_ADDRESS \
  0 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
  --rpc-url http://localhost:8545
```

## 문제 해결

### "Please install MetaMask" 메시지

**원인**: MetaMask가 설치되지 않음

**해결**:
1. [MetaMask 웹사이트](https://metamask.io/)에서 설치
2. 브라우저 재시작
3. 웹 UI 새로고침

### "Failed to connect wallet" 오류

**원인**: 네트워크 추가 실패 또는 거부

**해결**:
1. MetaMask에서 네트워크 수동 추가 (위의 "수동 설정" 참고)
2. 웹 UI에서 다시 연결 시도

### "No L2 registered yet" 경고

**원인**: 등록된 L2가 없음

**해결**:
위의 "L2 등록" 섹션을 참고하여 Cast로 L2를 등록합니다.

### "Staking failed" 오류

**가능한 원인**:
1. **TON 잔액 부족**: 잔액 확인
2. **가스비 부족**: ETH 잔액 확인
3. **L2가 등록되지 않음**: L2 등록 확인
4. **네트워크 연결 문제**: Anvil 노드 실행 확인

**해결**:
```bash
# Anvil 노드 상태 확인
cast block-number --rpc-url http://localhost:8545

# TON 잔액 확인
cast call $(jq -r '.ton' .devnet/addresses.json) \
  "balanceOf(address)(uint256)" \
  <YOUR_ADDRESS> \
  --rpc-url http://localhost:8545

# ETH 잔액 확인
cast balance <YOUR_ADDRESS> --rpc-url http://localhost:8545
```

### 트랜잭션이 pending 상태로 멈춤

**원인**: Anvil이 중지되었거나 네트워크 문제

**해결**:
1. Anvil 재시작:
   ```bash
   # Ctrl+C로 종료 후
   ./scripts/start-local-devnet.sh
   ```
2. MetaMask에서 pending 트랜잭션 취소
3. 웹 UI 새로고침

### 잔액이 업데이트되지 않음

**해결**:
웹 페이지를 새로고침하거나 "Connect Wallet" 버튼을 다시 클릭합니다.

## 개발자를 위한 정보

### 로컬 개발

```bash
cd web-ui
npm run dev  # 개발 서버 (HMR 지원)
```

### 빌드

```bash
npm run build  # 프로덕션 빌드
npm run preview  # 빌드된 결과 미리보기
```

### 설정 파일

- `web-ui/src/config.ts`: 컨트랙트 주소 및 네트워크 설정
- `web-ui/src/abis.ts`: 컨트랙트 ABI 정의
- `web-ui/src/App.tsx`: 메인 컴포넌트

### 향후 개선 사항

- [ ] L2 등록 인터페이스
- [ ] TON/WTON 스왑 기능
- [ ] 출금 (Unstaking) 인터페이스
- [ ] Validator 등록 기능
- [ ] 트랜잭션 히스토리
- [ ] 실시간 이벤트 로그
- [ ] 멀티체인 지원

## 다음 단계

- [RAT Client 가이드](./rat-client.md) - Validator 클라이언트 실행
- [모니터링 가이드](./monitoring.md) - 시스템 상태 모니터링

## 참고 자료

- [ethers.js 문서](https://docs.ethers.org/v6/)
- [Vite 문서](https://vitejs.dev/)
- [React 문서](https://react.dev/)
- [MetaMask 문서](https://docs.metamask.io/)
