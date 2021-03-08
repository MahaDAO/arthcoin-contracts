// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IVault} from '../../interfaces/IVault.sol';
import {IERC20} from '@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol';
import {VaultBoardroom} from '../core/VaultBoardroom.sol';

contract ArthArthEthLiquidityBoardroomV2 is VaultBoardroom {
    constructor(IERC20 cash_, IVault vault_) VaultBoardroom(cash_, vault_) {}
}