// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/contracts/math/SafeMath.sol';
import {Vault} from './Vault.sol';
import {VaultBoardroom} from './VaultBoardroom.sol';

contract VestedVaultBoardroom is VaultBoardroom {
    // For how much time should vesting take place.
    uint256 public vestFor;
    using SafeMath for uint256;

    /**
     * Event.
     */
    event VestingPeriodChanged(uint256 oldPeriod, uint256 period);

    /**
     * Constructor.
     */
    constructor(
        IERC20 token_,
        Vault vault_,
        uint256 vestFor_
    ) VaultBoardroom(token_, vault_) {
        vestFor = vestFor_;
    }

    /**
     * Views/Getters.
     */
    function earned(address director) public view override returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(director).rewardPerShare;

        // If last time rewards claimed were less than the latest epoch start time,
        // then we don't consider those rewards in further calculations and mark them
        // as pending.
        uint256 latestFundingTime = boardHistory[boardHistory.length - 1].time;
        uint256 rewardEarned =
            (
                directors[director].lastClaimedOn < latestFundingTime
                    ? 0
                    : directors[director].rewardEarned
            );

        return
            vault
                .balanceWithoutBonded(director)
                .mul(latestRPS.sub(storedRPS))
                .div(1e18)
                .add(rewardEarned);
    }

    /**
     * Setters.
     */
    function setVestFor(uint256 period) public onlyOwner {
        emit VestingPeriodChanged(vestFor, period);
        vestFor = period;
    }

    function claimReward() public override directorExists returns (uint256) {
        _updateReward(msg.sender);

        uint256 reward = directors[msg.sender].rewardEarned;
        if (reward <= 0) return 0;

        uint256 latestFundingTime = boardHistory[boardHistory.length - 1].time;

        // If past the vesting period, then claim entire reward.
        if (block.timestamp >= latestFundingTime.add(vestFor)) {
            // If past latest funding time and vesting period then we claim entire 100%
            // reward from both previous and current and subtract the reward already claimed
            // in this epoch.
            reward = reward.add(directors[msg.sender].rewardPending).sub(
                directors[msg.sender].rewardClaimedThisEpoch
            );

            directors[msg.sender].rewardEarned = 0;
            directors[msg.sender].rewardPending = 0;
            directors[msg.sender].rewardClaimedThisEpoch = 0;
        }
        // If not past the vesting period, then claim reward as per linear vesting.
        else {
            uint256 timeSinceLastFunded =
                block.timestamp.sub(latestFundingTime);

            // Calculate reward to be given assuming msg.sender has not claimed in current
            // vesting cycle(8hr cycle).
            // NOTE: here we are multiplying by 1e3 to get precise decimal values.
            uint256 timelyRewardRatio =
                timeSinceLastFunded.mul(1e3).div(vestFor);

            if (directors[msg.sender].lastClaimedOn > latestFundingTime) {
                /*
                  And if msg.sender has claimed atleast once after the new vesting kicks in,
                  then we need to find the ratio for current time.

                  Let's say we want vesting to be for 10 seconds.
                  Then if we try to claim rewards at every 1 second then, we should get
                  1/10 of the rewards every second.
                  So for 1st second reward could be 1/10, for next also 1/10, we can convert
                  this to `(timeNext-timeOld)/timePeriod`.
                  For 1st second: (1-0)/10
                  For 2nd second: (2-1)/10
                  and so on.
                */
                uint256 timeSinceLastClaimed =
                    block.timestamp.sub(directors[msg.sender].lastClaimedOn);

                // NOTE: here we are multiplying by 1e3 to get precise decimal values.
                timelyRewardRatio = timeSinceLastClaimed.mul(1e3).div(vestFor);
            }

            // Update reward as per vesting.
            // NOTE: here we are nullyfying the multplication by 1e3 effect on the top.
            reward = timelyRewardRatio.mul(reward).div(1e3);

            // We add the reward claimed in this epoch to the variables.
            directors[msg.sender].rewardClaimedThisEpoch = (
                directors[msg.sender].rewardClaimedThisEpoch.add(reward)
            );

            // If this is the first claim inside this vesting period, then we also
            // give away 100% of previous vesting period's pending rewards.
            if (directors[msg.sender].lastClaimedOn < latestFundingTime) {
                // HERE since this is the first claim we don't need to subtract claim reward in this epoch variable.
                reward = reward.add(directors[msg.sender].rewardPending);
                directors[msg.sender].rewardPending = 0;
            }
        }

        directors[msg.sender].lastClaimedOn = block.timestamp;

        token.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);

        return reward;
    }

    function claimAndReinvestReward() external virtual {
        uint256 reward = claimReward();
        vault.bondFor(msg.sender, reward);
    }

    function _updateReward(address director) private {
        Boardseat storage seat = directors[director];

        // Set the default latest funding time to 0.
        // This represents that boardroom has not been allocated seigniorage yet.
        uint256 latestFundingTime = 0;

        // Check if seigniorage has been allocated more than once or not.
        if (boardHistory.length == 1) {
            // If only once, then we recalculate the reward per share depending on
            // the reward that was received while allocating and current supply of
            // the pool.

            boardHistory[0].rewardPerShare = boardHistory[0]
                .rewardReceived
                .mul(1e18)
                .div(vault.totalSupply());
        } else {
            // If more than once, then we recalculate the reward per share depending on
            // the rewad per share of the previous allocation(Refer: vaultBoardroom.sol, L: ~168) and the reward that was
            // received while allocating and current supply of the pool.
            uint256 oldRewardPerShare =
                boardHistory[boardHistory.length - 2].rewardPerShare;

            boardHistory[boardHistory.length - 1].rewardPerShare = (
                oldRewardPerShare.add(
                    boardHistory[boardHistory.length - 1]
                        .rewardReceived
                        .mul(1e18)
                        .div(vault.totalSupply())
                )
            );

            latestFundingTime = boardHistory[boardHistory.length - 1].time;
        }

        // If rewards are updated before epoch start of the current,
        // then we mark claimable rewards as pending and set the
        // current earned rewards to 0.
        if (seat.lastClaimedOn < latestFundingTime) {
            seat.rewardPending = seat.rewardEarned.sub(
                seat.rewardClaimedThisEpoch
            );
            seat.rewardEarned = 0;
            seat.rewardClaimedThisEpoch = 0;
        }

        seat.rewardEarned = earned(director);
        seat.lastSnapshotIndex = latestSnapshotIndex();
    }
}
