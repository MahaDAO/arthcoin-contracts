// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../interfaces/IOracle.sol';
import '../lib/UniswapV2Library.sol';

contract MockOracle is IOracle {
    using SafeMath for uint256;

    uint256 epoch;
    uint256 period = 1;

    uint256 public price = 1e18;
    bool public error;

    uint256 startTime;

    constructor() public {
        startTime = block.timestamp;
    }

    // epoch
    function callable() public pure returns (bool) {
        return true;
    }

    function setEpoch(uint256 _epoch) public {
        epoch = _epoch;
    }

    function setStartTime(uint256 _startTime) public {
        startTime = _startTime;
    }

    function setPeriod(uint256 _period) public {
        period = _period;
    }

    function getLastEpoch() public view returns (uint256) {
        return epoch;
    }

    function getCurrentEpoch() public view returns (uint256) {
        return epoch;
    }

    function getNextEpoch() public view returns (uint256) {
        return epoch.add(1);
    }

    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(getNextEpoch().mul(period));
    }

    // params
    function getPeriod() public view returns (uint256) {
        return period;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function setPrice(uint256 _price) public {
        price = _price;
    }

    function setRevert(bool _error) public {
        error = _error;
    }

    function getPrice() external view override returns (uint256) {
        return price;
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) external pure returns (address lpt) {
        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }

    function update() public {
        require(!error, 'Oracle: mocked error');

        emit Updated(0, 0);
    }

    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast);
}
