// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


interface IStartCard {
    function mintNFT(address to,uint64 id, uint64 level, uint64 starRating, uint64 computingPower, string memory quality, string memory color) external ;
}

interface IMeteorite{
    function mintMeteorite(address to ,uint256 tokenId, string memory quality)external;
}

contract BlindBox is Initializable, ERC1155Upgradeable, OwnableUpgradeable{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    address private _backend;
    address private _usdt;
    address private  _starCard;
    address private  _meteorite;

    struct StarCardParam {
        uint64 id;
        uint64 level;
        uint64 starRating;
        uint64 computingPower;
        string quality;
        string color;
    }

    struct MeteoriteParam {
        uint64 id;
        string quality;
    }

    mapping(uint256 => bool) recordMap;

    modifier once(uint256 nonce) {
        require(!recordMap[nonce], "already transferred");
        _;
        recordMap[nonce] = true;
    }

    event SetStarCard(address indexed owner, address indexed starCard);
    event SetMeteorite(address indexed owner, address indexed meteorite);
    event SetUSDT(address indexed owner, address indexed usdt);
    event SetBackend(address indexed owner, address indexed backend);

    function initialize(address backend_)initializer public {
        __ERC1155_init("");
        __Ownable_init();
        _backend = backend_;
    }


    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }

    function setBackend(address backend_) external onlyOwner {
        require(backend_ != address(0),"BlindBox: zero address error");
        _backend = backend_;
    }

    function setStarCard(address starCard_) external onlyOwner {
        require(starCard_ != address(0),"BlindBox: zero address error");
        _starCard = starCard_;
    }

    function setMeteorite(address meteorite_)external onlyOwner {
        require(meteorite_ != address(0),"BlindBox: zero address error");
        _meteorite = meteorite_;
    }

    function setUSDT(address usdt_)external onlyOwner {
        require(usdt_ != address(0),"BlindBox: zero address error");
        _usdt = usdt_;
    }

    function meteorite()external view returns(address){
        return  _meteorite;
    }

    function starCard()external view returns(address){
        return _starCard;
    }

    function USDT()external view returns(address){
        return _usdt;
    }
    // Centralized purchase starcard
    function cTreasureBox(uint256 nftID, uint256 amount, uint256 nonce, bytes calldata signature) external once(nonce)  {
        checkSigner(abi.encodePacked(nftID, amount, nonce), signature);
        require(amount > 0 ,"BlindBox: Invalid amount");
        _mint(msg.sender, nftID, amount, "");
    }
    // Decentralized purchase starcard
    function dTreasureBox(uint256 nftID, uint256 amount, uint256 price,uint256 nonce, bytes calldata signature) external once(nonce) {
        checkSigner(abi.encodePacked(nftID, amount,price, nonce), signature);
        require(amount > 0 ,"BlindBox: Invalid amount");
        require(price !=0 && IERC20Upgradeable(_usdt).balanceOf(msg.sender) >=  amount * price,"BlindBox: price error");

        IERC20Upgradeable(_usdt).transferFrom(msg.sender,address(this) , amount * price);
        _mint(msg.sender, nftID, amount, "");
    }

    function openStarBox(uint256 tokneId,uint256 nonce,bytes calldata signature, StarCardParam[] memory args ) external once(nonce) {
        require(tokneId == 1,"BlindBox: tokneId wrong");
        checkSigner(abi.encodePacked(tokneId, nonce), signature);
        uint256 amount = args.length;
        require(balanceOf(msg.sender, tokneId) >= amount, "BlindBox: user has no such box");

        // mint startNFT
        for(uint256 i = 0;i < amount; i++){
            IStartCard(_starCard).mintNFT(msg.sender,args[i].id, args[i].level, args[i].starRating, args[i].computingPower, args[i].quality, args[i].color);
            
        }

        // burn 1155BlindBox
        _burn(msg.sender, tokneId, amount);

    }

    function openMeteoriteBox(uint256 tokneId,uint256 nonce,bytes calldata signature, MeteoriteParam[] memory args ) external once(nonce) {
        require(tokneId == 2,"BlindBox: tokneId wrong");
        checkSigner(abi.encodePacked(tokneId, nonce), signature);
        uint256 amount = args.length;
        require(balanceOf(msg.sender, tokneId) >= amount, "BlindBox: user has no such box");

        // mint startNFT
        for(uint256 i = 0;i < amount; i++){
            IMeteorite(_meteorite).mintMeteorite(_msgSender(), args[i].id, args[i].quality);
            
        }
        // burn 1155BlindBox
        _burn(msg.sender, tokneId, amount);

    }


    function withdraw() external onlyOwner {
        require(IERC20Upgradeable(_usdt).balanceOf(address(this)) > 0, "BlindBox: Balance is zero");
        require(IERC20Upgradeable(_usdt).transfer(msg.sender, IERC20Upgradeable(_usdt).balanceOf(address(this))), "BlindBox: withdraw fail");
        
    }

    function checkSigner(bytes memory hash, bytes memory signature)private view{
        require( keccak256(hash).toEthSignedMessageHash().recover(signature) == _backend,"wrong signer");
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
      string memory baseTokenURI =  super.uri(tokenId);
      return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString())) : "";
    }


}