# SeigManager

- This is a contract that manages the issuance of seigniorage.
- tot: An object containing seigniorage information allocated to the entire layer
- coinages: An object containing seigniorage information allocated to each layer
- Using tot and coinages, the seigniorage issued per block is distributed according to [logic](https://github.com/tokamak-network/papers/blob/master/cryptoeconomics/tokamak-cryptoeconomics-en.md#2-seigniorage).
- [Issuance of seigniorage](../README.md#seigniorage-issuance)


## Differentiated functions

### [updateSeigniorageLayer (address layer2)](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#writeProxyContract#F50)
Distributes seigniorage to accounts that have staked TON on a specific layer.
 - Parameters
   -  layer2 (address) : Layer Address

---

### [coinages (address layer2)](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#readProxyContract#F18)
Look up the coinage (seigniorage held) contract address of the layer
- Parameters
  - layer2 (address) : Layer Address
- Result
  - (address) : Coinage contract address


---

### [commissionRates (address layer2)](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#readProxyContract#F19)
View operator commission rates for layers
- Parameters
  - layer2 (address) : Layer Address
- Result
  - (uint256) : Commission rates, expressed in RAY units (10^27)

---

### [lastCommitBlock (address layer2)](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#readProxyContract#F37)
The block number that recently distributed seigniorage at a specific layer
- Parameters
  - layer2 (address) : Layer Address
- Result
  - (uint256) : The block number

---


### [seigPerBlock ()](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#readProxyContract#F50)
Seigniorage issuance per block
- Parameters
  - none
- Result
  - (uint256) : The issuance amount, expressed in decimals RAY units (10^27).


---

### [lastSeigBlock ()](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#readProxyContract#F38)
The block number where the most recent seigniorage was distributed
- Parameters
  - none
- Result
  - (uint256) : The block number


---

### [totalSupplyOfTon ()](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#readProxyContract#F64)
Total Supply of TON (including seigniorage issuance)
- Parameters
  - none
- Result
  - (uint256) : The total amount, expressed in decimals RAY units (10^27).

---
### [stakeOf (address account)](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#readProxyContract#F53)
The amount staked by a specific account
- Parameters
  - account (address) : Account address
- Result
  - Staking amount, expressed in decimals RAY units (10^27).

---

### [stakeOf (address layer2, address account)](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#readProxyContract#F54)
The amount staked by a specific account on a specific layer
- Parameters
  - layer2 (address) : Layer Address
  - account (address) : Account address
- Result
  - (uint256) : Staking amount, expressed in decimals RAY units (10^27).

---

### (coinages (address layer2)).totalSupply()
Total staked amount in a particular layer
 After searching for the coinage address of the layer, look up the totalSupply of the coinage contract.

- Parameters
  - layer2 (address) : Layer Address
- Result
  - (uint256) : Staking amount, expressed in decimals RAY units (10^27).

---

### [stakeOfTotal ()](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#readProxyContract#F59)
Total staked amount (based on seigniorage issuance)
- Parameters
  - none
- Result
  - (uint256) : Staking amount, expressed in decimals RAY units (10^27).

---

### [stakeOfAllLayers ()](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f?#readProxyContract#F55)
Total staked amount (based on seigniorage distribution)
- Parameters
  - none
- Result
  - (uint256) : Staking amount, expressed in decimals RAY units (10^27).

---

# L2 Sequencer Sequencer Distribution

## Related Storage

- maxCommitCountForClaim : The number of commits that can be settled at once for the L2 operator to receive the seigniorage of unsettled commit seigniorage
- l2UpdateBlock : L2 Seigniorage distributed block array , The first index of the array is not used, storage starts from index 1
- layer2RewardInfo : Layer2 claim-related information is stored in the form of Layer2Reward
- l2RewardAtBlock  : Amount of seigniorage granted per L2 liquidity per commit block
- layer2L2UpdateBlockIndexes : An array that stores the largest index number of l2UpdateBlock whenever L2 is committed.
- commitLayer2Tvl  : When L2 is committed, the L2 TVL of the previous commit (signature calculation is calculated based on the previous commit TVL)
- layer2PauseBlockIndex : Block number when L2 seigniorage issue is stopped
- layer2UnpauseBlockIndex : Block number when L2 seigniorage issue is resume

```

    struct Layer2Tvl {
        uint256 l2UpdateBlockIndexes; // l2UpdateBlock's index
        uint256 layer2Tvl;
    }

    struct Layer2Reward {
        uint256 layer2Tvl;            // L2 TVL at most recent commit
        uint256 startBlock;           // Update Signoria Start Block
        uint256 claimedLastIndex;     // The last index number of l2UpdateBlock at the time of the most recent claim.
        uint256 claimedBlockNumber;   // The block number at the time of the most recent claim
        uint256 claimedReward;        // Cumulative amount claimed so far
    }

    struct Layer2PauseBlock {
        uint256 pauseIndex; // pause l2UpdateBlock index, 포함 인덱스부터 발급안함
        uint256 unpauseIndex; // unpause l2UpdateBlock index, 포함 인덱스까지 발급안함
    }

    /// When claiming L2 seigniorage, only maxCommitCountForClaim can be claimed at a time.
    uint256 public maxCommitCountForClaim;

    // L2 update seigniorage commit block
    uint256[] public l2UpdateBlock; // index 0 - unused, it's a dummy

    /// layer2 reward information for each layer2(candidate).
    mapping (address => Layer2Reward) public layer2RewardInfo;

    // Calculate seigniorage per liquidity for L2 update seigniorage commit block.
    mapping (uint256 => uint256) public l2RewardAtBlock;

    // layer2 - the array of l2UpdateBlockIndex
    mapping (address => uint256[]) public layer2L2UpdateBlockIndexes;

    // layer2 - commit block number - commitLayer2Tvl
    mapping (address => mapping (uint256 => uint256)) public commitLayer2Tvl;

    // layer2 - the array of pause block index
    mapping (address => uint256[]) public layer2PauseBlockIndex;


    //layer2 - pause block index - unpause block index
    mapping (address => mapping (uint256 => uint256)) public layer2UnpauseBlockIndex;


```


# When running 'Update Seigniorage' function
- Stores the commit block number and the amount of seigniorage granted per L2 liquidity in storage.
  - Related functions
    - _insertL2UpdateBlock_Reward(uint256 l2TotalSeigs_, uint256 totalLayer2TVL_)

- Stores the TVL of the previous commit to be used in calculating seigniorage per commit block in layer2.
  - Related functions
    - _insertCommitLayer2Tvl(address layer2, uint256 layer2Tvl_)

- Reflect the current L2 TVL to the total L2 TVL and save it.



# When running 'claimL2Seigniorage' function
- Anyone can claim seigniorage allocated L2 to an L2 operator.  The seigniorage is transferred to the Operator Manager contract for that L2.
  - Related functions
    - _claimL2Seigniorage(address layer2)
    - claimableL2Seigniorage(address layer2) public view returns (uint256 amount, uint256 uptoIndex)


# To stop issuing seigniorage to a specific L2 operator,
- The onlySeigniorageCommittee can stop issuing seigniorage to specific L2 operators.
  - Related functions
    - rejectCandidateAddOn(address rollupConfig)


# To resume issuing seigniorage to a specific L2 operator,
- The onlySeigniorageCommittee can resume issuing seigniorage to specific L2 operators.
  - Related functions
    - restoreCandidateAddOn(address rollupConfig, bool rejectedL2Deposit)
