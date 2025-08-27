# EIP-1271 구현 예시

## 완전한 구현 예시

DAOCommittee_V2에서 추출한 EIP-1271 구현 패턴을 기반으로 한 예시입니다.

### 기본 구현

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

interface IMultiSigWallet {
    function isOwner(address owner) external view returns (bool);
    function getOwners() external view returns (address[] memory);
    function numConfirmationsRequired() external view returns (uint256);
}

contract EIP1271Implementation is AccessControl, IERC1271 {
    // ERC-1271 Magic Values
    bytes4 private constant MAGICVALUE = 0x1626ba7e;
    bytes4 private constant INVALID_SIGNATURE = 0xffffffff;
    
    // MultiSig wallet address (DAO Owner)
    address public multiSigWallet;
    
    // Events
    event MultiSigWalletSet(address indexed oldWallet, address indexed newWallet);
    
    // Modifiers
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        _;
    }
    
    modifier nonZero(address _addr) {
        require(_addr != address(0), "Zero address");
        _;
    }
    
    /**
     * @notice EIP-1271 signature validation
     * @param _hash Hash that was signed
     * @param _signature Signature data
     * @return magicValue ERC-1271 magic value if valid
     */
    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) external view returns (bytes4 magicValue) {
        if (multiSigWallet == address(0)) {
            return INVALID_SIGNATURE;
        }
        
        require(hasRole(DEFAULT_ADMIN_ROLE, multiSigWallet), "MultiSig not admin");
        
        if (_validateSignatures(_hash, _signature)) {
            return MAGICVALUE;
        }
        return INVALID_SIGNATURE;
    }
    
    /**
     * @notice Set MultiSig wallet address
     * @param _multiSigWallet New MultiSig wallet address
     */
    function setMultiSigWallet(address _multiSigWallet) 
        external 
        onlyOwner 
        nonZero(_multiSigWallet) 
    {
        address oldWallet = multiSigWallet;
        require(hasRole(DEFAULT_ADMIN_ROLE, _multiSigWallet), "New wallet not admin");
        
        multiSigWallet = _multiSigWallet;
        emit MultiSigWalletSet(oldWallet, _multiSigWallet);
    }
    
    /**
     * @notice Validate single signature from MultiSig owner
     * @dev Only requires one MultiSig owner signature, not multiple
     * @param _hash Hash that was signed
     * @param _signature Signature data (65 bytes)
     * @return true if signer is a MultiSig owner
     */
    function _validateSignatures(
        bytes32 _hash,
        bytes memory _signature
    ) internal view returns (bool) {
        if (_signature.length < 65) return false;
        
        // Extract first signature (65 bytes) - single signature validation
        bytes memory sigPart = _signature[0:65];
        address signer = _recoverSigner(_hash, sigPart);
        
        // Only check if signer is one of the MultiSig owners
        return IMultiSigWallet(multiSigWallet).isOwner(signer);
    }
    
    /**
     * @notice Recover signer from ECDSA signature
     * @param _hash Hash that was signed
     * @param _signature Signature data (65 bytes)
     * @return signer Recovered signer address
     */
    function _recoverSigner(
        bytes32 _hash,
        bytes memory _signature
    ) internal pure returns (address signer) {
        require(_signature.length == 65, "Invalid signature length");
        
        uint8 v = uint8(_signature[64]);
        bytes32 r;
        bytes32 s;
        
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
        }
        
        // Prevent signature malleability
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Invalid signature 's' value"
        );
        
        require(v == 27 || v == 28, "Invalid signature 'v' value");
        
        // Create Ethereum signed message hash
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
        
        signer = ecrecover(ethSignedMessageHash, v, r, s);
        require(signer != address(0), "Invalid signer");
        
        return signer;
    }
}
```

### 사용 예시

```javascript
// JavaScript/TypeScript 사용 예시
const { ethers } = require("hardhat");

async function signAndValidate() {
    const [signer] = await ethers.getSigners();
    const contract = await ethers.getContractAt("EIP1271Implementation", contractAddress);
    
    // 메시지 해시 생성
    const message = "Hello, EIP-1271!";
    const messageHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
    
    // 서명 생성
    const signature = await signer.signMessage(ethers.utils.arrayify(messageHash));
    
    // 서명 검증
    const result = await contract.isValidSignature(messageHash, signature);
    
    console.log("Signature valid:", result === "0x1626ba7e");
}
```

### 가스 최적화된 단일 서명 구현

```solidity
contract OptimizedEIP1271 is EIP1271Implementation {
    /**
     * @notice Gas-optimized single signature validation
     * @dev Ignores MultiSig's required confirmations for efficiency
     * @param _hash Hash that was signed
     * @param _signature Single signature (65 bytes)
     * @return true if signer is any MultiSig owner
     */
    function _validateSingleSignature(
        bytes32 _hash,
        bytes memory _signature
    ) internal view returns (bool) {
        // Early return for invalid signature length
        if (_signature.length != 65) return false;
        
        // Recover signer address
        address signer = _recoverSigner(_hash, _signature);
        
        // Single external call to check ownership
        return IMultiSigWallet(multiSigWallet).isOwner(signer);
    }
    
    /**
     * @notice Override to use single signature validation
     */
    function _validateSignatures(
        bytes32 _hash,
        bytes memory _signature
    ) internal view override returns (bool) {
        return _validateSingleSignature(_hash, _signature);
    }
}
```

### 테스트 예시

```javascript
describe("EIP-1271 Implementation", function () {
    let contract, multiSig, owner, user1, user2;
    
    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        
        // Deploy MultiSig mock
        const MultiSigMock = await ethers.getContractFactory("MultiSigMock");
        multiSig = await MultiSigMock.deploy([user1.address, user2.address], 1);
        
        // Deploy EIP-1271 contract
        const EIP1271 = await ethers.getContractFactory("EIP1271Implementation");
        contract = await EIP1271.deploy();
        
        // Setup
        await contract.grantRole(await contract.DEFAULT_ADMIN_ROLE(), multiSig.address);
        await contract.setMultiSigWallet(multiSig.address);
    });
    
    it("should validate signature from MultiSig owner", async function () {
        const message = "test message";
        const messageHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
        // user1 is a MultiSig owner
        const signature = await user1.signMessage(ethers.utils.arrayify(messageHash));
        
        const result = await contract.isValidSignature(messageHash, signature);
        expect(result).to.equal("0x1626ba7e");
    });
    
    it("should reject signature from non-MultiSig owner", async function () {
        const messageHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test"));
        // owner is NOT a MultiSig owner
        const wrongSignature = await owner.signMessage(ethers.utils.arrayify(messageHash));
        
        const result = await contract.isValidSignature(messageHash, wrongSignature);
        expect(result).to.equal("0xffffffff");
    });
    
    it("should work with single signature (not requiring multiple)", async function () {
        const message = "single sig test";
        const messageHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
        // Only one signature needed, even if MultiSig requires 2
        const signature = await user2.signMessage(ethers.utils.arrayify(messageHash));
        
        const result = await contract.isValidSignature(messageHash, signature);
        expect(result).to.equal("0x1626ba7e");
    });
});
```

### 배포 스크립트

```javascript
// deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    
    console.log("Deploying with account:", deployer.address);
    
    // Deploy EIP-1271 contract
    const EIP1271 = await ethers.getContractFactory("EIP1271Implementation");
    const contract = await EIP1271.deploy();
    
    await contract.deployed();
    console.log("EIP1271 deployed to:", contract.address);
    
    // Setup MultiSig (if needed)
    if (process.env.MULTISIG_ADDRESS) {
        await contract.grantRole(
            await contract.DEFAULT_ADMIN_ROLE(), 
            process.env.MULTISIG_ADDRESS
        );
        await contract.setMultiSigWallet(process.env.MULTISIG_ADDRESS);
        console.log("MultiSig configured:", process.env.MULTISIG_ADDRESS);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
```

이 예시들을 참조하여 프로젝트에 맞는 EIP-1271 구현을 개발할 수 있습니다.