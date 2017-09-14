const AO = artifacts.require("../contracts/test/AOMock.sol");
const EtherDivvy = artifacts.require("../contracts/EtherDivvy.sol")
const Crowdsale = artifacts.require("../contracts/test/CrowdsaleMock.sol")

module.exports = function(deployer) {
  deployer.deploy(AO)
  deployer.deploy(EtherDivvy)
  deployer.deploy(Crowdsale)
};
