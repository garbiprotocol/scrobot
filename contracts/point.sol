// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract point is Ownable, ERC20Burnable {
    using SafeMath for uint256;

    address public miningMachineContract;
    uint256 public immutable MAX_SUPPLY;
    uint256 public totalBurned = 0;

    address public pointTaskPool;
    address public pointMarketingPool;

    uint256 public checkMintPool = 0;
    
    constructor(
        uint256 _maxSupply
    ) ERC20("point token", "POINT") {
        MAX_SUPPLY = _maxSupply;
    }
    
    modifier onlyMiningMachine() {
        require(msg.sender == miningMachineContract, 'INVALID_MINING_MACHINE');
        _;
    }

    function setTaskPool(address _pointTaskPool) public onlyOwner {
        pointTaskPool = _pointTaskPool;
    }

    function setMarketingPool(address _pointMarketingPool) public onlyOwner {
        pointMarketingPool = _pointMarketingPool;
    }

    function setMiningMachine(address _miningMachineContract) public onlyOwner {
        miningMachineContract = _miningMachineContract;
    }

    function mintMarkettingPool() public onlyOwner {
        require(pointMarketingPool != address(0), "INVALID_MARKETTING_POOL");
        require(checkMintPool == 0, "INVALID_MINT_POOL");
        checkMintPool = checkMintPool.add(1);
        _mint(pointMarketingPool, MAX_SUPPLY.mul(5).div(100)); // 5%
    }

    function mintTaskPool() public onlyOwner {
        require(pointTaskPool != address(0), "INVALID_TASK_POOL");
        require(checkMintPool == 1, "INVALID_MINT_POOL");
        checkMintPool = checkMintPool.add(1);
        _mint(pointTaskPool, MAX_SUPPLY.mul(5).div(100));  // 5%
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        totalBurned = totalBurned.add(amount);
    }

    function mint(address _user, uint256 _amount) external onlyMiningMachine {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply.add(_amount) <= MAX_SUPPLY, "No more minting allowed!");

        _mint(_user, _amount);
    }
    
}