// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FlowraTypes} from "../libraries/FlowraTypes.sol";

/**
 * @title IFlowraYieldRouter
 * @notice Interface for Octant yield distribution to projects
 * @dev Routes yield to public goods project wallets
 */
interface IFlowraYieldRouter {
    /**
     * @notice Add a new project for yield distribution
     * @param wallet Project wallet address
     * @param allocationBps Allocation in basis points
     * @param name Project name
     * @param description Project description
     */
    function addProject(
        address payable wallet,
        uint256 allocationBps,
        string calldata name,
        string calldata description
    ) external;

    /**
     * @notice Update project allocation
     * @param projectId Project identifier
     * @param newAllocationBps New allocation in basis points
     */
    function updateProjectAllocation(uint256 projectId, uint256 newAllocationBps) external;

    /**
     * @notice Remove project from distribution
     * @param projectId Project identifier
     */
    function removeProject(uint256 projectId) external;

    /**
     * @notice Distribute yield to all active projects
     * @param yieldAmount Total yield to distribute
     */
    function distributeYield(uint256 yieldAmount) external;

    /**
     * @notice Get project details
     * @param projectId Project identifier
     * @return project Project struct
     */
    function getProject(uint256 projectId) external view returns (FlowraTypes.Project memory project);

    /**
     * @notice Get all active projects
     * @return projects Array of active projects
     */
    function getAllProjects() external view returns (FlowraTypes.Project[] memory projects);

    /**
     * @notice Get total yield distributed
     * @return Total yield sent to projects
     */
    function getTotalDistributed() external view returns (uint256);

    /**
     * @notice Get yield distributed to specific project
     * @param wallet Project wallet address
     * @return Amount distributed to project
     */
    function getProjectDistribution(address wallet) external view returns (uint256);
}
