
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


// import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol"
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";



library SafeERC20 { 
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IStartCard is IERC721Upgradeable {
    function mintNFT(address to, uint64 level, uint64 starRating, uint64 computingPower, string memory quality, string memory mcolor) external ;
    function getNftInfo(uint256 tokenId) external returns (uint64,uint64,uint64,uint64,string memory,string memory);
    function getNFTpower(uint256 tokenId) external returns (uint256);
}

contract Staking is Initializable, IERC721ReceiverUpgradeable, OwnableUpgradeable {
using SafeERC20 for IERC20Upgradeable;

    struct UserInfo{
        uint256 power;
        uint256 rewardDebt; 
    }
    
    uint256 public perBlock;
    IERC20Upgradeable public rewardToken;

    mapping(address=>UserInfo) public userInfo;
    mapping(uint256=>address) public ownerOf;

    struct PoolInfo {
        uint256 totalPower;
	    uint256 accPerShare; 
	    uint256 lastRewardBlock; 
    }

    PoolInfo public pool;
    address private  _StartNft;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address startNft_) initializer public {
        __Ownable_init();
        setStartNft(startNft_);
        
    }

    function stake(address to, uint256 tokenId)external {
        uint256 power =  IStartCard(_StartNft).getNFTpower(tokenId);

        updatePool();
        ownerOf[tokenId] = to;
        UserInfo storage user =  userInfo[to];
        // 结算奖励
        uint256 pending = user.power * pool.accPerShare  / 1e12 / user.rewardDebt;
        if(pending > 0){
            rewardToken.safeTransfer(msg.sender, pending);
        }
        user.power += power;
        pool.totalPower += power;
        
    }

    function withdraw(uint256 tokenId)external {
        require(ownerOf[tokenId] == msg.sender,"");
        uint256 power =  IStartCard(_StartNft).getNFTpower(tokenId);
        UserInfo storage user =  userInfo[msg.sender];

        updatePool();

        // 结算奖励
        uint256 pending = user.power * pool.accPerShare  / 1e12 / user.rewardDebt;
        if(pending > 0){
            rewardToken.safeTransfer(msg.sender, pending);
        }

        user.power -= power;
        pool.totalPower -= power;
        ownerOf[tokenId] = address(0);
       
        // 转nft给用户
        IStartCard(_StartNft).safeTransferFrom(address(this),msg.sender,tokenId);
    }


    function update(uint256 tokenId,uint256 power_) public{

        address owner = ownerOf[tokenId];
        UserInfo storage user =  userInfo[owner];

        updatePool();
        // 结算奖励
        uint256 pending = user.power * pool.accPerShare  / 1e12 / user.rewardDebt;
        if(pending > 0){
            rewardToken.safeTransfer(msg.sender, pending);
        }
        user.power += power_;
        pool.totalPower += power_;
    }


    function updatePool()internal {
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 totalPower = pool.totalPower;
        if (totalPower == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 accPerShare = pool.accPerShare;
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
          
        uint256 reward = multiplier * perBlock ;
        pool.accPerShare = accPerShare + (reward * 1e12  / pool.totalPower );
        pool.lastRewardBlock = block.number;
    }


    //     // Withdraw LP tokens from MasterChef.
    // function withdraw(uint256 _pid, uint256 _amount) public {
    //     PoolInfo storage pool = poolInfo[_pid];
    //     UserInfo storage user = userInfo[_pid][msg.sender];
    //     require(user.amount >= _amount, "withdraw: not good");
    //     updatePool(_pid);
    //     uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
    //     safeSushiTransfer(msg.sender, pending);
    //     user.amount = user.amount.sub(_amount);
    //     user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
    //     pool.lpToken.safeTransfer(address(msg.sender), _amount);
    //     emit Withdraw(msg.sender, _pid, _amount);
    // }


    function setStartNft(address startNft_) public onlyOwner {
        _StartNft = startNft_;
    }

    function StartNft()external view returns(address){
        return address(_StartNft) ;
    }

     
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

        // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
            return _to - _from ;
        
    }

        // View function to see pending SUSHIs on frontend.
    function pendingSushi( address _user) external view returns (uint256) {
        // PoolInfo storage pool = PoolInfo[_pid];
        UserInfo storage user = userInfo[_user];
        uint256 accPerShare = pool.accPerShare;
        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && pool.totalPower != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward = multiplier * perBlock ;
            accPerShare = accPerShare + (reward * 1e12  / pool.totalPower );
        }
        return user.power * accPerShare / 1e12 - user.rewardDebt;
    }

   
}