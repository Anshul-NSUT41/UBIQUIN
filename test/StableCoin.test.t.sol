//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {StableCoin} from "../src/StableCoin.sol";

contract StableCoinTest is Test {
    StableCoin public stableCoin;
    address public treasury = address(0x3);
    function setUp() public {
        stableCoin = new StableCoin(treasury);
    }
    function testTreasurySetCorrectly() public {
        assertEq(stableCoin.s_treasury(), treasury);
    }
    function testMint() public {
        vm.expectRevert();
        stableCoin.mint(address(this), 100);
    }
    function testBurn() public {
        vm.prank(treasury);
        stableCoin.mint(address(this), 100);
        stableCoin.burn(50);
        assertEq(
            stableCoin.balanceOf(address(this)),
            50
        );
    }
}