import "@nomicfoundation/hardhat-foundry";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.5.12",
      },
      {
        version: "0.8.19",
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
    ],
  },
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache_hardhat",
    artifacts: "./artifacts",
  },
  // Foundry remappings을 Hardhat에서 자동 인식
  // @nomicfoundation/hardhat-foundry 플러그인이 foundry.toml의 remappings를 자동으로 읽습니다
  // 주의: 'src/=' remapping이 프로젝트 내부 src/와 충돌할 수 있음
  // 해결: foundry.toml의 'src/=' remapping은 Optimism 컨트랙트용이므로
  // 프로젝트 내부 src/는 상대 경로로 import되어야 함
};

export default config;

