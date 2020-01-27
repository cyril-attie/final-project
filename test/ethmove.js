const EthMov = artifacts.require("EthMov");
const Withdrawal = artifacts.require("Withdrawal");
const assert = require("chai").assert;
const truffleAssert = require('truffle-assertions');

contract('EthMov', (accounts) => {
    beforeEach('setup contract for each test', async function () {
       
    })
    
    it('should be able to create a transport demand', async () => {
        const EthMovInstance = await EthMov.deployed();
        const transporter = accounts[3];
        let _to = accounts[2];
        let _sizeCategory = 0;
        let _weightCategory = 0;
        let _itinerary = [48.861700, 2.343343, 37.789617, -122.390179].map(x => x * 10**6);;
        let _maxDeliveryTimestamp = 1581634800.0;
        let _weiPacketValue = web3.utils.toWei('0.06', 'ether');
        let _bidPrice = web3.utils.toWei('0.09', 'ether');

        let transportDemand1 = [_to, _sizeCategory, _weightCategory,_itinerary,_maxDeliveryTimestamp, _weiPacketValue,_bidPrice];
        
        let id = Number(await EthMovInstance.demandTransport.call(...transportDemand1, {from :accounts[0]})); 
        let itinerary = (await EthMovInstance.viewItinerary.call(id, {from : transporter})).map(x => Number(x));
        console.log(itinerary);
        console.log(typeof(itinerary));
        
        assert.equal(itinerary, _itinerary, "Itinerary wasn't [48.861700, 2.343343, 37.789617, -122.390179]");

    });

    // it('should store and view list of available offers for particular transport demand', async () => {
    //     const metaCoinInstance = await MetaCoin.deployed();
    //     const metaCoinBalance = (await metaCoinInstance.getBalance.call(accounts[0])).toNumber();
    //     const metaCoinEthBalance = (await metaCoinInstance.getBalanceInEth.call(accounts[0])).toNumber();

    //     assert.equal(metaCoinEthBalance, 2 * metaCoinBalance, 'Library function returned unexpected function, linkage may be broken');
    // });
    // it('should cancel transport demand', async () => {
        
    //     // Setup 2 accounts.
    //     const accountOne = accounts[0];
    //     const accountTwo = accounts[1];

    //     // Get initial balances of first and second account.
    //     const accountOneStartingBalance = (await metaCoinInstance.getBalance.call(accountOne)).toNumber();
    //     const accountTwoStartingBalance = (await metaCoinInstance.getBalance.call(accountTwo)).toNumber();

    //     // Make transaction from first account to second.
    //     const amount = 10;
    //     await metaCoinInstance.sendCoin(accountTwo, amount, { from: accountOne });

    //     // Get balances of first and second account after the transactions.
    //     const accountOneEndingBalance = (await metaCoinInstance.getBalance.call(accountOne)).toNumber();
    //     const accountTwoEndingBalance = (await metaCoinInstance.getBalance.call(accountTwo)).toNumber();


    //     assert.equal(accountOneEndingBalance, accountOneStartingBalance - amount, "Amount wasn't correctly taken from the sender");
    //     assert.equal(accountTwoEndingBalance, accountTwoStartingBalance + amount, "Amount wasn't correctly sent to the receiver");
    // });
    // it('should cancel supply offer', async () => {

    // };)

    // it('should record pick up', async () => {

    // };)

    // it('should record delivery', async () => {

    // };)
});

