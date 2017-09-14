pragma solidity ^0.4.15;

import '../AO.sol';

contract AOMock is AO {

    uint mockBlockNumber = 1;

    function AOMock() AO() {}

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