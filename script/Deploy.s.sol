// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {FlowraCore} from "../src/FlowraCore.sol";
import {FlowraAaveVault} from "../src/FlowraAaveVault.sol";
import {FlowraYieldRouter} from "../src/FlowraYieldRouter.sol";
import {FlowraHook} from "../src/FlowraHook.sol";

/**
 * @title Deploy
 * @notice Deployment script for Flowra protocol on Arbitrum mainnet
 * @dev Deploys all contracts in correct order with proper configuration
 *
 * Usage:
 * forge script script/Deploy.s.sol --rpc-url $ARBITRUM_RPC_URL --broadcast --verify
 *
 * Environment Variables Required:
 * - ARBITRUM_RPC_URL: RPC endpoint for Arbitrum
 * - PRIVATE_KEY: Deployer private key
 * - ARBISCAN_API_KEY: For contract verification
 */
contract Deploy is Script {
    // ============ Arbitrum Mainnet Addresses ============

    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    // Uniswap v4 PoolManager on Arbitrum One (from https://docs.uniswap.org/contracts/v4/deployments)
    address constant POOL_MANAGER = 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32;

    // ============ Deployed Contracts ============

    FlowraCore public flowraCore;
    FlowraAaveVault public aaveVault;
    FlowraYieldRouter public yieldRouter;
    FlowraHook public flowraHook;

    function run() external {
        // Support both deployment methods:
        // 1. Named wallet (--account monad-deployer): No PRIVATE_KEY needed
        // 2. Private key (.env PRIVATE_KEY): Traditional approach

        // Try to get PRIVATE_KEY, if not available, use named wallet approach
        uint256 deployerPrivateKey;
        address deployer;
        bool usePrivateKey = false;

        try vm.envUint("PRIVATE_KEY") returns (uint256 key) {
            deployerPrivateKey = key;
            deployer = vm.addr(deployerPrivateKey);
            usePrivateKey = true;
        } catch {
            // PRIVATE_KEY not set, assume using --account flag
            deployer = msg.sender; // Will be set by --sender flag
        }

        console2.log("==============================================");
        console2.log("Flowra Protocol Deployment");
        console2.log("==============================================");
        console2.log("Deployer:", deployer);
        console2.log("Network: Arbitrum Mainnet (Chain ID: 42161)");
        console2.log("Method:", usePrivateKey ? "Private Key" : "Named Wallet");
        console2.log("==============================================\n");

        // Start broadcast (with or without private key)
        if (usePrivateKey) {
            vm.startBroadcast(deployerPrivateKey);
        } else {
            vm.startBroadcast(); // Uses --account wallet
        }

        // ============ Phase 1: Core Infrastructure ============
        console2.log("Phase 1: Deploying Core Infrastructure...\n");

        // 1. Deploy FlowraAaveVault
        console2.log("1. Deploying FlowraAaveVault...");
        aaveVault = new FlowraAaveVault(USDC, AAVE_POOL);
        console2.log("   FlowraAaveVault deployed at:", address(aaveVault));
        console2.log("");

        // 2. Deploy FlowraYieldRouter
        console2.log("2. Deploying FlowraYieldRouter...");
        yieldRouter = new FlowraYieldRouter(USDC);
        console2.log("   FlowraYieldRouter deployed at:", address(yieldRouter));
        console2.log("");

        // 3. Deploy FlowraCore
        console2.log("3. Deploying FlowraCore...");
        flowraCore = new FlowraCore(USDC, WETH, POOL_MANAGER);
        console2.log("   FlowraCore deployed at:", address(flowraCore));
        console2.log("");

        // ============ Phase 2: Configuration ============
        console2.log("Phase 2: Configuring Contracts...\n");

        // Set FlowraCore in AaveVault
        console2.log("4. Setting FlowraCore in AaveVault...");
        aaveVault.setFlowraCore(address(flowraCore));
        console2.log("   FlowraCore set successfully");
        console2.log("");

        // Set FlowraCore in YieldRouter
        console2.log("5. Setting FlowraCore in YieldRouter...");
        yieldRouter.setFlowraCore(address(flowraCore));
        console2.log("   FlowraCore set successfully");
        console2.log("");

        // Set AaveVault in FlowraCore
        console2.log("6. Setting AaveVault in FlowraCore...");
        flowraCore.setAaveVault(address(aaveVault));
        console2.log("   AaveVault set successfully");
        console2.log("");

        // Set YieldRouter in FlowraCore
        console2.log("7. Setting YieldRouter in FlowraCore...");
        flowraCore.setYieldRouter(address(yieldRouter));
        console2.log("   YieldRouter set successfully");
        console2.log("");

        // ============ Phase 3: Uniswap v4 Hook (Optional - when v4 is live) ============
        console2.log("Phase 3: Uniswap v4 Integration (Optional)...\n");
        console2.log("NOTE: Deploy FlowraHook when Uniswap v4 is available on Arbitrum");
        console2.log("      Use DeployHook.s.sol for hook deployment with CREATE2");
        console2.log("");

        vm.stopBroadcast();

        // ============ Deployment Summary ============
        console2.log("==============================================");
        console2.log("Deployment Complete!");
        console2.log("==============================================\n");

        console2.log("Contract Addresses:");
        console2.log("-------------------");
        console2.log("FlowraCore:        ", address(flowraCore));
        console2.log("FlowraAaveVault:   ", address(aaveVault));
        console2.log("FlowraYieldRouter: ", address(yieldRouter));
        console2.log("");

        console2.log("Network Addresses:");
        console2.log("-------------------");
        console2.log("USDC:              ", USDC);
        console2.log("WETH:              ", WETH);
        console2.log("Aave Pool:         ", AAVE_POOL);
        console2.log("Uniswap PoolMgr:   ", POOL_MANAGER);
        console2.log("");

        console2.log("Next Steps:");
        console2.log("-------------------");
        console2.log("1. Verify contracts on Arbiscan using Verify.s.sol");
        console2.log("2. Add projects to YieldRouter using AddProjects.s.sol");
        console2.log("3. Test with small deposit");
        console2.log("4. Deploy FlowraHook when Uniswap v4 is available");
        console2.log("==============================================\n");

        // Save deployment addresses to file
        _saveDeploymentInfo();
    }

    /**
     * @notice Save deployment info to JSON file
     */
    function _saveDeploymentInfo() internal {
        string memory json = "deployment";

        vm.serializeAddress(json, "flowraCore", address(flowraCore));
        vm.serializeAddress(json, "aaveVault", address(aaveVault));
        vm.serializeAddress(json, "yieldRouter", address(yieldRouter));
        vm.serializeAddress(json, "usdc", USDC);
        vm.serializeAddress(json, "weth", WETH);
        string memory finalJson = vm.serializeAddress(json, "aavePool", AAVE_POOL);

        vm.writeJson(finalJson, "./deployments/arbitrum-mainnet.json");

        console2.log("Deployment info saved to: deployments/arbitrum-mainnet.json");
    }
}
