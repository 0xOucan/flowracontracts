# FlowraHook Deployment Guide 🪝

Complete guide to deploying FlowraHook on Arbitrum mainnet with Uniswap v4 integration.

## Prerequisites

Before deploying the hook, ensure you have:

✅ **FlowraCore deployed** - Run `./deploy.sh` first
✅ **Executor role configured** - Run `./complete-setup.sh`
✅ **Projects added** - 6 public goods projects in YieldRouter
✅ **ETH on Arbitrum** - At least 0.01 ETH for hook deployment
✅ **Wallet keystore** - `monad-deployer` imported via Cast

## Uniswap v4 on Arbitrum One

FlowraHook integrates with Uniswap v4, which is **already deployed** on Arbitrum:

| Contract | Address |
|----------|---------|
| **PoolManager** | `0x360e68faCcca8cA495c1B759Fd9EEe466db9FB32` |
| **PositionManager** | `0xd88f38f930b7952f2db2432cb002e7abbf3dd869` |
| **UniversalRouter** | `0xa51afafe0263b40edaef0df8781ea9aa03e381a3` |

## Quick Start

### Option 1: Automated Deployment (Recommended)

```bash
cd /home/oucan/Escritorio/flowra/flowra-contracts
./deploy-hook.sh
```

This script will:
1. ✅ Check all prerequisites
2. ✅ Verify FlowraCore is deployed
3. ✅ Deploy FlowraHook contract
4. ✅ Configure hook with FlowraCore
5. ✅ Set Uniswap v4 PoolManager
6. ✅ Link hook to FlowraCore
7. ✅ Verify on Arbiscan
8. ✅ Save deployment addresses

### Option 2: Manual Deployment

```bash
# Deploy FlowraHook
forge script script/DeployHook.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $YOUR_ADDRESS \
  --broadcast \
  --verify \
  --etherscan-api-key $ARBISCAN_API_KEY
```

## What Gets Deployed

### FlowraHook Contract

**Constructor Parameters:**
- `USDC`: `0xaf88d065e77c8cC2239327C5EDb3A432268e5831`
- `WETH`: `0x82aF49447D8a07e3bd95BD0d56f35241523fBab1`

**Configuration:**
- Sets FlowraCore address
- Sets PoolManager address (`0x360e68faCcca8cA495c1B759Fd9EEe466db9FB32`)
- Registers with FlowraCore

**Hook Capabilities:**
- `beforeSwap()` - Checks for pending DCA swaps before any pool swap
- `afterSwap()` - Updates swap queue after pool swaps
- Automated execution (no keepers needed!)

## Hook Architecture

```
User Activity on USDC/WETH Pool
         │
         ▼
   ┌────────────┐
   │ Pool Swap  │
   └─────┬──────┘
         │
         ▼
   ┌────────────────────┐
   │ beforeSwap() Hook  │◄─── FlowraHook checks swap queue
   └──────┬─────────────┘
          │
          ├─── Has pending DCA swaps? ──► Execute via FlowraCore
          │
          └─── No pending swaps ──────► Continue with original swap
         │
         ▼
   ┌────────────┐
   │ Pool Swap  │ (Original swap executes)
   └─────┬──────┘
         │
         ▼
   ┌────────────────────┐
   │ afterSwap() Hook   │◄─── Update queue, check for new users
   └────────────────────┘
```

## Post-Deployment Steps

### 1. Initialize USDC/WETH Pool (If Needed)

Check if pool exists on Uniswap v4:
```bash
# Check on Uniswap app
https://app.uniswap.org/pools

# Or query PoolManager directly
cast call 0x360e68faCcca8cA495c1B759Fd9EEe466db9FB32 \
  "getPool(bytes32)" \
  <POOL_KEY> \
  --rpc-url $ARBITRUM_RPC_URL
```

If pool doesn't exist, initialize it via PositionManager:
```bash
# This requires creating a pool initialization transaction
# See Uniswap v4 documentation for details
```

### 2. Set Pool Key in FlowraHook

Once pool exists, set the pool key:
```bash
cast send $FLOWRA_HOOK_ADDRESS \
  "setPoolKey(bytes32)" \
  $POOL_KEY \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer
```

### 3. Test Hook Integration

Make a test deposit to trigger DCA:
```bash
# Approve USDC
cast send 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
  "approve(address,uint256)" \
  $FLOWRA_CORE \
  100000000 \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer

# Deposit 100 USDC with 10% yield to Flowra project
cast send $FLOWRA_CORE \
  "deposit(uint256,uint256,uint256[])" \
  100000000 \
  1000 \
  "[5]" \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer
```

### 4. Monitor Hook Activity

Watch for automated swaps:
```bash
# Check swap queue
cast call $FLOWRA_HOOK \
  "getPendingSwapCount()" \
  --rpc-url $ARBITRUM_RPC_URL

# Get next user ready for swap
cast call $FLOWRA_HOOK \
  "getNextSwapUser()" \
  --rpc-url $ARBITRUM_RPC_URL

# View full queue
cast call $FLOWRA_HOOK \
  "getSwapQueue()" \
  --rpc-url $ARBITRUM_RPC_URL
```

## How Automated Swaps Work

1. **User deposits USDC** → Position created in FlowraCore
2. **24 hours pass** → User becomes eligible for swap
3. **Anyone swaps on USDC/WETH pool** → `beforeSwap()` hook triggers
4. **Hook checks queue** → Finds users ready for DCA swap
5. **Executes DCA swap** → Calls `FlowraCore.executeSwap()`
6. **Piggybacks on pool activity** → Zero keeper costs!

## Key Benefits

### 🔥 Zero Keeper Costs
- Swaps execute when **anyone** trades USDC/WETH
- No need for external bots or relayers
- Scales automatically with pool activity

### 🛡️ Fully Decentralized
- No off-chain dependencies
- No centralized keeper infrastructure
- Trustless execution via smart contracts

### ⚡ Gas Efficient
- Amortizes costs across multiple users
- Batch processing when multiple users ready
- Minimal overhead per swap

### 🔒 MEV Resistant
- Executes within pool transactions
- No separate swap transactions to front-run
- Protected by Uniswap v4 architecture

## Troubleshooting

### Hook Not Executing Swaps

**Check:**
1. Pool key is set correctly: `cast call $HOOK "poolKey()"`
2. Users are in queue: `cast call $HOOK "getPendingSwapCount()"`
3. Users are eligible: Wait 24h after last swap
4. Pool has activity: Check recent swaps on USDC/WETH pool

### Deployment Failed

**Common issues:**
1. FlowraCore not deployed: Run `./deploy.sh` first
2. Insufficient ETH: Need ~0.001 ETH for deployment
3. Compilation errors: Run `forge clean && forge build`

### Verification Failed

Re-verify manually:
```bash
forge verify-contract \
  $FLOWRA_HOOK_ADDRESS \
  src/FlowraHook.sol:FlowraHook \
  --chain-id 42161 \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" $USDC $WETH)
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                  Uniswap v4 USDC/WETH Pool             │
│                                                         │
│  ┌────────────┐      ┌────────────┐      ┌──────────┐ │
│  │   Trader   │─────▶│    Swap    │─────▶│  Hooks   │ │
│  └────────────┘      └────────────┘      └────┬─────┘ │
└──────────────────────────────────────────────┼────────┘
                                              │
                         beforeSwap()         │
                                              ▼
                                    ┌──────────────────┐
                                    │   FlowraHook     │
                                    │                  │
                                    │ • Check queue    │
                                    │ • Execute DCA    │
                                    │ • Update state   │
                                    └────────┬─────────┘
                                             │
                                             │ executeSwap(user)
                                             ▼
                                    ┌──────────────────┐
                                    │   FlowraCore     │
                                    │                  │
                                    │ • Validate user  │
                                    │ • Execute swap   │
                                    │ • Update position│
                                    └──────────────────┘
```

## Cost Breakdown

| Action | Estimated Gas | Cost (0.01 gwei) |
|--------|---------------|------------------|
| Deploy FlowraHook | ~1,500,000 | ~0.00015 ETH |
| Set FlowraCore | ~50,000 | ~0.000005 ETH |
| Set PoolManager | ~50,000 | ~0.000005 ETH |
| Set Hook in Core | ~50,000 | ~0.000005 ETH |
| **Total** | **~1,650,000** | **~0.000165 ETH** |

## Security Considerations

### Access Control
- Only PoolManager can call hook functions
- Only FlowraCore/owner can manage queue
- Owner can pause in emergencies

### Safety Features
- Queue validation before swaps
- Emergency queue clearing
- Token recovery for accidents

### Audit Status
⚠️ **Not yet audited** - Hook is a hackathon prototype

## Resources

- [Uniswap v4 Hooks Docs](https://docs.uniswap.org/contracts/v4/overview)
- [Uniswap v4 Deployments](https://docs.uniswap.org/contracts/v4/deployments)
- [FlowraCore Documentation](./README.md)
- [Arbitrum Addresses](./ARBITRUM_ADDRESSES.md)

## Support

For issues or questions:
- GitHub: [0xOucan/flowracontracts](https://github.com/0xOucan/flowracontracts)
- Twitter: [@0xoucan](https://x.com/0xoucan)

---

**Made with ❤️ for the Octant DeFi Hackathon 2025**
