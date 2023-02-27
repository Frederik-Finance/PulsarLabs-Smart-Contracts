// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


// this NFT contract will be deployed by the pulsaRouter which will be the 'owner' of it
contract NovaTrading is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    fallback() external payable {}

    receive() external payable {}
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    mapping(address => bool) internal locktrading;
    mapping(address => bool) initializer;


   constructor() {
    // transfer ownership to the deployer
    transferOwnership(tx.origin)
}


// 108814
// samesignature
// will there be a conflict with address this.
function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata  path,
    address to,
    uint deadline
) public payable {

    address _target = path[path.length -1];
    // should get the amount out min from the simulation
    require(locktrading[_target] == false, 'locked');
    // Call the UniswapV2 Router to execute the swap
    (bool success,) = address(0x10ED43C718714eb63d5aA57B78B54704E256024E).call{value: amountOutMin}(
        abi.encodeWithSignature(
            "swapExactETHForTokensSupportingFeeOnTransferTokens(uint256,address[],address,uint256)",
            amountOutMin,
            path,
            address(this),
            deadline
        )
    );
    //109380
      if(success) {
        locktrading[_target] = true;
    }
}

//onlyOwner
function unlock(address addr) public {
    locktrading[addr] = false;
}

    address gasAccount;
    function _grantInitializerRole(address _address) internal {
            initializer[gasAccount] = false;
            initializer[_address] = true;
            gasAccount = _address;
        
    }

    function _revokeInitializerRole(address[] memory _addresses)
        internal
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            initializer[_addresses[i]] = false;
        }
    }
   
}


pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract NovaWallet is ERC721, ERC721URIStorage, Ownable, NovaTrading {
    using Counters for Counters.Counter;
    using Strings for *;

    Counters.Counter private _tokenIdCounter;

    // Add a mapping to store the owner of each token
    mapping(address => uint) public _tokenIds;
    mapping(uint256 => address) public _tokenOwners;
    mapping(uint256 => uint256) public _subscriptionIds;
    mapping(uint256 => uint256) public _expirationDates;
    mapping(uint256 => mapping(address => uint256)) private _balances;



    constructor() ERC721("NovaWallet", "NVA") {}
        function safeMint(string memory uri, uint256 subscriptionId, uint256 expirationDate, address tokenOwner) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(tokenOwner, tokenId);
        _setTokenURI(tokenId, uri);
        // Set the owner of the token to the msg.sender and store the subscription ID and expiration date

        _tokenOwners[tokenId] = tokenOwner;
        _tokenIds[tokenOwner] = tokenId;
        _subscriptionIds[tokenId] = subscriptionId;
        _expirationDates[tokenId] = block.timestamp +  expirationDate;
    }

    // Add a modifier to check if the msg.sender is the owner of the token
    modifier onlyTokenOwner(uint256 tokenId) {
        require(_tokenOwners[tokenId] == msg.sender, "You are not the owner of this token.");
        _;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

        function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        // Retrieve the subscription ID and expiration date for the token
        uint256 subscriptionId = _subscriptionIds[tokenId];
        uint256 expirationDate = _expirationDates[tokenId];

        // Generate the URI using the subscription ID and expiration date
        string memory uri = string.concat("https://example.com/nft/", tokenId.toString(), "/", subscriptionId.toString(), "/", expirationDate.toString());
        // string memory uri = string.concat("https://example.com/nft/", "/");
    }


function withdrawTokens(
    address tokenContract,  // The address of the ERC20 contract
    uint256 amount,
    uint tokenId  // The amount of tokens to withdraw
) public onlyTokenOwner(tokenId) {
    // Ensure that the msg.sender is the owner of the token
    require(_tokenOwners[tokenId] == msg.sender, "You are not the owner of this token.");
    // Call the ERC20 contract to transfer the tokens from the contract to the owner
    IERC20(tokenContract).transfer(msg.sender, amount);
}

 function withdrawBNB(uint amount, uint tokenId) public payable onlyTokenOwner(tokenId) {
        require(address(this).balance > amount, "You tried to withdraw more than your current Balance");
        (bool withdrawn, ) = address(_tokenOwners[tokenId]).call{
            value: amount
        }("");
        require(withdrawn, "Error during withdrawal");
    }

    function grantInitializerRole(address gasAccount, uint tokenId) public onlyTokenOwner(tokenId) {
        _grantInitializerRole(gasAccount);
    }

    function revokeInitializerRole(address[] memory addresses, uint tokenId) public onlyTokenOwner(tokenId) {
        _revokeInitializerRole(addresses);
    }

    
function setSubscriptionId(uint256 tokenId, uint256 subscriptionId) public onlyOwner {
  _subscriptionIds[tokenId] = subscriptionId;
}

function setExpirationDate(uint256 tokenId, uint256 expirationDate) public onlyOwner {
  _expirationDates[tokenId] = expirationDate;
}

function getBalance(uint256 tokenId, address owner) public view onlyTokenOwner(tokenId) returns (uint) {
  return _balances[tokenId][owner];
}

}
