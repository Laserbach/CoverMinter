// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface TokenInterface {
    function balanceOf(address) external returns (uint);
    function allowance(address, address) external returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

interface CoverInterface {
    function redeemNoclaim() external;
}

contract Redeem {
    TokenInterface public daiToken;
    TokenInterface public noClaimToken;
    CoverInterface public cover;

    constructor(TokenInterface daiToken_, TokenInterface noClaimToken_, CoverInterface cover_) public {
        daiToken = daiToken_;
        noClaimToken = noClaimToken_;
        cover = cover_;
    }

    function redeemCollateral(address _coverageProvider, address _coverageProviderContract) external {
      require(msg.sender == _coverageProviderContract);

      uint noClaimAmount = noClaimToken.balanceOf(address(this));
      cover.redeemNoclaim();
      uint daiAmount = daiToken.balanceOf(address(this));
      require(daiAmount == noClaimAmount);

      if (daiAmount > 0) {
          require(daiToken.transfer(_coverageProvider, daiAmount), "ERR_TRANSFER_FAILED");
      }
    }
    receive() external payable {}
}
