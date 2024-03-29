// Programmer: Ts. Dr. Mohd Anuar Mat Isa, iExplotech & IPTM Secretariat, 2021
// Contact: anuarls@hotmail.com
// Project: Blockchain Digital Certificate Verification for IPT Malaysia, 2022
// Collaboration: Institusi Pendidikan Tinggi Malaysia (IPTM) Blockchain Testnet 2022
// Website: https://github.com/iexplotech  http://blockscout.iexplotech.com, www.iexplotech.com
// Smart Contract Name: IPTM_BlockchainCertificate
// Date: 25 August 2022
// Version: 1.1.1
// Notice: Any referrence, usage or modification of this smart contract without a proper citation (reference) 
//         is considered as plagarism!. Dear Student, do citation - it is a part of learning.
// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity ^0.7.6;

contract AccessControl {

    // Event Logs
    event _ChangeTrustedAgent(address TrustedAgent);

    address internal deployer; // who deploys this smartcontract into blockchain
    address payable internal owner;  // who owner this smartcontract
    address internal registrar; // who can write, read, update, delete all certificates
    address internal trustedAgent; // who can read all certificates - for webserver
    string contractName;
    string systemDeveloper;
    
    // onlyOwner can deploy and destroy contract;
    modifier onlyOwner {
        require(msg.sender == owner, "onlyOwner is Authorized!");
        _;
    }
    // onlyRegistrar can write, read, update, delete all data
    modifier onlyRegistrar {
        require(msg.sender == registrar, "onlyRegistrar is Authorized!");
        _;
    }
    // onlyTrustedAgent can read all data
    modifier onlyTrustedAgent {
        require(msg.sender == trustedAgent, "onlyTrustedAgent is Authorized!");
        _;
    }
    // onlyRegistrar or onlyTrustedAgent can read all data
    modifier onlyRegistrar_or_onlyTrustedAgent {
        if(msg.sender == registrar || msg.sender == trustedAgent)
            _;
        else revert("onlyRegistrar or onlyTrustedAgent is Authorized!");
        
    }
    
    function GetContractInfo() public view returns (string memory ContractName, address ContractAddress, 
        address Deployer, address Owner, address Registrar, address TrustedAgent, string memory SystemDeveloper) {
        return (contractName, address(this), deployer, owner, registrar, trustedAgent, systemDeveloper);
    }

    function ChangeTrustedAgent(address _trustedAgent) public onlyOwner {
        trustedAgent = _trustedAgent;
        emit _ChangeTrustedAgent(trustedAgent);
    }
    
    // Contract is no longer accessible, but all certificate records still in blockchain
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
    
    function whoAmI() public view returns (address) {
        return msg.sender;
    }
    
}

contract Library {
     // Solving Problem CompilerError: Stack too deep, try using fewer variables.
    function concat6StrPadding(string memory s1, string memory s2, string memory s3, string memory s4, string memory s5,
        string memory s6) internal pure returns (string memory) {
        return string(abi.encodePacked(s1, "::", s2, "::", s3, "::", s4, "::", s5, "::", s6)); // you can concat many input strings using padding ::
    }
    
    function concat2Str(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    // Source: https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    // Source: https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function strCompare(string memory _a, string memory _b) internal pure returns (int _returnCode) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    // Safe Maths
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "Overflow Add Operation");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "Underflow Subtraction Operation");
        c = a - b;
    }
}

// Deployed on Remix IDE 
// GAS LIMIT: 7000000
// EVM VERSION: istanbul
// Enable optimization: 200
// Latest Deployed Address: 0x7224a0ed70d46b53edc5791389e4c6a9a93d01fa  // Your address will be different!
contract IPTM_BlockchainCertificate is AccessControl, Library {
    
    // Event Logs
    event addedCertificate(string CertificateNo);
    event updatedCertificate(string CertificateNo);
    event deletedCertificate(string CertificateNo);
	
    // Certificate No is used as the index. Therefore it is data redundant to add it into this struct
    struct Certificate {
        string name;
        string ic;
        string studentId;
        string programme;
        string convoDate;
        string semesterFinish;
        string prev;  // Use for backward travesal searching Cert
        string next;  // Use for forward travesal searching Cert
    }

    mapping(string => Certificate) internal mapCert;  // LinkedList of Certificates: string certNo => struct Certificate
    uint256 internal totalMapCert;  // Total Counter Added CertNo
    string internal tempFirstCertNo;  // Pointer to the first added CertNo, use for forward travesal searching Cert
    string internal tempLatestCertNo;  // Pointer to the latest added CertNo, use for backward travesal searching Cert
    uint256 internal lastUpdate;  // Time when lastime certificate was added, update or remove. Unix Timestamp. Applicable for caching certiface records.

    constructor() {
        deployer = msg.sender;
        owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;  // Remix IDE
        registrar = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;  // Remix IDE
        trustedAgent = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;   // Remix IDE
        //owner = 0x188834ca6e9934F40C6d7bE119a241159ad092C7;  // IPTM Testnet Single 2021
        //registrar = 0xE0feB70159cD53c8d717659d89B33Bf3D0fc7ec1;  // IPTM Testnet Single 2021
        //trustedAgent = 0x66d834b07e01746F294530948f08d23c9C96f34a;   // IPTM Testnet Single 2021
        contractName = "Blockchain Digital Certificate for IPT Malaysia, 2022";
        systemDeveloper = "iExploTech, IPTM Secretariat, 2022";
        totalMapCert = 0;
        tempFirstCertNo = "";
        tempLatestCertNo = "";
        lastUpdate = block.timestamp;
    }

    function addCertificate(string memory _certNo, string memory _name, string memory _ic, 
        string memory _studentId, string memory _programme, string memory _convoDate, 
        string memory _semesterFinish) public onlyRegistrar returns (bool Status) {
            
         // Check CertNo existent, true if CertNo existed
        if(isValidCertificate(_certNo) == true) {
            return (false);  // may use revert()
        }
        
        mapCert[_certNo].name = _name;
        mapCert[_certNo].ic = _ic;
        mapCert[_certNo].studentId = _studentId;
        mapCert[_certNo].programme = _programme; 
        mapCert[_certNo].convoDate = _convoDate;
        mapCert[_certNo].semesterFinish = _semesterFinish;
        mapCert[_certNo].next = "";  // next always empty until new added cert trigered. Latest added cert will update previous cert next
        
        if(totalMapCert == 0) {  // Will add the first cert into mapCert
            mapCert[_certNo].prev = "";  // The first cert added always prev empty
            tempFirstCertNo = _certNo;  // Pointer to the first added CertNo, use for forward travesal searching Cert
        } else {
            mapCert[_certNo].prev = tempLatestCertNo;  // Add previous, use for backward travesal searching Cert
            mapCert[tempLatestCertNo].next = _certNo;  // Update previous cert with next CertNo, use for forward travesal searching Cert
            
            //mapCert[_certNo].next = tempFirstCertNo; // LinkedList: Making Circle travesal searching Cert, Not Recomended - overheat write operation 
            //mapCert[tempFirstCertNo].prev = _certNo; // LinkedList: Making Circle travesal searching Cert, Not Recomended - overheat write operation
        }

        tempLatestCertNo = _certNo; // Set existing Cert No as reference for future new addCertificate()
        totalMapCert = add(totalMapCert, 1);
        
        lastUpdate = block.timestamp;
        emit addedCertificate(_certNo);  // Event Log
        
        return true;
    }

    // Public will use this function to verify a certificate
    function readCertificatePublic(string memory _certNo) public view returns (
        string memory CertNo, string memory Name, string memory Programme, string memory ConvoDate) {
        
        // if studentId is empty, CertNo not exist
        if(strCompare(mapCert[_certNo].studentId , "") == 0)  // 0 is equal
            return ("", "", "", "");
        else 
            return (_certNo, mapCert[_certNo].name, mapCert[_certNo].programme, mapCert[_certNo].convoDate);
    }
    
    function readCertificate(string memory _certNo) public view onlyRegistrar_or_onlyTrustedAgent returns (
        string memory Name, string memory IC, string memory _StudentId, string memory Programme, 
        string memory ConvoDate, string memory SemesterFinish) {
            
        // if studentId is empty, then CertNo not exist
        if(strCompare(mapCert[_certNo].studentId , "") == 0)  // 0 is equal
            return ("", "", "", "", "", "");
        else 
            return (mapCert[_certNo].name, mapCert[_certNo].ic, mapCert[_certNo].studentId,
                mapCert[_certNo].programme, mapCert[_certNo].convoDate, mapCert[_certNo].semesterFinish);
    }
    
     function searchCertificate(string memory _certNo) public view onlyRegistrar_or_onlyTrustedAgent returns (
        string memory CertData, string memory PrevCertNo, string memory NextCertNo) {
        
         // if studentId is empty, then CertNo not exist
        if(strCompare(mapCert[_certNo].studentId , "") == 0)  // 0 is equal
            return ("", "", "");
        else 
            return (concat6StrPadding(mapCert[_certNo].name, mapCert[_certNo].ic, mapCert[_certNo].studentId,
                mapCert[_certNo].programme, mapCert[_certNo].convoDate, mapCert[_certNo].semesterFinish), 
                mapCert[_certNo].prev, mapCert[_certNo].next);
    }
    
    function isValidCertificate(string memory _certNo) public view returns (bool Status) {
         
         // if studentId is empty, then CertNo not exist
        if(strCompare(mapCert[_certNo].studentId , "") == 0)  // 0 is equal
            return (false);
        else
            return (true);
    }
    
    function searchData(string memory _searchValue, string memory _searchType, 
        string memory _searchIndex) public view onlyRegistrar_or_onlyTrustedAgent returns (string memory CertData, 
        string memory NextCertNo, bool Status, string memory Message) {
            
        if(totalMapCert == 0) {  // Empty List Cert
            return ("", "", false, "Empty List Certificate"); 
        }

        if(strCompare(_searchIndex , "") == 0) {  // Empty Search Index
            _searchIndex = tempFirstCertNo;  // Point to the first added CertNo, use for forward travesal searching Cert
        }
        
        // Check CertNo existent, false if CertNo not exist
        if(isValidCertificate(_searchIndex) == false)
            return ("", "", false,  "Invalid Search Index"); 
        
        Status = false;
        
        if(strCompare(_searchType , "ic") == 0) {  // 
        
            while(isValidCertificate(_searchIndex) == true) {
                
                if(strCompare(mapCert[_searchIndex].ic , _searchValue) == 0) {  // 
                    Status = true;
                    break;
                }
                _searchIndex = mapCert[_searchIndex].next;  // point to next CertNo
            }
            
        } else if(strCompare(_searchType , "id") == 0) {  // 
                
            while(isValidCertificate(_searchIndex) == true) {
                
                if(strCompare(mapCert[_searchIndex].studentId , _searchValue) == 0) {  // 
                    Status = true;
                    break;
                }
                _searchIndex = mapCert[_searchIndex].next;  // point to next CertNo
            }
                
        } else if(strCompare(_searchType , "name") == 0) {  //
        
            while(isValidCertificate(_searchIndex) == true) {
                
                if(strCompare(mapCert[_searchIndex].name , _searchValue) == 0) {  // 
                    Status = true;
                    break;
                }
                _searchIndex = mapCert[_searchIndex].next;  // point to next CertNo    
            }
            
        } else {
                return ("", "", false,  "Invalid Search Type"); 
        }
        
        if(Status == true) {
            // only return one search result, Use NextCertNo if you want to continue the search by calling 
            // searchDataOnlyRegistrar() with NextCertNo as the _searchIndex
            return (concat6StrPadding(mapCert[_searchIndex].name, mapCert[_searchIndex].ic, 
                mapCert[_searchIndex].studentId, mapCert[_searchIndex].programme, 
                mapCert[_searchIndex].convoDate, mapCert[_searchIndex].semesterFinish), 
                mapCert[_searchIndex].next, Status, "Found Certificate");
        }
        
        return ("", "", false, "Not Found Certificate"); // Not found
    }
    
    function updateCertificate(string memory _certNo, string memory _name, string memory _ic, 
        string memory _studentId, string memory _programme, string memory _convoDate, 
        string memory _semesterFinish) public onlyRegistrar returns (bool Status) {
            
        if(isValidCertificate(_certNo) == false) {
            return (false); // may use revert()
        }
        
        mapCert[_certNo].name = _name;
        mapCert[_certNo].ic = _ic;
        mapCert[_certNo].studentId = _studentId;
        mapCert[_certNo].programme = _programme; 
        mapCert[_certNo].convoDate = _convoDate;
        mapCert[_certNo].semesterFinish = _semesterFinish;
        
        lastUpdate = block.timestamp;
        emit updatedCertificate(_certNo);  // Event Log
        
        return true;
    }
    
    function deleteCertificate(string memory _certNo) public onlyRegistrar returns (bool Status) {
         
        // Check CertNo existent, false if CertNo not exist
        if(isValidCertificate(_certNo) == false) {
            return (false);  // may use revert()
        }
        else {  // Many condition MUST be satified to avoid broken LinkedList of Cert
            if(strCompare(mapCert[_certNo].prev, "") != 0) {  // if previous CertNo exist, change it next pointer to the deleted cert next pointer
                mapCert[mapCert[_certNo].prev].next = mapCert[_certNo].next;
            }
            
            if(strCompare(mapCert[_certNo].next, "") != 0) {  // if next CertNo exist, change it prev pointer to the deleted cert prev pointer
                mapCert[mapCert[_certNo].next].prev = mapCert[_certNo].prev;
            }
            
            // If the deleted CertNo it is the first cert in list, update the second cert as the new first cert
            if(strCompare(tempFirstCertNo, _certNo) == 0 && strCompare(mapCert[_certNo].next, "") != 0) {
                tempFirstCertNo = mapCert[_certNo].next;
            }
            
            // If the deleted CertNo it is the last cert in list, update the second last cert as the new last cert
            if(strCompare(tempLatestCertNo, _certNo) == 0 && strCompare(mapCert[_certNo].prev, "") != 0) {
                tempLatestCertNo = mapCert[_certNo].prev;
            }
            
            if(totalMapCert == 1) {  // If only one cert exist, deleted cert will cause First & Latest pointers to Empty
                tempFirstCertNo = "";
                tempLatestCertNo = "";
            }
            
            delete mapCert[_certNo];
            totalMapCert = sub(totalMapCert, 1);  // deduct cert counter
            
            lastUpdate = block.timestamp;
            emit deletedCertificate(_certNo);  // Event Log
            
            return (true);
        }
    }
    
    function getListCertificateStatus() public view onlyRegistrar_or_onlyTrustedAgent returns (string memory FirstCertNo, 
        string memory LatestCertNo, uint256 TotalMapCert, uint256 LastUpdate) {
            
        return (tempFirstCertNo, tempLatestCertNo, totalMapCert, lastUpdate);
    }

    /*
    How to run this smart contract?

    Step 1: Deploy
    Run as Owner address
    Deployed IPTM_BlockchainCertificate on Remix IDE or Geth Client (based on your generated address with ether, You must unlock accounts!)
    owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;  // Change Owner address as required
    registrar = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;  // Change Registrar address as required
    GAS LIMIT: 7000000
    EVM VERSION: istanbul
    Enable optimization: 200
    
    Step 2: Write Cert
    Run as Registrar address
    Executes DebugAddCertificate() 5 times to push 5 dummy certs
    
    Step 3: Check Cert List
    Run as Registrar or Trusted Agent address
    Executes getListCertificateStatus()
    
    Step 4: Search Cert
    Run as Registrar or Trusted Agent address
    Executes:
    4.1. searchData() as the following params:
    _searchValue: IC_3
    _searchType: ic
    _searchIndex:  <empty without value> for advance indexed search, put CertNo
    
    4.2. searchData() as the following params:
    _searchValue: StudentId_2
    _searchType: id
    _searchIndex:  <empty without value> for advance indexed search, put CertNo
    
    4.3. searchData() as the following params:
    _searchValue: Name_4
    _searchType: name
    _searchIndex:  <empty without value> for advance indexed search, put CertNo
    
    Step 5: Public Check Cert
    Run as any address
    Executes readCertificatePublic()  as the following param:
    _certNo: "CertNo_1"

    Other Steps:
    Run as Registrar address
    Try to Update or Delete Cert - figure out by yourself, im too buzy to explain it
    
    Found Bug or Better Suggestion? email to anuarls@hotmail.com
    */
        
    
    // DEBUG SECTION
    // Debuging Functions - If you are lazy to type long inputs
    // For Production or Pilot Deployment, You must remove these debug functions
    // Add Dummy Cert
    uint16 i = 0;  // This index value will increse even after reset
    function DebugAddCertificate() public onlyRegistrar returns (bool Status) {
        i += 1;
        
        return (addCertificate(concat2Str("CertNo_", uint2str(i)), concat2Str("Name_", uint2str(i)), 
            concat2Str("IC_", uint2str(i)), concat2Str("StudentId_", uint2str(i)), 
            concat2Str("Programme_", uint2str(i)), concat2Str("ConvoDate_", uint2str(i)), 
            concat2Str("SemesterFinish_", uint2str(i))) );
    }
    
    // Update Dummy Cert
    uint16 j = 0;  // This index value will increse even after reset
    function DebugUpdateCertificate(string memory _certNo) public onlyRegistrar returns (bool Status) {
        j += 1;
        
        return (updateCertificate(_certNo, concat2Str("Name_Updated_", uint2str(j)), 
            concat2Str("IC_Updated_", uint2str(j)), concat2Str("StudentId_Updated_", uint2str(j)), 
            concat2Str("Programme_Updated_", uint2str(j)), concat2Str("ConvoDate_Updated_", uint2str(j)), 
            concat2Str("SemesterFinish_Updated_", uint2str(j))) );
    }
    
    // Delete All Certificates - Hell yeah!
    // May hangup in Remix IDE if too many Certificates
    // if Gas required exceeds allowance (8000000), you cannot run this function. Too many write operation in blockchain
    // Delete one by one certificate if exceeds allowance gas
    function DebugDeleteAllCertificate() public onlyRegistrar {
        
        string memory index = tempFirstCertNo;
        string memory current = "";
        while(isValidCertificate(index) == true) {
            current = index;
            index = mapCert[index].next;  // point to next CertNo  
            delete mapCert[current];
        }
        
        tempFirstCertNo = "";
        tempLatestCertNo = "";
        totalMapCert = 0;
    }
}
