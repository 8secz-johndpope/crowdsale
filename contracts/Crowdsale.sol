pragma solidity ^0.4.13;
import './base/SafeMath.sol';
import './AO.sol';

contract Crowdsale {
    using SafeMath for uint;

    AO public saveToken;                        // Address of the AO contract.
    address public multisig;                    // Address of TokenBnk company wallets.

    // Constants for token distributions.
    uint public constant FOUNDER_STAKE1 = 0;        // 6.5%
    uint public constant FOUNDER_STAKE2 = 0;        // 3.5%
    uint public constant COMPANY_RETAINER    = 0;   // 60%
    uint public constant CONTRIBUTION_STAKE = 0;    // 30%

    uint public minContribution = 0.01 ether;
    uint public maxGasPrice = 50000000000;     // 50 GWei

    bool public tokenTransfersEnabled = false; // Token transfers will be enabled at the
                                               // conclusion of the sale.
    
    uint public softCapAmount = 0;             // Amount in wei that will trigger soft cap duration.
    uint public softCapDuration = 0;           // Seconds after the softcap that sale will continue unless hardcap.
    uint public hardCapAmount = 0;             // Amount in wei that will trigger hard cap / end of sale.
    uint public startTime = 0;                 // UNIX timestamp for start of sale.
    uint public endTime = 0;                   // UNIX timestamp for end of sale.
    bool public initialized;                   // True if crowdsale has been initialized.
    bool public isEnabled;                     // True if crowdsale has been enabled.
    bool public softCapReached;                // True if soft cap was reached.
    bool public hardCapReached;                // True if hard cap was reached.
    uint public totalContributionAmount;       // Total amount of ETH that has been contributed.
    address[] public contributorKeys;          // Public keys of all contributors.
    mapping(address => uint) contributors;     // Mapping of address to contribution amounts.

    modifier onlyMultisig {
        require(multisig == msg.sender);
        _;
    }

    // TEMP EMERGENCY STOP
    bool public stopped;

    modifier stopInEmergency {
        require(!stopped);
        _;
    }

    function stopSale()
        onlyMultisig 
    {
        stopped = true;
    }

    function resumeSale()
        onlyMultisig
    {
        stopped = false;
    }
    // END TEMP EMERGENCY STOP

    function Crowdsale(address _companyWallet) {
        multisig = _companyWallet;
    }

    function ()
        public
        payable
        stopInEmergency 
    {
        contributeWithAddress(msg.sender);
    }

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
            uint endTime = now;
            HardCapReached(endTime);

            // Only accept funds up to the hard cap amount.
            excessContribution = newTotal.sub(hardCapAmount);
            contribution = contribution.sub(excessContribution);
            totalContributionAmount = hardCapAmount;
        }

        // First time buyer? Let's take down your address...
        if (contributors[_contributor] == 0) {
            contributorKeys.push(_contributor);
        }

        contributors[_contributor] = contributors[_contributor].add(contribution);

        multisig.transfer(contribution);
        if (excessContribution != 0) {
            msg.sender.transfer(excessContribution);
        }

        Contribution(_contributor, contribution, now);
    }

    /*
     * Admin Functions
     */
    function initializeSale(address _saveToken,
                            uint _softCapAmount,
                            uint _softCapDuration,
                            uint _hardCapAmount,
                            uint _startTime,
                            uint _endTime)
        onlyMultisig
    {
        require(_softCapAmount != 0);
        softCapAmount = _softCapAmount;

        require(_softCapDuration != 0);
        softCapDuration = _softCapDuration;

        require(_hardCapAmount != 0);
        hardCapAmount = _hardCapAmount;

        require(_startTime > now);
        startTime = _startTime;

        require(_endTime > startTime);
        endTime = _endTime;

        assert(setAndCreateSaveTokens(_saveToken));

    }

    function setAndCreateSaveTokens(address _saveToken)
        internal
        onlyMultisig
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
                                       .add(COMPANY_RETAINER)
                                       .add(EARLY_CONTRIBUTOR2)
                                       .add(CONTRIBUTION_STAKE));
        return true;
    }

    function enableTokenSale()
        onlyMultisig 
    {
        require(startTime <= now);
        require(initialized);
        isEnabled = true;
    }

    function enableTokenTransfers()
        internal // OR onlyMultisig???
    {
        require(endTime < now);
        // saveToken.enableTransfers(true);
        tokenTransfersEnabled = true;
    }

    /*
     * Parameter Tweaks
     */
    function setMinContrib(uint _minContrib) 
        onlyMultisig
    {
        require(_minContrib > 0);
        require(startTime > now);

        minContribution = _minContrib;
    }

    function setMaxGasPrice(uint _gasPrice)
        onlyMultisig
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
        return block.number;
    }

    /*
     * Events
     */
    event Contribution(address indexed who, uint indexed amount, uint indexed timestamp);
    event SoftCapReached(uint timestamp);
    event HardCapReached(uint timestamp);
}