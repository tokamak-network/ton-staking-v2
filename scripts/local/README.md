# TON Staking V3 - Local Devnet (Sepolia Fork)

로컬 개발 환경에서 TON Staking V3와 Optimism L2를 테스트하기 위한 Sepolia Fork Devnet 가이드입니다.

---

## 📋 목차

- [시스템 구성](#시스템-구성)
- [사전 준비](#사전-준비)
- [L1/L2 Genesis 생성 (새로운 배포자 주소)](#l1l2-genesis-생성-새로운-배포자-주소)
- [Devnet 시작](#devnet-시작)
- [스크립트 설명](#스크립트-설명)
- [주요 주소](#주요-주소)

---

## 🏗️ 시스템 구성

Sepolia Fork Devnet은 다음으로 구성됩니다:

```
┌─────────────────────────────────────────────────────────────┐
│ L1: Anvil (Sepolia Fork)                                     │
│  - Sepolia 테스트넷 상태를 포크                                │
│  - TON Staking V3 컨트랙트 배포 (allocs)                      │
│  - Optimism L1 컨트랙트 배포 (allocs)                         │
│  - Port: 8546                                                │
└─────────────────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ L2: Optimism Stack (Docker)                                  │
│  - op-geth: L2 실행 레이어 (Port: 9545)                       │
│  - op-node: L2 합의 레이어 (Port: 7545)                       │
│  - op-batcher: L1에 배치 제출                                 │
│  - op-proposer: L2 상태를 L1에 제안                           │
│  - RAT clients (3): 검증자 클라이언트                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 사전 준비

### 필수 도구

```bash
# Foundry 설치
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Docker 설치 (Docker Desktop 권장)
# https://www.docker.com/products/docker-desktop

# jq 설치
brew install jq  # macOS
# apt-get install jq  # Ubuntu
```

### 환경 변수 설정

`.env` 파일에 Sepolia RPC URL을 설정합니다:

```bash
# .env
SEPOLIA_RPC=https://ethereum-sepolia-rpc.publicnode.com
# 또는 Alchemy/Infura API 사용
# SEPOLIA_RPC=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

---

## 🆕 L1/L2 Genesis 생성 (새로운 배포자 주소)

### 개요

완전히 새로운 Optimism 컨트랙트 주소를 생성하려면 새로운 배포자 주소로 genesis를 생성해야 합니다.

### 새로운 배포자 주소

```
0x8836bcfa3D4e83673D6F888A9b1049Ca442CbB0E
```

이 주소는 Sepolia 테스트넷에서 nonce가 0인 새로운 주소입니다.

### 실행 방법

```bash
# 1. L1/L2 Genesis 생성
./scripts/generate-optimism-allocs-new.sh
```

이 스크립트는 다음을 수행합니다:

1. **임시 Anvil 시작** - 배포를 위한 로컬 네트워크
2. **Optimism L1 컨트랙트 배포** - 새로운 배포자 주소로 배포
3. **L1 상태 추출** - 배포된 컨트랙트 코드와 storage
4. **L1 주소 추출** - 배포된 프록시 컨트랙트 주소들
5. **L2 Genesis 생성** - Optimism predeploy 컨트랙트 포함
6. **L2 Bridge 주소 설정** - L1 주소를 L2 predeploy에 연결

### 생성되는 파일

```bash
scripts/config/
├── optimism-allocs-l1-sepolia.json      # L1 컨트랙트 코드 (balance 제외)
├── optimism-addresses-sepolia.json      # L1 프록시 주소 (10개)
└── genesis-l2-sepolia.json              # L2 genesis (2048개 predeploy)
```

### Genesis 자동 설정

스크립트는 L2 genesis를 생성할 때 다음을 자동으로 설정합니다:

#### 1. L2 Bridge 주소 연결
```bash
L2CrossDomainMessenger (0x4200...0007)
└─ storage[0xcf] = L1CrossDomainMessenger 주소

L2StandardBridge (0x4200...0010)
└─ storage[0x04] = L1StandardBridge 주소
```

#### 2. L1Block Fee Scalars (가스비 설정)
```bash
L1Block (0x4200...0015)
├─ storage[0x03] = 1000        # l1FeeScalar (0.1%)
└─ storage[0x05] = 0x3e8000003e8  # baseFeeScalar + blobBaseFeeScalar (각 0.1%)
```

**설정 값:**
- `baseFeeScalar`: 1000 (0.1%) - Calldata 비용 배율
- `blobBaseFeeScalar`: 1000 (0.1%) - Blob 비용 배율
- `l1FeeScalar`: 1000 (0.1%) - 레거시 호환용

**효과:**
- L2 트랜잭션 비용 대폭 절감 (로컬 개발 환경용)
- Rollup cost 오버플로우 방지
- 메인넷 대비 약 1/50 ~ 1/100 비용

### 프로덕션 위치로 복사

```bash
# 2. 생성된 파일들을 사용 위치로 복사
cp scripts/config/optimism-allocs-l1-new.json scripts/config/optimism-allocs-l1.json
cp scripts/config/optimism-addresses-new.json scripts/config/optimism-addresses.json
cp scripts/config/genesis-l2-new.json .devnet/genesis-l2.json
```

### (선택) TON Staking Allocs 재생성

```bash
# 3. TON Staking V3 allocs 생성 (첫 실행 시 또는 컨트랙트 변경 시)
make devnet-allocs-offline
```

---

## 🚀 Devnet 시작

### 전체 환경 시작

```bash
./scripts/local/start-sepolia-fork.sh
```

### 시작 과정

스크립트는 다음 단계를 자동으로 수행합니다:

1. **Anvil 시작** (Sepolia Fork)
   - Sepolia 상태를 포크
   - Port: 8546

2. **Optimism L1 컨트랙트 배포**
   - `optimism-allocs-l1.json`의 코드를 Anvil에 주입
   - 기존 Sepolia 상태를 덮어씀

3. **TON Staking V3 컨트랙트 배포**
   - `allocs-l1-staking-v3.json`의 코드를 주입

4. **L2 서비스 시작** (Docker)
   - op-geth: L2 실행 레이어
   - op-node: L2 합의 레이어
   - op-batcher: 배치 제출
   - op-proposer: 상태 제안
   - RAT clients: 검증자 (3개)

5. **L2 등록**
   - L1BridgeRegistry에 L2 등록
   - Layer2Manager에 CandidateAddOn 등록

6. **검증자 등록**
   - 3개의 검증자 등록 및 스테이킹

7. **테스트 계정 설정**
   - ETH, TON, WTON 배분

### 성공 메시지

```
=== Devnet Started Successfully ===

=== RPC Endpoints ===
L1 (Anvil Sepolia Fork): http://localhost:8546
L2 (op-geth):            http://localhost:9545
L2 Rollup (op-node):     http://localhost:7545

=== Key Addresses ===
TON:            0x...
WTON:           0x...
SeigManager:    0x...
RAT:            0x...
...
```

### Devnet 중지

```bash
./scripts/local/stop-sepolia-fork.sh
```

---

## ⛽ L2 Gas Fee 설정

### 개요

L2 트랜잭션 비용은 **L2 실행 비용 + L1 데이터 비용**으로 구성됩니다:

```
총 비용 = L2 실행 비용 + L1 데이터 비용
         (L2 gas)      (Rollup Cost)
```

### L1Block Predeploy (0x4200...0015)

L1 가스 가격 정보를 저장하는 시스템 컨트랙트입니다.

#### 주요 파라미터

| 파라미터 | 의미 | 단위 | 기본값 |
|---------|------|------|--------|
| `baseFeeScalar` | Calldata 비용 배율 | 1/1,000,000 | 5,227 (0.5%) |
| `blobBaseFeeScalar` | Blob 비용 배율 | 1/1,000,000 | 1,014,213 (101%) |
| `l1FeeScalar` | 레거시 비용 배율 (deprecated) | 1/1,000,000 | 684,000 (68%) |

#### 비용 계산 (Ecotone 업그레이드 이후)

```solidity
// 1. Calldata 비용
l1_calldata_cost = compressed_tx_size × l1_basefee × baseFeeScalar / 1,000,000

// 2. Blob 비용 (EIP-4844)
l1_blob_cost = tx_size × blob_basefee × blobBaseFeeScalar / 1,000,000

// 3. 총 L1 비용
l1_fee = l1_calldata_cost + l1_blob_cost

// 4. 총 트랜잭션 비용
total_cost = (l2_gas_used × l2_gas_price) + l1_fee
```

### Blob Fee란? (EIP-4844)

**Blob (Binary Large Object)**은 L2 데이터를 저렴하게 L1에 제출하기 위한 새로운 데이터 타입입니다.

#### 특징

- **크기**: 128 KB per blob
- **비용**: Calldata 대비 10-100배 저렴
- **수명**: 약 18일 (영구 저장 아님)
- **용도**: Rollup 트랜잭션 배치 데이터

#### Blob Fee 동적 조정

```
블록당 목표: 3 blobs
블록당 최대: 6 blobs

사용량에 따른 가격 조정:
├─ < 3 blobs: blob_basefee 하락 ↓
├─ = 3 blobs: blob_basefee 유지 →
└─ > 3 blobs: blob_basefee 상승 ↑
```

### Genesis 설정

L2 Genesis 파일에서 L1Block storage를 초기화합니다:

```json
{
  "alloc": {
    "0x4200000000000000000000000000000000000015": {
      "storage": {
        // Slot 3: l1FeeScalar (deprecated, 하위 호환용)
        "0x0000...0003": "0x00000000000000000000000000000000000000000000000000000000000a6d40",

        // Slot 5: Ecotone scalars (baseFeeScalar + blobBaseFeeScalar)
        // baseFeeScalar (하위 32비트) + blobBaseFeeScalar (상위 32비트)
        "0x0000...0005": "0x00000000000000000000000000000000000000000000000000000f79c50000146b"
      }
    }
  }
}
```

#### 값 설정 예시

**로컬 개발 (저렴한 비용):**
```bash
baseFeeScalar = 1,000 (0.1%)
blobBaseFeeScalar = 1,000 (0.1%)
```

**Optimism 메인넷 (2026-02-06 기준):**
```bash
baseFeeScalar = 5,227 (0.5%)
blobBaseFeeScalar = 1,014,213 (101%)
```

### 설정 변경

Genesis 파일 생성 시 `generate-optimism-allocs-sepolia.sh` 스크립트가 자동으로 L1Block storage를 설정합니다.

사용자 정의 값으로 변경하려면:

```bash
# 1. Genesis 백업
cp .devnet/genesis-l2.json .devnet/genesis-l2.json.backup

# 2. jq로 storage 수정
jq '.alloc["0x4200000000000000000000000000000000000015"].storage["0x0000000000000000000000000000000000000000000000000000000000000005"] = "0x00000000000000000000000000000000000000000000000000000003e8000003e8"' \
  .devnet/genesis-l2.json > .devnet/genesis-l2.json.new

# 3. 백업과 교체
mv .devnet/genesis-l2.json.new .devnet/genesis-l2.json

# 4. L2 재시작
docker compose -f .devnet-sepolia-fork/docker-compose.yml down -v
./scripts/local/start-sepolia-fork.sh
```

### 런타임 확인

L2가 실행 중일 때 현재 fee scalar 값을 확인할 수 있습니다:

```bash
# baseFeeScalar 확인
cast call 0x4200000000000000000000000000000000000015 \
  "baseFeeScalar()(uint32)" --rpc-url http://localhost:9545

# blobBaseFeeScalar 확인
cast call 0x4200000000000000000000000000000000000015 \
  "blobBaseFeeScalar()(uint32)" --rpc-url http://localhost:9545

# 현재 L1 basefee 확인
cast call 0x4200000000000000000000000000000000000015 \
  "basefee()(uint256)" --rpc-url http://localhost:9545
```

### 트러블슈팅

#### Overflow in total rollup cost 에러

**증상:**
```
ERROR: RPC method eth_sendRawTransaction crashed:
       overflow in total rollup cost: l1Cost
```

**원인:**
- `l1FeeScalar` 값이 너무 큼 (초기화 안 됨)
- Rollup cost 계산 시 오버플로우 발생

**해결:**
```bash
# Genesis 파일의 L1Block storage 확인
jq '.alloc["0x4200000000000000000000000000000000000015"].storage' .devnet/genesis-l2.json

# Slot 3과 Slot 5가 합리적인 값인지 확인
# - Slot 3: ~1,000 - 1,000,000 범위
# - Slot 5: 두 개의 32비트 값이 결합됨

# 잘못된 경우 위의 "설정 변경" 절차 참조
```

---

## 📜 스크립트 설명

### `generate-optimism-allocs-sepolia.sh`

**목적:** Sepolia Fork용 Optimism L1/L2 genesis를 생성합니다.

**단계:**
1. Prerequisites 확인 (forge, jq, anvil)
2. Optimism contracts 빌드
3. Deployment config 생성
4. 임시 Anvil 시작 (포트 9999)
5. Optimism L1 컨트랙트 배포
6. L1 상태 및 주소 추출
7. L2 genesis 업데이트:
   - 기존 L2 genesis 복사
   - L2 Bridge 주소 설정 (L1 주소 연결)
   - **L1Block fee scalars 초기화** ⭐ (오버플로우 방지)

**출력:**
- `optimism-allocs-l1-sepolia.json`: L1 컨트랙트 allocs
- `optimism-addresses-sepolia.json`: L1 주소 맵
- `genesis-l2-sepolia.json`: L2 genesis (fee scalars 설정됨)

**특징:**
- 컨트랙트 코드만 포함 (balance 제외)
- L2 predeploy 2048개 포함
- L1 bridge 주소를 L2에 자동 설정
- **L1Block fee scalars 자동 설정** (baseFee: 0.1%, blobBaseFee: 0.1%)
- Rollup cost 오버플로우 자동 방지

### `start-sepolia-fork.sh`

**목적:** Sepolia Fork 기반 전체 devnet 환경을 시작합니다.

**주요 기능:**
- Anvil로 Sepolia 포크
- L1 컨트랙트 배포 (allocs 주입)
- L2 Docker 컨테이너 시작
- L2 등록 및 검증자 설정
- 테스트 계정 자금 배분

**Port:**
- L1: 8546
- L2: 9545
- L2 Rollup: 7545

### `stop-sepolia-fork.sh`

**목적:** 실행 중인 devnet을 안전하게 중지합니다.

**동작:**
- Anvil 프로세스 종료
- Docker 컨테이너 중지 및 제거
- 로그 파일 정리

---

## 🔑 주요 주소

### 새로운 배포자 주소

```
0x8836bcfa3D4e83673D6F888A9b1049Ca442CbB0E
```

### Anvil 기본 계정

이 계정들은 devnet에서 자동으로 사용됩니다:

| 역할 | 주소 | Anvil Account |
|------|------|---------------|
| Operator | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | #0 |
| Manager | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | #1 |
| Validator 1 | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | #3 |
| Validator 2 | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` | #4 |
| Validator 3 | `0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc` | #5 |
| Personal Test | `0x976EA74026E726554dB657fA54763abd0C3a0aa9` | #6 |

모든 계정은 100,000 ETH + 100,000 TON + 100,000 WTON을 받습니다.

---

## 🐛 트러블슈팅

### Anvil이 시작되지 않음

```bash
# 기존 Anvil 프로세스 확인 및 종료
pkill -f "anvil.*8546"
```

### Docker 컨테이너가 시작되지 않음

```bash
# Docker 상태 확인
docker ps -a

# 컨테이너 로그 확인
docker logs ton-staking-l2-execution
docker logs ton-staking-l2-node

# 완전히 정리 후 재시작
./scripts/local/stop-sepolia-fork.sh
docker system prune -f
./scripts/local/start-sepolia-fork.sh
```

### L2가 L1 deposit을 처리하지 않음

```bash
# op-node 로그 확인
docker logs -f ton-staking-l2-node

# L1 블록 생성 확인
cast block-number --rpc-url http://localhost:8546
```

### Genesis 파일이 없음

```bash
# L2 genesis 재생성
./scripts/generate-optimism-allocs-new.sh

# 파일 복사
cp scripts/config/genesis-l2-new.json .devnet/genesis-l2.json
```

---

## 📚 추가 자료

- [TON Staking V3 Docs](../../docs-site/docs/)
- [Optimism Integration Guide](../../docs-site/docs/12-optimism-integration.md)
- [RAT Client Documentation](../../clients/rat-client-type3/README.md)

---

## 🎯 다음 단계

1. **Web UI 실행**
   ```bash
   cd web-ui
   npm install
   npm run dev
   # Open http://localhost:5173
   ```

2. **E2E 테스트 실행**
   ```bash
   make test-e2e
   ```

3. **RAT 클라이언트 로그 확인**
   ```bash
   docker logs -f ton-staking-rat-client-1
   ```

---

**문제가 있으시면 GitHub Issues에 보고해주세요!**
