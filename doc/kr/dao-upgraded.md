# DAOCommitteeProxy에서 변경되는 사항들

## DAOCommitteProxy의 Contract 구조의 변화

기존의 Proxy구조는 한 로직만 바라볼 수 있어서 DAO의 로직추가가 제한적이라는 문제점이 있었습니다.
기존 TONStaking이 TON StakingV2로 업그레이드됨에 따라서 추가되야하는 함수들이 있는데 함수들을 추가하기 위해서는 기존의 기능을 삭제해야하는 상황까지왔습니다. 
그래서 저희는 Proxy의 구조를 변경하여서 기존의 기능을 계속 유지하면서 기능을 추가할 수 있고 앞으로도 계속 업그레이드 가능한 구조로 변경하였습니다.

> 기존 DAO 구조
![DAO_Original](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/DAO_Original.jpg)


> 변경된 DAO 구조
![DAO_Changed](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/DAO_Changed.jpg)


## 기존 DAOCommittee에서 변경점

### 1. createLayer2Candidate 함수 추가
TON StakingV2에서 기존 Candidate와 다른 Layer2Candidate가 추가되었습니다.
그에 따라서 DAO에서 해당 Layer2Candidate를 추가할 수 있도록 하였습니다.
자세한 내용은 [다음페이지](https://github.com/tokamak-network/ton-staking-v2/blob/codeReview/docs/en/ton-staking-v2.md#add-layer2candidate)에서 확인하실 수 있습니다.

### 2. setCandidateAddOnFactory 함수 추가
TON StakingV2에서 CandidateAddOn 추가되면서 해당 함수에서 사용하는 candidateAddOnFactory를 설정하여야합니다.
그에 따라서 해당 값을 설정할 수 있는 setCandidateAddOnFactory 함수가 추가 되었습니다.

### 3. setLayer2Manager 함수 추가
createLayer2Candidate함수를 통해서 Layer2Candidate를 생성하고자할때 해당 함수를 호출할 수 있는 권한은 Layer2ManagerContract에서만 호출할 수 있도록 하였습니다.
Layer2Manager주소를 설정하여서 해당 호출이 Layer2ManagerContract에서 호출이 되었는지 체크합니다.

### 4. setTargetSetLayer2Manager 함수 추가
TONStakingV2로 업데이트 되면서 SeigManagerContract에서 Layer2ManagerContract와 상호작용하게 되었습니다.
그래서 SeigManagerContract에서 Layer2ManagerContract의 함수를 호출하기 위해서 layer2Manager를 설정할 수 있도록 하였습니다.

### 5. setTargetSetL1BridgeRegistry 함수 추가
TONStakingV2로 업데이트 되면서 SeigManagerContract에 L1BridgeRegistryContract와 상호작용하게 되었습니다.
그래서 SeigManagerContract에 L1BridgeRegistryContract의 함수를 호출하기 위해서 l1BridgeRegistry를 설정할 수 있도록 하였습니다.
 
### 6. setTargetLayer2StartBlock 함수 추가
TON StakingV2로 업데이트되면서 Layer2의 특정 블록을 기준점으로 지정할 수 있게 되었습니다. 
이 기준점 이후부터 시뇨리지(seigniorage)를 계산할 수 있게 되었습니다. 
이 기능을 위해 기준이 되는 블록의 값을 설정하는 함수가 추가되었습니다.

### 7. setTargetSetImplementation2 함수 추가
DAO가 Owner 역할을 하는 Proxy Contract의 로직을 Agenda를 통해 수정할 수 있도록 함수를 추가했습니다.

### 8. setTargetSetSelectorImplementations2 함수 추가
DAO가 Owner 역할을 하는 Proxy Contract의 로직 function을 Agenda를 통해서 관리할 수 있도록 함수를 추가하였습니다.


# Use Case

## For User who want to become a candidate
Tokamak DAOCommittee의 Candidate가 될 수 있는 방법은 다음과 같습니다.

### createCandidate 함수 호출
Candidate가 되고 싶은 누구나 호출할 수 있습니다.
해당 함수를 호출한 msg.sender의 주소가 operator가 되고 operator로 정상적인 활동을 하기위해서는 만들어진 Candidate에 operator가 1000.1TON 이상 deposit하여야합니다.
![createCandidate](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/createCandidate.jpg)


### createCandidateAddOn 함수 호출
Layer2Candidate가 되고 싶은 누구나 호출할 수 있지만 L2Registry에 등록된 SystemConfig에 대해서만 registerCandidateAddOn 등록 가능합니다.
registerCandidateAddOn 등록시에는 operator가 등록과 동시에 1000.1TON이상을 Deposit하여서 바로 operator로 정상적인 활동이 가능합니다.
![createCandidateAddOn](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/createCandidateAddOn.jpg)


### registerLayer2CandidateByOwner 함수 호출
자신만의 Layer2를 DAO의 Candidate로 등록하고 싶을 때 사용하는 방법입니다.
자신의 Layer2가 있다면 registerLayer2CandidateByOwner 함수가 실행되도록 DAO Agenda로 제안을 하고, 이 제안이 통과되어 Agenda가 실행되면 해당 Layer2가 Candidate로 등록됩니다.
Candidate로 등록 후, Candidate로 활동하기 위해서는 1000.1 TON 이상의 deposit이 필요합니다.
![registerLayer2CandidateByOwner](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/registerLayer2CandidateByOwner.jpg)


## For Candidate of DAOCommittee
Candidate들은 changeMember와 setMemoOnCandidate, setMemoOnCandidateContract 함수를 호출할 수 있습니다.

changeMember 함수는 자신이 다른 member들보다 Stake된 TON의 양이 많을 경우, 다른 member대신 자신이 member가 될 수 있습니다.
그리고 setMemoOnCandidate와 setMemoOnCandidateContract를 통해서 자신의 Candidate Contract에 등록된 memo값을 수정할 수 있습니다.

![ForCandidate](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/ForCandidate.jpg)



## For everyone
모든 유저들은 onApprove와 endAgendaVoting, executeAgenda, updateSeigniorage를 사용할 수 있습니다.

onApprove 함수는 Agenda를 생성할 때 사용하는 함수입니다. 유저들은 직접 onApprove 함수를 호출하지 않고, TONContract의 ApproveAndCall을 통해 Agenda를 생성할 수 있습니다.
endAgendaVoting 함수는 Agenda의 투표 시간이 종료되었을 때 실행되며, 해당 Agenda의 Status와 Result 상태를 갱신합니다.
executeAgenda 함수는 Agenda의 투표가 끝나고 Status가 WAITING_EXEC이며 Result가 ACCEPT일 때 실행 가능합니다. 이 함수를 호출하면 통과된 Agenda의 함수들이 실행됩니다.
updateSeigniorage 함수는 실행 시 입력된 Candidate 주소의 Seigniorage를 갱신하는 함수입니다.

![ForEveryone](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/ForEveryone.jpg)


## For Member of DAOCommittee
Member들은 retireMember와 castVote, claimActivityReward 함수들을 사용할 수 있습니다.

retireMember 함수는 Member들이 Member 역할을 은퇴하고 Candidate 역할로 돌아갈 때 사용합니다.
castVote 함수는 Member들이 Agenda에 대해 투표할 때 사용합니다. 이 함수를 통해 Agenda에 대한 찬성, 반대, 중립 의견을 comment와 함께 표현할 수 있습니다.
claimActivityReward 함수는 현재 Member와 과거 Member였던 Candidate들이 호출할 수 있습니다. Member들은 그 역할 수행에 대한 보상(reward)을 받게 되는데, 이 보상은 Member로 활동한 시간과 activityRewardPerSecond 값에 따라 결정됩니다. 
이 보상을 받기 위해서는 claimActivityReward 함수를 호출해야 합니다.

![ForMember](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/ForMember.jpg)


# Contract Details

## DAOCommittee

- 개요
    - 토카막 네트워크에서 운영하는 DAO 컨트랙트입니다.
    - 로직은 DAOCommittee_V1, DAOCommitteeOwner으로 구성되어있습니다.
    - 추후 업그레이드를 고려하여서 Proxy구조를 변경하였습니다.
    - 누구나 Candidate가 될 수 있습니다.
    - Candidate 중 Staking이 많이 되어있는 순으로 Member가 될 수 있습니다.
- 권한
    - Owner : 오너는 DAOCommitteeContract 자신이며, Agenda를 통해서 로직 업그레이드와 로직 실행을 할 수 있습니다.
    - DAOContract는 TON, WTON, SeigManager, DepositManager의 Owner입니다.
    - Candidate : 누구나 Candidate가 될 수 있으며 Candidate가 되면 Candidate들이 사용할 수 있는 함수들을 사용할 수 있습니다.
    - Member : Candidate들 중 Member보다 TON Staking이 더 많이 되어있으면 해당 Member를 Candidate로 변경하고 자신이 Member가 될 수 있습니다. Member가 되면 Member들이 사용할 수 있는 함수를 사용할 수 있습니다.
- 스토리지
    ```
    struct CandidateInfo {
        address candidateContract;
        uint256 indexMembers;
        uint128 memberJoinedTime;
        uint128 rewardPeriod;
        uint128 claimedTimestamp;
    }

    address public ton;
    IDAOVault public daoVault;
    IDAOAgendaManager public agendaManager;
    ICandidateFactory public candidateFactory;
    ILayer2Registry public layer2Registry;
    ISeigManager public seigManager;

    address[] public candidates;
    address[] public members;
    uint256 public maxMember;

    // candidate EOA => candidate information
    mapping(address => CandidateInfo) internal _candidateInfos;
    uint256 public quorum;
    uint256 public activityRewardPerSecond;
    
    address internal _implementation;
    bool public pauseProxy;

    // Migrate. Previous layer information
    mapping(address => CandidateInfo2) internal _oldCandidateInfos;

    struct CandidateInfo2 {
        address candidateContract;
        address newCandidate;
        uint256 indexMembers;
        uint128 memberJoinedTime;
        uint128 rewardPeriod;
        uint128 claimedTimestamp;
    }

    address public wton;
    address public layer2Manager;
    address public candidateAddOnFactory;
    ```



# How to Test

## Build
Clone the repository
```
git clone https://github.com/tokamak-network/ton-staking-v2.git
```


Checkout the branch
```
git checkout NewDAOStructure
```

install the repo
```
npm install

npx hardhat compile
```

## Set the environment
setting the env
```
# copy to .env
cp .env.example .env

# open file
vi .env

# ..need to edit and save
export ETH_NODE_URI_MAINNET=${MainnetKey}
export ETH_NODE_URI_GOERLI=${GoerliKey}
export ETH_NODE_URI_sepolia=${SepoliaKey}
export ETHERSCAN_API_KEY=${Etherscan_APIKey}
export INFURA_API_KEY=${Infura_APIKey}
export COINMARKETCAP_API_KEY=${CoinMarketcapKey}
export PRIVATE_KEY=${PrivateKey}
export DEPLOYER=${DeployerKey}
```


## Mainnet Test

change setting hardhat.config.ts 

```
hardhat: {
  forking: {
    // mainnet or sepolia
    url: `${process.env.ETH_NODE_URI_MAINNET}`,
    blockNumber: 20425200
    // url: `${process.env.ETH_NODE_URI_sepolia}`,
    // blockNumber: 6000000
  },
  allowUnlimitedContractSize: true,
  // deploy: ['deploy-migration']
},
```

Test code execution command

```
# Proxy upgraded test
npx hardhat test test/agenda/12.UpgradeDAOProxy-test-mainnet.js

# registerLayer2CandidateByOwner Test
npx hardhat test test/agenda/18.Layer2CandidateTest-mainnet.js
```

## Sepolia Test
change setting hardhat.config.ts 
```
hardhat: {
  forking: {
    // mainnet or sepolia
    // url: `${process.env.ETH_NODE_URI_MAINNET}`,
    // blockNumber: 20425200
    url: `${process.env.ETH_NODE_URI_sepolia}`,
    blockNumber: 6000000
  },
  allowUnlimitedContractSize: true,
  // deploy: ['deploy-migration']
},
```

Test code execution command
```
npx hardhat test test/agenda/13.UpgradeDAOProxy-test-sepolia.js
```