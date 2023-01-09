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
