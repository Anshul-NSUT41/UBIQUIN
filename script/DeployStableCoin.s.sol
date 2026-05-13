//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {StableCoin} from "../src/StableCoin.sol";
import "forge-std/Script.sol";

contract StableCoinScript is Script {
    function run() external returns(StableCoin){
        address treasury = vm.envAddress("TREASURY");
        vm.startBroadcast();
        StableCoin stableCoin = new StableCoin(treasury);
        vm.stopBroadcast();
        return stableCoin ;
    }
}