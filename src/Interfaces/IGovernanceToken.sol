// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IGovernanceToken {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function remainingMintableSupply() external view returns (uint256);
}