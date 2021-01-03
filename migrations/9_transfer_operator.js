const ArthLiquidityBoardroom = artifacts.require('ArthLiquidityBoardroom');
const ArthBoardroom = artifacts.require('ArthBoardroom');
const Treasury = artifacts.require('Treasury');
const ARTH = artifacts.require('ARTH');
const ARTHB = artifacts.require('ARTHB');
const Timelock = artifacts.require('Timelock');


const DAY = 86400;


/**
 * Main migrations
 */
module.exports = async (deployer, network, accounts) => {
  // Set the main account, you'll be using accross all the files for various
  // important activities to your desired address in the .env file.
  accounts[0] = process.env.WALLET_KEY;

  const cash = await ARTH.deployed();
  const bond = await ARTHB.deployed();
  const treasury = await Treasury.deployed();
  // const boardroom = await Boardroom.deployed();
  const arthLiquidityBoardroom = await ArthLiquidityBoardroom.deployed();
  const arthBoardroom = await ArthBoardroom.deployed();
  const timelock = await deployer.deploy(Timelock, accounts[0], 2 * DAY);


  for await (const contract of [cash, bond]) {
    console.log(`transferring operator for ${contract.address} to ${treasury.address}`)
    await contract.transferOperator(treasury.address);
    console.log(`transferring ownership for ${contract.address} to ${treasury.address}`)
    await contract.transferOwnership(treasury.address);
  }

  // await boardroom.transferOperator(treasury.address);
  // await boardroom.transferOwnership(timelock.address);
  await arthLiquidityBoardroom.transferOperator(treasury.address);
  await arthBoardroom.transferOperator(treasury.address);

  await arthLiquidityBoardroom.transferOwnership(timelock.address);
  await arthBoardroom.transferOwnership(timelock.address);

  await treasury.transferOperator(timelock.address);
  await treasury.transferOwnership(timelock.address);

  console.log(`Transferred the operator role from the deployer (${accounts[0]}) to Treasury (${Treasury.address})`);
}
