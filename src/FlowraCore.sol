// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import {IFlowraCore} from "./interfaces/IFlowraCore.sol";
import {IFlowraAaveVault} from "./interfaces/IFlowraAaveVault.sol";
import {IFlowraYieldRouter} from "./interfaces/IFlowraYieldRouter.sol";
import {FlowraTypes} from "./libraries/FlowraTypes.sol";
import {FlowraMath} from "./libraries/FlowraMath.sol";

/**
 * @title FlowraCore
 * @notice Main coordinator for Flowra DCA protocol on Arbitrum
 * @dev Manages user deposits, coordinates swaps via Uniswap v4, and distributes yield
 *
 * Core Responsibilities:
 * - Accept USDC deposits from users
 * - Create and track DCA positions (1% daily swaps)
 * - Coordinate with FlowraAaveVault for yield generation
 * - Execute daily USDC → WETH swaps
 * - Distribute WETH to users
 * - Route yield to public goods projects via FlowraYieldRouter
 */
contract FlowraCore is IFlowraCore, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    /// @notice USDC token on Arbitrum
    IERC20 public immutable USDC;

    /// @notice WETH token on Arbitrum
    IERC20 public immutable WETH;

    /// @notice Aave vault for yield generation
    IFlowraAaveVault public aaveVault;

    /// @notice Yield router for project distribution
    IFlowraYieldRouter public yieldRouter;

    /// @notice User positions mapping
    mapping(address => FlowraTypes.UserPosition) public positions;

    /// @notice Protocol-wide statistics
    FlowraTypes.ProtocolStats public protocolStats;

    /// @notice Total value locked in protocol
    uint256 public totalValueLocked;

    /// @notice Active users count
    uint256 public activeUsersCount;

    /// @notice Hook contract address (for authorized swaps)
    address public hookContract;

    // ============ Events ============

    event PositionCreated(
        address indexed user,
        uint256 usdcAmount,
        uint256 dailySwapAmount,
        uint256 timestamp
    );

    event SwapExecuted(
        address indexed user,
        uint256 usdcIn,
        uint256 wethOut,
        uint256 timestamp
    );

    event PositionClosed(
        address indexed user,
        uint256 usdcReturned,
        uint256 wethReturned,
        uint256 timestamp
    );

    event WETHClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event YieldHarvested(
        uint256 yieldAmount,
        uint256 timestamp
    );

    event VaultUpdated(address indexed oldVault, address indexed newVault);
    event YieldRouterUpdated(address indexed oldRouter, address indexed newRouter);
    event HookUpdated(address indexed oldHook, address indexed newHook);

    // ============ Errors ============

    error InsufficientDeposit(uint256 provided, uint256 minimum);
    error NoActivePosition();
    error PositionAlreadyExists();
    error SwapTooSoon(uint256 timeRemaining);
    error NoWETHToClaim();
    error ZeroAddress();
    error Unauthorized();
    error SwapFailed();
    error InsufficientBalance();

    // ============ Constructor ============

    /**
     * @notice Initialize FlowraCore with Arbitrum token addresses
     * @param _usdc USDC token address (0xaf88d065e77c8cC2239327C5EDb3A432268e5831)
     * @param _weth WETH token address (0x82aF49447D8a07e3bd95BD0d56f35241523fBab1)
     */
    constructor(
        address _usdc,
        address _weth
    ) Ownable(msg.sender) {
        if (_usdc == address(0) || _weth == address(0)) revert ZeroAddress();

        USDC = IERC20(_usdc);
        WETH = IERC20(_weth);
    }

    // ============ Admin Functions ============

    /**
     * @notice Set Aave vault contract
     * @param _vault Aave vault address
     */
    function setAaveVault(address _vault) external onlyOwner {
        if (_vault == address(0)) revert ZeroAddress();
        emit VaultUpdated(address(aaveVault), _vault);
        aaveVault = IFlowraAaveVault(_vault);
    }

    /**
     * @notice Set yield router contract
     * @param _router Yield router address
     */
    function setYieldRouter(address _router) external onlyOwner {
        if (_router == address(0)) revert ZeroAddress();
        emit YieldRouterUpdated(address(yieldRouter), _router);
        yieldRouter = IFlowraYieldRouter(_router);
    }

    /**
     * @notice Set hook contract address
     * @param _hook Hook contract address
     */
    function setHook(address _hook) external onlyOwner {
        if (_hook == address(0)) revert ZeroAddress();
        emit HookUpdated(hookContract, _hook);
        hookContract = _hook;
    }

    /**
     * @notice Pause protocol operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause protocol operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ User Functions ============

    /**
     * @notice Deposit USDC to create a DCA position
     * @param amount Amount of USDC to deposit (must be >= 100 USDC)
     * @return positionId Unique position identifier
     */
    function deposit(uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
        returns (bytes32 positionId)
    {
        // Validate deposit amount
        if (amount < FlowraMath.MIN_DEPOSIT) {
            revert InsufficientDeposit(amount, FlowraMath.MIN_DEPOSIT);
        }

        // Check if user already has an active position
        if (positions[msg.sender].active) {
            revert PositionAlreadyExists();
        }

        // Transfer USDC from user
        USDC.safeTransferFrom(msg.sender, address(this), amount);

        // Calculate daily swap amount (1% of deposit)
        uint256 dailySwapAmount = FlowraMath.calculateDailySwapAmount(amount);

        // Create user position
        positions[msg.sender] = FlowraTypes.UserPosition({
            owner: msg.sender,
            usdcDeposited: amount,
            wethAccumulated: 0,
            dailySwapAmount: dailySwapAmount,
            lastSwapTimestamp: block.timestamp,
            totalSwapsExecuted: 0,
            yieldEarned: 0,
            active: true,
            createdAt: block.timestamp
        });

        // Update protocol stats
        totalValueLocked += amount;
        activeUsersCount++;
        protocolStats.activePositions++;

        // Supply to Aave for yield generation
        if (address(aaveVault) != address(0)) {
            USDC.forceApprove(address(aaveVault), amount);
            aaveVault.supplyToAave(amount);
        }

        // Generate position ID
        positionId = keccak256(abi.encodePacked(msg.sender, block.timestamp));

        emit PositionCreated(msg.sender, amount, dailySwapAmount, block.timestamp);
    }

    /**
     * @notice Execute daily swap for a user (callable by anyone or hook)
     * @param user User address to swap for
     * @return amountOut WETH received from swap
     */
    function executeSwap(address user)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 amountOut)
    {
        FlowraTypes.UserPosition storage position = positions[user];

        // Validate position exists
        if (!position.active) revert NoActivePosition();

        // Check if 24 hours have passed
        if (!FlowraMath.canExecuteSwap(position.lastSwapTimestamp)) {
            uint256 timeRemaining = FlowraMath.timeUntilNextSwap(position.lastSwapTimestamp);
            revert SwapTooSoon(timeRemaining);
        }

        // Calculate swap amount
        uint256 swapAmount = position.dailySwapAmount;

        // Check if user has enough remaining USDC
        uint256 remainingUsdc = position.usdcDeposited -
            (position.totalSwapsExecuted * position.dailySwapAmount);

        if (remainingUsdc < swapAmount) {
            swapAmount = remainingUsdc;
        }

        if (swapAmount == 0) revert InsufficientBalance();

        // Withdraw from Aave
        if (address(aaveVault) != address(0)) {
            aaveVault.withdrawFromAave(swapAmount);
        }

        // Execute swap via Uniswap v4 (simplified - actual implementation would interact with pool manager)
        // For now, we'll emit an event and the hook will handle the actual swap
        // In production, this would call the Uniswap v4 PoolManager with swap parameters

        // NOTE: Actual swap execution would happen through Uniswap v4 integration
        // This is a placeholder for the swap logic that will be completed when integrating with the hook

        // For demonstration, we'll assume swap succeeded and update position
        // In reality, the WETH would come from the Uniswap pool via the hook

        // Update position
        position.lastSwapTimestamp = block.timestamp;
        position.totalSwapsExecuted++;

        // Track WETH accumulated (placeholder - actual amount from swap)
        // position.wethAccumulated += amountOut;

        // Update protocol stats
        protocolStats.totalSwapsExecuted++;

        emit SwapExecuted(user, swapAmount, amountOut, block.timestamp);

        return amountOut;
    }

    /**
     * @notice Withdraw from position (close position and claim all assets)
     * @return usdcAmount USDC returned to user
     * @return wethAmount WETH returned to user
     */
    function withdraw()
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 usdcAmount, uint256 wethAmount)
    {
        FlowraTypes.UserPosition storage position = positions[msg.sender];

        // Validate position exists
        if (!position.active) revert NoActivePosition();

        // Calculate remaining USDC
        usdcAmount = position.usdcDeposited -
            (position.totalSwapsExecuted * position.dailySwapAmount);

        wethAmount = position.wethAccumulated;

        // Withdraw remaining USDC from Aave
        if (usdcAmount > 0 && address(aaveVault) != address(0)) {
            aaveVault.withdrawFromAave(usdcAmount);
        }

        // Transfer assets to user
        if (usdcAmount > 0) {
            USDC.safeTransfer(msg.sender, usdcAmount);
        }

        if (wethAmount > 0) {
            WETH.safeTransfer(msg.sender, wethAmount);
        }

        // Update protocol stats
        totalValueLocked -= position.usdcDeposited;
        activeUsersCount--;
        protocolStats.activePositions--;

        // Close position
        position.active = false;

        emit PositionClosed(msg.sender, usdcAmount, wethAmount, block.timestamp);
    }

    /**
     * @notice Claim accumulated WETH without closing position
     * @return wethAmount WETH claimed
     */
    function claimWETH()
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 wethAmount)
    {
        FlowraTypes.UserPosition storage position = positions[msg.sender];

        // Validate position exists
        if (!position.active) revert NoActivePosition();

        wethAmount = position.wethAccumulated;

        if (wethAmount == 0) revert NoWETHToClaim();

        // Reset accumulated WETH
        position.wethAccumulated = 0;

        // Transfer WETH to user
        WETH.safeTransfer(msg.sender, wethAmount);

        emit WETHClaimed(msg.sender, wethAmount, block.timestamp);
    }

    /**
     * @notice Harvest yield from Aave and distribute to projects
     * @dev Only callable by owner
     * @return yieldAmount Total yield harvested
     */
    function harvestYield()
        external
        onlyOwner
        nonReentrant
        returns (uint256 yieldAmount)
    {
        if (address(aaveVault) == address(0)) revert ZeroAddress();
        if (address(yieldRouter) == address(0)) revert ZeroAddress();

        // Harvest yield from Aave
        yieldAmount = aaveVault.harvestYield();

        if (yieldAmount > 0) {
            // Approve yield router to spend USDC
            USDC.forceApprove(address(yieldRouter), yieldAmount);

            // Distribute yield to projects
            yieldRouter.distributeYield(yieldAmount);

            // Update protocol stats
            protocolStats.totalYieldGenerated += yieldAmount;

            emit YieldHarvested(yieldAmount, block.timestamp);
        }

        return yieldAmount;
    }

    // ============ View Functions ============

    /**
     * @notice Get user position details
     * @param user User address
     * @return position User position struct
     */
    function getPosition(address user)
        external
        view
        override
        returns (FlowraTypes.UserPosition memory position)
    {
        return positions[user];
    }

    /**
     * @notice Check if user can execute swap (24h passed)
     * @param user User address
     * @return True if swap can be executed
     */
    function canSwap(address user)
        external
        view
        override
        returns (bool)
    {
        if (!positions[user].active) return false;
        return FlowraMath.canExecuteSwap(positions[user].lastSwapTimestamp);
    }

    /**
     * @notice Get protocol statistics
     * @return stats Protocol stats struct
     */
    function getProtocolStats()
        external
        view
        override
        returns (FlowraTypes.ProtocolStats memory stats)
    {
        stats = protocolStats;
        stats.totalValueLocked = totalValueLocked;
        return stats;
    }

    /**
     * @notice Get estimated swap output
     * @param amountIn USDC input amount
     * @return amountOut Estimated WETH output
     */
    function getSwapQuote(uint256 amountIn)
        external
        view
        override
        returns (uint256 amountOut)
    {
        // This would integrate with Uniswap v4 quoter to get real-time quotes
        // Placeholder implementation
        // In production, this would call the Uniswap v4 quoter contract
        return 0;
    }

    /**
     * @notice Get remaining USDC for a user's position
     * @param user User address
     * @return Remaining USDC amount
     */
    function getRemainingUSDC(address user) external view returns (uint256) {
        FlowraTypes.UserPosition storage position = positions[user];
        if (!position.active) return 0;

        uint256 swappedAmount = position.totalSwapsExecuted * position.dailySwapAmount;
        return position.usdcDeposited - swappedAmount;
    }

    /**
     * @notice Get estimated days to complete DCA for a user
     * @param user User address
     * @return Days remaining
     */
    function getDaysRemaining(address user) external view returns (uint256) {
        FlowraTypes.UserPosition storage position = positions[user];
        if (!position.active) return 0;

        uint256 remainingUsdc = position.usdcDeposited -
            (position.totalSwapsExecuted * position.dailySwapAmount);

        return FlowraMath.estimateDaysToComplete(remainingUsdc, position.dailySwapAmount);
    }

    /**
     * @notice Get position progress percentage
     * @param user User address
     * @return Progress in basis points (0-10000)
     */
    function getPositionProgress(address user) external view returns (uint256) {
        FlowraTypes.UserPosition storage position = positions[user];
        if (!position.active) return 0;

        uint256 totalSwapsNeeded = FlowraMath.estimateDaysToComplete(
            position.usdcDeposited,
            position.dailySwapAmount
        );

        return FlowraMath.calculateProgress(position.totalSwapsExecuted, totalSwapsNeeded);
    }
}
