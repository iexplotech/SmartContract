// Programmer: Dr. Mohd Anuar Mat Isa, iExplotech & IPTM Secretariat
// Project: UKM's NFT Tutorial - Learn Solidity
// Website: https://github.com/iexplotech www.iexplotech.com
// SPDX-License-Identifier: GPL3+
// Further References:
// https://eips.ethereum.org/EIPS/eip-721
// https://docs.openzeppelin.com/contracts/4.x/wizard


pragma solidity ^0.7.6;

contract control {
    address internal owner;
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
}
contract info is control {
    string contractName;

    function whoAmI() public view returns (address Address) { 
        return msg.sender; 
    }

    function setContractName(string memory _contractName) public onlyOwner {
        contractName = _contractName;
    }

    function getContractName() public view returns (string memory ContractName) {
        return contractName;
    }
}
contract identity is control {
    //string internal name;
    //int8 internal age;

    mapping(address => string) internal name;
    mapping(address => int8) internal age;
    mapping(address => int128) internal wallet;

    function getOwner() public view returns (address Owner) {
        return owner;
    }
    function setMyIdentity(string memory _name, int8 _age) public {
        name[msg.sender] = _name;
        age[msg.sender] = _age;
    }
    function getMyIdentity() public view returns (string memory Name, int8 Age, int128 Wallet) {
        return (name[msg.sender], age[msg.sender], wallet[msg.sender]);
    }
    function getIdentity(address _address) public view 
        returns (string memory Name, int8 Age, int128 Wallet) {
        return (name[_address], age[_address], wallet[_address]);
    }
}

contract trade is identity, info {
    struct asset {  // structure
        string name;
        int32 quantity;
        int64 price;
    }
    int128 public decimal;
    int128 public total_supply;
    constructor () {
        owner = msg.sender;
        decimal = 2;
        total_supply = 10000000;  //  total_supply = 100000 * 10^decimal;

        addProduct("UKM's NFT Collection", 5, 1000); // Quantity 5, Price RM 10.00
        giveToken(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 2500);  // Ali = RM 25.00
        giveToken(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 4000);  // Abu = RM 40.00
    }

    //mapping(address=>asset) internal product;
    asset internal product;

    function addProduct(string memory _name, int32 _quantity, int64 _price) public onlyOwner {
        product.name = _name;
        product.quantity = _quantity;
        product.price = _price;
    }

    function readProductInfo() public view 
        returns (string memory Name, int32 Quantity, int64 Price) {
            return(product.name, product.quantity, product.price);
    }
    
    function giveToken(address _address, int128 _amount) public onlyOwner {
        if(_amount <= total_supply) {
           wallet[_address] = wallet[_address] + _amount; 
           total_supply = total_supply - _amount;
        } else {
            revert("Invalid Deposit Amount");
        }  
    }

    function transfer(address _to, int128 _amount) public {
        if(wallet[msg.sender] >= _amount) {
            wallet[_to] = wallet[_to] + _amount;
            wallet[msg.sender] = wallet[msg.sender] - _amount;
        } else {
            revert ("Invalid Transfer Amount");
        }
    }

    function pay(int32 _quantity) public {
        if(wallet[msg.sender] >= product.price * _quantity) {
            if(_quantity <= product.quantity) {
                transfer(owner, product.price * _quantity);
                product.quantity = product.quantity - _quantity;  // deduct quantity after user paid
            }
            else {
                revert("Not enough product stock");
            }
        }
        else {
            revert("Not enough token in your wallet");
        }

    }
}
