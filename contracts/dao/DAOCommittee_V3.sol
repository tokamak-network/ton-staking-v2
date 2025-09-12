// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ICandidateFactory} from './interfaces/ICandidateFactory.sol';

import {ICandidate} from './interfaces/ICandidate.sol';
import {ILayer2} from './interfaces/ILayer2.sol';
import {IDAOAgendaManager} from './interfaces/IDAOAgendaManager.sol';
import {ISeigManager} from './interfaces/ISeigManager.sol';
import {ICoinage} from './interfaces/ICoinage.sol';
import {ICandidateAddOnFactory} from './interfaces/ICandidateAddOnFactory.sol';
import {LibAgenda} from './lib/Agenda.sol';
import {ERC165Checker} from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';

import {AccessControl} from '../accessControl/AccessControl.sol';
import {ERC165A} from '../accessControl/ERC165A.sol';

import './StorageStateCommittee.sol';
import './StorageStateCommitteeV2.sol';
import './StorageStateCommitteeV3.sol';
import './lib/BytesLib.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "../mocks/MockECDSA.sol";

import 'hardhat/console.sol';

/**
 * @notice Error that occurs when creating Candidate
 * @param x 1: deployed candidateContract is zero
 *          2: The candidate already has contract
 *          3: failed to registerAndDeployCoinage
 */
error CreateCandiateError(uint x);
error PermissionError();
error ZeroAddressError();
error ClaimTONError();
error ClaimWTONError();

interface IMultiSigWallet {
    function isOwner(address owner) external view returns (bool);
    function numConfirmationsRequired() external view returns (uint256);
}

interface ISignatureValidator {
    function isValidSignature(bytes memory _data, bytes memory _signature) external view returns (bytes4);
}

interface ISafe {
    function domainSeparator() external view returns (bytes32);
    function getChainId() external view returns (uint256);
    function signedMessages(bytes32) external view returns (uint256);
    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures) external view;
}

contract DAOCommittee_V3 is
    StorageStateCommittee,
    AccessControl,
    ERC165A,
    StorageStateCommitteeV2,
    StorageStateCommitteeV3
{
    using BytesLib for bytes;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // ERC-1271 Magic Values
    bytes4 private constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
    bytes4 private constant INVALID_SIGNATURE = 0xffffffff;

    bytes32 public constant SAFE_MSG_TYPEHASH = 0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca;
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;
    // bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;
    address public constant SENTINEL_OWNERS = address(0x1);

    address public constant SAFE_PROXY = 0x623E2B35964F944e166E6531CEF7577C2851F415;


    //////////////////////////////
    // Events
    //////////////////////////////

    event MultiSigWalletSet(address indexed oldWallet, address indexed newWallet);

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            'not admin'
        );
        _;
    }

    //////////////////////////////////////////////////////////////////////
    // ERC-1271 Implementation
    //////////////////////////////////////////////////////////////////////

    function domainSeparator() public pure returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), SAFE_PROXY));
        // return hex"354d6f7b96d2576ed7cef655de3fc5de82569dc776d566faa0d81e3837df2f3b";
    }

    function domainSeparator2() public view returns (bytes32) {
        ISafe safe = ISafe(payable(SAFE_PROXY));
        return safe.domainSeparator();
    }

    function getChainId() public pure returns (uint256) {
        uint256 id = 11155111;
        return id;
    }

    function isValidSignature(bytes memory _data, bytes memory _signature) public view returns (bytes4) {
        // Caller should be a Safe
        console.log("input _data");
        console.logBytes(_data);
        ISafe safe = ISafe(payable(SAFE_PROXY));
        bytes memory messageData = encodeMessageDataForSafe(_data);
        bytes32 messageHash = keccak256(messageData);
        
        console.log("changed _data is messageHash");
        console.logBytes32(messageHash);

        console.log("changed _data is messageData");
        console.logBytes(messageData);

        if (_signature.length == 0) {
            console.log("1");
            require(safe.signedMessages(messageHash) != 0, "Hash not approved");
        } else {
            checkSignatures(messageHash, messageData, _signature);
        }
        return EIP1271_MAGIC_VALUE;
    }

    function encodeMessageDataForSafe(bytes memory message) public pure returns (bytes memory) {
        bytes32 safeMessageHash = keccak256(abi.encode(SAFE_MSG_TYPEHASH, keccak256(message)));
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeMessageHash);
    }

    function signMessage(bytes32 messageHash) external {
        signedMessages[messageHash] = 1;
    }

    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures) public view {
        uint256 _threshold = threshold;
        checkNSignatures(dataHash, data, signatures, _threshold);
    }

    function checkNSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures, uint256 requiredSignatures) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures * 65, "GS020");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            console.log("v is ", v);
            console.log("r is ");
            console.logBytes32(r);
            console.log("s is ");
            console.logBytes32(s);
            if (v == 0) {
                // console.log("dataHash is ");
                // console.logBytes32(dataHash);
                // console.log("data is ");
                // console.logBytes(data);
                // console.log("data.length", data.length);
                require(keccak256(data) == dataHash, "GS027");
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));
                console.log("currentOwner is ", currentOwner);
                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= requiredSignatures * 65, "GS021");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s) + 32 <= signatures.length, "GS022");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s) + 32 + contractSignatureLen <= signatures.length, "GS023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                console.log("data");
                console.logBytes(data);
                console.log("contractSignature");
                console.logBytes(contractSignature);
                console.log("contractSignature.length", contractSignature.length);
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                console.log("2");
                console.log("dataHash is ");
                console.logBytes32(dataHash);
                // console.log("r is ");
                // console.logBytes32(r);
                // console.log("s is ");
                // console.logBytes32(s);
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
                console.log("expected currentOwner is ", currentOwner);
                console.log("3");
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
                console.log("not expected currentOwner is ", currentOwner);
            }
            require(currentOwner > lastOwner, "error1");
            // require(owners[currentOwner] != address(0), "error2");
            require(currentOwner != SENTINEL_OWNERS, "error3");

            require(isOwner(currentOwner) || isOwner2(currentOwner), "Diff SignerAddress");
            // require(currentOwner > lastOwner && owners[currentOwner] != address(0) && currentOwner != SENTINEL_OWNERS, "GS026");
            console.log("pass require");
            lastOwner = currentOwner;
        }
    }

    function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            /**
             * Here we are loading the last 32 bytes, including 31 bytes
             * of 's'. There is no 'mload8' to do this.
             * 'byte' is not working due to the Solidity parser, so lets
             * use the second best option, 'and'
             */
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    function isValidSignature2(bytes memory _hash, bytes memory _signature) external view returns (bytes4 magicValue) {
        if (_validateSignatures(_hash, _signature)) {
            return EIP1271_MAGIC_VALUE;
        }
        return INVALID_SIGNATURE;
    }

    function _validateSignatures(
        bytes memory _hash,
        bytes memory _signature
    ) internal view returns (bool) {
        if (_signature.length < 65) return false;

        address signer;

        // Try different signature recovery methods
        signer = _recoverSigner(_hash, _signature);
        if (IMultiSigWallet(multiSigWallet).isOwner(signer)) {
            return true; 
        }

        return false;
    }

    function _recoverSigner(
        bytes memory _hash,
        bytes memory _signature
    ) internal view returns (address signer) {
        console.log("signatures");
        console.logBytes(_signature);
        console.log("signatures.length", _signature.length);
        require(_signature.length >= 65, 'bad sig len');

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract r, s, v from signature
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // Prevent signature malleability
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "bad sig 's' value"
        );
        
        console.logBytes32(r);
        console.logBytes32(s);
        console.log("v is ", v);
        // require(v == 27 || v == 28, "bad sig 'v' value");
        // require(v > 30 , "bad sig 'v' value");

        // Create Ethereum signed message hash
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked('\x19Ethereum Signed Message:\n32', _hash)
        );
        // bytes32 messageHash = getMessageHash(_hash);
        // bytes32 messageHash = keccak256(_hash);
        // signer = messageHash.toEthSignedMessageHash().recover(_signature);
        // signer = ECDSA.recover(messageHash, _signature);
        // signer = ecrecover(messageHash, v-4, r, s);
        signer = ecrecover(ethSignedMessageHash, v - 4 , r, s);
        // signer = ecrecover(keccak256(_hash), v - 4, r, s);
        console.log("signer", signer);

        require(signer != address(0), 'Invalid signer');
        return signer;
    }


    /**
     * @notice Verify that you are the owner of MultiSigWallet
     * @param _address Enter address
     * @return true True if the owner of MultiSigWallet
     */
    function isOwner(address _address) public view returns (bool) {
        return IMultiSigWallet(multiSigWallet).isOwner(_address);
    }

    function isOwner2(address _address) public view returns (bool) {
        return _address == 0xA2101482b28E3D99ff6ced517bA41EFf4971a386;
    }

    /**
     * @notice Sets MultiSigWallet address (onlyOwner)
     * @dev MultiSigWallet becomes the DAO Owner and its owners' signatures are validated via EIP-1271
     * @param _multiSigWallet New MultiSigWallet address
     */
    function setMultiSigWallet(
        address _multiSigWallet
    ) external onlyOwner {
        address oldWallet = multiSigWallet;
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _multiSigWallet),
            'not admin'
        );
        multiSigWallet = _multiSigWallet;
        emit MultiSigWalletSet(oldWallet, _multiSigWallet);
    }

    function version() public pure virtual returns (string memory) {
        return '2.0.0';
    }
}
