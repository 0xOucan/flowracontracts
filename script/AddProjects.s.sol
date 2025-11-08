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
     * @notice Configure your 6 projects here
     * @dev Projects are chosen by users - no fixed allocations
     *      Users select 1-6 projects and donations are split equally among selected projects
     */
    function getProjects() internal pure returns (ProjectConfig[] memory) {
        ProjectConfig[] memory projectsConfig = new ProjectConfig[](6);

        // Project 0: Amazon Rainforest Restoration
        projectsConfig[0] = ProjectConfig({
            wallet: payable(0x0000000000000000000000000000000000000001), // TODO: Replace with actual wallet
            allocationBps: 0, // Not used - users choose projects
            name: "Amazon Rainforest Restoration",
            description: "Reforestation efforts in the Amazon rainforest, Brazil"
        });

        // Project 1: Ocean Plastic Removal
        projectsConfig[1] = ProjectConfig({
            wallet: payable(0x0000000000000000000000000000000000000002), // TODO: Replace with actual wallet
            allocationBps: 0,
            name: "Ocean Plastic Removal",
            description: "Ocean cleanup initiatives in the Pacific Ocean"
        });

        // Project 2: Solar Power for Villages
        projectsConfig[2] = ProjectConfig({
            wallet: payable(0x0000000000000000000000000000000000000003), // TODO: Replace with actual wallet
            allocationBps: 0,
            name: "Solar Power for Villages",
            description: "Renewable energy projects in rural Kenya"
        });

        // Project 3: Regenerative Farming Initiative
        projectsConfig[3] = ProjectConfig({
            wallet: payable(0x0000000000000000000000000000000000000004), // TODO: Replace with actual wallet
            allocationBps: 0,
            name: "Regenerative Farming Initiative",
            description: "Sustainable agriculture programs in India"
        });

        // Project 4: Coral Reef Restoration
        projectsConfig[4] = ProjectConfig({
            wallet: payable(0x0000000000000000000000000000000000000005), // TODO: Replace with actual wallet
            allocationBps: 0,
            name: "Coral Reef Restoration",
            description: "Coral reef conservation in the Great Barrier Reef"
        });

        // Project 5: Flowra (Default selected in UI)
        projectsConfig[5] = ProjectConfig({
            wallet: payable(0x0000000000000000000000000000000000000006), // TODO: Replace with actual wallet
            allocationBps: 0,
            name: "Flowra",
            description: "Open source DeFi protocol for public goods funding"
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

        console2.log("Total Projects to Add:", projects.length);
        console2.log("Note: Users will select projects and donation % during deposit");
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Add each project
        for (uint256 i = 0; i < projects.length; i++) {
            console2.log("Adding Project", i, ":", projects[i].name);
            console2.log("  Wallet:", projects[i].wallet);
            console2.log("  Description:", projects[i].description);

            yieldRouter.addProject(
                projects[i].wallet,
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
        console2.log("");
        console2.log("How it works:");
        console2.log("- Users select 1-6 projects during deposit");
        console2.log("- Users choose 1-20% of their yield to donate");
        console2.log("- Donations are split equally among selected projects");
        console2.log("- Users keep 80-99% of their yield");
        console2.log("==============================================\n");
    }
}
