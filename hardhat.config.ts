import { parse, visit } from "@solidity-parser/parser";
import { HardhatUserConfig, extendEnvironment } from "hardhat/config";
import { getFullyQualifiedName } from "hardhat/utils/contract-names";

const config: HardhatUserConfig = {
  solidity: {
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
    compilers: [
      {
        version: "0.8.13",
      },
      {
        version: "0.8.11",
      },
      {
        version: "0.8.6",
      },
      {
        version: "0.8.0",
      },
    ],
  },
  networks: {
    hardhat: {
      // blockGasLimit: DEFAULT_BLOCK_GAS_LIMIT,
      // gas: DEFAULT_BLOCK_GAS_LIMIT,
      // chainId: BUIDLEREVM_CHAINID,
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      allowUnlimitedContractSize: true,
      // accounts: accounts.map(
      //   ({ secretKey, balance }: { secretKey: string; balance: string }) => ({
      //     privateKey: secretKey,
      //     balance,
      //   })
      // ),
      // forking: buildForkConfig(),
    },
    localhost: {
      // blockGasLimit: DEFAULT_BLOCK_GAS_LIMIT,
      // gas: DEFAULT_BLOCK_GAS_LIMIT,
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      allowUnlimitedContractSize: true,
      // forking: buildForkConfig(),
      // accounts: accounts.map(
      //   ({ secretKey }: { secretKey: string; balance: string }) => secretKey
      // ),
    },
  },
  mocha: { 
    timeout: 20000 
  },
};

extendEnvironment((hre) => {
  hre.getEnum = async (contractName, enumName) => {
    const { artifacts } = hre;
    const { sourceName } = await artifacts.readArtifact(contractName);
    const { input } = await artifacts.getBuildInfo(getFullyQualifiedName(sourceName, contractName));
    return new Promise((resolve, reject) => {
      let found = false;
      visit(parse(input.sources[sourceName].content), {
        EnumDefinition: ({ name, members }) => {
          if (found || name !== enumName) return;
          found = true;
          resolve(
            Object.fromEntries(
              members.flatMap(({ name: valueName }, i) => [
                [i, valueName],
                [valueName, i],
              ]),
            ),
          );
        },
      });
      if (!found) reject("not found");
    });
  };
});



export default config;

declare module "hardhat/types/runtime" {
  export interface HardhatRuntimeEnvironment {
    getEnum: (contractName: string, enumName: string) => Promise<any>; // eslint-disable-line @typescript-eslint/no-explicit-any
  }
}