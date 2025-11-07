# Test Setup Configuration Changes

This branch (`testsetup`) contains modifications for hackathon testing and demonstration on Arbitrum mainnet.

## 🔧 Changes Made

### 1. Testing Parameters

**FlowraMath.sol**:
- `MIN_DEPOSIT`: Changed from 100 USDC → **1 USDC** (for easier testing)
- `SECONDS_PER_DAY`: Changed from 86400 (24h) → **60 seconds (1 minute)** for rapid swap testing

### 2. EXECUTOR Role System

**Problem Solved**: Uniswap v4 hooks execute automatically when swaps happen on the pool, but if pool activity is low, DCA swaps won't trigger.

**Solution**: Added EXECUTOR role for manual/automated execution fallback.

**Changes to FlowraCore.sol**:

#### New Role
```solidity
bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
```

#### Role Management Functions
- `grantExecutor(address)` - Admin grants executor role
- `revokeExecutor(address)` - Admin revokes executor role  
- `isExecutor(address)` - Check if address is executor

#### Executor Functions
- `executeSwapBatch(address[] users)` - Batch execute swaps for multiple users
  - Only callable by EXECUTOR_ROLE
  - Continues on individual failures
  - Returns success count
  - Gas-efficient for processing many users

#### Updated Documentation
- `executeSwap()` - Now documented as callable by anyone, hooks, or executors

## 🤖 Execution Model

### Automatic Execution (Primary)
When someone swaps on the USDC/WETH Uniswap v4 pool:
1. Hook's `beforeSwap()` triggers automatically
2. Checks queue for ready users
3. Executes their DCA swap piggyback-style
4. **No keeper needed!**

### Manual Execution (Fallback)
When pool activity is low:
1. Server-based wallet with EXECUTOR_ROLE monitors blockchain
2. Queries `canSwap(user)` for each user
3. Calls `executeSwapBatch([user1, user2, ...])` 
4. Executes swaps manually

## 🚀 Deployment Strategy for Testing

### Step 1: Deploy Contracts
```bash
forge script script/Deploy.s.sol --rpc-url $ARBITRUM_RPC_URL --broadcast
```

### Step 2: Grant Executor Role
```bash
# In your deployment script or manually:
flowraCore.grantExecutor(EXECUTOR_WALLET_ADDRESS);
```

### Step 3: Server Setup
Create a viem.sh script that:
1. Monitors user positions
2. Checks timestamps (every minute in testing)
3. Calls `executeSwapBatch()` for ready users

### Step 4: Test with Small Amounts
- Users deposit 1-10 USDC
- Swaps happen every minute
- Monitor via events

## 💻 Server-Side Executor Script (Pseudocode)

```javascript
// viem.sh implementation
import { createWalletClient } from 'viem'

const executorWallet = createWalletClient({
  account: privateKeyToAccount(EXECUTOR_PRIVATE_KEY),
  chain: arbitrum,
})

async function monitorAndExecute() {
  while (true) {
    // Get all active users (implement getActiveUsers)
    const users = await getAllActiveUsers()
    
    // Filter users ready for swap
    const readyUsers = []
    for (const user of users) {
      const canSwap = await flowraCore.read.canSwap([user])
      if (canSwap) {
        readyUsers.push(user)
      }
    }
    
    // Execute batch if any ready
    if (readyUsers.length > 0) {
      const { hash } = await flowraCore.write.executeSwapBatch([readyUsers])
      console.log(`Executed ${readyUsers.length} swaps: ${hash}`)
    }
    
    // Wait 30 seconds before next check
    await sleep(30000)
  }
}
```

## 🔐 Security Notes

### Executor Role Permissions
- ✅ **CAN**: Execute swaps for users (no value transfer to executor)
- ✅ **CAN**: Batch process multiple users efficiently
- ❌ **CANNOT**: Withdraw user funds
- ❌ **CANNOT**: Modify positions
- ❌ **CANNOT**: Pause protocol
- ❌ **CANNOT**: Change protocol parameters

### Admin Functions (Owner Only)
- Pause/unpause protocol
- Set Aave vault address
- Set yield router address
- Set hook contract address
- Harvest yield for distribution
- Grant/revoke roles

## 📊 Testing Checklist

- [ ] Deploy all contracts to Arbitrum mainnet
- [ ] Grant EXECUTOR_ROLE to server wallet
- [ ] Deploy server with viem.sh executor script
- [ ] Test deposit (1 USDC minimum)
- [ ] Verify swap executes after 1 minute
- [ ] Test batch execution with multiple users
- [ ] Monitor gas costs
- [ ] Test yield harvesting
- [ ] Test yield distribution to projects
- [ ] Verify emergency pause works

## 🔄 Differences from Production

| Parameter | Main Branch | testsetup Branch |
|-----------|-------------|------------------|
| MIN_DEPOSIT | 100 USDC | 1 USDC |
| Swap Interval | 24 hours | 1 minute |
| Executor Role | No | Yes (for testing) |
| Batch Execution | No | Yes |

## ⚠️ Important Notes

1. **Swap Interval**: 1 minute is ONLY for testing. Production should use 24 hours.
2. **Minimum Deposit**: 1 USDC is ONLY for testing. Production should use 100 USDC.
3. **Executor Role**: Consider removing in production if pool has sufficient activity.
4. **Gas Costs**: Monitor executor wallet balance - executing swaps costs gas.
5. **Uniswap v4**: Not yet deployed on Arbitrum - hook won't work until v4 is live.

## 🎯 Expected Behavior

1. User deposits 10 USDC
2. DCA position created (0.1 USDC per swap, 100 swaps total)
3. Every minute (after 60 seconds):
   - Either pool swap triggers hook → automatic execution
   - Or executor bot calls `executeSwapBatch()` → manual execution
4. User accumulates WETH over time
5. Idle USDC earns yield on Aave
6. Yield distributed to projects

