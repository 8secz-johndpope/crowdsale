pragma solidity ^0.4.15;
import './base/SafeMath.sol';

contract EtherDivvy {

    address public founderOne;    
    address public founderTwo;
    address public founderThree;

    address multisig;

    modifier onlyMultisig {
        require(msg.sender == multisig);
        _;
    }

    function divvy()
        onlyMultisig
    {
        uint oneTenth = SafeMath.div(this.balance, 10);
        uint stake1 = SafeMath.mul(oneTenth, 2);
        uint stake2 = SafeMath.mul(oneTenth, 3);
        uint stake3 = SafeMath.mul(oneTenth, 5);

        founderOne.transfer(stake1);
        founderTwo.transfer(stake2);
        founderThree.transfer(stake3);
    }

    function setAddresses(address _one, address _two, address _three)
        onlyMultisig
    {
        require(_one != 0x0 &&
                _two != 0x0 &&
                _three != 0x0);

        founderOne = _one;
        founderTwo = _two;
        founderThree = _three;
    }
}