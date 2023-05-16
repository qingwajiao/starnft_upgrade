require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
// require('dotenv').config( { path: `.env.${process.env.NODE_ENV}` } )
// require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.10",

  settings:{
    optimizer:{
      enabled: true,
      runs: 200
    }
  },

  networks: {
    sepolia: {
      url: 'https://sepolia.infura.io/v3/fa99da8fb08c4b94b7e9a29f6d7f7c09',
      accounts: ['0x34e99c293405283be8dddc8e847c87ceae9e7e91b1995fd94aabf5032c8917c4']
    },

    bsctest: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      accounts: ['0x34e99c293405283be8dddc8e847c87ceae9e7e91b1995fd94aabf5032c8917c4']
    },

    localhost: {
      url: 'http://localhost:8545',
      accounts: ['d786d2833c9fe8172edd7b964656a4dbdcf1363be1b4de09718c6e57b53f1946']
    },
    
  },
  etherscan: {
      apiKey: "QDUX16KXR7A4YU3STAMGNBSZ925EWQUW9W"
    
  }

};

// 正在發佈 FRANKNFTUUPS ...
// Proxy 合約地址 0x4Ee453c9D32dBB45D59f46d77dc3191a7dB2ABe9
// 等待兩個網路確認 ... 
// 邏輯合約地址 getImplementationAddress 0x2C88774918866E3C3C2b2213B5fc631591a88036