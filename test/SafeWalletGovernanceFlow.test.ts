import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

import dotenv from "dotenv";
dotenv.config();

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
import { createWalletClient, http, Hex } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { sepolia } from 'viem/chains'

/// const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommittee_V2_ABI = require("../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;
const MultiSigWallet_ABI = require("../abi/MultiSigWallet.json");
const Safe_ABI = require("../abi/Safe.json");
const CompatibilityFallbackHandler_ABI = require("../abi/CompatibilityFallbackHandler.json");

const EQ_OR_GT_1_3_0 = '>=1.3.0'

const proxyAdmin_ABI = [
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
]

describe("EIP-1271 Upgrade Integration Tests", function () {
  // Network Configuration
  const DAO_COMMITTEE_PROXY = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
  const SAFE_PROXY = "0xbae2Dd3e3B03952C4a6793da7fCE035418d8241F"
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
  const testHash = "0x764e688dc9a5c471ba7a5d07845e630cae726aa1f2a563d220da634dab1f4e6f"
  const numConfirmationsRequired = 2; // 2 out of 3 multisig

  const SAFE_SIGNATURE = 'safe_sign'

  // let sendether = "0xDE0B6B3A7640000"

  let safeTransactionData = {
    "to": "0xab59cCb04588C95CEa44206868f90a943BcD1e0c",
    "data": "0x7eff275e000000000000000000000000330d4f93b7aef878fe97529896793fab47c1d4df0000000000000000000000007220c734653ae8ca014d4d82a84041ee4169499c",
    "value": "0",
    "operation": 0,
    "baseGas": "0",
    "gasPrice": "0",
    "gasToken": "0x0000000000000000000000000000000000000000",
    "nonce": 19,
    "refundReceiver": "0x0000000000000000000000000000000000000000",
    "safeTxGas": "0"
  }

  let apiKit: SafeApiKit;
  let protocolKit: any;
  let safeTx: any;

  let daoCommitteeAdmin: any;
  const daoAdminAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";
  let sendether = "0xDE0B6B3A7640000"

  let proxyAdmin: any;
  let proxyAdminAddress = "0xab59cCb04588C95CEa44206868f90a943BcD1e0c"
  let originalOwner = "0xcf358978506df27dD3688B3233b23f25b3756Edb"
  let changedOwner = "0x7220c734653ae8Ca014d4D82A84041EE4169499c"

  const FOUNDATION_KEY = process.env.EXECUTE_PRIVATE_KEY;

  before(async function () {
    [SafeWalletOwner1, multiSigOwner1, multiSigOwner2] = await ethers.getSigners();

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //   daoAdminAddress,
    // ]);
    // daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

    // await hre.network.provider.send("hardhat_setBalance", [
    //   daoAdminAddress,
    //   sendether
    // ]);

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

    // it("should Set MultiSigWallet", async function () {
    //   //==== Set Proxy2Contract =================================
    //   multiSigWallet = new ethers.Contract(
    //     MULTISIG_WALLET,
    //     MultiSigWallet_ABI.abi,
    //     ethers.provider
    //   )
    // });

    // it("Setting the ProxyAdmin", async function () {
    //   proxyAdmin = new ethers.Contract(
    //     proxyAdminAddress,
    //     proxyAdmin_ABI,
    //     ethers.provider
    //   )
    // })
  });

  // describe("Check contract settings and settings values", function () {
  //   it("Set the DAOProxy2Contract", async function () {
  //     const daoCommitteeProxy2Contract = new ethers.Contract(
  //       DAO_COMMITTEE_PROXY,
  //       DAOProxy2ABI,
  //       ethers.provider
  //     )

  //     daoProxy = daoCommitteeProxy2Contract;
  //   });

  //   it("set the DAOCommitteeV2", async function () {
  //     daoCommitteeV2 = new ethers.Contract(
  //       daoProxy.address,
  //       DAOCommittee_V2_ABI,
  //       daoCommitteeAdmin
  //     );
  //   });

  //   it("should check MultiSigWalletAddress", async function () {
  //     let tx = await daoCommitteeV2.multiSigWallet()
  //     console.log("tx : ", tx)
  //     console.log("MULTISIG_WALLET : ", MULTISIG_WALLET)
  //     // expect(tx).to.equal(MULTISIG_WALLET);
  //   });
  // });

  describe("DAO's isValidSignature Basic Functionality", function () {
    // it("set the SafeContract", async function () {
    //   safeContract = new ethers.Contract(
    //     SAFE_PROXY,
    //     CompatibilityFallbackHandler_ABI.abi,
    //     ethers.provider
    //   );
    //   // console.log("safeContract", safeContract)
    // })

    // it("FOUNDATION CONFIRMATION", async function () {
    //   let newProtocolKit = await protocolKit.connect({
    //     signer: process.env.EXECUTE_PRIVATE_KEY,
    //     safeAddress: SAFE_PROXY,
    //   })

    //   const newSafeTxHash = await newProtocolKit.getTransactionHash(safeTx)
    //   console.log("newSafeTxHash :", newSafeTxHash)
    //   const newSignature = await newProtocolKit.signHash(newSafeTxHash)

    //   const newSignatureResponse = await apiKit.confirmTransaction(
    //     newSafeTxHash,
    //     newSignature.data
    //   )
    //   console.log("newSignatureResponse :", newSignatureResponse)
    // })

    it("isValidSignature GovernanceFlow test passed", async function () {
      // let beforeOwner = await proxyAdmin.owner()
      // expect(beforeOwner).to.equal(originalOwner)

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

      // let protocolKit2 = await protocolKit.connect({
      //   signer: process.env.OWNER_PRIVATE_KEY,
      //   safeAddress: DAO_COMMITTEE_PROXY,
      // })

      let chainId = await protocolKit.getChainId()
      console.log('체인 ID:', chainId)

      let safeVersion = await protocolKit.getContractVersion()
      console.log("safeVersion", safeVersion)

      const safeTxHash = await protocolKit.getTransactionHash(safeTx)
      console.log("safeTxHash", safeTxHash)
      expect(safeTxHash).to.equal(testHash);

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

      const contractSignature = await buildContractSignature(
        Array.from(multiSigSigns.signatures.values()),
        DAO_COMMITTEE_PROXY!
      )

      safeTx.addSignature(contractSignature)

      let checkSignature = buildSignatureBytes([
        safeTx.getSignature(DAO_COMMITTEE_PROXY) as SafeSignature,
      ])
      // console.log("checkSignature : ", checkSignature)

      let sigLength = 196
      const makeSignature = "0x" + checkSignature.substring(sigLength);
      // console.log("makeSignature : ", makeSignature)

      // const result = await daoCommitteeV2.callStatic.isValidSignature(txHashData, makeSignature);
      // expect(result).to.equal(MAGIC_VALUE);

      const transaction = await apiKit.getTransaction(
        testHash
      )
      console.log("transaction", transaction)

      const orginSign = await protocolKit
        .toSafeTransactionType(transaction)
        .then((safeTx) => Array.from(safeTx.signatures.values())[0])

      console.log("orginSign", orginSign)

      const orginSign2 = await protocolKit
        .toSafeTransactionType(transaction)
        .then((safeTx) => Array.from(safeTx.signatures.values())[1])

      console.log("orginSign2 :", orginSign2)

      let sumSignature = buildSignatureBytes([
        orginSign,
        safeTx.getSignature(DAO_COMMITTEE_PROXY!) as SafeSignature,
      ])

      console.log("sumSignature", sumSignature)
      console.log("sumSignature.length", sumSignature.length)

      const signatureResponse = await apiKit.confirmTransaction(
        safeTxHash,
        sumSignature
      )
      console.log("signatureResponse", signatureResponse)

      const safeTransaction = await protocolKit.toSafeTransactionType(transaction)
      safeTransaction.encodedSignatures = () => {
        return signatureResponse.signature
      }
      const data = await protocolKit.getEncodedTransaction(safeTransaction)
      console.log(data)

      //account Setting
      const account = privateKeyToAccount(process.env.EXECUTE_PRIVATE_KEY as Hex)
      const client = createWalletClient({
        account,
        chain: sepolia,
        transport: http("https://eth-sepolia.api.onfinality.io/public"),
      })

      //send data
      const hash = await client.sendTransaction({
        to: SAFE_PROXY as `0x${string}`,
        data: data as Hex,
      })
      console.log(hash)

    });

  });


});