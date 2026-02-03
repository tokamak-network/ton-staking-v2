# Web UI - 시작하기

TON Staking V3 Web UI 설치 및 실행 가이드입니다.

---

## 📋 사전 요구사항

### 1. 로컬 네트워크 실행 중 ✅

Web UI를 사용하기 전에 로컬 devnet이 실행 중이어야 합니다:

```bash
# 프로젝트 루트에서
make devnet-start

# 상태 확인
make devnet-info
```

**확인사항**:
- ✅ L1 RPC: `http://localhost:8545` (Chain ID: 900)
- ✅ L2 RPC: `http://localhost:9545` (Chain ID: 901)
- ✅ 컨테이너 상태: `healthy`

### 2. Node.js 설치

- **권장 버전**: Node.js 20.19+ 또는 22.12+
- **최소 버전**: Node.js 18+

```bash
# 버전 확인
node --version
```

> ⚠️ **주의**: Vite 7는 Node.js 20.19+ 또는 22.12+를 권장합니다. 낮은 버전에서도 작동하지만 경고가 표시됩니다.

### 3. MetaMask 설치 (선택)

브라우저에 MetaMask 확장 프로그램을 설치하면 지갑 연결 기능을 사용할 수 있습니다:
- Chrome/Brave: [Chrome Web Store](https://chrome.google.com/webstore)
- Firefox: [Firefox Add-ons](https://addons.mozilla.org/)

---

## 🚀 설치 및 실행

### 1. Web UI 디렉토리로 이동

```bash
cd web-ui
```

### 2. 의존성 설치

```bash
npm install
```

**예상 시간**: 1-2분

### 3. 개발 서버 실행

```bash
npm run dev
```

**출력 예시**:
```
  VITE v7.3.1  ready in 432 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help
```

### 4. 브라우저에서 접속

브라우저를 열고 다음 주소로 접속하세요:

```
http://localhost:5173
```

---

## 🔌 지갑 연결

### 방법 1: MetaMask로 연결

1. **"Connect Wallet" 버튼 클릭**
2. **MetaMask 팝업에서 네트워크 추가 승인**
   - Chain ID: 900
   - RPC URL: http://localhost:8545
   - Chain Name: TON Staking V3 Local
3. **계정 연결 승인**

### 방법 2: 테스트 계정 가져오기

Web UI 메인 화면에서 제공되는 테스트 계정 정보를 MetaMask에 가져올 수 있습니다:

#### Account #0 - Deployer / Operator
```
Address:     0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
Balance:     10,000 ETH
Role:        L2 Operator & Sequencer
```

#### Account #1 - TON Staking Deployer
```
Address:     0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
Balance:     10,000 ETH + 100,000 TON
Role:        Admin (Manager Role)
```

#### Account #2 - Validator #1
```
Address:     0x90F79bf6EB2c4f870365E785982E1f101E93b906
Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
Balance:     10,000 ETH
Role:        RAT Validator
```

**MetaMask에 가져오는 방법**:
1. MetaMask 열기
2. 계정 아이콘 클릭 → "계정 가져오기"
3. Private Key 입력
4. "가져오기" 클릭

---

## 📱 화면 구성

### 연결 전 화면

지갑 연결 전에는 다음이 표시됩니다:
- **Connect Wallet 버튼**
- **테스트 계정 목록** (Private Key 포함)

### 연결 후 화면

지갑 연결 후 대시보드가 표시됩니다:
- **왼쪽 사이드바**: 메뉴 네비게이션
- **오른쪽 메인 영역**: 선택한 탭의 내용
- **상단 헤더**: 연결된 주소 표시

---

## ⚙️ 빌드 (프로덕션)

개발이 완료되면 프로덕션 빌드를 생성할 수 있습니다:

```bash
npm run build
```

**출력 디렉토리**: `dist/`

**결과**:
- `dist/index.html` - 메인 HTML 파일
- `dist/assets/` - 번들된 CSS 및 JavaScript

### 빌드 결과물 실행

```bash
npm run preview
```

프로덕션 빌드를 로컬에서 미리 볼 수 있습니다.

---

## 🔄 자동 업데이트

Web UI는 다음 데이터를 **10초마다 자동으로 새로고침**합니다:
- ✅ L1/L2 블록 번호
- ✅ Validator 목록 및 상태
- ✅ Operator 정보
- ✅ Dispute Games
- ✅ 시스템 파라미터

연결된 지갑의 잔액도 자동으로 업데이트됩니다.

---

## 🛑 종료

개발 서버를 종료하려면:

```bash
# 터미널에서 Ctrl + C
```

---

## 📂 프로젝트 구조

```
web-ui/
├── src/
│   ├── App.tsx          # 메인 애플리케이션 (1800+ 줄)
│   ├── App.css          # 스타일시트
│   ├── config.ts        # 설정 (RPC URL, 컨트랙트 주소)
│   ├── abis.ts          # 컨트랙트 ABI 정의
│   └── main.tsx         # 진입점
├── public/              # 정적 파일
├── dist/                # 빌드 출력 (빌드 후 생성)
├── package.json         # 의존성 및 스크립트
└── vite.config.ts       # Vite 설정
```

---

## 🔧 설정 변경

### RPC URL 변경

`src/config.ts` 파일에서 RPC URL을 변경할 수 있습니다:

```typescript
export const CONFIG = {
  chainId: 900,
  rpcUrl: 'http://localhost:8545',      // L1 RPC
  l2RpcUrl: 'http://localhost:9545',    // L2 RPC
  chainName: 'TON Staking V3 Local',
  // ...
};
```

### 컨트랙트 주소 업데이트

`.devnet/addresses.json` 파일이 변경되면 `src/config.ts`의 `contracts` 섹션을 업데이트하세요:

```typescript
contracts: {
  ton: '0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E',
  wton: '0x2B2fE3204CcB8282ac6bC31d485cB6aa010d193a',
  // ... 기타 컨트랙트
}
```

---

## 다음 단계

설치가 완료되었다면:

1. **[기능 가이드](./features.md)** - 각 메뉴 및 기능 상세 설명
2. **[문제 해결](./troubleshooting.md)** - 일반적인 문제 해결

---

## 📞 도움말

문제가 발생하면 [문제 해결](./troubleshooting.md) 문서를 확인하거나 GitHub Issues에 문의하세요.
