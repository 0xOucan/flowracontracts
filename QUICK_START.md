# ⚡ Quick Start - Deploy in 5 Minutes

The fastest way to deploy Flowra contracts to Arbitrum mainnet.

## Prerequisites (5 minutes)

```bash
# 1. Install Foundry (if not already)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 2. Import your wallet
cast wallet import monad-deployer --interactive
# Enter your private key and set a password

# 3. Verify wallet imported
cast wallet list
# Should show: monad-deployer (0xYOUR_ADDRESS)
```

## Setup .env (2 minutes)

```bash
# Copy template
cp .env.example .env

# Edit with your addresses
nano .env
```

**Required variables:**
- `ARBITRUM_RPC_URL` - Use default or choose from provided options
- `ARBISCAN_API_KEY` - Get from https://arbiscan.io/myapikey
- `EXECUTOR_ADDRESS` - Your executor wallet address
- `EXECUTOR_PRIVATE_KEY` - Your executor private key (for frontend)
- `PROJECT_0_WALLET` through `PROJECT_5_WALLET` - 6 project addresses

## Deploy (5-10 minutes)

```bash
# Run interactive deployment script
./deploy.sh
```

**That's it!** The script will:
1. ✅ Validate your setup
2. ✅ Show deployment summary
3. ✅ Deploy contracts (Step 1/3) - Enter password
4. ✅ Setup executor (Step 2/3) - Enter password
5. ✅ Add projects (Step 3/3) - Enter password
6. ✅ Verify on Arbiscan
7. ✅ Save addresses to `deployments/arbitrum-mainnet.json`

## What You'll See

```
==============================================
  🌱 Flowra Protocol Deployment Script
==============================================

✅ Foundry installed
✅ .env file loaded
✅ monad-deployer wallet found
✅ Balance: 0.125 ETH

📋 Deployment Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Network:        Arbitrum One
Deployer:       0x1234...5678
Executor:       0xABCD...EFAB
Projects:       6 configured

Does everything look correct? (y/n): y

🚀 Starting Deployment

Step 1/3: Deploy Core Contracts
⚠️  Enter your monad-deployer password

[Password prompt]

✅ Contracts deployed successfully!
  FlowraCore:        0xABCD...1234
  FlowraAaveVault:   0xEFGH...5678
  FlowraYieldRouter: 0xIJKL...9012

[Steps 2 & 3...]

🎉 Deployment Complete!
```

## After Deployment (2 minutes)

### Test with Small Deposit

```bash
# Get your deployed addresses
FLOWRA_CORE=$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)

# Approve 1 USDC
cast send 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
  "approve(address,uint256)" \
  $FLOWRA_CORE \
  1000000 \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer

# Deposit 1 USDC with 10% donation to Flowra (project 5)
cast send $FLOWRA_CORE \
  "deposit(uint256,uint256,uint256[])" \
  1000000 \
  1000 \
  "[5]" \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer

# Check your position
cast call $FLOWRA_CORE \
  "getPosition(address)" \
  $(cast wallet address --account monad-deployer) \
  --rpc-url $ARBITRUM_RPC_URL
```

### View on Arbiscan

After deployment, the script shows Arbiscan links:
```
https://arbiscan.io/address/0xABCD...1234
```

Click to view your verified contracts!

## Update Frontend (1 minute)

```javascript
// Add to your frontend config
export const FLOWRA_CONTRACTS = {
  flowraCore: "0x...",      // from deployments/arbitrum-mainnet.json
  aaveVault: "0x...",       // from deployments/arbitrum-mainnet.json
  yieldRouter: "0x...",     // from deployments/arbitrum-mainnet.json
}
```

```bash
# Add to frontend .env
EXECUTOR_PRIVATE_KEY=0xYOUR_EXECUTOR_PRIVATE_KEY
```

## Troubleshooting

### "monad-deployer wallet not found"
```bash
cast wallet import monad-deployer --interactive
```

### "Missing environment variables"
Check your `.env` file has all 6 project wallets and executor address.

### "Insufficient ETH balance"
Bridge ETH to Arbitrum: https://bridge.arbitrum.io/
Need at least 0.05 ETH.

### "Deployment failed"
The script offers retry. Or run manually:
```bash
DEPLOYER=$(cast wallet address --account monad-deployer)
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $DEPLOYER \
  --broadcast \
  --verify
```

## Complete Documentation

- **`./deploy.sh`** - Interactive deployment script (this guide)
- **`DEPLOY_SCRIPT_GUIDE.md`** - Detailed script documentation
- **`DEPLOYMENT_GUIDE_NAMED_WALLET.md`** - Manual deployment steps
- **`FUND_SAFETY.md`** - Fund recovery mechanisms (99% success)
- **`ARBITRUM_ADDRESSES.md`** - Network reference
- **`TEST_SUMMARY.md`** - Test results (37/45 passing)

## Timeline

```
Setup:          ~5 minutes  (install Foundry, import wallet)
Configure .env: ~2 minutes  (add addresses)
Deploy:         ~5 minutes  (script runs, enter password 3 times)
Test:           ~2 minutes  (deposit 1 USDC, verify)
─────────────────────────────────────────
Total:          ~15 minutes from zero to deployed! 🚀
```

## Safety First

**Start with 1-5 USDC to test!**
- ✅ Low risk (~$2)
- ✅ Verify everything works
- ✅ Learn the flow
- ✅ Scale up once confident

See `FUND_SAFETY.md` for complete recovery guide.

## Need Help?

1. Check `DEPLOY_SCRIPT_GUIDE.md` for detailed troubleshooting
2. Review `DEPLOYMENT_GUIDE_NAMED_WALLET.md` for manual steps
3. See example output in script documentation

---

**Ready?** Run `./deploy.sh` and follow the prompts! 🌱
