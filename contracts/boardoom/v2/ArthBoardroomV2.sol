// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '../core/VestedBondedBoardroom.sol';

contract ArthBoardroomV2 is VestedBondedBoardroom {
    constructor(
        IERC20 _cash,
        uint256 _duration,
        uint256 _vestFor
    ) public VestedBondedBoardroom(_cash, _cash, _duration, _vestFor) {}
}
