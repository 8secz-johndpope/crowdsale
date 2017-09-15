const BigNumber = require('bignumber.js')
const assertFail = require('./helpers/assertFail.js')

const AO = artifacts.require('../contracts/test/AOMock.sol')
const Crowdsale = artifacts.require('../contracts/test/CrowdsaleMock.sol')
const EtherDivvy = artifacts.require('../contracts/EtherDivvy.sol')
const VestingSchedule = artifacts.require('../contracts/VestingWallet.sol')

contract('TokenBnk crowdsale', function(accounts) {
    const TokenBnk = accounts[0]
    const Founder1 = accounts[1]
    const Founder2 = accounts[2]
    const Founder3 = accounts[3]
    const mockContributor1 = accounts[4]
    const mockContributor2 = accounts[5]

    let ao 
    let crowdsale
    let etherDivvy 

    const startBlock = 100000
    const endBlock = 104000
    const exchangeRate = 30000

    const totalSupply = 3e23
    const hardCapAmount = web3.toWei(100)

    it('Deploys all contracts', async function() {
        ao = await AO.new()
        crowdsale = await Crowdsale.new()
        etherDivvy = await EtherDivvy.new()
    })

    it('Initializes crowdsale', async function() {

        /// First set the owner of ao to the crowdsale contract
        ao.transferOwnership(crowdsale.address)

        /// Will generate the tokens
        await crowdsale.initializeSale(
            ao.address,
            etherDivvy.address,
            vestingWallet.address,
            hardCapAmount,
            startBlock,
            endBlock 
        )

        /// Check that the crowdsale flipped on the switch that it was initialized.
        let initialized = await crowdsale.initialized()
        assert.equal(
            initialized,
            true,
            'It should have initialized crowdsale'
        )        
    })

    it('Should generate the tokens and send them to crowdsale address', async function() {

        /// Create the tokens
        await crowdsale.createTokens()
        
        /// Assert balances are equal
        let _totalSupply = await ao.totalSupply()
        let _balanceOf = await ao.balanceOf(crowdsale.address)

        assert.equal(
            _totalSupply.toNumber(),
            _balanceOf.toNumber(),
            'It should have sent all generated tokens to the crowdsale.'
        )

        /// Assert balance / total supply is what we expected.
        assert.equal(
            _totalSupply.toNumber(),
            totalSupply,
            'It should have created the number of tokens we expect.'
        )
    })

    it('Should be enabled', async function() {
        
        /// First set the mock block number to be greater than our start constant.
        await crowdsale.setBlockNumber(startBlock + 1)

        /// Enable the sale
        await crowdsale.enableTokenSale()

        let enabled = await crowdsale.isEnabled()
        assert.equal(
            enabled,
            true,
            'It should be enabled.'
        )
    })

    it('Should accept contributions', async function() {

        let balanceBefore1 = await web3.eth.getBalance(mockContributor1).toNumber()
        let balanceBefore2 = await web3.eth.getBalance(mockContributor2).toNumber()

        let contributedAmountBefore = await web3.eth.getBalance(etherDivvy.address).toNumber()

        let contribution1 = web3.toWei(4)
        let contribution2 = web3.toWei(6)

        await crowdsale.contribute({from: mockContributor1, value: contribution1, gasPrice: 20000000000})
        await crowdsale.contribute({from: mockContributor2, value: contribution2, gasPrice: 50000000000})

        assert.equal(
            await web3.eth.getBalance(crowdsale.address).toNumber(),
            0,
            'The crowdsale contract should hold no ether from contributions'
        )
        
        assert.isAbove(
            await web3.eth.getBalance(etherDivvy.address).toNumber(),
            contributedAmountBefore,
            'The contributions should go into the EtherDivvy contract'
        )

        assert.isAbove(
            balanceBefore1,
            await web3.eth.getBalance(mockContributor1).toNumber(),            
            'Higher balance before contribution'
        )

        assert.isAbove(
            balanceBefore2,
            await web3.eth.getBalance(mockContributor2).toNumber(),
            'Higher balance before contribution'
        )
    })

    it('Should throw faulty contributions', async function() {
        await assertFail(async function() {
            await crowdsale.contribution({from: mockContributor1, value: web3.toWei(5), gasPrice: 50000000001})
        }, 'Should throw if gas price is over the max gas price.')

        await assertFail(async function() {
            await crowdsale.contribution({from: mockContributor1, value: web3.toWei(0.45), gasPrice: 50000000000})
        }, 'Should throw if contribution value is less than the min contribution.')
    })

    it('Should trigger HardCap() event and stop the crowdsale on hard cap hit and excess contribution sent back', async function() {
        
        /// We already have a contribution amount of 10 ether from the transactions in the test above
        /// This transaction should send 90 eth as contribution and recieve 1 eth back
        let contribution = web3.toWei(91)
        
        let balanceBefore = await web3.eth.getBalance(mockContributor1)

        await crowdsale.contribute({from: mockContributor1, value: contribution, gasPrice: 50000000000})
        
        assert.equal(
            await web3.eth.getBalance(etherDivvy.address).toNumber(),
            hardCapAmount,
            'The entire amount of funds up to Hard Cap should go into EtherDivvy'
        )

        /// Because of gas fees it should be slightly below this number ... [see next test]
        assert.isBelow(
            await web3.eth.getBalance(mockContributor1).toNumber(),
            balanceBefore - web3.toWei(90),
            'Should have only sent 90 eth'
        )

        /// ...But also above this number
        assert.isAbove(
            await web3.eth.getBalance(mockContributor1).toNumber(),
            balanceBefore - web3.toWei(91),
            'Should NOT have sent 91 eth'
        )
    })


    it("Should throw any contributions after the hard cap is reached", async function() {

        await assertFail(async function() {
            await crowdsale.contribution({from: mockContributor1, value: web3.toWei(5), gasPrice: 40000000000})
        }, 'Should throw after Hard Cap.')
    })

    it("Should vest tokens and contribute contributors", async function() {

        await crowdsale.
    })

})