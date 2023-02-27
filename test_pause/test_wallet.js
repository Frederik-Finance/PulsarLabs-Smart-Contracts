//ganache-cli -f http://localhost:8545 -p 7545 -m horn
// ganache-cli -f http://localhost:8545 -p 7545 -d path/to/one.json
// myth like bonus scare over problem client lizard pioneer submit female collect

const { BN, expectEvent, expectRevert, time } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");

const NovaWallet = artifacts.require("NovaWallet");
const ERC20 = artifacts.require('IERC20');

const chai = require("chai");
const { expect } = chai;
chai.use(require("chai-as-promised"));


// set the parameters

contract("NovaWallet", accounts => {
    let novaWallet;
    const owner = accounts[0];
    const user1 = accounts[1];
    const initialEther = new BN("1000000000000000000"); // 1 ETH


    let WBNB;
    let TARGET;
    let TOKENIN
    let normal_path;
    let Erc20;


    let buy_path, sell_path;

    beforeEach(async () => {
        novaWallet = await NovaWallet.new(owner, { from: owner });



        WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
        TOKENIN = ""
        TARGET = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
        normal_path = true

        if (normal_path) {
            buy_path = [WBNB, TARGET];
            sell_path = [TARGET, WBNB]

        } else {
            buy_path = [WBNB, TOKENIN, TARGET]
            sell_path = [TARGET, TOKENIN, WBNB]
        }

        await novaWallet.unlock(TARGET, { from: owner })

        await web3.eth.sendTransaction({ from: owner, to: novaWallet.address, value: initialEther });
        console.log("Ether sent to NovaWallet contract:", initialEther.toString());




    });

    describe("buy function", () => {
        it("should allow a user to buy tokens", async () => {
            // maybe get the input for the simulation;
            await novaWallet.grantInitRole(user1, { from: owner });
            await novaWallet.swapExactETHForTokens(
                web3.utils.toWei("0.01", "ether"),
                buy_path,
                WBNB,
                Date.now(),
                { from: user1 }
            );


            Erc20 = await ERC20.at(TARGET)
            let balance = await Erc20.balanceOf(novaWallet.address)
            console.log(`Actual out-amount: ${balance}`)

        });
    });

    describe("sell function", () => {
        it("should allow a user to sell tokens", async () => {
            await novaWallet.grantInitRole(user1, { from: owner });
            await novaWallet.swapExactETHForTokens(
                web3.utils.toWei("0.5", "ether"),
                buy_path,
                WBNB,
                Date.now(),
                { from: user1 }
            );

            await novaWallet.sell_safe(
                50,
                20,
                sell_path,
                novaWallet.address,
                Date.now(),
                { from: user1 }
            );

        });
    });
});
