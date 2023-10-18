
const hre = require("hardhat");
const { ethers } = hre;
const { BigNumber } = require('ethers')
const  fs = require('fs')
// const { CalculatedSeig, TonStakingV2Fixtures, JSONFixture } = require( './shared/fixtureInterfaces')

const RAYDIFF = ethers.BigNumber.from("1"+"0".repeat(9))
const RAY = ethers.BigNumber.from("1"+"0".repeat(27))
const REFACTOR_DIVIDER = BigNumber.from("2");
const REFACTOR_BOUNDARY = BigNumber.from("1"+"0".repeat(28));

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

const calcMaxSeigs = async  (seigManager, blockNumber) => {
    let lastSeigBlock = await seigManager.lastSeigBlock()
    let seigPerBlock = await seigManager.seigPerBlock()
    let span = blockNumber - lastSeigBlock.toNumber()
    return seigPerBlock.mul(ethers.BigNumber.from(""+span))
}

const calcNewFactor = async (prevTotal, nxtTotal, oldFactor) => {

    return nxtTotal.mul(oldFactor).div(prevTotal)
}

const applyFactor = async (factor, refactorCount, balance, refactoredCount) => {

    let v = balance.mul(factor).div(RAY)
    v = v.mul(REFACTOR_DIVIDER.pow(refactorCount.sub(refactoredCount)))
    return v
}

const setFactor = async (factor_) => {
    let count = 0;
    let f = factor_;

    for (; f.gte(REFACTOR_BOUNDARY); f = f.div(REFACTOR_DIVIDER)) {
        count++;
    }
    return {factor: f, refactorCount: BigNumber.from(''+count)}
}

const calcSeigsDistribution = async (layer2, seigManager, coinage, prevTotalSupply, seigs, isCommissionRateNegative, operator) => {

    let commissionRate = await seigManager.commissionRates(layer2);
    let nextTotalSupply = prevTotalSupply.add(seigs)

    let operatorSeigs = BigNumber.from('0')
    if (commissionRate == 0) {
        return {nextTotalSupply: nextTotalSupply, operatorSeigs: operatorSeigs, commissionRate: commissionRate}
    }

    if (!isCommissionRateNegative) {
        operatorSeigs = seigs.mul(commissionRate).div(RAY); // additional seig for operator
        nextTotalSupply = nextTotalSupply.sub(operatorSeigs);
        return {nextTotalSupply: nextTotalSupply, operatorSeigs: operatorSeigs, commissionRate: commissionRate};
    }
    if (prevTotalSupply == 0) {
        return {nextTotalSupply: nextTotalSupply, operatorSeigs: operatorSeigs, commissionRate: commissionRate};
    }
    let operatorBalance = coinage.balanceOf(operator);
    if (operatorBalance == ethers.constants.Zero) {
        return {nextTotalSupply: nextTotalSupply, operatorSeigs: operatorSeigs, commissionRate: commissionRate};
    }
    let operatorRate = operatorBalance.mul(RAY).div(prevTotalSupply).div(RAY) ;
    if(operatorRate == RAY) delegatorSeigs = operatorSeigs
    else delegatorSeigs = operatorSeigs.mul(RAY).div(RAY - operatorRate).div(RAY)

    if(operatorRate == RAY) operatorSeigs = operatorSeigs
    else operatorSeigs =  operatorSeigs.add(delegatorSeigs.mul(operatorRate).div(RAY))

    nextTotalSupply = nextTotalSupply + delegatorSeigs;

    return {nextTotalSupply: nextTotalSupply, operatorSeigs: operatorSeigs, commissionRate: commissionRate}
}

const calcSeigniorage  = async (contractInfos, toBlock,  layer2) =>  {
    const RefactorCoinageSnapshotABI = JSON.parse(await fs.readFileSync("./abi/RefactorCoinageSnapshot.json")).abi;
    const TONABI = JSON.parse(await fs.readFileSync("./abi/TON.json")).abi;
    const CandidateABI = JSON.parse(await fs.readFileSync("./abi/Candidate.json")).abi;

    const tonContract = new ethers.Contract(
        oldContractInfo.TON,
        TONABI,
        ethers.provider
    )
    const seigManager = new ethers.Contract(
        contractInfos.abis["SeigManagerProxy"].address,
        contractInfos.abis["SeigManager"].abi,
        ethers.provider
    )
    let totAddress = await seigManager.tot()
    // let coinageAddress = await seigManager.coinages(layer2)
    const totContract = new ethers.Contract(
        totAddress,
        RefactorCoinageSnapshotABI,
        ethers.provider
    )
    const layer2Contract = new ethers.Contract(
        layer2,
        CandidateABI,
        ethers.provider
    )
    let coinage = new ethers.Contract((await seigManager.coinages(layer2)), RefactorCoinageSnapshotABI, ethers.provider)
    let relativeSeigRate = await seigManager.relativeSeigRate()
    let powerTONSeigRate = await seigManager.powerTONSeigRate()
    let daoSeigRate = await seigManager.daoSeigRate()
    let tonTotalSupply = await tonContract.totalSupply()
    let tonBalanceOfWton = await tonContract.balanceOf(oldContractInfo.WTON)
    let tonBalanceOfZero = await tonContract.balanceOf(ethers.constants.AddressZero)
    let tonBalanceOfOne = await tonContract.balanceOf('0x0000000000000000000000000000000000000001')
    let totTotalSupply = await totContract.totalSupply()
    let tos = (tonTotalSupply.sub(tonBalanceOfWton).sub(tonBalanceOfZero).sub(tonBalanceOfOne)).mul(RAYDIFF).add(totTotalSupply)

    let totBalanceLayer = await totContract.balanceOf(layer2)
    let totFactor = await totContract.factor()
    let totTotalAndFactor = await totContract.getTotalAndFactor()
    let totBalanceAndFactor = await totContract.getBalanceAndFactor(layer2)

    let coinageTotalSupply = await coinage.totalSupply()
    let coinageFactor = await coinage.factor()
    let coinageTotalAndFactor = await coinage.getTotalAndFactor()

    let maxSeig = await calcMaxSeigs(seigManager, toBlock)
    let stakedSeig1 = maxSeig.mul(totTotalSupply).div(tos)
    let unstakedSeig = maxSeig.sub(stakedSeig1)
    let stakedSeig = stakedSeig1.add(unstakedSeig.mul(relativeSeigRate).div(RAY))

    let daoSeig = unstakedSeig.mul(daoSeigRate).div(RAY)
    let powerTonSeig = unstakedSeig.mul(powerTONSeigRate).div(RAY)
    let nextTonTotalSupply = tonTotalSupply.add(maxSeig) ;
    let nextTotTotalSupply = totTotalSupply.add(stakedSeig) ;

    let newTotFactor = await calcNewFactor (totTotalSupply, nextTotTotalSupply, totFactor)
    let newFactorSet = await setFactor(newTotFactor)
    let nextBalanceOfLayerInTot =  await applyFactor(newFactorSet.factor, newFactorSet.refactorCount, totBalanceAndFactor[0].balance, totBalanceAndFactor[0].refactoredCount)

    //=================
    let commissionRate = await seigManager.commissionRates(layer2)
    let isCommissionRateNegative = await seigManager.isCommissionRateNegative(layer2)
    let operator = await layer2Contract.operator()

    let seigOfLayer = nextBalanceOfLayerInTot.sub(coinageTotalSupply)
    // let operatorRate = operatorBalance.mul(RAY).div(coinageTotalSupply).div(RAY)
    let operatorSeigs = ethers.constants.Zero
    let nextLayerTotalSupply = nextBalanceOfLayerInTot

    if(commissionRate != ethers.constants.Zero) {
        if(!isCommissionRateNegative) {
            operatorSeigs = seigOfLayer.mul(commissionRate).div(RAY)
            nextLayerTotalSupply = nextLayerTotalSupply.sub(operatorSeigs)
        }
    }

    //=================
    let newCoinageFactor = await calcNewFactor (coinageTotalSupply, nextLayerTotalSupply, coinageFactor)

    return {
        toBlock: toBlock,
        layer2Address: layer2,
        tonTotalSupply: tonTotalSupply,
        tonBalanceOfWton: tonBalanceOfWton,
        tos: tos,
        totTotalSupply: totTotalSupply,
        totBalanceLayer: totBalanceLayer,
        totTotalAndFactor: totTotalAndFactor,
        totBalanceAndFactor: totBalanceAndFactor,
        totFactor: totFactor,
        coinageTotalSupply: coinageTotalSupply,
        coinageTotalAndFactor: coinageTotalAndFactor,
        coinageFactor: coinageFactor,
        maxSeig: maxSeig,
        stakedSeig: stakedSeig,
        daoSeig: daoSeig,
        powerTonSeig: powerTonSeig,
        nextTonTotalSupply: nextTonTotalSupply,
        nextTotTotalSupply: nextTotTotalSupply,
        nextTotBalanceLayer: nextBalanceOfLayerInTot,
        newTotFactor: newTotFactor,
        newCoinageFactor: newCoinageFactor,
        seigOfLayer : seigOfLayer,
        operatorSeigs: operatorSeigs,
        nextLayerTotalSupply : nextLayerTotalSupply
    }
}

module.exports = {
    calcSeigniorage
}