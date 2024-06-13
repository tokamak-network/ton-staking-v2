const { ethers } = require("hardhat");
const { encodeFunctionSignature } = require("web3-eth-abi");

async function func1() {

  const selector1 = encodeFunctionSignature("setLayer2StartBlock(uint256)");
  const selector2 = encodeFunctionSignature("setLayer2Manager(address)");
  const selector3 = encodeFunctionSignature("setL2Registry(address)");
  const selector4 = encodeFunctionSignature("updateSeigniorage()");
  const selector5 = encodeFunctionSignature("updateSeigniorageOperator()");
  const selector6 = encodeFunctionSignature("updateSeigniorageLayer()");
  const selector7 = encodeFunctionSignature("allowIssuanceLayer2Seigs(address)");
  const selector8 = encodeFunctionSignature("totalLayer2TVL()");
  const selector9 = encodeFunctionSignature("layer2RewardInfo(address)");
  const selector10 = encodeFunctionSignature("l2Registry()");
  const selector11 = encodeFunctionSignature("layer2Manager()");
  const selector12 = encodeFunctionSignature("layer2StartBlock()");
  const selector13 = encodeFunctionSignature("l2RewardPerUint()");
  const selector14 = encodeFunctionSignature("unSettledReward(address)");
  const selector15 = encodeFunctionSignature("estimatedDistribute(uint256,address,bool)");
  const selector16 = encodeFunctionSignature("excludeFromSeigniorage(address)");

    let functionBytecodes = [
        selector1, selector2, selector3, selector4, selector5,
        selector6, selector7, selector8, selector9, selector10,
        selector11, selector12, selector13, selector14, selector15,
        selector16];

        console.log('SeigManagerV1_3 add functions : ', functionBytecodes)
}

async function func2() {

  const selector1 = encodeFunctionSignature("ton()");
  const selector2 = encodeFunctionSignature("minDepositGasLimit()");
  const selector3 = encodeFunctionSignature("setMinDepositGasLimit(uint256)");
  const selector4 = encodeFunctionSignature("withdrawAndDepositL2(address,uint256)");

   let functionBytecodes = [
                selector1, selector2, selector3, selector4 ];

      console.log('DepositManagerV1_1 add functions : ', functionBytecodes)
}

const main = async () => {
  await func1()
  await func2()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
