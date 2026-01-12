// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {DeployV3SlashForDevnet} from "../../script/DeployV3SlashForDevnet.s.sol";
import {Layer2Manager_Slashing} from "../../src/layer2/Layer2Manager_Slashing.sol";
import {DepositManager_Slashing} from "../../src/stake/managers/DepositManager_Slashing.sol";
import {SeigManager_Slashing} from "../../src/stake/managers/SeigManager_Slashing.sol";
import {DepositManager} from "../../src/stake/managers/DepositManager.sol";
import {SeigManagerV1_2} from "../../src/stake/managers/SeigManagerV1_2.sol";
import {Layer2ManagerV1_1} from "../../src/layer2/Layer2ManagerV1_1.sol";
import {L1BridgeRegistryV1_2} from "../../src/layer2/L1BridgeRegistryV1_2.sol";
import {AuthControlL1BridgeRegistry} from "../../src/common/AuthControlL1BridgeRegistry.sol";
import {IWTON} from "../../src/dao/interfaces/IWTON.sol";
import {ITON} from "../../src/stake/interfaces/ITON.sol";
import {GameType, Claim, Position, Clock} from "../../src/layer2/lib/LibUDT.sol";
import {GameStatus} from "../../src/layer2/lib/Types.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interfaces for mocking or interaction
interface ITON_Mint is ITON {
    function mint(address to, uint256 amount) external returns (bool);
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

contract SlashingTest is Test, DeployV3SlashForDevnet {
    address public operator = makeAddr("operator");
    address public challenger = makeAddr("challenger");
    address public rollupConfig = makeAddr("mockRollupConfig");

    SlashingMockGame public mockGame;
    SlashingMockFactory public mockFactory;

    function setUp() public {
        // 1. 배포 스크립트 실행
        run();

        // 2. Mock 인프라 설정
        mockFactory = new SlashingMockFactory();
        mockGame = new SlashingMockGame(challenger);

        // 3. 테스트 컨트랙트에 권한 부여 (Rollup 등록을 위해)
        // script에서 l1BridgeRegistryProxy의 admin은 daoCommitteeProxy임
        vm.prank(daoCommitteeProxy);
        AuthControlL1BridgeRegistry(l1BridgeRegistryProxy).addManager(address(this));
        AuthControlL1BridgeRegistry(l1BridgeRegistryProxy).addRegistrant(address(this));

        // 4. Rollup 인프라 모킹 (Layer2Manager 등록 시 필요)
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

        // 5. Rollup 등록
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfig(
            rollupConfig,
            2, // Bedrock
            address(0),
            "TestRollup"
        );

        vm.label(operator, "Operator");
        vm.label(challenger, "Challenger");
        vm.label(daoCommitteeProxy, "DAOCommittee");
    }

    function test_CandidateRegistrationAndStaking() public {
        uint256 stakeAmount = 10000 * 1e18; // 10,000 TON

        // Operator에게 TON 지급
        ITON_Mint(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);

        // Candidate 등록
        Layer2ManagerV1_1(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true, // Use TON
            "MyOperator"
        );
        vm.stopPrank();

        // 등록 검증
        address operatorManager = Layer2ManagerV1_1(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV1_1(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );

        assertTrue(candidateAddOn != address(0), "Candidate registration failed");

        uint256 stakedAmount = DepositManager(depositManagerProxy).accStaked(
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

        address operatorManager = Layer2ManagerV1_1(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV1_1(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        uint256 initialStake = DepositManager(depositManagerProxy).accStaked(
            candidateAddOn,
            operatorManager
        );

        // 2. 슬래싱 게임 설정
        GameType gType = GameType.wrap(0);
        Claim rClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        mockFactory.setGame(gType, rClaim, extraData, address(mockGame));

        // 3. 슬래싱 실행
        uint256 challengerBalanceBefore = IWTON(wton).balanceOf(challenger);

        Layer2Manager_Slashing(layer2ManagerProxy).slashingCandidate(
            operatorManager,
            gType,
            rClaim,
            extraData,
            address(mockGame)
        );

        // 4. 결과 검증
        uint256 finalStake = DepositManager(depositManagerProxy).accStaked(
            candidateAddOn,
            operatorManager
        );
        assertEq(finalStake, 0, "Stake should be zeroed");

        // 보상 검증 (10% reward)
        uint256 expectedReward = (initialStake * 1000) / 10000;
        uint256 challengerBalanceAfter = IWTON(wton).balanceOf(challenger);

        assertEq(
            challengerBalanceAfter - challengerBalanceBefore,
            expectedReward,
            "Challenger reward mismatch"
        );

        console.log("Slashing Successful!");
        console.log("Slashed Amount (RAY):", initialStake);
        console.log("Challenger Reward (RAY):", expectedReward);
    }
}
