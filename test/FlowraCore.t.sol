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

        vm.startPrank(alice);

        // Approve FlowraCore to spend USDC
        USDC.approve(address(flowraCore), depositAmount);

        // Deposit
        bytes32 positionId = flowraCore.deposit(depositAmount);

        vm.stopPrank();

        // Verify position created
        assertTrue(positionId != bytes32(0), "Position ID should not be zero");

        // Check position details
        (
            address positionOwner,
            uint256 usdcDeposited,
            uint256 wethAccumulated,
            uint256 dailySwapAmount,
            ,
            ,
            ,
            bool active,

        ) = flowraCore.positions(alice);

        assertEq(positionOwner, alice, "Position owner should be Alice");
        assertEq(usdcDeposited, depositAmount, "Deposit amount mismatch");
        assertEq(wethAccumulated, 0, "WETH should be zero initially");
        assertEq(dailySwapAmount, depositAmount / 100, "Daily swap should be 1%");
        assertTrue(active, "Position should be active");
    }

    function test_Deposit_RevertIfBelowMinimum() public {
        uint256 depositAmount = 50 * 10**6; // 50 USDC (below minimum)

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);

        // Expect revert
        vm.expectRevert();
        flowraCore.deposit(depositAmount);

        vm.stopPrank();
    }

    function test_Deposit_RevertIfPositionExists() public {
        uint256 depositAmount = 500 * 10**6;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount * 2);

        // First deposit succeeds
        flowraCore.deposit(depositAmount);

        // Second deposit should fail
        vm.expectRevert();
        flowraCore.deposit(depositAmount);

        vm.stopPrank();
    }

    // ============ Withdraw Tests ============

    function test_Withdraw_Success() public {
        uint256 depositAmount = 500 * 10**6;

        // Alice deposits
        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);
        flowraCore.deposit(depositAmount);

        // Get Alice's USDC balance before withdrawal
        uint256 usdcBefore = USDC.balanceOf(alice);

        // Withdraw
        (uint256 usdcReturned, uint256 wethReturned) = flowraCore.withdraw();

        vm.stopPrank();

        // Verify withdrawal
        assertGt(usdcReturned, 0, "Should return USDC");
        assertEq(wethReturned, 0, "No WETH accumulated yet");
        assertEq(USDC.balanceOf(alice), usdcBefore + usdcReturned, "USDC balance mismatch");
    }

    function test_Withdraw_RevertIfNoPosition() public {
        vm.startPrank(alice);

        // Expect revert when withdrawing without position
        vm.expectRevert();
        flowraCore.withdraw();

        vm.stopPrank();
    }

    // ============ View Function Tests ============

    function test_CanSwap_False_Initially() public {
        uint256 depositAmount = 500 * 10**6;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);
        flowraCore.deposit(depositAmount);
        vm.stopPrank();

        // Should not be able to swap immediately (24h not passed)
        bool canSwap = flowraCore.canSwap(alice);
        assertFalse(canSwap, "Should not be able to swap immediately");
    }

    function test_CanSwap_True_After24Hours() public {
        uint256 depositAmount = 500 * 10**6;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);
        flowraCore.deposit(depositAmount);
        vm.stopPrank();

        // Fast forward 24 hours
        vm.warp(block.timestamp + 24 hours);

        // Should be able to swap now
        bool canSwap = flowraCore.canSwap(alice);
        assertTrue(canSwap, "Should be able to swap after 24h");
    }

    function test_GetProtocolStats() public {
        // Initial stats should be zero
        FlowraTypes.ProtocolStats memory stats = flowraCore.getProtocolStats();

        assertEq(stats.totalValueLocked, 0, "Initial TVL should be zero");
        assertEq(stats.totalSwapsExecuted, 0, "Initial swaps should be zero");
        assertEq(stats.totalYieldGenerated, 0, "Initial yield should be zero");
        assertEq(stats.activePositions, 0, "Initial positions should be zero");

        // After deposit, TVL should increase
        uint256 depositAmount = 500 * 10**6;
        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);
        flowraCore.deposit(depositAmount);
        vm.stopPrank();

        stats = flowraCore.getProtocolStats();
        assertEq(stats.totalValueLocked, depositAmount, "TVL should equal deposit");
        assertEq(stats.activePositions, 1, "Should have 1 active position");
    }

    // ============ Admin Function Tests ============

    function test_Pause_OnlyOwner() public {
        // Owner can pause
        flowraCore.pause();
        assertTrue(flowraCore.paused(), "Contract should be paused");

        // Non-owner cannot pause
        vm.startPrank(alice);
        vm.expectRevert();
        flowraCore.pause();
        vm.stopPrank();
    }

    function test_Deposit_RevertWhenPaused() public {
        // Pause contract
        flowraCore.pause();

        uint256 depositAmount = 500 * 10**6;
        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);

        // Deposit should fail when paused
        vm.expectRevert();
        flowraCore.deposit(depositAmount);

        vm.stopPrank();
    }

    // ============ Helper Functions ============

    function _dealUSDC(address to, uint256 amount) internal {
        deal(address(USDC), to, amount);
    }
}
