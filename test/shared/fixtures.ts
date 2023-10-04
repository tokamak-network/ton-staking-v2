import hre from 'hardhat'
import { ethers } from 'hardhat'
import {  Wallet, Signer, Contract, BigNumber } from 'ethers'
import { TonStakingV2Fixtures, TonStakingV2NoSnapshotFixtures, JSONFixture } from './fixtureInterfaces'

import { DepositManager } from "../../typechain-types/contracts/stake/managers/DepositManager.sol"
import { DepositManagerProxy } from "../../typechain-types/contracts/stake/managers/DepositManagerProxy"
import { SeigManager } from "../../typechain-types/contracts/stake/managers/SeigManager.sol"
import { SeigManagerProxy } from "../../typechain-types/contracts/stake/managers/SeigManagerProxy"
import { Layer2Registry } from "../../typechain-types/contracts/stake/Layer2Registry.sol"
import { Layer2RegistryProxy } from "../../typechain-types/contracts/stake/Layer2RegistryProxy"
import { CoinageFactory } from "../../typechain-types/contracts/stake/factory/CoinageFactory.sol"
import { RefactorCoinageSnapshot } from "../../typechain-types/contracts/stake/tokens/RefactorCoinageSnapshot"
import { Candidate } from "../../typechain-types/contracts/dao/Candidate.sol"
import { CandidateProxy } from "../../typechain-types/contracts/dao/CandidateProxy"
import { DAOCommitteeExtend } from "../../typechain-types/contracts/dao/DAOCommitteeExtend.sol"
import { CandidateFactory } from "../../typechain-types/contracts/dao/factory/CandidateFactory.sol"
import { CandidateFactoryProxy } from "../../typechain-types/contracts/dao/factory/CandidateFactoryProxy"
import { PowerTONUpgrade } from "../../typechain-types/contracts/stake/powerton/PowerTONUpgrade"

import DepositManager_Json from '../abi/DepositManager.json'
import SeigManager_Json from '../abi/SeigManager.json'
import L2Registry_Json from '../abi/Layer2Registry.json'
import CoinageFactory_Json from '../abi/CoinageFactory.json'
import Ton_Json from '../abi/TON.json'
import Wton_Json from '../abi/WTON.json'
import Tos_Json from '../abi/TOS.json'
import DAOCommitteeProxy_Json from '../abi/DAOCommitteeProxy.json'
import CandidateFactory_Json from '../abi/CandidateFactory.json'
import DAOAgendaManager_Json from '../abi/DAOAgendaManager.json'
import RefactorCoinageSnapshot_Json from '../../artifacts/contracts/stake/tokens/RefactorCoinageSnapshot.sol/RefactorCoinageSnapshot.json'
import DAOCommittee_Json from '../abi/DAOCommittee.json'
import Candidate_Json from '../../artifacts/contracts/dao/Candidate.sol/Candidate.json'
import PowerTON_Json from '../abi/PowerTONSwapperProxy.json'

// export const lastSeigBlock = ethers.BigNumber.from("18146037");
export const lastSeigBlock = ethers.BigNumber.from("18146000");
export const globalWithdrawalDelay  = ethers.BigNumber.from("93046")

export const seigManagerInfo = {
  minimumAmount: ethers.BigNumber.from("1000000000000000000000000000000"),
  powerTONSeigRate: ethers.BigNumber.from("100000000000000000000000000"),
  relativeSeigRate: ethers.BigNumber.from("400000000000000000000000000"),
  daoSeigRate: ethers.BigNumber.from("500000000000000000000000000"),
  seigPerBlock: ethers.BigNumber.from("3920000000000000000000000000"),
  adjustCommissionDelay:  ethers.BigNumber.from("93096"),
}

export const jsonFixtures = async function (): Promise<JSONFixture> {

  return  {
    DepositManager: DepositManager_Json ,
    SeigManager: SeigManager_Json ,
    L2Registry: L2Registry_Json ,
    CoinageFactory: CoinageFactory_Json ,
    TON: Ton_Json ,
    WTON: Wton_Json ,
    TOS: Tos_Json ,
    DAOCommitteeProxy: DAOCommitteeProxy_Json ,
    CandidateFactory: CandidateFactory_Json ,
    DAOAgendaManager: DAOAgendaManager_Json ,
    RefactorCoinageSnapshot: RefactorCoinageSnapshot_Json,
    Candidate: Candidate_Json,
    PowerTON: PowerTON_Json
  }
}

export const tonStakingV2Fixture = async function (): Promise<TonStakingV2Fixtures> {
  const [deployer, addr1, addr2 ] = await ethers.getSigners();
  const {
    DepositManager, SeigManager, L2Registry, CoinageFactory, TON, WTON, TOS, DAOCommitteeProxy,
    CandidateFactory, DAOAgendaManager, AutoCoinageSnapshot2, DaoCommitteeAdminAddress ,
    powerTonAddress, daoVaultAddress,
    level19Address, level19Admin, tokamakAddress, tokamakAdmin,
    powerTonAdminAddress
   } = await hre.getNamedAccounts();

  const contractJson = await jsonFixtures()

  //-------------------------------
  const depositManagerV1 = new ethers.Contract( DepositManager, contractJson.DepositManager.abi, deployer)
  const seigManagerV1 = new ethers.Contract(SeigManager, contractJson.SeigManager.abi,  deployer)
  const layer2RegistryV1 = new ethers.Contract( L2Registry,contractJson.L2Registry.abi, deployer)
  const coinageFactoryV1= new ethers.Contract(CoinageFactory, contractJson.CoinageFactory.abi,  deployer)
  const TONContract = new ethers.Contract(TON, contractJson.TON.abi,  deployer)
  const WTONContract = new ethers.Contract(WTON,  contractJson.WTON.abi, deployer)
  const TOSContract = new ethers.Contract(TOS,  contractJson.TOS.abi, deployer)
  const candidateFactoryV1 = new ethers.Contract(CandidateFactory,  contractJson.CandidateFactory.abi, deployer)
  const daoCommitteeProxy = new ethers.Contract(DAOCommitteeProxy, contractJson.DAOCommitteeProxy.abi, deployer)
  const daoAgendaManager = new ethers.Contract(DAOAgendaManager,  contractJson.DAOAgendaManager.abi, deployer)
  const powerTonProxy= new ethers.Contract(powerTonAddress,  contractJson.PowerTON.abi, deployer)
  console.log('DAOCommitteeProxy', DAOCommitteeProxy)

  //==========================
  //-- DAOCommittee 로직 업데이트
  //--- 1. change  CandidateFactory in DAOCommittee
  await hre.network.provider.send("hardhat_impersonateAccount", [
    DaoCommitteeAdminAddress,
  ]);
  const daoCommitteeAdmin = await hre.ethers.getSigner(DaoCommitteeAdminAddress);

  console.log('DaoCommitteeAdminAddress', DaoCommitteeAdminAddress)

  const daoCommitteeExtend = (await (await ethers.getContractFactory("DAOCommitteeExtend")).connect(deployer).deploy()) as DAOCommitteeExtend;
  await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(daoCommitteeExtend.address)).wait()

  const daoCommittee = (await ethers.getContractAt("DAOCommitteeExtend", DAOCommitteeProxy, daoCommitteeAdmin)) as DAOCommitteeExtend;
  console.log('daoCommittee', daoCommittee.address)

  //-- 기존 디파짓 매니저의 세그매니저를 0으로 설정한다.
  await (await daoCommittee.connect(daoCommitteeAdmin).setTargetSeigManager(
    depositManagerV1.address, ethers.constants.AddressZero)).wait()

  //=====================
  //--파워톤 로직 업데이트
  await hre.network.provider.send("hardhat_impersonateAccount", [
    powerTonAdminAddress,
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    powerTonAdminAddress,
    "0x10000000000000000000000000",
  ]);
  const powerTonAdmin = await hre.ethers.getSigner(powerTonAdminAddress);

  const powerTONUpgradeLogic = (await (await ethers.getContractFactory("PowerTONUpgrade")).connect(deployer).deploy()) as PowerTONUpgrade;
  await (await powerTonProxy.connect(powerTonAdmin).upgradeTo(powerTONUpgradeLogic.address)).wait()

  const powerTON = (await ethers.getContractAt("PowerTONUpgrade", powerTonProxy.address, daoCommitteeAdmin)) as PowerTONUpgrade;
  console.log('powerTON', powerTON.address)

  //----------- v2 배포
  const depositManagerV2Imp = (await (await ethers.getContractFactory("DepositManager")).connect(deployer).deploy()) as DepositManager;
  const depositManagerProxy = (await (await ethers.getContractFactory("DepositManagerProxy")).connect(deployer).deploy()) as DepositManagerProxy;
  await depositManagerProxy.connect(deployer).upgradeTo(depositManagerV2Imp.address);
  const depositManagerV2 = (await ethers.getContractAt("DepositManager", depositManagerProxy.address, deployer)) as DepositManager;

  const seigManagerV2Imp = (await (await ethers.getContractFactory("SeigManager")).connect(deployer).deploy()) as SeigManager;
  const seigManagerProxy = (await (await ethers.getContractFactory("SeigManagerProxy")).connect(deployer).deploy()) as SeigManagerProxy;
  await seigManagerProxy.connect(deployer).upgradeTo(seigManagerV2Imp.address);
  const seigManagerV2 = (await ethers.getContractAt("SeigManager", seigManagerProxy.address, deployer)) as SeigManager;

  const layer2RegistryV2Imp = (await (await ethers.getContractFactory("Layer2Registry")).connect(deployer).deploy()) as Layer2Registry;
  const layer2RegistryProxy = (await (await ethers.getContractFactory("Layer2RegistryProxy")).connect(deployer).deploy()) as Layer2RegistryProxy;
  await layer2RegistryProxy.connect(deployer).upgradeTo(layer2RegistryV2Imp.address);
  const layer2RegistryV2 = (await ethers.getContractAt("Layer2Registry", layer2RegistryProxy.address, deployer)) as Layer2Registry;

  const candidateImp = (await (await ethers.getContractFactory("Candidate")).connect(deployer).deploy()) as Candidate;
  const candidateFactoryLogic = (await (await ethers.getContractFactory("CandidateFactory")).connect(deployer).deploy()) as CandidateFactory;
  const candidateFactoryProxy = (await (await ethers.getContractFactory("CandidateFactoryProxy")).connect(deployer).deploy()) as CandidateFactoryProxy;

  await candidateFactoryProxy.connect(deployer).upgradeTo(candidateFactoryLogic.address);
  const candidateFactory = (await ethers.getContractAt("CandidateFactory", candidateFactoryProxy.address, deployer)) as CandidateFactory;

  await (await daoCommittee.connect(daoCommitteeAdmin).setCandidateFactory(candidateFactoryProxy.address)).wait()
  await (await daoCommittee.connect(daoCommitteeAdmin).setSeigManager(seigManagerProxy.address)).wait()
  await (await daoCommittee.connect(daoCommitteeAdmin).setLayer2Registry(layer2RegistryProxy.address)).wait()

  const refactorCoinageSnapshot = (await (await ethers.getContractFactory("RefactorCoinageSnapshot")).connect(deployer).deploy()) as RefactorCoinageSnapshot;
  const coinageFactoryV2 = (await (await ethers.getContractFactory("CoinageFactory")).connect(deployer).deploy()) as CoinageFactory;
  await (await coinageFactoryV2.connect(deployer).setAutoCoinageLogic(refactorCoinageSnapshot.address)).wait()


  //====== set v2 ==================

  await (await depositManagerV2.connect(deployer).initialize (
    WTONContract.address,
    layer2RegistryProxy.address,
    seigManagerV2.address,
    globalWithdrawalDelay
  )).wait()

  console.log('depositManagerV2 initialized ')
  await (await seigManagerV2.connect(deployer).initialize (
    TONContract.address,
    WTONContract.address,
    layer2RegistryProxy.address,
    depositManagerV2.address,
    seigManagerInfo.seigPerBlock,
    coinageFactoryV2.address,
    lastSeigBlock
  )).wait()
  console.log('seigManagerV2 initialized ')

  await (await seigManagerV2.connect(deployer).setData (
    powerTonAddress,
    daoVaultAddress,
    seigManagerInfo.powerTONSeigRate,
    seigManagerInfo.daoSeigRate,
    seigManagerInfo.relativeSeigRate,
    seigManagerInfo.adjustCommissionDelay,
    seigManagerInfo.minimumAmount
  )).wait()
  console.log('seigManagerV2 setData ')


  await (await layer2RegistryV2.connect(deployer).addMinter(
    daoCommittee.address
  )).wait()

  await (await seigManagerV2.connect(deployer).addMinter(
    layer2RegistryV2.address
  )).wait()

  //==========================
  await hre.network.provider.send("hardhat_impersonateAccount", [
    DAOCommitteeProxy,
  ]);

  await hre.network.provider.send("hardhat_setBalance", [
    DAOCommitteeProxy,
    "0x10000000000000000000000000",
  ]);

  // const daoAdmin = await hre.ethers.getSigner(DAOCommitteeProxy);
  const daoAdmin = await hre.ethers.getSigner(DAOCommitteeProxy);

  // for version 2
  await (await WTONContract.connect(daoAdmin).addMinter(seigManagerV2.address)).wait()

  // for test :
  await (await TONContract.connect(daoAdmin).mint(deployer.address, ethers.utils.parseEther("10000"))).wait()
  await (await WTONContract.connect(daoAdmin).mint(deployer.address, ethers.utils.parseEther("10000"+"0".repeat(9)))).wait()

  //-- v2 배포후에 설정
  await (await candidateFactory.connect(deployer).setAddress(
    depositManagerV2.address,
    DAOCommitteeProxy,
    candidateImp.address,
    TONContract.address,
    WTONContract.address
  )).wait()
  console.log('candidateFactory setAddress ')

  return  {
    deployer: deployer,
    addr1: addr1,
    addr2: addr2,
    depositManagerV1: depositManagerV1 ,
    seigManagerV1: seigManagerV1 ,
    layer2RegistryV1: layer2RegistryV1 ,
    coinageFactoryV1: coinageFactoryV1 ,
    powerTonProxy: powerTonProxy ,
    TON: TONContract,
    WTON: WTONContract ,
    daoCommitteeProxy: daoCommitteeProxy ,
    daoAgendaManager: daoAgendaManager,
    candidateFactoryV1: candidateFactoryV1 ,
    daoCommitteeExtend: daoCommitteeExtend,
    daoCommitteeAdmin: daoCommitteeAdmin,
    daoCommittee: daoCommittee,
    depositManagerV2: depositManagerV2 ,
    depositManagerProxy: depositManagerProxy,
    seigManagerV2: seigManagerV2 ,
    seigManagerProxy: seigManagerProxy,
    layer2RegistryV2: layer2RegistryV2 ,
    layer2RegistryProxy: layer2RegistryProxy,
    candidateFactoryV2: candidateFactory ,
    candidateFactoryProxy: candidateFactoryProxy ,
    candidateImp: candidateImp ,
    refactorCoinageSnapshot: refactorCoinageSnapshot,
    coinageFactoryV2 : coinageFactoryV2,
    powerTonAddress: powerTonAddress,
    daoVaultAddress: daoVaultAddress,
    level19Address: level19Address,
    tokamakAddress: tokamakAddress,
    level19Admin: level19Admin,
    tokamakAdmin: tokamakAdmin,
    daoAdmin: daoAdmin,
    powerTON: powerTON
  }
}


export const tonStakingV2NoSnapshotFixture = async function (): Promise<TonStakingV2NoSnapshotFixtures> {
  const [deployer, addr1, addr2 ] = await ethers.getSigners();
  const {
    DepositManager, SeigManager, L2Registry, CoinageFactory, TON, WTON, TOS, DAOCommitteeProxy,
    CandidateFactory, DAOAgendaManager, AutoCoinageSnapshot2, DaoCommitteeAdminAddress ,
    powerTonAddress, daoVaultAddress,
    level19Address, level19Admin, tokamakAddress, tokamakAdmin,
    powerTonAdminAddress
   } = await hre.getNamedAccounts();

  const contractJson = await jsonFixtures()

  //-------------------------------
  const depositManagerV1 = new ethers.Contract( DepositManager, contractJson.DepositManager.abi, deployer)
  const seigManagerV1 = new ethers.Contract(SeigManager, contractJson.SeigManager.abi,  deployer)
  const layer2RegistryV1 = new ethers.Contract( L2Registry,contractJson.L2Registry.abi, deployer)
  const coinageFactoryV1= new ethers.Contract(CoinageFactory, contractJson.CoinageFactory.abi,  deployer)
  const TONContract = new ethers.Contract(TON, contractJson.TON.abi,  deployer)
  const WTONContract = new ethers.Contract(WTON,  contractJson.WTON.abi, deployer)
  const TOSContract = new ethers.Contract(TOS,  contractJson.TOS.abi, deployer)
  const candidateFactoryV1 = new ethers.Contract(CandidateFactory,  contractJson.CandidateFactory.abi, deployer)
  const daoCommitteeProxy = new ethers.Contract(DAOCommitteeProxy, contractJson.DAOCommitteeProxy.abi, deployer)
  const daoAgendaManager = new ethers.Contract(DAOAgendaManager,  contractJson.DAOAgendaManager.abi, deployer)
  const powerTonProxy= new ethers.Contract(powerTonAddress,  contractJson.PowerTON.abi, deployer)
  console.log('DAOCommitteeProxy', DAOCommitteeProxy)

  //==========================
  //-- DAOCommittee 로직 업데이트
  //--- 1. change  CandidateFactory in DAOCommittee
  await hre.network.provider.send("hardhat_impersonateAccount", [
    DaoCommitteeAdminAddress,
  ]);
  const daoCommitteeAdmin = await hre.ethers.getSigner(DaoCommitteeAdminAddress);

  console.log('DaoCommitteeAdminAddress', DaoCommitteeAdminAddress)

  const daoCommitteeExtend = (await (await ethers.getContractFactory("DAOCommitteeExtend")).connect(deployer).deploy()) as DAOCommitteeExtend;
  await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(daoCommitteeExtend.address)).wait()

  const daoCommittee = (await ethers.getContractAt("DAOCommitteeExtend", DAOCommitteeProxy, daoCommitteeAdmin)) as DAOCommitteeExtend;
  console.log('daoCommittee', daoCommittee.address)

  //-- 기존 디파짓 매니저의 세그매니저를 0으로 설정한다.
  await (await daoCommittee.connect(daoCommitteeAdmin).setTargetSeigManager(
    depositManagerV1.address, ethers.constants.AddressZero)).wait()

  //=====================
  //--파워톤 로직 업데이트
  await hre.network.provider.send("hardhat_impersonateAccount", [
    powerTonAdminAddress,
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    powerTonAdminAddress,
    "0x10000000000000000000000000",
  ]);
  const powerTonAdmin = await hre.ethers.getSigner(powerTonAdminAddress);

  const powerTONUpgradeLogic = (await (await ethers.getContractFactory("PowerTONUpgrade")).connect(deployer).deploy()) as PowerTONUpgrade;
  await (await powerTonProxy.connect(powerTonAdmin).upgradeTo(powerTONUpgradeLogic.address)).wait()

  const powerTON = (await ethers.getContractAt("PowerTONUpgrade", powerTonProxy.address, daoCommitteeAdmin)) as PowerTONUpgrade;
  console.log('powerTON', powerTON.address)

  //----------- v2 배포
  const depositManagerV2Imp = (await (await ethers.getContractFactory("DepositManager")).connect(deployer).deploy()) as DepositManager;
  const depositManagerProxy = (await (await ethers.getContractFactory("DepositManagerProxy")).connect(deployer).deploy()) as DepositManagerProxy;
  await depositManagerProxy.connect(deployer).upgradeTo(depositManagerV2Imp.address);
  const depositManagerV2 = (await ethers.getContractAt("DepositManager", depositManagerProxy.address, deployer)) as DepositManager;

  const seigManagerV2Imp = (await (await ethers.getContractFactory("SeigManager")).connect(deployer).deploy()) as SeigManager;
  const seigManagerProxy = (await (await ethers.getContractFactory("SeigManagerProxy")).connect(deployer).deploy()) as SeigManagerProxy;
  await seigManagerProxy.connect(deployer).upgradeTo(seigManagerV2Imp.address);
  const seigManagerV2 = (await ethers.getContractAt("SeigManager", seigManagerProxy.address, deployer)) as SeigManager;

  const layer2RegistryV2Imp = (await (await ethers.getContractFactory("Layer2Registry")).connect(deployer).deploy()) as Layer2Registry;
  const layer2RegistryProxy = (await (await ethers.getContractFactory("Layer2RegistryProxy")).connect(deployer).deploy()) as Layer2RegistryProxy;
  await layer2RegistryProxy.connect(deployer).upgradeTo(layer2RegistryV2Imp.address);
  const layer2RegistryV2 = (await ethers.getContractAt("Layer2Registry", layer2RegistryProxy.address, deployer)) as Layer2Registry;

  const candidateImp = (await (await ethers.getContractFactory("Candidate")).connect(deployer).deploy()) as Candidate;
  const candidateFactoryLogic = (await (await ethers.getContractFactory("CandidateFactory")).connect(deployer).deploy()) as CandidateFactory;
  const candidateFactoryProxy = (await (await ethers.getContractFactory("CandidateFactoryProxy")).connect(deployer).deploy()) as CandidateFactoryProxy;

  await candidateFactoryProxy.connect(deployer).upgradeTo(candidateFactoryLogic.address);
  const candidateFactory = (await ethers.getContractAt("CandidateFactory", candidateFactoryProxy.address, deployer)) as CandidateFactory;

  await (await daoCommittee.connect(daoCommitteeAdmin).setCandidateFactory(candidateFactoryProxy.address)).wait()
  await (await daoCommittee.connect(daoCommitteeAdmin).setSeigManager(seigManagerProxy.address)).wait()
  await (await daoCommittee.connect(daoCommitteeAdmin).setLayer2Registry(layer2RegistryProxy.address)).wait()

  const autoRefactorCoinage = (await (await ethers.getContractFactory("AutoRefactorCoinage")).connect(deployer).deploy()) as AutoRefactorCoinage;
  const coinageFactoryV2 = (await (await ethers.getContractFactory("AutoRefactorCoinageFactory")).connect(deployer).deploy()) as AutoRefactorCoinageFactory;
  await (await coinageFactoryV2.connect(deployer).setAutoCoinageLogic(autoRefactorCoinage.address)).wait()


  //====== set v2 ==================

  await (await depositManagerV2.connect(deployer).initialize (
    WTONContract.address,
    layer2RegistryProxy.address,
    seigManagerV2.address,
    globalWithdrawalDelay
  )).wait()

  console.log('depositManagerV2 initialized ')
  await (await seigManagerV2.connect(deployer).initialize (
    TONContract.address,
    WTONContract.address,
    layer2RegistryProxy.address,
    depositManagerV2.address,
    seigManagerInfo.seigPerBlock,
    coinageFactoryV2.address,
    lastSeigBlock
  )).wait()
  console.log('seigManagerV2 initialized ')

  await (await seigManagerV2.connect(deployer).setData (
    powerTonAddress,
    daoVaultAddress,
    seigManagerInfo.powerTONSeigRate,
    seigManagerInfo.daoSeigRate,
    seigManagerInfo.relativeSeigRate,
    seigManagerInfo.adjustCommissionDelay,
    seigManagerInfo.minimumAmount
  )).wait()
  console.log('seigManagerV2 setData ')


  await (await layer2RegistryV2.connect(deployer).addMinter(
    daoCommittee.address
  )).wait()

  await (await seigManagerV2.connect(deployer).addMinter(
    layer2RegistryV2.address
  )).wait()

  //==========================
  await hre.network.provider.send("hardhat_impersonateAccount", [
    DAOCommitteeProxy,
  ]);

  await hre.network.provider.send("hardhat_setBalance", [
    DAOCommitteeProxy,
    "0x10000000000000000000000000",
  ]);

  // const daoAdmin = await hre.ethers.getSigner(DAOCommitteeProxy);
  const daoAdmin = await hre.ethers.getSigner(DAOCommitteeProxy);

  // for version 2
  await (await WTONContract.connect(daoAdmin).addMinter(seigManagerV2.address)).wait()

  // for test :
  await (await TONContract.connect(daoAdmin).mint(deployer.address, ethers.utils.parseEther("10000"))).wait()
  await (await WTONContract.connect(daoAdmin).mint(deployer.address, ethers.utils.parseEther("10000"+"0".repeat(9)))).wait()

  //-- v2 배포후에 설정
  await (await candidateFactory.connect(deployer).setAddress(
    depositManagerV2.address,
    DAOCommitteeProxy,
    candidateImp.address,
    TONContract.address,
    WTONContract.address
  )).wait()
  console.log('candidateFactory setAddress ')

  return  {
    deployer: deployer,
    addr1: addr1,
    addr2: addr2,
    depositManagerV1: depositManagerV1 ,
    seigManagerV1: seigManagerV1 ,
    layer2RegistryV1: layer2RegistryV1 ,
    coinageFactoryV1: coinageFactoryV1 ,
    powerTonProxy: powerTonProxy ,
    TON: TONContract,
    WTON: WTONContract ,
    daoCommitteeProxy: daoCommitteeProxy ,
    daoAgendaManager: daoAgendaManager,
    candidateFactoryV1: candidateFactoryV1 ,
    daoCommitteeExtend: daoCommitteeExtend,
    daoCommitteeAdmin: daoCommitteeAdmin,
    daoCommittee: daoCommittee,
    depositManagerV2: depositManagerV2 ,
    depositManagerProxy: depositManagerProxy,
    seigManagerV2: seigManagerV2 ,
    seigManagerProxy: seigManagerProxy,
    layer2RegistryV2: layer2RegistryV2 ,
    layer2RegistryProxy: layer2RegistryProxy,
    candidateFactoryV2: candidateFactory ,
    candidateFactoryProxy: candidateFactoryProxy ,
    candidateImp: candidateImp ,
    autoRefactorCoinage: autoRefactorCoinage,
    coinageFactoryV2 : coinageFactoryV2,
    powerTonAddress: powerTonAddress,
    daoVaultAddress: daoVaultAddress,
    level19Address: level19Address,
    tokamakAddress: tokamakAddress,
    level19Admin: level19Admin,
    tokamakAdmin: tokamakAdmin,
    daoAdmin: daoAdmin,
    powerTON: powerTON
  }
}
