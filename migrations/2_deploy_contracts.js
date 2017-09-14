const AO = artifacts.require("../contracts/AO.sol");
const EtherDivvy = artifacts.require("../contracts/EtherDivvy.sol")
const Crowdsale = artifacts.require("../contracts/Crowdsale.sol")

module.exports = function(deployer) {
  deployer.deploy(AO)
  deployer.deploy(EtherDivvy)
  deployer.deploy(Crowdsale)
};
