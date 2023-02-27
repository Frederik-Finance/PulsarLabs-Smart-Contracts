const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const {
    BN
} = require('@openzeppelin/test-helpers');
const { assert } = require("chai");

const Simulation = artifacts.require("Simulation");
const ERC20 = artifacts.require('IERC20');
// "0x42981d0bfbAf196529376EE702F2a9Eb9092fcB5"

contract("Simulation", function (accounts) {
    let Erc20;
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
        const percentage = 90
        Erc20 = await ERC20.at(target)

        // // The amount of DAI expected to be received
        // let out = await simulation.getAmountOutMin(amountIn, [tokenIn, target])
        // console.log(`Expected out-amount: ${out}`)

        // Send the BNB to be traded to the contract
        let res = await simulation.startSimulation(target, tokenIn, percentage, false, {
            from: accounts[3], to: simulation.address, value: amountIn
        })
        console.log(res)
        // let balance = await Erc20.balanceOf(simulation.address)
        // console.log(`Actual out-amount: ${balance}`)
    })
    it("should execute a swap on the high-tax token called JeetpackToken", async function () {
        // BNB address
        const tokenIn = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
        // DAI address
        const target = "0x35E4EFa6f4f00478Cb9e391F0894f48A7A02a583";

        // The amount of BNB to be traded
        const amountIn = new BN("10");
        // The percentage of the amountIn to be used for the swap
        const percentage = 50
        // let JeetpackToken = await ERC20.at(target)

        // The amount of DAI expected to be received
        let out = await simulation.getAmountOutMin(amountIn, [tokenIn, target])
        console.log(`Expected out-amount: ${out}`)

        // Send the BNB to be traded to the contract
        let res = await simulation.startSimulation(target, tokenIn, percentage, true, {
            from: accounts[3], to: simulation.address, value: amountIn
        })
        // let balance = await JeetpackToken.balanceOf(simulation.address)
        // console.log(`Actual out-amount: ${balance}`)

        // console.log(`${((Number(balance / out) - 1) * 100).toFixed(2)} % realized after slippage & taxes, set slippage tolerance in Nova ${percentage - 100} % `)
    })

    // it("test function", async function () {
    //     // BNB address
    //     const tokenIn = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
    //     // DAI address
    //     const target = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";

    //     // The amount of BNB to be traded
    //     const amountIn = new BN("10");
    //     // The percentage of the amountIn to be used for the swap
    //     const percentage = 20

    //     let busd = await ERC20.at(target)
    //     await busd.transfer(simulation.address, 100, { from: "0xf977814e90da44bfa03b6295a0616a897441acec" })
    //     console.log(`${await busd.balanceOf(simulation.address)}`)


    //     await simulation.sellTest([target, tokenIn], { from: "0xf977814e90da44bfa03b6295a0616a897441acec" })

    // })

})
