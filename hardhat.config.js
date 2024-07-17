require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */

const ETHEREUM_RPC_URL = process.env.ETHEREUM_RPC_URL;
const ETHEREUM_TESTNET_RPC_URL = process.env.ETHEREUM_TESTNET_RPC_URL;
const WALLET_PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY;

module.exports = {
  solidity: "0.8.20",
  networks: {
    hardhat: {
      forking: {
        url: ETHEREUM_RPC_URL,
      },
    },
    testnet: {
      url: ETHEREUM_TESTNET_RPC_URL,
      chainId: 11155111, // Sepolia Chain ID
      accounts: [WALLET_PRIVATE_KEY],
    },
  },
};
