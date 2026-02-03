# Deployment Guide

DelegateStakingV3Upgradeable 배포 가이드입니다.

## 목차

1. [사전 요구사항](#사전-요구사항)
2. [환경 설정](#환경-설정)
3. [로컬 배포](#로컬-배포)
4. [테스트넷 배포](#테스트넷-배포)
5. [메인넷 배포](#메인넷-배포)
6. [업그레이드](#업그레이드)
7. [검증](#검증)
8. [배포 후 설정](#배포-후-설정)

## 사전 요구사항

### 필수 도구

```bash
# Foundry 설치
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 버전 확인
forge --version  # >= 0.2.0
cast --version
```

### 환경 변수

```bash
cp .env.example .env
```

`.env` 파일 설정:

```env
# RPC URLs
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# 배포자 개인키 (0x 접두사 제외)
PRIVATE_KEY=your_private_key_here

# Etherscan API Key (컨트랙트 검증용)
ETHERSCAN_API_KEY=your_etherscan_api_key

# V3 컨트랙트 주소 (메인넷/테스트넷)
TON_ADDRESS=0x...
WTON_ADDRESS=0x...
SEIG_MANAGER_ADDRESS=0x...
LAYER2_MANAGER_ADDRESS=0x...
```

### 필요한 자금

- 배포: ~0.05 ETH (가스비)
- 프록시 배포 포함 시: ~0.08 ETH

## 로컬 배포

### Anvil 실행

```bash
# 터미널 1: Anvil 로컬 노드 실행
anvil --fork-url $MAINNET_RPC_URL
```

### 배포 스크립트 실행

```bash
# 터미널 2: 로컬 배포
forge script script/DeployLocalV3.s.sol \
    --rpc-url http://localhost:8545 \
    --broadcast \
    -vvvv
```

### 배포 확인

```bash
# 배포된 주소 확인
cat broadcast/DeployLocalV3.s.sol/31337/run-latest.json | jq '.transactions[].contractAddress'
```

## 테스트넷 배포 (Sepolia)

### 1. 배포 스크립트 생성

```solidity
// script/DeploySepolia.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DelegateStakingV3Upgradeable} from "../contracts/DelegateStakingV3Upgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeploySepolia is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Sepolia V3 컨트랙트 주소 (실제 주소로 변경 필요)
        address ton = vm.envAddress("TON_ADDRESS");
        address wton = vm.envAddress("WTON_ADDRESS");
        address seigManager = vm.envAddress("SEIG_MANAGER_ADDRESS");
        address layer2Manager = vm.envAddress("LAYER2_MANAGER_ADDRESS");

        uint256 unbondingPeriod = 7 days;

        vm.startBroadcast(deployerPrivateKey);

        // 1. Implementation 배포
        DelegateStakingV3Upgradeable implementation = new DelegateStakingV3Upgradeable();

        // 2. Proxy 배포 및 초기화
        bytes memory initData = abi.encodeWithSelector(
            DelegateStakingV3Upgradeable.initialize.selector,
            ton,
            wton,
            seigManager,
            layer2Manager,
            unbondingPeriod,
            deployer // owner
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        vm.stopBroadcast();

        // 배포된 주소 출력
        console.log("Implementation:", address(implementation));
        console.log("Proxy:", address(proxy));
        console.log("Owner:", deployer);
    }
}
```

### 2. 배포 실행

```bash
# 테스트넷 배포
forge script script/DeploySepolia.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    -vvvv
```

### 3. 배포 확인

```bash
# 컨트랙트 버전 확인
cast call $PROXY_ADDRESS "version()(string)" --rpc-url $SEPOLIA_RPC_URL
# 결과: "1.3.0"

# Owner 확인
cast call $PROXY_ADDRESS "owner()(address)" --rpc-url $SEPOLIA_RPC_URL
```

## 메인넷 배포

### 1. 사전 체크리스트

- [ ] 모든 테스트 통과 (`forge test`)
- [ ] 코드 감사 완료
- [ ] 멀티시그 지갑 준비 (owner 용)
- [ ] 배포 스크립트 테스트넷 검증 완료
- [ ] 환경 변수 메인넷 주소로 설정
- [ ] 충분한 ETH 잔액 확인

### 2. 배포 스크립트

```solidity
// script/DeployMainnet.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DelegateStakingV3Upgradeable} from "../contracts/DelegateStakingV3Upgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMainnet is Script {
    // Tokamak Mainnet Addresses
    address constant TON = 0x2be5e8c109e2197D077D13A82dAead6a9b3433C5;
    address constant WTON = 0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2;

    // V3 컨트랙트 주소 (실제 배포 후 업데이트 필요)
    address constant SEIG_MANAGER = address(0); // TODO: V3 배포 후 설정
    address constant LAYER2_MANAGER = address(0); // TODO: V3 배포 후 설정

    // 멀티시그 주소 (owner)
    address constant MULTISIG = address(0); // TODO: 멀티시그 주소 설정

    uint256 constant UNBONDING_PERIOD = 7 days;

    function run() external {
        require(MULTISIG != address(0), "Set MULTISIG address");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Implementation 배포
        DelegateStakingV3Upgradeable implementation = new DelegateStakingV3Upgradeable();

        // 2. Proxy 배포 (owner를 멀티시그로 설정)
        bytes memory initData = abi.encodeWithSelector(
            DelegateStakingV3Upgradeable.initialize.selector,
            TON,
            WTON,
            SEIG_MANAGER,
            LAYER2_MANAGER,
            UNBONDING_PERIOD,
            MULTISIG // owner = multisig
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        vm.stopBroadcast();

        console.log("=== Mainnet Deployment ===");
        console.log("Implementation:", address(implementation));
        console.log("Proxy:", address(proxy));
        console.log("Owner (Multisig):", MULTISIG);
    }
}
```

### 3. 배포 실행

```bash
# 시뮬레이션 먼저 실행
forge script script/DeployMainnet.s.sol \
    --rpc-url $MAINNET_RPC_URL \
    -vvvv

# 실제 배포 (--broadcast 추가)
forge script script/DeployMainnet.s.sol \
    --rpc-url $MAINNET_RPC_URL \
    --broadcast \
    --verify \
    --slow \
    -vvvv
```

### 4. 컨트랙트 검증

```bash
# Etherscan 검증 (자동 실패 시 수동)
forge verify-contract \
    --chain mainnet \
    --watch \
    $IMPLEMENTATION_ADDRESS \
    contracts/DelegateStakingV3Upgradeable.sol:DelegateStakingV3Upgradeable

# 프록시 검증
forge verify-contract \
    --chain mainnet \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,bytes)" $IMPLEMENTATION_ADDRESS $INIT_DATA) \
    $PROXY_ADDRESS \
    lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy
```

## 업그레이드

### 1. 새 Implementation 배포

```solidity
// script/Upgrade.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DelegateStakingV3Upgradeable} from "../contracts/DelegateStakingV3Upgradeable.sol";

contract Upgrade is Script {
    address constant PROXY = address(0); // TODO: 프록시 주소

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 1. 새 Implementation 배포
        DelegateStakingV3Upgradeable newImplementation = new DelegateStakingV3Upgradeable();

        // 2. 업그레이드 (owner만 가능)
        DelegateStakingV3Upgradeable proxy = DelegateStakingV3Upgradeable(PROXY);
        proxy.upgradeToAndCall(address(newImplementation), "");

        vm.stopBroadcast();

        console.log("New Implementation:", address(newImplementation));
        console.log("New Version:", proxy.version());
    }
}
```

### 2. 업그레이드 실행

```bash
# 시뮬레이션
forge script script/Upgrade.s.sol --rpc-url $MAINNET_RPC_URL -vvvv

# 실행 (멀티시그 트랜잭션 필요)
forge script script/Upgrade.s.sol --rpc-url $MAINNET_RPC_URL --broadcast
```

## 검증

### 배포 후 검증 스크립트

```bash
#!/bin/bash
# verify-deployment.sh

PROXY_ADDRESS=$1
RPC_URL=$2

echo "=== Deployment Verification ==="

# 1. Version 확인
VERSION=$(cast call $PROXY_ADDRESS "version()(string)" --rpc-url $RPC_URL)
echo "Version: $VERSION"

# 2. Owner 확인
OWNER=$(cast call $PROXY_ADDRESS "owner()(address)" --rpc-url $RPC_URL)
echo "Owner: $OWNER"

# 3. 상수 확인
MAX_COMMISSION=$(cast call $PROXY_ADDRESS "MAX_COMMISSION()(uint256)" --rpc-url $RPC_URL)
echo "MAX_COMMISSION: $MAX_COMMISSION"

UNBONDING=$(cast call $PROXY_ADDRESS "unbondingPeriod()(uint256)" --rpc-url $RPC_URL)
echo "Unbonding Period: $UNBONDING seconds"

# 4. Pausable 상태 확인
PAUSED=$(cast call $PROXY_ADDRESS "paused()(bool)" --rpc-url $RPC_URL)
echo "Paused: $PAUSED"

# 5. TON/WTON 주소 확인
TON=$(cast call $PROXY_ADDRESS "ton()(address)" --rpc-url $RPC_URL)
WTON=$(cast call $PROXY_ADDRESS "wton()(address)" --rpc-url $RPC_URL)
echo "TON: $TON"
echo "WTON: $WTON"

echo "=== Verification Complete ==="
```

실행:

```bash
chmod +x verify-deployment.sh
./verify-deployment.sh $PROXY_ADDRESS $MAINNET_RPC_URL
```

## 배포 후 설정

### 1. V3 컨트랙트 연동 설정 (Owner)

```bash
# SeigManager 설정
cast send $PROXY_ADDRESS \
    "setSeigManager(address)" $SEIG_MANAGER_ADDRESS \
    --private-key $OWNER_KEY \
    --rpc-url $RPC_URL

# Layer2Manager 설정
cast send $PROXY_ADDRESS \
    "setLayer2Manager(address)" $LAYER2_MANAGER_ADDRESS \
    --private-key $OWNER_KEY \
    --rpc-url $RPC_URL
```

### 2. Guardian 설정

```bash
# 기본 Guardian 설정
cast send $PROXY_ADDRESS \
    "setDefaultGuardian(address)" $GUARDIAN_ADDRESS \
    --private-key $OWNER_KEY \
    --rpc-url $RPC_URL
```

### 3. 파라미터 조정 (필요시)

```bash
# 최소 스테이크 조정
cast send $PROXY_ADDRESS \
    "setMinStakeAmount(uint256)" 200000000000000000000 \
    --private-key $OWNER_KEY \
    --rpc-url $RPC_URL  # 200 TON

# 언본딩 기간 조정 (7일)
cast send $PROXY_ADDRESS \
    "setUnbondingPeriod(uint256)" 604800 \
    --private-key $OWNER_KEY \
    --rpc-url $RPC_URL
```

### 4. 운영 모니터링 설정

이벤트 모니터링 스크립트:

```bash
# 스테이킹 이벤트 모니터링
cast logs \
    --address $PROXY_ADDRESS \
    --from-block latest \
    "Staked(address,address,uint256)" \
    --rpc-url $RPC_URL

# 비상 이벤트 모니터링
cast logs \
    --address $PROXY_ADDRESS \
    --from-block latest \
    "EmergencyActivated(address,address,uint256)" \
    --rpc-url $RPC_URL
```

## 문제 해결

### 가스 부족

```bash
# 가스 예측
forge script script/DeployMainnet.s.sol \
    --rpc-url $MAINNET_RPC_URL \
    --gas-estimate
```

### 논스 문제

```bash
# 현재 논스 확인
cast nonce $DEPLOYER_ADDRESS --rpc-url $RPC_URL

# 특정 논스로 재시도
forge script ... --nonce $NONCE
```

### 검증 실패

```bash
# 컴파일러 버전 확인
forge build --force

# 수동 검증 (flatten 사용)
forge flatten contracts/DelegateStakingV3Upgradeable.sol > flat.sol
# Etherscan에서 직접 검증
```

## 체크리스트

### 배포 전

- [ ] 환경 변수 설정 완료
- [ ] 테스트 전체 통과
- [ ] 시뮬레이션 성공
- [ ] 멀티시그 주소 확인
- [ ] 가스비 충분

### 배포 후

- [ ] 컨트랙트 검증 완료
- [ ] 버전 확인
- [ ] Owner 확인
- [ ] V3 연동 설정
- [ ] Guardian 설정
- [ ] 모니터링 설정
- [ ] 문서 업데이트
