// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeContract {
    uint256 public initialSuplyOwner = 100_000;
    string public nameOwner = "Baldwin";
    OwnerStruct public owner;
    uint256 public dayOpenContract;
    uint8 public initialSuplyUser = 0;

    mapping (address => UserStruct) public users;

    struct OwnerStruct {
        address ownerAddress;
        uint256 initialSupply;
        string nameOwner;
        uint256 createOwner;
    }

    struct UserStruct {
        uint256 balance;
        uint256 unlockPeriod;
        uint256 dateCreateUser;
        string nameUser;
    }

    modifier verifyAddress (address _address) {
        require(_address != address(0), "Address cannot be zero");
        _;
    }

    function checkBalance () public view returns(uint256) {
        require(msg.sender != address(0), "User does not exist");
        require(users[msg.sender].balance > 0, "User balance is zero");

        return users[msg.sender].balance;
    }

    function createUser (string memory _nameUser) verifyAddress(msg.sender) public returns(bool success) {
        require(bytes(_nameUser).length > 0, "Name cannot be empty");

        UserStruct memory newUser = UserStruct({
            balance: initialSuplyUser,
            unlockPeriod: 0,
            dateCreateUser: block.timestamp,
            nameUser: _nameUser
        });

        users[msg.sender] = newUser;

        return true;
    }

    function getUser (address _addressUser) public view verifyAddress(_addressUser) returns(UserStruct memory) {
        return users[_addressUser];
    }

    constructor () {
        owner = OwnerStruct({
            ownerAddress: msg.sender,
            initialSupply: initialSuplyOwner,
            nameOwner: nameOwner,
            createOwner: block.timestamp
        });

        dayOpenContract = block.timestamp;
    }
}