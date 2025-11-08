// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {FlowraHook} from "../src/FlowraHook.sol";

/**
 * @title SetPoolKey
 * @notice Set the USDC/WETH pool key in FlowraHook
 * @dev This connects FlowraHook to the live Uniswap v4 pool
 *
 * Usage:
 *   forge script script/SetPoolKey.s.sol \
 *     --rpc-url $ARBITRUM_RPC_URL \
 *     --account monad-deployer \
 *     --sender $DEPLOYER_ADDRESS \
 *     --broadcast
 */
contract SetPoolKey is Script {
    // USDC/WETH pool key on Arbitrum (from https://app.uniswap.org/explore/pools/arbitrum/)
    bytes32 constant POOL_KEY = 0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8;

    function run() external {
        console.log("==============================================");
        console.log("Setting Pool Key in FlowraHook");
        console.log("==============================================");
        console.log("Deployer:", msg.sender);
        console.log("Network: Arbitrum Mainnet (Chain ID: 42161)");
        console.log("==============================================\n");

        // Load FlowraHook address from deployment file
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/arbitrum-hook.json");
        string memory json = vm.readFile(path);

        address flowraHook = vm.parseJsonAddress(json, ".flowraHook");

        console.log("FlowraHook:", flowraHook);
        console.log("Pool Key:");
        console.logBytes32(POOL_KEY);
        console.log("");

        vm.startBroadcast();

        console.log("Setting pool key in FlowraHook...");
        FlowraHook(flowraHook).setPoolKey(POOL_KEY);
        console.log("[SUCCESS] Pool key set!");
        console.log("");

        vm.stopBroadcast();

        console.log("==============================================");
        console.log("Pool Key Configuration Complete!");
        console.log("==============================================\n");

        console.log("Pool Details:");
        console.log("  Pair:        USDC/WETH");
        console.log("  Network:     Arbitrum One");
        console.log("  Pool Key:");
        console.logBytes32(POOL_KEY);
        console.log("");

        console.log("View Pool on Uniswap:");
        console.log("  https://app.uniswap.org/explore/pools/arbitrum/0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8");
        console.log("");

        console.log("Next Steps:");
        console.log("  1. Test with small DCA deposit (100-500 USDC)");
        console.log("  2. Wait 24 hours for first swap eligibility");
        console.log("  3. Monitor swap queue for automated execution");
        console.log("  4. Update frontend with contract addresses");
        console.log("==============================================\n");
    }
}
