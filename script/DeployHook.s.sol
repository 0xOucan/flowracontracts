// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {FlowraHook} from "../src/FlowraHook.sol";
import {FlowraCore} from "../src/FlowraCore.sol";

/**
 * @title DeployHook
 * @notice Deployment script for FlowraHook on Arbitrum mainnet
 * @dev Deploys FlowraHook and configures it with FlowraCore
 *
 * Usage:
 *   forge script script/DeployHook.s.sol \
 *     --rpc-url $ARBITRUM_RPC_URL \
 *     --account monad-deployer \
 *     --sender $DEPLOYER_ADDRESS \
 *     --broadcast \
 *     --verify
 */
contract DeployHook is Script {
    // Arbitrum mainnet addresses
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant POOL_MANAGER = 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32;

    function run() external {
        // Get deployer address from environment
        address deployer = msg.sender;

        console.log("==============================================");
        console.log("FlowraHook Deployment");
        console.log("==============================================");
        console.log("Deployer:", deployer);
        console.log("Network: Arbitrum Mainnet (Chain ID: 42161)");
        console.log("Method:", "Named Wallet");
        console.log("==============================================\n");

        // Load FlowraCore address from deployment file
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/arbitrum-mainnet.json");
        string memory json = vm.readFile(path);

        address flowraCore = vm.parseJsonAddress(json, ".flowraCore");

        console.log("Existing Deployment:");
        console.log("  FlowraCore:", flowraCore);
        console.log("");

        vm.startBroadcast();

        console.log("Deploying FlowraHook...\n");

        // Deploy FlowraHook
        FlowraHook hook = new FlowraHook(USDC, WETH);
        console.log("  FlowraHook deployed at:", address(hook));
        console.log("");

        console.log("Configuring FlowraHook...\n");

        // Set FlowraCore
        console.log("1. Setting FlowraCore...");
        hook.setFlowraCore(flowraCore);
        console.log("   FlowraCore set successfully");
        console.log("");

        // Set PoolManager
        console.log("2. Setting PoolManager...");
        hook.setPoolManager(POOL_MANAGER);
        console.log("   PoolManager set successfully");
        console.log("");

        console.log("3. Setting Hook in FlowraCore...");
        FlowraCore(flowraCore).setHook(address(hook));
        console.log("   Hook set in FlowraCore successfully");
        console.log("");

        vm.stopBroadcast();

        console.log("==============================================");
        console.log("Hook Deployment Complete!");
        console.log("==============================================\n");

        console.log("Contract Addresses:");
        console.log("-------------------");
        console.log("FlowraHook:        ", address(hook));
        console.log("FlowraCore:        ", flowraCore);
        console.log("");

        console.log("Uniswap v4 Integration:");
        console.log("-------------------");
        console.log("PoolManager:       ", POOL_MANAGER);
        console.log("USDC/WETH Pool:     Not initialized yet");
        console.log("");

        console.log("Next Steps:");
        console.log("-------------------");
        console.log("1. Initialize USDC/WETH pool on Uniswap v4");
        console.log("2. Set pool key in FlowraHook");
        console.log("3. Test hook with small DCA deposit");
        console.log("4. Monitor first automated swap execution");
        console.log("==============================================\n");

        // Save deployment info
        string memory finalJson = "deployment";
        vm.serializeAddress(finalJson, "flowraHook", address(hook));
        vm.serializeAddress(finalJson, "flowraCore", flowraCore);
        vm.serializeAddress(finalJson, "poolManager", POOL_MANAGER);
        vm.serializeAddress(finalJson, "usdc", USDC);
        string memory output = vm.serializeAddress(finalJson, "weth", WETH);

        string memory deploymentPath = string.concat(root, "/deployments/arbitrum-hook.json");
        vm.writeJson(output, deploymentPath);

        console.log("Deployment info saved to: deployments/arbitrum-hook.json");
        console.log("");
    }
}
