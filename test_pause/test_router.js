const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const {
    BN
} = require('@openzeppelin/test-helpers');
const { expect } = require("chai");

// ganache-cli -f http://localhost:8545 -p 7545 -m "myth like bonus scare over problem client lizard pioneer submit female collect" 

const PulsarRouter = artifacts.require("PulsarRouter");
const ERC20 = artifacts.require('IERC20');


contract("PulsarRouter", (accounts) => {
    let pulsarRouterInstance;
    const owner = accounts[0];
    const user1 = accounts[1];
    let Erc20;
    let BUSD


    beforeEach(async () => {
        pulsarRouterInstance = await PulsarRouter.new({ from: owner });
        await pulsarRouterInstance.initialize({ from: owner });
        // await pulsarRouterInstance.updatePlan(1, 100, 300000000, 10, { from: owner });
        BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";

    });

    it('tests the quote function', async () => {
        const amount = 100;

        const result = await pulsarRouterInstance.quote(amount, { from: accounts[2] });
        // console.log(`the result is ${JSON.stringify(result)}`)

        // assert.equal(result, expectedWbnb, 'The quote function did not return the expected WBNB amount');

    });


    it("should create a NOVA BNB contract", async () => {
        // Set up a plan
        const subscriptionId = 1;
        const price = 100;
        const expirationDate = 100000;
        const discount = 10;

        await pulsarRouterInstance.updatePlan(
            subscriptionId,
            price,
            expirationDate,
            discount
            , { from: owner });


        console.log("router:", pulsarRouterInstance.address)
        // Send a transaction to create a NOVA BNB contract
        const tx = await pulsarRouterInstance.createNovaBNB(subscriptionId, {
            value: web3.utils.toWei("0.35", "ether"),
            from: accounts[3],
        });

        // 100000000000000000000
        // 104773700496823283328

        const logs = await pulsarRouterInstance.getPastEvents("Log", {
            fromBlock: tx.blockNumber,
            toBlock: "latest",
        });

        for (let i = 0; i < logs.length; i++) {
            console.log(`Event: ${JSON.stringify(logs[i])}`);
        }




        // for (let i = 0; i < logs.length; i++) {
        //     console.log(`Event: ${JSON.stringify(logs[i])}`);
        // }
        // const value = web3.utils.toWei("0.35", "ether")
        // console.log(value)
        // const convert = await pulsarRouterInstance.convertToBusd(value, { value: value })
        // console.log(convert)
        // console.log(`${JSON.stringify(tx)}`)

        // const logs = await pulsarRouterInstance.getPastEvents("NovaCreated", {
        //     fromBlock: tx.blockNumber,
        //     toBlock: "latest",
        // });

        // const NovaCreatedEvent = pulsarRouterInstance.events.NovaCreated({}, (error, event) => {
        //     if (error) console.log(error);
        //     console.log("Nova address:", event.returnValues.nova);
        // });

        // Log the events
        // for (let i = 0; i < logs.length; i++) {
        //     console.log(`Event: ${JSON.stringify(logs[i])}`);
        // }

        // const wallet_address = await pulsarRouterInstance.subscriptions(accounts[3])
        // console.log("wallet: ", wallet_address)

        // await web3.eth.sendTransaction({ from: accounts[9], to: wallet_address, value: web3.utils.toWei("1", "ether") });



        Erc20 = await ERC20.at(BUSD)
        let balance = await Erc20.balanceOf(pulsarRouterInstance.address)
        console.log(`Actual out-amount: ${balance}`)
        // 97,725578889207455410

    });
});



// create an entry for that in the database;
// gas account can be any funded account
// owner of wallet 1 is account 4
