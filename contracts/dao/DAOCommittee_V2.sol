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
    function isValidSignature2(bytes memory _data, bytes memory _signature) external view returns (bytes4);
}

contract DAOCommittee_V2 is
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
    
    // EIP-712 constants
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant SAFE_MSG_TYPEHASH = keccak256("SafeMessage(bytes message)");
    
    bytes32 public domainSeparator;
    address public constant SENTINEL_OWNERS = address(0x1);

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

   function isValidSignature(bytes calldata _data, bytes calldata _signature)
        external
        returns (bytes4)
    {

        bytes32 messageHash = getMessageHash(_data);
        // consumeHash needs to be false, as the state should not be changed
        checkSignatures(messageHash, _data, _signature, false);
        console.log("checkSignatures end");

        return EIP1271_MAGIC_VALUE;
    }

    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures, bool consumeHash)
        internal
    {   
        console.log("signatures");
        console.logBytes(signatures);
        console.log("signatures.length", signatures.length);
        // Check that the provided signature data is not too short
        require(signatures.length >= (threshold * (65)), "Signatures data too short");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            
            console.log("v is ", v);
            // If v is 0 then it is a contract signature
            if (v == 0) {
                console.log("s is ", uint256(s));
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));
                console.log("currentOwner is ", currentOwner);

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                // require(uint256(s) >= (threshold * (65)), "Invalid contract signature location: inside static part");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require((uint256(s)+(32)) <= signatures.length, "Invalid contract signature location: length not present");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solium-disable-next-line security/no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require((uint256(s)+(32))+(contractSignatureLen) <= signatures.length, "Invalid contract signature location: data not complete");

                // Check signature
                bytes memory contractSignature;
                // solium-disable-next-line security/no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                console.log("contractSignature");
                console.logBytes(contractSignature);
                console.log("contractSignature.length", contractSignature.length);
                require(ISignatureValidator(currentOwner).isValidSignature2(data, contractSignature) == EIP1271_MAGIC_VALUE, "Invalid contract signature provided");
            // If v is 1 then it is an approved hash
            } else if (v == 1) {
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "Hash has not been approved");
                // Hash has been marked for consumption. If this hash was pre-approved free storage
                if (consumeHash && msg.sender != currentOwner) {
                    approvedHashes[currentOwner][dataHash] = 0;
                }
            } else if (v > 30) {
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, uint8(v), r, s);
                console.log("currentOwner", currentOwner);
            }
            require(currentOwner > lastOwner, "error1");
            require(currentOwner != SENTINEL_OWNERS, "error3");
            require(isOwner2(currentOwner), "error2");
            require (currentOwner > lastOwner && isOwner2(currentOwner) && currentOwner != SENTINEL_OWNERS, "Invalid owner provided");
            console.log("pass require");
            lastOwner = currentOwner;
        }
    }

    function getMessageHash(
        bytes memory message
    )
        public
        view
        returns (bytes32)
    {
        bytes32 safeMessageHash = keccak256(
            abi.encode(SAFE_MSG_TYPEHASH, keccak256(message))
        );
        return keccak256(
            abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, safeMessageHash)
        );
    }

    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
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
        domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this));
        emit MultiSigWalletSet(oldWallet, _multiSigWallet);
    }

    function version() public pure virtual returns (string memory) {
        return '2.0.0';
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

        // // Try ETH_SIGN method (with prefix)
        // signer = _recoverSignerWithPrefix(_hash, _signature);
        // if (IMultiSigWallet(multiSigWallet).isOwner(signer)) {
        //     return true; 
        // }

        // // Try direct hash recovery (for Safe signatures)
        // signer = _recoverSignerDirect(_hash, _signature);
        // if (IMultiSigWallet(multiSigWallet).isOwner(signer)) {
        //     return true; 
        // }

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
        signer = ecrecover(ethSignedMessageHash, v - 4, r, s);
        console.log("signer", signer);

        require(signer != address(0), 'Invalid signer');
        return signer;
    }

    function _recoverSignerWithPrefix(
        bytes memory _hash,
        bytes memory _signature
    ) internal pure returns (address signer) {
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
        
        require(v == 27 || v == 28, "bad sig 'v' value");

        // Create Ethereum signed message hash with prefix
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked('\x19Ethereum Signed Message:\n32', _hash)
        );
        
        signer = ecrecover(ethSignedMessageHash, v, r, s);
        require(signer != address(0), 'Invalid signer');
        return signer;
    }

    function _recoverSignerDirect(
        bytes memory _hash,
        bytes memory _signature
    ) internal pure returns (address signer) {
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

        console.logBytes32(r);
        console.logBytes32(s);
        console.log("v is ", v);

        // Prevent signature malleability
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "bad sig 's' value"
        );
        
        // require(v == 27 || v == 28, "bad sig 'v' value");
        require(v > 30 , "bad sig 'v' value");

        // Direct hash recovery (for Safe signatures without prefix)
        bytes32 hashBytes32;
        assembly {
            hashBytes32 := mload(add(_hash, 32))
        }
        
        signer = ecrecover(hashBytes32, v, r, s);
        console.log("signer", signer);

        require(signer != address(0), 'Invalid signer');
        return signer;
    }
}
