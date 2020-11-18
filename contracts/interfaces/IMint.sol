// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./IProtocol.sol";
import "./IBalancerPool.sol";
import "./IERC20.sol";

interface IMint {
    function initialize(IProtocol, IBalancerPool, IERC20, IERC20, IERC20, uint48) external;
    function provideCoverage(uint, address) external;
}
