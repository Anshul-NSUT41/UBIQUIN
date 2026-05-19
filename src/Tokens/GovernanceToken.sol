//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    ERC20Burnable
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {
    ERC20Permit
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {
    ERC20Votes
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title GovernanceToken
 * @notice Protocol governance and incentive token (GOV).
 *         Used for: on-chain voting, staking rewards distribution.
 * @dev    ERC20Votes enables historical balance checkpointing.
 *         ERC20Permit enables gasless approvals for staking UX.
 *         Hard capped at MAX_SUPPLY — no infinite inflation.
 */

contract GovernanceToken is
    ERC20,
    ERC20Burnable,
    ERC20Permit,
    ERC20Votes,
    AccessControl
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10 ** 18;

    error GovernanceToken__NotMinter();
    error GovernanceToken__MaxSupplyExceeded(
        uint256 MAX_SUPPLY,
        uint256 attemptedAmount
    );
    error GovernanceToken__ZeroAddress();
    error GovernanceToken__ZeroAmount();

    event MinterRoleGranted(address indexed account);
    event GovernanceMinted(address indexed to, uint256 amount);
    constructor(
        address admin,
        address initialHolder,
        uint256 initialSupply
    ) ERC20("Governance", "GOV") ERC20Permit("Governance") ERC20Votes() {
        if (admin == address(0)) {
            revert GovernanceToken__ZeroAddress();
        }
        if (initialSupply > MAX_SUPPLY) {
            revert GovernanceToken__MaxSupplyExceeded(
                MAX_SUPPLY,
                initialSupply
            );
        }
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        if (initialHolder == address(0)) {
            revert GovernanceToken__ZeroAddress();
        }
        if (initialSupply == 0) {
            revert GovernanceToken__ZeroAmount();
        }
        if (initialSupply > 0) {
            _mint(initialHolder, initialSupply);
        }
    }

    function grantMinterRole(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) revert GovernanceToken__ZeroAddress();
        _grantRole(MINTER_ROLE, account);
        emit MinterRoleGranted(account);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (to == address(0)) revert GovernanceToken__ZeroAddress();
        if (amount == 0) revert GovernanceToken__ZeroAmount();
        if (totalSupply() + amount > MAX_SUPPLY)
            revert GovernanceToken__MaxSupplyExceeded(MAX_SUPPLY, amount);
        _mint(to, amount);
        emit GovernanceMinted(to, amount);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function remainingMintableSupply() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }
}
