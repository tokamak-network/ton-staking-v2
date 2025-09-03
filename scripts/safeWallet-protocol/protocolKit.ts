// This script demonstrates how to sign a transaction using the Safe Protocol Kit.
// Please replace the placeholder values with your actual data.

// You need to install the following packages:
// npm install @safe-global/protocol-kit ethers dotenv

import 'dotenv/config'
import Safe, {
    EthSafeSignature,
    PredictedSafeProps,
    SafeAccountConfig,
    buildContractSignature,
    buildSignatureBytes,
    hashSafeMessage
} from '@safe-global/protocol-kit'
import { SigningMethod } from '@safe-global/types-kit';
import SafeApiKit from '@safe-global/api-kit'
import hre, { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

// Load environment variables
const RPC_URL = process.env.ETH_NODE_URI_sepolia;
const OWNER_PRIVATE_KEY = process.env.OWNER_PRIVATE_KEY;
const OWNER_PRIVATE_KEY2 = process.env.OWNER_PRIVATE_KEY2;
const SAFE_ADDRESS = process.env.SAFE_ADDRESS;
const DAO_ADDRESS = process.env.DAO_ADDRESS;
const MULTISIG_ADDRESS = process.env.MULTISIG_ADDRESS;
const SAFE_API_KEY = process.env.SAFE_API_KEY;

let multiSigOwner1: SignerWithAddress;
let multiSigOwner2: SignerWithAddress;
let daoCommitteeV2: Contract;

const DAOCommittee_V2_ABI = require("../../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;

if (!RPC_URL || !OWNER_PRIVATE_KEY || !OWNER_PRIVATE_KEY2 || !SAFE_ADDRESS || !DAO_ADDRESS) {
    throw new Error("Please make sure you have a .env file with RPC_URL, OWNER_PRIVATE_KEY, and SAFE_ADDRESS variables.");
}

// const provider = new ethers.JsonRpcProvider(RPC_URL);
// const wallet = new ethers.Wallet(OWNER_PRIVATE_KEY, provider);

async function main(): Promise<void> {
    [multiSigOwner1, multiSigOwner2] = await ethers.getSigners();

    let daoAddress = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
    const MAGIC_VALUE = "0x1626ba7e";

    // Create upgraded proxy interface
    daoCommitteeV2 = new ethers.Contract(
        daoAddress,
        DAOCommittee_V2_ABI,
        multiSigOwner1
    );

    // Check if multiSigWallet is set
    try {
        const multiSigWalletAddress = await daoCommitteeV2.multiSigWallet();
        console.log("Current MultiSigWallet address:", multiSigWalletAddress);

        if (multiSigWalletAddress === "0x0000000000000000000000000000000000000000") {
            console.log("❌ MultiSigWallet is not set (address(0))");
            return;
        }

        // Check if multiSigWallet has admin role
        const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const hasAdminRole = await daoCommitteeV2.hasRole(DEFAULT_ADMIN_ROLE, multiSigWalletAddress);
        console.log("MultiSigWallet has admin role:", hasAdminRole);

        if (!hasAdminRole) {
            console.log("❌ MultiSigWallet does not have DEFAULT_ADMIN_ROLE");
            return;
        }
    } catch (error) {
        console.log("Error checking MultiSigWallet setup:", error);
        return;
    }

    const safeAccountConfig: SafeAccountConfig = {
        owners: ['0x80047c450ee203c4A970A7005d6cd30b2F34C98f', '0x6E1c4a442E9B9ddA59382ee78058650F1723E0F6', '0x3bFda92Fa3bC0AB080Cac3775147B6318b1C5115'],
        threshold: 2
        // More optional properties
    }

    const predictedSafe: PredictedSafeProps = {
        safeAccountConfig
        // More optional properties
    }

    let protocolKit = await Safe.init({
        provider: RPC_URL!,
        signer: OWNER_PRIVATE_KEY!,
        predictedSafe
    })

    // // 2. 메인 Safe 인스턴스 생성 (DAOContract가 소유자인 Safe)
    // const mainSafeKit = await Safe.init({
    //     provider: RPC_URL!,
    //     signer: OWNER_PRIVATE_KEY!,
    //     safeAddress: SAFE_ADDRESS!
    // });


    // 3. Safe 트랜잭션 데이터 생성
    const safeTransactionData = {
        "to": "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea",
        "data": "0x",
        "value": "20000000000000000",
        "operation": 0,
        "baseGas": "0",
        "gasPrice": "0",
        "gasToken": "0x0000000000000000000000000000000000000000",
        "nonce": 0,
        "refundReceiver": "0x0000000000000000000000000000000000000000",
        "safeTxGas": "0"
    }

    // const safeTransaction = await protocolKit.createTransaction({
    let transactionSafe2_3 = await protocolKit.createTransaction({
        transactions: [safeTransactionData]
    });

    // Connect OWNER_4_ADDRESS(MultiSigWallet의 Owner) and the address of SAFE_2_3_ADDRESS(MultiSigWallet)
    protocolKit = await protocolKit.connect({
        provider: RPC_URL!,
        signer: OWNER_PRIVATE_KEY!,
        safeAddress: MULTISIG_ADDRESS!
    })


    // Sign the transactionSafe2_3 with OWNER_4_ADDRESS
    // After this, the transactionSafe2_3 contains the signature from OWNER_4_ADDRESS
    // Parent Safe Address => SafeWalletAddress
    transactionSafe2_3 = await protocolKit.signTransaction(
        transactionSafe2_3,
        SigningMethod.SAFE_SIGNATURE,
        SAFE_ADDRESS // Parent Safe address
    )
    
    // Connect OWNER_5_ADDRESS(MultiSigWallet의 Owner2)
    protocolKit = await protocolKit.connect({
        provider: RPC_URL,
        signer: OWNER_PRIVATE_KEY2
    })
    
    // Sign the transactionSafe2_3 with OWNER_5_ADDRESS
    // After this, the transactionSafe2_3 contains the signature from OWNER_5_ADDRESS
    transactionSafe2_3 = await protocolKit.signTransaction(
        transactionSafe2_3,
        SigningMethod.SAFE_SIGNATURE,
        SAFE_ADDRESS // Parent Safe address
    )

    // Build the contract signature of SAFE_2_3_ADDRESS
    const signatureSafe2_3 = await buildContractSignature(
        Array.from(transactionSafe2_3.signatures.values()),
        DAO_ADDRESS!
    )
    // console.log("signatureSafe2_3 : ", signatureSafe2_3);
    
    // Add the signatureSafe2_3 to safeTransaction
    // After this, the safeTransaction contains the signature from OWNER_1_ADDRESS, OWNER_2_ADDRESS, SAFE_1_1_ADDRESS and SAFE_2_3_ADDRESS
    transactionSafe2_3.addSignature(signatureSafe2_3)

    const safeTransactionHash = await protocolKit.getTransactionHash(transactionSafe2_3)
    
    const signerSafeSig2_3 = transactionSafe2_3.getSignature(DAO_ADDRESS!) as EthSafeSignature
    // 4. Safe 트랜잭션 해시 생성
    // 트랜잭션 해시 생성
    // const txHash = await mainSafeKit.getTransactionHash(safeTransaction);
    // console.log("Safe Transaction Hash:", txHash);

    const safeTxHash = "0x34148392eddee2686a39b6da312a95afdbf953bef85122e5b0c73f3b624cba8f"
    // const messageHash = "0x6370ebc01fb12eade1b75e7c107e2872d7a97f6cbc364514189f7da6b049d6fb"

    const signatures = await createMultipleSignatures(
        [multiSigOwner1, multiSigOwner2],
        safeTransactionHash
    );

    console.log("signerSafeSig2_3 :", signerSafeSig2_3)
    console.log("signatures :", signatures)

    // console.log("safeTransactionHash :", safeTransactionHash)
    // console.log("safeTxHash :", safeTxHash)

    const result = await daoCommitteeV2.isValidSignature(safeTransactionHash, signatures);
    // console.log(result)
    if (result == MAGIC_VALUE) {
        console.log("pass the DAOContract signature")
    } else {
        console.log("fail the Sign")
    }

    const apiKit = new SafeApiKit({
        chainId: 11155111n,
        apiKey: SAFE_API_KEY
    });

    await apiKit.confirmTransaction(
        safeTransactionHash,
        buildSignatureBytes([signerSafeSig2_3])
    )

    // await apiKit.confirmTransaction(
    //     txHash,
    //     signatures
    // );
    console.log("Transaction confirmed with DAO approval!");

    
    // const MESSAGE = "save" 
    // const messageHash = hashSafeMessage(MESSAGE)

    // const isValid = await protocolKit.isValidSignature(messageHash, '0x')
    // console.log(isValid)

    // const daoContractSignature = await buildContractSignature(
    //     Array.from(multiSigTransaction.signatures.values()),  // MultiSigWallet의 2개 서명 배열
    //     DAO_ADDRESS!  // DAOContract 주소 (EIP-1271 구현체)
    // );

    // safeTransaction.addSignature(signatures)
}

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

main().catch((error) => {
    console.error(error);
    process.exit(1);
});