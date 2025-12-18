# V3 배포 가이드

## 개요

TON Staking V3는 두 가지 배포 방식을 지원합니다:

1. **Fork 배포** - 기존 메인넷/세폴리아 환경에 V3 컨트랙트 추가 배포
2. **Full 배포** - 테스트베드를 위한 전체 시스템 배포

## 배포 스크립트

### 1. Fork 배포 (`script/DeployV3Fork.s.sol`)

기존 TON Staking V2가 배포된 네트워크(메인넷/세폴리아)에 V3 컴포넌트만 추가 배포합니다.

#### 포함된 컨트랙트

| 컨트랙트 | 설명 |
|---------|------|
| `DeployV3Fork` | 메인넷 실제 배포용 |
| `DeployV3ForkWithImpersonation` | 메인넷 포크 테스트용 (DAO impersonation 포함) |
| `DeployV3ForkSepolia` | 세폴리아 배포용 |

#### 배포되는 구성요소

**새 구현체 (Implementation)**
- `SeigManagerV1_4` - V3 시뇨리지 분배 로직
- `DepositManagerV1_2` - V3 스테이킹 콜백
- `Layer2ManagerV1_2` - SystemConfig 매핑
- `L1BridgeRegistryV1_2` - Bridged TON 트래킹

**신규 컨트랙트**
- `RAT` (Proxy + Impl) - Random Audit Task (검증자 등록/담보금/슬래싱)
- `ValidatorReward` (Proxy + Impl) - 검증자 보상 분배

#### 실행 명령어

```bash
# 메인넷 실제 배포
forge script script/DeployV3Fork.s.sol:DeployV3Fork \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  -vvvv

# 메인넷 포크 테스트 (DAO impersonation)
forge script script/DeployV3Fork.s.sol:DeployV3ForkWithImpersonation \
  --fork-url $MAINNET_RPC_URL \
  -vvvv

# 세폴리아 배포
forge script script/DeployV3Fork.s.sol:DeployV3ForkSepolia \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  -vvvv
```

#### 환경 변수

```bash
export PRIVATE_KEY=0x...  # 배포자 프라이빗 키
export MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
export SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
```

### 2. Full 배포 (`script/DeployV3Full.s.sol`)

테스트 환경에서 전체 시스템을 처음부터 배포합니다.

#### 포함된 컨트랙트

| 컨트랙트 | 설명 |
|---------|------|
| `DeployV3Full` | 전체 시스템 배포 |
| `DeployV3FullLocal` | 로컬 Anvil 테스트용 |

#### 배포되는 구성요소

- Mock TON / Mock WTON
- 모든 매니저 구현체
- RAT Proxy + Implementation
- ValidatorReward Proxy + Implementation
- 기본 파라미터 설정

#### 실행 명령어

```bash
# 로컬 Anvil 배포
anvil &  # 백그라운드에서 Anvil 실행

forge script script/DeployV3Full.s.sol:DeployV3FullLocal \
  --rpc-url http://localhost:8545 \
  --broadcast \
  -vvvv

# 테스트넷 전체 배포
forge script script/DeployV3Full.s.sol:DeployV3Full \
  --rpc-url $RPC_URL \
  --broadcast \
  -vvvv
```

## DAO 아젠다 요구사항

Fork 배포 시, **프록시 업그레이드는 DAO 승인이 필요**합니다.

배포 스크립트는 새 구현체만 배포하고, 다음 업그레이드는 DAO 아젠다로 진행:

```
1. SeigManager Proxy 업그레이드
   - Proxy: 0x0b55a0f463b6DEFb81c6063973763951712D0E5F (메인넷)
   - New Impl: [배포된 SeigManagerV1_4 주소]

2. DepositManager Proxy 업그레이드
   - Proxy: 0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E (메인넷)
   - New Impl: [배포된 DepositManagerV1_2 주소]

3. Layer2Manager Proxy 업그레이드
   - Proxy: 0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D (메인넷)
   - New Impl: [배포된 Layer2ManagerV1_2 주소]

4. L1BridgeRegistry Proxy 업그레이드
   - Proxy: 0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4 (메인넷)
   - New Impl: [배포된 L1BridgeRegistryV1_2 주소]
```

## 배포 결과 저장

배포 스크립트는 결과를 JSON 파일로 저장합니다:

```
deployments/
├── v3-mainnet-fork.json    # 메인넷 포크 배포 결과
├── v3-sepolia-fork.json    # 세폴리아 포크 배포 결과
└── v3-full.json            # Full 배포 결과
```

### JSON 형식

```json
{
  "seigManagerV1_4Impl": "0x...",
  "depositManagerV1_2Impl": "0x...",
  "layer2ManagerV1_2Impl": "0x...",
  "l1BridgeRegistryV1_2Impl": "0x...",
  "ratProxy": "0x...",
  "ratImpl": "0x...",
  "validatorRewardProxy": "0x...",
  "validatorRewardImpl": "0x..."
}
```

## 배포된 주소 참조

### 메인넷 (기존 V2)

| 컨트랙트 | 주소 |
|---------|------|
| TON | `0x2be5e8c109e2197D077D13A82dAead6a9b3433C5` |
| WTON | `0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2` |
| SeigManager Proxy | `0x0b55a0f463b6DEFb81c6063973763951712D0E5F` |
| DepositManager Proxy | `0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E` |
| Layer2Manager Proxy | `0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D` |
| L1BridgeRegistry Proxy | `0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4` |
| DAO Committee | `0xDD9f0cCc044B0781289Ee318e5971b0139602C26` |

### 세폴리아 (기존 V2)

| 컨트랙트 | 주소 |
|---------|------|
| TON | `0xa30fe40285B8f5c0457DbC3B7C8A280373c40044` |
| WTON | `0x79E0d92670106c85E9067b56B8F674340dCa0Bbd` |
| SeigManager Proxy | `0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7` |
| DepositManager Proxy | `0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F` |
| Layer2Manager Proxy | `0x58B4C2FEf19f5CDdd944AadD8DC99cCC71bfeFDc` |
| L1BridgeRegistry Proxy | `0x2D47fa57101203855b336e9E61BC9da0A6dd0Dbc` |

## 배포 테스트

포크 배포 테스트는 `test/v3/DeployV3Fork.t.sol`에서 수행합니다:

```bash
# 배포 테스트 실행
forge test --match-path test/v3/DeployV3Fork.t.sol -vvv
```

### 테스트 항목

1. **구현체 배포 검증**
   - 모든 V3 구현체가 올바르게 배포되었는지 확인
   - 코드 사이즈 > 0 검증

2. **프록시 초기화 검증**
   - RAT, ValidatorReward 프록시 초기화 확인
   - 올바른 구현체 연결 확인

3. **파라미터 설정 검증**
   - V3 파라미터가 올바르게 설정되었는지 확인

## 배포 후 체크리스트

### Fork 배포 후

- [ ] 모든 구현체 주소 기록
- [ ] RAT, ValidatorReward 프록시 주소 기록
- [ ] DAO 아젠다 생성 (프록시 업그레이드)
- [ ] DAO 투표 완료 후 업그레이드 확인
- [ ] V3 마이그레이션 함수 호출 (`migrateToV3()`)
- [ ] V3 파라미터 설정 확인

### Full 배포 후

- [ ] 모든 컨트랙트 주소 기록
- [ ] RAT, ValidatorReward 초기화 확인
- [ ] 테스트 시나리오 실행

## 트러블슈팅

### 1. "fs_permissions" 오류

배포 결과를 파일로 저장하려면 `foundry.toml`에 권한 설정 필요:

```toml
fs_permissions = [{ access = "read-write", path = "./deployments" }]
```

### 2. 프록시 업그레이드 실패

프록시 업그레이드는 DAO 권한이 필요합니다:
- 테스트 시: `vm.prank(DAO_COMMITTEE)` 사용
- 실제 배포 시: DAO 아젠다 통과 필요

### 3. Initialize 중복 호출 오류

프록시는 한 번만 초기화 가능합니다:
```solidity
error AlreadyInitialized();
```

### 4. Gas 부족

복잡한 배포는 gas가 많이 필요합니다:
```bash
--gas-limit 30000000
```

## 보안 고려사항

1. **프라이빗 키 관리**
   - 환경 변수로 관리
   - `.env` 파일은 `.gitignore`에 포함

2. **배포 검증**
   - 배포 후 반드시 구현체 코드 검증
   - 프록시 연결 상태 확인

3. **초기화 순서**
   - RAT, ValidatorReward는 SeigManager 주소 필요
   - ValidatorReward는 RAT 주소 필요
   - 올바른 순서로 초기화

4. **권한 설정**
   - 프록시 owner 확인
   - 관리자 권한 설정 확인
