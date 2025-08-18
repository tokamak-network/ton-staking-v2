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
        
        // console.log("MultiSigWallet deployed to:", multiSigWallet.address);
        // console.log("MultiSigWallet owners:", testOwners);

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
            
            // owner1의 서명 생성 (해시에 직접 서명)
            const signature1 = await owner1.signMessage(ethers.utils.arrayify(hash));

            let OwnerCheck = await multiSigWallet.isOwner(owner1.address)
            expect(OwnerCheck).to.equal(true);
            
            const result = await daoCommittee.isValidSignature(hash, signature1);
            expect(result).to.equal(MAGICVALUE);
        });

        // it("should reject invalid signatures", async function () {
        //     const message = "Hello, ERC-1271!";
        //     const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
        //     // nonOwner의 서명
        //     const signature = await nonOwner.signMessage(ethers.utils.toUtf8Bytes(message));
            
        //     const result = await daoCommittee.isValidSignature(hash, signature);
        //     expect(result).to.equal(INVALID_SIGNATURE);
        // });

        // it("should reject duplicate signatures", async function () {
        //     const message = "Hello, ERC-1271!";
        //     const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
        //     // owner1의 서명을 두 번 사용
        //     const signature1 = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
        //     const combinedSignature = signature1 + signature1.slice(2); // 같은 서명을 두 번
            
        //     const result = await daoCommittee.isValidSignature(hash, combinedSignature);
        //     expect(result).to.equal(INVALID_SIGNATURE);
        // });
    });

    // describe("ERC1271Helper", function () {
    //     it("should validate EOA signatures", async function () {
    //         const message = "Test message";
    //         const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
    //         const signature = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
            
    //         const isValid = await erc1271Helper.isValidSignature(owner1.address, hash, signature);
    //         expect(isValid).to.be.true;
    //     });

    //     it("should validate contract signatures via ERC-1271", async function () {
    //         const message = "Test message";
    //         const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
    //         // MultiSigWallet owner들의 서명
    //         const signature1 = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
    //         const signature2 = await owner2.signMessage(ethers.utils.toUtf8Bytes(message));
    //         const combinedSignature = signature1 + signature2.slice(2);
            
    //         const isValid = await erc1271Helper.isValidSignature(
    //             daoCommittee.address, 
    //             hash, 
    //             combinedSignature
    //         );
    //         expect(isValid).to.be.true;
    //     });

    //     it("should recover signer address", async function () {
    //         const message = "Test message";
    //         const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
    //         const signature = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
            
    //         const recoveredSigner = await erc1271Helper.recoverSigner(hash, signature);
    //         expect(recoveredSigner).to.equal(owner1.address);
    //     });
    // });

    // describe("MultiSigWallet Integration", function () {
    //     it("should work with actual MultiSigWallet confirmations", async function () {
    //         // MultiSigWallet에서 트랜잭션 제출
    //         const data = daoCommittee.interface.encodeFunctionData("setMultiSigWallet", [multiSigWallet.address]);
    //         await multiSigWallet.submitTransaction(daoCommittee.address, 0, data);
            
    //         // 트랜잭션 확인
    //         await multiSigWallet.confirmTransaction(0);
    //         await multiSigWallet.connect(owner2).confirmTransaction(0);
            
    //         // 트랜잭션 실행
    //         await multiSigWallet.executeTransaction(0);
            
    //         // 이제 ERC-1271 서명 검증이 작동해야 함
    //         const message = "Test after execution";
    //         const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
    //         const signature1 = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
    //         const signature2 = await owner2.signMessage(ethers.utils.toUtf8Bytes(message));
    //         const combinedSignature = signature1 + signature2.slice(2);
            
    //         const result = await daoCommittee.isValidSignature(hash, combinedSignature);
    //         expect(result).to.equal(MAGICVALUE);
    //     });
    // });

    // describe("Security Tests", function () {
    //     it("should reject signatures with wrong hash", async function () {
    //         const message1 = "Message 1";
    //         const message2 = "Message 2";
    //         const hash1 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message1));
    //         const hash2 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message2));
            
    //         const signature1 = await owner1.signMessage(ethers.utils.toUtf8Bytes(message1));
    //         const signature2 = await owner2.signMessage(ethers.utils.toUtf8Bytes(message1));
    //         const combinedSignature = signature1 + signature2.slice(2);
            
    //         // message1의 서명으로 message2의 해시 검증
    //         const result = await daoCommittee.isValidSignature(hash2, combinedSignature);
    //         expect(result).to.equal(INVALID_SIGNATURE);
    //     });

    //     it("should handle insufficient signatures", async function () {
    //         const message = "Test message";
    //         const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
            
    //         // owner1만 서명
    //         const signature = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
            
    //         const result = await daoCommittee.isValidSignature(hash, signature);
    //         expect(result).to.equal(INVALID_SIGNATURE);
    //     });
    // });
}); 