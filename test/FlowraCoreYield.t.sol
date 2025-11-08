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
 * @title FlowraCoreYieldTest
 * @notice Comprehensive tests for user-controlled yield donations
 * @dev Tests the new 1-20% donation model with 6 projects
 */
contract FlowraCoreYieldTest is Test {
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
    address public charlie;
    address public executor;

    // ============ Project Wallets ============
    address payable public amazonWallet;
    address payable public oceanWallet;
    address payable public solarWallet;
    address payable public farmingWallet;
    address payable public coralWallet;
    address payable public flowraWallet;

    function setUp() public {
        // Create fork of Arbitrum mainnet
        vm.createSelectFork(vm.envString("ARBITRUM_RPC_URL"));

        // Setup accounts
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        executor = makeAddr("executor");

        // Setup project wallets
        amazonWallet = payable(makeAddr("amazon"));
        oceanWallet = payable(makeAddr("ocean"));
        solarWallet = payable(makeAddr("solar"));
        farmingWallet = payable(makeAddr("farming"));
        coralWallet = payable(makeAddr("coral"));
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
        yieldRouter.addProject(amazonWallet, "Amazon Rainforest", "Reforestation in Brazil");
        yieldRouter.addProject(oceanWallet, "Ocean Cleanup", "Pacific plastic removal");
        yieldRouter.addProject(solarWallet, "Solar Villages", "Renewable energy in Kenya");
        yieldRouter.addProject(farmingWallet, "Regenerative Farming", "Sustainable agriculture in India");
        yieldRouter.addProject(coralWallet, "Coral Restoration", "Great Barrier Reef conservation");
        yieldRouter.addProject(flowraWallet, "Flowra", "Open source DeFi for public goods");

        // Fund test accounts with USDC
        deal(address(USDC), alice, 100000 * 10**6);   // 100,000 USDC
        deal(address(USDC), bob, 100000 * 10**6);
        deal(address(USDC), charlie, 100000 * 10**6);
    }

    // ============ Deposit Tests ============

    function test_Deposit_MinDonation_1Percent() public {
        uint256 depositAmount = 1000 * 10**6; // 1,000 USDC
        uint256 donationPercent = 100; // 1% (minimum)
        uint256[] memory projects = new uint256[](1);
        projects[0] = 5; // Flowra only

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);
        bytes32 positionId = flowraCore.deposit(depositAmount, donationPercent, projects);
        vm.stopPrank();

        FlowraTypes.UserPosition memory position = flowraCore.getPosition(alice);
        assertEq(position.donationPercentBps, 100, "Should be 1%");
        assertEq(position.selectedProjects.length, 1, "Should have 1 project");
        assertEq(position.selectedProjects[0], 5, "Should be Flowra");
    }

    function test_Deposit_MaxDonation_20Percent() public {
        uint256 depositAmount = 10000 * 10**6; // 10,000 USDC
        uint256 donationPercent = 2000; // 20% (maximum)
        uint256[] memory projects = new uint256[](6);
        projects[0] = 0; // All 6 projects
        projects[1] = 1;
        projects[2] = 2;
        projects[3] = 3;
        projects[4] = 4;
        projects[5] = 5;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);
        bytes32 positionId = flowraCore.deposit(depositAmount, donationPercent, projects);
        vm.stopPrank();

        FlowraTypes.UserPosition memory position = flowraCore.getPosition(alice);
        assertEq(position.donationPercentBps, 2000, "Should be 20%");
        assertEq(position.selectedProjects.length, 6, "Should have 6 projects");
    }

    function test_Deposit_RevertIf_DonationTooLow() public {
        uint256 depositAmount = 1000 * 10**6;
        uint256 donationPercent = 50; // 0.5% - too low
        uint256[] memory projects = new uint256[](1);
        projects[0] = 0;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);

        vm.expectRevert(FlowraTypes.InvalidDonationPercent.selector);
        flowraCore.deposit(depositAmount, donationPercent, projects);
        vm.stopPrank();
    }

    function test_Deposit_RevertIf_DonationTooHigh() public {
        uint256 depositAmount = 1000 * 10**6;
        uint256 donationPercent = 2500; // 25% - too high
        uint256[] memory projects = new uint256[](1);
        projects[0] = 0;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);

        vm.expectRevert(FlowraTypes.InvalidDonationPercent.selector);
        flowraCore.deposit(depositAmount, donationPercent, projects);
        vm.stopPrank();
    }

    function test_Deposit_RevertIf_NoProjects() public {
        uint256 depositAmount = 1000 * 10**6;
        uint256 donationPercent = 1000;
        uint256[] memory projects = new uint256[](0); // Empty array

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);

        vm.expectRevert(FlowraTypes.InvalidProjectSelection.selector);
        flowraCore.deposit(depositAmount, donationPercent, projects);
        vm.stopPrank();
    }

    function test_Deposit_RevertIf_TooManyProjects() public {
        uint256 depositAmount = 1000 * 10**6;
        uint256 donationPercent = 1000;
        uint256[] memory projects = new uint256[](7); // 7 projects - too many

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);

        vm.expectRevert(FlowraTypes.InvalidProjectSelection.selector);
        flowraCore.deposit(depositAmount, donationPercent, projects);
        vm.stopPrank();
    }

    function test_Deposit_RevertIf_DuplicateProjects() public {
        uint256 depositAmount = 1000 * 10**6;
        uint256 donationPercent = 1000;
        uint256[] memory projects = new uint256[](3);
        projects[0] = 0;
        projects[1] = 1;
        projects[2] = 0; // Duplicate

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);

        vm.expectRevert(FlowraTypes.InvalidProjectSelection.selector);
        flowraCore.deposit(depositAmount, donationPercent, projects);
        vm.stopPrank();
    }

    function test_Deposit_RevertIf_InvalidProjectId() public {
        uint256 depositAmount = 1000 * 10**6;
        uint256 donationPercent = 1000;
        uint256[] memory projects = new uint256[](1);
        projects[0] = 6; // Project ID 6 doesn't exist (only 0-5)

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);

        vm.expectRevert(FlowraTypes.InvalidProjectSelection.selector);
        flowraCore.deposit(depositAmount, donationPercent, projects);
        vm.stopPrank();
    }

    // ============ View Function Tests ============

    function test_GetPendingYield() public {
        // Alice deposits
        uint256 depositAmount = 10000 * 10**6; // 10,000 USDC
        uint256[] memory projects = new uint256[](1);
        projects[0] = 5;

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), depositAmount);
        flowraCore.deposit(depositAmount, 1000, projects); // 10% donation
        vm.stopPrank();

        // Check initial pending yield (should be 0 initially)
        uint256 pending = flowraCore.getPendingYield(alice);
        assertEq(pending, 0, "Should have no yield initially");
    }

    function test_GetUserSelectedProjects() public {
        uint256[] memory projects = new uint256[](3);
        projects[0] = 0; // Amazon
        projects[1] = 2; // Solar
        projects[2] = 5; // Flowra

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 5000 * 10**6);
        flowraCore.deposit(5000 * 10**6, 1500, projects); // 15% donation
        vm.stopPrank();

        uint256[] memory selected = flowraCore.getUserSelectedProjects(alice);
        assertEq(selected.length, 3, "Should have 3 projects");
        assertEq(selected[0], 0, "First should be Amazon");
        assertEq(selected[1], 2, "Second should be Solar");
        assertEq(selected[2], 5, "Third should be Flowra");
    }

    function test_GetUserDonationPercent() public {
        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 5000 * 10**6);

        uint256[] memory projects = new uint256[](1);
        projects[0] = 0;

        flowraCore.deposit(5000 * 10**6, 750, projects); // 7.5% donation
        vm.stopPrank();

        uint256 donationPercent = flowraCore.getUserDonationPercent(alice);
        assertEq(donationPercent, 750, "Should be 7.5% (750 BPS)");
    }

    // ============ Multiple Users Test ============

    function test_MultipleUsers_DifferentPreferences() public {
        // Alice: 10% donation to Amazon + Flowra
        uint256[] memory aliceProjects = new uint256[](2);
        aliceProjects[0] = 0; // Amazon
        aliceProjects[1] = 5; // Flowra

        vm.startPrank(alice);
        USDC.approve(address(flowraCore), 10000 * 10**6);
        flowraCore.deposit(10000 * 10**6, 1000, aliceProjects);
        vm.stopPrank();

        // Bob: 5% donation to Ocean only
        uint256[] memory bobProjects = new uint256[](1);
        bobProjects[0] = 1; // Ocean

        vm.startPrank(bob);
        USDC.approve(address(flowraCore), 20000 * 10**6);
        flowraCore.deposit(20000 * 10**6, 500, bobProjects);
        vm.stopPrank();

        // Charlie: 20% donation to all 6 projects
        uint256[] memory charlieProjects = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            charlieProjects[i] = i;
        }

        vm.startPrank(charlie);
        USDC.approve(address(flowraCore), 30000 * 10**6);
        flowraCore.deposit(30000 * 10**6, 2000, charlieProjects);
        vm.stopPrank();

        // Verify each user's preferences
        assertEq(flowraCore.getUserDonationPercent(alice), 1000, "Alice 10%");
        assertEq(flowraCore.getUserDonationPercent(bob), 500, "Bob 5%");
        assertEq(flowraCore.getUserDonationPercent(charlie), 2000, "Charlie 20%");

        assertEq(flowraCore.getUserSelectedProjects(alice).length, 2, "Alice 2 projects");
        assertEq(flowraCore.getUserSelectedProjects(bob).length, 1, "Bob 1 project");
        assertEq(flowraCore.getUserSelectedProjects(charlie).length, 6, "Charlie 6 projects");
    }

    // ============ Project Tests ============

    function test_GetAllProjects_Returns6() public {
        FlowraTypes.Project[] memory projects = yieldRouter.getAllProjects();
        assertEq(projects.length, 6, "Should have exactly 6 projects");

        // Verify project names
        assertEq(projects[0].name, "Amazon Rainforest", "Project 0 name");
        assertEq(projects[1].name, "Ocean Cleanup", "Project 1 name");
        assertEq(projects[2].name, "Solar Villages", "Project 2 name");
        assertEq(projects[3].name, "Regenerative Farming", "Project 3 name");
        assertEq(projects[4].name, "Coral Restoration", "Project 4 name");
        assertEq(projects[5].name, "Flowra", "Project 5 name");
    }

    function test_GetProject_ByIndex() public {
        FlowraTypes.Project memory project = yieldRouter.getProject(0);
        assertEq(project.wallet, amazonWallet, "Amazon wallet");
        assertEq(project.name, "Amazon Rainforest", "Amazon name");
        assertTrue(project.active, "Should be active");
    }

    function test_ProjectWalletMapping() public {
        assertEq(yieldRouter.getProjectIdByWallet(flowraWallet), 5, "Flowra should be ID 5");
        assertEq(yieldRouter.getProjectIdByWallet(amazonWallet), 0, "Amazon should be ID 0");
        assertEq(yieldRouter.getProjectIdByWallet(oceanWallet), 1, "Ocean should be ID 1");
    }
}
