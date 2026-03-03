# 4. Reward Distribution Logic & Security Design

## Winner Determination Criteria

### _distributeBond Recipient = Winner

In all 3 cases where `_distributeBond(recipient, claim)` is called in the `resolveClaim` function, the bond recipient is the **winner** of that subgame.

| Case | Situation | recipient | Type of Win |
|------|-----------|-----------|-------------|
| Case 1 | Claim with no children: `counteredBy != address(0)` | counteredBy (step executor) | Offensive win |
| Case 1 | Claim with no children: `counteredBy == address(0)` | claimant (self) | Defensive win (bond recovery) |
| Case 2 | L2 block number challenge successful | l2BlockNumberChallenger | Offensive win |
| Case 3 | Regular subgame: `countered != address(0)` | countered (child claim asserter) | Subgame win |
| Case 3 | Regular subgame: `countered == address(0)` | claimant (parent claim asserter) | Defensive win (bond recovery) |

### gameCreator Filtering

In the CHALLENGER_WINS scenario:
- `gameCreator` = Proposer (Loser)
- All bond recipients who are not `gameCreator` = Winners on the Challenger side

```solidity
function _recordWinningChallenger(address recipient) internal {
    if (recipient == gameCreator()) return;       // Exclude Proposer
    if (isWinningChallenger[recipient]) return;   // Prevent duplication
    isWinningChallenger[recipient] = true;
    _winningChallengers.push(recipient);
}
```

### Edge Case: Defender on the Proposer's Side

A person defending the Proposer might win a specific subgame and receive a bond. In this case, that Defender is not the `gameCreator` and is thus recorded as a winning challenger. In the current design, this is allowed for simplicity, and complex contribution assessments can be resolved in a future weight-based system.

---

## Distribution Formula

```text
Total Reward = Slashed amount * slashingRewardRate / 10000
Individual Reward = Total Reward / Number of challengers
Remainder = Total Reward % Number of challengers → Paid to the first challenger
```

### Distribution Example

| Number of Challengers | Total Reward | Individual Reward | First Person's Reward |
|-----------------------|--------------|-------------------|-----------------------|
| 1 person | 1000 WTON | 1000 | 1000 |
| 2 people | 1000 WTON | 500 | 500 |
| 3 people | 1000 WTON | 333 | 334 (Remainder 1) |
| 5 people | 1000 WTON | 200 | 200 |

### Backward Compatibility

If there's only a single challenger (`challengers.length == 1`), it operates identically to the legacy system.

---

## Security Design

| Item | Implementation Method |
|------|-----------------------|
| **Access Control** | `recordWinner()`: Only allows `msg.sender == game` |
| | `setWinningChallengerTracker()`: `onlyOwner` |
| | `slash()`: `onlyLayer2Manager` |
| **Duplication Prevention** | Duplication check via `isWinner[game][winner]` mapping |
| **DoS Prevention** | Max number of challengers can be limited (`MAX_WINNING_CHALLENGERS = 100`) |
| **Reentrancy Prevention** | Use `SafeERC20.safeTransfer`, state changes completed prior to external calls |
| **Proposer Exclusion** | Filtering via `recipient != gameCreator()` |
| **External Call Safety** | Use `try-catch` in `_recordWinningChallenger`, failure in tracker call does not affect game logic |

---

## Gas Costs

| Item | Additional Gas |
|------|----------------|
| Recording new winner (external call + storage write) | ~25,000 gas |
| Multiple WTON transfers | Number of challengers * ~21,000 gas |

---

Next: [05-build-deploy.md](./05-build-deploy.md)
