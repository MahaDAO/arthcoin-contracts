// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {
    AccessControl
} from '@openzeppelin/contracts/contracts/access/AccessControl.sol';
import {Ownable} from '@openzeppelin/contracts/contracts/access/Ownable.sol';
import {IBasisAsset} from './interfaces/IBasisAsset.sol';

/**
 * This contract is the owner/operator of ARTH & ARTH Bonds.
 */
contract Maharaja is AccessControl, Ownable {
    bytes32 public constant CASH_OPERATOR = keccak256('CASH_OPERATOR');
    bytes32 public constant BOND_OPERATOR = keccak256('BOND_OPERATOR');

    // RBAC contract has to be the operator/owner of these assets.
    IBasisAsset public cash;
    IBasisAsset public bond;
    bool public migrated = false;

    constructor(IBasisAsset cash_, IBasisAsset bond_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BOND_OPERATOR, _msgSender());
        _setupRole(CASH_OPERATOR, _msgSender());

        cash = cash_;
        bond = bond_;
    }

    function migrate(address target) external onlyOwner {
        require(target != address(0), 'migrate to zero');
        require(!migrated, '!migrated');

        // cash
        cash.transferOperator(target);
        cash.transferOwnership(target);
        cash.transfer(target, cash.balanceOf(address(this)));

        // bond
        bond.transferOperator(target);
        bond.transferOwnership(target);
        bond.transfer(target, bond.balanceOf(address(this)));

        migrated = true;
    }

    function grantOperator(address who) external onlyOwner {
        grantRole(CASH_OPERATOR, who);
        grantRole(BOND_OPERATOR, who);
    }

    function mintCash(address who, uint256 amount) external {
        require(hasRole(CASH_OPERATOR, _msgSender()));
        cash.mint(who, amount);
    }

    function mintBond(address account, uint256 amount) external {
        require(hasRole(BOND_OPERATOR, _msgSender()));
        bond.mint(account, amount);
    }

    function burnCash(address account, uint256 amount) external {
        require(hasRole(CASH_OPERATOR, _msgSender()));
        cash.burnFrom(account, amount);
    }

    function burnBond(address account, uint256 amount) external {
        require(hasRole(BOND_OPERATOR, _msgSender()));
        bond.burnFrom(account, amount);
    }
}
