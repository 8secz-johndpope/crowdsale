pragma solidity ^0.4.15;

import './SmartToken.sol';

/**
    SaveToken
 */
contract AO is SmartToken {
    
    function AO() 
        SmartToken("Save Token",
                   "AO",
                   18)
    {}
}