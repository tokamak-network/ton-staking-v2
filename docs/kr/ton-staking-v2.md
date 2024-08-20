
> Simple Staking 서비스는 TON Economy의 Layer2 를 통합하여, ton staking v2로 업그레이드 됩니다. 이 글에서는 Simple Staking 가 layer2를 어떻게 통합하여 version2로 진화되는지에 대해 알려줄 것입니다.

TON Staking v2 는 V2 백서의 내용을 구체화하기 위한 개발이므로,  [백서](https://github.com/tokamak-network/papers/blob/master/cryptoeconomics/tokamak-cryptoeconomics-kr.md)를 사전에 숙지하시기 바랍니다.

V2에는 V1에는 존재하지 않는 L2 시퀀서라는 개념이 도입되었으며,  새로 발행되는 톤 시뇨리지의 일부를 L2 시퀀서에게 분배하는 내용이 추가된 내용입니다.  V2는 기존  V1 컨트랙에서 보강된 시스템이기 때문에, V1에 존재하는 컨트랙일 경우, 업그레이드하여 구현합니다.  따라서 본 글을 읽으시는 독자는 V1 시스템을 알고 있어야 합니다.  톤스테이킹 V1에 대해서 더 자세히 알고 싶은 분은 [미디움 글](https://medium.com/tokamak-network/looking-into-tokamak-networks-staking-contract-7d5f9fa057e7)을 참고하시기 바랍니다.

# Ton Staking V2에서 변경되는 사항들

## 시뇨리지 분배의 변화

V2에서는  발행된 시뇨리지에서 톤의 총 발행량과  L2 레이어의 톤 유동성의 비율만큼의 시뇨리지를 L2 시퀀서에게 지급합니다.  ([백서](https://github.com/tokamak-network/papers/blob/master/cryptoeconomics/tokamak-cryptoeconomics-kr.md#222-%ED%86%A4-%EC%8A%A4%ED%85%8C%EC%9D%B4%ED%82%B9-v2ton-staking-v2) 참고)

$S:　TON　스테이킹　금액$ <br/>
$T :　TON　총　발행량$<br/>
$TON seigs :　발행되는　TON　시뇨리지　양$<br/>
$D :　Layer2 들의　총　TON 유동성$<br/>

<figure>
    <img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/1-1.png" alt="V1 의 시뇨리지 분배" width=500>
    <figcaption>V1 의 시뇨리지 분배</figcaption>
</figure>

<figure>
    <img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/1-2.png" alt="V2의 시뇨리지 분배" width=500>
    <figcaption>V2의 시뇨리지 분배</figcaption>
</figure>


## CandidateAddOn 추가

V1에서는 Candidate 가 존재하였습니다. Candidate 는 다오의 위원회가 될 수 있는 Layer2 입니다.

V2에서 추가되는 CandidateAddOn은 Candidate의 모든 기능을 상속받아 다오의 위원회가 될 수 있음과 동시에 Layer2의 시퀀서가 시뇨리지를 받을 수 있습니다.

## 스테이킹 금액을 즉시 Layer2 유동성으로 사용

CandidateAddOn 에서 추가된 기능은, 해당 Layer2의 독자적인 예치 기능을 언스테이킹 기능과 연계하여, 스테이킹된 톤을 인출과 동시에 L2에 예치하는(withdrawAndDepositL2) 함수를 제공합니다.

withdrawAndDepositL2 함수는 스테이킹 금액을 언스테이킹하면서 동시에 Layer2에 예치하는 기능입니다. 이 기능이 V1과 비교했을때의 강점은 언스테이킹 요청 후 대기 시간없이(대기 블록: 93046 블록) 바로 언스테이킹이 가능하다는데 있습니다.  함수 실행 즉시 L1에 묶인 자금을 L2 유동성으로 사용할 수 있습니다.

## CandidateAddOn 의 L2시퀀서 시뇨리지 제공 중지

시뇨리지 위원회는 특정 CandidateAddOn의 레이어2 시퀀서에게 부여되는 시뇨리지를 중지할 수 있습니다. 만일의 경우를 위해 존재하는 기능입니다.

## CandidateAddOn 의 L2시퀀서 시뇨리지 제공 중지 취소

Layer2Candidate의 시뇨리지 중지의 복구는 시뇨리지 위원회에 의해 다시 중지취소가 가능합니다.

# TON Stake Contracts

## TON Stake V1 Contracts

V1 의 컨트랙트는 아래와 같이 구성되어 있다. Candidate는 DAOCommittee를 통해 생성을 할 수 있으며, 생성된 Candidate는 Layer2Registry를 통해 등록되고, SeigManager에 등록되면서, Candidate와 매핑되는 AutoCoinage가 생성된다. AutoCoinage 는 스테이킹 금액을 관리하면서, 복리이자를 지급하기 위한 로직을 보유한다. 때문에 각 레이어 (Candidate) 마다 별도의 AutoCoinage 가 생성된다.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/2-1.png"
         alt="TON Stake V1 Contracts Relationship" width=700></center>
    <figcaption>TON Stake V1 Contracts Relationship</figcaption>
</figure>

## TON Stake V2 Contracts

V2는 V1의 구성을 유지하면서 CandidateAddOn가 추가되었다. 컨트랙트 구성은 아래 그림과 같다. V1에 비해 다소 복잡해보인다. 그러나 파란색 부분의 컨트랙이 추가되었고 기존 구성에는 전혀 변경사항이 없음을 알 수 있다.

<figure>
   <center> <img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/2-2.png"
         alt="TON Stake V2 Contracts Relationship" width=700 ></center>
    <figcaption>TON Stake V2 Contracts Relationship</figcaption>
</figure>

먼저 이해하고 넘어가야 할것은 Layer2를 L1에서 어떻게 확인할 것인가에 대한 문제이다. 우리가 현재 타켓으로 하고 있는 Layer2는 Optimism Rollup이다. 옵티미즘의 레이어2를 먼저 적용하고, 다른 레이어도 적용될수 있도록 컨트랙 업그레이가 가능하게 제작한다.  옵티미즘 레이어2는 legacy버전과 배드락 버전이 있다. 처음 적용 대상은 옵티미즘 레거시 버전과 옵티미즘 배드락버전 중 L2 nativeToken이 톤인 경우로 제한한다는 것을 기억해주길 바란다.

우리는 RollupConfig, RollupType, L2TON 의 정보를 입력받아, 레이어2를 확인할 것이다.

- RollupConfig
  옵티미즘 배드락 버전에는 SystemConfig 컨트랙에 L1컨트랙의 정보와 환경설정이 담겨있다. 따라서 SystemConfig의 주소를 RollupConfig (Layer2를 구별할 수 있는 주소)로 사용할 것이다. 레거시 버전의 경우에는 SystemConfig가 존재하지 않기 때문에, legacySystemConfig 컨트랙을 별도 만들었다. 레거시 레이어2의 경우는 legacySystemConfig 컨트랙을 배포하여, 이 주소를 해당 RollupConfig (Layer2를 구별할 수 있는 주소) 정보로 사용해야 한다.

- RollupType
  옵티미즘 레거시 버전을 0으로 사용하고,
  옵티미즘 배드락 버전이고, native TON을 사용하는 경우는 1 값을 사용한다.
  다른 형태의 롤업을 지원할때 해당 타입을 추가로 지정해주면서 업그레이드한다.

- L2TON
  CandidateAddOn을 등록할때, 해당 레이어2에서 사용하는 L2 TON의 주소를 입력받아야 한다.

# Use case
## For registrant of L1BridgeRegistry
L1BridgeRegistry 컨트랙에 registrant 권한을 가진 계정은 Layer2 의 고유한 정보를 보유하고 있는 RollupConfig를 등록할 수 있다. RollupConfig를 등록한다는 것은 해당 레이어2가 문제가 없는 레이어2라는 것을 확인했다는 의미이다.  등록된 RollupConfig의 레이어2만 CandidateAddOn으로 등록될 수 있다.  CandidateAddOn 이 등록이 되고 나서야 해당 시퀀서가 시뇨리지를 받을 수 있게 된다.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/3-1.png"
         alt="Register SystemConfig" width=400 ></center>
    <figcaption> </figcaption>
</figure>


## For everyone
누구나 L1BridgeRegistry에 등록된 RollupConfig 값으로만 CandidateAddOn을 등록할 수 있다. CandidateAddOn 등록시에는 오퍼레이터 계정으로 최소 예치금 이상을 예치하여야 하므로, 최소예치금에 해당하는 톤을 같이 제공해야 한다. 현재 서비스 기준으로는 최소 1000.1 TON을 제공해야 한다.  ‘CandidateAddOn 등록’ 기능을 통해 OperatorManager, CandidateAddOn, Coinage 컨트랙이 생성된다.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/3-2.png"
         alt="Register CandidateAddOn" width=500 ></center>
    <figcaption> </figcaption>
</figure>


## For staker in CandidateAddOn
CandidateAddOn 에 스테이킹한 사용자는 WithdrawAndDepositL2 기능을 통해 스테이킹을 금액 인출과 동시에 인출된 금액을 해당 Layer2 에 예치하는 기능을 수행할 수 있습니다. 이때 스테이킹 금액을 인출할 때 대기시간없이 바로 인출 및 L2 예치가 됩니다.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/3-3.png"
         alt="Withdraw and deposit to L2" width=500 ></center>
    <figcaption> </figcaption>
</figure>


## For seigniorageCommittee
심플 스테이킹 V2는 CandidateAddOn의 OperatorManager 에게 톤 시뇨리지를 발급하는 이코노미를 설계했습니다. 해당 레이어2 시퀀서는 OperatorManager 컨트랙에 보관된 시뇨리지를 클래임하여 가져갈 수 있습니다.

만일의 경우를 대비해서, 해당 OperatorManager에게 톤 시뇨리지 발급을 중지할 수 있는 기능이 있어야 합니다. L1BridgeRegistry 컨트랙에 시뇨리지 위원회 계정을 만들었습니다. 시뇨리지 위원회는 특정 CandidateAddOn의 시퀀서에 대한 시뇨리지 발급 중지 또는 발급 중지 취소 기능을 수행할 수 있습니다.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/3-4.png"
         alt="Reject and Restore Layer2" width=500 ></center>
    <figcaption> </figcaption>
</figure>


# Sequence Diagrams

## Register CandidateAddOn

CandidateAddOn를 등록할때에는 해당 레이어의 오퍼레이터 이름으로 최소 예치금액 이상을 예치해야 합니다.

CandidateAddOn를 등록시. Layer2의 환경설정 정보를 보유하고 있는 RollupConfig(SystemConfig) 컨트랙 주소를 제시해야 합니다.

또한 입력하는 RollupConfig(SystemConfig)는 등록전에 L1BridgeRegistry에 등록되어 있어야 합니다. ( L1BridgeRegistry에 등록하는 권한은 L1BridgeRegistry의 Registrant 권한을 보유한 계정만 등록이 가능합니다. )

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/4-1.png"
         alt="Reject and Restore Layer2" width=1000 ></center>
    <figcaption> </figcaption>
</figure>

## Withdraw And Deposit L2

CandidateAddOn 에 스테이킹한 사용자는 스테이킹한 금액을 즉시 출금하면서, Layer2에 예치할 수 있습니다.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/4-2.png"
         alt="Reject and Restore Layer2" width=800 ></center>
    <figcaption> </figcaption>
</figure>

## Stop distributing a seigniorage to the L2 sequencer

시뇨리지 위원회는  특정 레이어2가 시뇨리지를 받기에 불합리하다고 판단될때, 해당 레이어2의 시퀀서에게 배분하는 시뇨리지 발급을 중지할 수 있습니다.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/4-3.png"
         alt="Reject and Restore Layer2" width=500 ></center>
    <figcaption> </figcaption>
</figure>

## Cancel stopping distributing a seigniorage to the L2 sequencer

시뇨리지 위원회는  특정 레이어2의 시퀀서에게 배분하는 시뇨리지 발급을 중지했던 것을 취소하여, 다시 시뇨리지를 지급할 수 있습니다.

<figure>
    <center><img src="https://github.com/tokamak-network/ton-staking-v2/blob/staking-v2.5/docs/img/4-4.png"
         alt="Reject and Restore Layer2" width=500 ></center>
    <figcaption> </figcaption>
</figure>


# Contract Details

## L1BridgeRegistry

- 개요
    - 레이어2의 L1 컨트랙 정보가 저장된 컨트랙을 rollupConfig 스토리지에 저장합니다.
    - 옵티미즘 롤업 배드락의 경우, SystemConfig 주소를 rollupConfig 로 지정합니다.
    - 타이탄, 타노스는 어드민에 의해 수동으로 SystemConfig을 rollupConfig로 저장합니다.
    - on-demand L2에서 생성된 컨트랙은 컨트랙 생성시 자동으로 등록됩니다.
    - 추후 다른 레이어(ex, zk-EVM) 지원을 고려하여 프록시로 구성하여 업그레이드 가능해야 합니다.
- 권한
    - Owner :  오너는 로직 업그레이드 권한을 갖으며, 매니저를 지정할 수 있다.
    - Manager : 재단은 MANAGER_ROLE 을 보유하고 있고, 매니저는 Registrant를 등록하거나 제거할 수 있다.
    - Registrant:  on-demand-L2 오픈시, L2를 실제 배포하는 서버의 EOA에게 REGISTRANT_ROLE 을 주어야 한다.
- 스토리지

    ```jsx
    address public layer2Manager;
    address public seigManager;
    address public ton;

    /// rollupConfig - type (0:empty, 1: optimism legacy, 2: optimism bedrock native TON)
    mapping (address => uint8) public rollupType;

    /// For registered bridges, set to true.
    mapping (address => bool) public l1Bridge;

    /// For registered portals, set to true.
    mapping (address => bool) public portal;

    /// Set the layer where seigniorage issuance has been suspended to true.
    mapping (address => bool) public rejectRollupConfig;

    address public seigniorageCommittee;

    /// rollupConfig - l2TON
    mapping (address => address) public l2TON;
    ```

- 이벤트

    ```jsx
    event SetAddresses(address _layer2Manager, address _seigManager, address _ton);
    event SetSeigniorageCommittee(address _seigniorageCommittee);

    /**
    * @notice  Event occurs when registering rollupConfig
    * @param   rollupConfig      the rollupConfig address
    * @param   type_         0: none, 1: legacy, 2: bedrock with nativeTON
    */
    event RegisteredRollupConfig(address rollupConfig, uint8 type_);

    /**
    * @notice  Event occurs when an account with registrant privileges changes the layer 2 type.
    * @param   rollupConfig      the rollupConfig address
    * @param   type_         0: none, 1: legacy, 2: bedrock with nativeTON
    */
    event ChangedType(address rollupConfig, uint8 type_);

    /**
    * @notice  Event occurs when onlySeigniorageCommittee stops issuing seigniorage
    *          to the layer 2 sequencer of a specific rollupConfig.
    * @param   rollupConfig  the rollupConfig address
    */
    event RejectedCandidateAddOn(address rollupConfig);

    /**
    * @notice  Event occurs when onlySeigniorageCommittee cancels stopping issuing seigniorage
    *          to the layer 2 sequencer of a specific rollupConfig.
    * @param   rollupConfig  the rollupConfig address
    */
    event RestoredCandidateAddOn(address rollupConfig);

    /**
    * @notice  Event occurs when a bridge address is registered during system configuration registration.
    * @param   rollupConfig        the rollupConfig address
    * @param   bridge          the bridge address
    */
    event AddedBridge(address rollupConfig, address bridge);

    /**
    * @notice  Event occurs when an optimismPortal address is registered during system configuration registration.
    * @param rollupConfig          the rollupConfig address
    * @param portal            the bridge address
    */
    event AddedPortal(address rollupConfig, address portal);


    ```

- 주요 Transaction Functions
    - function rejectCandidateAddOn(address rollupConfig)  external onlySeigniorageCommittee()

        ```solidity
        /**
        * @notice Stop issuing seigniorage to the layer 2 sequencer of a specific rollupConfig.
        * @param rollupConfig the rollupConfig address
        */
        function rejectCandidateAddOn(
        address rollupConfig
        )  external onlySeigniorageCommittee()
        ```

    - function restoreCandidateAddOn(address _systemConfig)  external onlySeigniorageCommittee()

        ```solidity
        /**
        * Restore cancel stopping seigniorage to the layer 2 sequencer of a specific rollupConfig.
        * @param rollupConfig the rollupConfig address
        */
        function restoreCandidateAddOn(
            address rollupConfig
        )  external onlySeigniorageCommittee()
        ```

    - function registerRollupConfigByManager(address rollupConfig, uint8 _type, address _l2TON) external onlyManager

        ```solidity
        /**
        * @notice Registers Layer2 for a specific rollupConfig by the manager.
        * @param rollupConfig       the rollupConfig address
        * @param _type              1: legacy, 2: bedrock with nativeTON
        */
        function registerRollupConfigByManager(address rollupConfig, uint8 _type, address _l2TON)  external  onlyManager

        ```

    - function registerRollupConfig(address rollupConfig, uint8 _type, address _l2TON) external  onlyRegistrant

        ```solidity
        /**
        * @notice Registers Layer2 for a specific rollupConfig by Registrant.
        * @param rollupConfig       the rollupConfig address
        * @param _type          1: legacy, 2: bedrock with native TON
        */
        function registerRollupConfig(address rollupConfig, uint8 _type, address _l2TON)  external  onlyRegistrant

        ```

    - function changeType(address rollupConfig, uint8 _type)  external  onlyRegistrant

        ```solidity
        /**
        * @notice Changes the Layer2 type for a specific rollupConfig by Registrant.
        * @param rollupConfig the rollupConfig address
        * @param _type          1: legacy, 2: bedrock with native TON
        */
        function changeType(address rollupConfig, uint8 _type)  external  onlyRegistrant
        ```

- 주요 View Functions
    - function layer2TVL(address rollupConfig) public view returns (uint256 amount)

        ```solidity
        /**
        * @notice View the liquidity of Layer2 TON for a specific systemConfig.
        * @param rollupConfig the rollupConfig address
        */
        function layer2TVL(address rollupConfig) public view returns (uint256 amount)
        ```

    - function availableForRegistration(address rollupConfig, uint8 _type) public view returns (bool valid)

        ```solidity
        /**
        * @notice Check whether a specific systemConfig can be registered as a type.
        * @param rollupConfig the rollupConfig address
        * @param _type         1: legacy, 2: bedrock with native TON
        */
        function availableForRegistration(address rollupConfig, uint8 _type) public view returns (bool valid)

        ```

## OperatorManagerFactory

- 개요

    DAOCommittee 에 CandidateAddOn이 멤버로 등록될때 CandidateAddOn의 오퍼레이터 주소가 매핑의 키값으로 등록되기 때문에 오퍼레이터 주소가 변경되어서는 안된다.  그래서, 해당 OperatorManager 컨트랙을 만들어, 오퍼레이터 주소 대신 사용하고, 실제 오퍼레이터는  OperatorManager의 manager로 등록하여, 시뇨리지를 가져갈 수 있도록 설계하였다.  OperatorManager 컨트랙은 RollupConfig 주소에 매핑되는 컨트랙이다. 즉, RollupConfig (L2레이어) 컨트랙 주소로 OperatorManager 컨트랙의 주소를 생성하여야 한다.   추후 로직 변경 가능성이 있으므로, 프록시로 구현하였다.

- 권한
    - 오너 : 오너는 배포되는 오퍼레이터의 로직을 설정할 수 있다.
- 스토리지

    ```jsx
    address public operatorManagerImp;
    address public depositManager;
    address public ton;
    address public wton;
    address public layer2Manager;
    ```

- 이벤트

    ```jsx
    /**
     * @notice Event occurs when set the addresses
    * @param depositManager    the depositManager address
    * @param ton               TON address
    * @param wton              WTON
    * @param layer2Manager     the layer2Manager address
    */
    event SetAddresses(address depositManager, address ton, address wton, address layer2Manager);

    /**
    * @notice Event occurred when changing the operatorManager implimplementationementaion address
    * @param newOperatorManagerImp the operatorManager implementation address
    */
    event ChangedOperatorManagerImp(address newOperatorManagerImp);

    /**
    * @notice Event occurred when creating the OperatorManager Contract
    * @param rollupConfig      the rollupConfig address
    * @param owner             the owner address
    * @param manager           the manager address
    * @param operatorManager   the operatorManager address
    */
    event CreatedOperatorManager(address rollupConfig, address owner, address manager, address operatorManager);

    ```

- 주요  Transaction 함수
    - function changeOperatorManagerImp(address newOperatorManagerImp) external onlyOwner

        ```solidity
        /**
        * @notice Change the operatorManager implementation address by Owner
        * @param newOperatorManagerImp the operatorManager implementation address
        */
        function changeOperatorManagerImp(address newOperatorManagerImp) external onlyOwner
        ```

    - function createOperatorManager(address rollupConfig) external returns (address operator)

        ```solidity
        /**
        * @notice  Create an OperatorManager Contract and return its address.
        *          return revert if the account has already been deployed.
        *          Note. Only Layer2Manager Contract can be called.
        *          When creating the CandidateAddOn, create an OperatorManager contract
        *          that is mapped to RollupConfig.
        * @param rollupConfig  the rollupConfig address
        */
        function createOperatorManager(address rollupConfig) external returns (address operatorManager)

        ```

- 주요 View 함수
    - function getAddress(address rollupConfig) public view returns (address)

        ```solidity
        /**
        * @notice  Returns the operatorManager contract address matching rollupConfig.
        * @param rollupConfig  the rollupConfig address
        */
        function getAddress(address rollupConfig) public view returns (address)
        ```


## OperatorManager

- 개요
    - OperatorManager 컨트랙은 추후 Layer2에서 다중 시퀀서(오퍼레이터)를 지원할 가능성이 있다는 것을 염두에 두고 설계되어야 한다. 따라서 업그레이드 가능한 구조로 설계된다.
    - CandidateAddOn 는 Candidate의 모든 기능을 상속받았다. Candidate의 onlyCandidate 의 정의
        - **Operator.isOperator(msg.sender)** 가 true인 계정을 의미하며, OperatorManager 의 manager로 지정된 계정이 CandidateAddOn의 오퍼레이터 함수를 사용할수 있다.
- 권한
   - owner
        - 프록시 오너로서, 로직을 업그레이드 할 수 있다.
        - 매니저를 변경할 수 있다.
    - manager
        - 관리자는 레이어2의 시퀀서로 지정하며, 최초 배포시 RollupConfig(SystemConfig)의 owner()를 manager 로 지정한다.
        - 추후 RollupConfig(SystemConfig)의 오너가 변경될때, transferManager 를 이용하여 manager를 변경해야 한다. (SystemConfig.owner 가 manager를 가져갈 수 있는 인터페이스를 제공한다.)
        - CandidateAddOn 의 오퍼레이터 권한을 보유하여, 다오멤버의 함수를 사용할 수 있다.
            - Candidate에서 상속받은 onlyCandidate가 사용할 수 있는 함수를 실행할 수 있다.
            - changeMember 함수 → OperatorManager 컨트랙이 다오의 멤버가 된다.
            - retireMember 함수 → OperatorManager 컨트랙이 다오 멤버에서 사임한다.
            - castVote 함수  → OperatorManager 컨트랙 이름으로 안건에 투표한다.
            - claimActivityReward 함수 → 리워드는 OperatorManager 컨트랙이 받는다.
    - RollupConfig 컨트랙은 반드시 owner() 함수를 지원해야 한다.
- 스토리지

    ```jsx
    address public rollupConfig;
    address public layer2Manager;
    address public depositManager;
    address public ton;
    address public wton;

    address public manager;
    string public explorer;
    ```

- 이벤트

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

    /**
    * @notice Event occurs when setting the explorer url
    * @param _explorer a explorer url
    */
    event SetExplorer(string _explorer);

    ```

- 주요  Transaction 함수
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

    - function depositByCandidateAddOn(uint256 amount) external onlyCandidateAddOn

        ```jsx
        /**
        * @notice Deposit wton amount to DepositManager as named Layer2
        * @param amount    the deposit wton amount (ray)
        */
        function depositByCandidateAddOn(uint256 amount) external onlyCandidateAddOn
        ```

    - function claimByCandidateAddOn(uint256 amount) external onlyCandidateAddOn

        ```jsx
        /**
         * @notice Claim WTON to a manager
        * @param amount    the deposit wton amount (ray)
        */
        function claimByCandidateAddOn(uint256 amount) external onlyCandidateAddOn
        ```

- 주요 View 함수
    - function acquireManager() external

        ```jsx
        /**
         * @notice acquire manager privileges.
         */
        function acquireManager() external
        ```

    - function isOperator(address addr) public view returns (bool)

        ```jsx
        /**
         * @notice Returns true if the the addr is a manager.
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
- 개요
    - Layer2 시퀀서가 시뇨리지를 받기 위해서는 RollupConfig(SystemConfig) 주소를  Layer2Manager에 등록해야 합니다.
    - 시뇨리지 분배시, Layer2의 시퀀서들에게 지급되는 시뇨리지를 Layer2Manager에게 지급합니다. 따라서 Layer2Manager는 특정 CandidateAddOn의 시퀀서 시뇨리지 정산 전까지 해당 시뇨리지를 보유하게 됩니다.
- 권한
    - Owner :  오너는 로직 업그레이드 권한을 갖으며, 설정값들을 설정할 수 있다.
- 스토리지

    ```jsx
    struct CandidateAddOnInfo {
        address rollupConfig;
        address candidateAddOn;
    }

    struct SeqSeigStatus {
        uint8 status; // status for giving seigniorage ( 0: none, 1: registered, 2: paused )
        address operatorManager;
    }

    address public l1BridgeRegistry;
    address public operatorManagerFactory;

    address public ton;
    address public wton;
    address public dao;
    address public depositManager;
    address public seigManager;
    address public swapProxy;

    uint256 public minimumInitialDepositAmount;   /// ton

    /// rollupConfig - SeqSeigStatus
    mapping (address => SeqSeigStatus) public rollupConfigInfo;

    /// operator - CandidateAddOnInfo
    mapping (address => CandidateAddOnInfo) public operatorInfo;

    ```

- 이벤트

    ```jsx
    /**
    * @notice Event occurs when setting the minimum initial deposit amount
    * @param _minimumInitialDepositAmount the minimum initial deposit amount
    */
    event SetMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount);

    /**
    * @notice Event occurs when registering CandidateAddOn
    * @param rollupConfig      the rollupConfig address
    * @param wtonAmount        the wton amount depositing when registering CandidateAddOn
    * @param memo              the name of CandidateAddOn
    * @param operator          an operator contract address
    * @param candidateAddOn    a candidateAddOn address
    */
    event RegisteredCandidateAddOn(address rollupConfig, uint256 wtonAmount, string memo, address operator, address candidateAddOn);

    /**
    * @notice Event occurs when pausing the CandidateAddOn
    * @param rollupConfig      the rollupConfig address
    * @param candidateAddOn    the candidateAddOn address
    */
    event PausedCandidateAddOn(address rollupConfig, address candidateAddOn);

    /**
    * @notice Event occurs when pausing the CandidateAddOn
    * @param rollupConfig      the rollupConfig address
    * @param candidateAddOn    the candidateAddOn address
    */
    event UnpausedCandidateAddOn(address rollupConfig, address candidateAddOn);
    ```

- 주요  Transaction 함수
    - function registerCandidateAddOn(address rollupConfig, uint256 amount, bool flagTon, string calldata memo) external

        ```jsx
       /**
        * @notice Register the CandidateAddOn
        * @param rollupConfig     rollupConfig's address
        * @param amount           transferred amount
        * @param flagTon          if true, amount is ton, otherwise it wton
        * @param memo             layer's name
        */
        function registerCandidateAddOn(
        address rollupConfig,
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

    - function pauseCandidateAddOn(address rollupConfig) external onlyL1BridgeRegistry ifFree

        ```jsx
        /**
         * @notice Pause the CandidateAddOn
        * @param rollupConfig the rollupConfig address
        */
        function pauseCandidateAddOn(address rollupConfig) external onlyL1BridgeRegistry ifFree
        ```

    - function unpauseCandidateAddOn(address rollupConfig) external onlyL1BridgeRegistry ifFree

        ```solidity
        /**
        * @notice Unpause the CandidateAddOn
        * @param rollupConfig the rollupConfig address
        */
        function unpauseCandidateAddOn(address rollupConfig) external onlyL1BridgeRegistry ifFree
        ```

    - function updateSeigniorage(address rollupConfig, uint256 amount) external onlySeigManger

        ```jsx
        /**
         * @notice When executing update seigniorage, the seigniorage is settled to the Operator of Layer 2.
        * @param rollupConfig the rollupConfig address
        * @param amount the amount to give a seigniorage
        */
        function updateSeigniorage(address rollupConfig, uint256 amount) external onlySeigManger
        ```

    - function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)  external  onlyOwner

        ```jsx
        /**
         * @notice  Set the minimum TON deposit amount required when creating a CandidateAddOn.
        *          Due to calculating swton, it is recommended to set DepositManager's minimum deposit + 0.1 TON
        * @param _minimumInitialDepositAmount the minimum initial deposit amount
        */
        function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)  external  onlyOwner
        ```

- 주요 View 함수
    - function candidateAddOnOfOperator(address _oper) external view returns (address)

        ```jsx
        /**
         * @notice  View the CandidateAddOn address of the operator address.
        * @param _oper     the operator address
        * @return          the candidateAddOn address
        */
        function candidateAddOnOfOperator(address _oper) external view returns (address)
        ```

    - function operatorOfRollupConfig(address _rollupConfig) external view returns (address)

        ```jsx
        /**
         * @notice View the operator address of the rollupConfig address.
        * @param _rollupConfig      the rollupConfig address
        * @return                   the operator address
        */
        function operatorOfRollupConfig(address _rollupConfig) external view returns (address)
        ```

    - function candidateAddOnOfOperator(address _oper) external view returns (address)

        ```jsx
        /**
         * @notice  View the candidateAddOn address of the operator address.
         * @param _oper     the operator address
         * @return          the candidateAddOn address
         */
        function candidateAddOnOfOperator(address _oper) external view returns (address)
        ```

    - function statusLayer2(address _rollupConfig) external view returns (uint8)

        ```jsx
        /**
        * @notice View the status of seigniorage provision for Layer 2 corresponding to rollupConfig.
        * @param _rollupConfig   the rollupConfig address
        * @return                the status of seigniorage provision for Layer 2
        *                        ( 0: none , 1: registered, 2: paused )
        */
        function statusLayer2(address _rollupConfig) external view returns (uint8)
        ```

    - function checkLayer2TVL(address _rollupConfig) public view returns (bool result, uint256 amount)

        ```jsx
        /**
         * @notice  Check Layer 2’s TON liquidity-related information
        * @param _rollupConfig the rollupConfig address
        * @return result       whether layer 2 TON liquidity can be checked
        * @return amount       the layer 2's TON amount (total value liquidity)
        */
        function checkLayer2TVL(address _rollupConfig) public view returns (bool result, uint256 amount)
        ```

    - function checkL1Bridge(address _rollupConfig) public view returns (bool result, address l1Bridge, address portal, address l2Ton)

        ```jsx
        /**
        * @notice Layer 2 related information search
        * @param _rollupConfig     the rollupConfig address
        * @return result           whether Layer2 information can be searched
        * @return l1Bridge         the L1 bridge address
        * @return portal           the optimism portal address
        * @return l2Ton            the L2 TON address
        */
        function checkL1Bridge(address _rollupConfig) public view returns (bool result, address l1Bridge, address portal, address l2Ton)

        ```


## CandidateAddOnFactory

- 개요
    - CandidateAddOn 를 생성하는 컨트랙입니다.
- 권한
    - Owner :  오너는 로직 업그레이드 권한을 갖으며, 설정값들을 설정할 수 있다.
- 스토리지

    ```jsx
    address public depositManager;
    address public daoCommittee;
    address public layer2CandidateImp;
    address public ton;
    address public wton;

    address public onDemandL1BridgeRegistry;
    ```

- 이벤트

    ```jsx
    /**
     * @notice  Event that occurs when a Candidate is created
    * @param sender            the sender address
    * @param layer2            the layer2(candidate) address
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

- 주요  Transaction 함수
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



## CandidateAddOn

- 개요
    - 심플스테이킹(톤 스테이킹)의 기본기능(예치, 업데이트시뇨리지-이자지급, 출금 기능)을 지원한다.
    - Candidate에서 할 수 있는 다오 멤버 기능을 지원한다.
    - 업데이트 시뇨리지 실행시, CandidateAddOn의 레이어2 시퀀서(오퍼레이터)가 시뇨리지를 받을 수 있다.
- 권한
    - Owner : 오너는 로직 업그레이드 권한을 갖으며, 설정값을 초기화 할 수 있다.
    - onlyCandidate : CandidateAddOn 에 매칭되는 OperatorManager 컨트랙의 manager 계정

        ```jsx
         modifier onlyCandidate() {
              require(IOperateContract(candidate).isOperator(msg.sender),
              "sender is not an operator");
              _;
          }
        ```

- 스토리지

    ```solidity
        mapping(bytes4 => bool) internal _supportedInterfaces;
        bool public isLayer2Candidate;
        address public candidate;  /// operatorManager
        string public memo;

        address public committee;
        address public seigManager;
        address public ton;
        address public wton;
    ```

- 이벤트

    ```jsx
    event Initialized(address _operateContract, string memo, address committee, address seigManager);
    event SetMemo(string _memo);
    ```

- 주요  Transaction 함수
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

- 주요 View 함수
    - function totalStaked() external  view returns (uint256 totalsupply)

        ```jsx
        /// @notice Retrieves the total staked balance on this candidate
        /// @return totalSupply Total staked amount on this candidate
        function totalStaked()
            external
            view
            returns (uint256 totalSupply)
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
- 개요
    - CandidateAddOn의 업데이트 시뇨리지 실행시, layer2의 TON TVL에 따라  Layer2 시퀀서에게 시뇨리지를 지급해야 하며, 지급되는 시뇨리지는 OperatorManager 컨트랙에게 정산됩니다.
    - OperatorManager 컨트랙의 manager 계정은  CandidateAddOn 의  업데이트 시뇨리지 실행(시뇨리지 분배시)시, 청구 및 스테이킹 옵션을 선택해서, 시뇨리지 정산과 동시에 청구 또는 스테이킹 기능을  같이 실행할 수 있습니다.
    - L2 시퀀서에게 분배되는 시뇨리지 분배로직은 [V2 백서](https://github.com/tokamak-network/papers/blob/master/cryptoeconomics/tokamak-cryptoeconomics-en.md#222-ton-staking-v2)의 시뇨리지 배분 규칙에 따라 이루어진다.
    - V1에서 이미 SeigManager 가 배포되어 운영되고 있으므로, 다른 기능은 변경없이 업데이트 시뇨리지 함수만  SeigManagerV1_3에 변경된 로직으로 실행되도록 한다.
    - 업데이트 시뇨리지 함수실행시 Layer2에게 제공하는 시뇨리지를 관리하기 위한 스토리지를 추가한다.


- 추가된 스토리지

    ```jsx
    struct Layer2Reward {
        uint256 layer2Tvl;
        uint256 initialDebt;
    }

    /// L1BridgeRegistry address
    address public L1BridgeRegistry;

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

- 삭제된 이벤트

    업데이트 시뇨리지 실행시 발생하던 SeigGiven 이벤트가 삭제되었다.

    ```jsx
    event SeigGiven(address indexed layer2, uint256 totalSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 pseig);
    ```

- 추가된 이벤트

    업데이트 시뇨리지 실행시 아래 SeigGiven2 이벤트가 추가 발생한다.

    ```jsx
    /**
     * Event that occurs when seigniorage is distributed when update seigniorage is executed
     * @param layer2        The layer2(candidateAddOn) address
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
     *                      to CandidateAddOn's operator contract
     */
    event SeigGiven2(address indexed layer2, uint256 totalSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 pseig, uint256 l2TotalSeigs, uint256 layer2Seigs);

    ```

- 주요  Transaction 함수
    - function excludeFromSeigniorage (address _layer2) external returns (bool) onlyLayer2Manager

        ```
        /**
        * @notice Exclude the layer2 in distributing a seigniorage
        * @param _layer2     the layer2(candidate) address
        */
        function excludeFromSeigniorage (address _layer2)
        external
        returns (bool)
        ```

    - function updateSeigniorageOperator() external  returns (bool)  onlyCandidate

        ```jsx
        /**
        * @notice Distribute the issuing seigniorage.
        *         If caller is a CandidateAddOn, the seigniorage is settled to the L2 OperatorManager.
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

- 주요 View 함수
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
        * @return layer2Seigs        the amount currently to be settled (give)  to CandidateAddOn's operator contract
        */
        function estimatedDistribute(uint256 blockNumber, address layer2, bool _isSenderOperator)
        external view
        returns (uint256 maxSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 relativeSeig, uint256 l2TotalSeigs, uint256 layer2Seigs)
        ```



## DepositManagerV1_1

- 개요
    - CandidateAddOn 의 경우라면 톤스테이킹출금을 하면서, 동시에 해당 Layer2에 예치할 수 있는 기능 (withdrawAndDepositL2) 을 지원한다. 이 때에는 출금시 지연시간 없이 즉시 출금 후, L1에 예치된다.
    - CandidateAddOn가 아닌 레이어에 withdrawAndDepositL2 함수를 요청할때는 에러를 발생한다.
    - DepositManagerProxy에 기존 로직은 그대로 두고, withdrawAndDepositL2 함수만 추가되도록 한다.
- 스토리지

    ```jsx
    address public ton;
    uint32 public minDepositGasLimit; /// not used
    ```

- 이벤트

    ```jsx
    /**
     * @notice Event that occurs when calling the withdrawAndDepositL2 function
     * @param layer2    The layer2(candidate) address
     * @param account   The account address
     * @param amount    The amount of withdrawal and deposit L2
     */
    event WithdrawalAndDeposited(address indexed layer2, address account, uint256 amount);

    ```

- 주요  Transaction 함수
    - function withdrawAndDepositL2(address layer2, uint256 amount) external ifFree returns (bool)

    ```jsx
    /**
     * @notice Withdrawal from L1 and deposit to L2
     * @param layer2    The layer2(candidate) address
     * @param amount    The amount to be withdrawal and deposit L2. ()`amount` WTON in RAY)
     */
    function withdrawAndDepositL2(address layer2, uint256 amount) external ifFree returns (bool)
    ```

