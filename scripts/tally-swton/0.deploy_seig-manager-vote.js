const { ethers } = require("hardhat");
const SeigManagerV1_Vote_Json = require('../../abi/SeigManagerV1_Vote.json')

// sepolia
const SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
const TokamakVoteERC20Address = "0xE9394DAE067eF993Bb79d98917799CfA48BC83F0"

async function SeigManagerV1_Vote() {

  //==== SeigManagerV1_Vote =================================
  const SeigManagerV1_VoteDep = await ethers.getContractFactory("SeigManagerV1_Vote");
  const SeigManagerV1_Vote = await SeigManagerV1_VoteDep.deploy();
  await SeigManagerV1_Vote.deployed();
  console.log('SeigManagerV1_Vote' , SeigManagerV1_Vote.address)
}

async function set_seigManager_vote() {

  const accounts = await ethers.getSigners()
  const deployer = accounts[0]
  const deployerAddress = await deployer.getAddress()

  console.log("deployer", deployerAddress)

  const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManagerV1_Vote_Json.abi, deployer)

  let voteToken = await seigManager.voteToken();
  console.log('voteToken' , voteToken)

  await (await seigManager.connect(deployer).setVoteToken(TokamakVoteERC20Address)).wait()

  voteToken = await seigManager.voteToken();
  console.log('voteToken' , voteToken)
}

const main = async () => {
    // await SeigManagerV1_Vote()
    await set_seigManager_vote()
}


  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
