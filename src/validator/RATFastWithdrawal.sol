// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ProxyStorage} from "../proxy/ProxyStorage.sol";
import {AccessibleCommon} from "../common/AccessibleCommon.sol";
import {RATStorage} from "./RATStorage.sol";
import {BLS12381} from "../libraries/BLS12381.sol";
import {RATFastWithdrawalLib} from "../libraries/RATFastWithdrawalLib.sol";
import {ILayer2Manager} from "../layer2/interfaces/ILayer2Manager.sol";
import {IValidatorReward} from "./IValidatorReward.sol";

// OptimismPortal2 인터페이스 (Fast Withdrawal용)
interface IOptimismPortal2ForRAT {
    /// @notice 출금이 RAT에 의해 검증되었음을 표시
    function setWithdrawalVerified(bytes32 _withdrawalHash) external;

    /// @notice Fast Withdrawal 실행 (7일 딜레이 없이 즉시 출금)
    function fastWithdrawalFinalize(Types.WithdrawalTransaction memory _tx) external;

    /// @notice 출금 검증 여부 조회
    function withdrawalVerified(bytes32 _withdrawalHash) external view returns (bool);

    /// @notice Fast Withdrawal로 완료된 출금인지 확인
    function fastFinalizedWithdrawals(bytes32 _withdrawalHash) external view returns (bool);
}

// Types 라이브러리 (Optimism)
library Types {
    struct WithdrawalTransaction {
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 gasLimit;
        bytes data;
    }
}

// V3: SeigManager 연동을 위한 인터페이스 (Fast Withdrawal에서 필요한 부분만)
interface ISeigManagerForFastWithdrawal {
    function v3Migrated() external view returns (bool);
    function stakeOf(address layer2, address account) external view returns (uint256);
}

// Custom Errors
error NotActiveValidatorError();
error InsufficientCollateralError();
error InvalidSystemConfigError();
error NotMigratedError();
error InvalidBLSPublicKeyError();
error InvalidProofOfPossessionError();
error BLSKeyAlreadyRegisteredError();
error BLSKeyNotRegisteredError();
error AlreadyRegisteredError();
error MaxValidatorsReachedError();

// Fast Withdrawal 관련 에러
error FastWithdrawalDisabledError();
error FastWithdrawalAlreadyProcessedError();
error FastWithdrawalInvalidHashError();
error FastWithdrawalNotUnanimousError();
error FastWithdrawalInvalidBLSSignatureError();
error FastWithdrawalInvalidAdjacentLeavesError();
error FastWithdrawalPortalNotSetError();
error FastWithdrawalInvalidValidatorBitmapError();
error FastWithdrawalNoValidatorsError();
error FastWithdrawalInsufficientValidatorsError();
error InvalidAggregatorFeeRateError();
error InvalidMinValidatorsError();

/**
 * @title RATFastWithdrawal
 * @notice RAT Fast Withdrawal 기능을 담당하는 구현체
 * @dev RAT 프록시의 두 번째 구현체로, BLS 공개키 관리 및 Fast Withdrawal 기능 제공
 * @dev RATStorage를 상속받아 RAT.sol과 동일한 메모리 레이아웃 유지
 * @dev 프록시 Selector Routing: RAT.sol과 함께 같은 프록시 주소에서 사용
 *
 * 핵심 기능:
 * 1. BLS 공개키 등록/조회 (검증자)
 * 2. Fast Withdrawal 검증 및 실행
 * 3. 수수료 분배 (집계자 + 검증자)
 */
contract RATFastWithdrawal is ProxyStorage, AccessibleCommon, RATStorage {
    // ==========================================
    // Modifiers
    // ==========================================

    // onlyOwner는 AccessibleCommon에서 상속 (AccessControl 기반)

    // ==========================================
    // Events
    // ==========================================

    /// @notice BLS 공개키가 등록되었을 때 발생하는 이벤트
    event BLSPublicKeyRegistered(
        address indexed validator,
        address indexed systemConfig,
        bytes blsPublicKey
    );

    /// @notice BLS 공개키가 업데이트되었을 때 발생하는 이벤트
    event BLSPublicKeyUpdated(
        address indexed validator,
        address indexed systemConfig,
        bytes oldKey,
        bytes newKey
    );

    /// @notice Fast Withdrawal 실행 이벤트
    event FastWithdrawalExecuted(
        bytes32 indexed withdrawalHash,
        address indexed user,
        uint256 amount,
        address indexed aggregator
    );

    /// @notice 집계자 수수료율 변경 이벤트
    event AggregatorFeeRateUpdated(uint256 newRate);

    /// @notice 최소 검증자 수 변경 이벤트
    event MinValidatorsForFastWithdrawalUpdated(uint256 newMinValidators);

    /// @notice 검증자 등록 이벤트 (BLS 포함 등록용)
    event ValidatorRegistered(
        address indexed validator,
        address indexed systemConfig,
        address indexed layer2,
        uint256 collateral,
        uint256 index
    );

    // ==========================================
    // BLS Public Key Management
    // ==========================================

    /// @notice 검증자 등록 (BLS 공개키 포함)
    /// @dev 기존 registerValidator + BLS 공개키 등록
    /// @dev Proof of Possession으로 Rogue Key Attack 방지
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param blsPublicKey BLS 공개키 (128 bytes, uncompressed G1 point, EIP-2537)
    /// @param blsProofOfPossession BLS 개인키 소유 증명 (256 bytes, uncompressed G2 signature, EIP-2537)
    function registerValidatorWithBLS(
        address systemConfig,
        bytes calldata blsPublicKey,
        bytes calldata blsProofOfPossession
    ) external ifFree whenNotPaused {
        // V3 마이그레이션 후에만 검증자 등록 가능
        if (!ISeigManagerForFastWithdrawal(seigManager).v3Migrated()) revert NotMigratedError();
        if (systemConfig == address(0)) revert InvalidSystemConfigError();

        // BLS 공개키 길이 검증 (128 bytes, uncompressed G1 point)
        if (blsPublicKey.length != 128) revert InvalidBLSPublicKeyError();

        // BLS PoP 길이 검증 (256 bytes, uncompressed G2 signature)
        if (blsProofOfPossession.length != 256) revert InvalidProofOfPossessionError();

        // 이미 등록된 검증자인지 먼저 확인 (빠른 실패)
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        if (reg.isActive) revert AlreadyRegisteredError();

        // V3: coinage에서 담보금 확인
        (uint256 collateral, address layer2) = _getValidatorCollateral(msg.sender, systemConfig);
        uint256 minDeposit = _getDynamicMinimumCollateral(systemConfig);
        if (collateral < minDeposit) revert InsufficientCollateralError();

        // BLS Proof of Possession 검증
        // PoP message: keccak256("BLS_POP", chainId, validatorAddress, publicKey)
        bool validPoP = BLS12381.verifyProofOfPossession(
            block.chainid,
            msg.sender,
            blsPublicKey,
            blsProofOfPossession
        );
        if (!validPoP) revert InvalidProofOfPossessionError();

        // 검증자 등록 로직
        _registerValidatorInternal(msg.sender, systemConfig, reg, collateral, layer2);

        // BLS 공개키 저장
        reg.blsPublicKey = blsPublicKey;

        emit BLSPublicKeyRegistered(msg.sender, systemConfig, blsPublicKey);
    }

    /// @notice 기존 검증자의 BLS 공개키 등록/업데이트
    /// @dev 이미 등록된 검증자가 BLS 공개키를 추가/변경할 때 사용
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param blsPublicKey BLS 공개키 (128 bytes, uncompressed G1 point, EIP-2537)
    /// @param blsProofOfPossession BLS 개인키 소유 증명 (256 bytes, uncompressed G2 signature, EIP-2537)
    function registerBLSPublicKey(
        address systemConfig,
        bytes calldata blsPublicKey,
        bytes calldata blsProofOfPossession
    ) external ifFree whenNotPaused {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];

        // 활성 검증자만 BLS 키 등록 가능
        if (!reg.isActive) revert NotActiveValidatorError();

        // BLS 공개키 길이 검증 (128 bytes, uncompressed G1 point)
        if (blsPublicKey.length != 128) revert InvalidBLSPublicKeyError();

        // BLS PoP 길이 검증 (256 bytes, uncompressed G2 signature)
        if (blsProofOfPossession.length != 256) revert InvalidProofOfPossessionError();

        // BLS Proof of Possession 검증
        bool validPoP = BLS12381.verifyProofOfPossession(
            block.chainid,
            msg.sender,
            blsPublicKey,
            blsProofOfPossession
        );
        if (!validPoP) revert InvalidProofOfPossessionError();

        bytes memory oldKey = reg.blsPublicKey;

        // BLS 공개키 저장
        reg.blsPublicKey = blsPublicKey;

        if (oldKey.length == 0) {
            emit BLSPublicKeyRegistered(msg.sender, systemConfig, blsPublicKey);
        } else {
            emit BLSPublicKeyUpdated(msg.sender, systemConfig, oldKey, blsPublicKey);
        }
    }

    /// @notice 검증자의 BLS 공개키 조회
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return BLS 공개키 (128 bytes, uncompressed G1) 또는 빈 bytes (미등록)
    function getValidatorBLSPubKey(
        address validator,
        address systemConfig
    ) external view returns (bytes memory) {
        return validatorRegistrations[systemConfig][validator].blsPublicKey;
    }

    /// @notice 여러 검증자의 BLS 공개키 일괄 조회
    /// @dev Fast Withdrawal 컨트랙트에서 가스 효율적인 조회에 사용
    /// @param validators 검증자 주소 배열
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return blsPublicKeys BLS 공개키 배열
    function getBatchValidatorBLSPublicKeys(
        address[] calldata validators,
        address systemConfig
    ) external view returns (bytes[] memory blsPublicKeys) {
        uint256 length = validators.length;
        blsPublicKeys = new bytes[](length);

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                blsPublicKeys[i] = validatorRegistrations[systemConfig][validators[i]].blsPublicKey;
            }
        }
    }

    /// @notice 검증자가 BLS 공개키를 등록했는지 확인
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return true if BLS key is registered
    function hasValidatorBLSKey(
        address validator,
        address systemConfig
    ) external view returns (bool) {
        return validatorRegistrations[systemConfig][validator].blsPublicKey.length == 128;
    }

    /// @notice Fast Withdrawal을 위한 활성 검증자 목록 조회 (BLS 키 등록 여부 포함)
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return validators 활성 검증자 주소 목록
    /// @return blsKeys 각 검증자의 BLS 공개키
    /// @return validBLSCount BLS 키가 등록된 검증자 수
    function getActiveValidatorsWithBLS(
        address systemConfig
    ) external view returns (
        address[] memory validators,
        bytes[] memory blsKeys,
        uint256 validBLSCount
    ) {
        validators = validatorPools[systemConfig].validators;
        uint256 length = validators.length;
        blsKeys = new bytes[](length);

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                blsKeys[i] = validatorRegistrations[systemConfig][validators[i]].blsPublicKey;
                if (blsKeys[i].length == 128) {
                    ++validBLSCount;
                }
            }
        }
    }

    // ==========================================
    // Fast Withdrawal Functions
    // ==========================================

    /// @notice 집계자 수수료율 설정
    /// @param rate 수수료율 (RAY 단위, 10% = 1e26)
    function setAggregatorFeeRate(uint256 rate) external onlyOwner {
        if (rate > RAY) revert InvalidAggregatorFeeRateError();
        aggregatorFeeRate = rate;
        emit AggregatorFeeRateUpdated(rate);
    }

    /// @notice Fast Withdrawal을 위한 최소 검증자 수 설정
    /// @param minValidators 최소 검증자 수 (0이면 Fast Withdrawal 비활성화)
    function setMinValidatorsForFastWithdrawal(uint256 minValidators) external onlyOwner {
        minValidatorsForFastWithdrawal = minValidators;
        emit MinValidatorsForFastWithdrawalUpdated(minValidators);
    }

    /// @notice BLS 집계 서명 + 인접 리프 증명으로 빠른 출금 실행
    /// @dev Aggregator가 호출 (누구나 가능, 수수료 인센티브)
    /// @dev 최적화: calldata 직접 사용, 중복 메모리 복사 제거
    ///
    /// @dev 호출 흐름:
    ///      1. 사용자가 OptimismPortal2.proveAndRequestFastWithdrawal() 호출
    ///      2. FastWithdrawalRequested 이벤트 발생
    ///      3. RAT 검증자들이 오프체인에서 이벤트 감지 → L2 상태 검증 → BLS 서명
    ///      4. Aggregator가 서명 수집 후 이 함수 호출
    ///      5. RAT이 검증 후 OptimismPortal2.setWithdrawalVerified() 호출
    ///      6. RAT이 OptimismPortal2.fastWithdrawalFinalize() 호출 → 즉시 출금 완료
    ///
    /// @param _tx 출금 트랜잭션 (OptimismPortal2의 WithdrawalTransaction)
    /// @param input Fast Withdrawal 검증에 필요한 모든 데이터
    /// @param _aggregatedSignature 검증자들의 BLS 집계 서명 (256 bytes)
    function verifyAndExecuteFastWithdrawal(
        Types.WithdrawalTransaction calldata _tx,
        RATFastWithdrawalLib.FastWithdrawalInput calldata input,
        bytes calldata _aggregatedSignature
    ) external payable ifFree whenNotPaused {
        // 사전 검증 (portal 주소 반환받아 재사용)
        address portal = _validateFastWithdrawalPreconditions(input, _tx);

        // 검증자 정보 조회
        uint256 validatorCount = validatorPools[input.systemConfig].activeCount;

        // 최소 검증자 수 요구사항 체크
        // minValidatorsForFastWithdrawal이 0이면 Fast Withdrawal 비활성화
        // minValidatorsForFastWithdrawal이 설정되어 있으면 해당 값 이상 필요
        uint256 minValidators = minValidatorsForFastWithdrawal;
        if (minValidators == 0) revert FastWithdrawalDisabledError();
        if (validatorCount < minValidators) {
            revert FastWithdrawalInsufficientValidatorsError();
        }

        // 만장일치 검증: 모든 검증자가 서명했는지 확인
        // validatorBitmap의 모든 비트가 1이어야 함 (예: 3명이면 0b111 = 7 = (1 << 3) - 1)
        if (input.validatorBitmap != (1 << validatorCount) - 1) {
            revert FastWithdrawalNotUnanimousError();
        }

        // BLS 공개키 수집 (storage 직접 참조로 메모리 복사 방지)
        ValidatorPoolInfo storage pool = validatorPools[input.systemConfig];
        bytes[] memory publicKeys = new bytes[](validatorCount);
        unchecked {
            for (uint256 i = 0; i < validatorCount; ++i) {
                publicKeys[i] = validatorRegistrations[input.systemConfig][pool.validators[i]].blsPublicKey;
            }
        }

        // BLS 공개키 집계 (라이브러리 사용)
        bytes memory aggregatedPubKey = RATFastWithdrawalLib.aggregatePublicKeys(
            publicKeys,
            input.validatorBitmap,
            validatorCount
        );

        // BLS 서명 검증 (라이브러리 사용)
        RATFastWithdrawalLib.verifyBLSSignature(
            input,
            _aggregatedSignature,
            aggregatedPubKey
        );

        // 인접 리프 증명 검증 (라이브러리 사용)
        RATFastWithdrawalLib.verifyAdjacentLeaves(input);

        // 검증 통과 → 실행
        _executeFastWithdrawal(input, _tx, portal);
    }

    /// @notice Fast Withdrawal 사전 조건 검증
    /// @return portal OptimismPortal 주소 (재사용을 위해 반환)
    function _validateFastWithdrawalPreconditions(
        RATFastWithdrawalLib.FastWithdrawalInput calldata input,
        Types.WithdrawalTransaction calldata _tx
    ) internal view returns (address portal) {
        portal = _getOptimismPortal(input.systemConfig);
        if (portal == address(0)) revert FastWithdrawalPortalNotSetError();

        if (processedWithdrawals[input.withdrawalHash]) revert FastWithdrawalAlreadyProcessedError();

        // 해시 검증 (라이브러리 사용)
        RATFastWithdrawalLib.validateWithdrawalHash(
            _tx.nonce,
            _tx.sender,
            _tx.target,
            _tx.value,
            _tx.gasLimit,
            _tx.data,
            input.withdrawalHash
        );
    }

    /// @notice Fast Withdrawal 실행 (Portal 호출 및 수수료 분배)
    function _executeFastWithdrawal(
        RATFastWithdrawalLib.FastWithdrawalInput calldata input,
        Types.WithdrawalTransaction calldata _tx,
        address portal
    ) internal {
        processedWithdrawals[input.withdrawalHash] = true;

        IOptimismPortal2ForRAT(portal).setWithdrawalVerified(input.withdrawalHash);
        IOptimismPortal2ForRAT(portal).fastWithdrawalFinalize(_tx);

        // 수수료 분배 (라이브러리 사용)
        RATFastWithdrawalLib.distributeFees(msg.value, msg.sender, validatorReward, aggregatorFeeRate);

        emit FastWithdrawalExecuted(input.withdrawalHash, _tx.sender, _tx.value, msg.sender);
    }

    // ==========================================
    // Internal Helper Functions
    // ==========================================

    /// @notice 검증자 담보금 조회 (coinage 스테이킹 금액)
    /// @dev V3: SeigManager.stakeOf(layer2, validator) 사용
    /// @return collateral 담보금
    /// @return layer2 Layer2 주소
    function _getValidatorCollateral(address validator, address systemConfig) internal view returns (uint256 collateral, address layer2) {
        layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
        if (layer2 == address(0)) return (0, address(0));
        collateral = ISeigManagerForFastWithdrawal(seigManager).stakeOf(layer2, validator);
    }

    /// @notice L2별 동적 최소 담보금 계산
    /// @dev C_off = max(slashingPenalty, (c_m × N) / π_a)
    /// @dev D_min = C_off + Δ_validator
    function _getDynamicMinimumCollateral(address systemConfig) internal view returns (uint256) {
        uint256 n = validatorPools[systemConfig].activeCount;
        if (n == 0) n = 1;
        return _calculateMinimumCollateral(n);
    }

    /// @notice 검증자 수 기반 D_min 계산
    function _calculateMinimumCollateral(uint256 n) internal view returns (uint256) {
        return _calculateDynamicCoff(n) + validatorBuffer;
    }

    /// @notice 백서 공식 기반 동적 C_off 계산
    function _calculateDynamicCoff(uint256 n) internal view returns (uint256) {
        uint256 _slashingPenalty = slashingPenalty;
        uint256 _attentionCost = attentionCost;
        uint256 _ratTriggerProb = ratTriggerProbability;

        if (_attentionCost > 0 && _ratTriggerProb > 0) {
            uint256 formulaCoff = (_attentionCost * n * RAY) / _ratTriggerProb;
            if (formulaCoff > _slashingPenalty) {
                return formulaCoff;
            }
        }

        return _slashingPenalty;
    }

    /// @notice 내부 검증자 등록 로직 (registerValidatorWithBLS용)
    function _registerValidatorInternal(
        address validator,
        address systemConfig,
        ValidatorRegistration storage reg,
        uint256 collateral,
        address layer2
    ) internal {
        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        uint256 index = pool.validators.length;

        // N_max 체크
        if (index >= maxValidatorsPerL2) {
            revert MaxValidatorsReachedError();
        }

        pool.validators.push(validator);
        pool.activeCount++;

        reg.validatorIndex = uint32(index);
        reg.isActive = true;

        validatorIndexes[systemConfig][validator] = index;
        validatorSystemConfigs[validator].push(systemConfig);

        // V1.1: ValidatorReward에 등록 알림 (O(1) 보상 분배용)
        if (validatorReward != address(0)) {
            IValidatorReward(validatorReward).registerValidatorToL2(validator, systemConfig);
        }

        emit ValidatorRegistered(validator, systemConfig, layer2, collateral, index);
    }

    /// @notice SystemConfig에서 OptimismPortal 주소 조회
    /// @dev Layer2Manager를 통해 동적으로 Portal 주소를 가져옴 (여러 L2 지원)
    /// @param systemConfig L2의 SystemConfig 주소 (rollupConfig)
    /// @return portal OptimismPortal2 주소, 없으면 address(0)
    function _getOptimismPortal(address systemConfig) internal view returns (address portal) {
        // Layer2Manager.checkL1BridgeDetail()로 Portal 주소 조회
        (bool result, , address _portal, , , , , ) =
            ILayer2Manager(layer2Manager).checkL1BridgeDetail(systemConfig);

        if (!result) {
            return address(0);
        }

        return _portal;
    }

    /// @notice Fast Withdrawal 수수료 수령을 위한 receive 함수
    receive() external payable {}
}
