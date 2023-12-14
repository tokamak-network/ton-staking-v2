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
    SeigManagerAddress: {
      default: 3,
      mainnet: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      goerli: '0x446ece59ef429B774Ff116432bbB123f1915D9E3',
      hardhat: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      local: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
    },
    DepositManagerAddress: {
      default: 4,
      mainnet: '0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e',
      local: '0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e',
      goerli: '0x0ad659558851f6ba8a8094614303F56d42f8f39A',
      hardhat: '0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e',

    },
    L2RegistryAddress: {
      default: 5,
      mainnet: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      local: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      goerli: '0x6817e1c04748eae68EBFF13216280Df1ec15ba86',
      hardhat: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
    },
    TON: {
      default: 6,
      mainnet: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
      goerli: '0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00',
      hardhat: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
      local: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
    },
    WTON: {
      default: 7,
      mainnet: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
      goerli: '0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6',
      hardhat: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
      local: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
    },
    TOS: {
      default: 8,
      mainnet: '0x409c4D8cd5d2924b9bc5509230d16a61289c8153',
      goerli: '0x67F3bE272b1913602B191B3A68F7C238A2D81Bb9',
      hardhat: '0x409c4D8cd5d2924b9bc5509230d16a61289c8153',
      local: '0x5b40841eeCfB429452AB25216Afc1e1650C07747',
    },
    DAOCommitteeProxy: {
      default: 9,
      mainnet: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
      goerli: '0x3C5ffEe61A384B384ed38c0983429dcDb49843F6',
      hardhat: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
      local: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
    },
    DaoCommitteeAdminAddress: {
      default: 10,
      mainnet: '0xb4983da083a5118c903910db4f5a480b1d9f3687',
      local: '0xb4983da083a5118c903910db4f5a480b1d9f3687',
      goerli: '',
      hardhat: '0xb4983da083a5118c903910db4f5a480b1d9f3687',

    },
    powerTonAddress: {
      default: 11,
      mainnet: '0x970298189050aBd4dc4F119ccae14ee145ad9371',
      local: '0x970298189050aBd4dc4F119ccae14ee145ad9371',
      goerli: '',
      hardhat: '0x970298189050aBd4dc4F119ccae14ee145ad9371',

    },
    daoVaultAddress: {
      default: 12,
      mainnet: '0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303',
      goerli: '',
      hardhat: '0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303',
      local: '0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303',
    },
    level19Address: {
      default: 13,
      mainnet: '0x0F42D1C40b95DF7A1478639918fc358B4aF5298D',
      goerli: '',
      hardhat: '0x0F42D1C40b95DF7A1478639918fc358B4aF5298D',
      local: '0x0F42D1C40b95DF7A1478639918fc358B4aF5298D',
    },
    level19Admin: {
      default: 14,
      mainnet: '0xd1820b18be7f6429f1f44104e4e15d16fb199a43',
      goerli: '',
      hardhat: '0xd1820b18be7f6429f1f44104e4e15d16fb199a43',
      local: '0xd1820b18be7f6429f1f44104e4e15d16fb199a43',
    },
    tokamakAddress: {
      default: 15,
      mainnet: '0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF',
      goerli: '',
      hardhat: '0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF',
      local: '0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF',
    },
    tokamakAdmin: {
      default: 16,
      mainnet: '0xEA8e2eC08dCf4971bdcdfFFe21439995378B44F3',
      goerli: '',
      hardhat: '0xEA8e2eC08dCf4971bdcdfFFe21439995378B44F3',
      local: '0xEA8e2eC08dCf4971bdcdfFFe21439995378B44F3',
    },
    powerTonAdminAddress: {
      default: 17,
      mainnet: '0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1',
      local: '0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1',
      goerli: '',
      hardhat: '0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1',
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
        blockNumber: 18575278
        // blockNumber:18229970
      },
      allowUnlimitedContractSize: false,
      // deploy: ['deploy-migration']
    },
    local: {
      url: `${process.env.ETH_NODE_URI_localhost}`,
      timeout: 400000,
      // accounts: [`${process.env.PRIVATE_KEY}`],
      // deploy: ['deploy-migration']
    },
    mainnet: {
      url: `${process.env.ETH_NODE_URI_MAINNET}`,
      accounts: [`${process.env.PRIVATE_KEY}`],
      timeout: 400000,
      gasPrice: 30000000000,
      // deploy: ['deploy-migration']
    },
    goerli: {
      url: `${process.env.ETH_NODE_URI_goerli}`,
      accounts: [`${process.env.DEPLOYER}`],
      timeout: 400000,
      chainId: 5,
      // deploy: ['deploy-migration-goerli']
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
      mainnet: `${process.env.ETHERSCAN_API_KEY}`,
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
  mocha: {
    timeout: 400000
  }
};

export default config;
