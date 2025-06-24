const hre = require("hardhat");
const { ethers } = hre;

async function main() {
    // Candidate 컨트랙트 주소 (수동으로 입력)
    const CANDIDATE_ADDRESS = "0xBdbB2C17846027c75802464d4aFdD23a9192E103"; // 여기에 Candidate 컨트랙트 주소를 입력하세요
    
    // 네트워크 확인
    const network = await ethers.provider.getNetwork();
    console.log("Network:", network.name);
    console.log("Chain ID:", network.chainId);
    
    // Candidate 컨트랙트 ABI (필요한 함수만 포함)
    const CandidateABI = [
        "function changeMember(uint256 _memberIndex) external returns (bool)",
        "function candidate() external view returns (address)",
        "function isCandidateContract() external view returns (bool)",
        "function totalStaked() external view returns (uint256)",
        "function stakedOf(address _account) external view returns (uint256)"
    ];

    // signer는 Candidate Contract의 operator여야함
    const [signer] = await ethers.getSigners();
    console.log("Signer address:", signer.address);
    
    const candidateContract = new ethers.Contract(
        CANDIDATE_ADDRESS, 
        CandidateABI, 
        ethers.provider
    );


    //change할 MemberIndex선택 
    let receipt =  await candidateContract.connect(signer).changeMember(
        1
    )

    console.log("tx Hash :", receipt.hash)
    console.log(receipt)
    console.log(receipt.nonce)

}

// 스크립트 실행
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
});
