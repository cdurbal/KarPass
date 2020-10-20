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

    struct MappingWaitingEvent {
        uint256 size;
        mapping(uint => Event) data;
        MappingIndex index;
    }

    struct MappingIndex {
        uint size;
        mapping(uint => uint256) data;
    }

    struct MappingOwner {
        uint size;
        mapping(uint => Owner) data;
    }

 

    struct Event {
        address sender;
        string description;
        uint256 date;
        uint256 expirationDate;
        uint km;
        bool exists;
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
        MappingWaitingEvent waitingEvents;
        MappingOwner historyOwners;

        bool exists;
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
        Create a modifier that throws an error if not the event creator.
    */
    modifier requireEventCreator(uint256 idPassport, uint256 idEvent) {
        require(
            _passport[idPassport].waitingEvents.data[idEvent].sender >= msg.sender,
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
            "Not enougth token"
        );
        _;
    }

    /*
        Create a modifier that throws an error if the msg.sender has not the require token number.
    */
    modifier requireLockedToken(address sender, uint numToken) {
        require(
            numToken<=_lockedBalance[sender],
            "Not enougth locked token"
        );
        _;
    }

    /*
        Create a modifier that throws an error if the msg.sender has not the require token number.
    */
    modifier requirePassportToken(uint256 idPassport, uint numToken) {
        require(
            _passport[idPassport].balance>=numToken,
            "Not enougth token on passport"
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
            PASSPORT_PRICE<=_balance[acquirer]+KarToken(_tokenContractAddr).allowance(acquirer, address(this)),
            "Not enought token"
        );
        _;
    }

    /*
        Create a modifier that throws an error if the acquirer has not enougth token.
    */
    modifier requireAvailableToken(address sender, uint numToken){
        require(
            numToken<=_balance[sender]+KarToken(_tokenContractAddr).allowance(sender, address(this)),
            "Not enought token"
        );
        _;
    }

    /*
        Create a modifier that throws an error if the passport does not exist.
    */
    modifier requireExists(uint256 passportId) {
        require(
            _passport[passportId].exists,
            "the passport does not exist"
        );
        _;
    }

    /*
        Create a modifier that throws an error if event does not exist.
    */
    modifier requireEventExists(uint256 passportId, uint256 idEvent) {
        require(
            _passport[passportId].events.size > 0 && _passport[passportId].events.data[idEvent].exists,
            "the passport does not exist"
        );
        _;
    }

    /*
        Create a modifier that throws an error if waiting event does not exist.
    */
    modifier requireWaitingEventExists(uint256 passportId, uint idEvent) {
        require(
            _passport[passportId].waitingEvents.size > 0 && _passport[passportId].waitingEvents.data[idEvent].exists,
            "the passport does not exist"
        );
        _;
    }


    /*
        constructor
    */
    constructor(address tokenContractAddr)
    public payable
    {
        _tokenContractAddr = tokenContractAddr;
    }

    /*
        createPassport
    */
    function createPassport(string memory name,
                            string memory id,
                            string memory brand,
                            string memory modele,
                            uint256 year,
                            string memory numberPlate)
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
        _passport[_totalPassport].exists = true;

        //Update search with address index
        _passportIdentifiants[msg.sender].size++;
        uint indexPassportId = _passportIdentifiants[msg.sender].size;
        _passportIdentifiants[msg.sender].data[indexPassportId] = _totalPassport;

        return _totalPassport;
    }

    /**
     * deletePassport
     */
    function totalPassport(address owner)
    public view returns(uint){
        return _passportIdentifiants[owner].size;
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
    public view returns (uint256[] memory){
        uint256[] memory memoryArray = new uint256[](_passportIdentifiants[msg.sender].size);

        for(uint i = 0; i < _passportIdentifiants[msg.sender].size; i++) {
            memoryArray[i] = _passportIdentifiants[msg.sender].data[i+1];
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
    returns (address, string memory, uint256, uint256, uint) {
        Event memory e = _passport[idPassport].events.data[eventIndex];
         return (e.sender,
                e.description,
                e.date,
                e.expirationDate,
                e.km);
    }

    /**
    * passportWaitingEvents
    */
    function passportWaitingEvents(uint256 idPassport, uint eventIndex)
    public view requireExists(idPassport) requireWaitingEventExists(idPassport, eventIndex)
    returns (address, string memory, uint256, uint256, uint) {

        Event memory e = _passport[idPassport].waitingEvents.data[eventIndex];
         return (e.sender,
                e.description,
                e.date,
                e.expirationDate,
                e.km);
    }

    /**
    * passportWaitingEventsIDs
    */
    function passportWaitingEventsIDs(uint256 idPassport)
    public view requireExists(idPassport)
    returns (uint256[] memory){
        uint256[] memory memoryArray = new uint256[](_passport[idPassport].waitingEvents.index.size);

        for(uint i = 0; i < _passport[idPassport].waitingEvents.index.size; i++) {
            if(msg.sender==_passport[idPassport].waitingEvents.data[i+1].sender ||
                msg.sender==_passport[idPassport].owner){
                memoryArray[i] = _passport[idPassport].waitingEvents.index.data[i+1];
            }
        }
        return memoryArray;
    }

    /**
    * createEvent
    */
    function createEvent(uint256 idPassport,
                        string memory description,
                        uint256 date,
                        uint256 expirationDate,
                        uint km)
    public requireToken(TOKEN_EVENT_LOCK) returns (bool){
        _lockToken(msg.sender, TOKEN_EVENT_LOCK);

        _passport[idPassport].waitingEvents.size++;
        _passport[idPassport].waitingEvents.data[_passport[idPassport].waitingEvents.size].sender = msg.sender;
        _passport[idPassport].waitingEvents.data[_passport[idPassport].waitingEvents.size].description = description;
        _passport[idPassport].waitingEvents.data[_passport[idPassport].waitingEvents.size].date = date;
        _passport[idPassport].waitingEvents.data[_passport[idPassport].waitingEvents.size].expirationDate = expirationDate;
        _passport[idPassport].waitingEvents.data[_passport[idPassport].waitingEvents.size].km = km;
        _passport[idPassport].waitingEvents.data[_passport[idPassport].waitingEvents.size].exists = true;

        _passport[idPassport].waitingEvents.index.size++;
        uint256 idEvent = _passport[idPassport].waitingEvents.size;
        _passport[idPassport].waitingEvents.index.data[_passport[idPassport].waitingEvents.index.size] = idEvent;
        return true;
    }

    /**
    * approveEvent
    */
    function approveEvent(uint256 idPassport, uint idEvent)
    public requireOwner(idPassport) requirePassportToken(idPassport, TOKEN_EVENT_REWARD) returns (bool)
    {
         address eventSender = _passport[idPassport].waitingEvents.data[idEvent].sender;
        _unlockToken(eventSender, TOKEN_EVENT_LOCK);
        _passport[idPassport].balance = _passport[idPassport].balance.sub(TOKEN_EVENT_REWARD);
        _balance[eventSender] = _balance[eventSender].add(TOKEN_EVENT_REWARD);

        _passport[idPassport].events.size++;
        _passport[idPassport].events.data[_passport[idPassport].events.size] = _passport[idPassport].waitingEvents.data[idEvent];

        _deleteWaitingEvent(idPassport, idEvent);
        return true;
    }

    /**
    * approveEvent
    */
    function dismissEvent(uint256 idPassport, uint idEvent)
    public requireOwner(idPassport) returns (bool)
    {
        _unlockToken(_passport[idPassport].waitingEvents.data[idEvent].sender, TOKEN_EVENT_LOCK);
        _deleteWaitingEvent(idPassport, idEvent);
        return true;
    }

    /**
    * approveEvent
    */
    function cancelEvent(uint256 idPassport, uint idEvent)
    public requireEventCreator(idPassport, idEvent) returns (bool)
    {
        _unlockToken(_passport[idPassport].waitingEvents.data[idEvent].sender, TOKEN_EVENT_LOCK);
        _deleteWaitingEvent(idPassport, idEvent);
        return true;
    }

    /**
    * _deleteWaitingEvent
    */
    function _deleteWaitingEvent(uint256 idPassport, uint idToDelete)
    private returns (bool)
    {
        //retreive idToDelete from index table
        uint indexToDelete = 0;
        for(uint i = 1; i < _passport[idPassport].waitingEvents.index.size+1; i++) {
            if(_passport[idPassport].waitingEvents.index.data[i]==idToDelete){
                indexToDelete = i;
            }
        }

        //delete from index table
        uint indexMax = _passport[idPassport].waitingEvents.index.size;
        if(indexToDelete>0){
            if(indexToDelete < indexMax){
                _passport[idPassport].waitingEvents.index.data[indexToDelete] = _passport[idPassport].waitingEvents.index.data[indexMax];
            }
            delete(_passport[idPassport].waitingEvents.index.data[indexMax]);
            _passport[idPassport].waitingEvents.index.size--;
        }

        //delete the waiting event
        delete(_passport[idPassport].waitingEvents.data[idToDelete]);
    }

    /**
    * _lockToken
    */
    function _lockToken(address sender, uint numToken)
    private requireToken(numToken) returns (bool)
    {
        _lockedBalance[sender] = _lockedBalance[sender].add(numToken);
        _balance[sender] = _balance[sender].sub(numToken);
    }

    /**
    * _unlockToken
    */
    function _unlockToken(address sender, uint numToken)
    private requireLockedToken(sender, numToken) returns (bool)
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

    /**
     * balance
     */
    function lockedBalance() public view returns (uint) {
        return _lockedBalance[msg.sender];
    }

    /**
     * passport
     **/
    function passport(uint256 identifiant)
    public view requireExists(identifiant) returns (string memory, string memory, string memory, string memory, uint256, string memory, uint256, uint256, uint256)
    {
        Passport memory p = _passport[identifiant];
        return (p.identity.name,
                p.identity.id,
                p.identity.brand,
                p.identity.modele,
                p.identity.year,
                p.identity.numberPlate,
                p.km,
                p.technicalControlExpirationDate,
                p.insuranceExpirationDate);
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


}
