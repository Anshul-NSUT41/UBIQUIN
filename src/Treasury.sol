// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20}          from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20}       from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable}        from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControl}   from "@openzeppelin/contracts/access/AccessControl.sol";
import {AggregatorV3Interface} from
    "@chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {IStableCoin}    from "../interfaces/IStableCoin.sol";
import {ITreasury}      from "../interfaces/ITreasury.sol";
import {OracleLibrary}  from "../oracle/OracleLibrary.sol";


contract Treasury  is ITreasury, ReentrancyGuard, Pausable, AccessControl {
    using OracleLibrary for AggregatorV3Interface;
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
}