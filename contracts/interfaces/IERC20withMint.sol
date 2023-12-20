// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20withMint is IERC20 {
   function mint(address _user, uint256 _amount) external; 
}