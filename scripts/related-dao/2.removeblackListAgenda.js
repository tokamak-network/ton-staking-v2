const hre = require("hardhat");
const { ethers } = hre;

const DAOCommittee_V2ABI = require("../../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const TonABI = require("../../abi/TON.json").abi;
const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;

const Web3EthAbi = require('web3-eth-abi');

async function main() {
    // removeBlackList Candidate 컨트랙트 주소 (수동으로 입력)
    const CANDIDATE_ADDRESS = "0xF078AE62eA4740E19ddf6c0c5e17Ecdb820BbEe1"; // 여기에 Candidate 컨트랙트 주소를 입력하세요
    const CANDIDATE_ADDRESS2 = "0xAbD15C021942Ca54aBd944C91705Fe70FEA13f0d"; // 여기에 Candidate 컨트랙트 주소를 입력하세요
    
    // 네트워크 확인
    const network = await ethers.provider.getNetwork();
    console.log("Network:", network.name);
    console.log("Chain ID:", network.chainId);
    
    let daoCommitteeProxyAddr = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
    let daoAgendaManagerAddr = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08";
    let tonAddr = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044";


    // signer는 Candidate Contract의 operator여야함
    const [signer] = await ethers.getSigners();
    console.log("Signer address:", signer.address);
    
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

    //==== Set DAOAgendaManager =================================
    let daoagendaManager = new ethers.Contract(
        daoAgendaManagerAddr,
        DAOAgendaManagerABI,
        ethers.provider
    )

    //==== Set TON =================================
    let ton = new ethers.Contract(
        tonAddr,
        TonABI,
        ethers.provider
    )

    //==== Create Agenda =================================
    let targets = []
    let params = []
    let callDtata

    // =========================================
    // 1. removeFromBlacklist daoCommitteeProxy2Contract
    targets.push(daoCommitteeProxyAddr)
    callDtata = daoCommitteeV2.interface.encodeFunctionData("removeFromBlacklist", [CANDIDATE_ADDRESS])
    params.push(callDtata)

    // =========================================
    // 2. removeFromBlacklist daoCommitteeProxy2Contract
    targets.push(daoCommitteeProxyAddr)
    callDtata = daoCommitteeV2.interface.encodeFunctionData("removeFromBlacklist", [CANDIDATE_ADDRESS2])
    params.push(callDtata)
  
    
    // =========================================
    // . make an agenda
    const memo = ""
    const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
    const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
    const agendaFee = await daoagendaManager.createAgendaFees();
    const param = Web3EthAbi.encodeParameters(
        ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
        [
            targets,
            noticePeriod.toString(),
            votingPeriod.toString(),
            true,
            params,
            memo
        ]
    )


    // =========================================
    // Propose an agenda
    console.log("deployerAddr :", signer.address)
    let receipt = await ton.connect(signer).approveAndCall(
        daoCommitteeProxy.address,
        agendaFee,
        param
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
