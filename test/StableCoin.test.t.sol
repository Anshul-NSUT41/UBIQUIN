//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {StableCoin} from "../src/StableCoin.sol";

contract StableCoinTest is Test{
    StableCoin public stableCoin ;
    address public owner = address(0x1);
    address public treasury = address(0x2);

    function setUp() public {
        stableCoin = new StableCoin();
    }

    function testSetTreasury() public {
        stableCoin.setTreasury(treasury);
        assertEq(stableCoin.s_treasury(), treasury);
    }

    function testMint() public {
        stableCoin.setTreasury(treasury);
        vm.expectRevert() ;
        stableCoin.mint(address(this), 100);
    }

    function testBurn() public {
        stableCoin.setTreasury(treasury);
        vm.prank(treasury);
        stableCoin.mint(address(this), 100);
        stableCoin.burn(50);
        assertEq(stableCoin.balanceOf(address(this)), 50);
    }
}