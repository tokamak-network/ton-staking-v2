const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { mine } = require("@nomicfoundation/hardhat-network-helpers")

const { readContracts, deployedContracts } = require("../common_func");
const networkName = "goerli"
const pauseBlock = 9768417
const startBlock = 8437208
const dataFolder = './data-goerli'
const daoAdminAddress = '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'
const testBlock = 9869217

// goerli network
const oldContractInfo = {
    TON: "0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00",
    WTON: "0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6",
    Layer2Registry: "0x6817e1c04748eae68EBFF13216280Df1ec15ba86",
    DepositManager: "0x0ad659558851f6ba8a8094614303F56d42f8f39A",
    CoinageFactory: "0x09207BdB146E41dadad015aB3d835f66498b0A0c",
    OldDAOVaultMock: "0xFD7C2c54a0A755a46793A91449806A4b14E3eEe8",
    SeigManager: "0x446ece59ef429B774Ff116432bbB123f1915D9E3",
    PowerTON: "0x031B5b13Df847eB10c14451EB2a354EfEE23Cc94",
    DAOVault: "0xb0B9c6076D46E333A8314ccC242992A625931C99",
    DAOAgendaManager: "0x0e1583da47cf641305eDD1e4C6dB6DD18e138a21",
    CandidateFactory: "0xd1c4fE0Ac211F8A41817c26D1801fd549D56E31e",
    DAOCommittee: "0xF7368a07653de908a8510e5d768c9C71b71cB2Ae",
    DAOCommitteeProxy: "0x3C5ffEe61A384B384ed38c0983429dcDb49843F6"
}

async function oldContractRecovery(daoCommitteeAdmin) {
    const SeigManagerABI = JSON.parse(await fs.readFileSync("./abi/SeigManager.json")).abi;

    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);

    const daoCommittee = new ethers.Contract(
        oldContractInfo.DAOCommitteeProxy,
        contractInfos.abis["DAOCommitteeExtend"].abi,
        daoCommitteeAdmin
    )

    const oldSeigManager = new ethers.Contract(
        oldContractInfo.SeigManager,
        SeigManagerABI,
        ethers.provider
    )
    //-------------------------------
    // dao pause 상태 및 로직 복구
    let pauseProxy = await daoCommittee.pauseProxy()
    if (pauseProxy) {
        await (await daoCommittee.connect(daoCommitteeAdmin).setProxyPause(false)).wait()
    }
    let paused = await oldSeigManager.paused()
    if (paused) {
        await (await daoCommittee.connect(daoCommitteeAdmin).setSeigUnpause()).wait()
    }

    // depositManager 의 시뇨리지 주소 복구
    await (await daoCommittee.connect(daoCommitteeAdmin).setTargetSeigManager(
        oldContractInfo.DepositManager,
        oldContractInfo.SeigManager
    )).wait()
}


async function updateSeigniorage(daoCommitteeAdmin) {

    const AutoRefactorCoinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;
    const CandidateABI = JSON.parse(await fs.readFileSync("./abi/Candidate.json")).abi;

    //-------------------------------
    // 블록 마이닝
    let passTime = 60*60*24*14
    let blockIntervalSec = 12
    let passBlock = passTime / blockIntervalSec

    let curBlock = await ethers.provider.getBlock('latest')
    console.log('curBlock before mining : ', curBlock.number , curBlock.timestamp )

    await mine(passBlock, { interval: blockIntervalSec });

    curBlock = await ethers.provider.getBlock('latest')
    console.log('curBlock after mining : ', curBlock.number , curBlock.timestamp )
    //-------------------------------
    // 레이어별 업데이트 시뇨리지 실행하고,
    let oldLayers = JSON.parse(await fs.readFileSync(dataFolder + "/coinages-total-supply.json"));

    for (let oldLayer of oldLayers) {

        const oldCoinageContract = new ethers.Contract(
            oldLayer.coinage,
            AutoRefactorCoinageABI,
            ethers.provider
        )
        const oldLayerContract = new ethers.Contract(
            oldLayer.layer2,
            CandidateABI,
            ethers.provider
        )

        // 업데이트 시뇨리지
        await (await oldLayerContract.connect(daoCommitteeAdmin).updateSeigniorage()).wait()

        // 계정별 잔액을 다시 집계한다.
        let updateBalances = []
        let accounts = JSON.parse(await fs.readFileSync(dataFolder + "/layer2-accounts-balances/"+oldLayer.layer2.toLowerCase()+".json"));
        for (let account of accounts) {
            let balance =  await oldCoinageContract.balanceOf(account.account)
            let addAmount = balance.sub(ethers.BigNumber.from(account.balance))
            updateBalances.push(
                {
                    account: account.account.toLowerCase(),
                    prevBalance: account.balance,
                    afterBalance: balance.toString(),
                    addAmount: addAmount.toString()
                }
            )
        }
        await fs.writeFileSync(dataFolder + "/old-update-seig/"+oldLayer.layer2.toLowerCase()+".json", JSON.stringify(updateBalances));
    }

}


async function main() {
    const [ deployer ] = await ethers.getSigners()
    // console.log(deployer.address)
    await hre.network.provider.send("hardhat_impersonateAccount", [
        daoAdminAddress,
    ]);
    const daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

    await oldContractRecovery(daoCommitteeAdmin)

    await updateSeigniorage(daoCommitteeAdmin)
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

