pragma solidity ^0.4.15;
import './IERC20.sol';

/*
    Token Holder interface

    TODO change the name of this contract. Does it need to be owned?
*/
contract ITokenHolder {
    function withdrawTokens(IERC20 _token, address _to, uint256 _amount) public;
}