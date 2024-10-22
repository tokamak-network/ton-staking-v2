// import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import "@nomicfoundation/hardhat-chai-matchers";
// import "hardhat-deploy/src/type-extensions";
// import "@nomiclabs/hardhat-ethers";

import "hardhat-gas-reporter";
import dotenv from "dotenv" ;
import { HardhatUserConfig } from "hardhat/types";
import "hardhat-deploy";
dotenv.config();
import { task, types } from 'hardhat/config'
import "./tasks";

const config: HardhatUserConfig = {
  namedAccounts: {
    deployer: 0,
    addr1: 1,
    addr2: 2,
    SeigManager: {
      default: 3,
      mainnet: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      goerli: '0x446ece59ef429B774Ff116432bbB123f1915D9E3',
      hardhat: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      local: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      sepolia: '0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7'
    },
    DepositManager: {
      default: 4,
      mainnet: '0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E',
      goerli: '0x0ad659558851f6ba8a8094614303F56d42f8f39A',
      hardhat: '0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E',
      local: '0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E',
      sepolia: '0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F'
    },
    L2Registry: {
      default: 5,
      mainnet: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      goerli: '0x6817e1c04748eae68EBFF13216280Df1ec15ba86',
      hardhat: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      local: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      sepolia: '0xA0a9576b437E52114aDA8b0BC4149F2F5c604581'
    },
    CoinageFactory: {
      default: 6,
      mainnet: '0xe8fae91b80dd515c3d8b9fc02cb5b2ecfddabf43',
      goerli: '0x09207BdB146E41dadad015aB3d835f66498b0A0c',
      hardhat: '0xe8fae91b80dd515c3d8b9fc02cb5b2ecfddabf43',
      local: '0xe8fae91b80dd515c3d8b9fc02cb5b2ecfddabf43',
      sepolia: '0x93258413Ef2998572AB4B269b5DCb963dD35D440'
    },
    TON: {
      default: 7,
      mainnet: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
      goerli: '0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00',
      hardhat: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
      local: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
      sepolia: '0xa30fe40285b8f5c0457dbc3b7c8a280373c40044'
    },
    WTON: {
      default: 8,
      mainnet: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
      goerli: '0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6',
      hardhat: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
      local: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
      sepolia: '0x79e0d92670106c85e9067b56b8f674340dca0bbd'
    },
    TOS: {
      default: 9,
      mainnet: '0x409c4D8cd5d2924b9bc5509230d16a61289c8153',
      goerli: '0x67F3bE272b1913602B191B3A68F7C238A2D81Bb9',
      hardhat: '0x409c4D8cd5d2924b9bc5509230d16a61289c8153',
      local: '0x409c4D8cd5d2924b9bc5509230d16a61289c8153',
      sepolia: '0xff3ef745d9878afe5934ff0b130868afddbc58e8'
    },
    DAOCommitteeProxy: {
      default: 10,
      mainnet: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
      goerli: '0x3C5ffEe61A384B384ed38c0983429dcDb49843F6',
      hardhat: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
      local: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
      sepolia: '0xA2101482b28E3D99ff6ced517bA41EFf4971a386'
    },
    CandidateFactory: {
      default: 11,
      mainnet: '0x9fc7100a16407ee24a79c834a56e6eca555a5d7c',
      goerli: '0xd1c4fE0Ac211F8A41817c26D1801fd549D56E31e',
      hardhat: '0x9fc7100a16407ee24a79c834a56e6eca555a5d7c',
      local: '0x9fc7100a16407ee24a79c834a56e6eca555a5d7c',
      sepolia: '0x04e3C2B720FB8896A7f9Ea59DdcA85fD45189C7f'
    },
    DAOAgendaManager: {
      default: 12,
      mainnet: '0xcD4421d082752f363E1687544a09d5112cD4f484',
      goerli: '0x0e1583da47cf641305eDD1e4C6dB6DD18e138a21',
      hardhat: '0xcD4421d082752f363E1687544a09d5112cD4f484',
      local: '0xcD4421d082752f363E1687544a09d5112cD4f484',
      sepolia: '0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08'
    },
    AutoCoinageSnapshot2: {
      default: 13,
      mainnet: '0x85Ca9f611C363065252EA9462c90743922767b55',
      goerli: '',
      hardhat: '0x85Ca9f611C363065252EA9462c90743922767b55',
      local: '0x85Ca9f611C363065252EA9462c90743922767b55',
      sepolia: ''
    },
    DaoCommitteeAdminAddress: {
      default: 14,
      mainnet: '0xb4983da083a5118c903910db4f5a480b1d9f3687',
      goerli: '',
      hardhat: '0xb4983da083a5118c903910db4f5a480b1d9f3687',
      local: '0xb4983da083a5118c903910db4f5a480b1d9f3687',
      sepolia: '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'
    },
    powerTonAddress: {
      default: 15,
      mainnet: '0x970298189050aBd4dc4F119ccae14ee145ad9371',
      goerli: '',
      hardhat: '0x970298189050aBd4dc4F119ccae14ee145ad9371',
      local: '0x970298189050aBd4dc4F119ccae14ee145ad9371',
      sepolia: '0xbe16830EeD019227892938Ae13C54Ec218772f48'
    },
    daoVaultAddress: {
      default: 16,
      mainnet: '0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303',
      goerli: '',
      hardhat: '0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303',
      local: '0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303',
      sepolia: '0xB9F6c9E75418D7E5a536ADe08f0218196BB3eBa4'
    },
    level19Address: {
      default: 17,
      mainnet: '0x42ccf0769e87cb2952634f607df1c7d62e0bbc52',
      goerli: '',
      hardhat: '0x42ccf0769e87cb2952634f607df1c7d62e0bbc52',
      local: '0x42ccf0769e87cb2952634f607df1c7d62e0bbc52',
      sepolia: ''
    },
    level19Admin: {
      default: 18,
      mainnet: '0xd1820b18be7f6429f1f44104e4e15d16fb199a43',
      goerli: '',
      hardhat: '0xd1820b18be7f6429f1f44104e4e15d16fb199a43',
      local: '0xd1820b18be7f6429f1f44104e4e15d16fb199a43',
      sepolia: ''
    },
    tokamakAddress: {
      default: 19,
      mainnet: '0x576c7a48fcef1c70db632bb1504d9a5c0d0190d3',
      goerli: '',
      hardhat: '0x576c7a48fcef1c70db632bb1504d9a5c0d0190d3',
      local: '0x576c7a48fcef1c70db632bb1504d9a5c0d0190d3',
      sepolia: ''
    },
    tokamakAdmin: {
      default: 20,
      mainnet: '0xEA8e2eC08dCf4971bdcdfFFe21439995378B44F3',
      goerli: '',
      hardhat: '0xEA8e2eC08dCf4971bdcdfFFe21439995378B44F3',
      local: '0xEA8e2eC08dCf4971bdcdfFFe21439995378B44F3',
      sepolia: ''
    },
    powerTonAdminAddress: {
      default: 21,
      mainnet: '0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1',
      goerli: '',
      hardhat: '0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1',
      local: '0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1',
      sepolia: '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'
    },
    SeigManagerProxy: {
      default: 22,
      mainnet: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      goerli: '',
      hardhat: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      local: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      sepolia: '0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7'
    },
    DepositManagerProxy: {
      default: 23,
      mainnet: '0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e',
      goerli: '',
      hardhat: '0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e',
      local: '0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e',
      sepolia: '0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F'
    },
    Layer2RegistryProxy: {
      default: 23,
      mainnet: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      goerli: '',
      hardhat: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      local: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      sepolia: '0xA0a9576b437E52114aDA8b0BC4149F2F5c604581'
    },
    // tonAdminAddress: {
    //   default: 10,
    //   mainnet: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
    //   goerli: '',
    //   hardhat: '',
    // },
    l1MessengerAddress: {
      default: 22,
      mainnet: '0xfd76ef26315Ea36136dC40Aeafb5D276d37944AE',
      goerli: '0x2878373BA3Be0Ef2a93Ba5b3F7210D76cb222e63',
      hardhat: '0xfd76ef26315Ea36136dC40Aeafb5D276d37944AE',
      local: '0xfd76ef26315Ea36136dC40Aeafb5D276d37944AE',
      sepolia: '0xc123047238e8f4bFB7Ad849cA4364b721B5ABD8A'
    },
    l1BridgeAddress: {
      default: 23,
      mainnet: '0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD',
      goerli: '0x7377F3D0F64d7a54Cf367193eb74a052ff8578FD',
      hardhat: '0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD',
      local: '0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD',
      sepolia: '0x1F032B938125f9bE411801fb127785430E7b3971'
    },
    l1AddressManagerAddress: {
      default: 24,
      mainnet: '0xeDf6C92fA72Fa6015B15C9821ada145a16c85571',
      goerli: '0xEFa07e4263D511fC3a7476772e2392efFb1BDb92',
      hardhat: '0xeDf6C92fA72Fa6015B15C9821ada145a16c85571',
      local: '0xeDf6C92fA72Fa6015B15C9821ada145a16c85571',
      sepolia: '0x79a53E72e9CcfAe63B0fB9A4edb66C7563d74Dc3'
    },
    l2TokenFactoryAddress: {
      default: 25,
      mainnet: '',
      goerli: '',
      hardhat: '',
      local: '',
      sepolia: ''
    },
    l2TonAddress: {
      default: 26,
      mainnet: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2',
      goerli: '0xFa956eB0c4b3E692aD5a6B2f08170aDE55999ACa',
      hardhat: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2',
      local: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2',
      sepolia: '0x7c6b91d9be155a6db01f749217d76ff02a7227f2'
    },
    swapProxy: {
      default: 27,
      mainnet: '0x30e65B3A6e6868F044944Aa0e9C5d52F8dcb138d',
      goerli: '',
      hardhat: '0x30e65B3A6e6868F044944Aa0e9C5d52F8dcb138d',
      local: '0x30e65B3A6e6868F044944Aa0e9C5d52F8dcb138d',
      sepolia: '0x690f994b82f001059e24d79292c3c476854b767a'
    },
    DAOCommitteeOwner : {
      default: 28,
      mainnet: '0xe070ffd0e25801392108076ed5291fa9524c3f44',
      goerli: '',
      hardhat: '0xe070ffd0e25801392108076ed5291fa9524c3f44',
      local: '0xe070ffd0e25801392108076ed5291fa9524c3f44',
      sepolia: '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'
    },
    titanL1StandardBridge : {
      default: 29,
      mainnet: '0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD',
      goerli: '',
      hardhat: '0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD',
      local: '0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD',
      sepolia: '0x1F032B938125f9bE411801fb127785430E7b3971'
    },
    titanL1CrossDomainMessenger : {
      default: 30,
      mainnet: '0xfd76ef26315Ea36136dC40Aeafb5D276d37944AE',
      goerli: '',
      hardhat: '0xfd76ef26315Ea36136dC40Aeafb5D276d37944AE',
      local: '0xfd76ef26315Ea36136dC40Aeafb5D276d37944AE',
      sepolia: '0xc123047238e8f4bFB7Ad849cA4364b721B5ABD8A'
    },
    titanL1ERC721Bridge: {
      default: 31,
      mainnet: '0x0000000000000000000000000000000000000000',
      goerli: '',
      hardhat: '0x0000000000000000000000000000000000000000',
      local: '0x0000000000000000000000000000000000000000',
      sepolia: '0x0000000000000000000000000000000000000000'
    },
    titanL2OutputOracle: {
      default: 32,
      mainnet: '0x0000000000000000000000000000000000000000',
      goerli: '',
      hardhat: '0x0000000000000000000000000000000000000000',
      local: '0x0000000000000000000000000000000000000000',
      sepolia: '0x0000000000000000000000000000000000000000'
    },
    titanOptimismPortal: {
      default: 33,
      mainnet: '0x0000000000000000000000000000000000000000',
      goerli: '',
      hardhat: '0x0000000000000000000000000000000000000000',
      local: '0x0000000000000000000000000000000000000000',
      sepolia: '0x0000000000000000000000000000000000000000'
    },
    titanOptimismMintableERC20Factory: {
      default: 34,
      mainnet: '0x4200000000000000000000000000000000000012',
      goerli: '',
      hardhat: '0x4200000000000000000000000000000000000012',
      local: '0x4200000000000000000000000000000000000012',
      sepolia: '0x4200000000000000000000000000000000000012'
    },
    thanosL1StandardBridge : {
      default: 35,
      mainnet: '0x0000000000000000000000000000000000000000',
      goerli: '',
      hardhat: '0x5D2Ed95c0230Bd53E336f12fA9123847768B2B3E',
      local: '0x5D2Ed95c0230Bd53E336f12fA9123847768B2B3E',
      sepolia: '0x5D2Ed95c0230Bd53E336f12fA9123847768B2B3E'
    },
    thanosL1CrossDomainMessenger : {
      default: 36,
      mainnet: '0x0000000000000000000000000000000000000000',
      goerli: '',
      hardhat: '0x8ca593C92446104B4DA968786735dbd503886ed7',
      local: '0x8ca593C92446104B4DA968786735dbd503886ed7',
      sepolia: '0x8ca593C92446104B4DA968786735dbd503886ed7'
    },
    thanosL1ERC721Bridge: {
      default: 37,
      mainnet: '0x0000000000000000000000000000000000000000',
      goerli: '',
      hardhat: '0x29677290236F7950B96a30383D76AD363C08f51A',
      local: '0x29677290236F7950B96a30383D76AD363C08f51A',
      sepolia: '0x29677290236F7950B96a30383D76AD363C08f51A'
    },
    thanosL2OutputOracle: {
      default: 38,
      mainnet: '0x0000000000000000000000000000000000000000',
      goerli: '',
      hardhat: '0xfa565a84075091044FC891e3f73E26A014A4fd8c',
      local: '0xfa565a84075091044FC891e3f73E26A014A4fd8c',
      sepolia: '0xfa565a84075091044FC891e3f73E26A014A4fd8c'
    },
    thanosOptimismPortal: {
      default: 39,
      mainnet: '0x0000000000000000000000000000000000000000',
      goerli: '',
      hardhat: '0x54A01163474FCD8a781455f09Ff0910e7e31B772',
      local: '0x54A01163474FCD8a781455f09Ff0910e7e31B772',
      sepolia: '0x54A01163474FCD8a781455f09Ff0910e7e31B772'
    },
    thanosOptimismMintableERC20Factory: {
      default: 40,
      mainnet: '0x4200000000000000000000000000000000000012',
      goerli: '0x4200000000000000000000000000000000000012',
      hardhat: '0x4200000000000000000000000000000000000012',
      local: '0x4200000000000000000000000000000000000012',
      sepolia: '0x1b624b7037C7d958Fb3fe22B12307E5295530C27'
    },
    thanosSystemConfig: {
      default: 41,
      mainnet: '0x0000000000000000000000000000000000000000',
      goerli: '0x0000000000000000000000000000000000000000',
      hardhat: '0xf8FCFDbdb7C4E734D035A5681Fd1fe08ec85e387',
      local: '0xf8FCFDbdb7C4E734D035A5681Fd1fe08ec85e387',
      sepolia: '0xf8FCFDbdb7C4E734D035A5681Fd1fe08ec85e387'
    },
    titanL2TON: {
      default: 42,
      mainnet: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2',
      goerli: '',
      hardhat: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2',
      local: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2',
      sepolia: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2'
    },
    thanosL2TON: {
      default: 42,
      mainnet: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2',
      goerli: '',
      hardhat: '0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000',
      local: '0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000',
      sepolia: '0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000'
    },
    daoMember1: {
      default: 43,
      mainnet: '0x0f42d1c40b95df7a1478639918fc358b4af5298d',
      goerli: '',
      hardhat: '0x0f42d1c40b95df7a1478639918fc358b4af5298d',
      local: '0x0f42d1c40b95df7a1478639918fc358b4af5298d',
      sepolia: '0x0f42d1c40b95df7a1478639918fc358b4af5298d'
    },
    daoMember2: {
      default: 44,
      mainnet: '0xf3b17fdb808c7d0df9acd24da34700ce069007df',
      goerli: '',
      hardhat: '0xf3b17fdb808c7d0df9acd24da34700ce069007df',
      local: '0xf3b17fdb808c7d0df9acd24da34700ce069007df',
      sepolia: '0xf3b17fdb808c7d0df9acd24da34700ce069007df'
    },
    daoMember3: {
      default: 45,
      mainnet: '0x06d34f65869ec94b3ba8c0e08bceb532f65005e2',
      goerli: '',
      hardhat: '0x06d34f65869ec94b3ba8c0e08bceb532f65005e2',
      local: '0x42adfaae7db56b294225ddcfebef48b337b34b23',
      sepolia: '0x06d34f65869ec94b3ba8c0e08bceb532f65005e2'
    }
  },
  networks: {
    hardhat: {
      forking: {
        url: `${process.env.ETH_NODE_URI_MAINNET}`,
        // url: `${process.env.ETH_NODE_URI_sepolia}`,
        // npx hardhat test test/layer2/units/3.Layer2Manager.sepolia.test.ts
        // blockNumber: 5859537,
        // blockNumber: 6042730
        // npx hardhat test test/layer2/units/3.Layer2Manager.sepolia.test.ts
        // blockNumber: 6042730
        // npx hardhat test test/layer2/sepolia_test/0.registerLayer2Candidate.ts
        // blockNumber: 5860655,
        // npx hardhat test test/layer2/sepolia_test/2.withdrawAndDepositL2.ts
        // blockNumber: 5870490,
        // npx hardhat test test/layer2/sepolia_test/1.updateSeigs.ts
        // blockNumber: 5874556,
        // npx hardhat test test/layer2/sepolia_test/3.updateSeigsAndClaim.ts
        // blockNumber: 5892966,
        // blockNumber: 6676283,
        // url: `${process.env.ETH_NODE_URI_MAINNET}`,
        // blockNumber: 18811511
        // blockNumber:
        // test registerCandidateAddOn
        // blockNumber: 6797943
      },
      // allowUnlimitedContractSize: false,
      // deploy: ['deploy-layer2'],
      deploy: ['deploy-staking-v2.5-mainnet'],
    },
    local: {
      url: `${process.env.ETH_NODE_URI_localhost}`,
      timeout: 800000,
      accounts: [`${process.env.PRIVATE_KEY}`],
      // deploy: ['deploy-migration']
    },
    mainnet: {
      url: `${process.env.ETH_NODE_URI_MAINNET}`,
      accounts: [`${process.env.AGENDA_KEY}`],
      gasPrice: 8000000000,
      // gasPrice: 40000000000, //40 Gwei
      // deploy: ['deploy']
    },
    goerli: {
      url: `${process.env.ETH_NODE_URI_goerli}`,
      accounts: [`${process.env.PRIVATE_KEY}`],
      chainId: 5,
      // deploy: ['deploy-seig-manager-v1']
    },
    titan: {
      url: `${process.env.ETH_NODE_URI_TITAN}`,
      accounts: [`${process.env.PRIVATE_KEY}`],
      chainId: 55004,
      // gasPrice: 1000000,
      // deploy: ['deploy_l2_proxy']
    },
    titangoerli: {
      url: `${process.env.ETH_NODE_URI_TITAN_GOERLI}`,
      accounts: [`${process.env.PRIVATE_KEY}`],
      chainId: 5050,
      gasPrice: 250000,
      // deploy: ['deploy_l2_proxy']
    },
    sepolia: {
      url: `${process.env.ETH_NODE_URI_sepolia}`,
      accounts: [`${process.env.SEPOLIA_PRIVATE_KEY}`],
      // gasPrice: 40000000000,
      // deploy: ['deploy_l2_proxy']
      // deploy: ['deploy-layer2']
    },
  },
  deterministicDeployment: (network: string) => {
    // Skip on hardhat's local network.
    if (network === "31337") {
      return undefined;
    } else {
      return {
        factory: "0x4e59b44847b379578588920ca78fbf26c0b4956c",
        deployer: "0x3fab184622dc19b6109349b94811493bf2a45362",
        funding: "10000000000000000",
        signedTx: "0x00",
      }
    }
  },
  etherscan: {
    apiKey: {
      mainnet: `${process.env.ETHERSCAN_API_KEY}`,
      goerli: `${process.env.ETHERSCAN_API_KEY}`,
      sepolia: `${process.env.ETHERSCAN_API_KEY}`,
      titan: "verify",
      titangoerli: "verify"
    } ,
    customChains: [
      {
        network: "titan",
        chainId: 55004,
        urls: {
          apiURL: "https://explorer.titan.tokamak.network//api",
          browserURL: "https://explorer.titan.tokamak.network/"
        }
      },
      {
        network: "titangoerli",
        chainId: 5050,
        urls: {
          apiURL: "https://explorer.titan-goerli.tokamak.network/api",
          browserURL: "https://explorer.titan-goerli.tokamak.network/"
        }
      }
    ]
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    gasPrice: 21,
    coinmarketcap: `${process.env.COINMARKETCAP_API_KEY}`
  },
  mocha: {
    timeout: 100000000
  },
  solidity: {
    version: '0.8.19',
    settings: {
      // evmVersion: "cancun",
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
        // details: {
        //   yul: true,
        // },
      },
      metadata: {
        // do not include the metadata hash, since this is machine dependent
        // and we want all generated code to be deterministic
        // https://docs.soliditylang.org/en/v0.8.12/metadata.html
        bytecodeHash: 'none',
      },
    },
  },
};

export default config;
