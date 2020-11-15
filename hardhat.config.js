require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

module.exports = {
  solidity: "0.6.6",
  networks: {
    hardhat: {
      forking: {
        url: process.env.FORKING_URL,
        blockNumber: 11250730
      }
    }
  }
};
