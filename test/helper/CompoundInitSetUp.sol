pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import {Unitroller} from "compound-protocol/contracts/Unitroller.sol";
import {CToken} from "compound-protocol/contracts/CToken.sol";
import { CErc20 } from "compound-protocol/contracts/CErc20.sol";


contract CompoundInitSetUp is Test {
  CErc20 public cToken = CErc20(0x6479c1Cd803db22a57D2266b34Fd67Ac785d2143); // --> delegator
  // CErc20 public cToken = CErc20(0xf526c24A59056b270B762222A896c2569D78E4Ba); // --> delegat
  Unitroller public unitroller = Unitroller(payable(0x8aa8E65882d80E07412844e5825edFC6aE128ebb));
  Comptroller public comptroller;
  address public admin = 0x570D01A5Bd431BdC206038f3cff8E17B22AA3662;

  function setUp() public virtual {
     uint256 forkId = vm.createFork(
            "https://eth-sepolia.g.alchemy.com/v2/DbEb9i79GXBoPu12o66beAkCtixxnaOg"
            ,4812710);
    vm.selectFork(forkId);

    // Q2
    comptroller = Comptroller(address(unitroller));

    vm.startPrank(admin);
    comptroller._supportMarket(cToken);
    vm.stopPrank();

    // Q3~5

    vm.label(address(cToken), "cJT");
    vm.label(address(comptroller), "Comptroller");
  }
}
