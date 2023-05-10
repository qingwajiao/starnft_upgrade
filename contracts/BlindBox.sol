// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


interface IstartNFT {
    function mintNFT(address to,uint64 id, uint64 level, uint64 starRating, uint64 computingPower, string memory quality, string memory color) external ;
    function getNFT(uint256 tokenId) external;
}

contract BlindBox is Initializable, ERC1155Upgradeable, OwnableUpgradeable{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    address private _backend;
    address private _USDT;
    address private  _StartNft;

    struct Attribute {
        uint64 id;
        uint64 level;
        uint64 starRating;
        uint64 computingPower;
        string quality;
        string color;
    }

    struct BlindBoxAmount{
        uint256 total;
        uint256 unopenedAmount;
    }
    mapping(uint256 =>BlindBoxAmount ) public blindBoxAmounts;
    mapping(uint256 => bool) recordMap;

    modifier once(uint256 nonce) {
        require(!recordMap[nonce], "already transferred");
        _;
        recordMap[nonce] = true;
    }

    event CBuyBox(address indexed user, uint256 indexed tokenID, uint256 indexed amount);
    event DBuyBox(address indexed user, uint256 indexed tokenID, uint256 indexed amount,uint256 price);
    event OpenBox(address indexed user, uint256 indexed tokenID, uint256 indexed amount);

    function initialize(address backend_)initializer public {
        __ERC1155_init("");
        __Ownable_init();
        _backend = backend_;
    }


    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }

    function setBackend(address backend_) external onlyOwner {
        _backend = backend_;
    }

    function setStartNft(address startNft_) external onlyOwner {
        _StartNft = startNft_;
    }

    function setUSDT(address usdt_)external onlyOwner {
        _USDT = usdt_;
    }

    function StartNft()external view returns(address){
        return address(_StartNft) ;
    }

    function USDT()external view returns(address){
        return _USDT;
    }
// Centralized purchasing
    function cBuyBox(uint256 nftID, uint256 amount, uint256 nonce, bytes calldata signature) external once(nonce)  {
        checkSigner(abi.encodePacked(nftID, amount, nonce), signature);
        require(amount > 0 ,"BlindBox: Invalid amount");
        _mint(msg.sender, nftID, amount, "");

        emit CBuyBox(msg.sender,nftID,amount);
    }
    // Decentralized purchasing
    function dBuyBox(uint256 nftID, uint256 amount, uint256 price,uint256 nonce, bytes calldata signature) external once(nonce) {
        checkSigner(abi.encodePacked(nftID, amount,price, nonce), signature);
        require(amount > 0 ,"BlindBox: Invalid amount");
        require(IERC20Upgradeable(_USDT).balanceOf(msg.sender) >=  amount * price,"BlindBox: Insufficient amount");

        IERC20Upgradeable(_USDT).transferFrom(msg.sender,address(this) , amount * price);
        _mint(msg.sender, nftID, amount, "");

        emit DBuyBox(msg.sender,nftID,amount,price);
    }

    function openBox(uint256 nftID,uint256 nonce,bytes calldata signature, Attribute[] memory args ) external once(nonce) {
        checkSigner(abi.encodePacked(nftID, nonce), signature);
        uint256 amount = args.length;
        require(balanceOf(msg.sender, nftID) >= amount, "BlindBox: user has no such box");

        // mint startNFT
        for(uint256 i = 0;i < amount; i++){
            IstartNFT(_StartNft).mintNFT(msg.sender,args[i].id, args[i].level, args[i].starRating, args[i].computingPower, args[i].quality, args[i].color);
            
        }

        // burn 1155BlindBox
        _burn(msg.sender, nftID, amount);

        emit OpenBox(msg.sender,nftID,amount);

    }



    function withdraw() external onlyOwner {
        require(IERC20Upgradeable(_USDT).balanceOf(address(this)) > 0, "BlindBox: Balance is zero");
        require(IERC20Upgradeable(_USDT).transfer(msg.sender, IERC20Upgradeable(_USDT).balanceOf(address(this))), "BlindBox: withdraw fail");
        
    }

    function checkSigner(bytes memory hash, bytes memory signature)private view{
        require( keccak256(hash).toEthSignedMessageHash().recover(signature) == _backend,"wrong signer");
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
      string memory baseTokenURI =  super.uri(tokenId);
      return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString())) : "";
    }






}