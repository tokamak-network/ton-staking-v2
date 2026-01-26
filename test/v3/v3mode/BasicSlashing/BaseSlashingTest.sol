// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {DeployV3WithSlashing} from "../../../../script/DeployV3WithSlashing.s.sol";
import {Layer2Manager_Slashing} from "../../../../src/layer2/Layer2Manager_Slashing.sol";
import {DepositManager_Slashing} from "../../../../src/stake/managers/DepositManager_Slashing.sol";
import {SeigManager_Slashing} from "../../../../src/stake/managers/SeigManager_Slashing.sol";
import {DepositManagerV3} from "../../../../src/stake/managers/DepositManagerV3.sol";
import {SeigManagerV1_2} from "../../../../src/stake/managers/SeigManagerV1_2.sol";
import {Layer2ManagerV3} from "../../../../src/layer2/Layer2ManagerV3.sol";
import {L1BridgeRegistryV1_2} from "../../../../src/layer2/L1BridgeRegistryV1_2.sol";
import {AuthControlL1BridgeRegistry} from "../../../../src/common/AuthControlL1BridgeRegistry.sol";
import {IWTON} from "../../../../src/dao/interfaces/IWTON.sol";
import {ITON} from "../../../../src/stake/interfaces/ITON.sol";
import {GameType, Claim, Position, Clock} from "../../../../src/layer2/lib/LibUDT.sol";
import {GameStatus} from "../../../../src/layer2/lib/Types.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RATProxy} from "../../../../src/validator/RATProxy.sol";
import {ValidatorRewardProxy} from "../../../../src/validator/ValidatorRewardProxy.sol";
import {MockTON} from "../../../../src/mocks/MockTON.sol";
import {MockWTON} from "../../../../src/mocks/MockWTON.sol";
import {MockDisputeGameFactory} from "../../../../src/mocks/MockDisputeGameFactory.sol";
import {MockFaultDisputeGame2} from "../../../../src/mocks/MockFaultDisputeGame2.sol";
import {
    RefactorCoinageSnapshotI
} from "../../../../src/stake/interfaces/RefactorCoinageSnapshotI.sol";
import {CandidateAddOnV1_1} from "../../../../src/dao/CandidateAddOnV1_1.sol";

/// @title BaseSlashingTest
/// @notice Base test contract for slashing tests with shared setup and helpers
abstract contract BaseSlashingTest is Test, DeployV3WithSlashing {
    address public operator = makeAddr("operator");
    address public challenger = makeAddr("challenger");
    address public rollupConfig = makeAddr("mockRollupConfig");

    event onSlashed(address layer2, address operator);
    event Slashed(
        address indexed layer2,
        address indexed operator,
        address indexed challenger,
        uint256 slashedAmount,
        uint256 rewardAmount
    );
    event ChallengerRewarded(address indexed layer2, address indexed challenger, uint256 amount);

    function setUp() public virtual {
        address admin = makeAddr("proxyAdmin");
        address owner = address(this);

        // IMPORTANT: Set proxyAdmin before _deployV3Contracts is called
        // as it uses proxyAdmin for RAT and ValidatorReward proxy admin
        proxyAdmin = admin;

        vm.startPrank(owner);

        // 1. Deploy entire system
        _deployTokens();
        _deployCoinageInfrastructure(owner);
        _deployLayer2Registry(owner);
        _deployManagerProxies();
        _deployManagerImplementations();

        // Slashing implementations
        _deploySlashingImplementations();

        _initializeManagers(owner);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(owner);

        _deployV3Contracts(owner);

        // No need to change admin anymore since proxyAdmin is already set correctly
        // RATProxy(payable(ratProxy)).changeAdmin(admin);
        // ValidatorRewardProxy(payable(validatorPoolProxy)).changeAdmin(admin);

        _setupCrossReferences(owner);

        // 2. Deploy DAO contracts
        _deployDAOVault();
        _deployDAOAgendaManager();
        _deployDAOCommittee();
        _addMinterSetting();
        _addSeigManagerSetting();
        _setupContractOwner();

        vm.stopPrank();

        // 3. Setup permissions
        vm.prank(daoCommitteeProxy);
        AuthControlL1BridgeRegistry(l1BridgeRegistryProxy).addManager(address(this));
        AuthControlL1BridgeRegistry(l1BridgeRegistryProxy).addRegistrant(address(this));

        // 4. Mock rollup infrastructure
        _setupRollupMocks(rollupConfig);

        // 5. Register rollup
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfig(
            rollupConfig,
            2, // Bedrock
            makeAddr("l2TON"),
            "TestRollup"
        );

        vm.label(operator, "Operator");
        vm.label(challenger, "Challenger");
        vm.label(daoCommitteeProxy, "DAOCommittee");
    }

    /// @notice Setup mock calls for a rollup config
    function _setupRollupMocks(address _rollupConfig) internal {
        vm.mockCall(
            _rollupConfig,
            abi.encodeWithSignature("l1StandardBridge()"),
            abi.encode(makeAddr("mockL1Bridge"))
        );
        vm.mockCall(
            _rollupConfig,
            abi.encodeWithSignature("optimismPortal()"),
            abi.encode(makeAddr("mockPortal"))
        );
        vm.mockCall(
            _rollupConfig,
            abi.encodeWithSignature("unsafeBlockSigner()"),
            abi.encode(makeAddr("mockUnsafeBlockSigner"))
        );
        // Default dispute game factory - can be overridden in tests
        vm.mockCall(
            _rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(0))
        );
    }

    /// @notice Register candidate and stake for an operator
    function _registerCandidateAndStake(
        address _operator,
        address _rollupConfig,
        uint256 _stakeAmount
    ) internal returns (address operatorManager, address candidateAddOn) {
        MockTON(ton).mint(_operator, _stakeAmount);

        vm.startPrank(_operator);
        IERC20(ton).approve(layer2ManagerProxy, _stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            _rollupConfig,
            _stakeAmount,
            true, // Use TON
            "TestOperator"
        );
        vm.stopPrank();

        operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(_rollupConfig);
        candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
    }

    /// @notice Setup dispute game factory and create a game
    function _setupDisputeGame(
        address _rollupConfig,
        GameType _gameType,
        Claim _rootClaim,
        bytes memory _extraData
    ) internal returns (MockDisputeGameFactory gameFactory, MockFaultDisputeGame2 game) {
        gameFactory = new MockDisputeGameFactory();

        vm.mockCall(
            _rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        game = MockFaultDisputeGame2(
            address(gameFactory.create(_gameType, _rootClaim, _extraData))
        );
        game.initialize();
    }

    /// @notice Make challenger win the dispute game
    function _makeChallengerWin(MockFaultDisputeGame2 _game) internal virtual {
        vm.prank(challenger);
        _game.step();
        _game.resolve();
    }

    /// @notice Execute slashing for an operator
    function _executeSlashing(
        address _operatorManager,
        GameType _gameType,
        Claim _rootClaim,
        bytes memory _extraData,
        address _game
    ) internal {
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            _operatorManager,
            _gameType,
            _rootClaim,
            _extraData,
            _game
        );
    }

    /// @notice Get stake of an account in a candidate
    function _getStakeOf(
        address _candidateAddOn,
        address _account
    ) internal view returns (uint256) {
        return SeigManagerV1_2(seigManagerProxy).stakeOf(_candidateAddOn, _account);
    }

    /// @notice Get WTON balance of an account
    function _getWtonBalance(address _account) internal view returns (uint256) {
        return IWTON(wton).balanceOf(_account);
    }

    /// @notice Get slashing reward rate
    function _getSlashingRewardRate() internal view returns (uint256) {
        return DepositManager_Slashing(address(depositManagerProxy)).slashingRewardRate();
    }

    /// @notice Set slashing reward rate (must be called by daoCommitteeProxy)
    function _setSlashingRewardRate(uint256 _rate) internal {
        vm.prank(daoCommitteeProxy);
        DepositManager_Slashing(address(depositManagerProxy)).setSlashingRewardRate(_rate);
    }

    /// @notice Update seigniorage for a candidate
    function _updateSeigniorage(address _candidateAddOn) internal returns (bool) {
        return CandidateAddOnV1_1(_candidateAddOn).updateSeigniorage();
    }

    /// @notice Get default game parameters
    function _getDefaultGameParams()
        internal
        pure
        returns (GameType gameType, Claim rootClaim, bytes memory extraData)
    {
        gameType = GameType.wrap(0);
        rootClaim = Claim.wrap(bytes32(uint256(1)));
        extraData = hex"1234";
    }
}
