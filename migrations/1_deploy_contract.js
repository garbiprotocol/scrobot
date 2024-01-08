const scrobot = artifacts.require("scrobot");
const stETH = artifacts.require("stETH");
const point = artifacts.require("point");
const miningMachine = artifacts.require("miningMachine");

// const address_stETH = '0x773044B9E67E5B8CdFfe0f3295db27e2e3DD5a1e';     // sepolia
// const address_point = '0x1ce14D96e1f33eFC8844f30C8FC396e9c6b92cB0';     // sepolia
// const address_miningMachine = '0x6B6F886c2aC84A630cb1A89B12D0B168272379d3';     // sepolia

const address_stETH = '0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034';     // holesky
const address_point = '0xf139d03D4CD2f86c9a9a65a9558A1898aD1278DD';     // holesky
const address_miningMachine = '';     // holesky

module.exports = function(deployer) {
    // deployer.deploy(stETH);
    // deployer.deploy(point, "100000000000000000000000000");
    deployer.deploy(scrobot, address_stETH,  address_point);
    // deployer.deploy(miningMachine, address_point, 0);
};