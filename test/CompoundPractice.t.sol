// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { EIP20Interface } from "compound-protocol/contracts/EIP20Interface.sol";
import { CErc20 } from "compound-protocol/contracts/CErc20.sol";
import "forge-std/Test.sol";
import "test/helper/CompoundInitSetUp.sol";
import {CToken} from "compound-protocol/contracts/CToken.sol";
import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import {Unitroller} from "compound-protocol/contracts/Unitroller.sol";

contract CompoundPracticeTest is Test,CompoundInitSetUp {
  EIP20Interface public JT = EIP20Interface(0xbd098C26334CA2E2690d14D59E8D4d623241D7F1);
  EIP20Interface public TokenA = EIP20Interface(0x9AeDde9bcA594AAF5801892603193f8c8Bb84AC8);
  EIP20Interface public TokenB = EIP20Interface(0xA8524B8fCC146C35Fb6F9849eA062DA0B5a95aB8);
  // CErc20 public cToken = CErc20(0x6479c1Cd803db22a57D2266b34Fd67Ac785d2143);
  // 0x6479c1Cd803db22a57D2266b34Fd67Ac785d2143 => ecr20delegator

  address public user1;
  address public user2;

  function setUp() override public {

    super.setUp();
   
    user1 = makeAddr("User1");
    user2 = makeAddr("User2");

    uint256 initialBalanceA = 1000 * 10 ** TokenA.decimals();
    deal(address(TokenA), user2, initialBalanceA);

    uint256 initialBalance = 10000 * 10 ** JT.decimals();
    uint256 initialBalanceB = 1000 * 10 ** TokenB.decimals();
    deal(address(JT), user1, initialBalance);
    deal(address(TokenB), user1, initialBalanceB);

    
    vm.label(user2, "User2");
    vm.label(user1, "User1");
    vm.label(address(JT), "JT");
    vm.label(address(TokenA), "TokenA");
    vm.label(address(TokenB), "TokenB");
  }

  function test_mint_after_redeem() public {
    vm.startPrank(user1); 
    // TODO: 1. Mint some cUSDC with USDC
  
    console.log(JT.balanceOf((user1)));
    JT.approve(address(cToken),100 * 10 ** JT.decimals());
    cToken.mint(100 * 10 ** JT.decimals());
    
    // TODO: 2. Modify block state to generate interest
    // vm.roll(4812710 + 10000);

    // TODO: 3. Redeem and check the redeemed amount
    cToken.redeem(cToken.balanceOf((user1)));
    console.log(JT.balanceOf((user1)));
    vm.stopPrank(); 
  }

  function test_borrow_after_repay() public {
    vm.startPrank(user2);

    // UserA
    TokenA.approve(address(cTokenA),100 * 10 ** TokenA.decimals());
    cTokenA.mint(100 * 10 ** TokenA.decimals());

    address[] memory tokens = new address[](2);
    tokens[0] = address(cTokenA);
    tokens[1] = address(cTokenB);

    Comptroller(address(unitrollerAB)).enterMarkets(tokens);
    console.log(TokenA.balanceOf(user2));
    vm.stopPrank();

    vm.startPrank(user1);
    TokenB.approve(address(cTokenB),100 * 10 ** TokenB.decimals());
    cTokenB.mint(1 * 10 ** TokenB.decimals());

    Comptroller(address(unitrollerAB)).enterMarkets(tokens);
    cTokenA.borrow(50);
    vm.stopPrank();
  }

  function test_alter_collateral_factor_Liquidated() public {
    test_borrow_after_repay();

    // update the TokenB price.
    uint closeFactorMantissa = Comptroller(address(unitrollerAB)).closeFactorMantissa();
    // uint borrowBalance = cTokenA.repayBalanceCurrent(user1);
    Comptroller(address(unitrollerAB))._setCollateralFactor(CToken(address(cTokenB)),5 * 1e17);
  }

  function test_alter_oracle_BTokenPrice_Liquidated() public {
    test_borrow_after_repay();

    // update the TokenB price.
    oracle.setUnderlyingPrice(CToken(address(cTokenB)),100 * 1e18);
  }
}
