// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './SlashingE2E_Deploy.t.sol';
import './SlashingE2E_improved_Deploy.t.sol';

// 필요한 인터페이스 추가 임포트
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {GameType, Claim} from '../src/layer2/lib/LibUDT.sol';

import {MockDisputeGameFactory} from '../src/mocks/MockDisputeGameFactory.sol';
import {MockFaultDisputeGame} from '../src/mocks/MockFaultDisputeGame.sol';

interface ITON_Mint is ITON {
    function mint(address to, uint256 amount) external returns (bool);
}

// contract SlashingE2E_Functional is SlashingE2E_Deploy {
contract SlashingE2E_Functional is SlashingE2E_improved_Deploy {
    address public rollupConfig; // Mock L2 SystemConfig address

    function setUp() public override {
        super.setUp();

        // DAOCommitteeProxy is now the admin of L1BridgeRegistryProxy
        // Grant Manager role to this test contract from the admin
        vm.prank(daoCommitteeProxy);
        console.log('address check');
        console.log(daoCommitteeProxy);
        console.log(address(this));
        L1BridgeRegistryV1_1(address(l1BridgeRegistryProxy)).addManager(address(this));

        // As a Manager, grant Registrant role to itself
        L1BridgeRegistryV1_1(address(l1BridgeRegistryProxy)).addRegistrant(address(this));

        // 테스트용 Mock RollupConfig 주소 설정
        rollupConfig = makeAddr('mockRollupConfig');

        // 2. Layer2Manager/L1BridgeRegistry가 해당 RollupConfig의 l1StandardBridge 등을 조회하므로 MockCall 설정
        // 실제 Optimism SystemConfig가 없으므로 해당 주소에 대한 call을 mocking 합니다.
        // MUST be called before registerRollupConfig
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

        // 1. L1BridgeRegistry에 Rollup 정보 먼저 등록 (Layer2Manager 등록 전 필수 단계)
        L1BridgeRegistryV1_1(address(l1BridgeRegistryProxy)).registerRollupConfig(
            rollupConfig,
            2, // Bedrock 타입
            address(0x123), // L2 TON 주소 (Mock)
            'TestRollup'
        );
    }

    function test_CandidateRegistrationAndStaking() public {
        uint256 stakeAmount = 10000 * 1e18; // 10,000 TON

        // --- 1. TON 준비 ---
        // 배포된 TON 컨트랙트에서 오퍼레이터에게 TON 지급 (mint 권한이 테스트 컨트랙트에 있다고 가정)
        ITON_Mint(ton).mint(operator, stakeAmount);

        vm.startPrank(operator);

        // --- 2. CandidateAddOn 등록 (Stake 포함) ---
        // Layer2Manager를 통해 등록하면:
        // - OperatorManager 생성
        // - DAOCommittee에 CandidateAddOn 등록
        // - DepositManager에 스테이킹이 한 번에 진행됩니다.
        ITON(ton).approve(address(layer2ManagerProxy), stakeAmount);
        Layer2ManagerV1_Slashing(address(layer2ManagerProxy)).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true, // TON 사용 여부
            'MyFirstCandidate'
        );

        vm.stopPrank();

        // --- 3. 상태 검증 ---
        address operatorManager = Layer2ManagerV1_Slashing(address(layer2ManagerProxy))
            .operatorOfRollupConfig(rollupConfig);
        address candidateAddOn = Layer2ManagerV1_Slashing(address(layer2ManagerProxy))
            .candidateAddOnOfOperator(operatorManager);
        assertTrue(candidateAddOn != address(0), 'CandidateAddOn should be deployed');

        // DepositManager에서 스테이킹된 금액 확인 (RAY 단위)
        // _registerCandidateAddOn에서 deposit(candidateAddOn, operatorManager, _wtonAmount) 호출함
        uint256 stagedAmount = DepositManager(address(depositManagerProxy)).accStaked(
            candidateAddOn,
            operatorManager
        );
        assertEq(stagedAmount, stakeAmount * 1e9, 'Staked amount mismatch (in RAY)');

        console.log('Candidate Registered at:', candidateAddOn);
        console.log('Staked Amount (RAY):', stagedAmount);
    }

    function test_Slashing() public {
        // 1. Candidate 등록 및 스테이킹 (10,000 TON)
        test_CandidateRegistrationAndStaking();

        address operatorManager = Layer2ManagerV1_Slashing(address(layer2ManagerProxy))
            .operatorOfRollupConfig(rollupConfig);
        address candidateAddOn = Layer2ManagerV1_Slashing(address(layer2ManagerProxy))
            .candidateAddOnOfOperator(operatorManager);

        uint256 initialStake = DepositManager(address(depositManagerProxy)).accStaked(
            candidateAddOn,
            operatorManager
        );
        assertEq(initialStake, 10000 * 1e18 * 1e9, 'Initial stake mismatch');

        // 2. Slashing 준비 (Mock Dispute Game 컨트랙트 실제 배포)
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();

        // SystemConfig.disputeGameFactory() 모킹 (실제 배포된 gameFactory 주소를 리턴하도록)
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature('disputeGameFactory()'),
            abi.encode(address(gameFactory))
        );

        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex'1234';

        // Dispute Game 생성 및 상태 설정
        MockFaultDisputeGame game = MockFaultDisputeGame(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize(); // claimData[0] 설정을 위해 초기화 필요

        // Challenger 승리 시뮬레이션
        vm.prank(challenger);
        game.step(); // 챌린저가 대응(step)함
        game.resolve(); // 게임 종료 -> CHALLENGER_WINS 상태가 됨

        // 3. Slashing 실행
        uint256 challengerInitialWton = IERC20(wton).balanceOf(challenger);

        Layer2ManagerV1_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 4. 결과 검증
        // 스테이크가 0이 되었는지 확인
        uint256 finalStake = DepositManager(address(depositManagerProxy)).accStaked(
            candidateAddOn,
            operatorManager
        );
        assertEq(finalStake, 0, 'Stake should be slashed to 0');

        // 챌린저 보상 확인 (10% = 1,000 TON in RAY = 1,000 * 1e18 * 1e9)
        uint256 rewardAmount = (initialStake * SLASHING_REWARD_RATE) / 10000;
        uint256 challengerFinalWton = IERC20(wton).balanceOf(challenger);
        assertEq(
            challengerFinalWton - challengerInitialWton,
            rewardAmount,
            'Challenger reward mismatch'
        );

        console.log('Slashing successful!');
        console.log('Slashed Amount (RAY):', initialStake);
        console.log('Challenger Reward (RAY):', rewardAmount);
    }
}
