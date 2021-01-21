// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract IMultiRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(address token, uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            'Caller is not reward distribution'
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        virtual
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}
