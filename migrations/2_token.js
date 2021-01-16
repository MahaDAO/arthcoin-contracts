/**
 * Contracts.
 */
const UniswapV2Factory = artifacts.require('UniswapV2Factory');
const UniswapV2Router02 = artifacts.require('UniswapV2Router02');

const ARTH = artifacts.require('ARTH');
const ARTHB = artifacts.require('ARTHB');
const MockDai = artifacts.require('MockDai');
const MahaToken = artifacts.require('MahaToken');


/**
 * Main migrations.
 */
const migration = async (deployer, network, accounts) => {
  // Set the main account, you'll be using accross all the files for
  // various important activities to your desired address in the .env
  // file.
  accounts[0] = process.env.WALLET_KEY;

  await deployer.deploy(ARTH);
  await deployer.deploy(ARTHB);

  if (network !== 'mainnet') {
    await deployer.deploy(MahaToken);

    const dai = await deployer.deploy(MockDai);
    console.log(`MockDAI address: ${dai.address}`);
  }

  // Deploy uniswap.
  if (network !== 'mainnet' && network !== 'ropsten') {
    console.log(`Deploying uniswap on ${network} network.`, accounts[0]);
    await deployer.deploy(UniswapV2Factory, accounts[0]);
    await deployer.deploy(UniswapV2Router02, UniswapV2Factory.address, accounts[0]);
  }
}


module.exports = migration;