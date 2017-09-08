pragma solidity ^0.4.15;
import './base/SafeMath.sol';

contract EtherDivvy {

    address one;    
    address two;
    address three;

    address multisig;

    modifier onlyMultisig {
        require(msg.sender == multisig);
        _;
    }

    function divvy()
        onlyMultisig
    {
        uint stake1 = SafeMath.div(this.balance, 3);
        uint stake2 = SafeMath.div(this.balance, 20);
        uint stake3 = SafeMath.sub(SafeMath.sub(this.balance, stake1), stake2);

        one.transfer(stake1);
        two.transfer(stake2);
        three.transfer(stake3);
    }
}