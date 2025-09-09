import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

import semverSatisfies from 'semver/functions/satisfies.js'

import {
  SafeTransaction,
  SafeTransactionData,
  EIP712TypedData,
  TypedMessageTypes,
  TypedDataTypes,
  EIP712TxTypes,
  SafeSignature
} from '@safe-global/types-kit'

import { 
  keccak256, 
  isHex,
  toHex, 
  Hex, 
  HashTypedDataParameters, 
  getTypesForEIP712Domain, 
  validateTypedData, 
  hashDomain, 
  concat, 
  AbiParameter,
  encodeAbiParameters 
} from 'viem'


/// const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommittee_V2_ABI = require("../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;
const MultiSigWallet_ABI = require("../abi/MultiSigWallet.json");

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
  // const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
  const testHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EIP-1271 test message"));
  const txHash = "0x34148392eddee2686a39b6da312a95afdbf953bef85122e5b0c73f3b624cba8f"
  const testHash2 = "0x644a6c15e3d1cf448599d487c6f3fe68e93e891205961df6fb5950ff3cf45c66"
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
    it("should return magic value for valid signatures", async function () {
      const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        testHash2
      );
      // console.log("testHash2", testHash2);
      // console.log("signatures", signatures);

      const result = await daoCommitteeV2.callStatic.isValidSignature(txHash, signatures);
      console.log("result", result);
      expect(result).to.equal(MAGIC_VALUE);
    });

    it("check the ", async function () {

    });

    // it("should return invalid signature for wrong signatures", async function () {
    //   const signatures = await createMultipleSignatures(
    //     [nonOwner, multiSigOwner1],
    //     testHash2
    //   );

    //   const tx = await daoCommitteeV2.isValidSignature(testHash, signatures);
    //   const result = await tx.wait();
    //   console.log("tx", tx);
    //   console.log("result", result);
    //   expect(result).to.equal(INVALID_SIGNATURE);
    // });

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
  

  async function signHash(hash: string): Promise<SafeSignature> {
    const isPasskeySigner = await this.#safeProvider.isPasskeySigner()
    const signerAddress = await this.#safeProvider.getSignerAddress()

    if (isPasskeySigner && signerAddress) {
      let signature = await this.#safeProvider.signMessage(hash)

      signature = await adjustVInSignature(SigningMethod.ETH_SIGN, signature, hash, signerAddress)

      const safeSignature = new EthSafeSignature(signerAddress, signature, true)

      return safeSignature
    }

    const signature = await generateSignature(this.#safeProvider, hash)

    return signature
  }
  


});