require("@nomiclabs/hardhat-waffle");
require('dotenv').config();
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  solidity: "0.6.6",
  networks: {
    hardhat: {
      forking: {
        url: process.env.FORKING_URL,
        blockNumber: 11198001
      }
    },
    kovan: {
      url: process.env.KOVAN_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};

// task("test-all", "Runs all tests in their appropriate network")
//   .setAction(async (args, { run }) => {
//     await run("test", { testFiles: ["test/testFork.js"] });
//     await run("test", { testFiles: ["test/testKovan.js"], network: 'kovan' });
//   });
