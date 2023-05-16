// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// 0x8f3Cc0aC3ccB6f06D5D57A8825C5016E1cbe5bbf
interface ISTAKING{
    function cStake(address to, uint256 tokenId)external;
    function update(uint256 tokenId,uint256 computingPower)external;
}

interface IMeteorite{
    function powers(uint256 tokenId)external returns (string memory);
    function burn(uint256 tokenId)external;
}

contract StartCard is Initializable, ERC721Upgradeable, OwnableUpgradeable,UUPSUpgradeable {
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    string public baseTokenURI;
    address public backend;
    address public staking;
    address public  meteorite;
    mapping(address => bool) public operators;

    struct StarCard {
        uint64 id;
        uint64 level;
        uint64 starRating;
        uint64 computingPower;
        string quality;
        string color;
    }
    mapping (uint256 => StarCard) public starCards;
    
   
   event SetOperator(address indexed owner, address indexed operator,bool indexed state);
   event SetBackend(address indexed owner, address indexed backend);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("STAR CARD", "STAR");
        __Ownable_init();
        __UUPSUpgradeable_init();
        setBackend(0x51b5234307b6eB330E2b635f878db6514ea445B4);
        setMeteorite(0x07e796bD996e4C71A1787F39F5bfe344A713BB2B);
        setOperator(0xb9ef9BbF8e274c57e54A7085B6F24353C13B3620,true);

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

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mintStarCard(address to, uint64 id, uint64 level, uint64 starRating, uint64 computingPower, string memory quality, string memory color) public onlyOperator returns (uint256) {
 
        _safeMint(staking, id);

        starCards[id] = StarCard(id, level, starRating, computingPower, quality, color);

        ISTAKING(staking).cStake(to,id);

        return id;
    }

    // Upgrade level
    function upgradeLevel(uint256 starToken1, uint256[] memory starToken2s,uint256 level_, uint256 computingPower_, uint256 nonce, bytes calldata signature)external{
        checkSigner(abi.encodePacked(level_,computingPower_,nonce), signature);

        // 判断 starToken2是否存在
        for(uint256 i=0;i<starToken2s.length;i++){
            require(ownerOf(starToken2s[i]) == msg.sender,"StarNft: Not the owner");
            _burn(starToken2s[i]);
        }

        StarCard storage starCard1 = starCards[starToken1];
        starCard1.level += uint64(level_);
        starCard1.computingPower += uint64(computingPower_);

        if(ownerOf(starToken1) == staking){
            ISTAKING(staking).update(starToken1,computingPower_);
        }

    }

    // Upgrade star rating
    function upgradeStarRating(uint256 starTokenId_, uint256 meteoriteTokenId_,uint256 starRating_, uint256 computingPower_, uint256 nonce, bytes calldata signature)external{
        checkSigner(abi.encodePacked(starRating_,computingPower_,nonce), signature);
        // IMeteorite
        string memory meteoriteQuality = IMeteorite(meteorite).powers(meteoriteTokenId_);
        StarCard storage starCard = starCards[starTokenId_];
        require(keccak256(abi.encodePacked(starCard.quality))== keccak256(abi.encodePacked(meteoriteQuality)),"StarNft: different quality");
        starCard.starRating += uint64(starRating_);
        starCard.computingPower += uint64(computingPower_);

        if(ownerOf(starTokenId_) == staking){
            ISTAKING(staking).update(starTokenId_,computingPower_);
        }

        IMeteorite(meteorite).burn(meteoriteTokenId_);

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
        staking = staking_;
    }


    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setOperator(address operator,bool state)public onlyOwner {
        operators[operator] = state;
        emit SetOperator(msg.sender,operator,state);
    }

    function setBackend(address backend_) public onlyOwner {
        require(backend_ != address(0),"BlindBox: zero address error");
        backend = backend_;

        emit SetBackend(msg.sender,backend_);
    }

    function setMeteorite(address meteorite_)public onlyOwner{
        require(meteorite_ != address(0),"BlindBox: zero address error");
        meteorite = meteorite_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function checkSigner(bytes memory hash, bytes memory signature)private view{
        require( keccak256(hash).toEthSignedMessageHash().recover(signature) == backend,"wrong signer");
    }

    function _checkOperator() internal view virtual {
        require(operators[_msgSender()], "BlindBox:: caller is not the operator");
    }



}