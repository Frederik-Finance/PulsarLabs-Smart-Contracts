const assert = require('chai').assert;

/*
This Unit test is in development and not yet adapted to the updated version of the router contract

*/
const {
    BN
} = require('@openzeppelin/test-helpers');

const { web3 } = require("@openzeppelin/test-helpers/src/setup");

const PulsarReferral = artifacts.require('PulsarRouter');
const performanceCoinInstance = artifacts.require('PulsarReferralCoin');



contract('PulsarReferral', (accounts) => {
    let contractInstance;
    let nova;
    throw ('This Unit test is in development and not yet adapted to the updated version of the router contract')

    before(async () => {
        contractInstance = await PulsarReferral.deployed();

        console.log(await nova.PULSAR_ROUTER());
        await nova.mapIdToTier(0, 0, { from: accounts[0] });
    });

    it('user1 creates referral code and 11 other users create referral codes', async () => {

        // user1 creates referral code
        const referralCode1 = 'referralCode1';
        await contractInstance.generateReferralCode(referralCode1, { from: accounts[0] });

        // user2 - user11 create referral codes
        for (let i = 2; i <= 35; i++) {
            const referralCode = `referralCode${i}`;
            console.log(`creating referralCode${i} for account${i}`);
            await contractInstance.generateReferralCode(referralCode, { from: accounts[i] });
        }
    });

    it('5 users set referral code of user1 and call paySniper function', async () => {

        // account0 -> account3 -> account6 ->
        // user2 - user5 set referral code of user1 and call paySniper function
        for (let i = 3; i <= 3; i++) {
            await contractInstance.setReferral('referralCode1', { from: accounts[i] });
            await contractInstance.paySniper(1, { from: accounts[i] });
        }


        for (let i = 6; i <= 6; i++) {
            await contractInstance.setReferral('referralCode3', { from: accounts[i] });
            await contractInstance.paySniper(1, { from: accounts[i] });
        }

        for (let i = 7; i <= 9; i++) {
            await contractInstance.setReferral('referralCode6', { from: accounts[i] });
            await contractInstance.paySniper(1, { from: accounts[i] });
        }

        for (let i = 10; i <= 32; i++) {
            await contractInstance.setReferral('referralCode6', { from: accounts[i] });
            await contractInstance.paySniper(1, { from: accounts[i] });
        }
        const rootNodeAddress = accounts[0];
        const period = 0;
        const sum = await contractInstance.sumChildrenValues(rootNodeAddress, period);
        const childrenCount = await
            contractInstance.countChildren(rootNodeAddress, period);

        // assert.equal(sum.toNumber(), 300, 'Incorrect sum of points');
        // assert.equal(childrenCount, 2, 'Incorrect number of children');


        console.log(`Total value of children of node ${rootNodeAddress} in period ${period}: ${sum}`);
        console.log(`Number of children of node ${rootNodeAddress} in period ${period}: ${childrenCount}`);

        const rewards = await contractInstance.showRewardsStringCode('referralCode1', 0);
        console.log(`Rewards eligible for withdrawal for account ${accounts[0]} in period 0: ${rewards}`);

        // Rewards eligible for withdrawal for account 0xFc13A682E1866e0c1828e661193393EC326443C0 in period 0: 17640
    });


    it('calls the mintPerformance function and logs the balance of the performance coin of account 0', async () => {
        // Call the mintPerformance function
        await contractInstance.mintPerformanceTokens(0, { from: accounts[0] });
        // await contractInstance.mintPerformanceTokens(0, { from: accounts[0] });



        // Get the PulsarPerformanceToken contract instance
        const performanceCoinAddress = await contractInstance.pulsarPerformanceToken();
        const performanceCoin = await performanceCoinInstance.at(performanceCoinAddress.toString())

        // Get the balance of the performance coin of account 0
        const balance = await performanceCoin.balanceOf(accounts[0]);

        // Log the balance
        console.log(`The balance of the performance coin of account 0 is: ${balance}`);



    });


})