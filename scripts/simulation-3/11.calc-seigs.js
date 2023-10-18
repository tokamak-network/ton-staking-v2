const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { mine } = require("@nomicfoundation/hardhat-network-helpers")

const { readContracts, deployedContracts } = require("../common_func");
const { calcSeigniorage } = require("../common_seig_func");

const networkName = "local"
const pauseBlock = 18231453
const startBlock = 10837675

const dataFolder = './data-mainnet'
const deployerAddress = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'

const goerliPowerTonAdmin = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const mainnetPowerTonAdmin = "0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1"

const DAOCommitteeExtendABI = require("../../abi/DAOCommitteeExtend.json").abi;
const DepositManagerABI = require("../../abi/DepositManager.json").abi;

// mainnet network
const oldContractInfo = {
    TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
    WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
    Layer2Registry: "0x0b3E174A2170083e770D5d4Cf56774D221b7063e",
    DepositManager: "0x56E465f654393fa48f007Ed7346105c7195CEe43",
    CoinageFactory: "0x5b40841eeCfB429452AB25216Afc1e1650C07747",
    OldDAOVaultMock: "",
    SeigManager: "0x710936500aC59e8551331871Cbad3D33d5e0D909",
    PowerTON: "0x970298189050aBd4dc4F119ccae14ee145ad9371",
    DAOVault: "0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303",
    DAOAgendaManager: "0xcD4421d082752f363E1687544a09d5112cD4f484",
    CandidateFactory: "0xE6713aF11aDB0cFD3C60e15b23E43f5548C32942",
    DAOCommittee: "0xd1A3fDDCCD09ceBcFCc7845dDba666B7B8e6D1fb",
    DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
}

// 18231453 + 100800 (2주)
const passToBlock = 18332253

const RAYDIFF = ethers.BigNumber.from("1"+"0".repeat(9))
const RAY = ethers.BigNumber.from("1"+"0".repeat(27))
const REFACTOR_DIVIDER = 2;


function getNewLayerAddress (layerList, oldLayer){
    for (let layer of layerList) {
        if(layer.oldLayer.toLowerCase() == oldLayer.toLowerCase()) return layer.newLayer.toLowerCase()
    }
    return null
}


async function updateSeigniorage (deployer){

    // 레이어마다 업데이트 시뇨리지를 하므로, 레이어별로 업데이트 시뇨리지 하고, 각 개개인의 잔액도 업데이트해서 확인한다.
    const RefactorCoinageSnapshotABI = JSON.parse(await fs.readFileSync("./abi/RefactorCoinageSnapshot.json")).abi;
    const CandidateABI = JSON.parse(await fs.readFileSync("./abi/Candidate.json")).abi;
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    //-------------------------------
    // 레이어별 업데이트 시뇨리지 실행하고,
    let oldLayers = JSON.parse(await fs.readFileSync(dataFolder + "/coinages-total-supply.json"));
    let layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2_name_map_created.json"));
    const seigManager = new ethers.Contract(
        contractInfos.abis["SeigManagerProxy"].address,
        contractInfos.abis["SeigManager"].abi,
        deployer
    )
    let totAddress = await seigManager.tot()
    const totContract = new ethers.Contract(
        totAddress,
        RefactorCoinageSnapshotABI,
        ethers.provider
    )

    let i = 1;
    for (let oldLayer of oldLayers) {

        if( i == 3 ) {
            let layerAddress = getNewLayerAddress(layer2s, oldLayer.layer2)

            console.log('======================== layer ',oldLayer, layerAddress)
            const coinAddress = seigManager.coinages(layerAddress)
            const coinageContract = new ethers.Contract(
                coinAddress,
                RefactorCoinageSnapshotABI,
                deployer
            )
            const layerContract = new ethers.Contract(
                layerAddress,
                CandidateABI,
                deployer
            )

            // 현재 블록 확인
            let block = await ethers.provider.getBlock('latest')
            let toBlock = block.number+1
            let seigCalc = await calcSeigniorage(contractInfos, toBlock, layerAddress)
            console.log(' calcSeigniorage  seigCalc ', seigCalc)

            // 업데이트 시뇨리지
            let receipt = await (await layerContract.connect(deployer).updateSeigniorage()).wait()
            console.log('updateSeigniorage : ',layerAddress,', tx:  ', receipt.transactionHash)
            const topic1 = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            console.log('------- AddedSeigAtLayer  ', deployedEvent1.args)
            console.log('------- after update seig ')

            let totalSupply1 = await totContract.totalSupply()
            console.log(' totalSupply of tot ', ethers.utils.formatUnits(totalSupply1, 27))

            let balanceOf1  = await totContract.balanceOf(layerAddress)
            console.log('balanceOf layerAddress of tot ', ethers.utils.formatUnits(balanceOf1, 27))

            let factor1  = await totContract.factor()
            console.log(' factor  of tot ',  ethers.utils.formatUnits(factor1, 27))

            let totalSupplyCoin1 = await coinageContract.totalSupply()
            console.log(' totalSupply of coinage ',  ethers.utils.formatUnits(totalSupplyCoin1, 27))

            let factor2 = await coinageContract.factor()
            console.log(' factor of coinage ',  ethers.utils.formatUnits(factor2, 27))

        }

        i++;
    }
}


async function main() {
    const [ deployer ] = await ethers.getSigners()
    console.log('deployer', deployer.address)
    // let calc = await calcSeigniorage(passToBlock)
    // console.log(calc)

    await updateSeigniorage (deployer)

}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

