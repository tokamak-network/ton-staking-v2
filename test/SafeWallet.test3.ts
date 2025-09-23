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
  SafeAccountConfig,
  PredictedSafeProps
} from '@safe-global/protocol-kit'
import {
  SafeTransaction,
  SafeTransactionData,
  EIP712TypedData,
  TypedMessageTypes,
  TypedDataTypes,
  EIP712TxTypes,
  SafeSignature,
  SigningMethod,
  OperationType
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

import { sepolia } from "viem/chains"

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

  // Test accounts
  let deployer: SignerWithAddress;
  let multiSigOwner1: SignerWithAddress;
  let multiSigOwner2: SignerWithAddress;
  let multiSigOwner3: SignerWithAddress;
  let nonOwner: SignerWithAddress;
  let safeWalletOwner1: SignerWithAddress;
  let safeWalletOwner2: SignerWithAddress;


  // Contract instances
  let daoProxy: Contract;
  let daoCommitteeV2: Contract;
  let multiSigWallet: Contract;
  let newImplementation: Contract;
  let safeContract: Contract;

  // Test constants
  const MAGIC_VALUE = "0x20c13b0b";
  const INVALID_SIGNATURE = "0xffffffff";
  const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
  const testHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message"));
  const txHash = "0x34148392eddee2686a39b6da312a95afdbf953bef85122e5b0c73f3b624cba8f"
  const testHash2 = "0x644a6c15e3d1cf448599d487c6f3fe68e93e891205961df6fb5950ff3cf45c66"
  const testHash3 = "0x7bda76da0451419e101d9ea5799411334d48f2efb09637eeb787f4cc521b9810"
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
    "nonce": 5,
    "refundReceiver": "0x0000000000000000000000000000000000000000",
    "safeTxGas": "0"
  }

  let apiKit: SafeApiKit;
  let protocolKit: any;
  let safeTx: any;

  let daoCommitteeAdmin: any;
  const daoAdminAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";
  let sendether = "0xDE0B6B3A7640000"

  let safeProxyAddress: any;

  before(async function () {
    [deployer, multiSigOwner1, multiSigOwner2, multiSigOwner3, nonOwner, safeWalletOwner1, safeWalletOwner2] = await ethers.getSigners();

    await hre.network.provider.send("hardhat_impersonateAccount", [
      daoAdminAddress,
    ]);
    daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

    await hre.network.provider.send("hardhat_setBalance", [
        daoAdminAddress,
        sendether
    ]);

    console.log("Setting up EIP-1271 upgrade test environment...");
    console.log(`deployer: ${deployer.address}`);
    console.log(`multiSigOwner1: ${multiSigOwner1.address}`);
    console.log(`multiSigOwner2: ${multiSigOwner2.address}`);
    console.log(`nonOwner: ${nonOwner.address}`);
    console.log(`DAO Proxy: ${DAO_COMMITTEE_PROXY}`);

    

    apiKit = new SafeApiKit({
      chainId: 11155111n,
      apiKey: SAFE_API_KEY
    });

    // protocolKit = await Safe.init({
    //   provider: RPC_URL!,
    //   safeAddress: SAFE_PROXY
    // })

    // safeTx = await protocolKit.createTransaction({
    //   transactions: [
    //       safeTransactionData
    //   ],
    // })
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

      // Grant admin role to deployer for testing
      await daoProxy.connect(daoCommitteeAdmin).grantRole(DEFAULT_ADMIN_ROLE, deployer.address);
    });

    it("Set the DAOCommitteeV2", async function () {
      daoCommitteeV2 = new ethers.Contract(
        daoProxy.address,
        newImplementation.interface,
        deployer
      );
    });
  });

  describe("Proxy Pattern upgradeTo2", function () {
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

      await expect(upgradedProxy.connect(daoCommitteeAdmin).setMultiSigWallet(multiSigWallet.address)).to.not.be.reverted;

      const multiSigAddress = await upgradedProxy.multiSigWallet();
      expect(multiSigAddress).to.equal(multiSigWallet.address);
    });
  });
  
  describe("SafeWallet Deploly & Propose", function () {
    it("should deploy NewSafeWallet", async function () {
      const safeAccountConfig: SafeAccountConfig = {
        owners: [safeWalletOwner1.address, safeWalletOwner2.address, daoCommitteeV2.address],
        threshold: 2,
      }

      const predictedSafe: PredictedSafeProps = {
        safeAccountConfig,
      }

      const protocolKit = await Safe.init({
        provider: sepolia.rpcUrls.default.http[0],
        signer: process.env.SAFE_OWNER_PRIVATE_KEY,
        predictedSafe,
      })

      safeProxyAddress = await protocolKit.getAddress()
      console.log(`Safe Address : ${safeProxyAddress}`)
    });

    it("should propose the SafeWallet", async function () {

      let protocolKit = await Safe.init({
        provider: "https://eth-sepolia.public.blastapi.io",
        signer: ,
        safeAddress: safeProxyAddress,
      })

      safeTx = await protocolKit.createTransaction({
        transactions: [
          {
            to: "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea",
            value: "1",
            data: "0x",
            operation: OperationType.Call,
          },
        ],
      })
    });
  });

  describe("DAO Contract isValidSignature Test", function () {
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

      // const messageHash = await protocolKit2.getSafeMessageHash(txHashData)
      // console.log("messageHash", messageHash)

      // let smapleTxHash = await protocolKit2.getTransactionHash(safeTx)
      // console.log("smapleTxHash : ", smapleTxHash)   

      // let test1 = await protocolKit2.signHash(messageHash)
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
        console.log("multiSigSigns2", multiSigSigns)
      
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
      expect(safeTxHash).to.equal(testHash3);

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
      

      let changedcheckSignature2 = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a38600000000000000000000000000000000000000000000000000000000000000820000000000000000000000000000000000000000000000000000000000000000827c884a93d367f70eed1edc95ee6b9e0b96fe7f4caf03b7a190e7786aab63be2d302a5d3b534277789465c7b917ba4206ea6c6a5f21e6487c17c2aa118dd6bc2a209e77e9dd73703da05391e6d303891802c4ae677f8e3582d2d27de52391b0bac11d81497fcf36d63b42fcab38cd7d8712aebda9f663f4b21b6f409316b4bf323b1f"
      
      let makeSignature = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386000000000000000000000000000000000000000000000000000000000000008200c5eca5424f426c2e4817cae6fd86ae57c97d757ee49e609c669065edf9dee6e75b4a2e842d67284b50f4b3024264eb70b38145c31528c8d330d92bad4409aea71b00000000000000000000000000000000000000000000000000000000000000827c884a93d367f70eed1edc95ee6b9e0b96fe7f4caf03b7a190e7786aab63be2d302a5d3b534277789465c7b917ba4206ea6c6a5f21e6487c17c2aa118dd6bc2a209e77e9dd73703da05391e6d303891802c4ae677f8e3582d2d27de52391b0bac11d81497fcf36d63b42fcab38cd7d8712aebda9f663f4b21b6f409316b4bf323b1f"
      // let makeSignature = "
      // 0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386
      // 000000000000000000000000000000000000000000000000000000000000008200
      // c5eca5424f426c2e4817cae6fd86ae57c97d757ee49e609c669065edf9dee6e75b4a2e842d67284b50f4b3024264eb70b38145c31528c8d330d92bad4409aea71b
      // 0000000000000000000000000000000000000000000000000000000000000082
      // 7c884a93d367f70eed1edc95ee6b9e0b96fe7f4caf03b7a190e7786aab63be2d302a5d3b534277789465c7b917ba4206ea6c6a5f21e6487c17c2aa118dd6bc2a209e77e9dd73703da05391e6d303891802c4ae677f8e3582d2d27de52391b0bac11d81497fcf36d63b42fcab38cd7d8712aebda9f663f4b21b6f409316b4bf323b1f"
      
      let makeSignatureSampleAddress = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386"

      let makeSignature2 = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386000000000000000000000000000000000000000000000000000000000000008200e3959d981f91f3008815c4f720c674953d1961ff2e9edb6bb9573e9a707f6f1c26d5c9b8a09a68782470115ff364c2379cff78d25a5a13d723ae3a144cece10a1c0000000000000000000000000000000000000000000000000000000000000082592c2304865f6e52b50999d9ce19403a30dd176d6044586deb7290cd43e6eebc1fe22df0a690c2d46852f89226dbec88d91bdcb2d0fa229d9c85d8f8cf354ac81f451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720"
      // console.log("makeSignature2.length : ", makeSignature2.length)
      // let makeSignature2 = "
      // 0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386
      // 000000000000000000000000000000000000000000000000000000000000008200
      // e3959d981f91f3008815c4f720c674953d1961ff2e9edb6bb9573e9a707f6f1c26d5c9b8a09a68782470115ff364c2379cff78d25a5a13d723ae3a144cece10a1c
      // 0000000000000000000000000000000000000000000000000000000000000082
      // 592c2304865f6e52b50999d9ce19403a30dd176d6044586deb7290cd43e6eebc1fe22df0a690c2d46852f89226dbec88d91bdcb2d0fa229d9c85d8f8cf354ac81f451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720"
      let makeSignature3 = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386000000000000000000000000000000000000000000000000000000000000008200e3959d981f91f3008815c4f720c674953d1961ff2e9edb6bb9573e9a707f6f1c26d5c9b8a09a68782470115ff364c2379cff78d25a5a13d723ae3a144cece10a1c0000000000000000000000000000000000000000000000000000000000000082451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720"
      // console.log("makeSignature3.length : ", makeSignature3.length)
      
      // const signatureResponse = await apiKit.confirmTransaction(
      //   safeTxHash,
      //   buildSignatureBytes([
      //     orginSign,
      //     safeTx.getSignature(DAO_COMMITTEE_PROXY!) as SafeSignature,
      //   ])
      // )      
    
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

      // let validCheck = await safeContract["isValidSignature(bytes,bytes)"](
      //   txHashData,
      //   makeSignature2
      // )
      // console.log("validCheck", validCheck)

      const result = await daoCommitteeV2.callStatic.isValidSignature3(txHashData, makeSignature2);
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

      const contractSignature = await buildContractSignature(
        Array.from(multiSigSigns.signatures.values()),
        DAO_COMMITTEE_PROXY!
      )
      safeTx.addSignature(contractSignature)

      const pendingTxs = await apiKit.getPendingTransactions(
        SAFE_PROXY!
      )
      const transaction = await apiKit.getTransaction(
        pendingTxs.results[0].safeTxHash
      )
      const orginSign = await protocolKit
        .toSafeTransactionType(transaction)
        .then((safeTx) => Array.from(safeTx.signatures.values())[0])
      
      const safeTxHash = await protocolKit.getTransactionHash(safeTx)

      let check2Signature = buildSignatureBytes([
        orginSign,
        safeTx.getSignature(DAO_COMMITTEE_PROXY) as SafeSignature,
      ])

      let makeSignature3 = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386000000000000000000000000000000000000000000000000000000000000008200e3959d981f91f3008815c4f720c674953d1961ff2e9edb6bb9573e9a707f6f1c26d5c9b8a09a68782470115ff364c2379cff78d25a5a13d723ae3a144cece10a1c0000000000000000000000000000000000000000000000000000000000000082451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720"
      await expect(daoCommitteeV2.callStatic.isValidSignature3(txHashData, makeSignature3)).to.be.revertedWith("GS024");

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

      const contractSignature = await buildContractSignature(
        Array.from(multiSigSigns.signatures.values()),
        DAO_COMMITTEE_PROXY!
      )
      safeTx.addSignature(contractSignature)

      const pendingTxs = await apiKit.getPendingTransactions(
        SAFE_PROXY!
      )
      const transaction = await apiKit.getTransaction(
        pendingTxs.results[0].safeTxHash
      )
      const orginSign = await protocolKit
        .toSafeTransactionType(transaction)
        .then((safeTx) => Array.from(safeTx.signatures.values())[0])
      
      const safeTxHash = await protocolKit.getTransactionHash(safeTx)

      let check2Signature = buildSignatureBytes([
        orginSign,
        safeTx.getSignature(DAO_COMMITTEE_PROXY) as SafeSignature,
      ])

      let makeSignature4 = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386000000000000000000000000000000000000000000000000000000000000008200e3959d981f91f3008815c4f720c674953d1961ff2e9edb6bb9573e9a707f6f1c26d5c9b8a09a68782470115ff364c2379cff78d25a5a13d723ae3a144cece10a1c00000000000000000000000000000000000000000000000000000000000000C3451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720592c2304865f6e52b50999d9ce19403a30dd176d6044586deb7290cd43e6eebc1fe22df0a690c2d46852f89226dbec88d91bdcb2d0fa229d9c85d8f8cf354ac81f"
      let makeSignature5 = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386000000000000000000000000000000000000000000000000000000000000008200e3959d981f91f3008815c4f720c674953d1961ff2e9edb6bb9573e9a707f6f1c26d5c9b8a09a68782470115ff364c2379cff78d25a5a13d723ae3a144cece10a1c00000000000000000000000000000000000000000000000000000000000000C3451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720592c2304865f6e52b50999d9ce19403a30dd176d6044586deb7290cd43e6eebc1fe22df0a690c2d46852f89226dbec88d91bdcb2d0fa229d9c85d8f8cf354ac81f451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720"
      let makeSignature6 = "0x000000000000000000000000A2101482b28E3D99ff6ced517bA41EFf4971a386000000000000000000000000000000000000000000000000000000000000008200e3959d981f91f3008815c4f720c674953d1961ff2e9edb6bb9573e9a707f6f1c26d5c9b8a09a68782470115ff364c2379cff78d25a5a13d723ae3a144cece10a1c00000000000000000000000000000000000000000000000000000000000000C3451900dbdd687d2196a88001c90243a526b68f15d0db2df6f6c3cba553ed01413017bbdce7087741ba96cd3c3c9c24acd023989f1e8d101ed7a6188e3df8c2d720592c2304865f6e52b50999d9ce19403a30dd176d6044586deb7290cd43e6eebc1fe22df0a690c2d46852f89226dbec88d91bdcb2d0fa229d9c85d8f8cf354ac81f592c2304865f6e52b50999d9ce19403a30dd176d6044586deb7290cd43e6eebc1fe22df0a690c2d46852f89226dbec88d91bdcb2d0fa229d9c85d8f8cf354ac81f"
      const result = await daoCommitteeV2.callStatic.isValidSignature3(txHashData, makeSignature6);
      expect(result).to.equal(MAGIC_VALUE);
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