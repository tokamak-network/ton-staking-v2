const hre = require("hardhat");
const { ethers } = hre;

const DAOCommittee_V2ABI = require("../../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const MultiSigWalletABI = require("../../abi/MultiSigWallet.json").abi;


async function main() {
    // MultiSigWallet can only be executed by Owners. 
    // The Owners currently set in Sepolia are as follows:
    let Owenrs = [
        "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea",
        "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2",
        "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
    ]

    // removeBlackList Candidate contract address (enter manually)
    const CANDIDATE_ADDRESS = "0xF078AE62eA4740E19ddf6c0c5e17Ecdb820BbEe1"; // Enter the Candidate contract address you want to remove from the blacklist here
    
    
    // 네트워크 확인
    const network = await ethers.provider.getNetwork();
    console.log("Network:", network.name);
    console.log("Chain ID:", network.chainId);
    
    let daoCommitteeProxyAddr = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
    let daoAgendaManagerAddr = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08";
    let tonAddr = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044";
    let multiSigWalletAddr = "0x82460E7D90e19cF778a2C09DcA75Fc9f79Da877C"


    // signer는 Candidate Contract의 operator여야함
    const [signer] = await ethers.getSigners();
    console.log("Signer address:", signer.address);
    
    // =========================================
    // Owner 권한 확인
    console.log("=== Owner 권한 확인 ===");
    console.log("현재 Signer:", signer.address);
    console.log("등록된 Owners:");
    Owenrs.forEach((owner, index) => {
        console.log(`  ${index + 1}. ${owner}`);
    });
    
    // signer가 Owner 중 하나인지 확인
    const isOwner = Owenrs.some(owner => owner.toLowerCase() === signer.address.toLowerCase());
    
    if (!isOwner) {
        console.error("❌ 실행 불가: 현재 signer가 등록된 Owner가 아닙니다.");
        console.error("Owner 중 하나의 계정으로 실행해주세요.");
        process.exit(1);
    }
    
    console.log("✅ Owner 권한 확인 완료 - 실행 가능합니다.");


    //==== Set DAOCommitteeProxy =================================
    let daoCommitteeProxy = new ethers.Contract(
        daoCommitteeProxyAddr,
        DAOCommitteeProxyABI,
        ethers.provider
    )

    //==== Set DAOCommitteeV2 =================================
    let daoCommitteeV2 = new ethers.Contract(
        daoCommitteeProxyAddr,
        DAOCommittee_V2ABI,
        ethers.provider
    )

    //==== Set MultiSigWallet =================================
    let MultiSigWallet = new ethers.Contract(
        multiSigWalletAddr,
        MultiSigWalletABI,
        ethers.provider
    )

    // =========================================
    // removeFromBlacklist from MultiSigWallet

    console.log("=== Check Blacklist Status ===");

    let isBlacklisted = await daoCommitteeV2.blacklist(CANDIDATE_ADDRESS);

    if(isBlacklisted) {
        const data = DAOCommitteeV2.interface.encodeFunctionData(
            "removeFromBlacklist",
            [CANDIDATE_ADDRESS]
        )
    
        await MultiSigWallet.connect(signer).submitTransaction(
            daoCommitteeProxyAddr,  
            0,
            data
        );
    } 

}

// 스크립트 실행
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
});
