// scripts/deploy.js

const { ethers } = require("hardhat");
const { upgrades } = require("hardhat");

const fs = require('fs');

function appendToFile(filePath, content) {
  fs.appendFile(filePath, content, function (err) {
    if (err) {
      console.error('文件追加失败:', err);
    } else {
      console.log('内容已成功追加到文件:', filePath);
    }
  });
}

// 示例用法
const filePath = '../ContractAddress.txt';
const content = '要追加的内容';

appendToFile(filePath, content)

async function main() {

  const StarNft = await ethers.getContractFactory("StarNft")
  
  console.log("正在發佈 StarNft ...")
  const proxy = await upgrades.deployProxy(StarNft, { initializer: 'initialize' })
  
  console.log("StarNftProxy 合約地址", proxy.address)
  console.log("等待兩個網路確認 ... ")
  const receipt = await proxy.deployTransaction.wait(2);

  console.log("管理合約地址 getAdminAddress", await upgrades.erc1967.getAdminAddress(proxy.address))
  console.log("StarNft邏輯合約地址 getImplementationAddress", await upgrades.erc1967.getImplementationAddress(proxy.address))    
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

