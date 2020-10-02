/*
    SPDX-License-Identifier: UNLICENSED"
*/
pragma solidity ^0.7.0;
//pragma experimental ABIEncoderV2;

import {KarToken} from "./KarToken.sol";

contract KarPassport {


    event TransfertToken(address sender, address passport, uint amount, uint senderBalance);

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    uint   PASSPORT_PRICE = 10;

    //contract info
    address payable public _owner;
    uint256 private _balance;
    
    address private _tokenContractAddr;

    // car info
    string private _name;
    string private _id;
    string private _brand;
    string private _modele;
    uint256 private _year;
    uint256 private _releaseDate;
    string private _oilType;
    string private _gearbox;
    string private _outColor;
    string private _inColor;
    uint256 private _numberOfDoor;
    uint256 private _numberOfPlace;
    uint256 private _power;
    string [] private _options;

    //car variable
    uint256 private _km;
    uint256 private _technicalControlExpirationDate;
    uint256 private _insuranceExpirationDate;
    string private _numberplate;

    //car event
    Event [] events;
    Event [] toBeValidatedEvents;
    Owner [] historyOwners;

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


    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier requireOwner() {
        require(
            msg.sender == _owner,
            "Not owner"
        );
        _;
    }


    /*
        constructor
    */
    constructor(address tokenContractAddr,
                string memory name, string memory id, string memory brand, string memory modele, uint256 year, uint256 releaseDate, 
                string memory oilType, string memory gearbox, string memory outColor, string memory inColor, uint256 numberOfDoor, 
                uint256 numberOfPlace, uint256 power)
    {
        
        _tokenContractAddr = tokenContractAddr;
        _owner = msg.sender;
        _name=name;
        _id=id;
        _brand=brand;
        _modele=modele;
        _year=year;
        _releaseDate=releaseDate;
        _oilType=oilType;
        _gearbox=gearbox;
        _outColor=outColor;
        _inColor=inColor;
        _numberOfDoor=numberOfDoor;
        _numberOfPlace=numberOfPlace;
        _power=power;
        //_options=options;
    }
    
    
    function activate()
    public returns (bool)
    {
        TransfertToken(msg.sender, address(this), PASSPORT_PRICE, 0);
        KarToken token = KarToken(_tokenContractAddr);
        require(token.balanceOf(msg.sender) >= PASSPORT_PRICE, "Not enought KAR");
        TransfertToken(msg.sender, address(this), PASSPORT_PRICE, token.balanceOf(msg.sender));
        token.transferFrom(msg.sender, address(this), PASSPORT_PRICE);
        TransfertToken(msg.sender, address(this), PASSPORT_PRICE, token.balanceOf(msg.sender));
        
        _balance += PASSPORT_PRICE;
        
        return true;
    }
    
    /**
     * @dev Returns the name
     */
    function balance() public view returns (uint256) {
        return _balance;
    }


    /**
     * @dev Returns the name
     */
    function name() public view returns (string memory) {
        return _name;
    }


    /**
     * @dev Returns the id
     */
    function id() public view returns (string memory) {
        return _id;
    }

    /**
     * @dev Returns the brand
     */
    function brand() public view returns (string memory) {
        return _brand;
    }

    /**
     * @dev Returns the modele
     */
    function modele() public view returns (string memory) {
        return _modele;
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
