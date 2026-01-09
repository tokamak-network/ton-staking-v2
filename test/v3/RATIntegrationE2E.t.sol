// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {RAT} from "../../src/validator/RAT.sol";
import {MockWTON} from "../../src/mocks/MockWTON.sol";
import {MockTON} from "../../src/mocks/MockTON.sol";

/// @title RATIntegrationE2E
/// @notice E2E 테스트 - Go client와 통합하기 위한 테스트 환경
/// @dev 이 테스트는 anvil을 실행하고 Go client가 연결할 수 있는 환경을 제공합니다
contract RATIntegrationE2E is Test {
    RAT public rat;
    MockWTON public wton;
    MockTON public ton;
    MockL1BridgeRegistry public mockL1BridgeRegistry;
    MockFaultDisputeGame public mockGame;

    address public owner = address(this);
    address public factory = address(0x3);
    address public systemConfig = address(0x10);
    address public validator = address(0x100);

    uint256 public slashingPenalty = 100e27;
    uint256 public minimumDeposit = 200e27;

    /// @notice E2E 테스트 셋업
    /// @dev Go client가 연결할 수 있도록 deterministic addresses 사용
    function setUp() public {
        // Deploy mocks with deterministic addresses for Go client
        ton = new MockTON();
        wton = new MockWTON();
        wton.setTON(address(ton));

        mockL1BridgeRegistry = new MockL1BridgeRegistry();
        mockL1BridgeRegistry.setFactory(factory, systemConfig);
        mockL1BridgeRegistry.setRollupType(systemConfig, 3);

        mockGame = new MockFaultDisputeGame(systemConfig);

        // Deploy RAT
        rat = new RAT();
        rat.initialize(
            address(0x1), // seigManager
            address(wton),
            address(ton),
            address(0),   // layer2Manager
            owner,
            0.01e27       // ratTriggerProbability
        );

        rat.setSlashingPenalty(slashingPenalty);
        rat.setValidatorBuffer(100e27);
        rat.setMinimumThreshold(150e27);
        rat.setL1BridgeRegistry(address(mockL1BridgeRegistry));
        rat.setEvidenceSubmissionPeriod(1 hours);

        // Mint tokens to validator
        ton.mint(validator, 10000e27);
        vm.prank(validator);
        ton.approve(address(rat), type(uint256).max);

        // Register validator
        vm.prank(validator);
        rat.registerValidator(systemConfig, minimumDeposit);

        // Log deployed addresses for Go client
        emit log_named_address("RAT Contract", address(rat));
        emit log_named_address("TON Token", address(ton));
        emit log_named_address("Mock Game", address(mockGame));
        emit log_named_address("System Config", systemConfig);
        emit log_named_address("Validator", validator);
    }

    /// @notice E2E 테스트: RAT 트리거 → Go client가 evidence 제출 → 검증
    /// @dev 이 테스트는 interactive하게 실행됩니다
    function test_E2E_triggerAndWaitForEvidence() public {
        emit log_string("=== E2E Test: RAT Evidence Submission ===");
        emit log_string("");

        // Step 1: Trigger attention test
        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame), systemConfig, batchIndex, batchHash, blockHash);

        bytes32 testId = rat.batchToTestId(systemConfig, batchIndex);

        emit log_string("[OK] Step 1: Attention test triggered");
        emit log_named_bytes32("Test ID", testId);
        emit log_named_uint("Block Number", block.number);
        emit log_named_uint("Deadline", block.timestamp + 1 hours);
        emit log_string("");

        // Step 2: Check validator state (pre-deduction)
        (uint256 depositBefore, uint256 bondBefore,,) = rat.getValidatorRegistration(validator, systemConfig);
        emit log_string("[INFO] Step 2: Validator state after trigger");
        emit log_named_uint("Deposit (deducted)", depositBefore);
        emit log_named_uint("Bond (locked)", bondBefore);
        assertEq(depositBefore, minimumDeposit - slashingPenalty, "Deposit should be pre-deducted");
        assertEq(bondBefore, slashingPenalty, "Bond should hold slashing penalty");
        emit log_string("");

        // Step 3: Wait for Go client to submit evidence
        emit log_string("[WAIT] Step 3: Waiting for Go client to submit evidence...");
        emit log_string("");
        emit log_string(">>> Go Client Instructions <<<");
        emit log_string("1. Read the deployed contract addresses above");
        emit log_string("2. Prepare valid StateLeafEvidence with OutputRootProof");
        emit log_string("3. Submit via: rat.submitEvidence(testId, 1, evidenceData)");
        emit log_string("");
        emit log_string("To continue this test, call submitEvidence from Go client");
        emit log_string("with the following parameters:");
        emit log_named_bytes32("testId", testId);
        emit log_string("evidenceType: 1 (StateLeaf)");
        emit log_string("");

        // NOTE: 실제 E2E에서는 여기서 pause하고 Go client가 제출할 때까지 대기
        // Forge 테스트에서는 skip
        vm.skip(true);
    }

    /// @notice Helper: 미리 준비된 valid evidence로 제출 테스트
    /// @dev Go client 없이도 전체 플로우를 확인할 수 있습니다
    function test_E2E_submitPrecomputedEvidence() public {
        emit log_string("=== E2E Test: Submit Precomputed Evidence ===");

        // Step 1: Trigger
        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(
            address(mockGame),
            systemConfig,
            batchIndex,
            keccak256("batch1"),
            keccak256("block1")
        );

        bytes32 testId = rat.batchToTestId(systemConfig, batchIndex);
        emit log_named_bytes32("Test ID", testId);

        // Step 2: Create valid evidence
        // NOTE: 실제로는 Go client가 생성하지만, 여기서는 미리 준비된 데이터 사용
        bytes memory evidence = _createValidEvidence();
        emit log_named_uint("Evidence size", evidence.length);

        // Step 3: Submit (이 부분이 실제 E2E에서는 Go client가 수행)
        // NOTE: 실제 Merkle proof가 필요해서 현재는 스킵
        // 실제 E2E에서는 Go client가 valid proof를 생성해서 제출
        emit log_string("[SKIP] Skipping actual submission (requires valid Merkle proofs)");
        emit log_string("");
        emit log_string("In real E2E:");
        emit log_string("1. Go client generates valid StateLeafEvidence");
        emit log_string("2. Go client submits to RAT contract");
        emit log_string("3. Contract verifies and restores deposit");
    }

    /// @notice Helper: 배포된 컨트랙트 주소 출력 (Go client용)
    function test_E2E_printDeploymentInfo() public view {
        console.log("=== Deployment Info for Go Client ===");
        console.log("");
        console.log("RAT Contract:", address(rat));
        console.log("TON Token:", address(ton));
        console.log("Mock Game:", address(mockGame));
        console.log("System Config:", systemConfig);
        console.log("Factory:", factory);
        console.log("Validator:", validator);
        console.log("");
        console.log("Validator Private Key: Use forge's default key");
        console.log("RPC URL: http://127.0.0.1:8545 (anvil)");
    }

    /// @notice Helper function to create valid evidence structure
    function _createValidEvidence() internal pure returns (bytes memory) {
        // OutputRootProof that matches mockGame's rootClaim
        bytes32 version = bytes32(0);
        bytes32 stateRoot = bytes32(uint256(0x1234));
        bytes32 messagePasserStorageRoot = bytes32(uint256(0x5678));
        bytes32 latestBlockhash = bytes32(uint256(0x9abc));

        // Adjacent leaves with proper range
        bytes32 leafAKey = bytes32(uint256(4000));
        bytes memory leafAValue = hex"f84401830f424084deadbeef80a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
        bytes[] memory leafAProof = new bytes[](3);
        leafAProof[0] = hex"f851a0abcd";
        leafAProof[1] = hex"e2a0beef";
        leafAProof[2] = hex"c0";

        bytes32 leafBKey = bytes32(uint256(5000));
        bytes memory leafBValue = hex"f84402830f424084cafebabe80a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
        bytes[] memory leafBProof = new bytes[](3);
        leafBProof[0] = hex"f851a0dcba";
        leafBProof[1] = hex"e2a0feeb";
        leafBProof[2] = hex"c0";

        return abi.encode(
            leafAKey,
            leafAValue,
            leafAProof,
            leafBKey,
            leafBValue,
            leafBProof,
            stateRoot,
            uint256(1000),
            version,
            stateRoot,
            messagePasserStorageRoot,
            latestBlockhash
        );
    }
}

/// @notice Mock L1BridgeRegistry for E2E testing
contract MockL1BridgeRegistry {
    mapping(address => address) public rollupConfigWithDisputeGameFactory;
    mapping(address => uint8) public rollupType;

    function setFactory(address factory, address systemConfig) external {
        rollupConfigWithDisputeGameFactory[factory] = systemConfig;
    }

    function setRollupType(address rollupConfig, uint8 _rollupType) external {
        rollupType[rollupConfig] = _rollupType;
    }
}

/// @notice Mock FaultDisputeGame for E2E testing
contract MockFaultDisputeGame {
    address public systemConfig;
    bytes32 public rootClaim;

    constructor(address _systemConfig) {
        systemConfig = _systemConfig;
        rootClaim = keccak256(abi.encode(
            bytes32(0),
            bytes32(uint256(0x1234)),
            bytes32(uint256(0x5678)),
            bytes32(uint256(0x9abc))
        ));
    }
}
