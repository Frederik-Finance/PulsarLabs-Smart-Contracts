const NovaWallet = artifacts.require("NovaWallet");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const { TokenAmount } = require("@uniswap/sdk");



contract("NovaWallet", async (accounts) => {
    const owner = accounts[0];
    const gasAccount = accounts[1];
    const alice = accounts[2];
    const amount = web3.utils.toWei("1", "ether");
    const amountOutMin = web3.utils.toWei("0.05", "ether")
    const path = ["0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"];
    // const deadline = Math.floor(Date.now() / 1000) + 300; // 5 minutes from now
    const deadline = 0

    it("should grant init role to an account and swap tokens", async () => {
        const novaWallet = await NovaWallet.new(gasAccount, { from: owner });
        await novaWallet.grantInitRole(alice, { from: owner });

        // Approve path
        await novaWallet.unlockPath(path, { from: owner });

        // Transfer funds to contract
        await web3.eth.sendTransaction({ from: alice, to: novaWallet.address, value: amount });

        // Transfer funds to gas account
        await web3.eth.sendTransaction({ from: alice, to: gasAccount, value: amount });

        // Check gas account balance
        const gasAccountBalance = await web3.eth.getBalance(gasAccount);
        // assert.equal(gasAccountBalance, amount);

        // Swap tokens
        await novaWallet.swapTokens(amountOutMin, 50, 1, path, alice, deadline, true, { from: alice });
        // await novaWallet.swapExactETHForTokens(amountOutMin, path, alice, deadline, { from: alice }); // value: web3.utils.toWei("0.1", "ether")

        // await novaWallet.sellSafe(
        //     50,
        //     50,
        //     path.reverse(),
        //     novaWallet.address,
        //     { from: alice }
        // );


        // check if withdrawal is possible 

        // Withdraw 1 ETH from the contract to the owner's account



        // Print balance of 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
        const tokenContract = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
        const balance = await web3.eth.call({ to: tokenContract, data: `0x70a08231000000000000000000000000${novaWallet.address.substring(2)}` });
        console.log(`Balance of BUSD in ${novaWallet.address}: ${web3.utils.fromWei(balance)}`);


        // Check balances
        const ETHbalance = await web3.eth.getBalance(novaWallet.address);
        console.log(ETHbalance)
        // assert.equal(balance, 0);

        await novaWallet.withdrawTokens(tokenContract, "10", { from: alice });
        await novaWallet.withdrawBNB(web3.utils.toWei("0.02", "ether"), { from: accounts[0] });

        const finalBalance = await web3.eth.getBalance(novaWallet.address);
        const finalTokenBalance = await web3.eth.call({ to: tokenContract, data: `0x70a08231000000000000000000000000${novaWallet.address.substring(2)}` });

        console.log(`Balance of BUSD in ${novaWallet.address}: ${web3.utils.fromWei(finalTokenBalance)}`);

        console.log('BNB balance after witdrawal', finalBalance)

    });
});
