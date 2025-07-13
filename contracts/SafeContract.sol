// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeContract {
    uint256 public initialSuplyOwner = 100_000;
    string public nameOwner = "Baldwin";
    OwnerStruct public owner;
    uint256 public dayOpenContract;

    struct OwnerStruct {
        address ownerAddress;
        uint256 initialSupply;
        string nameOwner;
        uint256 createOwner;
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