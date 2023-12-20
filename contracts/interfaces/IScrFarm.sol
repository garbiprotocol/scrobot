// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IScrFarm {

   uint256 public totalShare;

   IERC20 public want;

   mapping(address => uint256) public shareOf; 
}