// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {BLS12381} from "../libraries/BLS12381.sol";
import {AdjacentLeavesVerifier} from "../libraries/AdjacentLeavesVerifier.sol";

/**
 * @title RATFastWithdrawalLib
 * @notice RAT Fast Withdrawal 로직을 처리하는 라이브러리
 * @dev 상태 변수는 RAT에 저장, 로직만 라이브러리로 분리하여 코드 크기 감소
 */
library RATFastWithdrawalLib {
    // ==========================================
    // Constants
    // ==========================================

    uint256 internal constant RAY = 1e27;

    // ==========================================
    // Structs
    // ==========================================

    struct FastWithdrawalInput {
        bytes32 withdrawalHash;
        address systemConfig;
        address gameAddress;
        bytes32 stateRoot;
        uint256 validatorBitmap;
        bytes32 leafA;
        bytes32 leafB;
        bytes[] proofsA;
        bytes[] proofsB;
    }

    // Note: RAT 컨트랙트의 ValidatorRegistration 구조체 참조
    // Storage 구조체는 컨트랙트에서 정의, 라이브러리는 참조만

    // ==========================================
    // Errors
    // ==========================================

    error FastWithdrawalInvalidHashError();
    error FastWithdrawalNotUnanimousError();
    error FastWithdrawalInvalidBLSSignatureError();
    error FastWithdrawalInvalidAdjacentLeavesError();
    error FastWithdrawalInvalidValidatorBitmapError();
    error BLSKeyNotRegisteredError();
    error AggregatorFeeTransferFailedError();
    error ValidatorFeeTransferFailedError();
    error InvalidAggregatorFeeRateError();

    // ==========================================
    // Verification Functions
    // ==========================================

    /// @notice 출금 해시 검증
    function validateWithdrawalHash(
        uint256 nonce,
        address sender,
        address target,
        uint256 value,
        uint256 gasLimit,
        bytes calldata data,
        bytes32 expectedHash
    ) internal pure {
        bytes32 computedHash = keccak256(abi.encode(
            nonce,
            sender,
            target,
            value,
            gasLimit,
            data
        ));

        if (computedHash != expectedHash) revert FastWithdrawalInvalidHashError();
    }

    /// @notice BLS 서명 메시지 생성
    function constructBLSMessage(
        FastWithdrawalInput calldata input
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

    /// @notice BLS 집계 서명 검증
    /// @dev aggregatePublicKeys에서 이미 비트맵 검증을 완료했으므로 중복 체크 불필요
    function verifyBLSSignature(
        FastWithdrawalInput calldata input,
        bytes calldata aggregatedSignature,
        bytes memory aggregatedPubKey
    ) internal view {
        // 메시지 해시 계산
        bytes32 message = constructBLSMessage(input);

        // BLS 서명 검증
        if (!BLS12381.verifyAggregatedSignature(aggregatedPubKey, message, aggregatedSignature)) {
            revert FastWithdrawalInvalidBLSSignatureError();
        }
    }

    /// @notice 인접 리프 증명 검증
    function verifyAdjacentLeaves(
        FastWithdrawalInput calldata input
    ) internal pure {
        if (!AdjacentLeavesVerifier.verify(
            input.stateRoot,
            input.leafA,
            input.leafB,
            input.proofsA,
            input.proofsB
        )) {
            revert FastWithdrawalInvalidAdjacentLeavesError();
        }
    }

    // ==========================================
    // Helper Functions
    // ==========================================

    /// @notice 검증자 BLS 공개키 집계 (메모리 버전)
    /// @dev Storage 매핑을 직접 참조할 수 없으므로 RAT에서 미리 조회한 데이터 사용
    function aggregatePublicKeys(
        bytes[] memory publicKeys,
        uint256 validatorBitmap,
        uint256 validatorCount
    ) internal view returns (bytes memory aggregatedPubKey) {
        // Fail-fast: 비트맵이 0이면 즉시 실패
        if (validatorBitmap == 0) {
            revert FastWithdrawalInvalidValidatorBitmapError();
        }
        
        // 검증자 수 체크 (1~255)
        if (validatorCount == 0 || validatorCount > 255) {
            revert FastWithdrawalInvalidValidatorBitmapError();
        }
        
        // publicKeys 배열 길이 검증
        if (publicKeys.length != validatorCount) {
            revert FastWithdrawalInvalidValidatorBitmapError();
        }
        
        // 비트맵이 validatorCount 범위를 초과하는지 체크
        if (validatorBitmap >= (1 << validatorCount)) {
            revert FastWithdrawalInvalidValidatorBitmapError();
        }

        bytes memory result;
        uint256 bitmap = validatorBitmap;
        
        unchecked {
            // 첫 번째 키 찾기 (초기화)
            uint256 i;
            while ((bitmap & 1) == 0) {
                bitmap >>= 1;
                ++i;
            }
            
            result = publicKeys[i];
            if (result.length != 128) revert BLSKeyNotRegisteredError();
            
            bitmap >>= 1;
            ++i;
            
            // 나머지 키 집계
            while (bitmap != 0 && i < validatorCount) {
                if ((bitmap & 1) == 1) {
                    bytes memory pubKey = publicKeys[i];
                    if (pubKey.length != 128) revert BLSKeyNotRegisteredError();
                    result = BLS12381.aggregatePublicKeys(result, pubKey);
                }
                bitmap >>= 1;
                ++i;
            }
        }

        return result;
    }

    /// @notice Fast Withdrawal 수수료 분배
    /// @dev RAT 컨트랙트에서 msg.value를 파라미터로 전달받아야 함
    function distributeFees(
        uint256 totalFee,
        address aggregator,
        address validatorReward,
        uint256 aggregatorFeeRate
    ) internal {
        if (totalFee == 0) return;

        // aggregatorFeeRate 범위 검증 (0 ~ RAY)
        if (aggregatorFeeRate > RAY) revert InvalidAggregatorFeeRateError();

        // 집계자 수수료 계산
        uint256 aggregatorFee = (totalFee * aggregatorFeeRate) / RAY;
        uint256 validatorFees;
        
        unchecked {
            validatorFees = totalFee - aggregatorFee;
        }

        // 집계자 수수료 전송
        if (aggregatorFee > 0 && aggregator != address(0)) {
            (bool success, ) = payable(aggregator).call{value: aggregatorFee}("");
            if (!success) revert AggregatorFeeTransferFailedError();
        }

        // 검증자 수수료 전송 (남은 전부)
        if (validatorFees > 0 && validatorReward != address(0)) {
            (bool success, ) = payable(validatorReward).call{value: validatorFees}("");
            if (!success) revert ValidatorFeeTransferFailedError();
        }
    }
}
