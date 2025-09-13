import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

import dotenv from "dotenv" ;
dotenv.config();

import semverSatisfies from 'semver/functions/satisfies.js'

import Safe, {
  buildContractSignature,
  buildSignatureBytes,
  preimageSafeTransactionHash,
} from '@safe-global/protocol-kit'
import {
  SafeTransaction,
  SafeTransactionData,
  EIP712TypedData,
  TypedMessageTypes,
  TypedDataTypes,
  EIP712TxTypes,
  SafeSignature,
  SigningMethod
} from '@safe-global/types-kit'
import SafeApiKit from '@safe-global/api-kit'

import { 
  isHex,
  toHex, 
  Hex, 
  HashTypedDataParameters, 
  getTypesForEIP712Domain, 
  validateTypedData, 
  hashDomain, 
  concat, 
  AbiParameter,
  keccak256, 
  encodeAbiParameters ,
  recoverAddress,
  parseAbiParameters
} from 'viem'

/// const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const MultiSigWallet_ABI = require("../abi/MultiSigWallet.json");
const Safe_ABI = require("../abi/Safe.json");
const CompatibilityFallbackHandler_ABI = require("../abi/CompatibilityFallbackHandler.json");

const EQ_OR_GT_1_3_0 = '>=1.3.0'

const EIP712_DOMAIN_BEFORE_V130 = [
  {
    type: 'address',
    name: 'verifyingContract'
  }
]

const EIP712_DOMAIN = [
  {
    type: 'uint256',
    name: 'chainId'
  },
  {
    type: 'address',
    name: 'verifyingContract'
  }
]

describe("EIP-1271 Upgrade Integration Tests", function () {
  // Network Configuration
  const DAO_COMMITTEE_PROXY = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
  let currentOwner = "0xa2101482b28e3d99ff6ced517ba41eff4971a386"
  const SAFE_PROXY = "0x623E2B35964F944e166E6531CEF7577C2851F415"
  const MULTISIG_WALLET = "0x82460E7D90e19cF778a2C09DcA75Fc9f79Da877C"

  const RPC_URL = process.env.ETH_NODE_URI_sepolia;
  const SAFE_API_KEY = process.env.SAFE_API_KEY;

  // const safeVersion = "1.4.1"
  // const chainId = 11155111n

  // Test accounts
  let deployer: SignerWithAddress;
  let SafeWalletOwner1: SignerWithAddress;
  let multiSigOwner1: SignerWithAddress;
  let multiSigOwner2: SignerWithAddress;
  let nonOwner: SignerWithAddress;


  // Contract instances
  let daoProxy: Contract;
  let daoCommitteeV2: Contract;
  let multiSigWallet: Contract;
  let newImplementation: Contract;
  let safeContract: Contract;

  // Test constants
  const MAGIC_VALUE = "0x20c13b0b";
  const INVALID_SIGNATURE = "0xffffffff";
  // const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
  const testHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message"));
  const txHash = "0x34148392eddee2686a39b6da312a95afdbf953bef85122e5b0c73f3b624cba8f"
  const testHash2 = "0x644a6c15e3d1cf448599d487c6f3fe68e93e891205961df6fb5950ff3cf45c66"
  const numConfirmationsRequired = 2; // 2 out of 3 multisig

  const SAFE_SIGNATURE = 'safe_sign'

  // let sendether = "0xDE0B6B3A7640000"

  let safeTransactionData = {
    "to": "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea",
    "data": "0x",
    "value": "1000000000000000",
    "operation": 0,
    "baseGas": "0",
    "gasPrice": "0",
    "gasToken": "0x0000000000000000000000000000000000000000",
    "nonce": 4,
    "refundReceiver": "0x0000000000000000000000000000000000000000",
    "safeTxGas": "0"
  }


  before(async function () {
    [SafeWalletOwner1, multiSigOwner1, multiSigOwner2, nonOwner] = await ethers.getSigners();

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
      const DAOCommitteeV2Factory = await ethers.getContractFactory("DAOCommittee_V3");
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

  describe("Proxy Pattern upgradeTo2", function () {
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
    it("set the SafeContract", async function () {
      safeContract = new ethers.Contract(
        SAFE_PROXY,
        CompatibilityFallbackHandler_ABI.abi,
        ethers.provider
      );
      // console.log("safeContract", safeContract)
    })
    // it("should return magic value for valid signatures", async function () {
    //   const signatures = await createMultipleSignatures(
    //     [multiSigOwner1, multiSigOwner2],
    //     testHash2
    //   );
    //   // console.log("testHash2", testHash2);
    //   // console.log("signatures", signatures);

    //   const result = await daoCommitteeV2.callStatic.isValidSignature(testHash2, signatures);
    //   console.log("result", result);
    //   expect(result).to.equal(MAGIC_VALUE);
    // });

    // it("should return magic value for valid signatures2", async function () {
    //   const signatures = await createMultipleSignatures(
    //     [multiSigOwner1, multiSigOwner2],
    //     testHash2
    //   );
    //   // console.log("testHash2", testHash2);
    //   // console.log("signatures", signatures);
    //   let sig = "0x689ede44e2b9b1f653b1df6a446457f33f50058d48a317612254e7ca4b21fe3f14a0dc3882ff8230c1b2c00994539a00d65ce38db418646362149b60b86aa2b61c11625595dee99fb80d9f3e5aadf820e7919addc2c12b8d39e89f2e8ed08face34e03207fcd37f10713d161e56fe39d815eed700f8d6ea52863db2d0c2e0c9fa41b"
    //   // 1c부분이 v를 담당하는 부분
    //   // 1c를 2c로 변경했을때 28이 44로 변경됨

    //   let sig1 = "689ede44e2b9b1f653b1df6a446457f33f50058d48a317612254e7ca4b21fe3f14a0dc3882ff8230c1b2c00994539a00d65ce38db418646362149b60b86aa2b6"
    //   let sig2 = "11625595dee99fb80d9f3e5aadf820e7919addc2c12b8d39e89f2e8ed08face34e03207fcd37f10713d161e56fe39d815eed700f8d6ea52863db2d0c2e0c9fa41b"
    //   console.log(sig1.length)
    //   console.log(sig2.length)

    //   const result = await daoCommitteeV2.callStatic.isValidSignature2(testHash2, signatures);
    //   // console.log("result", result);
    //   expect(result).to.equal(MAGIC_VALUE);
    // });

    // it("check the signHash Result", async function () {
    //   let safe = await Safe.init({
    //     provider: RPC_URL!,
    //     signer: process.env.OWNER_PRIVATE_KEY,
    //     safeAddress: DAO_COMMITTEE_PROXY
    //   })

    //   const signature = await safe.signHash(testHash2);
    //   console.log("signature", signature);

    //   const result = await daoCommitteeV2.callStatic.isValidSignature(testHash2, signature.data);
    //   // const result2 = await daoCommitteeV2.callStatic.isValidSignature2(testHash2, signature.data);
    //   // console.log("result", result);
    //   expect(result).to.equal(MAGIC_VALUE);
    //   // expect(result2).to.equal(MAGIC_VALUE);
      
    // });

    // it("check the signHash Result2", async function () {
    //   let safe = await Safe.init({
    //     provider: RPC_URL!,
    //     signer: process.env.OWNER_PRIVATE_KEY,
    //     safeAddress: DAO_COMMITTEE_PROXY
    //   })

    //   const signature = await safe.signHash(testHash2);
    //   console.log("signature", signature);

    //   // const result = await daoCommitteeV2.callStatic.isValidSignature(testHash2, signature.data);
    //   const result2 = await daoCommitteeV2.callStatic.isValidSignature2(testHash2, signature.data);
    //   // console.log("result", result);
    //   // expect(result).to.equal(MAGIC_VALUE);
    //   expect(result2).to.equal(MAGIC_VALUE);
      
    // });
    
    // it("check the signTransaction Result", async function () {
    //   let protocolKit = await Safe.init({
    //     provider: RPC_URL!,
    //     safeAddress: SAFE_PROXY
    //   })

    //   let safeTx = await protocolKit.createTransaction({
    //     transactions: [
    //         safeTransactionData
    //     ],
    //   })

    //   protocolKit = await protocolKit.connect({
    //     provider: RPC_URL!,
    //     signer: process.env.OWNER_PRIVATE_KEY,
    //     safeAddress: DAO_COMMITTEE_PROXY
    //   })

    //   let multiSigSigns = await protocolKit.signTransaction(
    //     safeTx,
    //     SAFE_SIGNATURE,
    //     SAFE_PROXY
    //   )

    //   // console.log("multiSigSigns1", multiSigSigns);

    //   protocolKit = await protocolKit.connect({
    //     provider: RPC_URL!,
    //     signer: process.env.OWNER_PRIVATE_KEY2,
    //   })

    //   multiSigSigns = await protocolKit.signTransaction(
    //     multiSigSigns,
    //     SAFE_SIGNATURE,
    //     SAFE_PROXY
    //   )

    //   // console.log("multiSigSigns2", multiSigSigns);


    //   const contractSignature = await buildContractSignature(
    //     Array.from(multiSigSigns.signatures.values()),
    //     DAO_COMMITTEE_PROXY
    //   )
    //   // console.log("contractSignature", contractSignature)

    //   safeTx.addSignature(contractSignature)
    //   // console.log("safeTx2", safeTx)
    //   console.log("safeTx2", safeTx.signatures)


    //   let checkSignature = buildSignatureBytes([
    //     safeTx.getSignature(DAO_COMMITTEE_PROXY) as SafeSignature,
    //   ])

    //   console.log("checkSignature", checkSignature)

    //   const apiKit = new SafeApiKit({
    //     chainId: 11155111n,
    //     apiKey: SAFE_API_KEY
    //   });

    //   const pendingTxs = await apiKit.getPendingTransactions(
    //     SAFE_PROXY
    //   )

    //   const transaction = await apiKit.getTransaction(
    //     pendingTxs.results[0].safeTxHash
    //   )
      
    //   const orginSign = await protocolKit
    //     .toSafeTransactionType(transaction)
    //     .then((safeTx) => Array.from(safeTx.signatures.values())[0])


    //   // console.log("orginSign", orginSign)

    //   let check2Signature = buildSignatureBytes([
    //     orginSign,
    //     safeTx.getSignature(DAO_COMMITTEE_PROXY) as SafeSignature,
    //   ])

    //   console.log("check2Signature", check2Signature)
      
    //   const safeTxHash = await protocolKit.getTransactionHash(safeTx)
    //   console.log("safeTxHash", safeTxHash)
    //   expect(safeTxHash).to.equal(testHash2);


    //   // const result = await daoCommitteeV2.callStatic.isValidSignature(testHash2, check2Signature);
    //   const result2 = await daoCommitteeV2.callStatic.isValidSignature2(testHash2, check2Signature);
    //   // console.log("result", result);
    //   // expect(result).to.equal(MAGIC_VALUE);
    //   expect(result2).to.equal(MAGIC_VALUE);
      
    // });

    it("check the signTransaction Result", async function () {
      
      const apiKit = new SafeApiKit({
        chainId: 11155111n,
        apiKey: SAFE_API_KEY
      });

      let protocolKit = await Safe.init({
        provider: RPC_URL!,
        safeAddress: SAFE_PROXY
      })

      let safeTx = await protocolKit.createTransaction({
        transactions: [
            safeTransactionData
        ],
      })
      // console.log("safeTx", safeTx)

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

      const messageHash = await protocolKit2.getSafeMessageHash(txHashData)
      // console.log("messageHash", messageHash)

      // let smapleTxHash = await protocolKit2.getTransactionHash(safeTx)
      // console.log("smapleTxHash : ", smapleTxHash)   

      let test1 = await protocolKit2.signHash(messageHash)
      // console.log("test1", test1)

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
      
      const transaction = await apiKit.getTransaction(
        pendingTxs.results[0].safeTxHash
      )

      const orginSign = await protocolKit
        .toSafeTransactionType(transaction)
        .then((safeTx) => Array.from(safeTx.signatures.values())[0])

      // console.log("orginSign", orginSign)

      const safeTxHash = await protocolKit.getTransactionHash(safeTx)
      // console.log("safeTxHash", safeTxHash)
      expect(safeTxHash).to.equal(testHash2);

      let checkSignature = buildSignatureBytes([
        safeTx.getSignature(DAO_COMMITTEE_PROXY) as SafeSignature,
      ])
      // console.log("checkSignature", checkSignature)
      
      
      let check2Signature = buildSignatureBytes([
        orginSign,
        safeTx.getSignature(DAO_COMMITTEE_PROXY) as SafeSignature,
      ])
      console.log("check2Signature", check2Signature)


      // let checkSignature3 = buildSignatureBytes([
      //   orginSign,
      //   contractSignature
      // ])
      // console.log("checkSignature3", checkSignature3)

      // let checkSignature4 = buildSignatureBytes2([
      //   orginSign,
      //   contractSignature
      // ])
      // console.log("checkSignature4", checkSignature4)
      
      let setSignature = "0x7c884a93d367f70eed1edc95ee6b9e0b96fe7f4caf03b7a190e7786aab63be2d302a5d3b534277789465c7b917ba4206ea6c6a5f21e6487c17c2aa118dd6bc2a209e77e9dd73703da05391e6d303891802c4ae677f8e3582d2d27de52391b0bac11d81497fcf36d63b42fcab38cd7d8712aebda9f663f4b21b6f409316b4bf323b1f"
      let setSignature1 = "0x7c884a93d367f70eed1edc95ee6b9e0b96fe7f4caf03b7a190e7786aab63be2d302a5d3b534277789465c7b917ba4206ea6c6a5f21e6487c17c2aa118dd6bc2a20"
      let setSignature2 = "0x9e77e9dd73703da05391e6d303891802c4ae677f8e3582d2d27de52391b0bac11d81497fcf36d63b42fcab38cd7d8712aebda9f663f4b21b6f409316b4bf323b1f"
      // let setSignature3 = "0xc5eca5424f426c2e4817cae6fd86ae57c97d757ee49e609c669065edf9dee6e75b4a2e842d67284b50f4b3024264eb70b38145c31528c8d330d92bad4409aea71b"
      let changedcheckSignature2 = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a38600000000000000000000000000000000000000000000000000000000000000820000000000000000000000000000000000000000000000000000000000000000827c884a93d367f70eed1edc95ee6b9e0b96fe7f4caf03b7a190e7786aab63be2d302a5d3b534277789465c7b917ba4206ea6c6a5f21e6487c17c2aa118dd6bc2a209e77e9dd73703da05391e6d303891802c4ae677f8e3582d2d27de52391b0bac11d81497fcf36d63b42fcab38cd7d8712aebda9f663f4b21b6f409316b4bf323b1f"
      
      let makeSignature = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386000000000000000000000000000000000000000000000000000000000000008200c5eca5424f426c2e4817cae6fd86ae57c97d757ee49e609c669065edf9dee6e75b4a2e842d67284b50f4b3024264eb70b38145c31528c8d330d92bad4409aea71b00000000000000000000000000000000000000000000000000000000000000827c884a93d367f70eed1edc95ee6b9e0b96fe7f4caf03b7a190e7786aab63be2d302a5d3b534277789465c7b917ba4206ea6c6a5f21e6487c17c2aa118dd6bc2a209e77e9dd73703da05391e6d303891802c4ae677f8e3582d2d27de52391b0bac11d81497fcf36d63b42fcab38cd7d8712aebda9f663f4b21b6f409316b4bf323b1f"
      let makeSignatureSampleAddress = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386"
      let passSample = "0x0000000000000000000000000A92feB25C1ff258A7df028a9469412ba9F5b00900000000000000000000000000000000000000000000000000000000000000820051e1d0de7a535297d74a16a9adb961d4dc43fce8cdf961941c830205c71397d21278f49b019239ee95855b383c776bdf048d2e0db7c895bc8b8424dcf4efcfb91b0000000000000000000000000000000000000000000000000000000000000082dca70dc61bb85ffdbd29a5269dd11a6385c51adb62a61add04db49e518ec50702f7d6212ce714e4dfcee681ca8c03baa88085a401321b1b544332a77fed118e61f22bdac89e180594a9e3f859004f1d057ede5d8858371dd75c02a2b5f4f5f9b2c4cf226f3a4bac2eb235905be7f84e527173d7feab5c880797239e9d25d51935f20"
      let SampleAddress = "0x0000000000000000000000000A92feB25C1ff258A7df028a9469412ba9F5b009"
      // console.log("changedcheckSignature3.length : ", makeSignature.length)
      // console.log("passSample.length : ", passSample.length)
      // console.log("--------------------------------")
      // console.log("makeSignatureSampleAddress.length : ", makeSignatureSampleAddress.length)
      // console.log("SampleAddress.length : ", SampleAddress.length)
      // console.log("--------------------------------")
      
      // const signatureResponse = await apiKit.confirmTransaction(
      //   safeTxHash,
      //   buildSignatureBytes([
      //     orginSign,
      //     safeTx.getSignature(DAO_COMMITTEE_PROXY!) as SafeSignature,
      //   ])
      // )

      // console.log("signatureResponse", signatureResponse)
      
      
      
      // let getSigner = await recoverSignerFromSafeSignature(
      //   setSignature2, 
      //   SAFE_PROXY, 
      //   safeTransactionData, 
      //   safeVersion, 
      //   chainId
      // )
      // console.log("getSigner", getSigner)

      // safeTxHash = keccak256(
      //   "\x19\x01" +           // EIP-712 prefix
      //   domainHash +           // 도메인 해시
      //   messageHash            // 메시지 해시
      // )
      // let domainHash = "0x354d6f7b96d2576ed7cef655de3fc5de82569dc776d566faa0d81e3837df2f3b"
      // let messageHash = "0x4357a32901c8d398210e2a3f8dd0dbf6cf2a38e887884040ef5225fecc40c3d1"
      // const chainId = await protocolKit.getChainId()
      // console.log('체인 ID:', chainId)
      // const actualHash = await protocolKit.getSafeMessageHash(safeTxHash)
      // console.log("actualHash", actualHash)

      // const recoveredSigner = await recoverAddress({
      //   hash: actualHash as `0x${string}`,
      //   signature: setSignature2 as `0x${string}`
      // })
      
      // console.log('복구된 서명자:', recoveredSigner)

      // console.log("1")
      // const dataHash = keccak256(safeTxHash as `0x${string}`);

      // const domainSeparator = await daoCommitteeV2.callStatic.domainSeparator();
      // console.log("domainSeparator", domainSeparator)
      // const domainSeparator2 = await daoCommitteeV2.callStatic.domainSeparator2();
      // console.log("domainSeparator2", domainSeparator2)
      const getChainId = await daoCommitteeV2.callStatic.getChainId();
      console.log("getChainId", getChainId)
      const getChainId2 = await daoCommitteeV2.callStatic.getChainId2();
      console.log("getChainId2", getChainId2)

      // let validCheck = await safeContract["isValidSignature(bytes,bytes)"](
      //   txHashData,
      //   check2Signature
      // )
      // console.log("validCheck", validCheck)

      let sampleSafeTxHash = "0x471b155e978e50607d41a39e4458e91f50ff92cddcc3024b47b7382ea4827e13"
      let sampleSign = "0x22bdac89e180594a9e3f859004f1d057ede5d8858371dd75c02a2b5f4f5f9b2c4cf226f3a4bac2eb235905be7f84e527173d7feab5c880797239e9d25d51935f20"
      let secondHash = "0x387aacc5db817ca362ab38da5c074ebb2abfeeef8df22cb9dab4ef99b220e3dc"

      let messageHash2 = "0x4357a32901c8d398210e2a3f8dd0dbf6cf2a38e887884040ef5225fecc40c3d1"

      // const domainSeparator = await daoCommitteeV2.callStatic.domainSeparator();
      // console.log("domainSeparator", domainSeparator)
      const result = await daoCommitteeV2.callStatic.isValidSignature3(txHashData, makeSignature);
      expect(result).to.equal(MAGIC_VALUE);
      // const result = await daoCommitteeV2.callStatic.isValidSignature2(txHashData, makeSignature);
      // expect(result).to.equal(MAGIC_VALUE);
      // let result = await daoCommitteeV2.callStatic.isValidSignature(txHashData, setSignature);
      // expect(result).to.equal(MAGIC_VALUE);
      // result = await daoCommitteeV2.callStatic.isValidSignature(txHashData, setSignature1);
      // expect(result).to.equal(MAGIC_VALUE);
      // result = await daoCommitteeV2.callStatic.isValidSignature(txHashData, setSignature2);
      // expect(result).to.equal(MAGIC_VALUE);
      // const result2 = await daoCommitteeV2.callStatic.isValidSignature2(messageHash, setSignature2);
      // expect(result2).to.equal(MAGIC_VALUE);
    });



  });

  const buildSignatureBytes2 = (signatures: SafeSignature[]): string => {
    const SIGNATURE_LENGTH_BYTES = 65
  
    signatures.sort((left, right) =>
      left.signer.toLowerCase().localeCompare(right.signer.toLowerCase())
    )
    console.log("in buildSignatureBytes2")
    console.log("signatures", signatures)
    
    const EMPTY_DATA: Hex = '0x'
    let signatureBytes = EMPTY_DATA
    let dynamicBytes = ''
  
    for (const signature of signatures) {
      console.log("signature", signature)
      if (signature.isContractSignature) {
        console.log("isContractSignature is true")
        /* 
          A contract signature has a static part of 65 bytes and the dynamic part that needs to be appended 
          at the end of signature bytes.
          The signature format is
          Signature type == 0
          Constant part: 65 bytes
          {32-bytes signature verifier}{32-bytes dynamic data position}{1-byte signature type}
          Dynamic part (solidity bytes): 32 bytes + signature data length
          {32-bytes signature length}{bytes signature data}
        */
        const dynamicPartPosition = (
          signatures.length * SIGNATURE_LENGTH_BYTES +
          dynamicBytes.length / 2
        )
          .toString(16)
          .padStart(64, '0')
  
        signatureBytes += signature.staticPart(dynamicPartPosition)
        dynamicBytes += signature.dynamicPart()
      } else {
        console.log("isContractSignature is false")
        signatureBytes += signature.data.slice(2)
      }
    }
    console.log("out buildSignatureBytes2")
    return signatureBytes + dynamicBytes
  }
  

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

  async function getSafeMessageHash(hash: string): Promise<string> {
    const safeAddress = "0x623E2B35964F944e166E6531CEF7577C2851F415"
    const safeVersion = "1.4.1"
    const chainId = 11155111

    return calculateSafeMessageHash(safeAddress, hash, safeVersion, chainId)
  }


  async function getTransactionHash(safeTransaction: SafeTransaction): Promise<string> {
    const safeAddress = "0x623E2B35964F944e166E6531CEF7577C2851F415"
    const safeVersion = "1.4.1"
    const chainId = 11155111

    return calculateSafeTransactionHash(safeAddress, safeTransaction.data, safeVersion, chainId)
  }

  async function calculateSafeMessageHash(
    safeAddress: string, 
    hash: string, 
    safeVersion: string, 
    chainId: number
  ): Promise<string> {
    const safeMessageTypes = await getEip712MessageTypes(safeVersion)

    return hashTypedData({
      domain: { verifyingContract: safeAddress, chainId: Number(chainId) },
      types: { SafeMessage: safeMessageTypes.SafeMessage },
      message: { hash }
    })
  }

  async function getEip712MessageTypes(safeVersion: string): Promise<any> {
    const eip712WithChainId = semverSatisfies(safeVersion, EQ_OR_GT_1_3_0)
    return {
      EIP712Domain: eip712WithChainId ? EIP712_DOMAIN : EIP712_DOMAIN_BEFORE_V130,
      SafeMessage: [{ type: 'bytes', name: 'message' }]
    }
  }

  async function hashTypedData(typedData: EIP712TypedData): Promise<string> {
    return hashTypedStructuredData(typedData)
  }

  function hashTypedStructuredData(typedData: EIP712TypedData): string {
    const data = encodeTypedData(typedData)
    return keccak256(asHex(data))
  }

  function asHex(hex?: string): Hex {
    return isHex(hex) ? (hex as Hex) : (`0x${hex}` as Hex)
  }

  function encodeTypedData(typedData: EIP712TypedData): string {
    typedData.primaryType = !typedData?.primaryType
      ? deducePrimaryType(typedData.types)
      : typedData?.primaryType
  
    const { domain = {}, message, primaryType } = typedData as any as HashTypedDataParameters
    const types = {
      EIP712Domain: getTypesForEIP712Domain({ domain: domain as Record<string, unknown> }),
      ...typedData.types
    }
  
    // Need to do a runtime validation check on addresses, byte ranges, integer ranges, etc
    // as we can't statically check this with TypeScript.
    validateTypedData({
      domain: domain as any,
      message,
      primaryType: primaryType as any,
      types
    })
  
    const parts: Hex[] = ['0x1901']
    if (domain)
      parts.push(
        hashDomain({
          domain,
          types: types
        })
      )
  
    if (primaryType !== 'EIP712Domain')
      parts.push(
        hashStruct({
          data: message,
          primaryType: primaryType,
          types: types
        })
      )
  
    return concat(parts)
  }

  function deducePrimaryType(types: TypedMessageTypes) {
    // In ethers the primaryType is assumed to be the first yielded by a forEach of the types keys
    // https://github.com/ethers-io/ethers.js/blob/a4b1d1f43fca14f2e826e3c60e0d45f5b6ef3ec4/src.ts/hash/typed-data.ts#L278C13-L278C20
    return Object.keys(types)[0]
  }

  function hashStruct({
    data,
    primaryType,
    types
  }: {
    data: Record<string, unknown>
    primaryType: string
    types: Record<string, TypedDataTypes[]>
  }) {
    const encoded = encodeData({
      data,
      primaryType,
      types
    })
    return keccak256(encoded)
  }

  function encodeData({
    data,
    primaryType,
    types
  }: {
    data: Record<string, unknown>
    primaryType: string
    types: Record<string, TypedDataTypes[]>
  }) {
    const encodedTypes: AbiParameter[] = [{ type: 'bytes32' }]
    const encodedValues: unknown[] = [hashType({ primaryType, types })]
  
    for (const field of types[primaryType]) {
      const [type, value] = encodeField({
        types,
        name: field.name,
        type: field.type,
        value: data[field.name]
      })
      encodedTypes.push(type)
      encodedValues.push(value)
    }
  
    return encodeAbiParameters(encodedTypes, encodedValues)
  }

  function hashType({
    primaryType,
    types
  }: {
    primaryType: string
    types: Record<string, TypedDataTypes[]>
  }) {
    const encodedHashType = toHex(encodeType({ primaryType, types }))
    return keccak256(encodedHashType)
  }

  function encodeField({
    types,
    name,
    type,
    value
  }: {
    types: Record<string, TypedDataTypes[]>
    name: string
    type: string
    value: any
  }): [type: AbiParameter, value: any] {
    if (types[type] !== undefined) {
      return [{ type: 'bytes32' }, keccak256(encodeData({ data: value, primaryType: type, types }))]
    }
  
    if (type === 'bytes') {
      const prepend = value.length % 2 ? '0' : ''
      value = `0x${prepend + value.slice(2)}`
      return [{ type: 'bytes32' }, keccak256(value)]
    }
  
    if (type === 'string') return [{ type: 'bytes32' }, keccak256(toHex(value))]
  
    if (type.lastIndexOf(']') === type.length - 1) {
      const parsedType = type.slice(0, type.lastIndexOf('['))
      const typeValuePairs = (value as [AbiParameter, any][]).map((item) =>
        encodeField({
          name,
          type: parsedType,
          types,
          value: item
        })
      )
      return [
        { type: 'bytes32' },
        keccak256(
          encodeAbiParameters(
            typeValuePairs.map(([t]) => t),
            typeValuePairs.map(([, v]) => v)
          )
        )
      ]
    }
  
    return [{ type }, value]
  }

  function encodeType({
    primaryType,
    types
  }: {
    primaryType: string
    types: Record<string, TypedDataTypes[]>
  }) {
    let result = ''
    const unsortedDeps = findTypeDependencies({ primaryType, types })
    unsortedDeps.delete(primaryType)
  
    const deps = [primaryType, ...Array.from(unsortedDeps).sort()]
    for (const type of deps) {
      result += `${type}(${types[type].map(({ name, type: t }) => `${t} ${name}`).join(',')})`
    }
  
    return result
  }

  function findTypeDependencies(
    {
      primaryType: primaryType_,
      types
    }: {
      primaryType: string
      types: Record<string, TypedDataTypes[]>
    },
    results: Set<string> = new Set()
  ): Set<string> {
    const match = primaryType_.match(/^\w*/u)
    const primaryType = match?.[0] || ''
    if (results.has(primaryType) || types[primaryType] === undefined) {
      return results
    }
  
    results.add(primaryType)
  
    for (const field of types[primaryType]) {
      findTypeDependencies({ primaryType: field.type, types }, results)
    }
    return results
  }

  
  async function calculateSafeTransactionHash(
    safeAddress: string,
    safeTx: SafeTransactionData,
    safeVersion: string,
    chainId: number
  ): Promise<string> {
    const safeTxTypes = getEip712TxTypes(safeVersion)
    const domain: {
      chainId?: number
      verifyingContract: string
    } = { verifyingContract: safeAddress }
  
    if (semverSatisfies(safeVersion, EQ_OR_GT_1_3_0)) {
      domain.chainId = Number(chainId)
    }
  
    const message = safeTx as unknown as Record<string, unknown>
  
    return hashTypedData({ domain, types: { SafeTx: safeTxTypes.SafeTx }, message })
  }

  function getEip712TxTypes(safeVersion: string): EIP712TxTypes {
    const eip712WithChainId = semverSatisfies(safeVersion, EQ_OR_GT_1_3_0)
    return {
      EIP712Domain: eip712WithChainId ? EIP712_DOMAIN : EIP712_DOMAIN_BEFORE_V130,
      SafeTx: [
        { type: 'address', name: 'to' },
        { type: 'uint256', name: 'value' },
        { type: 'bytes', name: 'data' },
        { type: 'uint8', name: 'operation' },
        { type: 'uint256', name: 'safeTxGas' },
        { type: 'uint256', name: 'baseGas' },
        { type: 'uint256', name: 'gasPrice' },
        { type: 'address', name: 'gasToken' },
        { type: 'address', name: 'refundReceiver' },
        { type: 'uint256', name: 'nonce' }
      ]
    }
  }

  // async function signHash(hash: string): Promise<SafeSignature> {
  //   const isPasskeySigner = await this.#safeProvider.isPasskeySigner()
  //   const signerAddress = await this.#safeProvider.getSignerAddress()

  //   if (isPasskeySigner && signerAddress) {
  //     let signature = await this.#safeProvider.signMessage(hash)

  //     signature = await adjustVInSignature(SigningMethod.ETH_SIGN, signature, hash, signerAddress)

  //     const safeSignature = new EthSafeSignature(signerAddress, signature, true)

  //     return safeSignature
  //   }

  //   const signature = await generateSignature(this.#safeProvider, hash)

  //   return signature
  // }

  // async function signTransaction(
  //   safeTransaction: SafeTransaction | SafeMultisigTransactionResponse,
  //   signingMethod: SigningMethodType = SigningMethod.ETH_SIGN_TYPED_DATA_V4,
  //   preimageSafeAddress?: string
  // ): Promise<SafeTransaction> {
  //   const transaction = isSafeMultisigTransactionResponse(safeTransaction)
  //     ? await this.toSafeTransactionType(safeTransaction)
  //     : safeTransaction

  //   const signerAddress = await this.#safeProvider.getSignerAddress()
  //   if (!signerAddress) {
  //     throw new Error('The protocol-kit requires a signer to use this method')
  //   }

  //   const addressIsOwner = await this.isOwner(signerAddress)
  //   if (!addressIsOwner) {
  //     throw new Error('Transactions can only be signed by Safe owners')
  //   }

  //   const safeVersion = this.getContractVersion()
  //   if (
  //     signingMethod === SigningMethod.SAFE_SIGNATURE &&
  //     semverSatisfies(safeVersion, EQ_OR_GT_1_3_0) &&
  //     !preimageSafeAddress
  //   ) {
  //     throw new Error('The parent Safe account address is mandatory for contract signatures')
  //   }

  //   let signature: SafeSignature

  //   const isPasskeySigner = await this.#safeProvider.isPasskeySigner()

  //   if (isPasskeySigner) {
  //     const txHash = await this.getTransactionHash(transaction)

  //     signature = await this.signHash(txHash)
  //   } else if (signingMethod === SigningMethod.ETH_SIGN_TYPED_DATA_V4) {
  //     signature = await this.signTypedData(transaction, 'v4')
  //   } else if (signingMethod === SigningMethod.ETH_SIGN_TYPED_DATA_V3) {
  //     signature = await this.signTypedData(transaction, 'v3')
  //   } else if (signingMethod === SigningMethod.ETH_SIGN_TYPED_DATA) {
  //     signature = await this.signTypedData(transaction, undefined)
  //   } else {
  //     const safeVersion = this.getContractVersion()
  //     const chainId = await this.getChainId()
  //     if (!hasSafeFeature(SAFE_FEATURES.ETH_SIGN, safeVersion)) {
  //       throw new Error('eth_sign is only supported by Safes >= v1.1.0')
  //     }

  //     let txHash: string

  //     // IMPORTANT: because the safe uses the old EIP-1271 interface which uses `bytes` instead of `bytes32` for the message
  //     // we need to use the pre-image of the transaction hash to calculate the message hash
  //     // https://github.com/safe-global/safe-contracts/blob/192c7dc67290940fcbc75165522bb86a37187069/test/core/Safe.Signatures.spec.ts#L229-L233
  //     if (
  //       signingMethod === SigningMethod.SAFE_SIGNATURE &&
  //       semverSatisfies(safeVersion, EQ_OR_GT_1_3_0) &&
  //       preimageSafeAddress
  //     ) {
  //       const txHashData = preimageSafeTransactionHash(
  //         preimageSafeAddress,
  //         safeTransaction.data as SafeTransactionData,
  //         safeVersion,
  //         chainId
  //       )

  //       txHash = await this.getSafeMessageHash(txHashData)
  //     } else {
  //       txHash = await this.getTransactionHash(transaction)
  //     }
  //     signature = await this.signHash(txHash)
  //   }

  //   const signedSafeTransaction = await this.copyTransaction(transaction)
  //   signedSafeTransaction.addSignature(signature)

  //   return signedSafeTransaction
  // }

  async function recoverSignerFromSafeSignature(
    signature: string,
    safeAddress: string,
    safeTransactionData: any,
    safeVersion: string,
    chainId: bigint
  ): Promise<string> {
    
    // 1단계: EIP-712 도메인 정의
    const domain = {
      chainId: Number(chainId),
      verifyingContract: safeAddress
    }
    
    // 2단계: SafeTx 타입 정의
    const SafeTx = [
      { type: 'address', name: 'to' },
      { type: 'uint256', name: 'value' },
      { type: 'bytes', name: 'data' },
      { type: 'uint8', name: 'operation' },
      { type: 'uint256', name: 'safeTxGas' },
      { type: 'uint256', name: 'baseGas' },
      { type: 'uint256', name: 'gasPrice' },
      { type: 'address', name: 'gasToken' },
      { type: 'address', name: 'refundReceiver' },
      { type: 'uint256', name: 'nonce' }
    ]
    
    // 3단계: EIP-712 인코딩
    const domainSeparator = keccak256(
      encodeAbiParameters(
        parseAbiParameters('bytes32, bytes32, bytes32, uint256, address'),
        [
          keccak256('0x1901'), // EIP-712 prefix
          keccak256('EIP712Domain(uint256 chainId,address verifyingContract)' as `0x${string}`),
          keccak256('SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)' as `0x${string}`),
          BigInt(chainId),
          safeAddress as `0x${string}`
        ]
      )
    )
    
    // 4단계: 메시지 해시 생성
    const messageHash = keccak256(
      encodeAbiParameters(
        parseAbiParameters('bytes32, bytes32'),
        [
          domainSeparator,
          keccak256(
            encodeAbiParameters(
              parseAbiParameters('address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256'),
              [
                safeTransactionData.to,
                BigInt(safeTransactionData.value),
                safeTransactionData.data,
                safeTransactionData.operation,
                BigInt(safeTransactionData.safeTxGas),
                BigInt(safeTransactionData.baseGas),
                BigInt(safeTransactionData.gasPrice),
                safeTransactionData.gasToken,
                safeTransactionData.refundReceiver,
                BigInt(safeTransactionData.nonce)
              ]
            )
          )
        ]
      )
    )
    console.log("messageHash", messageHash)
    // 5단계: 서명자 복구
    const recoveredSigner = await recoverAddress({
      hash: messageHash as `0x${string}`,
      signature: signature as `0x${string}`
    })
    
    return recoveredSigner
  }
  


});