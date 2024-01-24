// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ERC20 {

    IERC20 public token0;
    IERC20 public token1;

    uint256 public reserve0;
    uint256 public reserve1;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Swap(
        address indexed sender,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut
    );

    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) public returns (uint256 liquidity) {
        token0.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);

        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = sqrt(amount0Desired * amount1Desired);
        } else {
            liquidity = min(
                (amount0Desired * _totalSupply) / reserve0,
                (amount1Desired * _totalSupply) / reserve1
            );
        }

        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");

        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        _mint(msg.sender, liquidity);

        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

    function removeLiquidity(
        uint256 liquidity
    ) external returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        uint256 _totalSupply = totalSupply();
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_BURNED");

        _burn(msg.sender, liquidity);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);

        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    function swap(
        uint256 amountIn,
        IERC20 tokenIn,
        uint256 amountOutMin
    ) external returns (uint256 amountOut, IERC20 tokenOut) {
        require(amountIn > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(tokenIn == token0 || tokenIn == token1, "INVALID_TOKEN");

        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        if (tokenIn == token0) {
            tokenOut = token1;
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        } else {
            tokenOut = token0;

            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }

        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Swap(
            msg.sender,
            amountIn,
            address(tokenIn),
            amountOut,
            address(tokenOut)
        );
    }
}
