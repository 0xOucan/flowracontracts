#!/bin/bash

# Flowra Setup Completion Script
# Completes executor setup and project addition

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
GEAR="⚙️"

echo -e "${CYAN}"
echo "=============================================="
echo "  🌱 Flowra Protocol Setup Completion"
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

# Check if monad-deployer wallet exists
print_step "Checking monad-deployer wallet..."

if ! cast wallet list | grep -q "monad-deployer"; then
    print_error "monad-deployer wallet not found!"
    exit 1
fi

print_success "monad-deployer wallet found"
echo ""

# Get deployer address
DEPLOYER=$(cast wallet address --account monad-deployer 2>/dev/null || echo "")
if [ -z "$DEPLOYER" ]; then
    print_error "Failed to get deployer address"
    exit 1
fi

print_info "Deployer address: $DEPLOYER"
echo ""

# Display summary
echo -e "${CYAN}=============================================="
echo "  📋 Setup Summary"
echo "==============================================\\n${NC}"
echo "Network:        Arbitrum One (Chain ID: 42161)"
echo "Deployer:       $DEPLOYER"
echo "Executor:       $EXECUTOR_ADDRESS"
echo ""
echo "Projects to add:"
echo "  0. Amazon:    $PROJECT_0_WALLET"
echo "  1. Ocean:     $PROJECT_1_WALLET"
echo "  2. Solar:     $PROJECT_2_WALLET"
echo "  3. Farming:   $PROJECT_3_WALLET"
echo "  4. Coral:     $PROJECT_4_WALLET"
echo "  5. Flowra:    $PROJECT_5_WALLET"
echo ""

read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Setup cancelled by user"
    exit 1
fi
echo ""

# Step 2: Setup executor
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 2/3: Setup Executor Role${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_info "Granting EXECUTOR_ROLE to: $EXECUTOR_ADDRESS"
print_warning "You will be prompted for your password"
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
    exit 1
fi

# Step 3: Add projects
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 3/3: Add Projects${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_info "Adding 6 public goods projects..."
print_warning "You will be prompted for your password again"
echo ""

read -p "Press Enter to continue..."
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
    exit 1
fi

# Complete!
echo ""
echo -e "${GREEN}=============================================="
echo "  🎉 Setup Complete!"
echo "==============================================\\n${NC}"

print_success "Executor role granted to: $EXECUTOR_ADDRESS"
print_success "6 projects added to YieldRouter"
echo ""

echo "✨ Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Test with small deposit (1-5 USDC recommended)"
echo "2. Update frontend with contract addresses"
echo "3. Add EXECUTOR_PRIVATE_KEY to frontend .env"
echo "4. Monitor first few deposits closely"
echo ""

print_success "Setup script completed successfully!"
echo ""
