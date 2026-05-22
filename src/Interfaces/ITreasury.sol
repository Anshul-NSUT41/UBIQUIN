// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ITreasury {

    error Treasury__ZeroAmount();
    error Treasury__ZeroAddress();
    error Treasury__InsufficientCollateral();
    error Treasury__HealthFactorTooLow(uint256 healthFactor);
    error Treasury__HealthFactorOk();
    error Treasury__TransferFailed();

    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralRedeemed(address indexed user, address indexed token, uint256 amount);
    event StableCoinMinted(address indexed user, uint256 amount);
    event StableCoinBurned(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 debtCovered);

    function depositCollateralAndMint(
        address collateralToken,
        uint256 collateralAmount,
        uint256 mintAmount
    ) external;

    function redeemCollateralAndBurn(
        address collateralToken,
        uint256 collateralAmount,
        uint256 burnAmount
    ) external;

    function liquidate(
        address collateralToken,
        address user,
        uint256 debtToCover
    ) external;

    function getHealthFactor(address user) external view returns (uint256);

    function getAccountInfo(address user)
        external
        view
        returns (uint256 totalCollateralValueUsd, uint256 totalDebtUsd);

    function getCollateralValueUsd(
        address token,
        uint256 amount
    ) external view returns (uint256);
}