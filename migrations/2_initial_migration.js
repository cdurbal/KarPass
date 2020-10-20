var karToken = artifacts.require("KarToken");
var karPassport = artifacts.require("KarPassport");

module.exports = function(deployer) {
  deployer.deploy(karToken, 1000000000000000, "KarPassport", "KAR", "0x858f82a0a8179a995d0AB9226C22bF19CD7e0724").then(() => {
    return deployer.deploy(karPassport, karToken.address);
  });
  //deployer.deploy(karPassport, karToken.at("address"));
};