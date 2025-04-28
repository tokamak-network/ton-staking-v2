const { ethers } = require("hardhat");

async function deployCandidateAddOnFactory() {
    //==== CandidateAddOnFactory =================================
    const CandidateAddOnFactoryDep = await ethers.getContractFactory("CandidateAddOnFactory");
    const CandidateAddOnFactory = await CandidateAddOnFactoryDep.deploy();
    await CandidateAddOnFactory.deployed()

    // console.log('tx' , tx)
    console.log('CandidateAddOnFactory' , CandidateAddOnFactory.address)
}

const main = async () => {
  await deployCandidateAddOnFactory()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
