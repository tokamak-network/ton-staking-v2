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

## Calculating seigniorage for L2 sequencers

Added the ability to give seigniorage to L2 sequencers separately.
You can find more details in [this document](https://github.com/tokamak-network/ton-staking-v2/blob/ton-staking-v2.5/docs/en/ton-staking-v2.md#seigniorage-distribution-of-v25).

### Related Storages

- layer2StartBlock : Block that starts giving seigniorage to the L2 sequencer
- l2RewardPerUint
  - The amount of seigniorage provided per one L2 liquidity
  - Seigniorage calculations are applied from layer2StartBlock block(!=0).

- totalLayer2TVL : The total amount of TVL of all L2s
- layer2RewardInfo : Layer2Reward Information of L2
  - layer2Tvl : The amount of TVL in L2
  - initialDebt : The amount to be deducted from seigniorage calculated as l2RewardPerUint
  - SeigManagerV1_3Storage.sol#L8:11
  ```
  struct Layer2Reward {
      uint256 layer2Tvl;
      uint256 initialDebt;
  }

  ```

- SeigManagerV1_3Storage.sol#L13:24
```
/// layer2 seigs start block
uint256 public layer2StartBlock;

uint256 public l2RewardPerUint;  // ray unit .1e27

/// total layer2 TON TVL
uint256 public totalLayer2TVL;

/// layer2 reward information for each layer2(candidate).
mapping (address => Layer2Reward) public layer2RewardInfo;
```

### Related Logics

#### unSettledReward(address layer2) public view returns (uint256 amount)
The amount of seigniorage that has not yet been settled is the product of L2RewardPerUint and the L2 total liquidity (layer2Tvl), minus the deduction amount(initialDebt).

  - SeigManagerV1_3Storage.sol#L374:378
  ```
    function unSettledReward(address layer2) public view returns (uint256 amount) {
        Layer2Reward memory layer2Info = layer2RewardInfo[layer2];
        if (layer2Info.layer2Tvl != 0)
            amount = l2RewardPerUint * (layer2Info.layer2Tvl / 1e18) - layer2Info.initialDebt;
    }
  ```


#### L2 Seigniorage Settlement in _increaseTot(bool _isSenderOperator)

- The case of L2 seigniorage settlement
  When l2RewardPerUint seigniorage is greater than zero, L2 seigniorage settlement is made in the following cases:
  - If you are an operator, (SeigManagerV1_3Storage.sol#L660:666)
  - If L2 liquidity has decreased compared to the previous update seigniorage, (SeigManagerV1_3Storage.sol#L660:666)
  - If you execute the first update seigniorage. (SeigManagerV1_3Storage.sol#L667:669)
    - Since we use l2RewardPerUint to calculate the amount that has not been settled yet, L2 that started receiving seigniorage from a block after layer2StartBlock (!=0) has to deduct the amount (seigniorage between the layer2StartBlock and the start block). Therefore, when the update seigniorage is executed for the first time, we calculate this deductible amount.

- SeigManagerV1_3Storage.sol#L653:674
  ```
  // L2 seigs settlement
  if (layer2Allowed) {
      if (l2TotalSeigs != 0) l2RewardPerUint += ((l2TotalSeigs * 1e18) / totalLayer2TVL);

      Layer2Reward storage newLayer2Info = layer2RewardInfo[msg.sender];

      if (l2RewardPerUint != 0) {
          if (_isSenderOperator || oldLayer2Info.layer2Tvl > curLayer2Tvl) {
              layer2Seigs = unSettledReward(msg.sender);

              if (layer2Seigs != 0) {
                  ILayer2Manager(_layer2Manager).updateSeigniorage(rollupConfig, layer2Seigs);
                  newLayer2Info.initialDebt += layer2Seigs;
              }
          } else if (_lastCommitBlock[msg.sender] == 0) {
              newLayer2Info.initialDebt = (l2RewardPerUint * oldLayer2Info.layer2Tvl) / 1e18;
          }
      }

      newLayer2Info.layer2Tvl = curLayer2Tvl;
      totalLayer2TVL = totalLayer2TVL + curLayer2Tvl - oldLayer2Info.layer2Tvl;
  }
  ```

