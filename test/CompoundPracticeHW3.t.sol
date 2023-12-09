// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { EIP20Interface } from "compound-protocol/contracts/EIP20Interface.sol";
import { CErc20 } from "compound-protocol/contracts/CErc20.sol";
import "forge-std/Test.sol";
import "test/helper/CompoundInitSetUp.sol";
import { CToken } from "compound-protocol/contracts/CToken.sol";
import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";
import { Unitroller } from "compound-protocol/contracts/Unitroller.sol";
import { CErc20Delegator } from "compound-protocol/contracts/CErc20Delegator.sol";
import { CErc20Delegate } from "compound-protocol/contracts/CErc20Delegate.sol";
import { Pool } from "../lib/aave-address-book/lib/aave-v3-core/contracts/protocol/pool/Pool.sol";
import { SimpleFlashLoan } from "../constracts/SimpleFlashLoan.sol";
import {InterestRateModel} from "compound-protocol/contracts/InterestRateModel.sol";
import {WhitePaperInterestRateModel} from "compound-protocol/contracts/WhitePaperInterestRateModel.sol";

contract CompoundPracticeTestHW3 is Test {
  EIP20Interface public JT = EIP20Interface(0xbd098C26334CA2E2690d14D59E8D4d623241D7F1);
  EIP20Interface public TokenA_USDC = EIP20Interface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  EIP20Interface public TokenB_UNI = EIP20Interface(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

  address public user1 = makeAddr("User1");
  address public user2 = makeAddr("User2");

  // CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
  // CErc20 public cUNI = CErc20(0x35A18000230DA775CAc24873d00Ff85BccdeD550);

  CErc20Delegator public cUSDC;
  CErc20Delegator public cUNI;

  // Unitroller public unitroller = Unitroller(payable(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B));
  Unitroller public unitroller;

  address public admin = 0x6d903f6003cca6255D85CcA4D3B5E5146dC33925;
  SimplePriceOracle oracle;

  Pool pool = Pool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

  struct FlashParam{
        address tokenIn;
        address tokenOut;
        uint repayAmount;
        address to;
        address liquidatedUser;
  }

  function setUp() public {
    uint256 forkId = vm.createFork(
            "https://eth-mainnet.g.alchemy.com/v2/k-sz4T_Vr7gOvMk-OHpUTzlAiU9VDs3q"
            ,17465000);
    vm.selectFork(forkId);
   
    vm.startPrank(admin);
    // Comptroller proxy
    unitroller = new Unitroller();

    // Comptroller
    Comptroller comptroller = new Comptroller();
    unitroller._setPendingImplementation(address(comptroller));
    comptroller._become(unitroller);

    WhitePaperInterestRateModel model = new WhitePaperInterestRateModel(0, 0);
    CErc20Delegate cERC20DelegateA = new CErc20Delegate();
    cUSDC = new CErc20Delegator(
          address(TokenA_USDC),
          Comptroller(address(unitroller)),
          InterestRateModel(model),
          1e6,
          "compound USDC",
          "cUSDC",
          18,
          payable(admin),
          address(cERC20DelegateA),
          new bytes(0));

    CErc20Delegate cERC20DelegateB = new CErc20Delegate();
    cUNI = new CErc20Delegator(
          address(TokenB_UNI),
          Comptroller(address(unitroller)),
          InterestRateModel(model),
          1e18,
          "compound UNI",
          "cUNI",
          18,
          payable(admin),
          address(cERC20DelegateB),
          new bytes(0));

    // error MintComptrollerRejection(9) MARKET_NOT_LISTED
    Comptroller(address(unitroller))._supportMarket(CErc20(address(cUSDC)));
    Comptroller(address(unitroller))._supportMarket(CErc20(address(cUNI)));

    Comptroller(address(unitroller))._setCloseFactor(5e17);
    Comptroller(address(unitroller))._setLiquidationIncentive(1.08 * 1e18);

    oracle = new SimplePriceOracle();
    Comptroller(address(unitroller))._setPriceOracle(oracle);

    // 36 - 6
    oracle.setUnderlyingPrice(CToken(address(cUSDC)),1 * 1e30);

    // 36 - 18
    oracle.setUnderlyingPrice(CToken(address(cUNI)),5 * 1e18);
    Comptroller(address(unitroller))._setCollateralFactor(CToken(address(cUNI)),5e17);

    // admin supply the liquidity
    deal(address(TokenA_USDC), admin, 1000 * 1e18);
    TokenA_USDC.approve(address(cUSDC), 1000 * 1e18);
    cUSDC.mint(1000 * 1e18);
    // address[] memory tokensAdmin = new address[](2);
    // tokensAdmin[0] = address(cUSDC);
    // tokensAdmin[1] = address(cUNI);
    // Comptroller(address(unitroller)).enterMarkets(tokensAdmin);
    vm.stopPrank();

    vm.label(address(pool), "FlashPool");
    vm.label(address(TokenB_UNI), "TokenB_UNI");
    vm.label(address(TokenA_USDC), "TokenA_USDC");
    vm.label(user1, "User1");
    vm.label(user2, "User2");
    vm.label(address(unitroller), "Comptroller");
  }

  function test_AAVE_Flashloan_Liquidate() public {
    vm.startPrank(user1);

    uint256 initialBalanceB = 1000 * 1e18;
    deal(address(TokenB_UNI), user1, initialBalanceB);

    console2.log("user1 UNI:",TokenB_UNI.balanceOf(user1));
    TokenB_UNI.approve(address(cUNI), 1000 * 1e18);
    cUNI.mint(1000 * 1e18);

    console2.log("user1 cUNI:",cUNI.balanceOf(user1));

    address[] memory tokens = new address[](2);
    tokens[0] = address(cUNI);
    Comptroller(address(unitroller)).enterMarkets(tokens);

    console2.log("user1 before USDC:",TokenA_USDC.balanceOf(user1));

    //  BorrowComptrollerRejection(4) INSUFFICIENT_LIQUIDITY 
    cUSDC.borrow(2500 * 1e6);
    console2.log("user1 USDC:",TokenA_USDC.balanceOf(user1));
    vm.stopPrank();

    vm.startPrank(admin);
    oracle.setUnderlyingPrice(CToken(address(cUNI)),4 * 1e18);
    vm.stopPrank();

    vm.startPrank(user2);
    // Comptroller(address(unitroller)).enterMarkets(tokens);
    uint closeFactorMantissa = Comptroller(address(unitroller)).closeFactorMantissa();
    uint borowBalance = cUSDC.borrowBalanceCurrent(user1);
    uint borowBalance2 = cUSDC.borrowBalanceStored(user1);
    uint repayAmount = borowBalance * closeFactorMantissa / 1e18;
    console2.log("closeFactorMantissa:",closeFactorMantissa);
    console2.log("borowBalance:",borowBalance);
    console2.log("borowBalance2:",borowBalance2);
    console2.log("repayAmount:",repayAmount);

    FlashParam memory arg = FlashParam(address(TokenB_UNI),address(TokenA_USDC),repayAmount,user2,user1);

    // uint256 initialBalanceA = 1000 * 10 ** TokenA_USDC.decimals();
    // deal(address(TokenA_USDC), user2, initialBalanceA);
    // cUSDC.mint(initialBalanceA);

    deal(address(TokenA_USDC), user2, 5000 * 10 ** TokenA_USDC.decimals());
    console2.log("TokenA_USDC User2 USDC:",TokenA_USDC.balanceOf(user2));
    console2.log("User2 cUNI:",cUNI.balanceOf(user2));

    console2.log("Oracle cUNI:",oracle.getUnderlyingPrice(CToken(address(cUNI))));
    console2.log("Oracle cUSDC:",oracle.getUnderlyingPrice(CToken(address(cUSDC))));

    
    TokenA_USDC.approve(address(cUSDC), 5000 * 10 ** TokenA_USDC.decimals());
    (uint err) = cUSDC.liquidateBorrow(user1, repayAmount, cUNI);
    console2.log("liquidateBorrow Error:",err);
    // console2.log("User2 cUNI after:",cUNI.balanceOf(user2));

    // 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e -> PoolAddressesProvider
    // SimpleFlashLoan flashLoan = new SimpleFlashLoan(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);
    // TokenB_UNI.transfer(address(flashLoan), 1e18);

    // console2.log("flashLoan UNI:",TokenB_UNI.balanceOf(address(flashLoan)));
    // flashLoan.fn_RequestFlashLoan(abi.encode(arg));

    // console2.log("user2 USDC:",TokenA_USDC.balanceOf(user2));

    //TokenA_USDC.approve(address(cUSDC), repayAmount);
    // (uint err) = cUSDC.liquidateBorrow(user1, repayAmount / 10 ** TokenA_USDC.decimals(), cUNI);
    // require(err ==0,"liquidate failed");
    
    // console2.log("<<user1 account liquidity After change collateral factor>>");
    // (,uint liquidityAfter,uint shortfallAfter) = Comptroller(address(unitroller)).getAccountLiquidity(user1);
    // console2.log("user1 liquidity:",liquidityAfter);
    // console2.log("user1 shortfall:",shortfallAfter);
  }
}
