//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
contract StableCoin is ERC20, Ownable {
    address public s_treasury;

    error Not_Treasury();

    constructor(address treasury) ERC20("StableCoin", "STC") Ownable(msg.sender) {
        s_treasury = treasury;
    }

    
    function mint(address to, uint256 amount) external {
        if (msg.sender != s_treasury) {
            revert Not_Treasury();
        }
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
