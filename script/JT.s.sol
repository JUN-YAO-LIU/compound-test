// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "../lib/forge-std/src/console.sol";
import {Comp} from "compound-protocol/contracts/Governance/Comp.sol";
import {Script,console2} from "forge-std/Script.sol";
import {CErc20Delegator} from "compound-protocol/contracts/CErc20Delegator.sol";
import {CErc20Immutable} from "compound-protocol/contracts/CErc20Immutable.sol";
import {CErc20} from "compound-protocol/contracts/CErc20.sol";
import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import {SimplePriceOracle} from "compound-protocol/contracts/SimplePriceOracle.sol";
import {InterestRateModel} from "compound-protocol/contracts/InterestRateModel.sol";
import {Unitroller} from "compound-protocol/contracts/Unitroller.sol";
import {CErc20Delegate} from "compound-protocol/contracts/CErc20Delegate.sol";
import {WhitePaperInterestRateModel} from "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import {CTokenStorage} from "compound-protocol/contracts/CTokenInterfaces.sol";
import "compound-protocol/contracts/CToken.sol";
import "../constracts/JimToken.sol";

contract JTScript is Script {

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        JimToken JT =  new JimToken();

        vm.stopBroadcast();
    }
}
