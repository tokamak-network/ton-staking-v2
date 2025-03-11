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

# L2 Sequencer Seigniorage

Added the ability to give seigniorage to L2 sequencers separately.
You can find more details in [this document](https://github.com/tokamak-network/ton-staking-v2/blob/ton-staking-v2.5/docs/en/ton-staking-v2.md#seigniorage-distribution-of-v25).

## Related Storage

- layer2StartBlock : Block that starts giving seigniorage to the L2 sequencer
- l2RewardPerUint
  - The amount of seigniorage provided per one L2 liquidity
  - Seigniorage calculations are applied from layer2StartBlock block(!=0).

- totalLayer2TVL : The total amount of TVL of all L2s
- layer2RewardInfo : Layer2Reward Information of L2
  - layer2Tvl : The amount of TVL in L2
  - initialDebt : Amount to be deducted when calculating seigniorage
  - startBlock : Block that started issuing the L2 sequencer seigniorage

- layer2PauseBlockIndex : block number when stopping issuing L2 seigniorage
- layer2UnpauseBlockIndex :  block number when resuming issuing L2 seigniorage

  ```
  struct Layer2Reward {
      uint256 layer2Tvl;
      uint256 initialDebt;
      uint256 startBlock;
  }

  /// layer2 seigs start block
  uint256 public layer2StartBlock;

  uint256 public l2RewardPerUint;

  /// total layer2 TON TVL
  uint256 public totalLayer2TVL;

  /// layer2 reward information for each layer2(candidate).
  mapping (address => Layer2Reward) public layer2RewardInfo;

  // layer2 - block number when pausing
  mapping(address => uint256[]) public layer2PauseBlocks;

  //layer2 - block number when pausing - block number when unpausing
  mapping(address => mapping(uint256 => uint256)) public layer2UnpauseBlocks;
  ```

#  When running update seigniorage, L2 sequencer seigniorage is issued.

Calculate the seigniorage granted to the L2 sequencer,
Calculate the seigniorage per L2 liquidity.
Send the seigniorage granted to the L2 sequencer to Layer2Manager.

  ```
  if (layer2StartBlock <= block.number && totalLayer2TVL > 0) {
      l2TotalSeigs = rdiv(rmul(maxSeig, totalLayer2TVL * 1e9), tos);
      l2RewardPerUint += (l2TotalSeigs * WEI_UINT) / totalLayer2TVL;
      IWTON(wton_).mint(layer2Manager, l2TotalSeigs);
  }
  ```

If the Layer2 is a Layer2 that allows L2 sequencer seigniorage issuance,
Calculate the seigniorage that the Layer2 should receive and send the seigniorage to the operator of Layer2.

  ```
   (address rollupConfig, bool allowed) = allowIssuanceLayer2Seigs(msg.sender);
    if (allowed && !isPauseL2Seigniorage(msg.sender)) {
        uint256 curLayer2Tvl = IL1BridgeRegistry(l1BridgeRegistry).layer2TVL(rollupConfig);
        Layer2Reward storage newLayer2Info = layer2RewardInfo[msg.sender];
        Layer2Reward memory oldLayer2Info = layer2RewardInfo[msg.sender];

        // update layer2 tvl if it has changed
        // Because the previous information(oldLayer2Info) was loaded into memory, the storage immediately reflects the latest information.
        if (oldLayer2Info.layer2Tvl != curLayer2Tvl) {
            newLayer2Info.layer2Tvl = curLayer2Tvl;
            totalLayer2TVL = totalLayer2TVL + curLayer2Tvl - oldLayer2Info.layer2Tvl;
        }

        // If this the first commit, set up an initial debt
        if (oldLayer2Info.startBlock == 0) {
            newLayer2Info.startBlock = block.number;

        } else {

            // distribute seigniorage to layer2 based on previous layer2 tvl
            // layer2Tvl would be 0 when layer2 has been paused
            if (oldLayer2Info.layer2Tvl > 0) {
                layer2Seigs =
                    ((l2RewardPerUint * oldLayer2Info.layer2Tvl) / WEI_UINT) -
                    oldLayer2Info.initialDebt;
                // rewards just increase higher than layer2Debt because it is calculated based on previous layer2 tvl
                if (layer2Seigs != 0) ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
            }
        }
        newLayer2Info.initialDebt = (l2RewardPerUint * curLayer2Tvl) / WEI_UINT;
    }

  ```