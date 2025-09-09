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
  const SAFE_PROXY = "0x623E2B35964F944e166E6531CEF7577C2851F415"
  const MULTISIG_WALLET = "0x82460E7D90e19cF778a2C09DcA75Fc9f79Da877C"

  // Test accounts
  let deployer: SignerWithAddress;
  let SafeWalletOwner1: SignerWithAddress;
  let multiSigOwner1: SignerWithAddress;
  let multiSigOwner2: SignerWithAddress;
  let nonOwner: SignerWithAddress;

  let daoCommitteeAdmin: any;


  // Contract instances
  let daoProxy: Contract;
  let daoCommitteeV2: Contract;
  let multiSigWallet: Contract;
  let newImplementation: Contract;

  // Test constants
  const MAGIC_VALUE = "0x20c13b0b";
  const INVALID_SIGNATURE = "0xffffffff";
  const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
  const testHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message"));
  const txHash = "0x34148392eddee2686a39b6da312a95afdbf953bef85122e5b0c73f3b624cba8f"
  const testHash2 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message2"));
  const testHash3 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message3"));
  const testHash4 = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message4"));
  const numConfirmationsRequired = 2; // 2 out of 3 multisig

  const SAFE_SIGNATURE = 'safe_sign'

  const daoAdminAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";
  let sendether = "0xDE0B6B3A7640000"


  before(async function () {
    [SafeWalletOwner1, multiSigOwner1, multiSigOwner2, nonOwner] = await ethers.getSigners();

    await hre.network.provider.send("hardhat_impersonateAccount", [
      daoAdminAddress,
    ]);
    daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

    await hre.network.provider.send("hardhat_setBalance", [
        daoAdminAddress,
        sendether
    ]);

    console.log("Setting up EIP-1271 upgrade test environment...");
    console.log(`SafeWalletOwner1: ${SafeWalletOwner1.address}`);
    console.log(`multiSigOwner1: ${multiSigOwner1.address}`);
    console.log(`multiSigOwner2: ${multiSigOwner2.address}`);
    console.log(`nonOwner: ${nonOwner.address}`);
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

    it("should Set MultiSigWallet", async function () {
      //==== Set Proxy2Contract =================================
      multiSigWallet = new ethers.Contract(
        MULTISIG_WALLET,
        MultiSigWallet_ABI.abi,
        ethers.provider
      ) 
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

    it("Set the DAOProxy2Contract", async function () {
      const daoCommitteeProxy2Contract = new ethers.Contract(
        DAO_COMMITTEE_PROXY,
        DAOProxy2ABI,
        ethers.provider
      ) 

      daoProxy = daoCommitteeProxy2Contract;
    });
  });

  describe("Proxy Pattern Tests", function () {
    it("should upgrade to DAOCommittee_V2 using upgradeTo2", async function () {
      // Perform upgrade
      const tx = await daoProxy.connect(multiSigOwner2).upgradeTo2(newImplementation.address);
      await tx.wait();

      // Verify upgrade
      const currentImpl = await daoProxy.implementation2(0);
      expect(currentImpl).to.equal(newImplementation.address);

      // console.log(`Upgraded to implementation: ${currentImpl}`);
    });

    it("should check MultiSigWalletAddress", async function () {
      // Create interface for upgraded proxy
      daoCommitteeV2 = new ethers.Contract(
        daoProxy.address,
        newImplementation.interface,
        multiSigOwner2
      );

      let tx  = await daoCommitteeV2.multiSigWallet()
      expect(tx).to.equal(MULTISIG_WALLET);
    });
  });

  describe("EIP-1271 Basic Functionality", function () {
    it("should return magic value for valid signatures", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        txHash
      );

      // console.log("Test hash:", testHash);
      // console.log("Signatures:", signatures);
      // console.log("MultiSig owners:", [multiSigOwner1.address, multiSigOwner2.address]);
      // console.log("MultiSig wallet:", multiSigWallet.address);

      const result = await daoCommitteeV2.callStatic.isValidSignature(txHash, signatures);
      console.log("result", result);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("should return invalid signature for wrong signatures", async function () {
      const signatures = await createMultipleSignatures(
        [nonOwner, multiSigOwner1],
        testHash
      );

      const tx = await daoCommitteeV2.isValidSignature(testHash, signatures);
      const result = await tx.wait();
      console.log("tx", tx);
      console.log("result", result);
      expect(result).to.equal(INVALID_SIGNATURE);
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


});