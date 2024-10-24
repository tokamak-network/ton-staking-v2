const { ethers } = require("hardhat");
const DepositManagerV1_1_Json = require('../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')
const SeigManager_Json = require('../artifacts/contracts/stake/managers/SeigManagerV1_2.sol/SeigManagerV1_2.json')
const SeigManagerV1_3_Json = require('../artifacts/contracts/stake/managers/SeigManagerV1_3.sol/SeigManagerV1_3.json')
const DAO_Json = require('../artifacts/contracts/dao/DAOCommitteeAddV1_1.sol/DAOCommitteeAddV1_1.json')
const SeigManagerV1_2_Json = require('../artifacts/contracts/stake/managers/SeigManagerV1_2.sol/SeigManagerV1_2.json')
const TON_Json = require('../test/abi/TON.json')

// mainnet
const DepositManagerAddress = "0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e"
const SeigManagerAddress = "0x0b55a0f463b6defb81c6063973763951712d0e5f"

const TonAddress = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5"

const tester = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";

const INITIAL_TOTAL_SUPPLY_MAINNET = ethers.BigNumber.from("50000000000000000000000000000000000")
const BURNT_AMOUNT_MAINNET = ethers.BigNumber.from("178111666909855730000000000000000")
const SEIG_START_MAINNET = ethers.BigNumber.from("10837698")
const SeigPerBlock = ethers.BigNumber.from("3920000000000000000000000000")
const RelativeSeigRate = ethers.BigNumber.from("500000000000000000000000000")
const DdaoSeigRate = ethers.BigNumber.from("500000000000000000000000000")
const RAY = ethers.BigNumber.from("1000000000000000000000000000")
const WAI = ethers.BigNumber.from("1000000000000000000")
async function totalSupplyOfTon (deployer, blockNumber) {
    const tonContract = new ethers.Contract(TonAddress,  TON_Json.abi, deployer)

    let tonBalance = await tonContract.balanceOf("0x0000000000000000000000000000000000000001")
    let tos =
    3920000000000000000000000000
    tos = INITIAL_TOTAL_SUPPLY_MAINNET.add(
        SeigPerBlock.mul(blockNumber.sub(SEIG_START_MAINNET))
    ).sub(
        tonBalance.mul(ethers.BigNumber.from("1000000000"))
    ).sub(BURNT_AMOUNT_MAINNET)
    return tos
}


async function estimatedDistribute (
    deployer,
    blockNumber
) {
    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManagerV1_2_Json.abi, deployer)
    const spansYear = 365*(60*60*24)/12;
    const lastSeigBlock = await seigManager.lastSeigBlock()
    let spans = blockNumber - lastSeigBlock;
    let spansBN = ethers.BigNumber.from(""+spans)
    console.log('lastSeigBlock', lastSeigBlock)
    console.log('spansYear', spansYear)
    console.log('spans', spans)

    let tos = await totalSupplyOfTon(deployer, ethers.BigNumber.from(""+blockNumber));
    let prevTotalSupply = await seigManager.stakeOfTotal();

    let maxSeig = SeigPerBlock.mul(spansBN)
    let stakedSeig =  maxSeig.mul(prevTotalSupply).div(tos); // for stakers
    let l2TotalSeigs = ethers.constants.Zero // l2 sequencers

    let totalPseig = (maxSeig.sub(stakedSeig).sub(l2TotalSeigs)).mul(RelativeSeigRate).div(RAY)

    console.log('tos', tos)
    console.log('prevTotalSupply', prevTotalSupply)
    console.log('stakedSeig', stakedSeig)
    console.log('totalPseig', totalPseig)

    let seigsPerStakedTon = stakedSeig.add(totalPseig).div(prevTotalSupply.div(RAY))
    console.log('seigsPerStakedTon', ethers.utils.formatUnits(seigsPerStakedTon,27) ," WTON")

    let seigsOneBlockPerStakedTon = seigsPerStakedTon.div(spansBN)
    console.log('seigsOneBlockPerStakedTon', ethers.utils.formatUnits(seigsOneBlockPerStakedTon,27) ," WTON")

    let seigsYearPerStakedTon = seigsOneBlockPerStakedTon.mul(spansYear)
    console.log('seigsYearPerStakedTon', ethers.utils.formatUnits(seigsYearPerStakedTon,27) ," WTON")

    console.log('=================================')
    console.log('APR (단리) = 단위 수익률 x 연간 정산 횟수')
    console.log('APY (복리) = (1+단위 수익률)^연간 정산 횟수 - 1')

    let uint = spans * 12
    let uintDay = spans * 12 / (60*60*24)
    let numberOfSettles =  spansYear/spans
    let yieldUnit = seigsPerStakedTon.mul(WAI).div(RAY).mul(ethers.BigNumber.from("100"))
    yieldUnit = Number(yieldUnit) / 1e18

    let apy = (1 + yieldUnit)^numberOfSettles - 1
    let apr = yieldUnit * numberOfSettles

    console.log('단위 정산기간 = 업데이트시뇨리지 대상 블록수 * 12 초 = ', uint ," 초 (" ,uintDay," 일) ")
    console.log('일년동안 정산 횟수 ', numberOfSettles ," 회")
    console.log('단위 정산기간 동안 1개의 TON 스테이킹시 받는 시뇨리지 = ', ethers.utils.formatUnits(seigsPerStakedTon,27) ," WTON ")
    console.log('단위 수익률 = ', yieldUnit ," %" )
    console.log('APR = ', apr ," %" )
    console.log('APY = ', apy ," %" )

}


async function checkApy() {

    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    let deployerAddress = await deployer.getAddress()

    await hre.network.provider.send("hardhat_impersonateAccount", [
        tester,
        ]);
    await hre.network.provider.send("hardhat_setBalance", [
        tester,
        "0x10000000000000000000000000",
    ]);
    deployer = await hre.ethers.getSigner(tester);
    deployerAddress = tester
    console.log("deployer", deployerAddress)

    //-----------------
    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)
    const seigManagerV1_3 = new ethers.Contract(SeigManagerAddress,  SeigManagerV1_3_Json.abi, deployer)

    let block = await ethers.provider.getBlock('latest')
    console.log('block', block.number)

    await estimatedDistribute(deployer, block.number);

}

const main = async () => {
    await checkApy()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
