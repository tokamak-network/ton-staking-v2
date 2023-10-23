import hre from 'hardhat'
import { ethers , deployments, getNamedAccounts, network } from 'hardhat'

import { readContracts, deployedContracts } from "../common_func"

import {  Wallet, Signer, Contract, BigNumber } from 'ethers'
import { TonStakingV2Fixtures, TonStakingV2NoSnapshotFixtures, JSONFixture } from './fixtureInterfaces'

import { DepositManagerForMigration } from "../../typechain-types/contracts/stake/managers/DepositManagerForMigration.sol"
import { DepositManager } from "../../typechain-types/contracts/stake/managers/DepositManager.sol"
import { DepositManagerProxy } from "../../typechain-types/contracts/stake/managers/DepositManagerProxy"
import { SeigManager } from "../../typechain-types/contracts/stake/managers/SeigManager.sol"
import { SeigManagerMigration } from "../../typechain-types/contracts/stake/managers/SeigManagerMigration.sol"
import { SeigManagerProxy } from "../../typechain-types/contracts/stake/managers/SeigManagerProxy"
import { Layer2Registry } from "../../typechain-types/contracts/stake/Layer2Registry.sol"
import { Layer2RegistryProxy } from "../../typechain-types/contracts/stake/Layer2RegistryProxy"
import { CoinageFactory } from "../../typechain-types/contracts/stake/factory/CoinageFactory.sol"
import { AutoRefactorCoinageFactory } from "../../typechain-types/contracts/stake/factory/AutoRefactorCoinageFactory.sol"

import { RefactorCoinageSnapshot } from "../../typechain-types/contracts/stake/tokens/RefactorCoinageSnapshot.sol"
import { AutoRefactorCoinage } from "../../typechain-types/contracts/stake/tokens/AutoRefactorCoinage"

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

export const lastSeigBlock = ethers.BigNumber.from("18169346");
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
  // console.log('DAOCommitteeProxy', DAOCommitteeProxy)

  //==========================
  //-- DAOCommittee 로직 업데이트
  //--- 1. change  CandidateFactory in DAOCommittee
  await hre.network.provider.send("hardhat_impersonateAccount", [
    DaoCommitteeAdminAddress,
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    DaoCommitteeAdminAddress,
    "0x10000000000000000000000000",
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

  console.log('coinageFactoryV2', coinageFactoryV2.address)
  console.log('refactorCoinageSnapshot', refactorCoinageSnapshot.address)

  //====== set v2 ==================

  await (await depositManagerV2.connect(deployer).initialize (
    WTONContract.address,
    layer2RegistryProxy.address,
    seigManagerV2.address,
    globalWithdrawalDelay,
    DepositManager
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
    globalWithdrawalDelay,
    DepositManager
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

const getContractAddress = function (contractInfos:any, name:string) : string {
  return contractInfos.abis[name].address ;
}

const getContractAbi = function (contractInfos:any, name:string): string {
  return contractInfos.abis[name].abi ;
}

const getContract = function (contractInfos:any, name:string) : string{
  return new ethers.Contract(
      contractInfos.abis[name].address,
      contractInfos.abis[name].abi,
      ethers.provider
  );
}

export const deployedTonStakingV2Fixture = async function (): Promise<TonStakingV2Fixtures> {
    const [deployer, addr1, addr2 ] = await ethers.getSigners();
    const {
      DepositManager, SeigManager, L2Registry, CoinageFactory, TON, WTON, TOS, DAOCommitteeProxy,
      CandidateFactory, DAOAgendaManager, AutoCoinageSnapshot2, DaoCommitteeAdminAddress ,
      powerTonAddress, daoVaultAddress,
      level19Address, level19Admin, tokamakAddress, tokamakAdmin,
      powerTonAdminAddress
    } = await getNamedAccounts();
    console.log('*** hre.network.name', hre.network.name)
    let deployment_DAOCommitteeExtend = await deployments.get("DAOCommitteeExtend")
    // console.log('deployment_DAOCommitteeExtend', deployment_DAOCommitteeExtend.address)

    const contractJson = await jsonFixtures()
    const contractInfos = await readContracts(__dirname+'/../../deployments/' + hre.network.name);
    // console.log('contractInfos', contractInfos.names)
    // console.log('deployer', deployer.address)

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

    //==========================
    //-- DAOCommittee 로직 업데이트
    //--- 1. change  CandidateFactory in DAOCommittee
    await hre.network.provider.send("hardhat_impersonateAccount", [
      DaoCommitteeAdminAddress,
    ]);
    const daoCommitteeAdmin = await hre.ethers.getSigner(DaoCommitteeAdminAddress);

    const daoCommitteeExtend = (await ethers.getContractAt("DAOCommitteeExtend", getContractAddress(contractInfos, 'DAOCommitteeExtend'), daoCommitteeAdmin)) as DAOCommitteeExtend;

    // let logic = await daoCommitteeProxy.implementation()
    // console.log('daoCommitteeProxy logic',logic)

    if ( (await daoCommitteeProxy.implementation()) != getContractAddress(contractInfos, 'DAOCommitteeExtend')) {
      await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(daoCommitteeExtend.address)).wait()
    }

    const daoCommittee = (await ethers.getContractAt("DAOCommitteeExtend", DAOCommitteeProxy, daoCommitteeAdmin)) as DAOCommitteeExtend;
    // console.log('daoCommittee', daoCommittee.address)

    let pauseProxy = await daoCommitteeProxy.pauseProxy()
    if(pauseProxy) {
      await (await daoCommitteeProxy.connect(daoCommitteeAdmin).setProxyPause(false)).wait()
    }

    //-- 기존 디파짓 매니저의 세그매니저를 0으로 설정한다.
    // await (await daoCommittee.connect(daoCommitteeAdmin).setTargetSeigManager(
    //   depositManagerV1.address, ethers.constants.AddressZero)).wait()

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
    // console.log('powerTonAdminAddress', powerTonAdminAddress)

    const PowerTONUpgradeDep = await deployments.get("PowerTONUpgrade")
    const powerTONUpgradeLogic = (await ethers.getContractAt("PowerTONUpgrade", PowerTONUpgradeDep.address, deployer)) as PowerTONUpgrade;

    if ((await powerTonProxy.implementation()) != powerTONUpgradeLogic.address) {
      await (await powerTonProxy.connect(powerTonAdmin).upgradeTo(powerTONUpgradeLogic.address)).wait()
    }
    const powerTON = (await ethers.getContractAt("PowerTONUpgrade", powerTonProxy.address, daoCommitteeAdmin)) as PowerTONUpgrade;
    // console.log('powerTON', powerTON.address)

    //===================== v2
    const DepositManagerDep = await deployments.get("DepositManager")
    const depositManagerV2Imp = (await ethers.getContractAt("DepositManager", DepositManagerDep.address, deployer)) as DepositManager;

    const depositManagerProxy = (await ethers.getContractAt("DepositManagerProxy",getContractAddress(contractInfos, 'DepositManagerProxy'), deployer)) as DepositManagerProxy;

    if ( (await depositManagerProxy.implementation()) != DepositManagerDep.address) {
      await (await depositManagerProxy.connect(deployer).upgradeTo(DepositManagerDep.address)).wait()
    }
    const depositManagerV2 = (await ethers.getContractAt("DepositManager", depositManagerProxy.address, deployer)) as DepositManager;
    // console.log('depositManagerV2', depositManagerV2.address)

    const SeigManagerDep = await deployments.get("SeigManager")
    const seigManagerV2Imp = (await ethers.getContractAt("SeigManager", SeigManagerDep.address, deployer)) as SeigManager;
    const seigManagerProxy = (await ethers.getContractAt("SeigManagerProxy", getContractAddress(contractInfos, 'SeigManagerProxy'), deployer)) as SeigManagerProxy;
    if ( (await seigManagerProxy.implementation()) != SeigManagerDep.address) {
      await (await seigManagerProxy.connect(deployer).upgradeTo(SeigManagerDep.address)).wait()
    }
    const seigManagerV2 = (await ethers.getContractAt("SeigManager", seigManagerProxy.address, deployer)) as SeigManager;
    // console.log('seigManagerV2', seigManagerV2.address)

    const Layer2RegistryDep = await deployments.get("Layer2Registry")
    const layer2RegistryV2Imp = (await ethers.getContractAt("Layer2Registry", Layer2RegistryDep.address, deployer)) as Layer2Registry;
    const layer2RegistryProxy = (await ethers.getContractAt("Layer2RegistryProxy",getContractAddress(contractInfos, 'Layer2RegistryProxy'), deployer)) as Layer2RegistryProxy;
    if ( (await layer2RegistryProxy.implementation()) != Layer2RegistryDep.address) {
      await (await layer2RegistryProxy.connect(deployer).upgradeTo(Layer2RegistryDep.address)).wait()
    }
    const layer2RegistryV2 = (await ethers.getContractAt("Layer2Registry", layer2RegistryProxy.address, deployer)) as Layer2Registry;
    // console.log('layer2RegistryV2', layer2RegistryV2.address)

    const candidateImp = (await ethers.getContractAt("Candidate", getContractAddress(contractInfos, 'Candidate'), deployer)) as Candidate;
    const candidateFactoryLogic = (await ethers.getContractAt("CandidateFactory",  getContractAddress(contractInfos, 'CandidateFactory'), deployer)) as CandidateFactory;
    const candidateFactoryProxy = (await ethers.getContractAt("CandidateFactoryProxy", getContractAddress(contractInfos, 'CandidateFactoryProxy'), deployer)) as CandidateFactoryProxy;

    if ( (await candidateFactoryProxy.implementation()) != getContractAddress(contractInfos, 'CandidateFactory')) {
      await (await candidateFactoryProxy.connect(deployer).upgradeTo(candidateFactoryLogic.address)).wait()
    }

    const candidateFactory = (await ethers.getContractAt("CandidateFactory", candidateFactoryProxy.address, deployer)) as CandidateFactory;
    // console.log('candidateFactory', candidateFactory.address)

    //===========================

    await (await daoCommittee.connect(daoCommitteeAdmin).setCandidateFactory(candidateFactoryProxy.address)).wait()
    await (await daoCommittee.connect(daoCommitteeAdmin).setSeigManager(seigManagerProxy.address)).wait()
    await (await daoCommittee.connect(daoCommitteeAdmin).setLayer2Registry(layer2RegistryProxy.address)).wait()

    const refactorCoinageSnapshot = (await ethers.getContractAt("RefactorCoinageSnapshot",  getContractAddress(contractInfos, 'RefactorCoinageSnapshot'), deployer)) as RefactorCoinageSnapshot;
    const coinageFactoryV2 = (await ethers.getContractAt("CoinageFactory", getContractAddress(contractInfos, 'CoinageFactory'), deployer)) as CoinageFactory;
    await (await coinageFactoryV2.connect(deployer).setAutoCoinageLogic(refactorCoinageSnapshot.address)).wait()

    // console.log('coinageFactoryV2', coinageFactoryV2.address)
    // console.log('refactorCoinageSnapshot', refactorCoinageSnapshot.address)

    //======= set v2 =============

    if ((await depositManagerV2.wton()) != WTONContract.address) {
      await (await depositManagerV2.connect(deployer).initialize (
        WTONContract.address,
        layer2RegistryProxy.address,
        seigManagerV2.address,
        globalWithdrawalDelay,
        DepositManager
      )).wait()
      console.log('depositManagerV2 initialized ')
    }

    if ((await seigManagerV2.wton()) != WTONContract.address) {
      await (await seigManagerV2.connect(deployer).initialize (
        TONContract.address,
        WTONContract.address,
        layer2RegistryProxy.address,
        depositManagerV2.address,
        seigManagerInfo.seigPerBlock,
        coinageFactoryV2.address,
        lastSeigBlock
      )).wait()
      // console.log('seigManagerV2 initialized ', seigManagerV2.address)
    }


    if ((await seigManagerV2.powerton()) != powerTonAddress) {
      await (await seigManagerV2.connect(deployer).setData (
        powerTonAddress,
        daoVaultAddress,
        seigManagerInfo.powerTONSeigRate,
        seigManagerInfo.daoSeigRate,
        seigManagerInfo.relativeSeigRate,
        seigManagerInfo.adjustCommissionDelay,
        seigManagerInfo.minimumAmount
      )).wait()
      // console.log('seigManagerV2 setData ')
    }

    if ((await layer2RegistryV2.isMinter(daoCommittee.address)) == false) {
      await (await layer2RegistryV2.connect(deployer).addMinter(
        daoCommittee.address
      )).wait()
    }

    if ((await seigManagerV2.isMinter(layer2RegistryV2.address)) == false) {
      await (await seigManagerV2.connect(deployer).addMinter(
        layer2RegistryV2.address
      )).wait()
    }

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
    if ((await WTONContract.isMinter(seigManagerV2.address)) == false) {
      await (await daoCommittee.connect(daoAdmin).setTargetAddMinter(WTONContract.address, seigManagerV2.address)).wait()
    }

    // for test :
    await (await TONContract.connect(daoAdmin).mint(deployer.address, ethers.utils.parseEther("10000"))).wait()
    await (await WTONContract.connect(daoAdmin).mint(deployer.address, ethers.utils.parseEther("10000"+"0".repeat(9)))).wait()

    //-- v2 배포후에 설정
    if ((await candidateFactory.depositManager()) != depositManagerV2.address) {
      await (await candidateFactory.connect(deployer).setAddress(
        depositManagerV2.address,
        DAOCommitteeProxy,
        candidateImp.address,
        TONContract.address,
        WTONContract.address
      )).wait()
      // console.log('candidateFactory setAddress ')
    }


    return {
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



export const newTonStakingV2Fixture = async function (): Promise<NewTonStakingV2Fixtures> {

  const DaoCommitteeAdminAddress = ""

  // goerli network
  const oldContractInfo = {
    TON: "0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00",
    WTON: "0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6",
    Layer2Registry: "0x6817e1c04748eae68EBFF13216280Df1ec15ba86",
    DepositManager: "0x0ad659558851f6ba8a8094614303F56d42f8f39A",
    CoinageFactory: "0x09207BdB146E41dadad015aB3d835f66498b0A0c",
    OldDAOVaultMock: "0xFD7C2c54a0A755a46793A91449806A4b14E3eEe8",
    SeigManager: "0x446ece59ef429B774Ff116432bbB123f1915D9E3",
    PowerTON: "0x031B5b13Df847eB10c14451EB2a354EfEE23Cc94",
    DAOVault: "0xb0B9c6076D46E333A8314ccC242992A625931C99",
    DAOAgendaManager: "0x0e1583da47cf641305eDD1e4C6dB6DD18e138a21",
    CandidateFactory: "0xd1c4fE0Ac211F8A41817c26D1801fd549D56E31e",
    DAOCommittee: "0xF7368a07653de908a8510e5d768c9C71b71cB2Ae",
    DAOCommitteeProxy: "0x3C5ffEe61A384B384ed38c0983429dcDb49843F6"
  }

  const newContractInfo = {
    "TestSeigManager": "0xAEaF225b558A29D27caA6BE21256fdb0002D6FF1",
    "DAOCommitteeExtend": "0x22479E215a927F152db09b59Ffd48B036eca92bf",
    "PowerTONUpgrade": "0x1F7CB23e4A0DE64CD837130691C100f00077B610",
    "SeigManager": "0x21913b743b533D0ff9AC4A90B61303a606C68BfA",
    "SeigManagerMigration" : "0x7F54aEAF368Cb189CEa7CE21Ce2227e0A33805E5",
    "SeigManagerProxy" : "0x50255c955d0F760C8512ff556453AEe6502ef47f",
    "DepositManager" : "0x4E777711dE705DfcBDf7d93592a27088Bfd1abA1",
    "DepositManagerForMigration" :"0x2b72a681C71Bc189F232fB783532cB71d3e7612B",
    "DepositManagerProxy":"0x0e1EF78939F9d3340e63A7a1077d50999CC6B64f",
    "Layer2Registry" : "0x9ff632422d671ceaC8BdD12C98E0f7FB6ef3B44a",
    "Layer2RegistryProxy" :  "0xFF2258eAa1c82d09a9ed0198116d9557c34104Fa",
    "Candidate": "0x23279597a87381e85c841eF249020e7FD915E18a",
    "CandidateFactory" :"0x41C8622c15e6e164103FA30De23F1Aa43F6Db3E0",
    "CandidateFactoryProxy": "0xF7Fea9ddDc88b1E6D6507F2507438FB2e4Aa2D67",
    "RefactorCoinageSnapshot":"0xC747915eA0CDc3587F931D2d99c730d2FB628A0f",
    "CoinageFactory" : "0x1c2b22d20dE2fEEB57AA6D0CC0e406dC8328236E"
  }


  /*
  const newContractInfo = {
    "TestSeigManager": "0x8F6265eDe57f0a324Be02dC817F2B357779bd2c7",
    "DAOCommitteeExtend": "0xfE4bA125422BAbf58Ef12fd7F099517dc4A928F5",
    "PowerTONUpgrade": "0x543F7eB26906DAceB6a02B1a1Bc0BaFCEFaC223C",
    "SeigManager": "0xa790Bb30F80e3b9b38Efaa8fE47CE53A77A7C1CF",
    "SeigManagerMigration" : "0x19914364cc6f53aD0984b9F959331717C40495ad",
    "SeigManagerProxy" : "0x8829Cb37CbbF32404B372113F9Fc3F6cd965c474",
    "DepositManager" : "0xd773D576c4B69509f6273e35BB099Ccbf0f76293",
    "DepositManagerForMigration" :"0x143B413EeCCAD2edAe4C624a256ffd383Aa5B4dE",
    "DepositManagerProxy":"0xA0458d8af8a25A18959b9cB607c33Bc4973f7849",
    "Layer2Registry" : "0x677B3fd2472E189F7E729b2716BF230f0cbD251E",
    "Layer2RegistryProxy" :  "0x3619154232f205b1bF657e2e9905D52B9957eDfd",
    "Candidate": "0xC903C31D5257eEa1FFc17275C092442162E7B218",
    "CandidateFactory" :"0x5D610D9B1d39916A9dA2D4b7412B14f99C306fF4",
    "CandidateFactoryProxy": "0x38Ca0a85bB4aCD6fE7647642bA72D2B0e48F0a37",
    "RefactorCoinageSnapshot":"0x8616B4409Eb47737f92479fc25C9B88Bab13EE5b",
    "CoinageFactory" : "0x42634D16b4c7Bb9A448eA14170416C917FeE8B9E"
  }
  */
  console.log('newTonStakingV2Fixture');
  const [deployer, addr1, addr2 ] = await ethers.getSigners();

  const contractJson = await jsonFixtures()
  console.log('DepositManager', oldContractInfo.DepositManager);

  //-------------------------------
  const depositManagerV1 = new ethers.Contract( oldContractInfo.DepositManager, contractJson.DepositManager.abi, deployer)
  const seigManagerV1 = new ethers.Contract(oldContractInfo.SeigManager, contractJson.SeigManager.abi,  deployer)
  const layer2RegistryV1 = new ethers.Contract( oldContractInfo.Layer2Registry,contractJson.L2Registry.abi, deployer)
  const coinageFactoryV1= new ethers.Contract(oldContractInfo.CoinageFactory, contractJson.CoinageFactory.abi,  deployer)
  const TONContract = new ethers.Contract(oldContractInfo.TON, contractJson.TON.abi,  deployer)
  const WTONContract = new ethers.Contract(oldContractInfo.WTON,  contractJson.WTON.abi, deployer)
  const candidateFactoryV1 = new ethers.Contract(oldContractInfo.CandidateFactory,  contractJson.CandidateFactory.abi, deployer)
  const daoCommitteeProxy = new ethers.Contract(oldContractInfo.DAOCommitteeProxy, contractJson.DAOCommitteeProxy.abi, deployer)
  const daoAgendaManager = new ethers.Contract(oldContractInfo.DAOAgendaManager,  contractJson.DAOAgendaManager.abi, deployer)
  const powerTonProxy= new ethers.Contract(oldContractInfo.PowerTON,  contractJson.PowerTON.abi, deployer)
  console.log('DAOCommitteeProxy', oldContractInfo.DAOCommitteeProxy)

  const daoCommittee = (await ethers.getContractAt("DAOCommitteeExtend", oldContractInfo.DAOCommitteeProxy, deployer)) as DAOCommitteeExtend;
  console.log('daoCommittee', daoCommittee.address)

  const powerTON = (await ethers.getContractAt("PowerTONUpgrade", powerTonProxy.address, deployer)) as PowerTONUpgrade;
  console.log('powerTON', powerTON.address)

  //----------- v2 배포
  const depositManagerV2 = (await ethers.getContractAt("DepositManager", newContractInfo.DepositManagerProxy, deployer)) as DepositManager;
  const seigManagerV2 = (await ethers.getContractAt("SeigManager", newContractInfo.SeigManagerProxy, deployer)) as SeigManager;
  const layer2RegistryV2 = (await ethers.getContractAt("Layer2Registry", newContractInfo.Layer2RegistryProxy, deployer)) as Layer2Registry;


  //==========================
  const adminAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
  await hre.network.provider.send("hardhat_impersonateAccount", [
    adminAddress,
  ]);
  await hre.network.provider.send("hardhat_setBalance", [
    adminAddress,
    "0x10000000000000000000000000",
  ]);
  const admin = await hre.ethers.getSigner(adminAddress);

  // for test :
  await (await TONContract.connect(admin).mint(deployer.address, ethers.utils.parseEther("10000"))).wait()
  await (await WTONContract.connect(admin).mint(deployer.address, ethers.utils.parseEther("10000"+"0".repeat(9)))).wait()

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
    daoCommittee: daoCommittee,
    depositManagerV2: depositManagerV2 ,
    seigManagerV2: seigManagerV2 ,
    layer2RegistryV2: layer2RegistryV2 ,
    powerTON: powerTON,
    powerTonAddress: oldContractInfo.PowerTON
  }
}

