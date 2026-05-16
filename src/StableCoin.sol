//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title StableCoin
/// @author Anshul
/// @notice ERC20 based stablecoin for the protocol
/// @dev Minting and burning controlled by owner/treasury

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    ERC20Burnable
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract StableCoin is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    error StableCoin__NotMinter();
    error StableCoin__ZeroAddress();
    error StableCoin__InsufficientBalance(uint256 balance, uint256 amount);
    error StableCoin__ZeroAmount();

    event MinterRoleGranted(address indexed account);
    event BurnerRoleGranted(address indexed account);

    /**
     * @param admin  Address receiving DEFAULT_ADMIN_ROLE.
     *               In production: a multisig (Gnosis Safe).
     *               In tests: the deployer.
     */

    constructor(address admin) ERC20("UbiQuin", "UBQ") {
        if (admin == address(0)) revert StableCoin__ZeroAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (to == address(0)) revert StableCoin__ZeroAddress();
        if (amount == 0) revert StableCoin__ZeroAmount();
        _mint(to, amount);
    }

    function burnFrom(address from , uint256 amount) public override onlyRole(BURNER_ROLE){
        if(from == address(0)) revert StableCoin__ZeroAddress();
        if(amount == 0) revert StableCoin__ZeroAmount();
        if(amount > balanceOf(from)) revert StableCoin__InsufficientBalance(balanceOf(from), amount);
        _burn(from, amount);    
    }

    function grantMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) revert StableCoin__ZeroAddress();
        _grantRole(MINTER_ROLE, account);
        emit MinterRoleGranted(account);
    }

    function grantBurnerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) revert StableCoin__ZeroAddress();
        grantRole(BURNER_ROLE, account);
        emit BurnerRoleGranted(account);
    }
}
