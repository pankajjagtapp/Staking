// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public DEFI;

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public lastStakedTime;
    mapping(address => uint256) public rewardsToClaim;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    error InvalidAmount();
    error TransferFailed();
    error NothingToWithdraw();

    constructor(address DEFItokenAddr) {
        DEFI = IERC20(DEFItokenAddr);
    }

    function stake(uint256 amount) external nonReentrant {
        if (amount == 0) {
            revert InvalidAmount();
        }
        DEFI.safeTransferFrom(msg.sender, address(this), amount);

        if (stakedAmount[msg.sender] > 0) {
            rewardsToClaim[msg.sender] += calculateReward(msg.sender);
        }
        lastStakedTime[msg.sender] = block.timestamp;
        stakedAmount[msg.sender] += amount;

        emit Staked(msg.sender, amount);
    }

    function withdraw() external nonReentrant {
        uint256 amountToWithdraw = stakedAmount[msg.sender];

        if (amountToWithdraw == 0) {
            revert NothingToWithdraw();
        }

        uint256 reward = calculateReward(msg.sender);

        rewardsToClaim[msg.sender] = 0;
        stakedAmount[msg.sender] = 0;
        lastStakedTime[msg.sender] = block.timestamp;

        DEFI.safeTransfer(msg.sender, amountToWithdraw + reward);

        emit Withdrawn(msg.sender, amountToWithdraw + reward);
    }

    function getUserRewards(address user) external view returns (uint256) {
        uint256 reward = calculateReward(user);
        return rewardsToClaim[user] + reward;
    }

    function calculateReward(address user) internal view returns (uint256) {
        // The user should be rewarded a total of 1 DEFI token per day for every 1000 DEFI tokens staked.
        return
            ((block.timestamp - lastStakedTime[user]) * stakedAmount[user]) /
            (1 days * 1000);
    }
}
