import "./Ownable.sol";

pragma solidity ^0.4.0;

contract BackupAddressWallet is Ownable {
    address public backup;
    address public transferInitiator;
    uint256 public bondAmount;
    uint256 public bondPaid;
    uint256 public backupCancelPeriod;
    uint256 public backupStartTime;
    
    event TransferStarted(address indexed _initiator, uint256 _startTime);
    event TransferCancelled();
    event TransferCompleted(uint256 _amount);
    event Transfer(address indexed _receiver, uint256 _amount);
    
    /**
     * @dev Reverts if transfer hasn't been initiated.
     */
    modifier transferStarted() {
        require(backupStartTime > 0);
        _;
    }

    /**
     * @dev Reverts if transfer has been started.
     */
    modifier transferNotStarted() {
        require(backupStartTime == 0);
        _;
    }

    /**
     * @dev Reverts if transfer period has not elapsed.
     */
    modifier transferPeriodElapsed() {
        require(block.timestamp - backupStartTime > backupCancelPeriod);
        _;
    }

    /**
     * @dev Reverts if the message value is not exactly the bond amount.
     */
    modifier transferBondEnough() {
        require(msg.value == bondAmount);
        _;
    }

    /**
     * @dev Constructor, takes the backup address, cancellation period, and bond amount
     * @param _backup Backup address
     * @param _backupCancelPeriod Period in which transfer can be cancelled
     * @param _bondAmount Bond required to initiate a transfer
     */
    constructor(address _backup, uint256 _backupCancelPeriod, uint256 _bondAmount) public {
        backup = _backup;
        backupCancelPeriod = _backupCancelPeriod;
        bondAmount = _bondAmount;
    }

    function () public payable { }
    
    /**
     * @dev Set the backup address to something else
     * @param _backup New backup address
     */
    function setBackup(address _backup) public onlyOwner {
        backup = _backup;
    }
    
    /**
     * @dev Set the bond amount to something else
     * @param _bondAmount New bond amount
     */
    function setBondAmount(uint256 _bondAmount) public onlyOwner {
        bondAmount = _bondAmount;
    }
    
    /**
     * @dev Start the backup transfer challenge period, requires a bond
     */
    function startBackupTransfer() public payable transferNotStarted transferBondEnough {
        backupStartTime = block.timestamp;
        transferInitiator = msg.sender;
        bondPaid = bondAmount;
        
        emit TransferStarted(transferInitiator, backupStartTime);
    }

    /**
     * @dev Cancel the backup transfer and slash the bond
     */
    function cancelBackupTransfer() public transferStarted onlyOwner {
        backupStartTime = 0;
        transferInitiator = 0;
        
        emit TransferCancelled();
    }
    
    /**
     * @dev Complete the backup transfer and refund the bond
     */
    function completeBackupTransfer() public transferStarted transferPeriodElapsed {
        transferInitiator.transfer(bondPaid);
        uint256 balance = getBalance();
        backup.transfer(balance);

        bondPaid = 0;
        backupStartTime = 0;
        
        emit TransferCompleted(balance);
    }
    
    /**
     * @dev Allows the owner to transfer funds from this account
     * @param _receiver Address to send to
     * @param _amount Amount to transfer
     */
    function transfer(address _receiver, uint256 _amount) public onlyOwner {
        _receiver.transfer(_amount);

        emit Transfer(_receiver, _amount);
    }
    
    /**
     * @dev Allows the owner to withdraw funds
     * @param _amount Amount to withdraw
     */
    function withdraw(uint256 _amount) public onlyOwner {
        transfer(owner, _amount);
    }

    /**
     * @dev Returns the contract's balance
     * @return The contract's balance, in wei
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
