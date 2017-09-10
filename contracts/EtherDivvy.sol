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
        uint oneHundredth = SafeMath.div(this.balance, 100);
        uint fivePercent = SafeMath.mul(oneHundredth, 5);
        uint threePercent = SafeMath.mul(oneHundredth, 3);
        uint twoPercent = SafeMath.mul(oneHundredth, 2);

        founderOne.transfer(twoPercent);
        founderTwo.transfer(threePercent);
        founderThree.transfer(fivePercent);
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