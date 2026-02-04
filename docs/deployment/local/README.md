# TON Staking V3 - 로컬 배포 가이드

TON Staking V3를 로컬 환경에서 실행하고 테스트하기 위한 문서입니다.

---

## 📚 문서 구조

| 문서 | 설명 | 대상 |
|------|------|------|
| **[빠른 시작 가이드](./QUICKSTART.md)** | 5분 안에 로컬 환경 구축 | 모든 사용자 |
| **[현재 상태](./STATUS.md)** | 작동 기능 및 제한사항 | 모든 사용자 |
| **[구현 상세](./IMPLEMENTATION.md)** | 기술적 세부사항 | 개발자 |
| **[Validator 설정](./VALIDATOR-SETUP.md)** | Validator 등록 가이드 | 고급 사용자 |

---

## 🚀 빠른 시작

```bash
# 1. Genesis 파일 생성
make devnet-allocs-offline

# 2. 로컬 네트워크 시작
make devnet-start

# 3. 상태 확인
make devnet-info
```

자세한 내용은 **[빠른 시작 가이드](./QUICKSTART.md)**를 참조하세요.

---

## 🏗️ 시스템 구성

```
┌─────────────────────────────────────────┐
│     TON Staking V3 Local Devnet         │
├─────────────────────────────────────────┤
│                                         │
│  L1 (Anvil Fork)     L2 (Optimism)      │
│  ├─ Chain ID: 900    ├─ Chain ID: 901  │
│  ├─ Port: 8546       ├─ Port: 9545     │
│  ├─ Sepolia Fork     ├─ op-geth        │
│  └─ TON Staking      │  (Debug Mode)   │
│     + Optimism       ├─ op-node        │
│     Contracts        ├─ batcher        │
│                      ├─ proposer       │
│                      └─ RAT Clients(3) │
└─────────────────────────────────────────┘
```

---

## 📋 필수 도구

- **[Foundry](https://book.getfoundry.sh/)** - Solidity 개발 툴킷
- **[Docker Desktop](https://www.docker.com/products/docker-desktop)** - 컨테이너 실행
- **[jq](https://stedolan.github.io/jq/)** - JSON 처리

---

## 🔑 주요 명령어

```bash
# Genesis 파일 생성
make devnet-allocs-offline

# 환경 시작
make devnet-start

# 상태 확인
make devnet-info

# 환경 중지
make devnet-stop

# 완전 초기화
docker-compose down -v
rm -rf .devnet
```

---

## 🌐 RPC 엔드포인트

| 서비스 | URL | Chain ID | 비고 |
|--------|-----|----------|------|
| L1 (Anvil) | http://localhost:8546 | 900 | Sepolia Fork |
| L2 (op-geth) | http://localhost:9545 | 901 | Debug API 활성화 |
| L2 Rollup | http://localhost:7545 | 901 | op-node |

> **참고**: L1 포트는 8546입니다 (MetaMask 호환성을 위해 8545 대신 사용)

---

## 📝 주요 컨트랙트

배포 후 `.devnet/addresses.json`에서 주소 확인 가능:

```bash
cat .devnet/addresses.json | jq '{ton, wton, seigManagerProxy, depositManagerProxy}'
```

| 컨트랙트 | 역할 |
|---------|------|
| `ton` | TON 토큰 |
| `wton` | Wrapped TON |
| `seigManagerProxy` | V3 시뇨리지 관리 |
| `depositManagerProxy` | 스테이킹 관리 |
| `layer2ManagerProxy` | L2 등록 및 관리 |
| `ratProxy` | Validator RAT |
| `systemConfig` | Optimism SystemConfig |

---

## 👥 테스트 계정

| 역할 | 주소 | 용도 |
|------|------|------|
| Operator | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` (Anvil #0) | 시퀀서/배처/프로포저 |
| Manager | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` (Anvil #1) | 배포자/관리자 |
| Validator1 | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` (Anvil #3) | 검증자 |
| Validator2 | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` (Anvil #4) | 검증자 |
| Validator3 | `0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc` (Anvil #5) | 검증자 |
| Personal | `0x976EA74026E726554dB657fA54763abd0C3a0aa9` (Anvil #6) | 개인 테스트 (100k TON + 100k WTON) |

Private Key는 Anvil 기본 키를 사용합니다. [빠른 시작 가이드](./QUICKSTART.md#테스트-계정)에서 확인하세요.

---

## ✅ 현재 상태

- ✅ **L1 + L2 네트워크**: 정상 작동
- ✅ **모든 컨트랙트**: 배포 완료
- ✅ **L2 등록**: 자동 등록 (Rollup Type 3)
- ✅ **Validator 등록**: 자동 등록 (3개)
- ✅ **RAT 설정**: 자동 구성 완료
- ✅ **테스트 계정**: TON/WTON 자동 발급

자세한 내용은 **[현재 상태](./STATUS.md)**를 참조하세요.

---

## 🧪 테스트 가능 기능

### ✅ 지금 바로 테스트 가능
- L1/L2 네트워크 연결 확인
- TON/WTON 잔액 조회 및 민팅
- 컨트랙트 함수 호출
- L2 스테이킹/출금
- Validator 상태 확인
- 시뇨리지 업데이트
- Web UI 대시보드 사용

### 📋 자동 설정 항목
시작 스크립트(`start-sepolia-fork.sh`)에서 자동으로 설정됩니다:
- L2 롤업 등록 (Type 3: Optimism Bedrock DisputeGame)
- Validator 3명 등록 및 담보금 예치
- RAT 파라미터 구성 (slashingPenalty, evidenceSubmissionPeriod 등)
- 테스트 계정에 TON/WTON 발급

---

## 🌐 Web UI

Web UI를 통해 대시보드에서 TON Staking V3 시스템을 관리할 수 있습니다.

```bash
# Web UI 시작
cd web-ui && npm install && npm run dev

# 브라우저에서 열기
open http://localhost:5173
```

### Web UI 기능
- **Overview**: 시스템 상태, 주요 컨트랙트 정보
- **Sequencer**: 시퀀서 담보금 및 자격 상태
- **Validators**: 검증자 목록 및 RAT 설정
- **TON Staking**: 스테이킹/출금 기능
- **Seigniorage**: 시뇨리지 상태 및 업데이트
- **L1/L2 Information**: 네트워크 및 컨트랙트 상세 정보
- **Bridge**: L2 브릿지 기능
- **Balances**: 테스트 계정 잔액 및 민팅

---

## 🛠️ 문제 해결

### 포트가 이미 사용 중
```bash
# 프로세스 확인
lsof -i :8546
lsof -i :9545

# 기존 환경 종료
make devnet-stop
docker-compose down -v
```

### Docker 실행 안됨
```bash
# macOS/Windows
open -a Docker

# Linux
sudo systemctl start docker
```

### Genesis 생성 실패
```bash
# 서브모듈 재설치
rm -rf lib
git submodule update --init --recursive

# 재빌드
forge clean
forge build
```

더 많은 문제 해결 방법은 [빠른 시작 가이드 - 문제 해결](./QUICKSTART.md#문제-해결)을 참조하세요.

---

## 📖 다음 단계

1. **[빠른 시작 가이드](./QUICKSTART.md)** - 환경 구축
2. **[Validator 설정](./VALIDATOR-SETUP.md)** - Validator 등록
3. **[구현 상세](./IMPLEMENTATION.md)** - 기술 이해

---

## 📞 문의 및 지원

- **GitHub Issues**: https://github.com/tokamak-network/ton-staking-v2/issues
- **브랜치**: `ton-staking-v3/deploy-local`
- **TON Staking V3 문서**: https://tokamak-network.github.io/ton-staking-v2/
