# Monad Escrow — MVP

A time-based escrow contract for Monad testnet/mainnet.

**How it works:**
- Buyer deposits MON (native) or an ERC20 token (e.g. USDC) for a seller, with a `releaseTime`.
- If nothing happens, anyone can call `release()` after that time and the seller gets paid — fully automatic, no third party needed.
- If either party has a problem, they call `raiseDispute()` *before* the release time. This freezes auto-release.
- Once disputed, either party can `proposeSplit()` (e.g. "60% back to buyer, 40% to seller"), and the *other* party calls `acceptSplit()` to execute it. Funds only move when both agree.

There is currently no arbitrator/admin override — if the two parties can't agree on a split, funds stay locked in the disputed state. That's a deliberate MVP simplification; the next version can add a time-boxed arbitrator fallback if you want one.

---

## ⚠️ Before this touches real client money

This is a **testnet-ready MVP**, not an audited production system. Escrow contracts are one of the most common smart contract exploit targets. Before deploying to mainnet with real funds:

1. Test extensively on testnet with real dispute/split flows, not just the happy path.
2. Get the contract reviewed — even a paid one-time review from a smart contract security freelancer (much cheaper than a full audit firm) is far better than nothing.
3. Consider a bug bounty or a small-value soft launch before handling large sums.

Skipping this step is the single biggest risk to your business and your clients' money.

---

## Setup

```bash
npm install
cp .env.example .env
```

Edit `.env`:
- `PRIVATE_KEY` — a wallet private key to deploy from. **For testnet, use a throwaway wallet, not your main one.**

## Get testnet MON

1. Add Monad Testnet to MetaMask — Chain ID `10143`, RPC `https://monad-testnet.drpc.org` (or use chainlist.org and search "Monad Testnet").
2. Get free test MON from the official Monad faucet (search "Monad testnet faucet" — faucet URLs change, so check monad.xyz/developers for the current one).

## Deploy

```bash
npm run deploy:testnet
```

This prints the deployed contract address — save it, you'll need it for the frontend.

When you're ready for real funds:
```bash
npm run deploy:mainnet
```
(Mainnet Chain ID `143`, RPC `https://rpc.monad.xyz` — already configured in `hardhat.config.js`.)

## Files

- `contracts/MonadEscrow.sol` — the escrow logic
- `scripts/deploy.js` — deployment script
- `hardhat.config.js` — network configuration for Monad testnet/mainnet
- `compile-check.js` — standalone compiler sanity check (doesn't need Hardhat's network access)

## Next step: frontend

This repo is contract-only. Next we'd build a simple web frontend (wallet connect + create/release/dispute buttons) so your clients don't need MetaMask console skills. Ask me to build that next.
