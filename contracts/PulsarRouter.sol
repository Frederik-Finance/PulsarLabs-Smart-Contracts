// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./PulsarReferral.sol";
import "./PulsarReferralCoin.sol";
import "./Quoter.sol";
import "./wallets/NovaWallet.sol";
// import "./MinimalProxy.sol";
// import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";


contract PulsarRouter is Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PulsarReferral, Quoter
    {

  event NovaCreated(address indexed buyer, address nova);

  using SafeMath for uint256;

  struct SubscriptionPlan {
    uint256 price;
    uint256 expirationDate;
    uint discount;
  }

  // Prices of each subscription plan
  mapping(uint256 => SubscriptionPlan) public plans;
  mapping(address => address) internal subscriptions;
  address public pulsarReferralCoin;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        multiplier = 3;
        // init quoter variables
         BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
         WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
         router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    }

    function setReferralCoin(address _referralCoin) public onlyOwner {
    require(_referralCoin != address(0), "Invalid address");
    pulsarReferralCoin = _referralCoin;
    }


  // Initialize a subscription plan
  function updatePlan(
    uint256 _subscriptionId,
    uint256 _price,
    uint256 _expirationDate,
    uint _discount
  ) public onlyOwner{
    plans[_subscriptionId] = SubscriptionPlan(_price, _expirationDate, _discount);
  }


  function deletePlan(uint256 _id) public onlyOwner {
  // Set the value at the key corresponding to the plan's ID to the default value of the struct
  plans[_id] = (SubscriptionPlan)(0, 0, 0);
}

function createNovaWalletFor(address _user, uint256 _subscriptionId) public onlyOwner returns (address payable nova_address) {
    uint payment = plans[_subscriptionId].price;

    nova_address = payable(address(new NovaWallet(_user)));
    subscriptions[_user] = nova_address;
    NovaWallet(nova_address).setExpirationDate(plans[_subscriptionId].expirationDate);
    NovaWallet(nova_address).setCurrentPlan(_subscriptionId);
    emit NovaCreated(_user, nova_address);

    return nova_address;
}


function createNovaBNB(
  uint256 _subscriptionId) public payable returns (address payable nova_address) {
    uint payment = plans[_subscriptionId].price;

  // Check if user is using a referral code, and apply discount if applicable
  if (referralInUse[msg.sender][period] != bytes32(0)) {
      payment = payment.sub(payment.mul(plans[_subscriptionId].discount).div(100));
      incrementP(payment, msg.sender);
  }

  // Convert payment to BUSD using PancakeSwap router
  uint amountWbnb = quote(payment.mul(10**18));
  uint[] memory amountsOut = convertToBusd(amountWbnb);
  
  // Verify that the amount of BUSD received is sufficient to cover the subscription price
  require(amountsOut[amountsOut.length -1] > plans[_subscriptionId].price.mul(10**18), "The amount received is less than the expected amount required to create a NovaBNB. Please ensure you are sending enough funds to cover the subscription price.");

  // Create a new NovaWallet contract for the user, or update an existing one if it already exists
  if(subscriptions[msg.sender] == address(0)) {
    nova_address =  payable(address(new NovaWallet(msg.sender)));
    subscriptions[msg.sender] = nova_address;
    NovaWallet(nova_address).setExpirationDate(plans[_subscriptionId].expirationDate);
    NovaWallet(nova_address).setCurrentPlan(_subscriptionId);
    emit NovaCreated(msg.sender, nova_address);
    return nova_address;
  }
  else {
    // Get the address of the existing NovaWallet contract
    nova_address = payable(subscriptions[msg.sender]);
    NovaWallet(nova_address).setExpirationDate(plans[_subscriptionId].expirationDate);
    NovaWallet(nova_address).setCurrentPlan(_subscriptionId);
    emit NovaCreated(msg.sender, nova_address);
    return nova_address;
  }
}


  function withdrawRewards() public nonReentrant {
    require(withdrawn[msg.sender][period] == false, "Rewards already withdrawn for this period");
    uint rewards = showRewards(msg.sender, period);
    require(rewards > 0, "No rewards available for withdrawal");

    // Transfer rewards to the user
    PulsarReferralCoin(pulsarReferralCoin).transfer(msg.sender, rewards);

    // Mark rewards as withdrawn for this period
    withdrawn[msg.sender][period] = true;

}

function withdrawEther(uint256 amount) public onlyOwner {
    require(amount > 0, "Amount must be greater than zero");
    payable(owner()).transfer(amount);
}

function withdrawToken(address _tokenAddress, uint256 amount) public onlyOwner {
    require(amount > 0, "Amount must be greater than zero");
    uint256 tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
    require(tokenBalance >= amount, "Insufficient token balance");
    require(IERC20(_tokenAddress).transfer(owner(), amount), "Transfer failed");
}




}

