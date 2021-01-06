const knownContracts = require('./known-contracts');
const { arthPools, POOL_START_DATE } = require('./pools');

/**
 * Tokens deployed first.
 */
const ARTH = artifacts.require('ARTH');
const MockDai = artifacts.require('MockDai');


/**
 * Main migrations
 */
module.exports = async (deployer, network, accounts) => {
  // Set the main account, you'll be using accross all the files for various
  // important activities to your desired address in the .env file.
  accounts[0] = process.env.WALLET_KEY;

  for await (const { contractName, token } of arthPools) {
    const tokenAddress = knownContracts[token] && knownContracts[token][network] || MockDai.address;
    if (!tokenAddress) {
      // Network is mainnet, so MockDai is not available.
      throw new Error(
        `Address of ${token} is not registered on migrations/known-contracts.js!`
      );
    }

    const contract = artifacts.require(contractName);
    await deployer.deploy(contract, ARTH.address, tokenAddress, POOL_START_DATE);
  }
};
