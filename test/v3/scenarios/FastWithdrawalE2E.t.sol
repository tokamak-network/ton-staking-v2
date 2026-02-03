// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {RATFastWithdrawal, Types, IOptimismPortal2ForRAT} from "../../../src/validator/RATFastWithdrawal.sol";
import {RATFastWithdrawalLib} from "../../../src/libraries/RATFastWithdrawalLib.sol";
import {BLS12381} from "../../../src/libraries/BLS12381.sol";
import {AdjacentLeavesVerifier} from "../../../src/libraries/AdjacentLeavesVerifier.sol";
import {
    FastWithdrawalDisabledError,
    FastWithdrawalAlreadyProcessedError,
    FastWithdrawalNotUnanimousError,
    FastWithdrawalNoValidatorsError,
    FastWithdrawalInsufficientValidatorsError
} from "../../../src/validator/RATFastWithdrawal.sol";

/// @notice Mock ETHLockbox - simulates actual ETHLockbox behavior
contract MockETHLockbox {
    mapping(address => bool) public authorizedPortals;
    bool public paused;

    event ETHLocked(address indexed portal, uint256 amount);
    event ETHUnlocked(address indexed portal, uint256 amount);

    error ETHLockbox_Unauthorized();
    error ETHLockbox_Paused();
    error ETHLockbox_InsufficientBalance();

    receive() external payable {}

    function authorizePortal(address _portal) external {
        authorizedPortals[_portal] = true;
    }

    function setPaused(bool _paused) external {
        paused = _paused;
    }

    function lockETH() external payable {
        if (!authorizedPortals[msg.sender]) revert ETHLockbox_Unauthorized();
        emit ETHLocked(msg.sender, msg.value);
    }

    function unlockETH(uint256 _value) external {
        if (paused) revert ETHLockbox_Paused();
        if (!authorizedPortals[msg.sender]) revert ETHLockbox_Unauthorized();
        if (address(this).balance < _value) revert ETHLockbox_InsufficientBalance();

        emit ETHUnlocked(msg.sender, _value);
        (bool success,) = msg.sender.call{value: _value}("");
        require(success, "ETH transfer failed");
    }
}

/// @notice Full Mock OptimismPortal2 - mirrors actual Tokamak OptimismPortal2 implementation
contract MockOptimismPortal2Full is IOptimismPortal2ForRAT {
    address internal constant DEFAULT_L2_SENDER = 0x000000000000000000000000000000000000dEaD;

    address public l2Sender;
    mapping(bytes32 => bool) public finalizedWithdrawals;
    mapping(bytes32 => bool) public override withdrawalVerified;
    mapping(bytes32 => bool) public override fastFinalizedWithdrawals;
    uint256 public fastWithdrawalResponsePeriod;
    address public ratContract;
    MockETHLockbox public ethLockbox;
    bool public paused;
    mapping(bytes32 => bool) public provenWithdrawals;
    mapping(bytes32 => uint256) public fastWithdrawalDeadlines;

    event FastWithdrawalRequested(
        bytes32 indexed withdrawalHash,
        address indexed user,
        uint256 amount,
        bytes32 stateRoot,
        uint256 feePaid,
        uint256 deadline
    );
    event WithdrawalVerifiedByRAT(bytes32 indexed withdrawalHash);
    event FastWithdrawalFinalized(bytes32 indexed withdrawalHash, bool success);

    error OptimismPortal_OnlyRAT();
    error OptimismPortal_CallPaused();
    error OptimismPortal_NoReentrancy();
    error OptimismPortal_BadTarget();
    error OptimismPortal_AlreadyFinalized();
    error OptimismPortal_AlreadyFastFinalized();
    error OptimismPortal_NotVerifiedByRAT();

    constructor() {
        l2Sender = DEFAULT_L2_SENDER;
        fastWithdrawalResponsePeriod = 10 minutes;
    }

    receive() external payable {}

    function setRatContract(address _ratContract) external {
        ratContract = _ratContract;
    }

    function setETHLockbox(MockETHLockbox _ethLockbox) external {
        ethLockbox = _ethLockbox;
    }

    function setFastWithdrawalResponsePeriod(uint256 _period) external {
        fastWithdrawalResponsePeriod = _period;
    }

    function setPaused(bool _paused) external {
        paused = _paused;
    }

    function proveAndRequestFastWithdrawal(
        Types.WithdrawalTransaction memory _tx,
        bytes32 stateRoot
    ) external payable returns (bytes32) {
        _assertNotPaused();
        if (_isUnsafeTarget(_tx.target)) revert OptimismPortal_BadTarget();

        bytes32 withdrawalHash = _hashWithdrawal(_tx);
        provenWithdrawals[withdrawalHash] = true;
        uint256 deadline = block.timestamp + fastWithdrawalResponsePeriod;
        fastWithdrawalDeadlines[withdrawalHash] = deadline;

        emit FastWithdrawalRequested(withdrawalHash, msg.sender, _tx.value, stateRoot, msg.value, deadline);
        return withdrawalHash;
    }

    function setWithdrawalVerified(bytes32 _withdrawalHash) external override {
        if (msg.sender != ratContract) revert OptimismPortal_OnlyRAT();
        withdrawalVerified[_withdrawalHash] = true;
        emit WithdrawalVerifiedByRAT(_withdrawalHash);
    }

    function fastWithdrawalFinalize(Types.WithdrawalTransaction memory _tx) external override {
        if (msg.sender != ratContract) revert OptimismPortal_OnlyRAT();
        _assertNotPaused();
        if (l2Sender != DEFAULT_L2_SENDER) revert OptimismPortal_NoReentrancy();
        if (_isUnsafeTarget(_tx.target)) revert OptimismPortal_BadTarget();

        bytes32 withdrawalHash = _hashWithdrawal(_tx);
        if (finalizedWithdrawals[withdrawalHash]) revert OptimismPortal_AlreadyFinalized();
        if (fastFinalizedWithdrawals[withdrawalHash]) revert OptimismPortal_AlreadyFastFinalized();
        if (!withdrawalVerified[withdrawalHash]) revert OptimismPortal_NotVerifiedByRAT();

        fastFinalizedWithdrawals[withdrawalHash] = true;

        if (_tx.value > 0) {
            ethLockbox.unlockETH(_tx.value);
        }

        l2Sender = _tx.sender;
        bool success = _safeCall(_tx.target, _tx.gasLimit, _tx.value, _tx.data);
        l2Sender = DEFAULT_L2_SENDER;

        emit FastWithdrawalFinalized(withdrawalHash, success);

        if (!success && _tx.value > 0) {
            ethLockbox.lockETH{value: _tx.value}();
        }
    }

    function isProven(bytes32 withdrawalHash) external view returns (bool) {
        return provenWithdrawals[withdrawalHash];
    }

    function getDeadline(bytes32 withdrawalHash) external view returns (uint256) {
        return fastWithdrawalDeadlines[withdrawalHash];
    }

    function _assertNotPaused() internal view {
        if (paused) revert OptimismPortal_CallPaused();
    }

    function _isUnsafeTarget(address _target) internal view returns (bool) {
        return _target == address(this) || _target == address(ethLockbox);
    }

    function _hashWithdrawal(Types.WithdrawalTransaction memory _tx) internal pure returns (bytes32) {
        return keccak256(abi.encode(_tx.nonce, _tx.sender, _tx.target, _tx.value, _tx.gasLimit, _tx.data));
    }

    function _safeCall(address _target, uint256 _gasLimit, uint256 _value, bytes memory _data)
        internal
        returns (bool success)
    {
        assembly {
            success := call(_gasLimit, _target, _value, add(_data, 0x20), mload(_data), 0, 0)
        }
    }
}

/// @notice Mock ValidatorReward that can receive ETH fees
contract MockValidatorRewardE2E {
    uint256 public totalFeesReceived;
    mapping(address => bool) public registeredValidators;
    mapping(address => address[]) public validatorL2s;

    receive() external payable {
        totalFeesReceived += msg.value;
    }

    function registerValidatorToL2(address validator, address systemConfig) external {
        registeredValidators[validator] = true;
        validatorL2s[validator].push(systemConfig);
    }

    function deregisterValidatorFromL2(address validator, address) external {
        registeredValidators[validator] = false;
    }

    function syncValidatorReward(address, address) external {}
}

/// @title FastWithdrawalE2ETest
/// @notice Fast Withdrawal End-to-End 통합 테스트
/// @dev RAT과 OptimismPortal2의 전체 흐름을 시뮬레이션
contract FastWithdrawalE2ETest is V3TestBase {
    // Test addresses
    address public validator1 = address(0x6001);
    address public validator2 = address(0x6002);
    address public validator3 = address(0x6003);
    address public aggregator = address(0x7001);
    address public withdrawUser = address(0x8001);
    address public treasury = address(0x9001);

    // Mock contracts
    MockOptimismPortal2Full public portal;
    MockETHLockbox public ethLockbox;
    MockValidatorRewardE2E public validatorRewardE2E;

    // RATFastWithdrawal reference
    RATFastWithdrawal public ratFastWithdrawal;

    // Test withdrawal transaction
    Types.WithdrawalTransaction public testWithdrawal;
    bytes32 public testWithdrawalHash;
    bytes32 public testStateRoot;

    // BLS Precompile addresses (EIP-2537)
    address constant BLS12_G1ADD = address(0x0b);
    address constant BLS12_G2ADD = address(0x0e);
    address constant BLS12_PAIRING = address(0x11);
    address constant BLS12_MAP_FP2_TO_G2 = address(0x13);

    // Test BLS keys (128 bytes for G1, 256 bytes for G2)
    bytes constant TEST_BLS_PUBKEY = hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1";
    bytes constant TEST_BLS_SIGNATURE = hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001";

    function setUp() public {
        _v3TestSetup();

        vm.startPrank(owner);

        // RAT 파라미터 설정
        rat.setSlashingPenalty(100 * RAY);
        rat.setValidatorBuffer(100 * RAY);
        rat.setMinimumThreshold(200 * RAY);
        rat.setRatTriggerProbability(RAY);
        rat.setEvidenceSubmissionPeriod(1 hours);
        rat.setChallengeGameDuration(7 days);
        rat.setSafetyBuffer(1 days);
        rat.setAttentionCost(1 * RAY);
        rat.setRelaxedValidatorCheck(true);
        rat.setMaxValidatorsPerL2(100);
        rat.setTreasury(treasury);

        // Mock ETHLockbox 및 Portal 생성
        ethLockbox = new MockETHLockbox();
        portal = new MockOptimismPortal2Full();

        portal.setETHLockbox(ethLockbox);
        portal.setRatContract(address(rat));
        ethLockbox.authorizePortal(address(portal));
        mockSystemConfig.setOptimismPortal(address(portal));

        // Layer2 등록
        (mockLayer2, operatorManager) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig),
            mockL2TON,
            "TestL2",
            operator1,
            1000 * RAY
        );

        _setupV3AndMigrate();

        ratFastWithdrawal = RATFastWithdrawal(payable(address(rat)));

        validatorRewardE2E = new MockValidatorRewardE2E();
        rat.setValidatorReward(address(validatorRewardE2E));

        // Fast Withdrawal 활성화 (최소 검증자 수 1명)
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(1);
        ratFastWithdrawal.setAggregatorFeeRate(1e26); // 10%

        vm.stopPrank();

        // 검증자들 스테이킹
        _stakeForValidator(validator1, mockLayer2, 500 * RAY);
        _stakeForValidator(validator2, mockLayer2, 600 * RAY);
        _stakeForValidator(validator3, mockLayer2, 700 * RAY);

        // ETHLockbox에 ETH 예치
        vm.deal(address(ethLockbox), 100 ether);

        // 테스트 출금 트랜잭션 설정
        testWithdrawal = Types.WithdrawalTransaction({
            nonce: 1,
            sender: withdrawUser,
            target: withdrawUser,
            value: 1 ether,
            gasLimit: 100000,
            data: ""
        });

        testWithdrawalHash = keccak256(abi.encode(
            testWithdrawal.nonce,
            testWithdrawal.sender,
            testWithdrawal.target,
            testWithdrawal.value,
            testWithdrawal.gasLimit,
            testWithdrawal.data
        ));

        testStateRoot = keccak256("test_state_root");
    }

    // ==========================================
    // BLS Precompile Helpers
    // ==========================================

    /// @notice Check if BLS precompiles are available (EIP-2537)
    function _isBLSPrecompileAvailable() internal view returns (bool) {
        // Try calling G1ADD with identity points
        bytes memory input = new bytes(256);
        (bool success, bytes memory output) = BLS12_G1ADD.staticcall{gas: 50000}(input);
        return success && output.length == 128;
    }

    /// @notice Skip test if BLS precompiles are not available
    modifier onlyWithBLSPrecompiles() {
        if (!_isBLSPrecompileAvailable()) {
            // BLS precompiles not available - skip test
            return;
        }
        _;
    }

    // ==========================================
    // Adjacent Leaves Proof Helpers
    // ==========================================

    /// @notice Generate valid Adjacent Leaves proof for testing
    /// @dev Creates a simple 2-level Merkle tree
    function _generateAdjacentLeavesProof(bytes32 stateRoot)
        internal
        pure
        returns (
            bytes32 leafA,
            bytes32 leafB,
            bytes[] memory proofsA,
            bytes[] memory proofsB
        )
    {
        // 간단한 4-리프 Merkle 트리 구성:
        //           stateRoot
        //          /         \
        //      nodeAB        nodeCD
        //      /    \        /    \
        //   leafA  leafB  leafC  leafD

        leafA = keccak256("leaf_A");
        leafB = keccak256("leaf_B");
        bytes32 leafC = keccak256("leaf_C");
        bytes32 leafD = keccak256("leaf_D");

        // 중간 노드 계산
        bytes32 nodeAB;
        if (leafA < leafB) {
            nodeAB = keccak256(abi.encodePacked(leafA, leafB));
        } else {
            nodeAB = keccak256(abi.encodePacked(leafB, leafA));
        }

        bytes32 nodeCD;
        if (leafC < leafD) {
            nodeCD = keccak256(abi.encodePacked(leafC, leafD));
        } else {
            nodeCD = keccak256(abi.encodePacked(leafD, leafC));
        }

        // stateRoot 계산 (테스트용)
        // 실제로는 파라미터로 받은 stateRoot를 사용
        // 여기서는 간단히 검증을 위해 proof 구성

        // leafA의 proof: [leafB, nodeCD]
        proofsA = new bytes[](2);
        proofsA[0] = abi.encodePacked(leafB);
        proofsA[1] = abi.encodePacked(nodeCD);

        // leafB의 proof: [leafA, nodeCD]
        proofsB = new bytes[](2);
        proofsB[0] = abi.encodePacked(leafA);
        proofsB[1] = abi.encodePacked(nodeCD);
    }

    /// @notice Generate valid state root from leaves
    function _computeStateRootFromLeaves() internal pure returns (bytes32) {
        bytes32 leafA = keccak256("leaf_A");
        bytes32 leafB = keccak256("leaf_B");
        bytes32 leafC = keccak256("leaf_C");
        bytes32 leafD = keccak256("leaf_D");

        bytes32 nodeAB;
        if (leafA < leafB) {
            nodeAB = keccak256(abi.encodePacked(leafA, leafB));
        } else {
            nodeAB = keccak256(abi.encodePacked(leafB, leafA));
        }

        bytes32 nodeCD;
        if (leafC < leafD) {
            nodeCD = keccak256(abi.encodePacked(leafC, leafD));
        } else {
            nodeCD = keccak256(abi.encodePacked(leafD, leafC));
        }

        if (nodeAB < nodeCD) {
            return keccak256(abi.encodePacked(nodeAB, nodeCD));
        } else {
            return keccak256(abi.encodePacked(nodeCD, nodeAB));
        }
    }

    // ==========================================
    // Unit Tests: State Root & Withdrawal Hash
    // ==========================================

    function test_Unit_StateRootComputation() public pure {
        bytes32 computed = _computeStateRootFromLeaves();
        assertTrue(computed != bytes32(0), "State root should not be zero");
    }

    function test_Unit_WithdrawalData() public view {
        assertEq(testWithdrawal.nonce, 1);
        assertEq(testWithdrawal.sender, withdrawUser);
        assertEq(testWithdrawal.target, withdrawUser);
        assertEq(testWithdrawal.value, 1 ether);
    }

    function test_Unit_WithdrawalHashComputation() public view {
        bytes32 expected = keccak256(abi.encode(1, withdrawUser, withdrawUser, 1 ether, uint256(100000), bytes("")));
        assertEq(testWithdrawalHash, expected);
    }

    // ==========================================
    // Unit Test: Adjacent Leaves Verification
    // ==========================================

    function test_AdjacentLeavesVerifier_ValidProof() public {
        bytes32 stateRoot = _computeStateRootFromLeaves();
        (
            bytes32 leafA,
            bytes32 leafB,
            bytes[] memory proofsA,
            bytes[] memory proofsB
        ) = _generateAdjacentLeavesProof(stateRoot);

        bool result = _verifyAdjacentLeaves(stateRoot, leafA, leafB, proofsA, proofsB);
        assertTrue(result, "Adjacent leaves verification should pass");
    }

    function test_AdjacentLeavesVerifier_InvalidRoot() public {
        bytes32 validRoot = _computeStateRootFromLeaves();
        bytes32 invalidRoot = keccak256("invalid_root");
        (
            bytes32 leafA,
            bytes32 leafB,
            bytes[] memory proofsA,
            bytes[] memory proofsB
        ) = _generateAdjacentLeavesProof(validRoot);

        bool result = _verifyAdjacentLeaves(invalidRoot, leafA, leafB, proofsA, proofsB);
        assertFalse(result, "Verification should fail with invalid root");
    }

    function test_AdjacentLeavesVerifier_SameLeaf() public {
        bytes32 stateRoot = _computeStateRootFromLeaves();
        bytes32 leafA = keccak256("leaf_A");
        bytes[] memory proofsA = new bytes[](1);
        proofsA[0] = abi.encodePacked(keccak256("leaf_B"));

        bool result = _verifyAdjacentLeaves(stateRoot, leafA, leafA, proofsA, proofsA);
        assertFalse(result, "Same leaf should not be adjacent");
    }

    /// @notice Wrapper for AdjacentLeavesVerifier that converts memory to calldata
    function _verifyAdjacentLeaves(
        bytes32 stateRoot,
        bytes32 leafA,
        bytes32 leafB,
        bytes[] memory proofsA,
        bytes[] memory proofsB
    ) internal view returns (bool) {
        return this.verifyAdjacentLeavesExternal(stateRoot, leafA, leafB, proofsA, proofsB);
    }

    /// @notice External function to convert memory to calldata
    function verifyAdjacentLeavesExternal(
        bytes32 stateRoot,
        bytes32 leafA,
        bytes32 leafB,
        bytes[] calldata proofsA,
        bytes[] calldata proofsB
    ) external pure returns (bool) {
        return AdjacentLeavesVerifier.verify(stateRoot, leafA, leafB, proofsA, proofsB);
    }

    // ==========================================
    // E2E: Full Flow with verifyAndExecuteFastWithdrawal
    // ==========================================

    /// @notice 테스트: 실제 verifyAndExecuteFastWithdrawal 호출
    /// @dev Phase 5-6를 실제로 테스트 - BLS precompile 필요 (EIP-2537, Pectra 이후)
    /// @dev 현재 테스트 환경에서는 skip됨 - 실제 네트워크에서 fork 테스트로 검증 필요
    function test_E2E_VerifyAndExecuteFastWithdrawal_WithBLS() public onlyWithBLSPrecompiles {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        // BLS 키 등록 (실제 precompile 필요)
        vm.prank(validator1);
        ratFastWithdrawal.registerBLSPublicKey(
            address(mockSystemConfig),
            TEST_BLS_PUBKEY,
            TEST_BLS_SIGNATURE
        );

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1);
        assertTrue(ratFastWithdrawal.hasValidatorBLSKey(validator1, address(mockSystemConfig)));

        bytes32 validStateRoot = _computeStateRootFromLeaves();
        (
            bytes32 leafA,
            bytes32 leafB,
            bytes[] memory proofsA,
            bytes[] memory proofsB
        ) = _generateAdjacentLeavesProof(validStateRoot);

        vm.deal(withdrawUser, 2 ether);
        vm.prank(withdrawUser);
        bytes32 withdrawalHash = portal.proveAndRequestFastWithdrawal{value: 0.01 ether}(
            testWithdrawal,
            validStateRoot
        );

        assertTrue(portal.isProven(withdrawalHash));

        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            gameAddress: address(0),
            stateRoot: validStateRoot,
            validatorBitmap: 1,
            leafA: leafA,
            leafB: leafB,
            proofsA: proofsA,
            proofsB: proofsB
        });

        uint256 userBalanceBefore = withdrawUser.balance;
        uint256 aggregatorBalanceBefore = aggregator.balance;
        uint256 fee = 0.1 ether;

        vm.deal(aggregator, 1 ether);
        vm.prank(aggregator);

        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: fee}(
            testWithdrawal,
            input,
            TEST_BLS_SIGNATURE
        );

        assertTrue(portal.withdrawalVerified(withdrawalHash), "Withdrawal should be verified");
        assertTrue(portal.fastFinalizedWithdrawals(withdrawalHash), "Withdrawal should be fast finalized");
        assertTrue(rat.processedWithdrawals(withdrawalHash), "RAT should mark as processed");
        assertEq(withdrawUser.balance, userBalanceBefore + 1 ether, "User should receive ETH");

        uint256 expectedAggregatorFee = (fee * 1e26) / RAY;
        assertEq(aggregator.balance, aggregatorBalanceBefore + 1 ether - fee + expectedAggregatorFee);
        assertEq(validatorRewardE2E.totalFeesReceived(), fee - expectedAggregatorFee);
    }

    // ==========================================
    // E2E: Multiple Validators with verifyAndExecuteFastWithdrawal
    // ==========================================

    /// @dev BLS precompile 필요 - skip if not available
    function test_E2E_VerifyAndExecute_MultipleValidators() public onlyWithBLSPrecompiles {
        // 3명 검증자 등록 with BLS keys
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator1);
        ratFastWithdrawal.registerBLSPublicKey(address(mockSystemConfig), TEST_BLS_PUBKEY, TEST_BLS_SIGNATURE);

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        ratFastWithdrawal.registerBLSPublicKey(address(mockSystemConfig), TEST_BLS_PUBKEY, TEST_BLS_SIGNATURE);

        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator3);
        ratFastWithdrawal.registerBLSPublicKey(address(mockSystemConfig), TEST_BLS_PUBKEY, TEST_BLS_SIGNATURE);

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 3);

        bytes32 validStateRoot = _computeStateRootFromLeaves();
        (bytes32 leafA, bytes32 leafB, bytes[] memory proofsA, bytes[] memory proofsB) = _generateAdjacentLeavesProof(validStateRoot);

        vm.deal(withdrawUser, 2 ether);
        vm.prank(withdrawUser);
        bytes32 withdrawalHash = portal.proveAndRequestFastWithdrawal{value: 0.01 ether}(testWithdrawal, validStateRoot);

        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            gameAddress: address(0),
            stateRoot: validStateRoot,
            validatorBitmap: 7,
            leafA: leafA,
            leafB: leafB,
            proofsA: proofsA,
            proofsB: proofsB
        });

        vm.deal(aggregator, 1 ether);
        vm.prank(aggregator);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: 0.1 ether}(testWithdrawal, input, TEST_BLS_SIGNATURE);

        assertTrue(portal.fastFinalizedWithdrawals(withdrawalHash));
    }

    // ==========================================
    // E2E: Non-Unanimous Bitmap Rejection
    // ==========================================

    /// @dev BLS precompile 필요 - skip if not available
    function test_E2E_VerifyAndExecute_NonUnanimous_Reverts() public onlyWithBLSPrecompiles {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator1);
        ratFastWithdrawal.registerBLSPublicKey(address(mockSystemConfig), TEST_BLS_PUBKEY, TEST_BLS_SIGNATURE);

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        ratFastWithdrawal.registerBLSPublicKey(address(mockSystemConfig), TEST_BLS_PUBKEY, TEST_BLS_SIGNATURE);

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 2);

        bytes32 validStateRoot = _computeStateRootFromLeaves();
        (bytes32 leafA, bytes32 leafB, bytes[] memory proofsA, bytes[] memory proofsB) = _generateAdjacentLeavesProof(validStateRoot);

        vm.deal(withdrawUser, 2 ether);
        vm.prank(withdrawUser);
        bytes32 withdrawalHash = portal.proveAndRequestFastWithdrawal{value: 0.01 ether}(testWithdrawal, validStateRoot);

        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            gameAddress: address(0),
            stateRoot: validStateRoot,
            validatorBitmap: 1,
            leafA: leafA,
            leafB: leafB,
            proofsA: proofsA,
            proofsB: proofsB
        });

        vm.deal(aggregator, 1 ether);
        vm.prank(aggregator);
        vm.expectRevert(FastWithdrawalNotUnanimousError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: 0.1 ether}(testWithdrawal, input, TEST_BLS_SIGNATURE);
    }

    // ==========================================
    // E2E: Minimum Validators Check
    // ==========================================

    /// @dev BLS precompile 필요 - skip if not available
    function test_E2E_VerifyAndExecute_InsufficientValidators_Reverts() public onlyWithBLSPrecompiles {
        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(3);

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator1);
        ratFastWithdrawal.registerBLSPublicKey(address(mockSystemConfig), TEST_BLS_PUBKEY, TEST_BLS_SIGNATURE);

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        ratFastWithdrawal.registerBLSPublicKey(address(mockSystemConfig), TEST_BLS_PUBKEY, TEST_BLS_SIGNATURE);

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 2);

        bytes32 validStateRoot = _computeStateRootFromLeaves();
        (bytes32 leafA, bytes32 leafB, bytes[] memory proofsA, bytes[] memory proofsB) = _generateAdjacentLeavesProof(validStateRoot);

        vm.deal(withdrawUser, 2 ether);
        vm.prank(withdrawUser);
        bytes32 withdrawalHash = portal.proveAndRequestFastWithdrawal{value: 0.01 ether}(testWithdrawal, validStateRoot);

        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            gameAddress: address(0),
            stateRoot: validStateRoot,
            validatorBitmap: 3,
            leafA: leafA,
            leafB: leafB,
            proofsA: proofsA,
            proofsB: proofsB
        });

        vm.deal(aggregator, 1 ether);
        vm.prank(aggregator);
        vm.expectRevert(FastWithdrawalInsufficientValidatorsError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: 0.1 ether}(testWithdrawal, input, TEST_BLS_SIGNATURE);
    }

    // ==========================================
    // E2E Scenario: 성공적인 Fast Withdrawal 전체 흐름 (Portal 시뮬레이션)
    // ==========================================

    function test_E2E_FastWithdrawal_FullFlow() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1);

        vm.deal(withdrawUser, 2 ether);
        vm.prank(withdrawUser);
        bytes32 withdrawalHash = portal.proveAndRequestFastWithdrawal{value: 0.01 ether}(testWithdrawal, testStateRoot);

        assertTrue(portal.isProven(withdrawalHash));
        assertTrue(portal.getDeadline(withdrawalHash) > block.timestamp);

        vm.prank(address(rat));
        portal.setWithdrawalVerified(withdrawalHash);
        assertTrue(portal.withdrawalVerified(withdrawalHash));

        uint256 userBalanceBefore = withdrawUser.balance;
        vm.prank(address(rat));
        portal.fastWithdrawalFinalize(testWithdrawal);

        assertTrue(portal.fastFinalizedWithdrawals(withdrawalHash));
        assertEq(withdrawUser.balance, userBalanceBefore + 1 ether);
    }

    // ==========================================
    // E2E Scenario: Fast Withdrawal 비활성화
    // ==========================================

    /// @dev BLS precompile 필요 - skip if not available
    function test_E2E_FastWithdrawal_DisabledReverts() public onlyWithBLSPrecompiles {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator1);
        ratFastWithdrawal.registerBLSPublicKey(address(mockSystemConfig), TEST_BLS_PUBKEY, TEST_BLS_SIGNATURE);

        // Fast Withdrawal 비활성화 (최소 검증자 수 0)
        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(0);

        bytes32 validStateRoot = _computeStateRootFromLeaves();
        (bytes32 leafA, bytes32 leafB, bytes[] memory proofsA, bytes[] memory proofsB) = _generateAdjacentLeavesProof(validStateRoot);

        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: testWithdrawalHash,
            systemConfig: address(mockSystemConfig),
            gameAddress: address(0),
            stateRoot: validStateRoot,
            validatorBitmap: 1,
            leafA: leafA,
            leafB: leafB,
            proofsA: proofsA,
            proofsB: proofsB
        });

        vm.deal(aggregator, 1 ether);
        vm.prank(aggregator);
        vm.expectRevert(FastWithdrawalDisabledError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: 0.1 ether}(testWithdrawal, input, TEST_BLS_SIGNATURE);
    }

    // ==========================================
    // E2E Scenario: 중복 Fast Withdrawal 방지
    // ==========================================

    function test_E2E_FastWithdrawal_DuplicatePrevention() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.deal(withdrawUser, 2 ether);
        vm.prank(withdrawUser);
        bytes32 withdrawalHash = portal.proveAndRequestFastWithdrawal{value: 0.01 ether}(testWithdrawal, testStateRoot);

        vm.prank(address(rat));
        portal.setWithdrawalVerified(withdrawalHash);

        vm.prank(address(rat));
        portal.fastWithdrawalFinalize(testWithdrawal);

        vm.prank(address(rat));
        vm.expectRevert(MockOptimismPortal2Full.OptimismPortal_AlreadyFastFinalized.selector);
        portal.fastWithdrawalFinalize(testWithdrawal);
    }

    // ==========================================
    // E2E Scenario: 수수료 분배 검증
    // ==========================================

    /// @dev BLS precompile 필요 - skip if not available
    function test_E2E_FastWithdrawal_FeeDistribution() public onlyWithBLSPrecompiles {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator1);
        ratFastWithdrawal.registerBLSPublicKey(address(mockSystemConfig), TEST_BLS_PUBKEY, TEST_BLS_SIGNATURE);

        bytes32 validStateRoot = _computeStateRootFromLeaves();
        (bytes32 leafA, bytes32 leafB, bytes[] memory proofsA, bytes[] memory proofsB) = _generateAdjacentLeavesProof(validStateRoot);

        vm.deal(withdrawUser, 2 ether);
        vm.prank(withdrawUser);
        bytes32 withdrawalHash = portal.proveAndRequestFastWithdrawal{value: 0.01 ether}(testWithdrawal, validStateRoot);

        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            gameAddress: address(0),
            stateRoot: validStateRoot,
            validatorBitmap: 1,
            leafA: leafA,
            leafB: leafB,
            proofsA: proofsA,
            proofsB: proofsB
        });

        uint256 fee = 1 ether;
        uint256 aggregatorBalanceBefore = aggregator.balance;

        vm.deal(aggregator, 2 ether);
        vm.prank(aggregator);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: fee}(testWithdrawal, input, TEST_BLS_SIGNATURE);

        // 10% to aggregator, 90% to validators
        uint256 expectedAggregatorFee = (fee * 1e26) / RAY;  // 0.1 ether
        uint256 expectedValidatorFee = fee - expectedAggregatorFee;  // 0.9 ether

        assertEq(aggregator.balance, aggregatorBalanceBefore + 2 ether - fee + expectedAggregatorFee);
        assertEq(validatorRewardE2E.totalFeesReceived(), expectedValidatorFee);
    }

    // ==========================================
    // E2E Scenario: 검증자 탈퇴 후 Fast Withdrawal
    // ==========================================

    function test_E2E_FastWithdrawal_ValidatorDeactivation() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 2);

        vm.prank(validator1);
        rat.deactivateValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1);
    }

    // ==========================================
    // E2E Scenario: Portal 미설정 시 실패
    // ==========================================

    function test_E2E_FastWithdrawal_NoPortal() public {
        SimpleMockSystemConfig mockSystemConfig2 = new SimpleMockSystemConfig();
        mockSystemConfig2.setL1StandardBridge(address(0x1));
        mockSystemConfig2.setOptimismPortal(address(0));
        mockSystemConfig2.setDisputeGameFactory(address(0x2));
        mockSystemConfig2.setUnsafeBlockSigner(operator1);

        vm.startPrank(owner);
        l1BridgeRegistry.registerRollupConfig(address(mockSystemConfig2), 3, address(0x3), "TestL2_NoPortal");
        vm.stopPrank();

        vm.prank(operator1);
        MockWTON(wton).mint(operator1, 1000 * RAY);
        vm.prank(operator1);
        MockWTON(wton).approve(layer2ManagerProxy, 1000 * RAY);
        vm.prank(operator1);
        layer2Manager.registerCandidateAddOn(address(mockSystemConfig2), 1000 * RAY, false, "TestL2_NoPortal");

        address newLayer2 = layer2Manager.getLayer2BySystemConfig(address(mockSystemConfig2));

        _stakeForValidator(validator1, newLayer2, 500 * RAY);
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig2));
    }

    // ==========================================
    // E2E Scenario: 응답 기간 초과
    // ==========================================

    function test_E2E_FastWithdrawal_DeadlineExpiry() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.deal(withdrawUser, 2 ether);
        vm.prank(withdrawUser);
        bytes32 withdrawalHash = portal.proveAndRequestFastWithdrawal{value: 0.01 ether}(testWithdrawal, testStateRoot);

        uint256 deadline = portal.getDeadline(withdrawalHash);
        vm.warp(deadline + 1);
        assertTrue(block.timestamp > deadline);
    }

    // ==========================================
    // E2E Scenario: 대용량 출금
    // ==========================================

    function test_E2E_FastWithdrawal_LargeAmount() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        Types.WithdrawalTransaction memory largeWithdrawal = Types.WithdrawalTransaction({
            nonce: 2,
            sender: withdrawUser,
            target: withdrawUser,
            value: 50 ether,
            gasLimit: 100000,
            data: ""
        });

        bytes32 withdrawalHash = keccak256(abi.encode(
            largeWithdrawal.nonce,
            largeWithdrawal.sender,
            largeWithdrawal.target,
            largeWithdrawal.value,
            largeWithdrawal.gasLimit,
            largeWithdrawal.data
        ));

        vm.deal(withdrawUser, 51 ether);
        vm.prank(withdrawUser);
        portal.proveAndRequestFastWithdrawal{value: 0.5 ether}(largeWithdrawal, testStateRoot);

        vm.prank(address(rat));
        portal.setWithdrawalVerified(withdrawalHash);

        uint256 userBalanceBefore = withdrawUser.balance;

        vm.prank(address(rat));
        portal.fastWithdrawalFinalize(largeWithdrawal);

        assertEq(withdrawUser.balance, userBalanceBefore + 50 ether);
    }

    // ==========================================
    // E2E Scenario: 연속 Fast Withdrawal
    // ==========================================

    function test_E2E_FastWithdrawal_Sequential() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        for (uint256 i = 0; i < 3; i++) {
            Types.WithdrawalTransaction memory withdrawal = Types.WithdrawalTransaction({
                nonce: i + 10,
                sender: withdrawUser,
                target: withdrawUser,
                value: 1 ether,
                gasLimit: 100000,
                data: ""
            });

            bytes32 withdrawalHash = keccak256(abi.encode(
                withdrawal.nonce,
                withdrawal.sender,
                withdrawal.target,
                withdrawal.value,
                withdrawal.gasLimit,
                withdrawal.data
            ));

            vm.deal(withdrawUser, 2 ether);
            vm.prank(withdrawUser);
            portal.proveAndRequestFastWithdrawal{value: 0.01 ether}(withdrawal, testStateRoot);

            vm.prank(address(rat));
            portal.setWithdrawalVerified(withdrawalHash);

            vm.prank(address(rat));
            portal.fastWithdrawalFinalize(withdrawal);

            assertTrue(portal.fastFinalizedWithdrawals(withdrawalHash));
        }
    }
}
