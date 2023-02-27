
// * return all intermediary amounts, // return the decoded_output which is necessary for the swap to work

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "./Stealth.sol";


// use a the swapmaker logic to create a minimal proxy every time
// bsc: 0x783e0E94D0bE4B20302Fd3e8F15f2755DdF74a39

contract Executor {
    // ll call to the simulation contract
    address private immutable Simulator;
    address private immutable MinimalProxy;

    constructor(address _Simulator, address _MinimalProxy) {
        Simulator = _Simulator;
        MinimalProxy = _MinimalProxy;
    }

    function startSimulation(address _target, address _tokenIn,  uint256 _percentage, bool _blackListModeOn) public payable returns (uint[] memory result ) {
        address  Simulator_Clone = Stealth(MinimalProxy).forward(payable(address(Simulator)));

         (bool success, bytes memory output) = address(Simulator_Clone).call(
            abi.encodeWithSignature("startSimulation(address,address,uitn256,bool)", _target,_tokenIn,_percentage,_blackListModeOn)
        );
        require(success, "Simulation failed");
        result = abi.decode(output, (uint256[]));


    }



}


contract Simulation {
    using SafeMath for uint256;
    
    address private constant UNISWAP_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    fallback() external payable {}

    receive() external payable {}


    function startSimulation(address _target, address _tokenIn,  uint256 _percentage, bool _blackListModeOn) public payable returns (uint[] memory result ) {
        // determines the path, if the pair-token is not WETH this will route the trade through the pair token. 

        address[] memory path;

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



        (bool pool_existing, bytes memory output) = address(UNISWAP_V2_ROUTER).call(
            abi.encodeWithSignature("getAmountsOut(uint256,address[])", msg.value, path)
        );

        require(pool_existing, "No Pool");

        result = abi.decode(output, (uint256[]));
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

        
         (, bytes memory output2) = address(UNISWAP_V2_ROUTER).call(
            abi.encodeWithSignature("getAmountsOut(uint256,address[])", msg.value, path2)
        );

        uint256[] memory result2 = abi.decode(output2, (uint256[]));

        uint256 decoded_output2 = result2[path2.length - 1].mul(_percentage).div(100);


         (bool success2,) = address(this).call(
            abi.encodeWithSignature("sellTest(address[])", path2)
        );
        require(success2, "Blacklist");
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

    
    function sellTest(address[] memory path) external payable {
        uint256 token_balance = IERC20(path[0]).balanceOf(address(this));
        (bool S, ) = address(this).call(
            abi.encodeWithSignature(
                "reverseSwap(address[],uint256)",
                path,
                token_balance
            )
        );
        require(S, "BP");
    }


    function reverseSwap(address[] memory _path, uint token_balance)
        external
        payable
    { 

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                block.timestamp,
                keccak256("0x608")
            )
        );

        address TransferTestAddress = address(uint160(uint256(hash)));

        (bool A, ) = address(_path[0]).call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                UNISWAP_V2_ROUTER,
                type(uint).max
                            )
        );

        (bool S, ) = address(UNISWAP_V2_ROUTER).call(
            abi.encodeWithSignature(
                "swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)",
                token_balance,
                0,
                _path,
                TransferTestAddress,
                type(uint256).max
            )
        );

        require(S);
    }


    // use path as input
     function getAmountOutMin(
        uint256 _amountIn,
        address[] memory path
    ) external view returns (uint256) {
        // same length as path
        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);

        return amountOutMins[path.length - 1];
    }

}