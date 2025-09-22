const { ethers } = require("hardhat");

async function analyzeSignatureV2() {
    const hash = "0x644a6c15e3d1cf448599d487c6f3fe68e93e891205961df6fb5950ff3cf45c66";
    const signature = "0x9e77e9dd73703da05391e6d303891802c4ae677f8e3582d2d27de52391b0bac11d81497fcf36d63b42fcab38cd7d8712aebda9f663f4b21b6f409316b4bf323b1f";
    const expectedSigner = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";

    console.log("=== 서명 분석 (V2) ===");
    console.log("Hash:", hash);
    console.log("Signature:", signature);
    console.log("Expected Signer:", expectedSigner);

    // 서명을 r, s, v로 분해
    const r = signature.slice(0, 66);
    const s = "0x" + signature.slice(66, 130);
    const v = signature.slice(130, 132);
    const vDecimal = parseInt(v, 16);

    console.log("\n=== 서명 분해 ===");
    console.log("r:", r);
    console.log("s:", s);
    console.log("v:", v, "(decimal:", vDecimal, ")");

    // v 값을 27, 28로 조정하여 시도
    console.log("\n=== v 값 조정 시도 ===");
    
    for (let recoveryId = 0; recoveryId < 2; recoveryId++) {
        const adjustedV = 27 + recoveryId;
        const adjustedSignature = r + s.slice(2) + adjustedV.toString(16).padStart(2, '0');
        
        console.log(`\n--- Recovery ID: ${recoveryId}, v: ${adjustedV} ---`);
        
        // 1. 직접 해시 복구
        try {
            const recoveredSigner1 = ethers.utils.recoverAddress(hash, adjustedSignature);
            console.log("Direct recovery:", recoveredSigner1);
            console.log("Match:", recoveredSigner1.toLowerCase() === expectedSigner.toLowerCase());
        } catch (error) {
            console.log("Direct recovery error:", error.message);
        }

        // 2. Ethereum Signed Message prefix
        try {
            const messageHash = ethers.utils.hashMessage(ethers.utils.arrayify(hash));
            const recoveredSigner2 = ethers.utils.recoverAddress(messageHash, adjustedSignature);
            console.log("Prefix recovery:", recoveredSigner2);
            console.log("Match:", recoveredSigner2.toLowerCase() === expectedSigner.toLowerCase());
        } catch (error) {
            console.log("Prefix recovery error:", error.message);
        }

        // 3. EIP-155 체인 ID 고려 (Sepolia = 11155111)
        const chainId = 11155111;
        const eip155V = recoveryId + 2 * chainId + 35;
        console.log(`EIP-155 v for chain ${chainId}: ${eip155V}`);
        
        if (eip155V === vDecimal) {
            console.log("✅ EIP-155 v 값과 일치!");
            console.log(`Recovery ID: ${recoveryId}`);
        }
    }

    // 4. 다른 체인 ID들도 시도
    console.log("\n=== 다른 체인 ID 시도 ===");
    const commonChainIds = [1, 3, 4, 5, 42, 137, 250, 43114, 56, 1284, 1285, 1287, 11155111];
    
    for (const chainId of commonChainIds) {
        for (let recoveryId = 0; recoveryId < 2; recoveryId++) {
            const eip155V = recoveryId + 2 * chainId + 35;
            if (eip155V === vDecimal) {
                console.log(`✅ Chain ID ${chainId}, Recovery ID ${recoveryId}에서 v 값 일치!`);
                
                const adjustedV = 27 + recoveryId;
                const adjustedSignature = r + s.slice(2) + adjustedV.toString(16).padStart(2, '0');
                
                try {
                    const recoveredSigner = ethers.utils.recoverAddress(hash, adjustedSignature);
                    console.log("Recovered Signer:", recoveredSigner);
                    console.log("Match:", recoveredSigner.toLowerCase() === expectedSigner.toLowerCase());
                } catch (error) {
                    console.log("Recovery error:", error.message);
                }
            }
        }
    }
}

analyzeSignatureV2().catch(console.error);
