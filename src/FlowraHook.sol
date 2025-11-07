// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IFlowraHook} from "./interfaces/IFlowraHook.sol";
import {IFlowraCore} from "./interfaces/IFlowraCore.sol";
import {FlowraTypes} from "./libraries/FlowraTypes.sol";
import {FlowraMath} from "./libraries/FlowraMath.sol";

/**
 * @title FlowraHook
 * @notice Uniswap v4 hook for automated DCA swap execution
 * @dev Implements beforeSwap and afterSwap hooks for event-driven DCA
 *
 * Core Responsibilities:
 * - Listen for swaps on USDC/WETH pool
 * - Check if any users are ready for daily swap (24h passed)
 * - Piggyback on regular swaps to execute DCA swaps
 * - No keepers needed - fully event-driven
 * - Uses JIT liquidity pattern for efficiency
 *
 * NOTE: This contract requires Uniswap v4 to be deployed on Arbitrum
 * It follows the BaseHook pattern from Uniswap v4 periphery
 */
contract FlowraHook is IFlowraHook, Ownable {
    // ============ State Variables ============

    /// @notice FlowraCore contract
    IFlowraCore public flowraCore;

    /// @notice USDC token on Arbitrum
    IERC20 public immutable USDC;

    /// @notice WETH token on Arbitrum
    IERC20 public immutable WETH;

    /// @notice Uniswap v4 PoolManager
    /// @dev Will be set once v4 is deployed on Arbitrum
    address public poolManager;

    /// @notice USDC/WETH pool key
    /// @dev Will be set during initialization
    bytes32 public poolKey;

    /// @notice Users ready for swap (queue)
    address[] public swapQueue;

    /// @notice Mapping to check if user is in queue
    mapping(address => bool) public inQueue;

    // ============ Events ============

    event SwapExecuted(
        address indexed user,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );

    event UserAddedToQueue(address indexed user);
    event UserRemovedFromQueue(address indexed user);
    event PoolManagerUpdated(address indexed poolManager);
    event FlowraCoreUpdated(address indexed core);

    // ============ Errors ============

    error ZeroAddress();
    error Unauthorized();
    error NotPoolManager();
    error SwapFailed();
    error UserNotReady();

    // ============ Modifiers ============

    /// @notice Only PoolManager can call hook functions
    modifier onlyPoolManager() {
        if (msg.sender != poolManager) revert NotPoolManager();
        _;
    }

    // ============ Constructor ============

    /**
     * @notice Initialize FlowraHook with token addresses
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
     * @notice Set FlowraCore contract address
     * @param _core FlowraCore address
     */
    function setFlowraCore(address _core) external override onlyOwner {
        if (_core == address(0)) revert ZeroAddress();
        flowraCore = IFlowraCore(_core);
        emit FlowraCoreUpdated(_core);
    }

    /**
     * @notice Set PoolManager address
     * @param _poolManager Uniswap v4 PoolManager address
     */
    function setPoolManager(address _poolManager) external onlyOwner {
        if (_poolManager == address(0)) revert ZeroAddress();
        poolManager = _poolManager;
        emit PoolManagerUpdated(_poolManager);
    }

    /**
     * @notice Set pool key for USDC/WETH pool
     * @param _poolKey Pool key bytes32
     */
    function setPoolKey(bytes32 _poolKey) external onlyOwner {
        poolKey = _poolKey;
    }

    // ============ Hook Functions ============

    /**
     * @notice beforeSwap hook - executed before any swap on the pool
     * @dev Checks if any users are ready for DCA swap and executes
     *
     * NOTE: This is a placeholder for the actual Uniswap v4 hook implementation
     * The actual signature will match IHooks.beforeSwap from v4-core
     */
    function beforeSwap(
        address /* sender */,
        bytes calldata /* key */,
        bytes calldata /* params */,
        bytes calldata /* hookData */
    ) external onlyPoolManager returns (bytes4) {
        // Check if any users are ready for swap
        _processSwapQueue();

        // Return selector to continue with swap
        return this.beforeSwap.selector;
    }

    /**
     * @notice afterSwap hook - executed after any swap on the pool
     * @dev Updates position tracking after swap completes
     *
     * NOTE: This is a placeholder for the actual Uniswap v4 hook implementation
     * The actual signature will match IHooks.afterSwap from v4-core
     */
    function afterSwap(
        address /* sender */,
        bytes calldata /* key */,
        bytes calldata /* params */,
        int256 /* delta */,
        bytes calldata /* hookData */
    ) external onlyPoolManager returns (bytes4) {
        // Update queue after swap
        _updateQueue();

        // Return selector to continue
        return this.afterSwap.selector;
    }

    // ============ Queue Management ============

    /**
     * @notice Add user to swap queue
     * @param user User address
     */
    function addToQueue(address user) external {
        if (msg.sender != address(flowraCore) && msg.sender != owner()) {
            revert Unauthorized();
        }

        if (!inQueue[user] && canExecuteSwap(user)) {
            swapQueue.push(user);
            inQueue[user] = true;
            emit UserAddedToQueue(user);
        }
    }

    /**
     * @notice Remove user from swap queue
     * @param user User address
     */
    function removeFromQueue(address user) external {
        if (msg.sender != address(flowraCore) && msg.sender != owner()) {
            revert Unauthorized();
        }

        _removeUserFromQueue(user);
    }

    /**
     * @notice Process swap queue during beforeSwap
     */
    function _processSwapQueue() internal {
        if (swapQueue.length == 0) return;
        if (address(flowraCore) == address(0)) return;

        // Try to execute swap for first user in queue
        address user = swapQueue[0];

        if (canExecuteSwap(user)) {
            try flowraCore.executeSwap(user) returns (uint256 amountOut) {
                emit SwapExecuted(user, 0, amountOut, block.timestamp);
            } catch {
                // Swap failed, user will retry next time
            }
        }

        // Remove user from queue
        _removeUserFromQueue(user);
    }

    /**
     * @notice Update queue after swap
     */
    function _updateQueue() internal {
        // Check if any new users are ready
        // This would require maintaining a list of all users
        // Or FlowraCore can call addToQueue when users become ready
    }

    /**
     * @notice Remove user from swap queue
     * @param user User address
     */
    function _removeUserFromQueue(address user) internal {
        if (!inQueue[user]) return;

        // Find and remove user from queue
        for (uint256 i = 0; i < swapQueue.length; i++) {
            if (swapQueue[i] == user) {
                // Move last element to this position
                swapQueue[i] = swapQueue[swapQueue.length - 1];
                swapQueue.pop();
                break;
            }
        }

        inQueue[user] = false;
        emit UserRemovedFromQueue(user);
    }

    // ============ View Functions ============

    /**
     * @notice Check if user can execute swap
     * @param user User address
     * @return True if user is ready for swap
     */
    function canExecuteSwap(address user)
        public
        view
        override
        returns (bool)
    {
        if (address(flowraCore) == address(0)) return false;
        return flowraCore.canSwap(user);
    }

    /**
     * @notice Get pending swap count
     * @return Number of users in queue
     */
    function getPendingSwapCount()
        external
        view
        override
        returns (uint256)
    {
        return swapQueue.length;
    }

    /**
     * @notice Get next user ready for swap
     * @return user User address (address(0) if none)
     */
    function getNextSwapUser()
        external
        view
        override
        returns (address user)
    {
        if (swapQueue.length == 0) return address(0);
        return swapQueue[0];
    }

    /**
     * @notice Get hook permissions for Uniswap v4
     * @return Permissions flags
     * @dev Returns flags indicating which hooks are implemented
     * BEFORE_SWAP_FLAG | AFTER_SWAP_FLAG
     */
    function getHookPermissions()
        external
        pure
        override
        returns (uint256)
    {
        // This would return the actual permission flags for v4
        // For now, placeholder that indicates beforeSwap and afterSwap
        return 0;
    }

    /**
     * @notice Get full swap queue
     * @return Array of user addresses
     */
    function getSwapQueue() external view returns (address[] memory) {
        return swapQueue;
    }

    /**
     * @notice Check if user is in queue
     * @param user User address
     * @return True if in queue
     */
    function isInQueue(address user) external view returns (bool) {
        return inQueue[user];
    }

    // ============ Emergency Functions ============

    /**
     * @notice Clear swap queue in emergency
     */
    function clearQueue() external onlyOwner {
        for (uint256 i = 0; i < swapQueue.length; i++) {
            inQueue[swapQueue[i]] = false;
        }
        delete swapQueue;
    }

    /**
     * @notice Recover ERC20 tokens sent by mistake
     * @param token Token address
     * @param amount Amount to recover
     */
    function recoverERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }
}
