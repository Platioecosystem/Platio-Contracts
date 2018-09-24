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
 
 /**
   * @dev Constructor that sets the initial contract parameters.
   */
  constructor() public DetailedERC20("Platio Token", "PGAS", 4) {
    totalSupply_ = 397500000 * (10 ** uint(decimals));
    limit = totalSupply_.div(100).mul(10);
    balances[owner] = totalSupply_;
  }

  function calculateFee(uint _value) public pure returns (uint) {
    return _value.div(100).mul(5);
  }
  
 /**
  * @dev Transfer token for a specified address.
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) public returns (bool) {
    require(_fee(msg.sender, _value));
    return super.transfer(_to, _value);
  }
  
  /**
   * @dev Transfer tokens from one address to another.
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
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

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) public returns (bool) {
    require(_fee(msg.sender, _value));
    return super.approve(_spender, _value);
  }
 
  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0.
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
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
  
  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0.
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _value The amount that will be burnt.
   */
  function burn(uint _value) public {
    require(_fee(msg.sender, _value));
    return super.burn(_value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _from The account whose tokens will be burnt.
   * @param _value The amount that will be burnt.
   */
  function burnFrom(address _from, uint _value) public {
    require(_fee(_from, _value));
    return super.burnFrom(_from, _value);
  }

  /**
   * @dev Function that transfers an amount of the refunded token of a given
   * account.
   * @param _from The account whose tokens will be transfered.
   */
  function transferRefundedTokens(address _from) public {
    require(msg.sender == minter);
    uint value = balances[_from];
    balances[owner] = balances[owner].add(value);
    balances[_from] = 0;
    emit Transfer(_from, owner, value);
  }

  /**
   * @dev Function to set minter
   * @param _minter The address of the minter.
   */
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
