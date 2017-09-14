const BigNumber = require('bignumber.js')

const AO = artifacts.require('../contracts/test/AOMock.sol')
const Crowdsale = artifacts.require('../contracts/test/CrowdsaleMock.sol')
const EtherDivvy = artifacts.require('../contracts/EtherDivvy.sol')

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
            web3.toWei(1000),
            startBlock,
            endBlock 
        )
    })
})