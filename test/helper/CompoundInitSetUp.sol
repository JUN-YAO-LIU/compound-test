pragma solidity 0.8.19;

import "forge-std/Test.sol";
import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";
import { Unitroller } from "compound-protocol/contracts/Unitroller.sol";
import { CToken } from "compound-protocol/contracts/CToken.sol";
import { CErc20 } from "compound-protocol/contracts/CErc20.sol";
import { SimplePriceOracle } from "compound-protocol/contracts/SimplePriceOracle.sol";


contract CompoundInitSetUp is Test {
  CErc20 public cToken = CErc20(0x6479c1Cd803db22a57D2266b34Fd67Ac785d2143); // --> delegator
  Unitroller public unitroller = Unitroller(payable(0x8aa8E65882d80E07412844e5825edFC6aE128ebb));
  Unitroller public unitrollerAB = Unitroller(payable(0x11c4990e26eF3874457D77A7d7a12f5AacF57123));
  address public admin = 0x570D01A5Bd431BdC206038f3cff8E17B22AA3662;

  CErc20 public cTokenA = CErc20(0xAC341D0Ee2d3c0fD59120E18a74Bf3f37144004D);
  CErc20 public cTokenB = CErc20(0xF47Ab7125921E9Ea0921A9C5447811bCBA8aAA92);

  SimplePriceOracle oracle = SimplePriceOracle(0x66633b870b70F33087Be9Df070416Ccc0A798A37);

  function setUp() public virtual {
     uint256 forkId = vm.createFork(
            "https://eth-sepolia.g.alchemy.com/v2/DbEb9i79GXBoPu12o66beAkCtixxnaOg"
            ,4827028);
    vm.selectFork(forkId);

    // Q2
    vm.startPrank(admin);
    Comptroller(address(unitroller))._supportMarket(cToken);
    Comptroller(address(unitrollerAB))._supportMarket(cTokenB);
    Comptroller(address(unitrollerAB))._supportMarket(cTokenA);
    Comptroller(address(unitrollerAB))._setPriceOracle(oracle);
    Comptroller(address(unitrollerAB))._setCloseFactor(5e17);
    Comptroller(address(unitrollerAB))._setLiquidationIncentive(1.08 * 1e18);
    Comptroller(address(unitrollerAB))._setCollateralFactor(CToken(address(cTokenB)),5 * 1e17);

    oracle.setUnderlyingPrice(CToken(address(cTokenA)),1 * 1e18);
    oracle.setUnderlyingPrice(CToken(address(cTokenB)),100 * 1e18);
    
    // Q3~5
    vm.stopPrank();
    vm.label(address(cTokenA), "cTokenA");
    vm.label(address(cTokenB), "cTokenB");
    vm.label(address(cToken), "cJT");
    vm.label(address(unitroller), "unitroller");
    vm.label(address(unitrollerAB), "unitrollerAB");
  }
}
