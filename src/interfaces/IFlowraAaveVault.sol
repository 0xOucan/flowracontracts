// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IFlowraAaveVault
 * @notice Interface for Aave v3 integration and yield generation
 * @dev Manages USDC supply to Aave and yield tracking
 */
interface IFlowraAaveVault {
    /**
     * @notice Supply USDC to Aave v3
     * @param amount USDC amount to supply
     */
    function supplyToAave(uint256 amount) external;

    /**
     * @notice Withdraw USDC from Aave v3
     * @param amount USDC amount to withdraw
     * @return Actual amount withdrawn
     */
    function withdrawFromAave(uint256 amount) external returns (uint256);

    /**
     * @notice Get total yield earned from Aave
     * @return Total yield in USDC
     */
    function getYieldEarned() external view returns (uint256);

    /**
     * @notice Harvest yield for Octant distribution
     * @return yieldAmount Yield harvested
     */
    function harvestYield() external returns (uint256 yieldAmount);

    /**
     * @notice Get current Aave position details
     * @return supplied Total USDC supplied
     * @return aTokenBalance Current aToken balance
     * @return currentAPY Current Aave APY in basis points
     */
    function getAavePosition() external view returns (
        uint256 supplied,
        uint256 aTokenBalance,
        uint256 currentAPY
    );

    /**
     * @notice Get available liquidity in Aave
     * @return Available USDC to withdraw
     */
    function getAvailableLiquidity() external view returns (uint256);
}
