// scripts/deploy.js

const { ethers } = require("hardhat");
const { upgrades } = require("hardhat");

async function main() {

  const BlindBox = await ethers.getContractFactory("BlindBox")
  
  console.log("正在發佈 BlindBox ...")
  const proxy = await upgrades.deployProxy(BlindBox, ["0xA86d6876E8c50D66A00B1A5E81B9D5a6fF0aA204"], { initializer: 'initialize' })
  
  console.log("Proxy 合約地址", proxy.address)

  console.log("等待兩個網路確認 ... ")
  const receipt = await proxy.deployTransaction.wait(2);

  console.log("管理合約地址 getAdminAddress", await upgrades.erc1967.getAdminAddress(proxy.address))
  let ImplementationAddress = await upgrades.erc1967.getImplementationAddress(proxy.address)
  console.log("邏輯合約地址 getImplementationAddress", ImplementationAddress)  
  
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})