// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol';
import {Operator} from './owner/Operator.sol';

contract VoteProxy is Operator {
    // Events
    event BoardroomChanged(
        address indexed operator,
        address indexed oldBoardroom,
        address indexed newBoardroom
    );

    // Boardroom
    address public boardroom;

    constructor(address _boardroom) {
        boardroom = _boardroom;
    }

    function setBoardroom(address newBoardroom) public onlyOperator {
        address oldBoardroom = boardroom;
        boardroom = newBoardroom;
        emit BoardroomChanged(msg.sender, oldBoardroom, newBoardroom);
    }

    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return 'MAHA in Boardroom';
    }

    function symbol() external pure returns (string memory) {
        return 'SMAHA';
    }

    function totalSupply() external view returns (uint256) {
        return IERC20(boardroom).totalSupply();
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return IERC20(boardroom).balanceOf(_voter);
    }
}
