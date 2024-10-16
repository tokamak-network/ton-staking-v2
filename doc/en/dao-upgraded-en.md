# What's changing in DAOCommitteeProxy

## Changes to the Contract structure of DAOCommitteProxy

The existing Proxy structure had a problem in that it could only refer to one logic, so the addition of DAO logic was limited. As TON Staking was upgraded to TON StakingV2, functions needed to be added, and the situation arose where existing functions had to be deleted. Therefore, we changed the Proxy structure to maintain existing functions while adding new functions, and improved the structure to enable continuous upgrades in the future.

> Original DAO structure
![DAO_Original](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/DAO_Original.jpg)


> Changed DAO structure
![DAO_Changed](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/DAO_Changed.jpg)


## Changes from the existing DAOCommittee

### 1. Added createLayer2Candidate function
In TON StakingV2, a Layer2Candidate different from the existing Candidate has been added.
Accordingly, the Layer2Candidate can be added in the DAO.
For more information,You can check it at the following [Link](https://github.com/tokamak-network/ton-staking-v2/blob/codeReview/docs/en/ton-staking-v2.md#add-layer2candidate).

### 2. Added setCandidateAddOnFactory function
With the addition of CandidateAddOn in TON StakingV2, the candidateAddOnFactory used in the function must be set. Accordingly, a new function setCandidateAddOnFactory has been added to set the value.

### 3. Added setLayer2Manager function
When creating a Layer2Candidate via the createLayer2Candidate function, the permission to call the function is restricted to only Layer2ManagerContract. Set the Layer2Manager address to verify that the call was actually made from Layer2ManagerContract.

### 4. Added setTargetSetLayer2Manager function
With the update to TON StakingV2, SeigManagerContract now interacts with Layer2ManagerContract. 
Accordingly, we have enabled layer2Manager to be set up so that SeigManagerContract can call functions of Layer2ManagerContract.

### 5. Added setTargetSetL1BridgeRegistry function
With the update to TON StakingV2, SeigManagerContract now interacts with L1BridgeRegistryContract. 
Accordingly, we have enabled setting l1BridgeRegistry so that SeigManagerContract can call functions of L1BridgeRegistryContract.
 
### 6. Added setTargetLayer2StartBlock function
With the update to TON StakingV2, it is now possible to designate a specific block in Layer2 as a reference point.
From this reference point onwards, seigniorage can be calculated.
For this function, a function that sets the value of the reference block has been added.

### 7. Added setTargetSetImplementation2 function
Added a function to allow modifying the logic of a Proxy Contract where the DAO acts as the Owner via the Agenda.

### 8. Added setTargetSetSelectorImplementations2 function
We added a function to enable DAO to manage the logic function of the Proxy Contract, which acts as the Owner, through the Agenda.


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
자신만의 Layer2를 DAO의 Candidate로 등록하고 싶을때 사용하는 방법입니다.
자신의 Layer2가 있다면 registerLayer2CandidateByOwner함수가 실행되게 DAO Agenda로 건의를 하고 통과가 되어서 Agenda가 실행이 되면 해당 Layer2가 Candidate로 등록이 됩니다.
Candidate로 등록 후. Candidate로 활동을 하기 위해서는 1000.1TON 이상 deposit이 필요합니다.
![registerLayer2CandidateByOwner](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/registerLayer2CandidateByOwner.jpg)


## For Candidate of DAOCommittee
Candidate들은 changeMember와 setMemoOnCandidate, setMemoOnCandidateContract 함수를 호출할 수 있습니다.

changeMember 함수는 자신이 다른 member들보다 Stake된 TON의 양이 많을 경우, 다른 member대신 자신이 member가 될 수 있습니다.
그리고 setMemoOnCandidate와 setMemoOnCandidateContract를 통해서 자신의 Candidate Contract에 등록된 memo값을 수정할 수 있습니다.

![ForCandidate](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/ForCandidate.jpg)



## For everyone
모든 유저들은 onApprove와 endAgendaVoting, executeAgenda, updateSeigniorage를 사용할 수 있습니다.

onApprove함수는 Agenda를 생성할때 쓰는 함수입니다.
유저들이 바로 직접적으로 onApprove함수를 콜하지않고 TONContract의 ApproveAndCall을 통해서 호출하여서 Agenda를 생성할 수 있습니다.
endAgendaVoting 함수는 Agenda의 Voting시간이 끝났을 때 실행하는 함수로 해당 Agenda의 Status와 Result 상태를 변경합니다.
executeAgenda 함수는 Agenda가 Voting이 끝나고 Status가 WAITING_EXEC이고 Result는 ACCEPT일때 실행가능하며 함수를 호출하게 되면 통과된 Agenda의 함수들을 실행하게 됩니다.
updateSeigniorage 함수는 updateSeigniorage 함수를 실행할때 입력하는 Candidate주소의 Seigniorage를 업데이트 하는 함수입니다.

![ForEveryone](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/ForEveryone.jpg)


## For Member of DAOCommittee
Member들은 retireMember와 castVote, claimActivityReward 함수들을 사용할 수 있습니다.

retireMember 함수는 Member들이 Member의 역할을 은퇴하고 Candidate의 역할로 돌아갈 때 사용하는 함수입니다.
castVote 함수는 Member들이 Agenda에 대해서 투표를 할 때 사용하는 함수 입니다.
해당 Agenda에 대해서 comment와 함께 찬성할지 반대할지 중립인지에 대해서 투표할 수 있습니다.
claimActivityReward 함수는 member와 그리고 member였던 Candidate들이 호출할 수 있는 함수입니다.
Member들은 Member의 역할을 함으로써 받게되는 reward가 있습니다.
이 reward는 Member를 한 시간과 activityRewardPerSecond값에 의해서 결정됩니다.
해당 reward를 받을때 claimActivityReward 함수를 호출하여서 받을 수 있습니다.

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