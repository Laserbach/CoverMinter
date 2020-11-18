// SPDX-License-Identifier: No License

pragma solidity 0.6.6;

interface IBalancerPool {
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
}
