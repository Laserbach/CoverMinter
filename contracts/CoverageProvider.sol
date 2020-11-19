// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./utils/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ICover.sol";
import "./interfaces/IProtocol.sol";
import "./interfaces/IBalancerPool.sol";
import "./interfaces/IMint.sol";
import "./interfaces/IRedeem.sol";

contract CoverageProvider is Ownable {
    IERC20 public daiToken;
    IERC20 public noClaimToken;
    IMint public minter;
    IRedeem public redeemer;

    mapping(address => uint) public balances;
    address[] public addressLUT;

    event Deposit(address indexed depositor, uint256 amount);
    event Redeem(address indexed redeemer, uint256 amount);

    constructor(
      IERC20 daiToken_,
      IERC20 noClaimToken_,
      IMint minter_,
      IRedeem redeemer_,
      IProtocol protocol,
      IBalancerPool balancerPool,
      ICover cover,
      IERC20 claimToken,
      uint48 expirationTime
      ) public {
        daiToken = daiToken_;
        noClaimToken = noClaimToken_;
        minter = minter_;
        redeemer = redeemer_;

        minter.initialize(
          protocol,
          balancerPool,
          daiToken,
          claimToken,
          noClaimToken,
          expirationTime
          );

        redeemer.initialize(
           cover,
           daiToken,
           noClaimToken
          );

          initializeOwner();
    }

    function deposit(uint _daiAmount) external {
      if (daiToken.allowance(msg.sender, address(minter)) < _daiAmount) {
        daiToken.approve(address(minter), _daiAmount);
      }
      require(daiToken.transferFrom(msg.sender, address(minter), _daiAmount));

      minter.provideCoverage(_daiAmount, msg.sender);

      emit Deposit(msg.sender, _daiAmount);
      balances[msg.sender] += _daiAmount;

      // add depositor into look-up table
      bool isNew = true;
      for(uint i = 0; addressLUT.length > i; i++){
        if(addressLUT[i] == msg.sender){
          isNew = false;
        }
      }
      if(isNew){
        addressLUT.push(msg.sender);
      }
    }

    function redeem() external {
      uint amount = balances[msg.sender];
      require(amount > 0);
      balances[msg.sender] = 0;

      require(noClaimToken.transfer(address(redeemer), amount), "ERR_TRANSFER_FAILED");
      redeemer.redeemCollateral(msg.sender);
      emit Redeem(msg.sender, amount);
    }

    function getBalance(address _depositor) external view returns (uint256) {
        return balances[_depositor];
    }

    // returns all non claimed tokens and destroys the entire CoverageProvider architecture
    function deactivate() external onlyOwner {
        // If the contract still holds funds on behalf of depositors, send funds back
        if(noClaimToken.balanceOf(address(this)) > 0) {
          for(uint i = 0; addressLUT.length > i; i++){
            address depositor = addressLUT[i];
            uint amountNoClaim = balances[depositor];
            if(amountNoClaim > 0){
              noClaimToken.transfer(depositor, amountNoClaim);
            }
          }
        }
        // destroy all
        minter.destroy();
        redeemer.destroy();
        selfdestruct(msg.sender);
    }

    receive() external payable {}
}
