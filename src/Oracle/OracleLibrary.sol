// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from
    "@chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLibrary
 * @notice Wraps Chainlink price feeds with staleness, validity,
 *         and decimal normalization checks.
 * @dev    Used as a library — no state, no deployment cost beyond
 *         the contracts that use it (inlined by compiler).
 */
library OracleLibrary {

    // -------------------------
    // Constants
    // -------------------------

    /// @notice Maximum age of a price update before considered stale.
    ///         Chainlink ETH/USD updates every ~1hr on mainnet.
    ///         3600s = 1 hour. Adjust per feed's heartbeat.
    uint256 public constant STALENESS_THRESHOLD = 3600;

    /// @notice Chainlink feeds return 8 decimals.
    ///         We normalize to 18 decimals for internal accounting.
    uint256 public constant FEED_DECIMALS = 8;
    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public constant FEED_PRECISION   = 1e8;

    // -------------------------
    // Errors
    // -------------------------

    error OracleLibrary__StalePrice(uint256 updatedAt, uint256 threshold);
    error OracleLibrary__InvalidPrice(int256 price);
    error OracleLibrary__RoundIncomplete(uint80 roundId, uint80 answeredInRound);

    // -------------------------
    // Core Function
    // -------------------------

    /**
     * @notice Returns the USD price of 1 unit of `token` normalized to 18 decimals.
     * @dev    Three safety checks:
     *           1. Round completeness  — detects mid-update snapshots
     *           2. Staleness           — detects dead/paused feeds
     *           3. Price validity      — detects zero / negative prices
     * @param  priceFeed  Chainlink AggregatorV3Interface for the token
     * @return price18    Price in USD, scaled to 18 decimals
     */
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256 price18) {

        (
            uint80 roundId,
            int256 answer,
            ,           
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        if (answeredInRound < roundId) {
            revert OracleLibrary__RoundIncomplete(roundId, answeredInRound);
        }
        if (block.timestamp - updatedAt > STALENESS_THRESHOLD) {
            revert OracleLibrary__StalePrice(updatedAt, STALENESS_THRESHOLD);
        }
        if (answer <= 0) {
            revert OracleLibrary__InvalidPrice(answer);
        }
        price18 = (uint256(answer) * PRICE_PRECISION) / FEED_PRECISION;
    }

    /**
     * @notice Converts a token amount to its USD value (18 decimals).
     * @param  priceFeed     Chainlink feed for the token
     * @param  tokenAmount   Amount in token's native decimals (assumed 18)
     * @return usdValue18    USD value scaled to 18 decimals
     */
    function getUsdValue(
        AggregatorV3Interface priceFeed,
        uint256 tokenAmount
    ) internal view returns (uint256 usdValue18) {
        uint256 price18 = getPrice(priceFeed);

        usdValue18 = (price18 * tokenAmount) / PRICE_PRECISION;
    }

    /**
     * @notice Converts a USD value to token amount (inverse of getUsdValue).
     * @dev    Used during redemption: "how much ETH is $500 worth?"
     * @param  priceFeed   Chainlink feed for the token
     * @param  usdAmount   USD value scaled to 18 decimals
     * @return tokenAmount Equivalent token amount (18 decimals)
     */
    function getTokenAmountFromUsd(
        AggregatorV3Interface priceFeed,
        uint256 usdAmount
    ) internal view returns (uint256 tokenAmount) {
        uint256 price18 = getPrice(priceFeed);

        tokenAmount = (usdAmount * PRICE_PRECISION) / price18;
    }
}