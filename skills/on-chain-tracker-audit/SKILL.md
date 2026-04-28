---
name: on-chain-tracker-audit
description: Audit a blockchain deposit tracker by comparing off-chain DB data against the smart contract's on-chain ground truth. Detect overcounts, missed deposits, and phantom transfers.
version: 1.0.0
category: devops
---

# On-Chain Deposit Tracker Audit

Audit a bot/service that monitors blockchain deposits by comparing its tracked data against the smart contract's own ground truth.

## When to Use

- Monitoring bot shows different totals than the website/contract
- Verifying that a deposit tracker hasn't missed or double-counted events
- Debugging discrepancies between off-chain indexing and on-chain state

## Step-by-Step

### 1. Get the Contract's Ground Truth

The contract's storage is the authoritative source. Read it directly:

```bash
# Read storage slots (use eth_getStorageAt via Alchemy/Infura)
# Try slots 0-20, convert raw values to token amounts (divide by 10^decimals)
# Look for values matching the website's displayed total
```

- Common patterns: `totalRaised`, `totalDeposits`, `totalSupply` often in early slots (0-10)
- Token addresses in slot 0, caps/limits in slots 3-5, running totals in slots 6-10
- Use `eth_getStorageAt(contract, slot_hex, "latest")` via JSON-RPC

### 2. Compare Against Tracker DB

```bash
# Sum all tracked amounts from the bot's database
sqlite3 tracker.db "SELECT SUM(CAST(total_amount AS REAL)) / 1e6 FROM wallet_totals;"
```

If DB total ≠ contract total, there's a bug.

### 3. Classify the Discrepancy

| Symptom | Likely Cause |
|---------|-------------|
| DB > contract | Tracker counts transfers that bypass `deposit()` — direct token sends, bridge routing, or duplicate events |
| DB < contract | Missed transfers (WS disconnect, polling gap, wrong token address, or threshold filtering) |

### 4. Identify Phantom/Duplicate Deposits

```bash
# Check if "depositors" are actually smart contracts (bridges, aggregators)
# Use eth_getCode to classify addresses
# 48-byte code starting with 0xef01 = EIP-7702 delegated EOA (real user)
# Large bytecode (>1KB) = likely DEX aggregator/router
```

### 5. Verify Per-Transfer Accuracy

For each Transfer event the bot tracks:

1. Fetch the transaction receipt
2. Check if the tx called `deposit()` (or the relevant deposit function) on the target contract
3. Only count transfers where the deposit function was called — these are "real deposits"

**Critical insight**: Direct `transfer()` calls to the contract address send tokens but don't trigger the contract's deposit accounting. The bot must verify that `deposit()` was called in the same transaction.

### 6. Cross-Check On-Chain Storage

```bash
# For mapping(address => uint256), compute storage location:
# slot = keccak256(abi.encode(address, mappingSlot))
# Read with eth_getStorageAt

# Try common function selectors for unverified contracts:
# deposits(address): 0x6e26f9c3
# balanceOf(address): 0x70a08231
# invested(address): 0x5da96a5f
```

### 7. Gap Scan (Verify No Missed Deposits)

```bash
# Compare bot's last scanned block vs current block
sqlite3 tracker.db "SELECT value FROM scan_progress;"

# Scan the gap for Transfer events in 10-block chunks (Alchemy free tier limit)
# If no new events found in the gap → no missed deposits
```

## Fix: Read Contract-Verified Total Instead of Summing Transfers

When the bot overcounts because it sums ALL Transfer events, replace the
DB-derived total with a direct contract storage read:

```javascript
export async function readContractTotalRaised(provider, contractAddress) {
  const TOTAL_RAISED_SLOT = 6; // Verify against actual contract layout
  try {
    const rawValue = await provider.getStorage(contractAddress, TOTAL_RAISED_SLOT);
    const totalMicroUSDT = BigInt(rawValue);
    // BigInt-safe: avoid Number() which loses precision above ~$9M for 6-decimal tokens
    const whole = totalMicroUSDT / 1_000_000n;
    const frac = totalMicroUSDT % 1_000_000n;
    const fracStr = frac.toString().padStart(6, '0').slice(0, 2);
    return Number(`${whole}.${fracStr}`);
  } catch (err) {
    console.error('[TRACKER] Error reading totalRaised:', err.message);
    return null; // Graceful degradation — omit field from embed
  }
}
```

Key decisions:
- **Don't cache** — per-deposit call shows current authoritative total
- **Return null on error** — embed omits the field, doesn't break
- **Storage slot is hardcoded** — storage layout is a compile-time constant
- **Document verification date** — slot position, contract address, how verified

Per-wallet totals from the DB are still useful as estimates (renamed from
"Total Invested" to "Wallet Total" to avoid confusion with the authoritative
contract-verified "Total Raised").

## Common Pitfalls

- **Unverified contracts**: No ABI available. Use storage slot probing instead of function calls.
- **EIP-7702 accounts**: Addresses with 48-byte `0xef01...` code are delegated EOAs (real users), NOT routers.
- **Proxy contracts**: Storage lives in the proxy, not the implementation. Read storage from the proxy address.
- **Transfer vs Deposit**: `Transfer(from, to, amount)` ≠ `deposit()` call. Always verify the tx input data.
- **Multiple token paths**: Bridge may convert ETH→USDT, creating a Transfer from bridge→contract. The "from" is the bridge, not the user.
- **BigInt precision**: `Number(BigInt)` loses precision above 2^53. For 6-decimal tokens, this means ~$9M. Use BigInt-safe string formatting instead.

## Quick Health Check

```bash
# 1. Service running?
systemctl status <service>

# 2. DB has data?
sqlite3 tracker.db "SELECT COUNT(*) FROM wallet_totals;"

# 3. Heartbeat logs?
journalctl -u <service> --since "5 min ago" | grep HEALTH

# 4. WS connected?
# Look for: [HEALTH] WS=OPEN ... pollErrors=0

# 5. Total matches contract?
# Compare DB sum vs eth_getStorageAt total
```

## Tools

- `sqlite3` for DB queries
- `curl` + Alchemy JSON-RPC for on-chain data
- `eth_getStorageAt` for contract storage reads
- `eth_getCode` for address classification (EOA vs contract vs EIP-7702)