// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeContract {
    uint256 public initialSuplyOwner = 100_000;
    string public nameOwner = "Baldwin";
    OwnerStruct public owner;
    uint256 public dayOpenContract;
    uint8 public initialSuplyUser = 0;

    mapping (address => UserStruct) public user;

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
        uint256 initialSuplyUser;
        address userAddress;
    }

    function checkBalance () public view returns(uint256) {
        require(user[msg.sender].userAddress != address(0), "User does not exist");
        require(user[msg.sender].userAddress == msg.sender, "You are not the user");
        
        return user[msg.sender].balance;
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