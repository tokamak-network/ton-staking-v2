import hre from 'hardhat'
import { ethers , deployments, getNamedAccounts, network } from 'hardhat'

import { readContracts, deployedContracts } from "../common_func"

import {  Wallet, Signer, Contract, BigNumber } from 'ethers'

import { TonStakingV2Fixtures, TonStakingV2NoSnapshotFixtures, JSONFixture, NewTonStakingV2Fixtures } from './fixtureInterfaces'

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


export const newTonStakingV2MainnetFixture = async function (): Promise<NewTonStakingV2Fixtures> {

  const DaoCommitteeAdminAddress = ""

  // mainnet network
  const oldContractInfo = {
    TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
    WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
    Layer2Registry: "0x0b3E174A2170083e770D5d4Cf56774D221b7063e",
    DepositManager: "0x56E465f654393fa48f007Ed7346105c7195CEe43",
    CoinageFactory: "0x5b40841eeCfB429452AB25216Afc1e1650C07747",
    OldDAOVaultMock: "",
    SeigManager: "0x710936500aC59e8551331871Cbad3D33d5e0D909",
    PowerTON: "0x970298189050aBd4dc4F119ccae14ee145ad9371",
    DAOVault: "0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303",
    DAOAgendaManager: "0xcD4421d082752f363E1687544a09d5112cD4f484",
    CandidateFactory: "0xE6713aF11aDB0cFD3C60e15b23E43f5548C32942",
    DAOCommittee: "0xd1A3fDDCCD09ceBcFCc7845dDba666B7B8e6D1fb",
    DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
  }

  // 새로 배포된 컨트랙
  const newContractInfo = {
    "TestSeigManager": "0xbe8808548c8e1179435448fB621EC5A7A60c178D",
    "DAOCommitteeExtend": "0x5AB2B7df0529C28Bf2895CeD50F4a2999E238EDD",
    "PowerTONUpgrade": "0x0950245941D6a5504c54D4b8c36bE71B066FABF2",
    "SeigManager": "0xf158ac85B6d46ccA482675aA2D437c2B438FBEA4",
    "SeigManagerMigration" : "0x580Fc28CBd9982b446BD9eC012158d2c40f896dC",
    "SeigManagerProxy" : "0xb2d344984f92130AF8925eD283018d21673Bd17d",
    "DepositManager" : "0xD95b5FDC4Aee54f30F864fAF2642DCCB413689c5",
    "DepositManagerForMigration" :"0x2aD53C5501F9688dE51812c9DC3B05B916F81359",
    "DepositManagerProxy":"0x4049A8842536Ff2fA2a1D23335b22710C2f0f1cd",
    "Layer2Registry" : "0x1F5ec567655f2eA2DDeAcBa73411ec24AB765bf2",
    "Layer2RegistryProxy" :  "0x97a713Fa14e863610555a9f737060b2f409344B9",
    "Candidate": "0x69CC158F7E0103880aBC4f7d27daC22C1B62fFe5",
    "CandidateFactory" :"0xE4faf76e8EDDb2a4EC05f5F009a9105cB0f309ec",
    "CandidateFactoryProxy": "0x68d31C2d5B37741d8a06D72A43F999B53c53aDFa",
    "RefactorCoinageSnapshot":"0x8b8B9a683d7Fa4E72B84415C3b5674a280832B46",
    "CoinageFactory" : "0x2bf74c8Ae28DE991A0f88232C0168eAB60B0bbbb"
  }

  console.log('newTonStakingV2Fixture');
  const [deployer, addr1, addr2 ] = await ethers.getSigners();

  console.log('deployer', deployer.address);

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
  console.log('DepositManagerProxy', depositManagerV2.address)

  //-- 테스트 전에 세그매니저와 디파짓 매니저 로직 변경

  const depositManagerV2Proxy = (await ethers.getContractAt("DepositManagerProxy", newContractInfo.DepositManagerProxy, deployer)) as DepositManagerProxy;
  const seigManagerV2Proxy = (await ethers.getContractAt("SeigManagerProxy", newContractInfo.SeigManagerProxy, deployer)) as SeigManagerProxy;
  let imp1 = await depositManagerV2Proxy.implementation()
  if(imp1 != newContractInfo.DepositManager) {
    await (await depositManagerV2Proxy.connect(deployer).upgradeTo(newContractInfo.DepositManager)).wait()
  }
  let imp2 = await seigManagerV2Proxy.implementation()
  if(imp2 != newContractInfo.SeigManager) {
    await (await seigManagerV2Proxy.connect(deployer).upgradeTo(newContractInfo.SeigManager)).wait()
  }

  //==========================
  // const adminAddress =  "0x710936500ac59e8551331871cbad3d33d5e0d909"
  // await hre.network.provider.send("hardhat_impersonateAccount", [
  //   adminAddress,
  // ]);
  // await hre.network.provider.send("hardhat_setBalance", [
  //   adminAddress,
  //   "0x10000000000000000000000000",
  // ]);
  // const admin = await hre.ethers.getSigner(adminAddress);


  // await hre.network.provider.send("hardhat_impersonateAccount", [
  //   oldContractInfo.DAOCommitteeProxy,
  // ]);
  // await hre.network.provider.send("hardhat_setBalance", [
  //   oldContractInfo.DAOCommitteeProxy,
  //   "0x10000000000000000000000000",
  // ]);
  // const testadmin = await hre.ethers.getSigner(oldContractInfo.DAOCommitteeProxy);

  // // for test :
  // await (await TONContract.connect(testadmin).mint(deployer.address, ethers.utils.parseEther("10000"))).wait()
  // console.log('TON')

  // await (await WTONContract.connect(admin).mint(deployer.address, ethers.utils.parseEther("10000"+"0".repeat(9)))).wait()
  // console.log('WTONContract')
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