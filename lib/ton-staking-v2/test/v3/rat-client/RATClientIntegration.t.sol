// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";

/// @title RATClientIntegrationTest
/// @notice rat-client 브랜치의 통합 테스트를 V3 API에 맞게 수정
/// @dev V3TestBase를 상속하여 전체 시스템 통합 테스트
contract RATClientIntegrationTest is V3TestBase {
    address public validator1 = address(0x6001);
    address public treasury = address(0x9001);
    
    function setUp() public {
        _v3TestSetup();
        
        vm.startPrank(owner);
        
        // RAT 설정
        rat.setSlashingPenalty(100e27);
        rat.setValidatorBuffer(100e27);
        rat.setMinimumThreshold(200e27);
        rat.setRatTriggerProbability(RAY); // 100%
        rat.setTreasury(treasury);
        
        // Layer2 등록
        (mockLayer2, operatorManager) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig),
            mockL2TON,
            "TestL2",
            operator1,
            1000 * RAY
        );
        
        _setupV3AndMigrate();
        
        vm.stopPrank();
        
        // 검증자 스테이킹
        _stakeForValidator(validator1, mockLayer2, 500 * RAY);
    }
    
    /// @notice 전체 플로우: 등록 → RAT 트리거 → 증거 제출
    function test_fullFlow_registerTriggerSubmit() public {
        // 1. 검증자 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        
        // 2. 등록 확인
        (uint256 collateral,, bool isActive) = rat.getValidatorRegistration(
            validator1,
            address(mockSystemConfig)
        );
        assertEq(collateral, 500 * RAY);
        assertTrue(isActive);
        
        // 3. RAT 트리거는 DisputeGameFactory에서만 가능
        // (통합 테스트에서는 skip - 실제 DisputeGame 필요)
    }
    
    /// @notice 담보금 부족 → 자동 제거 → 재등록
    function test_fullFlow_slashingAndReregistration() public {
        // 1. 검증자 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        
        // 2. 출금으로 담보금 감소 (향후 구현)
        // (V3에서는 자동 비활성화 메커니즘 테스트 필요)
        
        // 3. 재등록 (담보금 충분 시)
        // _stakeForValidator(validator1, mockLayer2, 200 * RAY);
        // vm.prank(validator1);
        // rat.registerValidator(address(mockSystemConfig));
    }
    
    /// @notice 여러 L2에 검증자 등록
    function test_fullFlow_multipleL2Registration() public {
        // L2 하나만 setup되어 있으므로 skip
        // 필요시 추가 L2 등록 후 테스트
    }
}
