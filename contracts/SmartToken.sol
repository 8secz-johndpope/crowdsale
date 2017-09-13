pragma solidity ^0.4.15;

import './Utils.sol';
import './interfaces/ISmartToken.sol';
import './zeppelin/token/StandardToken.sol';
import './zeppelin/Ownable.sol';
import './zeppelin/SafeMath.sol';

/**
 * @title Smart Token that is compatible with a Bancor Changer.
*/
contract SmartToken is ISmartToken, Ownable, Utils, StandardToken {
    using SafeMath for uint;

    string name;        // Name of the token
    string symbol;      // Symbol of the token
    uint8 decimals;     // Decimal places of the token

    bool public transfersEnabled = false;    // true if transfer/transferFrom are enabled, false if not

    /**
        @dev constructor

        @param _name       token name
        @param _symbol     token short symbol, 1-6 characters
        @param _decimals   for display purposes only
    */
    function SmartToken(string _name, string _symbol, uint8 _decimals)
    {
        require(bytes(_symbol).length <= 6); // validate input
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // allows execution only when transfers aren't disabled
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

    /**
        @dev disables/enables transfers
        can only be called by the contract owner

        @param _disable    true to disable transfers, false to enable them
    */
    function disableTransfers(bool _disable) 
        public onlyOwner
    {
        transfersEnabled = !_disable;
    }

    /**
        @dev increases the token supply and sends the new tokens to an account
        can only be called by the contract owner

        @param _to         account to receive the new amount
        @param _amount     amount to increase the supply by
    */
    function issue(address _to, uint256 _amount)
        public
        onlyOwner
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }

    /**
        @dev removes tokens from an account and decreases the token supply
        can be called by the contract owner to destroy tokens from any account or by any holder to destroy tokens from his/her own account

        @param _from       account to remove the amount from
        @param _amount     amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount) public {
        require(msg.sender == _from || msg.sender == owner); // validate input

        balances[_from] = balances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        Transfer(_from, this, _amount);
        Destruction(_amount);
    }

    // ERC20 standard method overrides with some extra functionality

    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors
        in addition to the standard checks, the function throws if transfers are disabled

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public 
        transfersAllowed 
        returns (bool success) 
    {
        assert(super.transfer(_to, _value));
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors
        in addition to the standard checks, the function throws if transfers are disabled

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value) 
        public 
        transfersAllowed 
        returns (bool success)
    {
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }

    // triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(uint256 _amount);
}