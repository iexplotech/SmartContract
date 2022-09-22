// programmer: Dr. Mohd Anuar
// tutorial: INSPEM, UPM 2022
// "SPDX-License-Identifier: GPL3+" 

pragma solidity ^0.7.6;

contract control {
    address investigator = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    address admin = 0x583031D1113aD414F02576BD6afaBfb302140225;
    modifier onlyInvestigator {
        require(msg.sender == investigator, 
        "You are not Investigator");
        _;
    }
    modifier onlyAdmin {
        require(msg.sender == admin, 
        "You are not Admin");
        _;
    }
}

contract policy is control {

    function whoami () public view returns (address){
        return msg.sender;
    }

    function contractInfo () public view returns (address) {
        return address(this);
    }

    function serial() internal view onlyInvestigator returns (string memory) {
        return "SF1391";
    }
}

contract hello is policy {
    // variable datatype: public, internal, private
    string name;
    uint8 age;

    constructor() {
        name = "no name";
        age = 18;
    }

    function getSerialNo() public view returns(string memory) {
        return serial();
    }

    function setName(string memory _name) public onlyAdmin {
        name = _name;
    }
    function setAge(uint8 _age) public onlyAdmin {
        age = _age;
    }
    function setNameAge(string memory _name, uint8 _age) public onlyAdmin {
        name = _name;
        age = _age;
    }
    function displayName() public view returns(string memory Name) {
        return name;
    }
    function displayAge() public view returns(uint8 Age) {
        return age;
    }
    function displayNameAge() public view returns(string memory Name, uint8 Age) {
        return (name,age);
    }
}