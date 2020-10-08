pragma solidity >= 0.5.0 < 0.7.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/KarPassport.sol";
import "../contracts/KarToken.sol";

contract TestKarPassport {
 // The address of the adoption contract to be tested
 KarToken token = KarToken(DeployedAddresses.KarToken());
 

 //The expected owner of adopted pet is this contract
 address expectedRichMan = 0xc0A9c1509eA5A34DcB3028a7BC9Bb353c4B2fc23;
 address testAddress = address(this);

function testUserCanAdoptPet0() public {
  token.testTransfer(expectedRichMan, testAddress, 100);
}

 // Testing the adopt() function
function testUserCanAdoptPet() public {
  
  KarPassport passport = new KarPassport(DeployedAddresses.KarToken());
  //KarPassport passport = KarPassport(passportAddress);
  passport.activate();

  //uint returnedBalance = token.balanceOf(expectedRichMan);
  //uint returnedtestBalance = token.balanceOf(testAddress);
  uint returnedTestBalanceActivate = token.balanceOf(testAddress);

  Assert.equal(returnedTestBalanceActivate, 90, "fuck");
  //Assert.equal(returnedtestBalance, 100, "comparing test and creator of contract balance");
  //Assert.equal(returnedBalance, 9900, "Adoption of the expected pet should match what is returned.");
}

/*
// Testing retrieval of a single pet's owner
function testGetAdopterAddressByPetId() public {
  address adopter = karPassport.adopters(expectedPetId);

  Assert.equal(adopter, expectedAdopter, "Owner of the expected pet should be this contract");
}

// Testing retrieval of all pet owners
function testGetAdopterAddressByPetIdInArray() public {
  // Store adopters in memory rather than contract's storage
  address[16] memory adopters = karPassport.getAdopters();

  Assert.equal(adopters[expectedPetId], expectedAdopter, "Owner of the expected pet should be this contract");
}*/

}