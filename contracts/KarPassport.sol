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
    uint   PASSPORT_PRICE = 100;
    uint   TOKEN_EVENT_LOCK = 10;
    uint   TOKEN_EVENT_REWARD = 1;

    uint256 _totalPassport = 0;
    mapping (uint => Passport) _passport;
    mapping (address => Mapping) _passportIdentifiants;
    address _tokenContractAddr;
    mapping (address => uint) _balance;
    mapping (address => uint) _lockedBalance;

    //Typologies
    struct Mapping {
        uint size;
        mapping(uint => uint) data;
    }

    struct MappingEvent {
        uint size;
        mapping(uint => Event) data;
    }

    struct MappingOwner {
        uint size;
        mapping(uint => Owner) data;
    }

    
    
    enum EventType { Insurance, Repairing, TechnicalControl, Accident, Upgrade }

    struct Event {
        EventType typeEvent;
        string description; 
        address contributor; 
        string interventions;
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
        uint256  releaseDate;
        string  oilType;
        string  gearbox;
        string  outColor;
        string  inColor;
        uint  numberOfDoor;
        uint numberOfPlace;
        uint  power;
        Mapping  options;
        
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
        MappingEvent events;
        MappingEvent toBeValidatedEvents;
        MappingOwner historyOwners;
        
        bool exist;
    }


    /*
        Create a modifier that throws an error if the sender has no allowance.
    */
    modifier requireTokenAllowance(address sender) {
        require(
            KarToken(_tokenContractAddr).allowance(sender, address(this)) >= 0,
            "No token allowed"
        );
        _;
    }

    /*
        Create a modifier that throws an error if the msg.sender has not the require token number.
    */
    modifier requireToken(uint numToken) {
        require(
            numToken<=_balance[msg.sender], 
            "Not enought token"
        );
        _;
    }

    /*
        Create a modifier that throws an error if the msg.sender has not the require token number.
    */
    modifier requireLockedToken(uint numToken) {
        require(
            numToken<=_lockedBalance[msg.sender], 
            "Not enought locked token"
        );
        _;
    }
    
    
    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier requireOwner(uint256 passportId) {
        require(
            _passport[passportId].owner == msg.sender, 
            "Not owner"
        );
        _;
    }
    
    /*
        Create a modifier that throws an error if the acquirer has not enougth token.
    */
    modifier requirePassportPrice(address acquirer){
        require(
            PASSPORT_PRICE <=_balance[acquirer] + KarToken(_tokenContractAddr).allowance(acquirer, address(this)), 
            "Not enought token"
        );
        _;
    }

    /*
        Create a modifier that throws an error if the acquirer has not enougth token.
    */
    modifier requireAvailableToken(address sender, uint numToken){
        require(
            numToken <=_balance[sender] + KarToken(_tokenContractAddr).allowance(sender, address(this)), 
            "Not enought token"
        );
        _;
    }

    /*
        Create a modifier that throws an error if the passport does not exist.
    */
    modifier requireExists(uint256 passportId) {
        require(
            _passport[passportId].exist, 
            "the passport does not exist"
        );
        _;
    }

    /*
        Create a modifier that throws an error if event does not exist.
    */
    modifier requireEventExists(uint256 passportId, uint index) {
        require(
            _passport[passportId].events.size > 0 && _passport[passportId].events.size <= index, 
            "the passport does not exist"
        );
        _;
    }


    /*
        constructor
    */
    constructor(address tokenContractAddr)
    public
    {  
        _tokenContractAddr = tokenContractAddr;
    }
    
    /*
        createPassport
    */
    function createPassport(string memory name, string memory id, string memory brand, string memory modele, uint256 year, string memory numberPlate)
    public returns (uint256)
    {
        require(_balance[msg.sender] >= PASSPORT_PRICE, "Not enought token");

        _balance[msg.sender] = _balance[msg.sender].sub(PASSPORT_PRICE);
        
        _totalPassport++;
        _passport[_totalPassport].owner = msg.sender;
        _passport[_totalPassport].identity.name = name;
        _passport[_totalPassport].identity.id = id;
        _passport[_totalPassport].identity.brand = brand;
        _passport[_totalPassport].identity.modele = modele;
        _passport[_totalPassport].identity.year = year;
        _passport[_totalPassport].identity.numberPlate = numberPlate;
        _passport[_totalPassport].balance = PASSPORT_PRICE;
        _passport[_totalPassport].exist = true;
        
        //Update search with address index
        _passportIdentifiants[msg.sender].size++;
        uint indexPassportId = _passportIdentifiants[msg.sender].size;
        _passportIdentifiants[msg.sender].data[indexPassportId] = _totalPassport;
        
        return _totalPassport;
    }
    
    /**
     * deletePassport
     */
    function deletePassport(uint256 passportId) 
    public requireOwner(passportId) returns (bool){
        
        _balance[msg.sender] = _balance[msg.sender].add(_passport[passportId].balance);
        delete(_passport[passportId]);

        //delete from owner table
        uint indexToDelete = 0;
        for(uint i = 1; i < _passportIdentifiants[msg.sender].size+1; i++) {
            if(_passportIdentifiants[msg.sender].data[i]==passportId){
                indexToDelete = i;
            }
        }

        return _deleteMappingItem(indexToDelete);
    }

    /**
        _deleteMappingItem
     */
    function _deleteMappingItem(uint indexToDelete)
    private returns (bool){
        uint indexMax = _passportIdentifiants[msg.sender].size;
        if(indexToDelete>0){
            if(indexToDelete < indexMax){
                _passportIdentifiants[msg.sender].data[indexToDelete] = _passportIdentifiants[msg.sender].data[indexMax];
            }
            delete(_passportIdentifiants[msg.sender].data[indexMax]);
            _passportIdentifiants[msg.sender].size--;
        }

        return true;
    }
    
    /**
     * transferAllowedToken
     */
    function transferAllowedToken() 
    public returns (bool) {
        return _transferAllowedToken(msg.sender);
    }
    
    /**
     * _transferAllowedToken
     */
    function _transferAllowedToken(address sender)
    private requireTokenAllowance(sender) returns (bool){
        KarToken token = KarToken(_tokenContractAddr);
        uint numToken = token.allowance(sender, address(this));
         _balance[sender] = _balance[sender].add(numToken);
        token.transferFrom(sender, address(this), numToken);
        emit TransfertToken(sender, address(this), numToken, _balance[sender]);
        return true;
    }
    
    /**
     * withdrawToken
     */
    function withdrawToken(uint numToken)
    public requireToken(numToken) returns (bool){
        KarToken token = KarToken(_tokenContractAddr);
        token.transfer(msg.sender, numToken);
        _balance[msg.sender] = _balance[msg.sender].sub(numToken);
        return true;
    }
    
    /**
     * transferPassport
     */
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
    
    /**
     * passportIdentifiants
     */
    function passportIdentifiants()
    public view returns (uint[] memory){
        uint[] memory memoryArray = new uint[](_passportIdentifiants[msg.sender].size);

        for(uint i = 0; i < _passportIdentifiants[msg.sender].size; i++) {
            memoryArray[i] = _passportIdentifiants[msg.sender].data[i];
        }
        return memoryArray;
    }
    
    /**
     * @dev Returns the number of event
     */
    function eventsNumber(uint256 idPassport) public view returns (uint) {
        return _passport[idPassport].events.size;
    }

    /**
        passportEvent
     */
    function passportEvent(uint256 idPassport, uint eventIndex) 
    public view requireExists(idPassport) requireEventExists(idPassport, eventIndex) 
    returns (EventType, string memory, address, string memory, uint256, uint, string memory, uint256) {
         return (_passport[idPassport].events.data[eventIndex].typeEvent,
                _passport[idPassport].events.data[eventIndex].description,
                _passport[idPassport].events.data[eventIndex].contributor,
                _passport[idPassport].events.data[eventIndex].interventions,
                _passport[idPassport].events.data[eventIndex].date,
                _passport[idPassport].events.data[eventIndex].price,
                _passport[idPassport].events.data[eventIndex].currency,
                _passport[idPassport].events.data[eventIndex].expirationDate);
    }

    /**
    * createEvent
    */
    function createEvent(uint256 idPassport, 
                            EventType typeEvent,
                            string memory description,
                            string memory interventions,
                            uint256 date,
                            uint price,
                            string memory currency,
                            uint256 expirationDate) 
    public requireToken(TOKEN_EVENT_LOCK) returns (bool){
        _lockToken(msg.sender, TOKEN_EVENT_LOCK);
        _passport[idPassport].toBeValidatedEvents.size++;
        _passport[idPassport].toBeValidatedEvents.data[_passport[idPassport].toBeValidatedEvents.size].typeEvent=typeEvent;
        _passport[idPassport].toBeValidatedEvents.data[_passport[idPassport].toBeValidatedEvents.size].description=description;
        _passport[idPassport].toBeValidatedEvents.data[_passport[idPassport].toBeValidatedEvents.size].contributor=msg.sender;
        _passport[idPassport].toBeValidatedEvents.data[_passport[idPassport].toBeValidatedEvents.size].interventions=interventions;
        _passport[idPassport].toBeValidatedEvents.data[_passport[idPassport].toBeValidatedEvents.size].date=date;
        _passport[idPassport].toBeValidatedEvents.data[_passport[idPassport].toBeValidatedEvents.size].price=price;
        _passport[idPassport].toBeValidatedEvents.data[_passport[idPassport].toBeValidatedEvents.size].currency=currency;
        _passport[idPassport].toBeValidatedEvents.data[_passport[idPassport].toBeValidatedEvents.size].expirationDate=expirationDate;
        return true;
    }

    /**
    * approveEvent
    */
    function approveEvent(uint256 idPassport, uint index)
    public requireToken(TOKEN_EVENT_REWARD) returns (bool)
    {
        
        _unlockToken(_passport[idPassport].toBeValidatedEvents.data[index].contributor, TOKEN_EVENT_LOCK);
        return true;
    }

    /**
    * _lockToken
    */
    function _lockToken(address sender, uint numToken)
    public requireToken(numToken) returns (bool)
    {
        _lockedBalance[sender] = _lockedBalance[sender].add(numToken);
        _balance[sender] = _balance[sender].sub(numToken);
    }

    /**
    * _unlockToken
    */
    function _unlockToken(address sender, uint numToken)
    public requireLockedToken(numToken) returns (bool)
    {
        _lockedBalance[sender] = _lockedBalance[sender].sub(numToken);
        _balance[sender] = _balance[sender].add(numToken);
    }


    /**
     * @dev Returns the name
     */
    function balance(uint256 idPassport) public view returns (uint256) {
        return _passport[idPassport].balance;
    }
    
    /**
     * balance
     */
    function balance() public view returns (uint) {
        return _balance[msg.sender];
    }

    function passport(uint256 identifiant)
    public view requireExists(identifiant) returns (string memory, string memory, string memory, string memory, uint256, string memory, uint256, uint256, uint256)
    {
        return (_passport[identifiant].identity.name,
                _passport[identifiant].identity.id,
                _passport[identifiant].identity.brand,
                _passport[identifiant].identity.modele,
                _passport[identifiant].identity.year,
                _passport[identifiant].identity.numberPlate,
                _passport[identifiant].km,
                _passport[identifiant].technicalControlExpirationDate,
                _passport[identifiant].insuranceExpirationDate);
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
