pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';


contract Quoter {
  using SafeMath for uint256;
  using Address for address;

  address public BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
  address public constant WBNB =0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

//   function quote(uint256 amount) public view returns (uint256) {
//     (, uint256 wbnb) = router.call(bytes4(bytes32(0xf01b3b42)), BUSD, amount);
//     return wbnb;
//   }



function quote(uint256 amount) public returns (uint256 wbnb) {

// (, bytes memory wbnb_encoded) = address(router).call(abi.encodeWithSignature("getAmountOut(uint256,address[])", amount, [BUSD, WBNB]));

// uint256[] memory wbnb_decoded = abi.decode(
//                 wbnb_encoded,
//                 (uint256[])
//             );
//  wbnb = wbnb_decoded[wbnb_decoded.length - 1];

address[] memory path;
  path = new address[](2);
  path[0] = WBNB;
  path[1] = BUSD;
  IUniswapV2Router02(router).getAmountsOut(amount ,path);

}

function convertToBusd(uint amount) public payable {
  address[] memory path;
  path = new address[](2);
  path[0] = WBNB;
  path[1] = BUSD;
  IUniswapV2Router02(router).swapExactETHForTokens{value: msg.value}(amount ,path, address(this), type(uint).max);
}


}
