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

contract BalancerTraderCover {
    PoolInterface public bPool;
    TokenInterface public daiToken;
    TokenInterface public claimToken;

    constructor(PoolInterface bPool_, TokenInterface daiToken_, TokenInterface claimToken_) public {
        bPool = bPool_;
        daiToken = daiToken_;
        claimToken = claimToken_;
    }

    function sellClaim(uint sellClaimAmount) public {
        require(claimToken.balanceOf(msg.sender) >= sellClaimAmount, "ERR_NOT_ENOUGH_BALANCE");
        require(claimToken.allowance(msg.sender, address(this)) == sellClaimAmount, "ERR_NOT_ENOUGH_ALLOWANCE");
        claimToken.transferFrom(msg.sender, address(this), sellClaimAmount);
        _swapClaimForDai(sellClaimAmount);
    }

    function _swapClaimForDai(uint sellClaimAmount) private {
        if (claimToken.allowance(address(this), address(bPool)) < sellClaimAmount) {
          require(claimToken.approve(address(bPool), sellClaimAmount), "ERR_APPROVE_BAL");
        }
        //require(claimToken.transfer(address(bPool), sellClaimAmount), "ERR_TRANSFER_FAILED");
        (uint daiAmountOut,) = PoolInterface(bPool).swapExactAmountIn(
            address(claimToken),
            sellClaimAmount,
            address(daiToken),
            0, // minAmountOut, set to 0 -> sell no matter how low the price of CLAIM tokens are
            2**256 - 1 // maxPrice, set to max -> accept any swap prices
        );
        if (daiAmountOut > 0) {
            require(daiToken.transfer(msg.sender, daiToken.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        }
    }
    receive() external payable {}
}
