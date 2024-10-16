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
Here's how you can become a Candidate for the Tokamak DAOCommittee

### Call the createCandidate function
Anyone who wants to become a Candidate can call it. 
The address of the msg.sender that called the function becomes the operator, and in order to perform normal activities as an operator, the operator must deposit more than 1000.1TON in the created Candidate.
![createCandidate](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/createCandidate.jpg)


### Call the createCandidateAddOn function
Anyone who wants to become a Layer2Candidate can call, but only SystemConfig registered in L2Registry can registerCandidateAddOn. 
When registerCandidateAddOn is registered, the operator must deposit more than 1000.1TON at the same time as registration, so that the operator can immediately perform normal activities.
![createCandidateAddOn](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/createCandidateAddOn.jpg)


### Call the registerLayer2CandidateByOwner function
This is the method used when you want to register your own Layer2 as a Candidate of DAO.
If you have your own Layer2, you can make a proposal to the DAO Agenda so that the registerLayer2CandidateByOwner function is executed, and if this proposal passes and the Agenda is executed, the Layer2 will be registered as a Candidate.
After registering as a Candidate, a deposit of 1000.1 TON or more is required to act as a Candidate.
![registerLayer2CandidateByOwner](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/registerLayer2CandidateByOwner.jpg)


## For Candidate of DAOCommittee
Candidates can call the changeMember, setMemoOnCandidate, and setMemoOnCandidateContract functions.

The changeMember function allows you to become a member instead of another member if you have more TON staked than other members.
And you can modify the memo value registered in your Candidate Contract through setMemoOnCandidate and setMemoOnCandidateContract.

![ForCandidate](https://github.com/tokamak-network/ton-staking-v2/blob/NewDAOStructure/doc/img/ForCandidate.jpg)



## For everyone
모든 유저들은 onApprove와 endAgendaVoting, executeAgenda, updateSeigniorage를 사용할 수 있습니다.

The onApprove function is a function used when creating an Agenda. Users can create an Agenda through TONContract's ApproveAndCall without directly calling the onApprove function.
The endAgendaVoting function is executed when the voting time for the Agenda has ended, and updates the Status and Result status of the Agenda.
The executeAgenda function can be executed when the voting for the Agenda is finished, the Status is WAITING_EXEC, and the Result is ACCEPT. When this function is called, the functions of the passed Agenda are executed.
The updateSeigniorage function is a function that updates the Seigniorage of the Candidate address entered when executing.

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