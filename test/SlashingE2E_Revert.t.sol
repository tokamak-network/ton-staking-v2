// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './SlashingE2E_improved_Deploy.t.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {GameType, Claim} from '../src/layer2/lib/LibUDT.sol';
import {GameStatus} from '../src/layer2/lib/Types.sol';
import {MockDisputeGameFactory} from '../src/mocks/MockDisputeGameFactory.sol';
import {MockFaultDisputeGame} from '../src/mocks/MockFaultDisputeGame.sol';

interface ITON_Mint is ITON {
    function mint(address to, uint256 amount) external returns (bool);
}

/**
 * @title SlashingE2E_Revert
 * @notice Slashing 관련 예외 상황(Revert) 테스트
 */
contract SlashingE2E_Revert is SlashingE2E_improved_Deploy {
    address public rollupConfig;
    MockDisputeGameFactory public gameFactory;
    GameType public gameType = GameType.wrap(0);
    Claim public rootClaim = Claim.wrap(bytes32(uint256(1)));
    bytes public extraData = hex'1234';

    function setUp() public override {
        super.setUp();

        // 1. L1BridgeRegistry 권한 설정 (Manager/Registrant)
        vm.prank(daoCommitteeProxy);
        L1BridgeRegistryV1_1(address(l1BridgeRegistryProxy)).addManager(address(this));
        L1BridgeRegistryV1_1(address(l1BridgeRegistryProxy)).addRegistrant(address(this));

        // 2. Mock RollupConfig 설정
        rollupConfig = makeAddr('mockRollupConfig');
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature('l1StandardBridge()'),
            abi.encode(makeAddr('mockL1Bridge'))
        );
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature('optimismPortal()'),
            abi.encode(makeAddr('mockPortal'))
        );
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature('unsafeBlockSigner()'),
            abi.encode(makeAddr('mockUnsafeBlockSigner'))
        );

        // 3. Rollup 등록
        L1BridgeRegistryV1_1(address(l1BridgeRegistryProxy)).registerRollupConfig(
            rollupConfig,
            2,
            address(0x123),
            'TestRollup'
        );

        // 4. Dispute Game Factory 준비 및 모킹
        gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature('disputeGameFactory()'),
            abi.encode(address(gameFactory))
        );
    }

    /// @dev 공통 오퍼레이터 등록 로직
    function _registerOperator() internal returns (address operatorManager) {
        uint256 stakeAmount = 10000 * 1e18;
        ITON_Mint(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);
        ITON(ton).approve(address(layer2ManagerProxy), stakeAmount);
        Layer2ManagerV1_1(address(layer2ManagerProxy)).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            'RevertTestCandidate'
        );
        vm.stopPrank();

        return Layer2ManagerV1_1(address(layer2ManagerProxy)).operatorOfRollupConfig(rollupConfig);
    }

    /**
     * @notice 시나리오: Dispute Game이 끝나지 않았거나 Defender가 이겼을 때 슬래싱 시도
     */
    function test_SlashInvalidGame() public {
        address operatorManager = _registerOperator();

        // 1. 게임 생성 (초기 상태: IN_PROGRESS)
        MockFaultDisputeGame game = MockFaultDisputeGame(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        // Case A: Game is IN_PROGRESS -> Revert (StatusError)
        vm.expectRevert(bytes4(keccak256('StatusError()')));
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // Case B: Game state is DEFENDER_WINS -> Revert (StatusError)
        // resolve()를 바로 호출하면 챌린저가 대응하지 않았으므로 Defender 승리
        game.resolve();
        assertEq(uint8(game.status()), uint8(GameStatus.DEFENDER_WINS));

        vm.expectRevert(bytes4(keccak256('StatusError()')));
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );
    }

    /**
     * @notice 시나리오: onlyLayer2Manager 권한이 없는 계정으로 DepositManager.slash 직접 호출 시도
     */
    function test_UnauthorizedSlash() public {
        address operatorManager = _registerOperator();
        address candidateAddOn = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .candidateAddOnOfOperator(operatorManager);

        address unauthorizedUser = makeAddr('unauthorized');

        // DepositManager_Slashing.slash는 오직 Layer2Manager(Proxy)만 호출 가능해야 함
        vm.prank(unauthorizedUser);
        vm.expectRevert('not layer2Manager');
        DepositManager_Slashing(address(depositManagerProxy)).slash(
            candidateAddOn,
            operatorManager,
            unauthorizedUser
        );
    }

    /**
     * @notice 시나리오: onlyDepositManager 권한이 없는 계정으로 SeigManager_Slashing.onSlash 직접 호출 시도
     */
    function test_UnauthorizedSeigManagerSlash() public {
        address operatorManager = _registerOperator();
        address candidateAddOn = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .candidateAddOnOfOperator(operatorManager);

        address unauthorizedUser = makeAddr('unauthorized');

        // SeigManager_Slashing.onSlash는 오직 DepositManager(Proxy)만 호출 가능해야 함
        vm.prank(unauthorizedUser);
        vm.expectRevert('not onlyDepositManager');
        SeigManager_Slashing(address(seigManagerProxy)).onSlash(candidateAddOn, operatorManager);
    }
}
