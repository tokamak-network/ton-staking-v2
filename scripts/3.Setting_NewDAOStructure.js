const hre = require("hardhat");
const { ethers } = hre;

const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;

const Web3EthAbi = require('web3-eth-abi');

const sepoliaContractInfo = {
    DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
    DAOCommitteeProxy2: "0x5FBb951E7B7a3E2e947AF7E8565b15AA11e670fE",
    DAOCommittee_V1: "0x324715873db4fc19057acE49eD17dA0a93Ae2310",
    DAOCommitteeOwner: "0xaF23260F74806641e3307Eb567C57a4640861080"
}

const mainnetContractInfo = {
    DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26",
    DAOCommitteeProxy2: "",
    DAOCommittee_V1: "",
    DAOCommitteeOwner: ""
}

async function Setting_changeDAOStructure() {
    const [deployer] = await ethers.getSigners();
    //==== Set DAOCommitteeProxy =================================
    let daoCommitteeProxy = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOCommitteeProxyABI,
        ethers.provider
    )

    //==== pauseCheck =================================
    let pauseProxy = await daoCommitteeProxy.pauseProxy()

    if (pauseProxy == true) {
        await daoCommitteeProxy.setProxyPause(false)
    }

    console.log("pauseProxy pass")

    //==== DAOCommitteeProxy upgradeTo DAOCommitteeProxy2 =================================
    await daoCommitteeProxy.connect(deployer).upgradeTo(
        sepoliaContractInfo.DAOCommitteeProxy2
    )
    console.log("upgradeTo DAOCommitteeProxy2 done")

    //==== Set DAOCommitteeProxy2 =================================
    daoCommitteeProxy2Contract = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOProxy2ABI,
        ethers.provider
    )
    console.log("set daoCommitteeProxy2Contract done")

    //==== Set DAOCommitteeProxy2 upgradeTo2 DAOCommittee_V1 =================================
    
    await daoCommitteeProxy2Contract.connect(deployer).upgradeTo2(
        sepoliaContractInfo.DAOCommittee_V1
    )
    console.log("upgradeTo2 DAOCommittee_V1 done")

    //==== Set DAOCommitteeProxy2 setAliveImplementation2 DAOCommittee_V1 =================================
    
    await daoCommitteeProxy2Contract.connect(deployer).setAliveImplementation2(
        sepoliaContractInfo.DAOCommittee_V1, 
        true
    )
    console.log("setAliveImplementation2 DAOCommittee_V1 done")

    //==== Set DAOCommitteeProxy2 setImplementation2 DAOCommittee_V1 =================================
    
    await daoCommitteeProxy2Contract.connect(deployer).setImplementation2(
        sepoliaContractInfo.DAOCommittee_V1, 
        0, 
        true
    )
    console.log("setImplementation2 DAOCommittee_V1 done")

    //==== Set DAOCommitteeProxy2 setAliveImplementation2 DAOCommitteeOwner =================================
    
    await daoCommitteeProxy2Contract.connect(deployer).setAliveImplementation2(
        sepoliaContractInfo.DAOCommitteeOwner, 
        true
    )
    console.log("setAliveImplementation2 DAOCommitteeOwner done")

    //==== Set DAOCommitteeProxy2 setImplementation2 DAOCommitteeOwner =================================
    
    await daoCommitteeProxy2Contract.connect(deployer).setImplementation2(
        sepoliaContractInfo.DAOCommitteeOwner, 
        1, 
        true
    )
    console.log("setImplementation2 DAOCommitteeOwner done")

    //==== Set DAOCommitteeProxy2 selectorImplementations2 DAOCommitteeOwner =================================
    const _setLayer2CandidateFactory = Web3EthAbi.encodeFunctionSignature(
        "setLayer2CandidateFactory(address)"
    ) 

    const _setLayer2Manager = Web3EthAbi.encodeFunctionSignature(
        "setLayer2Manager(address)"
    ) 

    const _setTargetSetLayer2Manager = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetLayer2Manager(address,address)"
    )

    const _setTargetSetL2Registry = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetL2Registry(address,address)"
    )

    const _setTargetLayer2StartBlock = Web3EthAbi.encodeFunctionSignature(
        "setTargetLayer2StartBlock(address,uint256)"
    )

    const _setTargetSetImplementation2 = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetImplementation2(address,address,uint256,bool)"
    )

    const _setTargetSetSelectorImplementations2 = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetSelectorImplementations2(address,bytes4[],address)"
    )

    const _setSeigManager = Web3EthAbi.encodeFunctionSignature(
        "setSeigManager(address)"
    )

    const _setTargetSeigManager = Web3EthAbi.encodeFunctionSignature(
        "setTargetSeigManager(address,address)"
    )

    const _setSeigPause = Web3EthAbi.encodeFunctionSignature(
        "setSeigPause()"
    )

    const _setSeigUnpause = Web3EthAbi.encodeFunctionSignature(
        "setSeigUnpause()"
    )

    const _setTargetGlobalWithdrawalDelay = Web3EthAbi.encodeFunctionSignature(
        "setTargetGlobalWithdrawalDelay(address,uint256)"
    )

    const _setTargetAddMinter = Web3EthAbi.encodeFunctionSignature(
        "setTargetAddMinter(address,address)"
    )

    const _setTargetUpgradeTo = Web3EthAbi.encodeFunctionSignature(
        "setTargetUpgradeTo(address,address)"
    )

    const _setTargetSetTON = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetTON(address,address)"
    )
    
    const _setTargetSetWTON = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetWTON(address,address)"
    )

    const _setDaoVault = Web3EthAbi.encodeFunctionSignature(
        "setDaoVault(address)"
    )

    const _setLayer2Registry = Web3EthAbi.encodeFunctionSignature(
        "setLayer2Registry(address)"
    )

    const _setAgendaManager = Web3EthAbi.encodeFunctionSignature(
        "setAgendaManager(address)"
    )

    const _setCandidateFactory = Web3EthAbi.encodeFunctionSignature(
        "setCandidateFactory(address)"
    )

    const _setTon = Web3EthAbi.encodeFunctionSignature(
        "setTon(address)"
    )

    const _setWton = Web3EthAbi.encodeFunctionSignature(
        "setWton(address)"
    )

    const _increaseMaxMember = Web3EthAbi.encodeFunctionSignature(
        "increaseMaxMember(uint256,uint256)"
    )

    const _setQuorum = Web3EthAbi.encodeFunctionSignature(
        "setQuorum(uint256)"
    )

    const _decreaseMaxMember = Web3EthAbi.encodeFunctionSignature(
        "decreaseMaxMember(uint256,uint256)"
    )

    const _setBurntAmountAtDAO = Web3EthAbi.encodeFunctionSignature(
        "setBurntAmountAtDAO(uint256)"
    )

    const _setActivityRewardPerSecond = Web3EthAbi.encodeFunctionSignature(
        "setActivityRewardPerSecond(uint256)"
    )

    const _setCandidatesSeigManager = Web3EthAbi.encodeFunctionSignature(
        "setCandidatesSeigManager(address[],address)"
    )

    const _setCandidatesCommittee = Web3EthAbi.encodeFunctionSignature(
        "setCandidatesCommittee(address[],address)"
    )

    const _setCreateAgendaFees = Web3EthAbi.encodeFunctionSignature(
        "setCreateAgendaFees(uint256)"
    )

    const _setMinimumNoticePeriodSeconds = Web3EthAbi.encodeFunctionSignature(
        "setMinimumNoticePeriodSeconds(uint256)"
    )

    const _setMinimumVotingPeriodSeconds = Web3EthAbi.encodeFunctionSignature(
        "setMinimumVotingPeriodSeconds(uint256)"
    )

    const _setExecutingPeriodSeconds = Web3EthAbi.encodeFunctionSignature(
        "setExecutingPeriodSeconds(uint256)"
    )


    await daoCommitteeProxy2Contract.connect(deployer).setSelectorImplementations2(
            [
                _setLayer2CandidateFactory,_setLayer2Manager,_setTargetSetLayer2Manager,_setTargetSetL2Registry,
                _setTargetLayer2StartBlock,_setTargetSetImplementation2,_setTargetSetSelectorImplementations2,
                _setSeigManager,_setTargetSeigManager,_setSeigPause,_setSeigUnpause,
                _setTargetGlobalWithdrawalDelay,_setTargetAddMinter,_setTargetUpgradeTo,_setTargetSetTON,_setTargetSetWTON,
                _setDaoVault,_setLayer2Registry,_setAgendaManager,_setCandidateFactory,_setTon,_setWton,
                _increaseMaxMember,_setQuorum,_decreaseMaxMember,_setBurntAmountAtDAO,
                _setActivityRewardPerSecond,_setCandidatesSeigManager,_setCandidatesCommittee,_setCreateAgendaFees,
                _setMinimumNoticePeriodSeconds,_setMinimumVotingPeriodSeconds,_setExecutingPeriodSeconds
            ],
            sepoliaContractInfo.DAOCommitteeOwner
    )
    console.log("setSelectorImplementations2 DAOCommitteeOwner done")

}

const main = async () => {
  await Setting_changeDAOStructure()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
