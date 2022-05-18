// // test/Box.test.js
// // Load dependencies
// const { expect } = require('chai');

// // Import utilities from Test Helpers
// const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

// // Load compiled artifacts
// const BallBoard = artifacts.require('BallBoard');

// // Start test block
// contract('BallBoard', function ([ owner, other ]) {

//   beforeEach(async function () {
//     this.ballBoard = await BallBoard.new({ from: owner });
//   });

//   it('update reveal values', async function () {
//     await this.ballBoard.createBoard(4, { from: owner });
//     await this.ballBoard.revealCup(0,1);
//     expect(await this.ballBoard.isRevealed(0,1)).to.equal(true);
//   });

//   it('create emits an event', async function () {
//     const boardId = await this.ballBoard.createBoard(4, { from: owner });

//     expectEvent(boardId, 'boardCreated');
//   });

//   it('non owner cannot store a value', async function () {
//     // Test a transaction reverts
//     await expectRevert(
//       this.box.store(value, { from: other }),
//       'Ownable: caller is not the owner',
//     );
//   });
});