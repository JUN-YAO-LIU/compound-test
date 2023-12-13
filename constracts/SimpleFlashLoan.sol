// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../lib/aave-address-book/lib/aave-v3-core/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "../lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import "../lib/aave-address-book/lib/aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "./Uni/ISwapRouter.sol";
import { CErc20 } from "../lib/compound-protocol/contracts/CErc20.sol";
import { EIP20Interface } from "../lib/compound-protocol/contracts/EIP20Interface.sol";
import { CErc20Delegator } from "../lib/compound-protocol/contracts/CErc20Delegator.sol";

contract SimpleFlashLoan is FlashLoanSimpleReceiverBase {
    address payable owner;
    // CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    // CErc20 public cUNI = CErc20(0x35A18000230DA775CAc24873d00Ff85BccdeD550);

    EIP20Interface public TokenA_USDC = EIP20Interface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    EIP20Interface public TokenB_UNI = EIP20Interface(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    struct FlashParam{
        CErc20Delegator cUNI;
        CErc20Delegator cUSDC;
        uint repayAmount;
        address to;
        address liquidatedUser;
  }

    constructor(address _addressProvider)
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
        owner = payable(msg.sender);
    }

    function fn_RequestFlashLoan(bytes memory param) public {
        FlashParam memory flashParam = abi.decode(param,(FlashParam));

        address receiverAddress = address(this);
        address asset = address(TokenA_USDC);
        uint256 amount = flashParam.repayAmount;
        bytes memory params = param;
        uint16 referralCode = 0;

        // 0xD0fC8bA7E267f2bc56044A7715A489d851dC6D78 -> uniV3 pool
        TokenB_UNI.approve(0xD0fC8bA7E267f2bc56044A7715A489d851dC6D78, 1e18);

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }
    
    //This function is called after your contract has received the flash loaned amount

    function  executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    )  external override returns (bool) {
        
        //Logic goes here
        FlashParam memory flashParam = abi.decode(params,(FlashParam));

        // already borrowed Usdc
        EIP20Interface(asset).approve(address(flashParam.cUSDC), type(uint256).max);
        (uint err) = flashParam.cUSDC.liquidateBorrow(flashParam.liquidatedUser, amount , flashParam.cUNI);
        require(err ==0,"liquidate failed");

        flashParam.cUNI.redeem(flashParam.cUNI.balanceOf(address(this)));
        TokenB_UNI.approve(0xE592427A0AEce92De3Edee1F18E0157C05861564, type(uint256).max);

        // borrow what token, just takenOut what token.
        ISwapRouter.ExactInputSingleParams memory swapParams =
            ISwapRouter.ExactInputSingleParams({
            tokenIn: address(TokenB_UNI),
            tokenOut: address(TokenA_USDC),
            fee: 3000, // 0.3%
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: TokenB_UNI.balanceOf(address(this)),// uniAmount
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // swap Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564
        // swap out the USDC
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564).exactInputSingle(swapParams);

        uint256 totalAmount = amount + premium;
        IERC20(asset).approve(address(POOL), totalAmount);
        IERC20(asset).transfer(flashParam.to, IERC20(asset).balanceOf(address(this)) - totalAmount);

        return true;
    }
    receive() external payable {}
}