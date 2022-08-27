// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    string public lotteryName;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    uint256 public entryFee;

    event RequestedRandomness(bytes32 requestId);
    
    constructor(address _vrfCoordinator, address _link, uint256 _fee, bytes32 _keyhash) VRFConsumerBase(_vrfCoordinator, _link) {
        entryFee = 1 ether;
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function startLottery(string memory _name) public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Can't start a new lottery yet!");
        lottery_state = LOTTERY_STATE.OPEN;
        lotteryName = _name;
    }

    function joinLottery() payable public {
        require(msg.sender != address(0), "Not a valid Address");
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value == 2 ether, "Not enough ETH");
        players.push(payable(msg.sender));
    }

    function endLottery() public onlyOwner returns(bytes32 _requestId) {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
        return requestId;
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {

        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't there yet!");
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        payable(recentWinner).transfer(transferAmount()); 

        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }

    function transferAmount() public view returns(uint tranferrableAmount) {
        uint amount = address(this).balance;
        tranferrableAmount = (amount * 10) / 100;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getPlayers() public view returns(address payable[] memory){
        return players;
    }
}