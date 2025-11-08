// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "../libraries/FlowraTypes.sol";

/// @notice Minimal Uniswap v4 PoolManager interface for swap execution
/// @dev Only includes functions needed for Flowra DCA swaps
interface IPoolManager {
    /// @notice Swap parameters
    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Pool key structure
    struct PoolKey {
        Currency currency0;
        Currency currency1;
        uint24 fee;
        int24 tickSpacing;
        address hooks;
    }

    /// @notice Execute a swap
    /// @param key The pool key
    /// @param params The swap parameters
    /// @param hookData Optional data to pass to hooks
    /// @return delta The balance delta from the swap
    function swap(
        PoolKey memory key,
        SwapParams memory params,
        bytes calldata hookData
    ) external returns (int256 delta);

    /// @notice Unlock the pool manager for callback execution
    /// @param data Data to pass to the callback
    /// @return The return data from the callback
    function unlock(bytes calldata data) external returns (bytes memory);
}
