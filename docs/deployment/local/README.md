# TON Staking V3 - 로컬 배포 가이드

TON Staking V3를 로컬 환경에서 실행하고 테스트하기 위한 문서 모음입니다.

## 문서 구조

- **[빠른 시작 가이드](./QUICKSTART.md)** - 5분 안에 로컬 환경 구축하기
- **[Validator 설정](./VALIDATOR-SETUP.md)** - Validator 등록 및 RAT Client 실행
- **[구현 상세](./IMPLEMENTATION.md)** - 기술적 세부사항 및 문제 해결 과정
- **[현재 상태](./STATUS.md)** - ⭐ 작동하는 기능, 제한사항, 개선 계획

## 개요

로컬 개발 환경은 다음으로 구성됩니다:

```
┌─────────────────────────────────────────┐
│     TON Staking V3 Local Devnet         │
├─────────────────────────────────────────┤
│                                         │
│  L1 (Anvil)          L2 (Optimism)      │
│  ├─ Chain ID: 900    ├─ Chain ID: 901  │
│  ├─ Port: 8545       ├─ Port: 9545     │
│  └─ TON Staking      └─ op-geth        │
│     Contracts           op-node        │
│                         batcher         │
│                         proposer        │
└─────────────────────────────────────────┘
```

## 빠른 참조

### 필수 도구

- [Foundry](https://book.getfoundry.sh/) - Solidity 개발 툴킷
- [Docker Desktop](https://www.docker.com/products/docker-desktop) - 컨테이너 실행
- [jq](https://stedolan.github.io/jq/) - JSON 처리

### 주요 명령어

```bash
# Genesis 파일 생성
make devnet-allocs-offline

# 환경 시작
make devnet-start

# 상태 확인
make devnet-info

# 환경 중지
make devnet-stop

# 테스트 실행
./scripts/test-local-devnet.sh
```

### RPC 엔드포인트

| 서비스 | URL | Chain ID |
|--------|-----|----------|
| L1 (Anvil) | http://localhost:8545 | 900 |
| L2 (op-geth) | http://localhost:9545 | 901 |
| L2 Rollup | http://localhost:7545 | 901 |

### 주요 컨트랙트

배포 후 `.devnet/addresses.json`에서 확인:

| 컨트랙트 | 역할 |
|---------|------|
| `ton` | TON 토큰 |
| `wton` | Wrapped TON |
| `seigManagerProxy` | V3 시뇨리지 관리 |
| `depositManagerProxy` | 스테이킹 관리 |
| `layer2ManagerProxy` | L2 등록 및 관리 |
| `ratProxy` | Validator RAT |
| `systemConfig` | Optimism SystemConfig |

### 테스트 계정

| 이름 | 주소 | ETH | TON | 용도 |
|------|------|-----|-----|------|
| Account #0 | `0xf39Fd...2266` | 10,000 | - | Batcher/Proposer |
| Account #1 | `0x70997...79C8` | 10,000 | 100,000 | Deployer/Staker |
| Account #2 | `0x90F79...b906` | 10,000 | - | Validator |

전체 계정 정보는 [빠른 시작 가이드](./QUICKSTART.md#테스트-계정)에서 확인하세요.

## 알려진 제한사항

현재 로컬 환경의 알려진 제한사항:

1. **op-node 실행 불가**: SystemConfig의 `unsafeBlockSigner` 초기화 문제로 op-node가 시작되지 않습니다. L1과 L2 execution은 정상 작동합니다.

2. **cast 호환성**: 일부 환경에서 cast 명령이 Anvil과 호환되지 않을 수 있습니다. 이 경우 curl을 사용한 직접 RPC 호출을 권장합니다.

3. **L2 블록 생성**: op-node가 작동하지 않아 L2 블록이 자동으로 생성되지 않습니다. 하지만 L1의 모든 TON Staking 기능은 정상적으로 테스트 가능합니다.

자세한 내용은 [구현 상세](./IMPLEMENTATION.md#발생한-문제와-해결-방법)를 참조하세요.

## 주요 기능 테스트

로컬 환경에서 테스트 가능한 기능:

- ✅ TON/WTON 토큰 조회 및 전송
- ✅ TON ↔ WTON 스왑
- ✅ 컨트랙트 함수 호출 및 상태 조회
- ⚠️ L2 등록 (registerCandidateAddOn 함수 사용 필요)
- ⚠️ 스테이킹 (L2 등록 후 가능)
- ❌ L2 블록 생성 (op-node 이슈)

## 문제 해결

일반적인 문제는 [빠른 시작 가이드 - 문제 해결](./QUICKSTART.md#문제-해결) 섹션을 참조하세요.

심화 문제는 [구현 상세 - 발생한 문제와 해결 방법](./IMPLEMENTATION.md#발생한-문제와-해결-방법)을 확인하세요.

## 다음 단계

로컬 환경 구축 후:

1. **스테이킹 테스트**: Layer2 등록 및 TON 스테이킹 테스트
2. **웹 UI** (준비 중): 웹 인터페이스를 통한 시각적 테스트
3. **RAT Client** (준비 중): Validator 클라이언트 실행
4. **모니터링** (준비 중): 실시간 상태 모니터링

## 참고 자료

- [TON Staking V3 문서](https://tokamak-network.github.io/ton-staking-v2/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Optimism Specs](https://github.com/ethereum-optimism/specs)
