// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script,console2} from "forge-std/Script.sol";
import {CErc20Delegator} from "compound-protocol/contracts/CErc20Delegator.sol";
import {CErc20} from "compound-protocol/contracts/CErc20.sol";
import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import {JumpRateModelV2} from "compound-protocol/contracts/JumpRateModelV2.sol";
import {ComptrollerInterface} from "compound-protocol/contracts/ComptrollerInterface.sol";
import {InterestRateModel} from "compound-protocol/contracts/InterestRateModel.sol";
import {Unitroller} from "compound-protocol/contracts/Unitroller.sol";
import {CErc20Delegate} from "compound-protocol/contracts/CErc20Delegate.sol";


contract CompoundScript is Script {

    address owner = 0x570D01A5Bd431BdC206038f3cff8E17B22AA3662;
    function setUp() public {}

    function run() public {
        vm.startBroadcast(0x8061cdc7f38513491444f675981f8e35d7cf78564bf9d6a4b5193b794aadc30c);

        CErc20 cERC20 =  new CErc20();

        // Comptroller實作
        Comptroller comptroller = new Comptroller();

        JumpRateModelV2 jumpRateModel = new JumpRateModelV2(
            1,
            1,
            1,
            1,
            owner
        );

        CErc20Delegate cERC20Delegate = new CErc20Delegate();

        CErc20Delegator cERC20Delegator = new CErc20Delegator(
            0xFB76C72C0B19b07739A52355B8500374514a17C5, // underlying_ JB Token
            comptroller,
            InterestRateModel(jumpRateModel),
            1,
            "compound JB Token.",
            "cJBT",
            18, // decimals_
            payable(owner), // admin
            address(cERC20Delegate), // implementation
            abi.encode(0x0000000000000000000000000000000000000000));

        vm.stopBroadcast();
    }
}
