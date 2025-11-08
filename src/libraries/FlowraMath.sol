// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title FlowraMath
 * @notice Math utilities for Flowra protocol calculations
 * @dev Provides safe mathematical operations and DCA-specific calculations
 */
library FlowraMath {
    /// @notice Basis points denominator (100%)
    uint256 public constant BPS_DENOMINATOR = 10000;

    /// @notice Daily swap percentage (1%)
    uint256 public constant DAILY_SWAP_BPS = 100; // 1% in basis points

    /// @notice Swap interval in seconds (5 minutes for testing, configurable in FlowraCore)
    /// @dev This is now just a default - actual interval is set in FlowraCore
    uint256 public constant DEFAULT_SWAP_INTERVAL = 300; // 5 minutes for testing (use 86400 for production/daily)

    /// @notice Minimum deposit amount (1 USDC with 6 decimals for testing)
    uint256 public constant MIN_DEPOSIT = 1 * 10**6; // Changed from 100 for testing

    /// @notice Maximum slippage (1%)
    uint256 public constant MAX_SLIPPAGE_BPS = 100;

    /**
     * @notice Calculate daily swap amount (1% of deposit)
     * @param totalDeposit Total USDC deposited
     * @return Daily swap amount
     */
    function calculateDailySwapAmount(uint256 totalDeposit) internal pure returns (uint256) {
        return (totalDeposit * DAILY_SWAP_BPS) / BPS_DENOMINATOR;
    }

    /**
     * @notice Calculate minimum output with slippage protection
     * @param expectedOutput Expected swap output
     * @param slippageBps Slippage tolerance in basis points
     * @return Minimum acceptable output
     */
    function calculateMinOutput(uint256 expectedOutput, uint256 slippageBps) internal pure returns (uint256) {
        require(slippageBps <= MAX_SLIPPAGE_BPS, "Slippage too high");
        return (expectedOutput * (BPS_DENOMINATOR - slippageBps)) / BPS_DENOMINATOR;
    }

    /**
     * @notice Check if enough time has passed for next swap (uses DEFAULT_SWAP_INTERVAL)
     * @param lastSwapTime Timestamp of last swap
     * @return True if swap interval has passed
     * @dev This function uses the hardcoded DEFAULT_SWAP_INTERVAL for compatibility
     */
    function canExecuteSwap(uint256 lastSwapTime) internal view returns (bool) {
        return block.timestamp >= lastSwapTime + DEFAULT_SWAP_INTERVAL;
    }

    /**
     * @notice Check if enough time has passed for next swap (with custom interval)
     * @param lastSwapTime Timestamp of last swap
     * @param swapInterval Swap interval in seconds
     * @return True if swap interval has passed
     */
    function canExecuteSwapWithInterval(uint256 lastSwapTime, uint256 swapInterval) internal view returns (bool) {
        return block.timestamp >= lastSwapTime + swapInterval;
    }

    /**
     * @notice Calculate time until next swap (uses DEFAULT_SWAP_INTERVAL)
     * @param lastSwapTime Timestamp of last swap
     * @return Seconds until next swap (0 if ready)
     */
    function timeUntilNextSwap(uint256 lastSwapTime) internal view returns (uint256) {
        uint256 nextSwapTime = lastSwapTime + DEFAULT_SWAP_INTERVAL;
        if (block.timestamp >= nextSwapTime) {
            return 0;
        }
        return nextSwapTime - block.timestamp;
    }

    /**
     * @notice Calculate time until next swap (with custom interval)
     * @param lastSwapTime Timestamp of last swap
     * @param swapInterval Swap interval in seconds
     * @return Seconds until next swap (0 if ready)
     */
    function timeUntilNextSwapWithInterval(uint256 lastSwapTime, uint256 swapInterval) internal view returns (uint256) {
        uint256 nextSwapTime = lastSwapTime + swapInterval;
        if (block.timestamp >= nextSwapTime) {
            return 0;
        }
        return nextSwapTime - block.timestamp;
    }

    /**
     * @notice Calculate allocation amount from basis points
     * @param total Total amount to distribute
     * @param allocationBps Allocation in basis points
     * @return Allocated amount
     */
    function calculateAllocation(uint256 total, uint256 allocationBps) internal pure returns (uint256) {
        require(allocationBps <= BPS_DENOMINATOR, "Invalid allocation");
        return (total * allocationBps) / BPS_DENOMINATOR;
    }

    /**
     * @notice Calculate estimated days to complete DCA
     * @param totalDeposit Total deposit amount
     * @param dailySwapAmount Amount swapped daily
     * @return Estimated days to completion
     */
    function estimateDaysToComplete(
        uint256 totalDeposit,
        uint256 dailySwapAmount
    ) internal pure returns (uint256) {
        if (dailySwapAmount == 0) return 0;
        return (totalDeposit + dailySwapAmount - 1) / dailySwapAmount; // Ceiling division
    }

    /**
     * @notice Calculate progress percentage
     * @param swapsExecuted Number of swaps completed
     * @param totalSwapsNeeded Total swaps needed
     * @return Progress in basis points (0-10000)
     */
    function calculateProgress(
        uint256 swapsExecuted,
        uint256 totalSwapsNeeded
    ) internal pure returns (uint256) {
        if (totalSwapsNeeded == 0) return 0;
        return (swapsExecuted * BPS_DENOMINATOR) / totalSwapsNeeded;
    }

    /**
     * @notice Validate allocation percentages sum to 100%
     * @param allocations Array of allocation basis points
     * @return True if valid
     */
    function validateAllocations(uint256[] memory allocations) internal pure returns (bool) {
        uint256 total = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            total += allocations[i];
        }
        return total == BPS_DENOMINATOR;
    }

    /**
     * @notice Calculate APY from yield earned
     * @param principal Initial principal amount
     * @param yield_ Total yield earned
     * @param durationDays Duration in days
     * @return APY in basis points
     */
    function calculateAPY(
        uint256 principal,
        uint256 yield_,
        uint256 durationDays
    ) internal pure returns (uint256) {
        if (principal == 0 || durationDays == 0) return 0;

        // APY = (yield / principal) * (365 / days) * 10000
        return (yield_ * 365 * BPS_DENOMINATOR) / (principal * durationDays);
    }

    /**
     * @notice Safe multiplication with overflow check
     * @param a First number
     * @param b Second number
     * @return Product
     */
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    /**
     * @notice Safe division with zero check
     * @param a Numerator
     * @param b Denominator
     * @return Quotient
     */
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        return a / b;
    }
}
