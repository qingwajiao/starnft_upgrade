const { ethers } = require("ethers");
// const { contractABI } = require('./blinbox_ABI.js');
const contractABI = require('./blinbox_ABI.js');

// 1. 构建 provider  
const provider = new ethers.providers.JsonRpcProvider('https://sepolia.infura.io/v3/fa99da8fb08c4b94b7e9a29f6d7f7c09');


// 2.获取wallet   
    // userWallet 用户钱包用于发起交易 
const userWallet = new ethers.Wallet("17e35505254978766c36ed7ec3421984e0245a18b2df92c1ab433195a3868e19", provider);
    // backendAdminWallet 后端管理账户只用于给的合约方法生成签名参数 signature
const backendAdminWallet = new ethers.Wallet("17e35505254978766c36ed7ec3421984e0245a18b2df92c1ab433195a3868e19");

const BlindboxAddress = "0xb9ef9BbF8e274c57e54A7085B6F24353C13B3620";
// 3.通过 地址，abi，provider 构建合约对象
const contract = new ethers.Contract(BlindboxAddress, contractABI, provider);
const contractWithWallet = contract.connect(userWallet);


// 构建创建星卡需要的属性 Attribute 对象数组
const attributes1 = [
  {
    id: 3,                // toeknid 不能重复，否则创建星卡失败
    level: 1,             // 级别
    starRating: 1,        // 星级
    computingPower: 1,    // 算力
    quality: 'Rare',         // 品质
    color: 'Red'          // 颜色
  },
  {
    id: 4,                // toeknid 不能重复，否则创建星卡失败
    level: 2,             // 级别
    starRating: 2,        // 星级
    computingPower: 2,    // 算力
    quality: 'excellent',         // 品质
    color: 'yellow'       // 颜色
  }
];

const attributes2 = [
  {
    id: 3,                // toeknid 不能重复，否则创建陨石失败
    quality: 'Rare',         // 品质
  },
  {
    id: 4,                // toeknid 不能重复，否则创建陨石失败
    quality: 'excellent',         // 品质
  },

];



function cTreasureBoxSignature(tokenId, amount, nonce) {
  // 2. 签名内容进行 solidityKeccak256格式 Hash  【--- 此处为参数类型----】   【---此处为参数值------】    
  let result = ethers.utils.solidityKeccak256(['uint256', 'uint256', 'uint256'], [tokenId, amount, nonce]);
  // 3.转成UTF8 bytes    
  let arrayifyMessage = ethers.utils.arrayify(result);
  // 4.签名    
  let signMessage = backendAdminWallet.signMessage(arrayifyMessage)
  return signMessage;
}


function dTreasureBoxSignature(tokenId, amount, price,currency, nonce) {

  // 2. 签名内容进行 solidityKeccak256格式 Hash  【--- 此处为参数类型----】   【---此处为参数值------】    
  let result = ethers.utils.solidityKeccak256(['uint256', 'uint256', 'uint256','address', 'uint256'], [tokenId, amount, price,currency, nonce]);
  // 3.转成UTF8 bytes    
  let arrayifyMessage = ethers.utils.arrayify(result);
  // 4.签名    
  let signMessage = backendAdminWallet.signMessage(arrayifyMessage)
  return signMessage;
}

function openBoxSignature(tokenId, nonce) {
  // 2. 签名内容进行 solidityKeccak256格式 Hash  【--- 此处为参数类型----】   【---此处为参数值------】    
  let result = ethers.utils.solidityKeccak256(['uint256', 'uint256'], [tokenId, nonce]);
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
 async function cTreasureBox(tokenId, amount, nonce) {

  let balanceBefore = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("购买前用户的盲盒数量:", balanceBefore.toString());

  const sign = cTreasureBoxSignature(tokenId, amount, nonce)
  const tx = await contractWithWallet.cTreasureBox(tokenId, amount, nonce, sign);

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
* @method openBox       开盲盒，创建星卡-->销毁盲盒  可以理解这两步在一个事务中
* @param  tokenId       盲盒tokenid，表示同一种盲盒
* @param  nonce         后端签名的序列号，防止重用签名
* @param  attributes    创建星卡所需要的属性，因为支持批量操作，所以这里是一个attribute数组
* @return status        交易是否成功：status: 1 (成功) 或 0 (失败)
*/
 async function openStarBox(tokenId, nonce, attributes) {

  let balanceBefore = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("开盲盒前用户的盲盒数量:", balanceBefore.toString());

  let sign = openBoxSignature(tokenId, nonce)
  let tx = await contractWithWallet.openStarBox(tokenId, nonce, sign, attributes);

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

async function dTreasureBox(tokenId, amount, price,currency, nonce) {

  let balanceBefore = await contract.balanceOf(await userWallet.getAddress(), tokenId);
  console.log("购买前用户的盲盒数量:", balanceBefore.toString());

  let _price = ethers.utils.parseUnits(price.toString() ,8);
  let sign = dTreasureBoxSignature(tokenId, amount, _price,currency, nonce)
  console.log("签名消息:", sign);
  let tx = await contractWithWallet.dTreasureBox(tokenId, amount, _price, nonce,currency, sign);

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

async function show(){
  let balanceBefore = await contract.currencys("0xA2A1C2289a878ed542152165b15cc39c59C2bcFA");
  console.log("购买前用户的盲盒数量:", balanceBefore);
}

async function set(){
  let tx = await contractWithWallet.setMeteorite("0x07e796bD996e4C71A1787F39F5bfe344A713BB2B");

  // 等待交易上链
  await tx.wait();

}




async function main(){

  // show()
  // set()
  // show()
  // (tokenId, amount, nonce) 
  // cTreasureBox(2,3,3)

  // openStarBox(tokenId, nonce, attributes)
  // openStarBox(1,2,attributes1)

  // openMeteoriteBox(tokenId, nonce, attributes2)
  // openMeteoriteBox(2,4,attributes2)

  dTreasureBox(1, 3, 1,"0xA2A1C2289a878ed542152165b15cc39c59C2bcFA", 6)
  
  // // 输出测试结果
  // console.log(result);

  // 去中心化购买
  // cBuyBox(2,3,3)
  // setMeteorite("0x349A5d5Ae61855070D99EFA9B579bF545dDB95B1")
  // openMeteoriteBox(2, 4, attributes2)

}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

