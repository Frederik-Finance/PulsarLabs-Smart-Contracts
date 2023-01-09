const Simulation = artifacts.require("Simulation");

module.exports = function (deployer) {
    deployer.deploy(Simulation);
};
