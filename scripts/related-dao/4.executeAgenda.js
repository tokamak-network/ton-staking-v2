const hre = require("hardhat");
const { ethers } = hre;

const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const DAOCommittee_V2ABI = require("../../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;

async function main() {

    // signer는 Candidate Contract의 operator여야함
    const [signer] = await ethers.getSigners();
    console.log("voter address:", signer.address);

    
    let daoAgendaManagerAddr = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08";
    let daoCommitteeProxyAddr = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";

    //==== Set DAOLogicV2 =================================
    let daoLogicV2 = new ethers.Contract(
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

    //가장 최신 AgendaID
    let agendaID = (await daoagendaManager.numAgendas()).sub(1);


    const agenda = await daoagendaManager.agendas(agendaID);
    
    await daoLogicV2.connect(deployer).executeAgenda(agendaID);
    console.log("executed agendaID :", agendaID)

}

// 스크립트 실행
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
});
