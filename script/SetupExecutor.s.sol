// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {FlowraCore} from "../src/FlowraCore.sol";

/**
 * @title SetupExecutor
 * @notice Script to grant EXECUTOR_ROLE to the executor wallet
 * @dev Run this after deploying FlowraCore
 *
 * Usage with named wallet:
 * forge script script/SetupExecutor.s.sol \
 *   --rpc-url $ARBITRUM_RPC_URL \
 *   --account monad-deployer \
 *   --broadcast
 *
 * Usage with private key:
 * forge script script/SetupExecutor.s.sol \
 *   --rpc-url $ARBITRUM_RPC_URL \
 *   --broadcast
 *
 * Environment Variables Required:
 * - ARBITRUM_RPC_URL: RPC endpoint for Arbitrum
 * - EXECUTOR_ADDRESS: Address to grant executor role
 * - PRIVATE_KEY: Deployer private key (if not using named wallet)
 */
contract SetupExecutor is Script {
    function run() external {
        // Load deployment info
        string memory deploymentJson = vm.readFile("./deployments/arbitrum-mainnet.json");
        address flowraCoreAddress = vm.parseJsonAddress(deploymentJson, ".flowraCore");

        FlowraCore flowraCore = FlowraCore(flowraCoreAddress);

        // Get executor address from env
        address executorAddress = vm.envAddress("EXECUTOR_ADDRESS");

        // Support both deployment methods
        uint256 deployerPrivateKey;
        address deployer;
        bool usePrivateKey = false;

        try vm.envUint("PRIVATE_KEY") returns (uint256 key) {
            deployerPrivateKey = key;
            deployer = vm.addr(deployerPrivateKey);
            usePrivateKey = true;
        } catch {
            // Using named wallet with --account flag
            deployer = msg.sender;
        }

        console2.log("==============================================");
        console2.log("Setting Up Executor Role");
        console2.log("==============================================");
        console2.log("FlowraCore:      ", flowraCoreAddress);
        console2.log("Executor Address:", executorAddress);
        console2.log("Deployer:        ", deployer);
        console2.log("Method:          ", usePrivateKey ? "Private Key" : "Named Wallet");
        console2.log("==============================================\n");

        if (usePrivateKey) {
            vm.startBroadcast(deployerPrivateKey);
        } else {
            vm.startBroadcast();
        }

        // Get EXECUTOR_ROLE hash
        bytes32 executorRole = flowraCore.EXECUTOR_ROLE();

        // Check if executor already has role
        bool hasRole = flowraCore.hasRole(executorRole, executorAddress);

        if (hasRole) {
            console2.log("Executor already has EXECUTOR_ROLE");
        } else {
            console2.log("Granting EXECUTOR_ROLE to executor...");
            flowraCore.grantRole(executorRole, executorAddress);
            console2.log("[SUCCESS] EXECUTOR_ROLE granted");
        }

        vm.stopBroadcast();

        console2.log("");
        console2.log("==============================================");
        console2.log("Executor Setup Complete!");
        console2.log("==============================================");
        console2.log("");
        console2.log("Executor Capabilities:");
        console2.log("- Execute automated swap batches");
        console2.log("- Execute automated yield claim batches");
        console2.log("- Pause protocol in emergencies");
        console2.log("");
        console2.log("Next Steps:");
        console2.log("1. Add executor private key to frontend .env");
        console2.log("2. Configure automated yield claiming bot");
        console2.log("3. Test executor functions with small amounts");
        console2.log("==============================================\n");
    }
}
