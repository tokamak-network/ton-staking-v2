const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');

const SeigManagerAbi = [
        {
            "constant": true,
            "inputs": [
            {
                "internalType": "address",
                "name": "layer2",
                "type": "address"
            }
            ],
            "name": "coinages",
            "outputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }
    ]

const AutoRefactorCoinageAbi = [
        {
            "inputs": [
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
            ],
            "name": "balanceOf",
            "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
              {
                "internalType": "address",
                "name": "account",
                "type": "address"
              },
              {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
              }
            ],
            "name": "burnFrom",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
          }
    ]


async function test1() {
  let seigManager = '0x710936500aC59e8551331871Cbad3D33d5e0D909'
    let layer2 = '0x' // 특정 레이어 주소
    let account = "0x" // 특정 타겟 주소

    let SeigManagerContract = new ethers.Contract(seigManager, SeigManagerAbi, deployer)
    let coinage = await SeigManagerContract.coinages(layer2)
    let coinagesContract = new ethers.Contract(coinage, AutoRefactorCoinageAbi, deployer)

    let balanceOfAddr1 = await coinagesContract.balanceOf(account)
    console.log('balanceOfAddr1', balanceOfAddr1)

    // 갖고 있는 잔액의 절반을 없앰
    await (await coinagesContract.burnFrom(account, balanceOfAddr1.div(ethers.BigNumber.from("2")))).wait()

    let balanceOfAddr2 = await coinagesContract.balanceOf(account)
    console.log('balanceOfAddr2', balanceOfAddr2)

}


async function test2() {
  const TONABI = JSON.parse(await fs.readFileSync("./abi/TON.json")).abi;

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
  const tonContract = new ethers.Contract(
    oldContractInfo.TON,
    TONABI,
    ethers.provider
  )

  let block = await ethers.provider.getBlock('latest')
  console.log('block number : ', block.number)

  let tonBalanceOfWton = await tonContract.balanceOf(oldContractInfo.WTON)
  console.log('tonBalanceOfWton', ethers.utils.formatUnits(tonBalanceOfWton,18) , ' TON')


}



async function main() {
    const [deployer] = await ethers.getSigners();
    // await test1()
    await test2()
  }

  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
