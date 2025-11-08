#!/bin/bash

# Finalize FlowraHook Setup
# Sets pool key and prepares for testing

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Emojis
CHECK="✅"
CROSS="❌"
WARN="⚠️"
ROCKET="🚀"
HOOK="🪝"
GEAR="⚙️"

echo -e "${CYAN}"
echo "=============================================="
echo "  ${HOOK} FlowraHook Finalization"
echo "=============================================="
echo -e "${NC}"

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

# Load .env
print_step "Loading environment..."
if [ ! -f .env ]; then
    print_error ".env file not found!"
    exit 1
fi

set -a
source .env
set +a
print_success "Environment loaded"
echo ""

# Check wallet
print_step "Checking wallet..."
if ! cast wallet list | grep -q "monad-deployer"; then
    print_error "monad-deployer wallet not found!"
    exit 1
fi

DEPLOYER=$(cast wallet address --account monad-deployer 2>/dev/null || echo "")
if [ -z "$DEPLOYER" ]; then
    print_error "Failed to get deployer address"
    exit 1
fi

print_success "Wallet found: $DEPLOYER"
echo ""

# Check FlowraHook
print_step "Checking FlowraHook deployment..."

if [ ! -f "deployments/arbitrum-hook.json" ]; then
    print_error "FlowraHook not deployed yet! Run ./deploy-hook.sh first"
    exit 1
fi

FLOWRA_HOOK=$(grep -o '"flowraHook"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-hook.json | grep -o '0x[a-fA-F0-9]*' || echo "")
FLOWRA_CORE=$(grep -o '"flowraCore"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-mainnet.json | grep -o '0x[a-fA-F0-9]*' || echo "")

if [ -z "$FLOWRA_HOOK" ]; then
    print_error "FlowraHook address not found!"
    exit 1
fi

print_success "FlowraHook: $FLOWRA_HOOK"
print_success "FlowraCore: $FLOWRA_CORE"
echo ""

# Display summary
echo -e "${CYAN}=============================================="
echo "  📋 Finalization Summary"
echo "==============================================\\n${NC}"
echo "Action:         Set Pool Key in FlowraHook"
echo "Network:        Arbitrum One (Chain ID: 42161)"
echo "Deployer:       $DEPLOYER"
echo ""
echo "Contracts:"
echo "  FlowraHook:   $FLOWRA_HOOK"
echo "  FlowraCore:   $FLOWRA_CORE"
echo ""
echo "Pool Details:"
echo "  Pair:         USDC/WETH"
echo "  Pool Key:     0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8"
echo "  Pool Link:    https://app.uniswap.org/explore/pools/arbitrum/0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8"
echo ""

read -p "Set pool key now? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Setup cancelled"
    exit 1
fi
echo ""

# Set pool key
print_step "Setting pool key..."
echo ""
print_warning "You will be prompted for your password"
echo ""

if forge script script/SetPoolKey.s.sol \
    --rpc-url $ARBITRUM_RPC_URL \
    --account monad-deployer \
    --sender $DEPLOYER \
    --broadcast \
    -vv; then
    print_success "Pool key set successfully!"
    echo ""
else
    print_error "Failed to set pool key!"
    exit 1
fi

# Success!
echo ""
echo -e "${GREEN}=============================================="
echo "  🎉 FlowraHook Setup Complete!"
echo "==============================================\\n${NC}"

echo "📋 Deployment Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "FlowraCore:        $FLOWRA_CORE"
echo "FlowraAaveVault:   $(grep -o '"aaveVault"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-mainnet.json | grep -o '0x[a-fA-F0-9]*')"
echo "FlowraYieldRouter: $(grep -o '"yieldRouter"[[:space:]]*:[[:space:]]*"[^"]*"' deployments/arbitrum-mainnet.json | grep -o '0x[a-fA-F0-9]*')"
echo "FlowraHook:        $FLOWRA_HOOK"
echo ""

echo "🔗 View on Arbiscan:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "FlowraCore:    https://arbiscan.io/address/$FLOWRA_CORE"
echo "FlowraHook:    https://arbiscan.io/address/$FLOWRA_HOOK"
echo ""

echo "🪝 Uniswap v4 Pool:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Pool:          USDC/WETH"
echo "View:          https://app.uniswap.org/explore/pools/arbitrum/0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8"
echo ""

echo "✨ Next Steps - Test the System:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Make a test deposit (100-500 USDC)"
echo ""
echo "   # Approve USDC"
echo "   cast send 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \\"
echo "     \"approve(address,uint256)\" \\"
echo "     $FLOWRA_CORE \\"
echo "     100000000 \\"
echo "     --rpc-url \$ARBITRUM_RPC_URL \\"
echo "     --account monad-deployer"
echo ""
echo "   # Deposit 100 USDC with 10% yield to Flowra"
echo "   cast send $FLOWRA_CORE \\"
echo "     \"deposit(uint256,uint256,uint256[])\" \\"
echo "     100000000 \\"
echo "     1000 \\"
echo "     \"[5]\" \\"
echo "     --rpc-url \$ARBITRUM_RPC_URL \\"
echo "     --account monad-deployer"
echo ""
echo "2. Monitor swap queue:"
echo ""
echo "   cast call $FLOWRA_HOOK \\"
echo "     \"getPendingSwapCount()\" \\"
echo "     --rpc-url \$ARBITRUM_RPC_URL"
echo ""
echo "3. After 24 hours, swaps execute automatically when anyone"
echo "   trades on the USDC/WETH pool!"
echo ""

echo "📚 Documentation:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  HOOK_DEPLOYMENT_GUIDE.md  - Complete hook guide"
echo "  README.md                 - Main documentation"
echo "  ARBITRUM_ADDRESSES.md     - Network addresses"
echo ""

print_success "FlowraHook is ready for automated DCA swaps!"
echo ""
