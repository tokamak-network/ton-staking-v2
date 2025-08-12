const hre = require("hardhat");
const { ethers } = hre;
const MultiSigWallet_ABI = require("../abi/MultiSigWallet.json");

async function main() {
    console.log("=== ERC-1271 사용 예시 ===");
    
    const [owner1, owner2, owner3, user] = await ethers.getSigners();
    
    // 1. MultiSigWallet 배포
    console.log("\n1. MultiSigWallet 배포 중...");
    const MultiSigWallet = new ethers.ContractFactory(MultiSigWallet_ABI.abi, MultiSigWallet_ABI.bytecode, owner1);
    const multiSigWallet = await MultiSigWallet.deploy([owner1.address, owner2.address, owner3.address]);
    await multiSigWallet.deployed();
    console.log("MultiSigWallet 배포됨:", multiSigWallet.address);
    
    // 2. DAOCommittee_V2 배포
    console.log("\n2. DAOCommittee_V2 배포 중...");
    const DAOCommittee = await ethers.getContractFactory("DAOCommittee_V2");
    const daoCommittee = await DAOCommittee.deploy();
    await daoCommittee.deployed();
    console.log("DAOCommittee_V2 배포됨:", daoCommittee.address);
    
    // 3. ERC1271Helper 배포
    console.log("\n3. ERC1271Helper 배포 중...");
    const ERC1271Helper = await ethers.getContractFactory("ERC1271Helper");
    const erc1271Helper = await ERC1271Helper.deploy();
    await erc1271Helper.deployed();
    console.log("ERC1271Helper 배포됨:", erc1271Helper.address);
    
    // 4. MultiSigWallet 주소 설정
    console.log("\n4. MultiSigWallet 주소 설정 중...");
    await daoCommittee.setMultiSigWallet(multiSigWallet.address);
    console.log("MultiSigWallet 주소 설정 완료");
    
    // 5. ERC-1271 서명 검증 예시
    console.log("\n5. ERC-1271 서명 검증 예시");
    
    const message = "DAO Committee approves this action";
    const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));
    console.log("메시지:", message);
    console.log("해시:", hash);
    
    // MultiSigWallet owner들의 서명 생성
    console.log("\nMultiSigWallet owner들이 서명 생성 중...");
    const signature1 = await owner1.signMessage(ethers.utils.toUtf8Bytes(message));
    const signature2 = await owner2.signMessage(ethers.utils.toUtf8Bytes(message));
    console.log("Owner1 서명:", signature1);
    console.log("Owner2 서명:", signature2);
    
    // 서명들을 연결 (0x 제거하고 연결)
    const combinedSignature = signature1 + signature2.slice(2);
    console.log("연결된 서명:", combinedSignature);
    
    // 6. DAO Committee에서 직접 검증
    console.log("\n6. DAO Committee에서 직접 검증");
    const result = await daoCommittee.isValidSignature(hash, combinedSignature);
    console.log("검증 결과:", result);
    console.log("유효한 서명:", result === "0x1626ba7e");
    
    // 7. ERC1271Helper를 통한 검증
    console.log("\n7. ERC1271Helper를 통한 검증");
    const isValid = await erc1271Helper.isValidSignature(
        daoCommittee.address, 
        hash, 
        combinedSignature
    );
    console.log("ERC1271Helper 검증 결과:", isValid);
    
    // 8. 잘못된 서명 테스트
    console.log("\n8. 잘못된 서명 테스트");
    const wrongSignature = await user.signMessage(ethers.utils.toUtf8Bytes(message));
    const wrongResult = await daoCommittee.isValidSignature(hash, wrongSignature);
    console.log("잘못된 서명 검증 결과:", wrongResult);
    console.log("유효하지 않은 서명:", wrongResult === "0xffffffff");
    
    // 9. 실제 사용 시나리오 예시
    console.log("\n9. 실제 사용 시나리오 예시");
    console.log("=== 오프체인 주문 서명 검증 ===");
    
    const orderData = {
        token: "0x1234567890123456789012345678901234567890",
        amount: "1000000000000000000", // 1 ETH
        price: "2000000000000000000000", // 2000 USDC
        nonce: Date.now(),
        expiry: Math.floor(Date.now() / 1000) + 3600 // 1시간 후 만료
    };
    
    const orderHash = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256", "uint256", "uint256"],
            [orderData.token, orderData.amount, orderData.price, orderData.nonce, orderData.expiry]
        )
    );
    
    console.log("주문 데이터:", orderData);
    console.log("주문 해시:", orderHash);
    
    // DAO Committee가 주문을 승인하는 서명
    const orderSignature1 = await owner1.signMessage(ethers.utils.arrayify(orderHash));
    const orderSignature2 = await owner2.signMessage(ethers.utils.arrayify(orderHash));
    const orderCombinedSignature = orderSignature1 + orderSignature2.slice(2);
    
    // 주문 서명 검증
    const orderValidation = await daoCommittee.isValidSignature(orderHash, orderCombinedSignature);
    console.log("주문 서명 검증 결과:", orderValidation);
    console.log("주문 승인됨:", orderValidation === "0x1626ba7e");
    
    console.log("\n=== ERC-1271 구현 완료 ===");
    console.log("이제 DAO Committee는 MultiSigWallet owner들의 서명을 통해");
    console.log("ERC-1271 표준에 맞는 서명 검증이 가능합니다.");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 