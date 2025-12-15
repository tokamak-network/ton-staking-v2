# TON Staking V3

Tokamak Network의 V3 스테이킹 스마트 컨트랙트입니다. Tokamak Economics Whitepaper V2를 기반으로 구현되었습니다.

## 주요 기능

- **V3 시뇨리지 분배**: Bridged TON 기반 쌍곡선 포화 함수
- **검증자 시스템**: ValidatorPool, RAT (Randomized Attention Test)
- **점진적 V2→V3 전환**: λ, r 파라미터를 통한 부드러운 경제 전환

## 설치

### 요구사항

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Clone 및 빌드

```bash
# submodule 포함하여 clone
git clone --recursive https://github.com/tokamak-network/ton-staking-v2.git
cd ton-staking-v2

# 빌드
forge build
```

### 이미 clone한 경우 (submodule 초기화)

```bash
git submodule update --init --recursive
forge build
```

### Submodule 업데이트

```bash
# optimism 라이브러리를 최신으로 업데이트
git submodule update --remote lib/optimism
```

### ⚠️ lib/optimism 서브모듈 주의사항

`lib/optimism` 서브모듈의 커밋을 변경할 때는 **명시적으로 GIT_DIR을 지정**해야 합니다. 그렇지 않으면 상위 저장소(ton-staking-v2)의 HEAD가 변경될 수 있습니다.

**안전한 서브모듈 커밋 변경 방법:**

```bash
# 명시적 GIT_DIR 사용 (권장)
GIT_DIR=.git/modules/lib/optimism GIT_WORK_TREE=lib/optimism git fetch origin feature/ton-staking-v3
GIT_DIR=.git/modules/lib/optimism GIT_WORK_TREE=lib/optimism git checkout <commit-hash>
```

**현재 lib/optimism 설정:**
- Repository: `tokamak-network/optimism`
- Branch: `feature/ton-staking-v3`
- Commit: `2e955e16f` (feat: integrate TON Staking V3 RAT and SeigManager with Optimism dispute system)

## 프로젝트 구조

```
src/
├── stake/              # 스테이킹 핵심 로직
│   ├── managers/       # SeigManager, DepositManager
│   └── tokens/         # Coinage 토큰
├── layer2/             # L2 관리 및 브릿지 연동
├── validator/          # V3 검증자 시스템
│   ├── ValidatorPoolV1.sol
│   └── RAT.sol
└── dao/                # DAO 관련 컨트랙트

lib/
├── optimism/           # tokamak-network/optimism (branch: feature/ton-staking-v3)
├── tokamak-dao-contracts/  # tokamak-network/tokamak-dao-contracts (DAO 거버넌스)
├── openzeppelin-contracts/
└── forge-std/
```

## 테스트

```bash
# 전체 테스트
forge test

# V3 테스트만
forge test --match-path "test/v3/*"

# 특정 테스트
forge test --match-test testUpdateSeigniorageV3
```

## 외부 라이브러리

| 라이브러리 | 용도 |
|-----------|------|
| `@optimism/` | Optimism L1/L2 인터페이스 (SystemConfig, L1StandardBridge, OptimismPortal 등) |
| `@openzeppelin/contracts/` | ERC20, SafeERC20, Math 등 |
| `@tokamak-dao/` | DAO 거버넌스 컨트랙트 (DAOCommitteeProxy, DAOAgendaManager 등) |

### Optimism 인터페이스 사용 예시

```solidity
import { ISystemConfig } from "@optimism/interfaces/L1/ISystemConfig.sol";
import { IL1StandardBridge } from "@optimism/interfaces/L1/IL1StandardBridge.sol";
import { IOptimismPortal2 } from "@optimism/interfaces/L1/IOptimismPortal2.sol";
```

## 문서

상세 설계 문서는 `docs/for-llm-en/` 디렉토리를 참조하세요.

## 라이선스

MIT
