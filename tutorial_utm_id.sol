// Programmer: Ts. Dr. Mohd Anuar Mat Isa, anuarls@hotmail.com
// Website: https://github.com/iexplotech, www.iexplotech.com
// Smart Contract Name: tutorial_utm_id.sol
// Notice: Tutorial for Programming Smart Contract
// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity ^0.7.6;

contract control {
    address internal account;
    function whoami() public view returns (address Account) {
        return msg.sender;
    }
    function setAccount(address _account) internal {
        account = _account;
    }
    function getAccount() public view returns (address Account) {
        return account;
    }
}

contract identity is control {
//string internal name;
//uint8 internal age;

//mapping (address => string) internal name;
//mapping (address => uint8) internal age;

struct id {
    string name;
    uint8 age;
    uint16 no;
}

mapping (address => id) internal staff_info;

/*
function setName(string memory _name) public {
    name = _name;
    setAccount(msg.sender);
}
function setAge(uint8 _age) public {
    age = _age;
    setAccount(msg.sender);
}
*/

function setStaffInfo(string memory _name, uint8 _age, uint16 _no) public {
    //name = _name;
    //age = _age;
    staff_info[msg.sender].name = _name;
    staff_info[msg.sender].age = _age;
    staff_info[msg.sender].no = _no;
    setAccount(msg.sender);
}
/*
function getName() public view returns(string memory Name) {
    return name;
}
function getAge() public view returns(uint8 Age) {
    return age;
}*/
function getStaffInfo() public view returns(string memory Name, uint8 Age, uint16 No) {
    return (staff_info[msg.sender].name, staff_info[msg.sender].age, staff_info[msg.sender].no);
}

}
