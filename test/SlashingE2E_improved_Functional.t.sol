// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './SlashingE2E_Deploy.t.sol';
import './SlashingE2E_improved_Deploy.t.sol';

// 필요한 인터페이스 추가 임포트
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {GameType, Claim} from '../src/layer2/lib/LibUDT.sol';

import {MockDisputeGameFactory} from '../src/mocks/MockDisputeGameFactory.sol';
import {MockFaultDisputeGame} from '../src/mocks/MockFaultDisputeGame.sol';
import {RefactorCoinageSnapshotI} from '../src/stake/interfaces/RefactorCoinageSnapshotI.sol';

interface ITON_Mint is ITON {
    function mint(address to, uint256 amount) external returns (bool);
}

contract SlashingE2E_improved_Functional is SlashingE2E_improved_Deploy {
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
        Layer2ManagerV1_1(address(layer2ManagerProxy)).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true, // TON 사용 여부
            'MyFirstCandidate'
        );

        vm.stopPrank();

        // --- 3. 상태 검증 ---
        address operatorManager = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .operatorOfRollupConfig(rollupConfig);
        address candidateAddOn = Layer2ManagerV1_1(address(layer2ManagerProxy))
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

        address operatorManager = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .operatorOfRollupConfig(rollupConfig);
        address candidateAddOn = Layer2ManagerV1_1(address(layer2ManagerProxy))
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

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
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
        uint256 slashingRewardRate = DepositManager_Slashing(address(depositManagerProxy))
            .slashingRewardRate();
        console.log('Slashing Reward Rate:', slashingRewardRate);
        uint256 rewardAmount = (initialStake * slashingRewardRate) / 10000;
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

    /**
     * @notice 시나리오: 보상 비율을 50%로 변경했을 때 슬래싱 보상이 맞게 지급되는지 확인
     */
    function test_SlashingRewardRateChange() public {
        test_CandidateRegistrationAndStaking();

        address operatorManager = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .operatorOfRollupConfig(rollupConfig);
        address candidateAddOn = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .candidateAddOnOfOperator(operatorManager);

        uint256 initialStake = DepositManager(address(depositManagerProxy)).accStaked(
            candidateAddOn,
            operatorManager
        );

        // 1. 보상 비율을 50% (5000)로 변경
        uint256 newRate = 5000;
        vm.prank(daoCommitteeProxy); // Owner 권한으로 실행
        DepositManager_Slashing(address(depositManagerProxy)).setSlashingRewardRate(newRate);

        // 2. Slashing 준비
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature('disputeGameFactory()'),
            abi.encode(address(gameFactory))
        );
        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex'1234';
        MockFaultDisputeGame game = MockFaultDisputeGame(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        vm.prank(challenger);
        game.step();
        game.resolve();

        // 3. Slashing 실행
        uint256 challengerInitialWton = IERC20(wton).balanceOf(challenger);
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 4. 결과 검증 (50% 보상)
        uint256 expectedReward = (initialStake * newRate) / 10000;
        uint256 challengerFinalWton = IERC20(wton).balanceOf(challenger);
        assertEq(
            challengerFinalWton - challengerInitialWton,
            expectedReward,
            '50% reward mismatch'
        );

        console.log('Slashing with 50% reward rate successful!');
    }

    /**
     * @notice 시나리오: 시뇨리지가 발생한 상태에서 슬래싱 시 원금+이자 모두 소각되는지 확인
     */
    function test_SlashingWithSeigniorage() public {
        test_CandidateRegistrationAndStaking();

        address operatorManager = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .operatorOfRollupConfig(rollupConfig);
        address candidateAddOn = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .candidateAddOnOfOperator(operatorManager);

        // 1. 블록을 100개 뒤로 보내 시뇨리지 발생 환경 조성
        vm.roll(block.number + 100);

        // 2. 시뇨리지 업데이트 실행 (Layer2 본인이 호출해야 함)
        vm.prank(candidateAddOn);
        SeigManagerV1_3(address(seigManagerProxy)).updateSeigniorage();

        // 3. 현재 tot 잔액 확인 (이자 포함되어 원금보다 커야 함)
        uint256 principal = 10000 * 1e18 * 1e9;
        uint256 totBalanceBefore = RefactorCoinageSnapshotI(
            SeigManagerV1_2(address(seigManagerProxy)).tot()
        ).balanceOf(candidateAddOn);
        assertTrue(totBalanceBefore > principal, 'Seigniorage should be accumulated');

        // 4. Slashing 실행 준비
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature('disputeGameFactory()'),
            abi.encode(address(gameFactory))
        );
        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex'1234';
        MockFaultDisputeGame game = MockFaultDisputeGame(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        vm.prank(challenger);
        game.step();
        game.resolve();

        // 5. Slashing 실행
        Layer2ManagerV1_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            address(game)
        );

        // 6. 결과 검증: Coinage(원금)와 Tot(원금+이자) 모두 0(또는 매우 작은 값)이 되어야 함
        uint256 finalCoinage = RefactorCoinageSnapshotI(
            SeigManagerV1_2(address(seigManagerProxy)).coinages(candidateAddOn)
        ).balanceOf(operatorManager);
        uint256 finalTot = RefactorCoinageSnapshotI(
            SeigManagerV1_2(address(seigManagerProxy)).tot()
        ).balanceOf(candidateAddOn);

        assertEq(finalCoinage, 0, 'Coinage should be 0');
        // 부동 소수점 오차 등을 고려하여 매우 작은 값 이하인지 확인 (1e9 미만)
        assertTrue(finalTot < 1e9, 'Tot (including seigniorage) should be cleared');

        console.log('Slashing with seigniorage successful!');
        console.log('Burned Tot Amount (including rewards):', totBalanceBefore);
    }

    /**
     * @notice 시나리오: 시뇨리지 업데이트(받기)를 하지 않은 상태(Unreceived)에서도 슬래싱 시
     * 미지급된 시뇨리지까지 모두 계산되어 소각되는지 확인
     */
    function test_SlashingWithUncheckedSeigniorage() public {
        // 1. 첫 번째 Candidate (슬래싱 대상) 등록 및 스테이킹
        test_CandidateRegistrationAndStaking();
        address operatorManager1 = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .operatorOfRollupConfig(rollupConfig);
        address candidateAddOn1 = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .candidateAddOnOfOperator(operatorManager1);

        // 2. 두 번째 Candidate 등록 (글로벌 시뇨리지 업데이트를 트리거하기 위함)
        address rollupConfig2 = makeAddr('mockRollupConfig2');
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature('l1StandardBridge()'),
            abi.encode(makeAddr('mockL1Bridge2'))
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature('optimismPortal()'),
            abi.encode(makeAddr('mockPortal2'))
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature('unsafeBlockSigner()'),
            abi.encode(makeAddr('mockUnsafeBlockSigner2'))
        );
        L1BridgeRegistryV1_1(address(l1BridgeRegistryProxy)).registerRollupConfig(
            rollupConfig2,
            2,
            address(0x456),
            'TestRollup2'
        );

        address operator2 = makeAddr('operator2');
        ITON_Mint(ton).mint(operator2, 10000 * 1e18);
        vm.startPrank(operator2);
        ITON(ton).approve(address(layer2ManagerProxy), 10000 * 1e18);
        Layer2ManagerV1_1(address(layer2ManagerProxy)).registerCandidateAddOn(
            rollupConfig2,
            10000 * 1e18,
            true,
            'SecondCandidate'
        );
        vm.stopPrank();

        address operatorManager2 = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .operatorOfRollupConfig(rollupConfig2);
        address candidateAddOn2 = Layer2ManagerV1_1(address(layer2ManagerProxy))
            .candidateAddOnOfOperator(operatorManager2);

        // 3. 시간 경과 (100 블록)
        vm.roll(block.number + 100);

        // 4. Candidate 2가 시뇨리지 업데이트 호출 (글로벌 Tot pool의 Factor가 업데이트됨)
        vm.prank(candidateAddOn2);
        SeigManagerV1_3(address(seigManagerProxy)).updateSeigniorage();

        // 5. 상태 확인: Candidate 1은 업데이트를 안 했으므로 Coinage는 그대로지만, Tot 잔액은 늘어나 있어야 함
        uint256 principal = 10000 * 1e18 * 1e9;
        uint256 totBalanceBefore = RefactorCoinageSnapshotI(
            SeigManagerV1_2(address(seigManagerProxy)).tot()
        ).balanceOf(candidateAddOn1);
        uint256 coinageBalanceBefore = RefactorCoinageSnapshotI(
            SeigManagerV1_2(address(seigManagerProxy)).coinages(candidateAddOn1)
        ).balanceOf(operatorManager1);

        assertTrue(
            totBalanceBefore > principal,
            'Tot balance should increase automatically due to global factor update'
        );
        assertEq(
            coinageBalanceBefore,
            principal,
            'Coinage balance should remain at principal (unreceived)'
        );

        // 6. Slashing 실행 (Candidate 1)
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature('disputeGameFactory()'),
            abi.encode(address(gameFactory))
        );
        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex'1234';
        MockFaultDisputeGame game = MockFaultDisputeGame(
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

        // 7. 결과 검증
        uint256 finalCoinage = RefactorCoinageSnapshotI(
            SeigManagerV1_2(address(seigManagerProxy)).coinages(candidateAddOn1)
        ).balanceOf(operatorManager1);
        uint256 finalTot = RefactorCoinageSnapshotI(
            SeigManagerV1_2(address(seigManagerProxy)).tot()
        ).balanceOf(candidateAddOn1);

        assertEq(finalCoinage, 0, 'Coinage should be 0');
        assertTrue(finalTot < 1e9, 'Tot (including hidden seigniorage) should be cleared');

        console.log('Slashing with unchecked seigniorage successful!');
    }
}
