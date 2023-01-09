// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./TreeStructure.sol";

contract PulsarReferral is OwnableUpgradeable, TreeStructure {
   
    struct Rank {
        uint256 MinPoints;
        uint256 Reward;
    }

    struct Profile {
        address Creator; // User
        string CodeString;
        bytes32 CodeHash;
    }

    uint256 public maxRankId;
    uint public period;
    uint public multiplier;

 
    mapping(uint256 => Rank) public rank;
    mapping(address => Profile) public profiles;
    mapping(address => mapping(uint => bool)) internal withdrawn;

    mapping(bytes32 => address) internal referralCode;
    mapping(bytes32 => bool) internal referralCodeExists;
    mapping(address => mapping(uint=> bytes32)) referralInUse; 



    event Referral_Code_Created(address creator, bytes32 codehash, string codeString);
    event Referral_SignUp(address referee, address signer);


    function updateReferralRewards(uint _rank, uint _minPoints, uint _reward) public onlyOwner {
        if(_rank > maxRankId) {
            maxRankId = _rank;
        }
         rank[_rank] = Rank({MinPoints: _minPoints, Reward: _reward});
    }

 
    function incrementPeriod(uint _period) public onlyOwner {
        period ++;
    }

    function updateMultiplier(uint _multiplier) public onlyOwner {
        require(_multiplier >= 1);
        multiplier = _multiplier;
    }

   

   function incrementP(uint256 value, address sender) public {
    require(msg.sender == address(this));
    uint ps = value * multiplier;
    bytes32 rCodeInUse = referralInUse[sender][period];

    // to whom does the code belong;
    address rCodeOwner = referralCode[rCodeInUse];

    bool hasChild = nodeHasChild(rCodeOwner, period, sender);
    if(hasChild) {
        // add points
        updateNodeValue(rCodeOwner, period, ps);
    } else {
        // create new node
        addChildNode(rCodeOwner, period, ps, sender);
    }

    }

    function getRankReward(uint256 pv) public view returns (uint256 r) {
        r = 0;
        for (uint256 i = 1; i <= maxRankId; i++) { 
            if (pv < rank[i].MinPoints) {
                r = rank[i - 1].Reward;
                break;
            } 
        }
    }

    
function updateRanks(uint rankId, uint _minPoints, uint _reward) public  onlyOwner{
    rank[rankId] = Rank({ MinPoints: _minPoints, Reward: _reward });
    if (rankId + 1 >= maxRankId) {
        maxRankId = rankId + 1;
        rank[maxRankId] = Rank({
            MinPoints: type(uint256).max,
            Reward: uint256(0)
        });
    }
}



function showRewards(address sender, uint _period) public view returns (uint rewardEligible) {
    uint p;
    if (_period != period) {
        p = _period;
    } else {
        p = period;
    }
    uint256 totalPV = traverseTree(sender, p);
    uint _rankReward = getRankReward(totalPV);
    rewardEligible = _rankReward * totalPV; 
}

function showRewardsStringCode(string memory code, uint _period) public view returns (uint rewardEligible) {
    (,address rootNode )= showCode(code);
    rewardEligible = showRewards(rootNode, _period);
    
}


 
    function setReferral(string memory _referralCode) public {
    // require(referralInUse[msg.sender][period] == bytes32(0));

        (bytes32 rawRef, address creator) = showCode(_referralCode);
        referralInUse[msg.sender][period] = rawRef;

    }

    function showCode(string memory _referralCode)
        public
        view
        returns (bytes32 rawRef, address creator)
    {
        rawRef = keccak256(abi.encodePacked(_referralCode));
        require(referralCodeExists[rawRef] == true);
        creator = referralCode[rawRef];
    }

    /*
    * @idea charge a fee for code creation;
    */
    function generateReferralCode(string memory _referralCode)
        public payable
        returns (bytes32 rCode)
    {
        Profile memory profile;
   
        require(msg.sender != address(0), "Zero address");
        rCode = keccak256(abi.encodePacked(_referralCode));
        require(
            !referralCodeExists[rCode],
"Sorry, this referral code has already been claimed by another user. Please try using a different referral code.");

        profiles[msg.sender] = Profile({Creator: msg.sender, CodeString: _referralCode, CodeHash: rCode});
        referralCodeExists[rCode] = true;
        referralCode[rCode] = msg.sender;

    }    
  
}


