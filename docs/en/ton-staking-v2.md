
> Simple Staking service integrates Layer 2 of TON Economy and is upgraded to ton staking v2. In this article, we will tell you how Simple Staking integrates layer 2 and evolves to version 2.

TON Staking v2 is developed to implement the contents of the V2 white paper, so [white paper](https://github.com/tokamak-network/papers/blob/master/cryptoeconomics/tokamak-cryptoeconomics-en.md) must be read in advance.

V2 introduces a concept called L2 sequencer, which was not present in V1, and new content has been added to distribute a portion of the newly issued TON seigniorage to the L2 sequencer. Since V2 is a reinforced system from the existing V1 contract, if there is a contract that exists in V1, it is implemented by upgrading. Therefore, readers of this article should be familiar with the V1 system. If you want to know more about TON staking V1, please refer to this [Medium article](https://medium.com/tokamak-network/looking-into-tokamak-networks-staking-contract-7d5f9fa057e7).

# Changes in TON Staking V2

## Changes in seigniorage distribution

In V2, the seigniorage from the issued TON is paid to the L2 sequencer in proportion to the total issuance of TON and the liquidity of TON in the L2 layer. (refer to [white paper](https://github.com/tokamak-network/papers/blob/master/cryptoeconomics/tokamak-cryptoeconomics-en.md#222-ton-staking-v2))

$S:　TON　staking　amount$ <br/>
$T :　Total　TON　supply$<br/>
$TON seigs :　Amount　of　TON　seigniorage　issued$<br/>
$D :　Total　TON　liquidity　of　Layer2$<br/>

- Seigniorage distribution of V1
<figure>
    <img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/1-1.png" alt="Seigniorage distribution of V1" width=500>
    <figcaption> </figcaption>
</figure>

- Seigniorage distribution of V2
<figure>
    <img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/1-2.png" alt="Seigniorage distribution of V2" width=500>
    <figcaption></figcaption>
</figure>


## Add Layer2Candidate

In V1, DAOCandidate Layer2 existed. DAOCandidate is Layer 2 that can become a DAO committee.

Layer2Candidate added in V2 inherits all the functions of DAOCandidate and can become a committee of DAO, and at the same time, Layer2's sequencer can receive seigniorage.

## Provides withdrawal and L2 deposit functions executed at once

As a feature added in Layer2Candidate, it provides a function that deposits to L2 (withdrawAndDepositL2) at the same time as withdrawal by linking Layer2's unique deposit function with the withdraw function.

TThe withdrawAndDepositL2 function is a function that withdraw the staking amount and deposits it to Layer 2 at the same time. The strength of this feature compared to V1 is that withdrawal is possible immediately  without waiting time (93046  waiting blocks ). As soon as the function is executed, funds tied up in L1 can be used as L2 liquidity.

## Stop providing seigniorage to the L2 sequencer in Layer2Candidate

Because the layer 2 sequencer is judged to contribute to the tokamak economy, it is designed to provide seigniorage.
However, if it is determined that Layer 2 is not contributing positively to the Tokamak economy, the Seigniorage Committee may suspend seigniorage granted to the sequencer of the Layer2Candidate.

## Cancel stopping distributing a seigniorage to the L2 sequencer

Layer2Candidate's seigniorage suspension can be reinstated by the seigniorage committee if it is determined that there is a valid reason or improvement.


# TON Stake Contracts

## TON Stake V1 Contracts

V1’s contract is structured as follows. DAOCandidate can be created through DAOCommittee, and when the created daoCandiate is registered through Layer2Registry and registered in SeigManager, an AutoCoinage mapped to DAOCandidate is created. AutoCoinage manages the staking amount and has logic to pay compound interest. Therefore, a separate AutoCoinage is created for each layer (DAOCandidate).

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/2-1.png"
         alt="TON Stake V1 Contracts Relationship" width=700></center>
    <figcaption> </figcaption>
</figure>

## TON Stake V2 Contracts

V2 maintains the configuration of V1 and adds Layer2Candidate. The contract configuration is as shown below. It looks a bit more complicated than V1. However, you can see that the contract in the blue part has been added and there are no changes to the existing configuration.

<figure>
   <center> <img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/2-2.png"
         alt="TON Stake V2 Contracts Relationship" width=700 ></center>
    <figcaption> </figcaption>
</figure>

The first thing to understand is the issue of how to check Layer 2 in L1. Layer 2 that we are currently targeting is Optimism Rollup. Layer 2 of Optimism is applied first, and contracts can be upgraded so that other layers can also be applied. Optimism Layer 2 has a legacy version and a bedrock version. Please remember that the initial application target is limited to cases where the L2 nativeToken is TON among Optimism Legacy Version and Optimism Bedrock Version. The Optimism Bedrock version contains the information and environment settings of the L1 contract in the SystemConfig contract. Therefore, the address of SystemConfig will be used as an address to distinguish Layer2. In the case of the legacy version, SystemConfig does not exist, so a separate legacySystemConfig contract was created. In the case of legacy layer 2, you must deploy the legacySystemConfig contract and use this address as an address book to distinguish the corresponding layer 2.

The added contracts in the blue part will be explained in detail in the contract part below.

# Use case
## For registrant of L2Registry
An account with registrant permission in the L2Registry contract can register SystemConfig, which holds unique information about Layer2. Registering SystemConfig means confirming that Layer 2 is problem-free. Only Layer 2 of the registered SystemConfig can be registered as Layer2Candidate. Only after being registered as Layer2Candidate can the sequencer receive seigniorage.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/3-1.png"
         alt="Register SystemConfig" width=400 ></center>
    <figcaption> </figcaption>
</figure>


## For everyone
Anyone can register Layer2Candidate for SystemConfig registered in L2Registry. When registering Layer2Candidate, you must deposit more than the minimum deposit into the operator account, so you must also provide a ton equivalent to the minimum deposit. Based on the current service standard, at least 1000.1 TON must be provided. Operator, Layer2Candidate, and Coinage contracts are created through the ‘registerLayer2Candidate’ function.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/3-2.png"
         alt="Register Layer2Candidate" width=500 ></center>
    <figcaption> </figcaption>
</figure>


## For staker in Layer2Candidate

Users who have staked on Layer2Candidate can perform the function of withdrawing the staking amount and simultaneously depositing the withdrawn amount into the corresponding Layer2 through the WithdrawAndDepositL2 function. At this time, when withdrawing the staking amount, withdrawal and L2 deposit are made immediately without waiting time.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/3-3.png"
         alt="Withdraw and deposit to L2" width=500 ></center>
    <figcaption> </figcaption>
</figure>


## For seigniorageCommittee

Simple Staking V2 has designed an economy that issues TON seigniorage to the sequencer of Layer2Candidate, which operates Layer2. However, there must be a function to stop issuing TON seigniorages to the corresponding Layer 2 sequencer as soon as it detects actions such as not actually operating Layer 2 or unreasonably allocating seigniorage.

Created a Seigniorage Committee account defined in the L2Registry contract. The Seigniorage Committee can perform the function of suspending or canceling issuance of Seigniorage for the Layer 2 sequencer.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/3-4.png"
         alt="Reject and Restore Layer2" width=500 ></center>
    <figcaption> </figcaption>
</figure>


# Sequence Diagrams

## Register Layer2Candidate

When registering a Layer2Candidate, you must deposit at least the minimum deposit amount in the name of the operator of that layer.

When registering Layer2Candidate. You must present the SystemConfig contract address that holds Layer 2 configuration information.

Additionally, the SystemConfig you enter must be registered in L2Registry before registration. (Only accounts with L2Registry Registrant privileges can register with L2Registry.)
<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/4-1.png"
         alt="Reject and Restore Layer2" width=1000 ></center>
    <figcaption> </figcaption>
</figure>

## Withdraw And Deposit L2

Users who stake on Layer2Candidate can withdraw the staked amount immediately and deposit it on Layer2 concurrently.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/4-2.png"
         alt="Reject and Restore Layer2" width=800 ></center>
    <figcaption> </figcaption>
</figure>

## Stop distributing a seigniorage to the L2 sequencer

When the seigniorage committee determines that it is unreasonable for a specific layer 2 to receive seigniorage, it can stop issuing seigniorage to a layer2 sequencer.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/4-3.png"
         alt="Reject and Restore Layer2" width=500 ></center>
    <figcaption> </figcaption>
</figure>

## Cancel stopping distributing a seigniorage to the L2 sequencer

The Seigniorage Committee can cancel the suspension of seigniorage issuance distributed to specific Layer 2 sequencers and issue seigniorage again.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/15-create-a-document/docs/img/4-4.png"
         alt="Reject and Restore Layer2" width=500 ></center>
    <figcaption> </figcaption>
</figure>


# Contract Details

## L2Registry

- Basic understanding
    - By registering an authenticated layer 2 SystemConfig contract, it can be used in the simple staking service.
    - For Titan and Thanos Layer 2, SystemConfig is registered manually by the owner.
    - Contracts created in on-demand L2 are automatically registered when the contract is created.
    - There was a Layer2Registry contract in Simple Staking previously, so we named it L2Registry to distinguish it.
    - It must be upgradeable by configuring it as a proxy, considering support for other layers (ex, zk-EVM) in the future.
- Authority
    - Owner: The owner has the right to upgrade logic and can designate a manager.
    - Manager: The foundation holds MANAGER_ROLE, and the manager can register or remove operators ( or SeigniorageCommittee).
    - Registrant: When opening on-demand-L2, REGISTRANT_ROLE must be given to the EOA of the server that actually distributes L2.
- Storage

    ```jsx
    address public layer2Manager;
    address public seigManager;
    address public ton;
    address public seigniorageCommittee;

    /// systemConfig - type (0:empty, 1: optimism legacy, 2: optimism bedrock native TON)
    mapping (address => uint8) public systemConfigType;

    /// For registered bridges, set to true.
    mapping (address => bool) public l1Bridge;

    /// For registered portals, set to true.
    mapping (address => bool) public portal;

    /// Set the layer where seigniorage issuance has been suspended to true.
    mapping (address => bool) public rejectSystemConfig;
    ```

- Event

    ```jsx
    event SetAddresses(address _layer2Manager, address _seigManager, address _ton);
    event SetSeigniorageCommittee(address _seigniorageCommittee);

    /**
     * @notice  Event occurs when registering SystemConfig
     * @param   systemConfig  the systemConfig address
     * @param   type_         0: none, 1: legacy, 2: bedrock with nativeTON
     */
    event RegisteredSystemConfig(address systemConfig, uint8 type_);

    /**
     * @notice  Event occurs when an account with registrant privileges changes the layer 2 type.
     * @param   systemConfig  the systemConfig address
     * @param   type_         0: none, 1: legacy, 2: bedrock with nativeTON
     */
    event ChangedType(address systemConfig, uint8 type_);

    /**
     * @notice  Event occurs when onlySeigniorageCommittee stops issuing seigniorage
     *          to the layer 2 sequencer of a specific systemConfig.
     * @param   _systemConfig  the systemConfig address
     */
    event RejectedLayer2Candidate(address _systemConfig);

    /**
     * @notice  Event occurs when onlySeigniorageCommittee cancels stoping issuing seigniorage
     *          to the layer 2 sequencer of a specific systemConfig.
     * @param   _systemConfig  the systemConfig address
     */
    event RestoredLayer2Candidate(address _systemConfig);

    ```

- Transaction Functions
    - function rejectLayer2Candidate(address _systemConfig)  external onlySeigniorageCommittee()

        ```solidity
        /**
         * @notice Stop issuing seigniorage to the layer 2 sequencer of a specific systemConfig.
         * @param _systemConfig the systemConfig address
         */
        function rejectLayer2Candidate(
            address _systemConfig
        )  external onlySeigniorageCommittee()
        ```

    - function restoreLayer2Candidate(address _systemConfig)  external onlySeigniorageCommittee()

        ```solidity
        /**
         * Restore cancel stoping seigniorage to the layer 2 sequencer of a specific systemConfig.
         * @param _systemConfig the systemConfig address
         */
        function restoreLayer2Candidate(
            address _systemConfig
        )  external onlySeigniorageCommittee()
        ```

    - function registerSystemConfigByManager(address _systemConfig, uint8 _type)  external onlyManager

        ```solidity
        /**
         * @notice Registers Layer2 for a specific systemConfig by the manager.
         * @param _systemConfig  the systemConfig address
         * @param _type          1: legacy, 2: bedrock with nativeTON
         */
        function registerSystemConfigByManager(address _systemConfig, uint8 _type)  external  onlyManager

        ```

    - function registerSystemConfig(address _systemConfig, uint8 _type)  external  onlyRegistrant

        ```solidity
        /**
         * @notice Registers Layer2 for a specific systemConfig by Registrant.
         * @param _systemConfig the systemConfig address
         * @param _type          1: legacy, 2: bedrock with nativeTON
         */
        function registerSystemConfig(address _systemConfig, uint8 _type)  external  onlyRegistrant

        ```

    - function changeType(address _systemConfig, uint8 _type)  external  onlyRegistrant

        ```solidity
        /**
         * @notice Changes the Layer2 type for a specific systemConfig by Registrant.
         * @param _systemConfig the systemConfig address
         * @param _type          1: legacy, 2: bedrock with nativeTON
         */
        function changeType(address _systemConfig, uint8 _type)  external  onlyRegistrant
        ```

- View Functions
    - function layer2TVL(address _systemConfig) public view returns (uint256 amount)

        ```solidity
        /**
         * @notice View the liquidity of Layer2 TON for a specific systemConfig.
         * @param _systemConfig the systemConfig address
         */
        function layer2TVL(address _systemConfig) public view returns (uint256 amount)
        ```

    - function availableForRegistration(address _systemConfig, uint8 _type) public view returns (bool valid)

        ```solidity
        /**
         * @notice Check whether a specific systemConfig can be registered as a type.
         * @param _systemConfig the systemConfig address
         * @param _type         1: legacy, 2: bedrock with nativeTON
         */
        function availableForRegistration(address _systemConfig, uint8 _type) public view returns (bool valid)

        ```

## OperatorFactory

- Basic understanding

    When Layer2Candidate is registered as a member in DAOCommittee, the operator address of Layer2Candidate is registered as the key value of the mapping, so the operator address should not be changed. However, because the operator of the L2 layer (SystemConfig) can change at any time, an Operator contract was created. The Operator contract is a contract that maps to the SystemConfig contract. In other words, the address of the Operator contract must be created using the SystemConfig (L2 layer) contract address. Because there is a possibility of logic changes in the future, it was implemented as a proxy.

- Authority
    - Owner: The owner can set the logic of the deployed operator.

- Storage

    ```jsx
    address public operatorImplementation;
    address public depositManager;
    address public ton;
    address public wton;
    address public layer2Manager;
    ```

- Event

    ```jsx
    /**
     * @notice Event occured when set the addresses
     * @param depositManager    the depositManager address
     * @param ton               TON address
     * @param wton              WTON
     * @param layer2Manager     the layer2Manager address
     */
    event SetAddresses(address depositManager, address ton, address wton, address layer2Manager);

    /**
     * @notice Event occured when change the operator implementaion address
     * @param newOperatorImplementation the operator implementaion address
     */
    event ChangedOperatorImplementaion(address newOperatorImplementation);

    /**
     * @notice Event occured when create the Operator Contract
     * @param systemConfig  the systemConfig address
     * @param owner         the owner address
     * @param manager       the manager address
     * @param operator      the operator address
     */
    event CreatedOperator(address systemConfig, address owner, address manager, address operator);

    ```

- Transaction functions
    - function changeOperatorImplementaion(address newOperatorImplementation) external onlyOwner

        ```solidity
        /**
         * @notice Change the operator implementaion address by Owner
         * @param newOperatorImplementation the operator implementaion address
         */
        function changeOperatorImplementaion(address newOperatorImplementation) external onlyOwner
        ```

    - function createOperator(address systemConfig) external returns (address operator)

        ```solidity
        /**
         * @notice  Create an Operator Contract, and return its address.
         *          return revert if the account is already deployed.
         *          Note. Only Layer2Manager Contract can be called.
         *          When creating the Layer2Candidate, create an Operator contract
         *          that is mapped to SystemConfig.
         * @param systemConfig  the systemConfig address
         */
        function createOperator(address systemConfig) external returns (address operator) {

        ```

- View functions
    - function getAddress(address systemConfig) public view returns (address)

        ```solidity
        /**
         * @notice  Returns the operator contract address matching systemConfig.
         * @param systemConfig  the systemConfig address
         */
        function getAddress(address systemConfig) public view returns (address)
        ```


## Operator

- Basic understanding
    - Operator contracts should be designed with the possibility of supporting multiple sequencers (operators) in Layer 2 in the future. Therefore, it is designed with an upgradeable structure.
    - Layer2Candidate inherits all the functions of DAOCandidate.
    - The onlyCandidate account (an account where Operator.isOperator(msg.sender) is true has operator privileges) can use the functions that onlyCandidate of DAOCandidate can perform.

- Authority
    - owner
        - As a proxy owner, you can upgrade the logic.
        - Foundation holds the proxy owner
        - Owner can change the manager.
        - Owner can add/delete operators.
    - manager
        - Administrator privileges can register and remove operators. When deploying for the first time, designate the owner of SystemConfig as manager.
        - When the owner of SystemConfig changes in the future, the manager must be changed using transferManager. (SystemConfig.owner provides an interface to take the manager.)

    - operator  (onlyCandidate)
        - Possesses operator authority. You can use the functions of DAO members.
        - onlyCandidate : This is an account where Operator.isOperator(msg.sender) == true.
        - Functions that can be used by onlyCandidate inherited from DAOCandidate can be executed by the operator.
        - changeMember function → Operator contract becomes a member of DAO.
        - retireMember function → Operator contract resigns as a DAO member.
        - castVote function → Vote on the agenda by Operator contract.
        - claimActivityReward function → The reward is received by the Operator contract.

- Storage

    ```jsx
    address public systemConfig;
    address public layer2Manager;
    address public depositManager;
    address public ton;
    address public wton;

    address public manager;
    mapping(address => bool) public operator;
    ```

- Event

    ```jsx
    /**
    * @notice Event occurs when the transfer manager
    * @param previousManager   the previous manager address
    * @param newManager        the new manager address
    */
    event TransferredManager(address previousManager, address newManager);

    /**
    * @notice Event occurs when adding the operator
    * @param operator  the operator address
    */
    event AddedOperator(address operator);

    /**
    * @notice Event occurs when deleting the operator
    * @param operator  the operator address
    */
    event DeletedOperator(address operator);

    /**
    * @notice Event occurs when setting the addresses
    * @param _layer2Manager    the _layer2Manager address
    * @param _depositManager   the _depositManager address
    * @param _ton              the TON address
    * @param _wton             the WTON address
    */
    event SetAddresses(address _layer2Manager, address _depositManager, address _ton, address _wton);

    /**
    * @notice Event occurs when the claim token
    * @param token     the token address, if token address is address(0), it is ETH
    * @param caller    the caller address
    * @param to        the address received token
    * @param amount    the received token amount
    */
    event Claimed(address token, address caller, address to, uint256 amount);

    ```

- Transaction functions
    - function claimETH() external onlyOwnerOrManager

        ```jsx
        /**
         * @notice  Give ETH to a manager through the manager(or owner) claim
         */
        function claimETH() external onlyOwnerOrManager
        ```

    - function claimERC20(address token, uint256 amount) external onlyOwnerOrManager

        ```jsx
        /**
         * @notice  Give ERC20 to a manager through the manager(or owner) claim
         * @param token     the token address
         * @param amount    the amount claimed token
         */
        function claimERC20(address token, uint256 amount) external onlyOwnerOrManager
        ```

    - function depositByLayer2Canddiate(uint256 amount) external onlyLayer2Candidate

        ```jsx
        /**
         * @notice Deposit wton amount to DepositManager as named Layer2
         * @param amount    the deposit wton amount (ray)
         */
        function depositByLayer2Canddiate(uint256 amount) external onlyLayer2Candidate
        ```

    - function claimByLayer2Candidate(uint256 amount) external onlyLayer2Candidate

        ```jsx
        /**
        * @notice Claim WTON to a manager
        * @param amount    the deposit wton amount (ray)
        */
        function claimByLayer2Candidate(uint256 amount) external onlyLayer2Candidate
        ```

- View functions
    - function acquireManager() external

        ```jsx
        /**
         * @notice acquire administrator privileges.
         */
        function acquireManager() external
        ```

    - function isOperator(address addr) public view returns (bool)

        ```jsx
        /**
         * @notice Returns true if the operator has permission.
         * @param addr the address to check
         */
        function isOperator(address addr) public view returns (bool)
        ```

    - function checkL1Bridge() public view returns (bool result, address l1Bridge, address portal, address l2Ton)

        ```jsx
        /**
         * @notice Returns the availability status of Layer 2, L1 bridge address, portal address, and L2TON address.
         * @return result   the availability status of Layer 2
         * @return l1Bridge the L1 bridge address
         * @return portal   the L1 portal address
         * @return l2Ton    the L2 TON address
         *                  L2TON address is 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000,
         *                  In this case, the native token of Layer 2 is TON.
         */
        function checkL1Bridge() public view returns (bool result, address l1Bridge, address portal, address l2Ton) {

        ```


## Layer2Manager
- Basic understanding
    - In order for the Layer2 sequencer to receive seigniorage, the SystemConfig address must be registered in the Layer2Manager.
    - When distributing seigniorage, the seigniorage paid to Layer 2 sequencers is paid to Layer 2 Manager. Therefore, Layer2Manager holds the seigniorage until the seigniorage of Layer2Candidate is settled.

- Authority
    - Owner : The owner has the authority to upgrade logic and can set settings.

- Storage

    ```jsx
    struct OperatorInfo {
        address systemConfig;
        address layer2Candidate;
    }

    struct SystemConfigInfo {
        uint8 stateIssue; // status for giving seigniorage ( 0: none, 1: registered, 2: paused )
        address operator;
    }

    address public l2Register;
    address public operatorFactory;
    address public ton;
    address public wton;
    address public dao;
    address public depositManager;
    address public seigManager;
    address public swapProxy;

    /// The minimum TON deposit amount required when creating a Layer2Candidate.
    /// Due to calculating swton, It is recommended to set
    /// DepositManager's minimum deposit + 0.1 TON
    uint256 public minimumInitialDepositAmount;

    /// systemConfig - SystemConfigInfo
    mapping (address => SystemConfigInfo) public systemConfigInfo;

    /// operator - OperatorInfo
    mapping (address => OperatorInfo) public operatorInfo;

    ```

- Event

    ```jsx
    /**
     * @notice Event occurs when setting the minimum initial deposit amount
     * @param _minimumInitialDepositAmount the inimum initial deposit amount
     */
    event SetMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount);

    /**
     * @notice Event occurs when registering Layer2Candidate
     * @param systemConfig      the systemConfig address
     * @param wtonAmount        the wton amount depositing when registering Layer2Canddiate
     * @param memo              the name of Layer2Canddiate
     * @param operator          a opperator contract address
     * @param layer2Candidate   a layer2Candidate address
     */
    event RegisteredLayer2Candidate(address systemConfig, uint256 wtonAmount, string memo, address operator, address layer2Candidate);

    /**
     * @notice Event occurs when pausing the layer2 candidate
     * @param systemConfig      the systemConfig address
     * @param _layer2           the layer2 address
     */
    event PausedLayer2Candidate(address systemConfig, address _layer2);

    /**
     * @notice Event occurs when pausing the layer2 candidate
     * @param systemConfig      the systemConfig address
     * @param _layer2           the layer2 address
     */
    event UnpausedLayer2Candidate(address systemConfig, address _layer2);
    ```

- Transaction functions
    - function registerLayer2Candidate(address systemConfig, uint256 amount, bool flagTon, string calldata memo) external

        ```jsx
        /**
         * @notice Register the Layer2Candidate
         * @param systemConfig     systemConfig's address
         * @param amount           transfered amount
         * @param flagTon          if true, amount is ton, otherwise it it wton
         * param memo             layer's name
         */
        function registerLayer2Candidate(
            address systemConfig,
            uint256 amount,
            bool flagTon,
            string calldata memo
        )
            external
        ```

    - function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external returns (bool)

        ```jsx
        /// @notice ERC20 Approve callback
        /// @param owner    Account that called approveAndCall
        /// @param spender  OnApprove function contract address
        /// @param amount   Approved amount
        /// @param data     Data used in OnApprove contract
        /// @return bool    true
        function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external returns (bool)
        ```

    - function pauseLayer2Candidate(address systemConfig) external onlyL2Register ifFree

        ```jsx
        /**
         * @notice Pause the layer2 candidate
         * @param systemConfig the systemConfig address
         */
        function pauseLayer2Candidate(address systemConfig) external onlyL2Register ifFree
        ```

    - function unpauseLayer2Cnadidate(address systemConfig) external onlyL2Register ifFree

        ```solidity
        /**
         * @notice Unpause the layer2 candidate
         * @param systemConfig the systemConfig address
         */
        function unpauseLayer2Cnadidate(address systemConfig) external onlyL2Register ifFree
        ```

    - function updateSeigniorage(address systemConfig, uint256 amount) external onlySeigManger

        ```jsx
        /**
        * @notice When executing update seigniorage, the seigniorage is settled to the Operator of Layer 2.
        * @param systemConfig the systemConfig address
        * @param amount the amount to give a seigniorage
        */
        function updateSeigniorage(address systemConfig, uint256 amount) external onlySeigManger
        ```

    - function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)  external  onlyOwner

        ```jsx
        /**
        * @notice  Set the minimum TON deposit amount required when creating a Layer2Candidate.
        *          Due to calculating swton, it is recommended to set DepositManager's minimum deposit + 0.1 TON
        * @param   _minimumInitialDepositAmount the minimum initial deposit amount
        */
        function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)  external  onlyOwner
        ```


- View functions
    - function systemConfigOfOperator(address _oper) external view returns (address)

        ```jsx
        /**
         * @notice View the systemConfig address of the operator address.
         * @param _oper     the operator address
         * @return          the systemConfig address
         */
        function systemConfigOfOperator(address _oper) external view returns (address)
        ```

    - function operatorOfSystemConfig(address _sys) external view returns (address)

        ```jsx
        /**
         * @notice View the operator address of the systemConfig address.
         * @param _sys      the systemConfig address
         * @return          the operator address
         */
        function operatorOfSystemConfig(address _sys) external view returns (address)
        ```

    - function layer2CandidateOfOperator(address _oper) external view returns (address)

        ```jsx
        /**
         * @notice  View the layer2Candidate address of the operator address.
         * @param _oper     the operator address
         * @return          the layer2Candidate address
         */
        function layer2CandidateOfOperator(address _oper) external view returns (address)
        ```

    - function issueStatusLayer2(address _sys) external view returns (uint8)

        ```jsx
        /**
         * @notice View the status of seigniorage provision for Layer 2 corresponding to SystemConfig.
         * @param _sys      the systemConfig address
         * @return          the status of seigniorage provision for Layer 2
         *                  ( 0: none , 1: registered, 2: paused )
         */
        function issueStatusLayer2(address _sys) external view returns (uint8)
        ```

    - function checkLayer2TVL(address _systemConfig) public view returns (bool result, uint256 amount)

        ```jsx
        /**
         * @notice  Check Layer 2’s TON liquidity related information
         * @param _systemConfig the syatemConfig address
         * @return result       whether layer 2 TON liquidity can be checked
         * @return amount       the layer 2's TON amount (total value liquidity)
         */
        function checkLayer2TVL(address _systemConfig) public view returns (bool result, uint256 amount)
        ```

    - function checkL1Bridge(address _systemConfig) public view returns (bool result, address l1Bridge, address portal, address l2Ton)

        ```jsx
        /**
         * @notice Layer 2 related information search
         * @param _systemConfig     the systemConfig address
         * @return result           whether Layer2 information can be searched
         * @return l1Bridge         the L1 bridge address
         * @return portal           the optimism portal address
         * @return l2Ton            the L2 TON address
         */
        function checkL1Bridge(address _systemConfig) public view returns (bool result, address l1Bridge, address portal, address l2Ton)

        ```


## Layer2ContractFactory

- Basic understanding
    - This is a contract that creates Layer2Candiate.

- Authority
    - Owner : The owner has the authority to upgrade logic and can set settings.

- Storage

    ```jsx
    address public depositManager;
    address public daoCommittee;
    address public layer2CandidateImp;
    address public ton;
    address public wton;

    address public onDemandL2Registry;
    ```

- Event

    ```jsx
    /**
     * @notice  Event that occurs when a Candidate is created
     * @param sender            the sender address
     * @param layer2            the layer2 address
     * @param operator          the operator address
     * @param isLayer2Candidate whether it is Layer2Candidate
     * @param name              the name of Layer2
     * @param committee         the committee address
     * @param seigManager       the seigManager address
     */
    event DeployedCandidate(
        address sender,
        address layer2,
        address operator,
        bool isLayer2Candidate,
        string name,
        address committee,
        address seigManager
    );
    ```

- Transaction functions
    - function deploy(address _sender, string memory _name, address _committee, address _seigManager) public onlyDAOCommittee  returns (address)

        ```solidity
        /**
        * @notice Deploy the candidate contract
        * @param _sender       the sender address
        * @param _name         the name of layer2
        * @param _committee    the committee address
        * @param _seigManager  the seigManager address
        * @return              the created candidate address
        */
        function deploy(
          address _sender,
          string memory _name,
          address _committee,
          address _seigManager
        )
          public onlyDAOCommittee
          returns (address)
        ```



## Layer2Contract

- Basic understanding
    - Supports the basic functions of Simple Staking (Tone Staking) (deposit, update seigniorage-interest payment, withdrawal function).
    - Supports DAO member functions available in DAOCandidate.
    - When executing update seigniorage, Layer2Candidate’s sequencer (operator) can receive seigniorage.

- Authority
    - Owner : The owner has the authority to upgrade logic and can initialize settings.
    - onlyCandidate : Account with operator privileges of the Operator contract of Layer2Candidate

        ```jsx
         modifier onlyCandidate() {
              require(IOperateContract(candidate).isOperator(msg.sender),
              "sender is not an operator");
              _;
          }
        ```

- Storage

    ```solidity
        mapping(bytes4 => bool) internal _supportedInterfaces;
        bool public isLayer2Candidate;
        address public candidate;
        string public memo;

        address public committee;
        address public seigManager;
        address ton;
        address wton;
    ```

- Event

    ```jsx
    event Initialized(address _operateContract, string memo, address committee, address seigManager);
    event SetMemo(string _memo);
    ```

- Transaction functions
    - function changeMember(uint256 _memberIndex) external  onlyCandidate   returns (bool)

        ```jsx
        /// @notice Try to be a member
        /// @param _memberIndex The index of changing member slot
        /// @return Whether or not the execution succeeded
        function changeMember(uint256 _memberIndex)
            external
            onlyCandidate
            returns (bool)
        ```

    - function retireMember() external onlyCandidate returns (bool)

        ```jsx
        /// @notice Retire a member
        /// @return Whether or not the execution succeeded
        function retireMember() external onlyCandidate returns (bool)
        ```

    - function castVote(uint256 _agendaID,  uint256 _vote, string calldata  _comment ) external  onlyCandidate

        ```jsx
        /// @notice Vote on an agenda
        /// @param _agendaID The agenda ID
        /// @param _vote voting type
        /// @param _comment voting comment
        function castVote(
            uint256 _agendaID,
            uint256 _vote,
            string calldata _comment
        )
            external
            onlyCandidate
        ```

    - function claimActivityReward() external  onlyCandidate

        ```jsx
        /**
         * @notice Claim an activity reward
         */
        function claimActivityReward()
            external
            onlyCandidate
        ```

    - function updateSeigniorage() external returns (bool)

        ```jsx
        /// @notice Call updateSeigniorage on SeigManager
        /// @return Whether or not the execution succeeded
        function updateSeigniorage() external returns (bool)
        ```

    - function updateSeigniorage(uint256 afterCall) public returns (bool)

        ```jsx
        /// @notice Call updateSeigniorage on SeigManager
        /// @param afterCall    After running update seigniorage, option to run additional functions
        ///                     0: none, 1: claim, 2: staking
        /// @return             Whether or not the execution succeeded
        function updateSeigniorage(uint256 afterCall) public returns (bool)
        ```

- View functions
    - function totalStaked() external  view returns (uint256 totalsupply)

        ```jsx
        /// @notice Retrieves the total staked balance on this candidate
        /// @return totalsupply Total staked amount on this candidate
        function totalStaked()
            external
            view
            returns (uint256 totalsupply)
        ```

    - function stakedOf(address _account)  external  view returns (uint256 amount)

        ```jsx
        /// @notice Retrieves the staked balance of the account on this candidate
        /// @param _account Address being retrieved
        /// @return amount The staked balance of the account on this candidate
        function stakedOf(
            address _account
        )
            external
            view
            returns (uint256 amount)
        ```


## SeigManagerV1_3
- Basic understanding
    - When Layer2Candidate's update seigniorage is executed, seigniorage must be paid to the Layer2 sequencer according to Layer2's TON TVL, and the paid seigniorage is settled to the Operator contract.
    - A sequencer with operator privileges in the Operator contract can select the claim and staking option when executing the update seigniorage of Layer2Candidate (when distributing seigniorage) and execute the claim or staking function at the same time as seigniorage settlement.
    - The seigniorage distribution logic distributed to the L2 sequencer is done according to the seigniorage distribution rules of v2. [V2 white paper](https://github.com/tokamak-network/papers/blob/master/cryptoeconomics/tokamak-cryptoeconomics-en.md#222-ton-staking-v2)
    - Since SeigManager is already deployed and operated in V1, only the update seigniorage function is executed with the changed logic in SeigManagerV1_3 without changing other functions.
    - Add storage to manage the seigniorage provided to Layer 2 when executing the update seigniorage function.


- Added storage

    ```jsx
    struct Layer2Reward {
        uint256 layer2Tvl;
        uint256 initialDebt;
    }

    /// L2Registry address
    address public l2Registry;

    /// Layer2Manager address
    address public layer2Manager;

    /// layer2 seigs start block
    uint256 public layer2StartBlock;

    uint256 public l2RewardPerUint;  // ray unit .1e27

    /// total layer2 TON TVL
    uint256 public totalLayer2TVL;

    /// layer2 reward information for each layer2.
    mapping (address => Layer2Reward) public layer2RewardInfo;

    ```

- Deleted Event

    The SeigGiven event that occurred when executing update seigniorage has been deleted.

    ```jsx
    event SeigGiven(address indexed layer2, uint256 totalSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 pseig);
    ```

- Added Event

    When executing update seigniorage, the SeigGiven2 event occurs.

    ```jsx
    /**
     * Event that occurs when seigniorage is distributed when update seigniorage is executed
     * @param layer2        The layer2 address
     * @param totalSeig     Total amount of seigniorage issued
     * @param stakedSeig    Seigniorage equal to the staking ratio of ton total
     *                      supply in total issued seigniorage
     * @param unstakedSeig  Total issued seigniorage minus stakedSeig
     * @param powertonSeig  Seigniorage distributed to powerton
     * @param daoSeig       Seigniorage distributed to dao
     * @param pseig         Seigniorage equal to relativeSeigRate ratio
     *                      from unstakedSeig amount
     *                      Seigniorage given to stakers = stakedSeig + pseig
     * @param l2TotalSeigs  Seigniorage distributed to L2 sequencer
     * @param layer2Seigs   Seigniorage currently settled (give)
     *                      to layer2Candidate's operator contract
     */
    event SeigGiven2(address indexed layer2, uint256 totalSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 pseig, uint256 l2TotalSeigs, uint256 layer2Seigs);

    ```

- Transaction functions
    - function excludeFromSeigniorage (address _layer2) external returns (bool) onlyLayer2Manager

        ```
        /**
        * @notice Exclude the layer2 in distributing a seigniorage
        * @param _layer2     the layer2 address
        */
        function excludeFromSeigniorage (address _layer2)
        external
        returns (bool)
        ```

    - function updateSeigniorageOperator() external  returns (bool)  onlyCandidate

        ```jsx
        /**
        * @notice Distribute the issuing seigniorage.
        *         If caller is a Layer2Candidate, the seigniorage is settled to the L2 Operator.
        */
        function updateSeigniorageOperator()
        external
        returns (bool)
        ```

    - function updateSeigniorage() external  returns (bool)  onlyCandidate

        ```jsx
        /**
        * @notice Distribute the issuing seigniorage.
        */
        function updateSeigniorage()
        external
        returns (bool)
        ```

    - function updateSeigniorageLayer(address layer2) external returns (bool)

        ```jsx
        /**
        * @notice Distribute the issuing seigniorage on layer2.
        */
        function updateSeigniorageLayer(address layer2) external returns (bool)
        ```

- View functions
    - function getOperatorAmount(address layer2) external view returns (uint256)

        ```jsx
        /**
        * @notice Query the staking amount held by the operator
        */
        function getOperatorAmount(address layer2) external view returns (uint256)
        ```

    - function estimatedDistribute(uint256 blockNumber, address layer2, bool _isSenderOperator)  external view returns (uint256 maxSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 relativeSeig, uint256 l2TotalSeigs, uint256 layer2Seigs)

        ```jsx
        /**
        * @notice Estimate the seigniorage to be distributed
        * @param blockNumber         The block number
        * @param layer2              The layer2 address
        * @param _isSenderOperator   Whether sender is operator of layer2
        * @return maxSeig            Total amount of seigniorage occurring in that block
        * @return stakedSeig         the amount equals to the staking ratio in TON total supply
        *                            in total issuing seigniorage
        * @return unstakedSeig       MaxSeig minus stakedSeig
        * @return powertonSeig       the amount calculated to be distributed to Powerton
        * @return daoSeig            the amount calculated to be distributed to DAO
        * @return relativeSeig       the amount equal to relativeSeigRate ratio from unstakedSeig amount
        * @return l2TotalSeigs       the amount calculated to be distributed to L2 sequencer
        * @return layer2Seigs        the amount currently to be settled (give)  to layer2Candidate's operator contract
        */
        function estimatedDistribute(uint256 blockNumber, address layer2, bool _isSenderOperator)
        external view
        returns (uint256 maxSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 relativeSeig, uint256 l2TotalSeigs, uint256 layer2Seigs)
        ```



## DepositManagerV1_1

- Basic understanding
    - In the case of Layer2Candidate, it supports the function (withdrawAndDepositL2) that allows you to withdraw tons staking and deposit to Layer 2 at the same time. In this case, the money is withdrawn immediately without delay and deposited in L2.
    - An error occurs when requesting the withdrawAndDepositL2 function from a layer other than Layer2Candidate.
    - Didn't change the existing logic in DepositManagerProxy as is and add only the withdrawAndDepositL2 function.

- Storage

    ```jsx
    address public ton;
    uint32 public minDepositGasLimit; /// not used
    ```

- Event

    ```jsx
    /**
     * @notice Event that occurs when calling the withdrawAndDepositL2 function
     * @param layer2    The layer2 address
     * @param account   The account address
     * @param amount    The amount of withdrawal and deposit L2
     */
    event WithdrawalAndDeposited(address indexed layer2, address account, uint256 amount);

    ```

- Transaction functions
    - function withdrawAndDepositL2(address layer2, uint256 amount) external ifFree returns (bool)

    ```jsx
    /**
     * @notice Withdrawal from L1 and deposit to L2
     * @param layer2    The layer2 address
     * @param amount    The amount to be withdrawal and deposit L2. ()`amount` WTON in RAY)
     */
    function withdrawAndDepositL2(address layer2, uint256 amount) external ifFree returns (bool)
    ```

