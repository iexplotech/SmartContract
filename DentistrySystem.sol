// Programmer: Ts. Dr. Mohd Anuar Mat Isa, anuarls@hotmail.com
// Website: https://github.com/iexplotech  http://blockscout.iexplotech.com, www.iexplotech.com
// Smart Contract Name: DentistrySystem
// Notice: Tutorial for Programming Smart Contract
// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.6.12;

contract Admin {
    
    address payable internal owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
        
    function getOwner() public view returns (address) {
        return (owner);
    }
    
    function whoAmI() public view returns (address) {
        return msg.sender;
    }
    
    function kill() public onlyOwner{
        selfdestruct(owner);
    }
}

contract MedicalOfficer is Admin {
    
    address internal dentist;
    
    function setDentist(address newDentist) public onlyOwner {
        dentist = newDentist;
    }
    
    function getDentist() public view returns (address Dentist) {
        return dentist;  
    }
    
    modifier onlyDentist {
        require(msg.sender == dentist);
        _;
    }
    
}

contract DentistrySystem is MedicalOfficer {
    // type of variables: public, private, internal (protected) 

    string internal name;
    uint8 internal age;
    
    struct patient {
        string name;
        uint8 age;
        string dateCheckup;
    }
    
    mapping(address=>patient) internal patientInfo;
    
    constructor() public {
        owner = msg.sender;
    }
    
    // Only dentist can add new patient
    function setPatient(address newPatient, string memory newName, uint8 newAge, string memory newDateCheckup) public onlyDentist {
        patientInfo[newPatient].name = newName;
        patientInfo[newPatient].age = newAge;
        patientInfo[newPatient].dateCheckup = newDateCheckup;
    }
    
    // Only dentist can view all patients
    function getPatient(address newPatient) public view onlyDentist returns (string memory Name, uint8 Age, string memory DateCheckup) {
        return (patientInfo[newPatient].name, patientInfo[newPatient].age, patientInfo[newPatient].dateCheckup);
    }
    
    // Only patient can view it own medical record
    function getMyRecord() public view returns (string memory Name, uint8 Age, string memory DateCheckup) {
        return (patientInfo[msg.sender].name, patientInfo[msg.sender].age, patientInfo[msg.sender].dateCheckup);
    }
    
    
    
}