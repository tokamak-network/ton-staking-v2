const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const layer2RegistryAddress = "0x0b3E174A2170083e770D5d4Cf56774D221b7063e";
const depositManagerAddress = "0x56E465f654393fa48f007Ed7346105c7195CEe43";
const seigManagerAddress = "0x710936500aC59e8551331871Cbad3D33d5e0D909";

const pauseBlock = 18231453
const startBlock = 10837675
const dataFolder = './data-mainnet'

async function getLayer2s() {

  const candidateABI = JSON.parse(await fs.readFileSync("./abi/Candidate.json")).abi;
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
  const names = []
  const numberOfLayer2s = await layer2Registry.numLayer2s()

  for (let i = 0; i < numberOfLayer2s; i++) {

    let layer2Address = await layer2Registry.layer2ByIndex(i)
    let coinageAddress = await seigManager.coinages(layer2Address)

    const layerContract = new ethers.Contract(
      layer2Address,
      candidateABI,
      ethers.provider
    );
    let operatorAddress = await layerContract.operator()

    layer2s.push(layer2Address.toLowerCase())
    coinages.push(coinageAddress.toLowerCase())
    names.push({
      oldLayer: layer2Address.toLowerCase(),
      newLayer: '',
      operator: operatorAddress.toLowerCase(),
      name: ''
    })
  }
  console.log({ layer2s });
  console.log({ coinages });
  console.log({ names });
  console.log("length: ", layer2s.length);

  await fs.writeFileSync(dataFolder + "/layer2s.json", JSON.stringify(layer2s));
  await fs.writeFileSync(dataFolder + "/coinages.json", JSON.stringify(coinages));
  await fs.writeFileSync(dataFolder + "/layer2_name_map.json", JSON.stringify(names));

  return layer2s;
}


async function getTotBalances() {

  const seigManagerABI = JSON.parse(await fs.readFileSync("./abi/seigManager.json")).abi;
  const coinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;
  const layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2s.json"));
  const coinages = JSON.parse(await fs.readFileSync(dataFolder + "/coinages.json"));

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

  let last_seig_block = [];
  let layer2_last_commit_block = [];

  //------------------
  let totalSupply = await tot.totalSupply()
  tot_total.push(totalSupply.toString())
  console.log("tot-total-supply: ", tot_total);
  await fs.writeFileSync(dataFolder + "/tot-total-supply.json", JSON.stringify(tot_total));

  //------------------
  let lastSeigBlock = await seigManager.lastSeigBlock()
  console.log("lastSeigBlock: ", lastSeigBlock);
  last_seig_block.push(lastSeigBlock.toString())
  await fs.writeFileSync(dataFolder + "/last-seig-block.json", JSON.stringify(last_seig_block));

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

    let lastCommitBlock = await seigManager.lastCommitBlock(layer)
    layer2_last_commit_block.push({
      layer2: layer,
      coinage: coinage,
      last_commit_block: lastCommitBlock.toString()
    });
  }

  console.log("tot-balances: ", tot_balances);
  await fs.writeFileSync(dataFolder + "/tot-balances.json", JSON.stringify(tot_balances));
  await fs.writeFileSync(dataFolder + "/layer2_last_commit_block.json", JSON.stringify(layer2_last_commit_block));

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
  await fs.writeFileSync(dataFolder + "/coinages-total-supply.json", JSON.stringify(coin_total));
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
  await fs.writeFileSync(dataFolder + "/depositedTxs.json", JSON.stringify(depositedTxs));
}

async function getAccounts() {

  const depositedTxs = JSON.parse(await fs.readFileSync(dataFolder + "/depositedTxs.json"));
  const layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2s.json"));

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
      await fs.writeFileSync(dataFolder + "/depositors.json", JSON.stringify(depositors));
    }
  }

  console.log( depositors )
  await fs.writeFileSync(dataFolder + "/depositors.json", JSON.stringify(depositors));
}


async function getAccountBalances() {
  const coinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;

  const depositors = JSON.parse(await fs.readFileSync(dataFolder + "/depositors.json"));
  const coinages = JSON.parse(await fs.readFileSync(dataFolder + "/coinages-total-supply.json"));


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

      if(balance.gt(ethers.constants.Zero)) {
        deposits.push({
          account: depositor.toLowerCase(),
          balance: balance.toString()
        })
      }
    }
    console.log("layer: ",layer, " , deposits: ", deposits.length);
    await fs.writeFileSync(dataFolder + "/layer2-accounts-balances/"+layer+".json", JSON.stringify(deposits));
  }
}


async function main() {

  // await getLayer2s();  // 모든 레이어 , 코인에이지 목록

  // await getDepositTxs();  // 디파짓한 트랜잭션 목록
  // await getAccounts();  // 레이어별 디파짓한 적 있는 계정 목록

  // await getTotBalances();  // 코인에이지 정보 , last-seig-block, layer2_last_commit_block

  await getAccountBalances(); // 레이어별 계정별 코인에이지 정보

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
