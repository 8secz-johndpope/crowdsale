pragma solidity ^0.4.15;
import './base/SafeMath.sol';

/*
    Contract to divvy up the ether between founders.
**/
contract EtherDivvy {
    address public founderOne;      // Shayne 
    address public founderTwo;      // Logan
    address public founderThree;    // Jack
    address public company;         // TokenBnk wallet

    address multisig;               // Wallet that will be owner of this contract to facilitate address setting.

    modifier onlyMultisig {
        require(msg.sender == multisig);
        _;
    }

    modifier onlyIfAddressesSet {
        require(founderOne != 0x0 &&
                founderTwo != 0x0 &&
                founderThree != 0x0 &&
                company != 0x0);
        _;
    }

    function EtherDivvy(address _multisig) {
        multisig = _multisig;
    }

    function divvy()
        onlyMultisig
        onlyIfAddressesSet
    {
        /// Use SafeMath.***() here to mitigate compiler error.
        uint oneHundredth = SafeMath.div(this.balance, 100);
        uint fivePercent = SafeMath.mul(oneHundredth, 5);
        uint threePercent = SafeMath.mul(oneHundredth, 3);
        uint twoPercent = SafeMath.mul(oneHundredth, 2);
        uint companyShare = SafeMath.sub(
                                SafeMath.sub(
                                    SafeMath.sub(this.balance, fivePercent),
                                threePercent),
                            twoPercent);

        founderThree.transfer(twoPercent);
        founderTwo.transfer(threePercent);
        founderOne.transfer(fivePercent);
        company.transfer(companyShare);
    }

    function setAddresses(address _one, address _two, address _three, address _company)
        onlyMultisig
    {
        require(_one != 0x0 &&
                _two != 0x0 &&
                _three != 0x0 &&
                _company != 0x0);

        founderOne = _one;
        founderTwo = _two;
        founderThree = _three;
        company = _company;
    }

    function () payable {
    }
}