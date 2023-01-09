


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';


// use a the swapmaker logic to create a minimal proxy every time




contract Simulation {
    using SafeMath for uint256;

event MakePath(address[] path);


    address private constant UNISWAP_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    function sendTransaction(address _target, address _tokenIn,  uint256 _percentage, bool _blackListModeOn) public payable {
        // determines the path, if the pair-token is not WETH this will route the trade through the pair token. 
        address[] memory path;
        revert('hier');


        // path can be an argument to the get amount out 
        if (_tokenIn == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _target;
        } else {
            path = new address[](3);
            path[0] = WETH;
            path[1] = _tokenIn;
            path[2] = _target;
        }
        emit MakePath(path);


        (bool pool_existing, bytes memory output) = UNISWAP_V2_ROUTER.call(
            abi.encodeWithSignature("getAmountsOut(uint256,address[])", msg.value, path)
        );

        require(pool_existing, "No Pool");

        uint256[] memory result = abi.decode(output, (uint256[]));
        uint256 decoded_output = result[path.length - 1].mul(_percentage).div(100);

        require(decoded_output != 0, "No Liquidity");

        (bool success,) = address(this).call{value: msg.value}(
            abi.encodeWithSignature("mySwap(address[],uint256)", path, decoded_output)
        );
        require(success, "Bad Price");

        if (_blackListModeOn) {
         address[] memory path2;


     if (_tokenIn == WETH) {
            path2= new address[](2);
            path2[0] = _target;
            path2[1] = _tokenIn;
        } 
    else {
            path2 = new address[](3);
            path2[0] = _target;
            path2[1] = _tokenIn;
            path2[2] = WETH;
        }

        
         (, bytes memory output2) = UNISWAP_V2_ROUTER.call(
            abi.encodeWithSignature("getAmountsOut(uint256,address[])", msg.value, path2)
        );

        uint256[] memory result2 = abi.decode(output2, (uint256[]));

        uint256 decoded_output2 = result2[path2.length - 1].mul(_percentage).div(100);


         (bool success2,) = address(this).call{value: msg.value}(
            abi.encodeWithSignature("mySwap(address[],uint256)", path2, decoded_output2)
        );
        require(success2, "Bad Price");
    }
    }



 function mySwap(address[] memory path, uint256 output) external payable {
        (bool S, ) = address(UNISWAP_V2_ROUTER).call{
            value: msg.value
        }(
            abi.encodeWithSignature(
                "swapExactETHForTokensSupportingFeeOnTransferTokens(uint256,address[],address,uint256)",
                output,
                path,
                address(this),
                type(uint256).max
            )
        );
        /*
        * the following prevents will save you from the token tax
        */
        require(
            IERC20(path[path.length - 1]).balanceOf(address(this)) >= output,
            "Token Tax"
        );
        require(S, "Swap Error");
    }





    // use path as input
     function getAmountOutMin(
        uint256 _amountIn,
        address[] memory path
    ) external view returns (uint256) {
        // same length as path
        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);

        // return amountOutMins[path.length - 1];
    }

}