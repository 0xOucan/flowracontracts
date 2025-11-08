#!/bin/bash

# Flowra Complete Deployment Script
# Author: Flowra Team
# Description: Complete end-to-end deployment of Flowra protocol on Arbitrum
#
# This unified script performs all deployment steps in order:
# 1. Deploy core contracts (FlowraCore, AaveVault, YieldRouter)
# 2. Setup executor role
# 3. Add public goods projects
# 4. Deploy FlowraHook
# 5. Set pool key in FlowraCore and FlowraHook
#
# Usage:
#   ./deploy-all.sh
#
# Prerequisites:
#   - Foundry installed (forge, cast)
#   - jq installed for JSON parsing
#   - .env file configured
#   - monad-deployer wallet imported
#   - Minimum 0.05 ETH on Arbitrum for gas

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
LOCK="🔐"
GEAR="⚙️"
MONEY="💰"
HOOK="🪝"

echo -e "${CYAN}"
echo "=============================================="
echo "  🌱 Flowra Protocol - Complete Deployment"
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_step "Checking prerequisites..."

if ! command_exists forge; then
    print_error "Foundry not found. Please install it first:"
    echo "  curl -L https://foundry.paradigm.xyz | bash"
    echo "  foundryup"
    exit 1
fi
print_success "Foundry installed"

if ! command_exists cast; then
    print_error "Cast not found. Please install Foundry."
    exit 1
fi
print_success "Cast installed"

if ! command_exists jq; then
    print_warning "jq not installed. Installing jq for JSON parsing..."
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y jq
    elif command_exists brew; then
        brew install jq
    else
        print_error "Please install jq manually: https://stedolan.github.io/jq/download/"
        exit 1
    fi
fi
print_success "jq installed"

echo ""

# Load .env file
print_step "Loading environment variables..."

if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo ""
    echo "Please create .env file from .env.example:"
    echo "  cp .env.example .env"
    echo "  nano .env  # Edit with your values"
    exit 1
fi

# Source .env
set -a
source .env
set +a

print_success ".env file loaded"
echo ""

# Validate required variables
print_step "Validating environment variables..."

MISSING_VARS=()

# Check network config
[ -z "$ARBITRUM_RPC_URL" ] && MISSING_VARS+=("ARBITRUM_RPC_URL")
[ -z "$ARBISCAN_API_KEY" ] && MISSING_VARS+=("ARBISCAN_API_KEY")

# Check executor
[ -z "$EXECUTOR_ADDRESS" ] && MISSING_VARS+=("EXECUTOR_ADDRESS")

# Check project wallets
for i in {0..5}; do
    var_name="PROJECT_${i}_WALLET"
    [ -z "${!var_name}" ] && MISSING_VARS+=("$var_name")
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    print_error "Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Please update your .env file with all required values."
    exit 1
fi

print_success "All required variables set"
echo ""

# Check if monad-deployer wallet exists
print_step "Checking monad-deployer wallet..."

if ! cast wallet list | grep -q "monad-deployer"; then
    print_error "monad-deployer wallet not found!"
    echo ""
    echo "Please import your wallet first:"
    echo "  cast wallet import monad-deployer --interactive"
    echo ""
    read -p "Would you like to import it now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cast wallet import monad-deployer --interactive
        print_success "Wallet imported successfully"
    else
        exit 1
    fi
else
    print_success "monad-deployer wallet found"
fi

# Get deployer address
DEPLOYER=$(cast wallet address --account monad-deployer 2>/dev/null || echo "")
if [ -z "$DEPLOYER" ]; then
    print_error "Failed to get deployer address. Please check your wallet."
    exit 1
fi

print_info "Deployer address: $DEPLOYER"
echo ""

# Check balance
print_step "Checking ETH balance on Arbitrum..."
BALANCE=$(cast balance $DEPLOYER --rpc-url $ARBITRUM_RPC_URL 2>/dev/null || echo "0")
BALANCE_ETH=$(cast --from-wei $BALANCE)

if (( $(echo "$BALANCE_ETH < 0.05" | bc -l) )); then
    print_warning "Low ETH balance: $BALANCE_ETH ETH"
    echo "  Recommended: at least 0.05 ETH for complete deployment"
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    print_success "Balance: $BALANCE_ETH ETH"
fi
echo ""

# Display deployment summary
echo -e "${CYAN}=============================================="
echo "  📋 Deployment Summary"
echo "==============================================\n${NC}"
echo "Network:        Arbitrum One (Chain ID: 42161)"
echo "RPC:            $ARBITRUM_RPC_URL"
echo "Deployer:       $DEPLOYER"
echo "Balance:        $BALANCE_ETH ETH"
echo ""
echo "Executor:       $EXECUTOR_ADDRESS"
echo ""
echo "Projects:"
echo "  0. Amazon:    $PROJECT_0_WALLET"
echo "  1. Ocean:     $PROJECT_1_WALLET"
echo "  2. Solar:     $PROJECT_2_WALLET"
echo "  3. Farming:   $PROJECT_3_WALLET"
echo "  4. Coral:     $PROJECT_4_WALLET"
echo "  5. Flowra:    $PROJECT_5_WALLET"
echo ""

read -p "Deploy complete Flowra protocol now? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Deployment cancelled by user"
    exit 1
fi
echo ""

# Compilation check
print_step "Compiling contracts..."
if forge build > /tmp/forge-build.log 2>&1; then
    print_success "Contracts compiled successfully"
else
    print_error "Compilation failed. See /tmp/forge-build.log for details"
    tail -20 /tmp/forge-build.log
    exit 1
fi
echo ""

# Create deployments directory
mkdir -p deployments

# Main deployment
echo -e "${CYAN}=============================================="
echo "  ${ROCKET} Starting Complete Deployment"
echo "==============================================\n${NC}"

# ============================================================
# STEP 1: Deploy Core Contracts
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 1/5: Deploy Core Contracts${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_substep "Deploying FlowraCore, FlowraAaveVault, FlowraYieldRouter"
print_warning "You will be prompted for your monad-deployer wallet password"
echo ""

read -p "Press Enter to continue..."
echo ""

if forge script script/Deploy.s.sol \
    --rpc-url $ARBITRUM_RPC_URL \
    --account monad-deployer \
    --sender $DEPLOYER \
    --broadcast \
    --verify \
    --etherscan-api-key $ARBISCAN_API_KEY \
    -vv; then
    print_success "Core contracts deployed successfully!"
    echo ""

    # Check if deployment file exists
    if [ -f "deployments/arbitrum-mainnet.json" ]; then
        FLOWRA_CORE=$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)
        AAVE_VAULT=$(jq -r '.aaveVault' deployments/arbitrum-mainnet.json)
        YIELD_ROUTER=$(jq -r '.yieldRouter' deployments/arbitrum-mainnet.json)

        print_substep "FlowraCore:        $FLOWRA_CORE"
        print_substep "FlowraAaveVault:   $AAVE_VAULT"
        print_substep "FlowraYieldRouter: $YIELD_ROUTER"
        echo ""
    fi
else
    print_error "Core contract deployment failed!"
    echo ""
    echo "Common issues:"
    echo "  - Incorrect password"
    echo "  - Insufficient ETH balance"
    echo "  - RPC connection issues"
    exit 1
fi

# Wait for user
read -p "Press Enter to continue to Step 2..."
echo ""

# ============================================================
# STEP 2: Setup Executor Role
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 2/5: Setup Executor Role${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_substep "Granting EXECUTOR_ROLE to: $EXECUTOR_ADDRESS"
print_warning "You will be prompted for your password again"
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
    echo "You can retry later with: ./complete-setup.sh"
    echo ""
fi

# Wait for user
read -p "Press Enter to continue to Step 3..."
echo ""

# ============================================================
# STEP 3: Add Projects
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 3/5: Add Public Goods Projects${NC}"
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
    echo "You can retry later with: ./complete-setup.sh"
    echo ""
fi

# Wait for user
read -p "Press Enter to continue to Step 4..."
echo ""

# ============================================================
# STEP 4: Deploy FlowraHook
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 4/5: Deploy Uniswap v4 Hook${NC}"
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

    # Check if deployment file exists
    if [ -f "deployments/arbitrum-hook.json" ]; then
        FLOWRA_HOOK=$(jq -r '.flowraHook' deployments/arbitrum-hook.json)
        print_substep "FlowraHook: $FLOWRA_HOOK"
        echo ""
    fi
else
    print_error "Hook deployment failed!"
    echo "You can retry later with: ./deploy-hook.sh"
    exit 1
fi

# Wait for user
read -p "Press Enter to continue to Step 5 (final step)..."
echo ""

# ============================================================
# STEP 5: Set Pool Key
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 5/5: Configure Pool Key${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_substep "Setting USDC/WETH pool key in FlowraCore and FlowraHook"
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
    echo "You can retry later with: ./finalize-hook.sh"
    exit 1
fi

# ============================================================
# Deployment Complete!
# ============================================================
echo ""
echo -e "${GREEN}=============================================="
echo "  🎉 Complete Deployment Successful!"
echo "==============================================\n${NC}"

if [ -f "deployments/arbitrum-mainnet.json" ] && [ -f "deployments/arbitrum-hook.json" ]; then
    FLOWRA_CORE=$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)
    AAVE_VAULT=$(jq -r '.aaveVault' deployments/arbitrum-mainnet.json)
    YIELD_ROUTER=$(jq -r '.yieldRouter' deployments/arbitrum-mainnet.json)
    FLOWRA_HOOK=$(jq -r '.flowraHook' deployments/arbitrum-hook.json)

    echo "📋 Contract Addresses:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "FlowraCore:        $FLOWRA_CORE"
    echo "FlowraAaveVault:   $AAVE_VAULT"
    echo "FlowraYieldRouter: $YIELD_ROUTER"
    echo "FlowraHook:        $FLOWRA_HOOK"
    echo ""

    echo "🔗 View on Arbiscan:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "FlowraCore:    https://arbiscan.io/address/$FLOWRA_CORE"
    echo "AaveVault:     https://arbiscan.io/address/$AAVE_VAULT"
    echo "YieldRouter:   https://arbiscan.io/address/$YIELD_ROUTER"
    echo "FlowraHook:    https://arbiscan.io/address/$FLOWRA_HOOK"
    echo ""

    echo "📦 Saved to:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "deployments/arbitrum-mainnet.json"
    echo "deployments/arbitrum-hook.json"
    echo ""
fi

echo "🪝 Uniswap v4 Pool:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Pool:          USDC/WETH (0.3% fee)"
echo "View:          https://app.uniswap.org/explore/pools/arbitrum/0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8"
echo ""

echo "✨ Next Steps - Test the System:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Update frontend with contract addresses:"
echo "   - FLOWRA_CORE: $FLOWRA_CORE"
echo "   - FLOWRA_HOOK: $FLOWRA_HOOK"
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
echo "   - After 5 minutes, swaps execute automatically when anyone"
echo "     trades on the USDC/WETH pool"
echo "   - Or manually trigger with executeSwap(address user)"
echo ""
echo "   ⏱️  Testing Mode: 5-minute intervals (~8.3 hours total)"
echo "   📅 Production Mode: 24-hour intervals (~100 days total)"
echo ""

echo "📚 Documentation:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  README.md                 - Main documentation"
echo "  FUND_SAFETY.md            - Fund recovery guide"
echo "  ARBITRUM_ADDRESSES.md     - Network addresses"
echo "  HOOK_DEPLOYMENT_GUIDE.md  - Complete hook guide"
echo ""

# Quick verification
echo "🔍 Quick Verification:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "deployments/arbitrum-mainnet.json" ]; then
    FLOWRA_CORE=$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)
    YIELD_ROUTER=$(jq -r '.yieldRouter' deployments/arbitrum-mainnet.json)

    # Check total projects
    echo -n "Checking projects... "
    TOTAL_PROJECTS=$(cast call $YIELD_ROUTER "getTotalProjects()" --rpc-url $ARBITRUM_RPC_URL 2>/dev/null || echo "0x")
    if [ "$TOTAL_PROJECTS" = "0x0000000000000000000000000000000000000000000000000000000000000006" ]; then
        print_success "6 projects added"
    else
        print_warning "Projects might not be added correctly"
    fi

    # Check executor role
    echo -n "Checking executor role... "
    EXECUTOR_ROLE=$(cast call $FLOWRA_CORE "EXECUTOR_ROLE()" --rpc-url $ARBITRUM_RPC_URL 2>/dev/null || echo "")
    if [ -n "$EXECUTOR_ROLE" ]; then
        HAS_ROLE=$(cast call $FLOWRA_CORE "hasRole(bytes32,address)" $EXECUTOR_ROLE $EXECUTOR_ADDRESS --rpc-url $ARBITRUM_RPC_URL 2>/dev/null || echo "")
        if [ "$HAS_ROLE" = "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
            print_success "Executor role granted"
        else
            print_warning "Executor role might not be granted"
        fi
    fi

    # Check pool key is set
    echo -n "Checking pool key... "
    POOL_CURRENCY0=$(cast call $FLOWRA_CORE "poolKey()" --rpc-url $ARBITRUM_RPC_URL 2>/dev/null | head -1 || echo "")
    if [ "$POOL_CURRENCY0" != "0x0000000000000000000000000000000000000000" ]; then
        print_success "Pool key configured"
    else
        print_warning "Pool key might not be set"
    fi
fi

echo ""
print_success "Complete deployment script finished successfully!"
echo ""
