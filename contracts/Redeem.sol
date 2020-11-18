// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ICover.sol";

contract Redeem is Initializable, Ownable {
    IERC20 public daiToken;
    IERC20 public noClaimToken;
    ICover public cover;

    // Initialize, called once
    function initialize (
      ICover cover_,
      IERC20 daiToken_,
      IERC20 noClaimToken_
    )
      external initializer
    {
      cover = cover_;
      daiToken = daiToken_;
      noClaimToken = noClaimToken_;

      initializeOwner();
    }

    function redeemCollateral(address _coverageProvider) external onlyOwner {
      uint noClaimAmount = noClaimToken.balanceOf(address(this));
      cover.redeemNoclaim();
      uint daiAmount = daiToken.balanceOf(address(this));
      require(daiAmount == noClaimAmount);

      if (daiAmount > 0) {
          require(daiToken.transfer(_coverageProvider, daiAmount), "ERR_TRANSFER_FAILED");
      }
    }

    function destroy() external onlyOwner {
        selfdestruct(msg.sender);
    }

    receive() external payable {}
}
