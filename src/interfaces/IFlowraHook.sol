// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FlowraTypes} from "../libraries/FlowraTypes.sol";

/**
 * @title IFlowraHook
 * @notice Interface for Uniswap v4 hook for automated DCA swaps
 * @dev Implements beforeSwap and afterSwap hooks for event-driven execution
 */
interface IFlowraHook {
    /**
     * @notice Check if a user's position is ready for swap
     * @param user User address
     * @return True if swap can be executed
     */
    function canExecuteSwap(address user) external view returns (bool);

    /**
     * @notice Get pending swap count
     * @return Number of users ready for swap
     */
    function getPendingSwapCount() external view returns (uint256);

    /**
     * @notice Get next user ready for swap
     * @return user User address (address(0) if none)
     */
    function getNextSwapUser() external view returns (address user);

    /**
     * @notice Set FlowraCore contract address
     * @param _core FlowraCore address
     */
    function setFlowraCore(address _core) external;

    /**
     * @notice Get hook permissions
     * @return Permissions flags
     */
    function getHookPermissions() external pure returns (uint256);
}
