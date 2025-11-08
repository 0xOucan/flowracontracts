// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Currency type (Uniswap v4 compatible)
/// @dev Wraps an address to represent a currency (address(0) for native ETH)
type Currency is address;

/**
 * @title FlowraTypes
 * @notice Shared type definitions for the Flowra protocol
 * @dev Used across all Flowra contracts for consistency
 */
library FlowraTypes {
    /// @notice User position tracking for DCA strategy
    struct UserPosition {
        address owner;              // Position owner
        uint256 usdcDeposited;      // Total USDC deposited
        uint256 wethAccumulated;    // WETH received from swaps
        uint256 dailySwapAmount;    // Amount to swap daily (1% of deposit)
        uint256 lastSwapTimestamp;  // Last swap execution time
        uint256 totalSwapsExecuted; // Number of swaps completed
        uint256 yieldEarned;        // Yield earned from Aave
        bool active;                // Position status
        uint256 createdAt;          // Position creation timestamp
    }

    /// @notice Project configuration for yield distribution
    struct Project {
        address payable wallet;     // Project wallet address
        uint256 allocationBps;      // Allocation in basis points (10000 = 100%)
        uint256 totalReceived;      // Total yield received
        bool active;                // Project status
        string name;                // Project name
        string description;         // Project description
    }

    /// @notice Swap execution parameters
    struct SwapParams {
        address user;               // User address
        uint256 amountIn;           // USDC amount to swap
        uint256 minAmountOut;       // Minimum WETH to receive
        uint24 fee;                 // Pool fee tier
        uint256 deadline;           // Swap deadline
    }

    /// @notice Aave position tracking
    struct AavePosition {
        uint256 supplied;           // Total USDC supplied to Aave
        uint256 borrowed;           // Total borrowed (if any)
        uint256 lastUpdateTime;     // Last interaction timestamp
        uint256 accumulatedYield;   // Yield earned
    }

    /// @notice Protocol statistics
    struct ProtocolStats {
        uint256 totalValueLocked;    // Total USDC in protocol
        uint256 totalSwapsExecuted;  // Total swaps completed
        uint256 totalYieldGenerated; // Total yield from Aave
        uint256 totalYieldDonated;   // Total yield to projects
        uint256 activePositions;     // Number of active positions
        uint256 totalWethDistributed;// Total WETH given to users
    }

    /// @notice Events
    event PositionCreated(address indexed user, uint256 amount, uint256 timestamp);
    event SwapExecuted(address indexed user, uint256 usdcIn, uint256 wethOut, uint256 timestamp);
    event YieldHarvested(uint256 amount, uint256 timestamp);
    event YieldDistributed(address indexed project, uint256 amount, uint256 timestamp);
    event PositionClosed(address indexed user, uint256 usdcReturned, uint256 wethReturned, uint256 timestamp);
    event ProjectAdded(address indexed wallet, uint256 allocationBps, string name);
    event ProjectUpdated(address indexed wallet, uint256 newAllocationBps);
    event ProjectRemoved(address indexed wallet);

    /// @notice Errors
    error InvalidAmount();
    error InvalidAddress();
    error PositionNotActive();
    error InsufficientBalance();
    error SwapTooSoon();
    error SlippageExceeded();
    error InvalidAllocation();
    error ProjectNotActive();
    error Unauthorized();
    error DeadlineExpired();
}
