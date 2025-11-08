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
     * @param name Project name
     * @param description Project description
     */
    function addProject(
        address payable wallet,
        string calldata name,
        string calldata description
    ) external;

    /**
     * @notice Record a donation to a project
     * @param projectId Project identifier
     * @param amount Amount donated in USDC
     * @param donor Address of the donor
     */
    function recordDonation(
        uint256 projectId,
        uint256 amount,
        address donor
    ) external;

    /**
     * @notice Remove project from distribution
     * @param projectId Project identifier
     */
    function removeProject(uint256 projectId) external;

    /**
     * @notice Get project details
     * @param projectId Project identifier
     * @return project Project struct
     */
    function getProject(uint256 projectId) external view returns (FlowraTypes.Project memory project);

    /**
     * @notice Get project by ID (alias for getProject)
     * @param projectId Project identifier
     * @return project Project struct
     */
    function getProjectById(uint256 projectId) external view returns (FlowraTypes.Project memory project);

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
