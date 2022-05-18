//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract BallBoard {

    struct Board {
        bool[] revealBoard;
        bool[] ballBoard;
    }

    event boardCreated (uint256 newBoardId);

    mapping(uint256 => Board) private boards;
    uint256 public numBoards = 0;

    function createBoard(uint8 size) public returns (uint256 newBoardId) {
        newBoardId = numBoards++;
        Board storage newBoard = boards[newBoardId];
        uint8 ballLocation = (uint8)(block.timestamp % size);
        newBoard.revealBoard = new bool[](size);
        newBoard.ballBoard = new bool[](size);
        newBoard.ballBoard[ballLocation] = true;

        emit boardCreated(newBoardId);
    }

    function revealCup(uint256 boardId, uint8 location) public returns (bool isBall) {
        boards[boardId].revealBoard[location] = true;
        isBall = boards[boardId].ballBoard[location];
    }

    function getBallBoard(uint256 boardId) public view returns (bool[] memory) {
        return boards[boardId].ballBoard;
    }

    function getRevealBoard(uint256 boardId) public view returns (bool[] memory) {
        return boards[boardId].revealBoard;
    }

    function isRevealed(uint256 boardId, uint8 location) public view returns (bool) {
        return boards[boardId].revealBoard[location];
    }

}
