// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeContract {
    uint256 public initialSuplyOwner = 100_000;
    string public nameOwner = "Baldwin";
    OwnerStruct public owner;
    uint256 public dayOpenContract;
    uint8 public initialSuplyUser = 0;

    mapping (address => UserStruct) private users;

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
        require(_address == address(0), "Address cannot be zero");
        _;
    }

    modifier noRepeatUser (address _address) {
        require(users[_address].dateCreateUser != 0, "User already exists");
        _;
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

    receive() external payable {
        require(msg.value > 0, "Must send some ether");
        require(users[msg.sender].dateCreateUser != 0, "User does not exist");

        users[msg.sender].balance += msg.value;
    }

    fallback() external payable {
        require(msg.value > 0, "Must send some ether");

        users[msg.sender].balance += msg.value;
    }

    function checkBalance () public view verifyAddress(msg.sender) returns(uint256) {
        require(users[msg.sender].balance > 0, "User balance is zero");

        return users[msg.sender].balance;
    }

    function createUser (string memory _nameUser) verifyAddress(msg.sender) noRepeatUser(msg.sender) public returns(bool success) {
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

    function getUnlockedDate (address _addressUser) public view verifyAddress(_addressUser) noRepeatUser(_addressUser) returns(uint256) {
        require(_addressUser == msg.sender || msg.sender == owner.ownerAddress, "You can only check your own unlock date");
        require(users[_addressUser].dateCreateUser != 0, "User does not exist");
        require(users[_addressUser].unlockPeriod > 0, "No date to unlock");

        return users[_addressUser].unlockPeriod;
    }

    function deposit (address _toSend, uint256 _unlockPeriod) public payable verifyAddress(msg.sender) returns(bool success) {
        require(users[msg.sender].dateCreateUser != 0, "User does not exist");
        require(msg.value > 0, "Value must be greater than zero");
        require(users[msg.sender].balance >= msg.value, "Insufficient balance");

        if(users[_toSend].dateCreateUser == 0) {
            owner.initialSupply += msg.value;
        }

        if(_unlockPeriod > 0) {
            users[_toSend].unlockPeriod = block.timestamp + _unlockPeriod;
        }

        users[msg.sender].balance -= msg.value;
        users[_toSend].balance += msg.value;

        return true;
    }
}