const assert = require('chai').assert;

const { BN } = require('@openzeppelin/test-helpers');

const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const PulsarRouter = artifacts.require("PulsarRouter");
const L = console.log



contract('PulsarReferral', (accounts) => {
    let contractInstance;
    let nova;

    before(async () => {
        contractInstance = await PulsarRouter.deployed();
        // await contractInstance.initialize({ from: accounts[0] });

    });

    it('user1 creates referral code and 11 other users create referral codes', async () => {

        // user1 creates referral code
        const referralCode1 = 'referralCode1';
        let res = await contractInstance.generateReferralCode(referralCode1, { from: accounts[3] });
        L(res)

        // user2 - user11 create referral codes
        // for (let i = 2; i <= 12; i++) {
        //     const referralCode = `referralCode${i}`;
        //     console.log(`creating referralCode${i} for account${i}`);
        //     await contractInstance.generateReferralCode(referralCode, { from: accounts[i] });
        // }
    });

    it('5 users set referral code of user1 and call incrementP function', async () => {

        // account0 -> account3 -> account6 ->
        // user2 - user5 set referral code of user1 and call incrementP function
        for (let i = 3; i <= 3; i++) {
            await contractInstance.setReferral('referralCode1', { from: accounts[i] });
            await contractInstance.incrementP(10, accounts[i]);
        }

        for (let i = 4; i <= 4; i++) {
            await contractInstance.setReferral('referralCode3', { from: accounts[i] });
            await contractInstance.incrementP(20, accounts[i]);
        }

        for (let i = 6; i <= 6; i++) {
            await contractInstance.setReferral('referralCode5', { from: accounts[i] });
            await contractInstance.incrementP(30, accounts[i]);
        }

        for (let i = 7; i <= 9; i++) {
            await contractInstance.setReferral('referralCode6', { from: accounts[i] });
            await contractInstance.incrementP(40, accounts[i]);
        }

        for (let i = 10; i <= 10; i++) {
            await contractInstance.setReferral('referralCode8', { from: accounts[i] });
            await contractInstance.incrementP(50, accounts[i]);
        }

        const rootNodeAddress = accounts[0];
        const sum = await contractInstance.traverseTree(rootNodeAddress, 0);
        const reward = await contractInstance.showRewardsStringCode('referralCode1', 0);


    });

    it('calls the mintPerformance function and logs the balance of the performance coin of account 0', async () => {
        // Call the mintPerformance function
        await contractInstance.mintPerformanceTokens(0, { from: accounts[0] });

        // Get the PulsarPerformanceToken contract instance
        const performanceCoinAddress = await contractInstance.pulsarPerformanceToken();
        const performanceCoin = await performanceCoinInstance.at(performanceCoinAddress.toString())

        // Get the balance of the performance coin of account 0
        const balance = await performanceCoin.balanceOf(accounts[0]);

        // Log the balance
        console.log(`The balance of the performance coin of account 0 is: ${balance}`);
    });
});