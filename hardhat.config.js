require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    local: {
      url:'http://127.0.0.1:8545/'	// <-- here add the '/' in the end
    }
    ,baseSepolia: {
      url: process.env.rpc, // Base Sepolia RPC URL
      accounts: [process.env.PRIVATE_KEY] 
    }
    }
};
