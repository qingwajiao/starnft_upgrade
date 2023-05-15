
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol"
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IStartCard is IERC721Upgradeable {
    function mintNFT(address to, uint64 level, uint64 starRating, uint64 computingPower, string memory quality, string memory mcolor) external ;
    function getNftInfo(uint256 tokenId) external returns (uint64,uint64,uint64,uint64,string memory,string memory);
    function getNFTpower(uint256 tokenId) external returns (uint256);
}

contract Staking is Initializable, IERC721ReceiverUpgradeable, OwnableUpgradeable {


    struct UserInfo{
        uint256 power;
        int256 rewardDebt; 
    }

    mapping(address=>UserInfo) public userinfo;
    mapping(uint256=>address) public ownerOf;

    struct PoolInfo {
        uint256 totalPower;
	    uint128 accSushiPerShare; 
	    uint64 lastRewardBlock; 
    }

    PoolInfo public  p;
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
        ownerOf[tokenId] = to;
        UserInfo storage u =  userinfo[to];
        u.power += power;
        updatePool();

        p.totalPower += power;
    }

    function withdraw(uint256 tokenId)external {
        require(ownerOf[tokenId] == msg.sender,"");
        uint256 power =  IStartCard(_StartNft).getNFTpower(tokenId);
        UserInfo storage u =  userinfo[msg.sender];
        u.power -= power;
        ownerOf[tokenId] = address(0);
        // 结算奖励
        updatePool();
        // 转nft给用户
        IStartCard(_StartNft).safeTransferFrom(address(this),msg.sender,tokenId);
    }

    // 更新算力池
    function updatePool() internal {

    }


    function setStartNft(address startNft_) public onlyOwner {
        _StartNft = startNft_;
    }

    function StartNft()external view returns(address){
        return address(_StartNft) ;
    }

     
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}