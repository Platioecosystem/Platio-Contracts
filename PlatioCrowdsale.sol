pragma solidity ^0.4.24;

import "./PlatioToken.sol";
import "openzeppelin-solidity/contracts/ownership/Contactable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @title Platio Token
 */
contract PlatioCrowdsale is Contactable {
  using SafeMath for uint;
  using SafeERC20 for PlatioToken;

  PlatioToken public token;

  uint public preSaleStartTime = 1539000000;
  uint public preSaleEndTime = 1540123200;
  uint public saleStartTime = 1540209600;
  uint public saleEndTime = 1541332800;
  uint public startTime = preSaleStartTime;
  uint public endTime = saleEndTime;
  uint public cap = 184092 finney;
  uint public goal = 26680 finney;
  uint public rate = 933;
  uint public weiRaised;
  uint public saleAmount;
  uint public teamAmount;
  uint public advisorsAmount;
  uint public bountyAmount;
  bool public isFinalized;

  mapping (address => uint) public paidAmountOf;

  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint value,
    uint amount
  );
  event Refund(address who, uint value);
  event Finalized();

  constructor(PlatioToken _token) public {
    require(address(_token) != address(0));
    token = _token;
    saleAmount = token.totalSupply().div(100).mul(65);
    teamAmount = token.totalSupply().div(100).mul(25);
    advisorsAmount = token.totalSupply().div(100).mul(8);
    bountyAmount = token.totalSupply().div(100).mul(2);
  }

  function() public payable {
    buyTokens(msg.sender);
  }

  function hasStarted() public view returns (bool) {
    return block.timestamp >= startTime;
  }
  
  function hasEnded() public view returns (bool) {
    return block.timestamp > endTime;
  }

  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

  function getTokenAmount(uint _weiAmount) public view returns (uint) {
    return _weiAmount.mul(rate);
  }

  function getTokenAmountWithBonus(uint _weiAmount)
    public view returns (uint)
  {
    if (hasStarted() && block.timestamp < 1539604800) {
      return(
        getTokenAmount(_weiAmount).
        add(
          getTokenAmount(_weiAmount).
          div(100).
          mul(15)
        )
      );
    } else if (block.timestamp >= 1539604800 && block.timestamp < 1540123200) {
      return(
        getTokenAmount(_weiAmount).
        add(
          getTokenAmount(_weiAmount).
          div(100).
          mul(10)
        )
      );
    } else if (block.timestamp >= 1540123200 && block.timestamp < 1540382400) {
      return(
        getTokenAmount(_weiAmount).
        add(
          getTokenAmount(_weiAmount).
          div(100).
          mul(8)
        )
      );
    } else if (block.timestamp >= 1540382400 && block.timestamp < 1540728000) {
      return(
        getTokenAmount(_weiAmount).
        add(
          getTokenAmount(_weiAmount).
          div(100).
          mul(5)
        )
      );
    } else {
      return getTokenAmount(_weiAmount);
    }
  }

  function buyTokens(address _beneficiary) public payable {
    require(_beneficiary != address(0));
    require(msg.value > 0);
    require(hasStarted() && !hasEnded());
    require(weiRaised.add(msg.value) <= cap);
    require(getTokenAmountWithBonus(msg.value) <= saleAmount);

    weiRaised = weiRaised.add(msg.value);
    saleAmount = saleAmount.sub(getTokenAmountWithBonus(msg.value));
    token.safeTransferFrom(
      owner,
      _beneficiary,
      getTokenAmountWithBonus(msg.value)
    );

    emit TokenPurchase(
      msg.sender, 
      _beneficiary, 
      msg.value, 
      getTokenAmountWithBonus(msg.value)
    );
  }

  function refund() public {
    require(!goalReached() && isFinalized);
    msg.sender.transfer(paidAmountOf[msg.sender]);
    uint refundedTokens = token.balanceOf(msg.sender);
    token.transferRefundedTokens(msg.sender);
    emit Refund(msg.sender, refundedTokens);
  }

  function withdraw() public onlyOwner {
    require(goalReached());
    owner.transfer(address(this).balance);
  }

  function finalize(
    address _teamFund, 
    address _advisorsFund
  ) 
    public 
    onlyOwner 
  {
    require(hasEnded());
    require(!isFinalized);

    if (goalReached() && address(this).balance > 0) withdraw();
    token.safeTransferFrom(owner, _teamFund, teamAmount);
    token.safeTransferFrom(owner, _advisorsFund, advisorsAmount);
    advisorsAmount = 0;
    teamAmount = 0;
    isFinalized = true;

    emit Finalized();
  }
}
