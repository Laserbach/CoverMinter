// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./ICover.sol";
import "./IERC20.sol";

interface IRedeem {
    function initialize(ICover, IERC20, IERC20) external;
    function redeemCollateral(address) external;
}
