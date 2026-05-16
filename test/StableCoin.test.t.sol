//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {StableCoin} from "../src/StableCoin.sol";

contract StableCoinTest is Test {
    StableCoin public stableCoin;
    /**
     * @dev Address of the minter and burner in tests.
      In production, these would be the treasury or a multisig (Gnosis Safe).
     */
    address public constant MINTER = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
    address public constant BURNER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    function setUp() public {
        stableCoin = new StableCoin(address(this));
    }
    function testMint() public {
        stableCoin.grantMinterRole(MINTER);
        vm.prank(MINTER);
        stableCoin.mint(address(this), 10);
        assertEq(stableCoin.balanceOf(address(this)), 10);
    }

    function testBurn() public {
        stableCoin.grantMinterRole(MINTER);
        stableCoin.grantBurnerRole(BURNER);
        vm.prank(MINTER);
        stableCoin.mint(address(this), 10);
        vm.prank(BURNER);
        stableCoin.burnFrom(address(this), 5);
        assertEq(stableCoin.balanceOf(address(this)), 5);
    }

    function testInsufficientBalanceBurn() public {
        stableCoin.grantMinterRole(MINTER);
        stableCoin.grantBurnerRole(BURNER);
        vm.prank(MINTER);
        stableCoin.mint(address(this), 10);
        vm.prank(BURNER);
        vm.expectRevert();
        stableCoin.burnFrom(address(this), 20);
    }

    function testNonMinterCannotMint() public {
        vm.expectRevert();
        stableCoin.mint(address(this), 10);
    }

    function testNonBurnerCannotBurn() public {
        stableCoin.grantMinterRole(MINTER);
        vm.prank(MINTER);
        stableCoin.mint(address(this), 10);
        vm.expectRevert();
        stableCoin.burnFrom(address(this), 5);
    }

    function testCannotMintToZeroAddress() public {
        stableCoin.grantMinterRole(MINTER);
        vm.prank(MINTER);
        vm.expectRevert(StableCoin.StableCoin__ZeroAddress.selector);
        stableCoin.mint(address(0), 10);
    }

    function testCannotMintZeroAmount() public {
        stableCoin.grantMinterRole(MINTER);
        vm.prank(MINTER);
        vm.expectRevert(StableCoin.StableCoin__ZeroAmount.selector);
        stableCoin.mint(address(this), 0);
    }

    function testCannotBurnZeroAmount() public {
        stableCoin.grantBurnerRole(BURNER);
        vm.prank(BURNER);
        vm.expectRevert(StableCoin.StableCoin__ZeroAmount.selector);
        stableCoin.burnFrom(address(this), 0);
    }

    function testBurnReducesTotalSupply() public {
        stableCoin.grantMinterRole(MINTER);
        stableCoin.grantBurnerRole(BURNER);
        vm.prank(MINTER);
        stableCoin.mint(address(this), 10);
        vm.prank(BURNER);
        stableCoin.burnFrom(address(this), 5);
        assertEq(stableCoin.totalSupply(), 5);
    }

    function testNonAdminCannotGrant() public {
        vm.prank(address(0));
        vm.expectRevert();
        stableCoin.grantMinterRole(MINTER);
    }

    function testMintIncreasesSupply() public {
        stableCoin.grantMinterRole(MINTER);
        vm.prank(MINTER);
        stableCoin.mint(address(this), 10);
        assertEq(stableCoin.totalSupply(), 10);
    }

    function testConstructorRejectsZeroAddress() public {
        vm.expectRevert(StableCoin.StableCoin__ZeroAddress.selector);
        new StableCoin(address(0));
    }

    function testCannotBurnFromZeroAddress() public {
        stableCoin.grantBurnerRole(BURNER);
        vm.prank(BURNER);
        vm.expectRevert(StableCoin.StableCoin__ZeroAddress.selector);

        stableCoin.burnFrom(address(0), 100);
    }

    function testCannotGrantMinterRoleToZeroAddress() public {
        vm.expectRevert(StableCoin.StableCoin__ZeroAddress.selector);

        stableCoin.grantMinterRole(address(0));
    }

    function testCannotGrantBurnerRoleToZeroAddress() public {
        vm.expectRevert(StableCoin.StableCoin__ZeroAddress.selector);

        stableCoin.grantBurnerRole(address(0));
    }
}
