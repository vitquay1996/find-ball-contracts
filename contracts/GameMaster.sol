//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./BallBoard.sol";
import "./Queue.sol";
import "./GameCoin.sol";

contract GameMaster {
    using Queue for Queue.Uint256Queue;
    Queue.Uint256Queue runningGameQueue;
    BallBoard ballBoardContract;
    GameCoin gameCoinContract;
   
    event newGameID (uint256 newGameId);
    event gameover (uint256 gameId);

    struct Game {
        uint256 boardId;
        uint256 prizePool;
        uint256 numPlayers;
        uint256 numWinners;
        bool isGameRunning;

        address[] _playerList;
        address[] winnerList;
    }

    mapping(uint256 => Game) public games;
    mapping(address => bool) public playerList;

    address contractOwner;
    uint8 public numCups = 8;
    uint256 public entryCost;
    uint256 public numOfRunningGames;
    uint256 public contractOwnerCommission;
    uint256 public prizePool;

    constructor(BallBoard ballBoardContractAddress, GameCoin gameCoinContractAddress) {
        // fixed entryCost for simplicity
        // 10000000000000 Wei / 0.00001 Ether
        // Queue implementation always added a 0 so dequeued
        entryCost = 5;
        ballBoardContract = ballBoardContractAddress;
        gameCoinContract = gameCoinContractAddress;
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
            // if number of winners == 0, 10% of the prize pool is kept as commission
            //contractOwnerCommission += games[gameId].prizePool / 10;
            prizePool += games[gameId].prizePool;
        } else {
            // if number of winners > 0, prize pool divded evenly among winners
            // insecure divide
            uint256 prize = prizePool / numOfWinners; 
            prizePool = 0;
            for (uint256 i = 0; i < numOfWinners; i++) {
                // address payable winner = payable(games[gameId].winnerList[i]);
                // winner.transfer(prize);
                address winner = games[gameId].winnerList[i];
                gameCoinContract.transfer(winner, prize);
            }

        }

        // endgame logistics
        // mark globally all participatings players as currently not in any instance
        for (uint8 i = 0; i < 4; i++) {
            address player = games[gameId]._playerList[i];
            playerList[player] = false;
        }
        //delete games[gameId];

        emit gameover(gameId);
    }

    // main function to participate
    function play(uint8 playerGuess) public returns(uint256 gameId) {
        //require (msg.value >= entryCost, "Play: entry cost not met");
        //require (msg.sender != contractOwner, "Play: Owner cannot play");
        require (playerList[msg.sender] == false, "Play: player is already playing");

        gameCoinContract.transferFrom(msg.sender, address(this), entryCost);

        // find instance
        if (runningGameQueue.isEmpty() == true || games[runningGameQueue.peekLast()].isGameRunning == false ) {
            gameId = startGame();
            runningGameQueue.enqueue(gameId);
        } else {
            gameId = runningGameQueue.peekLast();
        }
        require(games[gameId].isGameRunning == true, "Play: game is not running");

        // game logistics
        games[gameId].numPlayers++;
        games[gameId].prizePool += entryCost;
        games[gameId]._playerList.push(msg.sender);
        playerList[msg.sender] = true;

        // play game
        bool isGuessCorrect = ballBoardContract.revealCup(games[gameId].boardId, playerGuess);
        if (isGuessCorrect == true) {
            games[gameId].numWinners++;
            games[gameId].winnerList.push(msg.sender);        
        } 
  
        // TODO: potential race condition?
        if (games[gameId].numPlayers == 4) {
            games[gameId].isGameRunning = false;
            //uint256 endingGameId = runningGameQueue.dequeue();
            //require (endingGameId == gameId, "Play: temp throw");
            endGame(gameId);
        }

        emit newGameID(gameId);
    }

    function getQueuePeek() public view returns(uint256) {
        return runningGameQueue.peek();
    }

    function isQueueEmpty() public view returns(bool) {
        return runningGameQueue.isEmpty();
    }

    function getNumWinners(uint256 gameId) public view returns(uint256) {
        return games[gameId].numWinners;
    }

    function getWinner(uint256 gameId, uint256 position) public view returns(address) {
        return games[gameId].winnerList[position];
    }

    function getPrizePool() public view returns(uint256) {
        console.log("here %s",prizePool);
        return prizePool;
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
