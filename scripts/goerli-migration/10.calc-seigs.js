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


// 9768417 + 100800 (2주)
const passToBlock = 9869217

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

        // if( i > 4 ) {
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

        // }

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

