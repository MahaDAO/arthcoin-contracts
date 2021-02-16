// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './core/SimpleOracle.sol';

contract ArthMahaOracle is SimpleOracle {
    constructor() SimpleOracle('ArthMahaOracle', 1e18) {}
}
