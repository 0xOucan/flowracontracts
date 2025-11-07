// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IFlowraAaveVault} from "./interfaces/IFlowraAaveVault.sol";
import {FlowraTypes} from "./libraries/FlowraTypes.sol";

/// @notice Aave reserve data structure
struct ReserveData {
    uint256 configuration;
    uint128 liquidityIndex;
    uint128 currentLiquidityRate;
    uint128 variableBorrowIndex;
    uint128 currentVariableBorrowRate;
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    uint16 id;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    uint128 accruedToTreasury;
    uint128 unbacked;
    uint128 isolationModeTotalDebt;
}

/// @notice Aave v3 Pool interface (minimal for our needs)
interface IPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function getReserveData(address asset) external view returns (ReserveData memory);
}

/**
 * @title FlowraAaveVault
 * @notice Aave v3 integration for Flowra protocol yield generation
 * @dev Manages USDC supply to Aave, tracks yield, and handles withdrawals
 *
 * Core Responsibilities:
 * - Supply USDC to Aave v3 to earn yield
 * - Track yield earned (aUSDC balance - supplied amount)
 * - Withdraw USDC on demand for DCA swaps
 * - Harvest yield for distribution to projects
 * - Monitor health factors and liquidity
 */
contract FlowraAaveVault is IFlowraAaveVault, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    /// @notice USDC token on Arbitrum
    IERC20 public immutable USDC;

    /// @notice aUSDC token (Aave interest-bearing USDC)
    IERC20 public aUSDC;

    /// @notice Aave v3 Pool on Arbitrum
    IPool public immutable aavePool;

    /// @notice FlowraCore contract (authorized caller)
    address public flowraCore;

    /// @notice Aave position tracking
    FlowraTypes.AavePosition public aavePosition;

    /// @notice Total USDC supplied to Aave
    uint256 public totalSupplied;

    /// @notice Total yield harvested
    uint256 public totalYieldHarvested;

    // ============ Events ============

    event SuppliedToAave(uint256 amount, uint256 timestamp);
    event WithdrawnFromAave(uint256 amount, uint256 timestamp);
    event YieldHarvested(uint256 yieldAmount, uint256 timestamp);
    event FlowraCoreUpdated(address indexed oldCore, address indexed newCore);
    event ATokenUpdated(address indexed aToken);

    // ============ Errors ============

    error ZeroAmount();
    error ZeroAddress();
    error Unauthorized();
    error InsufficientBalance();
    error InsufficientLiquidity();
    error AaveOperationFailed();

    // ============ Modifiers ============

    /// @notice Only FlowraCore can call certain functions
    modifier onlyCore() {
        if (msg.sender != flowraCore) revert Unauthorized();
        _;
    }

    // ============ Constructor ============

    /**
     * @notice Initialize FlowraAaveVault with Arbitrum addresses
     * @param _usdc USDC token address (0xaf88d065e77c8cC2239327C5EDb3A432268e5831)
     * @param _aavePool Aave v3 Pool address (0x794a61358D6845594F94dc1DB02A252b5b4814aD)
     */
    constructor(
        address _usdc,
        address _aavePool
    ) Ownable(msg.sender) {
        if (_usdc == address(0) || _aavePool == address(0)) revert ZeroAddress();

        USDC = IERC20(_usdc);
        aavePool = IPool(_aavePool);

        // Get aUSDC address from Aave reserve data
        ReserveData memory reserveData = aavePool.getReserveData(_usdc);
        aUSDC = IERC20(reserveData.aTokenAddress);

        emit ATokenUpdated(reserveData.aTokenAddress);
    }

    // ============ Admin Functions ============

    /**
     * @notice Set FlowraCore contract address
     * @param _core FlowraCore address
     */
    function setFlowraCore(address _core) external onlyOwner {
        if (_core == address(0)) revert ZeroAddress();
        emit FlowraCoreUpdated(flowraCore, _core);
        flowraCore = _core;
    }

    /**
     * @notice Update aUSDC token address (in case of Aave upgrades)
     */
    function updateAToken() external onlyOwner {
        ReserveData memory reserveData = aavePool.getReserveData(address(USDC));
        aUSDC = IERC20(reserveData.aTokenAddress);
        emit ATokenUpdated(reserveData.aTokenAddress);
    }

    // ============ Core Functions ============

    /**
     * @notice Supply USDC to Aave v3
     * @param amount USDC amount to supply
     */
    function supplyToAave(uint256 amount)
        external
        override
        onlyCore
        nonReentrant
    {
        if (amount == 0) revert ZeroAmount();

        // Transfer USDC from FlowraCore
        USDC.safeTransferFrom(msg.sender, address(this), amount);

        // Approve Aave Pool
        USDC.forceApprove(address(aavePool), amount);

        // Supply to Aave (referralCode = 0)
        aavePool.supply(address(USDC), amount, address(this), 0);

        // Update tracking
        totalSupplied += amount;
        aavePosition.supplied += amount;
        aavePosition.lastUpdateTime = block.timestamp;

        emit SuppliedToAave(amount, block.timestamp);
    }

    /**
     * @notice Withdraw USDC from Aave v3
     * @param amount USDC amount to withdraw (type(uint256).max for all)
     * @return actualAmount Actual amount withdrawn
     */
    function withdrawFromAave(uint256 amount)
        external
        override
        onlyCore
        nonReentrant
        returns (uint256 actualAmount)
    {
        if (amount == 0) revert ZeroAmount();

        // Check available liquidity
        uint256 availableLiquidity = getAvailableLiquidity();
        if (availableLiquidity == 0) revert InsufficientLiquidity();

        // Use max available if requested amount is too high
        uint256 withdrawAmount = amount;
        if (amount > availableLiquidity) {
            withdrawAmount = availableLiquidity;
        }

        // Withdraw from Aave
        actualAmount = aavePool.withdraw(address(USDC), withdrawAmount, flowraCore);

        // Update tracking (don't reduce more than totalSupplied)
        uint256 reduction = actualAmount > totalSupplied ? totalSupplied : actualAmount;
        totalSupplied -= reduction;
        aavePosition.supplied = totalSupplied;
        aavePosition.lastUpdateTime = block.timestamp;

        emit WithdrawnFromAave(actualAmount, block.timestamp);

        return actualAmount;
    }

    /**
     * @notice Get total yield earned from Aave
     * @return Total yield in USDC (aUSDC balance - supplied)
     */
    function getYieldEarned()
        external
        view
        override
        returns (uint256)
    {
        uint256 aTokenBalance = aUSDC.balanceOf(address(this));

        // Yield = current aToken balance - originally supplied amount
        if (aTokenBalance > totalSupplied) {
            return aTokenBalance - totalSupplied;
        }

        return 0;
    }

    /**
     * @notice Harvest yield for distribution to projects
     * @return yieldAmount Yield harvested
     */
    function harvestYield()
        external
        override
        onlyOwner
        nonReentrant
        returns (uint256 yieldAmount)
    {
        uint256 aTokenBalance = aUSDC.balanceOf(address(this));

        // Calculate yield (aToken balance - supplied)
        if (aTokenBalance > totalSupplied) {
            yieldAmount = aTokenBalance - totalSupplied;
        } else {
            return 0;
        }

        if (yieldAmount == 0) return 0;

        // Withdraw yield from Aave
        uint256 withdrawn = aavePool.withdraw(address(USDC), yieldAmount, msg.sender);

        // Update tracking
        totalYieldHarvested += withdrawn;
        aavePosition.accumulatedYield += withdrawn;
        aavePosition.lastUpdateTime = block.timestamp;

        emit YieldHarvested(withdrawn, block.timestamp);

        return withdrawn;
    }

    // ============ View Functions ============

    /**
     * @notice Get current Aave position details
     * @return supplied Total USDC supplied
     * @return aTokenBalance Current aToken balance
     * @return currentAPY Current Aave APY in basis points
     */
    function getAavePosition()
        external
        view
        override
        returns (
            uint256 supplied,
            uint256 aTokenBalance,
            uint256 currentAPY
        )
    {
        supplied = totalSupplied;
        aTokenBalance = aUSDC.balanceOf(address(this));

        // Get current APY from Aave
        ReserveData memory reserveData = aavePool.getReserveData(address(USDC));

        // Convert ray (1e27) to basis points (1e4)
        // Aave uses ray (1e27) for rates, we need BPS (1e4)
        // APY = rate / 1e27 * 1e4 = rate / 1e23
        currentAPY = uint256(reserveData.currentLiquidityRate) / 1e23;

        return (supplied, aTokenBalance, currentAPY);
    }

    /**
     * @notice Get available USDC liquidity in Aave
     * @return Available USDC to withdraw
     */
    function getAvailableLiquidity()
        public
        view
        override
        returns (uint256)
    {
        // Our aToken balance represents what we can withdraw
        return aUSDC.balanceOf(address(this));
    }

    /**
     * @notice Get current yield available for harvest
     * @return Current unharvested yield
     */
    function getCurrentYield() external view returns (uint256) {
        uint256 aTokenBalance = aUSDC.balanceOf(address(this));

        if (aTokenBalance > totalSupplied) {
            return aTokenBalance - totalSupplied;
        }

        return 0;
    }

    /**
     * @notice Get Aave position struct
     * @return Aave position details
     */
    function getAavePositionStruct()
        external
        view
        returns (FlowraTypes.AavePosition memory)
    {
        return aavePosition;
    }

    /**
     * @notice Get total yield harvested to date
     * @return Total harvested yield
     */
    function getTotalYieldHarvested() external view returns (uint256) {
        return totalYieldHarvested;
    }

    // ============ Emergency Functions ============

    /**
     * @notice Emergency withdraw all funds from Aave
     * @dev Only callable by owner in emergencies
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = aUSDC.balanceOf(address(this));

        if (balance > 0) {
            aavePool.withdraw(address(USDC), type(uint256).max, owner());
        }
    }

    /**
     * @notice Recover any ERC20 tokens sent to this contract by mistake
     * @param token Token address to recover
     * @param amount Amount to recover
     */
    function recoverERC20(address token, uint256 amount) external onlyOwner {
        if (token == address(USDC) || token == address(aUSDC)) {
            revert Unauthorized();
        }

        IERC20(token).safeTransfer(owner(), amount);
    }
}
