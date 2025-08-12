// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title ERC1271Helper
 * @notice ERC-1271 서명 검증을 위한 헬퍼 컨트랙트
 */
contract ERC1271Helper {
    using ECDSA for bytes32;

    // ERC-1271 Magic Values
    bytes4 private constant MAGICVALUE = 0x1626ba7e;
    bytes4 private constant INVALID_SIGNATURE = 0xffffffff;

    /**
     * @notice 컨트랙트의 서명을 검증
     * @param _contract 검증할 컨트랙트 주소
     * @param _hash 서명된 해시
     * @param _signature 서명 데이터
     * @return true if valid signature
     */
    function isValidContractSignature(
        address _contract,
        bytes32 _hash,
        bytes memory _signature
    ) external view returns (bool) {
        try IERC1271(_contract).isValidSignature(_hash, _signature) returns (bytes4 magicValue) {
            return magicValue == MAGICVALUE;
        } catch {
            return false;
        }
    }

    /**
     * @notice EOA 또는 컨트랙트의 서명을 검증
     * @param _signer 서명자 주소
     * @param _hash 서명된 해시
     * @param _signature 서명 데이터
     * @return true if valid signature
     */
    function isValidSignature(
        address _signer,
        bytes32 _hash,
        bytes memory _signature
    ) external view returns (bool) {
        // EOA인 경우 직접 검증
        if (_signer.code.length == 0) {
            return _signer == _hash.recover(_signature);
        }
        
        // 컨트랙트인 경우 ERC-1271 사용
        return isValidContractSignature(_signer, _hash, _signature);
    }

    /**
     * @notice 서명자 주소 복구
     * @param _hash 서명된 해시
     * @param _signature 서명 데이터
     * @return signer 서명자 주소
     */
    function recoverSigner(
        bytes32 _hash,
        bytes memory _signature
    ) external pure returns (address signer) {
        return _hash.recover(_signature);
    }
}

// ERC-1271 인터페이스
interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
} 