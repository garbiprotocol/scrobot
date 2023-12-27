// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './interfaces/IScrFarm.sol';
import './interfaces/IERC20withMint.sol';

contract miningMachine is Ownable{

    using SafeMath for uint256;

    IERC20withMint public TOKEN_REWARD;
    // just use for dislay at UI
    uint256 public totalBlockPerDay = 5760;
    // token reward each block.
    uint256 public tokenRewardPerBlock = 16*1e16; //0.16 token/block
    // The total point for all pools
    uint256 public totalAllocPoint = 1000;
    // The block when mining start
    uint256 public startBlock;

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => uint256)) public rewardDebtOf;

    struct PoolInfo {
    	address want;                   // token Addess
        IScrFarm scrFarm;               // Address Farm Contract.
        uint256 allocPoint;                
        uint256 lastRewardBlock;        // Last block number when the pool get reward.
        uint256 accTokenRewardPerShare; // Acc Per Share of the pool.
    }

    event onHarvest(uint256 _pid, address _user, uint256 _amt);

    constructor(
        IERC20withMint _tokenReward,
        uint256 _startBlock
    ) {
        TOKEN_REWARD = _tokenReward;
        startBlock = _startBlock;
    }

    function setTotalBlockPerDay(uint256 _totalBlockPerDay) public onlyOwner {
        totalBlockPerDay = _totalBlockPerDay;
    }

    function setTotalAllocPoint(uint256 _totalAllPoint) public onlyOwner {
        totalAllocPoint = _totalAllPoint;
    }

    function setTokenRewardContract(address _tokenReward) public onlyOwner {
        TOKEN_REWARD = IERC20withMint(_tokenReward);
    }

    // Add a new pool. Can only be called by the owner.
    function addPool(uint256 _allocPoint, IScrFarm _scrFarm) public onlyOwner { 

    	address want = address(_scrFarm.want());
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo.push(PoolInfo({
            want: want,
            scrFarm: _scrFarm,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accTokenRewardPerShare: 0
        }));
    }

    //Update the given pool's allocation point. Can only be called by the owner.
    function setPoolPoint(uint256 _pid, uint256 alloc_point) public onlyOwner 
    {
    	require(poolInfo[_pid].allocPoint != alloc_point, 'INVALID_INPUT');
    	updatePool(_pid);
        poolInfo[_pid].allocPoint = alloc_point;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {

        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 _totalShare = pool.scrFarm.totalShare();
        
        uint256 _multiplier = getBlockFrom(pool.lastRewardBlock, block.number);

        uint256 _reward = _multiplier.mul(tokenRewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        if (_totalShare == 0) {

            pool.lastRewardBlock = block.number;

            return;
        }

        TOKEN_REWARD.mint(address(this), _reward);

        pool.accTokenRewardPerShare = pool.accTokenRewardPerShare.add(_reward.mul(1e12).div(_totalShare));

        pool.lastRewardBlock = block.number;
    }

    function harvest(uint256 _pid, address _user) external returns(uint256 _pendingTokenReward) 
    {	
    	updatePool(_pid);
    
    	uint256 _rewardDebt;
    	(_pendingTokenReward, _rewardDebt, ) = getUserInfo(_pid, _user);

    	uint256 _tokenRewardBal = TOKEN_REWARD.balanceOf(address(this));

    	rewardDebtOf[_pid][_user] = _rewardDebt;

        if (_pendingTokenReward > _tokenRewardBal) {
            _pendingTokenReward = _tokenRewardBal;
    	}
        if (_pendingTokenReward > 0) {
            TOKEN_REWARD.transfer(_user, _pendingTokenReward);
            emit onHarvest(_pid, _user, _pendingTokenReward);
        }
    }

    function updateUser(uint256 _pid, address _user) public returns(bool)
    {
        PoolInfo memory pool = poolInfo[_pid];
        require(address(pool.scrFarm) == msg.sender, 'INVALID_PERMISSION');

        uint256 _userShare  = pool.scrFarm.shareOf(_user);
        rewardDebtOf[_pid][_user] = _userShare.mul(pool.accTokenRewardPerShare).div(1e12);

        return true;
    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getBlockFrom(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function getMiningSpeedOf(uint256 _pid) public view returns(uint256) {
        return poolInfo[_pid].allocPoint.mul(100).div(totalAllocPoint);
    }

    function getTotalMintPerDayOf(uint256 _pid) public view returns(uint256) {
        return totalBlockPerDay.mul(tokenRewardPerBlock).mul(poolInfo[_pid].allocPoint).div(totalAllocPoint);
    }

    function getTokenRewardAddr() public view returns(address) {
        return address(TOKEN_REWARD);
    }

    // View function to get User's Info in a pool.
    function getUserInfo(uint256 _pid, address _user) public view returns (uint256 _pendingTokenReward, uint256 _rewardDebt, uint256 _userShare) { 

        PoolInfo memory pool = poolInfo[_pid];

        uint256 accTokenRewardPerShare = pool.accTokenRewardPerShare;

        uint256 _totalShare = pool.scrFarm.totalShare();
        _userShare  = pool.scrFarm.shareOf(_user);

        if (block.number > pool.lastRewardBlock && _totalShare != 0) {
            uint256 _multiplier = getBlockFrom(pool.lastRewardBlock, block.number);
            uint256 _reward = _multiplier.mul(tokenRewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokenRewardPerShare = accTokenRewardPerShare.add(_reward.mul(1e12).div(_totalShare));
        }
        _rewardDebt  = _userShare.mul(accTokenRewardPerShare).div(1e12);

        if (_rewardDebt > rewardDebtOf[_pid][_user]) {
            _pendingTokenReward = _rewardDebt.sub(rewardDebtOf[_pid][_user]);
        }
    }
}