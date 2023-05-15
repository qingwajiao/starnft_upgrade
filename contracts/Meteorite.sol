// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Meteorite is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    string public baseTokenURI;
    mapping(uint256 =>string) public powers;
    mapping(address => bool) public operators;



    event MintMeteorite(address indexed to, uint256 indexed tokenId,string indexed power);
    event SetOperator(address indexed owner, address indexed operator,bool indexed state);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("Meteorite", "Meteorite");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    function mintMeteorite(address to ,uint256 tokenId, string memory quality)public onlyOperator {
        
        _safeMint(to, tokenId);
        powers[tokenId] = quality;
        emit MintMeteorite(to,tokenId,quality);
    }

    function burn(uint256 tokenId)public onlyOperator{
        _burn(tokenId);
        powers[tokenId] = "";
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

    function _checkOperator() internal view virtual {
        require(operators[_msgSender()], "Ownable: caller is not the owner");
    }
}