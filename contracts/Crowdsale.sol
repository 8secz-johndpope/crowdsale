pragma solidity ^0.4.15;

import './AO.sol';
import './zeppelin/Pausable.sol';
import './zeppelin/SafeMath.sol';

/**
 * @title TokenBnk Crowdsale
 */
contract Crowdsale is Pausable {
    using SafeMath for uint;

    AO public saveToken;                                // Address of the AO contract.
    address public wallet;                              // Wallet that recieves all ether from the sale. Will be an instance of EtherDivvy.sol.
    address public vestingSchedule;                     // Contract for vesting schedule of organization and founder tokens.

    // Constants for token distributions.
    uint public constant FOUNDER_STAKE1 = 40000 ether;            // 4%
    uint public constant FOUNDER_STAKE2 = 30000 ether;            // 3%
    uint public constant FOUNDER_STAKE3 = 30000 ether;            // 3%
    uint public constant ORGANIZATION_RETAINER = 100000 ether;    // 60%
    uint public constant CONTRIBUTION_STAKE = 100000 ether;       // 30% TODO: Finish the math

    uint public minContribution = 0.01 ether;           // ~ $3.00
    uint public maxGasPrice = 50000000000;              // 50 GWei

    bool public tokenTransfersEnabled = false;          // Token transfers will be enabled at the
                                                        // conclusion of the sale.
    
    struct Contributor {
        uint amount;
        bool isCompensated;
        uint amountCompensated;
    }

    uint public exchangeRate = 33333330000000;          // The number of AO tokens that will be created per wei. Pegged roughly to .01 USD. Exact pice will be determined shortly before token sale.
    uint public hardCapAmount;                      // Amount in wei that will trigger hard cap / end of sale.
    uint public startBlock;                         // Block that starts the sale.
    uint public endBlock;                           // Block that ends the sale.
    bool public initialized;                            // True if crowdsale has been initialized.
    bool public isEnabled;                              // True if crowdsale has been enabled.
    bool public hardCapReached;                         // True if hard cap was reached.
    uint public totalContributionAmount;                // Total amount of ETH that has been contributed.
    address[] public contributorKeys;                   // Public keys of all contributors.
    mapping(address => Contributor) contributors;       // Mapping of address to contribution amounts.

    function Crowdsale() {}

    function ()
        public 
        payable
        whenNotPaused
    {
        contributeWithAddress(msg.sender);
    }

    function contribute()
        public
        payable
        whenNotPaused 
    {
        contributeWithAddress(msg.sender);
    }

    /// @notice If users call either the fallback function or
    /// `contribute()` they will be redirected to this contribution function.
    /// This is the entry point to contribute to the sale.
    function contributeWithAddress(address _contributor)
        public
        payable 
        whenNotPaused
    {
        require(_contributor != 0x0);
        assert(validContribution());

        uint contribution = msg.value;
        uint excessContribution = 0;

        uint oldTotal = totalContributionAmount;
        totalContributionAmount = oldTotal.add(contribution);
        uint newTotal = totalContributionAmount;

        // If the new contribution hits the hard cap.
        if (newTotal >= hardCapAmount && oldTotal < hardCapAmount) {
            hardCapReached = true;
            endBlock = getBlockNumber();
            HardCapReached();

            // Only accept funds up to the hard cap amount.
            excessContribution = newTotal.sub(hardCapAmount);
            contribution = contribution.sub(excessContribution);
            totalContributionAmount = hardCapAmount;
        }

        // Let's find the data based on the public key.
        if (contributors[_contributor].amount == 0) {
            contributorKeys.push(_contributor);
        }

        contributors[_contributor].amount = contributors[_contributor].amount.add(contribution);

        wallet.transfer(contribution);
        if (excessContribution != 0) {
            msg.sender.transfer(excessContribution);
        }

        NewContribution(_contributor, contribution - excessContribution, newTotal - excessContribution, contributorKeys.length);
    }

    /// @notice After the conclusion of the sale this function will need to be called
    /// to award contributors with tokens proportionally to the amount that they
    /// contributed. Offset and limit are available to mitigate out of gas errors.
    /// @param _offset The number of first contributors to skip.
    /// @param _limit The max number of contributors that can be compensated on this call.
    function compensateContributors(uint _offset, uint _limit)
        onlyOwner
    {
        require(isEnabled);
        require(endBlock < getBlockNumber());

        uint i = _offset;
        uint compensatedCount = 0;
        uint contributorsCount = contributorKeys.length;

        while (i < contributorsCount && compensatedCount < _limit) {
            address contributorAddress = contributorKeys[i];
            if (!contributors[contributorAddress].isCompensated) {
                uint amountContributed = contributors[contributorAddress].amount;
                contributors[contributorAddress].isCompensated = true;

                contributors[contributorAddress].amountCompensated = amountContributed.mul(exchangeRate);

                saveToken.transfer(contributorAddress, contributors[contributorAddress].amountCompensated);
                OnCompensation(contributorAddress, contributors[contributorAddress].amountCompensated);

                compensatedCount++;
            }
            i++;
        }
    }

    /// @notice This function will be called at the conclusion of the sale and will
    /// transfer all organization and founder tokens to the vesting schedule contract.
    function vestTokens()
        onlyOwner
    {
        require(isEnabled);
        require(endBlock < getBlockNumber());

        saveToken.transfer(vestingSchedule, FOUNDER_STAKE1
            .add(FOUNDER_STAKE2)
            .add(FOUNDER_STAKE3)
            .add(ORGANIZATION_RETAINER));
    }

    /*
     * Admin Functions
     */
    function initializeSale(address _saveToken,
                            address _etherDivvy,
                            address _vestingSched,
                            uint _hardCapAmount,
                            uint _startBlock,
                            uint _endBlock)
        onlyOwner
    {
        require(!initialized);
        require(!isEnabled);

        require(_etherDivvy != 0x0 && _vestingSched != 0x0);

        require(isContract(_etherDivvy));
        wallet = _etherDivvy;

        require(isContract(_vestingSched));
        vestingSchedule = _vestingSched;

        require(_hardCapAmount != 0);
        hardCapAmount = _hardCapAmount;

        require(_startBlock > getBlockNumber());
        startBlock = _startBlock;

        require(_endBlock > startBlock);
        endBlock = _endBlock;

        saveToken = AO(_saveToken);

        initialized = true;
    }

    /**
     * @dev Require the _saveToken address to have this contract as an owner or else it throws.
     *      This contract must be an owner because it will mint / issue fresh tokens for the distribution.
     */
    function createTokens()
        public
        onlyOwner
    {
        require(address(saveToken) != 0x0);
        require(!isEnabled);

        uint totalSupplyOfTokens = FOUNDER_STAKE1
            .add(FOUNDER_STAKE2)
            .add(FOUNDER_STAKE3)
            .add(ORGANIZATION_RETAINER)
            .add(CONTRIBUTION_STAKE);

        saveToken.call(bytes4(keccak256("issue(address,uint256)")), address(this), totalSupplyOfTokens);
        assert(saveToken.balanceOf(address(this)) == totalSupplyOfTokens);
    }

    /// @dev This function will be called before the beginning of the sale to enable the contract to accept funds.
    function enableTokenSale()
        onlyOwner
    {
        require(startBlock <= getBlockNumber());
        require(initialized);
        isEnabled = true;
    }

    /// @dev We will call this function at the conclusion of the sale to allow token transfers.
    function enableTokenTransfers()
        onlyOwner
    {
        require(endBlock < getBlockNumber());
        saveToken.disableTransfers(false);
        tokenTransfersEnabled = true;
    }

    /*
     * Parameter Tweaks
     */
    function setMinContrib(uint _minContrib) 
        onlyOwner
    {
        require(_minContrib > 0);
        require(startBlock > getBlockNumber());

        minContribution = _minContrib;
    }

    function setMaxGasPrice(uint _gasPrice)
        onlyOwner
    {
        require(_gasPrice > 0);
        require(startBlock > getBlockNumber());

        maxGasPrice = _gasPrice;
    }

    function setExchangeRate(uint _exchangeRate)
        onlyOwner
    {
        require(_exchangeRate != 0);
        require(startBlock > getBlockNumber());

        exchangeRate = _exchangeRate;
    }

    function setHardCap(uint _hardCapAmount)
        onlyOwner
    {
        require(_hardCapAmount != 0);
        require(startBlock > getBlockNumber());

        hardCapAmount = _hardCapAmount;
    }

    /// @notice Wrapper over the `transferOwnership()` function to only be called after conclusion
    ///         of the sale and when the protocol is deployed, to change the owner of the token.
    function changeTokenOwner(address _newOwner)
        public 
        onlyOwner
    {
        require(endBlock < getBlockNumber());
        saveToken.call(bytes4(keccak256("transferOwnership(address)")), _newOwner);

        assert(saveToken.owner() == _newOwner);
    }

    /*
     * Helper Functions
     */
    function validContribution()
        constant internal returns (bool) 
    {
        require(!hardCapReached);
        require(isEnabled);
        require(startBlock <= getBlockNumber());
        require(endBlock > getBlockNumber());

        require(tx.gasprice <= maxGasPrice);
        require(msg.value >= minContribution);
        return true;
    }

    function isContract(address _addr) 
        constant internal returns(bool)
    {
        uint size;
        if (_addr == 0) {
            return false;
        }
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

     /// @notice This function is overridden by the test mocks.
    function getBlockNumber()
        internal constant returns (uint)
    {
        return block.number;
    }

    /*
     * Events
     */
    event NewContribution(address indexed who, uint amount, uint totalContribution, uint lengthOfContributors);
    event OnCompensation(address indexed who, uint amount);
    event HardCapReached();
}