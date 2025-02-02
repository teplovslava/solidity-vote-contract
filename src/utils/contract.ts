import { ethers } from 'ethers'
import contractABI from '../../artifacts/contracts/Vote.sol/Vote.json' // Файл ABI

interface WindowWithEthereum extends Window {
  ethereum?: any
}

declare const window: WindowWithEthereum

const CONTRACT_ADDRESS = import.meta.env.VITE_CONTRACT_ADDRESS

export const getContract = async () => {
  if (!window.ethereum) throw new Error('Metamask не найден!')

  const networkId = await window.ethereum.request({ method: 'eth_chainId' })
  console.log(`Current network ID: ${networkId}`)

  const provider = new ethers.BrowserProvider(window.ethereum)
  const signer = await provider.getSigner()
  const contract = new ethers.Contract(CONTRACT_ADDRESS, contractABI.abi, signer)

  return contract
}
