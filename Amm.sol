// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMM is ERC20 {
    IERC20 public weth;
    IERC20 public token;

    uint public reserveWeth;
    uint public reserveToken;

    event Mint(address indexed account, uint amountWeth, uint amountToken);
    event Burn(address indexed account, uint amountWeth, uint amountToken);

    event Swap(
        address indexed account,
        uint amountIn,
        address tokenIn,
        uint amountOut,
        address tokenOut
    );

    constructor(
        address addrWeth,
        address addrToken
    ) ERC20("Automated Market Maker", "AMM") {
        weth = IERC20(addrWeth);
        token = IERC20(addrToken);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function addLiquidity(
        uint amountWethDesired,
        uint amountTokenDesired
    ) public returns (uint liquidity) {
        require(
            (amountWethDesired != 0) && (amountTokenDesired != 0),
            "Cannot add liquidity"
        );
        address sender = _msgSender();
        require(
            weth.allowance(sender, address(this)) >= amountWethDesired,
            "Insufficient WETH allowance"
        );
        require(
            token.allowance(sender, address(this)) >= amountTokenDesired,
            "Insufficient Token allowance"
        );
        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = sqrt(amountWethDesired * amountTokenDesired);
        } else {
            liquidity = min(
                (amountWethDesired * _totalSupply) / reserveWeth,
                (amountTokenDesired * _totalSupply) / reserveToken
            );
        }
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        reserveWeth = weth.balanceOf(address(this));
        reserveToken = token.balanceOf(address(this));
        _mint(sender, liquidity);
        emit Mint(sender, amountWethDesired, amountTokenDesired);
    }

    function removeLiquidity(
        uint liquidity
    ) external returns (uint amountWeth, uint amountToken) {
        uint balanceWeth = weth.balanceOf(address(this));
        uint balanceToken = token.balanceOf(address(this));

        uint _totalSupply = totalSupply();
        amountWeth = (liquidity * balanceWeth) / _totalSupply;
        amountToken = (liquidity * balanceToken) / _totalSupply;

        require(
            amountWeth > 0 && amountToken > 0,
            "INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(_msgSender(), liquidity);

        weth.transfer(_msgSender(), amountWeth);
        token.transfer(_msgSender(), amountToken);

        reserveWeth = weth.balanceOf(address(this));
        reserveToken = token.balanceOf(address(this));

        emit Burn(_msgSender(), amountWeth, amountToken);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure returns (uint amountOut) {
        require(amountIn > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "INSUFFICIENT_OUTPUT_LIQUIDITY"
        );
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    function swap(
        uint amountIn,
        address addrTokenIn,
        uint amountOutMin
    ) external returns (uint amountOut, IERC20 tokenOut) {
        require(amountIn > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        IERC20 tokenIn = IERC20(addrTokenIn);
        require(tokenIn == weth || tokenIn == token, "INVALID_TOKEN");

        uint balanceWeth = weth.balanceOf(address(this));
        uint balanceToken = token.balanceOf(address(this));

        if (tokenIn == weth) {
            tokenOut = token;
            amountOut = getAmountOut(amountIn, balanceWeth, balanceToken);
            require(amountOut > amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
        } else {
            tokenOut = weth;
            amountOut = getAmountOut(amountIn, balanceToken, balanceWeth);
            require(amountOut > amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
        }
        tokenIn.transferFrom(_msgSender(), address(this), amountIn);
        tokenOut.transfer(_msgSender(), amountOut);

        reserveWeth = weth.balanceOf(address(this));
        reserveToken = token.balanceOf(address(this));

        emit Swap(
            _msgSender,
            amountIn,
            address(tokenIn),
            amountOut,
            address(tokenOut)
        );
    }
}
