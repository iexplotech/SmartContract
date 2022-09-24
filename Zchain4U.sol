// Project: Zchain4U: A Flexible, Secure and Instant Cashless Payment System Using Blockchain Technology
// Project Leader: Ts. Prof. Dr.Zuriati Ahmad Zukarnain, zuriati@upm.edu.my, Universiti Putra Malaysia (UPM)
// Programmer: Ts. Dr. Mohd Anuar Mat Isa, anuarls@hotmail.com, iExplotech & IPTM Secretariat, 2022
// Collaboration: Institusi Pendidikan Tinggi Malaysia (IPTM) Blockchain Testnet 2022
// Website: https://github.com/iexplotech, www.iexplotech.com
// Smart Contract Name: Zchain4U
// Date: 25 September 2022
// Version: 1.0.0
// Modify/Fork From: 
// 1) FixedSupplyToken_0.7.x, https://github.com/iexplotech/SmartContract/blob/master/FixedSupplyToken_0.7.x.sol
// 2) IPTM_BlockchainCertificate (v1.1.0), https://github.com/iexplotech/SmartContract/blob/master/IPTM_BlockchainCertificate.sol
// Note: Any referrence, usage or modification of this smart contract without a proper citation (reference) 
//       is considered as plagarism!. Do citation - it is a part of learning.
// "SPDX-License-Identifier: GPL-3.0-or-later"


pragma solidity ^0.7.6;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "Overflow Addition Operation");
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Underflow Subtraction Operation");
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Overflow Multiplication Operation");
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "Invalid Division Operation");
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// AccessControl contract
// IPTM_BlockchainCertificate (v1.1.0), https://github.com/iexplotech/SmartContract/blob/master/IPTM_BlockchainCertificate.sol
// ----------------------------------------------------------------------------
contract AccessControl {

    // Event Logs
    event OwnershipTransferred(address indexed _from, address indexed _to);

    address internal deployer; // who deploys this smartcontract into blockchain
    address payable internal owner;  // who owner this smartcontract
    address payable internal newOwner;
    string internal contractName;
    string internal systemDeveloper;
    uint256 internal lastUpdate;  // Time when lastime transaction was performed. Unix Timestamp. Applicable for caching transaction records. 
    
    // onlyOwner can deploy and destroy contract;
    modifier onlyOwner {
        require(msg.sender == owner, "onlyOwner is Authorized!");
        _;
    }
    
    function getContractInfo() public view returns (string memory ContractName, address ContractAddress, 
        address Deployer, address Owner, string memory SystemDeveloper, uint256 LastUpdate) {
        return (contractName, address(this), deployer, owner, systemDeveloper, lastUpdate);
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
        lastUpdate = block.timestamp;
    }
    
    // Contract is no longer accessible, but all transaction records still in blockchain
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
    
    function whoAmI() public view returns (address) {
        return msg.sender;
    }
    
}

// ----------------------------------------------------------------------------
// Zchain4U is ERC20 Token, with the addition of symbol, name and decimals and a fixed supply
// ----------------------------------------------------------------------------
contract Zchain4U is ERC20Interface, AccessControl {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed; 


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        deployer = msg.sender;
        owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;  // Remix IDE
        //owner = 0x188834ca6e9934F40C6d7bE119a241159ad092C7;  // IPTM Testnet Single 2021
        contractName = "Zchain4U: A Flexible, Secure and Instant Cashless Payment System Using Blockchain Technology";
        systemDeveloper = "Universiti Putra Malaysia (UPM); & iExploTech, IPTM Secretariat;";
        symbol = "ZC4U";
        name = "Zchain4U Token";
        decimals = 3;
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
        lastUpdate = block.timestamp;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view virtual override returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public virtual override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        lastUpdate = block.timestamp;
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public virtual override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        lastUpdate = block.timestamp;
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view virtual override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        lastUpdate = block.timestamp;
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    fallback () external {
        revert("Invalid Function Call");
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
