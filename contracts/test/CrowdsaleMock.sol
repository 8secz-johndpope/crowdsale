pragma solidity ^0.4.15;

import '../Crowdsale.sol';

/**
 * Wrapper around Crowdsale.sol that mocks the blocknumbers to facilitate testing.
 */
contract CrowdsaleMock is Crowdsale {

    uint mockBlockNumber = 1;

    function CrowdsaleMock() Crowdsale () {}

    function getBlockNumber() 
        internal constant returns (uint)
    {
        return mockBlockNumber;
    }

    function setBlockNumber(uint _num) 
        public
    {
        mockBlockNumber = _num;
    }
}