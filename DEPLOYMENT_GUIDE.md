# Flowra Protocol - Deployment Guide

Complete guide for deploying Flowra contracts to Arbitrum mainnet.

## 📋 Prerequisites

### Required Tools

```bash
# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
cast --version
```

### Required Funds

- **Admin Wallet**: Need ~0.01 ARB ($0.01-0.05) for deployment gas
- **Test USDC**: Minimum 1 USDC for testing deposits

### Required API Keys

- **Arbiscan API Key**: Get from https://arbiscan.io/myapikey
- **RPC URL**: Public RPC works, or get from Alchemy/Infura

---

## 🔧 Setup

### Step 1: Clone and Install

```bash
cd /home/oucan/Escritorio/flowra/flowra-contracts

# Install dependencies
forge install

# Build contracts (verify no errors)
forge build
```

### Step 2: Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env file with your values
nano .env  # or use your preferred editor
```

**Required .env values:**

```bash
# Network
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
ARBISCAN_API_KEY=YOUR_API_KEY

# Wallets
PRIVATE_KEY=0xYOUR_PRIVATE_KEY  # Admin wallet
EXECUTOR_WALLET=0xYOUR_EXECUTOR_ADDRESS

# Projects (6 wallets, must sum to 10000 BPS)
PROJECT_1_WALLET=0x...
PROJECT_1_ALLOCATION=3000  # 30%
# ... (continue for all 6 projects)
```

### Step 3: Import Wallet to Cast (Optional - for interactive signing)

```bash
# Import your private key to cast wallet
cast wallet import monad-deployer --interactive

# This will prompt for:
# - Your private key
# - A password to encrypt the keystore
```

---

## 🚀 Deployment

### Step 1: Deploy Core Contracts

```bash
# Deploy main contracts (FlowraCore, AaveVault, YieldRouter)
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast \
  --verify \
  --legacy
```

**What this does:**
1. Deploys FlowraAaveVault
2. Deploys FlowraYieldRouter
3. Deploys FlowraCore (with Uniswap v4 integration)
4. Links all contracts together
5. Verifies on Arbiscan
6. Saves addresses to `deployments/arbitrum-mainnet.json`

**Expected output:**
```
==============================================
Flowra Protocol Deployment
==============================================
Deployer: 0xYourAddress
Network: Arbitrum Mainnet (Chain ID: 42161)
==============================================

Phase 1: Deploying Core Infrastructure...
1. Deploying FlowraAaveVault...
   FlowraAaveVault deployed at: 0x...

2. Deploying FlowraYieldRouter...
   FlowraYieldRouter deployed at: 0x...

3. Deploying FlowraCore...
   FlowraCore deployed at: 0x...

Phase 2: Configuring Contracts...
[Configuration logs...]

Deployment Complete!
```

### Step 2: Add Projects

Edit `script/AddProjects.s.sol` with your project wallets from `.env`:

```solidity
// Update getProjects() function with your 6 projects
projectsConfig[0] = ProjectConfig({
    wallet: payable(0xYOUR_PROJECT_1_WALLET),
    allocationBps: 3000, // 30%
    name: "Climate Action Fund",
    description: "Supporting renewable energy"
});
// ... repeat for all 6 projects
```

Then deploy:

```bash
# Add projects to YieldRouter
forge script script/AddProjects.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast \
  --legacy
```

**Validation:** Total allocations must equal 10000 BPS (100%)

### Step 3: Grant Executor Role

```bash
# Get deployed FlowraCore address
FLOWRA_CORE=$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)

# Grant executor role to your executor wallet
cast send $FLOWRA_CORE \
  "grantExecutor(address)" \
  $EXECUTOR_WALLET \
  --rpc-url $ARBITRUM_RPC_URL \
  --private-key $PRIVATE_KEY \
  --legacy
```

---

## ✅ Post-Deployment Verification

### 1. Verify Contract Addresses

```bash
# View deployed addresses
cat deployments/arbitrum-mainnet.json

# Check on Arbiscan
open "https://arbiscan.io/address/$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)"
```

### 2. Verify Contract Configuration

```bash
FLOWRA_CORE=$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)

# Check Aave vault is set
cast call $FLOWRA_CORE "aaveVault()" --rpc-url $ARBITRUM_RPC_URL

# Check yield router is set
cast call $FLOWRA_CORE "yieldRouter()" --rpc-url $ARBITRUM_RPC_URL

# Check executor role
cast call $FLOWRA_CORE "isExecutor(address)" $EXECUTOR_WALLET --rpc-url $ARBITRUM_RPC_URL
```

### 3. Verify Projects

```bash
YIELD_ROUTER=$(jq -r '.yieldRouter' deployments/arbitrum-mainnet.json)

# Check active project count
cast call $YIELD_ROUTER "getActiveProjectCount()" --rpc-url $ARBITRUM_RPC_URL

# Should return: 6

# Check allocation validity
cast call $YIELD_ROUTER "isAllocationValid()" --rpc-url $ARBITRUM_RPC_URL

# Should return: true
```

---

## 🧪 Testing

### Test 1: Deposit USDC

```bash
FLOWRA_CORE=$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)
USDC=0xaf88d065e77c8cC2239327C5EDb3A432268e5831

# Approve USDC
cast send $USDC \
  "approve(address,uint256)" \
  $FLOWRA_CORE \
  "1000000" \  # 1 USDC (6 decimals)
  --rpc-url $ARBITRUM_RPC_URL \
  --private-key $PRIVATE_KEY \
  --legacy

# Deposit 1 USDC
cast send $FLOWRA_CORE \
  "deposit(uint256)" \
  "1000000" \
  --rpc-url $ARBITRUM_RPC_URL \
  --private-key $PRIVATE_KEY \
  --legacy
```

### Test 2: Check Position

```bash
# Get your position
cast call $FLOWRA_CORE \
  "getPosition(address)" \
  $YOUR_ADDRESS \
  --rpc-url $ARBITRUM_RPC_URL
```

### Test 3: Execute Swap (After 5 Minutes)

```bash
# Check if swap is ready
cast call $FLOWRA_CORE \
  "canSwap(address)" \
  $YOUR_ADDRESS \
  --rpc-url $ARBITRUM_RPC_URL

# Execute swap (as executor)
cast send $FLOWRA_CORE \
  "executeSwap(address)" \
  $YOUR_ADDRESS \
  --rpc-url $ARBITRUM_RPC_URL \
  --private-key $EXECUTOR_PRIVATE_KEY \
  --legacy
```

### Test 4: Check Yield

```bash
AAVE_VAULT=$(jq -r '.aaveVault' deployments/arbitrum-mainnet.json)

# Check yield earned
cast call $AAVE_VAULT \
  "getYieldEarned()" \
  --rpc-url $ARBITRUM_RPC_URL
```

---

## 🤖 Executor Bot Setup (Optional)

For automated swap execution when pool activity is low:

### Create Executor Script

```bash
cd flowra-contracts
mkdir executor
cd executor
npm init -y
npm install viem dotenv
```

Create `executor/monitor.js`:

```javascript
import { createPublicClient, createWalletClient, http } from 'viem'
import { arbitrum } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
import dotenv from 'dotenv'

dotenv.config({ path: '../.env' })

const account = privateKeyToAccount(process.env.EXECUTOR_PRIVATE_KEY)

const publicClient = createPublicClient({
  chain: arbitrum,
  transport: http(process.env.ARBITRUM_RPC_URL)
})

const walletClient = createWalletClient({
  account,
  chain: arbitrum,
  transport: http(process.env.ARBITRUM_RPC_URL)
})

const FLOWRA_CORE = process.env.FLOWRA_CORE

async function monitorAndExecute() {
  console.log('🤖 Flowra Executor Bot Started')

  while (true) {
    try {
      // TODO: Get list of active users
      // For now, check specific addresses
      const users = [/* your test addresses */]

      const readyUsers = []

      for (const user of users) {
        const canSwap = await publicClient.readContract({
          address: FLOWRA_CORE,
          abi: [{
            name: 'canSwap',
            type: 'function',
            inputs: [{ name: 'user', type: 'address' }],
            outputs: [{ type: 'bool' }]
          }],
          functionName: 'canSwap',
          args: [user]
        })

        if (canSwap) {
          readyUsers.push(user)
        }
      }

      if (readyUsers.length > 0) {
        console.log(`⏰ ${readyUsers.length} users ready for swap`)

        const { hash } = await walletClient.writeContract({
          address: FLOWRA_CORE,
          abi: [{
            name: 'executeSwapBatch',
            type: 'function',
            inputs: [{ name: 'users', type: 'address[]' }]
          }],
          functionName: 'executeSwapBatch',
          args: [readyUsers]
        })

        console.log(`✅ Executed swaps: ${hash}`)
      }
    } catch (error) {
      console.error('❌ Error:', error)
    }

    // Wait 30 seconds
    await new Promise(resolve => setTimeout(resolve, 30000))
  }
}

monitorAndExecute()
```

Run the bot:

```bash
node executor/monitor.js
```

---

## 🔍 Troubleshooting

### Contract Verification Failed

```bash
# Manual verification
forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/FlowraCore.sol:FlowraCore \
  --chain arbitrum \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" $USDC $WETH $POOL_MANAGER)
```

### Swap Execution Fails

**Common issues:**

1. **Not enough time passed:** Must wait 5 minutes (300 seconds) between swaps
2. **Insufficient liquidity:** Pool might not have enough liquidity
3. **Price impact too high:** Slippage protection triggered
4. **No Aave liquidity:** Can't withdraw USDC from Aave

**Debug:**

```bash
# Check user position
cast call $FLOWRA_CORE "getPosition(address)" $USER_ADDRESS

# Check time until next swap
cast call $FLOWRA_CORE "canSwap(address)" $USER_ADDRESS
```

### Gas Estimation Failed

Add `--legacy` flag to use legacy transaction type:

```bash
cast send ... --legacy
```

---

## 📊 Monitoring

### View TVL

```bash
cast call $FLOWRA_CORE "totalValueLocked()" --rpc-url $ARBITRUM_RPC_URL
```

### View Active Users

```bash
cast call $FLOWRA_CORE "activeUsersCount()" --rpc-url $ARBITRUM_RPC_URL
```

### View Protocol Stats

```bash
cast call $FLOWRA_CORE "getProtocolStats()" --rpc-url $ARBITRUM_RPC_URL
```

### View Project Distributions

```bash
YIELD_ROUTER=$(jq -r '.yieldRouter' deployments/arbitrum-mainnet.json)

# Total distributed
cast call $YIELD_ROUTER "getTotalDistributed()" --rpc-url $ARBITRUM_RPC_URL

# Project distribution
cast call $YIELD_ROUTER "getProjectDistribution(address)" $PROJECT_WALLET --rpc-url $ARBITRUM_RPC_URL
```

---

## ⚠️ Important Notes

### Testing Parameters

**Current configuration (testsetup branch):**
- Minimum deposit: **1 USDC** (testing only)
- Swap interval: **300 seconds (5 minutes)** (testing only)

**Production configuration:**
- Minimum deposit: **100 USDC**
- Swap interval: **86400 seconds (24 hours)**

### Uniswap v4 Status

- Uniswap v4 is deployed on Arbitrum: `0x360e68faccca8ca495c1b759fd9eee466db9fb32`
- Swap execution is implemented but **not fully tested**
- The hook-based automatic execution requires pool activity
- Use executor role for guaranteed execution during testing

### Security

- ⚠️ **Not audited** - Use at your own risk
- Start with **small test amounts** (1-10 USDC)
- Use a **multi-sig wallet** for admin in production
- Keep **executor wallet** funded with gas
- Monitor **Aave health factors** regularly

---

## 📞 Support

- **Docs:** https://docs.uniswap.org/contracts/v4/overview
- **Discord:** Octant DeFi Hackathon server
- **GitHub:** Open issues at your repo

---

## ✅ Deployment Checklist

- [ ] Install Foundry and dependencies
- [ ] Configure .env with all required values
- [ ] Verify wallet has ARB for gas
- [ ] Run `forge build` successfully
- [ ] Deploy core contracts
- [ ] Verify contracts on Arbiscan
- [ ] Add 6 projects with 100% allocation
- [ ] Grant executor role
- [ ] Test deposit with 1 USDC
- [ ] Wait 5 minutes and test swap
- [ ] Verify Aave yield accrual
- [ ] Set up executor bot (optional)
- [ ] Monitor protocol stats

**Good luck! 🚀**
