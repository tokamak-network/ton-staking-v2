const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");

const { mine } = require("@nomicfoundation/hardhat-network-helpers")
const networkName = "local"
const pauseBlock = 18231453
const startBlock = 10837675

//=============
const passToBlock = 18323890
const blockIntervalSec = 12
const RAYDIFF = ethers.BigNumber.from("1"+"0".repeat(9))
const RAY = ethers.BigNumber.from("1"+"0".repeat(27))
const REFACTOR_DIVIDER = 2;

//=============

const dataFolder = './data-mainnet'
const deployerAddress = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'

const goerliPowerTonAdmin = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const mainnetPowerTonAdmin = "0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1"

const DAOCommitteeExtendABI = require("../../abi/DAOCommitteeExtend.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;

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

async function mining() {
    let curBlock = await ethers.provider.getBlock('latest')
    console.log('curBlock before mining : ', curBlock.number , curBlock.timestamp )
    let passBlock = passToBlock - curBlock.number
    await mine(passBlock, { interval: blockIntervalSec });
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

const makePos = (v1, v2) => {
  v1 = ethers.BigNumber.from(''+v1);
  v2 = ethers.BigNumber.from(''+v2);

  const a = v1.mul(ethers.BigNumber.from("2").pow(ethers.BigNumber.from("128")));
  return a.add(v2).toString();
};

async function calcSeigniorage(toBlock) {
    const AutoRefactorCoinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;
    const CandidateABI = JSON.parse(await fs.readFileSync("./abi/Candidate.json")).abi;
    const WTONABI = JSON.parse(await fs.readFileSync("./abi/WTON.json")).abi;
    const TONABI = JSON.parse(await fs.readFileSync("./abi/TON.json")).abi;
    const SeigManagerABI = JSON.parse(await fs.readFileSync("./abi/SeigManager.json")).abi;


    const seigManager = new ethers.Contract(
        oldContractInfo.SeigManager,
        SeigManagerABI,
        ethers.provider
    )

    const tonContract = new ethers.Contract(
      oldContractInfo.TON,
      TONABI,
      ethers.provider
    )
    let totAddress = await seigManager.tot()
    const totContract = new ethers.Contract(
        totAddress,
        AutoRefactorCoinageABI,
        ethers.provider
    )

    let relativeSeigRate = await seigManager.relativeSeigRate()
    let powerTONSeigRate = await seigManager.powerTONSeigRate()
    let daoSeigRate = await seigManager.daoSeigRate()


    let tonTotalSupply = await tonContract.totalSupply()
    let tonBalanceOfWton = await tonContract.balanceOf(oldContractInfo.WTON)
    let totTotalSupply = await totContract.totalSupply()
    let totFactor = await totContract.factor()

    console.log('tonTotalSupply' , ethers.utils.formatUnits(tonTotalSupply, 18))
    console.log('tonBalanceOfWton' , ethers.utils.formatUnits(tonBalanceOfWton, 18))
    console.log('totTotalSupply' , ethers.utils.formatUnits(totTotalSupply, 27))
    console.log('totFactor' , ethers.utils.formatUnits(totFactor, 27))

    let currentTonTotal = (tonTotalSupply.sub(tonBalanceOfWton)).mul(RAYDIFF).add(totTotalSupply)
    let maxSeig = await calcMaxSeigs(seigManager, toBlock)
    let stakedSeig1 = maxSeig.mul(totTotalSupply).div(currentTonTotal)
    let unstakedSeig = maxSeig.sub(stakedSeig1)
    let stakedSeig = stakedSeig1.add(unstakedSeig.mul(relativeSeigRate).div(RAY))

    // dao 시뇨리지
    let daoSeig = unstakedSeig.mul(daoSeigRate).div(RAY)
    // powerton 시뇨리지
    let powerTonSeig = unstakedSeig.mul(powerTONSeigRate).div(RAY)

    // 시뇨리지가 발행한 다음의 총 스테이킹 양
    let nextTonTotalSupply = tonTotalSupply.add(maxSeig) ;
    let nextTotTotalSupply = totTotalSupply.add(stakedSeig) ;

    let newTotFactor = await calcNewFactor (totTotalSupply, nextTotTotalSupply, totFactor)

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
    const AutoRefactorCoinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;
    const CandidateABI = JSON.parse(await fs.readFileSync("./abi/Candidate.json")).abi;
    const SeigManagerABI = JSON.parse(await fs.readFileSync("./abi/SeigManager.json")).abi;
    const Layer2ABI = JSON.parse(await fs.readFileSync("./abi/Layer2.json")).abi;
    //-------------------------------
    // 레이어별 업데이트 시뇨리지 실행하고,
    let oldLayers = JSON.parse(await fs.readFileSync(dataFolder + "/coinages-total-supply.json"));
    let layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2_name_map_created.json"));

    const seigManager = new ethers.Contract(
      oldContractInfo.SeigManager,
      SeigManagerABI,
      ethers.provider
  )

    let totAddress = await seigManager.tot()
    console.log('======================== totAddress ', totAddress)

    const totContract = new ethers.Contract(
        totAddress,
        AutoRefactorCoinageABI,
        ethers.provider
    )

    let i = 1;
    for (let oldLayer of oldLayers) {

        if( i != 4 ) {
            // let layerAddress = getNewLayerAddress(layer2s, oldLayer.layer2)
            let layerAddress = layer2s[i-1].oldLayer
            let operator = layer2s[i-1].operator
            let caller = deployer

            console.log('\n======================== layer ',oldLayer, layerAddress)
            console.log(i, layer2s[i-1])
            const coinAddress = seigManager.coinages(layerAddress)

            const coinageContract = new ethers.Contract(
                coinAddress,
                AutoRefactorCoinageABI,
                deployer
            )


            //==================================================
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

            //==================================================
            const layerContract = new ethers.Contract(
              layerAddress,
              CandidateABI,
              deployer
            )

            let isLayer2 = true
            try {
              isLayer2 = await layerContract.isLayer2Candidate()
            } catch(e) {
            }
            console.log('isLayer2 ', isLayer2)

            if(isLayer2) {
                await hre.network.provider.send("hardhat_impersonateAccount", [
                  operator,
                ]);
                await hre.network.provider.send("hardhat_setBalance", [
                  operator,
                  "0x10000000000000000000000000",
                ]);

                caller = await hre.ethers.getSigner(operator);
                const layer2Contract = new ethers.Contract(
                    layerAddress,
                    Layer2ABI,
                    caller
                )
                let viewOperator = await layer2Contract.operator()
                console.log('viewOperator',viewOperator)

                let isSubmitter = await layer2Contract.isSubmitter(operator)
                console.log('isSubmitter',isSubmitter)


                const [
                  costNRB,
                  NRELength,
                  currentForkNumber,
                ] = await Promise.all([
                  layer2Contract.COST_NRB(),
                  layer2Contract.NRELength(),
                  layer2Contract.currentFork(),
                ]);

                console.log('costNRB',costNRB)
                console.log('NRELength',NRELength)
                console.log('currentForkNumber',currentForkNumber)

                const fork = await layer2Contract.forks(currentForkNumber);
                const epochNumber = parseInt(fork.lastEpoch) + 1;
                const startBlockNumber = parseInt(fork.lastBlock) + 1;
                const endBlockNumber = parseInt(startBlockNumber) + parseInt(NRELength) - 1;

                const pos1 = makePos(currentForkNumber, epochNumber);
                const pos2 = makePos(startBlockNumber, endBlockNumber);
                const dummyBytes = '0xdb431b544b2f5468e3f771d7843d9c5df3b4edcf8bc1c599f18f0b4ea8709bc3';

                const gasLimit = await layer2Contract.connect(caller).estimateGas.submitNRE(
                  pos1,
                  pos2,
                  dummyBytes, // epochStateRoot
                  dummyBytes, // epochTransactionsRoot
                  dummyBytes, // epochReceiptsRoot
                )
                console.log('gasLimit', gasLimit)

                let receipt = await (await layer2Contract.connect(caller).submitNRE(
                  pos1,
                  pos2,
                  dummyBytes, // epochStateRoot
                  dummyBytes, // epochTransactionsRoot
                  dummyBytes, // epochReceiptsRoot
                )).wait()
                console.log('updateSeigniorage : ',layerAddress,', tx:  ', receipt.transactionHash)

            } else {

              // 업데이트 시뇨리지
              let receipt = await (await layerContract.connect(caller).updateSeigniorage()).wait()
              console.log('updateSeigniorage : ',layerAddress,', tx:  ', receipt.transactionHash)

            }
            //==================================================
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

        } else {
          console.log('\n======================== layer ',oldLayer )
          console.log(' 4th layer skip!! \n' )
        }

        i++;
    }
}


async function main() {
    const [ deployer ] = await ethers.getSigners()
    console.log(deployer.address)
    await mining()
    await updateSeigniorage (deployer)
}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error);
  process.exit(1);
});


