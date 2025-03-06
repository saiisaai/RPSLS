// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPSLS {
    uint public numPlayer = 0;
    uint public reward = 0;
    
    mapping(address => uint) public player_choice; // 0 - Rock, 1 - Scissors, 2 - Paper, 3 - Lizard, 4 - Spock
    mapping(address => bool) public player_not_played;
    
    address[] public players;
    uint public numInput = 0;

    TimeUnit public timeUnit;
    uint256 public timeoutMinutes = 5; // Timeout set to 5 minutes

    constructor() {
        timeUnit = new TimeUnit();
    }

    function isAllowed(address player) private pure returns (bool) {
        return (player == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 ||
                player == 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 ||
                player == 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db ||
                player == 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
    }

    function addPlayer() public payable {
        require(isAllowed(msg.sender), "Address not authorized.");
        require(numPlayer < 2, "Game full.");
        if (numPlayer > 0) {
            require(msg.sender != players[0], "Already joined.");
        }
        require(msg.value == 1 ether, "Entry fee is 1 ether.");
        
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;

        if (numPlayer == 2) {
            timeUnit.setStartTime();
        }
    }

    function input(uint choice) public {
        require(numPlayer == 2, "Need 2 players.");
        require(player_not_played[msg.sender], "Already played.");
        require(choice >= 0 && choice <= 4, "Invalid choice.");
        
        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;
        numInput++;

        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if (_isWinner(p0Choice, p1Choice)) {
            account0.transfer(reward);
        } 
        else if (_isWinner(p1Choice, p0Choice)) {
            account1.transfer(reward);
        } 
        else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }

        _resetGame();
    }

    function claimWinDueToTimeout() public {
        require(numPlayer == 2, "Game not started.");
        require(timeUnit.hasTimedOut(timeoutMinutes), "Not timed out yet.");
        
        // If Player 1 has not played, Player 0 wins
        if (player_not_played[players[0]]) {
            address payable winner = payable(players[1]);
            winner.transfer(reward);
        }
        // If Player 2 has not played, Player 1 wins
        else if (player_not_played[players[1]]) {
            address payable winner = payable(players[0]);
            winner.transfer(reward);
        }

        _resetGame();
    }

    function claimRewardIfPlayer1DoesNotJoin() public {
        require(numPlayer == 1, "Player 1 must not join the game.");
        address payable winner = payable(players[0]);
        winner.transfer(reward);
        _resetGame();
    }

    function claimRewardIfPlayer1DoesNotMakeChoice() public {
        require(numPlayer == 2, "Need 2 players.");
        require(player_not_played[players[1]], "Player 1 has made their choice.");

        address payable winner = payable(players[0]);
        winner.transfer(reward);

        _resetGame();
    }

    function _resetGame() private {
        delete players;
        numPlayer = 0;
        numInput = 0;
        reward = 0;
        timeUnit.setStartTime(); // Reset timer for next game
    }

    function _isWinner(uint choiceA, uint choiceB) private pure returns (bool) {
        return (
            (choiceA == 0 && (choiceB == 1 || choiceB == 3)) || // Rock crushes Scissors & Lizard
            (choiceA == 1 && (choiceB == 2 || choiceB == 3)) || // Scissors cuts Paper & decapitates Lizard
            (choiceA == 2 && (choiceB == 0 || choiceB == 4)) || // Paper covers Rock & disproves Spock
            (choiceA == 3 && (choiceB == 2 || choiceB == 4)) || // Lizard eats Paper & poisons Spock
            (choiceA == 4 && (choiceB == 0 || choiceB == 1))    // Spock vaporizes Rock & smashes Scissors
        );
    }
}
