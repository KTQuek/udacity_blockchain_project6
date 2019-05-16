
var SupplyChain = artifacts.require("./SupplyChain.sol");

module.exports = function(deployer) {

  deployer.deploy(SupplyChain).then(() => console.log("address: " + SupplyChain.address));
  
};
