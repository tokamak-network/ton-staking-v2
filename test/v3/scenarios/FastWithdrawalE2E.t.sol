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

    // BLS Precompile addresses (EIP-2537 Final Spec - Pectra/Prague)
    address constant BLS12_G1ADD = address(0x0b);
    address constant BLS12_G2ADD = address(0x0d);
    address constant BLS12_PAIRING = address(0x0f);
    address constant BLS12_MAP_FP2_TO_G2 = address(0x11);

    // BLS signing tool path (built from clients/fast-withdrawal/validator/cmd/bls-sign/)
    string constant BLS_SIGN_BINARY = "clients/fast-withdrawal/validator/bls-sign";

    // Real BLS keys for test validators (generated with keygen tool, chainId=31337)
    // Validator1 (0x6001)
    string constant VALIDATOR1_BLS_PRIVKEY = "0x9c33ed76f5490864d72551f35796016aa7d5f93174c2437de8f4ab11f5258d10";
    bytes constant VALIDATOR1_BLS_PUBKEY = hex"0000000000000000000000000000000008dd19a9924e56482f1fb8fbb5fa665496948a95500938aac1a04f96e18b65753fd658ea31ebd65e36586b4ae3be864a000000000000000000000000000000000c9c677d1af0f283c1d8800ae5238fd8b7ce5e685c261d51cb1c8e3626410fdc78516cfadd9f5efa8f261b5dbd1216ef";
    bytes constant VALIDATOR1_BLS_POP = hex"000000000000000000000000000000001185b0d867dd1319d682b6ee70ecc61be32c2de148d0d3ef2cec07e5c11fcac1f47e69cf3d4f8fd61a7b08af1aa2f398000000000000000000000000000000000da99cef12f89e624c7ef51608e96e46c6cfa0781297864024a86f3c6c73fdafc4dc6327bc9805766cd6cd8ab7ac0b3e000000000000000000000000000000000909bb5b50f4ada369ac68df8a87f9a66e11c701a1bad693fecb76c30a09188802ca682d01cff813af0c58e937eefabb0000000000000000000000000000000016e448f37800315500bfec7b5a87fc8141b7f3dd1df49a76896cf617d50b854d73a555807b900c13a66e0a1cc1fdecec";

    // Validator2 (0x6002)
    string constant VALIDATOR2_BLS_PRIVKEY = "0xfd72db178184bf8d3f0d7fedb559a5487952e9fca5484ab739aee3eaae9b3223";
    bytes constant VALIDATOR2_BLS_PUBKEY = hex"000000000000000000000000000000000515b71131247e820dbf1a31d881cd954d578051aa692313481564e9747435c22a5a462009d89a4902f7f32055f3156f000000000000000000000000000000000d4ac3891d89cb8884bf2eb8fbf69cffac94065e03cc644e1b9ba0fd0772e5e478411af4522e09a28aa98c5e59919b28";
    bytes constant VALIDATOR2_BLS_POP = hex"0000000000000000000000000000000001a8602c6d88ce5327d5e5c949c88007ea79ce4ab9044b941b4a0134c1ee768574687bcf5cbe81205c547369607b33d40000000000000000000000000000000000212ea6545b4decca5aaccac5186a20583da975c5e05ffccb1c152435f4923ef8ab370b1fb0cfbe313a58365b08cb96000000000000000000000000000000000dfd3dcb5ed1d2731b59f1cc8fa6d14ca2874821f34a49e1c1812562448f7eb1d0cade2d5ca269aa0a1d39c7dfe2b0be000000000000000000000000000000000d671495f0ece7376e7db2c5ec12b95a36bfb0ff95010631039193b6e819334b79053c543b34ecd6f133ba4b469d369e";

    // Validator3 (0x6003)
    string constant VALIDATOR3_BLS_PRIVKEY = "0x6ba4df8793eca8889975a0965783b3c530a8b6311c433dda4c3a13b0fdcd916a";
    bytes constant VALIDATOR3_BLS_PUBKEY = hex"000000000000000000000000000000000d50b97cc57e49de3afefa05a6f3118067fb6ac6fc86f699736cfee1b9710b700c59478bfd56fffeaf6e9cc48ef49b1e00000000000000000000000000000000084a9c95e53f76f4270e4e5f4949462e07165a9c68701eeaede303a9de6372364d1c264c7fcc22e256d279d726b6cf5c";
    bytes constant VALIDATOR3_BLS_POP = hex"000000000000000000000000000000000ee686d1cbc7112c2de5dfe90238f6389cbeeca7c9d8f15cd6374cc3675808433be388e30df9172cd7b7a2bc10fe6d12000000000000000000000000000000000e1665228fcce67ec65822036bc8d64b0fa1d6b59df880c27b1e05ebd0f9ee65e96615b120496925c00993a15a431417000000000000000000000000000000000651a0fe19745451c6fa8eacc93be2eb0ad49c00d25ab7ce2e30f9cc311c9f422c84f1992c54f89e44ec0af0cde6e99400000000000000000000000000000000093fd2139ea871eec049aa38c17efc99d849aa7926645421f3558f6b5d240022137f3797a86e2f006193c216ca06b7d4";

    // Dummy BLS signature (256 bytes, for tests that revert before BLS verification)
    bytes constant DUMMY_BLS_SIGNATURE = hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

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

        // BLS precompile mock 설정 (네이티브 미지원 시)
        if (!_isBLSPrecompileNative()) {
            _usingMockBLS = true;
        }
        _setupBLSMocks();

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

    /// @notice Check if BLS precompiles are natively available (EIP-2537)
    function _isBLSPrecompileNative() internal view returns (bool) {
        bytes memory input = new bytes(256);
        (bool success, bytes memory output) = BLS12_G1ADD.staticcall{gas: 50000}(input);
        return success && output.length == 128;
    }

    /// @notice Setup mock BLS precompiles if native ones aren't available
    /// @dev Uses vm.etch to deploy minimal bytecode at precompile addresses
    /// @dev Mock behavior:
    ///   - G1ADD (0x0b): returns first 128 bytes of calldata
    ///   - G2ADD (0x0d): returns first 256 bytes of calldata
    ///   - G2MSM (0x0e): returns first 256 bytes of calldata
    ///   - PAIRING (0x0f): always returns 1 (valid)
    ///   - MAP_FP_TO_G1 (0x10): returns 128 zero bytes
    ///   - MAP_FP2_TO_G2 (0x11): returns 256 zero bytes
    function _setupBLSMocks() internal {
        if (_isBLSPrecompileNative()) return; // Skip if real precompiles available

        // G1ADD: calldatacopy(0, 0, 128); return(0, 128)
        vm.etch(BLS12_G1ADD, hex"608060006000376080600060003960806000f3");
        // Actually simpler: PUSH1 0x80, PUSH1 0, PUSH1 0, CALLDATACOPY, PUSH1 0x80, PUSH1 0, RETURN
        vm.etch(BLS12_G1ADD, hex"6080600060003760806000f3");

        // G2ADD: calldatacopy(0, 0, 256); return(0, 256)
        vm.etch(BLS12_G2ADD, hex"6101006000600037610100600060003961010060006000f3");
        vm.etch(BLS12_G2ADD, hex"61010060006000376101006000f3");

        // G2MSM (0x0e): calldatacopy(0, 0, 256); return(0, 256) - same as G2ADD
        vm.etch(address(0x0e), hex"61010060006000376101006000f3");

        // PAIRING: mstore(0, 1); return(0, 32) → always valid
        vm.etch(BLS12_PAIRING, hex"600160005260206000f3");

        // MAP_FP_TO_G1 (0x10): return(0, 128) → 128 zero bytes
        vm.etch(address(0x10), hex"60806000f3");

        // MAP_FP2_TO_G2: return(0, 256) → 256 zero bytes
        vm.etch(BLS12_MAP_FP2_TO_G2, hex"6101006000f3");
    }

    bool internal _usingMockBLS;

    /// @notice Check if we're using mocked BLS precompiles
    function _isUsingMockBLS() internal view returns (bool) {
        return _usingMockBLS;
    }

    // ==========================================
    // BLS FFI Signing Helpers
    // ==========================================

    /// @notice Compute the BLS message hash matching RATFastWithdrawalLib.constructBLSMessage
    function _computeBLSMessage(
        RATFastWithdrawalLib.FastWithdrawalInput memory input
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(
            "TOKAMAK_FAST_WITHDRAWAL",
            block.chainid,
            input.systemConfig,
            input.withdrawalHash,
            input.stateRoot,
            input.leafA,
            input.leafB
        ));
    }

    /// @notice Sign a BLS message using FFI (calls bls-sign Go binary)
    /// @dev When using mock precompiles, returns dummy signature since verification is mocked
    /// @param privateKeys Comma-separated 0x-prefixed private keys
    /// @param messageHash 32-byte message hash to sign
    /// @return Aggregated BLS signature (256 bytes)
    function _signBLS(string memory privateKeys, bytes32 messageHash) internal returns (bytes memory) {
        if (_isUsingMockBLS()) {
            // With mock precompiles, PAIRING always returns 1, so any 256-byte signature works
            return DUMMY_BLS_SIGNATURE;
        }
        string[] memory cmd = new string[](5);
        cmd[0] = BLS_SIGN_BINARY;
        cmd[1] = "--private-keys";
        cmd[2] = privateKeys;
        cmd[3] = "--message";
        cmd[4] = vm.toString(messageHash);
        return vm.ffi(cmd);
    }

    /// @notice Register validator with BLS key (two-step: registerValidator + registerBLSPublicKey)
    function _registerValidatorWithBLS(
        address validator,
        bytes memory pubkey,
        bytes memory pop
    ) internal {
        vm.prank(validator);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator);
        ratFastWithdrawal.registerBLSPublicKey(address(mockSystemConfig), pubkey, pop);
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

    /// @notice 테스트: 단일 검증자 verifyAndExecuteFastWithdrawal 전체 흐름
    /// @dev BLS precompile 필요 (EIP-2537, --evm-version prague), FFI로 BLS 서명 생성
    function test_E2E_VerifyAndExecuteFastWithdrawal_WithBLS() public {
        // 검증자 등록 + BLS 키 등록 (실제 PoP 검증)
        _registerValidatorWithBLS(validator1, VALIDATOR1_BLS_PUBKEY, VALIDATOR1_BLS_POP);

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

        // BLS 메시지 해시 계산 후 FFI로 서명
        bytes32 blsMessage = _computeBLSMessage(input);
        bytes memory blsSignature = _signBLS(VALIDATOR1_BLS_PRIVKEY, blsMessage);

        uint256 userBalanceBefore = withdrawUser.balance;
        uint256 aggregatorBalanceBefore = aggregator.balance;
        uint256 fee = 0.1 ether;

        vm.deal(aggregator, 1 ether);
        vm.prank(aggregator);

        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: fee}(
            testWithdrawal,
            input,
            blsSignature
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

    /// @notice 테스트: 3명 검증자 집계 서명으로 Fast Withdrawal 실행
    /// @dev BLS precompile 필요, FFI로 3개 키의 집계 BLS 서명 생성
    function test_E2E_VerifyAndExecute_MultipleValidators() public {
        // 3명 검증자 등록 with 각자 고유한 BLS keys
        _registerValidatorWithBLS(validator1, VALIDATOR1_BLS_PUBKEY, VALIDATOR1_BLS_POP);
        _registerValidatorWithBLS(validator2, VALIDATOR2_BLS_PUBKEY, VALIDATOR2_BLS_POP);
        _registerValidatorWithBLS(validator3, VALIDATOR3_BLS_PUBKEY, VALIDATOR3_BLS_POP);

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
            validatorBitmap: 7,  // 0b111 = all 3 validators
            leafA: leafA,
            leafB: leafB,
            proofsA: proofsA,
            proofsB: proofsB
        });

        // 3개 개인키로 집계 BLS 서명 생성 (FFI)
        bytes32 blsMessage = _computeBLSMessage(input);
        string memory allKeys = string(abi.encodePacked(
            VALIDATOR1_BLS_PRIVKEY, ",",
            VALIDATOR2_BLS_PRIVKEY, ",",
            VALIDATOR3_BLS_PRIVKEY
        ));
        bytes memory blsSignature = _signBLS(allKeys, blsMessage);

        vm.deal(aggregator, 1 ether);
        vm.prank(aggregator);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: 0.1 ether}(testWithdrawal, input, blsSignature);

        assertTrue(portal.fastFinalizedWithdrawals(withdrawalHash));
    }

    // ==========================================
    // E2E: Non-Unanimous Bitmap Rejection
    // ==========================================

    /// @notice 테스트: 만장일치가 아닌 비트맵으로 revert
    /// @dev 만장일치 체크에서 revert되므로 BLS 서명 검증 도달 전 실패
    function test_E2E_VerifyAndExecute_NonUnanimous_Reverts() public {
        _registerValidatorWithBLS(validator1, VALIDATOR1_BLS_PUBKEY, VALIDATOR1_BLS_POP);
        _registerValidatorWithBLS(validator2, VALIDATOR2_BLS_PUBKEY, VALIDATOR2_BLS_POP);

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
            validatorBitmap: 1,  // Only validator1 signed (not unanimous for 2 validators)
            leafA: leafA,
            leafB: leafB,
            proofsA: proofsA,
            proofsB: proofsB
        });

        vm.deal(aggregator, 1 ether);
        vm.prank(aggregator);
        vm.expectRevert(FastWithdrawalNotUnanimousError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: 0.1 ether}(testWithdrawal, input, DUMMY_BLS_SIGNATURE);
    }

    // ==========================================
    // E2E: Minimum Validators Check
    // ==========================================

    /// @notice 테스트: 최소 검증자 수 미달로 revert
    /// @dev 최소 검증자 수 체크에서 revert되므로 BLS 서명 검증 도달 전 실패
    function test_E2E_VerifyAndExecute_InsufficientValidators_Reverts() public {
        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(3);

        _registerValidatorWithBLS(validator1, VALIDATOR1_BLS_PUBKEY, VALIDATOR1_BLS_POP);
        _registerValidatorWithBLS(validator2, VALIDATOR2_BLS_PUBKEY, VALIDATOR2_BLS_POP);

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
            validatorBitmap: 3,  // Both validators signed, but need 3
            leafA: leafA,
            leafB: leafB,
            proofsA: proofsA,
            proofsB: proofsB
        });

        vm.deal(aggregator, 1 ether);
        vm.prank(aggregator);
        vm.expectRevert(FastWithdrawalInsufficientValidatorsError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: 0.1 ether}(testWithdrawal, input, DUMMY_BLS_SIGNATURE);
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

    /// @notice 테스트: Fast Withdrawal 비활성화 시 revert
    /// @dev 비활성화 체크에서 revert되므로 BLS 서명 검증 도달 전 실패
    function test_E2E_FastWithdrawal_DisabledReverts() public {
        _registerValidatorWithBLS(validator1, VALIDATOR1_BLS_PUBKEY, VALIDATOR1_BLS_POP);

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
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: 0.1 ether}(testWithdrawal, input, DUMMY_BLS_SIGNATURE);
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

    /// @notice 테스트: 수수료 분배 (10% aggregator, 90% validators)
    /// @dev BLS precompile 필요, FFI로 BLS 서명 생성
    function test_E2E_FastWithdrawal_FeeDistribution() public {
        _registerValidatorWithBLS(validator1, VALIDATOR1_BLS_PUBKEY, VALIDATOR1_BLS_POP);

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

        // FFI로 BLS 서명 생성
        bytes32 blsMessage = _computeBLSMessage(input);
        bytes memory blsSignature = _signBLS(VALIDATOR1_BLS_PRIVKEY, blsMessage);

        uint256 fee = 1 ether;
        uint256 aggregatorBalanceBefore = aggregator.balance;

        vm.deal(aggregator, 2 ether);
        vm.prank(aggregator);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal{value: fee}(testWithdrawal, input, blsSignature);

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
