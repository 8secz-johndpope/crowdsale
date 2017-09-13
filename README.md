### Crowdsale Contracts for the TokenBnk sale

We use Open Zeppelin for the base contracts:
    - Ownable.sol
    - Pausable.sol
    - SafeMath.sol
    - StandardToken.sol (and the smaller units of ERC20)

We implement the SmartToken.sol for our token NAME_HERE in order to maintain compatibility with the Bancor Changer contract.

We use the Vesting schedule written by the 0x team which has been vetted by them and additionally by us.

We implemented EtherDivvy.sol in order to manage founder shares raised in the crowdsale.

AO.sol is a wrapper over the SmartToken contract that implements our token.

Crowdsale.sol is our custom contract which was influenced by the Status and District0x token sale contracts.

### Parameters of the contracts

#### Crowdsale
  - `exchangeRate` is the amount of OUR_TOKEN exchanged per every ether contributed.
  - `hardCapAmount` is the hard cap of our sale denominated in ether price.
  - `startTime` is UNIX timestamp seconds of the exact time the contribution period starts.
  - `endTime` is the Unix timestamp in seconds of the exact time the contribution period ends.
  - `initialized` will be switched to true if all parameters have been set.
  - `isEnabled` will be switched to true when the crowdsale is enabled for production and all parameters are finalized.
  - `hardCapReached` will be switched to true when the hard cap is hit.
  - `tokenTransfersEnabled` will be called at the end of the sale and allow all tokens which were sent in exchange for contribution to be transfered. 