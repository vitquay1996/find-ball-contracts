// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const BallBoard = await hre.ethers.getContractFactory("BallBoard");
  const ballBoard = await BallBoard.deploy();

  await ballBoard.deployed();
  console.log("BallBoard deployed to:", ballBoard.address);

  const GameCoin = await hre.ethers.getContractFactory("GameCoin");
  const gameCoin = await GameCoin.deploy();

  await gameCoin.deployed();
  console.log("GameCoin deployed to:", gameCoin.address);

  const GameMaster = await hre.ethers.getContractFactory("GameMaster");
  const gameMaster = await GameMaster.deploy(ballBoard.address, gameCoin.address);

  await gameMaster.deployed();
  console.log("GameMaster deployed to:", gameMaster.address);

  
  await gameCoin.mint("0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",1000);
  await gameCoin.mint("0x70997970c51812dc3a010c7d01b50e0d17dc79c8",1000);
  await gameCoin.mint("0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc",1000);
  await gameCoin.mint("0x90f79bf6eb2c4f870365e785982e1f101e93b906",1000);
  await gameCoin.mint("0x15d34aaf54267db7d7c367839aaf71a00a2c6a65",1000);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
