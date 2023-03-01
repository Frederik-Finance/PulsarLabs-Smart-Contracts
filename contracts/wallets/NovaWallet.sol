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
    mapping(address => uint) private lastTriggeredBlock;
    // mapping(address[] => bool) internal pathApproved; // can not be an array
    mapping(address => bool) initAccount;

    address public gasAccount;
    
    event Outs(uint amount);
    event AmountOut(uint amount); // buy, sell


// validPath(path)

// make the deadline fixed three blocks from now and make the deadline parameter the amount out min
function swapExactETHForTokens(
    uint amountOutMin,
    address[] memory  path,
    address to,
    uint deadline
) public payable canTrade  validPath(path){ 
    address _target = path[path.length -1];
    // should get the amount out min from the simulation
    // Call the UniswapV2 Router to execute the swap
    uint before_balance = IERC20(_target).balanceOf(address(this));

    // Nova is only for ICOs
    // if(before_balance > 1) {
    //     revert('Token balance needs to be smaller than 1 before trading');
    // } 

    (bool success,  ) = address(PCS_ROUTER).call{value: amountOutMin}(
        abi.encodeWithSignature(
            "swapExactETHForTokensSupportingFeeOnTransferTokens(uint256,address[],address,uint256)",
            0, // deadline here; is what comes back from the simulation
            path,
            address(this), 
            type(uint).max
        )
    );

    uint after_balance = IERC20(_target).balanceOf(address(this)); 

    // uint[] outs = abi.decode(output, (uint256[]))
    emit Outs(after_balance - before_balance);

    
    //   if(success) {
    //     pathApproved[_target] = false;
    // }
}


// sell a percentrage of tokenBalance
function sell_safe(
  uint sell_percentage,
  uint slippage,
  address[] memory path,
  address to,
  uint deadline) public canTrade validPath(reversePath(path)) {
    // the assets can only be transferred to either the owner or this wallet
    if(to != address(this)) {
        to = owner();
    }
    // this ensures that the tokens can only be converted to WBNB; 

    uint token_balance = IERC20(path[0]).balanceOf(address(this)); 
    uint wbnb_before = IERC20(WBNB).balanceOf(address(this)); 

    
    uint sell_amount = token_balance.mul(sell_percentage).div(100);
    IERC20(path[0]).approve(PCS_ROUTER, sell_amount);

    (bool S, ) = address(PCS_ROUTER).call(
            abi.encodeWithSignature(
                "swapExactTokensForETH(uint256,uint256,address[],address,uint256)",
                sell_amount,
                0, //sell_amount.mul(slippage).div(100),
                path,
                to,
                deadline
                )
        );
    require(S, "swap failed");

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
) public canTrade payable returns (uint) { // also set the validPath
   // the input amount needs to be approximately the same as the ouput amount you get
    address target = path[path.length-1];
    uint wbnb_before = address(this).balance;
    uint token_before = IERC20(target).balanceOf(address(this)); 

    swapExactETHForTokens(amountOutMin, path, to, deadline);
    uint token_after = IERC20(target).balanceOf(address(this)); 

    if(!checkBlacklist) {
        uint out = token_after - token_before;
        emit AmountOut(out);
        return out;
    }

    // if blacklist check is activated
    sell_safe(sell_percentage, slippage, reversePath(path), to, deadline);

    // Calculate the amount of BNB received from sell_safe function
    uint wbnb_after = address(this).balance;
    uint wbnb_received = wbnb_before - wbnb_after;

    emit AmountOut(wbnb_received);
    return wbnb_received;
}


function withdrawTokens(
    address tokenContract,  // The address of the ERC20 contract
    uint256 amount
) public canTrade {
    IERC20(tokenContract).transfer(owner(), amount);
}

function withdrawAllTokens(address tokenContract, uint amount) public canTrade {
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

    // onlyOwner
    function grantInitRole(address _address) public  {
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

modifier cooldown() {
    require(block.number - lastTriggeredBlock[msg.sender] >= 5, "Function can only be called once every three blocks");
    _;
    lastTriggeredBlock[msg.sender] = block.number;
}


function hashPath(address[] memory path) internal pure returns (bytes32) {
    return keccak256(abi.encode(path));
}

function unlockPath(address[] memory path) public onlyOwner {
    bytes32 pathHash = hashPath(path);
    pathApproved[pathHash] = true;
}

mapping(bytes32 => bool) internal pathApproved;

modifier validPath(address[] memory path) {
    bytes32 pathHash = hashPath(path);
    require(pathApproved[pathHash], "Path not approved");
    _;
}




}
