// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { EIP20Interface } from "compound-protocol/contracts/EIP20Interface.sol";
import { CErc20 } from "compound-protocol/contracts/CErc20.sol";
import "forge-std/Test.sol";
import "test/helper/CompoundInitSetUp.sol";
import { CToken } from "compound-protocol/contracts/CToken.sol";
import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";
import { Unitroller } from "compound-protocol/contracts/Unitroller.sol";

contract CompoundPracticeTestHW3 is Test {
  EIP20Interface public JT = EIP20Interface(0xbd098C26334CA2E2690d14D59E8D4d623241D7F1);
  EIP20Interface public TokenA_USDC = EIP20Interface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  EIP20Interface public TokenB_UNI = EIP20Interface(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

  address public user1 = makeAddr("User1");
  address public user2 = makeAddr("User2");

  CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
  CErc20 public cUSNI = CErc20(0x35A18000230DA775CAc24873d00Ff85BccdeD550);

  Unitroller public unitroller = Unitroller(payable(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B));

  address public admin = 0x6d903f6003cca6255D85CcA4D3B5E5146dC33925;
  address public oracleAdmin = 0xCD8f976a4f5Ba1f577adf7666EA2C5389D3cCD53;
  SimplePriceOracle oracle;

  function setUp() public {
    uint256 forkId = vm.createFork(
            "https://eth-mainnet.g.alchemy.com/v2/k-sz4T_Vr7gOvMk-OHpUTzlAiU9VDs3q"
            ,17465000);
    vm.selectFork(forkId);
   
    vm.startPrank(admin);
    Comptroller(address(unitroller))._setCloseFactor(5e17);
    Comptroller(address(unitroller))._setLiquidationIncentive(1.08 * 1e18);

    oracle = new SimplePriceOracle();
    Comptroller(address(unitroller))._setPriceOracle(oracle);
    oracle.setUnderlyingPrice(CToken(address(cUSDC)),1 * 1e18);
    oracle.setUnderlyingPrice(CToken(address(cUSNI)),5 * 1e18);
    Comptroller(address(unitroller))._setCollateralFactor(CToken(address(cUSNI)),25 * 1e17);
    vm.stopPrank();
  }

  function test_AAVE_Flashloan_Liquidate() public {
    vm.startPrank(user1);

    uint256 initialBalanceB = 1000 * 10 ** TokenB_UNI.decimals();
    deal(address(TokenB_UNI), user1, initialBalanceB);

    console2.log("user1 UNI:",TokenB_UNI.balanceOf(user1));
    TokenB_UNI.approve(address(cUSNI), 1000 * 10 ** TokenB_UNI.decimals());
    cUSNI.mint(1000 * 1e18);

    console2.log("user1 cUNI:",cUSNI.balanceOf(user1));

    address[] memory tokens = new address[](2);
    tokens[0] = address(cUSDC);
    tokens[1] = address(cUSNI);

    Comptroller(address(unitroller)).enterMarkets(tokens);

    // 不能用1e18的寫法來運算
    cUSDC.borrow((2500 * 10 ** TokenA_USDC.decimals()));
    console2.log("user1 USDC:",TokenA_USDC.balanceOf(user1));

    vm.startPrank(admin);
    oracle.setUnderlyingPrice(CToken(address(cUSNI)),4 * 1e18);
    vm.stopPrank();
  }
}
