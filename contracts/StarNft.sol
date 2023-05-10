// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

interface ISTAKING{
    function stake(address to, uint256 tokenId)external;
}

contract StarNft is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    string public baseTokenURI;
    address private _staking;

    struct NFT {
        uint64 id;
        uint64 level;
        uint64 starRating;
        uint64 computingPower;
        string quality;
        string color;
    }

    mapping (uint256 => NFT) public nfts;
   
   
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("STAR NFT", "SNFT");
        __ERC721URIStorage_init();
        __Ownable_init();
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

    function mintNFT(address to,uint64 id, uint64 level, uint64 starRating, uint64 computingPower, string memory quality, string memory color) public returns (uint256) {
 
        _safeMint(_staking, id);

        nfts[id] = NFT(id, level, starRating, computingPower, quality, color);

        ISTAKING(_staking).stake(to,id);

        return id;
    }

    function getNftInfo(uint256 tokenId) public view returns (uint64,uint64,uint64,uint64,string memory,string memory) {
        NFT storage nft = nfts[tokenId];
        return (nft.id,nft.level,nft.starRating,nft.computingPower,nft.quality,nft.color);
    }
    

    function getNFT(uint256 tokenId) public view returns (NFT memory) {
        NFT storage nft = nfts[tokenId];
        return nft;
    }

    function getNFTpower(uint256 tokenId) public view returns (uint256) {
        NFT storage nft = nfts[tokenId];
        return nft.computingPower;
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

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }



}