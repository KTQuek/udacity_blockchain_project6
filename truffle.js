
const HDWalletProvider = require('truffle-hdwallet-provider');
const mnemonic = "infura endpoint for rinkeby";
const endPt = "metamask seed phrase";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: () => new HDWalletProvider(mnemonic, endPt),
      network_id: 4,
      gas : 6000000,                            //4500000
      gasPrice : 30000000000,
    },
  },
  compilers: {
    solc: {
      version: "0.5.0",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
       optimizer: {
         enabled: true,
         runs: 200
       }
      //  evmVersion: "byzantium"
      // }
    }
  }
};