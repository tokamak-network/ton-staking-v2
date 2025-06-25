const hre = require("hardhat");
const { ethers } = hre;

const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const CandidateABI = require("../../abi/Candidate.json").abi;

async function main() {

    // signer는 Candidate Contract의 operator여야함
    const [signer] = await ethers.getSigners();
    console.log("voter address:", signer.address);

    
    let daoAgendaManagerAddr = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08";
    
    //Member address : 0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea
    let MemberContractAddr = "0xbdbb2c17846027c75802464d4afdd23a9192e103"
    //Member address : 0x757de9c340c556b56f62efae859da5e08baae7a2
    // let MemberContractAddr = "0xabd15c021942ca54abd944c91705fe70fea13f0d"

    //==== Set MemberContract =================================
    let memberContract = new ethers.Contract(
        MemberContractAddr,
        CandidateABI,
        ethers.provider
    )

    //==== Set DAOAgendaManager =================================
    let daoagendaManager = new ethers.Contract(
        daoAgendaManagerAddr,
        DAOAgendaManagerABI,
        ethers.provider
    )

    //가장 최신 AgendaID
    let agendaID = (await daoagendaManager.numAgendas()).sub(1);
    console.log("AgendaID : ", agendaID);
    
    const agenda = await daoagendaManager.agendas(agendaID);  

    // const beforeCountingYes = agenda[7];
    // const beforeCountingNo = agenda[8];
    // const beforeCountingAbstain = agenda[9];
    
    const vote = 1

    // counting 0:abstainVotes 1:yesVotes 2:noVotes
    await memberContract.connect(signer).castVote(
        agendaID,
        vote,
        "vote"
    )
    console.log("vote done")

}

// 스크립트 실행
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
});
