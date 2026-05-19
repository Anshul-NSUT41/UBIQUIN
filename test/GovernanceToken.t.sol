//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {GovernanceToken} from "../src/Tokens/GovernanceToken.sol";

contract TestGovernanceToken is Test {
    GovernanceToken public governanceToken;

    address initialHolder = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
    uint256 initialSupply = 10;
    address Minter = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function setUp() public {
        governanceToken = new GovernanceToken(
            address(this),
            initialHolder,
            initialSupply
        );
    }
    function testMint() public {
        governanceToken.grantMinterRole(Minter);
        vm.prank(Minter);
      
        governanceToken.mint(address(this), 5);
        assertEq(governanceToken.balanceOf(address(this)), 5);
    }
    function testMintExceedsMaxSupply() public {
        governanceToken.grantMinterRole(Minter);
        vm.prank(Minter);
        uint256 max = governanceToken.MAX_SUPPLY();
        vm.expectRevert();
        governanceToken.mint(address(this), max + 9);
    }
    function testMintZeroAmount() public {
        governanceToken.grantMinterRole(Minter);
        vm.prank(Minter);
        vm.expectRevert();
        governanceToken.mint(address(this), 0);
    }
    function testMintZeroAddress() public {
        governanceToken.grantMinterRole(Minter);
        vm.prank(Minter);
        vm.expectRevert();
        governanceToken.mint(address(0), 5);
    }
    function testMintWithoutMinterRole() public {
        vm.expectRevert();
        governanceToken.mint(address(this), 5);
    }
    function testInitialSupply() public {
        assertEq(governanceToken.balanceOf(initialHolder), initialSupply);
    }
    function testGrantMinterRole() public {
        governanceToken.grantMinterRole(Minter);
        assertTrue(governanceToken.hasRole(governanceToken.MINTER_ROLE(), Minter));
    }
    function testAdminAddressisZero() public {
        vm.expectRevert();
        new GovernanceToken(address(0), initialHolder, initialSupply);
    }
    function testInitialHolderAddressisZero() public {
        vm.expectRevert();
        new GovernanceToken(address(this), address(0), initialSupply);
    }
    function testInitialSupplyisZero() public {
        vm.expectRevert();
        new GovernanceToken(address(this), initialHolder, 0);
    }
    function testInitialSupplyExceedsMaxSupply() public {
        uint256 max = governanceToken.MAX_SUPPLY();
        vm.expectRevert();
        new GovernanceToken(address(this), initialHolder, max + 1);
    }
    function testNonAdminCannotGrantRole() public {
    vm.prank(Minter);
    vm.expectRevert();
    governanceToken.grantMinterRole(address(123));
}
}
