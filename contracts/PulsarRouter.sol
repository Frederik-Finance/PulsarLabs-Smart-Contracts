// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "./PulsarReferral.sol";
import "./PulsarReferralCoin.sol";
import "./Quoter.sol";
import "./wallets/NovaWallet.sol";

contract PulsarRouter is Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PulsarReferral, Quoter
    {

  using SafeMath for uint256;

  struct SubscriptionPlan {
    uint256 price;
    uint256 expirationDate;
    uint discount;
  }

  // Prices of each subscription plan
  mapping(uint256 => SubscriptionPlan) public plans;
  IERC20 public StableCoin;

  // Address of the NOVA contract
  NovaWallet public NOVA;
  PulsarReferralCoin public pulsarReferralCoin ;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        //   pulsarReferralCoin = new PulsarReferralCoin();
        // NOVA = new NovaWallet();
        StableCoin = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
        // init PulsarReferralVariables
        multiplier = 3;
        // init quoter variables
         BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
         WBNB =0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    }


    // function initContracts() public onlyOwner {
    //   pulsarReferralCoin = new PulsarReferralCoin();
    //   NOVA = new NovaWallet();
    // }

  // Initialize a subscription plan
  function updatePlan(
    uint256 _subscriptionId,
    uint256 _price,
    uint256 _expirationDate,
    uint _discount
  ) public {
    plans[_subscriptionId] = SubscriptionPlan(_price, _expirationDate, _discount);
  }


  function deletePlan(uint256 _id) public onlyOwner {
  // Set the value at the key corresponding to the plan's ID to the default value of the struct
  plans[_id] = (SubscriptionPlan)(0, 0, 0);
}

// the buy function will be more difficult
// referralCode ? 
// buy or upgrade ? 
// pay with BUSD or BNB

// on the front end call quote first;
function mintNovaBnB(address _owner,
  uint256 _subscriptionId,
  string memory _uri) public payable {
    uint payment = plans[_subscriptionId].price;

  if (referralInUse[msg.sender][period] != bytes32(0)) {
      payment = payment.sub(payment.mul(plans[_subscriptionId].discount).div(100));
      incrementP(payment, msg.sender);
    }

  // perform the check for the funcion here
  uint amountWbnb = quote(payment);
  convertToBusd(amountWbnb);

  if(NOVA.balanceOf(msg.sender) == 0) {
        NOVA.safeMint(_uri, _subscriptionId, plans[_subscriptionId].expirationDate, _owner); 
    } else {
      uint Id = NOVA._tokenIds(msg.sender);
      require(NOVA._expirationDates(Id) < block.timestamp, "Plan not expired yet");
      NOVA.setExpirationDate(Id, plans[_subscriptionId].expirationDate);
      NOVA.setSubscriptionId(Id, _subscriptionId);
    }

    // if the user uses a referralCode then the increment p function needs to be called
 

  }



  // if in referral program then increment him; 
  

// here approve
function mintNova(
  address _owner,
  uint256 _subscriptionId,
  string memory _uri
) public {
  uint payment = plans[_subscriptionId].price;

  // Ensure that the sender has enough StableCoin balance to pay for the subscription plan
  require(StableCoin.balanceOf(msg.sender) >= payment, "Insufficient StableCoin balance");
  // Mint the NOVA
  // Transfer the cost of the subscription plan from the sender's StableCoin balance
  StableCoin.transferFrom(msg.sender, address(this), payment);

  NOVA.safeMint(_uri, _subscriptionId, plans[_subscriptionId].expirationDate, _owner); 
}



function changeStableCoin(address _StableCoin) public onlyOwner {
  StableCoin = IERC20(_StableCoin);

}

}

