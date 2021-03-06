// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './core/SimpleOracle.sol';

contract GMUOracle is SimpleOracle {
    constructor() SimpleOracle('GMU Oracle', 1e18) {}
}
