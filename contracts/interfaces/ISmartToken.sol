pragma solidity ^0.4.15;
import '../zeppelin/token/ERC20.sol';

/**
 * @title Smart Token Interface
 */
contract ISmartToken is ERC20 {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}