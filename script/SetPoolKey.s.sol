// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {FlowraHook} from "../src/FlowraHook.sol";
import {FlowraCore} from "../src/FlowraCore.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {Currency} from "../src/libraries/FlowraTypes.sol";

/**
 * @title SetPoolKey
 * @notice Set the USDC/WETH pool key in both FlowraCore and FlowraHook
 * @dev This connects Flowra to the live Uniswap v4 pool for swap execution
 *
 * Usage:
 *   forge script script/SetPoolKey.s.sol \
 *     --rpc-url $ARBITRUM_RPC_URL \
 *     --account monad-deployer \
 *     --sender $DEPLOYER_ADDRESS \
 *     --broadcast
 */
contract SetPoolKey is Script {
    // Arbitrum mainnet addresses
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    // Pool configuration (0.3% fee tier is standard for USDC/WETH)
    uint24 constant FEE = 3000; // 0.3%
    int24 constant TICK_SPACING = 60; // Standard for 0.3% pools

    // USDC/WETH pool key hash on Arbitrum (for FlowraHook)
    bytes32 constant POOL_KEY_HASH = 0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8;

    function run() external {
        console.log("==============================================");
        console.log("Setting Pool Key in FlowraCore & FlowraHook");
        console.log("==============================================");
        console.log("Deployer:", msg.sender);
        console.log("Network: Arbitrum Mainnet (Chain ID: 42161)");
        console.log("==============================================\n");

        // Load deployment addresses
        string memory root = vm.projectRoot();

        // Load FlowraCore address
        string memory mainnetPath = string.concat(root, "/deployments/arbitrum-mainnet.json");
        string memory mainnetJson = vm.readFile(mainnetPath);
        address flowraCore = vm.parseJsonAddress(mainnetJson, ".flowraCore");

        // Load FlowraHook address
        string memory hookPath = string.concat(root, "/deployments/arbitrum-hook.json");
        string memory hookJson = vm.readFile(hookPath);
        address flowraHook = vm.parseJsonAddress(hookJson, ".flowraHook");

        console.log("FlowraCore:  ", flowraCore);
        console.log("FlowraHook:  ", flowraHook);
        console.log("USDC:        ", USDC);
        console.log("WETH:        ", WETH);
        console.log("Fee:         ", FEE, "(0.3%)");
        console.log("Tick Spacing:", uint256(int256(TICK_SPACING)));
        console.log("Pool Key Hash:");
        console.logBytes32(POOL_KEY_HASH);
        console.log("");

        vm.startBroadcast();

        // Step 1: Set pool key in FlowraCore (struct format)
        console.log("Step 1: Setting pool key in FlowraCore...");
        IPoolManager.PoolKey memory poolKey = IPoolManager.PoolKey({
            currency0: Currency.wrap(USDC),
            currency1: Currency.wrap(WETH),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: flowraHook
        });
        FlowraCore(flowraCore).setPoolKey(poolKey);
        console.log("[SUCCESS] FlowraCore pool key set!");
        console.log("");

        // Step 2: Set pool key in FlowraHook (bytes32 hash format)
        console.log("Step 2: Setting pool key in FlowraHook...");
        FlowraHook(flowraHook).setPoolKey(POOL_KEY_HASH);
        console.log("[SUCCESS] FlowraHook pool key set!");
        console.log("");

        vm.stopBroadcast();

        console.log("==============================================");
        console.log("Pool Key Configuration Complete!");
        console.log("==============================================\n");

        console.log("Pool Details:");
        console.log("  Pair:        USDC/WETH");
        console.log("  Network:     Arbitrum One");
        console.log("  Pool Key:");
        console.logBytes32(POOL_KEY_HASH);
        console.log("");

        console.log("View Pool on Uniswap:");
        console.log("  https://app.uniswap.org/explore/pools/arbitrum/0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8");
        console.log("");

        console.log("Next Steps:");
        console.log("  1. Test with small DCA deposit (100-500 USDC)");
        console.log("  2. Wait 5 minutes for first swap eligibility (testing mode)");
        console.log("  3. Monitor swap queue for automated execution");
        console.log("  4. Update frontend with contract addresses");
        console.log("");
        console.log("Timing:");
        console.log("  Testing:    5-minute intervals (~8.3 hours total)");
        console.log("  Production: 24-hour intervals (~100 days total)");
        console.log("==============================================\n");
    }
}
