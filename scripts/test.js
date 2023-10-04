const hre = require("hardhat");
const { ethers } = hre;

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

async function main() {
    const [deployer] = await ethers.getSigners();
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

  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
