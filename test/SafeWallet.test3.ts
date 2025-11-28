import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

import dotenv from "dotenv";
dotenv.config();

import semverSatisfies from 'semver/functions/satisfies.js'

import Safe, {
  buildContractSignature,
  buildSignatureBytes,
  preimageSafeTransactionHash,
} from '@safe-global/protocol-kit'
import {
  SafeTransactionData,
  SafeSignature,
  SigningMethod
} from '@safe-global/types-kit'
import SafeApiKit from '@safe-global/api-kit'

/// const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommittee_V2_ABI = require("../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;
const MultiSigWallet_ABI = require("../abi/MultiSigWallet.json");
const Safe_ABI = require("../abi/Safe.json");
const CompatibilityFallbackHandler_ABI = require("../abi/CompatibilityFallbackHandler.json");

const EQ_OR_GT_1_3_0 = '>=1.3.0'

describe("EIP-1271 Upgrade Integration Tests", function () {
  // Network Configuration
  const DAO_COMMITTEE_PROXY = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
  const SAFE_PROXY = "0xEEdAd0a39Ef5A1FfE39ce053E061f53B943338eE"
  const MULTISIG_WALLET = "0x865200f8172bf55f99b53A8fa0E26988b94dfBbE"

  const RPC_URL = process.env.ETH_NODE_URI_sepolia;
  const SAFE_API_KEY = process.env.SAFE_API_KEY;

  // const safeVersion = "1.4.1"
  // const chainId = 11155111n

  // Test accounts
  let deployer: SignerWithAddress;
  let SafeWalletOwner1: SignerWithAddress;
  let multiSigOwner1: SignerWithAddress;
  let multiSigOwner2: SignerWithAddress;


  // Contract instances
  let daoProxy: Contract;
  let daoCommitteeV2: Contract;
  let multiSigWallet: Contract;
  let safeContract: Contract;

  // Test constants
  const MAGIC_VALUE = "0x20c13b0b";
  const INVALID_SIGNATURE = "0xffffffff";
  // const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
  const testHash = "0xe22e89fbd5cdcd4e2d53fb008fc3a6f459cc210e28a8d41d63ad835a88c395d9"
  const numConfirmationsRequired = 2; // 2 out of 3 multisig

  const SAFE_SIGNATURE = 'safe_sign'

  // let sendether = "0xDE0B6B3A7640000"

  let safeTransactionData = {
    "to": "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea",
    "data": "0x",
    "value": "1",
    "operation": 0,
    "baseGas": "0",
    "gasPrice": "0",
    "gasToken": "0x0000000000000000000000000000000000000000",
    "nonce": 0,
    "refundReceiver": "0x0000000000000000000000000000000000000000",
    "safeTxGas": "0"
  }

  let apiKit: SafeApiKit;
  let protocolKit: any;
  let safeTx: any;

  let daoCommitteeAdmin: any;
  const daoAdminAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";
  let sendether = "0xDE0B6B3A7640000"

  before(async function () {
    [SafeWalletOwner1, multiSigOwner1, multiSigOwner2] = await ethers.getSigners();

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
    console.log(`DAO Proxy: ${DAO_COMMITTEE_PROXY}`);

    apiKit = new SafeApiKit({
      chainId: 11155111n,
      apiKey: SAFE_API_KEY
    });

    protocolKit = await Safe.init({
      provider: RPC_URL!,
      safeAddress: SAFE_PROXY
    })

    safeTx = await protocolKit.createTransaction({
      transactions: [
        safeTransactionData
      ],
    })
    console.log("safeTx :", safeTx);
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

  describe("Check contract settings and settings values", function () {
    it("Set the DAOProxy2Contract", async function () {
      const daoCommitteeProxy2Contract = new ethers.Contract(
        DAO_COMMITTEE_PROXY,
        DAOProxy2ABI,
        ethers.provider
      )

      daoProxy = daoCommitteeProxy2Contract;
    });

    it("set the DAOCommitteeV2", async function () {
      daoCommitteeV2 = new ethers.Contract(
        daoProxy.address,
        DAOCommittee_V2_ABI,
        daoCommitteeAdmin
      );
    });

    it("should check MultiSigWalletAddress", async function () {
      let tx = await daoCommitteeV2.multiSigWallet()
      expect(tx).to.equal(MULTISIG_WALLET);
    });
  });

  describe("DAO's isValidSignature Basic Functionality", function () {
    it("set the SafeContract", async function () {
      safeContract = new ethers.Contract(
        SAFE_PROXY,
        CompatibilityFallbackHandler_ABI.abi,
        ethers.provider
      );
      // console.log("safeContract", safeContract)
    })

    it("isValidSignature test passed", async function () {
      let multiSigSigns = await protocolKit
        .connect({
          signer: process.env.OWNER_PRIVATE_KEY,
          safeAddress: DAO_COMMITTEE_PROXY,
        })
        .then((k) =>
          k.signTransaction(
            safeTx,
            SigningMethod.SAFE_SIGNATURE,
            SAFE_PROXY
          )
        )
      // console.log("multiSigSigns1", multiSigSigns)

      let protocolKit2 = await protocolKit.connect({
        signer: process.env.OWNER_PRIVATE_KEY,
        safeAddress: DAO_COMMITTEE_PROXY,
      })

      let chainId = await protocolKit2.getChainId()
      console.log('체인 ID:', chainId)

      let safeVersion = await protocolKit2.getContractVersion()
      console.log("safeVersion", safeVersion)

      const txHashData = preimageSafeTransactionHash(
        SAFE_PROXY,
        safeTx.data as SafeTransactionData,
        safeVersion,
        chainId
      )

      console.log("txHashData", txHashData)

      multiSigSigns = await protocolKit
        .connect({
          signer: process.env.OWNER_PRIVATE_KEY2,
          safeAddress: DAO_COMMITTEE_PROXY,
        })
        .then((k) =>
          k.signTransaction(
            multiSigSigns,
            SigningMethod.SAFE_SIGNATURE,
            SAFE_PROXY
          )
        )
      // console.log("multiSigSigns2", multiSigSigns)

      const contractSignature = await buildContractSignature(
        Array.from(multiSigSigns.signatures.values()),
        DAO_COMMITTEE_PROXY!
      )
      // console.log("contractSignature", contractSignature)
      // const contractSig = buildSignatureBytes([contractSignature])

      safeTx.addSignature(contractSignature)
      // console.log("safeTx2", safeTx)

      const pendingTxs = await apiKit.getPendingTransactions(
        SAFE_PROXY!
      )
      console.log("pendingTxs", pendingTxs)

      const transaction = await apiKit.getTransaction(
        pendingTxs.results[0].safeTxHash
      )
      console.log("transaction", transaction)

      const orginSign = await protocolKit
        .toSafeTransactionType(transaction)
        .then((safeTx) => Array.from(safeTx.signatures.values())[0])
      console.log("orginSign", orginSign)

      const safeTxHash = await protocolKit.getTransactionHash(safeTx)
      // console.log("safeTxHash", safeTxHash)
      expect(safeTxHash).to.equal(testHash);

      let checkSignature = buildSignatureBytes([
        safeTx.getSignature(DAO_COMMITTEE_PROXY) as SafeSignature,
      ])
      console.log("checkSignature :", checkSignature)
      console.log("checkSignature length :", checkSignature.length)

      // let check2Signature = buildSignatureBytes([
      //   orginSign,
      //   safeTx.getSignature(DAO_COMMITTEE_PROXY) as SafeSignature,
      // ])
      // console.log("check2Signature", check2Signature)

      let sigLength = 196
      const makeSignature = "0x" + checkSignature.substring(sigLength);
      console.log("makeSignature", makeSignature)

      const result = await daoCommitteeV2.callStatic.isValidSignature(txHashData, makeSignature);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("If the number of duplicate signers in isValidSignature is too small, it fails.", async function () {
      let multiSigSigns = await protocolKit
        .connect({
          signer: process.env.OWNER_PRIVATE_KEY,
          safeAddress: DAO_COMMITTEE_PROXY,
        })
        .then((k) =>
          k.signTransaction(
            safeTx,
            SigningMethod.SAFE_SIGNATURE,
            SAFE_PROXY
          )
        )

      let protocolKit2 = await protocolKit.connect({
        signer: process.env.OWNER_PRIVATE_KEY,
        safeAddress: DAO_COMMITTEE_PROXY,
      })

      let chainId = await protocolKit2.getChainId()
      let safeVersion = await protocolKit2.getContractVersion()

      const txHashData = preimageSafeTransactionHash(
        SAFE_PROXY,
        safeTx.data as SafeTransactionData,
        safeVersion,
        chainId
      )

      multiSigSigns = await protocolKit
        .connect({
          signer: process.env.OWNER_PRIVATE_KEY2,
          safeAddress: DAO_COMMITTEE_PROXY,
        })
        .then((k) =>
          k.signTransaction(
            multiSigSigns,
            SigningMethod.SAFE_SIGNATURE,
            SAFE_PROXY
          )
        )
      // console.log("multiSigSigns", multiSigSigns)
      // console.log("multiSigSigns.signatures.values()", Array.from(multiSigSigns.signatures.values())[0])

      let getSignature = Array.from(multiSigSigns.signatures.values())[1]
      // let getSignature2= Array.from(multiSigSigns.signatures.values())[2]

      const makeSignature = getSignature.data;
      const makeSignature3 = makeSignature + makeSignature.substring(2);
      // console.log("makeSignature3", makeSignature3)
      // console.log("makeSignature3.length", makeSignature3.length)

      const result = await daoCommitteeV2.callStatic.isValidSignature(txHashData, makeSignature3);
      expect(result).to.equal(INVALID_SIGNATURE);

    });

    it("In isValidSignature, even if the signer is duplicated, it succeeds if the number of signs is satisfied.", async function () {
      let multiSigSigns = await protocolKit
        .connect({
          signer: process.env.OWNER_PRIVATE_KEY,
          safeAddress: DAO_COMMITTEE_PROXY,
        })
        .then((k) =>
          k.signTransaction(
            safeTx,
            SigningMethod.SAFE_SIGNATURE,
            SAFE_PROXY
          )
        )

      let protocolKit2 = await protocolKit.connect({
        signer: process.env.OWNER_PRIVATE_KEY,
        safeAddress: DAO_COMMITTEE_PROXY,
      })

      let chainId = await protocolKit2.getChainId()
      let safeVersion = await protocolKit2.getContractVersion()

      const txHashData = preimageSafeTransactionHash(
        SAFE_PROXY,
        safeTx.data as SafeTransactionData,
        safeVersion,
        chainId
      )

      multiSigSigns = await protocolKit
        .connect({
          signer: process.env.OWNER_PRIVATE_KEY2,
          safeAddress: DAO_COMMITTEE_PROXY,
        })
        .then((k) =>
          k.signTransaction(
            multiSigSigns,
            SigningMethod.SAFE_SIGNATURE,
            SAFE_PROXY
          )
        )

      let getSignature = Array.from(multiSigSigns.signatures.values())[1]
      let getSignature2 = Array.from(multiSigSigns.signatures.values())[2]

      const makeSignature = getSignature.data;
      const makeSignature2 = getSignature2.data;
      const makeSignature3 = makeSignature + makeSignature.substring(2) + makeSignature2.substring(2);
      // console.log("makeSignature3", makeSignature3)

      const result = await daoCommitteeV2.callStatic.isValidSignature(txHashData, makeSignature3);
      expect(result).to.equal(MAGIC_VALUE);
    });



  });


});