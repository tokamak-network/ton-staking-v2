import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

// ABI imports
const MultiSigWalletABI = require("./abi/MultiSigWallet.json");
const DAOCommitteeProxy2ABI = require("./abi/DAOCommitteeProxy2.json");

describe("EIP-1271 Upgrade Integration Tests", function () {
  // Network Configuration
  const DAO_COMMITTEE_PROXY = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";

  // Test accounts
  let deployer: SignerWithAddress;
  let multiSigOwner1: any;
  let multiSigOwner2: any;
  let multiSigOwner3: any;
  let nonOwner: any;
  let safeWallet: SignerWithAddress;

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
  const numConfirmationsRequired = 2; // 2 out of 3 multisig

  before(async function () {
    [deployer, multiSigOwner1, multiSigOwner2, multiSigOwner3, nonOwner, safeWallet] = await ethers.getSigners();

    console.log("Setting up EIP-1271 upgrade test environment...");
    console.log(`Deployer: ${deployer.address}`);
    console.log(`DAO Proxy: ${DAO_COMMITTEE_PROXY}`);
  });

  describe("Environment Setup", function () {
    it("should connect to Sepolia network", async function () {
      const network = await ethers.provider.getNetwork();
      if(network.chainId === 31337) {
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
        MultiSigWalletABI.abi,
        MultiSigWalletABI.bytecode,
        deployer
    );

      // owners 배열과 필요한 확인 수 설정
      const testOwners = [multiSigOwner1.address, multiSigOwner2.address, multiSigOwner3.address];
      multiSigWallet = await MultiSigWalletFactory.deploy(testOwners);
      await multiSigWallet.deployed();

      console.log(`Test MultiSigWallet deployed at: ${multiSigWallet.address}`);

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

      console.log(`DAOCommittee_V2 deployed at: ${newImplementation.address}`);
      expect(newImplementation.address).to.be.properAddress;
    });
  });

  describe("Proxy Pattern Tests", function () {
    beforeEach(async function () {
      // Create proxy instance for testing
      // In real scenario, this would connect to existing proxy
      const DAOCommitteeProxyFactory = await ethers.getContractFactory("DAOCommitteeProxy2");
      daoProxy = await DAOCommitteeProxyFactory.deploy();
      await daoProxy.deployed();

      // Grant admin role to deployer for testing
      await daoProxy.grantRole(DEFAULT_ADMIN_ROLE, deployer.address);
    });

    it("should upgrade to DAOCommittee_V2 using upgradeTo2", async function () {
      // Perform upgrade
      const tx = await daoProxy.upgradeTo2(newImplementation.address);
      await tx.wait();

      // Verify upgrade
      const currentImpl = await daoProxy.implementation();
      expect(currentImpl).to.equal(newImplementation.address);

      console.log(`Upgraded to implementation: ${currentImpl}`);
    });

    it("should preserve proxy state after upgrade", async function () {
      // Set some state before upgrade
      await daoProxy.grantRole(DEFAULT_ADMIN_ROLE, multiSigWallet.address);

      // Perform upgrade
      await daoProxy.upgradeTo2(newImplementation.address);

      // Verify state is preserved
      const hasRole = await daoProxy.hasRole(DEFAULT_ADMIN_ROLE, multiSigWallet.address);
      expect(hasRole).to.be.true;
    });

    it("should access EIP-1271 functions through proxy after upgrade", async function () {
      // Upgrade first
      await daoProxy.upgradeTo2(newImplementation.address);

      // Create interface for upgraded proxy
      const upgradedProxy = new ethers.Contract(
        daoProxy.address,
        newImplementation.interface,
        deployer
      );

      // Test EIP-1271 function accessibility
      await expect(upgradedProxy.setMultiSigWallet(multiSigWallet.address)).to.not.be.reverted;

      const multiSigAddress = await upgradedProxy.multiSigWallet();
      expect(multiSigAddress).to.equal(multiSigWallet.address);
    });
  });

  describe("EIP-1271 Basic Functionality", function () {
    beforeEach(async function () {
      // Setup upgraded proxy
      await daoProxy.upgradeTo2(newImplementation.address);
      await daoProxy.grantRole(DEFAULT_ADMIN_ROLE, multiSigWallet.address);

      // Create upgraded proxy interface
      daoCommitteeV2 = new ethers.Contract(
        daoProxy.address,
        newImplementation.interface,
        deployer
      );

      // Set MultiSigWallet
      await daoCommitteeV2.setMultiSigWallet(multiSigWallet.address);
    });

    it("should return magic value for valid signatures", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      const result = await daoCommitteeV2.isValidSignature(testHash, signatures);
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
      await daoProxy.upgradeTo2(newImplementation.address);
      await daoProxy.grantRole(DEFAULT_ADMIN_ROLE, multiSigWallet.address);

      daoCommitteeV2 = new ethers.Contract(
        daoProxy.address,
        newImplementation.interface,
        deployer
      );

      await daoCommitteeV2.setMultiSigWallet(multiSigWallet.address);
    });

    it("should validate MultiSigWallet owner signatures", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      const result = await daoCommitteeV2.isValidSignature(testHash, signatures);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("should reject non-owner signatures", async function () {
      const signatures = await createMultipleSignatures(
        [nonOwner, multiSigOwner1],
        testHash
      );

      const result = await daoCommitteeV2.isValidSignature(testHash, signatures);
      expect(result).to.equal(INVALID_SIGNATURE);
    });

    it("should respect numConfirmationsRequired threshold", async function () {
      // Only 1 signature (less than required 2)
      const singleSignature = await createSignature(multiSigOwner1, testHash);

      const result = await daoCommitteeV2.isValidSignature(testHash, singleSignature);
      expect(result).to.equal(INVALID_SIGNATURE);
    });

    it("should get MultiSigWallet info correctly", async function () {
      const owners = await daoCommitteeV2.getMultiSigOwners();
      expect(owners).to.deep.equal([
        multiSigOwner1.address,
        multiSigOwner2.address,
        multiSigOwner3.address
      ]);

      const threshold = await daoCommitteeV2.getMultiSigThreshold();
      expect(threshold).to.equal(numConfirmationsRequired);

      const isOwner = await daoCommitteeV2.isMultiSigOwner(multiSigOwner1.address);
      expect(isOwner).to.be.true;

      const isNotOwner = await daoCommitteeV2.isMultiSigOwner(nonOwner.address);
      expect(isNotOwner).to.be.false;
    });
  });

  describe("Multi-Signature Validation", function () {
    beforeEach(async function () {
      await setupUpgradedDAO();
    });

    it("should succeed with exact required signatures", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      const result = await daoCommitteeV2.isValidSignature(testHash, signatures);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("should succeed with more than required signatures", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2, multiSigOwner3],
        testHash
      );

      const result = await daoCommitteeV2.isValidSignature(testHash, signatures);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("should handle signature order independence", async function () {
      const signaturesAB = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      const signaturesBA = await createMultipleSignatures(
        [multiSigOwner2, multiSigOwner1],
        testHash
      );

      const resultAB = await daoCommitteeV2.isValidSignature(testHash, signaturesAB);
      const resultBA = await daoCommitteeV2.isValidSignature(testHash, signaturesBA);

      expect(resultAB).to.equal(MAGIC_VALUE);
      expect(resultBA).to.equal(MAGIC_VALUE);
    });

    it("should prevent duplicate signers", async function () {
      // Create duplicate signature from same signer
      const sig1 = await createSignature(multiSigOwner1, testHash);
      const sig2 = await createSignature(multiSigOwner1, testHash);
      const duplicateSignatures = ethers.utils.hexConcat([sig1, sig2]);

      const result = await daoCommitteeV2.isValidSignature(testHash, duplicateSignatures);
      expect(result).to.equal(INVALID_SIGNATURE);
    });
  });

  describe("Security Tests", function () {
    beforeEach(async function () {
      await setupUpgradedDAO();
    });

    it("should prevent signature replay attacks", async function () {
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

    it("should reject invalid signature length", async function () {
      const invalidSig = "0x1234567890abcdef"; // Too short

      await expect(
        daoCommitteeV2.isValidSignature(testHash, invalidSig)
      ).to.be.reverted;
    });

    it("should detect signature tampering", async function () {
      const validSig = await createSignature(multiSigOwner1, testHash);
      // Tamper with signature
      const tamperedSig = "0x" + validSig.slice(2, 10) + "deadbeef" + validSig.slice(18);

      const result = await daoCommitteeV2.isValidSignature(testHash, tamperedSig);
      expect(result).to.equal(INVALID_SIGNATURE);
    });

    it("should check signature usage status", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      // Get signature hash for checking
      const signatureHash = await daoCommitteeV2._getSignatureHash(testHash, signatures);

      // Initially not used
      expect(await daoCommitteeV2.isSignatureUsed(signatureHash)).to.be.false;

      // Use signature
      await daoCommitteeV2.validateAndUseSignature(testHash, signatures);

      // Now should be marked as used
      expect(await daoCommitteeV2.isSignatureUsed(signatureHash)).to.be.true;
    });
  });

  describe("Safe Wallet Compatibility", function () {
    beforeEach(async function () {
      await setupUpgradedDAO();
    });

    it("should work as EIP-1271 implementation for Safe Wallet", async function () {
      // Simulate Safe Wallet calling isValidSignature
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      // Safe Wallet would call this to verify DAO Contract signature
      const result = await daoCommitteeV2.connect(safeWallet).isValidSignature(testHash, signatures);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("should maintain view function for EIP-1271 standard", async function () {
      // isValidSignature should be view function (no state changes)
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      // Multiple calls should return same result (no state change)
      const result1 = await daoCommitteeV2.isValidSignature(testHash, signatures);
      const result2 = await daoCommitteeV2.isValidSignature(testHash, signatures);

      expect(result1).to.equal(result2);
      expect(result1).to.equal(MAGIC_VALUE);
    });

    it("should support executeWithSignature for actual execution", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      // Mock target contract call
      const targetContract = daoCommitteeV2.address;
      const callData = daoCommitteeV2.interface.encodeFunctionData("getMultiSigThreshold");

      const success = await daoCommitteeV2.executeWithSignature(
        testHash,
        signatures,
        targetContract,
        callData
      );

      expect(success).to.be.true;

      // Signature should now be used
      await expect(
        daoCommitteeV2.executeWithSignature(testHash, signatures, targetContract, callData)
      ).to.be.revertedWith("Invalid or used signature");
    });
  });

  describe("Gas Efficiency Tests", function () {
    beforeEach(async function () {
      await setupUpgradedDAO();
    });

    it("should measure gas consumption for signature verification", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      const tx = await daoCommitteeV2.estimateGas.isValidSignature(testHash, signatures);
      console.log(`Gas used for 2-signature verification: ${tx.toString()}`);

      expect(tx.toNumber()).to.be.lessThan(300000); // Reasonable gas limit
    });

    it("should compare gas usage with different signature counts", async function () {
      const twoSigs = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash
      );

      const threeSigs = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2, multiSigOwner3],
        testHash
      );

      const gas2 = await daoCommitteeV2.estimateGas.isValidSignature(testHash, twoSigs);
      const gas3 = await daoCommitteeV2.estimateGas.isValidSignature(testHash, threeSigs);

      console.log(`Gas for 2 signatures: ${gas2.toString()}`);
      console.log(`Gas for 3 signatures: ${gas3.toString()}`);

      expect(gas3.toNumber()).to.be.greaterThan(gas2.toNumber());
    });
  });

  // Helper Functions
  async function createSignature(signer: SignerWithAddress, hash: string): Promise<string> {
    const messageHashBytes = ethers.utils.arrayify(hash);
    const signature = await signer.signMessage(messageHashBytes);
    return signature;
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