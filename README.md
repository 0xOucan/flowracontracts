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
- **Deposit USDC** and automatically DCA into WETH (1% daily swaps)
- **Earn yield** on idle USDC via Aave v3 integration
- **Fund public goods** by routing earned yield to selected projects

**No keepers needed** - Swaps execute automatically via Uniswap v4 hooks!

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

## 📦 Contracts

### Core Contracts

| Contract | Description | Location |
|----------|-------------|----------|
| **FlowraCore** | Main coordinator for deposits & DCA | `src/FlowraCore.sol` |
| **FlowraAaveVault** | Aave v3 yield generation | `src/FlowraAaveVault.sol` |
| **FlowraYieldRouter** | Octant v2 yield distribution | `src/FlowraYieldRouter.sol` |
| **FlowraHook** | Uniswap v4 automated swaps | `src/FlowraHook.sol` |

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

Edit `.env` file:

```bash
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
PRIVATE_KEY=your_private_key_here
ARBISCAN_API_KEY=your_arbiscan_api_key
```

### Deploy to Arbitrum Mainnet

```bash
# 1. Deploy core contracts
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast \
  --verify

# 2. Add project wallets for yield distribution
# (Edit script/AddProjects.s.sol first with your project wallets)
forge script script/AddProjects.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast

# 3. Verify contracts (optional - already done with --verify flag)
forge script script/Verify.s.sol \
  --rpc-url $ARBITRUM_RPC_URL
```

**Note**: Deployment addresses are saved to `deployments/arbitrum-mainnet.json`

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

## 💡 Key Features

- ✅ **Minimum deposit**: 100 USDC
- ✅ **DCA strategy**: Daily 1% USDC → WETH swaps
- ✅ **24-hour cooldown** between swaps
- ✅ **Aave yield generation** on idle capital
- ✅ **Yield distribution** to public goods projects
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
