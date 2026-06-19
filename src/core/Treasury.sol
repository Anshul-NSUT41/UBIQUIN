// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// --- Imports ---
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {
    AggregatorV3Interface
} from "@chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {IStableCoin} from "../interfaces/IStableCoin.sol";
import {ITreasury} from "../interfaces/ITreasury.sol";
import {OracleLibrary} from "../oracle/OracleLibrary.sol";

contract Treasury is ITreasury, ReentrancyGuard, Pausable, AccessControl {
    using OracleLibrary for AggregatorV3Interface;
    using SafeERC20 for IERC20;

    // -------------------------
    // Roles
    // -------------------------
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // -------------------------
    // Protocol Parameters
    // -------------------------
    uint256 private constant LIQUIDATION_THRESHOLD = 80;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant PRECISION = 1e18;

    // -------------------------
    // State Variables
    // -------------------------
    IStableCoin public immutable stableCoin;

    mapping(address token => address priceFeed) public priceFeeds;
    mapping(address user => mapping(address token => uint256 amount))
        public collateralDeposited;
    mapping(address user => uint256 debtAmount) public debtMinted;

    address[] public collateralTokens;

    // -------------------------
    // Constructor
    // -------------------------
    constructor(
        address _stableCoin,
        address[] memory _collateralTokens,
        address[] memory _priceFeeds,
        address admin
    ) {
        if (_stableCoin == address(0)) revert Treasury__ZeroAddress();
        if (admin == address(0)) revert Treasury__ZeroAddress();
        if (_collateralTokens.length != _priceFeeds.length) {
            revert Treasury__ZeroAmount();
        }

        stableCoin = IStableCoin(_stableCoin);

        for (uint256 i = 0; i < _collateralTokens.length; i++) {
            address token = _collateralTokens[i];
            address feed = _priceFeeds[i];

            if (token == address(0) || feed == address(0)) {
                revert Treasury__ZeroAddress();
            }

            priceFeeds[token] = feed;
            collateralTokens.push(token);
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    // -------------------------
    // Admin
    // -------------------------
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // =========================================================
    // EXTERNAL — Deposit & Redeem (user-facing functions)
    // =========================================================

    /**
     * @notice Deposit collateral only (no minting).
     */
    function depositCollateral(
        address collateralToken,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        _depositCollateral(msg.sender, collateralToken, amount);
    }

    /**
     * @notice Redeem collateral back to your wallet.
     * @dev    Health check runs AFTER redemption — if taking collateral
     *         out breaks your position, the whole tx reverts.
     */
    function redeemCollateral(
        address collateralToken,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        _redeemCollateral(msg.sender, msg.sender, collateralToken, amount);
        _revertIfHealthFactorBroken(msg.sender);
    }

    // =========================================================
    // INTERNAL — Core Logic
    // =========================================================

    function _depositCollateral(
        address user,
        address token,
        uint256 amount
    ) internal {
        // --- CHECKS ---
        if (amount == 0) revert Treasury__ZeroAmount();
        if (priceFeeds[token] == address(0))
            revert Treasury__InsufficientCollateral();

        // --- EFFECTS ---
        // Update our internal accounting FIRST, before any token transfer
        collateralDeposited[user][token] += amount;
        emit CollateralDeposited(user, token, amount);

        // --- INTERACTIONS ---
        // Only NOW do we touch the external ERC20 contract
        IERC20(token).safeTransferFrom(user, address(this), amount);
    }

    function _redeemCollateral(
        address from, // whose collateral balance to reduce
        address to, // who physically receives the tokens
        address token,
        uint256 amount
    ) internal {
        // --- CHECKS ---
        if (amount == 0) revert Treasury__ZeroAmount();

        // --- EFFECTS ---
        // Solidity 0.8 will automatically revert on underflow,
        // so if `from` doesn't have enough collateral this line reverts
        collateralDeposited[from][token] -= amount;
        emit CollateralRedeemed(from, token, amount);

        // --- INTERACTIONS ---
        IERC20(token).safeTransfer(to, amount);
    }

    // =========================================================
    // EXTERNAL — Deposit & Redeem (user-facing functions)
    // =========================================================

    /**
     * @notice Deposit collateral only (no minting).
     */
    function depositCollateral(
        address collateralToken,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        _depositCollateral(msg.sender, collateralToken, amount);
    }

    /**
     * @notice Redeem collateral back to your wallet.
     * @dev    Health check runs AFTER redemption — if taking collateral
     *         out breaks your position, the whole tx reverts.
     */
    function redeemCollateral(
        address collateralToken,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        _redeemCollateral(msg.sender, msg.sender, collateralToken, amount);
        _revertIfHealthFactorBroken(msg.sender); // we'll build this in Segment 4
    }

    // =========================================================
    // INTERNAL — Core Logic
    // =========================================================

    function _depositCollateral(
        address user,
        address token,
        uint256 amount
    ) internal {
        // --- CHECKS ---
        if (amount == 0) revert Treasury__ZeroAmount();
        if (priceFeeds[token] == address(0))
            revert Treasury__InsufficientCollateral();

        // --- EFFECTS ---
        // Update our internal accounting FIRST, before any token transfer
        collateralDeposited[user][token] += amount;
        emit CollateralDeposited(user, token, amount);

        // --- INTERACTIONS ---
        // Only NOW do we touch the external ERC20 contract
        IERC20(token).safeTransferFrom(user, address(this), amount);
    }

    function _redeemCollateral(
        address from, // whose collateral balance to reduce
        address to, // who physically receives the tokens
        address token,
        uint256 amount
    ) internal {
        // --- CHECKS ---
        if (amount == 0) revert Treasury__ZeroAmount();

        // --- EFFECTS ---
        // Solidity 0.8 will automatically revert on underflow,
        // so if `from` doesn't have enough collateral this line reverts
        collateralDeposited[from][token] -= amount;
        emit CollateralRedeemed(from, token, amount);

        // --- INTERACTIONS ---
        IERC20(token).safeTransfer(to, amount);
    }

    // =========================================================
    // EXTERNAL VIEW — Read collateral data
    // =========================================================

    function getCollateralValueUsd(
        address token,
        uint256 amount
    ) external view returns (uint256) {
        return AggregatorV3Interface(priceFeeds[token]).getUsdValue(amount);
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return collateralTokens;
    }
}
