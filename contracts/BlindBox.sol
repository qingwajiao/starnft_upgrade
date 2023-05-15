// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
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

interface IStartCard {
    function mintStarCard(address to,uint64 id, uint64 level, uint64 starRating, uint64 computingPower, string memory quality, string memory color) external ;
}

interface IMeteorite{
    function mintMeteorite(address to ,uint256 tokenId, string memory quality)external;
}

contract BlindBox is Initializable, ERC1155Upgradeable, OwnableUpgradeable,UUPSUpgradeable{

    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;
    using SafeERC20 for IERC20Upgradeable;

    address public  _backend;
    address private  _starCard;
    address private  _meteorite;
    mapping(IERC20Upgradeable => bool) public currencys;

    struct StarCardParam {
        uint64 id;
        uint64 level;
        uint64 starRating;
        uint64 computingPower;
        string quality;
        string color;
    }

    struct MeteoriteParam {
        uint256 id;
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
    event SetCurrency(address indexed owner, address indexed currency,bool indexed state);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize()public initializer  {
        __ERC1155_init("");
        __Ownable_init();
        __UUPSUpgradeable_init();
        setBackend(0x51b5234307b6eB330E2b635f878db6514ea445B4);
        setCurrency(IERC20Upgradeable(0x55d398326f99059fF775485246999027B3197955), true);

    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}


    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }

    function setCurrency(IERC20Upgradeable Currency_, bool state_) public  onlyOwner {
        currencys[Currency_] = state_;

        emit SetCurrency(msg.sender,address(Currency_) ,state_);
    }

    function setBackend(address backend_) public onlyOwner {
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

    function meteorite()external view returns(address){
        return  _meteorite;
    }

    function starCard()external view returns(address){
        return _starCard;
    }

    // Centralized purchase starcard
    function cTreasureBox(uint256 nftID, uint256 amount, uint256 nonce, bytes calldata signature) external once(nonce)  {
        checkSigner(abi.encodePacked(nftID, amount, nonce), signature);
        require(amount > 0 ,"BlindBox: Invalid amount");
        _mint(msg.sender, nftID, amount, "");
    }
    // Decentralized purchase starcard
    function dTreasureBox(uint256 nftID, uint256 amount, uint256 price,IERC20Upgradeable currency, uint256 nonce, bytes calldata signature) external once(nonce) {
        require(currencys[currency],"BlindBox: Illegal currency");
        checkSigner(abi.encodePacked(nftID, amount,price,currency, nonce), signature);
        require(amount > 0 ,"BlindBox: Invalid amount");
        require(price !=0 && IERC20Upgradeable(currency).balanceOf(msg.sender) >=  amount * price,"BlindBox: price error");

        currency.safeTransferFrom(msg.sender,address(this) , amount * price);
        _mint(msg.sender, nftID, amount, "");
    }

    function openStarBox(uint256 tokneId,uint256 nonce,bytes calldata signature, StarCardParam[] memory args ) external once(nonce) {
        require(tokneId == 1,"BlindBox: tokneId wrong");
        checkSigner(abi.encodePacked(tokneId, nonce), signature);
        uint256 amount = args.length;
        require(balanceOf(msg.sender, tokneId) >= amount, "BlindBox: user has no such box");

        // mint startNFT
        for(uint256 i = 0;i < amount; i++){
            IStartCard(_starCard).mintStarCard(msg.sender,args[i].id, args[i].level, args[i].starRating, args[i].computingPower, args[i].quality, args[i].color);
            
        }
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


    function withdraw(IERC20Upgradeable currency ) external onlyOwner {
        uint256 amount = currency.balanceOf(address(this));
        currency.safeTransfer(msg.sender, amount);
        
    }

    function checkSigner(bytes memory hash, bytes memory signature)private view{
        require( keccak256(hash).toEthSignedMessageHash().recover(signature) == _backend,"BlindBox: wrong signer");
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
      string memory baseTokenURI =  super.uri(tokenId);
      return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString())) : "";
    }


}