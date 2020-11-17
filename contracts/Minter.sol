// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface PoolInterface {
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
}

interface TokenInterface {
    function balanceOf(address) external returns (uint);
    function allowance(address, address) external returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

interface ProtocolInterface {
    function addCover(address, uint48, uint256) external returns (bool);
}

contract Minter {
    PoolInterface public bPool;
    TokenInterface public daiToken;
    TokenInterface public claimToken;
    TokenInterface public noClaimToken;
    ProtocolInterface public protocol;
    uint48 public expirationTime;

    constructor(PoolInterface bPool_, TokenInterface daiToken_, TokenInterface claimToken_, TokenInterface noClaimToken_, ProtocolInterface protocol_, uint48 expirationTime_) public {
        bPool = bPool_;
        daiToken = daiToken_;
        claimToken = claimToken_;
        noClaimToken = noClaimToken_;
        protocol = protocol_;
        expirationTime = expirationTime_;
    }

    function provideCoverage(uint _daiAmount, address _coverageProvider, address _coverageProviderContract) external {
      require(msg.sender == _coverageProviderContract);
      if (daiToken.allowance(address(this), address(protocol)) < _daiAmount) {
        daiToken.approve(address(protocol), _daiAmount);
      }
      protocol.addCover(address(daiToken), expirationTime, _daiAmount);

      uint claimAmount = claimToken.balanceOf(address(this));
      uint noClaimAmount = noClaimToken.balanceOf(address(this));
      require(_daiAmount == claimAmount);

      _swapClaimForDai(claimAmount, _coverageProvider);
      require(noClaimToken.transfer(_coverageProviderContract, noClaimAmount), "ERR_TRANSFER_FAILED");
    }

    function _swapClaimForDai(uint _sellClaimAmount, address _coverageProvider) private {
        if (claimToken.allowance(address(this), address(bPool)) < _sellClaimAmount) {
          claimToken.approve(address(bPool), _sellClaimAmount);
        }
        (uint daiAmountOut,) = PoolInterface(bPool).swapExactAmountIn(
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
