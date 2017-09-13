### Crowdsale Contracts for the TokenBnk sale

We use Open Zeppelin for the base contracts:
    - Ownable.sol
    - Pausable.sol
    - SafeMath.sol

We use Bancor contracts for the base contracts:
    - Utils.sol (Slightly modified to abstract out only necessay functions)
    - ISmartToken.sol
    - ITokenHolder.sol
    - SmartToken.sol (With modifications to use SafeMath)

We use the Vesting schedule written by the 0x team which has been vetted by them and additionally by us.

We implemented EtherDivvy.sol in order to manage founder shares raised in the crowdsale.

AO.sol is a wrapper over the SmartToken contract that implements our token.

Crowdsale.sol is our custom contract which was influenced by the Status and District0x token sale contracts.