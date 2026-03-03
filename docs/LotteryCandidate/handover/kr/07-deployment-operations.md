# 7. 배포 및 운영 방법

[← 목차로 돌아가기](./README.md) | [← 이전: API 명세](./06-api-specification.md)

---

## 7.1 로컬 데모 실행 (원클릭)

```bash
# 사전 요구사항: Foundry, Node.js v18+, MetaMask
git clone --recurse-submodules <repo-url>
cd ton-staking-v2

# 원클릭 실행 (Anvil + 컨트랙트 배포 + 프론트엔드)
./run-lottery-demo.sh
```

### 스크립트 실행 단계

| 단계 | 동작 | 세부 내용 |
|------|------|----------|
| 1 | Anvil 시작 | `--host 0.0.0.0 --port 8545 --chain-id 31337 --block-time 1` |
| 2 | 컨트랙트 배포 | `DeployLotteryDemo.s.sol` 실행 (`--via-ir` 플래그 필수) |
| 2.5 | 시뇨리지 초기화 | `updateSeigniorage()` 1회 호출 (First-Call Trap 해소) |
| 3 | 프론트엔드 설치 | `npm install` (최초 1회, `node_modules` 없을 때만) |
| 4 | 프론트엔드 시작 | `http://localhost:5173` 에서 접근 가능 |

### 배포 산출물

배포 스크립트는 `DEPLOYMENT_JSON_START` / `DEPLOYMENT_JSON_END` 마커 사이에 JSON을 출력한다. 이 JSON은 자동으로 `demo-frontend/src/deployment.json`에 저장되며, 다음 주소들을 포함한다:

- `ton`, `wton` - 토큰 주소
- `seigManager`, `depositManager` - 스테이킹 인프라
- `daoCommittee` - DAO 위원회
- `lotteryCandidate` - 생성된 LotteryCandidate 프록시
- `operator` - 오퍼레이터 주소
- 각 계정의 주소 및 프라이빗 키

---

## 7.2 테스트 계정 정보

> Anvil 기본 테스트 계정. **절대 메인넷에서 사용 금지.**

| 역할 | 주소 | 프라이빗 키 | 초기 잔액 |
|------|------|------------|----------|
| Deployer | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec...f80` | ETH only |
| Operator | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e9...e71` | 1001 TON (사전 예치됨) |
| User1 | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111af...a53` | 1000 TON |
| User2 | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | `0x7c852118a...fd7` | 1000 TON |
| User3 | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` | `0x47e179ec1...c71` | 1000 TON |

---

## 7.3 수동 실행 (3개 터미널)

```bash
# 터미널 1: Anvil 시작
anvil --host 0.0.0.0 --port 8545 --chain-id 31337 --block-time 1
```

```bash
# 터미널 2: 컨트랙트 배포
forge script script/DeployLotteryDemo.s.sol --via-ir \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast

# 출력에서 DEPLOYMENT_JSON_START ~ END 사이의 JSON을 복사하여
# demo-frontend/src/deployment.json 으로 저장

# 시뇨리지 초기화 (First-Call Trap 해소, 필수!)
sleep 2
cast send <lotteryCandidate_address> "updateSeigniorage()" \
  --rpc-url http://localhost:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

```bash
# 터미널 3: 프론트엔드 시작
cd demo-frontend
npm install
npm run dev
# → http://localhost:5173 접속
```

---

## 7.4 MetaMask 설정

1. **네트워크 추가:**
   - Network Name: `Anvil`
   - RPC URL: `http://localhost:8545`
   - Chain ID: `31337`
   - Currency Symbol: `ETH`

2. **테스트 계정 import:**
   - Settings → Import Account → 프라이빗 키 붙여넣기

---

## 7.5 Foundry 빌드 및 테스트

```bash
# 컨트랙트 빌드
forge build                          # 또는 make build

# 전체 테스트 실행
forge test                           # 또는 make test

# LotteryCandidate 테스트만 (상세 로그)
forge test --match-contract LotteryCandidateScenarioTest -vvv

# V3 테스트만
forge test --match-path "test/v3/*"  # 또는 make test-v3

# E2E 테스트 (Go, 제네시스 파일 필요)
make devnet-allocs-offline           # 제네시스 생성
make test-e2e                        # E2E 테스트 실행
```

---

## 7.6 환경 변수

**파일:** `.env.example`

| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| `INFURA_API_KEY` | Infura API 키 | 플레이스홀더 |
| `ETHERSCAN_API_KEY` | Etherscan API 키 | 플레이스홀더 |
| `COINMARKETCAP_API_KEY` | CoinMarketCap API 키 | 플레이스홀더 |
| `ETH_NODE_URI_localhost` | 로컬 RPC URL | `http://127.0.0.1:8545/` |
| `ETH_NODE_URI_MAINNET` | 이더리움 메인넷 RPC | Infura URL |
| `ETH_NODE_URI_sepolia` | Sepolia 테스트넷 RPC | Infura URL |
| `ETH_NODE_URI_TITAN_GOERLI` | Titan L2 Goerli RPC | 고정 URL |
| `ETH_NODE_URI_THANOS_SEPOLIA` | Thanos L2 Sepolia RPC | 고정 URL |
| `ADMIN` | 관리자 프라이빗 키 | Anvil Account #0 |
| `DEPLOYER` | 배포자 프라이빗 키 | Anvil Account #0 |
| `DEPLOYER_PRIVATE_KEY` | 배포자 프라이빗 키 | Anvil Account #0 |
| `SEPOLIA_PRIVATE_KEY` | Sepolia 테스트넷 키 | 플레이스홀더 |
| `AGENDA_KEY` | 안건 전용 키 | 플레이스홀더 |

---

## 7.7 Makefile 주요 명령어

```bash
make build                  # 컨트랙트 빌드
make test                   # 전체 Solidity 테스트
make test-v3                # V3 테스트만
make clean                  # 빌드 아티팩트 정리
make devnet-allocs-offline  # 제네시스 파일 생성
make test-e2e               # E2E 테스트 실행
make test-e2e-unit          # E2E 유닛 테스트 (제네시스 불필요)
make devnet-status          # 개발넷 상태 확인
make devnet-clean           # 개발넷 상태 초기화
make help                   # 도움말
```

---

## 7.8 CI/CD 흐름

> **확인 필요:** 현재 CI/CD 파이프라인(GitHub Actions 등)이 별도로 구성되어 있는지 확인 필요. 리포지토리에 `.github/workflows` 디렉토리 존재 여부 확인할 것.

---

[다음: 보안 고려사항 →](./08-security.md)
