pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';



contract Quoter {
  using SafeMath for uint256;

  address public BUSD;
  address public WBNB;
  address public router;

function quote(uint256 amount) public returns (uint256 wbnb) {

address[] memory path;
  path = new address[](2);
  path[0] = BUSD;
  path[1] = WBNB;
  uint[] memory amountsOut = IUniswapV2Router02(router).getAmountsOut(amount.mul(10**18) ,path);

  // wbnb = amountsOut[amountsOut.length -1];


}

//convertEthToBUSD
function convertToBusd(uint amount) public payable returns (uint[] memory) {
  address[] memory path;
  path = new address[](2);
  path[0] = WBNB;
  path[1] = BUSD;
  uint[] memory amountsOut = IUniswapV2Router02(router).swapExactETHForTokens{value: msg.value}(amount ,path, address(this), type(uint).max);
  return amountsOut;
}


}
