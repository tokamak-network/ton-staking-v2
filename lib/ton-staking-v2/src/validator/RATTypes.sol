// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice RAT 초기화 파라미터 (핵심 주소만 포함)
struct RATInitParams {
    address seigManager;
    address wton;
    address ton;
    address layer2Manager;
    address l1BridgeRegistry;
    address owner;
}

/// @notice RAT 설정 파라미터 (수치 설정)
struct RATConfigParams {
    uint256 ratTriggerProbability;
    uint256 evidenceSubmissionPeriod;
    uint256 slashingPenalty;
    uint256 validatorBuffer;
    uint256 minimumThreshold;
    uint256 maxValidatorsPerL2;
    uint256 challengeGameDuration;
    uint256 safetyBuffer;
    address treasury;
    uint256 attentionCost;
    bool relaxedValidatorCheck;
}
