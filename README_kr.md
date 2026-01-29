# TON Staking V3

> Tokamak Network를 위한 V3 스테이킹 스마트 컨트랙트

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.4-blue)](https://soliditylang.org/)

**기반:** [Tokamak Economics Whitepaper V3](https://github.com/tokamak-network/papers) (December 2025)

---

## 🚀 Quick Start

```bash
# submodule과 함께 clone
git clone --recursive https://github.com/tokamak-network/ton-staking-v2.git
cd ton-staking-v2

# 의존성 설치
forge install

# 빌드
forge build

# 테스트 실행
forge test

# E2E 테스트 실행
make devnet-allocs-offline  # 최초 1회만
make test-e2e
```

---

## 📖 TON Staking V3란?

TON Staking V3는 다음을 인센티브화하는 이더리움 L1 스테이킹 시스템입니다:
- 🔒 **L2 시퀀서** - 성과 기반 보상을 통한 안전한 네트워크 운영
- ✅ **검증자** - RAT(Randomized Attention Test)를 통한 지속적인 네트워크 모니터링
- 🎯 **공정한 분배** - 실제 네트워크 기여도(Bridged TON)에 기반한 보상

---

## 🆚 V2 → V3 주요 변경사항

| 항목 | V2 | V3 |
|---------|-----|-----|
| **분배 기준** | L2 TVL | Bridged TON (성과 기반) |
| **분배 함수** | 선형 | 쌍곡선: `y(x) = L·(x/(k+x))` |
| **자격 조건** | 최소 예치금 | 스테이킹 비율: `S_i ≥ θ·B_i` |
| **검증자 보상** | 없음 | `α·y(x) / n` |
| **스테이커 시뇨리지** | ✅ 제공 | ❌ 폐지됨 |

**상세 변경사항:** [V2 to V3 업그레이드 가이드](./docs/specs-kr/08-v2-to-v3-upgrade-guide.md)

---

## 🏗️ 시스템 아키텍처

```
Ethereum L1
├── SeigManager V3 ─────► 시뇨리지 분배 (쌍곡선 함수)
├── DepositManager ─────► TON/WTON 스테이킹
├── Layer2Manager ──────► L2 등록 & Bridged TON 조회
├── L1BridgeRegistry ───► 브릿지/포탈 TVL 추적
├── RAT ────────────────► 검증자 어텐션 테스트 & 슬래싱
└── ValidatorReward ────► 검증자 보상 풀

Optimism L2 (Titan, Thanos 등)
└── DisputeGameFactory ─► Dispute Game 생성 시 RAT 트리거
```

**상세 문서:** [시스템 아키텍처](./docs/specs-kr/02-system-architecture.md)

---

## 📦 핵심 컨트랙트

| 컨트랙트 | 버전 | 역할 |
|----------|---------|------|
| **SeigManagerV3_1** | V1_4 | V3 시뇨리지 분배 |
| **DepositManagerV3** | V1_2 | 스테이킹 관리 |
| **Layer2ManagerV3** | V1_2 | L2 등록 |
| **L1BridgeRegistryV1_2** | V1_2 | 브릿지 TVL 조회 |
| **RAT** | V1 | 검증자 어텐션 테스트 |
| **ValidatorRewardV1** | V1 | 검증자 보상 |

**전체 컨트랙트 상세:** [컨트랙트 구조](./docs/specs-kr/03-contract-structure.md)

---

## 🧪 테스트

### 주요 테스트 명령어
```bash
# 전체 테스트
forge test

# V3 테스트만
forge test --match-path "test/v3/*"

# 특정 컨트랙트
forge test --match-contract RATTest

# E2E 테스트 (Go)
make test-e2e
```

### 테스트 문서
- **[테스트 가이드](./docs/test/README.md)** - 전체 테스트 개요
- **[빠른 명령어](./docs/test/QUICK-COMMANDS.md)** - 모든 테스트 명령어 참조
- **[E2E 테스트](./op-e2e/README.md)** - Go 기반 end-to-end 테스트

**테스트 커버리지:** 175+ 유닛/통합 테스트 + 7개 E2E 테스트

---

## 📚 문서

### 🌐 개발자 가이드 (권장)
**검색 기능이 포함된 완전한 인터랙티브 문서:**
- **한국어:** https://tokamak-network.github.io/ton-staking-v2/ko/
- **English:** https://tokamak-network.github.io/ton-staking-v2/

시스템 아키텍처, 컨트랙트 구조, 액터 가이드, 함수 스펙, V2→V3 업그레이드 가이드 포함.

### 🧪 테스트 문서
- [테스트 가이드](./docs/test/README.md) - 빠른 시작 & 개요
- [빠른 명령어](./docs/test/QUICK-COMMANDS.md) - 명령어 참조
- [E2E 테스트](./op-e2e/README.md) - Go E2E 테스트 가이드
- [Genesis 설정](./op-e2e/GENESIS-SETUP.md) - E2E 환경 설정

---

## 📂 프로젝트 구조

```
src/
├── stake/              # 핵심 스테이킹 로직
│   └── managers/       # SeigManager, DepositManager
├── layer2/             # L2 관리
│   ├── managers/       # Layer2Manager, L1BridgeRegistry
│   └── factory/        # OperatorManagerFactory
├── validator/          # 검증자 시스템
│   ├── RAT.sol         # Randomized Attention Test
│   └── ValidatorRewardV1.sol
└── dao/                # DAO 거버넌스

test/
├── v3/                 # V3 유닛 테스트
│   ├── v3mode/         # V3 모드 테스트
│   ├── scenarios/      # 통합 시나리오
│   └── invariants/     # 불변성 테스트
└── v2mode/             # V2 호환성 테스트

op-e2e/                 # Go E2E 테스트
├── faultproofs/        # RAT 시나리오 테스트
└── e2eutils/           # 테스트 유틸리티
```

---

## 🔧 개발

### 요구사항
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Go 1.22+](https://go.dev/dl/) (E2E 테스트용)
- [Node.js](https://nodejs.org/) (선택사항, 문서용)

### 빌드
```bash
forge build
```

### 테스트
```bash
# Solidity 테스트
forge test

# E2E 테스트
make devnet-allocs-offline  # Genesis 생성 (1회)
make test-e2e
```

### 클린
```bash
forge clean
```

---

## 🔗 외부 라이브러리

| 라이브러리 | 용도 |
|---------|---------|
| [@optimism](https://github.com/ethereum-optimism/optimism) | L1/L2 인터페이스 (SystemConfig, Portal, Bridge) |
| [@openzeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts) | 표준 컨트랙트 (ERC20, Access Control, Math) |
| [@tokamak-dao](https://github.com/tokamak-network/tokamak-dao-contracts) | DAO 거버넌스 컨트랙트 |

### Submodules
```bash
# optimism 라이브러리 업데이트
git submodule update --remote lib/optimism

# 모든 submodule 업데이트
git submodule update --init --recursive
```

---

## 🤝 기여하기

기여를 환영합니다! 다음을 참조해주세요:
- [Contributing Guidelines](./CONTRIBUTING.md) (가능한 경우)
- [Code of Conduct](./CODE_OF_CONDUCT.md) (가능한 경우)

### 개발 워크플로우
1. 레포지토리 Fork
2. Feature 브랜치 생성
3. 변경사항 작성
4. 테스트 실행: `forge test && make test-e2e`
5. Pull request 제출

---

## 📞 지원

- **이슈:** [GitHub Issues](https://github.com/tokamak-network/ton-staking-v2/issues)
- **토론:** [GitHub Discussions](https://github.com/tokamak-network/ton-staking-v2/discussions)
- **문서:** [docs/specs-kr/](./docs/specs-kr/)

---

## 📄 라이선스

MIT License - 자세한 내용은 [LICENSE](./LICENSE) 참조

---

## 🔗 관련 프로젝트

- [Tokamak Network](https://tokamak.network/)
- [Optimism](https://optimism.io/)
- [Tokamak DAO Contracts](https://github.com/tokamak-network/tokamak-dao-contracts)

---

**Built with ❤️ by [Tokamak Network](https://tokamak.network/)**
