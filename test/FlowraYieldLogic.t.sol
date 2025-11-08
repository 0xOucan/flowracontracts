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
 * @title FlowraYieldLogicTest
 * @notice Unit tests for yield donation logic and calculations
 * @dev Tests the mathematical logic without full Aave integration
 */
contract FlowraYieldLogicTest is Test {
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

    // ============ Project Wallets ============
    address payable public amazonWallet;
    address payable public flowraWallet;

    function setUp() public {
        // Create fork of Arbitrum mainnet
        vm.createSelectFork(vm.envString("ARBITRUM_RPC_URL"));

        // Setup accounts
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Setup project wallets
        amazonWallet = payable(makeAddr("amazon"));
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

        // Add 6 projects
        yieldRouter.addProject(amazonWallet, "Amazon", "Rainforest");
        yieldRouter.addProject(payable(makeAddr("ocean")), "Ocean", "Cleanup");
        yieldRouter.addProject(payable(makeAddr("solar")), "Solar", "Energy");
        yieldRouter.addProject(payable(makeAddr("farming")), "Farming", "Regenerative");
        yieldRouter.addProject(payable(makeAddr("coral")), "Coral", "Restoration");
        yieldRouter.addProject(flowraWallet, "Flowra", "Public goods");

        // Fund test accounts
        deal(address(USDC), alice, 100000 * 10**6);
        deal(address(USDC), bob, 100000 * 10**6);
    }

    // ============ Donation Percentage Tests ============

    function test_DonationPercentage_1Percent() public {
        // Test that 1% donation is correctly stored
        uint256[] memory projects = new uint256[](1);
        projects[0] = 0;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 10000 * 10**6);
        flowraCore.deposit(10000 * 10**6, 100, projects); // 1% = 100 BPS
        vm.stopPrank();

        assertEq(flowraCore.getUserDonationPercent(alice), 100, "Should be 1%");
    }

    function test_DonationPercentage_20Percent() public {
        // Test that 20% donation is correctly stored
        uint256[] memory projects = new uint256[](1);
        projects[0] = 5;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 10000 * 10**6);
        flowraCore.deposit(10000 * 10**6, 2000, projects); // 20% = 2000 BPS
        vm.stopPrank();

        assertEq(flowraCore.getUserDonationPercent(alice), 2000, "Should be 20%");
    }

    function test_DonationPercentage_Midpoint_10Percent() public {
        // Test midpoint: 10%
        uint256[] memory projects = new uint256[](2);
        projects[0] = 0;
        projects[1] = 5;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 50000 * 10**6);
        flowraCore.deposit(50000 * 10**6, 1000, projects); // 10% = 1000 BPS
        vm.stopPrank();

        assertEq(flowraCore.getUserDonationPercent(alice), 1000, "Should be 10%");
    }

    // ============ Project Selection Tests ============

    function test_ProjectSelection_Single() public {
        uint256[] memory projects = new uint256[](1);
        projects[0] = 3; // Farming

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 10000 * 10**6);
        flowraCore.deposit(10000 * 10**6, 500, projects);
        vm.stopPrank();

        uint256[] memory selected = flowraCore.getUserSelectedProjects(alice);
        assertEq(selected.length, 1, "Should have 1 project");
        assertEq(selected[0], 3, "Should be project 3");
    }

    function test_ProjectSelection_Multiple() public {
        uint256[] memory projects = new uint256[](4);
        projects[0] = 0; // Amazon
        projects[1] = 2; // Solar
        projects[2] = 4; // Coral
        projects[3] = 5; // Flowra

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 20000 * 10**6);
        flowraCore.deposit(20000 * 10**6, 1500, projects);
        vm.stopPrank();

        uint256[] memory selected = flowraCore.getUserSelectedProjects(alice);
        assertEq(selected.length, 4, "Should have 4 projects");
        assertEq(selected[0], 0, "Project 0");
        assertEq(selected[1], 2, "Project 2");
        assertEq(selected[2], 4, "Project 4");
        assertEq(selected[3], 5, "Project 5");
    }

    function test_ProjectSelection_AllSix() public {
        uint256[] memory projects = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            projects[i] = i;
        }

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 100000 * 10**6);
        flowraCore.deposit(100000 * 10**6, 2000, projects);
        vm.stopPrank();

        uint256[] memory selected = flowraCore.getUserSelectedProjects(alice);
        assertEq(selected.length, 6, "Should have all 6 projects");
    }

    // ============ Yield Calculation Tests (No Aave) ============

    function test_YieldCalculation_SingleUser() public {
        // Alice deposits 10,000 USDC
        uint256[] memory projects = new uint256[](1);
        projects[0] = 0;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 10000 * 10**6);
        flowraCore.deposit(10000 * 10**6, 1000, projects);
        vm.stopPrank();

        // Check that initial pending yield is 0
        uint256 pending = flowraCore.getPendingYield(alice);
        assertEq(pending, 0, "Should have no yield initially");
    }

    function test_YieldCalculation_MultipleUsers_Proportional() public {
        // Alice deposits 60,000 USDC (60% of total)
        uint256[] memory aliceProjects = new uint256[](1);
        aliceProjects[0] = 0;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 60000 * 10**6);
        flowraCore.deposit(60000 * 10**6, 1000, aliceProjects);
        vm.stopPrank();

        // Bob deposits 40,000 USDC (40% of total)
        uint256[] memory bobProjects = new uint256[](1);
        bobProjects[0] = 1;

        vm.startPrank(bob);
        USDC.approve(address(flowraCore), 40000 * 10**6);
        flowraCore.deposit(40000 * 10**6, 500, bobProjects);
        vm.stopPrank();

        // Verify both users' positions
        FlowraTypes.UserPosition memory alicePos = flowraCore.getPosition(alice);
        FlowraTypes.UserPosition memory bobPos = flowraCore.getPosition(bob);

        assertEq(alicePos.usdcDeposited, 60000 * 10**6, "Alice deposit");
        assertEq(bobPos.usdcDeposited, 40000 * 10**6, "Bob deposit");

        // Verify TVL
        uint256 tvl = flowraCore.totalValueLocked();
        assertEq(tvl, 100000 * 10**6, "TVL should be 100,000 USDC");
    }

    // ============ View Function Tests ============

    function test_GetAllProjects() public {
        FlowraTypes.Project[] memory projects = yieldRouter.getAllProjects();
        assertEq(projects.length, 6, "Should have 6 projects");
        assertEq(projects[0].name, "Amazon", "Project 0 name");
        assertEq(projects[5].name, "Flowra", "Project 5 name");
    }

    function test_GetProjectById() public {
        FlowraTypes.Project memory project = yieldRouter.getProjectById(5);
        assertEq(project.name, "Flowra", "Should be Flowra");
        assertEq(project.wallet, flowraWallet, "Wallet match");
        assertTrue(project.active, "Should be active");
    }

    function test_GetProjectDistribution_Initial() public {
        uint256 distribution = yieldRouter.getProjectDistribution(amazonWallet);
        assertEq(distribution, 0, "Should have no distribution initially");
    }

    function test_GetTotalDistributed_Initial() public {
        uint256 total = yieldRouter.getTotalDistributed();
        assertEq(total, 0, "Should have no distributions initially");
    }

    // ============ Position Tracking Tests ============

    function test_PositionTracking_YieldStats() public {
        uint256[] memory projects = new uint256[](1);
        projects[0] = 0;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 10000 * 10**6);
        flowraCore.deposit(10000 * 10**6, 1000, projects);
        vm.stopPrank();

        FlowraTypes.UserPosition memory position = flowraCore.getPosition(alice);

        // Verify initial yield stats are zero
        assertEq(position.totalYieldEarned, 0, "No yield earned yet");
        assertEq(position.yieldDonated, 0, "No yield donated yet");
        assertEq(position.yieldClaimed, 0, "No yield claimed yet");
        assertEq(position.pendingYield, 0, "No pending yield");
    }

    function test_PositionTracking_DonationPreferences() public {
        uint256[] memory projects = new uint256[](3);
        projects[0] = 1;
        projects[1] = 3;
        projects[2] = 5;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 50000 * 10**6);
        flowraCore.deposit(50000 * 10**6, 1500, projects); // 15%
        vm.stopPrank();

        FlowraTypes.UserPosition memory position = flowraCore.getPosition(alice);

        assertEq(position.donationPercentBps, 1500, "Donation should be 15%");
        assertEq(position.selectedProjects.length, 3, "Should have 3 projects");
        assertEq(position.selectedProjects[0], 1, "Project 1");
        assertEq(position.selectedProjects[1], 3, "Project 3");
        assertEq(position.selectedProjects[2], 5, "Project 5");
    }

    // ============ Math Calculation Tests ============

    function test_DonationMath_10Percent() public pure {
        // If user has 1000 USDC yield and donates 10%, they should get:
        // Donated: 1000 * 1000 / 10000 = 100 USDC
        // User keeps: 1000 - 100 = 900 USDC

        uint256 totalYield = 1000 * 10**6;
        uint256 donationBps = 1000; // 10%

        uint256 donated = (totalYield * donationBps) / 10000;
        uint256 userGets = totalYield - donated;

        assertEq(donated, 100 * 10**6, "Should donate 100 USDC");
        assertEq(userGets, 900 * 10**6, "User gets 900 USDC");
    }

    function test_DonationMath_1Percent() public pure {
        // 1% donation on 5000 USDC yield
        uint256 totalYield = 5000 * 10**6;
        uint256 donationBps = 100; // 1%

        uint256 donated = (totalYield * donationBps) / 10000;
        uint256 userGets = totalYield - donated;

        assertEq(donated, 50 * 10**6, "Should donate 50 USDC (1%)");
        assertEq(userGets, 4950 * 10**6, "User gets 4,950 USDC (99%)");
    }

    function test_DonationMath_20Percent() public pure {
        // 20% donation on 10,000 USDC yield
        uint256 totalYield = 10000 * 10**6;
        uint256 donationBps = 2000; // 20%

        uint256 donated = (totalYield * donationBps) / 10000;
        uint256 userGets = totalYield - donated;

        assertEq(donated, 2000 * 10**6, "Should donate 2,000 USDC (20%)");
        assertEq(userGets, 8000 * 10**6, "User gets 8,000 USDC (80%)");
    }

    function test_ProjectSplit_3Projects() public pure {
        // 150 USDC donated to 3 projects = 50 USDC each
        uint256 totalDonation = 150 * 10**6;
        uint256 numProjects = 3;

        uint256 perProject = totalDonation / numProjects;

        assertEq(perProject, 50 * 10**6, "Each project gets 50 USDC");
    }

    function test_ProjectSplit_6Projects() public pure {
        // 600 USDC donated to 6 projects = 100 USDC each
        uint256 totalDonation = 600 * 10**6;
        uint256 numProjects = 6;

        uint256 perProject = totalDonation / numProjects;

        assertEq(perProject, 100 * 10**6, "Each project gets 100 USDC");
    }
}
