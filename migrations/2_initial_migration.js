var karPassport = artifacts.require("KarPassport");

module.exports = function(deployer) {
  deployer.deploy(karPassport);
};