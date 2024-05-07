const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');

const depositManagerAddress = "0x56E465f654393fa48f007Ed7346105c7195CEe43";
const seigManagerAddress = "0x710936500aC59e8551331871Cbad3D33d5e0D909";


async function getAccounts() {

  const depositedTxs = JSON.parse(await fs.readFileSync("./data/depositedTxs.json"));
  const layer2s = JSON.parse(await fs.readFileSync("./data/layer2s.json"));

  let depositors = {};
  for (const layer2 of layer2s) {
    let layer = layer2.toLowerCase()
    depositors[layer] = []
  }
  console.log("depositors: ", depositors);

  const abi = [ "event Deposited(address indexed layer2, address depositor, uint256 amount)" ];
  const iface = new ethers.utils.Interface(abi);
  const depositId = ethers.utils.id("Deposited(address,address,uint256)")

  let i = 0
  for (const depositedTx of depositedTxs) {
    const { logs } = await ethers.provider.getTransactionReceipt(depositedTx);
    const foundLog = logs.find(el => el && el.topics && el.topics.includes(depositId));
    if (!foundLog) continue;
    const parsedlog = iface.parseLog(foundLog);
    const { layer2, depositor } = parsedlog["args"];

    let layer = layer2.toLowerCase()
    let account = depositor.toLowerCase()

    if(!depositors[layer].includes(account)) depositors[layer].push(account)
    i++
    if(i % 100 == 0) {
      console.log('i --- ', i )
      await fs.writeFileSync("./data/depositors.json", JSON.stringify(depositors));
    }
  }

  console.log( depositors )
  await fs.writeFileSync("./data/depositors.json", JSON.stringify(depositors));
}


async function getAccountBalances() {
  const coinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;

  const depositors = JSON.parse(await fs.readFileSync("./data/depositors.json"));
  const coinages = JSON.parse(await fs.readFileSync("./data/coinages-total-supply.json"));


  for (const coinage of coinages) {
    let layer = coinage.layer2.toLowerCase()
    let depositorsList = depositors[layer]
    console.log("layer: ",layer, " , depositorsList: ", depositorsList.length);

    const coin = new ethers.Contract(
      coinage.coinage,
      coinageABI,
      ethers.provider
    );
    let deposits = [];
    for (const depositor of depositorsList) {
      let balance = await coin.balanceOf(depositor)

      deposits.push({
        account: depositor,
        balance: balance.toString()
      })
    }
    console.log("layer: ",layer, " , deposits: ", deposits);
    await fs.writeFileSync("./data/layer2-accounts-balances/"+layer+".json", JSON.stringify(deposits));
  }
}


async function main() {

  // await getLayer2s();  // 모든 레이어 , 코인에이지 목록

  await getDepositTxs();  // 디파짓한 트랜잭션 목록
  await getAccounts();  // 레이어별 디파짓한 적 있는 계정 목록

  // await getTotBalances();  // 코인에이지 정보 , last-seig-block, layer2_last_commit_block

  await getAccountBalances(); // 레이어별 계정별 코인에이지 정보

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
