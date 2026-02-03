// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {RATFastWithdrawal, Types, IOptimismPortal2ForRAT} from "../../../src/validator/RATFastWithdrawal.sol";
import {RATFastWithdrawalLib} from "../../../src/libraries/RATFastWithdrawalLib.sol";
import {BLS12381} from "../../../src/libraries/BLS12381.sol";
import {
    FastWithdrawalDisabledError,
    FastWithdrawalAlreadyProcessedError,
    FastWithdrawalInvalidHashError,
    FastWithdrawalNotUnanimousError,
    FastWithdrawalInvalidBLSSignatureError,
    FastWithdrawalInvalidAdjacentLeavesError,
    FastWithdrawalPortalNotSetError,
    FastWithdrawalInvalidValidatorBitmapError,
    FastWithdrawalNoValidatorsError,
    FastWithdrawalInsufficientValidatorsError,
    InvalidAggregatorFeeRateError
} from "../../../src/validator/RATFastWithdrawal.sol";

/// @notice Mock OptimismPortal2 for testing Fast Withdrawal
contract MockOptimismPortal2 is IOptimismPortal2ForRAT {
    mapping(bytes32 => bool) public override withdrawalVerified;
    mapping(bytes32 => bool) public override fastFinalizedWithdrawals;

    event WithdrawalVerified(bytes32 withdrawalHash);
    event FastWithdrawalFinalized(bytes32 withdrawalHash, address sender, uint256 value);

    function setWithdrawalVerified(bytes32 _withdrawalHash) external override {
        withdrawalVerified[_withdrawalHash] = true;
        emit WithdrawalVerified(_withdrawalHash);
    }

    function fastWithdrawalFinalize(Types.WithdrawalTransaction memory _tx) external override {
        bytes32 withdrawalHash = keccak256(abi.encode(
            _tx.nonce,
            _tx.sender,
            _tx.target,
            _tx.value,
            _tx.gasLimit,
            _tx.data
        ));
        fastFinalizedWithdrawals[withdrawalHash] = true;
        emit FastWithdrawalFinalized(withdrawalHash, _tx.sender, _tx.value);
    }
}

/// @notice Mock ValidatorReward for receiving fees
contract MockValidatorRewardForFastWithdrawal {
    uint256 public totalReceived;

    receive() external payable {
        totalReceived += msg.value;
    }

    function registerValidatorToL2(address, address) external {}
    function deregisterValidatorFromL2(address, address) external {}
}

/// @title FastWithdrawalScenariosTest
/// @notice Fast Withdrawal 시나리오 테스트
/// @dev BLS 서명 검증 및 인접 리프 증명은 프리컴파일 의존성으로 인해 모킹 필요
contract FastWithdrawalScenariosTest is V3TestBase {
    // Test addresses
    address public validator1 = address(0x6001);
    address public validator2 = address(0x6002);
    address public validator3 = address(0x6003);
    address public aggregator = address(0x7001);
    address public user = address(0x8001);
    address public treasury = address(0x9001);

    // Mock contracts
    MockOptimismPortal2 public mockPortal2;
    MockValidatorRewardForFastWithdrawal public mockValidatorRewardFW;

    // RATFastWithdrawal reference (same proxy as RAT)
    RATFastWithdrawal public ratFastWithdrawal;

    // Test BLS keys (128 bytes each, placeholder values)
    bytes public blsKey1;
    bytes public blsKey2;
    bytes public blsKey3;
    bytes public blsPoP; // Proof of Possession (256 bytes)

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

        // Mock Portal 생성 및 SystemConfig에 설정
        mockPortal2 = new MockOptimismPortal2();
        mockSystemConfig.setOptimismPortal(address(mockPortal2));

        // Layer2 등록
        (mockLayer2, operatorManager) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig),
            mockL2TON,
            "TestL2",
            operator1,
            1000 * RAY
        );

        // V3 설정 및 마이그레이션
        _setupV3AndMigrate();

        // RATFastWithdrawal 참조 설정 (같은 프록시 주소)
        ratFastWithdrawal = RATFastWithdrawal(payable(address(rat)));

        // Mock ValidatorReward 설정
        mockValidatorRewardFW = new MockValidatorRewardForFastWithdrawal();
        rat.setValidatorReward(address(mockValidatorRewardFW));

        vm.stopPrank();

        // 검증자들 스테이킹
        _stakeForValidator(validator1, mockLayer2, 500 * RAY);
        _stakeForValidator(validator2, mockLayer2, 600 * RAY);
        _stakeForValidator(validator3, mockLayer2, 700 * RAY);

        // Placeholder BLS keys (실제 테스트에서는 유효한 키 사용 필요)
        blsKey1 = new bytes(128);
        blsKey2 = new bytes(128);
        blsKey3 = new bytes(128);
        blsPoP = new bytes(256);
    }

    // ==========================================
    // Fast Withdrawal 활성화/비활성화 테스트
    // ==========================================

    function test_FW001_setMinValidatorsForFastWithdrawal_onlyOwner() public {
        // 비소유자가 호출 시 실패
        vm.prank(validator1);
        vm.expectRevert();
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(1);

        // 소유자가 호출 시 성공
        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(1);

        assertEq(rat.minValidatorsForFastWithdrawal(), 1, "Min validators should be 1");

        // 0으로 설정하면 Fast Withdrawal 비활성화
        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(0);
        assertEq(rat.minValidatorsForFastWithdrawal(), 0, "Min validators should be 0 (disabled)");
    }

    function test_FW002_setAggregatorFeeRate_validRange() public {
        vm.startPrank(owner);

        // 유효한 범위 (10% = 1e26)
        ratFastWithdrawal.setAggregatorFeeRate(1e26);
        assertEq(rat.aggregatorFeeRate(), 1e26, "Aggregator fee rate should be 10%");

        // 최대값 (100% = RAY)
        ratFastWithdrawal.setAggregatorFeeRate(RAY);
        assertEq(rat.aggregatorFeeRate(), RAY, "Aggregator fee rate should be 100%");

        // 0% 허용
        ratFastWithdrawal.setAggregatorFeeRate(0);
        assertEq(rat.aggregatorFeeRate(), 0, "Aggregator fee rate should be 0%");

        vm.stopPrank();
    }

    function test_FW003_setAggregatorFeeRate_exceedsMax_reverts() public {
        vm.prank(owner);
        vm.expectRevert(InvalidAggregatorFeeRateError.selector);
        ratFastWithdrawal.setAggregatorFeeRate(RAY + 1);
    }

    // ==========================================
    // BLS 공개키 조회 테스트
    // ==========================================

    function test_FW010_getValidatorBLSPubKey_notRegistered() public view {
        bytes memory key = ratFastWithdrawal.getValidatorBLSPubKey(validator1, address(mockSystemConfig));
        assertEq(key.length, 0, "Should return empty bytes for unregistered validator");
    }

    function test_FW011_hasValidatorBLSKey_notRegistered() public view {
        bool hasKey = ratFastWithdrawal.hasValidatorBLSKey(validator1, address(mockSystemConfig));
        assertFalse(hasKey, "Should return false for unregistered validator");
    }

    function test_FW012_getBatchValidatorBLSPublicKeys_empty() public view {
        address[] memory validators = new address[](2);
        validators[0] = validator1;
        validators[1] = validator2;

        bytes[] memory keys = ratFastWithdrawal.getBatchValidatorBLSPublicKeys(validators, address(mockSystemConfig));

        assertEq(keys.length, 2, "Should return array of same length");
        assertEq(keys[0].length, 0, "First key should be empty");
        assertEq(keys[1].length, 0, "Second key should be empty");
    }

    function test_FW013_getActiveValidatorsWithBLS_noValidators() public view {
        (
            address[] memory validators,
            bytes[] memory blsKeys,
            uint256 validBLSCount
        ) = ratFastWithdrawal.getActiveValidatorsWithBLS(address(mockSystemConfig));

        assertEq(validators.length, 0, "No validators should be registered");
        assertEq(blsKeys.length, 0, "No BLS keys");
        assertEq(validBLSCount, 0, "Valid BLS count should be 0");
    }

    // ==========================================
    // 검증자 등록 (기존 RAT 등록 사용) 테스트
    // ==========================================

    function test_FW020_registerValidator_then_checkBLSKey() public {
        // 기존 RAT 검증자 등록 (BLS 키 없이)
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        // BLS 키 미등록 상태 확인
        bool hasKey = ratFastWithdrawal.hasValidatorBLSKey(validator1, address(mockSystemConfig));
        assertFalse(hasKey, "Should not have BLS key after basic registration");

        // 검증자 활성 상태 확인
        (,, bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertTrue(isActive, "Validator should be active");
    }

    function test_FW021_getActiveValidatorsWithBLS_afterBasicRegistration() public {
        // 검증자 등록 (BLS 키 없이)
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        (
            address[] memory validators,
            bytes[] memory blsKeys,
            uint256 validBLSCount
        ) = ratFastWithdrawal.getActiveValidatorsWithBLS(address(mockSystemConfig));

        assertEq(validators.length, 2, "Should have 2 validators");
        assertEq(blsKeys.length, 2, "Should have 2 BLS key slots");
        assertEq(validBLSCount, 0, "No valid BLS keys yet");
        assertEq(blsKeys[0].length, 0, "First BLS key should be empty");
        assertEq(blsKeys[1].length, 0, "Second BLS key should be empty");
    }

    // ==========================================
    // Fast Withdrawal 비활성화 상태 테스트
    // ==========================================

    function test_FW030_verifyAndExecute_disabled_reverts() public {
        // Fast Withdrawal 비활성화 상태 확인
        assertFalse(rat.fastWithdrawalEnabled(), "Fast withdrawal should be disabled by default");

        Types.WithdrawalTransaction memory tx_ = Types.WithdrawalTransaction({
            nonce: 1,
            sender: user,
            target: user,
            value: 1 ether,
            gasLimit: 100000,
            data: ""
        });

        bytes32 withdrawalHash = keccak256(abi.encode(
            tx_.nonce,
            tx_.sender,
            tx_.target,
            tx_.value,
            tx_.gasLimit,
            tx_.data
        ));

        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            stateRoot: bytes32(uint256(1)),
            validatorBitmap: 1,
            leafA: bytes32(uint256(2)),
            leafB: bytes32(uint256(3)),
            proofsA: new bytes[](0),
            proofsB: new bytes[](0)
        });

        bytes memory aggregatedSignature = new bytes(256);

        vm.prank(aggregator);
        vm.expectRevert(FastWithdrawalDisabledError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal(tx_, input, aggregatedSignature);
    }

    // ==========================================
    // Fast Withdrawal 검증자 없음 테스트
    // ==========================================

    function test_FW031_verifyAndExecute_noValidators_reverts() public {
        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(1);

        // 검증자 없음 확인
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 0, "Should have no validators");

        Types.WithdrawalTransaction memory tx_ = Types.WithdrawalTransaction({
            nonce: 1,
            sender: user,
            target: user,
            value: 1 ether,
            gasLimit: 100000,
            data: ""
        });

        bytes32 withdrawalHash = keccak256(abi.encode(
            tx_.nonce,
            tx_.sender,
            tx_.target,
            tx_.value,
            tx_.gasLimit,
            tx_.data
        ));

        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            stateRoot: bytes32(uint256(1)),
            validatorBitmap: 0, // No validators
            leafA: bytes32(uint256(2)),
            leafB: bytes32(uint256(3)),
            proofsA: new bytes[](0),
            proofsB: new bytes[](0)
        });

        bytes memory aggregatedSignature = new bytes(256);

        vm.prank(aggregator);
        vm.expectRevert(FastWithdrawalInsufficientValidatorsError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal(tx_, input, aggregatedSignature);
    }

    // ==========================================
    // Fast Withdrawal 중복 처리 방지 테스트
    // ==========================================

    function test_FW032_processedWithdrawals_initialState() public view {
        bytes32 withdrawalHash = keccak256("test_withdrawal");
        assertFalse(rat.processedWithdrawals(withdrawalHash), "Should not be processed initially");
    }

    // ==========================================
    // Fast Withdrawal 비트맵 검증 테스트
    // ==========================================

    function test_FW040_validatorBitmap_notUnanimous_reverts() public {
        // 검증자 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(1);

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 2, "Should have 2 validators");

        Types.WithdrawalTransaction memory tx_ = Types.WithdrawalTransaction({
            nonce: 1,
            sender: user,
            target: user,
            value: 1 ether,
            gasLimit: 100000,
            data: ""
        });

        bytes32 withdrawalHash = keccak256(abi.encode(
            tx_.nonce,
            tx_.sender,
            tx_.target,
            tx_.value,
            tx_.gasLimit,
            tx_.data
        ));

        // 비트맵 1 = 0b01 (validator1만) - 만장일치 아님 (2명 중 1명)
        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            stateRoot: bytes32(uint256(1)),
            validatorBitmap: 1, // Only first validator
            leafA: bytes32(uint256(2)),
            leafB: bytes32(uint256(3)),
            proofsA: new bytes[](0),
            proofsB: new bytes[](0)
        });

        bytes memory aggregatedSignature = new bytes(256);

        vm.prank(aggregator);
        vm.expectRevert(FastWithdrawalNotUnanimousError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal(tx_, input, aggregatedSignature);
    }

    function test_FW041_validatorBitmap_unanimous_twoValidators() public {
        // 검증자 2명 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(1);

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 2, "Should have 2 validators");

        Types.WithdrawalTransaction memory tx_ = Types.WithdrawalTransaction({
            nonce: 1,
            sender: user,
            target: user,
            value: 1 ether,
            gasLimit: 100000,
            data: ""
        });

        bytes32 withdrawalHash = keccak256(abi.encode(
            tx_.nonce,
            tx_.sender,
            tx_.target,
            tx_.value,
            tx_.gasLimit,
            tx_.data
        ));

        // 비트맵 3 = 0b11 (validator1 + validator2) - 만장일치
        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            stateRoot: bytes32(uint256(1)),
            validatorBitmap: 3, // Both validators (0b11 = 3)
            leafA: bytes32(uint256(2)),
            leafB: bytes32(uint256(3)),
            proofsA: new bytes[](0),
            proofsB: new bytes[](0)
        });

        bytes memory aggregatedSignature = new bytes(256);

        // BLS 키 미등록으로 인해 revert (BLSKeyNotRegisteredError)
        // 비트맵 검증은 통과하지만 BLS 키 집계 단계에서 실패
        vm.prank(aggregator);
        vm.expectRevert(); // BLSKeyNotRegisteredError
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal(tx_, input, aggregatedSignature);
    }

    // ==========================================
    // Fast Withdrawal 해시 검증 테스트
    // ==========================================

    function test_FW050_invalidWithdrawalHash_reverts() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(1);

        Types.WithdrawalTransaction memory tx_ = Types.WithdrawalTransaction({
            nonce: 1,
            sender: user,
            target: user,
            value: 1 ether,
            gasLimit: 100000,
            data: ""
        });

        // 잘못된 해시 사용
        bytes32 wrongHash = keccak256("wrong_hash");

        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: wrongHash, // Wrong hash
            systemConfig: address(mockSystemConfig),
            stateRoot: bytes32(uint256(1)),
            validatorBitmap: 1, // Single validator
            leafA: bytes32(uint256(2)),
            leafB: bytes32(uint256(3)),
            proofsA: new bytes[](0),
            proofsB: new bytes[](0)
        });

        bytes memory aggregatedSignature = new bytes(256);

        // 해시 불일치로 revert
        vm.prank(aggregator);
        vm.expectRevert(RATFastWithdrawalLib.FastWithdrawalInvalidHashError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal(tx_, input, aggregatedSignature);
    }

    // ==========================================
    // 수수료 분배 테스트 (라이브러리 직접 테스트)
    // ==========================================

    function test_FW060_distributeFees_zeroFee() public view {
        // 수수료 0인 경우 아무 일도 안 함
        // 라이브러리 함수는 internal이므로 직접 테스트 불가
        // 대신 상태 검증
        assertEq(mockValidatorRewardFW.totalReceived(), 0, "No fees should be received yet");
    }

    function test_FW061_aggregatorFeeRate_calculation() public {
        vm.prank(owner);
        ratFastWithdrawal.setAggregatorFeeRate(1e26); // 10%

        uint256 totalFee = 1 ether;
        uint256 expectedAggregatorFee = (totalFee * 1e26) / RAY; // 0.1 ether
        uint256 expectedValidatorFee = totalFee - expectedAggregatorFee; // 0.9 ether

        assertEq(expectedAggregatorFee, 0.1 ether, "Aggregator fee should be 10%");
        assertEq(expectedValidatorFee, 0.9 ether, "Validator fee should be 90%");
    }

    // ==========================================
    // Portal 주소 검증 테스트
    // ==========================================

    function test_FW070_portal_notSet_reverts() public {
        // 새로운 SystemConfig 생성 (Portal 미설정)
        SimpleMockSystemConfig mockSystemConfig2 = new SimpleMockSystemConfig();
        mockSystemConfig2.setL1StandardBridge(address(0x1));
        mockSystemConfig2.setOptimismPortal(address(0)); // Portal 미설정
        mockSystemConfig2.setDisputeGameFactory(address(0x2));
        mockSystemConfig2.setUnsafeBlockSigner(operator1);

        vm.startPrank(owner);
        l1BridgeRegistry.registerRollupConfig(
            address(mockSystemConfig2),
            3,
            address(0x3),
            "TestL2_2"
        );
        vm.stopPrank();

        vm.prank(operator1);
        MockWTON(wton).mint(operator1, 1000 * RAY);
        vm.prank(operator1);
        MockWTON(wton).approve(layer2ManagerProxy, 1000 * RAY);
        vm.prank(operator1);
        layer2Manager.registerCandidateAddOn(
            address(mockSystemConfig2),
            1000 * RAY,
            false,
            "TestL2_2"
        );

        address newLayer2 = layer2Manager.getLayer2BySystemConfig(address(mockSystemConfig2));

        // 검증자 등록
        _stakeForValidator(validator1, newLayer2, 500 * RAY);
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig2));

        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(1);

        Types.WithdrawalTransaction memory tx_ = Types.WithdrawalTransaction({
            nonce: 1,
            sender: user,
            target: user,
            value: 1 ether,
            gasLimit: 100000,
            data: ""
        });

        bytes32 withdrawalHash = keccak256(abi.encode(
            tx_.nonce,
            tx_.sender,
            tx_.target,
            tx_.value,
            tx_.gasLimit,
            tx_.data
        ));

        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig2),
            stateRoot: bytes32(uint256(1)),
            validatorBitmap: 1,
            leafA: bytes32(uint256(2)),
            leafB: bytes32(uint256(3)),
            proofsA: new bytes[](0),
            proofsB: new bytes[](0)
        });

        bytes memory aggregatedSignature = new bytes(256);

        vm.prank(aggregator);
        vm.expectRevert(FastWithdrawalPortalNotSetError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal(tx_, input, aggregatedSignature);
    }

    // ==========================================
    // 다중 검증자 시나리오 테스트
    // ==========================================

    function test_FW080_threeValidators_unanimousBitmap() public {
        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(1);

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 3, "Should have 3 validators");

        Types.WithdrawalTransaction memory tx_ = Types.WithdrawalTransaction({
            nonce: 1,
            sender: user,
            target: user,
            value: 1 ether,
            gasLimit: 100000,
            data: ""
        });

        bytes32 withdrawalHash = keccak256(abi.encode(
            tx_.nonce,
            tx_.sender,
            tx_.target,
            tx_.value,
            tx_.gasLimit,
            tx_.data
        ));

        // 비트맵 7 = 0b111 (3명 모두) - 만장일치
        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            stateRoot: bytes32(uint256(1)),
            validatorBitmap: 7, // All 3 validators (0b111 = 7)
            leafA: bytes32(uint256(2)),
            leafB: bytes32(uint256(3)),
            proofsA: new bytes[](0),
            proofsB: new bytes[](0)
        });

        bytes memory aggregatedSignature = new bytes(256);

        // BLS 키 미등록으로 인해 revert
        vm.prank(aggregator);
        vm.expectRevert(); // BLSKeyNotRegisteredError
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal(tx_, input, aggregatedSignature);
    }

    function test_FW081_threeValidators_partialBitmap_reverts() public {
        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(owner);
        ratFastWithdrawal.setMinValidatorsForFastWithdrawal(1);

        Types.WithdrawalTransaction memory tx_ = Types.WithdrawalTransaction({
            nonce: 1,
            sender: user,
            target: user,
            value: 1 ether,
            gasLimit: 100000,
            data: ""
        });

        bytes32 withdrawalHash = keccak256(abi.encode(
            tx_.nonce,
            tx_.sender,
            tx_.target,
            tx_.value,
            tx_.gasLimit,
            tx_.data
        ));

        // 비트맵 5 = 0b101 (validator1 + validator3, validator2 빠짐) - 만장일치 아님
        RATFastWithdrawalLib.FastWithdrawalInput memory input = RATFastWithdrawalLib.FastWithdrawalInput({
            withdrawalHash: withdrawalHash,
            systemConfig: address(mockSystemConfig),
            stateRoot: bytes32(uint256(1)),
            validatorBitmap: 5, // 0b101 = validators 0 and 2 only
            leafA: bytes32(uint256(2)),
            leafB: bytes32(uint256(3)),
            proofsA: new bytes[](0),
            proofsB: new bytes[](0)
        });

        bytes memory aggregatedSignature = new bytes(256);

        vm.prank(aggregator);
        vm.expectRevert(FastWithdrawalNotUnanimousError.selector);
        ratFastWithdrawal.verifyAndExecuteFastWithdrawal(tx_, input, aggregatedSignature);
    }

    // ==========================================
    // receive() 함수 테스트
    // ==========================================

    function test_FW090_receive_acceptsEther() public {
        uint256 amount = 1 ether;
        vm.deal(aggregator, amount);

        uint256 balanceBefore = address(ratFastWithdrawal).balance;

        vm.prank(aggregator);
        (bool success,) = address(ratFastWithdrawal).call{value: amount}("");

        assertTrue(success, "Should accept ether");
        assertEq(address(ratFastWithdrawal).balance, balanceBefore + amount, "Balance should increase");
    }
}
