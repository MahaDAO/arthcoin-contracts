// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import './core/ARTHTOKENPool.sol';

contract MAHAMAHAETHLPTokenPool is ARTHTOKENPool {
    constructor(
        address cash_,
        address dai_,
        uint256 starttime_
    )
        public
        ARTHTOKENPool(
            cash_,
            dai_,
            starttime_,
            0,
            false,
            'MAHAMAHAETHLPTokenPool'
        )
    {}
}
