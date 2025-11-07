// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FlowraTypes} from "../libraries/FlowraTypes.sol";

/**
 * @title IFlowraCore
 * @notice Interface for the main Flowra protocol coordinator
 * @dev Manages user deposits, positions, and DCA execution
 */
interface IFlowraCore {
    /**
     * @notice Deposit USDC to create a DCA position
     * @param amount Amount of USDC to deposit
     * @return positionId Unique position identifier
     */
    function deposit(uint256 amount) external returns (bytes32 positionId);

    /**
     * @notice Withdraw from position (WETH + remaining USDC)
     * @return usdcAmount USDC returned
     * @return wethAmount WETH returned
     */
    function withdraw() external returns (uint256 usdcAmount, uint256 wethAmount);

    /**
     * @notice Execute daily swap for a user (callable by anyone)
     * @param user User address to swap for
     * @return amountOut WETH received
     */
    function executeSwap(address user) external returns (uint256 amountOut);

    /**
     * @notice Claim accumulated WETH without closing position
     * @return wethAmount WETH claimed
     */
    function claimWETH() external returns (uint256 wethAmount);

    /**
     * @notice Get user position details
     * @param user User address
     * @return position User position struct
     */
    function getPosition(address user) external view returns (FlowraTypes.UserPosition memory position);

    /**
     * @notice Check if user can execute swap (24h passed)
     * @param user User address
     * @return True if swap can be executed
     */
    function canSwap(address user) external view returns (bool);

    /**
     * @notice Get protocol statistics
     * @return stats Protocol stats struct
     */
    function getProtocolStats() external view returns (FlowraTypes.ProtocolStats memory stats);

    /**
     * @notice Get estimated swap output
     * @param amountIn USDC input amount
     * @return amountOut Estimated WETH output
     */
    function getSwapQuote(uint256 amountIn) external view returns (uint256 amountOut);
}
