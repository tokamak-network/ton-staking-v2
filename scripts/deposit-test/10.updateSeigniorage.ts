import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from 'hardhat'

import DepositManager_Json from '../../abi/DepositManager.json'
import DAOCommitteeProxy_Json from '../../abi/DAOCommitteeProxy.json'

const { readContracts, deployedContracts } = require("../common_func");

const fs = require('fs');

const networkName = "localhost"

const RAYDIFF = ethers.BigNumber.from("1"+"0".repeat(9))
const RAY = ethers.BigNumber.from("1"+"0".repeat(27))

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

let layer2Info_level19 : any;
let layer2Info_tokamak : any;
let layer2Info_hammerDAO : any;
let layer2Info_DXMCorp : any;
let layer2Info_danalFintech : any;
let layer2Info_DeSpread : any;
let layer2Info_decipher : any;
let layer2Info_Talken : any;
let layer2Info_DSRV : any;
let layer2Info_staked : any;

let DAOCommitteeProxy = "0xDD9f0cCc044B0781289Ee318e5971b0139602C26";
const DaoCommitteeAdminAddress = "0xb4983da083a5118c903910db4f5a480b1d9f3687"

async function updateSeigniorage() {
    /* layer 등록 순서
        1. level19
        2. tokamak
        3. hammerDAO
        4. DXMCorp
        5. danalFintech
        6. DeSpread
        7. decipher
        8. Talken
        9. DSRV
        10. staked
    */

    //oldLayerAddr
    const level19Addr = "0x42ccf0769e87cb2952634f607df1c7d62e0bbc52";
    const tokamak1Addr = "0x39a13a796a3cd9f480c28259230d2ef0a7026033";
    const hammerDAOAddr = "0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764";
    const DXMCorpAddr = "0x41fb4bad6fba9e9b6e45f3f96ba3ad7ec2ff5b3c";
    const danalFintechAddr = "0x97d0a5880542ab0e699c67e7f4ff61f2e5200484"
    const DeSpreadAddr = "0x2000fc16911fc044130c29c1aa49d3e0b101716a";
    const decipherAddr = "0x17602823b5fe43a65ad7122946a73b019e77fd33"
    const TalkenAddr = "0xb9d336596ea2662488641c4ac87960bfdcb94c6e";
    const DSRVAddr = "0xbc8896ebb2e3939b1849298ef8da59e09946cf66";
    const stakedAddr = "0xcc38c7aaf2507da52a875e93f57451e58e8c6372";


    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)
    
    // const [deployer2, addr1, addr2 ] = await ethers.getSigners();
    // const { deployer } = await hre.getNamedAccounts();
    // const { deploy } = hre.deployments;

    // const deploySigner = await hre.ethers.getSigner(deployer);
    const newLayer2s = []

    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const RefactorCoinageSnapshotABI = JSON.parse(await fs.readFileSync("./abi/RefactorCoinageSnapshot.json")).abi;
    const CandidateABI = JSON.parse(await fs.readFileSync("./abi/Candidate.json")).abi;
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);

    let oldLayers = JSON.parse(await fs.readFileSync("./data/coinages-total-supply.json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));

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

    let i;
    for(i = 0; i < 1; i++) {
        if(i == 8) {
            continue;
        } else {
            const coinAddress = seigManager.coinages(newLayerAddr[i])
        
            const coinageContract = new ethers.Contract(
                coinAddress,
                RefactorCoinageSnapshotABI,
                deployer
            )
        
            const layerContract = new ethers.Contract(
                newLayerAddr[i],
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
        
            let balanceOf  = await totContract.balanceOf(newLayerAddr[i])
            console.log('balanceOf layerAddress of tot ', ethers.utils.formatUnits(balanceOf, 27) )
        
            let factor0  = await totContract.factor()
            console.log(' factor  of tot ',  ethers.utils.formatUnits(factor0, 27))
        
            let totalSupplyCoin = await coinageContract.totalSupply()
            console.log(' totalSupply of coinage ',  ethers.utils.formatUnits(totalSupplyCoin, 27))
        
            let oldFactorOfCoin= await coinageContract.factor()
            console.log(' oldFactorOfCoin of coinage ', ethers.utils.formatUnits(oldFactorOfCoin, 27))
        
        
            // 업데이트 시뇨리지
            let receipt = await (await layerContract.connect(deployer).updateSeigniorage()).wait()
            console.log('updateSeigniorage : ',newLayerAddr[i],', tx:  ', receipt.transactionHash)
        
            console.log('------- after update seig ')
        
            let totalSupply1 = await totContract.totalSupply()
            console.log(' totalSupply of tot ', ethers.utils.formatUnits(totalSupply1, 27))
        
            let balanceOf1  = await totContract.balanceOf(newLayerAddr[i])
            console.log('balanceOf layerAddress of tot ', ethers.utils.formatUnits(balanceOf1, 27))
        
            let factor1  = await totContract.factor()
            console.log(' factor  of tot ',  ethers.utils.formatUnits(factor1, 27))
        
            let totalSupplyCoin1 = await coinageContract.totalSupply()
            console.log(' totalSupply of coinage ',  ethers.utils.formatUnits(totalSupplyCoin1, 27))
        
            let factor2 = await coinageContract.factor()
            console.log(' factor of coinage ',  ethers.utils.formatUnits(factor2, 27))
        }

    }


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

async function calcMaxSeigs (seigManager, blockNumber){
    let lastSeigBlock = await seigManager.lastSeigBlock()
    let seigPerBlock = await seigManager.seigPerBlock()
    let span = blockNumber - lastSeigBlock.toNumber()

    return seigPerBlock.mul(ethers.BigNumber.from(""+span))
}

async function calcNewFactor (prevTotal, nxtTotal, oldFactor){
    return nxtTotal.mul(oldFactor).div(prevTotal)
}

async function main() {
    await updateSeigniorage();
}
  
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });