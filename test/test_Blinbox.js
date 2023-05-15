const { ethers } = require("ethers");
// const { contractABI } = require('./blinbox_ABI.js');
const contractABI = require('./blinbox_ABI.js');

// 1. 构建 provider  
const provider = new ethers.providers.JsonRpcProvider('https://sepolia.infura.io/v3/fa99da8fb08c4b94b7e9a29f6d7f7c09');

// const contractABI = [
//   // 合约 ABI
//   'function checkSigner(uint256 nftID, uint256 amount, uint256 price, uint256 nonce, bytes calldata signature) external view returns (bool)',
//   'function cStarBox(uint256 nftID, uint256 amount, uint256 nonce, bytes calldata signature) external',
//   'function balanceOf(address account, uint256 id) external view returns (uint256)',
//   "function USDT()external pure returns(string memory)"
// ];

// 2.获取wallet   
    // userWallet 用户钱包用于发起交易 
const userWallet = new ethers.Wallet("0x34e99c293405283be8dddc8e847c87ceae9e7e91b1995fd94aabf5032c8917c4", provider);
    // backendAdminWallet 后端管理账户只用于给的合约方法生成签名参数 signature
const backendAdminWallet = new ethers.Wallet("0x34e99c293405283be8dddc8e847c87ceae9e7e91b1995fd94aabf5032c8917c4");

const BlindboxAddress = "0xD6B0d32C013E5a8E8B85F680066E237fAf1CE699";
// 3.通过 地址，abi，provider 构建合约对象
const contract = new ethers.Contract(BlindboxAddress, contractABI, provider);
const contractWithWallet = contract.connect(userWallet);


// 构建创建星卡需要的属性 Attribute 对象数组
const attributes1 = [
  {
    id: 7,                // toeknid 不能重复，否则创建星卡失败
    level: 1,             // 级别
    starRating: 1,        // 星级
    computingPower: 1,    // 算力
    quality: 'Rare',         // 品质
    color: 'Red'          // 颜色
  },
  // {
  //   id: 8,                // toeknid 不能重复，否则创建星卡失败
  //   level: 2,             // 级别
  //   starRating: 2,        // 星级
  //   computingPower: 2,    // 算力
  //   quality: 'B',         // 品质
  //   color: 'yellow'       // 颜色
  // }
];

const attributes2 = [
  {
    id: 7,                // toeknid 不能重复，否则创建星卡失败
    quality: 'aaa',         // 品质
  },

];


function cBuyBoxSignature(tokenId, amount, nonce) {
  // 2. 签名内容进行 solidityKeccak256格式 Hash  【--- 此处为参数类型----】   【---此处为参数值------】    
  let result = ethers.utils.solidityKeccak256(['int', 'int', 'int'], [tokenId, amount, nonce]);
  // 3.转成UTF8 bytes    
  let arrayifyMessage = ethers.utils.arrayify(result);
  // 4.签名    
  let signMessage = backendAdminWallet.signMessage(arrayifyMessage)
  return signMessage;
}

function dBuyBoxSignature(tokenId, amount, price, nonce) {

  // 2. 签名内容进行 solidityKeccak256格式 Hash  【--- 此处为参数类型----】   【---此处为参数值------】    
  let result = ethers.utils.solidityKeccak256(['uint256', 'uint256', 'uint256', 'uint256'], [tokenId, amount, price, nonce]);
  // 3.转成UTF8 bytes    
  let arrayifyMessage = ethers.utils.arrayify(result);
  // 4.签名    
  let signMessage = backendAdminWallet.signMessage(arrayifyMessage)
  return signMessage;
}

function openBoxSignature(tokenId, nonce) {
  // 2. 签名内容进行 solidityKeccak256格式 Hash  【--- 此处为参数类型----】   【---此处为参数值------】    
  let result = ethers.utils.solidityKeccak256(['int', 'int'], [tokenId, nonce]);
  // 3.转成UTF8 bytes    
  let arrayifyMessage = ethers.utils.arrayify(result);
  // 4.签名    
  let signMessage = backendAdminWallet.signMessage(arrayifyMessage)
  return signMessage;
}

/*
* @method cBuyBox  中心化钱包购买盲盒
* @param  tokenId  盲盒tokenid，表示同一种盲盒
* @param  amount   用户购买数量
* @param  nonce    后端签名的序列号，防止重用签名
* @return status   交易是否成功：status: 1 (成功) 或 0 (失败)
*/
 async function cBuyBox(tokenId, amount, nonce) {

  let balanceBefore = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("购买前用户的盲盒数量:", balanceBefore.toString());

  const sign = cBuyBoxSignature(tokenId, amount, nonce)
  const tx = await contractWithWallet.cStarBox(tokenId, amount, nonce, sign);

  // 等待交易上链
  await tx.wait();

  // 获取交易回执
  const receipt = await provider.getTransactionReceipt(tx.hash);
  console.log("交易哈希:", tx.hash, "交易状态:", receipt.status == 1 ? "成功!" : "失败!");

  const balanceAfter = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("购买后用户的盲盒数量:", balanceAfter.toString());

  // 查看交易是否成功：status: 1 (成功) 或 0 (失败)
  return {
    status: receipt.status,
    hash: tx.hash,
  };
};


/*
* @method dBuyBox  去中心化钱包购买盲盒
* @param  tokenId  盲盒tokenid，表示同一种盲盒
* @param  amount   用户购买数量
* @param  price    盲盒单价,注意代币的精度
* @param  nonce    后端签名的序列号，防止重用签名
* @return status   交易是否成功：status: 1 (成功) 或 0 (失败)
*/
 async function dBuyBox(tokenId, amount, price, nonce) {

  let balanceBefore = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("购买前用户的盲盒数量:", balanceBefore.toString());

  let _price = ethers.utils.parseUnits(price.toString() ,8);
  let sign = dBuyBoxSignature(tokenId, amount, _price, nonce)
  console.log("签名消息:", sign);
  let tx = await contractWithWallet.dBuyBox(tokenId, amount, _price, nonce, sign);

  // 等待交易上链
  await tx.wait();

  // 获取交易回执
  let receipt = await provider.getTransactionReceipt(tx.hash);
  console.log("交易哈希:", tx.hash, "交易状态:", receipt.status == 1 ? "成功!" : "失败!");

  let balanceAfter = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("购买后用户的盲盒数量:", balanceAfter.toString());

  // 查看交易是否成功：status: 1 (成功) 或 0 (失败)
  return receipt.status;
}

/*
* @method openBox       开盲盒，创建星卡-->销毁盲盒  可以理解这两步在一个事务中
* @param  tokenId       盲盒tokenid，表示同一种盲盒
* @param  nonce         后端签名的序列号，防止重用签名
* @param  attributes    创建星卡所需要的属性，因为支持批量操作，所以这里是一个attribute数组
* @return status        交易是否成功：status: 1 (成功) 或 0 (失败)
*/
 async function openBox(tokenId, nonce, attributes) {

  let balanceBefore = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("开盲盒前用户的盲盒数量:", balanceBefore.toString());

  let sign = openBoxSignature(tokenId, nonce)
  let tx = await contractWithWallet.openBox(tokenId, nonce, sign, attributes);

  // 等待交易上链
  await tx.wait();

  // 获取交易回执
  let receipt = await provider.getTransactionReceipt(tx.hash);
  console.log("交易哈希:", tx.hash, "交易状态:", receipt.status == 1 ? "成功!" : "失败!");

  let balanceAfter = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("开盲盒后用户的盲盒数量:", balanceAfter.toString());

  // 查看交易是否成功：status: 1 (成功) 或 0 (失败)
  return {
    status: receipt.status,
    hash: tx.hash,
  };
};

async function openMeteoriteBox(tokenId, nonce, attributes2) {

  let balanceBefore = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("开盲盒前用户的盲盒数量:", balanceBefore.toString());

  let sign = openBoxSignature(tokenId, nonce)
  let tx = await contractWithWallet.openMeteoriteBox(tokenId, nonce, sign, attributes2);

  // 等待交易上链
  await tx.wait();

  // 获取交易回执
  let receipt = await provider.getTransactionReceipt(tx.hash);
  console.log("交易哈希:", tx.hash, "交易状态:", receipt.status == 1 ? "成功!" : "失败!");

  let balanceAfter = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("开盲盒后用户的盲盒数量:", balanceAfter.toString());

  // 查看交易是否成功：status: 1 (成功) 或 0 (失败)
  return {
    status: receipt.status,
    hash: tx.hash,
  };
};

async function setMeteorite(meteorite) {

  let meteoriteAddress = await contract.meteorite();
  console.log("meteorite:", meteoriteAddress);

  // let sign = openBoxSignature(tokenId, nonce)
  let tx = await contractWithWallet.setMeteorite(meteorite);

  // 等待交易上链
  await tx.wait();

  // 获取交易回执
  let receipt = await provider.getTransactionReceipt(tx.hash);
  console.log("交易哈希:", tx.hash, "交易状态:", receipt.status == 1 ? "成功!" : "失败!");

  let meteoriteAddress2 = await contract.meteorite();
  console.log("后 meteorite:", meteoriteAddress2);

  // 查看交易是否成功：status: 1 (成功) 或 0 (失败)
  return {
    status: receipt.status,
    hash: tx.hash,
  };
};




async function main(){

  
  // // 输出测试结果
  // console.log(result);

  // 去中心化购买
  // cBuyBox(2,3,3)
  // setMeteorite("0x349A5d5Ae61855070D99EFA9B579bF545dDB95B1")
  openMeteoriteBox(2, 4, attributes2)

}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

