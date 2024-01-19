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
      goerli: '0x50255c955d0F760C8512ff556453AEe6502ef47f',
      hardhat: '0x50255c955d0F760C8512ff556453AEe6502ef47f',
      local: '0x50255c955d0F760C8512ff556453AEe6502ef47f',
    },
    DepositManagerAddress: {
      default: 4,
      mainnet: '0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e',
      local: '0x0e1EF78939F9d3340e63A7a1077d50999CC6B64f',
      goerli: '0x0e1EF78939F9d3340e63A7a1077d50999CC6B64f',
      hardhat: '0x0e1EF78939F9d3340e63A7a1077d50999CC6B64f',

    },
    L2RegistryAddress: {
      default: 5,
      mainnet: '0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b',
      local: '0xFF2258eAa1c82d09a9ed0198116d9557c34104Fa',
      goerli: '0xFF2258eAa1c82d09a9ed0198116d9557c34104Fa',
      hardhat: '0xFF2258eAa1c82d09a9ed0198116d9557c34104Fa',
    },
    TON: {
      default: 6,
      mainnet: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
      goerli: '0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00',
      hardhat: '0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00',
      local: '0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00',
    },
    WTON: {
      default: 7,
      mainnet: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
      goerli: '0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6',
      hardhat: '0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6',
      local: '0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6',
    },
    TOS: {
      default: 8,
      mainnet: '0x409c4D8cd5d2924b9bc5509230d16a61289c8153',
      goerli: '0x67F3bE272b1913602B191B3A68F7C238A2D81Bb9',
      hardhat: '0x67F3bE272b1913602B191B3A68F7C238A2D81Bb9',
      local: '0x67F3bE272b1913602B191B3A68F7C238A2D81Bb9',
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
      local: '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2',
      goerli: '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2',
      hardhat: '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2',

    },
    powerTonAddress: {
      default: 11,
      mainnet: '0x970298189050aBd4dc4F119ccae14ee145ad9371',
      local: '0x031B5b13Df847eB10c14451EB2a354EfEE23Cc94',
      goerli: '0x031B5b13Df847eB10c14451EB2a354EfEE23Cc94',
      hardhat: '0x031B5b13Df847eB10c14451EB2a354EfEE23Cc94',

    },
    daoVaultAddress: {
      default: 12,
      mainnet: '0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303',
      goerli: '0x3C5ffEe61A384B384ed38c0983429dcDb49843F6',
      hardhat: '0x3C5ffEe61A384B384ed38c0983429dcDb49843F6',
      local: '0x3C5ffEe61A384B384ed38c0983429dcDb49843F6',
    },
    level19Address: {
      default: 13,
      mainnet: '0x0F42D1C40b95DF7A1478639918fc358B4aF5298D',
      goerli: '0x2e8400Ec60349A18DD84De0566881379056a3085',
      hardhat: '0x2e8400Ec60349A18DD84De0566881379056a3085',
      local: '0x2e8400Ec60349A18DD84De0566881379056a3085',
    },
    level19Admin: {
      default: 14,
      mainnet: '0xd1820b18be7f6429f1f44104e4e15d16fb199a43',
      goerli: '0xc1eba383D94c6021160042491A5dfaF1d82694E6',
      hardhat: '0xc1eba383D94c6021160042491A5dfaF1d82694E6',
      local: '0xc1eba383D94c6021160042491A5dfaF1d82694E6',
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
      local: '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2',
      goerli: '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2',
      hardhat: '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2',
    },
    l1StosToL2Address: {
      default: 18,
      mainnet: '',
      local: '0x3ADE3a1d7471f9629B6Dbb3d316E158B2Bcab87b',
      goerli: '0x3ADE3a1d7471f9629B6Dbb3d316E158B2Bcab87b',
      hardhat: '0x3ADE3a1d7471f9629B6Dbb3d316E158B2Bcab87b',
    },
    l2AirdropStosAddress: {
      default: 19,
      mainnet: '',
      local: '0xC74b529Ad06E70fA51CDDAD11857D53E6354523d',
      goerli: '',
      hardhat: '0xC74b529Ad06E70fA51CDDAD11857D53E6354523d',
      titangoerli: '0xC74b529Ad06E70fA51CDDAD11857D53E6354523d'
    },
    l2UniversalStosAddress: {
      default: 20,
      mainnet: '',
      local: '0x58B4C2FEf19f5CDdd944AadD8DC99cCC71bfeFDc',
      goerli: '',
      hardhat: '0x58B4C2FEf19f5CDdd944AadD8DC99cCC71bfeFDc',
      titangoerli: '0x58B4C2FEf19f5CDdd944AadD8DC99cCC71bfeFDc'
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
      // forking: {
      //   url: `${process.env.ETH_NODE_URI_MAINNET}`,
      //   blockNumber: 18811511
      //   // blockNumber:18229970
      // },
      forking: {
        url: `${process.env.ETH_NODE_URI_goerli}`,
        blockNumber: 10397297
      },
      allowUnlimitedContractSize: false,
      // deploy: ['deploy-ton-register-l1']
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
      deploy: ['deploy-seig-manager-v1']
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
      // gasPrice: 250000,
      deploy: ['deploy-ton-register-l2']
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
          apiURL: "https://explorer.titan.tokamak.network/api",
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
