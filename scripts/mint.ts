import hre from 'hardhat'

async function main() {
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await hre.run('compile')
  const accounts = await hre.ethers.getSigners()

  const erc20Contract = await hre.ethers.getContractFactory('Token')
  const erc20 = await erc20Contract.deploy(
    accounts[0].address,
    accounts[0].address
  )

  await erc20.deployed()

  console.log('Token deployed to:', erc20.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
