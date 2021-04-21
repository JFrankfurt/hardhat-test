import { config } from 'dotenv'
import { task } from 'hardhat/config'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'
import { abi } from './artifacts/contracts/token.sol/Token.json'
import { Token } from './types/ethers-contracts/Token'
config({})

task('accounts', 'Prints the list of accounts', async (args, hre) => {
  const accounts = await hre.ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

task('mint', 'mint tokens to an address')
  .addParam('contract', 'contract to mint from')
  .addParam('to', 'token recipient')
  .setAction(async ({ contract, to }, hre) => {
    const accounts = await hre.ethers.getSigners()
    const tokenContract = new hre.ethers.Contract(
      contract,
      abi,
      accounts[0]
    ) as Token
    const transaction = await tokenContract.mint(
      to,
      hre.ethers.BigNumber.from('1000000000000000000')
    )
    const receipt = await transaction.wait()
    console.log(receipt)
  })

task('balanceOf', 'get balance of an address')
  .addParam('contract', 'contract to mint from')
  .addParam('address', 'address to check')
  .setAction(async ({ address, contract }, hre) => {
    const accounts = await hre.ethers.getSigners()
    const tokenContract = new hre.ethers.Contract(
      contract,
      abi,
      accounts[0]
    ) as Token
    const balance = await tokenContract.balanceOf(address)
    console.log(balance.div(hre.ethers.BigNumber.from(10).pow(18)).toString())
  })

const privateKey = process.env.pk || ''
module.exports = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      forking: {
        url: 'https://rinkeby.infura.io/v3/59577c8a6c7847d184faca937acd2e90',
        accounts: [privateKey],
      },
    },
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/59577c8a6c7847d184faca937acd2e90',
      accounts: [privateKey],
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
