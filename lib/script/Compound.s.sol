// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script,console2} from "forge-std/Script.sol";
import {CErc20Delegator} from "compound-protocol/contracts/CErc20Delegator.sol";

contract CompoundScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast(0x8061cdc7f38513491444f675981f8e35d7cf78564bf9d6a4b5193b794aadc30c);

        CErc20Delegator s = new CErc20Delegator(
            0xf3577Dc71c127c08E3F4fDA3C9eF0994cB4B35B8,
            0xFB76C72C0B19b07739A52355B8500374514a17C5);

        vm.stopBroadcast();
    }
}
