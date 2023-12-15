// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract stETH is Ownable, ERC20 {
    constructor() ERC20("stETH", "stETH") {}

    function submit(address _referral) external payable {
        require(_referral != address(0), "INVALID_INPUT");
        _mint(msg.sender, msg.value);
    }

    function mintReward(address _user, uint256 _amount) public onlyOwner {
        _mint(_user, _amount);
    }

    function widthdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}