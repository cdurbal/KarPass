var karToken = artifacts.require("KarToken");
//var karPassport = artifacts.require("KarPassport");

module.exports = function(deployer) {
  deployer.deploy(karToken, 10000, "KarPassport", "KAR");
  //deployer.deploy(karPassport, karToken.at("address"));
};