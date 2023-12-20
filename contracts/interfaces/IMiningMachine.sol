// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMiningMachine {
	function harvest(uint256 _pid, address _user) external returns(uint256 _pendingTokenReward);
	function updateUser(uint256 _pid, address _user) external returns(bool); 

	function getMiningSpeedOf(uint256 _pid) external view returns(uint256);
	function getTotalMintPerDayOf(uint256 _pid) external view returns(uint256);
	function getUserInfo(uint256 _pid, address _user) external view returns (uint256 _pendingTokenReward, uint256 _rewardDebt, uint256 _userShare);
	function getTokenRewardAddr() external view returns(address); 
}