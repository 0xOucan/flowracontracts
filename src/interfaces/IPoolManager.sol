// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "../libraries/FlowraTypes.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";

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
    /// @return swapDelta The balance delta from the swap
    function swap(
        PoolKey memory key,
        SwapParams memory params,
        bytes calldata hookData
    ) external returns (BalanceDelta swapDelta);

    /// @notice Unlock the pool manager for callback execution
    /// @param data Data to pass to the callback
    /// @return The return data from the callback
    function unlock(bytes calldata data) external returns (bytes memory);

    /// @notice Settle (pay) a currency to the pool manager
    /// @param currency The currency to settle
    /// @return paid The amount paid
    function settle(Currency currency) external payable returns (uint256 paid);

    /// @notice Take (receive) a currency from the pool manager
    /// @param currency The currency to take
    /// @param to The address to send the currency to
    /// @param amount The amount to take
    function take(Currency currency, address to, uint256 amount) external;
}
