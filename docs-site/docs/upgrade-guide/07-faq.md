---
id: upgrade-faq
sidebar_position: 7
---

# FAQ

## Q1. What is the role of general stakers in V3?
**A**: In V3, seigniorage is distributed to participants who directly operate or verify L2 networks. General stakers can receive seigniorage by registering as validators and participating in L2 network verification. They can register as validators while maintaining existing staking, allowing seigniorage receipt without additional funds.

## Q2. Can existing stakers convert to validators?
**A**: Yes. By calling `RAT.registerValidator()` while maintaining existing staking, they can register as validators and receive seigniorage.

## Q3. What additional tasks do sequencers need to do after V3 upgrade?
**A**: Since collateral is integrated with existing staking, no separate work is needed - just maintain existing staking. However, eligibility conditions (`T_i ≥ max(D_seq, θ·B_i)`) must be met to receive seigniorage.

## Q4. Is there a security problem if L2 is not stopped on slashing?
**A**: Economic sanctions (seigniorage suspension + collateral confiscation) provide sufficient deterrent. Rather, user service continuity is guaranteed, making it more stable.

## Q5. Who changes `relaxedValidatorCheck` and when?
**A**: It can be changed through DAO governance. When sufficient validators are secured, it can be switched to `false` for security strengthening.

## Q6. When does V2 → V3 transition occur?
**A**: When DAO governance calls `migrateToV3()`, it immediately switches to V3 mode. All subsequent seigniorage distributions follow V3 logic.

## Q7. Can we revert to V2 after V3 transition?
**A**: No. After `migrateToV3()` execution, rollback to V2 is not possible. The contract has no function to change `v3Migrated = false`, and this is intentional design.

---

## Appendix: Major Changes Summary

### Network Value
1. **L2 Security Strengthening**: Clear economic incentives for sequencers, continuous monitoring through validator network, guaranteed validator participation through RAT
2. **Performance-Based Rewards**: Reflect actual contribution based on Bridged TON, prevent monopolization with hyperbolic function, create fair competitive environment
3. **Service Stability Improvement**: Guarantee L2 service continuity even on slashing, improve user experience

### Economic Value
1. **Capital Efficiency Improvement**: No duplicate deposits needed with collateral and staking integration, lower entry barriers for sequencers/validators
2. **Flexible Policy Operation**: Gradual security strengthening with `relaxedValidatorCheck`, parameter adjustment through DAO governance

### Technical Value
1. **Structure Simplification**: Reduced contract complexity, reduced management points by removing RAT direct deposits, integrated design based on Coinage
2. **Governance Strengthening**: DAO-centric decision-making structure, transparent parameter management, support for gradual upgrades
3. **Scalability Improvement**: Preparation for Multi-Sequencer support, easy future feature addition, modularized architecture

### Precautions
1. **Seigniorage Distribution Target Change**: Clear communication essential, secure sufficient advance notice period, need to guide validator participation methods and benefits
2. **Validator Network Building**: Need initial validator attraction strategy, establish `relaxedValidatorCheck` operational policy, build RAT response rate monitoring system
3. **Sequencer Eligibility Management**: Monitor Bridged TON-based eligibility conditions, establish response plan for ineligible L2s, provide seigniorage prediction tools
