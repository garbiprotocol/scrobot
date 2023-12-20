const scrobot = artifacts.require("scrobot");
const stETH = artifacts.require("stETH");

const address_stETH = '0x773044B9E67E5B8CdFfe0f3295db27e2e3DD5a1e';     // sepolia
const address_point = '0x773044B9E67E5B8CdFfe0f3295db27e2e3DD5a1e';     // sepolia

module.exports = function(deployer) {
    // deployer.deploy(stETH);
    deployer.deploy(scrobot, address_stETH,  address_point);
};