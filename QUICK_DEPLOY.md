# Quick Deployment Reference

**Fast reference for deploying Flowra contracts using your monad-deployer wallet.**

## Prerequisites Checklist

- [ ] Foundry installed
- [ ] monad-deployer wallet imported to Foundry
- [ ] At least 0.05 ETH on Arbitrum mainnet
- [ ] Arbiscan API key
- [ ] 6 project wallet addresses ready
- [ ] 1 executor wallet address ready

## One-Time Setup

```bash
# 1. Import your wallet (only needed once)
cast wallet import monad-deployer --interactive
# Enter your private key when prompted
# Set a strong password

# 2. Verify wallet imported
cast wallet list
# Should show: monad-deployer (0xYOUR_ADDRESS)

# 3. Get your deployer address
DEPLOYER=$(cast wallet address --account monad-deployer)
echo $DEPLOYER

# 4. Check balance
cast balance $DEPLOYER --rpc-url https://arb1.arbitrum.io/rpc
```

## Configure Environment

```bash
# Copy and edit .env file
cp .env.example .env
nano .env

# Required variables to set:
# - ARBITRUM_RPC_URL
# - ARBISCAN_API_KEY
# - EXECUTOR_ADDRESS
# - EXECUTOR_PRIVATE_KEY
# - PROJECT_0_WALLET through PROJECT_5_WALLET

# Load environment
source .env
```

## Deploy (3 Commands)

```bash
# Get your deployer address for --sender flag
DEPLOYER=$(cast wallet address --account monad-deployer)

# 1. Deploy contracts (2-3 minutes)
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $DEPLOYER \
  --broadcast \
  --verify \
  --etherscan-api-key $ARBISCAN_API_KEY

# 2. Setup executor role (~30 seconds)
forge script script/SetupExecutor.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $DEPLOYER \
  --broadcast

# 3. Add projects (~1 minute)
forge script script/AddProjects.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $DEPLOYER \
  --broadcast
```

## Quick Verification

```bash
# Load deployed addresses
FLOWRA_CORE=$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)
YIELD_ROUTER=$(jq -r '.yieldRouter' deployments/arbitrum-mainnet.json)

# Check projects added
cast call $YIELD_ROUTER "getTotalProjects()" --rpc-url $ARBITRUM_RPC_URL
# Should return: 6

# Check executor has role
EXECUTOR_ROLE=$(cast call $FLOWRA_CORE "EXECUTOR_ROLE()" --rpc-url $ARBITRUM_RPC_URL)
cast call $FLOWRA_CORE "hasRole(bytes32,address)" $EXECUTOR_ROLE $EXECUTOR_ADDRESS --rpc-url $ARBITRUM_RPC_URL
# Should return: true

# View on Arbiscan
echo "FlowraCore: https://arbiscan.io/address/$FLOWRA_CORE"
```

## Test Deposit (Optional)

```bash
USDC=0xaf88d065e77c8cC2239327C5EDb3A432268e5831

# Approve 1 USDC
cast send $USDC "approve(address,uint256)" $FLOWRA_CORE 1000000 \
  --rpc-url $ARBITRUM_RPC_URL --account monad-deployer

# Deposit 1 USDC with 10% donation to Flowra (project 5)
cast send $FLOWRA_CORE "deposit(uint256,uint256,uint256[])" 1000000 1000 "[5]" \
  --rpc-url $ARBITRUM_RPC_URL --account monad-deployer

# Check your position
cast call $FLOWRA_CORE "getPosition(address)" $DEPLOYER --rpc-url $ARBITRUM_RPC_URL
```

## Troubleshooting

**"Wallet not found"**
```bash
cast wallet import monad-deployer --interactive
```

**"Insufficient funds"**
```bash
# Bridge ETH to Arbitrum: https://bridge.arbitrum.io/
```

**Verification failed**
```bash
# See DEPLOYMENT_GUIDE_NAMED_WALLET.md section 6
```

**Need to re-deploy**
```bash
# Backup old deployment
mv deployments/arbitrum-mainnet.json deployments/arbitrum-mainnet.backup.json
```

## Contract Addresses Reference

After deployment, save these addresses for frontend integration:

```javascript
// Update frontend config
export const FLOWRA_CONTRACTS = {
  flowraCore: "0x...",      // from deployments/arbitrum-mainnet.json
  aaveVault: "0x...",       // from deployments/arbitrum-mainnet.json
  yieldRouter: "0x...",     // from deployments/arbitrum-mainnet.json
  usdc: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
  weth: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
}
```

## Frontend Environment Variables

Add to frontend `.env`:

```bash
# Contract addresses from deployment
NEXT_PUBLIC_FLOWRA_CORE=0xYOUR_DEPLOYED_ADDRESS
NEXT_PUBLIC_AAVE_VAULT=0xYOUR_DEPLOYED_ADDRESS
NEXT_PUBLIC_YIELD_ROUTER=0xYOUR_DEPLOYED_ADDRESS

# Executor (for automated yield claiming)
EXECUTOR_PRIVATE_KEY=0xYOUR_EXECUTOR_PRIVATE_KEY
```

## Full Documentation

- **Complete Guide**: `DEPLOYMENT_GUIDE_NAMED_WALLET.md`
- **Environment Setup**: `.env.example`
- **Test Suite**: `TEST_SUMMARY.md`
- **Architecture**: `USER_YIELD_CONTROL_DESIGN.md`
