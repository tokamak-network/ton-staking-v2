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
│  L1 (Geth)           L2 (Optimism)      │
│  ├─ Chain ID: 900    ├─ Chain ID: 901  │
│  ├─ Port: 8545       ├─ Port: 9545     │
│  ├─ Clique PoA       ├─ op-geth        │
│  └─ TON Staking      │  (Debug Mode)   │
│     Contracts        ├─ op-node        │
│                      ├─ batcher        │
│                      └─ proposer       │
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
| L1 (Geth) | http://localhost:8545 | 900 | Clique PoA |
| L2 (op-geth) | http://localhost:9545 | 901 | Debug API 활성화 |
| L2 Rollup | http://localhost:7545 | 901 | op-node |

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

| 이름 | 주소 | ETH | TON | 용도 |
|------|------|-----|-----|------|
| Account #0 | `0xf39Fd...2266` | 10,000 | - | Batcher/Proposer |
| Account #1 | `0x70997...79C8` | 10,000 | 100,000 | Deployer/Staker |
| Account #2 | `0x90F79...b906` | 10,000 | - | Validator |

Private Key는 [빠른 시작 가이드](./QUICKSTART.md#테스트-계정)에서 확인하세요.

---

## ✅ 현재 상태

- ✅ **L1 + L2 네트워크**: 정상 작동
- ✅ **모든 컨트랙트**: 배포 완료
- ✅ **기본 기능**: 토큰 조회, 트랜잭션 실행
- ⚠️ **Validator 등록**: 수동 설정 필요
- ⚠️ **RAT 테스트**: 파라미터 조정 필요

자세한 내용은 **[현재 상태](./STATUS.md)**를 참조하세요.

---

## 🧪 테스트 가능 기능

### ✅ 지금 바로 테스트 가능
- L1/L2 네트워크 연결 확인
- TON/WTON 잔액 조회
- 컨트랙트 함수 호출
- 기본 트랜잭션 전송

### ⚠️ 추가 설정 필요
- Validator 등록 ([가이드](./VALIDATOR-SETUP.md) 참조)
- L2 스테이킹
- RAT Challenge 응답

---

## 🛠️ 문제 해결

### 포트가 이미 사용 중
```bash
# 프로세스 확인
lsof -i :8545
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
