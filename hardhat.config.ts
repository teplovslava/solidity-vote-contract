import type { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.2',
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
  },
}

export default config
