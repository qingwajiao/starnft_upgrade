const { ethers } = require("ethers");
// const { contractABI } = require('./blinbox_ABI.js');
const MeteoriteABI = require('./MeteoriteABI.js');

// 1. 构建 provider  
const provider = new ethers.providers.JsonRpcProvider('https://sepolia.infura.io/v3/fa99da8fb08c4b94b7e9a29f6d7f7c09');


// 2.获取wallet   
    // userWallet 用户钱包用于发起交易 
const userWallet = new ethers.Wallet("0x34e99c293405283be8dddc8e847c87ceae9e7e91b1995fd94aabf5032c8917c4", provider);
    // backendAdminWallet 后端管理账户只用于给的合约方法生成签名参数 signature
const backendAdminWallet = new ethers.Wallet("0x34e99c293405283be8dddc8e847c87ceae9e7e91b1995fd94aabf5032c8917c4");

const MeteoriteAddress = "0x349A5d5Ae61855070D99EFA9B579bF545dDB95B1";
// 3.通过 地址，abi，provider 构建合约对象
const contract = new ethers.Contract(MeteoriteAddress, MeteoriteABI, provider);
const contractWithWallet = contract.connect(userWallet);


/*
* @method cBuyBox  中心化钱包购买盲盒
* @param  tokenId  盲盒tokenid，表示同一种盲盒
* @param  amount   用户购买数量
* @param  nonce    后端签名的序列号，防止重用签名
* @return status   交易是否成功：status: 1 (成功) 或 0 (失败)
*/
 async function setOperator(op,state) {

  let state1 = await contract.operators(op);
  console.log("当前mint权限:", state1);

  const tx = await contractWithWallet.setOperator(op, state);

  // 等待交易上链
  await tx.wait();

  // 获取交易回执
  const receipt = await provider.getTransactionReceipt(tx.hash);
  console.log("交易哈希:", tx.hash, "交易状态:", receipt.status == 1 ? "成功!" : "失败!");

  let state2 = await contract.operators(op);
  console.log("当前mint权限:", state2);

  // 查看交易是否成功：status: 1 (成功) 或 0 (失败)
  return {
    status: receipt.status,
    hash: tx.hash,
  };
};


async function mint(to,id,quality) {

  let balanceBefore = await contract.balanceOf(to);
  console.log("购买前用户的盲盒数量:", balanceBefore.toString());

  const tx = await contractWithWallet.mintMeteorite(to,id,quality);

  // 等待交易上链
  await tx.wait();

  // 获取交易回执
  const receipt = await provider.getTransactionReceipt(tx.hash);
  console.log("交易哈希:", tx.hash, "交易状态:", receipt.status == 1 ? "成功!" : "失败!");

  let balanceAfter = await contract.balanceOf(to);
  console.log("购买后用户的盲盒数量:", balanceAfter.toString());

  // 查看交易是否成功：status: 1 (成功) 或 0 (失败)
  return {
    status: receipt.status,
    hash: tx.hash,
  };
};

async function quality(id) {

  let power = await contract.powers(id);
  console.log("购买前用户的盲盒数量:", power);

  // ownerOf
};

async function ownerOf(id) {

  let power = await contract.ownerOf(id);
  console.log("address:", power);

  // ownerOf
};



async function main(){


  // 去中心化购买
  // setOperator("0xD6B0d32C013E5a8E8B85F680066E237fAf1CE699",true) 
  // mint("0xA86d6876E8c50D66A00B1A5E81B9D5a6fF0aA204",1,"sss")

  ownerOf(7)

}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

