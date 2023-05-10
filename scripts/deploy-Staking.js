// scripts/deploy.js

const { ethers } = require("hardhat");
const { upgrades } = require("hardhat");



async function main() {

  const Staking = await ethers.getContractFactory("Staking")
  
  console.log("正在發佈 Staking ...")
  const proxy = await upgrades.deployProxy(Staking,["0x8ec3397952fbA1Ab7164EBA628fF56a6eb0e6213"], { initializer: 'initialize' })
  
  console.log("StakingProxy 合約地址", proxy.address)
  console.log("等待兩個網路確認 ... ")
  const receipt = await proxy.deployTransaction.wait(2);

  console.log("管理合約地址 getAdminAddress", await upgrades.erc1967.getAdminAddress(proxy.address))
  console.log("Staking邏輯合約地址 getImplementationAddress", await upgrades.erc1967.getImplementationAddress(proxy.address))    
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

