// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IstETH.sol";
import "./interfaces/IMiningMachine.sol";

contract scrobot is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IstETH public stETH;

    IERC20 public want;     // POINT
    IMiningMachine public miningMachine;
    uint256 public pidOfMining;

    uint256 public totalShare = 0;
    uint256 public accWantPerShare = 0;
    uint256 public lastBalance = 0;
    uint256 public timeOfHarvest = 0;
    uint256 public lastCaculationReward = 0;
    uint256 public periodOfDay = 1 days;
    uint256 public timeUnlock = 7 days;
    uint256 public timeUnlockWithdrawReward = 60 days;

    mapping(address => uint256) public shareOf;
    mapping(address => uint256) public shareOfLocked;
    mapping(address => uint256) public rewardWantDebtOf;
    mapping(address => uint256) public lastTimeSubmitOf;

    uint256 public calculationRewardBlock = 10;

    address public receiverShareOf;

    event onSubmit(address _user, uint256 _amount);

    constructor(address _stETH, address _want) {
        want = IERC20(_want);
        stETH = IstETH(_stETH);

        lastCaculationReward = block.number;
    }

    function setWantToken(address _want) public onlyOwner {
        want = IERC20(_want);
    }

    function setMiningMachine(address _miningMachine) public onlyOwner {
        miningMachine = IMiningMachine(_miningMachine);
    }

    function setPidOfMining(uint256 _pid) public onlyOwner {
        pidOfMining = _pid;
    }

    function setTimeUnlockWithdraw(uint256 _time) public onlyOwner {
        timeUnlock = _time;
    }

    function setTimeUnlockWithdrawReward(uint256 _time) public onlyOwner {
        timeUnlockWithdrawReward = _time;
    }

    function setReceiverShareOf(address _receiver) public onlyOwner {
        receiverShareOf = _receiver;
    }

    function setCalculationRewardBlock(uint256 _quantityBlock) public onlyOwner {
        calculationRewardBlock = _quantityBlock;
    }

    function submit(address _referral) external payable {
        uint256 _amount = msg.value;
        require(_amount > 0, 'INVALID_INPUT');
        require(msg.sender.balance >= _amount, 'INVALID_INPUT');

        // harvest
        harvest(msg.sender);

        stETH.submit{value: msg.value}(_referral);

        shareOf[msg.sender] = shareOf[msg.sender].add(_amount);
        totalShare = totalShare.add(_amount);

        // update user
        lastTimeSubmitOf[msg.sender] = block.timestamp;
        rewardWantDebtOf[msg.sender] = shareOf[msg.sender].mul(accWantPerShare).div(1e24);
        miningMachine.updateUser(pidOfMining, msg.sender);

        lastBalance = stETH.balanceOf(address(this));

        emit onSubmit(msg.sender, _amount);
    }

    function harvest(address _user) public {
        timeOfHarvest = block.timestamp;
        miningMachine.harvest(pidOfMining, _user);
        
        if(block.number >= lastCaculationReward.add(calculationRewardBlock)) {
            lastCaculationReward = block.number;
            uint256 currentBalance = stETH.balanceOf(address(this));
            uint256 _reward = currentBalance <= lastBalance ? 0 : currentBalance.sub(lastBalance);
        
            if (_reward > 0 && totalShare > 0) {
                accWantPerShare = accWantPerShare.add(_reward.mul(1e24).div(totalShare));
            }

            uint256 _userRewardDebt  = shareOf[_user].mul(accWantPerShare).div(1e24);

            if (_userRewardDebt > rewardWantDebtOf[_user]) {
                uint256 _userPendingWant = _userRewardDebt.sub(rewardWantDebtOf[_user]);
                shareOf[_user] = shareOf[_user].add(_userPendingWant);
                shareOfLocked[_user] = shareOfLocked[_user].add(_userPendingWant);
                totalShare = totalShare.add(_userPendingWant); 
                miningMachine.harvest(pidOfMining, _user);
            }

            rewardWantDebtOf[_user] = shareOf[_user].mul(accWantPerShare).div(1e24);
            // update lastBalance
            lastBalance = currentBalance;
        }
    }

    function withdraw(uint256 _wantAmt) external nonReentrant 
    {
        address _user = msg.sender;
        require(block.timestamp > lastTimeSubmitOf[_user].add(timeUnlock), 'INVALID_TIME');

        harvest(_user);
        
        if (block.timestamp > lastTimeSubmitOf[_user].add(timeUnlockWithdrawReward)) {
            shareOfLocked[_user] = 0;
        }

        shareOf[receiverShareOf] = shareOf[receiverShareOf].add(shareOfLocked[_user]);

        shareOf[_user] = shareOf[_user].sub(shareOfLocked[_user]);

        if (shareOf[_user] < _wantAmt) {
            _wantAmt = shareOf[_user];
        }
        require(_wantAmt > 0, 'INVALID_INPUT');

        shareOf[_user] = shareOf[_user].sub(_wantAmt);
        totalShare = totalShare.sub(_wantAmt);

        stETH.transfer(_user, _wantAmt);

        // update user
        rewardWantDebtOf[_user] = shareOf[_user].mul(accWantPerShare).div(1e24);
        miningMachine.updateUser(pidOfMining, _user);
        shareOfLocked[_user] = 0;
        
        lastBalance = stETH.balanceOf(address(this));
    }

    function pendingReward(address _user) public view returns (uint256 _pendingWant) {

        uint256 _accWantPerShare  = accWantPerShare;
        uint256 _reward = stETH.balanceOf(address(this)).sub(lastBalance);
        if (
            _reward > 0 &&
            totalShare > 0
            ) {
            _accWantPerShare = _accWantPerShare.add(_reward.mul(1e24).div(totalShare));

        }
        uint256 _rewardDebt  = shareOf[_user].mul(_accWantPerShare).div(1e24);
        if (_rewardDebt > rewardWantDebtOf[_user]) {
            _pendingWant = _rewardDebt.sub(rewardWantDebtOf[_user]);
        }
    }

    function getTotalRewardPerDay() public view returns (uint256 _rewardPerDay) {
        uint256 _reward = stETH.balanceOf(address(this)).sub(lastBalance);
        uint256 _rewardPerSec = 0;
        if (block.timestamp > timeOfHarvest) {
           _rewardPerSec = _reward.div(block.timestamp.sub(timeOfHarvest));     
        }
        return _rewardPerSec.mul(periodOfDay);
    }

    function userInfo(address _user) public view returns (uint256[14] memory data) {
        data[0] = shareOf[_user];
        data[1] = totalShare;
        data[2] = pendingReward(_user);
        data[3] = stETH.balanceOf(_user);
        data[4] = address(_user).balance;
        data[5] = getTotalRewardPerDay();
        data[6] = miningMachine.getTotalMintPerDayOf(pidOfMining);
        (data[7], , ) = miningMachine.getUserInfo(pidOfMining, _user);
        
        if(data[1] > 0) {
            data[8] = data[5].mul(365).mul(10000).div(data[1]);
        }
        data[9] = want.balanceOf(_user);
        data[10] = lastTimeSubmitOf[_user];
        data[11] = block.timestamp;
        data[12] = shareOfLocked[_user];
        data[13] = (data[11] > data[10].add(timeUnlockWithdrawReward)) ? data[0] : data[0].sub(data[12]);
    }
}