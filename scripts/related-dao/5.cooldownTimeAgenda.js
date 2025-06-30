const hre = require("hardhat");
const { ethers } = hre;

const DAOCommittee_V2ABI = require("../../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const TonABI = require("../../abi/TON.json").abi;
const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const DAOCommitteeOwnerABI = require("../../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;

const Web3EthAbi = require('web3-eth-abi');

async function main() {
    // Address of candidate who wants to check cooldown time (enter manually)
    const CANDIDATE_ADDRESS = "0xF078AE62eA4740E19ddf6c0c5e17Ecdb820BbEe1"; 


    // make the Cooldown Agenda
    let createAgenda = false
    
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

    //==== Set DAOCommitteeOwner =================================
    let daoCommitteeOwner = new ethers.Contract(
        daoCommitteeProxyAddr,
        DAOCommitteeOwnerABI,
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
    // 1. Check the currently set cooldownTime

    console.log("=== Check CooldownTime Status ===");

    let currentCooldownTime = await daoCommitteeOwner.cooldownTime();
    console.log(`Now Setting cooldownTime: ${currentCooldownTime} seconds`);


    // =========================================
    // 2. Check the cooldown status of a specific candidate
    if(CANDIDATE_ADDRESS != "") {
        let candidateCooldown = await daoCommitteeOwner.cooldown(CANDIDATE_ADDRESS);
        const currentTime = Math.floor(Date.now() / 1000);
        
        console.log(`Cooldown time for candidate ${CANDIDATE_ADDRESS}: ${candidateCooldown}`);
        
        if (candidateCooldown > currentTime) {
            const remainingTime = candidateCooldown - currentTime;
            console.log(`⏰ Cooldown remaining time: ${remainingTime} seconds`);
            console.log(`Cooldown is about to expire: ${new Date(candidateCooldown * 1000)}`);
        } else {
            console.log("✅ Cooldown has expired and changeMember can be executed.");
        }
    }


    
    // =========================================
    // . make an agenda
    if (createAgenda) {
        let changedcooldownTime = 300
    
        targets.push(daoCommitteeProxyAddr)
        callDtata = daoCommitteeOwner.interface.encodeFunctionData("setCooldownTime", [changedcooldownTime])
        params.push(callDtata)
    
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

}

// 스크립트 실행
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
});
