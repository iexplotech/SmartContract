// Programmer: Ts. Dr. Mohd Anuar Mat Isa, iExplotech & IPTM Secretariat, 2022
// Contact: anuarls@hotmail.com
// Project: Blockchain Smart Cashless Wallet for IPT Malaysia, 2022
// Collaboration: Institusi Pendidikan Tinggi Malaysia (IPTM) Blockchain Testnet 2022
// Website: https://github.com/iexplotech  http://blockscout.iexplotech.com, www.iexplotech.com
// Smart Contract Name: IPTM_Smart_Cashless_Wallet.sol
// Date: 01 October 2022
// Version: 1.0.0
// Modify/Fork From:
// 1) simpleOnlineWallet.sol, https://github.com/iexplotech/SmartContract/blob/master/simpleOnlineWallet.sol
// Notice: Any referrence, usage or modification of this smart contract without a proper citation (reference) 
//         is considered as plagarism!. Dear Student, do citation - it is a part of learning.
// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity ^0.7.6;

contract AccessControl {

    // Event Logs
    event ChangedRegistrar(address registrar);
    event ChangedTrustedAgent(address TrustedAgent);

    address internal deployer; // who deploys this smartcontract into blockchain
    address payable internal owner;  // who owner this smartcontract
    address internal registrar; // who can write, read, update, delete all certificates
    address internal trustedAgent; // who can read all certificates - for webserver
    string contractName;
    string systemDeveloper;
    uint256 deployDate; // Unix timestamp, datetime this contract deployed into blockchain 
    
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
        address Deployer, address Owner, address Registrar, address TrustedAgent, 
        string memory SystemDeveloper, uint256 DeployDate) {
        return (contractName, address(this), deployer, owner, registrar, trustedAgent, 
                systemDeveloper, deployDate);
    }

    function ChangeRegistrar(address _registrar) public onlyOwner {
        registrar = _registrar;
        emit ChangedRegistrar(registrar);
    }
    
    function ChangeTrustedAgent(address _trustedAgent) public onlyOwner {
        trustedAgent = _trustedAgent;
        emit ChangedTrustedAgent(trustedAgent);
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
    // Safe Maths
    function add256(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "Overflow Add 256-bit Operation");
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "Underflow Subtraction 256-bit Operation");
        c = a - b;
    }

    function add64(uint64 a, uint64 b) internal pure returns (uint64 c) {
        c = a + b;
        require(c >= a, "Overflow Add 64-bit Operation");
    }

    function sub64(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require(b <= a, "Underflow Subtraction 64-bit Operation");
        c = a - b;
    }
}

// Deployed on Remix IDE 
// GAS LIMIT: 3000000
// EVM VERSION: istanbul
// Enable optimization: 200
// Latest Deployed Address: 0x7224a0ed70d46b53edc5791389e4c6a9a93d01fa  // Your address will be different!
contract IPTM_Smart_Cashless_Wallet is AccessControl, Library {

    // Event Logs
    event addedTxReceive(address FromAddress, address ToAddress, uint256 Amount);
    event addedTxPayment(address FromAddress, address ToAddress, uint256 Amount);
    event initlizedUserTxIndex(address UserAddress);
    event resetedUserTxIndex_onlyRegistrar(address UserAddress);

    struct Index {
    bool isInitialized;  // Flag for stating Wallet address is enable to record transactions
    uint64 firstTxIndex;  // Pointer to the first added Transaction Index, use for forward travesal searching Transaction
    uint64 latestTxIndex;  // Pointer to the latest added Transaction Index, use for backward travesal searching
    }

    // Start is used as the index. Therefore it is data redundant to add it into this struct
    struct Transaction {
        address account;
        uint256 amount;
        uint256 timestamp;
        uint256 block;
    }

    //mapping(uint64 => Transaction) internal mapTx;  // LinkedList of Transaction: uint64 Index => struct Transaction
    //mapping(address => Index) internal mapTxIndex;  // Struct of Transaction Index: address user => struct Index
	
    uint64 internal totalUserAccount;  // Total Counter Added User Account by initialize_UserTxIndex()
    uint256 internal lastUpdateTxIndex;  // Time when lastime Transaction Index was added, update or remove. Unix Timestamp. Applicable for caching Transaction records.
    uint256 internal lastUpdateTx;  // Time when lastime Transaction was added, update or remove. Unix Timestamp. Applicable for caching Transaction records.

    
    mapping(address => Index) internal mapTxIndexReceive;  // Struct of Transaction Index: address user => struct Index Receive
    mapping(address => Index) internal mapTxIndexPayment;  // Struct of Transaction Index: address user => struct Index Payment

    mapping(address => mapping(uint64 => Transaction)) internal mapUserTxReceive;  // LinkedList of User Transactions: uint64 Index => struct Transaction Receive
    mapping(address => mapping(uint64 => Transaction)) internal mapUserTxPayment;  // LinkedList of User Transactions: uint64 Index => struct Transaction Payment

    constructor() {
        deployer = msg.sender;
        owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;  // Remix IDE
        registrar = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;  // Remix IDE
        trustedAgent = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;   // Remix IDE
        //owner = 0x188834ca6e9934F40C6d7bE119a241159ad092C7;  // IPTM Testnet Single 2021
        //registrar = 0xE0feB70159cD53c8d717659d89B33Bf3D0fc7ec1;  // IPTM Testnet Single 2021
        //trustedAgent = 0x66d834b07e01746F294530948f08d23c9C96f34a;   // IPTM Testnet Single 2021
        contractName = "IPTM Smart Wallet for IPT Malaysia, 2022";
        systemDeveloper = "iExploTech, IPTM Secretariat, 2022";
        deployDate = block.timestamp;

        totalUserAccount = 0;
        lastUpdateTxIndex = block.timestamp;
        lastUpdateTx = block.timestamp;
    }

    // ALL INDEX FUNCTION - START
    // 1.1: Registrar is allowed to initialize other User Transaction Index
    function initializetUserTxIndex_onlyRegistrar(address _address) public onlyRegistrar 
            returns (bool Status) {
        return(initializeUserTxIndex(_address));
    }

    // 1.2: User is allowed to initialize their own Transaction Index
    function initializeUserTxIndex() public returns (bool Status) {
        return(initializeUserTxIndex(msg.sender));
    }

    // 1.0: All User Address Must be Registered in the Struct mapUserTxReceive & mapTxIndexPayment
    function initializeUserTxIndex(address _address) private returns (bool Status) {

        if(isInitialize_UserTxIndexReceive(_address) == true)
            revert("Revert: initialize_UserTxIndexReceive(), Struct mapUserTxIndexReceive already Initialized: ");

        if(isInitialize_UserTxIndexPayment(_address) == true)
            revert("Revert: initialize_UserTxIndexReceive(), Struct mapUserTxIndexPayment already Initialized!");
        
        // Initial Index 0 as the Pointer of the Circle DoublyLinkedList. No data in index 0.
        // By default all initialized linked is has sentinel node [0] by empty value with an exist flag == true 
        // This node is counted as a part of API call: TNB_ListUser[msg.sender].length
        //mapUserTxReceive[_address][0].account = address(0x0);
        //mapUserTxReceive[_address][0].amount = 0;
        //mapUserTxReceive[_address][0].timestamp = block.timestamp;

        // For Receive Index
        mapTxIndexReceive[_address].isInitialized = true;
        mapTxIndexReceive[_address].firstTxIndex = 0;
        mapTxIndexReceive[_address].latestTxIndex = 0;

        // For Payment Index
        mapTxIndexPayment[_address].isInitialized = true;
        mapTxIndexPayment[_address].firstTxIndex = 0;
        mapTxIndexPayment[_address].latestTxIndex = 0;

        totalUserAccount = add64(totalUserAccount, 1);
        lastUpdateTxIndex = block.timestamp;

        emit initlizedUserTxIndex(_address);  // Event Log

        return true;
    }


    //  2.1 Registrar or TrustedAgent is allowed to read any User Index Receive Transaction 
    function getTxIndexReceive_onlyRegistrar_or_onlyTrustedAgent(address _address) 
            public view onlyRegistrar_or_onlyTrustedAgent returns (bool Status, 
            bool IsInitialized, uint256 FirstTxIndex, uint256 LatestTxIndex) {
        return(getTxIndexReceive(_address));
    }

    //  2.2 User is allowed to read their own Index Receive Transaction 
    function getTxIndexReceive() public view returns (bool Status, 
            bool IsInitialized, uint256 FirstTxIndex, uint256 LatestTxIndex) {
        return(getTxIndexReceive(msg.sender));
    }

    // 2.0:
    function getTxIndexReceive(address _address) private view returns (bool Status, 
            bool IsInitialized, uint256 FirstTxIndex, uint256 LatestTxIndex) {

        if(isInitialize_UserTxIndexReceive(_address) == false)
            return (false, false,  0, 0);
        else
            return (true, mapTxIndexReceive[_address].isInitialized, mapTxIndexReceive[_address].firstTxIndex, 
                mapTxIndexReceive[_address].latestTxIndex);
    }


    // 3.1: Registrar or TrustedAgent is allowed to read any User Index Payment Transaction 
    function getTxIndexPayment_onlyRegistrar_or_onlyTrustedAgent(address _address) 
            public view onlyRegistrar_or_onlyTrustedAgent returns (bool Status, 
            bool IsInitialized, uint256 FirstTxIndex, uint256 LatestTxIndex) {
        return(getTxIndexPayment(_address));
    }

    // 3.2: User is allowed to read their own Index Payment Transaction 
    function getTxIndexPayment() public view returns (bool Status, 
            bool IsInitialized, uint256 FirstTxIndex, uint256 LatestTxIndex) {
        return(getTxIndexPayment(msg.sender));
    }
    
    // 3.0: 
    function getTxIndexPayment(address _address) private view returns (bool Status, 
            bool IsInitialized, uint256 FirstTxIndex, uint256 LatestTxIndex) {

        if(isInitialize_UserTxIndexPayment(_address) == false)
            return (false, false,  0, 0);
        else
            return (true, mapTxIndexPayment[_address].isInitialized, mapTxIndexPayment[_address].firstTxIndex, 
                mapTxIndexPayment[_address].latestTxIndex);
    }
    // ALL INDEX FUNCTION - END


    // ALL TRANSACTION FUNCTION - START
    //  5.0 Transfer Token Function is allowed to add destination address of Receive Transaction 
    function addTxReceive(address _fromAddress, address _toAddress, uint256 _amount) private 
            returns (bool Status) {

        if(isInitialize_UserTxIndexReceive(_toAddress) == false)
            revert("Revert: addTxReceive(), Struct mapUserTxIndexReceive is not initialized yet!");
        
        mapUserTxReceive[_toAddress][mapTxIndexReceive[_toAddress].latestTxIndex].account = _fromAddress;
        mapUserTxReceive[_toAddress][mapTxIndexReceive[_toAddress].latestTxIndex].amount = _amount;
        mapUserTxReceive[_toAddress][mapTxIndexReceive[_toAddress].latestTxIndex].timestamp = block.timestamp;
        mapUserTxReceive[_toAddress][mapTxIndexReceive[_toAddress].latestTxIndex].block = block.number;

        mapTxIndexReceive[_toAddress].latestTxIndex = add64(mapTxIndexReceive[_toAddress].latestTxIndex, 1);
        lastUpdateTx = block.timestamp;

        emit addedTxReceive(msg.sender, _toAddress, _amount);  // Event Log
        
        return true;
    }

    //  6.0 Transfer Token Function is allowed to add source address of Payment Transaction 
    function addTxPayment(address _fromAddress, address _toAddress,  uint256 _amount) private 
            returns (bool Status) {

        if(isInitialize_UserTxIndexPayment(_fromAddress) == false)
            revert("Revert: addTxPayment(), Struct mapUserTxIndexPayment is not initialized yet!");
        
        mapUserTxPayment[_fromAddress][mapTxIndexPayment[_fromAddress].latestTxIndex].account = _toAddress;
        mapUserTxPayment[_fromAddress][mapTxIndexPayment[_fromAddress].latestTxIndex].amount = _amount;
        mapUserTxPayment[_fromAddress][mapTxIndexPayment[_fromAddress].latestTxIndex].timestamp = block.timestamp;
        mapUserTxPayment[_fromAddress][mapTxIndexPayment[_fromAddress].latestTxIndex].block = block.number;

        mapTxIndexPayment[_fromAddress].latestTxIndex = add64(mapTxIndexPayment[_fromAddress].latestTxIndex, 1);
        lastUpdateTx = block.timestamp;

        emit addedTxPayment(msg.sender, _toAddress, _amount);  // Event Log
        
        return true;
    }

    //  7.0 Transfer Token Function is allowed to add source address & destination address of the Transaction
    function addTxRecord(address _fromAddress, address _toAddress, uint256 _amount) internal 
            returns (bool Status) {
        addTxReceive(_fromAddress, _toAddress, _amount);
        addTxPayment(_fromAddress, _toAddress, _amount);
        return true;
    }

    //  8.1: Registrar or TrustedAgent is allowed to read any User Receive Transaction 
    function getTxReceive_onlyRegistrar_or_onlyTrustedAgent(address _address, uint64 _index) 
            public view onlyRegistrar_or_onlyTrustedAgent returns (bool Status, 
            address Account, uint256 Amount, uint256 Timestamp, uint256 Block) {
        return(getTxReceive(_address, _index));
    }

    //  8.2: User is allowed to read their own Receive Transaction 
    function getTxReceive(uint64 _index) public view returns (bool Status, 
            address Account, uint256 Amount, uint256 Timestamp, uint256 Block) {
        return(getTxReceive(msg.sender, _index));
    }
    
    //  8.0: 
    function getTxReceive(address _address, uint64 _index) private view returns (bool Status, 
            address Account, uint256 Amount, uint256 Timestamp, uint256 Block) {

        if(isInitialize_UserTxIndexReceive(_address) == false || 
            _index >= mapTxIndexReceive[_address].latestTxIndex || 
            mapTxIndexReceive[_address].latestTxIndex == 0)
            return (false, address(0x0), 0, 0, 0);
        else
            return (true, mapUserTxReceive[_address][_index].account, mapUserTxReceive[_address][_index].amount, 
                mapUserTxReceive[_address][_index].timestamp, mapUserTxReceive[_address][_index].block);
    }


    //  9.1: Registrar or TrustedAgent is allowed to read any User Payment Transaction
    function getTxPayment_onlyRegistrar_or_onlyTrustedAgent(address _address, uint64 _index) 
            public view onlyRegistrar_or_onlyTrustedAgent returns (bool Status, 
            address Account, uint256 Amount, uint256 Timestamp, uint256 Block) {
        return(getTxPayment(_address, _index));
    }

    //  9.2: User is allowed to read their own Payment Transaction
    function getTxPayment(uint64 _index) public view returns (bool Status, 
            address Account, uint256 Amount, uint256 Timestamp, uint256 Block) {
        return(getTxPayment(msg.sender, _index));
    }

    //  9.0: 
    function getTxPayment(address _address, uint64 _index) private view returns (bool Status, 
            address Account, uint256 Amount, uint256 Timestamp, uint256 Block) {

        if(isInitialize_UserTxIndexPayment(_address) == false || 
            _index >= mapTxIndexPayment[_address].latestTxIndex || 
            mapTxIndexPayment[_address].latestTxIndex == 0)
            return (false, address(0x0), 0, 0, 0);
        else
            return (true, mapUserTxPayment[_address][_index].account, 
                mapUserTxPayment[_address][_index].amount, 
                mapUserTxPayment[_address][_index].timestamp, 
                mapUserTxPayment[_address][_index].block);
    }
    // ALL TRANSACTION FUNCTION - END


    //  10.0: Check the Initialization Status of Struct mapUserTxReceive
    function isInitialize_UserTxIndexReceive(address _address) public view returns (bool) {
        return (mapTxIndexReceive[_address].isInitialized); // Return Flag Intialization User Wallet for Receive of this address

    }

    //  11.0: Check the Initialization Status of Struct mapUserTxPayment
    function isInitialize_UserTxIndexPayment(address _address) public view returns (bool) {
        return (mapTxIndexPayment[_address].isInitialized); // Return Flag Intialization User Wallet for Payment of this address

    }
    

    //  12.0: Registrar is allowed to reset other User Transaction Index
    function resetUserTxIndex_onlyRegistrar(address _address) public onlyRegistrar returns (bool) {

        if(isInitialize_UserTxIndexReceive(_address) == false)
            revert("Revert: reset_UserTxIndex_Registrar(), Struct mapUserTxReceive is not initialized yet!");

        
        if(isInitialize_UserTxIndexPayment(_address) == false)
            revert("Revert: reset_UserTxIndex_Registrar(), Struct mapUserTxPayment is not initialized yet!");
        
        // For Receive Index
        mapTxIndexReceive[_address].isInitialized = false;
        mapTxIndexReceive[_address].firstTxIndex = 0;
        mapTxIndexReceive[_address].latestTxIndex = 0;

        // For Payment Index
        mapTxIndexPayment[_address].isInitialized = false;
        mapTxIndexPayment[_address].firstTxIndex = 0;
        mapTxIndexPayment[_address].latestTxIndex = 0;

        totalUserAccount = sub64(totalUserAccount, 1);
        lastUpdateTxIndex = block.timestamp;

        emit resetedUserTxIndex_onlyRegistrar(_address);  // Event Log

        return true;
    }

    //  13.0: 
    function getOverallTxStatus_onlyRegistrar_or_onlyTrustedAgent() public view             
            onlyRegistrar_or_onlyTrustedAgent returns (uint64 TotalUserAccount, 
            uint256 LastUpdateTxIndex, uint256 LastUpdateTx) {
        return (totalUserAccount, lastUpdateTxIndex, lastUpdateTx);
    }


    /*
    How to run this smart contract?

    Step 1: Deploy
    Run as Owner address
    Deployed IPTM_Smart_Wallet on Remix IDE or Geth Client (based on your existing address with ether in running geth terminal, You must unlock accounts in the geth terminal before usage in Remix IDE!)
    owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;  // Change Owner address as required
    registrar = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;  // Change Registrar address as required
    trustedAgent = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;  // Change Trusted Agent address as required
    GAS LIMIT: 3000000
    EVM VERSION: istanbul
    Enable optimization: 200
    
    Step 2: Initialize Owner address with huge amount tokens or max total supply
    Run as Owner address
    Executes DEBUG_INIT()
    Executes balanceOfUser()
    Executes getTxIndexReceive()
    Executes getTxReceive(0) then (1)
    Executes getTxIndexPayment()
    Executes getTxPayment(0) then (1)
    
    Step 3: Check Total Registered Address as User Wallet
    Run as Registrar or Trusted Agent address
    Executes getOverallTxStatus_onlyRegistrar_or_onlyTrustedAgent()

    Step 4: Before any address can be use as Wallet, any address must register
    Run as any address but NOT Owner, Registrar or Trusted Agent address
    Executes initializeUserTxIndex() // Try this to many other accounts
    Executes balanceOfUser()
    Executes getTxIndexReceive()
    Executes getTxIndexPayment()

    Step 5: Owner transfer token to Account registered in the Step 4
    Run as Owner address
    Executes balanceOfUser()
    Executes DEBUG_transfer(<Step 4 Address>, 10000)  // a Wallet Account A
    Executes DEBUG_transfer(<Step 4 Address>, 20000)  // a Wallet Account B, MUST NOT the same adddress as Account A  
    Executes getTxIndexPayment()
    Executes getTxPayment(0) then (1), (2), (3)

    Step 6: Testing Wallet Account A 
    Run as Wallet Account A as usage in the Step 5
    Executes balanceOfUser()
    Executes getTxIndexReceive()
    Executes getTxReceive(0)

    Step 7: Testing Wallet Account B 
    Run as Wallet Account B as usage in the Step 5
    Executes balanceOfUser()
    Executes getTxIndexReceive()
    Executes getTxReceive(0)

    Step 8: Wallet Account B Transfer 3000 Token into Wallet Account A
    Run as Wallet Account B as usage in the Step 7
    Executes balanceOfUser()
    Executes DEBUG_transfer(<Wallet Account A Address>, 3000)
    Executes balanceOfUser()
    Executes getTxIndexPayment()
    Executes getTxPayment(0)

    Step 9: Check Wallet Account A
    Run as Wallet Account A as usage in the Step 6
    Executes balanceOfUser()
    Executes getTxIndexReceive()
    Executes getTxReceive(0) then (1)

    Other Steps: figure out by yourself, im too buzy to explain it
    
    Found Bug or Better Suggestion? email to anuarls@hotmail.com
    */
        
    
    // DEBUG SECTION
    // Debuging Functions - If you are lazy to type long inputs
    // Only Testing or Pilot Deployment, For Production You must remove these DEBUG functions
    // You must integrate this contract with another contract such as ERC20 contract as the final product.
    uint8 public decimals;
    uint _totalSupply;
    mapping(address => uint) balances;

    event Transfer(address indexed from, address indexed to, uint tokens);

    function DEBUG_INIT() public  {  // put these variables and functions in your constructor()
        decimals = 3;
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;

        initializeUserTxIndex(owner);
        DEBUG_transfer(owner, _totalSupply);

        emit Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function DEBUG_transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = sub256(balances[msg.sender], tokens);
        balances[to] = add256(balances[to], tokens);

        addTxRecord(msg.sender, to, tokens);

        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function balanceOfUser() public view returns (uint balance) {
        return balances[msg.sender];
    }

}