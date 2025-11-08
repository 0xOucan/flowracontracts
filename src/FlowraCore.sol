// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {IFlowraCore} from "./interfaces/IFlowraCore.sol";
import {IFlowraAaveVault} from "./interfaces/IFlowraAaveVault.sol";
import {IFlowraYieldRouter} from "./interfaces/IFlowraYieldRouter.sol";
import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {FlowraTypes, Currency} from "./libraries/FlowraTypes.sol";
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
contract FlowraCore is IFlowraCore, Ownable, ReentrancyGuard, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    // ============ Roles ============

    /// @notice Executor role - can manually trigger swaps for testing/low-activity periods
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

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

    /// @notice Uniswap v4 PoolManager
    IPoolManager public poolManager;

    /// @notice USDC/WETH pool key for Uniswap v4
    IPoolManager.PoolKey public poolKey;

    /// @notice Swap interval in seconds (configurable by admin)
    /// @dev Default is 300 seconds (5 minutes) for testing, use 86400 (24h) for production
    uint256 public swapInterval;

    /// @notice Maximum slippage tolerance in basis points (1% = 100 BPS)
    uint256 public maxSlippageBps;

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
    event PoolManagerUpdated(address indexed oldManager, address indexed newManager);
    event SwapIntervalUpdated(uint256 oldInterval, uint256 newInterval);
    event MaxSlippageUpdated(uint256 oldSlippage, uint256 newSlippage);

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
     * @param _poolManager Uniswap v4 PoolManager address (0x360e68faccca8ca495c1b759fd9eee466db9fb32)
     */
    constructor(
        address _usdc,
        address _weth,
        address _poolManager
    ) Ownable(msg.sender) {
        if (_usdc == address(0) || _weth == address(0) || _poolManager == address(0)) revert ZeroAddress();

        USDC = IERC20(_usdc);
        WETH = IERC20(_weth);
        poolManager = IPoolManager(_poolManager);

        // Initialize swap interval to 5 minutes (300 seconds) for testing
        swapInterval = FlowraMath.DEFAULT_SWAP_INTERVAL;

        // Initialize max slippage to 1% (100 basis points)
        maxSlippageBps = FlowraMath.MAX_SLIPPAGE_BPS;

        // Grant DEFAULT_ADMIN_ROLE to deployer for role management
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

    /**
     * @notice Grant executor role to an address
     * @param executor Address to grant executor role
     * @dev Only admin can grant executor role
     */
    function grantExecutor(address executor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(EXECUTOR_ROLE, executor);
    }

    /**
     * @notice Revoke executor role from an address
     * @param executor Address to revoke executor role
     * @dev Only admin can revoke executor role
     */
    function revokeExecutor(address executor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(EXECUTOR_ROLE, executor);
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
     * @notice Execute daily swap for a user
     * @param user User address to swap for
     * @return amountOut WETH received from swap
     * @dev Callable by: anyone (permissionless), hook (automatic), or executor (manual)
     *      Executors are useful when pool activity is low and automatic execution doesn't trigger
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

        // Execute swap via Uniswap v4
        amountOut = _executeUniswapSwap(swapAmount);

        // Update position
        position.lastSwapTimestamp = block.timestamp;
        position.totalSwapsExecuted++;
        position.wethAccumulated += amountOut;

        // Update protocol stats
        protocolStats.totalSwapsExecuted++;

        emit SwapExecuted(user, swapAmount, amountOut, block.timestamp);

        return amountOut;
    }

    /**
     * @notice Execute swap through Uniswap v4 PoolManager
     * @param usdcAmount Amount of USDC to swap
     * @return wethAmount Amount of WETH received
     * @dev This is a simplified implementation. For production, consider:
     *      1. Using Uniswap UniversalRouter for better routing
     *      2. Implementing proper unlock callback pattern
     *      3. Adding MEV protection
     *      4. Using TWAP/oracle for price validation
     */
    function _executeUniswapSwap(uint256 usdcAmount) internal returns (uint256 wethAmount) {
        // IMPORTANT: This is a simplified direct swap implementation
        // Uniswap v4 uses an "unlock" pattern for swaps, which is more complex
        // For a production implementation, you should:
        // 1. Use the unlock() function with a callback
        // 2. Implement unlockCallback() to handle the swap logic
        // 3. Properly handle balance deltas and settlements

        // For now, we'll use a direct approach that works for testing
        // TODO: Replace with proper v4 unlock pattern for production

        try poolManager.swap(
            poolKey,
            IPoolManager.SwapParams({
                zeroForOne: true, // USDC (currency0) → WETH (currency1)
                amountSpecified: int256(usdcAmount),
                sqrtPriceLimitX96: 0 // No price limit (not recommended for production)
            }),
            "" // No hook data
        ) returns (int256 delta) {
            // Delta is negative for amount out (WETH received)
            wethAmount = uint256(-delta);

            // Validate we received some WETH
            if (wethAmount == 0) revert SwapFailed();

            return wethAmount;
        } catch {
            // Swap failed - revert with error
            revert SwapFailed();
        }
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

    /**
     * @notice Execute swaps for multiple users in batch (executor only)
     * @param users Array of user addresses
     * @return successCount Number of successful swaps
     * @dev Only callable by executor role - useful for manual execution when pool activity is low
     *      Continues on individual failures to maximize successful swaps
     */
    function executeSwapBatch(address[] calldata users)
        external
        onlyRole(EXECUTOR_ROLE)
        nonReentrant
        whenNotPaused
        returns (uint256 successCount)
    {
        for (uint256 i = 0; i < users.length; i++) {
            try this.executeSwap(users[i]) returns (uint256) {
                successCount++;
            } catch {
                // Continue to next user on failure
                continue;
            }
        }

        return successCount;
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

    /**
     * @notice Check if user has executor role
     * @param account Address to check
     * @return True if account has executor role
     */
    function isExecutor(address account) external view returns (bool) {
        return hasRole(EXECUTOR_ROLE, account);
    }

    // ============ Override Required Functions ============

    /**
     * @notice Override supportsInterface for AccessControl + other interfaces
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
