// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeContract {
    uint256 public initialSuplyOwner = 100_000;
    string public nameOwner = "Baldwin";
    OwnerStruct public owner;

    struct OwnerStruct {
        address ownerAddress;
        uint256 initialSupply;
        string nameOwner;
    }

    constructor () {
        owner = OwnerStruct({
            ownerAddress: msg.sender,
            initialSupply: initialSuplyOwner,
            nameOwner: nameOwner
        });
    }
}