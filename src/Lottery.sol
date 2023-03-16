// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract Lottery {
    
    struct LotteryRound {
        uint16 winningNumber;                   // winning number
        uint startTime;                         // lottery start time
        uint endTime;                           // lottery end time
        uint winningAmount;                     // total winning amount
        uint winnersLuckyQty;                   // lottery winners length
        address[] participants;                 // lottery participants 
        mapping(address => uint) winnersLucky;  // lottery winners lucky
        mapping(address => uint16) numbers;     // lottery numbers
    }
    
    enum LotteryState { Accepting, Ended }

    LotteryRound public lotteryRound;
    LotteryState public state;
    address public owner;
    address public afterBuyer;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
        state = LotteryState.Accepting;
        lotteryRound.startTime = block.timestamp;
        lotteryRound.endTime = lotteryRound.startTime + 24 hours;
    }

    function buy(uint16 _value) public payable {
        require(msg.value == 0.1 ether, "Only 0.1 ether is accepted");
        require(lotteryRound.numbers[msg.sender] != _value + 1, "Your number is already taken");
    
        state = LotteryState.Accepting;

        if (block.timestamp >= lotteryRound.endTime) {
            require(afterBuyer == msg.sender, "Your number is already taken");
        }
        
        lotteryRound.numbers[msg.sender] = _value + 1;
        lotteryRound.winningAmount += msg.value;
        lotteryRound.participants.push(msg.sender);
        lotteryRound.endTime = block.timestamp + 24 hours;
        afterBuyer = msg.sender;
    }

    function draw() public onlyOwner {
        require(state == LotteryState.Accepting, "Lottery buy?");
        require(block.timestamp >= lotteryRound.endTime, "Lottery not yet ended");
    
        lotteryRound.winningNumber = uint16(uint(keccak256(abi.encodePacked(block.timestamp, block.number))) % 10000);
        {
            uint participants_length = lotteryRound.participants.length;
            for (uint i = 0; i < participants_length;) {
                address buyer = lotteryRound.participants[i];
                if (lotteryRound.numbers[buyer] - 1 == lotteryRound.winningNumber) {
                    lotteryRound.winnersLucky[buyer] = lotteryRound.winningAmount;
                    lotteryRound.winnersLuckyQty +=1;
                } else {
                    lotteryRound.participants.pop();
                }
                unchecked {
                    i++;
                }
            }            
        }
        state = LotteryState.Ended;
    }

    function claim() public {
        require(state == LotteryState.Ended, "Lottery draw?");
        {
            if (lotteryRound.winnersLucky[msg.sender] == 0) {
                (bool _success, ) = payable(msg.sender).call{value: 0}("");
                require(_success, "Transfer failed");
                delete lotteryRound.winnersLucky[msg.sender];
                return;
            }
        }{
            uint amount = (lotteryRound.winnersLucky[msg.sender] / lotteryRound.winnersLuckyQty);
            (bool _success, ) = payable(msg.sender).call{value: amount}("");
            require(_success, "Transfer failed");
            delete lotteryRound.winnersLucky[msg.sender];
        }
    }

    /* utils function */
    function winningNumber() public view returns (uint16) {
        return lotteryRound.winningNumber;
    }

    function _checkOwner() internal view virtual {
        require(msg.sender == owner, "Only owner can execute this function");
    }

    
}
