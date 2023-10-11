const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { mine } = require("@nomicfoundation/hardhat-network-helpers")

const { readContracts, deployedContracts } = require("../common_func");

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

async function calcMaxSeigs (seigManager, blockNumber){
    let lastSeigBlock = await seigManager.lastSeigBlock()
    let seigPerBlock = await seigManager.seigPerBlock()
    let span = blockNumber - lastSeigBlock.toNumber()

    return seigPerBlock.mul(ethers.BigNumber.from(""+span))
}

async function calcNewFactor (prevTotal, nxtTotal, oldFactor){
    return nxtTotal.mul(oldFactor).div(prevTotal)
}

async function applyFactor (factor, refactorCount, balance, refactoredCount) {
    let v = balance.mul(factor).div(RAY)
    v = v.mul(REFACTOR_DIVIDER.pow(refactorCount.sub(refactoredCount)))
    return v
}

async function calcSeigniorage(toBlock) {
    const RefactorCoinageSnapshotABI = JSON.parse(await fs.readFileSync("./abi/RefactorCoinageSnapshot.json")).abi;

    const AutoRefactorCoinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;
    const CandidateABI = JSON.parse(await fs.readFileSync("./abi/Candidate.json")).abi;
    const WTONABI = JSON.parse(await fs.readFileSync("./abi/WTON.json")).abi;
    const TONABI = JSON.parse(await fs.readFileSync("./abi/TON.json")).abi;

    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);

    const tonContract = new ethers.Contract(
        oldContractInfo.TON,
        TONABI,
        ethers.provider
    )

    const wtonContract = new ethers.Contract(
        oldContractInfo.WTON,
        WTONABI,
        ethers.provider
    )

    const seigManager = new ethers.Contract(
        contractInfos.abis["SeigManagerProxy"].address,
        contractInfos.abis["SeigManager"].abi,
        ethers.provider
    )
    let totAddress = await seigManager.tot()
    const totContract = new ethers.Contract(
        totAddress,
        RefactorCoinageSnapshotABI,
        ethers.provider
    )

    let relativeSeigRate = await seigManager.relativeSeigRate()
    let powerTONSeigRate = await seigManager.powerTONSeigRate()
    let daoSeigRate = await seigManager.daoSeigRate()

    //-------------------------------
    // 현재 상태를 조회한다.
    // 총 (w)ton total supply = ((ton.totalSupply - ton.balanceOf(wton)) *1e9) + totalmem.totalSupply
    let tonTotalSupply = await tonContract.totalSupply()
    let tonBalanceOfWton = await tonContract.balanceOf(oldContractInfo.WTON)
    let totTotalSupply = await totContract.totalSupply()
    let totFactor = await totContract.factor()
    // console.log('tonTotalSupply' , ethers.utils.formatUnits(tonTotalSupply, 27))
    // console.log('tonBalanceOfWton' , ethers.utils.formatUnits(tonBalanceOfWton, 27))
    // console.log('totTotalSupply' , ethers.utils.formatUnits(totTotalSupply, 27))
    // console.log('totFactor' , ethers.utils.formatUnits(totFactor, 27))

    // console.log('RAY',ethers.utils.formatUnits(RAY, 27))

    let currentTonTotal = (tonTotalSupply.sub(tonBalanceOfWton)).mul(RAYDIFF).add(totTotalSupply)
     // 현재 총발행량에서 주소0과 주소1에 있는 것은 빼주어야 하지 않을까요?

    // let block = await ethers.provider.getBlock('latest')
    let maxSeig = await calcMaxSeigs(seigManager, toBlock)
    // console.log('maxSeig' , ethers.utils.formatUnits(maxSeig, 27) )

    // 스테이킹을 한 사람들의 시뇨리지 stakedSeig
    let stakedSeig1 = maxSeig.mul(totTotalSupply).div(currentTonTotal)
    // console.log('stakedSeig1' , ethers.utils.formatUnits(stakedSeig1, 27)  )

    let unstakedSeig = maxSeig.sub(stakedSeig1)
    // console.log('unstakedSeig' ,  ethers.utils.formatUnits(unstakedSeig, 27) )

    let stakedSeig = stakedSeig1.add(unstakedSeig.mul(relativeSeigRate).div(RAY))
    // console.log('stakedSeig' , ethers.utils.formatUnits(stakedSeig, 27) )

    // dao 시뇨리지
    let daoSeig = unstakedSeig.mul(daoSeigRate).div(RAY)
    // console.log('daoSeig' , ethers.utils.formatUnits(daoSeig, 27)  )

    // powerton 시뇨리지
    let powerTonSeig = unstakedSeig.mul(powerTONSeigRate).div(RAY)
    // console.log('powerTonSeig' , ethers.utils.formatUnits(powerTonSeig, 27) )

    // 시뇨리지가 발행한 다음의 총 스테이킹 양
    let nextTonTotalSupply = tonTotalSupply.add(maxSeig) ;
    let nextTotTotalSupply = totTotalSupply.add(stakedSeig) ;

    // console.log('nextTonTotalSupply' , ethers.utils.formatUnits(nextTonTotalSupply, 27) )
    // console.log('nextTotTotalSupply' , ethers.utils.formatUnits(nextTotTotalSupply, 27) )

    // 팩터변경 : tot의 Factor가 변경된다. -> tot.balance 레이어별 잔액이 변경된다.

    let newTotFactor = await calcNewFactor (totTotalSupply, nextTotTotalSupply, totFactor)
    // console.log('tot  newFactor' , ethers.utils.formatUnits(newTotFactor, 27))

    return {
        tonTotalSupply: tonTotalSupply,
        tonBalanceOfWton: tonBalanceOfWton,
        totTotalSupply: totTotalSupply,
        totFactor: totFactor,
        maxSeig: maxSeig,
        stakedSeig: stakedSeig,
        daoSeig: daoSeig,
        powerTonSeig: powerTonSeig,
        nextTonTotalSupply: nextTonTotalSupply,
        nextTotTotalSupply: nextTotTotalSupply,
        newTotFactor: newTotFactor
    }
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
    console.log('======================== totAddress ', totAddress)

    const totContract = new ethers.Contract(
        totAddress,
        RefactorCoinageSnapshotABI,
        ethers.provider
    )

    let i = 1;
    for (let oldLayer of oldLayers) {

        if( i > 4 ) {
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
            let seigCalc = await calcSeigniorage(toBlock)
            console.log(' toBlock', toBlock, ', seigCalc ', seigCalc)

            console.log('------- prev update seig ')
            let totalSupply = await totContract.totalSupply()
            console.log(' totalSupply of tot ', ethers.utils.formatUnits(totalSupply, 27) )

            let balanceOf  = await totContract.balanceOf(layerAddress)
            console.log('balanceOf layerAddress of tot ', ethers.utils.formatUnits(balanceOf, 27) )

            let factor0  = await totContract.factor()
            console.log(' factor  of tot ',  ethers.utils.formatUnits(factor0, 27))

            let totalSupplyCoin = await coinageContract.totalSupply()
            console.log(' totalSupply of coinage ',  ethers.utils.formatUnits(totalSupplyCoin, 27))

            let oldFactorOfCoin= await coinageContract.factor()
            console.log(' oldFactorOfCoin of coinage ', ethers.utils.formatUnits(oldFactorOfCoin, 27))


            // 업데이트 시뇨리지
            let receipt = await (await layerContract.connect(deployer).updateSeigniorage()).wait()
            console.log('updateSeigniorage : ',layerAddress,', tx:  ', receipt.transactionHash)

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

