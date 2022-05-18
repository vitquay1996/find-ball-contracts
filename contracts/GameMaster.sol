//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./BallBoard.sol";

contract GameMaster {

    BallBoard ballBoardContract;

    struct Game {
        uint256 boardId;
        address owner;
        address winner;
        uint256 prizePool;
        uint256 numPlayers;
        uint256 entryCost;
        bool isGameRunning;
    }

    mapping(uint256 => Game) private games;

    uint8 public numCups = 8;
    uint256 private entryCommission;

    modifier gameOwnerOnly(uint256 gameId) {
        require(msg.sender == games[gameId].owner, "Message sender not owner");
        _;
    }

    constructor(uint256 _entryCommission, BallBoard ballBoardContractAddress) {
        // fixed commission for POC simplicity
        entryCommission = _entryCommission;
        ballBoardContract = ballBoardContractAddress;
    }

    // owner only
    function startGame(uint256 newEntryCost) public payable returns (uint256 newGameId) {
        // set running flag
        // inject starting pool
        // set new entry cost
        require(msg.value > 0, "Initial pot missing");

        //TODO: new logic for gameId
        newGameId = ballBoardContract.createBoard(numCups);
        
        Game storage newGame = games[newGameId];
        newGame.boardId = newGameId;
        newGame.owner = msg.sender;
        newGame.winner = address(0);
        newGame.prizePool += msg.value;
        newGame.entryCost = newEntryCost;
        newGame.isGameRunning = true;

    }

    function endGame(uint256 gameId) public {
        // winner can trigger the endgame and get the funds
        // game must not be running
        require(msg.sender == games[gameId].winner, "Only winner can trigger endgame");
        require(games[gameId].isGameRunning == false, "Game is still running");
        
        // transfer prizePool to winner
        address payable _winner = payable(games[gameId].winner);
        _winner.transfer(games[gameId].prizePool);
    }

    // main function to participate
    // returns bool to indicate win or lost
    function play(uint256 gameId, uint8 playerGuess) public payable returns(bool isGuessCorrect) {
        // game must be running
        // price to play must be payed
        // game owner should not be able to participate [not implemented]
        // the cup must not already be flipped
        require(games[gameId].isGameRunning == true, "Game must be running to play");
        require(msg.value >= games[gameId].entryCost, "Entry cost not met");        
        require(ballBoardContract.isRevealed(games[gameId].boardId, playerGuess) == false, "Cup has been flipped already");

        // owner take a cut
        games[gameId].numPlayers++;
        games[gameId].prizePool += msg.value - entryCommission;

        isGuessCorrect = ballBoardContract.revealCup(games[gameId].boardId, playerGuess);
        if (isGuessCorrect == true) {
            // if win
            // save winner address
            // mark game as close
            games[gameId].winner = msg.sender;
            games[gameId].isGameRunning = false;
        } else {
            // if lose
            // increase entryCost - POC increase arbitrarily e.g. *2
            games[gameId].entryCost *= 2;
        }  
    }

    function getPrizePool(uint256 gameId) public view returns(uint256) {
        return games[gameId].prizePool;
    }

    //TODO: Check logic
    function withdraw(uint256 gameId) public gameOwnerOnly(gameId) {  
        // game must not be running
        require (games[gameId].isGameRunning == false, "Game must not be running to withdraw");
        
        // withdraw commissions
        address payable _owner = payable(games[gameId].owner);
        _owner.transfer(games[gameId].numPlayers * entryCommission);
    }

    function getGameRunning(uint256 gameId) public view returns(bool) {
        return games[gameId].isGameRunning;
    }

    function getNumPlayers(uint256 gameId) public view returns(uint256) {
        return games[gameId].numPlayers;
    }

    function getOwner(uint256 gameId) public view returns(address) {
        return games[gameId].owner;
    }

    function getEntryCost(uint256 gameId) public view returns(uint256) {
        return games[gameId].entryCost;
    }

    function getWinner(uint256 gameId) public view returns(address) {
        return games[gameId].winner;
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
}
