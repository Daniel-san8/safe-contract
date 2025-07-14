// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeContract {
    uint256 public initialSupplyOwner = 100_000;
    string public nameOwner = "Baldwin";
    OwnerStruct public owner;
    uint256 public dayOpenContract;
    uint8 public initialSupplyUser = 100;

    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public unlockPeriods;

    mapping(address => mapping(address => uint256)) public unlockCounts;
    mapping(address => mapping(address => uint256[])) public unlockDates;
    mapping(address => UserStruct) private users;

    event TransferEvent(
        address indexed from,
        address indexed to,
        uint256 amount,
        bool addUnlockPeriod,
        uint256 unlockDate
    );
    event DepositEvent(address indexed user, uint256 indexed amount);
    event WithdrawEvent(address indexed user, uint256 indexed amount);
    event UnlockEvent(
        address indexed user,
        address indexed sender,
        uint256 amount,
        bool success,
        uint256 unlockDate
    );

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
        uint256 dateCreateUser;
        string nameUser;
        address userAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner.ownerAddress, "Only owner can call this");
        _;
    }

    modifier verifyAddress(address _address) {
        require(_address != address(0), "Address cannot be zero");
        _;
    }

    modifier userNotExists(address _address) {
        require(users[_address].dateCreateUser == 0, "User already exists");
        _;
    }

    constructor() {
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

    function checkBalance()
        public
        view
        verifyAddress(msg.sender)
        returns (uint256)
    {
        require(users[msg.sender].balance > 0, "User balance is zero");

        return users[msg.sender].balance;
    }

    function createUser(
        string memory _nameUser
    )
        public
        verifyAddress(msg.sender)
        userNotExists(msg.sender)
        returns (bool success)
    {
        require(bytes(_nameUser).length > 0, "Name cannot be empty");

        UserStruct storage user = users[msg.sender];
        user.balance = initialSupplyUser;
        user.dateCreateUser = block.timestamp;
        user.nameUser = _nameUser;
        user.userAddress = msg.sender;

        return true;
    }

    function getUser()
        public
        view
        verifyAddress(msg.sender)
        returns (uint256, uint256, string memory)
    {
        UserStruct storage user = users[msg.sender];
        return (user.balance, user.dateCreateUser, user.nameUser);
    }

    function getUnlockedDate(
        address _sender,
        uint256 index
    ) public view verifyAddress(msg.sender) returns (uint256) {
        require(
            unlockDates[msg.sender][_sender][index] > 0,
            "No date to unlock"
        );

        return unlockDates[msg.sender][_sender][index];
    }

    function deposit()
        public
        payable
        verifyAddress(msg.sender)
        returns (bool success)
    {
        require(msg.value > 0, "Must send ETH to deposit");

        users[msg.sender].balance += msg.value;

        emit DepositEvent(msg.sender, msg.value);

        return true;
    }

    function transfer(
        address _to,
        bool addUnlockPeriod,
        uint256 unlockDate,
        uint256 _amount
    ) public verifyAddress(msg.sender) returns (bool) {
        require(users[msg.sender].balance >= _amount, "Insufficient balance");
        require(
            users[_to].dateCreateUser != 0,
            "Recipient user does not exist"
        );

        if (addUnlockPeriod) {
            require(
                unlockDate > block.timestamp,
                "Unlock date must be in the future"
            );

            uint256 index = unlockCounts[_to][msg.sender];
            unlockPeriods[_to][msg.sender][index] = _amount;
            unlockDates[_to][msg.sender].push(unlockDate);
            unlockCounts[_to][msg.sender]++;

            users[msg.sender].balance -= _amount;
            emit TransferEvent(
                msg.sender,
                _to,
                _amount,
                addUnlockPeriod,
                unlockDate
            );

            return true;
        }

        users[msg.sender].balance -= _amount;
        users[_to].balance += _amount;
        emit TransferEvent(msg.sender, _to, _amount, addUnlockPeriod, 0);

        return true;
    }

    function withdraw(
        uint256 _amount
    ) public verifyAddress(msg.sender) returns (bool success) {
        require(users[msg.sender].balance >= _amount, "Insufficient balance");
        require(
            address(this).balance >= _amount,
            "Insufficient contract balance"
        );

        users[msg.sender].balance -= _amount;

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Transfer failed");
        emit WithdrawEvent(msg.sender, _amount);

        return true;
    }

    /// @notice Unlocks any funds available from a specific sender.
    /// @dev Must be called manually by the user. Does not unlock automatically.

    function unlockMyFunds(address sender) public returns (uint256) {
        require(
            unlockCounts[msg.sender][sender] > 0,
            "No locked funds from sender"
        );
        require(
            unlockDates[msg.sender][sender].length > 0,
            "No unlock dates available"
        );
        require(
            msg.sender == users[msg.sender].userAddress,
            "Unauthorized user"
        );

        uint256 count = unlockCounts[msg.sender][sender];
        uint256 totalUnlocked = 0;

        for (uint256 i = 0; i < count; i++) {
            uint256 unlockDate = unlockDates[msg.sender][sender][i];
            uint256 amount = unlockPeriods[msg.sender][sender][i];

            if (block.timestamp >= unlockDate && amount > 0) {
                unlockPeriods[msg.sender][sender][i] = 0;
                users[msg.sender].balance += amount;
                totalUnlocked += amount;
                emit UnlockEvent(msg.sender, sender, amount, true, unlockDate);
            }
        }
        return totalUnlocked;
    }

    function getUnlockedDatesCount() public view returns (uint256) {
        require(
            unlockDates[msg.sender][msg.sender].length > 0,
            "No unlock dates available"
        );

        return unlockDates[msg.sender][msg.sender].length;
    }
}
