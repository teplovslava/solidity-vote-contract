import { ethers } from 'hardhat'

async function main() {
  const [deployer] = await ethers.getSigners()
  console.log('Deploying contracts with the account:', deployer.address)
  await ethers.provider.send('evm_mine', [])

  const Vote = await ethers.getContractFactory('Vote')

  const vote = await Vote.deploy(1)

  await vote.waitForDeployment()

  const tx1 = await vote.addCandidates('Alice', await deployer.getAddress())
  await tx1.wait()

  const tx2 = await vote.addCandidates('Bob', await deployer.getAddress())
  await tx2.wait()

  console.log('Vote contract deployed to:', await vote.getAddress())
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
