// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

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
import "../constracts/ERC20Token.sol";

contract CompoundHW2Script is Script {

    ERC20Token tokenA;
    ERC20Token tokenB;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimplePriceOracle oracle = new SimplePriceOracle();

        // Comptroller proxy
        Unitroller unitroller = new Unitroller();

        // Comptroller
        Comptroller comptroller = new Comptroller();
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        comptroller._setPriceOracle(oracle);
        
        comptroller._setCloseFactor(5e17);
        comptroller._setLiquidationIncentive(1.08 * 1e18);

        WhitePaperInterestRateModel whiteInterest = new WhitePaperInterestRateModel(0,0);

        ERC20Token TokenA =  new ERC20Token("TokenA","TA");
        tokenA = TokenA;

        ERC20Token TokenB =  new ERC20Token("TokenB","TB");
        tokenB = TokenB;

        CErc20Delegate cERC20DelegateA = new CErc20Delegate();
        CErc20Delegate cERC20DelegateB = new CErc20Delegate();
        
        CErc20Delegator cTokenA = new CErc20Delegator(
            address(tokenA), // underlying_ JB Token
            Comptroller(address(unitroller)),
            InterestRateModel(whiteInterest),
            1e18,
            "cTokenA",
            "TA",
            18, // decimals_
            payable(msg.sender), // admin
            address(cERC20DelegateA), // implementation
            new bytes(0));

        CErc20Delegator cTokenB = new CErc20Delegator(
            address(tokenB), // underlying_ JB Token
            Comptroller(address(unitroller)),
            InterestRateModel(whiteInterest),
            1e18,
            "cTokenB",
            "TB",
            18, // decimals_
            payable(msg.sender), // admin
            address(cERC20DelegateB), // implementation
            new bytes(0));

        // set the token price
        oracle.setUnderlyingPrice(CToken(address(cTokenA)),1 * 1e18);
        oracle.setUnderlyingPrice(CToken(address(cTokenB)),100 * 1e18);

        // support the cToken to market list.
        comptroller._supportMarket(CToken(address(cTokenA)));
        comptroller._supportMarket(CToken(address(cTokenB)));
        comptroller._setCollateralFactor(CToken(address(cTokenB)),5 * 1e17);

        vm.stopBroadcast();
    }
}
