# Arbitrum One Contract Addresses

Official contract addresses for Arbitrum One mainnet (Chain ID: 42161)

## Aave v3 Protocol

Source: https://github.com/bgd-labs/aave-address-book/blob/main/src/AaveV3Arbitrum.sol

### Core Contracts

| Name | Address | Usage in Flowra |
|------|---------|----------------|
| **Pool** | `0x794a61358D6845594F94dc1DB02A252b5b4814aD` | ✅ Used in FlowraAaveVault |
| PoolAddressesProvider | `0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb` | Reference |
| PoolConfigurator | `0x8145eddDf43f50276641b55bd3AD95944510021E` | Reference |
| AaveProtocolDataProvider | `0x243A33AB9c78dEfe3e16312E8c73C7BAB5F80d6b` | Optional (for analytics) |
| ACLManager | `0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B` | Reference |

### Utility Contracts

| Name | Address | Usage |
|------|---------|-------|
| UiPoolDataProvider | `0x5c52fd8e597D7EFeEfb80bFDB5d55c23D0dDB8717` | Frontend integration |
| UiIncentiveDataProvider | `0x6810e776880c02933d47db1b9fc05908e5386b96` | Rewards data |
| WalletBalanceProvider | `0xBc790382B3686abffE4be14A030A96aC6154023a` | Multi-wallet balance |

### Governance & Treasury

| Name | Address | Usage |
|------|---------|-------|
| TreasuryCollector | `0x053D55f9B5AF8694c503EB288a1B7E552f590710` | Reference |
| ACLAdmin | `0xFF1137243698CaA18EE364Cc966CF0e02A4e6327` | Reference |

### Advanced Features

| Name | Address | Usage |
|------|---------|-------|
| DefaultIncentivesController | `0x929EC64c34a17401F460460D4B9390518E5B473e` | Optional rewards |
| AaveOracle | `0xb56c2F0B653B2e0b10C9b928C8580Ac5Df02C7C7` | Price feeds |
| RepayWithCollateral | `0xE28E2c8d240dd5eBd0adcab86fbD79df7a052034` | Future feature |
| DebtSwitch | `0x63df6460ec4e9Bb5c2bEa3Cae5D8d69CE71E8251C8A4` | Future feature |

## Tokens

### Stablecoins

| Token | Address | Decimals | Usage in Flowra |
|-------|---------|----------|----------------|
| **USDC** | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` | 6 | ✅ Primary deposit token |
| USDT | `0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9` | 6 | Future support |
| DAI | `0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1` | 18 | Future support |

### ETH

| Token | Address | Decimals | Usage in Flowra |
|-------|---------|----------|----------------|
| **WETH** | `0x82aF49447D8a07e3bd95BD0d56f35241523fBab1` | 18 | ✅ DCA target token |

## Uniswap v4

### Core Contracts

| Name | Address | Usage in Flowra |
|------|---------|----------------|
| **PoolManager** | `0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32` | ✅ Used in FlowraCore (when v4 launches) |

**Note**: Uniswap v4 is not yet live on Arbitrum mainnet. This address is from documentation and may change.

## Network Information

### RPC URLs

**Primary (Official)**:
```
https://arb1.arbitrum.io/rpc
```

**Fast Alternatives**:
```
https://arbitrum.drpc.org
https://arbitrum-one.public.blastapi.io
https://arbitrum.gateway.tenderly.co
https://arbitrum-one.publicnode.com
https://1rpc.io/arb
```

**Rate-Limited Free**:
```
https://arb-mainnet.g.alchemy.com/v2/demo
https://arbitrum.api.onfinality.io/public
```

### Network Details

| Parameter | Value |
|-----------|-------|
| Chain ID | 42161 |
| Native Token | ETH |
| Block Time | ~0.25s |
| Finality | ~15 minutes (L1 confirmation) |

### Block Explorers

| Name | URL | API Key Needed |
|------|-----|----------------|
| **Arbiscan** | https://arbiscan.io/ | ✅ For verification |
| Arbitrum Explorer | https://explorer.arbitrum.io/ | No |

## Flowra Deployed Contracts

After deployment, add your contract addresses here:

### Core Protocol

| Contract | Address | Verified |
|----------|---------|----------|
| FlowraCore | `TBD` | ❌ |
| FlowraAaveVault | `TBD` | ❌ |
| FlowraYieldRouter | `TBD` | ❌ |

### Optional

| Contract | Address | Verified |
|----------|---------|----------|
| FlowraHook | `TBD` | ❌ (when Uniswap v4 launches) |

## Testing Contracts

### Aave v3 Testing

All Aave v3 contracts are already deployed and tested on Arbitrum mainnet:
- ✅ $500M+ TVL on Arbitrum
- ✅ 2+ years of battle-testing
- ✅ Multiple audits (Trail of Bits, ABDK, Peckshield)

**Recommendation**: Test with 1-5 USDC on mainnet instead of testnet for:
1. Real Aave liquidity
2. Real USDC behavior
3. Real gas costs
4. Low risk ($2 max)

### Contract Addresses Storage

After deployment, addresses are saved to:
```
deployments/arbitrum-mainnet.json
```

Format:
```json
{
  "flowraCore": "0x...",
  "aaveVault": "0x...",
  "yieldRouter": "0x...",
  "usdc": "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
  "weth": "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
  "aavePool": "0x794a61358D6845594F94dc1DB02A252b5b4814aD"
}
```

## Verification Commands

### Verify on Arbiscan

```bash
# FlowraCore
forge verify-contract <CONTRACT_ADDRESS> \
  src/FlowraCore.sol:FlowraCore \
  --chain-id 42161 \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" \
    0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
    0x82aF49447D8a07e3bd95BD0d56f35241523fBab1 \
    0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32)

# FlowraAaveVault
forge verify-contract <CONTRACT_ADDRESS> \
  src/FlowraAaveVault.sol:FlowraAaveVault \
  --chain-id 42161 \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" \
    0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
    0x794a61358D6845594F94dc1DB02A252b5b4814aD)

# FlowraYieldRouter
forge verify-contract <CONTRACT_ADDRESS> \
  src/FlowraYieldRouter.sol:FlowraYieldRouter \
  --chain-id 42161 \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address)" \
    0xaf88d065e77c8cC2239327C5EDb3A432268e5831)
```

## Quick Reference Commands

### Check USDC Balance
```bash
cast call 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
  "balanceOf(address)" <YOUR_ADDRESS> \
  --rpc-url https://arb1.arbitrum.io/rpc
```

### Check Aave Pool Liquidity
```bash
cast call 0x794a61358D6845594F94dc1DB02A252b5b4814aD \
  "getReserveData(address)" 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 \
  --rpc-url https://arb1.arbitrum.io/rpc
```

### Get Latest Block
```bash
cast block-number --rpc-url https://arb1.arbitrum.io/rpc
```

## Resources

- **Aave v3 Docs**: https://docs.aave.com/developers/deployed-contracts/v3-mainnet/arbitrum
- **Aave Address Book**: https://github.com/bgd-labs/aave-address-book
- **Arbitrum Docs**: https://docs.arbitrum.io/
- **Arbiscan**: https://arbiscan.io/
- **Chainlist**: https://chainlist.org/chain/42161

---

**Last Updated**: 2025-01-XX
**Source**: Official Aave v3 deployments + Arbitrum docs
