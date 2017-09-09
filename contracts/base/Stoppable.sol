pragma solidity ^0.4.15;
import './Ownable.sol';

contract Stoppable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        require(!stopped);
        _;
    }

    function stop()
        onlyOwner 
    {
        stopped = true;
    }

    function resume()
        onlyOwner
    {
        stopped = false;
    }
}