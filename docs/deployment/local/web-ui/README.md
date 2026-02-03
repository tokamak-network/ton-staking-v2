# TON Staking V3 Web UI - 사용 가이드

TON Staking V3 로컬 환경을 위한 웹 대시보드입니다.

---

## 📚 문서 구조

| 문서 | 설명 |
|------|------|
| **[시작하기](./getting-started.md)** | 설치 및 실행 방법 |
| **[기능 가이드](./features.md)** | 각 메뉴 및 기능 상세 설명 |
| **[문제 해결](./troubleshooting.md)** | 일반적인 문제 및 해결 방법 |

---

## 🎯 주요 기능

### 1. 대시보드 모니터링
- ✅ L1/L2 네트워크 상태 실시간 확인
- ✅ Rollup 정보 조회
- ✅ 시스템 파라미터 확인
- ✅ 컨트랙트 주소 목록

### 2. Operator 관리
- ✅ Operator 정보 조회
- ✅ Sequencer 담보금 추가
- ✅ OperatorManager 상태 확인

### 3. Validator 관리
- ✅ 등록된 Validator 목록 조회
- ✅ Validator 상태 및 잔액 확인
- ✅ RAT 등록 상태 확인

### 4. TON 스테이킹
- ✅ WTON 토큰 스테이킹 (Deposit)
- ✅ 출금 요청 (Request Withdrawal)
- ✅ 출금 처리 (Process Withdrawal)
- ✅ 스테이킹 잔액 조회

### 5. 시뇨리지 (Seigniorage)
- ✅ Layer2별 시뇨리지 정보 조회
- ✅ 발행 조건 및 수령 가능 금액 확인
- ✅ 시뇨리지 발행 팩터 확인

### 6. L2 정보
- ✅ SystemConfig 정보 조회
- ✅ Batcher/Proposer 설정 확인
- ✅ Portal 상태 및 잔액 조회
- ✅ Bridge 컨트랙트 주소

### 7. Bridge 기능
- ✅ ETH를 L1에서 L2로 전송
- ✅ TON을 L1에서 L2로 전송
- ✅ ETH를 L2에서 L1로 출금
- ✅ Bridge 잔액 확인

### 8. Dispute Games
- ✅ 최근 Dispute Game 목록 조회
- ✅ Game Type 및 생성 시간 확인

### 9. 잔액 조회
- ✅ 연결된 지갑의 ETH/TON/WTON 잔액
- ✅ 스테이킹 금액 및 출금 대기 금액
- ✅ 실시간 업데이트 (10초 간격)

---

## 🚀 빠른 시작

```bash
# 1. 로컬 네트워크 시작 (선행 필수)
make devnet-start

# 2. Web UI 실행
cd web-ui
npm install
npm run dev

# 3. 브라우저에서 접속
# http://localhost:5173
```

자세한 내용은 **[시작하기](./getting-started.md)**를 참조하세요.

---

## 🛠️ 기술 스택

- **Frontend**: React 19 + TypeScript
- **Build Tool**: Vite 7
- **Blockchain**: ethers.js v6
- **Styling**: CSS (App.css)

---

## 📋 사전 요구사항

1. **로컬 네트워크 실행 중**
   ```bash
   make devnet-start
   # L1: http://localhost:8545 (Chain ID: 900)
   # L2: http://localhost:9545 (Chain ID: 901)
   ```

2. **Node.js 설치**
   - Node.js 18+ 권장

3. **MetaMask 설치** (선택)
   - 브라우저 확장 프로그램으로 설치
   - 테스트 계정 가져오기 가능

---

## ⚠️ 알려진 제한사항

### 빌드 오류
현재 TypeScript 빌드 시 다음 경고가 발생합니다:
```
error TS6133: 'LAYER2_STATUS' is declared but its value is never read.
error TS6133: 'VALIDATOR_REWARD_ABI' is declared but its value is never read.
```

**영향**: 개발 모드(`npm run dev`)는 정상 작동합니다.  
**해결**: 프로덕션 빌드 전 미사용 import 제거 필요

### Seigniorage 탭
- Layer2 주소를 선택한 후에만 정보 로드
- CandidateAddOn 주소가 필요 (Operator 등록 후 사용 가능)

---

## 🔗 관련 문서

- **[로컬 환경 구축](../QUICKSTART.md)** - 로컬 네트워크 시작
- **[현재 상태](../STATUS.md)** - 작동 기능 및 제한사항
- **[Validator 설정](../VALIDATOR-SETUP.md)** - Validator 등록

---

## 📞 문의 및 지원

- **GitHub Issues**: https://github.com/tokamak-network/ton-staking-v2/issues
- **브랜치**: `ton-staking-v3/deploy-local`
