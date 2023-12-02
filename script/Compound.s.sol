// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

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

contract CompoundScript is Script {

    address underlying = 0xFB76C72C0B19b07739A52355B8500374514a17C5;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 治理的代幣
        // Comp comp = new Comp(owner);

        SimplePriceOracle oracle = new SimplePriceOracle();

        // Comptroller proxy
        Unitroller unitroller = new Unitroller();

        // Comptroller實作
        Comptroller comptroller = new Comptroller();
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        comptroller._setPriceOracle(oracle);

        WhitePaperInterestRateModel whiteInterest = new WhitePaperInterestRateModel(0,0);

        // CErc20 cERC20 =  new CErc20();
        CErc20Immutable cERC20 = new CErc20Immutable(
            underlying,
            Comptroller(address(unitroller)),
            InterestRateModel(whiteInterest),
            1 * 10 ** 18,
            "compound JB Token.",
            "cJBT",
            18,
            payable(msg.sender));

        console.log(cERC20.admin());

        CErc20Delegate cERC20Delegate = new CErc20Delegate();
        // cERC20Delegate._becomeImplementation(abi.encode(cERC20));
        // console.log(cERC20Delegate.admin());
        
        CErc20Delegator cERC20Delegator = new CErc20Delegator(
            underlying, // underlying_ JB Token
            Comptroller(address(unitroller)),
            InterestRateModel(whiteInterest),
            1e18,
            "compound JB Token.",
            "cJBT",
            18, // decimals_
            payable(msg.sender), // admin
            address(cERC20Delegate), // implementation
            new bytes(0));

        vm.stopBroadcast();
    }
}
