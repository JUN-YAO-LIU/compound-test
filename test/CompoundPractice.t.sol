// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { EIP20Interface } from "compound-protocol/contracts/EIP20Interface.sol";
import { CErc20 } from "compound-protocol/contracts/CErc20.sol";
import "forge-std/Test.sol";
import "test/helper/CompoundInitSetUp.sol";
import {CToken} from "compound-protocol/contracts/CToken.sol";
import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import {Unitroller} from "compound-protocol/contracts/Unitroller.sol";

contract CompoundPracticeTest is Test,CompoundInitSetUp {
  EIP20Interface public JT = EIP20Interface(0x8C6BC971DF9513AFE356A645563002E18c908817);
  // CErc20 public cToken = CErc20(0x6479c1Cd803db22a57D2266b34Fd67Ac785d2143);
  address public user;

  function setUp() override public {

    super.setUp();
   
    user = makeAddr("User");  

    uint256 initialBalance = 10000 * 10 ** JT.decimals();
    deal(address(JT), user, initialBalance);

    
    vm.label(user, "User");
  }

  function test_mint_after_redeem() public {
    vm.startPrank(user); 
    // TODO: 1. Mint some cUSDC with USDC
    

    JT.approve(address(cToken),100 * 10 ** JT.decimals());
    cToken.mint(10);

    console.log(cToken.balanceOf(user));

    // TODO: 2. Modify block state to generate interest

    // TODO: 3. Redeem and check the redeemed amount
  }

  function test_borrow_after_repay() public {
    vm.startPrank(user); 
    // TODO: 1. Mint some cUSDC with USDC

    // TODO: 2. Modify block state to generate interest

    // TODO: 3. Redeem and check the redeemed amount
  }

  
}
