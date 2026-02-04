# Page Specification

This document describes the behavior, data requirements, and functionality of each page in the Tokamak Delegate Staking dApp.

---

## Table of Contents

1. [Home Page (/)](#1-home-page-)
2. [Sequencers Page (/sequencers)](#2-sequencers-page-sequencers)
3. [Sequencer Detail Page (/sequencers/[address])](#3-sequencer-detail-page-sequencersaddress)
4. [Dashboard Page (/dashboard)](#4-dashboard-page-dashboard)
5. [Admin Page (/admin)](#5-admin-page-admin)

---

## 1. Home Page (/)

### Purpose
Landing page that introduces the Tokamak Delegate Staking service and guides users to key actions.

### Wallet Connection
- **Not Required** - Page is accessible without wallet connection

### Displayed Data

| Section | Data | Source | Notes |
|---------|------|--------|-------|
| Hero | Static text | - | Service introduction |
| Features | Static cards | - | Secure Staking, Earn Rewards, Easy Redelegation |
| Stats | Total Staked | Contract | Currently showing "---" (placeholder) |
| Stats | Active Sequencers | Contract | Currently showing "---" (placeholder) |
| Stats | Total Delegators | Contract | Currently showing "---" (placeholder) |
| Stats | Avg APY | Calculated | Currently showing "---" (placeholder) |
| How It Works | Static steps | - | 4-step guide |

### User Actions
- Navigate to Sequencers page
- Navigate to Dashboard page

### Future Improvements
- Implement real-time stats from contract
- Add total staked amount display
- Show active sequencer count
- Calculate and display average APY

---

## 2. Sequencers Page (/sequencers)

### Purpose
Browse and search all registered sequencers on the network.

### Wallet Connection
- **Not Required** - Page is viewable without wallet
- **Recommended** - For staking actions

### Displayed Data

| Component | Data | Source | Hook |
|-----------|------|--------|------|
| Sequencer List | Array of addresses | `getSequencerList()` | `useSequencerList()` |
| Search Filter | User input | Local state | - |

### Sequencer Card Data

Each sequencer card displays:

| Field | Data | Source | Hook |
|-------|------|--------|------|
| Address | Sequencer address | From list | - |
| Total Staked | `sequencerInfo.totalStaked` | `getSequencerInfo()` | `useSequencerInfo()` |
| Commission | `sequencerInfo.commission` | `getSequencerInfo()` | `useSequencerInfo()` |
| Status | Active/Inactive | `sequencerInfo.isRegistered` | `useSequencerInfo()` |

### User Actions

| Action | Wallet Required | Description |
|--------|-----------------|-------------|
| Search | No | Filter sequencers by address |
| View Details | No | Navigate to sequencer detail page |
| Stake | Yes | Opens stake modal |

### Modals
- **StakeModal** - Stake TON to selected sequencer
- **UnstakeModal** - Unstake TON from sequencer

---

## 3. Sequencer Detail Page (/sequencers/[address])

### Purpose
View detailed information about a specific sequencer and manage staking position.

### Wallet Connection
- **Not Required** - Basic info viewable without wallet
- **Required** - For personal staking data and actions

### URL Parameters
- `address` - Sequencer's Ethereum address

### Displayed Data

#### Header Section (Always Visible)

| Field | Data | Format | Source |
|-------|------|--------|--------|
| Address | Sequencer address | `0x7099...79C8` | URL param |
| Status | Active badge | Green badge | `sequencerInfo.isRegistered` |

#### Stats Grid (Always Visible)

| Card | Data | Format | Source/Hook |
|------|------|--------|-------------|
| Total Staked | `sequencerInfo.totalStaked` | `600.0000 TON` | `useSequencerInfo()` |
| Commission | `sequencerInfo.commission` | `10.00%` | `useSequencerInfo()` |
| Share of Total | Calculated | `100.00%` | `totalStaked / getTotalStaked()` |
| Layer2 Address | `sequencerInfo.layer2` | `0x3976...1c4F` | `useSequencerInfo()` |

#### Your Position (Wallet Connected Only)

| Field | Data | Format | Source/Hook |
|-------|------|--------|-------------|
| Staked Amount | `stakeInfo.amount` | `600 TON` | `useStakeInfo(user, sequencer)` |
| Pending Rewards | `pendingRewards` | `0 WTON` | `usePendingRewards(user, sequencer)` |
| Pending Unstake | `stakeInfo.unstakeAmount` | `0 TON` | `useStakeInfo(user, sequencer)` |

**Not Connected State:**
- Shows "Connect your wallet to view your position and stake"
- "Connect & Stake" button

#### Economics & Rewards Section

##### L2 Eligibility Status

| Field | Data | Source/Hook |
|-------|------|-------------|
| Status | Eligible/Not Eligible | `useCheckLayer2Eligibility(layer2)` |
| Required Stake (θ × Bridged TON) | `eligibility[1]` | `useCheckLayer2Eligibility()` |
| Current Stake | `eligibility[2]` | `useCheckLayer2Eligibility()` |

**Warning Display:** If not eligible, shows how much more TON is needed.

##### Estimated Seigniorage (Always Visible)

| Field | Data | Source/Hook |
|-------|------|-------------|
| Sequencer Reward (for delegators) | `estimatedRewards[0]` | `useEstimateSeigniorage(sequencer)` |
| Validator Reward | `estimatedRewards[1]` | `useEstimateSeigniorage(sequencer)` |

##### Your Estimated Reward (Staked Users Only)

| Field | Data | Calculation |
|-------|------|-------------|
| Your Estimated Reward | WTON | `estimatedRewards[0] * userStake / totalStaked` |
| Your Share | Percentage | `userStake / totalStaked * 100` |

##### Reward Distribution

| Field | Data | Calculation |
|-------|------|-------------|
| Delegators | Percentage | `100 - commission` |
| Sequencer Commission | Percentage | `commission / 100` |

### User Actions

| Action | Button | Wallet Required | Conditions |
|--------|--------|-----------------|------------|
| Stake | "Stake" | Yes | - |
| Unstake | "Unstake" | Yes | `stakeInfo.amount > 0` |
| Copy Address | Copy icon | No | - |
| View on Etherscan | External link | No | Opens Layer2 address |

---

## 4. Dashboard Page (/dashboard)

### Purpose
Personal dashboard to manage all staking positions across sequencers.

### Wallet Connection
- **Required** - Redirects to connect wallet prompt if not connected

### Displayed Data

#### Overview Stats (Top Cards)

| Card | Data | Format | Source/Hook |
|------|------|--------|-------------|
| TON Balance | User's TON balance | `999,400 TON` | `useTonBalance(address)` |
| Total Staked | Sum of all stakes | `600 TON` | `useUserStakingStats()` |
| Claimable Rewards | Sum of pending rewards | `0 WTON` | `useUserStakingStats()` |
| Pending Unstake | Sum of pending unstakes | `0 TON` | `useUserStakingStats()` |

#### Staking Positions

For each registered sequencer, shows a card:

| Field | Data | Source/Hook |
|-------|------|-------------|
| Sequencer Address | Link to detail page | `useSequencerList()` |
| Status Badge | "Staked" (green) / "Not Staked" (gray) | `stakeInfo.amount > 0` |
| Staked | `stakeInfo.amount` | `useStakeInfo(user, sequencer)` |
| Rewards | `pendingRewards` | `usePendingRewards(user, sequencer)` |
| Pending Unstake | `stakeInfo.unstakeAmount` | `useStakeInfo(user, sequencer)` |

### User Actions

| Action | Button | Conditions |
|--------|--------|------------|
| Stake | "Stake" | Always available |
| Unstake | "Unstake" | Only if `stakeInfo.amount > 0` |
| View Sequencer | Click address | Navigates to detail page |

### Not Connected State
- Shows wallet icon
- "Connect Your Wallet" heading
- RainbowKit ConnectButton

---

## 5. Admin Page (/admin)

### Purpose
Sequencer operators can register, manage settings, and claim commissions.

### Wallet Connection
- **Required** - All functionality requires wallet connection

### States

#### 1. Not Connected
- Shows "Connect Your Wallet" prompt

#### 2. Not Registered as Sequencer
Shows registration form:

| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| Layer2 Address | Address input | `isAddress()` | Layer2 contract operated by sequencer |
| OperatorManager Address | Address input | `isAddress()` | From V3 Layer2Manager |
| Commission Rate | Number (0-30%) | `0 <= x <= 30` | Percentage of rewards |

**Action:** "Register Sequencer" button

#### 3. Registered as Sequencer
Shows management panel:

##### Sequencer Status Card

| Field | Data | Source |
|-------|------|--------|
| Address | Connected wallet | `useAccount()` |
| Layer2 | `sequencerInfo.layer2` | `useSequencerInfo()` |
| Commission | `sequencerInfo.commission` | `useSequencerInfo()` |
| Total Staked | `sequencerInfo.totalStaked` | `useSequencerInfo()` |

##### Update Commission Card

| Field | Type | Validation |
|-------|------|------------|
| New Commission Rate | Number input | `0 <= x <= 30` |

**Action:** "Update Commission" button

##### Claim Commission Card

| Field | Data | Source |
|-------|------|--------|
| Claimable Amount | `sequencerInfo.totalCommission` | `useSequencerInfo()` |

**Action:** "Claim Commission" button (disabled if 0)

##### Danger Zone

**Action:** "Deregister Sequencer" button
- **Conditions:** `sequencerInfo.totalStaked === 0n`
- **Warning:** Cannot deregister if there are staked tokens

### Hooks Used

| Hook | Purpose |
|------|---------|
| `useSequencerInfo(address)` | Get sequencer status |
| `useRegisterSequencer()` | Register as sequencer |
| `useUpdateCommission()` | Update commission rate |
| `useClaimCommission()` | Claim accumulated commission |
| `useDeregisterSequencer()` | Remove sequencer registration |

---

## Common Components

### StakeModal
- **Trigger:** "Stake" button on any page
- **Inputs:** Amount in TON
- **Actions:**
  1. Approve TON (if needed)
  2. Stake TON to sequencer
- **Hooks:** `useStake()`, `useTonAllowance()`, `useApproveTon()`

### UnstakeModal
- **Trigger:** "Unstake" button on any page
- **Inputs:** Amount in TON
- **Actions:** Request unstake (7-day unbonding period)
- **Hooks:** `useUnstake()`

### Withdraw (Not in UI yet)
- **Purpose:** Withdraw unstaked tokens after unbonding period
- **Hook:** `useWithdraw()`
- **Condition:** `block.timestamp >= stakeInfo.unstakeTime + unbondingPeriod`

---

## Data Flow Summary

```
Contract Layer
    │
    ├── getSequencerList() ─────────────► Sequencers Page
    │
    ├── getSequencerInfo(seq) ──────────► Sequencer Cards, Detail Page
    │
    ├── getStakeInfo(user, seq) ────────► Dashboard, Detail Page
    │
    ├── pendingRewards(user, seq) ──────► Dashboard, Detail Page
    │
    ├── getTotalStaked() ───────────────► Stats, Share calculation
    │
    ├── checkLayer2Eligibility(l2) ─────► Detail Page Economics
    │
    └── estimateSeigniorage(seq) ───────► Detail Page Rewards
```

---

## Format Functions

| Function | Input | Output | Example |
|----------|-------|--------|---------|
| `formatTON(value)` | BigInt (18 decimals) | String | `600000000000000000000n` → `"600.0000"` |
| `formatWTON(value)` | BigInt (27 decimals) | String | `1000000000000000000000000000n` → `"1.0000"` |
| `formatPercent(value)` | Number (basis points) | String | `1000` → `"10.00%"` |
| `formatAddress(addr, chars)` | Address, number | String | `0x7099...79C8` |
