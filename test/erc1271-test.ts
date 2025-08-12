import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@ethersproject/contracts";
import { DAOCommittee_V2, ERC1271Helper } from "../typechain-types";

describe("ERC-1271 Implementation", function () {
    let daoCommittee: DAOCommittee_V2;
    let erc1271Helper: ERC1271Helper;
    let multiSigWallet: any;
    let owner1: SignerWithAddress;
    let owner2: SignerWithAddress;
    let owner3: SignerWithAddress;
    let nonOwner: SignerWithAddress;

    const MAGICVALUE = "0x1626ba7e";
    const INVALID_SIGNATURE = "0xffffffff";

    beforeEach(async function () {
        [owner1, owner2, owner3, nonOwner] = await ethers.getSigners();

        // MultiSigWallet 배포 (간단한 버전)
        const MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
        multiSigWallet = await MultiSigWallet.deploy([owner1.address, owner2.address, owner3.address]);
        await multiSigWallet.deployed();

        // DAOCommittee_V2 배포
        const DAOCommittee = await ethers.getContractFactory("DAOCommittee_V2");
        daoCommittee = await DAOCommittee.deploy();
        await daoCommittee.deployed();

        // ERC1271Helper 배포
        const ERC1271Helper = await ethers.getContractFactory("ERC1271Helper");
        erc1271Helper = await ERC1271Helper.deploy();
        await erc1271Helper.deployed();

        // MultiSigWallet 주소 설정
        await daoCommittee.setMultiSigWallet(multiSigWallet.address);
    });

    describe("ERC-1271 Basic Functionality", function () {
        it("should return correct magic values", async function () {
            const magicValue = await daoCommittee.isValidSignature(
                ethers.utils.keccak256("test"),
                "0x"
            );
            expect(magicValue).to.equal(INVALID_SIGNATURE);
        });

        it("should validate MultiSigWallet owner signatures", async function () {
            const message = "Hello, ERC-1271!";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // MultiSigWallet의 required confirmations 가져오기
            const requiredConfirmations = await multiSigWallet.numConfirmationsRequired();
            
            // owner1과 owner2의 서명 생성
            const signature1 = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
            const signature2 = await owner2.signMessage(ethers.utils.toUtf8Bytes(message));
            
            // 서명들을 연결
            const combinedSignature = signature1 + signature2.slice(2); // 0x 제거하고 연결
            
            const result = await daoCommittee.isValidSignature(hash, combinedSignature);
            expect(result).to.equal(MAGICVALUE);
        });

        it("should reject invalid signatures", async function () {
            const message = "Hello, ERC-1271!";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // nonOwner의 서명
            const signature = await nonOwner.signMessage(ethers.utils.toUtf8Bytes(message));
            
            const result = await daoCommittee.isValidSignature(hash, signature);
            expect(result).to.equal(INVALID_SIGNATURE);
        });

        it("should reject duplicate signatures", async function () {
            const message = "Hello, ERC-1271!";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // owner1의 서명을 두 번 사용
            const signature1 = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
            const combinedSignature = signature1 + signature1.slice(2); // 같은 서명을 두 번
            
            const result = await daoCommittee.isValidSignature(hash, combinedSignature);
            expect(result).to.equal(INVALID_SIGNATURE);
        });
    });

    describe("ERC1271Helper", function () {
        it("should validate EOA signatures", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            const signature = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
            
            const isValid = await erc1271Helper.isValidSignature(owner1.address, hash, signature);
            expect(isValid).to.be.true;
        });

        it("should validate contract signatures via ERC-1271", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // MultiSigWallet owner들의 서명
            const signature1 = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
            const signature2 = await owner2.signMessage(ethers.utils.toUtf8Bytes(message));
            const combinedSignature = signature1 + signature2.slice(2);
            
            const isValid = await erc1271Helper.isValidSignature(
                daoCommittee.address, 
                hash, 
                combinedSignature
            );
            expect(isValid).to.be.true;
        });

        it("should recover signer address", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            const signature = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
            
            const recoveredSigner = await erc1271Helper.recoverSigner(hash, signature);
            expect(recoveredSigner).to.equal(owner1.address);
        });
    });

    describe("MultiSigWallet Integration", function () {
        it("should work with actual MultiSigWallet confirmations", async function () {
            // MultiSigWallet에서 트랜잭션 제출
            const data = daoCommittee.interface.encodeFunctionData("setMultiSigWallet", [multiSigWallet.address]);
            await multiSigWallet.submitTransaction(daoCommittee.address, 0, data);
            
            // 트랜잭션 확인
            await multiSigWallet.confirmTransaction(0);
            await multiSigWallet.connect(owner2).confirmTransaction(0);
            
            // 트랜잭션 실행
            await multiSigWallet.executeTransaction(0);
            
            // 이제 ERC-1271 서명 검증이 작동해야 함
            const message = "Test after execution";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            const signature1 = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
            const signature2 = await owner2.signMessage(ethers.utils.toUtf8Bytes(message));
            const combinedSignature = signature1 + signature2.slice(2);
            
            const result = await daoCommittee.isValidSignature(hash, combinedSignature);
            expect(result).to.equal(MAGICVALUE);
        });
    });

    describe("Security Tests", function () {
        it("should reject signatures with wrong hash", async function () {
            const message1 = "Message 1";
            const message2 = "Message 2";
            const hash1 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message1));
            const hash2 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message2));
            
            const signature1 = await owner1.signMessage(ethers.utils.toUtf8Bytes(message1));
            const signature2 = await owner2.signMessage(ethers.utils.toUtf8Bytes(message1));
            const combinedSignature = signature1 + signature2.slice(2);
            
            // message1의 서명으로 message2의 해시 검증
            const result = await daoCommittee.isValidSignature(hash2, combinedSignature);
            expect(result).to.equal(INVALID_SIGNATURE);
        });

        it("should handle insufficient signatures", async function () {
            const message = "Test message";
            const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
            // owner1만 서명
            const signature = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
            
            const result = await daoCommittee.isValidSignature(hash, signature);
            expect(result).to.equal(INVALID_SIGNATURE);
        });
    });
}); 