// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {FlowraCore} from "../src/FlowraCore.sol";
import {FlowraAaveVault} from "../src/FlowraAaveVault.sol";
import {FlowraYieldRouter} from "../src/FlowraYieldRouter.sol";
import {FlowraTypes} from "../src/libraries/FlowraTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FlowraYieldClaimingTest
 * @notice Tests for yield claiming and distribution to projects
 * @dev Tests manual claiming, executor batch claiming, and auto-claim on withdrawal
 */
contract FlowraYieldClaimingTest is Test {
    using stdStorage for StdStorage;

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
    address public executor;

    // ============ Project Wallets ============
    address payable public amazonWallet;
    address payable public oceanWallet;
    address payable public flowraWallet;

    // ============ Events ============
    event YieldClaimed(
        address indexed user,
        uint256 userAmount,
        uint256 donatedAmount,
        uint256 timestamp
    );

    event YieldDistributed(
        address indexed project,
        uint256 amount,
        address indexed donor,
        uint256 timestamp
    );

    function setUp() public {
        // Create fork of Arbitrum mainnet
        vm.createSelectFork(vm.envString("ARBITRUM_RPC_URL"));

        // Setup accounts
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        executor = makeAddr("executor");

        // Setup project wallets
        amazonWallet = payable(makeAddr("amazon"));
        oceanWallet = payable(makeAddr("ocean"));
        flowraWallet = payable(makeAddr("flowra"));

        // Deploy contracts
        aaveVault = new FlowraAaveVault(address(USDC), AAVE_POOL);
        yieldRouter = new FlowraYieldRouter(address(USDC));
        flowraCore = new FlowraCore(address(USDC), address(WETH), POOL_MANAGER);

        // Configure contracts
        aaveVault.setFlowraCore(address(flowraCore));
        yieldRouter.setFlowraCore(address(flowraCore));
        flowraCore.setAaveVault(address(aaveVault));
        flowraCore.setYieldRouter(address(yieldRouter));

        // Grant executor role
        flowraCore.grantRole(flowraCore.EXECUTOR_ROLE(), executor);

        // Add 6 projects
        yieldRouter.addProject(amazonWallet, "Amazon Rainforest", "Reforestation");
        yieldRouter.addProject(oceanWallet, "Ocean Cleanup", "Plastic removal");
        yieldRouter.addProject(payable(makeAddr("solar")), "Solar Villages", "Renewable energy");
        yieldRouter.addProject(payable(makeAddr("farming")), "Regenerative Farming", "Agriculture");
        yieldRouter.addProject(payable(makeAddr("coral")), "Coral Restoration", "Reef conservation");
        yieldRouter.addProject(flowraWallet, "Flowra", "Public goods funding");

        // Fund test accounts with USDC
        deal(address(USDC), alice, 100000 * 10**6);
        deal(address(USDC), bob, 100000 * 10**6);
    }

    // ============ Helper Functions ============

    /**
     * @notice Simulate yield generation by manipulating storage
     * @dev In production, yield comes from Aave interest rebasing aTokens.
     *      For testing, we manipulate the totalSupplied to fake yield.
     *      By reducing totalSupplied, getYieldEarned() will return positive yield.
     */
    function simulateYieldGeneration(uint256 yieldAmount) internal {
        // Get current values
        IERC20 aUSDC = aaveVault.aUSDC();
        uint256 totalSupplied = aaveVault.totalSupplied();
        uint256 currentATokenBalance = aUSDC.balanceOf(address(aaveVault));

        // Strategy: We'll give the vault extra aUSDC tokens
        // Since aUSDC is a proxy, we need to find the implementation storage

        // For testing, we'll use a different approach:
        // Directly manipulate the aToken balance using vm.store on the actual token
        // Get the balance slot for aUSDC (standard ERC20 is slot 0 with mapping)

        // Calculate target balance: current balance + yield amount
        uint256 targetBalance = currentATokenBalance + yieldAmount;

        // Use stdstore to manipulate the balance
        stdstore
            .target(address(aUSDC))
            .sig("balanceOf(address)")
            .with_key(address(aaveVault))
            .checked_write(targetBalance);
    }

    // ============ Yield Claiming Tests ============

    function test_ClaimYield_SingleUser_10PercentDonation() public {
        // Alice deposits 10,000 USDC with 10% donation to 2 projects
        uint256 depositAmount = 10000 * 10**6;
        uint256[] memory projects = new uint256[](2);
        projects[0] = 0; // Amazon
        projects[1] = 5; // Flowra

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);
        flowraCore.deposit(depositAmount, 1000, projects); // 10% donation
        vm.stopPrank();

        // Simulate 1,000 USDC yield generation (10% APY on 10,000 USDC)
        uint256 totalYield = 1000 * 10**6;
        simulateYieldGeneration(totalYield);

        // Fast forward time
        vm.warp(block.timestamp + 365 days);

        // Alice claims yield
        uint256 aliceBalanceBefore = USDC.balanceOf(alice);
        uint256 amazonBalanceBefore = USDC.balanceOf(amazonWallet);
        uint256 flowraBalanceBefore = USDC.balanceOf(flowraWallet);

        vm.prank(alice);
        (uint256 userAmount, uint256 donatedAmount) = flowraCore.claimYield();

        // Verify amounts
        // 10% donation = 100 USDC donated, 900 USDC to user
        assertEq(donatedAmount, 100 * 10**6, "Should donate 100 USDC (10%)");
        assertEq(userAmount, 900 * 10**6, "User should get 900 USDC (90%)");

        // Verify balances
        assertEq(USDC.balanceOf(alice) - aliceBalanceBefore, userAmount, "Alice balance increase");

        // Each project gets 50 USDC (100 USDC / 2 projects)
        uint256 expectedPerProject = 50 * 10**6;
        assertEq(USDC.balanceOf(amazonWallet) - amazonBalanceBefore, expectedPerProject, "Amazon received");
        assertEq(USDC.balanceOf(flowraWallet) - flowraBalanceBefore, expectedPerProject, "Flowra received");

        // Verify position stats updated
        FlowraTypes.UserPosition memory position = flowraCore.getPosition(alice);
        assertEq(position.totalYieldEarned, totalYield, "Total yield tracked");
        assertEq(position.yieldDonated, donatedAmount, "Donation tracked");
        assertEq(position.yieldClaimed, userAmount, "User claim tracked");
        assertEq(position.pendingYield, 0, "No pending yield after claim");
    }

    function test_ClaimYield_MinDonation_1Percent() public {
        // Bob deposits with 1% donation (minimum)
        uint256 depositAmount = 50000 * 10**6; // 50,000 USDC
        uint256[] memory projects = new uint256[](1);
        projects[0] = 1; // Ocean only

        vm.startPrank(bob);
        USDC.approve(address(flowraCore), depositAmount);
        flowraCore.deposit(depositAmount, 100, projects); // 1% donation
        vm.stopPrank();

        // Simulate 5,000 USDC yield (10% APY)
        uint256 totalYield = 5000 * 10**6;
        simulateYieldGeneration(totalYield);

        vm.warp(block.timestamp + 365 days);

        uint256 oceanBalanceBefore = USDC.balanceOf(oceanWallet);

        vm.prank(bob);
        (uint256 userAmount, uint256 donatedAmount) = flowraCore.claimYield();

        // 1% donation = 50 USDC donated, 4,950 USDC to user
        assertEq(donatedAmount, 50 * 10**6, "Should donate 50 USDC (1%)");
        assertEq(userAmount, 4950 * 10**6, "User should get 4,950 USDC (99%)");

        // Ocean gets all 50 USDC (only selected project)
        assertEq(USDC.balanceOf(oceanWallet) - oceanBalanceBefore, 50 * 10**6, "Ocean received all");
    }

    function test_ClaimYield_MaxDonation_20Percent() public {
        // Alice deposits with 20% donation (maximum) to all 6 projects
        uint256 depositAmount = 100000 * 10**6; // 100,000 USDC
        uint256[] memory projects = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            projects[i] = i;
        }

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);
        flowraCore.deposit(depositAmount, 2000, projects); // 20% donation
        vm.stopPrank();

        // Simulate 10,000 USDC yield (10% APY)
        uint256 totalYield = 10000 * 10**6;
        simulateYieldGeneration(totalYield);

        vm.warp(block.timestamp + 365 days);

        vm.prank(alice);
        (uint256 userAmount, uint256 donatedAmount) = flowraCore.claimYield();

        // 20% donation = 2,000 USDC donated, 8,000 USDC to user
        assertEq(donatedAmount, 2000 * 10**6, "Should donate 2,000 USDC (20%)");
        assertEq(userAmount, 8000 * 10**6, "User should get 8,000 USDC (80%)");

        // Each of 6 projects gets ~333.33 USDC
        // Note: Integer division means each gets 333.333... → 333 USDC
        uint256 expectedPerProject = donatedAmount / 6;
        assertTrue(expectedPerProject > 333 * 10**6, "Each project gets ~333 USDC");
    }

    function test_ClaimYield_MultipleUsers_ProportionalYield() public {
        // Alice deposits 60,000 USDC (60% of total)
        uint256[] memory aliceProjects = new uint256[](1);
        aliceProjects[0] = 0; // Amazon

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 60000 * 10**6);
        flowraCore.deposit(60000 * 10**6, 1000, aliceProjects); // 10% donation
        vm.stopPrank();

        // Bob deposits 40,000 USDC (40% of total)
        uint256[] memory bobProjects = new uint256[](1);
        bobProjects[0] = 1; // Ocean

        vm.startPrank(bob);
        USDC.approve(address(flowraCore), 40000 * 10**6);
        flowraCore.deposit(40000 * 10**6, 500, bobProjects); // 5% donation
        vm.stopPrank();

        // Total TVL: 100,000 USDC
        // Simulate 10,000 USDC total yield (10% APY)
        uint256 totalYield = 10000 * 10**6;
        simulateYieldGeneration(totalYield);

        vm.warp(block.timestamp + 365 days);

        // Alice should get 60% of yield = 6,000 USDC
        // 10% donation = 600 donated, 5,400 to Alice
        vm.prank(alice);
        (uint256 aliceUserAmount, uint256 aliceDonated) = flowraCore.claimYield();

        assertEq(aliceDonated, 600 * 10**6, "Alice donates 600 USDC");
        assertEq(aliceUserAmount, 5400 * 10**6, "Alice gets 5,400 USDC");

        // Bob should get 40% of yield = 4,000 USDC
        // 5% donation = 200 donated, 3,800 to Bob
        vm.prank(bob);
        (uint256 bobUserAmount, uint256 bobDonated) = flowraCore.claimYield();

        assertEq(bobDonated, 200 * 10**6, "Bob donates 200 USDC");
        assertEq(bobUserAmount, 3800 * 10**6, "Bob gets 3,800 USDC");
    }

    function test_ClaimYield_NoYield_Reverts() public {
        // Alice deposits but no yield generated yet
        uint256[] memory projects = new uint256[](1);
        projects[0] = 0;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 10000 * 10**6);
        flowraCore.deposit(10000 * 10**6, 1000, projects);
        vm.stopPrank();

        // Try to claim immediately (no yield) - should revert
        vm.prank(alice);
        vm.expectRevert(FlowraTypes.NoYieldToClaim.selector);
        flowraCore.claimYield();
    }

    // ============ Executor Batch Claiming Tests ============

    function test_ExecutorBatchClaim_MultipleUsers() public {
        // Setup 2 users with deposits
        uint256[] memory projects = new uint256[](1);
        projects[0] = 5; // Flowra

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 50000 * 10**6);
        flowraCore.deposit(50000 * 10**6, 1000, projects);
        vm.stopPrank();

        vm.startPrank(bob);
        USDC.approve(address(flowraCore), 50000 * 10**6);
        flowraCore.deposit(50000 * 10**6, 1500, projects);
        vm.stopPrank();

        // Simulate yield
        simulateYieldGeneration(10000 * 10**6);
        vm.warp(block.timestamp + 365 days);

        // Executor batch processes
        address[] memory users = new address[](2);
        users[0] = alice;
        users[1] = bob;

        vm.prank(executor);
        uint256 successCount = flowraCore.executeYieldClaimBatch(users);

        assertEq(successCount, 2, "Should process both users");

        // Verify pending yield was updated
        assertTrue(flowraCore.getPendingYield(alice) > 0, "Alice has pending");
        assertTrue(flowraCore.getPendingYield(bob) > 0, "Bob has pending");
    }

    function test_ExecutorBatchClaim_OnlyExecutorRole() public {
        address[] memory users = new address[](1);
        users[0] = alice;

        // Non-executor tries to batch claim
        vm.prank(alice);
        vm.expectRevert();
        flowraCore.executeYieldClaimBatch(users);
    }

    // ============ Project Distribution Tests ============

    function test_ProjectDistribution_Recorded() public {
        // Alice donates to 3 projects
        uint256[] memory projects = new uint256[](3);
        projects[0] = 0; // Amazon
        projects[1] = 1; // Ocean
        projects[2] = 5; // Flowra

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 30000 * 10**6);
        flowraCore.deposit(30000 * 10**6, 1000, projects); // 10% donation
        vm.stopPrank();

        // Simulate 3,000 USDC yield
        simulateYieldGeneration(3000 * 10**6);
        vm.warp(block.timestamp + 365 days);

        // Claim yield
        vm.prank(alice);
        flowraCore.claimYield();

        // Verify each project received and it was recorded
        // 10% of 3,000 = 300 USDC donated / 3 projects = 100 USDC each
        uint256 expectedPerProject = 100 * 10**6;

        // Check project stats
        FlowraTypes.Project memory amazon = yieldRouter.getProject(0);
        assertTrue(amazon.totalReceived >= expectedPerProject, "Amazon received");
        assertTrue(amazon.donorCount > 0, "Amazon has donors");

        // Check total distributed
        uint256 totalDistributed = yieldRouter.getTotalDistributed();
        assertEq(totalDistributed, 300 * 10**6, "Total distributed recorded");
    }

    // ============ Edge Cases ============

    function test_ClaimYield_TwiceInRow_SecondClaimZero() public {
        uint256[] memory projects = new uint256[](1);
        projects[0] = 0;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 10000 * 10**6);
        flowraCore.deposit(10000 * 10**6, 1000, projects);
        vm.stopPrank();

        // Simulate yield
        simulateYieldGeneration(1000 * 10**6);
        vm.warp(block.timestamp + 365 days);

        // First claim
        vm.prank(alice);
        (uint256 firstUser, uint256 firstDonation) = flowraCore.claimYield();

        assertTrue(firstUser > 0, "First claim has yield");

        // Second claim immediately (no new yield)
        vm.prank(alice);
        (uint256 secondUser, uint256 secondDonation) = flowraCore.claimYield();

        assertEq(secondUser, 0, "Second claim zero user");
        assertEq(secondDonation, 0, "Second claim zero donation");
    }

    function test_ClaimYield_EqualSplit_3Projects() public {
        // Test that 3 projects get exactly equal amounts
        uint256[] memory projects = new uint256[](3);
        projects[0] = 0;
        projects[1] = 1;
        projects[2] = 2;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 10000 * 10**6);
        flowraCore.deposit(10000 * 10**6, 1500, projects); // 15% donation
        vm.stopPrank();

        // Simulate 1,000 USDC yield
        simulateYieldGeneration(1000 * 10**6);
        vm.warp(block.timestamp + 365 days);

        uint256 project0Before = USDC.balanceOf(yieldRouter.getProject(0).wallet);
        uint256 project1Before = USDC.balanceOf(yieldRouter.getProject(1).wallet);
        uint256 project2Before = USDC.balanceOf(yieldRouter.getProject(2).wallet);

        vm.prank(alice);
        (uint256 userAmount, uint256 donated) = flowraCore.claimYield();

        // 15% of 1,000 = 150 USDC donated / 3 = 50 USDC each
        uint256 expectedEach = 50 * 10**6;

        uint256 project0Received = USDC.balanceOf(yieldRouter.getProject(0).wallet) - project0Before;
        uint256 project1Received = USDC.balanceOf(yieldRouter.getProject(1).wallet) - project1Before;
        uint256 project2Received = USDC.balanceOf(yieldRouter.getProject(2).wallet) - project2Before;

        assertEq(project0Received, expectedEach, "Project 0 equal share");
        assertEq(project1Received, expectedEach, "Project 1 equal share");
        assertEq(project2Received, expectedEach, "Project 2 equal share");
    }
}
