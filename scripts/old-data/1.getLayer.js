const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const layer2RegistryAddress = "0x0b3E174A2170083e770D5d4Cf56774D221b7063e";
const depositManagerAddress = "0x56E465f654393fa48f007Ed7346105c7195CEe43";
const seigManagerAddress = "0x710936500aC59e8551331871Cbad3D33d5e0D909";
const pauseBlock = 18231450
const startBlock = 10837675
async function getLayer2s() {

  const layer2RegistryABI = JSON.parse(await fs.readFileSync("./abi/layer2Registry.json")).abi;
  const seigManagerABI = JSON.parse(await fs.readFileSync("./abi/seigManager.json")).abi;

  const layer2Registry = new ethers.Contract(
    layer2RegistryAddress,
    layer2RegistryABI,
    ethers.provider
  );

  const seigManager = new ethers.Contract(
    seigManagerAddress,
    seigManagerABI,
    ethers.provider
  );
  const layer2s = []
  const coinages = []
  const numberOfLayer2s = await layer2Registry.numLayer2s()
  for (let i = 0; i < numberOfLayer2s; i++) {

    let layer2Address = await layer2Registry.layer2ByIndex(i)
    let coinageAddress = await seigManager.coinages(layer2Address)

    layer2s.push(layer2Address)
    coinages.push(coinageAddress)
  }
  console.log({ layer2s });
  console.log({ coinages });
  console.log("length: ", layer2s.length);
  await fs.writeFileSync("./data/layer2s.json", JSON.stringify(layer2s));
  await fs.writeFileSync("./data/coinages.json", JSON.stringify(coinages));

  return layer2s;
}


async function getTotBalances() {

  const seigManagerABI = JSON.parse(await fs.readFileSync("./abi/seigManager.json")).abi;
  const coinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;
  const layer2s = JSON.parse(await fs.readFileSync("./data/layer2s.json"));
  const coinages = JSON.parse(await fs.readFileSync("./data/coinages.json"));

  const seigManager = new ethers.Contract(
    seigManagerAddress,
    seigManagerABI,
    ethers.provider
  );

  let totAddress = await seigManager.tot()
  const tot = new ethers.Contract(
    totAddress,
    coinageABI,
    ethers.provider
  );
  console.log("totAddress: ", totAddress);
  let tot_total = [];
  let tot_balances = [];

  //------------------
  let totalSupply = await tot.totalSupply()
  tot_total.push(totalSupply.toString())
  console.log("tot-total-supply: ", tot_total);
  await fs.writeFileSync("./data/tot-total-supply.json", JSON.stringify(tot_total));

  let j = 0;
  //------------------
  for (j = 0; j < layer2s.length; j++) {
    let layer = layer2s[j].toLowerCase();
    let coinage = coinages[j].toLowerCase();

    let balance = await tot.balanceOf(layer)
    tot_balances.push({
      layer2: layer,
      coinage: coinage,
      balance: balance.toString()
    })
  }

  console.log("tot-balances: ", tot_balances);
  await fs.writeFileSync("./data/tot-balances.json", JSON.stringify(tot_balances));

  //------------------
  let coin_total = [];

  let i = 0;
  for (i = 0; i < layer2s.length; i++) {
    let layer = layer2s[i].toLowerCase();
    let coinage = coinages[i].toLowerCase();

    const coin = new ethers.Contract(
      coinage,
      coinageABI,
      ethers.provider
    );

    let totals = await coin.totalSupply()
    coin_total.push({
      layer2: layer,
      coinage: coinage,
      balance: totals.toString()
    })
  }
  console.log("coin_total: ", coin_total);
  await fs.writeFileSync("./data/coinages-total-supply.json", JSON.stringify(coin_total));
  //------------------
  return true;
}

async function getDepositTxs() {
  const depositManagerABI = JSON.parse(await fs.readFileSync("./abi/depositManager.json")).abi;

  const depositManager = new ethers.Contract(
    depositManagerAddress,
    depositManagerABI,
    ethers.provider
  );

  const abi = [ "event Deposited(address indexed layer2, address depositor, uint256 amount)" ];
  const iface = new ethers.utils.Interface(abi);
  const depositId = ethers.utils.id("Deposited(address,address,uint256)")
  let start = startBlock;
  let end = pauseBlock;

  let unit = 1000000
  let boolWhile = false
  let filter = null;

  let depositedTxs = []

  while (!boolWhile) {
    let toBlock = start + unit;
    if(toBlock > end)  {
      toBlock = end;
      boolWhile = true;
    }

    filter = {
      address: depositManagerAddress,
      fromBlock: start,
      toBlock: toBlock,
      topics: [depositId]
    };
    console.log('filter', filter )

    const txs = await ethers.provider.getLogs(filter);

    for (const tx of txs) {
      const { transactionHash } = tx;
      console.log('transactionHash', transactionHash )
      depositedTxs.push(transactionHash)
    }
    start = toBlock;
    console.log('start --- ', start )
  }
  await fs.writeFileSync("./data/depositedTxs.json", JSON.stringify(depositedTxs));
}

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
  // await getDepositTxs();  // 디파짓한 트랜잭션 목록
  // await getAccounts();  // 레이어별 디파짓한 적 있는 계정 목록
  await getTotBalances();  // 코인에이지 정보
  // await getAccountBalances(); // 레이어별 계정별 코인에이지 정보

  // 레이어별 가장 최근 커밋 블록 번호,
  // 가장 최근 커밋 블록 번호

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
