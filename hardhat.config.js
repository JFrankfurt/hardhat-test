const erc20ABI = require('./artifacts/contracts/erc20.sol/Uni.json')
const { Contract } = require('@ethersproject/contracts')
require('@nomiclabs/hardhat-ethers')
require('@nomiclabs/hardhat-waffle')
require('dotenv').config({})

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await hre.ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

task('mint', '100 mints tokens to a specified address')
  .addParam('contract', 'the token contract')
  .addParam('target', 'the token recipient')
  .setAction(async ({ contract, target }) => {
    const tokenContract = new Contract(contract, erc20ABI)
  })

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      forking: {
        url: 'https://rinkeby.infura.io/v3/59577c8a6c7847d184faca937acd2e90',
      },
    },
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/59577c8a6c7847d184faca937acd2e90',
      accounts: [process.env.pk],
    },
  },
  solidity: {
    version: '0.8.3',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
}
