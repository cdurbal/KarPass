/*
    SPDX-License-Identifier: UNLICENSED"
*/
pragma solidity ^0.7.0;
//pragma experimental ABIEncoderV2;

import {KarToken} from "./KarToken.sol";
import {SafeMath} from "./libraries/SafeMath.sol";

contract KarPassport {
    using SafeMath for uint;

    event TransfertToken(address sender, address passport, uint amount, uint senderBalance);

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    uint   PASSPORT_PRICE = 10;
    uint256 _numberOfPassport = 0;
    mapping (uint => Passport) _passport;
    mapping (address => mapping(uint => uint)) _owner;
    address _tokenContractAddr;
    mapping (address => uint256) _balance;
    Event [] _events;

    //Typologies
    enum EventType { Insurance, Repairing, TechnicalControl, Accident, Upgrade }

    struct Event {
        EventType typeEvent;
        string description; 
        address contributor; 
        string [] interventions;
        uint256 date;
        uint price; 
        string currency;
        uint256 expirationDate;
    }

    struct Owner {
        address _owner;
        uint256 acquisitionDate;
    }
    
    struct CarIdentity{
        // car info
        string  name;
        string  id;
        string  brand;
        string  modele;
        uint256  year;
        //uint256  releaseDate;
        //string  oilType;
        //string  gearbox;
        //string  outColor;
        //string  inColor;
        //uint256  numberOfDoor;
        //  numberOfPlace;
        //uint256  power;
        //string []  options;
        
        string  numberPlate;
    }
    
    struct Passport {
        
        CarIdentity identity;
    
        //car variable
        uint256  km;
        uint256  technicalControlExpirationDate;
        uint256  insuranceExpirationDate;
        
        //contract variable
        uint256 balance;
        
        //car event
        mapping (uint => Event) events;
        mapping (uint => Event) toBeValidatedEvents;
        mapping (uint => Owner) historyOwners;
        
        uint numEvents;
        uint numToBeValidatedEvents;
        uint numHistoryOwners;
        
        bool exist;
        
        //Event [] events;
        //Event [] toBeValidatedEvents;
        //Owner [] historyOwners;
    }


    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier requireTokenAllowance() {
        require(
            KarToken(_tokenContractAddr).allowance(msg.sender, address(this)) >= 0,
            "No token allowed"
        );
        _;
    }



    
     constructor(address tokenContractAddr)
    {
        
        _tokenContractAddr = tokenContractAddr;
    }
    
    
    function createPassport(string memory name, string memory id, string memory brand, string memory modele, uint256 year, string memory numberPlate)
    public returns (uint256)
    {
        require(_balance[msg.sender] >= PASSPORT_PRICE, "Not enought token");

        _balance[msg.sender].sub(PASSPORT_PRICE);
        
        CarIdentity memory identity = CarIdentity(name, id, brand, modele, year, numberPlate);
        _numberOfPassport++;
        _passport[_numberOfPassport].identity = identity;
        _passport[_numberOfPassport].balance = PASSPORT_PRICE;
        
        //_passport[_numberOfPassport] = Passport(identity, 0, 0, 0, PASSPORT_PRICE, events);
       // _passport[_numberOfPassport] = Passport(identity, 0, 0, 0, PASSPORT_PRICE, events, toBeValidatedEvents, historyOwners);
        
        return _numberOfPassport;
    }
    
    
    function deletePassport(uint256 passportId) 
    public returns (bool){
        
        _balance[msg.sender].add(_passport[passportId].balance);
        delete(_passport[passportId]);
        
        return true;
    }
    
    function transferToken() public requireTokenAllowance() returns (bool) {
        KarToken token = KarToken(_tokenContractAddr);
        uint numToken = token.allowance(msg.sender, address(this));
        token.transferFrom(msg.sender, address(this), numToken);
        _balance[msg.sender].add(numToken);
        return true;
    }
    
    
    
    function withdrawToken(uint numToken) public returns (bool){
        require(numToken<=_balance[msg.sender], "Not enought token");
        KarToken token = KarToken(_tokenContractAddr);
        token.transfer(msg.sender, numToken);
        _balance[msg.sender].sub(numToken);
        return true;
    }
    
    
    /**
     * @dev Returns the name
     */
    function balance(uint256 idPassport) public view returns (uint256) {
        return _passport[idPassport].balance;
    }


    /**
     * @dev Returns the name
     */
    function name(uint256 idPassport) public view returns (string memory) {
        return _passport[idPassport].identity.name;
    }


    /**
     * @dev Returns the id
     */
    function id(uint256 idPassport) public view returns (string memory) {
        return _passport[idPassport].identity.id;
    }

    /**
     * @dev Returns the brand
     */
    function brand(uint256 idPassport) public view returns (string memory) {
        return _passport[idPassport].identity.brand;
    }

    /**
     * @dev Returns the modele
     */
    function modele(uint256 idPassport) public view returns (string memory) {
        return _passport[idPassport].identity.modele;
    }








    address[16] public adopters;
    
    // Adopting a pet
    function adopt(uint petId) public returns (uint) {
        require(petId >= 0 && petId <= 15);

        adopters[petId] = msg.sender;

        return petId;
    }

    // Retrieving the adopters
    function getAdopters() public view returns (address[16] memory) {
        return adopters;
    }


}
