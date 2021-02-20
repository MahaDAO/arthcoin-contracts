const knownContracts = require('./known-contracts');


const ARTH = artifacts.require('ARTH');
const IERC20 = artifacts.require('IERC20');
const MockDai = artifacts.require('MockDai');
const UniswapV2Factory = artifacts.require('UniswapV2Factory');
const TWAP1hrOracle = artifacts.require('TWAP1hrOracle');

const ArthBoardroomV2 = artifacts.require('ArthBoardroomV2');
const ArthUniLiquidityBoardroomV2 = artifacts.require('ArthUniLiquidityBoardroomV2');
const ArthMlpLiquidityBoardroomV2 = artifacts.require('ArthMlpLiquidityBoardroomV2');
const MahaLiquidityBoardroomV2 = artifacts.require('MahaLiquidityBoardroomV2');

const ArthBoardroom = artifacts.require('ArthBoardroomV1');
const ArthLiquidityBoardroom = artifacts.require('ArthLiquidityBoardroomV1');
const MahaLiquidityBoardroom = artifacts.require('MahaLiquidityBoardroomV1');


async function migration(deployer, network, accounts) {
  // Set the main account, you'll be using accross all the files for
  // various important activities to your desired address in the .env
  // file.
  accounts[0] = process.env.WALLET_KEY;

  const DAY = 86400;
  const HOUR = 3600;
  const REWARDS_VESTING = network === 'mainnet' ? 8 * HOUR : HOUR;
  const ARTH_BOARDROOM_LOCK_DURATION = network === 'mainnet' ? 5 * DAY : 60 * 5;
  const LIQUIDITY_BOARDROOM_LOCK_DURATION = network === 'mainnet' ? 1 * DAY : 60 * 5;

  // Deploy dai or fetch deployed dai.
  console.log(`Fetching dai on ${network} network.`);
  const dai = network === 'mainnet'
    ? await IERC20.at(knownContracts.DAI[network])
    : await MockDai.deployed();

  // Fetching deployed ARTH.
  const cash = await ARTH.deployed();

  // Fetch the bond oracle.
  const bondRedemtionOralce = await TWAP1hrOracle.deployed();

  // Fetch the deployed uniswap.
  const uniswap = network === 'mainnet' || network === 'ropsten' || network === 'kovan'
    ? await UniswapV2Factory.at(knownContracts.UniswapV2Factory[network])
    : await UniswapV2Factory.deployed();

  // Get the oracle pair of ARTH-DAI.
  const dai_arth_lpt = network === 'mainnet'
    ? knownContracts.ARTH_DAI_LP[network]
    : await bondRedemtionOralce.pairFor(uniswap.address, cash.address, dai.address);

  const maha_weth_lpt = network === 'mainnet'
    ? knownContracts.MAHA_ETH_LP[network]
    : await bondRedemtionOralce.pairFor(uniswap.address, cash.address, dai.address);

  // Deploy ARTH-DAI liquidity boardroom.
  await deployer.deploy(ArthUniLiquidityBoardroomV2, cash.address, dai_arth_lpt, LIQUIDITY_BOARDROOM_LOCK_DURATION, REWARDS_VESTING);
  await deployer.deploy(ArthMlpLiquidityBoardroomV2, cash.address, dai_arth_lpt, LIQUIDITY_BOARDROOM_LOCK_DURATION, REWARDS_VESTING);
  await deployer.deploy(ArthBoardroomV2, cash.address, ARTH_BOARDROOM_LOCK_DURATION, REWARDS_VESTING);
  await deployer.deploy(MahaLiquidityBoardroomV2, cash.address, maha_weth_lpt, LIQUIDITY_BOARDROOM_LOCK_DURATION, REWARDS_VESTING);


  if (network === 'development') {
    // Deploy ARTH-DAI liquidity boardroom.
    await deployer.deploy(ArthLiquidityBoardroom, cash.address, dai_arth_lpt, LIQUIDITY_BOARDROOM_LOCK_DURATION);

    // Deploy arth boardroom.
    await deployer.deploy(ArthBoardroom, cash.address, ARTH_BOARDROOM_LOCK_DURATION);

    // Deploy MAHA-ETH boardroom.
    await deployer.deploy(MahaLiquidityBoardroom, cash.address, maha_weth_lpt, LIQUIDITY_BOARDROOM_LOCK_DURATION);
  }
}


module.exports = migration;
