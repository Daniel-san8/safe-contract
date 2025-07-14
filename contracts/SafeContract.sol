// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeContract {
    uint256 public initialSupplyOwner = 100_000;
    string public nameOwner = "Baldwin";
    OwnerStruct public owner;
    uint256 public dayOpenContract;
    uint8 public initialSupplyUser = 0;

    mapping (address => UserStruct) private users;

    enum OptionsWithdraw {
        Withdraw,
        User
    }

    struct OwnerStruct {
        address ownerAddress;
        uint256 balanceOwner;
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

    modifier userNotExists (address _address) {
        require(users[_address].dateCreateUser == 0, "User already exists");
        _;
    }
    constructor () {
        owner = OwnerStruct({
            ownerAddress: msg.sender,
            balanceOwner: initialSupplyOwner,
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
        require(users[msg.sender].dateCreateUser != 0);
        require(msg.value > 0, "Must send some ether");

        users[msg.sender].balance += msg.value;
    }

    function checkBalance () public view verifyAddress(msg.sender) returns(uint256) {
        require(users[msg.sender].balance > 0, "User balance is zero");

        return users[msg.sender].balance;
    }

    function createUser (string memory _nameUser) verifyAddress(msg.sender) userNotExists(msg.sender) public returns(bool success) {
        require(bytes(_nameUser).length > 0, "Name cannot be empty");

        UserStruct memory newUser = UserStruct({
            balance: initialSupplyUser,
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

    function getUnlockedDate (address _addressUser) public view verifyAddress(_addressUser) userNotExists(_addressUser) returns(uint256) {
        require(_addressUser == msg.sender || msg.sender == owner.ownerAddress, "You can only check your own unlock date");
        require(users[_addressUser].dateCreateUser != 0, "User does not exist");
        require(users[_addressUser].unlockPeriod > 0, "No date to unlock");

        return users[_addressUser].unlockPeriod;
    }

    function deposit() public payable verifyAddress(msg.sender) returns(bool) {
        require(users[msg.sender].dateCreateUser != 0, "User does not exist");
        require(msg.value > 0, "Must send ETH to deposit");

        users[msg.sender].balance += msg.value;

        return true;
    }

    function transfer(address _to, uint256 _amount) public verifyAddress(msg.sender) returns(bool) {
        require(users[msg.sender].balance >= _amount, "Insufficient balance");
        require(users[_to].dateCreateUser != 0, "Recipient user does not exist");

        users[msg.sender].balance -= _amount;
        users[_to].balance += _amount;

        return true;
    }

    function withdraw(uint256 _amount) public verifyAddress(msg.sender) returns(bool) {
        require(users[msg.sender].balance >= _amount, "Insufficient balance");
        require(address(this).balance >= _amount, "Insufficient contract balance");

        users[msg.sender].balance -= _amount;

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Transfer failed");

        return true;
    }

}