#!/bin/bash

# FlowraHook Deployment Script
# Author: Flowra Team
# Description: Deploy FlowraHook to Arbitrum mainnet and integrate with Uniswap v4

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis
CHECK="✅"
CROSS="❌"
WARN="⚠️"
ROCKET="🚀"
LOCK="🔐"
GEAR="⚙️"
HOOK="🪝"

echo -e "${CYAN}"
echo "=============================================="
echo "  ${HOOK} FlowraHook Deployment Script"
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

# Check if monad-deployer wallet exists
print_step "Checking monad-deployer wallet..."

if ! cast wallet list | grep -q "monad-deployer"; then
    print_error "monad-deployer wallet not found!"
    echo ""
    echo "Please import your wallet first:"
    echo "  cast wallet import monad-deployer --interactive"
    exit 1
fi

print_success "monad-deployer wallet found"

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

if (( $(echo "$BALANCE_ETH < 0.001" | bc -l) )); then
    print_warning "Low ETH balance: $BALANCE_ETH ETH"
    echo "  Recommended: at least 0.01 ETH for hook deployment"
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

# Check if FlowraCore is deployed
print_step "Checking existing deployment..."

if [ ! -f "deployments/arbitrum-mainnet.json" ]; then
    print_error "FlowraCore not deployed yet!"
    echo ""
    echo "Please deploy FlowraCore first:"
    echo "  ./deploy.sh"
    exit 1
fi

# Parse JSON without jq (more reliable)
FLOWRA_CORE=$(grep -o '"flowraCore"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-mainnet.json | grep -o '0x[a-fA-F0-9]*' || echo "")

if [ -z "$FLOWRA_CORE" ]; then
    print_error "FlowraCore address not found in deployment file!"
    echo ""
    echo "Deployment file contents:"
    cat deployments/arbitrum-mainnet.json
    exit 1
fi

print_success "FlowraCore found: $FLOWRA_CORE"
echo ""

# Display deployment summary
echo -e "${CYAN}=============================================="
echo "  📋 Hook Deployment Summary"
echo "==============================================\\n${NC}"
echo "Network:        Arbitrum One (Chain ID: 42161)"
echo "RPC:            $ARBITRUM_RPC_URL"
echo "Deployer:       $DEPLOYER"
echo "Balance:        $BALANCE_ETH ETH"
echo ""
echo "Existing Deployment:"
echo "  FlowraCore:   $FLOWRA_CORE"
echo ""
echo "Uniswap v4 Integration:"
echo "  PoolManager:  0x360e68faCcca8cA495c1B759Fd9EEe466db9FB32"
echo "  USDC:         0xaf88d065e77c8cC2239327C5EDb3A432268e5831"
echo "  WETH:         0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
echo ""

read -p "Deploy FlowraHook now? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Hook deployment cancelled by user"
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

# Main deployment
echo -e "${CYAN}=============================================="
echo "  ${ROCKET} Deploying FlowraHook"
echo "==============================================\\n${NC}"

print_warning "You will be prompted for your monad-deployer wallet password"
echo ""

read -p "Press Enter to continue..."
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
        FLOWRA_HOOK=$(grep -o '"flowraHook"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-hook.json | grep -o '0x[a-fA-F0-9]*' || echo "")

        echo "Deployed contracts:"
        echo "  FlowraHook:        $FLOWRA_HOOK"
        echo "  FlowraCore:        $FLOWRA_CORE"
        echo ""
        echo "View on Arbiscan:"
        echo "  https://arbiscan.io/address/$FLOWRA_HOOK"
        echo ""
    fi
else
    print_error "Hook deployment failed!"
    echo ""
    echo "Common issues:"
    echo "  - Incorrect password"
    echo "  - Insufficient ETH balance"
    echo "  - RPC connection issues"
    echo ""
    exit 1
fi

# Deployment complete!
echo ""
echo -e "${GREEN}=============================================="
echo "  🎉 FlowraHook Deployment Complete!"
echo "==============================================\\n${NC}"

if [ -f "deployments/arbitrum-hook.json" ]; then
    FLOWRA_HOOK=$(grep -o '"flowraHook"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-hook.json | grep -o '0x[a-fA-F0-9]*' || echo "")
    POOL_MANAGER=$(grep -o '"poolManager"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-hook.json | grep -o '0x[a-fA-F0-9]*' || echo "")

    echo "📋 Contract Addresses:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "FlowraHook:        $FLOWRA_HOOK"
    echo "FlowraCore:        $FLOWRA_CORE"
    echo "PoolManager:       $POOL_MANAGER"
    echo ""

    echo "🔗 View on Arbiscan:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "https://arbiscan.io/address/$FLOWRA_HOOK"
    echo ""

    echo "📦 Saved to:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "deployments/arbitrum-hook.json"
    echo ""
fi

echo "✨ Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Initialize USDC/WETH pool on Uniswap v4 (if not exists)"
echo "2. Set pool key in FlowraHook"
echo "3. Test with small DCA deposit (100-500 USDC)"
echo "4. Monitor first automated swap execution"
echo "5. Update frontend with hook address"
echo ""

echo "🔍 Pool Initialization:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Use Uniswap v4 Position Manager to create pool:"
echo "  Address: 0xd88f38f930b7952f2db2432cb002e7abbf3dd869"
echo ""
echo "Or check if USDC/WETH pool already exists on:"
echo "  https://app.uniswap.org/pools"
echo ""

print_success "Hook deployment script completed successfully!"
echo ""
