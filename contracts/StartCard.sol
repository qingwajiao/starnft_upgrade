// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol"; 

interface ISTAKING{
    function stake(address to, uint256 tokenId)external;
    function update(uint256 tokenId,uint256 computingPower)external;
}

interface IMeteorite{
    function getQuality(uint256 tokenId)external returns (string memory);
    function burn(uint256 tokenId)external;
}

contract StartCard is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    string public baseTokenURI;
    address private _backend;
    address private _staking;
    address private _meteorite;

    struct StarCard {
        uint64 id;
        uint64 level;
        uint64 starRating;
        uint64 computingPower;
        string quality;
        string color;
    }

    mapping (uint256 => StarCard) public starCards;
    mapping(address => bool) public operators;
   
   event SetOperator(address indexed owner, address indexed operator,bool indexed state);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("STAR CARD", "STAR");
        __ERC721URIStorage_init();
        __Ownable_init();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mintStarCard(address to,uint64 id, uint64 level, uint64 starRating, uint64 computingPower, string memory quality, string memory color) public onlyOperator returns (uint256) {
 
        _safeMint(_staking, id);

        starCards[id] = StarCard(id, level, starRating, computingPower, quality, color);

        ISTAKING(_staking).stake(to,id);

        return id;
    }

    // Upgrade level
    function upgradeLevel(uint256 starToken1, uint256[] memory starToken2s,uint256 level_, uint256 computingPower_,bytes calldata signature)external{
        checkSigner(abi.encodePacked(starToken1, level_,computingPower_), signature);

        // 判断 starToken2是否存在
        for(uint256 i=0;i<starToken2s.length;i++){
            require(ownerOf(starToken2s[i]) == msg.sender,"StarNft: Not the owner");
            _burn(starToken2s[i]);
        }

        StarCard storage starCard1 = starCards[starToken1];
        starCard1.level += uint64(level_);
        starCard1.computingPower += uint64(computingPower_);

        if(ownerOf(starToken1) == _staking){
            ISTAKING(_staking).update(starToken1,computingPower_);
        }

    }

    // Upgrade star rating
    function upgradeStarRating(uint256 starTokenId_, uint256 meteoriteTokenId_,uint256 starRating_, uint256 computingPower_,bytes calldata signature)external{
        checkSigner(abi.encodePacked(starTokenId_, meteoriteTokenId_, starRating_,computingPower_), signature);
        // IMeteorite
        string memory meteoriteQuality = IMeteorite(_meteorite).getQuality(meteoriteTokenId_);
        StarCard storage starCard = starCards[starTokenId_];
        require(keccak256(abi.encodePacked(starCard.quality))== keccak256(abi.encodePacked(meteoriteQuality)),"StarNft: different quality");
        starCard.starRating += uint64(starRating_);
        starCard.computingPower += uint64(computingPower_);

        if(ownerOf(starTokenId_) == _staking){
            ISTAKING(_staking).update(starTokenId_,computingPower_);
        }

        IMeteorite(_meteorite).burn(meteoriteTokenId_);

    }

    function getNftInfo(uint256 tokenId) public view returns (uint64,uint64,uint64,uint64,string memory,string memory) {
        StarCard storage nft = starCards[tokenId];
        return (nft.id,nft.level,nft.starRating,nft.computingPower,nft.quality,nft.color);
    }
    

    function getNFT(uint256 tokenId) public view returns (StarCard memory) {
        StarCard storage nft = starCards[tokenId];
        return nft;
    }

    function getNFTpower(uint256 tokenId) public view returns (uint256) {
        StarCard storage starCard = starCards[tokenId];
        return starCard.computingPower;
    }

    function setstaking(address staking_)external onlyOwner {
        _staking = staking_;
    }

    function taking()external view returns(address){
        return _staking ;
    }


    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setOperator(address operator,bool state)external onlyOwner {
        operators[operator] = state;
        emit SetOperator(msg.sender,operator,state);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function checkSigner(bytes memory hash, bytes memory signature)private view{
        require( keccak256(hash).toEthSignedMessageHash().recover(signature) == _backend,"wrong signer");
    }

    function _checkOperator() internal view virtual {
        require(operators[_msgSender()], "Ownable: caller is not the owner");
    }



}