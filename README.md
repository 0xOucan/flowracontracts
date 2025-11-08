# Flowra Smart Contracts 🌱

> Plant your crypto, grow impact

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.26-363636?style=flat-square&logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C?style=flat-square)](https://book.getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Status](https://img.shields.io/badge/Status-LIVE%20ON%20ARBITRUM-success?style=flat-square&logo=ethereum)](https://arbiscan.io/address/0xB2F2600792605Fb04a7eB0CfCAd6DFfDf5330B14)

**🎉 FULLY DEPLOYED & OPERATIONAL ON ARBITRUM MAINNET**

Flowra is a multi-contract DeFi protocol combining **DCA automation**, **yield generation**, and **public goods funding** on Arbitrum mainnet.

**✅ All systems deployed and verified**
**✅ Pool key configured and connected**
**✅ Ready for deposits and testing**

**Built for**: [Octant DeFi Hackathon 2025](https://octant.app/)
**Prize Categories**:
- Best Use of Uniswap v4 Hooks
- Octant Integration
- Public Goods Funding Innovation

## 🎯 Overview

Flowra enables users to:
- **Deposit USDC** and automatically DCA into WETH via Uniswap v4 swaps
- **Earn yield** on idle USDC via Aave v3 integration
- **Fund public goods** by routing 1-20% of earned yield to selected projects (inspired by Octant v2)
- **Keep full control** - Users choose which projects to support and donation percentage

**Deployed on Arbitrum One** - Ready for production use!

## 🏗️ Architecture

```
                     User Deposits USDC
                            │
                            ▼
                   ┌────────────────┐
                   │  FlowraCore    │ ◄──── Main Coordinator
                   │ (Orchestrator) │
                   └────┬───┬───┬───┘
                        │   │   │
           ┌────────────┘   │   └────────────┐
           │                │                │
           ▼                ▼                ▼
    ┌─────────────┐  ┌──────────┐  ┌──────────────┐
    │ FlowraAave  │  │ FlowraHook│  │ FlowraYield  │
    │ Vault       │  │ (Uniswap) │  │ Router       │
    │             │  │           │  │              │
    │ • Supply    │  │ • Daily   │  │ • Project    │
    │ • Yield     │  │   Swaps   │  │   Registry   │
    │ • Withdraw  │  │ • Auto    │  │ • Distribute │
    └──────┬──────┘  └─────┬─────┘  └──────┬───────┘
           │               │                │
           ▼               ▼                ▼
      Aave Pool     USDC/WETH Pool   Project Wallets
```

## 🚀 Live Deployment (Arbitrum One)

**Network**: Arbitrum One (Chain ID: 42161)
**Deployed**: January 8, 2025
**Deployer**: `0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45`
**Status**: ✅ **100% COMPLETE & READY** - All systems deployed, verified, and finalized

### System Status

| Component | Status | Details |
|-----------|--------|---------|
| **Core Contracts** | ✅ Deployed | FlowraCore, AaveVault, YieldRouter |
| **Uniswap v4 Hook** | ✅ Deployed | FlowraHook connected to live pool |
| **Pool Key Configuration** | ✅ Set | Connected to USDC/WETH pool |
| **Executor Role** | ✅ Configured | Automated operations enabled |
| **Public Goods Projects** | ✅ Added | 6 projects ready for yield donations |
| **Aave v3 Integration** | ✅ Connected | Yield generation active |
| **USDC/WETH Pool** | ✅ Connected | Live Uniswap v4 pool on Arbitrum |
| **Arbiscan Verification** | ✅ Complete | All contracts verified |
| **System Status** | ✅ **READY** | **Fully operational - ready for deposits!** |

### Deployed Contracts

| Contract | Address | Arbiscan | Function |
|----------|---------|----------|----------|
| **FlowraCore** | `0xB2F2600792605Fb04a7eB0CfCAd6DFfDf5330B14` | [View](https://arbiscan.io/address/0xB2F2600792605Fb04a7eB0CfCAd6DFfDf5330B14) | Main coordinator & DCA orchestrator |
| **FlowraAaveVault** | `0x0830637a1CEAA4dE039b186Ea9060d89AB63C1BE` | [View](https://arbiscan.io/address/0x0830637a1CEAA4dE039b186Ea9060d89AB63C1BE) | Aave v3 yield generation |
| **FlowraYieldRouter** | `0x8ba6246D59C8516Bb3522ce00fC95a3970b4C2B5` | [View](https://arbiscan.io/address/0x8ba6246D59C8516Bb3522ce00fC95a3970b4C2B5) | Public goods yield distribution |
| **FlowraHook** | `0x1c95Da298E99Fb478C30823afA7b59A0Ff7b99DF` | [View](https://arbiscan.io/address/0x1c95Da298E99Fb478C30823afA7b59A0Ff7b99DF) | Uniswap v4 automated DCA hook |

**Deployment Files:**
- Main contracts: [`deployments/arbitrum-mainnet.json`](./deployments/arbitrum-mainnet.json)
- Hook contract: [`deployments/arbitrum-hook.json`](./deployments/arbitrum-hook.json)

### Configuration ✅

**All setup completed and verified:**

- ✅ **Executor Address**: `0xcce721fC201D4571A5AC826A3e0908F81807fAa5` (has EXECUTOR_ROLE)
- ✅ **6 Public Goods Projects**: Added and active
- ✅ **Aave v3 Integration**: Connected to Arbitrum Aave Pool (`0x794a61358D6845594F94dc1DB02A252b5b4814aD`)
- ✅ **Uniswap v4 Hook**: Deployed at `0x1c95Da298E99Fb478C30823afA7b59A0Ff7b99DF`
- ✅ **Pool Manager**: Connected to `0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32`
- ✅ **Pool Key Configured**: USDC/WETH pool initialized
- ✅ **USDC/WETH Pool**: Connected to [live v4 pool](https://app.uniswap.org/explore/pools/arbitrum/0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8)
- ✅ **All contracts verified** on Arbiscan
- ✅ **System Status**: **READY FOR USE** 🚀

## 📦 Contracts

### Core Contracts

| Contract | Description | Location |
|----------|-------------|----------|
| **FlowraCore** | Main coordinator for deposits & DCA | `src/FlowraCore.sol` |
| **FlowraAaveVault** | Aave v3 yield generation | `src/FlowraAaveVault.sol` |
| **FlowraYieldRouter** | Octant v2-inspired yield distribution | `src/FlowraYieldRouter.sol` |
| **FlowraHook** | Uniswap v4 automated swaps (future) | `src/FlowraHook.sol` |

### Libraries & Interfaces

- **FlowraTypes** - Shared data structures
- **FlowraMath** - DCA calculations (1% daily swaps)
- Complete interfaces for all contracts

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js >= 16
- Git

### Installation

```bash
# Clone repository
git clone git@github.com:0xOucan/flowracontracts.git
cd flowracontracts

# Install dependencies
forge install

# Copy environment variables
cp .env.example .env

# Edit .env with your credentials
# - Add your PRIVATE_KEY
# - Add your ARBISCAN_API_KEY

# Build contracts
forge build
```

### Run Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test test_Deposit_Success

# Generate coverage report
forge coverage
```

## 🌐 Deployment

### Environment Setup

1. **Create wallet keystore** (for secure deployment):
```bash
cast wallet import monad-deployer --interactive
```

2. **Edit `.env` file** with your configuration:
```bash
# Network Configuration
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
ARBISCAN_API_KEY=your_arbiscan_api_key

# Executor Address (for automated operations)
EXECUTOR_ADDRESS=0xcce721fC201D4571A5AC826A3e0908F81807fAa5

# Project Wallet Addresses (for yield distribution)
PROJECT_0_WALLET=0xD308833dC6e9366D3C75981D6b1d716e32fFC3a8
PROJECT_1_WALLET=0xd051B758D8e4554bd89ACcC0288ad3eBA6238682
PROJECT_2_WALLET=0x15DFE880601a031Ea12B4F63400B36AA50D64993
PROJECT_3_WALLET=0x7518530d6a9ae910438C036d43EaA83A0424f4B6
PROJECT_4_WALLET=0x49FdCb1c1af4566A7bA45Fd9732A31B855D819bC
PROJECT_5_WALLET=0xF0ed6Bb76ba6eA3716B8D336e34Ba9A91065dAcd
```

### Deploy to Arbitrum Mainnet

**Option 1: Full Deployment Script (Recommended)**
```bash
./deploy.sh
```

This interactive script will:
1. ✅ Check prerequisites (Foundry, jq, wallet)
2. ✅ Deploy all 3 core contracts
3. ✅ Configure contract relationships
4. ✅ Verify on Arbiscan automatically
5. ✅ Prompt for Steps 2 & 3 (executor + projects)

**Option 2: Complete Setup (Steps 2 & 3 only)**

If contracts are already deployed, complete the setup:
```bash
./complete-setup.sh
```

This will:
1. ✅ Grant EXECUTOR_ROLE to your executor address
2. ✅ Add 6 public goods projects to YieldRouter

**Option 3: Manual Deployment**
```bash
# Step 1: Deploy core contracts
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $YOUR_ADDRESS \
  --broadcast \
  --verify

# Step 2: Setup executor role
forge script script/SetupExecutor.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $YOUR_ADDRESS \
  --broadcast

# Step 3: Add projects
forge script script/AddProjects.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer \
  --sender $YOUR_ADDRESS \
  --broadcast
```

**Option 4: Deploy FlowraHook (Uniswap v4 Integration)**

Deploy the automated DCA hook:
```bash
./deploy-hook.sh
```

This will:
1. ✅ Deploy FlowraHook to Arbitrum
2. ✅ Connect to Uniswap v4 PoolManager
3. ✅ Link hook to FlowraCore
4. ✅ Verify on Arbiscan

See [HOOK_DEPLOYMENT_GUIDE.md](./HOOK_DEPLOYMENT_GUIDE.md) for detailed instructions.

**Note**:
- Deployment addresses are saved to `deployments/arbitrum-mainnet.json`
- Hook deployment saved to `deployments/arbitrum-hook.json`
- You'll be prompted for your wallet password during deployment
- Recommended minimum balance: 0.05 ETH on Arbitrum (actual cost ~0.0002 ETH)

## 🔧 Network Configuration

### Arbitrum Mainnet

- **Chain ID**: 42161
- **RPC**: https://arb1.arbitrum.io/rpc
- **Explorer**: https://arbiscan.io

### Token Addresses

```solidity
USDC: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
WETH: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
```

### Protocol Addresses

```solidity
// Aave v3
Aave v3 Pool: 0x794a61358D6845594F94dc1DB02A252b5b4814aD

// Uniswap v4
PoolManager:      0x360e68faccca8ca495c1b759fd9eee466db9fb32
PositionManager:  0xd88f38f930b7952f2db2432cb002e7abbf3dd869
UniversalRouter:  0xa51afafe0263b40edaef0df8781ea9aa03e381a3
Permit2:          0x000000000022D473030F116dDEE9F6B43aC78BA3
```

## 🎨 Design Inspiration

### Octant v2 Yield Donation Integration

Flowra is inspired by **Octant v2's innovative yield donation mechanism**, adapting it for DeFi automation:

**Octant v2 Principles We Adopted:**
- ✅ **User control over yield allocation** - Users choose donation percentage (1-20%)
- ✅ **Multiple project selection** - Support up to 6 public goods projects simultaneously
- ✅ **Equal yield splitting** - Donations distributed evenly among selected projects
- ✅ **Transparent on-chain tracking** - All yield flows verifiable on Arbiscan
- ✅ **Permissionless project registry** - Owner can add verified public goods projects

**Our Innovation:**
- Combined DCA automation + yield generation + public goods funding in ONE protocol
- Integrated with Aave v3 for passive yield on idle deposits
- **Built on Uniswap v4** - leveraging live hook infrastructure on Arbitrum One

### Uniswap v4 Hooks Architecture

Flowra is designed with **Uniswap v4 Hooks** at its core:

**✅ Uniswap v4 is LIVE on Arbitrum One!**
- **PoolManager**: `0x360e68faccca8ca495c1b759fd9eee466db9fb32`
- **PositionManager**: `0xd88f38f930b7952f2db2432cb002e7abbf3dd869`
- **UniversalRouter**: `0xa51afafe0263b40edaef0df8781ea9aa03e381a3`

**Current Implementation:**
- ✅ `FlowraHook.sol` implements the BaseHook interface
- ✅ FlowraCore connected to v4 PoolManager on Arbitrum
- ✅ Automated DCA swaps via `beforeSwap()` and `afterSwap()` hooks
- ✅ CREATE2 deployment pattern for deterministic hook addresses
- 🔜 **Next**: Deploy FlowraHook and initialize USDC/WETH pool

**Hook Capabilities:**
- **Automated DCA Execution**: Swaps triggered by pool interactions (no keepers needed!)
- **Liquidity-Based Swaps**: Execute trades only when sufficient pool liquidity exists
- **Gas Optimization**: Batch multiple user swaps in single hook execution
- **Slippage Protection**: Built-in 1% max slippage via hook logic

**Why Hooks Matter:**
Traditional DCA requires external keepers/bots → costly & centralized. With Uniswap v4 hooks, swaps execute **automatically** whenever anyone interacts with the pool → **trustless, permissionless, and capital-efficient**.

**Architecture Benefits:**
- 🔥 **Zero keeper costs** - Piggybacks on organic pool activity
- 🛡️ **Decentralized execution** - No reliance on off-chain infrastructure
- ⚡ **Gas efficient** - Amortizes costs across multiple user swaps
- 🔒 **MEV resistant** - Execution within pool transactions

## 💡 Key Features

- ✅ **Minimum deposit**: 1 USDC (testing) / 100 USDC (production)
- ✅ **User-controlled yield donation**: Choose 1-20% to public goods
- ✅ **Select up to 6 projects**: Support causes you care about
- ✅ **Aave v3 yield generation**: Earn interest on idle USDC deposits
- ✅ **Uniswap v4 LIVE**: Hook deployed and connected to mainnet pool
- ✅ **DCA automation**: 1% swaps every 5 minutes (testing) / 24 hours (production)
- ✅ **Zero keeper costs**: Swaps execute via Uniswap v4 hooks automatically
- ✅ **Emergency pause** functionality
- ✅ **Reentrancy protection** on all external functions
- ✅ **Gas optimized** (1M runs, via IR compilation)

## 🧪 Testing the Deployed System

### ✅ System Ready - Start Testing Now!

**All setup complete!** Pool key configured, hook connected, system operational.

### Quick Test Flow

**Step 1: Make a Test Deposit**
```bash
# Approve USDC (100 USDC = 100000000 with 6 decimals)
cast send 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
  "approve(address,uint256)" \
  0xB2F2600792605Fb04a7eB0CfCAd6DFfDf5330B14 \
  100000000 \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer

# Deposit 100 USDC with 10% yield to Flowra project (ID 0)
cast send 0xB2F2600792605Fb04a7eB0CfCAd6DFfDf5330B14 \
  "deposit(uint256,uint256,uint256[])" \
  100000000 \
  1000 \
  "[0]" \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer
```

**Step 2: Monitor Swap Queue**
```bash
# Check pending swaps
cast call 0x1c95Da298E99Fb478C30823afA7b59A0Ff7b99DF \
  "getPendingSwapCount()" \
  --rpc-url $ARBITRUM_RPC_URL

# Check if you're in queue
cast call 0x1c95Da298E99Fb478C30823afA7b59A0Ff7b99DF \
  "isInQueue(address)" \
  0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45 \
  --rpc-url $ARBITRUM_RPC_URL
```

**Step 3: Wait for Automated Swap**
- ⏱️ **Testing**: Wait **5 minutes** after deposit (~8.3 hours total)
- 📅 **Production**: Wait **24 hours** after deposit (~100 days total)
- 🔄 Next swap on USDC/WETH pool triggers your DCA swap **automatically**!
- 🔥 **Zero keeper costs** - Swaps execute via Uniswap v4 hooks

**Step 4: Manual Swap (Optional - Testing Only)**
```bash
# Trigger swap manually as executor
cast send 0xB2F2600792605Fb04a7eB0CfCAd6DFfDf5330B14 \
  "executeSwap(address)" \
  0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45 \
  --rpc-url $ARBITRUM_RPC_URL \
  --account monad-deployer
```

### DCA Settings

| Setting | Testing | Production |
|---------|---------|------------|
| **Swap Interval** | 5 minutes | 24 hours |
| **Swap Amount** | 1% per swap | 1% per swap |
| **Min Deposit** | 1 USDC | 100 USDC |
| **Total Duration** | ~8.3 hours | ~100 days |

**To change for production**: Update `DEFAULT_SWAP_INTERVAL` in `src/libraries/FlowraMath.sol` to `86400` (24 hours).

## 🔐 Security

### Access Control
- Owner-only functions for pausing, project management
- Role-based access (Core → Vault/Router)
- Executor role for manual swap triggers
- Multi-sig recommended for production

### Safety Features
- ReentrancyGuard on all external functions
- Pausable for emergencies
- Input validation on all parameters
- Slippage protection (1% max)
- Aave health factor monitoring
- 5-minute cooldown between swaps (testing)

### Audit Status
⚠️ **Not yet audited** - This is a hackathon prototype. Comprehensive audit recommended before mainnet use with significant funds.

## 📚 Documentation

- [Architecture Document](../FLOWRA_ARCHITECTURE.md)
- [Implementation Summary](../IMPLEMENTATION_SUMMARY.md)
- [Uniswap v4 Docs](https://docs.uniswap.org/contracts/v4/overview)
- [Aave v3 Docs](https://docs.aave.com/developers/)
- [Octant Docs](https://docs.octant.app/)

## 📁 Project Structure

```
flowra-contracts/
├── src/
│   ├── FlowraCore.sol           # Main coordinator
│   ├── FlowraAaveVault.sol      # Aave integration
│   ├── FlowraYieldRouter.sol    # Yield distribution
│   ├── FlowraHook.sol           # Uniswap v4 hook
│   ├── interfaces/              # Contract interfaces
│   └── libraries/               # Shared libraries
├── script/
│   ├── Deploy.s.sol            # Deployment script
│   ├── AddProjects.s.sol       # Project management
│   └── Verify.s.sol            # Verification helper
├── test/
│   └── FlowraCore.t.sol        # Test suite
├── foundry.toml                # Foundry config
└── README.md                   # This file
```

## 🤝 Contributing

Contributions welcome!

**Built by**:
- **0xOucan** ([@0xoucan](https://x.com/0xoucan)) - Protocol design & implementation
- **Claude** - Development assistant

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Add tests for new features
4. Commit changes (`git commit -m 'Add amazing feature'`)
5. Push to branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎓 Hackathon Submission

**Event**: Octant DeFi Hackathon 2025
**Team**: 0xOucan
**Contact**: [@0xoucan](https://x.com/0xoucan) on X (Twitter)
**Submission Date**: January 8, 2025 (Latest Deployment)

### 🏆 Hackathon Highlights

**What We Built:**
- ✅ **Complete DeFi Protocol** - Fully deployed and operational on Arbitrum mainnet
- ✅ **Uniswap v4 Integration** - Live hook implementation with automated DCA swaps
- ✅ **Octant v2 Inspired** - User-controlled yield donation mechanism
- ✅ **Aave v3 Integration** - Passive yield generation on idle deposits
- ✅ **Zero Keeper Costs** - Automated swaps via Uniswap v4 hooks (no bots needed!)
- ✅ **Production Ready** - All contracts verified on Arbiscan

**Innovation:**
1. **First to combine**: DCA automation + Yield generation + Public goods funding
2. **Hook-powered DCA**: Eliminates need for expensive keeper infrastructure
3. **User sovereignty**: Full control over yield allocation and project selection
4. **Capital efficient**: Idle funds earn yield while waiting for DCA execution

**Technical Achievements:**
- 4 smart contracts deployed and verified
- Automated swap execution via Uniswap v4 hooks
- Integration with 3 major DeFi protocols (Uniswap v4, Aave v3, Octant v2)
- 6 public goods projects onboarded
- Complete testing and deployment automation scripts

**Live Demo:**
- **FlowraCore**: https://arbiscan.io/address/0xB2F2600792605Fb04a7eB0CfCAd6DFfDf5330B14
- **FlowraAaveVault**: https://arbiscan.io/address/0x0830637a1CEAA4dE039b186Ea9060d89AB63C1BE
- **FlowraYieldRouter**: https://arbiscan.io/address/0x8ba6246D59C8516Bb3522ce00fC95a3970b4C2B5
- **FlowraHook**: https://arbiscan.io/address/0x1c95Da298E99Fb478C30823afA7b59A0Ff7b99DF
- **USDC/WETH Pool**: https://app.uniswap.org/explore/pools/arbitrum/0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8

**Try It Yourself:**
```bash
git clone https://github.com/0xOucan/flowracontracts
cd flowracontracts
./finalize-hook.sh  # Set pool key
# Make test deposit (see Testing section above)
```

## 🔗 Resources

- [Flowra Mission](../evvmdocscrapper-main/dist/flowra-llms-full.txt)
- [Arbitrum Documentation](https://docs.arbitrum.io/)
- [Foundry Book](https://book.getfoundry.sh/)

## ⚠️ Disclaimer

This software is provided "as is" without warranty. Not audited. Use at your own risk.

---

## 📋 Quick Reference

### Contract Addresses (Copy-Paste Ready)

```bash
# Core Contracts
export FLOWRA_CORE=0xB2F2600792605Fb04a7eB0CfCAd6DFfDf5330B14
export FLOWRA_AAVE_VAULT=0x0830637a1CEAA4dE039b186Ea9060d89AB63C1BE
export FLOWRA_YIELD_ROUTER=0x8ba6246D59C8516Bb3522ce00fC95a3970b4C2B5
export FLOWRA_HOOK=0x1c95Da298E99Fb478C30823afA7b59A0Ff7b99DF

# Tokens
export USDC=0xaf88d065e77c8cC2239327C5EDb3A432268e5831
export WETH=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1

# Protocol Addresses
export AAVE_POOL=0x794a61358D6845594F94dc1DB02A252b5b4814aD
export POOL_MANAGER=0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32

# Network
export ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
export CHAIN_ID=42161

# Deployer (for reference)
export DEPLOYER=0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45
```

### Solidity Addresses

```solidity
// Core Protocol
address constant FLOWRA_CORE = 0xB2F2600792605Fb04a7eB0CfCAd6DFfDf5330B14;
address constant FLOWRA_AAVE_VAULT = 0x0830637a1CEAA4dE039b186Ea9060d89AB63C1BE;
address constant FLOWRA_YIELD_ROUTER = 0x8ba6246D59C8516Bb3522ce00fC95a3970b4C2B5;
address constant FLOWRA_HOOK = 0x1c95Da298E99Fb478C30823afA7b59A0Ff7b99DF;

// Tokens
address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

// Protocol Integrations
address constant AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
address constant POOL_MANAGER = 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32;
```

### TypeScript/JavaScript

```typescript
// Contract addresses for Arbitrum One
export const CONTRACTS = {
  FLOWRA_CORE: '0xB2F2600792605Fb04a7eB0CfCAd6DFfDf5330B14',
  FLOWRA_AAVE_VAULT: '0x0830637a1CEAA4dE039b186Ea9060d89AB63C1BE',
  FLOWRA_YIELD_ROUTER: '0x8ba6246D59C8516Bb3522ce00fC95a3970b4C2B5',
  FLOWRA_HOOK: '0x1c95Da298E99Fb478C30823afA7b59A0Ff7b99DF',
  USDC: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
  WETH: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
  AAVE_POOL: '0x794a61358D6845594F94dc1DB02A252b5b4814aD',
  POOL_MANAGER: '0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32',
} as const
```

---

**Made with ❤️ for public goods funding**
