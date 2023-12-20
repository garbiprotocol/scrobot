const scrobot = artifacts.require("scrobot");
const stETH = artifacts.require("stETH");
const point = artifacts.require("point");
const miningMachine = artifacts.require("miningMachine");

const address_stETH = '0x773044B9E67E5B8CdFfe0f3295db27e2e3DD5a1e';     // sepolia
const address_point = '0x1ce14D96e1f33eFC8844f30C8FC396e9c6b92cB0';     // sepolia

module.exports = function(deployer) {
    // deployer.deploy(stETH);
    // deployer.deploy(point, "10000000000000000000000000");
    // deployer.deploy(scrobot, address_stETH,  address_point);
    deployer.deploy(miningMachine, address_point, 0);
};