const NovaWallet = artifacts.require("NovaWallet");

module.exports = function (deployer) {
    const userAddress = "0xdb6e9bfe9eb4177574db016abed58ebea358484a";
    deployer.deploy(NovaWallet, userAddress);
};
