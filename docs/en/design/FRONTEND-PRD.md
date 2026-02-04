# Delegate Staking Frontend - Product Requirements Document (PRD)

> **Version**: 1.0
> **Status**: DRAFT
> **Related**: `DESIGN.md`, `FRONTEND-ARCHITECTURE.md`

## 1. Overview

A web interface for the **Sequencer Delegate Staking** system of Tokamak Network V3. Through this service, users can delegate TON to Sequencers and receive staking rewards.

### 1.1 Goals
- Provide an easy and intuitive UI for general users to participate in delegation (Staking)
- Simplify the complex V3 seigniorage structure and visualize portfolio performance (APY, rewards) to users
- Provide registration and management features for Sequencers

---

## 2. User Personas

### 2.1 Delegator (General User)
- **Goal**: Wants to deposit TON and earn interest (WTON/TON).
- **Main Activities**: Explore good Sequencers, delegate, claim rewards, withdraw.
- **Pain Points**: Complex bridging process, anxiety about long withdrawal waiting time (DTD).

### 2.2 Sequencer (Operator)
- **Goal**: Attract more delegations to increase commission revenue and maintain L2 seigniorage eligibility.
- **Main Activities**: Register Sequencer, promotion (commission rate adjustment), monitor operational status.

---

## 3. Core Features

### 3.1 Dashboard
- **My Asset Status**:
  - Total Staked Amount
  - Pending Withdrawal Amount
  - Claimable Rewards
  - Current APY (Estimated)
- **Activity Log**: Recent delegation and reward claim history.

### 3.2 Sequencer Explorer (Explore)
- **List View**:
  - Sequencer Name/Address
  - Total Delegated Amount (TVL)
  - Commission Rate
  - Number of Delegators
  - Status (Active/Inactive)
- **Filter/Sort**: By TVL, lowest commission rate, highest APY.

### 3.3 Delegate
- **Process**:
  1. Select Sequencer
  2. Enter TON amount to delegate
  3. Sign `Permit` or `Approve` transaction
  4. Send `Delegate` transaction
- **Notice**: Warning that "When delegating, TON is bridged to L2, and withdrawal takes 14 days".

### 3.4 Manage & Undelegate
- **Redelegate**:
  - Instantly move from current delegated Sequencer to another Sequencer.
- **Request Undelegate**:
  - Request partial or full withdrawal.
  - Display DTD (14 days) countdown start.
- **Withdraw**:
  - Receive assets to L1 after DTD ends (`Claim`).

### 3.5 Claim Rewards
- Claim rewards per Sequencer or batch claim functionality.

### 3.6 Sequencer Admin (Operator Only)
- Sequencer registration form (L2 Vault address input).
- Commission rate change functionality.

---

## 4. Page Structure (Sitemap)

| Path | Page Name | Description |
|------|-----------|-------------|
| `/` | **Home** | Service introduction and featured Sequencer highlights |
| `/dashboard` | **My Dashboard** | My staking status and portfolio management |
| `/sequencers` | **Sequencer List** | Full Sequencer list and detailed information |
| `/sequencers/:id`| **Sequencer Detail** | Specific Sequencer's detailed performance and delegation modal |
| `/admin` | **Sequencer Admin** | Sequencer registration and management (for operators) |

---

## 5. UI/UX Requirements

### 5.1 Design Principles
- **Premium & Trustworthy**: Design that conveys trust as a financial application (Glassmorphism, Clean lines).
- **Responsive**: Full support for mobile and desktop.
- **Dark Mode First**: Default dark mode support for crypto-native users.

### 5.2 Interactions
- **Wallet Connection**: Support various wallets using RainbowKit, etc.
- **Feedback**: Clear toast messages and progress indicators for all transaction stages (pending, processing, success, failure).
- **Loading State**: Use skeleton UI when loading data.

---

## 6. Data Requirements

- **Indexer** Necessity:
  - Sequencer list and historical APY data may be difficult to retrieve through on-chain traversal.
  - Initial Phase: Direct RPC calls (using `multicall`).
  - Future: Consider introducing The Graph or custom indexer.
