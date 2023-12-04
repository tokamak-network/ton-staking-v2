// import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import "@nomicfoundation/hardhat-chai-matchers";

import "hardhat-gas-reporter";
import dotenv from "dotenv" ;
import { HardhatUserConfig } from "hardhat/types";
import "hardhat-deploy";

dotenv.config();

const config: HardhatUserConfig = {
  namedAccounts: {
    deployer: 0,
    addr1: 1,
    addr2: 2,
    SeigManager: {
      default: 3,
      mainnet: '0x710936500aC59e8551331871Cbad3D33d5e0D909',
      goerli: '0x446ece59ef429B774Ff116432bbB123f1915D9E3',
      hardhat: '0x710936500aC59e8551331871Cbad3D33d5e0D909',
      local: '0x710936500aC59e8551331871Cbad3D33d5e0D909',
    },
    DepositManager: {
      default: 4,
      mainnet: '0x56E465f654393fa48f007Ed7346105c7195CEe43',
      goerli: '0x0ad659558851f6ba8a8094614303F56d42f8f39A',
      hardhat: '0x56E465f654393fa48f007Ed7346105c7195CEe43',
      local: '0x56E465f654393fa48f007Ed7346105c7195CEe43',
    },
    L2Registry: {
      default: 5,
      mainnet: '0x0b3E174A2170083e770D5d4Cf56774D221b7063e',
      goerli: '0x6817e1c04748eae68EBFF13216280Df1ec15ba86',
      hardhat: '0x0b3E174A2170083e770D5d4Cf56774D221b7063e',
      local: '0x0b3E174A2170083e770D5d4Cf56774D221b7063e',
    },
    CoinageFactory: {
      default: 6,
      mainnet: '0x5b40841eeCfB429452AB25216Afc1e1650C07747',
      goerli: '0x09207BdB146E41dadad015aB3d835f66498b0A0c',
      hardhat: '0x5b40841eeCfB429452AB25216Afc1e1650C07747',
      local: '0x5b40841eeCfB429452AB25216Afc1e1650C07747',
    },
    TON: {
      default: 7,
      mainnet: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
      goerli: '0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00',
      hardhat: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
      local: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
    },
    WTON: {
      default: 8,
      mainnet: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
      goerli: '0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6',
      hardhat: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
      local: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
    },
    TOS: {
      default: 9,
      mainnet: '0x409c4D8cd5d2924b9bc5509230d16a61289c8153',
      goerli: '0x67F3bE272b1913602B191B3A68F7C238A2D81Bb9',
      hardhat: '0x409c4D8cd5d2924b9bc5509230d16a61289c8153',
      local: '0x5b40841eeCfB429452AB25216Afc1e1650C07747',
    },
    DAOCommitteeProxy: {
      default: 10,
      mainnet: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
      goerli: '0x3C5ffEe61A384B384ed38c0983429dcDb49843F6',
      hardhat: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
      local: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
    },
    CandidateFactory: {
      default: 11,
      mainnet: '0xE6713aF11aDB0cFD3C60e15b23E43f5548C32942',
      goerli: '0xd1c4fE0Ac211F8A41817c26D1801fd549D56E31e',
      hardhat: '0xE6713aF11aDB0cFD3C60e15b23E43f5548C32942',
      local: '0xE6713aF11aDB0cFD3C60e15b23E43f5548C32942',
    },
    DAOAgendaManager: {
      default: 12,
      mainnet: '0xcD4421d082752f363E1687544a09d5112cD4f484',
      goerli: '0x0e1583da47cf641305eDD1e4C6dB6DD18e138a21',
      hardhat: '0xcD4421d082752f363E1687544a09d5112cD4f484',
      local: '0xcD4421d082752f363E1687544a09d5112cD4f484',
    },
    AutoCoinageSnapshot2: {
      default: 13,
      mainnet: '0x85Ca9f611C363065252EA9462c90743922767b55',
      goerli: '',
      hardhat: '0xcD4421d082752f363E1687544a09d5112cD4f484',
      local: '0x85Ca9f611C363065252EA9462c90743922767b55',
    },
    DaoCommitteeAdminAddress: {
      default: 14,
      mainnet: '0xb4983da083a5118c903910db4f5a480b1d9f3687',
      goerli: '',
      hardhat: '0xb4983da083a5118c903910db4f5a480b1d9f3687',
      local: '0xb4983da083a5118c903910db4f5a480b1d9f3687',
    },
    powerTonAddress: {
      default: 15,
      mainnet: '0x970298189050aBd4dc4F119ccae14ee145ad9371',
      goerli: '',
      hardhat: '0x970298189050aBd4dc4F119ccae14ee145ad9371',
      local: '0x970298189050aBd4dc4F119ccae14ee145ad9371',
    },
    daoVaultAddress: {
      default: 16,
      mainnet: '0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303',
      goerli: '',
      hardhat: '0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303',
      local: '0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303',
    },
    level19Address: {
      default: 17,
      mainnet: '0x42ccf0769e87cb2952634f607df1c7d62e0bbc52',
      goerli: '',
      hardhat: '0x42ccf0769e87cb2952634f607df1c7d62e0bbc52',
      local: '0x42ccf0769e87cb2952634f607df1c7d62e0bbc52',
    },
    level19Admin: {
      default: 18,
      mainnet: '0xd1820b18be7f6429f1f44104e4e15d16fb199a43',
      goerli: '',
      hardhat: '0xd1820b18be7f6429f1f44104e4e15d16fb199a43',
      local: '0xd1820b18be7f6429f1f44104e4e15d16fb199a43',
    },
    tokamakAddress: {
      default: 19,
      mainnet: '0x576c7a48fcef1c70db632bb1504d9a5c0d0190d3',
      goerli: '',
      hardhat: '0x576c7a48fcef1c70db632bb1504d9a5c0d0190d3',
      local: '0x576c7a48fcef1c70db632bb1504d9a5c0d0190d3',
    },
    tokamakAdmin: {
      default: 20,
      mainnet: '0xEA8e2eC08dCf4971bdcdfFFe21439995378B44F3',
      goerli: '',
      hardhat: '0xEA8e2eC08dCf4971bdcdfFFe21439995378B44F3',
      local: '0xEA8e2eC08dCf4971bdcdfFFe21439995378B44F3',
    },
    powerTonAdminAddress: {
      default: 21,
      mainnet: '0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1',
      goerli: '',
      hardhat: '0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1',
      local: '0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1',
    },
    // tonAdminAddress: {
    //   default: 10,
    //   mainnet: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
    //   goerli: '',
    //   hardhat: '',
    // },
  },
  networks: {
    hardhat: {
      forking: {
        url: `${process.env.ETH_NODE_URI_MAINNET}`,
        // blockNumber: 18231453
        // blockNumber:18229970
      },
      allowUnlimitedContractSize: false,
      // deploy: ['deploy-migration']
    },
    local: {
      url: `${process.env.ETH_NODE_URI_localhost}`,
      timeout: 400000,
      // accounts: [`${process.env.DEPLOYER}`],
      deploy: ['deploy-migration']
    },
    mainnet: {
      url: `${process.env.ETH_NODE_URI_MAINNET}`,
      accounts: [`${process.env.PRIVATE_KEY}`],
      gasPrice: 18000000000,
      // deploy: ['deploy']
    },
    goerli: {
      url: `${process.env.ETH_NODE_URI_goerli}`,
      accounts: [`${process.env.DEPLOYER}`],
      chainId: 5,
      // deploy: ['deploy']
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
      goerli: `${process.env.ETHERSCAN_API_KEY}`,
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
  solidity: {
    version: '0.8.19',
    settings: {
      optimizer: {
        enabled: true,
        runs: 625,
      },
      // viaIR: true,
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
