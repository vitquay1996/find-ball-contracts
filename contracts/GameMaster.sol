//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./BallBoard.sol";
import "./Queue.sol";


contract GameMaster {
    using Queue for Queue.Uint256Queue;
    Queue.Uint256Queue runningGameQueue;
    BallBoard ballBoardContract;
   

    struct Game {
        uint256 boardId;
        uint256 prizePool;
        uint256 numPlayers;
        bool isGameRunning;

        address[] _playerList;
        address[] winnerList;
    }

    mapping(uint256 => Game) public games;
    mapping(address => bool) public playerList;

    address contractOwner;
    uint8 public numCups = 8;
    uint256 public entryCommission;
    uint256 public entryCost;
    uint256 public numOfRunningGames;
    uint256 public contractOwnerCommission;

    constructor(BallBoard ballBoardContractAddress) {
        // fixed entryCost for simplicity
        // 10000000000000 Wei / 0.00001 Ether
        // Queue implementation always added a 0 so dequeued
        entryCost = 10000000000000;
        ballBoardContract = ballBoardContractAddress;
        runningGameQueue.dequeue();
    }

    // owner only
    // no longer need to be owner only
    function startGame() private returns (uint256 newGameId) {
        //TODO: new logic for gameId
        newGameId = ballBoardContract.createBoard(numCups);
        
        Game storage newGame = games[newGameId];
        newGame.boardId = newGameId;
        newGame.isGameRunning = true;
        numOfRunningGames++;
        runningGameQueue.enqueue(newGameId);
    }

    // end game and cashout
    //TODO: emit winner list? for front end consumption
    function endGame(uint256 gameId) private {
        require (games[gameId].isGameRunning == false, "End game: cannot end running game");
        
        uint256 numOfWinners = games[gameId].winnerList.length;
        require (numOfWinners >= 0, "End game: invalid number of winners");

        if (numOfWinners == 0) {
            // TODO: Rollover some pot
            // if number of winners == 0, 100% of the prize pool is kept as commission
            contractOwnerCommission += games[gameId].prizePool;
        } else {
            // if number of winners > 0, prize pool divded evenly among winners
            // insecure divide
            uint256 prize = games[gameId].prizePool / numOfWinners; 
            for (uint256 i = 0; i < numOfWinners; i++) {
                address payable winner = payable(games[gameId].winnerList[i]);
                winner.transfer(prize);
            }

        }

        // endgame logistics
        // mark globally all participatings players as currently not in any instance
        for (uint8 i = 0; i < 4; i++) {
            address player = games[gameId]._playerList[i];
            playerList[player] = false;
        }
        delete games[gameId];
    }

    // main function to participate
    function play(uint8 playerGuess) public payable returns(uint256 gameId) {
        require (msg.value == entryCost, "Play: entry cost not met");
        require (msg.sender != contractOwner, "Play: Owner cannot play");
        require (playerList[msg.sender] == false, "Play: player is already playing");

        // find instance
        if (runningGameQueue.isEmpty() == true) {
            gameId = startGame();
            runningGameQueue.enqueue(gameId);
        } else {
            gameId = runningGameQueue.peek();
        }
        require(games[gameId].isGameRunning == true, "Play: game is not running");

        // game logistics
        games[gameId].numPlayers++;
        games[gameId].prizePool += msg.value;
        games[gameId]._playerList.push(msg.sender);
        playerList[msg.sender] = true;

        // play game
        bool isGuessCorrect = ballBoardContract.revealCup(games[gameId].boardId, playerGuess);
        if (isGuessCorrect == true) {
            games[gameId].winnerList.push(msg.sender);        
        } 
  
        // TODO: potential race condition?
        if (games[gameId].numPlayers == 4) {
            games[gameId].isGameRunning = false;
            uint256 endingGameId = runningGameQueue.dequeue();
            require (endingGameId == gameId, "Play: temp throw");
            endGame(gameId);
        }
    }

    function getPrizePool(uint256 gameId) public view returns(uint256) {
        return games[gameId].prizePool;
    }

    //TODO: Check logic
    function withdraw() public {  
        require(msg.sender == contractOwner, "Withdraw: only contract owner can withdraw");
        
        address payable owner = payable(contractOwner);
        owner.transfer(contractOwnerCommission);
    }

    function getGameRunning(uint256 gameId) public view returns(bool) {
        return games[gameId].isGameRunning;
    }

    function getNumPlayers(uint256 gameId) public view returns(uint256) {
        return games[gameId].numPlayers;
    }


    function getEntryCost() public view returns(uint256) {
        return entryCost;
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
}
