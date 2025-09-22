const { ethers } = require("hardhat");

async function analyzeSignature() {
    const hash = "0x644a6c15e3d1cf448599d487c6f3fe68e93e891205961df6fb5950ff3cf45c66";
    const signature = "0x9e77e9dd73703da05391e6d303891802c4ae677f8e3582d2d27de52391b0bac11d81497fcf36d63b42fcab38cd7d8712aebda9f663f4b21b6f409316b4bf323b1f";
    const expectedSigner = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";

    console.log("=== 서명 분석 ===");
    console.log("Hash:", hash);
    console.log("Signature:", signature);
    console.log("Expected Signer:", expectedSigner);
    console.log("Signature length:", signature.length);

    // 서명을 r, s, v로 분해
    const r = signature.slice(0, 66); // 0x + 64자리
    const s = "0x" + signature.slice(66, 130); // 64자리
    const v = signature.slice(130, 132); // 2자리

    console.log("\n=== 서명 분해 ===");
    console.log("r:", r);
    console.log("s:", s);
    console.log("v:", v);

    // v 값을 10진수로 변환
    const vDecimal = parseInt(v, 16);
    console.log("v (decimal):", vDecimal);

    // 1. 직접 해시 복구 (prefix 없음)
    console.log("\n=== 1. 직접 해시 복구 ===");
    try {
        const recoveredSigner1 = ethers.utils.recoverAddress(hash, signature);
        console.log("Recovered Signer (direct):", recoveredSigner1);
        console.log("Match:", recoveredSigner1.toLowerCase() === expectedSigner.toLowerCase());
    } catch (error) {
        console.log("Error in direct recovery:", error.message);
    }

    // 2. Ethereum Signed Message prefix 사용
    console.log("\n=== 2. Ethereum Signed Message prefix ===");
    try {
        const messageHash = ethers.utils.hashMessage(ethers.utils.arrayify(hash));
        const recoveredSigner2 = ethers.utils.recoverAddress(messageHash, signature);
        console.log("Message Hash:", messageHash);
        console.log("Recovered Signer (with prefix):", recoveredSigner2);
        console.log("Match:", recoveredSigner2.toLowerCase() === expectedSigner.toLowerCase());
    } catch (error) {
        console.log("Error in prefix recovery:", error.message);
    }

    // 3. 수동으로 prefix 추가
    console.log("\n=== 3. 수동 prefix 추가 ===");
    try {
        const prefix = "\x19Ethereum Signed Message:\n32";
        const prefixedHash = ethers.utils.keccak256(ethers.utils.solidityPack(["string", "bytes32"], [prefix, hash]));
        const recoveredSigner3 = ethers.utils.recoverAddress(prefixedHash, signature);
        console.log("Prefixed Hash:", prefixedHash);
        console.log("Recovered Signer (manual prefix):", recoveredSigner3);
        console.log("Match:", recoveredSigner3.toLowerCase() === expectedSigner.toLowerCase());
    } catch (error) {
        console.log("Error in manual prefix recovery:", error.message);
    }

    // 4. v 값 조정 (27, 28로 변환)
    console.log("\n=== 4. v 값 조정 ===");
    if (vDecimal > 30) {
        const adjustedV = vDecimal - 27;
        const adjustedSignature = r + s.slice(2) + adjustedV.toString(16).padStart(2, '0');
        
        try {
            const recoveredSigner4 = ethers.utils.recoverAddress(hash, adjustedSignature);
            console.log("Adjusted v:", adjustedV);
            console.log("Adjusted Signature:", adjustedSignature);
            console.log("Recovered Signer (adjusted v):", recoveredSigner4);
            console.log("Match:", recoveredSigner4.toLowerCase() === expectedSigner.toLowerCase());
        } catch (error) {
            console.log("Error in adjusted v recovery:", error.message);
        }
    }

    // 5. Safe Wallet 방식 (getMessageHash 사용)
    console.log("\n=== 5. Safe Wallet 방식 ===");
    try {
        // Safe의 getMessageHash 함수 시뮬레이션
        const safeMessageHash = ethers.utils.keccak256(
            ethers.utils.solidityPack(["bytes32"], [hash])
        );
        const recoveredSigner5 = ethers.utils.recoverAddress(safeMessageHash, signature);
        console.log("Safe Message Hash:", safeMessageHash);
        console.log("Recovered Signer (Safe way):", recoveredSigner5);
        console.log("Match:", recoveredSigner5.toLowerCase() === expectedSigner.toLowerCase());
    } catch (error) {
        console.log("Error in Safe recovery:", error.message);
    }
}

analyzeSignature().catch(console.error);
