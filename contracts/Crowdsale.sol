pragma solidity ^0.4.13;
import './base/SafeMath.sol';
import './base/Stoppable.sol';
import './AO.sol';

/*
    Contribution Crowdsale for TokenBnk Save Tokens. Influenced by District0x's contribution
    contract model. With the major change being that we are using an 0x influenced vesting
    contract instead of an in-built solution.
 **/
contract Crowdsale is Stoppable {
    using SafeMath for uint;

    AO public saveToken;                                // Address of the AO contract.
    address public wallet;                              // Wallet that recieves all sale funds.
    address public founder1;                            // Wallet of founder 1.
    address public founder2;                            // Wallet of founder 2.
    address public founder3;                            // Wallet of founder 3.
    address public vestingSchedule;                     // Contract for vesting schedule.

    // Constants for token distributions.
    uint public constant FOUNDER_STAKE1 = 0;            // 5%
    uint public constant FOUNDER_STAKE2 = 0;            // 3%
    uint public constant FOUNDER_STAKE3 = 0;            // 2%
    uint public constant COMPANY_RETAINER    = 0;       // 60%
    uint public constant CONTRIBUTION_STAKE = 0;        // 30%

    uint public minContribution = 0.01 ether;
    uint public maxGasPrice = 50000000000;              // 50 GWei

    bool public tokenTransfersEnabled = false;          // Token transfers will be enabled at the
                                                        // conclusion of the sale.
    
    struct Contributor {
        uint amount;
        bool isCompensated;
        uint amountCompensated;
    }

    uint public exchangeRate = 0;                       // The number of AO tokens that will be sent per ether.
    uint public hardCapAmount = 0;                      // Amount in wei that will trigger hard cap / end of sale.
    uint public startTime = 0;                          // UNIX timestamp for start of sale.
    uint public endTime = 0;                            // UNIX timestamp for end of sale.
    bool public initialized;                            // True if crowdsale has been initialized.
    bool public isEnabled;                              // True if crowdsale has been enabled.
    bool public hardCapReached;                         // True if hard cap was reached.
    uint public totalContributionAmount;                // Total amount of ETH that has been contributed.
    address[] public contributorKeys;                   // Public keys of all contributors.
    mapping(address => Contributor) contributors;       // Mapping of address to contribution amounts.

    function Crowdsale(address _companyWallet,
                       address _founder1,
                       address _founder2,
                       address _founder3)
    {
        wallet = _companyWallet;
        founder1 = _founder1;
        founder2 = _founder2;
        founder3 = _founder3;
    }

    // @notice Returns true if contribution period is currently running
    function isContribPeriodRunning() constant returns (bool) {
        return !hardCapReached&&
               isEnabled &&
               startTime <= now &&
               endTime > now;
    }

    function ()
        public 
        payable
        stopInEmergency
    {
        contributeWithAddress(msg.sender);
    }

    function contribute()
        public
        payable
        stopInEmergency 
    {
        contributeWithAddress(msg.sender);
    }

    /// @notice If users call either the fallback function or
    /// `contribute()` they will be redirected to this contribution function.
    /// This is the entry point to contribute to the sale.
    function contributeWithAddress(address _contributor)
        public
        payable 
        stopInEmergency
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

        NewContribution(_contributor, contribution, newTotal, contributorKeys.length);
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
        require(endTime < now);

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
    /// transfer all company and founder tokens to the vesting schedule contract.
    function vestTokens()
        onlyOwner
    {
        require(isEnabled);
        require(endTime < now);

        saveToken.transfer(vestingSchedule, FOUNDER_STAKE1
            .add(FOUNDER_STAKE2)
            .add(FOUNDER_STAKE3)
            .add(COMPANY_RETAINER));
    }

    /*
     * Admin Functions
     */
    function initializeSale(address _saveToken,
                            uint _hardCapAmount,
                            uint _startTime,
                            uint _endTime)
        onlyOwner
    {
        require(_hardCapAmount != 0);
        hardCapAmount = _hardCapAmount;

        require(_startTime > now);
        startTime = _startTime;

        require(_endTime > startTime);
        endTime = _endTime;

        assert(setAndCreateSaveTokens(_saveToken));

        initialized = true;
    }

    function setAndCreateSaveTokens(address _saveToken)
        internal
        onlyOwner
        returns (bool)
    {
        require(address(saveToken) == 0x0);
        require(_saveToken != 0x0);
        require(!isEnabled);
        saveToken = AO(_saveToken);

        // Create the tokens and send them to this address.
        assert(saveToken.totalSupply() == 0);
        saveToken.issue(this, FOUNDER_STAKE1
            .add(FOUNDER_STAKE2)
            .add(FOUNDER_STAKE3)
            .add(COMPANY_RETAINER)
            .add(CONTRIBUTION_STAKE));
        return true;
    }

    function enableTokenSale()
        onlyOwner
    {
        require(startTime <= now);
        require(initialized);
        isEnabled = true;
    }

    function enableTokenTransfers()
        onlyOwner
    {
        require(endTime < now);
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
        require(startTime > now);

        minContribution = _minContrib;
    }

    function setMaxGasPrice(uint _gasPrice)
        onlyOwner
    {
        require(_gasPrice > 0);
        require(startTime > now);

        maxGasPrice = _gasPrice;
    }

    /*
     * Helper Functions
     */
    function validContribution()
        internal returns (bool) 
    {
        require(!hardCapReached);
        require(isEnabled);
        require(startTime <= now);
        require(endTime > now);

        require(tx.gasprice <= maxGasPrice);
        require(msg.value >= minContribution);
        return true;
    }

    function getNow()
        constant returns (uint)
    {
        return now;
    }

    /*
     * Events
     */
    event NewContribution(address indexed who, uint amount, uint totalContribution, uint lengthOfContributors);
    event OnCompensation(address indexed who, uint amount);
    event HardCapReached();
}