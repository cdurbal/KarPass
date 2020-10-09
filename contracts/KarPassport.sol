/*
    SPDX-License-Identifier: UNLICENSED"
*/
pragma solidity >= 0.5.0 < 0.7.0;
//pragma experimental ABIEncoderV2;

import {KarToken} from "./KarToken.sol";
import {SafeMath} from "./libraries/SafeMath.sol";

contract KarPassport {
    using SafeMath for uint;

    event TransfertToken(address sender, address contractAddress, uint amount, uint senderBalance);

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    uint   PASSPORT_PRICE = 10;
    uint256 _totalPassport = 0;
    mapping (uint => Passport) _passport;
    mapping (address => mapping(uint => uint)) _owner;
    mapping (address =>Mapping) _numPassport;
    address _tokenContractAddr;
    mapping (address => uint) _balance;
    Event [] _events;

    //Typologies
    struct Mapping {
        uint size;
        mapping(uint => uint) data;
    }
    
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
        address owner;
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
    modifier requireTokenAllowance(address sender) {
        require(
            KarToken(_tokenContractAddr).allowance(sender, address(this)) >= 0,
            "No token allowed"
        );
        _;
    }
    
    modifier requireToken(uint numToken) {
        require(
            numToken<=_balance[msg.sender], 
            "Not enought token"
        );
        _;
    }
    
    modifier requireOwner(uint256 passportId) {
        require(
            _passport[passportId].owner == msg.sender, 
            "Only owner can transfer passport"
        );
        _;
    }
    
    modifier requirePassportPrice(address acquirer){
        require(
            PASSPORT_PRICE <=_balance[acquirer] + KarToken(_tokenContractAddr).allowance(acquirer, address(this)), 
            "Not enought token"
        );
        _;
    }

    constructor(address tokenContractAddr)
    public
    {
        
        _tokenContractAddr = tokenContractAddr;
    }
    
    
    function createPassport(string memory name, string memory id, string memory brand, string memory modele, uint256 year, string memory numberPlate)
    public returns (uint256)
    {
        require(_balance[msg.sender] >= PASSPORT_PRICE, "Not enought token");

        _balance[msg.sender] = _balance[msg.sender].sub(PASSPORT_PRICE);
        
        CarIdentity memory identity = CarIdentity(name, id, brand, modele, year, numberPlate);
        _totalPassport++;
        _passport[_totalPassport].owner = msg.sender;
        _passport[_totalPassport].identity = identity;
        _passport[_totalPassport].balance = PASSPORT_PRICE;
        
        _numPassport[msg.sender].size++;
        _numPassport[msg.sender][_numPassport[msg.sender].size];
        _owner[msg.sender][_numPassport[msg.sender]] = _totalPassport;
        
        //_passport[_numberOfPassport] = Passport(identity, 0, 0, 0, PASSPORT_PRICE, events);
       // _passport[_numberOfPassport] = Passport(identity, 0, 0, 0, PASSPORT_PRICE, events, toBeValidatedEvents, historyOwners);
        
        return _totalPassport;
    }
    
    
    function deletePassport(uint256 passportId) 
    public returns (bool){
        
        _balance[msg.sender] = _balance[msg.sender].add(_passport[passportId].balance);
        delete(_passport[passportId]);
        
        return true;
    }
    
    function transferAllowedToken() 
    public returns (bool) {
        return _transferAllowedToken(msg.sender);
    }
    
    function _transferAllowedToken(address sender)
    private requireTokenAllowance(sender) returns (bool){
        KarToken token = KarToken(_tokenContractAddr);
        uint numToken = token.allowance(sender, address(this));
         _balance[sender] = _balance[sender].add(numToken);
        token.transferFrom(sender, address(this), numToken);
        emit TransfertToken(sender, address(this), numToken, _balance[sender]);
        return true;
    }
    
    
    function withdrawToken(uint numToken)
    public requireToken(numToken) returns (bool){
        KarToken token = KarToken(_tokenContractAddr);
        token.transfer(msg.sender, numToken);
        _balance[msg.sender] = _balance[msg.sender].sub(numToken);
        return true;
    }
    
    
    function transferPassport(uint256 passportId, address acquirer)
    public requireOwner(passportId) requirePassportPrice(acquirer) returns (bool){
        
        if(_balance[acquirer] < PASSPORT_PRICE){
            _transferAllowedToken(acquirer);
        }
        _balance[msg.sender] = _balance[msg.sender].add(_passport[passportId].balance);
        
        _balance[acquirer] = _balance[acquirer].sub(PASSPORT_PRICE);
        _passport[passportId].balance = PASSPORT_PRICE;
        _passport[passportId].owner = acquirer;
        
        return true;
    }
    
    
    function passportIdentifiants()
    public view returns (uint[] memory){
        uint[] memory memoryArray = new uint[](_numPassport[msg.sender].size);
        
        
        for(uint i = 0; i < _numPassport[msg.sender].size; i++) {
            memoryArray[i] = _numPassport[msg.sender][i];
        }
        return memoryArray;
    }
    
    /**
     * @dev Returns the name
     */
    function balance(uint256 idPassport) public view returns (uint256) {
        return _passport[idPassport].balance;
    }
    
    
    function balance() public view returns (uint) {
        return _balance[msg.sender];
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
