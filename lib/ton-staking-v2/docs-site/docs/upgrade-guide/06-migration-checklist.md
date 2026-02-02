---
id: upgrade-migration-checklist
sidebar_position: 6
---

# Migration Checklist

## User Response

### General Stakers
- [ ] Announce V3 seigniorage distribution target change (announcement required)
- [ ] Guide validator participation methods and benefits
- [ ] Create and distribute FAQ

### Sequencers
- [ ] Guide new eligibility conditions
- [ ] Guide Bridged TON-based distribution
- [ ] Guide capital efficiency improvement from collateral integration
- [ ] Guide seigniorage calculation method change
- [ ] Guide slashing policy change

### Validators (New)
- [ ] Guide validator registration procedures
- [ ] Explain RAT mechanism
- [ ] Guide reward calculation method
- [ ] Guide `relaxedValidatorCheck` policy
- [ ] Create validator guide document

## Pre-Deployment Preparation

### Contract Deployment
- [ ] Deploy SeigManagerV3_1
- [ ] Deploy SeigManagerV3_2 (V2 compatibility layer)
- [ ] Deploy RAT
- [ ] Deploy ValidatorRewardV1
- [ ] Deploy DepositManagerV3
- [ ] Deploy Layer2ManagerV3
- [ ] Deploy L1BridgeRegistryV1_2

### Selector Routing Setup (SeigManagerProxy)
- [ ] Register SeigManagerV3_1 selectors
  - [ ] `setValidatorReward(address)`
  - [ ] `setDaoDistributionRatio(uint256)`
  - [ ] `setMinStakingRatio(uint256)`
  - [ ] `setValidatorDistributionRatio(uint256)`
  - [ ] `setHalfSaturationPoint(uint256)`
  - [ ] `migrateToV3()`
  - [ ] `onBridgedTonChange()`
  - [ ] `updateSeigniorage()` (override)
  - [ ] `updateSeigniorageLayer(address)` (override)

### Address and Permission Setup
- [ ] Set RAT address in SeigManager (`setRATContract`)
- [ ] Set ValidatorReward address in SeigManager (`setValidatorReward`)
- [ ] Set Layer2Manager address in SeigManager
- [ ] Set L1BridgeRegistry address in SeigManager
- [ ] Set RAT permissions (verify `onlyRAT` modifier works)
- [ ] Set ValidatorReward permissions

### Parameter Setup
- [ ] Set `daoDistributionRatio` (d) (e.g., 0.2e27 = 20%)
- [ ] Set `minStakingRatio` (θ) (e.g., 0.1e27 = 10%)
- [ ] Set `validatorDistributionRatio` (α) (e.g., 0.2e27 = 20%)
- [ ] Set `halfSaturationPoint` (k) (e.g., 10,000,000e27 TON)
- [ ] Set `relaxedValidatorCheck = true` (initial value)
- [ ] Set RAT parameters
  - [ ] `ratTriggerProbability` (π_a)
  - [ ] `slashingPenalty` (C_off)
  - [ ] `minimumThreshold` (D_min)
  - [ ] `evidenceSubmissionPeriod`

### V3 Migration Execution
- [ ] Call `migrateToV3()` (DAO governance)
- [ ] Verify `v3Migrated = true`

## Post-Deployment Verification

### Function Verification
- [ ] Verify sequencer staking query works normally
- [ ] Verify validator collateral query works normally
- [ ] Verify RAT coinage transfer works normally
- [ ] Verify seigniorage eligibility check works normally
- [ ] Verify `relaxedValidatorCheck` flag works
- [ ] **Verify seigniorage distribution target change** (distribute only to L2 operators/validators)
- [ ] Verify sequencer seigniorage receipt
- [ ] Verify validator seigniorage distribution
- [ ] Verify undistributed portion (L - y) goes to DAO

### Security Verification
- [ ] Verify RAT permission check works (`onlyRAT`)
- [ ] Verify Coinage burn/mint permissions
- [ ] Test slashing logic (testnet)
- [ ] Verify DAO governance permissions
- [ ] Verify V3 migration permissions
- [ ] Verify selector routing works normally

### Scenario Testing
- [ ] V2 → V3 transition scenario
- [ ] Validator registration scenario
- [ ] RAT trigger and response scenario
- [ ] RAT timeout scenario
- [ ] Sequencer slashing scenario
- [ ] Ineligible L2 scenario
- [ ] L2 with no validators scenario

## Operational Plan

### Stage 1: Early Operation (Validator Attraction)
- `relaxedValidatorCheck = true` (relaxed criteria)
- Minimum collateral: C_off (low entry barrier)
- Monitoring: Validator count, network security metrics, RAT response rate

### Stage 2: Growth Period (Security Strengthening)
- Transition to `relaxedValidatorCheck = false` via DAO governance
- Minimum collateral: D_validator = C_off + Δ_validator
