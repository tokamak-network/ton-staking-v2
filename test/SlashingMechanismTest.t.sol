// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import { Layer2ManagerV1_1 } from "../src/layer2/Layer2ManagerV1_Slashing.sol";
import { DepositManagerV1_1 } from "../src/stake/managers/DepositManagerV1_Slash.sol";
import { MockDisputeGameFactory } from "../src/mocks/MockDisputeGameFactory.sol";
import { MockFaultDisputeGame } from "../src/mocks/MockFaultDisputeGame.sol";
import { MockSystemConfig } from "../src/mocks/MockSystemConfig.sol";
import { MockLayer2 } from "../src/mocks/MockLayer2.sol";
import { MockLayer2Registry } from "../src/mocks/MockLayer2Registry.sol";
import { GameType, Claim } from "../src/layer2/lib/LibUDT.sol";
import { GameStatus } from "../src/layer2/lib/Types.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SlashingMechanismTest is Test {
    Layer2ManagerV1_1 l2Manager;
    DepositManagerV1_1 depositManager;
    
    MockDisputeGameFactory gameFactory;
    MockSystemConfig systemConfig;
    MockLayer2 mockLayer2;
    MockLayer2Registry mockRegistry;
    
    address ton;
    address wton;
    
    address operator = address(0x111);
    address challenger = address(0x222);
    address seigManager = address(0x555);

    function setUp() public {
        l2Manager = new Layer2ManagerV1_1();
        depositManager = new DepositManagerV1_1();
        gameFactory = new MockDisputeGameFactory();
        systemConfig = new MockSystemConfig();
        systemConfig.setDisputeGameFactory(address(gameFactory));
        
        // --- Deploy Real TON and WTON ---
        ton = deployCode("abis/TON.json");
        bytes memory wtonArgs = abi.encode(ton);
        wton = deployCode("abis/WTON.json", wtonArgs);

        // DepositManager에게 보상으로 줄 WTON 지급 (100 WTON)
        // WTON은 RAY 단위(27 decimals)이므로 100 * 10^27
        deal(wton, address(depositManager), 100 * 1e27);

        mockLayer2 = new MockLayer2(operator);
        mockRegistry = new MockLayer2Registry();
        mockRegistry.register(address(mockLayer2));

        // --- Layer2Manager Mapping Injection ---
        // operatorInfo[operator] = { rollupConfig: systemConfig, candidateAddOn: mockLayer2 }
        bytes32 operatorInfoSlot = keccak256(abi.encode(operator, uint256(16)));
        vm.store(address(l2Manager), operatorInfoSlot, bytes32(uint256(uint160(address(systemConfig)))));
        vm.store(address(l2Manager), bytes32(uint256(operatorInfoSlot) + 1), bytes32(uint256(uint160(address(mockLayer2)))));
        
        // l2Manager.depositManager = depositManager (Slot 11)
        vm.store(address(l2Manager), bytes32(uint256(11)), bytes32(uint256(uint160(address(depositManager)))));

        // --- DepositManager State Injection ---
        // _wton (Slot 6), _registry (Slot 7), _seigManager (Slot 8)
        vm.store(address(depositManager), bytes32(uint256(6)), bytes32(uint256(uint160(wton))));
        vm.store(address(depositManager), bytes32(uint256(7)), bytes32(uint256(uint160(address(mockRegistry)))));
        vm.store(address(depositManager), bytes32(uint256(8)), bytes32(uint256(uint160(seigManager))));
        
        // layer2Manager (Slot 25), slashingRewardRate (Slot 26) = 10% (1000)
        vm.store(address(depositManager), bytes32(uint256(25)), bytes32(uint256(uint160(address(l2Manager)))));
        vm.store(address(depositManager), bytes32(uint256(26)), bytes32(uint256(1000)));

        // --- Mocks Calls ---
        // Mock SeigManager.onSlash -> returns true
        vm.mockCall(
            seigManager,
            abi.encodeWithSignature("onSlash(address,address)"),
            abi.encode(true)
        );
    }

    function test_FullSlashingAndRewardFlow() public {
        // WTON은 27 decimals (RAY)이므로 100 WTON = 100 * 1e27
        uint256 initialStake = 100 * 1e27;
        
        // 1. Operator 스테이킹 금액 주입
        // _accStaked[layer2][operator] (Slot 10)
        bytes32 slot10 = keccak256(abi.encode(address(mockLayer2), uint256(10)));
        bytes32 finalSlot = keccak256(abi.encode(operator, uint256(slot10)));
        vm.store(address(depositManager), finalSlot, bytes32(initialStake));

        // _accStakedLayer2[layer2] (Slot 11)
        bytes32 slot11 = keccak256(abi.encode(address(mockLayer2), uint256(11)));
        vm.store(address(depositManager), slot11, bytes32(initialStake));

        // _accStakedAccount[operator] (Slot 12)
        bytes32 slot12 = keccak256(abi.encode(operator, uint256(12)));
        vm.store(address(depositManager), slot12, bytes32(initialStake));

        // 2. Dispute Game 승리 상황 연출
        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";
        
        MockFaultDisputeGame game = MockFaultDisputeGame(address(gameFactory.create(gameType, rootClaim, extraData)));
        game.initialize(); // Initialize game to set up claimData[0]
        
        vm.prank(challenger);
        game.step(); 
        game.resolve(); 

        // 챌린저가 이긴경우인지 확인
        assertEq(uint8(game.status()), uint8(GameStatus.CHALLENGER_WINS), "Status should be CHALLENGER_WINS when step is executed");
        
        // 3. Slashing 실행
        // 예상 이벤트: 10% 보상 (10 WTON = 10 * 1e27)
        uint256 expectedReward = 10 * 1e27;
        vm.expectEmit(true, true, true, true);
        emit DepositManagerV1_1.ChallengerRewarded(address(mockLayer2), challenger, expectedReward); 
        
        l2Manager.slashingCandidate(operator, gameType, rootClaim, extraData, address(game));
        
        // 4. 검증: 스테이킹 금액이 0이 되었는지 확인
        bytes32 val = vm.load(address(depositManager), finalSlot);
        assertEq(uint256(val), 0, "Operator stake should be zero after slash");

        // 5. 검증: Challenger가 WTON 보상을 받았는지 확인
        assertEq(IERC20(wton).balanceOf(challenger), expectedReward, "Challenger should receive 10 WTON reward");
    }
}