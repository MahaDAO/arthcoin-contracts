// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './BACTOKENPool.sol';

contract ARTHBASPool is BACTOKENPool {
    constructor(
        address token0_,
        address token1_,
        uint256 starttime_
    ) public BACTOKENPool(token0_, token1_, starttime_) {}
}
