pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Contactable.sol";


/**
 * @title Platio Token
 */
contract PlatioToken is StandardBurnableToken, DetailedERC20, Contactable {
  uint public limit;
  address public minter;

  constructor() public DetailedERC20("Platio Token", "PGAS", 4) {
    totalSupply_ = 397500000 * (10 ** uint(decimals));
    limit = totalSupply_.div(100).mul(10);
    balances[owner] = totalSupply_;
  }

  function calculateFee(uint _value) public pure returns (uint) {
    return _value.div(100).mul(5);
  }

  function transfer(address _to, uint _value) public returns (bool) {
    require(_fee(msg.sender, _value));
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint _value
  )
    public
    returns (bool)
  {
    require(_fee(_from, _value));
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint _value) public returns (bool) {
    require(_fee(msg.sender, _value));
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    require(_fee(msg.sender, allowance(msg.sender, _spender).add(_addedValue)));
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    require(_fee(msg.sender, 0));
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  function burn(uint _value) public {
    require(_fee(msg.sender, _value));
    return super.burn(_value);
  }

  function burnFrom(address _from, uint _value) public {
    require(_fee(_from, _value));
    return super.burnFrom(_from, _value);
  }

  function transferRefundedTokens(address _from) public {
    require(msg.sender == minter);
    uint value = balances[_from];
    balances[owner] = balances[owner].add(value);
    balances[_from] = 0;
    emit Transfer(_from, owner, value);
  }

  function setMinter(address _minter) public onlyOwner {
    require(_minter != address(0));
    minter = _minter;
  }

  function _fee(address _from, uint _value) internal returns (bool) {
    if (totalSupply().sub(calculateFee(_value).div(2)) >= limit) {
      if (_from == msg.sender) {
        require(_value.add(calculateFee(_value)) <= balanceOf(_from));
        _burn(_from, calculateFee(_value).div(2));
        transfer(owner, calculateFee(_value).div(2));
      } else {
        require(
          _value.add(calculateFee(_value)) <= allowance(_from, msg.sender)
        );
        _burn(_from, calculateFee(_value).div(2));
        transferFrom(_from, owner, calculateFee(_value).div(2));
      }
    }
    return true;
  }
}
