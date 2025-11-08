// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {FlowraCore} from "../src/FlowraCore.sol";
import {FlowraAaveVault} from "../src/FlowraAaveVault.sol";
import {FlowraYieldRouter} from "../src/FlowraYieldRouter.sol";
import {FlowraTypes} from "../src/libraries/FlowraTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FlowraCoreTest
 * @notice Tests for FlowraCore contract
 * @dev Fork tests against Arbitrum mainnet
 */
contract FlowraCoreTest is Test {
    // ============ Contracts ============
    FlowraCore public flowraCore;
    FlowraAaveVault public aaveVault;
    FlowraYieldRouter public yieldRouter;

    // ============ Tokens (Arbitrum mainnet) ============
    IERC20 public constant USDC = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    IERC20 public constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public constant AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address public constant POOL_MANAGER = 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32;

    // ============ Test Accounts ============
    address public owner;
    address public alice;
    address public bob;

    // ============ Constants ============
    uint256 public constant MIN_DEPOSIT = 100 * 10**6; // 100 USDC

    function setUp() public {
        // Create fork of Arbitrum mainnet
        vm.createSelectFork(vm.envString("ARBITRUM_RPC_URL"));

        // Setup accounts
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Deploy contracts
        aaveVault = new FlowraAaveVault(address(USDC), AAVE_POOL);
        yieldRouter = new FlowraYieldRouter(address(USDC));
        flowraCore = new FlowraCore(address(USDC), address(WETH), POOL_MANAGER);

        // Configure contracts
        aaveVault.setFlowraCore(address(flowraCore));
        yieldRouter.setFlowraCore(address(flowraCore));
        flowraCore.setAaveVault(address(aaveVault));
        flowraCore.setYieldRouter(address(yieldRouter));

        // Fund test accounts with USDC
        // Using deal to give USDC to test accounts
        deal(address(USDC), alice, 10000 * 10**6); // 10,000 USDC
        deal(address(USDC), bob, 10000 * 10**6);   // 10,000 USDC
    }

    // ============ Deposit Tests ============

    function test_Deposit_Success() public {
        uint256 depositAmount = 500 * 10**6; // 500 USDC
        uint256 donationPercent = 1000; // 10%
        uint256[] memory projects = new uint256[](2);
        projects[0] = 0; // Amazon
        projects[1] = 5; // Flowra

        vm.startPrank(alice);

        // Approve FlowraCore to spend USDC
        USDC.approve(address(flowraCore), depositAmount);

        // Deposit with user preferences
        bytes32 positionId = flowraCore.deposit(depositAmount, donationPercent, projects);

        vm.stopPrank();

        // Verify position created
        assertTrue(positionId != bytes32(0), "Position ID should not be zero");

        // Check position details using getPosition
        FlowraTypes.UserPosition memory position = flowraCore.getPosition(alice);

        assertEq(position.owner, alice, "Position owner should be Alice");
        assertEq(position.usdcDeposited, depositAmount, "Deposit amount mismatch");
        assertEq(position.wethAccumulated, 0, "WETH should be zero initially");
        assertEq(position.dailySwapAmount, depositAmount / 100, "Daily swap should be 1%");
        assertTrue(position.active, "Position should be active");
        assertEq(position.donationPercentBps, donationPercent, "Donation % mismatch");
        assertEq(position.selectedProjects.length, 2, "Should have 2 selected projects");
    }
}
