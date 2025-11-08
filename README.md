# Flowra Smart Contracts 🌱

> Plant your crypto, grow impact

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.26-363636?style=flat-square&logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C?style=flat-square)](https://book.getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

Flowra is a multi-contract DeFi protocol combining **DCA automation**, **yield generation**, and **public goods funding** on Arbitrum mainnet.

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
**Deployed**: November 8, 2025
**Status**: ✅ Verified & Operational

### Deployed Contracts

| Contract | Address | Arbiscan |
|----------|---------|----------|
| **FlowraCore** | `0x3811AC2f669a7e57A60C06bE135DfB297a6E7639` | [View](https://arbiscan.io/address/0x3811AC2f669a7e57A60C06bE135DfB297a6E7639) |
| **FlowraAaveVault** | `0x4815146A7bC82621d00A9B6c53E7388365692817` | [View](https://arbiscan.io/address/0x4815146A7bC82621d00A9B6c53E7388365692817) |
| **FlowraYieldRouter** | `0xa757f81Cc0309a4Ef70e43d221C3292d572b1bB1` | [View](https://arbiscan.io/address/0xa757f81Cc0309a4Ef70e43d221C3292d572b1bB1) |

### Configuration

- **Executor Address**: `0xcce721fC201D4571A5AC826A3e0908F81807fAa5` (has EXECUTOR_ROLE)
- **6 Public Goods Projects**: ✅ Added and ready
- **Aave v3 Integration**: ✅ Connected to Arbitrum Aave Pool
- **All contracts verified** on Arbiscan

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

**Note**:
- Deployment addresses are saved to `deployments/arbitrum-mainnet.json`
- You'll be prompted for your wallet password during deployment
- Recommended minimum balance: 0.05 ETH on Arbitrum (actual cost ~0.0001 ETH)

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
Aave v3 Pool: 0x794a61358D6845594F94dc1DB02A252b5b4814aD
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
- Built for Uniswap v4 hook compatibility (ready when v4 launches on Arbitrum)

### Uniswap v4 Hooks Architecture

Flowra is designed with **Uniswap v4 Hooks** at its core:

**Current Implementation:**
- `FlowraHook.sol` implements the BaseHook interface
- Prepared for automated DCA swaps via `beforeSwap()` and `afterSwap()` hooks
- CREATE2 deployment pattern for deterministic hook addresses
- Ready to integrate when Uniswap v4 launches on Arbitrum mainnet

**Hook Capabilities (When v4 is Live):**
- **Automated DCA Execution**: Swaps triggered by pool interactions (no keepers needed!)
- **Liquidity-Based Swaps**: Execute trades only when sufficient pool liquidity exists
- **Gas Optimization**: Batch multiple user swaps in single hook execution
- **Slippage Protection**: Built-in 1% max slippage via hook logic

**Why Hooks Matter:**
Traditional DCA requires external keepers/bots → costly & centralized. With Uniswap v4 hooks, swaps execute automatically whenever anyone interacts with the pool → **trustless, permissionless, and capital-efficient**.

## 💡 Key Features

- ✅ **Minimum deposit**: 100 USDC
- ✅ **User-controlled yield donation**: Choose 1-20% to public goods
- ✅ **Select up to 6 projects**: Support causes you care about
- ✅ **Aave v3 yield generation**: Earn interest on idle USDC deposits
- ✅ **Uniswap v4 ready**: Hook implementation prepared for mainnet launch
- ✅ **DCA automation**: Gradual USDC → WETH conversion (hook-enabled)
- ✅ **Emergency pause** functionality
- ✅ **Reentrancy protection** on all external functions
- ✅ **Gas optimized** (1M runs, via IR compilation)

## 🔐 Security

### Access Control
- Owner-only functions for pausing, project management
- Role-based access (Core → Vault/Router)
- Multi-sig recommended for production

### Safety Features
- ReentrancyGuard on all external functions
- Pausable for emergencies
- Input validation on all parameters
- Slippage protection (1% max)
- Aave health factor monitoring

### Audit Status
⚠️ **Not yet audited** - Audit recommended before mainnet deployment

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

## 🎓 Hackathon Info

**Event**: Octant DeFi Hackathon 2025
**Team**: 0xOucan
**Contact**: [@0xoucan](https://x.com/0xoucan) on X (Twitter)

## 🔗 Resources

- [Flowra Mission](../evvmdocscrapper-main/dist/flowra-llms-full.txt)
- [Arbitrum Documentation](https://docs.arbitrum.io/)
- [Foundry Book](https://book.getfoundry.sh/)

## ⚠️ Disclaimer

This software is provided "as is" without warranty. Not audited. Use at your own risk.

---

**Made with ❤️ for public goods funding**
