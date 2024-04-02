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
      mainnet: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      goerli: '0x446ece59ef429B774Ff116432bbB123f1915D9E3',
      hardhat: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      local: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
    },
    DepositManager: {
      default: 4,
      mainnet: '0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E',
      goerli: '0x0ad659558851f6ba8a8094614303F56d42f8f39A',
      hardhat: '0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E',
      local: '0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E',
    },
    L2Registry: {
      default: 5,
      mainnet: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      goerli: '0x6817e1c04748eae68EBFF13216280Df1ec15ba86',
      hardhat: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      local: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
    },
    CoinageFactory: {
      default: 6,
      mainnet: '0xe8fae91b80dd515c3d8b9fc02cb5b2ecfddabf43',
      goerli: '0x09207BdB146E41dadad015aB3d835f66498b0A0c',
      hardhat: '0xe8fae91b80dd515c3d8b9fc02cb5b2ecfddabf43',
      local: '0xe8fae91b80dd515c3d8b9fc02cb5b2ecfddabf43',
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
      local: '0x409c4D8cd5d2924b9bc5509230d16a61289c8153',
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
      mainnet: '0x9fc7100a16407ee24a79c834a56e6eca555a5d7c',
      goerli: '0xd1c4fE0Ac211F8A41817c26D1801fd549D56E31e',
      hardhat: '0x9fc7100a16407ee24a79c834a56e6eca555a5d7c',
      local: '0x9fc7100a16407ee24a79c834a56e6eca555a5d7c',
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
    SeigManagerProxy: {
      default: 22,
      mainnet: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      goerli: '',
      hardhat: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
      local: '0x0b55a0f463b6defb81c6063973763951712d0e5f',
    },
    DepositManagerProxy: {
      default: 23,
      mainnet: '0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e',
      goerli: '',
      hardhat: '0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e',
      local: '0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e',
    },
    Layer2RegistryProxy: {
      default: 23,
      mainnet: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      goerli: '',
      hardhat: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      local: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
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
    },
    l1BridgeAddress: {
      default: 23,
      mainnet: '0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD',
      goerli: '0x7377F3D0F64d7a54Cf367193eb74a052ff8578FD',
      hardhat: '0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD',
      local: '0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD',
    },
    l1AddressManagerAddress: {
      default: 24,
      mainnet: '0xeDf6C92fA72Fa6015B15C9821ada145a16c85571',
      goerli: '0xEFa07e4263D511fC3a7476772e2392efFb1BDb92',
      hardhat: '0xeDf6C92fA72Fa6015B15C9821ada145a16c85571',
      local: '0xeDf6C92fA72Fa6015B15C9821ada145a16c85571',
    },
    l2TokenFactoryAddress: {
      default: 25,
      mainnet: '',
      goerli: '',
      hardhat: '',
      local: '',
    },
    l2TonAddress: {
      default: 26,
      mainnet: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2',
      goerli: '0xFa956eB0c4b3E692aD5a6B2f08170aDE55999ACa',
      hardhat: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2',
      local: '0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2',
    },
    swapProxy: {
      default: 27,
      mainnet: '0x30e65B3A6e6868F044944Aa0e9C5d52F8dcb138d',
      goerli: '',
      hardhat: '0x30e65B3A6e6868F044944Aa0e9C5d52F8dcb138d',
      local: '0x30e65B3A6e6868F044944Aa0e9C5d52F8dcb138d',
    },
    DAOCommitteeOwner : {
      default: 28,
      mainnet: '0xe070ffd0e25801392108076ed5291fa9524c3f44',
      goerli: '',
      hardhat: '0xe070ffd0e25801392108076ed5291fa9524c3f44',
      local: '0xe070ffd0e25801392108076ed5291fa9524c3f44',
    }
  },
  networks: {
    hardhat: {
      forking: {
        url: `${process.env.ETH_NODE_URI_MAINNET}`,
        // blockNumber: 18811511
        // blockNumber:18229970
      },

      // allowUnlimitedContractSize: false,
      // deploy: ['deploy-migration']
    },
    local: {
      url: `${process.env.ETH_NODE_URI_localhost}`,
      timeout: 800000,
      // accounts: [`${process.env.DEPLOYER}`],
      // deploy: ['deploy-migration']
    },
    mainnet: {
      url: `${process.env.ETH_NODE_URI_MAINNET}`,
      accounts: [`${process.env.PRIVATE_KEY}`],
      gasPrice: 50000000000,
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
      accounts: [`${process.env.PRIVATE_KEY}`],
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
  solidity: {
    version: '0.8.19',
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
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
