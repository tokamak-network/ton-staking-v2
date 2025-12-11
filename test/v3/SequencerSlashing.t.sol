// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {MockWTON} from "./mocks/MockWTON.sol";
import {MockTON} from "./mocks/MockTON.sol";
import {MockCoinage} from "./mocks/MockCoinage.sol";

/// @title MockLayer2 for Sequencer Slashing tests
contract MockLayer2 {
    address public operator;

    constructor(address _operator) {
        operator = _operator;
    }

    function setOperator(address _operator) external {
        operator = _operator;
    }
}

/// @title MockSeigManagerForSlashing
/// @notice 시퀀서 슬래싱 테스트를 위한 간소화된 SeigManager Mock
contract MockSeigManagerForSlashing {
    uint256 internal constant RAY = 1e27;

    // 스토리지
    address public owner;
    address public disputeContract;
    address public dao;
    uint256 public maxChallengers;
    uint256 public maxFraudProofCost;
    bool public v3Migrated;

    mapping(address => uint256) public sequencerAdditionalReward;
    mapping(address => uint256[]) public sequencerSlashTimestamps;
    mapping(address => MockCoinage) public coinages;
    mapping(address => bool) public pausedL2;

    // 이벤트
    event SequencerSlashed(
        address indexed layer2,
        address indexed sequencer,
        uint256 slashedAmount,
        uint256 challengerCount
    );

    event ChallengerRewarded(
        address indexed challenger,
        address indexed layer2,
        uint256 reward
    );

    event StakeTransferred(
        address indexed layer2,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    constructor() {
        owner = msg.sender;
        maxChallengers = 10;
        maxFraudProofCost = 10e27; // 10 WTON
        v3Migrated = true;
    }

    function setDisputeContract(address _disputeContract) external {
        require(msg.sender == owner, "not owner");
        disputeContract = _disputeContract;
    }

    function setDAO(address _dao) external {
        require(msg.sender == owner, "not owner");
        dao = _dao;
    }

    function setMaxChallengers(uint256 _maxChallengers) external {
        require(msg.sender == owner, "not owner");
        maxChallengers = _maxChallengers;
    }

    function setMaxFraudProofCost(uint256 _maxFraudProofCost) external {
        require(msg.sender == owner, "not owner");
        maxFraudProofCost = _maxFraudProofCost;
    }

    function setSequencerAdditionalReward(address layer2, uint256 reward) external {
        require(msg.sender == owner, "not owner");
        sequencerAdditionalReward[layer2] = reward;
    }

    function setCoinage(address layer2, address coinage) external {
        require(msg.sender == owner, "not owner");
        coinages[layer2] = MockCoinage(coinage);
    }

    /// @notice 시퀀서 슬래싱 (fraud proof 성공 시)
    /// @dev 백서: "the entire bond (D_sequencer) is slashed"
    /// @param layer2 슬래싱 대상 L2 주소
    /// @param challengers 성공한 챌린저 목록
    function slashSequencer(address layer2, address[] calldata challengers) external {
        require(v3Migrated, "not migrated");
        require(msg.sender == disputeContract, "only dispute contract");

        uint256 n = challengers.length;
        require(n > 0 && n <= maxChallengers, "invalid challenger count");

        // 시퀀서(오퍼레이터) 주소 조회
        address sequencer = MockLayer2(layer2).operator();
        require(sequencer != address(0), "no operator");

        // 담보금 = 해당 L2에 스테이킹된 시퀀서의 금액
        MockCoinage coinage = coinages[layer2];
        uint256 deposit = coinage.balanceOf(sequencer);
        require(deposit > 0, "no deposit to slash");

        uint256 additionalReward = sequencerAdditionalReward[layer2];

        // 백서 공식 (2): R_challenger = C_max + (Δ_sequencer / n)
        uint256 perChallengerReward = maxFraudProofCost + (additionalReward / n);

        // 총 챌린저 보상이 담보금을 초과하지 않도록
        uint256 totalChallengerRewards = perChallengerReward * n;
        if (totalChallengerRewards > deposit) {
            perChallengerReward = deposit / n;
            totalChallengerRewards = perChallengerReward * n;
        }

        // 각 챌린저에게 스테이킹 잔액으로 이전 (coinage 잔액 변경)
        for (uint256 i = 0; i < n; i++) {
            coinage.burnFrom(sequencer, perChallengerReward);
            coinage.mint(challengers[i], perChallengerReward);
            emit ChallengerRewarded(challengers[i], layer2, perChallengerReward);
        }

        // 나머지는 DAO의 스테이킹 잔액으로 이전
        uint256 remainder = deposit - totalChallengerRewards;
        if (remainder > 0) {
            coinage.burnFrom(sequencer, remainder);
            coinage.mint(dao, remainder);
        }

        // L2 시뇨리지 분배에서 제외 (일시 중지)
        pausedL2[layer2] = true;

        // 슬래싱 기록 저장
        sequencerSlashTimestamps[layer2].push(block.timestamp);

        emit SequencerSlashed(layer2, sequencer, deposit, n);
    }

    /// @notice 스테이킹 잔액 이전
    function transferStake(
        address layer2,
        address from,
        address to,
        uint256 amount
    ) external {
        require(v3Migrated, "not migrated");
        require(msg.sender == disputeContract, "only dispute contract");

        MockCoinage coinage = coinages[layer2];
        require(coinage.balanceOf(from) >= amount, "insufficient balance");

        coinage.burnFrom(from, amount);
        coinage.mint(to, amount);

        emit StakeTransferred(layer2, from, to, amount);
    }

    function getSlashTimestamps(address layer2) external view returns (uint256[] memory) {
        return sequencerSlashTimestamps[layer2];
    }
}

/// @title SequencerSlashingTest
/// @notice 시퀀서 슬래싱 단위 테스트 (챌린저 1명 기준)
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
contract SequencerSlashingTest is Test {
    MockSeigManagerForSlashing public seigManager;
    MockCoinage public coinage;
    MockLayer2 public layer2;

    address public owner = address(this);
    address public disputeContract = address(0x1);
    address public daoAddress = address(0x2);
    address public sequencer = address(0x100);
    address public challenger1 = address(0x200);
    address public challenger2 = address(0x300);
    address public challenger3 = address(0x400);

    uint256 internal constant RAY = 1e27;

    // 백서 V2 기본값
    uint256 public maxChallengers = 10;              // H_max = 10
    uint256 public maxFraudProofCost = 10e27;        // C_max = 10 WTON
    uint256 public additionalReward = 50e27;         // Δ_sequencer = 50 WTON

    function setUp() public {
        // Deploy contracts
        seigManager = new MockSeigManagerForSlashing();
        coinage = new MockCoinage();
        layer2 = new MockLayer2(sequencer);

        // Setup
        seigManager.setDisputeContract(disputeContract);
        seigManager.setDAO(daoAddress);
        seigManager.setMaxChallengers(maxChallengers);
        seigManager.setMaxFraudProofCost(maxFraudProofCost);
        seigManager.setCoinage(address(layer2), address(coinage));
        seigManager.setSequencerAdditionalReward(address(layer2), additionalReward);

        // 시퀀서에게 담보금 설정 (100 WTON)
        coinage.mint(sequencer, 100e27);
    }

    // ==========================================
    // 백서 공식 (1) 테스트: D_sequencer = H_max · C_max + Δ_sequencer
    // ==========================================

    /// @notice 시퀀서 담보금 공식 검증
    function test_sequencerDepositFormula() public pure {
        // D_sequencer = H_max · C_max + Δ_sequencer
        // D_sequencer = 10 · 10 + 50 = 150 WTON
        uint256 H_max = 10;
        uint256 C_max = 10e27;
        uint256 delta = 50e27;

        uint256 D_sequencer = (H_max * C_max) + delta;
        assertEq(D_sequencer, 150e27, "Sequencer deposit formula");
    }

    // ==========================================
    // 시퀀서 슬래싱 테스트 (챌린저 1명)
    // ==========================================

    /// @notice 챌린저 1명 슬래싱 성공
    /// @dev 백서 공식 (2): R_challenger = C_max + (Δ_sequencer / n)
    function test_slashSequencer_singleChallenger() public {
        uint256 sequencerBalanceBefore = coinage.balanceOf(sequencer);
        uint256 challengerBalanceBefore = coinage.balanceOf(challenger1);
        uint256 daoBalanceBefore = coinage.balanceOf(daoAddress);

        // 슬래싱: 챌린저 1명
        address[] memory challengers = new address[](1);
        challengers[0] = challenger1;

        vm.prank(disputeContract);
        seigManager.slashSequencer(address(layer2), challengers);

        // 백서 공식 (2): R_challenger = C_max + (Δ_sequencer / n)
        // n = 1: R = 10 + 50 = 60 WTON
        uint256 expectedChallengerReward = maxFraudProofCost + additionalReward;

        // 시퀀서 잔액: 100 - 100 = 0 (전액 슬래싱)
        assertEq(coinage.balanceOf(sequencer), 0, "Sequencer should have 0 balance");

        // 챌린저 보상: 60 WTON
        assertEq(
            coinage.balanceOf(challenger1),
            challengerBalanceBefore + expectedChallengerReward,
            "Challenger reward should be C_max + delta"
        );

        // DAO 보상: 100 - 60 = 40 WTON
        uint256 daoReward = sequencerBalanceBefore - expectedChallengerReward;
        assertEq(
            coinage.balanceOf(daoAddress),
            daoBalanceBefore + daoReward,
            "DAO should receive remainder"
        );

        // L2 일시 중지 확인
        assertTrue(seigManager.pausedL2(address(layer2)), "L2 should be paused");

        // 슬래싱 기록 확인
        uint256[] memory timestamps = seigManager.getSlashTimestamps(address(layer2));
        assertEq(timestamps.length, 1, "Should have 1 slash record");
    }

    /// @notice 챌린저 3명 슬래싱 성공
    function test_slashSequencer_multipleChallengers() public {
        uint256 sequencerBalanceBefore = coinage.balanceOf(sequencer);

        // 슬래싱: 챌린저 3명
        address[] memory challengers = new address[](3);
        challengers[0] = challenger1;
        challengers[1] = challenger2;
        challengers[2] = challenger3;

        vm.prank(disputeContract);
        seigManager.slashSequencer(address(layer2), challengers);

        // 백서 공식 (2): R_challenger = C_max + (Δ_sequencer / n)
        // n = 3: R = 10 + (50/3) = 10 + 16.67 = 26.67 WTON
        uint256 n = 3;
        uint256 perChallengerReward = maxFraudProofCost + (additionalReward / n);

        // 각 챌린저 보상 확인
        assertEq(coinage.balanceOf(challenger1), perChallengerReward, "Challenger1 reward");
        assertEq(coinage.balanceOf(challenger2), perChallengerReward, "Challenger2 reward");
        assertEq(coinage.balanceOf(challenger3), perChallengerReward, "Challenger3 reward");

        // DAO 보상: 100 - (26.67 * 3) = 100 - 80 = 20 WTON
        uint256 totalChallengerRewards = perChallengerReward * n;
        uint256 daoReward = sequencerBalanceBefore - totalChallengerRewards;
        assertEq(coinage.balanceOf(daoAddress), daoReward, "DAO should receive remainder");
    }

    /// @notice 담보금 부족 시 비례 분배
    function test_slashSequencer_insufficientDeposit() public {
        // 시퀀서 담보금을 30 WTON으로 설정 (C_max + Δ = 60 미만)
        coinage.setBalance(sequencer, 30e27);

        address[] memory challengers = new address[](1);
        challengers[0] = challenger1;

        vm.prank(disputeContract);
        seigManager.slashSequencer(address(layer2), challengers);

        // 담보금이 부족하므로 전액(30 WTON)이 챌린저에게
        assertEq(coinage.balanceOf(challenger1), 30e27, "Challenger gets full deposit");
        assertEq(coinage.balanceOf(sequencer), 0, "Sequencer has 0");
        assertEq(coinage.balanceOf(daoAddress), 0, "DAO gets nothing");
    }

    /// @notice 권한 없는 슬래싱 실패
    function test_slashSequencer_notDisputeContract() public {
        address[] memory challengers = new address[](1);
        challengers[0] = challenger1;

        vm.prank(challenger1);
        vm.expectRevert("only dispute contract");
        seigManager.slashSequencer(address(layer2), challengers);
    }

    /// @notice 빈 챌린저 배열 실패
    function test_slashSequencer_emptyChallengers() public {
        address[] memory challengers = new address[](0);

        vm.prank(disputeContract);
        vm.expectRevert("invalid challenger count");
        seigManager.slashSequencer(address(layer2), challengers);
    }

    /// @notice 최대 챌린저 수 초과 실패
    function test_slashSequencer_tooManyChallengers() public {
        address[] memory challengers = new address[](11); // maxChallengers = 10
        for (uint256 i = 0; i < 11; i++) {
            challengers[i] = address(uint160(0x1000 + i));
        }

        vm.prank(disputeContract);
        vm.expectRevert("invalid challenger count");
        seigManager.slashSequencer(address(layer2), challengers);
    }

    /// @notice 담보금 없는 시퀀서 슬래싱 실패
    function test_slashSequencer_noDeposit() public {
        coinage.setBalance(sequencer, 0);

        address[] memory challengers = new address[](1);
        challengers[0] = challenger1;

        vm.prank(disputeContract);
        vm.expectRevert("no deposit to slash");
        seigManager.slashSequencer(address(layer2), challengers);
    }

    // ==========================================
    // transferStake 테스트
    // ==========================================

    /// @notice 스테이킹 잔액 이전 성공
    function test_transferStake() public {
        uint256 transferAmount = 20e27;

        vm.prank(disputeContract);
        seigManager.transferStake(address(layer2), sequencer, challenger1, transferAmount);

        assertEq(coinage.balanceOf(sequencer), 80e27, "Sequencer balance after transfer");
        assertEq(coinage.balanceOf(challenger1), 20e27, "Challenger balance after transfer");
    }

    /// @notice 권한 없는 transferStake 실패
    function test_transferStake_notDisputeContract() public {
        vm.prank(challenger1);
        vm.expectRevert("only dispute contract");
        seigManager.transferStake(address(layer2), sequencer, challenger1, 10e27);
    }

    /// @notice 잔액 부족 transferStake 실패
    function test_transferStake_insufficientBalance() public {
        vm.prank(disputeContract);
        vm.expectRevert("insufficient balance");
        seigManager.transferStake(address(layer2), sequencer, challenger1, 200e27);
    }

    // ==========================================
    // 반복 슬래싱 테스트
    // ==========================================

    /// @notice 연속 슬래싱 기록
    function test_slashSequencer_multipleSlashes() public {
        // 첫 번째 슬래싱
        address[] memory challengers = new address[](1);
        challengers[0] = challenger1;

        vm.prank(disputeContract);
        seigManager.slashSequencer(address(layer2), challengers);

        // 시퀀서 담보금 재설정
        coinage.mint(sequencer, 100e27);
        seigManager.setSequencerAdditionalReward(address(layer2), additionalReward);

        // 두 번째 슬래싱
        vm.warp(block.timestamp + 1 days);
        challengers[0] = challenger2;

        vm.prank(disputeContract);
        seigManager.slashSequencer(address(layer2), challengers);

        // 슬래싱 기록 확인
        uint256[] memory timestamps = seigManager.getSlashTimestamps(address(layer2));
        assertEq(timestamps.length, 2, "Should have 2 slash records");
    }
}
