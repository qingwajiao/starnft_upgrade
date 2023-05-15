
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


// import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol"
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";



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

contract Staking is Initializable, IERC721ReceiverUpgradeable, OwnableUpgradeable ,UUPSUpgradeable{
    using SafeERC20 for IERC20Upgradeable;

    struct UserInfo{
        uint256 power;
        uint256 rewardDebt; 
        // uint256[] starCards; 
    }
    
    uint256 public perBlock;
    IERC20Upgradeable public rewardToken;

    mapping(address=>UserInfo) public userInfo;
    mapping(uint256=>address) public ownerOf;
    mapping(address => bool) public operators;

    struct PoolInfo {
        uint256 totalPower;
	    uint256 accPerShare; 
	    uint256 lastRewardBlock; 
    }

    PoolInfo public pool;
    address public  starCard;

    event SetOperator(address indexed owner, address indexed operator,bool indexed state);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        setStarCard(0x9D7f74d0C41E726EC95884E0e97Fa6129e3b5E99);
        
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /**
     * @dev Throws if called by any account other than the Operator.
     */
    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    function cStake(address to, uint256 tokenId)public onlyOperator {
        uint256 power =  IStartCard(starCard).getNFTpower(tokenId);

        updatePool();
        ownerOf[tokenId] = to;
        UserInfo storage user =  userInfo[to];

        if(user.power > 0){
            // 结算奖励
            uint256 pending = user.power * pool.accPerShare  / 1e12 - user.rewardDebt;
            rewardToken.safeTransfer(msg.sender, pending);
        }
 
        user.power += power;
        user.rewardDebt = user.power * pool.accPerShare  / 1e12 ;
        pool.totalPower += power;
        
    }

    function dStake( uint256 tokenId)public {
        address owner = msg.sender;
        require(IStartCard(starCard).ownerOf(tokenId) == owner,"Staking: Not the owner");
        uint256 power =  IStartCard(starCard).getNFTpower(tokenId);

        updatePool();
        ownerOf[tokenId] = owner;
        UserInfo storage user =  userInfo[owner];

        if(user.power > 0){
            // 结算奖励
            uint256 pending = user.power * pool.accPerShare  / 1e12 - user.rewardDebt;
            rewardToken.safeTransfer(owner, pending);
        }
 
        user.power += power;
        user.rewardDebt = user.power * pool.accPerShare  / 1e12 ;
        pool.totalPower += power;
        
    }

    function withdraw(address to, uint256 tokenId)external {
        require(ownerOf[tokenId] == msg.sender,"Staking: Not the owner");
        uint256 power =  IStartCard(starCard).getNFTpower(tokenId);
        UserInfo storage user =  userInfo[msg.sender];

        updatePool();

        if(user.power > 0){
            // 结算奖励
            uint256 pending = user.power * pool.accPerShare  / 1e12 - user.rewardDebt;
            rewardToken.safeTransfer(to, pending);
        }

        user.power -= power;
        user.rewardDebt = user.power * pool.accPerShare  / 1e12 ;
        pool.totalPower -= power;
        ownerOf[tokenId] = address(0);
       
        // 转nft给用户
        IStartCard(starCard).safeTransferFrom(address(this),to,tokenId);
    }


    function update(uint256 tokenId,uint256 power_) public onlyOperator {

        address owner = ownerOf[tokenId];
        UserInfo storage user =  userInfo[owner];

        updatePool();
        // 结算奖励
        if(user.power > 0){
            // 结算奖励
            uint256 pending = user.power * pool.accPerShare  / 1e12 - user.rewardDebt;
            rewardToken.safeTransfer(msg.sender, pending);
        }
        user.power += power_;
        user.rewardDebt = user.power * pool.accPerShare  / 1e12 ;
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


    function setStarCard(address starCard_) public onlyOwner {
        require(address(starCard_) != address(0),"Staking: Zero address error");
        starCard = starCard_;
    }

    function setRewardToken(IERC20Upgradeable rewardToken_ )external onlyOwner{
        require(address(rewardToken_) != address(0),"Staking: Zero address error");
         rewardToken = rewardToken_;
    }
    function setOperator(address operator,bool state)external onlyOwner {
        operators[operator] = state;
        emit SetOperator(msg.sender,operator,state);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

        // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
            return _to - _from ;
        
    }

        // View function to see pending SUSHIs on frontend.
    function pendingReward( address _user) external view returns (uint256) {
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

    function _checkOperator() internal view virtual {
        require(operators[_msgSender()], "Ownable: caller is not the owner");
    }

   
}