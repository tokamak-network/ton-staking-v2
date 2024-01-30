const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { padLeft } = require('web3-utils');
const { default: test } = require("node:test");

const layer2RegistryAddress = "0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b";
const depositManagerAddress = "0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e";
const seigManagerAddress = "0x0b55a0f463b6defb81c6063973763951712d0e5f";
const tonAddress = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5";
const wtonAddress = "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2";
const wtonHolder ="0x5edcd31b0f93e5ac44106f7e7f0d697ca7bd81e9";
const testerAddress ="0xceb2196addf345f68d1f536ddaa49fe54bcbddad";

const pauseBlock = 19118240
const startBlock = 18416838

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

async function deposit(layerInfo, tester) {

    const seigManagerABI = JSON.parse(await fs.readFileSync("./artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json")).abi;
    const depositManagerABI = JSON.parse(await fs.readFileSync("./artifacts/contracts/stake/managers/DepositManager.sol/DepositManager.json")).abi;

    const wtonABI = JSON.parse(await fs.readFileSync("./abi/WTON.json")).abi;

    const amount = ethers.utils.parseEther("1001"+"0".repeat(9))
    const depositAmount = ethers.utils.parseEther("2000"+"0".repeat(9))

    const depositManager = new ethers.Contract(
        depositManagerAddress,
        depositManagerABI,
        ethers.provider
    );
    const WTON = new ethers.Contract(
        wtonAddress,
        wtonABI,
        ethers.provider
    );

    await hre.network.provider.send("hardhat_impersonateAccount", [
        wtonHolder,
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
        wtonHolder,
        '0x10000000000000000000000000'
    ]);

    const holder = await hre.ethers.getSigner(wtonHolder);

    await (await WTON.connect(holder).transfer(
        testerAddress,
        amount.add(depositAmount),
        {from: wtonHolder}
    )).wait()

    console.log('--- updateSeigniorageLayer ', layerInfo.newLayer)

    // WTON approve
    await (await WTON.connect(tester).approve(depositManager.address, depositAmount.add(amount))).wait()

    // deposit 2000 &  deposit 1001 TON to operator
    await (await depositManager.connect(tester)["deposit(address,uint256)"](
        layerInfo.newLayer,
        depositAmount
    )).wait()


    await (await depositManager.connect(tester)["deposit(address,address,uint256)"](
        layerInfo.newLayer,
        layerInfo.operator,
        amount
    )).wait()

}


async function updateSeigs(layerInfo, tester) {

    const seigManagerABI = JSON.parse(await fs.readFileSync("./artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json")).abi;

    const seigManagerManager = new ethers.Contract(
        seigManagerAddress,
        seigManagerABI,
        ethers.provider
    );

    console.log('--- updateSeigniorageLayer ', layerInfo.newLayer)

    await (await seigManagerManager.connect(tester).updateSeigniorageLayer(layerInfo.newLayer)).wait()
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


    console.log('----- deposit  &  deposit 1001 TON to operator')
    // 2. deposit 2000 &  deposit 1001 TON to operator
    await hre.network.provider.send("hardhat_impersonateAccount", [
        testerAddress,
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
        testerAddress,
        '0x10000000000000000000000000'
    ]);
    const tester = await hre.ethers.getSigner(testerAddress);

    await deposit(layerInfo, tester);
    console.log('-----')

    // 1. get balance
    const prevBalances = await getAccountBalances("0x3bEb0d709Cd76b264A20839Cf9A7A1836e1CdE80", layerInfo.newLayer, filteredAccounts)
    console.log("prev balances : " , prevBalances)

    console.log('-----')
    // updateSeigs
    await updateSeigs(layerInfo, tester)

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