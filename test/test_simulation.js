const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const {
    BN
} = require('@openzeppelin/test-helpers');
const { assert } = require("chai");

const Simulation = artifacts.require("Simulation");

contract("Simulation", function (accounts) {
    let simulation;
    before(async function () {
        simulation = await Simulation.deployed();
    });

    it("should execute the swap and transfer the purchased tokens to the contract", async function () {
        // BNB address
        const tokenIn = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
        // DAI address
        const target = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
        // The amount of BNB to be traded
        const amountIn = new BN("1");
        // The percentage of the amountIn to be used for the swap
        const percentage = 50
        // The amount of DAI expected to be received
        let out = await simulation.getAmountOutMin(100000000000000, [tokenIn, target])
        console.log(out)

        // Send the BNB to be traded to the contract
        // await simulation.sendTransaction(target, tokenIn, percentage, false, {
        //     from: accounts[0], value: amountIn
        // })
    })
})
