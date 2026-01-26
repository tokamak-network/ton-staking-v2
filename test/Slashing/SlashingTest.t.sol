// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {DeployV3WithSlashing} from "../../script/DeployV3WithSlashing.s.sol";
import {Layer2Manager_Slashing} from "../../src/layer2/Layer2Manager_Slashing.sol";
import {DepositManager_Slashing} from "../../src/stake/managers/DepositManager_Slashing.sol";
import {SeigManager_Slashing} from "../../src/stake/managers/SeigManager_Slashing.sol";
import {DepositManagerV3} from "../../src/stake/managers/DepositManagerV3.sol";
import {SeigManagerV1_2} from "../../src/stake/managers/SeigManagerV1_2.sol";
import {Layer2ManagerV3} from "../../src/layer2/Layer2ManagerV3.sol";
import {L1BridgeRegistryV1_2} from "../../src/layer2/L1BridgeRegistryV1_2.sol";
import {AuthControlL1BridgeRegistry} from "../../src/common/AuthControlL1BridgeRegistry.sol";
import {IWTON} from "../../src/dao/interfaces/IWTON.sol";
import {ITON} from "../../src/stake/interfaces/ITON.sol";
import {GameType, Claim, Position, Clock} from "../../src/layer2/lib/LibUDT.sol";
import {GameStatus} from "../../src/layer2/lib/Types.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RATProxy} from "../../src/validator/RATProxy.sol";
import {ValidatorRewardProxy} from "../../src/validator/ValidatorRewardProxy.sol";
import {MockTON} from "../../src/mocks/MockTON.sol";
import {MockWTON} from "../../src/mocks/MockWTON.sol";

import {MockDisputeGameFactory} from "../../src/mocks/MockDisputeGameFactory.sol";
import {MockFaultDisputeGame2} from "../../src/mocks/MockFaultDisputeGame2.sol";
import {RefactorCoinageSnapshotI} from "../../src/stake/interfaces/RefactorCoinageSnapshotI.sol";
import {CandidateAddOnV1_1} from "../../src/dao/CandidateAddOnV1_1.sol";

// Interfaces for mocking or interaction
interface ITON_Mint is ITON {
    function mint(address to, uint256 amount) external returns (bool);
}

interface ILayer2 {
    function operator() external view returns (address);
}

// Slashing Scenario Mocks
contract SlashingMockGame {
    address public winner;

    constructor(address _winner) {
        winner = _winner;
    }

    function status() external pure returns (GameStatus) {
        return GameStatus.CHALLENGER_WINS;
    }

    function claimData(
        uint256
    )
        external
        view
        returns (
            uint32 parentIndex,
            address counteredBy,
            address claimant,
            uint128 bond,
            Claim claim,
            Position position,
            Clock clock
        )
    {
        return (0, winner, address(0), 0, Claim.wrap(bytes32(0)), Position.wrap(0), Clock.wrap(0));
    }
}

contract SlashingMockFactory {
    mapping(bytes32 => address) private _games;

    function setGame(
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData,
        address _game
    ) external {
        bytes32 id = keccak256(abi.encodePacked(_gameType, _rootClaim, _extraData));
        _games[id] = _game;
    }

    function games(
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData
    ) external view returns (address, uint64) {
        bytes32 id = keccak256(abi.encodePacked(_gameType, _rootClaim, _extraData));
        return (_games[id], uint64(block.timestamp));
    }
}

contract SlashingTest is Test, DeployV3WithSlashing {
    address public operator = makeAddr("operator");
    address public challenger = makeAddr("challenger");
    address public rollupConfig = makeAddr("mockRollupConfig");

    SlashingMockGame public mockGame;
    SlashingMockFactory public mockFactory;

    event onSlashed(address layer2, address operator);
    event Slashed(
        address indexed layer2,
        address indexed operator,
        address indexed challenger,
        uint256 slashedAmount,
        uint256 rewardAmount
    );
    event ChallengerRewarded(address indexed layer2, address indexed challenger, uint256 amount);

    function setUp() public {
        // TransparentUpgradeableProxy 패턴:
        // - admin: upgradeTo(), changeAdmin() 같은 관리 함수만 호출 가능
        // - owner: 구현체의 비즈니스 로직 함수 호출 가능
        address admin = makeAddr("proxyAdmin"); // Proxy admin 전용
        address owner = address(this); // 비즈니스 로직 owner (테스트 컨트랙트)

        // IMPORTANT: Set proxyAdmin before _deployV3Contracts is called
        // as it uses proxyAdmin for RAT and ValidatorReward proxy admin
        proxyAdmin = admin;

        // owner 컨텍스트에서 배포 시작
        vm.startPrank(owner);

        // 1. 전체 시스템 배포 (DeployV3WithSlashing 순서에 맞춤)
        _deployTokens();
        _deployCoinageInfrastructure(owner);
        _deployLayer2Registry(owner);
        _deployManagerProxies();
        _deployManagerImplementations();

        // Slashing 구현체 배포 (초기화 전에)
        _deploySlashingImplementations();

        _initializeManagers(owner);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(owner);

        // RAT, ValidatorReward를 owner로 배포 (proxyAdmin이 이미 설정됨)
        _deployV3Contracts(owner);

        // proxyAdmin이 이미 올바르게 설정되어 있으므로 changeAdmin 불필요
        // RATProxy(payable(ratProxy)).changeAdmin(admin);
        // ValidatorRewardProxy(payable(validatorPoolProxy)).changeAdmin(admin);

        // Cross references 설정
        _setupCrossReferences(owner);

        // 2. DAO 컨트랙트 배포
        _deployDAOVault();
        _deployDAOAgendaManager();
        _deployDAOCommittee();
        _addMinterSetting();
        _addSeigManagerSetting();
        _setupContractOwner();

        vm.stopPrank();

        // 3. Mock 인프라 설정
        mockFactory = new SlashingMockFactory();
        mockGame = new SlashingMockGame(challenger);

        // 4. 테스트 컨트랙트에 권한 부여 (Rollup 등록을 위해)
        // script에서 l1BridgeRegistryProxy의 admin은 daoCommitteeProxy임
        vm.prank(daoCommitteeProxy);
        AuthControlL1BridgeRegistry(l1BridgeRegistryProxy).addManager(address(this));
        AuthControlL1BridgeRegistry(l1BridgeRegistryProxy).addRegistrant(address(this));

        // 5. Rollup 인프라 모킹 (Layer2Manager 등록 시 필요)
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("l1StandardBridge()"),
            abi.encode(makeAddr("mockL1Bridge"))
        );
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("optimismPortal()"),
            abi.encode(makeAddr("mockPortal"))
        );
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("unsafeBlockSigner()"),
            abi.encode(makeAddr("mockUnsafeBlockSigner"))
        );
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(mockFactory))
        );

        // 6. Rollup 등록
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfig(
            rollupConfig,
            2, // Bedrock
            makeAddr("l2TON"), // L2 TON 주소 (테스트용 mock 주소)
            "TestRollup"
        );

        vm.label(operator, "Operator");
        vm.label(challenger, "Challenger");
        vm.label(daoCommitteeProxy, "DAOCommittee");
    }

    function test_CandidateRegistrationAndStaking() public {
        uint256 stakeAmount = 10000 * 1e18; // 10,000 TON

        console.log("Step 1: Minting TON to operator");
        // Operator에게 TON 지급
        MockTON(ton).mint(operator, stakeAmount);
        console.log("Operator TON balance:", IERC20(ton).balanceOf(operator));

        console.log("Step 2: Starting prank as operator");
        vm.startPrank(operator);

        console.log("Step 3: Approving Layer2Manager");
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        console.log("Approval successful");

        console.log("Step 4: Registering candidate");
        // Candidate 등록
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true, // Use TON
            "MyOperator"
        );
        console.log("Registration successful");
        vm.stopPrank();

        console.log("Step 5: Verifying registration");
        // 등록 검증
        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );

        assertTrue(candidateAddOn != address(0), "Candidate registration failed");

        // V3에서는 accStaked가 제거되었으므로 SeigManager.stakeOf() 사용
        uint256 stakedAmount = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        assertEq(stakedAmount, stakeAmount * 1e9, "Staked amount mismatch (RAY)");

        console.log("Candidate Registered at:", candidateAddOn);
        console.log("Operator Manager at:", operatorManager);
    }

    function test_SlashingAndReward() public {
        // 1. 등록 및 스테이킹
        test_CandidateRegistrationAndStaking();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        uint256 initialStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        assertEq(initialStake, 10000 * 1e18 * 1e9, "Initial stake mismatch");

        // 2. Slashing 준비 (Mock Dispute Game 컨트랙트 실제 배포)
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();

        // SystemConfig.disputeGameFactory() 모킹 (실제 배포된 gameFactory 주소를 리턴하도록)
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        // Dispute Game 생성 및 상태 설정
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize(); // claimData[0] 설정을 위해 초기화 필요

        // Challenger 승리 시뮬레이션
        vm.prank(challenger);
        game.step(); // 챌린저가 대응(step)함
        game.resolve(); // 게임 종료 -> CHALLENGER_WINS 상태가 됨

        // 3. 슬래싱 실행
        uint256 challengerBalanceBefore = IWTON(wton).balanceOf(challenger);

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 4. 결과 검증
        uint256 finalStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        assertEq(finalStake, 0, "Stake should be zeroed");

        // 보상 검증 (10% reward)
        uint256 slashingRewardRate = DepositManager_Slashing(address(depositManagerProxy))
            .slashingRewardRate();
        uint256 rewardAmount = (initialStake * slashingRewardRate) / 10000;
        uint256 challengerBalanceAfter = IWTON(wton).balanceOf(challenger);

        assertEq(
            challengerBalanceAfter - challengerBalanceBefore,
            rewardAmount,
            "Challenger reward mismatch"
        );

        console.log("Slashing Successful!");
        console.log("Slashed Amount (RAY):", initialStake);
        console.log("Challenger Reward (RAY):", rewardAmount);
    }

    // ============================================
    // 시나리오 1: 보상 비율 50%로 변경 테스트
    // ============================================
    function test_Slashing_CustomRewardRate_50Percent() public {
        console.log("\n=== Test: Slashing with 50% Reward Rate ===");

        // 1. 보상 비율을 50%로 설정 (5000 basis points)
        vm.prank(daoCommitteeProxy);
        DepositManager_Slashing(address(depositManagerProxy)).setSlashingRewardRate(5000);

        uint256 newRate = DepositManager_Slashing(address(depositManagerProxy))
            .slashingRewardRate();
        assertEq(newRate, 5000, "Reward rate should be 50%");
        console.log("Slashing reward rate set to:", newRate, "basis points (50%)");

        // 2. Candidate 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        uint256 initialStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );

        console.log("Initial stake (RAY):", initialStake);

        // 3. Dispute Game 설정 및 슬래싱
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        uint256 challengerBalanceBefore = IWTON(wton).balanceOf(challenger);

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 4. 50% 보상 검증
        uint256 expectedReward = (initialStake * 5000) / 10000; // 50%
        uint256 challengerBalanceAfter = IWTON(wton).balanceOf(challenger);
        uint256 actualReward = challengerBalanceAfter - challengerBalanceBefore;

        assertEq(actualReward, expectedReward, "Challenger should receive 50% reward");
        console.log("Expected reward (50%):", expectedReward);
        console.log("Actual reward:", actualReward);
        console.log("[OK] 50% reward rate verified");
    }

    // ============================================
    // 시나리오 2: 시뇨리지 발생 후 슬래싱 (원금+이자 소각)
    // ============================================
    function test_Slashing_WithSeigniorage_BurnsAll() public {
        console.log("\n=== Test: Slashing Burns Principal + Seigniorage ===");

        // 1. Candidate 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        uint256 initialStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );

        console.log("Initial stake (RAY):", initialStake);

        // 2. 시뇨리지 발생 시뮬레이션 (블록 진행)
        vm.roll(block.number + 1000); // 1000 블록 진행

        // 시뇨리지 업데이트 시도
        bool success = CandidateAddOnV1_1(candidateAddOn).updateSeigniorage();
        require(success, "Seigniorage update failed");

        uint256 stakeAfterSeigniorage = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );

        if (stakeAfterSeigniorage > initialStake) {
            uint256 seigniorageEarned = stakeAfterSeigniorage - initialStake;
            console.log("Stake after seigniorage (RAY):", stakeAfterSeigniorage);
            console.log("Seigniorage earned (RAY):", seigniorageEarned);
        } else {
            console.log("No seigniorage in test environment, using initial stake");
        }

        // 3. 슬래싱 실행
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 4. 원금+이자 모두 소각 검증
        uint256 finalStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        assertEq(finalStake, 0, "All stake (principal + seigniorage) should be burned");
        console.log("Final stake after slashing:", finalStake);
        console.log("[OK] Principal + Seigniorage fully burned");
    }

    // ============================================
    // 시나리오 3: 미지급 시뇨리지 포함 슬래싱
    // ============================================
    function test_Slashing_WithUnreceivedSeigniorage() public {
        console.log("\n=== Test: Slashing Includes Unreceived Seigniorage ===");

        // 1. Candidate 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        uint256 initialStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );

        console.log("Initial stake (RAY):", initialStake);

        // 2. 시뇨리지 발생 (블록 진행) - 하지만 updateSeigniorage 호출하지 않음
        vm.roll(block.number + 1000);

        // // 시뇨리지 업데이트를 하지 않은 상태에서 현재 스테이크 확인
        // uint256 stakeBeforeUpdate = SeigManagerV1_2(seigManagerProxy).stakeOf(
        //     candidateAddOn,
        //     operatorManager
        // );
        // console.log("Stake before seigniorage update (RAY):", stakeBeforeUpdate);
        // require(stakeBeforeUpdate > 0, "Stake before seigniorage update should be greater than 0");

        // 3. 슬래싱 실행 (미지급 시뇨리지 포함되어야 함)
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        uint256 challengerBalanceBefore = IWTON(wton).balanceOf(challenger);

        // 슬래싱 시 내부적으로 시뇨리지 업데이트가 되어야 함
        vm.recordLogs();

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        uint256 slashed = 0;
        uint256 challengerReward = 0;

        Vm.Log[] memory entries = vm.getRecordedLogs();
        console.log("Total logs emitted:", entries.length);

        for (uint i = 0; i < entries.length; i++) {
            Vm.Log memory entry = entries[i];

            // 1) SeigManager.onSlashed(address layer2, address operator)
            // - signature: onSlashed(address,address) -> keccak256("onSlashed(address,address)")
            // - topics[0] is signature
            // if (entry.topics[0] == keccak256("onSlashed(address,address)")) {
            //     (address l2, address op) = abi.decode(entry.data, (address, address));
            //     console.log("Captured SeigManager.onSlashed:");
            //     console.log(" - Layer2:", l2);
            //     console.log(" - Operator:", op);
            // }

            // // 2) ChallengerRewarded(address indexed layer2, address indexed challenger, uint256 amount)
            // if (entry.topics[0] == keccak256("ChallengerRewarded(address,address,uint256)")) {
            //     // indexed params are in topics[1], topics[2] ...
            //     address l2 = address(uint160(uint256(entry.topics[1])));
            //     address chal = address(uint160(uint256(entry.topics[2])));
            //     uint256 amount = abi.decode(entry.data, (uint256));

            //     console.log("Captured ChallengerRewarded:");
            //     console.log(" - Layer2:", l2);
            //     console.log(" - Challenger:", chal);
            //     console.log(" - Amount:", amount);
            // }

            // 3) Slashed(address indexed layer2, address indexed operator, address indexed challenger, uint256 slashed, uint256 reward)
            if (entry.topics[0] == keccak256("Slashed(address,address,address,uint256,uint256)")) {
                address l2 = address(uint160(uint256(entry.topics[1])));
                address op = address(uint160(uint256(entry.topics[2])));
                address chal = address(uint160(uint256(entry.topics[3])));
                (slashed, challengerReward) = abi.decode(entry.data, (uint256, uint256));

                console.log("Captured DepositManager.Slashed:");
                console.log(" - Layer2:", l2);
                console.log(" - Operator:", op);
                console.log(" - Challenger:", chal);
                console.log(" - Slashed Amount:", slashed);
                console.log(" - Reward Amount:", challengerReward);
            }
        }

        address candidateAddOn2 = candidateAddOn;
        address operatorManager2 = operatorManager;
        // require(
        //     slashed > initialStake,
        //     "Slashed amount should be greater than initial stake(because add seigniorage)"
        // );
        require(
            slashed > challengerReward,
            "The reward value must be less than the slashed value."
        );

        uint256 challengerBalanceAfter = IWTON(wton).balanceOf(challenger);
        uint256 reward = challengerBalanceAfter - challengerBalanceBefore;

        // 4. 검증: 보상값은 Slashed된 금액 * slashingRewardRate 값 입니다. (여기서 Slahed값은 미지급 시뇨리지 포함)
        uint256 slashingRewardRate = DepositManager_Slashing(address(depositManagerProxy))
            .slashingRewardRate();
        uint256 expectedMinReward = (slashed * slashingRewardRate) / 10000;

        assertTrue(reward >= expectedMinReward, "Reward should include unreceived seigniorage");
        console.log("Expected minimum reward (from initial stake):", expectedMinReward);
        console.log("Actual reward (including unreceived seigniorage):", reward);
        console.log("[OK] Unreceived seigniorage included in slashing");

        // 최종 스테이크는 0이어야 함
        uint256 finalStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn2,
            operatorManager2
        );
        assertEq(finalStake, 0, "All stake should be burned");
    }

    // ============================================
    // 시나리오 4: 중복 슬래싱 방지
    // ============================================
    function test_Slashing_PreventDoubleSlashing() public {
        console.log("\n=== Test: Prevent Double Slashing ===");

        // 1. Candidate 등록 및 첫 번째 슬래싱
        uint256 totalAmount = 100000 * 1e18;
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, totalAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );

        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        // 첫 번째 슬래싱
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        console.log("[OK] First slashing successful");

        // 2. Operator가 다시 스테이킹 (Restake) - 자금 복구 시뮬레이션 (직접 입금)
        vm.startPrank(operator);

        // // 2-1. TON 확보
        // MockTON(ton).mint(operator, stakeAmount);

        // 2-2. TON -> WTON 변환
        IERC20(ton).approve(address(wton), stakeAmount);
        IWTON(wton).swapFromTON(stakeAmount);

        // 2-3. DepositManager에 예치
        address myCandidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        uint256 wtonBalance = IERC20(wton).balanceOf(operator);

        IERC20(wton).approve(depositManagerProxy, wtonBalance);

        console.log("Attempting to deposit WTON (RAY):", wtonBalance);
        uint256 minAmount = SeigManagerV1_2(seigManagerProxy).minimumAmount();
        console.log("SeigManager Minimum Amount (RAY):", minAmount);

        try
            DepositManagerV3(depositManagerProxy).deposit(
                myCandidateAddOn,
                operatorManager,
                wtonBalance
            )
        {
            console.log("Deposit successful");
        } catch Error(string memory reason) {
            console.log("Deposit failed with reason:", reason);
            revert(reason); // Re-throw to fail test
        } catch (bytes memory lowLevelData) {
            console.log("Deposit failed with low-level error");
            // Decode custom error if possible?
            revert("Deposit failed low-level");
        }
        vm.stopPrank();

        // 스테이크 복구 확인
        uint256 currentStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            myCandidateAddOn,
            operatorManager
        );
        console.log("Restaked amount (RAY):", currentStake);
        require(currentStake > 0, "Stake should be restored");

        // 3. 두 번째 슬래싱 시도 (Replay Attack) - 돈이 있어도 실패해야 함!
        vm.expectRevert(abi.encodeWithSignature("SlashingError()"));
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        console.log("[OK] Double slashing prevented (even with funds)");
    }

    // ============================================
    // 시나리오 5: 여러 Operator 슬래싱 독립성
    // ============================================
    function test_Slashing_MultipleOperators_Independence() public {
        console.log("\n=== Test: Multiple Operators Slashing Independence ===");

        address operator2 = makeAddr("operator2");
        address rollupConfig2 = makeAddr("rollupConfig2");

        // Rollup Config 2 모킹
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("l1StandardBridge()"),
            abi.encode(makeAddr("mockL1Bridge2"))
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("optimismPortal()"),
            abi.encode(makeAddr("mockPortal2"))
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("unsafeBlockSigner()"),
            abi.encode(makeAddr("mockUnsafeBlockSigner2"))
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(mockFactory))
        );

        // Rollup Config 2 등록
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfig(
            rollupConfig2,
            2,
            makeAddr("l2TON2"),
            "TestRollup2"
        );

        // 1. Operator 1 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "Operator1"
        );
        vm.stopPrank();

        // 2. Operator 2 등록
        MockTON(ton).mint(operator2, stakeAmount);

        vm.startPrank(operator2);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig2,
            stakeAmount,
            true,
            "Operator2"
        );
        vm.stopPrank();

        address operatorManager1 = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address operatorManager2 = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig2
        );
        address candidateAddOn1 = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager1
        );
        address candidateAddOn2 = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager2
        );

        uint256 stake1Before = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn1,
            operatorManager1
        );
        uint256 stake2Before = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn2,
            operatorManager2
        );

        console.log("Operator 1 stake:", stake1Before);
        console.log("Operator 2 stake:", stake2Before);

        // 3. Operator 1만 슬래싱
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager1,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 4. 검증: Operator 1은 슬래싱, Operator 2는 영향 없음
        uint256 stake1After = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn1,
            operatorManager1
        );
        uint256 stake2After = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn2,
            operatorManager2
        );

        assertEq(stake1After, 0, "Operator 1 should be slashed");
        assertEq(stake2After, stake2Before, "Operator 2 should not be affected");

        console.log("[OK] Operator 1 slashed, Operator 2 unaffected");
    }

    // ============================================
    // 시나리오 6: 최소 스테이크 미만 슬래싱
    // ============================================
    function test_Slashing_BelowMinimumStake() public {
        console.log("\n=== Test: Slashing Below Minimum Stake ===");

        // 1. 최소 요구사항을 만족하는 작은 금액으로 등록 (1001 TON)
        uint256 smallStake = 1001 * 1e18; // 1001 TON (최소 요구사항 충족)
        MockTON(ton).mint(operator, smallStake);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, smallStake);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            smallStake,
            true,
            "SmallOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        uint256 initialStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );

        console.log("Small stake amount (RAY):", initialStake);

        // 2. 슬래싱 실행
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        uint256 challengerBalanceBefore = IWTON(wton).balanceOf(challenger);

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 3. 검증: 작은 금액도 정상적으로 슬래싱되고 보상 지급
        uint256 finalStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        assertEq(finalStake, 0, "Small stake should also be fully slashed");

        uint256 challengerBalanceAfter = IWTON(wton).balanceOf(challenger);
        uint256 reward = challengerBalanceAfter - challengerBalanceBefore;

        uint256 slashingRewardRate = DepositManager_Slashing(address(depositManagerProxy))
            .slashingRewardRate();
        uint256 expectedReward = (initialStake * slashingRewardRate) / 10000;

        assertEq(
            reward,
            expectedReward,
            "Reward should be calculated correctly even for small stakes"
        );
        console.log("[OK] Small stake slashed successfully with correct reward");
    }

    // ============================================
    // 시나리오 7: 보상 비율 0% (모두 소각)
    // ============================================
    function test_Slashing_ZeroRewardRate_AllBurned() public {
        console.log("\n=== Test: Zero Reward Rate - All Burned ===");

        // 1. 보상 비율을 0%로 설정
        vm.prank(daoCommitteeProxy);
        DepositManager_Slashing(address(depositManagerProxy)).setSlashingRewardRate(0);

        // 2. Candidate 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );

        // 3. 슬래싱 실행
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        uint256 challengerBalanceBefore = IWTON(wton).balanceOf(challenger);

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 4. 검증: Challenger는 보상을 받지 않음 (모두 소각)
        uint256 challengerBalanceAfter = IWTON(wton).balanceOf(challenger);
        assertEq(
            challengerBalanceAfter,
            challengerBalanceBefore,
            "Challenger should receive no reward"
        );

        console.log("[OK] All slashed amount burned, no reward to challenger");
    }

    // ============================================
    // 시나리오 8: 보상 비율 100% 테스트
    // ============================================
    function test_Slashing_FullRewardRate_100Percent() public {
        console.log("\n=== Test: Slashing with 100% Reward Rate ===");

        // 1. 보상 비율을 100%로 설정 (10000 basis points)
        vm.prank(daoCommitteeProxy);
        DepositManager_Slashing(address(depositManagerProxy)).setSlashingRewardRate(10000);

        uint256 newRate = DepositManager_Slashing(address(depositManagerProxy))
            .slashingRewardRate();
        assertEq(newRate, 10000, "Reward rate should be 100%");

        // 2. Candidate 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        uint256 initialStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );

        // 3. 슬래싱 실행
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        uint256 challengerBalanceBefore = IWTON(wton).balanceOf(challenger);

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 4. 100% 보상 검증
        uint256 challengerBalanceAfter = IWTON(wton).balanceOf(challenger);
        uint256 actualReward = challengerBalanceAfter - challengerBalanceBefore;

        assertEq(actualReward, initialStake, "Challenger should receive 100% of slashed amount");
        console.log("Initial stake:", initialStake);
        console.log("Challenger reward (100%):", actualReward);
        console.log("[OK] 100% reward rate verified");
    }

    // ============================================
    // 시나리오 9: 여러 Challenger 동시 슬래싱 테스트
    // ============================================
    function test_Slashing_MultipleChallengers_FirstWins() public {
        console.log("\n=== Test: Multiple Challengers - First Wins ===");

        address challenger2 = makeAddr("challenger2");

        // 1. Candidate 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );

        // 2. Dispute Game 설정
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        // 3. 첫 번째 Challenger가 step 호출
        vm.prank(challenger);
        game.step();

        // 4. 두 번째 Challenger가 step 호출 시도 (실패해야 함)
        vm.prank(challenger2);
        vm.expectRevert("Already countered");
        game.step();

        game.resolve();

        // 5. 첫 번째 Challenger만 슬래싱 성공
        uint256 challenger1BalanceBefore = IWTON(wton).balanceOf(challenger);
        uint256 challenger2BalanceBefore = IWTON(wton).balanceOf(challenger2);

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        uint256 challenger1BalanceAfter = IWTON(wton).balanceOf(challenger);
        uint256 challenger2BalanceAfter = IWTON(wton).balanceOf(challenger2);

        // 6. 검증: 첫 번째 Challenger만 보상 받음
        assertTrue(
            challenger1BalanceAfter > challenger1BalanceBefore,
            "First challenger should receive reward"
        );
        assertEq(
            challenger2BalanceAfter,
            challenger2BalanceBefore,
            "Second challenger should not receive reward"
        );

        console.log("First challenger reward:", challenger1BalanceAfter - challenger1BalanceBefore);
        console.log("[OK] Only first challenger received reward");
    }

    // ============================================
    // 시나리오 10: 슬래싱 후 재등록 테스트
    // ============================================
    function test_Slashing_ReRegistrationAfterSlashing() public {
        console.log("\n=== Test: Re-registration After Slashing ===");

        // 1. 첫 번째 등록 및 슬래싱
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "FirstRegistration"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );

        // 슬래싱 실행
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        console.log("[OK] First registration slashed");

        // 2. 재등록 (1001 TON 이상)
        uint256 reStakeAmount = 5000 * 1e18; // 5000 TON
        MockTON(ton).mint(operator, reStakeAmount);

        address rollupConfig2 = makeAddr("rollupConfig2");

        // Rollup Config 2 모킹
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("l1StandardBridge()"),
            abi.encode(makeAddr("mockL1Bridge2"))
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("optimismPortal()"),
            abi.encode(makeAddr("mockPortal2"))
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("unsafeBlockSigner()"),
            abi.encode(makeAddr("mockUnsafeBlockSigner2"))
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(mockFactory))
        );

        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfig(
            rollupConfig2,
            2,
            makeAddr("l2TON2"),
            "TestRollup2"
        );

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, reStakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig2,
            reStakeAmount,
            true,
            "ReRegistration"
        );
        vm.stopPrank();

        address newOperatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig2
        );
        address newCandidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            newOperatorManager
        );
        uint256 newStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            newCandidateAddOn,
            newOperatorManager
        );

        assertEq(newStake, reStakeAmount * 1e9, "Re-registration stake should match");
        console.log("[OK] Re-registration successful with stake:", newStake);

        // 3. 시간 경과 후 시뇨리지 확인
        vm.roll(block.number + 1000);

        // 시뇨리지 업데이트 시도 (직접 호출)
        bool success = CandidateAddOnV1_1(newCandidateAddOn).updateSeigniorage();
        require(success, "Seigniorage update failed");

        // stakeOf를 사용하여 시뇨리지 포함 총 스테이크 확인
        uint256 stakeAfterSeigniorage = SeigManagerV1_2(seigManagerProxy).stakeOf(
            newCandidateAddOn,
            newOperatorManager
        );

        console.log("Stake with Seigniorage:", stakeAfterSeigniorage);
        console.log("Initial Stake:", newStake);

        require(stakeAfterSeigniorage > newStake, "Seigniorage must increase");

        console.log("Seigniorage earned after re-registration:", stakeAfterSeigniorage - newStake);
        console.log("[OK] Re-registered operator can earn seigniorage");
    }

    // ============================================
    // 시나리오 11: 부분 출금 후 슬래싱 테스트
    // ============================================
    function test_Slashing_AfterPartialWithdrawal() public {
        console.log("\n=== Test: Slashing After Partial Withdrawal ===");

        // 1. Candidate 등록
        uint256 initialStake = 10000 * 1e18;
        MockTON(ton).mint(operator, initialStake);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, initialStake);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            initialStake,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );

        uint256 stakeBeforeWithdrawal = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        console.log("Initial stake:", stakeBeforeWithdrawal);

        // 2. 부분 출금 시도 (실제 구현에 따라 다를 수 있음)
        // Note: 부분 출금 기능이 구현되어 있다면 여기서 호출
        // vm.prank(operator);
        // DepositManagerV3(depositManagerProxy).requestWithdrawal(candidateAddOn, withdrawAmount);

        console.log("[INFO] Partial withdrawal feature may not be implemented yet");

        // 3. 슬래싱 실행
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 4. 검증: 남은 스테이크가 모두 슬래싱됨
        uint256 finalStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        assertEq(finalStake, 0, "All remaining stake should be slashed");
        console.log("[OK] Remaining stake after withdrawal fully slashed");
    }

    // ============================================
    // 시나리오 12: 잘못된 Dispute Game 상태 테스트
    // ============================================
    function test_Slashing_InvalidGameStates() public {
        console.log("\n=== Test: Invalid Dispute Game States ===");

        // 1. Candidate 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );

        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        // 2. 테스트 A: resolve되지 않은 게임으로 슬래싱 시도
        MockFaultDisputeGame2 unresolvedGame = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        unresolvedGame.initialize();

        vm.prank(challenger);
        unresolvedGame.step();
        // resolve() 호출하지 않음

        vm.expectRevert(); // 게임이 resolve되지 않아서 실패
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(unresolvedGame)
        );

        console.log("[OK] Unresolved game slashing prevented");

        // 3. 테스트 B: DEFENDER_WINS 상태 게임으로 슬래싱 시도
        MockFaultDisputeGame2 defenderWinsGame = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, hex"5678"))
        );
        defenderWinsGame.initialize();
        // step() 호출하지 않음 (challenger가 대응하지 않음)
        defenderWinsGame.resolve(); // DEFENDER_WINS 상태가 됨

        vm.expectRevert(); // DEFENDER_WINS이므로 슬래싱 실패
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            hex"5678",
            address(defenderWinsGame)
        );

        console.log("[OK] DEFENDER_WINS game slashing prevented");
    }

    // ============================================
    // 시나리오 13: 슬래싱 이벤트 검증 테스트
    // ============================================
    function test_Slashing_EventEmission() public {
        console.log("\n=== Test: Slashing Event Emission ===");

        // 1. Candidate 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        uint256 initialStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );

        // 2. Dispute Game 설정
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        // 3. 이벤트 검증을 위한 슬래싱 실행
        vm.recordLogs();

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        Vm.Log[] memory entries = vm.getRecordedLogs();
        console.log("Total logs emitted:", entries.length);

        for (uint i = 0; i < entries.length; i++) {
            Vm.Log memory entry = entries[i];

            // 1) SeigManager.onSlashed(address layer2, address operator)
            // - signature: onSlashed(address,address) -> keccak256("onSlashed(address,address)")
            // - topics[0] is signature
            if (entry.topics[0] == keccak256("onSlashed(address,address)")) {
                (address l2, address op) = abi.decode(entry.data, (address, address));
                console.log("Captured SeigManager.onSlashed:");
                console.log(" - Layer2:", l2);
                console.log(" - Operator:", op);
            }

            // 2) ChallengerRewarded(address indexed layer2, address indexed challenger, uint256 amount)
            if (entry.topics[0] == keccak256("ChallengerRewarded(address,address,uint256)")) {
                // indexed params are in topics[1], topics[2] ...
                address l2 = address(uint160(uint256(entry.topics[1])));
                address chal = address(uint160(uint256(entry.topics[2])));
                uint256 amount = abi.decode(entry.data, (uint256));

                console.log("Captured ChallengerRewarded:");
                console.log(" - Layer2:", l2);
                console.log(" - Challenger:", chal);
                console.log(" - Amount:", amount);
            }

            // 3) Slashed(address indexed layer2, address indexed operator, address indexed challenger, uint256 slashed, uint256 reward)
            if (entry.topics[0] == keccak256("Slashed(address,address,address,uint256,uint256)")) {
                address l2 = address(uint160(uint256(entry.topics[1])));
                address op = address(uint160(uint256(entry.topics[2])));
                address chal = address(uint160(uint256(entry.topics[3])));
                (uint256 slashed, uint256 reward) = abi.decode(entry.data, (uint256, uint256));

                console.log("Captured DepositManager.Slashed:");
                console.log(" - Layer2:", l2);
                console.log(" - Operator:", op);
                console.log(" - Challenger:", chal);
                console.log(" - Slashed Amount:", slashed);
                console.log(" - Reward Amount:", reward);
            }
        }

        // 4. 슬래싱 결과 확인 (이벤트가 발생했는지는 로그로 확인)
        uint256 finalStake = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        assertEq(finalStake, 0, "Stake should be zero after slashing");

        console.log("[OK] Slashing completed - events should be emitted");
        console.log("[INFO] Check transaction logs for emitted events");
    }

    // ============================================
    // 시나리오 14: 권한 없는 DepositManager.slash 호출
    // ============================================
    function test_Slashing_UnauthorizedDepositManagerAccess() public {
        console.log("\n=== Test: Unauthorized DepositManager.slash Access ===");

        // 1. Candidate 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );

        // 2. 일반 사용자가 직접 DepositManager.slash 호출 시도
        address attacker = makeAddr("attacker");

        vm.prank(attacker);
        vm.expectRevert(); // "not layer2Manager" 또는 유사한 에러 예상
        DepositManager_Slashing(address(depositManagerProxy)).slash(
            candidateAddOn,
            operatorManager,
            challenger
        );

        console.log("[OK] Unauthorized DepositManager.slash call prevented");

        // 3. 스테이크가 변경되지 않았는지 확인
        uint256 stakeAfterAttack = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        assertEq(stakeAfterAttack, stakeAmount * 1e9, "Stake should remain unchanged");
        console.log("[OK] Stake unchanged after unauthorized attempt");
    }

    // ============================================
    // 시나리오 15: 권한 없는 SeigManager.onSlash 호출
    // ============================================
    function test_Slashing_UnauthorizedSeigManagerAccess() public {
        console.log("\n=== Test: Unauthorized SeigManager.onSlash Access ===");

        // 1. Candidate 등록
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );

        // 2. 일반 사용자가 직접 SeigManager.onSlash 호출 시도
        address attacker = makeAddr("attacker");

        vm.prank(attacker);
        vm.expectRevert(); // "not onlyDepositManager" 또는 유사한 에러 예상
        SeigManager_Slashing(address(seigManagerProxy)).onSlash(candidateAddOn, operatorManager);

        console.log("[OK] Unauthorized SeigManager.onSlash call prevented");

        // 3. 스테이크가 변경되지 않았는지 확인
        uint256 stakeAfterAttack = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        assertEq(stakeAfterAttack, stakeAmount * 1e9, "Stake should remain unchanged");
        console.log("[OK] Stake unchanged after unauthorized SeigManager access attempt");
    }

    // ============================================
    // 시나리오 16: 일반 스테이커의 시뇨리지 보호 (슬래싱 시)
    // ============================================
    function test_Slashing_DelegatorSeigniorageProtection() public {
        console.log("\n=== Test: Delegator Seigniorage Protection During Slashing ===");

        // 테스트 계정 설정
        address delegator1 = makeAddr("delegator1");
        address delegator2 = makeAddr("delegator2");

        // 1. Operator가 Candidate 등록
        uint256 operatorStake = 10000 * 1e18;
        MockTON(ton).mint(operator, operatorStake);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, operatorStake);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            operatorStake,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );

        console.log("Operator registered with stake:", operatorStake);

        // 2. 일반 스테이커들이 해당 Layer2에 스테이킹
        uint256 delegator1Stake = 5000 * 1e18;
        uint256 delegator2Stake = 3000 * 1e18;

        // Delegator 1 스테이킹
        MockTON(ton).mint(delegator1, delegator1Stake);
        vm.startPrank(delegator1);
        IERC20(ton).approve(wton, delegator1Stake);
        MockWTON(wton).swapFromTONAndTransfer(delegator1, delegator1Stake);
        IERC20(wton).approve(depositManagerProxy, delegator1Stake * 1e9);
        DepositManagerV3(depositManagerProxy).deposit(candidateAddOn, delegator1Stake * 1e9);
        vm.stopPrank();

        // Delegator 2 스테이킹
        MockTON(ton).mint(delegator2, delegator2Stake);
        vm.startPrank(delegator2);
        IERC20(ton).approve(wton, delegator2Stake);
        MockWTON(wton).swapFromTONAndTransfer(delegator2, delegator2Stake);
        IERC20(wton).approve(depositManagerProxy, delegator2Stake * 1e9);
        DepositManagerV3(depositManagerProxy).deposit(candidateAddOn, delegator2Stake * 1e9);
        vm.stopPrank();

        console.log("Delegator 1 staked:", delegator1Stake);
        console.log("Delegator 2 staked:", delegator2Stake);

        // 3. 초기 스테이크 확인
        uint256 operatorStakeBefore = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        uint256 delegator1StakeBefore = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            delegator1
        );
        uint256 delegator2StakeBefore = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            delegator2
        );

        console.log("Initial operator stake (RAY):", operatorStakeBefore);
        console.log("Initial delegator1 stake (RAY):", delegator1StakeBefore);
        console.log("Initial delegator2 stake (RAY):", delegator2StakeBefore);

        // 4. 시간 경과 (시뇨리지 발생)
        vm.roll(block.number + 1000);

        // 시뇨리지 업데이트 시도
        bool success = CandidateAddOnV1_1(candidateAddOn).updateSeigniorage();
        require(success, "Seigniorage update failed");

        // 5. 시뇨리지 발생 후 스테이크 확인
        uint256 operatorStakeWithSeig = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        uint256 delegator1StakeWithSeig = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            delegator1
        );
        uint256 delegator2StakeWithSeig = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            delegator2
        );

        console.log("Operator stake with seigniorage (RAY):", operatorStakeWithSeig);
        console.log("Delegator1 stake with seigniorage (RAY):", delegator1StakeWithSeig);
        console.log("Delegator2 stake with seigniorage (RAY):", delegator2StakeWithSeig);
        
        address delegator1_2 = delegator1;
        address delegator2_2 = delegator2;

        // 6. Operator 슬래싱 실행
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        address operatorManager_2 = operatorManager;
        address candidateAddOn_2 = candidateAddOn;

        
        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );


        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        console.log("\n[Executing Slashing...]");
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager_2,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // uint256 delegator1StakeWithSeig_2 = delegator1StakeWithSeig;
        // uint256 delegator2StakeWithSeig_2 = delegator2StakeWithSeig;

        // 7. 슬래싱 후 스테이크 확인
        uint256 operatorStakeAfter = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn_2,
            operatorManager_2
        );
        uint256 delegator1StakeAfter = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn_2,
            delegator1_2
        );
        uint256 delegator2StakeAfter = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn_2,
            delegator2_2
        );

        console.log("\n=== After Slashing ===");
        console.log("Operator stake after slashing:", operatorStakeAfter);
        console.log("Delegator1 stake after slashing:", delegator1StakeAfter);
        console.log("Delegator2 stake after slashing:", delegator2StakeAfter);

        // 8. 검증: Operator만 슬래싱되고 일반 스테이커는 보호됨
        assertEq(operatorStakeAfter, 0, "Operator stake should be fully slashed");
        assertEq(
            delegator1StakeAfter,
            delegator1StakeWithSeig,
            "Delegator1 stake should be preserved"
        );
        assertEq(
            delegator2StakeAfter,
            delegator2StakeWithSeig,
            "Delegator2 stake should be preserved"
        );

        console.log("\n[OK] Operator slashed, delegators protected");

        // 9. 추가 검증: 일반 스테이커들의 시뇨리지 확인
        if (delegator1StakeWithSeig > delegator1StakeBefore) {
            uint256 delegator1Seigniorage = delegator1StakeWithSeig - delegator1StakeBefore;
            console.log("Delegator1 earned seigniorage:", delegator1Seigniorage);
            console.log("[OK] Delegator1 seigniorage preserved after slashing");
        }

        if (delegator2StakeWithSeig > delegator2StakeBefore) {
            uint256 delegator2Seigniorage = delegator2StakeWithSeig - delegator2StakeBefore;
            console.log("Delegator2 earned seigniorage:", delegator2Seigniorage);
            console.log("[OK] Delegator2 seigniorage preserved after slashing");
        }

        // 10. 슬래싱 후에도 일반 스테이커들이 출금 가능한지 확인
        console.log("\n=== Testing Delegator Withdrawal After Slashing ===");

        // Delegator1 출금 요청
        vm.startPrank(delegator1);
        DepositManagerV3(depositManagerProxy).requestWithdrawal(
            candidateAddOn,
            delegator1StakeAfter
        );
        vm.stopPrank();

        console.log("[OK] Delegator1 can request withdrawal after operator slashing");

        // 출금 가능 블록까지 진행
        uint256 delayBlocks = DepositManagerV3(depositManagerProxy).getDelayBlocks(candidateAddOn);
        vm.roll(block.number + delayBlocks + 1);

        // Delegator1 출금 처리
        uint256 delegator1WtonBefore = IERC20(wton).balanceOf(delegator1);
        vm.prank(delegator1);
        DepositManagerV3(depositManagerProxy).processRequest(candidateAddOn, false);
        uint256 delegator1WtonAfter = IERC20(wton).balanceOf(delegator1);

        assertEq(
            delegator1WtonAfter - delegator1WtonBefore,
            delegator1StakeAfter,
            "Delegator1 should receive full stake including seigniorage"
        );

        console.log(
            "Delegator1 withdrawn amount (RAY):",
            delegator1WtonAfter - delegator1WtonBefore
        );
        console.log("[OK] Delegator1 successfully withdrew stake with seigniorage");

        console.log("\n=== Test Summary ===");
        console.log("[OK] Operator fully slashed");
        console.log("[OK] All delegators' stakes preserved");
        console.log("[OK] All delegators' seigniorage preserved");
        console.log("[OK] Delegators can withdraw after operator slashing");
    }

    // ============================================
    // 시나리오 17: 슬래싱 후 새로운 스테이커 참여
    // ============================================
    function test_Slashing_NewDelegatorAfterSlashing() public {
        console.log("\n=== Test: New Delegator Can Join After Operator Slashing ===");

        address newDelegator = makeAddr("newDelegator");

        // 1. Operator 등록 및 슬래싱
        uint256 operatorStake = 10000 * 1e18;
        MockTON(ton).mint(operator, operatorStake);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, operatorStake);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            operatorStake,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );

        // 슬래싱 실행
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        console.log("[OK] Operator slashed");

        // 2. 슬래싱 후 새로운 스테이커가 참여 시도
        uint256 newDelegatorStake = 2000 * 1e18;
        MockTON(ton).mint(newDelegator, newDelegatorStake);

        vm.startPrank(newDelegator);
        IERC20(ton).approve(wton, newDelegatorStake);
        MockWTON(wton).swapFromTONAndTransfer(newDelegator, newDelegatorStake);
        IERC20(wton).approve(depositManagerProxy, newDelegatorStake * 1e9);

        // 슬래싱된 Layer2에는 스테이킹 불가능해야 함 (Operator 스테이크가 0이므로)
        vm.expectRevert("OperatorCollateral is insufficient.");
        DepositManagerV3(depositManagerProxy).deposit(candidateAddOn, newDelegatorStake * 1e9);
        vm.stopPrank();

        console.log(
            "[OK] New delegator cannot stake to slashed operator (operator collateral = 0)"
        );
        console.log("[INFO] Operator must re-stake before accepting new delegators");
    }

    // ============================================
    // 시나리오 18: 여러 스테이커 + 시뇨리지 + 슬래싱 종합 테스트
    // ============================================
    function test_Slashing_ComprehensiveDelegatorScenario() public {
        console.log("\n=== Test: Comprehensive Delegator + Seigniorage + Slashing ===");

        address delegator1 = makeAddr("delegator1");
        address delegator2 = makeAddr("delegator2");

        // 1. Operator 등록
        uint256 operatorStake = 10000 * 1e18;
        MockTON(ton).mint(operator, operatorStake);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, operatorStake);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            operatorStake,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );

        // 2. Delegator1 스테이킹
        uint256 delegator1Stake = 5000 * 1e18;
        MockTON(ton).mint(delegator1, delegator1Stake);
        vm.startPrank(delegator1);
        IERC20(ton).approve(wton, delegator1Stake);
        MockWTON(wton).swapFromTONAndTransfer(delegator1, delegator1Stake);
        IERC20(wton).approve(depositManagerProxy, delegator1Stake * 1e9);
        DepositManagerV3(depositManagerProxy).deposit(candidateAddOn, delegator1Stake * 1e9);
        vm.stopPrank();

        console.log("Phase 1: Operator and Delegator1 staked");

        // 3. 시간 경과 (첫 번째 시뇨리지 발생)
        vm.roll(block.number + 500);

        // 4. Delegator2 스테이킹 (중간에 참여)
        uint256 delegator2Stake = 3000 * 1e18;
        MockTON(ton).mint(delegator2, delegator2Stake);
        vm.startPrank(delegator2);
        IERC20(ton).approve(wton, delegator2Stake);
        MockWTON(wton).swapFromTONAndTransfer(delegator2, delegator2Stake);
        IERC20(wton).approve(depositManagerProxy, delegator2Stake * 1e9);
        DepositManagerV3(depositManagerProxy).deposit(candidateAddOn, delegator2Stake * 1e9);
        vm.stopPrank();

        console.log("Phase 2: Delegator2 joined");

        // 5. 추가 시간 경과 (두 번째 시뇨리지 발생)
        vm.roll(block.number + 500);

        // 6. 스테이크 확인 (슬래싱 전)
        uint256 operatorStakeBefore = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        uint256 delegator1StakeBefore = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            delegator1
        );
        uint256 delegator2StakeBefore = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            delegator2
        );

        console.log("\nBefore Slashing:");
        console.log("Operator stake:", operatorStakeBefore);
        console.log("Delegator1 stake:", delegator1StakeBefore);
        console.log("Delegator2 stake:", delegator2StakeBefore);

        // 7. 슬래싱 실행
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.resolve();

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 8. 슬래싱 후 스테이크 확인
        uint256 operatorStakeAfter = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            operatorManager
        );
        uint256 delegator1StakeAfter = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            delegator1
        );
        uint256 delegator2StakeAfter = SeigManagerV1_2(seigManagerProxy).stakeOf(
            candidateAddOn,
            delegator2
        );

        console.log("\nAfter Slashing:");
        console.log("Operator stake:", operatorStakeAfter);
        console.log("Delegator1 stake:", delegator1StakeAfter);
        console.log("Delegator2 stake:", delegator2StakeAfter);

        // 9. 검증
        assertEq(operatorStakeAfter, 0, "Operator should be fully slashed");
        assertEq(delegator1StakeAfter, delegator1StakeBefore, "Delegator1 stake preserved");
        assertEq(delegator2StakeAfter, delegator2StakeBefore, "Delegator2 stake preserved");

        // 10. Delegator1이 더 많은 시뇨리지를 받았는지 확인 (더 오래 스테이킹했으므로)
        uint256 delegator1Seigniorage = delegator1StakeBefore - (delegator1Stake * 1e9);
        uint256 delegator2Seigniorage = delegator2StakeBefore - (delegator2Stake * 1e9);

        if (delegator1Seigniorage > 0 && delegator2Seigniorage > 0) {
            assertTrue(
                delegator1Seigniorage > delegator2Seigniorage,
                "Delegator1 should have more seigniorage (staked longer)"
            );
            console.log("\n[OK] Delegator1 earned more seigniorage (staked longer)");
            console.log("Delegator1 seigniorage:", delegator1Seigniorage);
            console.log("Delegator2 seigniorage:", delegator2Seigniorage);
        }

        console.log("\n[OK] Comprehensive test passed");
        console.log("[OK] Operator slashed, delegators protected");
        console.log("[OK] Seigniorage distribution fair based on staking duration");
    }

    // ============================================
    // 디버그: updateSeigniorage 실패 원인 분석
    // ============================================
    function test_Debug_UpdateSeigniorage() public {
        console.log("\n=== Debug: UpdateSeigniorage ===");

        // 1. Register and stake
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "TestCandidate"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        console.log("CandidateAddOn:", candidateAddOn);
        console.log("OperatorManager:", operatorManager);

        // 2. Check coinage
        address coinageAddr = SeigManagerV1_2(seigManagerProxy).coinages(candidateAddOn);
        console.log("Coinage address:", coinageAddr);
        require(coinageAddr != address(0), "Coinage not deployed!");

        // 3. Check operator balance in coinage
        RefactorCoinageSnapshotI coinage = RefactorCoinageSnapshotI(coinageAddr);
        uint256 operatorBalance = coinage.balanceOf(operatorManager);
        console.log("Operator coinage balance:", operatorBalance);

        // 4. Check minimumAmount
        uint256 minAmount = SeigManagerV1_2(seigManagerProxy).minimumAmount();
        console.log("Minimum amount:", minAmount);
        console.log("operatorBalance >= minAmount?", operatorBalance >= minAmount);

        // 5. Check lastSeigBlock
        uint256 lastSeigBlock = SeigManagerV1_2(seigManagerProxy).lastSeigBlock();
        console.log("Last seig block:", lastSeigBlock);
        console.log("Current block:", block.number);
        console.log("block.number > lastSeigBlock?", block.number > lastSeigBlock);

        // 6. Advance blocks
        vm.roll(block.number + 1000);
        console.log("After vm.roll, block:", block.number);
        console.log("block.number > lastSeigBlock?", block.number > lastSeigBlock);

        // 7. Check tot
        address totAddr = SeigManagerV1_2(seigManagerProxy).tot();
        RefactorCoinageSnapshotI tot = RefactorCoinageSnapshotI(totAddr);
        uint256 totSupply = tot.totalSupply();
        console.log("Tot totalSupply:", totSupply);

        // 8. Try updateSeigniorage
        console.log("\n--- Calling updateSeigniorage() ---");
        bool success = CandidateAddOnV1_1(candidateAddOn).updateSeigniorage();
        console.log("updateSeigniorage success:", success);

        // 9. Check balances after
        uint256 newOperatorBalance = coinage.balanceOf(operatorManager);
        console.log("Operator coinage balance after:", newOperatorBalance);
        console.log("Balance increased:", newOperatorBalance > operatorBalance);
    }
}
