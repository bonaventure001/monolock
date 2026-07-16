require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000000";

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: { enabled: true, runs: 200 }
    }
  },
  networks: {
    monadTestnet: {
      url: process.env.MONAD_TESTNET_RPC || "https://monad-testnet.drpc.org",
      chainId: 10143,
      accounts: [PRIVATE_KEY]
    },
    monadMainnet: {
      url: process.env.MONAD_MAINNET_RPC || "https://rpc.monad.xyz",
      chainId: 143,
      accounts: [PRIVATE_KEY]
    }
  }
};
