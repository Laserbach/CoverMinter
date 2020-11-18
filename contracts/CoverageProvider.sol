// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./utils/Ownable.sol";

interface TokenInterface {
    function balanceOf(address) external returns (uint);
    function allowance(address, address) external returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

interface MinterInterface {
    function provideCoverage(uint, address, address) external;
}

interface RedeemInterface {
    function redeemCollateral(address, address) external;
}

contract CoverageProvider is Ownable {
    TokenInterface public daiToken;
    TokenInterface public noClaimToken;
    MinterInterface public minter;
    RedeemInterface public redeemer;

    mapping(address => uint) public balances;

    event Deposit(address indexed depositor, uint256 amount);
    event Redeem(address indexed redeemer, uint256 amount);

    constructor(TokenInterface daiToken_, TokenInterface noClaimToken_, MinterInterface minter_, RedeemInterface redeemer_) public {
        daiToken = daiToken_;
        noClaimToken = noClaimToken_;
        minter = minter_;
        redeemer = redeemer_;
        initializeOwner();
    }

    function deposit(uint _daiAmount) external {
      if (daiToken.allowance(msg.sender, address(minter)) < _daiAmount) {
        daiToken.approve(address(minter), _daiAmount);
      }
      require(daiToken.transferFrom(msg.sender, address(minter), _daiAmount));

      minter.provideCoverage(_daiAmount, msg.sender, address(this));
      uint noClaimAmount = noClaimToken.balanceOf(address(this));
      require(_daiAmount == noClaimAmount);

      emit Deposit(msg.sender, _daiAmount);
      balances[msg.sender] += _daiAmount;
    }

    function redeem() external {
      uint amount = balances[msg.sender];
      require(amount > 0);
      balances[msg.sender] = 0;

      require(noClaimToken.transfer(address(redeemer), amount), "ERR_TRANSFER_FAILED");
      redeemer.redeemCollateral(msg.sender, address(this));
      emit Redeem(msg.sender, amount);
    }

    function getBalance(address _depositor) external view returns (uint256) {
        return balances[_depositor];
    }

    function returnFunds() external onlyOwner {
        // RETURN ALL LOCKED NOCLAIM TO THEIR MINTERS:
        

    }

    receive() external payable {}
}
