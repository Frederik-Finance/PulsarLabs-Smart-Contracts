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
        transferOwnership(_owner);
    }
    fallback() external payable {}

    receive() external payable {}
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant PCS_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // meta data 
    uint expirationDate;
    uint currentPlan;

    // trading functions
    mapping(address => bool) internal unlocktrading;
    mapping(address => bool) init_account;
    address public gasAccount;

    event Outs(uint amount);


// make the deadline fixed three blocks from now and make the deadline parameter the amount out min
function swapExactETHForTokens(
    uint amountOutMin,
    address[] memory  path,
    address to,
    uint deadline
) public payable can_trade {
    address _target = path[path.length -1];
    // should get the amount out min from the simulation
    require(unlocktrading[_target] == true, 'locked');
    // Call the UniswapV2 Router to execute the swap
    uint before_balance = IERC20(_target).balanceOf(address(this)); 

    (bool success,  ) = address(PCS_ROUTER).call{value: amountOutMin}(
        abi.encodeWithSignature(
            "swapExactETHForTokensSupportingFeeOnTransferTokens(uint256,address[],address,uint256)",
            0,
            path,
            address(this), 
            deadline
        )
    );

    uint after_balance = IERC20(_target).balanceOf(address(this)); 

    // uint[] outs = abi.decode(output, (uint256[]))
    emit Outs(after_balance - before_balance);

    
      if(success) {
        unlocktrading[_target] = false;
    }
}


// sell a percentrage of tokenBalance
function sell_safe(
  uint sell_percentage,
  uint slippage,
  address[] memory path,
  address to,
  uint deadline) public can_trade {
    // the assets can only be transferred to either the owner or this wallet
    if(to != address(this)) {
        to = owner();
    }
    // this ensures that the tokens can only be converted to WBNB; 
    require(path[path.length -1] == WBNB, "Output needs to be BNB");
    uint token_balance = IERC20(path[0]).balanceOf(address(this)); 
    uint wbnb_before = IERC20(WBNB).balanceOf(address(this)); 

    
    uint sell_amount = token_balance.mul(sell_percentage).div(100);
    IERC20(path[path.length -1]).approve(PCS_ROUTER, sell_amount);

    (bool S, ) = address(PCS_ROUTER).call(
            abi.encodeWithSignature(
                "swapExactTokensForETH(uint256,uint256,address[],address,uint256)",
                sell_amount,
                sell_amount.mul(slippage).div(100),
                path,
                to,
                deadline
                )
        );

    uint wbnb_after = IERC20(WBNB).balanceOf(address(this));
    uint wbnb_diff = wbnb_after - wbnb_before;
    emit Outs(wbnb_diff);    
}



function swapTokens(
    uint amountOutMin,
    uint sell_percentage,
    uint slippage,
    address[] calldata path,
    address to,
    uint deadline,
    bool checkBlacklist
) public can_trade payable returns (uint) {
   // the input amount needs to be approximately the same as the ouput amount you get
    address target = path[path.length-1];
    uint wbnb_before = address(this).balance;
    uint token_before = IERC20(target).balanceOf(address(this)); 

    swapExactETHForTokens(amountOutMin, path, to, deadline);
    uint token_after = IERC20(target).balanceOf(address(this)); 

    if(!checkBlacklist) {
        return token_after - token_before;
    }

    // if blacklist check is activated
    sell_safe(sell_percentage, slippage, reversePath(path), to, deadline);

    // Calculate the amount of BNB received from sell_safe function
    uint wbnb_after = address(this).balance;
    uint wbnb_received = wbnb_before - wbnb_after;

    return wbnb_received;
}


function unlock(address token) public onlyOwner {
    unlocktrading[token] = true;
}

function withdrawTokens(
    address tokenContract,  // The address of the ERC20 contract
    uint256 amount
) public can_trade {
    IERC20(tokenContract).transfer(owner(), amount);
}

function withdrawAllTokens(address tokenContract, uint amount) public can_trade {
    require(IERC20(tokenContract).balanceOf(address(this)) >= amount, "The contract do not have enough tokens to transfer");
    IERC20(tokenContract).transfer(owner(), amount);
}

function withdrawBNB(uint amount) public payable can_trade {
    require(address(this).balance >= amount, "You tried to withdraw more than your current balance");
    (bool withdrawn, ) = address(owner()).call{
        value: amount
    }("");
    require(withdrawn, "Error during withdrawal");
}



    // onlyOwner
    function grantInitRole(address _address) public  {
            init_account[gasAccount] = false;
            init_account[_address] = true;
            gasAccount = _address;
    }

    function revokeInitRole(address[] memory _addresses)
        public onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            init_account[_addresses[i]] = false;
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

modifier can_trade() {
    require(init_account[msg.sender], "Only authorized accounts can trade, to protect the users funds");
    _;
}

function reversePath(address[] memory input) internal pure returns (address[] memory) {
    address[] memory result = new address[](input.length);

    for (uint i = 0; i < input.length; i++) {
        result[i] = input[input.length - i - 1];
    }

    return result;
}


}
