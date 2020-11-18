// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IProtocol.sol";
import "./interfaces/IBalancerPool.sol";

contract Minter is Initializable, Ownable {
    IBalancerPool public bPool;
    IERC20 public daiToken;
    IERC20 public claimToken;
    IERC20 public noClaimToken;
    IProtocol public protocol;
    uint48 public expirationTime;

    // Initialize, called once
    function initialize (
      IProtocol protocol_,
      IBalancerPool bPool_,
      IERC20 daiToken_,
      IERC20 claimToken_,
      IERC20 noClaimToken_,
      uint48 expirationTime_
    )
      external initializer
    {
      protocol = protocol_;
      bPool = bPool_;
      daiToken = daiToken_;
      claimToken = claimToken_;
      noClaimToken = noClaimToken_;
      expirationTime = expirationTime_;

      initializeOwner();
    }

    function provideCoverage(uint _daiAmount, address _coverageProvider) external onlyOwner {
      if (daiToken.allowance(address(this), address(protocol)) < _daiAmount) {
        daiToken.approve(address(protocol), _daiAmount);
      }
      protocol.addCover(address(daiToken), expirationTime, _daiAmount);

      uint claimAmount = claimToken.balanceOf(address(this));
      uint noClaimAmount = noClaimToken.balanceOf(address(this));
      require(_daiAmount == claimAmount);

      _swapClaimForDai(claimAmount, _coverageProvider);
      require(noClaimToken.transfer(msg.sender, noClaimAmount), "ERR_TRANSFER_FAILED");
    }

    function _swapClaimForDai(uint _sellClaimAmount, address _coverageProvider) private {
        if (claimToken.allowance(address(this), address(bPool)) < _sellClaimAmount) {
          claimToken.approve(address(bPool), _sellClaimAmount);
        }
        (uint daiAmountOut,) = IBalancerPool(bPool).swapExactAmountIn(
            address(claimToken),
            _sellClaimAmount,
            address(daiToken),
            0, // minAmountOut, set to 0 -> sell no matter how low the price of CLAIM tokens are
            2**256 - 1 // maxPrice, set to max -> accept any swap prices
        );
        if (daiAmountOut > 0) {
            require(daiToken.transfer(_coverageProvider, daiToken.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        }
    }

    receive() external payable {}
}
