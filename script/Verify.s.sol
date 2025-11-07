// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

/**
 * @title Verify
 * @notice Script to verify deployed contracts on Arbiscan
 * @dev Uses forge verify-contract command
 *
 * Usage:
 * forge script script/Verify.s.sol --rpc-url $ARBITRUM_RPC_URL
 *
 * Or manually verify each contract:
 * forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> \
 *   --chain-id 42161 \
 *   --constructor-args $(cast abi-encode "constructor(address,address)" <ARG1> <ARG2>) \
 *   --etherscan-api-key $ARBISCAN_API_KEY \
 *   --watch
 */
contract Verify is Script {
    // Arbitrum addresses
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    function run() external view {
        // Load deployment info
        string memory deploymentJson = vm.readFile("./deployments/arbitrum-mainnet.json");

        address flowraCoreAddr = vm.parseJsonAddress(deploymentJson, ".flowraCore");
        address aaveVaultAddr = vm.parseJsonAddress(deploymentJson, ".aaveVault");
        address yieldRouterAddr = vm.parseJsonAddress(deploymentJson, ".yieldRouter");

        console2.log("==============================================");
        console2.log("Flowra Protocol Contract Verification");
        console2.log("==============================================\n");

        console2.log("Run these commands to verify contracts:\n");

        // Verify FlowraCore
        console2.log("1. Verify FlowraCore:");
        console2.log("-------------------");
        _printVerifyCommand(
            "FlowraCore",
            flowraCoreAddr,
            _encodeConstructorArgs(USDC, WETH)
        );
        console2.log("");

        // Verify FlowraAaveVault
        console2.log("2. Verify FlowraAaveVault:");
        console2.log("-------------------");
        _printVerifyCommand(
            "FlowraAaveVault",
            aaveVaultAddr,
            _encodeConstructorArgs(USDC, AAVE_POOL)
        );
        console2.log("");

        // Verify FlowraYieldRouter
        console2.log("3. Verify FlowraYieldRouter:");
        console2.log("-------------------");
        _printVerifyCommand(
            "FlowraYieldRouter",
            yieldRouterAddr,
            _encodeConstructorArgsSingle(USDC)
        );
        console2.log("");

        console2.log("==============================================");
        console2.log("Verification Links");
        console2.log("==============================================\n");

        console2.log("After verification, view contracts at:");
        console2.log("FlowraCore:        https://arbiscan.io/address/", vm.toString(flowraCoreAddr));
        console2.log("FlowraAaveVault:   https://arbiscan.io/address/", vm.toString(aaveVaultAddr));
        console2.log("FlowraYieldRouter: https://arbiscan.io/address/", vm.toString(yieldRouterAddr));
        console2.log("");
    }

    function _printVerifyCommand(
        string memory contractName,
        address contractAddress,
        string memory constructorArgs
    ) internal view {
        console2.log("forge verify-contract \\");
        console2.log("  ", vm.toString(contractAddress), "\\");
        console2.log("  ", string.concat("src/", contractName, ".sol:", contractName), "\\");
        console2.log("  --chain-id 42161 \\");
        console2.log("  --constructor-args", constructorArgs, "\\");
        console2.log("  --etherscan-api-key $ARBISCAN_API_KEY \\");
        console2.log("  --watch");
    }

    function _encodeConstructorArgs(
        address arg1,
        address arg2
    ) internal pure returns (string memory) {
        bytes memory encoded = abi.encode(arg1, arg2);
        return vm.toString(encoded);
    }

    function _encodeConstructorArgsSingle(
        address arg1
    ) internal pure returns (string memory) {
        bytes memory encoded = abi.encode(arg1);
        return vm.toString(encoded);
    }
}
