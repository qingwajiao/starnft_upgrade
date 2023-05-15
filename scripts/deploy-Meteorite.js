// scripts/deploy.js

const { ethers } = require("hardhat");
const { upgrades } = require("hardhat");



async function main() {

  const Meteorite = await ethers.getContractFactory("Meteorite")
  
  console.log("正在發佈 FRANKNFTUUPS ...")
  const proxy = await upgrades.deployProxy(Meteorite, { initializer: 'initialize', kind: 'uups' })
  
  console.log("Proxy 合約地址", proxy.address)
  console.log("等待兩個網路確認 ... ")
  const receipt = await proxy.deployTransaction.wait(2);
  console.log("邏輯合約地址 getImplementationAddress", await upgrades.erc1967.getImplementationAddress(proxy.address))
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

