var karToken = artifacts.require("KarToken");
var karPassport = artifacts.require("KarPassport");

module.exports = function(deployer) {
  deployer.deploy(karToken, 1000000000000000, "KarPassport", "KAR", "0xc0A9c1509eA5A34DcB3028a7BC9Bb353c4B2fc23").then(() => {
    return deployer.deploy(karPassport, karToken.address);
  });
  //deployer.deploy(karPassport, karToken.at("address"));
};