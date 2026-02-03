# BLS Signature Fork Tests

이 디렉토리는 BLS 서명 관련 테스트를 포함합니다. BLS precompile(EIP-2537)이 필요한 테스트는 별도 파일로 분리되어 있습니다.

## 테스트 파일 구조

### 일반 테스트 (로컬 실행 가능)
- `FastWithdrawalScenarios.t.sol` - BLS precompile 없이 실행 가능한 Fast Withdrawal 시나리오 테스트
- `FastWithdrawalE2E.t.sol` - BLS precompile 없이 실행 가능한 E2E 테스트 (BLS 테스트는 자동 스킵)

### 메인넷 포크 테스트 (EIP-2537 필요)
- `FastWithdrawalE2EFork.t.sol` - BLS precompile이 필요한 Fast Withdrawal E2E 테스트
- `../BLS12381Fork.t.sol` - BLS12381 라이브러리 메인넷 포크 테스트

## 로컬 테스트 실행

BLS precompile이 없는 로컬 환경에서 실행:

```bash
# 모든 V3 테스트 실행 (BLS 포크 테스트 제외)
make test-v3

# Fast Withdrawal 시나리오 테스트만 실행
forge test --match-path "test/v3/scenarios/FastWithdrawalScenarios.t.sol" -vv

# Fast Withdrawal E2E 테스트 실행 (BLS 테스트는 자동 스킵)
forge test --match-path "test/v3/scenarios/FastWithdrawalE2E.t.sol" -vv

# BLS 라이브러리 기본 테스트 실행
forge test --match-path "test/v3/BLS12381.t.sol" -vv
```

## 메인넷 포크 테스트 실행

EIP-2537 BLS precompile을 사용하는 메인넷 포크 테스트:

### 방법 1: Makefile 사용 (권장)

```bash
# 환경변수로 RPC URL 설정
export MAINNET_RPC_URL="https://eth-mainnet.alchemyapi.io/v2/YOUR_API_KEY"

# 모든 BLS 포크 테스트 실행
make test-bls-fork

# BLS 라이브러리 포크 테스트만 실행
make test-bls-library-fork

# Fast Withdrawal E2E 포크 테스트만 실행
make test-fast-withdrawal-fork

# 또는 직접 RPC URL 전달
make test-bls-fork RPC_URL="https://your-mainnet-rpc-url"

# 공개 RPC 사용 (느릴 수 있음)
make test-bls-fork-public
```

### 방법 2: Forge 직접 사용

```bash
# BLS 라이브러리 포크 테스트
forge test --match-path "test/v3/BLS12381Fork.t.sol" \
  --fork-url https://your-mainnet-rpc-url -vv

# Fast Withdrawal E2E 포크 테스트
forge test --match-path "test/v3/scenarios/FastWithdrawalE2EFork.t.sol" \
  --fork-url https://your-mainnet-rpc-url -vv
```

## EIP-2537 BLS Precompiles

### 주소
- `0x0b` - BLS12_G1ADD
- `0x0c` - BLS12_G1MUL
- `0x0d` - BLS12_G1MSM
- `0x0e` - BLS12_G2ADD
- `0x0f` - BLS12_G2MUL
- `0x10` - BLS12_G2MSM
- `0x11` - BLS12_PAIRING
- `0x12` - BLS12_MAP_FP_TO_G1
- `0x13` - BLS12_MAP_FP2_TO_G2

### 가용성
- **이더리움 메인넷**: Pectra 업그레이드 이후 (2025년 5월 7일 이후) 사용 가능
- **로컬 Foundry**: 아직 구현되지 않음 (2024년 2월 기준)
- **테스트 방법**: 메인넷 포크를 사용하여 테스트

## 테스트 스킵 메커니즘

BLS precompile이 필요한 테스트는 `onlyWithBLSPrecompiles` modifier를 사용하여 precompile이 없는 환경에서 자동으로 스킵됩니다:

```solidity
modifier onlyWithBLSPrecompiles() {
    if (!_isBLSPrecompileAvailable()) {
        return; // Skip test
    }
    _;
}

function test_E2E_WithBLS() public onlyWithBLSPrecompiles {
    // BLS precompile 필요한 테스트 로직
}
```

## RPC 제공자

### Alchemy (권장)
```bash
export MAINNET_RPC_URL="https://eth-mainnet.alchemyapi.io/v2/YOUR_API_KEY"
```

### Infura
```bash
export MAINNET_RPC_URL="https://mainnet.infura.io/v3/YOUR_PROJECT_ID"
```

### 공개 RPC (느릴 수 있음)
```bash
export MAINNET_RPC_URL="https://ethereum-rpc.publicnode.com"
```

## 문제 해결

### 1. RPC Rate Limiting
공개 RPC를 사용하는 경우 rate limiting이 발생할 수 있습니다. Alchemy나 Infura 같은 서비스를 사용하는 것을 권장합니다.

### 2. Fork 실패
메인넷 포크가 실패하는 경우:
- RPC URL이 올바른지 확인
- 인터넷 연결 확인
- API 키가 유효한지 확인

### 3. Precompile 미지원
로컬 Foundry에서 BLS precompile이 지원되지 않는 경우, 테스트는 자동으로 스킵됩니다. 메인넷 포크를 사용하여 테스트하세요.

## 참고 문서

- [EIP-2537: BLS12-381 Precompiles](https://eips.ethereum.org/EIPS/eip-2537)
- [Ethereum Pectra Upgrade](https://ethereum.org/en/roadmap/pectra/)
- [Foundry Fork Testing](https://book.getfoundry.sh/forge/fork-testing)
