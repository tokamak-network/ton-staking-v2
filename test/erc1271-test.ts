import { expect } from "chai";
import hre, { ethers } from "hardhat";
// import { Signer } from 'ethers'
import { DAOCommittee_V2, ERC1271Helper } from "../typechain-types";

// const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommittee_V2_ABI = require("../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;
const MultiSigWallet_ABI = require("../abi/MultiSigWallet.json");

describe("ERC-1271 Implementation", function () {
    let daoCommittee: any;
    let daoCommitteeContract: DAOCommittee_V2;
    let erc1271Helper: ERC1271Helper;
    let multiSigWallet: any;
    let owner1: any;
    let owner2: any;
    let owner3: any;
    let nonOwner: any;
    // let daoCommitteeProxy: any;
    let daoCommitteeProxy2Contract: any;
    let daoCommitteeAdmin: any;

    let daoCommitteeProxyAddr = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";   //sepolia
    let daoAdminAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";
    // let multiSigWalletAddr = "0x82460E7D90e19cF778a2C09DcA75Fc9f79Da877C";
    // let owner1Address = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";
    // let owner2Address = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";
    // let owner3Address = "0xc1eba383D94c6021160042491A5dfaF1d82694E6";

    let sendether = "0xDE0B6B3A7640000"

    const MAGICVALUE = "0x1626ba7e";
    const INVALID_SIGNATURE = "0xffffffff";
    const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";

    beforeEach(async function () {
        [owner1, owner2, owner3, nonOwner] = await ethers.getSigners();

        await hre.network.provider.send("hardhat_impersonateAccount", [
            daoAdminAddress,
        ]);
        daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

        await hre.network.provider.send("hardhat_setBalance", [
            daoAdminAddress,
            sendether
        ]);

        // await hre.network.provider.send("hardhat_impersonateAccount", [
        //     owner1Address,
        // ]);
        // owner1 = await hre.ethers.getSigner(owner1Address);

        // await hre.network.provider.send("hardhat_setBalance", [
        //     owner1Address,
        //     sendether
        // ]);

        // await hre.network.provider.send("hardhat_impersonateAccount", [
        //     owner2Address,
        // ]);
        // owner2 = await hre.ethers.getSigner(owner2Address);

        // await hre.network.provider.send("hardhat_setBalance", [
        //     owner2Address,
        //     sendether
        // ]);

        // await hre.network.provider.send("hardhat_impersonateAccount", [
        //     owner3Address,
        // ]);
        // owner3 = await hre.ethers.getSigner(owner3Address);

        // await hre.network.provider.send("hardhat_setBalance", [
        //     owner3Address,
        //     sendether
        // ]);

        // MultiSigWallet 새로 배포
        const MultiSigWalletFactory = await ethers.getContractFactory(
            MultiSigWallet_ABI.abi,
            MultiSigWallet_ABI.bytecode,
            daoCommitteeAdmin
        );
        
        // owners 배열과 필요한 확인 수 설정
        const testOwners = [owner1.address, owner2.address, owner3.address];
        multiSigWallet = await MultiSigWalletFactory.deploy(testOwners);
        await multiSigWallet.deployed();

        //==== Set Proxy2Contract =================================
        daoCommitteeProxy2Contract = new ethers.Contract(
            daoCommitteeProxyAddr,
            DAOProxy2ABI,
            ethers.provider
        )

        // DAOCommittee_V2 배포 
        const DAOCommittee = await ethers.getContractFactory("DAOCommittee_V2");
        daoCommitteeContract = (await DAOCommittee.deploy()) as DAOCommittee_V2;
        await daoCommitteeContract.deployed();

        // DAOCommitteeProxy2에 DAOCommittee_V2 업그레이드
        await daoCommitteeProxy2Contract.connect(daoCommitteeAdmin).upgradeTo2(daoCommitteeContract.address);
        //==== Set Proxy2Contract =================================
        daoCommittee = new ethers.Contract(
            daoCommitteeProxyAddr,
            DAOCommittee_V2_ABI,
            ethers.provider
        )

        // ERC1271Helper 배포
        const erc1271HelperFactory = await ethers.getContractFactory("ERC1271Helper");
        erc1271Helper = (await erc1271HelperFactory.deploy()) as ERC1271Helper;
        await erc1271Helper.deployed();

        await daoCommitteeProxy2Contract.connect(daoCommitteeAdmin).grantRole(
            DEFAULT_ADMIN_ROLE,
            multiSigWallet.address
        );

        // MultiSigWallet 주소 설정
        await daoCommittee.connect(daoCommitteeAdmin).setMultiSigWallet(multiSigWallet.address);
    });

    describe("daoCommittee ERC-1271 Basic Functionality", function () {
        it("should return correct magic values", async function () {
            const message = "Hello, ERC-1271!";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            const magicValue = await daoCommittee.isValidSignature(
                hash,
                "0x"
            );
            expect(magicValue).to.equal(INVALID_SIGNATURE);
        });

        it("should validate MultiSigWallet owner signatures", async function () {
            const message = "Hello, ERC-1271!";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // owner1의 서명 생성 (EIP-1271 표준: raw hash 서명)
            const signature1 = await owner1.signMessage(ethers.utils.arrayify(hash));

            let OwnerCheck = await multiSigWallet.isOwner(owner1.address)
            expect(OwnerCheck).to.equal(true);
            
            const result = await daoCommittee.isValidSignature(hash, signature1);
            expect(result).to.equal(MAGICVALUE);
        });

        it("should reject invalid signatures", async function () {
            const message = "Hello, ERC-1271!";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // nonOwner의 서명 (EIP-1271 표준: raw hash 서명)
            const signature = await nonOwner.signMessage(ethers.utils.arrayify(hash));
            
            const result = await daoCommittee.isValidSignature(hash, signature);
            expect(result).to.equal(INVALID_SIGNATURE);
        });
    });

    describe("ERC1271Helper", function () {
        it("should validate EOA signatures", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            const signature = await owner1.signMessage(ethers.utils.arrayify(hash));
            
            const isValid = await erc1271Helper.isValidSignature(owner1.address, hash, signature);
            expect(isValid).to.be.true;
        });

        it("should validate contract signatures via ERC-1271", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // MultiSigWallet owner들의 서명 (EIP-1271 표준: raw hash 서명)
            const signature1 = await owner1.signMessage(ethers.utils.arrayify(hash));
            
            const isValid = await erc1271Helper.isValidSignature(
                daoCommittee.address, 
                hash, 
                signature1
            );
            expect(isValid).to.be.true;
        });

        it("should recover signer address", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            const signature = await owner1.signMessage(ethers.utils.arrayify(hash));
            
            const recoveredSigner = await erc1271Helper.recoverSigner(hash, signature);
            expect(recoveredSigner).to.equal(owner1.address);
        });
    });

    describe("Security Tests", function () {
        it("should reject signatures with wrong hash", async function () {
            const message1 = "Message 1";
            const message2 = "Message 2";
            const hash1 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message1));
            const hash2 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message2));
            
            // message1에 대한 서명 생성
            const signature1 = await owner1.signMessage(ethers.utils.arrayify(hash1));
            
            // message1의 서명으로 message2의 해시 검증 시도
            const result = await daoCommittee.isValidSignature(hash2, signature1);
            expect(result).to.equal(INVALID_SIGNATURE);
        });

        it("should reject signatures from non-MultiSigWallet owners", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // nonOwner의 서명 (MultiSigWallet owner가 아님)
            const signature = await nonOwner.signMessage(ethers.utils.arrayify(hash));
            
            const result = await daoCommittee.isValidSignature(hash, signature);
            expect(result).to.equal(INVALID_SIGNATURE);
        });

        it("should reject invalid signature lengths", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // 잘못된 길이의 서명 (64바이트 - 1바이트 부족)
            const invalidSignature = "0x" + "00".repeat(64);
            
            const result = await daoCommittee.isValidSignature(hash, invalidSignature);
            expect(result).to.equal(INVALID_SIGNATURE);
        });

        it("should reject empty signatures", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            const result = await daoCommittee.isValidSignature(hash, "0x");
            expect(result).to.equal(INVALID_SIGNATURE);
        });

        it("should reject when multiSigWallet is not set", async function () {
            // 새로운 DAOCommittee 배포 (multiSigWallet 설정 안함)
            const DAOCommittee = await ethers.getContractFactory("DAOCommittee_V2");
            const testDaoCommittee = await DAOCommittee.deploy();
            await testDaoCommittee.deployed();
            
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            const signature = await owner1.signMessage(ethers.utils.arrayify(hash));
            
            const result = await testDaoCommittee.isValidSignature(hash, signature);
            expect(result).to.equal(INVALID_SIGNATURE);
        });

        it("should reject malformed signatures (invalid v value)", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // 올바른 서명 생성 후 v 값을 잘못된 값으로 변경
            const validSignature = await owner1.signMessage(ethers.utils.arrayify(hash));
            const sigBytes = ethers.utils.arrayify(validSignature);
            
            // v 값을 26으로 변경 (잘못된 값, 27 또는 28이어야 함)
            sigBytes[64] = 26;
            const invalidSignature = ethers.utils.hexlify(sigBytes);
            
            // revert가 발생해야 함
            await expect(
                daoCommittee.isValidSignature(hash, invalidSignature)
            ).to.be.revertedWith("Invalid signature 'v' value");
        });

        it("should handle signature malleability (high s values)", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // 올바른 서명 생성
            const validSignature = await owner1.signMessage(ethers.utils.arrayify(hash));
            const sigBytes = ethers.utils.arrayify(validSignature);
            
            // s 값을 높은 값으로 변경 (malleability 테스트)
            const highS = "0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1";
            const highSBytes = ethers.utils.arrayify(highS);
            
            for (let i = 0; i < 32; i++) {
                sigBytes[32 + i] = highSBytes[i];
            }
            
            const malleavleSignature = ethers.utils.hexlify(sigBytes);
            
            // revert가 발생해야 함
            await expect(
                daoCommittee.isValidSignature(hash, malleavleSignature)
            ).to.be.revertedWith("Invalid signature 's' value");
        });

        it("should accept multiple valid owner signatures", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // 여러 owner들의 서명 생성
            const signature1 = await owner1.signMessage(ethers.utils.arrayify(hash));
            const signature2 = await owner2.signMessage(ethers.utils.arrayify(hash));
            
            // 서명들을 연결
            const combinedSignature = signature1 + signature2.slice(2);
            
            const result = await daoCommittee.isValidSignature(hash, combinedSignature);
            expect(result).to.equal(MAGICVALUE);
        });

        it("should accept duplicate signatures (same result)", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // owner1의 서명을 두 번 연결 (중복)
            const signature1 = await owner1.signMessage(ethers.utils.arrayify(hash));
            const duplicateSignature = signature1 + signature1.slice(2);
            
            // 중복이지만 한 명의 유효한 owner 서명이므로 통과해야 함
            const result = await daoCommittee.isValidSignature(hash, duplicateSignature);
            expect(result).to.equal(MAGICVALUE);
        });
    });
}); 