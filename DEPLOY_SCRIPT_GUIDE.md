# Interactive Deployment Script Guide

## Quick Start

```bash
# 1. Setup your .env file
cp .env.example .env
nano .env  # Add all your addresses

# 2. Import wallet (if not already done)
cast wallet import monad-deployer --interactive

# 3. Run deployment script
./deploy.sh
```

That's it! The script will guide you through everything.

---

## What the Script Does

### 🔍 Pre-Deployment Checks

1. ✅ Verifies Foundry is installed
2. ✅ Checks if .env file exists
3. ✅ Validates all required environment variables
4. ✅ Confirms monad-deployer wallet exists
5. ✅ Checks your ETH balance on Arbitrum
6. ✅ Shows deployment summary for your approval
7. ✅ Compiles all contracts

### 🚀 Deployment Steps

**Step 1/3: Deploy Core Contracts**
- Deploys FlowraCore, FlowraAaveVault, FlowraYieldRouter
- Auto-verifies on Arbiscan
- Saves addresses to `deployments/arbitrum-mainnet.json`
- **Prompts for password**: monad-deployer wallet password

**Step 2/3: Setup Executor Role**
- Grants EXECUTOR_ROLE to your executor wallet
- Enables automated operations
- **Prompts for password**: monad-deployer wallet password

**Step 3/3: Add Projects**
- Adds all 6 public goods projects from .env
- Projects become available for user selection
- **Prompts for password**: monad-deployer wallet password

### ✨ Post-Deployment

- Shows all contract addresses
- Provides Arbiscan links
- Runs quick verification
- Shows example test deposit command
- Lists next steps

---

## Prerequisites

### Required Software

```bash
# Check if installed
forge --version  # Foundry
cast --version   # Cast (part of Foundry)
jq --version     # JSON parser

# Install if missing
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install jq
# Ubuntu/Debian:
sudo apt-get install jq
# Mac:
brew install jq
```

### Required Setup

1. **monad-deployer wallet imported**
   ```bash
   cast wallet import monad-deployer --interactive
   ```

2. **ETH on Arbitrum** (at least 0.05 ETH)
   - Bridge at: https://bridge.arbitrum.io/

3. **.env file configured**
   - All 6 project wallet addresses
   - Executor address
   - Arbiscan API key

---

## Environment Variables Checklist

Before running `./deploy.sh`, verify your `.env` has:

```bash
# Network (required)
✓ ARBITRUM_RPC_URL
✓ ARBISCAN_API_KEY

# Executor (required)
✓ EXECUTOR_ADDRESS
✓ EXECUTOR_PRIVATE_KEY

# Projects (all 6 required)
✓ PROJECT_0_WALLET  # Amazon
✓ PROJECT_1_WALLET  # Ocean
✓ PROJECT_2_WALLET  # Solar
✓ PROJECT_3_WALLET  # Farming
✓ PROJECT_4_WALLET  # Coral
✓ PROJECT_5_WALLET  # Flowra
```

---

## Script Output Example

```
==============================================
  🌱 Flowra Protocol Deployment Script
==============================================

✅ Foundry installed
✅ Cast installed
✅ jq installed

⚙️  Loading environment variables...
✅ .env file loaded

⚙️  Validating environment variables...
✅ All required variables set

⚙️  Checking monad-deployer wallet...
✅ monad-deployer wallet found
ℹ️  Deployer address: 0x1234...5678

⚙️  Checking ETH balance on Arbitrum...
✅ Balance: 0.125 ETH

==============================================
  📋 Deployment Summary
==============================================

Network:        Arbitrum One (Chain ID: 42161)
RPC:            https://arb1.arbitrum.io/rpc
Deployer:       0x1234...5678
Balance:        0.125 ETH

Executor:       0xABCD...EFAB

Projects:
  0. Amazon:    0x1111...1111
  1. Ocean:     0x2222...2222
  2. Solar:     0x3333...3333
  3. Farming:   0x4444...4444
  4. Coral:     0x5555...5555
  5. Flowra:    0x6666...6666

Does everything look correct? (y/n): y

⚙️  Compiling contracts...
✅ Contracts compiled successfully

==============================================
  🚀 Starting Deployment
==============================================

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Step 1/3: Deploy Core Contracts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  You will be prompted for your monad-deployer wallet password

Press Enter to continue...

[Foundry output]
Enter keystore password: ********

✅ Contracts deployed successfully!

Deployed contracts:
  FlowraCore:        0xABCD...1234
  FlowraAaveVault:   0xEFGH...5678
  FlowraYieldRouter: 0xIJKL...9012

View on Arbiscan:
  https://arbiscan.io/address/0xABCD...1234

[... Steps 2 and 3 ...]

==============================================
  🎉 Deployment Complete!
==============================================
```

---

## Interactive Features

### Password Prompts
The script will ask for your monad-deployer password **3 times**:
1. During Step 1 (Deploy contracts)
2. During Step 2 (Setup executor)
3. During Step 3 (Add projects)

**Tip**: Keep your password ready!

### Confirmation Points
The script asks for confirmation:
- Before starting deployment (after summary)
- Between each step (press Enter to continue)
- If retrying after failure

### Error Handling
If any step fails:
- Clear error message shown
- Common issues listed
- Option to retry offered
- Can manually retry failed steps

---

## Manual Step Retry

If a step fails, you can retry it manually:

### Retry Step 1 (Deploy)
```bash
DEPLOYER=$(cast wallet address --account monad-deployer)

forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $DEPLOYER \
  --broadcast \
  --verify \
  --etherscan-api-key $ARBISCAN_API_KEY
```

### Retry Step 2 (Executor)
```bash
DEPLOYER=$(cast wallet address --account monad-deployer)

forge script script/SetupExecutor.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $DEPLOYER \
  --broadcast
```

### Retry Step 3 (Projects)
```bash
DEPLOYER=$(cast wallet address --account monad-deployer)

forge script script/AddProjects.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $DEPLOYER \
  --broadcast
```

---

## Troubleshooting

### "monad-deployer wallet not found"
```bash
# Import your wallet
cast wallet import monad-deployer --interactive
```

### "Missing required environment variables"
```bash
# Check which variables are missing
cat .env | grep "^#" -v | grep "="

# Edit .env to add missing values
nano .env
```

### "Insufficient ETH balance"
```bash
# Check your balance
cast balance $(cast wallet address --account monad-deployer) \
  --rpc-url https://arb1.arbitrum.io/rpc

# Bridge more ETH
# Visit: https://bridge.arbitrum.io/
```

### "Incorrect password"
- Make sure you're using the password you set during wallet import
- Try `cast wallet list` to verify wallet exists

### "Compilation failed"
```bash
# Check compilation logs
forge build

# If contracts are outdated
forge clean
forge build
```

### "RPC connection failed"
```bash
# Test RPC connection
cast block-number --rpc-url $ARBITRUM_RPC_URL

# Try alternative RPC (edit .env)
ARBITRUM_RPC_URL=https://arbitrum.drpc.org
```

### "Verification failed"
Verification can fail but deployment still succeeds. Verify manually:
```bash
# See ARBITRUM_ADDRESSES.md for verification commands
```

---

## Post-Deployment Verification

After deployment, the script automatically checks:

✅ **6 projects added**
```bash
cast call $YIELD_ROUTER "getTotalProjects()" --rpc-url $ARBITRUM_RPC_URL
# Should return: 0x...0006 (6 in hex)
```

✅ **Executor role granted**
```bash
EXECUTOR_ROLE=$(cast call $FLOWRA_CORE "EXECUTOR_ROLE()" --rpc-url $ARBITRUM_RPC_URL)
cast call $FLOWRA_CORE "hasRole(bytes32,address)" $EXECUTOR_ROLE $EXECUTOR_ADDRESS --rpc-url $ARBITRUM_RPC_URL
# Should return: 0x...0001 (true)
```

---

## Testing After Deployment

The script provides a test deposit command at the end:

```bash
# 1. Approve USDC
cast send 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
  "approve(address,uint256)" \
  $FLOWRA_CORE \
  1000000 \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer

# 2. Deposit 1 USDC with 10% donation to Flowra
cast send $FLOWRA_CORE \
  "deposit(uint256,uint256,uint256[])" \
  1000000 \
  1000 \
  "[5]" \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer

# 3. Check your position
cast call $FLOWRA_CORE \
  "getPosition(address)" \
  $(cast wallet address --account monad-deployer) \
  --rpc-url $ARBITRUM_RPC_URL
```

---

## What Gets Created

After successful deployment:

```
flowra-contracts/
├── deployments/
│   └── arbitrum-mainnet.json  ← Contract addresses
├── broadcast/
│   └── Deploy.s.sol/
│       └── 42161/            ← Deployment logs
└── cache/                    ← Forge cache
```

**Important**: Save `deployments/arbitrum-mainnet.json` - you need it for frontend!

---

## Next Steps After Deployment

1. **Verify on Arbiscan** (links provided in output)
2. **Test small deposit** (1-5 USDC)
3. **Update frontend** with contract addresses
4. **Add executor key** to frontend .env
5. **Monitor first deposits**

---

## Script Features

### Safety Checks
- ✅ Validates all prerequisites
- ✅ Checks ETH balance
- ✅ Warns on low balance
- ✅ Shows deployment summary before executing
- ✅ Waits for user confirmation

### User-Friendly
- 🎨 Colored output (green/red/yellow/blue)
- ✨ Emoji indicators
- 📋 Clear step numbering
- ⏸️  Pause between steps
- 🔄 Retry on failure

### Comprehensive
- 📊 Shows all addresses
- 🔗 Provides Arbiscan links
- ✅ Auto-verification
- 📝 Saves deployment info
- 🧪 Quick verification checks

---

## Security Notes

⚠️  **Never share your wallet password**
⚠️  **Never commit .env file**
⚠️  **Keep backup of wallet password**
⚠️  **Test with small amounts first**

---

## Support

If you encounter issues:

1. Check this guide's troubleshooting section
2. Review `FUND_SAFETY.md` for fund recovery
3. Check `DEPLOYMENT_GUIDE_NAMED_WALLET.md` for detailed steps
4. Review Foundry logs in `broadcast/` directory

---

## Summary

```bash
# Complete deployment in 3 steps:
./deploy.sh

# Enter password 3 times (once per step)
# Wait ~5-10 minutes total
# Get contract addresses
# Start testing! 🚀
```

**That's it!** The script handles everything else.
