// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract TimeLock {

    address private owner;

    event CL(string _msg, uint _uint);
    event Deposit(address indexed _owner, uint _fortnights, uint _amount);
    event Withdraw(address indexed _owner, uint _amount);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only the owner can call this function');
        _;
    }

    constructor () {
        owner = msg.sender;
    }

    struct timelock {
        uint startDate;
        uint endDate;
        uint fortnightAmount;
        uint lockedAmount;
        uint fortnightsPassed;
        address payable owner;
    }

    mapping (address => timelock) public timelocks;

    function deposit(uint _fortnights, address _owner) public payable onlyOwner {
        require(msg.value > 0, 'Deposit needs to be greater than 0');
        require(timelocks[_owner].startDate == 0, 'Owner already has a timelock');

        timelocks[_owner].startDate = block.timestamp;
        timelocks[_owner].endDate = block.timestamp + _fortnights * 2 weeks;
        timelocks[_owner].fortnightAmount = msg.value / _fortnights;
        timelocks[_owner].lockedAmount = msg.value;
        timelocks[_owner].owner = payable(_owner);

        emit Deposit(_owner, _fortnights, msg.value);
    }

    function withdraw() public {
        // Require 1 year cliff to pass
        timelock memory _timelock = timelocks[msg.sender];
        require(_timelock.startDate + 365 days > block.timestamp, 'Cannot withdraw yet');

        // Check last withdrawal date
        uint _fortnightsPassed = (block.timestamp - _timelock.fortnightsPassed * 2 weeks - _timelock.startDate ) / 2 weeks;
        require(_fortnightsPassed > _timelock.fortnightsPassed, 'Already withdrawn for this period');

        // Calculate how much to send
        uint _unclaimedFortnights = _fortnightsPassed - _timelock.fortnightsPassed;
        uint _amountToSend = _unclaimedFortnights * _timelock.fortnightAmount;

        // Update state
        timelocks[msg.sender].fortnightsPassed = _unclaimedFortnights + _timelock.fortnightsPassed;
        timelocks[msg.sender].lockedAmount -= _amountToSend;

        // Send
        _timelock.owner.transfer(_amountToSend);
        emit Withdraw(msg.sender, _amountToSend);
    }

    // Getters
    function getLockedAmount(address _owner) public view returns (uint) {
        return timelocks[_owner].lockedAmount;
    }

    function getCliffAmount(address _owner) public view returns (uint) {
        if (block.timestamp > timelocks[_owner].startDate + 365 days) {
            return 0;
        }
        return timelocks[_owner].fortnightAmount * 26;
    }

    function getNextPayDay(address _owner) public view returns (uint) {

        uint _daysPassed = (block.timestamp - timelocks[_owner].fortnightsPassed * 2 weeks - timelocks[_owner].startDate) / 1 days * 10;
        uint _fortnightsPassed = _daysPassed / 14;
        // if (_fortnightsPassed > timelocks[owner].fortnightsPassed) {
        //     return 0;
        // }
        // TIMES BY TEN AND IF THE LAST NUMBER IS 0 THEN THERE IS LEFT OVER

        uint _weeksPassed = (block.timestamp - timelocks[_owner].startDate) / 2 weeks;
        return _fortnightsPassed;
    }
    // How to find out when the next payment will be? 
    // Find If fortnights passed > owners fortnights passed
    // How long for next fortnight
}