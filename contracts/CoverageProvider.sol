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

interface MinterInterface {
    function provideCoverage(uint, address, address) external;
}

interface RedeemInterface {
    function redeemCollateral(address, address) external;
}

contract CoverageProvider {
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

      if (noClaimToken.allowance(address(this), address(redeemer)) < amount) {
        daiToken.approve(address(redeemer), amount);
      }
      require(daiToken.transferFrom(address(this), address(redeemer), amount));

      redeemer.redeemCollateral(msg.sender, address(this));
      emit Redeem(msg.sender, amount);
    }

    function getBalance(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    receive() external payable {}
}
