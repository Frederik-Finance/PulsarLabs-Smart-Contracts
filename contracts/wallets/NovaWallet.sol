// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../trading/Stealth.sol";


// this NFT contract will be deployed by the pulsaRouter which will be the 'owner' of it
contract NovaWallet is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    constructor(address _owner) {
        // transferOwnership(_owner);
    }
    
    fallback() external payable {}

    receive() external payable {}
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant PCS_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // meta data 
    uint expirationDate;
    uint currentPlan;

    // trading functions
    mapping(address => uint) private lastTriggeredBlock;
    mapping(address => bool) initAccount;
    mapping(bytes32 => bool) internal pathApproved;


    address public gasAccount;
    
    event AmountOut(uint buy, uint sell); // buy, sell


// validPath(path)

// make the deadline fixed three blocks from now and make the deadline parameter the amount out min
function swapExactETHForTokens(
    uint amountOutMin,
    address[] memory  path,
    address to,
    uint deadline
) public canTrade cooldown validPath(path){ 

    (bool success,  ) = address(PCS_ROUTER).call{value: amountOutMin}(
        abi.encodeWithSignature(
            "swapExactETHForTokensSupportingFeeOnTransferTokens(uint256,address[],address,uint256)",
            deadline, // deadline here; is what comes back from the simulation,
            path,
            address(this), 
            type(uint).max
        )
    );
    // require(success, "swap failed");
}


// sell a percentrage of tokenBalance
function sellSafe(
  uint sellPercentage,
  uint slippage,
  address[] memory path,
  address to) public canTrade validPath(reversePath(path)) {
    // the assets can only be transferred to either the owner or this wallet
    if(to != address(this)) {
        to = owner();
    }
    // this ensures that the tokens can only be converted to WBNB; 
    uint tokenBalance = IERC20(path[0]).balanceOf(address(this)); 
    uint wbnb_before = IERC20(WBNB).balanceOf(address(this)); 

    
    uint sell_amount = tokenBalance.mul(sellPercentage).div(100);
    IERC20(path[0]).approve(PCS_ROUTER, sell_amount);


    // bears the risk to get front-run
    // definetly also imolement the sell check there 
    (bool S, ) = address(PCS_ROUTER).call(
            abi.encodeWithSignature(
                "swapExactTokensForETH(uint256,uint256,address[],address,uint256)",
                sell_amount,
                0, //sell_amount.mul(slippage).div(100),
                path,
                to,
                type(uint).max
                )
        );
    // require(S, "swap failed");

    // uint wbnb_after = IERC20(WBNB).balanceOf(address(this));
    // uint wbnb_diff = wbnb_after - wbnb_before;
}



function swapTokens(
    uint amountOutMin,
    uint sellPercentage,
    uint slippage,
    address[] calldata path,
    address to,
    uint deadline,
    bool checkBlacklist
) public canTrade payable returns (uint, uint) { // also set the validPath
   // the input amount needs to be approximately the same as the ouput amount you get
    address target = path[path.length-1];
    uint bnb_before = address(this).balance;
    uint token_before = IERC20(target).balanceOf(address(this)); 

    swapExactETHForTokens(amountOutMin, path, to, deadline);
    uint token_after = IERC20(target).balanceOf(address(this)); 
    uint buyAmount = token_after - token_before;


    if(!checkBlacklist) {
        emit AmountOut(buyAmount, 0);
        return (buyAmount, 0);
    }

    // if blacklist check is activated
    sellSafe(sellPercentage, slippage, reversePath(path), to);

    // Calculate the amount of BNB received from sellSafe function
    uint bnb_after = address(this).balance;
    uint bnb_received = bnb_before - bnb_after;

    emit AmountOut(buyAmount, bnb_received);
    return (buyAmount,bnb_received);
}

function withdrawTokens(
    address tokenContract,  // The address of the ERC20 contract
    uint256 amount
) public canTrade {
    require(IERC20(tokenContract).balanceOf(address(this)) >= amount, "The contract do not have enough tokens to transfer");
    IERC20(tokenContract).transfer(owner(), amount);
}

function withdrawBNB(uint amount) public payable {
    require(msg.sender == address(owner()) || initAccount[msg.sender]);
    require(address(this).balance >= amount, "You tried to withdraw more than your current balance");
    (bool withdrawn, ) = address(owner()).call{
        value: amount
    }("");
    require(withdrawn, "Error during withdrawal");
}

function hashPath(address[] memory path) internal pure returns (bytes32) {
    return keccak256(abi.encode(path));
}

function unlockPath(address[] memory path) public onlyOwner {
    bytes32 pathHash = hashPath(path);
    pathApproved[pathHash] = true;
}


    // onlyOwner
    function grantInitRole(address _address) public onlyOwner  {
            initAccount[gasAccount] = false;
            initAccount[_address] = true;
            gasAccount = _address;
    }

    function revokeInitRole(address[] memory _addresses)
        public onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            initAccount[_addresses[i]] = false;
        }
    }
   
    function setExpirationDate(uint _expirationDate) public  {
    require(owner() == tx.origin);
    expirationDate = _expirationDate;
}

    function setCurrentPlan(uint _currentPlan) public  {
    require(owner() == tx.origin);
    currentPlan = _currentPlan;
}


function reversePath(address[] memory input) internal pure returns (address[] memory) {
    address[] memory result = new address[](input.length);

    for (uint i = 0; i < input.length; i++) {
        result[i] = input[input.length - i - 1];
    }

    return result;
}
modifier canTrade() {
    require(initAccount[msg.sender], "Only authorized accounts can trade, to protect the users funds");
    _;
}

// expenisive modifier, keeps the contract from executing a transaction multiple times
modifier cooldown() {
    require(block.number - lastTriggeredBlock[msg.sender] >= 3, "Function can only be called once every three blocks");
    _;
    lastTriggeredBlock[msg.sender] = block.number;
}

modifier validPath(address[] memory path) {
    bytes32 pathHash = hashPath(path);
    require(pathApproved[pathHash], "Path not approved");
    _;
}

function deleteContract() public onlyOwner {
    selfdestruct(payable(owner()));
}

}
