# Flowra Deployment Guide - Named Wallet (monad-deployer)

Complete step-by-step guide for deploying Flowra contracts to Arbitrum mainnet using Foundry's named wallet feature.

## Prerequisites

- [Foundry](https://getfoundry.sh/) installed (`curl -L https://foundry.paradigm.xyz | bash && foundryup`)
- Arbitrum mainnet RPC URL
- Arbiscan API key (for verification)
- Deployer wallet with ETH on Arbitrum (for gas)
- 6 project wallet addresses
- 1 executor wallet address

## Table of Contents

1. [Setup Named Wallet](#1-setup-named-wallet)
2. [Configure Environment](#2-configure-environment)
3. [Deploy Contracts](#3-deploy-contracts)
4. [Setup Executor](#4-setup-executor)
5. [Add Projects](#5-add-projects)
6. [Verify Deployment](#6-verify-deployment)
7. [Troubleshooting](#troubleshooting)

---

## 1. Setup Named Wallet

### Import Your Wallet to Foundry

The named wallet approach is more secure as your private key is encrypted and stored in Foundry's keystore.

```bash
# Import your wallet with the name "monad-deployer"
cast wallet import monad-deployer --interactive

# You'll be prompted to:
# 1. Enter your private key
# 2. Set a password to encrypt it

# Verify the wallet was imported
cast wallet list

# You should see:
# monad-deployer (0xYOUR_ADDRESS_HERE)
```

### Get Your Wallet Address

```bash
# Get the address of your named wallet
cast wallet address --account monad-deployer

# Save this address - you'll need it for --sender flag
```

### Check Balance

```bash
# Check ETH balance on Arbitrum mainnet
cast balance <YOUR_ADDRESS> --rpc-url https://arb1.arbitrum.io/rpc

# Recommended: At least 0.05 ETH for deployment and setup
```

---

## 2. Configure Environment

### Create .env File

```bash
# Copy the example
cp .env.example .env

# Edit .env with your favorite editor
nano .env  # or vim, code, etc.
```

### Required Environment Variables

Edit `.env` and set the following:

```bash
# Network Configuration
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc

# Arbiscan API Key (get from https://arbiscan.io/myapikey)
ARBISCAN_API_KEY=YOUR_ACTUAL_ARBISCAN_API_KEY

# Executor Configuration
EXECUTOR_ADDRESS=0xYOUR_EXECUTOR_WALLET_ADDRESS
EXECUTOR_PRIVATE_KEY=0xYOUR_EXECUTOR_PRIVATE_KEY

# Project Wallets
PROJECT_0_WALLET=0xAMAZON_WALLET_ADDRESS
PROJECT_1_WALLET=0xOCEAN_WALLET_ADDRESS
PROJECT_2_WALLET=0xSOLAR_WALLET_ADDRESS
PROJECT_3_WALLET=0xFARMING_WALLET_ADDRESS
PROJECT_4_WALLET=0xCORAL_WALLET_ADDRESS
PROJECT_5_WALLET=0xFLOWRA_WALLET_ADDRESS

# Note: PRIVATE_KEY is NOT needed when using named wallet
```

### Verify Environment

```bash
# Source the .env file
source .env

# Verify variables are set
echo $ARBITRUM_RPC_URL
echo $ARBISCAN_API_KEY
echo $EXECUTOR_ADDRESS
echo $PROJECT_5_WALLET  # Flowra wallet
```

---

## 3. Deploy Contracts

### Test Deployment (Dry Run)

```bash
# Simulate deployment without broadcasting
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $(cast wallet address --account monad-deployer)

# Review the output to ensure everything looks correct
```

### Deploy to Arbitrum Mainnet

```bash
# Deploy and verify contracts
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $(cast wallet address --account monad-deployer) \
  --broadcast \
  --verify \
  --etherscan-api-key $ARBISCAN_API_KEY

# You will be prompted to enter your wallet password
# Enter the password you set when importing the wallet
```

### Deployment Output

After successful deployment, you'll see:

```
==============================================
Deployment Complete!
==============================================

Contract Addresses:
-------------------
FlowraCore:         0xCONTRACT_ADDRESS_1
FlowraAaveVault:    0xCONTRACT_ADDRESS_2
FlowraYieldRouter:  0xCONTRACT_ADDRESS_3

Deployment info saved to: deployments/arbitrum-mainnet.json
```

**Save these addresses** - you'll need them for verification and frontend integration.

---

## 4. Setup Executor

Grant the EXECUTOR_ROLE to the executor wallet for automated operations.

```bash
# Grant executor role
forge script script/SetupExecutor.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $(cast wallet address --account monad-deployer) \
  --broadcast

# Enter your wallet password when prompted
```

### Verify Executor Setup

```bash
# Load the FlowraCore address from deployment
FLOWRA_CORE=$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)

# Get EXECUTOR_ROLE hash
EXECUTOR_ROLE=$(cast call $FLOWRA_CORE "EXECUTOR_ROLE()" --rpc-url $ARBITRUM_RPC_URL)

# Check if executor has the role
cast call $FLOWRA_CORE \
  "hasRole(bytes32,address)" \
  $EXECUTOR_ROLE \
  $EXECUTOR_ADDRESS \
  --rpc-url $ARBITRUM_RPC_URL

# Should return: true (0x0000...0001)
```

---

## 5. Add Projects

Add the 6 public goods projects to the yield router.

```bash
# Add projects from environment variables
forge script script/AddProjects.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $(cast wallet address --account monad-deployer) \
  --broadcast

# Enter your wallet password when prompted
```

### Verify Projects Added

```bash
# Load YieldRouter address
YIELD_ROUTER=$(jq -r '.yieldRouter' deployments/arbitrum-mainnet.json)

# Check total projects
cast call $YIELD_ROUTER "getTotalProjects()" --rpc-url $ARBITRUM_RPC_URL
# Should return: 6 (0x0000...0006)

# Get project 5 (Flowra)
cast call $YIELD_ROUTER "getProjectById(uint256)" 5 --rpc-url $ARBITRUM_RPC_URL

# Verify wallet address matches PROJECT_5_WALLET
```

---

## 6. Verify Deployment

### Manual Verification (if auto-verify failed)

If automatic verification failed during deployment, verify manually:

```bash
# Verify FlowraCore
forge verify-contract \
  $(jq -r '.flowraCore' deployments/arbitrum-mainnet.json) \
  src/FlowraCore.sol:FlowraCore \
  --chain-id 42161 \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" \
    0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
    0x82aF49447D8a07e3bd95BD0d56f35241523fBab1 \
    0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32)

# Verify FlowraAaveVault
forge verify-contract \
  $(jq -r '.aaveVault' deployments/arbitrum-mainnet.json) \
  src/FlowraAaveVault.sol:FlowraAaveVault \
  --chain-id 42161 \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" \
    0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
    0x794a61358D6845594F94dc1DB02A252b5b4814aD)

# Verify FlowraYieldRouter
forge verify-contract \
  $(jq -r '.yieldRouter' deployments/arbitrum-mainnet.json) \
  src/FlowraYieldRouter.sol:FlowraYieldRouter \
  --chain-id 42161 \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address)" \
    0xaf88d065e77c8cC2239327C5EDb3A432268e5831)
```

### Check Contract State

```bash
# Check FlowraCore configuration
FLOWRA_CORE=$(jq -r '.flowraCore' deployments/arbitrum-mainnet.json)

# Verify AaveVault is set
cast call $FLOWRA_CORE "aaveVault()" --rpc-url $ARBITRUM_RPC_URL

# Verify YieldRouter is set
cast call $FLOWRA_CORE "yieldRouter()" --rpc-url $ARBITRUM_RPC_URL

# Check totalValueLocked (should be 0 initially)
cast call $FLOWRA_CORE "totalValueLocked()" --rpc-url $ARBITRUM_RPC_URL
```

---

## 7. Test Deployment

### Test with Small Deposit

**IMPORTANT**: Test with a small amount first (1-10 USDC)

```bash
# Get USDC contract
USDC=0xaf88d065e77c8cC2239327C5EDb3A432268e5831

# Approve FlowraCore to spend USDC
cast send $USDC \
  "approve(address,uint256)" \
  $FLOWRA_CORE \
  1000000 \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer

# Deposit 1 USDC with 10% donation to project 5 (Flowra)
# deposit(uint256 amount, uint256 donationPercentBps, uint256[] calldata selectedProjects)
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

---

## Troubleshooting

### Error: "Failed to get EIP-1559 fees"

**Solution**: Your RPC endpoint doesn't support EIP-1559. Use legacy transactions:

```bash
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $(cast wallet address --account monad-deployer) \
  --broadcast \
  --verify \
  --legacy
```

### Error: "Wallet not found"

**Solution**: Import your wallet first:

```bash
cast wallet import monad-deployer --interactive
```

### Error: "Incorrect password"

**Solution**: You entered the wrong password. Try again or re-import the wallet:

```bash
# Remove the wallet
cast wallet remove monad-deployer

# Re-import with a new password
cast wallet import monad-deployer --interactive
```

### Error: "Insufficient funds"

**Solution**: Your wallet doesn't have enough ETH for gas. Bridge more ETH to Arbitrum:

- [Arbitrum Bridge](https://bridge.arbitrum.io/)
- Minimum recommended: 0.05 ETH

### Verification Fails

**Solution**: Verify manually using the commands in section 6.

### Contract Already Deployed

**Solution**: Deployment creates a JSON file to prevent re-deployment. To re-deploy:

```bash
# Backup old deployment
mv deployments/arbitrum-mainnet.json deployments/arbitrum-mainnet.backup.json

# Deploy again
forge script script/Deploy.s.sol ...
```

---

## Post-Deployment Checklist

- [ ] All contracts deployed successfully
- [ ] All contracts verified on Arbiscan
- [ ] Executor role granted
- [ ] All 6 projects added
- [ ] Test deposit successful
- [ ] Contract addresses saved
- [ ] Update frontend with contract addresses
- [ ] Add executor private key to frontend .env
- [ ] Monitor first real deposit

---

## Security Recommendations

1. **Wallet Security**
   - Keep your monad-deployer wallet password secure
   - Use a strong, unique password
   - Consider using a hardware wallet for production

2. **Key Management**
   - Never commit `.env` to version control
   - Store executor private key securely in frontend
   - Rotate executor keys periodically

3. **Testing**
   - Always test with small amounts first
   - Monitor first few real deposits closely
   - Set up monitoring for contract events

4. **Access Control**
   - Verify only executor has EXECUTOR_ROLE
   - Verify deployer is owner of all contracts
   - Consider transferring ownership to multisig

---

## Next Steps

1. Update frontend with deployed contract addresses
2. Add executor private key to frontend `.env`
3. Test full user flow with small amounts
4. Monitor Aave yield accrual
5. Test yield claiming after 24-48 hours
6. Verify project wallets receive donations correctly

---

## Support

- [Foundry Book](https://book.getfoundry.sh/)
- [Arbitrum Docs](https://docs.arbitrum.io/)
- [Aave v3 Docs](https://docs.aave.com/developers/getting-started/readme)
- [Flowra GitHub Issues](https://github.com/YOUR_REPO/issues)
