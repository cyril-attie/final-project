const Withdrawal = artifacts.require("Withdrawal.sol");
const EthMov = artifacts.require("EthMov.sol");

module.exports = function(deployer) {
  deployer.deploy(Withdrawal).then(function() {
    return deployer.deploy(EthMov, Withdrawal.address);
  });
};
