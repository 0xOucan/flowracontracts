// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IFlowraYieldRouter} from "./interfaces/IFlowraYieldRouter.sol";
import {FlowraTypes} from "./libraries/FlowraTypes.sol";
import {FlowraMath} from "./libraries/FlowraMath.sol";

/**
 * @title FlowraYieldRouter
 * @notice Yield distribution to public goods projects (Octant v2 integration)
 * @dev Routes yield from Aave to project wallets with configurable allocations
 *
 * Core Responsibilities:
 * - Manage project registry with wallet addresses
 * - Track allocation percentages (must sum to 100%)
 * - Distribute yield proportionally to projects
 * - Maintain transparent distribution records
 * - Support dynamic project additions/removals
 */
contract FlowraYieldRouter is IFlowraYieldRouter, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    /// @notice USDC token on Arbitrum
    IERC20 public immutable USDC;

    /// @notice FlowraCore contract (authorized caller)
    address public flowraCore;

    /// @notice Array of all projects
    FlowraTypes.Project[] public projects;

    /// @notice Mapping from wallet to project ID
    mapping(address => uint256) public walletToProjectId;

    /// @notice Total yield distributed across all projects
    uint256 public totalDistributed;

    /// @notice Mapping from wallet to total received
    mapping(address => uint256) public projectDistributions;

    /// @notice Active project count
    uint256 public activeProjectCount;

    // ============ Events ============

    event ProjectAdded(
        uint256 indexed projectId,
        address indexed wallet,
        uint256 allocationBps,
        string name
    );

    event ProjectUpdated(
        uint256 indexed projectId,
        address indexed wallet,
        uint256 oldAllocation,
        uint256 newAllocation
    );

    event ProjectRemoved(
        uint256 indexed projectId,
        address indexed wallet
    );

    event YieldDistributed(
        uint256 totalAmount,
        uint256 timestamp
    );

    event ProjectPayment(
        uint256 indexed projectId,
        address indexed wallet,
        uint256 amount,
        uint256 timestamp
    );

    event FlowraCoreUpdated(
        address indexed oldCore,
        address indexed newCore
    );

    // ============ Errors ============

    error ZeroAddress();
    error ZeroAmount();
    error Unauthorized();
    error InvalidAllocation();
    error AllocationsMustEqual100Percent();
    error ProjectNotFound();
    error ProjectAlreadyExists();
    error ProjectNotActive();
    error NoActiveProjects();
    error TransferFailed();

    // ============ Modifiers ============

    /// @notice Only FlowraCore can call distribution functions
    modifier onlyCore() {
        if (msg.sender != flowraCore && msg.sender != owner()) revert Unauthorized();
        _;
    }

    // ============ Constructor ============

    /**
     * @notice Initialize FlowraYieldRouter with USDC address
     * @param _usdc USDC token address (0xaf88d065e77c8cC2239327C5EDb3A432268e5831)
     */
    constructor(address _usdc) Ownable(msg.sender) {
        if (_usdc == address(0)) revert ZeroAddress();
        USDC = IERC20(_usdc);
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
     * @notice Add a new project for yield distribution
     * @param wallet Project wallet address
     * @param allocationBps Allocation in basis points (10000 = 100%)
     * @param name Project name
     * @param description Project description
     */
    function addProject(
        address payable wallet,
        uint256 allocationBps,
        string calldata name,
        string calldata description
    ) external override onlyOwner {
        if (wallet == address(0)) revert ZeroAddress();
        if (allocationBps == 0 || allocationBps > FlowraMath.BPS_DENOMINATOR) {
            revert InvalidAllocation();
        }

        // Check if wallet already exists
        if (projects.length > 0 && walletToProjectId[wallet] != 0) {
            revert ProjectAlreadyExists();
        }

        // Create project
        FlowraTypes.Project memory newProject = FlowraTypes.Project({
            wallet: wallet,
            allocationBps: allocationBps,
            totalReceived: 0,
            active: true,
            name: name,
            description: description
        });

        // Add to array
        projects.push(newProject);
        uint256 projectId = projects.length - 1;

        // Update mappings
        walletToProjectId[wallet] = projectId;
        activeProjectCount++;

        // Validate total allocations
        _validateTotalAllocations();

        emit ProjectAdded(projectId, wallet, allocationBps, name);
    }

    /**
     * @notice Update project allocation
     * @param projectId Project identifier
     * @param newAllocationBps New allocation in basis points
     */
    function updateProjectAllocation(
        uint256 projectId,
        uint256 newAllocationBps
    ) external override onlyOwner {
        if (projectId >= projects.length) revert ProjectNotFound();
        if (newAllocationBps == 0 || newAllocationBps > FlowraMath.BPS_DENOMINATOR) {
            revert InvalidAllocation();
        }

        FlowraTypes.Project storage project = projects[projectId];
        if (!project.active) revert ProjectNotActive();

        uint256 oldAllocation = project.allocationBps;
        project.allocationBps = newAllocationBps;

        // Validate total allocations
        _validateTotalAllocations();

        emit ProjectUpdated(projectId, project.wallet, oldAllocation, newAllocationBps);
    }

    /**
     * @notice Remove project from distribution
     * @param projectId Project identifier
     */
    function removeProject(uint256 projectId) external override onlyOwner {
        if (projectId >= projects.length) revert ProjectNotFound();

        FlowraTypes.Project storage project = projects[projectId];
        if (!project.active) revert ProjectNotActive();

        project.active = false;
        project.allocationBps = 0;
        activeProjectCount--;

        // Clean up mapping
        delete walletToProjectId[project.wallet];

        emit ProjectRemoved(projectId, project.wallet);
    }

    // ============ Distribution Functions ============

    /**
     * @notice Distribute yield to all active projects
     * @param yieldAmount Total yield to distribute
     */
    function distributeYield(uint256 yieldAmount)
        external
        override
        onlyCore
        nonReentrant
    {
        if (yieldAmount == 0) revert ZeroAmount();
        if (activeProjectCount == 0) revert NoActiveProjects();

        // Transfer USDC from caller (FlowraCore or owner)
        USDC.safeTransferFrom(msg.sender, address(this), yieldAmount);

        // Distribute to each active project
        for (uint256 i = 0; i < projects.length; i++) {
            FlowraTypes.Project storage project = projects[i];

            if (!project.active) continue;

            // Calculate project share
            uint256 projectShare = FlowraMath.calculateAllocation(
                yieldAmount,
                project.allocationBps
            );

            if (projectShare > 0) {
                // Transfer to project wallet
                USDC.safeTransfer(project.wallet, projectShare);

                // Update tracking
                project.totalReceived += projectShare;
                projectDistributions[project.wallet] += projectShare;
                totalDistributed += projectShare;

                emit ProjectPayment(i, project.wallet, projectShare, block.timestamp);
            }
        }

        emit YieldDistributed(yieldAmount, block.timestamp);
    }

    // ============ View Functions ============

    /**
     * @notice Get project details
     * @param projectId Project identifier
     * @return project Project struct
     */
    function getProject(uint256 projectId)
        external
        view
        override
        returns (FlowraTypes.Project memory project)
    {
        if (projectId >= projects.length) revert ProjectNotFound();
        return projects[projectId];
    }

    /**
     * @notice Get all active projects
     * @return activeProjects Array of active projects
     */
    function getAllProjects()
        external
        view
        override
        returns (FlowraTypes.Project[] memory activeProjects)
    {
        // Count active projects
        uint256 count = 0;
        for (uint256 i = 0; i < projects.length; i++) {
            if (projects[i].active) count++;
        }

        // Create array of active projects
        activeProjects = new FlowraTypes.Project[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < projects.length; i++) {
            if (projects[i].active) {
                activeProjects[index] = projects[i];
                index++;
            }
        }

        return activeProjects;
    }

    /**
     * @notice Get total yield distributed
     * @return Total yield sent to projects
     */
    function getTotalDistributed()
        external
        view
        override
        returns (uint256)
    {
        return totalDistributed;
    }

    /**
     * @notice Get yield distributed to specific project
     * @param wallet Project wallet address
     * @return Amount distributed to project
     */
    function getProjectDistribution(address wallet)
        external
        view
        override
        returns (uint256)
    {
        return projectDistributions[wallet];
    }

    /**
     * @notice Get total number of projects (active + inactive)
     * @return Total project count
     */
    function getTotalProjects() external view returns (uint256) {
        return projects.length;
    }

    /**
     * @notice Get active project count
     * @return Active projects
     */
    function getActiveProjectCount() external view returns (uint256) {
        return activeProjectCount;
    }

    /**
     * @notice Get project ID by wallet address
     * @param wallet Project wallet
     * @return Project ID (0 if not found)
     */
    function getProjectIdByWallet(address wallet) external view returns (uint256) {
        return walletToProjectId[wallet];
    }

    /**
     * @notice Check if allocations sum to 100%
     * @return True if valid
     */
    function isAllocationValid() external view returns (bool) {
        return _checkTotalAllocations();
    }

    // ============ Internal Functions ============

    /**
     * @notice Validate total allocations equal 100%
     * @dev Reverts if allocations don't sum to 10000 BPS
     */
    function _validateTotalAllocations() internal view {
        if (!_checkTotalAllocations()) {
            revert AllocationsMustEqual100Percent();
        }
    }

    /**
     * @notice Check if total allocations equal 100%
     * @return True if valid
     */
    function _checkTotalAllocations() internal view returns (bool) {
        uint256 totalAllocation = 0;

        for (uint256 i = 0; i < projects.length; i++) {
            if (projects[i].active) {
                totalAllocation += projects[i].allocationBps;
            }
        }

        return totalAllocation == FlowraMath.BPS_DENOMINATOR;
    }

    // ============ Emergency Functions ============

    /**
     * @notice Emergency withdraw USDC (only owner)
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        if (amount > USDC.balanceOf(address(this))) revert ZeroAmount();
        USDC.safeTransfer(owner(), amount);
    }

    /**
     * @notice Recover any ERC20 tokens sent by mistake
     * @param token Token address
     * @param amount Amount to recover
     */
    function recoverERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }
}
