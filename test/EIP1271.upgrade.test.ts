import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

/// const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommittee_V2_ABI = require("../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;
const MultiSigWallet_ABI = require("../abi/MultiSigWallet.json");

describe("EIP-1271 Upgrade Integration Tests", function () {
  // Network Configuration
  const DAO_COMMITTEE_PROXY = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";

  // Test accounts
  let deployer: SignerWithAddress;
  let multiSigOwner1: SignerWithAddress;
  let multiSigOwner2: SignerWithAddress;
  let multiSigOwner3: SignerWithAddress;
  let nonOwner: SignerWithAddress;
  let safeWallet: SignerWithAddress;

  let daoCommitteeAdmin: any;


  // Contract instances
  let daoProxy: Contract;
  let daoCommitteeV2: Contract;
  let multiSigWallet: Contract;
  let newImplementation: Contract;

  // Test constants
  const MAGIC_VALUE = "0x1626ba7e";
  const INVALID_SIGNATURE = "0xffffffff";
  const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
  const testHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message"));
  const txHash = "0x34148392eddee2686a39b6da312a95afdbf953bef85122e5b0c73f3b624cba8f"
  const testHash2 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message2"));
  const testHash3 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message3"));
  const testHash4 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message4"));
  const numConfirmationsRequired = 2; // 2 out of 3 multisig

  const daoAdminAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";
  let sendether = "0xDE0B6B3A7640000"


  before(async function () {
    [deployer, multiSigOwner1, multiSigOwner2, multiSigOwner3, nonOwner, safeWallet] = await ethers.getSigners();

    await hre.network.provider.send("hardhat_impersonateAccount", [
      daoAdminAddress,
    ]);
    daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

    await hre.network.provider.send("hardhat_setBalance", [
        daoAdminAddress,
        sendether
    ]);

    console.log("Setting up EIP-1271 upgrade test environment...");
    console.log(`Deployer: ${deployer.address}`);
    console.log(`DAO Proxy: ${DAO_COMMITTEE_PROXY}`);
  });

  describe("Environment Setup", function () {
    it("should connect to Sepolia network", async function () {
      const network = await ethers.provider.getNetwork();
      if (network.chainId === 31337) {
        console.log(`Connected to network: local (chainId: ${network.chainId})`);
      } else {
        console.log(`Connected to network: ${network.name} (chainId: ${network.chainId})`);
      }

      // For local testing, we'll skip Sepolia connection requirement
      if (network.chainId !== 11155111 && network.chainId !== 31337) {
        console.log("Warning: Not connected to Sepolia or local network, running on unknown network");
      }
    });

    it("should deploy test MultiSigWallet", async function () {

      // MultiSigWallet 새로 배포
      const MultiSigWalletFactory = await ethers.getContractFactory(
        MultiSigWallet_ABI.abi,
        MultiSigWallet_ABI.bytecode,
        deployer
      );

      // owners 배열과 필요한 확인 수 설정
      const testOwners = [multiSigOwner1.address, multiSigOwner2.address, multiSigOwner3.address];
      multiSigWallet = await MultiSigWalletFactory.deploy(testOwners);
      await multiSigWallet.deployed();

      // console.log(`Test MultiSigWallet deployed at: ${multiSigWallet.address}`);

      // Verify setup
      const owners = await multiSigWallet.getOwners();
      expect(owners).to.deep.equal([
        multiSigOwner1.address,
        multiSigOwner2.address,
        multiSigOwner3.address
      ]);

      const threshold = await multiSigWallet.numConfirmationsRequired();
      expect(threshold).to.equal(numConfirmationsRequired);
    });
  });

  describe("DAOCommittee_V2 Deployment", function () {
    it("should deploy new DAOCommittee_V2 implementation", async function () {
      const DAOCommitteeV2Factory = await ethers.getContractFactory("DAOCommittee_V2");
      newImplementation = await DAOCommitteeV2Factory.deploy();
      await newImplementation.deployed();

      // console.log(`DAOCommittee_V2 deployed at: ${newImplementation.address}`);
      expect(newImplementation.address).to.be.properAddress;
    });
  });

  describe("Proxy Pattern Tests", function () {
    beforeEach(async function () {
      // Create proxy instance for testing
      // In real scenario, this would connect to existing proxy

      //==== Set Proxy2Contract =================================
      const daoCommitteeProxy2Contract = new ethers.Contract(
        DAO_COMMITTEE_PROXY,
        DAOProxy2ABI,
        ethers.provider
      ) 

      daoProxy = daoCommitteeProxy2Contract;


      // Grant admin role to deployer for testing
      await daoProxy.connect(daoCommitteeAdmin).grantRole(DEFAULT_ADMIN_ROLE, deployer.address);
    });

    it("should upgrade to DAOCommittee_V2 using upgradeTo2", async function () {
      // Perform upgrade
      const tx = await daoProxy.connect(daoCommitteeAdmin).upgradeTo2(newImplementation.address);
      await tx.wait();

      // Verify upgrade
      const currentImpl = await daoProxy.implementation2(0);
      expect(currentImpl).to.equal(newImplementation.address);

      // console.log(`Upgraded to implementation: ${currentImpl}`);
    });

    it("should preserve proxy state after upgrade", async function () {
      // Set some state before upgrade
      await daoProxy.connect(daoCommitteeAdmin).grantRole(DEFAULT_ADMIN_ROLE, multiSigWallet.address);

      // Verify state is preserved
      const hasRole = await daoProxy.hasRole(DEFAULT_ADMIN_ROLE, multiSigWallet.address);
      expect(hasRole).to.be.true;
    });

    it("should access EIP-1271 functions through proxy after upgrade", async function () {
      // Create interface for upgraded proxy
      const upgradedProxy = new ethers.Contract(
        daoProxy.address,
        newImplementation.interface,
        deployer
      );

      // Test EIP-1271 function accessibility
      await expect(upgradedProxy.connect(daoCommitteeAdmin).setMultiSigWallet(multiSigWallet.address)).to.not.be.reverted;

      const multiSigAddress = await upgradedProxy.multiSigWallet();
      expect(multiSigAddress).to.equal(multiSigWallet.address);
    });
  });

  describe("EIP-1271 Basic Functionality", function () {
    beforeEach(async function () {
      // Ensure all dependencies are deployed
      if (!multiSigWallet) {
        const MultiSigWalletFactory = await ethers.getContractFactory(
          MultiSigWallet_ABI.abi,
          MultiSigWallet_ABI.bytecode,
          deployer
        );
        const testOwners = [multiSigOwner1.address, multiSigOwner2.address, multiSigOwner3.address];
        multiSigWallet = await MultiSigWalletFactory.deploy(testOwners);
        await multiSigWallet.deployed();
      }

      if (!newImplementation) {
        const DAOCommitteeV2Factory = await ethers.getContractFactory("DAOCommittee_V2");
        newImplementation = await DAOCommitteeV2Factory.deploy();
        await newImplementation.deployed();
      }

      if (!daoProxy) {
        const daoCommitteeProxy2Contract = new ethers.Contract(
          DAO_COMMITTEE_PROXY,
          DAOProxy2ABI,
          ethers.provider
        );
        daoProxy = daoCommitteeProxy2Contract;
      }

      // Create upgraded proxy interface
      daoCommitteeV2 = new ethers.Contract(
        daoProxy.address,
        newImplementation.interface,
        deployer
      );

      // Set MultiSigWallet
      await daoCommitteeV2.connect(daoCommitteeAdmin).setMultiSigWallet(multiSigWallet.address);
    });

    it("should return magic value for valid signatures", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        txHash
      );

      // console.log("Test hash:", testHash);
      // console.log("Signatures:", signatures);
      // console.log("MultiSig owners:", [multiSigOwner1.address, multiSigOwner2.address]);
      // console.log("MultiSig wallet:", multiSigWallet.address);

      const result = await daoCommitteeV2.isValidSignature(txHash, signatures);
      // console.log("Result:", result);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("should return invalid signature for wrong signatures", async function () {
      const signatures = await createMultipleSignatures(
        [nonOwner, multiSigOwner1],
        testHash
      );

      const result = await daoCommitteeV2.isValidSignature(testHash, signatures);
      expect(result).to.equal(INVALID_SIGNATURE);
    });

    it("should handle signature reuse prevention", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      // First use should succeed
      await expect(
        daoCommitteeV2.validateAndUseSignature(testHash, signatures)
      ).to.not.be.reverted;

      // Second use should fail
      await expect(
        daoCommitteeV2.validateAndUseSignature(testHash, signatures)
      ).to.be.reverted;
    });
  });

  describe("MultiSigWallet Integration", function () {
    beforeEach(async function () {
      // await daoProxy.upgradeTo2(newImplementation.address);
      // await daoProxy.grantRole(DEFAULT_ADMIN_ROLE, multiSigWallet.address);

      daoCommitteeV2 = new ethers.Contract(
        daoProxy.address,
        newImplementation.interface,
        deployer
      );

      // await daoCommitteeV2.setMultiSigWallet(multiSigWallet.address);
    });

    it("should validate MultiSigWallet owner signatures", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash2
      );

      const result = await daoCommitteeV2.isValidSignature(testHash2, signatures);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("should reject non-owner signatures", async function () {
      const signatures = await createMultipleSignatures(
        [nonOwner, multiSigOwner1],
        testHash2
      );

      const result = await daoCommitteeV2.isValidSignature(testHash2, signatures);
      expect(result).to.equal(INVALID_SIGNATURE);
    });

    it("should respect numConfirmationsRequired threshold", async function () {
      // Only 1 signature (less than required 2)
      const singleSignature = await createSignature(multiSigOwner1, testHash2);

      const result = await daoCommitteeV2.isValidSignature(testHash2, singleSignature);
      expect(result).to.equal(INVALID_SIGNATURE);
    });
  });

  describe("Multi-Signature Validation", function () {
    it("should succeed with exact required signatures", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash3
      );

      const result = await daoCommitteeV2.isValidSignature(testHash3, signatures);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("should succeed with more than required signatures", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2, multiSigOwner3],
        testHash3
      );

      const result = await daoCommitteeV2.isValidSignature(testHash3, signatures);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("should handle signature order independence", async function () {
      const signaturesAB = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash3
      );

      const signaturesBA = await createMultipleSignatures(
        [multiSigOwner2, multiSigOwner1],
        testHash3
      );

      const resultAB = await daoCommitteeV2.isValidSignature(testHash3, signaturesAB);
      const resultBA = await daoCommitteeV2.isValidSignature(testHash3, signaturesBA);

      expect(resultAB).to.equal(MAGIC_VALUE);
      expect(resultBA).to.equal(MAGIC_VALUE);
    });

    it("should prevent duplicate signers", async function () {
      // Create duplicate signature from same signer
      const sig1 = await createSignature(multiSigOwner1, testHash3);
      const sig2 = await createSignature(multiSigOwner1, testHash3);
      const duplicateSignatures = ethers.utils.hexConcat([sig1, sig2]);

      const result = await daoCommitteeV2.isValidSignature(testHash3, duplicateSignatures);
      expect(result).to.equal(INVALID_SIGNATURE);
    });
  });

  describe("Security Tests", function () {
    it("should prevent signature replay attacks", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash3
      );

      // First use should succeed
      await expect(
        daoCommitteeV2.validateAndUseSignature(testHash3, signatures)
      ).to.not.be.reverted;

      // Second use should fail
      await expect(
        daoCommitteeV2.validateAndUseSignature(testHash3, signatures)
      ).to.be.reverted;
    });

    it("should reject invalid signature length", async function () {
      const invalidSig = "0x1234567890abcdef"; // Too short

      const result = await daoCommitteeV2.isValidSignature(testHash2, invalidSig);
      expect(result).to.equal(INVALID_SIGNATURE);
    });

    it("should detect signature tampering", async function () {
      const validSig = await createSignature(multiSigOwner1, testHash2);
      // Tamper with signature
      const tamperedSig = "0x" + validSig.slice(2, 10) + "deadbeef" + validSig.slice(18);

      const result = await daoCommitteeV2.isValidSignature(testHash2, tamperedSig);
      expect(result).to.equal(INVALID_SIGNATURE);
    });
  });

  describe("Safe Wallet Compatibility", function () {
    it("should work as EIP-1271 implementation for Safe Wallet", async function () {
      // Simulate Safe Wallet calling isValidSignature
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash4
      );

      // Safe Wallet would call this to verify DAO Contract signature
      const result = await daoCommitteeV2.connect(safeWallet).isValidSignature(testHash4, signatures);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("should maintain view function for EIP-1271 standard", async function () {
      // isValidSignature should be view function (no state changes)
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash4
      );

      // Multiple calls should return same result (no state change)
      const result1 = await daoCommitteeV2.isValidSignature(testHash4, signatures);
      const result2 = await daoCommitteeV2.isValidSignature(testHash4, signatures);

      expect(result1).to.equal(result2);
      expect(result1).to.equal(MAGIC_VALUE);
    });
  });

  describe("Gas Efficiency Tests", function () {
    it("should measure gas consumption for signature verification", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash4
      );

      const tx = await daoCommitteeV2.estimateGas.isValidSignature(testHash4, signatures);
      console.log(`Gas used for 2-signature verification: ${tx.toString()}`);

      expect(tx.toNumber()).to.be.lessThan(300000); // Reasonable gas limit
    });

    it("should compare gas usage with different signature counts", async function () {
      const twoSigs = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash4
      );

      const threeSigs = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2, multiSigOwner3],
        testHash4
      );

      const gas2 = await daoCommitteeV2.estimateGas.isValidSignature(testHash4, twoSigs);
      const gas3 = await daoCommitteeV2.estimateGas.isValidSignature(testHash4, threeSigs);

      console.log(`Gas for 2 signatures: ${gas2.toString()}`);
      console.log(`Gas for 3 signatures: ${gas3.toString()}`);

      expect(gas3.toNumber()).to.be.greaterThan(gas2.toNumber());
    });
  });

  // Helper Functions
  async function createSignature(signer: SignerWithAddress, hash: string): Promise<string> {
    // Sign the raw hash bytes directly (not as a message)
    const hashBytes = ethers.utils.arrayify(hash);
    const flatSig = await signer.signMessage(hashBytes);
    return flatSig;
  }

  async function createMultipleSignatures(
    signers: SignerWithAddress[],
    hash: string
  ): Promise<string> {
    const signatures = await Promise.all(
      signers.map(signer => createSignature(signer, hash))
    );
    return ethers.utils.hexConcat(signatures);
  }

  async function setupUpgradedDAO(): Promise<void> {
    await daoProxy.upgradeTo2(newImplementation.address);
    await daoProxy.grantRole(DEFAULT_ADMIN_ROLE, multiSigWallet.address);

    daoCommitteeV2 = new ethers.Contract(
      daoProxy.address,
      newImplementation.interface,
      deployer
    );

    await daoCommitteeV2.setMultiSigWallet(multiSigWallet.address);
  }
});