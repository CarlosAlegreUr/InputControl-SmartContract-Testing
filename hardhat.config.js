require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@nomiclabs/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",

  networks: {
    hardhat: {},

    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
      gas: 2100000,
      gasPrice: 8000000000
    },
  },

  namedAccounts: {
    deployer: {
      default: 0,
      31337: 0,
    },
    client1: {
      default: 1,
      31337: 1,
    },
    client2: {
      default: 2,
      31337: 2,
    },
  },
};
