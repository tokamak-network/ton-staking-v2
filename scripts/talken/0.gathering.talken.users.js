const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { padLeft } = require('web3-utils');

const layer2RegistryAddress = "0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b";
const depositManagerAddress = "0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e";
const seigManagerAddress = "0x0b55a0f463b6defb81c6063973763951712d0e5f";
const tonAddress = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5";
const wtonAddress = "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2";
const tonHolder ="0x20885c9cce922ab30cc5d84dcfc0f47c41bbe5e8";

const pauseBlock = 19116303
const startBlock = 18416838
// const dataFolder = './data-mainnet'

// async function getLayer2s() {

//   const candidateABI = JSON.parse(await fs.readFileSync("./abi/Candidate.json")).abi;
//   const layer2RegistryABI = JSON.parse(await fs.readFileSync("./abi/layer2Registry.json")).abi;
//   const seigManagerABI = JSON.parse(await fs.readFileSync("./abi/seigManager.json")).abi;

//   const layer2Registry = new ethers.Contract(
//     layer2RegistryAddress,
//     layer2RegistryABI,
//     ethers.provider
//   );

//   const seigManager = new ethers.Contract(
//     seigManagerAddress,
//     seigManagerABI,
//     ethers.provider
//   );
//   const layer2s = []
//   const coinages = []
//   const names = []
//   const numberOfLayer2s = await layer2Registry.numLayer2s()

//   for (let i = 0; i < numberOfLayer2s; i++) {

//     let layer2Address = await layer2Registry.layer2ByIndex(i)
//     let coinageAddress = await seigManager.coinages(layer2Address)

//     const layerContract = new ethers.Contract(
//       layer2Address,
//       candidateABI,
//       ethers.provider
//     );
//     let operatorAddress = await layerContract.operator()

//     layer2s.push(layer2Address.toLowerCase())
//     coinages.push(coinageAddress.toLowerCase())
//     names.push({
//       oldLayer: layer2Address.toLowerCase(),
//       newLayer: '',
//       operator: operatorAddress.toLowerCase(),
//       name: ''
//     })
//   }
//   console.log({ layer2s });
//   console.log({ coinages });
//   console.log({ names });
//   console.log("length: ", layer2s.length);

// //   await fs.writeFileSync(dataFolder + "/layer2s.json", JSON.stringify(layer2s));
// //   await fs.writeFileSync(dataFolder + "/coinages.json", JSON.stringify(coinages));
// //   await fs.writeFileSync(dataFolder + "/layer2_name_map.json", JSON.stringify(names));

//   return layer2s;
// }


// async function getTotBalances() {

//   const seigManagerABI = JSON.parse(await fs.readFileSync("./abi/seigManager.json")).abi;
//   const coinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;
//   const layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2s.json"));
//   const coinages = JSON.parse(await fs.readFileSync(dataFolder + "/coinages.json"));

//   const seigManager = new ethers.Contract(
//     seigManagerAddress,
//     seigManagerABI,
//     ethers.provider
//   );

//   let totAddress = await seigManager.tot()
//   const tot = new ethers.Contract(
//     totAddress,
//     coinageABI,
//     ethers.provider
//   );
//   console.log("totAddress: ", totAddress);
//   let tot_total = [];
//   let tot_balances = [];

//   let last_seig_block = [];
//   let layer2_last_commit_block = [];

//   //------------------
//   let totalSupply = await tot.totalSupply()
//   tot_total.push(totalSupply.toString())
//   console.log("tot-total-supply: ", tot_total);
//   await fs.writeFileSync(dataFolder + "/tot-total-supply.json", JSON.stringify(tot_total));

//   //------------------
//   let lastSeigBlock = await seigManager.lastSeigBlock()
//   console.log("lastSeigBlock: ", lastSeigBlock);
//   last_seig_block.push(lastSeigBlock.toString())
//   await fs.writeFileSync(dataFolder + "/last-seig-block.json", JSON.stringify(last_seig_block));

//   let j = 0;
//   //------------------
//   for (j = 0; j < layer2s.length; j++) {
//     let layer = layer2s[j].toLowerCase();
//     let coinage = coinages[j].toLowerCase();

//     let balance = await tot.balanceOf(layer)
//     tot_balances.push({
//       layer2: layer,
//       coinage: coinage,
//       balance: balance.toString()
//     })

//     let lastCommitBlock = await seigManager.lastCommitBlock(layer)
//     let commissionRates = await seigManager.commissionRates(layer)
//     let isCommissionRateNegative = await seigManager.isCommissionRateNegative(layer)
//     let delayedCommissionBlock = await seigManager.delayedCommissionBlock(layer)

//     layer2_last_commit_block.push({
//       layer2: layer,
//       coinage: coinage,
//       last_commit_block: lastCommitBlock.toString(),
//       commissionRates: commissionRates.toString(),
//       isCommissionRateNegative: isCommissionRateNegative,
//       delayedCommissionBlock: delayedCommissionBlock.toString()
//     });
//   }

//   console.log("tot-balances: ", tot_balances);
//   await fs.writeFileSync(dataFolder + "/tot-balances.json", JSON.stringify(tot_balances));
//   await fs.writeFileSync(dataFolder + "/layer2_last_commit_block.json", JSON.stringify(layer2_last_commit_block));

//   //------------------
//   let coin_total = [];

//   let i = 0;
//   for (i = 0; i < layer2s.length; i++) {
//     let layer = layer2s[i].toLowerCase();
//     let coinage = coinages[i].toLowerCase();

//     const coin = new ethers.Contract(
//       coinage,
//       coinageABI,
//       ethers.provider
//     );

//     let totals = await coin.totalSupply()
//     coin_total.push({
//       layer2: layer,
//       coinage: coinage,
//       balance: totals.toString()
//     })
//   }
//   console.log("coin_total: ", coin_total);
//   await fs.writeFileSync(dataFolder + "/coinages-total-supply.json", JSON.stringify(coin_total));
//   //------------------
//   return true;
// }
function marshalString (str) {
    if (str.slice(0, 2) === '0x') return str;
    return '0x'.concat(str);
}

function unmarshalString (str) {
    if (str.slice(0, 2) === '0x') return str.slice(2);
    return str;
}

async function getDepositTxs(layerInfo) {
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

  let topic1 = '0x000000000000000000000000'+layerInfo.newLayer.substring(2)

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
      topics: [depositId, topic1]
    };
    // console.log('filter', filter )

    const txs = await ethers.provider.getLogs(filter);
    // console.log('txs', txs )

    for (const tx of txs) {
      const { transactionHash } = tx;
    //   console.log('transactionHash', transactionHash )
      depositedTxs.push(transactionHash)
    }
    start = toBlock;
  }
//   await fs.writeFileSync(dataFolder + "/depositedTxs.json", JSON.stringify(depositedTxs));

    return depositedTxs
}

async function getAccounts(depositedTxs, layerAddress) {

    let depositors = [];

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
        if(layer == layerAddress.toLowerCase()){
            let account = depositor.toLowerCase()
            if(!depositors.includes(account)) depositors.push(account)
        }

        i++
    }


    return depositors

}

async function filteringAccount(accounts) {
    let depositors = [];
    let i = 0
    for (const item of accounts) {
        // console.log(item)
        let account = item.account.toLowerCase()
        if(!depositors.includes(account)) depositors.push(account)
        i++
    }
    return depositors
}

async function getAccountBalances(coinageAddress, layer, depositorsList) {

  const coinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;

    const coin = new ethers.Contract(
        coinageAddress,
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

    return deposits

}

async function depositAndUpdateSeigs(layerInfo) {

    const depositManagerABI = JSON.parse(await fs.readFileSync("./abi/DepositManager.json")).abi;
    // const seigManagerABI = JSON.parse(await fs.readFileSync("./abi/SeigManager.json")).abi;
    const seigManagerABI = JSON.parse(await fs.readFileSync("./artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json")).abi;

    const coinageABI = JSON.parse(await fs.readFileSync("./abi/AutoRefactorCoinage.json")).abi;
    const tonABI = JSON.parse(await fs.readFileSync("./abi/TON.json")).abi;
    const amount = ethers.utils.parseEther("1001")

    const depositManager = new ethers.Contract(
        depositManagerAddress,
        depositManagerABI,
        ethers.provider
    );
    const coinageManager = new ethers.Contract(
        depositManagerAddress,
        depositManagerABI,
        ethers.provider
    );
    const seigManagerManager = new ethers.Contract(
        seigManagerAddress,
        seigManagerABI,
        ethers.provider
    );

    const TON = new ethers.Contract(
        tonAddress,
        tonABI,
        ethers.provider
    );
    await hre.network.provider.send("hardhat_impersonateAccount", [
        layerInfo.operator,
    ]);
    const operator = await hre.ethers.getSigner(layerInfo.operator);

    await hre.network.provider.send("hardhat_impersonateAccount", [
        tonHolder,
    ]);
    const holder = await hre.ethers.getSigner(tonHolder);
    await (await TON.connect(holder).transfer(
        layerInfo.operator,
        amount,
        {from: tonHolder}
    )).wait()

    await hre.network.provider.send("hardhat_setBalance", [
        layerInfo.operator,
        '0x10000000000000000000000000'
    ]);
    console.log('--- updateSeigniorageLayer ', layerInfo.newLayer)

    const data = marshalString(
        [depositManagerAddress, layerInfo.newLayer]
          .map(unmarshalString)
          .map(str => padLeft(str, 64))
          .join(''),
    );

    await (await TON.connect(operator).approveAndCall(
        wtonAddress,
        amount,
        data,
        {from: layerInfo.operator}
    )).wait()


    await (await seigManagerManager.connect(operator).updateSeigniorageLayer(layerInfo.newLayer)).wait()
}

function findBalance(items, account) {

    let value ;
    for (let i = 0; i < items.length; i++){
        if(items[i].account == account) {
            value = items[i].balance ;
            break;
        }
    }
    return value;
}
async function calcSeigs(prevBalances, afterBalances) {

    let len = prevBalances.length;
    let depositors = []
    let i = 0;
    for (i = 0; i < len ; i++){
        let account = prevBalances[i].account;
        let prevBalance = prevBalances[i].balance;
        let afterBalance = findBalance(afterBalances, account);

        if(afterBalance != undefined && afterBalance != null) {
            let prevBalanceBN = ethers.BigNumber.from(prevBalance)
            let afterBalanceBN = ethers.BigNumber.from(afterBalance)
            depositors.push(
                {account: account, seigs: afterBalanceBN.sub(prevBalanceBN).toString() }
            )
        }
    }

    return depositors
}

async function main() {

    // talken
    const layerInfo = {"oldLayer":"0xb9d336596ea2662488641c4ac87960bfdcb94c6e","newLayer":"0x36101b31e74c5E8f9a9cec378407Bbb776287761","operator":"0xcc2f386adca481a00d614d5aa77a30984f264a07","name":"Talken"}
    const oldUsers = [{"account":"0x86f2d556c21ca350dce7988f08d4b5c61cc25144","balance":"2000000000000000000000000000000"},{"account":"0x6e40960315ce2906577042c78e03006da3f55226","balance":"6000000000000000000000000000"},{"account":"0x85d8d5eb9f6d1c9dd61ff39ee99f68c77d6f7780","balance":"3000000000000000000000000000"},{"account":"0xd040baeb020692d62a0ec7811fb6be9b96f9844e","balance":"5000000000000000000000000000"},{"account":"0x2b8fa2d118ff2e512ba76f6a8c19dea4e75df05a","balance":"1000000000000000000000000000"},{"account":"0x61009474455ee644bce02d729d4d29df2f3bda00","balance":"1000000000000000000000000000"},{"account":"0xbe3ee1401be4bd18eb75ab528b88ffc1df8c6007","balance":"174000000000000000000000000000"},{"account":"0x30448930a038fec80f8534fa54a24ad0f5393dd4","balance":"420920000000000000000000000000"},{"account":"0xceb2196addf345f68d1f536ddaa49fe54bcbddad","balance":"5000000000000000000000000000"}]
    const filteredAccounts = await filteringAccount(oldUsers)
    // console.log(filteredAccounts)

    const depositedTxs = await getDepositTxs(layerInfo);  // 디파짓한 트랜잭션 목록
    const accountList = await getAccounts(depositedTxs, layerInfo.newLayer);  // 레이어별 디파짓한 적 있는 계정 목록
    // console.log(accountList)
    let i;
    let len = accountList.length
    for (i = 0; i < len; i++) {
        if(!filteredAccounts.includes(accountList[i])) filteredAccounts.push(accountList[i])
    }

    // 0. talken accounts
    console.log("talken accounts : " , filteredAccounts)

    // 1. get balance
    const prevBalances = await getAccountBalances("0x3bEb0d709Cd76b264A20839Cf9A7A1836e1CdE80", layerInfo.newLayer, filteredAccounts)
    console.log("prev balances : " , prevBalances)

    // 2. deposit 1001 TON of operator
    await depositAndUpdateSeigs(layerInfo);
    console.log('-----')

    // 3. get balance
    const afterBalances = await getAccountBalances("0x3bEb0d709Cd76b264A20839Cf9A7A1836e1CdE80", layerInfo.newLayer, filteredAccounts)
    console.log("after balances : " , afterBalances)

    console.log('-----')
    const addSeigs =  await calcSeigs(prevBalances, afterBalances)
    console.log('addSeigs : ', addSeigs)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });