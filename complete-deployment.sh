#!/bin/bash

# Flowra Deployment Completion Script
# Author: Flowra Team
# Description: Complete Steps 2-5 of Flowra deployment
#
# This script finishes the deployment after Step 1 (core contracts) is done:
# - Step 2: Setup executor role
# - Step 3: Add public goods projects
# - Step 4: Deploy FlowraHook
# - Step 5: Set pool key in both FlowraCore and FlowraHook
#
# Usage:
#   ./complete-deployment.sh
#
# Prerequisites:
#   - Step 1 must be completed (core contracts deployed)
#   - deployments/arbitrum-mainnet.json must exist

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Emojis
CHECK="✅"
CROSS="❌"
WARN="⚠️"
ROCKET="🚀"
GEAR="⚙️"
HOOK="🪝"

echo -e "${CYAN}"
echo "=============================================="
echo "  🌱 Flowra Deployment - Steps 2-5"
echo "=============================================="
echo -e "${NC}"

# Function to print colored output
print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARN} $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${CYAN}${GEAR} $1${NC}"
}

print_substep() {
    echo -e "${MAGENTA}  ↳ $1${NC}"
}

# Load .env file
print_step "Loading environment variables..."

if [ ! -f .env ]; then
    print_error ".env file not found!"
    exit 1
fi

# Source .env
set -a
source .env
set +a

print_success ".env file loaded"
echo ""

# Check if Step 1 was completed
print_step "Checking Step 1 completion..."

if [ ! -f "deployments/arbitrum-mainnet.json" ]; then
    print_error "Step 1 not completed! Run deploy-all.sh first or deploy core contracts manually."
    exit 1
fi

# Extract addresses from JSON (using grep instead of jq)
FLOWRA_CORE=$(grep -o '"flowraCore"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-mainnet.json | grep -o '0x[a-fA-F0-9]*' || echo "")
AAVE_VAULT=$(grep -o '"aaveVault"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-mainnet.json | grep -o '0x[a-fA-F0-9]*' || echo "")
YIELD_ROUTER=$(grep -o '"yieldRouter"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-mainnet.json | grep -o '0x[a-fA-F0-9]*' || echo "")

if [ -z "$FLOWRA_CORE" ] || [ -z "$AAVE_VAULT" ] || [ -z "$YIELD_ROUTER" ]; then
    print_error "Could not read contract addresses from deployment file!"
    cat deployments/arbitrum-mainnet.json
    exit 1
fi

print_success "Step 1 completed - Core contracts deployed"
print_substep "FlowraCore:        $FLOWRA_CORE"
print_substep "FlowraAaveVault:   $AAVE_VAULT"
print_substep "FlowraYieldRouter: $YIELD_ROUTER"
echo ""

# Get deployer address
DEPLOYER=$(cast wallet address --account monad-deployer 2>/dev/null || echo "")
if [ -z "$DEPLOYER" ]; then
    print_error "Failed to get deployer address. Is monad-deployer wallet imported?"
    exit 1
fi

print_info "Deployer: $DEPLOYER"
print_info "Executor: $EXECUTOR_ADDRESS"
echo ""

# Display summary
echo -e "${CYAN}=============================================="
echo "  📋 Deployment Completion Plan"
echo "==============================================\n${NC}"
echo "Network:        Arbitrum One (Chain ID: 42161)"
echo "Deployer:       $DEPLOYER"
echo "Executor:       $EXECUTOR_ADDRESS"
echo ""
echo "Remaining Steps:"
echo "  Step 2: Grant executor role"
echo "  Step 3: Add 6 public goods projects"
echo "  Step 4: Deploy FlowraHook"
echo "  Step 5: Set pool key (CRITICAL FIX!)"
echo ""

read -p "Continue with Steps 2-5? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Deployment cancelled by user"
    exit 1
fi
echo ""

# ============================================================
# STEP 2: Setup Executor Role
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 2/4: Setup Executor Role${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_substep "Granting EXECUTOR_ROLE to: $EXECUTOR_ADDRESS"
print_warning "You will be prompted for your wallet password"
echo ""

read -p "Press Enter to continue..."
echo ""

if forge script script/SetupExecutor.s.sol \
    --rpc-url $ARBITRUM_RPC_URL \
    --account monad-deployer \
    --sender $DEPLOYER \
    --broadcast \
    -vv; then
    print_success "Executor role granted successfully!"
    echo ""
else
    print_error "Failed to setup executor role"
    echo ""
    exit 1
fi

# Wait for user
read -p "Press Enter to continue to Step 3..."
echo ""

# ============================================================
# STEP 3: Add Projects
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 3/4: Add Public Goods Projects${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_substep "Adding 6 public goods projects to YieldRouter"
print_warning "You will be prompted for your password again"
echo ""

if forge script script/AddProjects.s.sol \
    --rpc-url $ARBITRUM_RPC_URL \
    --account monad-deployer \
    --sender $DEPLOYER \
    --broadcast \
    -vv; then
    print_success "All 6 projects added successfully!"
    echo ""
else
    print_error "Failed to add projects"
    echo ""
    exit 1
fi

# Wait for user
read -p "Press Enter to continue to Step 4..."
echo ""

# ============================================================
# STEP 4: Deploy FlowraHook
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 4/4: Deploy Uniswap v4 Hook${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_substep "Deploying FlowraHook for automated DCA execution"
print_warning "You will be prompted for your password again"
echo ""

if forge script script/DeployHook.s.sol \
    --rpc-url $ARBITRUM_RPC_URL \
    --account monad-deployer \
    --sender $DEPLOYER \
    --broadcast \
    --verify \
    --etherscan-api-key $ARBISCAN_API_KEY \
    -vv; then
    print_success "FlowraHook deployed successfully!"
    echo ""

    # Check if deployment file exists and extract hook address
    if [ -f "deployments/arbitrum-hook.json" ]; then
        FLOWRA_HOOK=$(grep -o '"flowraHook"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-hook.json | grep -o '0x[a-fA-F0-9]*' || echo "")
        if [ -n "$FLOWRA_HOOK" ]; then
            print_substep "FlowraHook: $FLOWRA_HOOK"
            echo ""
        fi
    fi
else
    print_error "Hook deployment failed!"
    echo ""
    exit 1
fi

# Wait for user
read -p "Press Enter to continue to Step 5 (final step)..."
echo ""

# ============================================================
# STEP 5: Set Pool Key
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 5/5: Configure Pool Key (CRITICAL!)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_substep "Setting USDC/WETH pool key in FlowraCore and FlowraHook"
print_substep "This fixes the swap execution issue!"
print_warning "You will be prompted for your password one last time"
echo ""

if forge script script/SetPoolKey.s.sol \
    --rpc-url $ARBITRUM_RPC_URL \
    --account monad-deployer \
    --sender $DEPLOYER \
    --broadcast \
    -vv; then
    print_success "Pool key configured successfully!"
    echo ""
else
    print_error "Failed to set pool key!"
    echo ""
    exit 1
fi

# ============================================================
# Deployment Complete!
# ============================================================
echo ""
echo -e "${GREEN}=============================================="
echo "  🎉 Complete Deployment Successful!"
echo "==============================================\n${NC}"

# Extract addresses
if [ -f "deployments/arbitrum-hook.json" ]; then
    FLOWRA_HOOK=$(grep -o '"flowraHook"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-hook.json | grep -o '0x[a-fA-F0-9]*' || echo "")
fi

echo "📋 All Contract Addresses:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "FlowraCore:        $FLOWRA_CORE"
echo "FlowraAaveVault:   $AAVE_VAULT"
echo "FlowraYieldRouter: $YIELD_ROUTER"
if [ -n "$FLOWRA_HOOK" ]; then
    echo "FlowraHook:        $FLOWRA_HOOK"
fi
echo ""

echo "🔗 View on Arbiscan:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "FlowraCore:    https://arbiscan.io/address/$FLOWRA_CORE"
echo "AaveVault:     https://arbiscan.io/address/$AAVE_VAULT"
echo "YieldRouter:   https://arbiscan.io/address/$YIELD_ROUTER"
if [ -n "$FLOWRA_HOOK" ]; then
    echo "FlowraHook:    https://arbiscan.io/address/$FLOWRA_HOOK"
fi
echo ""

echo "✅ Deployment Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Core contracts deployed and verified"
print_success "Executor role granted to $EXECUTOR_ADDRESS"
print_success "6 public goods projects added"
if [ -n "$FLOWRA_HOOK" ]; then
    print_success "FlowraHook deployed and verified"
fi
print_success "Pool key configured in FlowraCore and FlowraHook"
echo ""

echo "🪝 Uniswap v4 Pool:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Pool:          USDC/WETH (0.3% fee)"
echo "View:          https://app.uniswap.org/explore/pools/arbitrum/0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8"
echo ""

echo "✨ Next Steps - Test the System:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Update frontend with NEW contract addresses:"
echo "   - FLOWRA_CORE: $FLOWRA_CORE"
if [ -n "$FLOWRA_HOOK" ]; then
    echo "   - FLOWRA_HOOK: $FLOWRA_HOOK"
fi
echo ""
echo "2. Make a test deposit (100-500 USDC recommended):"
echo ""
echo "   # Approve USDC"
echo "   cast send 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \\"
echo "     \"approve(address,uint256)\" \\"
echo "     $FLOWRA_CORE \\"
echo "     100000000 \\"
echo "     --rpc-url \$ARBITRUM_RPC_URL \\"
echo "     --account monad-deployer"
echo ""
echo "   # Deposit 100 USDC with 10% yield to Flowra (project ID: 0)"
echo "   cast send $FLOWRA_CORE \\"
echo "     \"deposit(uint256,uint256,uint256[])\" \\"
echo "     100000000 \\"
echo "     1000 \\"
echo "     \"[0]\" \\"
echo "     --rpc-url \$ARBITRUM_RPC_URL \\"
echo "     --account monad-deployer"
echo ""
echo "3. Monitor swap execution:"
echo "   - After 5 minutes, check if you can execute swap:"
echo ""
echo "   cast call $FLOWRA_CORE \\"
echo "     \"canSwap(address)\" \\"
echo "     $DEPLOYER \\"
echo "     --rpc-url \$ARBITRUM_RPC_URL"
echo ""
echo "   - Execute swap manually:"
echo ""
echo "   cast send $FLOWRA_CORE \\"
echo "     \"executeSwap(address)\" \\"
echo "     $DEPLOYER \\"
echo "     --rpc-url \$ARBITRUM_RPC_URL \\"
echo "     --account monad-deployer"
echo ""
echo "   ⏱️  Testing Mode: 5-minute intervals (~8.3 hours total)"
echo "   📅 Production Mode: 24-hour intervals (~100 days total)"
echo ""

# Quick verification
echo "🔍 Quick Verification:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check total projects
echo -n "Checking projects... "
TOTAL_PROJECTS=$(cast call $YIELD_ROUTER "getTotalProjects()" --rpc-url $ARBITRUM_RPC_URL 2>/dev/null || echo "0x")
if [ "$TOTAL_PROJECTS" = "0x0000000000000000000000000000000000000000000000000000000000000006" ]; then
    print_success "6 projects added"
else
    print_warning "Projects count: $TOTAL_PROJECTS"
fi

# Check executor role
echo -n "Checking executor role... "
EXECUTOR_ROLE=$(cast call $FLOWRA_CORE "EXECUTOR_ROLE()" --rpc-url $ARBITRUM_RPC_URL 2>/dev/null || echo "")
if [ -n "$EXECUTOR_ROLE" ]; then
    HAS_ROLE=$(cast call $FLOWRA_CORE "hasRole(bytes32,address)" $EXECUTOR_ROLE $EXECUTOR_ADDRESS --rpc-url $ARBITRUM_RPC_URL 2>/dev/null || echo "")
    if [ "$HAS_ROLE" = "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
        print_success "Executor role granted"
    else
        print_warning "Executor role status unclear"
    fi
fi

# Check pool key is set
echo -n "Checking pool key... "
# Try to read the first field of poolKey struct (currency0)
POOL_KEY_CHECK=$(cast call $FLOWRA_CORE "poolKey()(address,address,uint24,int24,address)" --rpc-url $ARBITRUM_RPC_URL 2>/dev/null | head -1 || echo "")
if [ -n "$POOL_KEY_CHECK" ] && [ "$POOL_KEY_CHECK" != "0x0000000000000000000000000000000000000000" ]; then
    print_success "Pool key configured"
else
    print_warning "Pool key verification inconclusive"
fi

echo ""
print_success "Deployment completion script finished successfully!"
echo ""
echo "📚 Documentation:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  README.md                 - Main documentation"
echo "  ARBITRUM_ADDRESSES.md     - Network addresses"
echo "  HOOK_DEPLOYMENT_GUIDE.md  - Hook integration guide"
echo ""
