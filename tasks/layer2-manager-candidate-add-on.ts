import '@nomiclabs/hardhat-ethers'
import { BytesLike, ethers } from 'ethers'
import { task, types } from 'hardhat/config'
// import { HardhatRuntimeEnvironment } from 'hardhat/types'
import Layer2ManagerV1_1_ABI from "./abi/Layer2ManagerV1_1.json"
import TON_ABI from "./abi/TON.json"
import CandidateAddOn_ABI from "./abi/CandidateAddOnV1_1.json"
import OperatorManager_ABI from "./abi/OperatorManagerV1_1.json"

task("register-candidate-add-on", "Register CandidateAddOn")
  .addParam("tonAddress", "The TON Address")
  .addParam("layer2ManagerAddress", "The layer2Manager Address")
  .addParam("rollupConfig", "The rollupConfig address")
  .addParam("amount", "transferred amount, it must be greater than 1000.1 TON")
  .addParam("memo", "layer's name")
  .setAction(async (taskArgs, hre) => {
    console.log(taskArgs)

    const [deployer] = await hre.ethers.getSigners()
    console.log('deployer: ',deployer.address)
    const amount = ethers.BigNumber.from(taskArgs.amount)

    const layer2Manager  = new ethers.Contract(taskArgs.layer2ManagerAddress, Layer2ManagerV1_1_ABI.abi, deployer)
    const ton  = new ethers.Contract(taskArgs.tonAddress, TON_ABI.abi,  deployer)
    const minAmount = await layer2Manager.minimumInitialDepositAmount();

    if (amount.lt(minAmount)) {
      console.log("The amount value must be greater than ", ethers.utils.formatEther(minAmount) ," TON" );
      return;
    }

    const balanceTon = await ton.balanceOf(deployer.address)
    if (balanceTon.lt(amount)) {
      console.log("Your TON Balance is insufficient." );
      return;
    }

    let allowance = await ton.allowance(deployer.address, layer2Manager.address)
    if(allowance.lt(amount)){
      await (await ton.connect(deployer).approve(layer2Manager.address, amount)).wait()
    }

    const tx2 = await layer2Manager.connect(deployer).registerCandidateAddOn(
      taskArgs.rollupConfig, amount, true, taskArgs.memo
    );

    console.log('registerCandidateAddOn tx: ',tx2.hash)
    const receipt = await tx2.wait();

    const topic = layer2Manager.interface.getEventTopic('RegisteredCandidateAddOn');
    const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
    const deployedEvent = layer2Manager.interface.parseLog(log);
    const candidateAddOnAddress = deployedEvent.args.candidateAddOn
    const candidateAddOn  = new ethers.Contract(candidateAddOnAddress, CandidateAddOn_ABI.abi,  deployer)
    const operatorManagerAddress = await candidateAddOn.operator()
    const operatorManager  = new ethers.Contract(operatorManagerAddress, OperatorManager_ABI.abi,  deployer)
    const manager  = await operatorManager.manager()

    console.log('rollupConfig     : ', deployedEvent.args.rollupConfig)
    console.log('candidateAddOn   : ', candidateAddOnAddress)
    console.log('operatorManager  : ', operatorManagerAddress)
    console.log('operatorManager\'s manager  : ', manager)

  });

