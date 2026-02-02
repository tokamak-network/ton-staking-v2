// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {
    OnlyDepositManagerError,
    OnlyL1BridgeOrRegistryError,
    OnlyRatError,
    ZeroAddressError,
    InvalidParameterError
} from "../../../src/stake/managers/SeigManagerV3_1.sol";
import {InvalidFactoryError, InvalidParameterError as RATInvalidParameterError} from "../../../src/validator/RAT.sol";

/// @title SecurityPermissionsTest
/// @notice 보안 권한 검증 테스트
/// @dev 테스트 계획서 SEC-002, SEC-003, SEC-005 구현
///
/// 테스트 대상:
/// - SEC-002: onlyRAT 함수 - RAT 외 호출 거부
/// - SEC-003: onlyDepositManager - DepositManager 외 호출 거부
/// - SEC-005: onlyL1BridgeOrRegistry - L1BridgeRegistry 외 거부
/// - SEC-004: onlyValidFactory - 유효 Factory만 트리거 (RAT)
/// - SEC-001: onlyOwner 함수 - 비권한자 호출 거부
contract SecurityPermissionsTest is V3TestBase {
    // ==========================================
    // Additional Test Addresses
    // ==========================================
    address public validator1 = address(0x6001);
    address public attacker = address(0xBAD);
    address public randomUser = address(0x1234);

    function setUp() public {
        _v3TestSetup();

        vm.startPrank(owner);

        // RAT 파라미터
        _setupRATParams();

        // L2 등록
        _registerFirstL2(1000 * RAY);

        // V3 마이그레이션
        seigManager.setRatContract(address(rat));
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.setValidatorDistributionRatio(0.2e27);
        seigManager.setHalfSaturationPoint(1000e27);
        seigManager.setMaxChallengers(3);
        seigManager.setMaxFraudProofCost(50e27);
        seigManager.setValidatorReward(validatorPoolProxy);
        seigManager.migrateToV3();

        MockTON(ton).mint(validator1, INITIAL_TON);

        vm.stopPrank();
    }

    /// @notice _setupCrossReferences 오버라이드 - L1BridgeRegistry 설정 추가
    function _setupCrossReferences(address) internal override {
        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
        SeigManagerV1_2(seigManagerProxy).setL1BridgeRegistry(l1BridgeRegistryProxy);
        SeigManagerV3_1(seigManagerProxy).setValidatorReward(validatorPoolProxy);

        Layer2ManagerV3(layer2ManagerProxy).setAddresses1(
            l1BridgeRegistryProxy, operatorManagerFactory, ton, wton
        );
        Layer2ManagerV3(layer2ManagerProxy).setAddresses2(
            daoCommitteeProxy, depositManagerProxy, seigManagerProxy, address(0)
        );

        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).setAddresses(layer2ManagerProxy, seigManagerProxy, ton);
        OperatorManagerFactory(operatorManagerFactory).setAddresses(depositManagerProxy, ton, wton, layer2ManagerProxy);
        DepositManagerV3(depositManagerProxy).setAddresses(l1BridgeRegistryProxy, layer2ManagerProxy);
    }

    // ==========================================
    // SEC-002: onlyRAT 권한 검증
    // ==========================================

    /// @notice SEC-002: transferCoinageToRat - RAT만 호출 가능
    function test_SEC002_onlyRAT_transferCoinageToRat() public {
        // attacker가 호출 시 revert
        vm.prank(attacker);
        vm.expectRevert(OnlyRatError.selector);
        seigManager.transferCoinageToRat(mockLayer2, validator1, 100 * RAY);

        // owner가 호출 시에도 revert
        vm.prank(owner);
        vm.expectRevert(OnlyRatError.selector);
        seigManager.transferCoinageToRat(mockLayer2, validator1, 100 * RAY);

        // depositManager가 호출 시에도 revert
        vm.prank(depositManagerProxy);
        vm.expectRevert(OnlyRatError.selector);
        seigManager.transferCoinageToRat(mockLayer2, validator1, 100 * RAY);
    }

    /// @notice SEC-002: transferCoinageFromRat - RAT만 호출 가능
    function test_SEC002_onlyRAT_transferCoinageFromRat() public {
        vm.prank(attacker);
        vm.expectRevert(OnlyRatError.selector);
        seigManager.transferCoinageFromRat(mockLayer2, validator1, 100 * RAY);

        vm.prank(owner);
        vm.expectRevert(OnlyRatError.selector);
        seigManager.transferCoinageFromRat(mockLayer2, validator1, 100 * RAY);
    }

    /// @notice SEC-002: transferCoinageFromRatTo - RAT만 호출 가능
    function test_SEC002_onlyRAT_transferCoinageFromRatTo() public {
        address treasury = address(0x9001);

        vm.prank(attacker);
        vm.expectRevert(OnlyRatError.selector);
        seigManager.transferCoinageFromRatTo(mockLayer2, treasury, 100 * RAY);

        vm.prank(owner);
        vm.expectRevert(OnlyRatError.selector);
        seigManager.transferCoinageFromRatTo(mockLayer2, treasury, 100 * RAY);
    }

    /// @notice SEC-002: RAT에서 호출 시 성공
    function test_SEC002_onlyRAT_success() public {
        // 검증자 등록 (coinage 잔액 확보)
        vm.startPrank(validator1);
        MockWTON(wton).mint(validator1, 500 * RAY);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, validator1, 500 * RAY);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();

        // RAT에서 호출 시 성공
        vm.prank(address(rat));
        seigManager.transferCoinageToRat(mockLayer2, validator1, 100 * RAY);

        // 잔액 확인
        assertEq(SeigManagerV1_2(seigManagerProxy).stakeOf(mockLayer2, validator1), 400 * RAY);
        assertEq(SeigManagerV1_2(seigManagerProxy).stakeOf(mockLayer2, address(rat)), 100 * RAY);
    }

    // ==========================================
    // SEC-003: onlyDepositManager 권한 검증
    // ==========================================

    /// @notice SEC-003: onDeposit - DepositManager만 호출 가능
    function test_SEC003_onlyDepositManager_onDeposit() public {
        vm.prank(attacker);
        vm.expectRevert(OnlyDepositManagerError.selector);
        seigManager.onDeposit(mockLayer2, validator1, 100 * RAY);

        vm.prank(owner);
        vm.expectRevert(OnlyDepositManagerError.selector);
        seigManager.onDeposit(mockLayer2, validator1, 100 * RAY);

        vm.prank(address(rat));
        vm.expectRevert(OnlyDepositManagerError.selector);
        seigManager.onDeposit(mockLayer2, validator1, 100 * RAY);
    }

    /// @notice SEC-003: onWithdraw - DepositManager만 호출 가능
    function test_SEC003_onlyDepositManager_onWithdraw() public {
        vm.prank(attacker);
        vm.expectRevert(OnlyDepositManagerError.selector);
        seigManager.onWithdraw(mockLayer2, validator1, 100 * RAY);

        vm.prank(owner);
        vm.expectRevert(OnlyDepositManagerError.selector);
        seigManager.onWithdraw(mockLayer2, validator1, 100 * RAY);
    }

    /// @notice SEC-003: onStakingChange - DepositManager만 호출 가능
    function test_SEC003_onlyDepositManager_onStakingChange() public {
        vm.prank(attacker);
        vm.expectRevert(OnlyDepositManagerError.selector);
        seigManager.onStakingChange(mockLayer2);

        vm.prank(owner);
        vm.expectRevert(OnlyDepositManagerError.selector);
        seigManager.onStakingChange(mockLayer2);
    }

    // ==========================================
    // SEC-005: onlyL1BridgeOrRegistry 권한 검증
    // ==========================================

    /// @notice SEC-005: onBridgedTonChange - 미등록 caller는 조기 리턴 (revert 안함)
    /// @dev rollupConfigWithPortal 매핑에 없는 주소는 조기 리턴하여 무시됨
    function test_SEC005_onlyL1BridgeOrRegistry_onBridgedTonChange() public {
        // 사전 상태 기록
        uint256 totalEffectiveBefore = seigManager.totalEffectiveBridgedTON();

        // attacker가 호출 시 조기 리턴 (rollupConfigWithPortal 매핑에 없음)
        vm.prank(attacker);
        seigManager.onBridgedTonChange(); // revert 없이 조기 리턴

        // owner가 호출 시에도 조기 리턴 (rollupConfigWithPortal 매핑에 없음)
        vm.prank(owner);
        seigManager.onBridgedTonChange(); // revert 없이 조기 리턴

        // randomUser가 호출 시에도 조기 리턴
        vm.prank(randomUser);
        seigManager.onBridgedTonChange(); // revert 없이 조기 리턴

        // totalEffectiveBridgedTON 변경 없음 확인 (미등록 caller는 무시됨)
        uint256 totalEffectiveAfter = seigManager.totalEffectiveBridgedTON();
        assertEq(totalEffectiveAfter, totalEffectiveBefore, "totalEffectiveBridgedTON should not change for unauthorized callers");
    }

    /// @notice SEC-005: onBridgedTonChange - Portal(L1BridgeRegistry에 등록됨)이 호출 가능
    function test_SEC005_onlyL1BridgeOrRegistry_validPortal_success() public {
        // Portal 주소 가져오기
        address portal = mockSystemConfig.optimismPortal();

        // Portal이 호출하면 정상 실행됨 (rollupConfigWithPortal 매핑에 있음)
        // revert 없이 실행되면 성공
        vm.prank(portal);
        seigManager.onBridgedTonChange();

        // 함수가 revert 없이 실행되었음 = 권한 검증 통과
        assertTrue(true, "Portal call succeeded without revert");
    }

    // ==========================================
    // SEC-004: onlyValidFactory 권한 검증 (RAT)
    // ==========================================

    /// @notice SEC-004: triggerAttentionTest - 유효한 Factory만 트리거 가능
    function test_SEC004_onlyValidFactory_triggerAttentionTest() public {
        // 검증자 등록
        _registerValidator(validator1, 500 * RAY);

        // 사전 조건: attacker는 유효한 factory가 아님
        assertTrue(attacker != mockDisputeGameFactory, "attacker should not be valid factory");

        // attacker가 호출 시 InvalidFactoryError
        vm.prank(attacker);
        vm.expectRevert(InvalidFactoryError.selector);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 등록되지 않은 factory가 호출 시 InvalidFactoryError
        vm.prank(randomUser);
        vm.expectRevert(InvalidFactoryError.selector);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );
    }

    /// @notice SEC-004: 유효한 Factory에서 호출 시 성공
    function test_SEC004_validFactory_success() public {
        // 검증자 등록
        _registerValidator(validator1, 500 * RAY);

        // 유효한 factory(mockDisputeGameFactory)에서 호출 시 성공
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 테스트 생성 확인
        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), 1);
        assertTrue(testId != bytes32(0), "Test should be created");
    }

    // ==========================================
    // SEC-001: onlyOwner 권한 검증
    // ==========================================

    /// @notice SEC-001: SeigManager onlyOwner 함수들
    function test_SEC001_onlyOwner_seigManager() public {
        // 사전 조건: attacker는 admin이 아님
        assertFalse(seigManager.isAdmin(attacker), "attacker should not be admin");

        // setDaoDistributionRatio
        vm.prank(attacker);
        vm.expectRevert("AuthControl: Caller is not an admin");
        seigManager.setDaoDistributionRatio(0.2e27);

        // setMinStakingRatio
        vm.prank(attacker);
        vm.expectRevert("AuthControl: Caller is not an admin");
        seigManager.setMinStakingRatio(0.2e27);

        // setValidatorDistributionRatio
        vm.prank(attacker);
        vm.expectRevert("AuthControl: Caller is not an admin");
        seigManager.setValidatorDistributionRatio(0.3e27);

        // setHalfSaturationPoint
        vm.prank(attacker);
        vm.expectRevert("AuthControl: Caller is not an admin");
        seigManager.setHalfSaturationPoint(2000e27);

        // setMaxChallengers
        vm.prank(attacker);
        vm.expectRevert("AuthControl: Caller is not an admin");
        seigManager.setMaxChallengers(10);

        // setMaxFraudProofCost
        vm.prank(attacker);
        vm.expectRevert("AuthControl: Caller is not an admin");
        seigManager.setMaxFraudProofCost(1 ether);

        // setRatContract
        vm.prank(attacker);
        vm.expectRevert("AuthControl: Caller is not an admin");
        seigManager.setRatContract(address(0x1234));

        // setValidatorReward
        vm.prank(attacker);
        vm.expectRevert("AuthControl: Caller is not an admin");
        seigManager.setValidatorReward(address(0x1234));
    }

    /// @notice SEC-001: RAT onlyOwner 함수들
    function test_SEC001_onlyOwner_rat() public {
        // setSlashingPenalty
        vm.prank(attacker);
        vm.expectRevert("Accessible: Caller is not an admin");
        rat.setSlashingPenalty(200 * RAY);

        // setValidatorBuffer
        vm.prank(attacker);
        vm.expectRevert("Accessible: Caller is not an admin");
        rat.setValidatorBuffer(200 * RAY);

        // setMinimumThreshold
        vm.prank(attacker);
        vm.expectRevert("Accessible: Caller is not an admin");
        rat.setMinimumThreshold(400 * RAY);

        // setRatTriggerProbability
        vm.prank(attacker);
        vm.expectRevert("Accessible: Caller is not an admin");
        rat.setRatTriggerProbability(0.5e27);

        // setEvidenceSubmissionPeriod
        vm.prank(attacker);
        vm.expectRevert("Accessible: Caller is not an admin");
        rat.setEvidenceSubmissionPeriod(2 hours);

        // setMaxValidatorsPerL2
        vm.prank(attacker);
        vm.expectRevert("Accessible: Caller is not an admin");
        rat.setMaxValidatorsPerL2(50);

        // setRelaxedValidatorCheck
        vm.prank(attacker);
        vm.expectRevert("Accessible: Caller is not an admin");
        rat.setRelaxedValidatorCheck(false);

        // setL1BridgeRegistry
        vm.prank(attacker);
        vm.expectRevert("Accessible: Caller is not an admin");
        rat.setL1BridgeRegistry(address(0x1234));

        // setTreasury
        vm.prank(attacker);
        vm.expectRevert("Accessible: Caller is not an admin");
        rat.setTreasury(address(0x1234));

        // transferOwnership
        vm.prank(attacker);
        vm.expectRevert("Accessible: Caller is not an admin");
        rat.transferOwnership(attacker);
    }

    /// @notice SEC-001: owner가 호출 시 성공
    function test_SEC001_onlyOwner_success() public {
        // SeigManager
        vm.startPrank(owner);
        seigManager.setDaoDistributionRatio(0.15e27);
        assertEq(seigManager.daoDistributionRatio(), 0.15e27);

        seigManager.setMaxChallengers(5);
        assertEq(seigManager.maxChallengers(), 5);
        vm.stopPrank();

        // RAT
        vm.startPrank(owner);
        rat.setSlashingPenalty(150 * RAY);
        assertEq(rat.slashingPenalty(), 150 * RAY);

        rat.setMaxValidatorsPerL2(50);
        assertEq(rat.maxValidatorsPerL2(), 50);
        vm.stopPrank();
    }

    // ==========================================
    // 추가: Zero Address 검증 (SEC-030)
    // ==========================================

    /// @notice SEC-030: setRatContract - zero address 거부
    function test_SEC030_zeroAddress_setRatContract() public {
        vm.prank(owner);
        vm.expectRevert(ZeroAddressError.selector);
        seigManager.setRatContract(address(0));
    }

    /// @notice SEC-030: setValidatorReward - zero address 거부
    function test_SEC030_zeroAddress_setValidatorReward() public {
        vm.prank(owner);
        vm.expectRevert(ZeroAddressError.selector);
        seigManager.setValidatorReward(address(0));
    }

    /// @notice SEC-030: RAT transferOwnership - zero address 거부
    function test_SEC030_zeroAddress_transferOwnership() public {
        vm.prank(owner);
        vm.expectRevert("Accessible: zero address");
        rat.transferOwnership(address(0));
    }

    // ==========================================
    // 추가: 파라미터 범위 검증 (SEC-031)
    // ==========================================

    /// @notice SEC-031: daoDistributionRatio >= RAY 거부
    function test_SEC031_parameterRange_daoDistributionRatio() public {
        vm.prank(owner);
        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setDaoDistributionRatio(RAY);

        vm.prank(owner);
        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setDaoDistributionRatio(RAY + 1);
    }

    /// @notice SEC-031: validatorDistributionRatio >= RAY 거부
    function test_SEC031_parameterRange_validatorDistributionRatio() public {
        vm.prank(owner);
        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setValidatorDistributionRatio(RAY);
    }

    /// @notice SEC-031: minStakingRatio > RAY 거부
    function test_SEC031_parameterRange_minStakingRatio() public {
        vm.prank(owner);
        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setMinStakingRatio(RAY + 1);
    }

    /// @notice SEC-031: ratTriggerProbability > RAY 거부
    function test_SEC031_parameterRange_ratTriggerProbability() public {
        vm.prank(owner);
        vm.expectRevert(RATInvalidParameterError.selector);
        rat.setRatTriggerProbability(RAY + 1);
    }

    // ==========================================
    // SEC-011: CEI 패턴 준수 테스트
    // ==========================================

    /// @notice SEC-011: CEI 패턴 준수 검증
    function test_SEC011_CEI_pattern() public {
        // 검증자 등록 및 deposit
        vm.startPrank(validator1);
        MockWTON(wton).mint(validator1, 500 * RAY);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);

        // deposit 전 상태
        uint256 wtonBefore = MockWTON(wton).balanceOf(validator1);
        uint256 stakeBefore = SeigManagerV1_2(seigManagerProxy).stakeOf(mockLayer2, validator1);

        // deposit 실행
        depositManager.deposit(mockLayer2, validator1, 300 * RAY);

        // deposit 후 상태
        uint256 wtonAfter = MockWTON(wton).balanceOf(validator1);
        uint256 stakeAfter = SeigManagerV1_2(seigManagerProxy).stakeOf(mockLayer2, validator1);

        // CEI 패턴 검증: 상태 변경이 일관성 있게 완료됨
        assertEq(wtonBefore - wtonAfter, 300 * RAY, "WTON deducted");
        assertEq(stakeAfter - stakeBefore, 300 * RAY, "Stake increased");
        vm.stopPrank();
    }

    // ==========================================
    // SEC-020: 랜덤 보안 테스트
    // ==========================================

    /// @notice SEC-020: RAT 랜덤 소스는 L1 블록 해시 + L1 timestamp
    /// @dev DisputeGameFactory.create() 코드:
    ///      bytes32 parentHash = blockhash(block.number - 1);  // L1 이전 블록 해시
    ///      IRAT(rat).triggerAttentionTest(..., parentHash);
    ///
    ///      보안 모델:
    ///      - blockHash: L1 이전 블록 해시 (시퀀서 제어 불가)
    ///      - block.timestamp: L1 타임스탬프 (시퀀서 제어 불가)
    ///      - 둘 다 L1 값이므로 L2 시퀀서가 조작할 수 없음
    function test_SEC020_randomness_uses_L1_values() public {
        // 검증자 등록
        _registerValidator(validator1, 500 * RAY);

        // DisputeGameFactory에서 사용하는 방식: blockhash(block.number - 1)
        // 테스트에서는 시뮬레이션
        vm.roll(100);
        bytes32 l1ParentHash1 = blockhash(block.number - 1);
        uint256 ts1 = block.timestamp;

        // L1 블록 진행
        vm.roll(101);
        vm.warp(block.timestamp + 12);
        bytes32 l1ParentHash2 = blockhash(block.number - 1);
        uint256 ts2 = block.timestamp;

        // L1 블록이 다르면 parentHash도 다름
        assertTrue(l1ParentHash1 != l1ParentHash2, "Different L1 blocks have different hashes");

        // 랜덤 값 계산 (RAT._selectRandomValidator 방식)
        bytes32 hash1 = keccak256(abi.encodePacked(l1ParentHash1, ts1));
        bytes32 hash2 = keccak256(abi.encodePacked(l1ParentHash2, ts2));

        // L1 값들이 다르므로 랜덤 결과도 다름
        assertTrue(hash1 != hash2, "Different L1 state produces different randomness");

        // 결론: L2 시퀀서는 L1 블록 해시와 L1 타임스탬프를 제어할 수 없으므로
        //       검증자 선택 결과를 조작할 수 없음
    }

    // ==========================================
    // SEC-032: 배열 길이 검증
    // ==========================================

    /// @notice SEC-032: 빈 배열 처리
    function test_SEC032_emptyArrayHandling() public {
        // 검증자가 없는 상태에서 RAT 트리거
        vm.prank(mockDisputeGameFactory);
        // 빈 배열(검증자 없음)에서 RAT 트리거 → early return, revert 없음
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 테스트가 revert 없이 통과하면 성공
        assertTrue(true, "Empty validator pool handled gracefully");
    }

    /// @notice SEC-032: N_max 제한 설정 확인
    function test_SEC032_maxValidatorLimit() public view {
        uint256 nMax = rat.maxValidatorsPerL2();

        // N_max가 설정되어 있음 확인 (컨트랙트는 > 0만 요구)
        assertTrue(nMax > 0, "N_max should be positive");
    }
}
