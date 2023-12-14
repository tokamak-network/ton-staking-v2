
import { ethers } from 'hardhat'
import {  Wallet, Signer, Contract } from 'ethers'

import { DepositManager } from "../../typechain-types/contracts/stake/managers/DepositManager.sol"
import { DepositManagerProxy } from "../../typechain-types/contracts/stake/managers/DepositManagerProxy"
import { SeigManager } from "../../typechain-types/contracts/stake/managers/SeigManager.sol"
import { SeigManager1 } from "../../typechain-types/contracts/stake/managers/SeigManager1.sol"
import { SeigManagerProxy } from "../../typechain-types/contracts/stake/managers/SeigManagerProxy"
import { Layer2Registry } from "../../typechain-types/contracts/stake/Layer2Registry.sol"
import { Layer2RegistryProxy } from "../../typechain-types/contracts/stake/Layer2RegistryProxy"
import { CoinageFactory } from "../../typechain-types/contracts/stake/factory/CoinageFactory.sol"
import { RefactorCoinageSnapshot } from "../../typechain-types/contracts/stake/tokens/RefactorCoinageSnapshot.sol"
import { Candidate } from "../../typechain-types/contracts/dao/Candidate.sol"
import { CandidateProxy } from "../../typechain-types/contracts/dao/CandidateProxy"
import { DAOCommitteeExtend } from "../../typechain-types/contracts/dao/DAOCommitteeExtend.sol"

import { CandidateFactory } from "../../typechain-types/contracts/dao/factory/CandidateFactory.sol"
import { CandidateFactoryProxy } from "../../typechain-types/contracts/dao/factory/CandidateFactoryProxy"
import { PowerTONUpgrade } from "../../typechain-types/contracts/stake/powerton/PowerTONUpgrade"
import { AutoRefactorCoinage } from "../../typechain-types/contracts/stake/tokens/AutoRefactorCoinage"
import { AutoRefactorCoinageFactory } from "../../typechain-types/contracts/stake/factory/AutoRefactorCoinageFactory.sol"

import { L1StakedTonToL2 } from "../../typechain-types/contracts/L1/L1StakedTonToL2.sol"
import { L1StakedTonInL2 } from "../../typechain-types/contracts/L2/L1StakedTonInL2.sol"
import { L2SeigManager } from "../../typechain-types/contracts/L2/L2SeigManager.sol"
import { Lib_AddressManager } from "../../typechain-types/contracts/test/Lib_AddressManager"
import { MockL1Messenger } from "../../typechain-types/contracts/test/MockL1Messenger.sol"
import { MockL2Messenger } from "../../typechain-types/contracts/test/MockL2Messenger"


interface TonStakingV2Fixtures  {
    deployer: Signer,
    addr1: Signer,
    addr2: Signer,
    depositManagerV1: any ,
    seigManagerV1: any ,
    layer2RegistryV1: any ,
    coinageFactoryV1: any ,
    TON: any ,
    WTON: any ,
    daoCommitteeProxy: any ,
    daoAgendaManager: any,
    candidateFactoryV1: any ,
    powerTonProxy: any ,
    daoCommitteeExtend: DAOCommitteeExtend,
    daoCommitteeAdmin: Signer,
    daoCommittee: DAOCommitteeExtend,
    depositManagerV2: DepositManager ,
    depositManagerProxy: DepositManagerProxy,
    seigManagerV2: SeigManager ,
    seigManagerProxy: SeigManagerProxy,
    layer2RegistryV2: Layer2Registry ,
    layer2RegistryProxy: Layer2RegistryProxy,
    candidateFactoryV2: CandidateFactory ,
    candidateFactoryProxy: CandidateFactoryProxy ,
    candidateImp: Candidate ,
    refactorCoinageSnapshot: RefactorCoinageSnapshot,
    coinageFactoryV2: CoinageFactory,
    powerTonAddress: string,
    daoVaultAddress: string,
    level19Address: string,
    tokamakAddress: string,
    level19Admin: string,
    tokamakAdmin: string,
    daoAdmin: Signer,
    powerTON: PowerTONUpgrade
}

interface TonStakingV2NoSnapshotFixtures  {
    deployer: Signer,
    addr1: Signer,
    addr2: Signer,
    depositManagerV1: any ,
    seigManagerV1: any ,
    layer2RegistryV1: any ,
    coinageFactoryV1: any ,
    TON: any ,
    WTON: any ,
    daoCommitteeProxy: any ,
    daoAgendaManager: any,
    candidateFactoryV1: any ,
    powerTonProxy: any ,
    daoCommitteeExtend: DAOCommitteeExtend,
    daoCommitteeAdmin: Signer,
    daoCommittee: DAOCommitteeExtend,
    depositManagerV2: DepositManager ,
    depositManagerProxy: DepositManagerProxy,
    seigManagerV2: SeigManager ,
    seigManagerProxy: SeigManagerProxy,
    layer2RegistryV2: Layer2Registry ,
    layer2RegistryProxy: Layer2RegistryProxy,
    candidateFactoryV2: CandidateFactory ,
    candidateFactoryProxy: CandidateFactoryProxy ,
    candidateImp: Candidate ,
    autoRefactorCoinage: AutoRefactorCoinage,
    coinageFactoryV2: AutoRefactorCoinageFactory,
    powerTonAddress: string,
    daoVaultAddress: string,
    level19Address: string,
    tokamakAddress: string,
    level19Admin: string,
    tokamakAdmin: string,
    daoAdmin: Signer,
    powerTON: PowerTONUpgrade
}

interface JSONFixture {
    DepositManager: any ,
    SeigManager: any ,
    L2Registry: any ,
    CoinageFactory: any ,
    TON: any ,
    WTON: any ,
    TOS: any ,
    DAOCommitteeProxy: any ,
    CandidateFactory: any ,
    DAOAgendaManager: any ,
    RefactorCoinageSnapshot: any,
    Candidate: any,
    PowerTON: any
}

interface NewTonStakingV2Fixtures  {
    deployer: Signer,
    addr1: Signer,
    addr2: Signer,
    depositManagerV1: any ,
    seigManagerV1: any ,
    layer2RegistryV1: any ,
    coinageFactoryV1: any ,
    TON: any ,
    WTON: any ,
    daoCommitteeProxy: any ,
    daoAgendaManager: any,
    candidateFactoryV1: any ,
    powerTonProxy: any ,
    daoCommittee: DAOCommitteeExtend,
    depositManagerV2: DepositManager ,
    seigManagerV2: SeigManager ,
    layer2RegistryV2: Layer2Registry ,
    powerTON: PowerTONUpgrade,
    powerTonAddress : string
}

interface StakedTonSyncFixture  {
    deployer: Signer,
    addr1: Signer,
    addr2: Signer,
    daoAdmin: Signer,
    TON: any ,
    WTON: any ,
    depositManager: DepositManager,
    seigManagerV1: SeigManager,
    seigManagerV2Imp: SeigManager1,
    l2Registry: Layer2Registry,
    l1StakedTonToL2: L1StakedTonToL2,
    l1StakedTonInL2: L1StakedTonInL2,
    l2SeigManager: L2SeigManager,
    addressManager: Lib_AddressManager,
    l1Messenger: MockL1Messenger,
    l2Messenger: MockL2Messenger
}


export {
    TonStakingV2Fixtures,
    TonStakingV2NoSnapshotFixtures,
    NewTonStakingV2Fixtures,
    JSONFixture,
    StakedTonSyncFixture
}
