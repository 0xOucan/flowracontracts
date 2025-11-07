// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {FlowraYieldRouter} from "../src/FlowraYieldRouter.sol";

/**
 * @title AddProjects
 * @notice Script to add projects to FlowraYieldRouter
 * @dev Configure project wallets and allocations
 *
 * Usage:
 * forge script script/AddProjects.s.sol --rpc-url $ARBITRUM_RPC_URL --broadcast
 *
 * Note: Edit the projects array below to configure your projects
 */
contract AddProjects is Script {
    // ============ Configuration ============

    struct ProjectConfig {
        address payable wallet;
        uint256 allocationBps;
        string name;
        string description;
    }

    /**
     * @notice Configure your projects here
     * @dev Allocations must sum to 10000 (100%)
     */
    function getProjects() internal pure returns (ProjectConfig[] memory) {
        ProjectConfig[] memory projectsConfig = new ProjectConfig[](4);

        // Project 1: Climate Initiatives (40%)
        projectsConfig[0] = ProjectConfig({
            wallet: payable(0x0000000000000000000000000000000000000001), // TODO: Replace with actual wallet
            allocationBps: 4000, // 40%
            name: "Climate Action Fund",
            description: "Supporting renewable energy and carbon offset projects"
        });

        // Project 2: Developer Tooling (30%)
        projectsConfig[1] = ProjectConfig({
            wallet: payable(0x0000000000000000000000000000000000000002), // TODO: Replace with actual wallet
            allocationBps: 3000, // 30%
            name: "Open Source Tooling",
            description: "Funding developer tools and infrastructure"
        });

        // Project 3: Education (20%)
        projectsConfig[2] = ProjectConfig({
            wallet: payable(0x0000000000000000000000000000000000000003), // TODO: Replace with actual wallet
            allocationBps: 2000, // 20%
            name: "Blockchain Education",
            description: "Educational resources and workshops"
        });

        // Project 4: Research (10%)
        projectsConfig[3] = ProjectConfig({
            wallet: payable(0x0000000000000000000000000000000000000004), // TODO: Replace with actual wallet
            allocationBps: 1000, // 10%
            name: "Protocol Research",
            description: "Funding research on DeFi protocols and mechanisms"
        });

        return projectsConfig;
    }

    function run() external {
        // Load deployment info
        string memory deploymentJson = vm.readFile("./deployments/arbitrum-mainnet.json");
        address yieldRouterAddress = vm.parseJsonAddress(deploymentJson, ".yieldRouter");

        FlowraYieldRouter yieldRouter = FlowraYieldRouter(yieldRouterAddress);

        // Get deployer
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console2.log("==============================================");
        console2.log("Adding Projects to FlowraYieldRouter");
        console2.log("==============================================");
        console2.log("YieldRouter:", address(yieldRouter));
        console2.log("==============================================\n");

        ProjectConfig[] memory projects = getProjects();

        // Validate total allocations
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < projects.length; i++) {
            totalAllocation += projects[i].allocationBps;
        }

        require(totalAllocation == 10000, "Allocations must sum to 100% (10000 BPS)");
        console2.log("Total allocation: 100% (10000 BPS)");
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Add each project
        for (uint256 i = 0; i < projects.length; i++) {
            console2.log("Adding Project:", projects[i].name);
            console2.log("  Wallet:", projects[i].wallet);
            console2.log("  Allocation (BPS):", projects[i].allocationBps);
            console2.log("  Description:", projects[i].description);

            yieldRouter.addProject(
                projects[i].wallet,
                projects[i].allocationBps,
                projects[i].name,
                projects[i].description
            );

            console2.log("  [SUCCESS] Added successfully");
            console2.log("");
        }

        vm.stopBroadcast();

        console2.log("==============================================");
        console2.log("Projects Added Successfully!");
        console2.log("==============================================");
        console2.log("Total Projects:", projects.length);
        console2.log("==============================================\n");

        // Verify allocations
        console2.log("Verifying allocations...");
        bool isValid = yieldRouter.isAllocationValid();
        console2.log("Allocation Valid:", isValid ? "YES" : "NO");
        console2.log("");
    }
}
