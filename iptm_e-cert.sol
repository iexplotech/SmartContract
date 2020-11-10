// Programmer: Dr. Mohd Anuar Mat Isa, iExplotech & IPTM Secretariat
// Project: Sample Blockchain Based Electronic Certificate Verification System
// Website: https://github.com/iexplotech  http://blockscout.iexplotech.com, www.iexplotech.com
// License: GPL3


pragma solidity ^0.5.12;

contract Privileged {
    
    address payable owner;  // submit smart contract, owner of this smart contract
    address IPTM_Verifier; // verify smart contract, only IPTM Secretariat can do this
    address registrar; // submit certificate info
    // msg.sender is the current user that run this smart contract, limited privilege
    
    bool verifiedSmartContract; // true if this smart contract passed verification by IPTM_Verifier
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyIPTM_Verifier {
        require(msg.sender == IPTM_Verifier);
        _;
    }
    
    modifier onlyRegistrar {
        require(msg.sender == registrar);
        _;
    }
    
    constructor () public {
        owner = msg.sender;
        //IPTM_Verifier = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C; // Simulate on Remix VM
        //registrar  = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB; // Simulate on Remix VM
        
        IPTM_Verifier = 0x80Ce17271FfA4a7F66E2cbF3561a6946587F470D; // Run on IPTM Blockchain
        registrar  = 0xcC2Fb9D68140CAEA8D29B9E51bd0f24bbD1b071A; // Run on IPTM Blockchain
        
        verifiedSmartContract = false;
    }
    
    function whoAmI() public view returns (address) {
        return msg.sender;
    }
    
    function whoSmartContractVerifier() public view returns (address) {
        return IPTM_Verifier;
    }
    
    function whoOwner() public view returns (address) {
        return owner;
    }
    
    function whoRegistrar() public view returns (address) {
        return registrar;
    }
    
    function setSmartContractVerification (bool newStatus) public onlyIPTM_Verifier {
        verifiedSmartContract = newStatus;
    }
    
    function getSmartContractVerification () public view returns (bool)  {
        return verifiedSmartContract;
    }
    
    function kill() public onlyOwner {
            selfdestruct(owner);
    }
}

contract IPTM_E_Certificate is Privileged {

    // university
    struct certificate {
        string name;
        string programme;
        string semesterGraduate;
        string convocation;
    }
    
    struct personal {
        string name;
        string NRIC; // National Registration Identity Card
    }
    
    mapping (address=>certificate) internal gradCert;
    mapping (address=>personal) internal myPersonal;
    
    constructor () public {
        
    }
    
    function setCertInfo(address newAddress, string memory newName, string memory  newProgramme, 
                            string memory  newSemesterGraduate, string memory  newConvocation) public onlyRegistrar {
        gradCert[newAddress].name = newName;
        gradCert[newAddress].programme = newProgramme;
        gradCert[newAddress].semesterGraduate = newSemesterGraduate;
        gradCert[newAddress].convocation = newConvocation;
    }
    
    function getCertInfo(address newAddress) public onlyRegistrar view returns (string memory, string memory, 
                            string memory, string memory) {
        return(gradCert[newAddress].name, gradCert[newAddress].programme, gradCert[newAddress].semesterGraduate, 
                gradCert[newAddress].convocation);
    }
    
    function getMyCertInfo() public view returns (string memory, string memory, string memory, string memory) {
        return(gradCert[msg.sender].name, gradCert[msg.sender].programme, gradCert[msg.sender].semesterGraduate, 
                gradCert[msg.sender].convocation);
    }
    
    function setMyPersonalInfo(string memory newName, string memory newNRIC) public {
        myPersonal[msg.sender].name = newName;
        myPersonal[msg.sender].NRIC= newNRIC;

    }
    
    function getMyPersonalInfo() public view returns (string memory, string memory){
        return(myPersonal[msg.sender].name, myPersonal[msg.sender].NRIC);
    }
    
    function getPersonalInfo(address newAddress) public onlyRegistrar view returns (string memory, string memory){
        return(myPersonal[newAddress].name, myPersonal[newAddress].NRIC);
    }
    
    
    
    // Testing and Debuging Functions
    function setDebugPersonalInfo () public {
         setMyPersonalInfo("MOHD ANUAR BIN MAT ISA", "820716001234");
    }
    
    function setDebugCertInfo(address newAddress) public onlyRegistrar {
        gradCert[newAddress].name = "MOHD ANUAR BIN MAT ISA";
        gradCert[newAddress].programme = "DOCTOR OF PHILOSOPHY IN ELECTRICAL ENGINEERING";
        gradCert[newAddress].semesterGraduate = "Session 1 2018/2019";
        gradCert[newAddress].convocation = "MARCH 2019";
    }
    
    function setDebugSmartContractVerification () public onlyIPTM_Verifier {
        setSmartContractVerification (true);
    }
}

