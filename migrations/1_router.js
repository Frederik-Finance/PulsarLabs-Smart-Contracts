

const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const PulsarRouter = artifacts.require("PulsarRouter");

module.exports = async function (deployer) {
  // const pulsar_router = PulsarRouter.networks[56].address


  await deployProxy(PulsarRouter, { deployer, initializer: 'initialize' });
};



// ganache-cli -f ws://localhost:8546 -p 7545 -i 97 
// truffle compile --all && truffle migrate --reset --network development && truffle test

