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
- l2UpdateBlock : An array of L2 update seigniorage commit block
- l2RewardAtBlock : Reward(seigniorage) per L2 liquidity in commit blocks
- maxLoopCount : When calculating rewards for previous unsettled commit blocks, up to  maxLoopCount commit block rewards are settled. (Gas fee issue)
You can find out how much gas has not been settled by using an event off-chain, but rewards (signatures) that have not been settled because they exceed the maximum number of commit settlements are  locked in the contract.
Therefore,  operators should regularly execute  the update signature commits to avoid being disadvantaged in settlement.

- totalLayer2TVL : The total amount of TVL of all L2s
- layer2RewardInfo : Layer2Reward Information of L2
  - layer2Tvl : The amount of TVL in L2
  - reward : Amount of rewards settled (calculated). After sending the reward to the L2 operator, it is initialized to 0.
  - lastBlock : The most recent block that received L2 operator seigniorage settlement
  - lastIndex : The most recent block index that received the sequencer seigniorage settlement (the index of l2UpdateBlock)
  - startBlock : L2 Candidate Seigniorage Issuance Start Block


  - SeigManagerV1_3Storage.sol#L8:11
  ```
  struct Layer2Reward {
      uint256 layer2Tvl;
      uint256 reward;
      uint256 lastBlock;
      uint256 lastIndex;
      uint256 startBlock;
  }

  ```

- SeigManagerV1_3Storage.sol#L21:38
```
/// layer2 seigs start block
uint256 public layer2StartBlock;

/// total layer2 TON TVL
uint256 public totalLayer2TVL;

/// layer2 reward information for each layer2(candidate).
mapping (address => Layer2Reward) public layer2RewardInfo;


// ===============================
// L2 update seigniorage commit block:
uint256[] public l2UpdateBlock;

// Calculate seigniorage per liquidity for L2 update seigniorage commit block.
mapping (uint256 => uint256) public l2RewardAtBlock;

uint256 public maxLoopCount;
```

### Related Logics

#### unSettledReward(address layer2) public view returns (uint256 amount)
Check the amount of rewards that have been settled (calculated) but not yet taken.

  [code](https://github.com/tokamak-network/ton-staking-v2/blob/2d843b922a37769669d4f5e148ba02a9dcf60bb7/contracts/stake/managers/SeigManagerV1_3.sol#L394)
  ```
    function unSettledReward(address layer2) public view returns (uint256 amount) {
        Layer2Reward memory layer2Info = layer2RewardInfo[layer2];
        amount = layer2Info.reward;
    }
  ```


#### L2 Seigniorage Settlement in _increaseTot(bool _isSenderOperator)

- When committing, calculate and store the reward per L2 liquidity in the commit block.

  [code](https://github.com/tokamak-network/ton-staking-v2/blob/2d843b922a37769669d4f5e148ba02a9dcf60bb7/contracts/stake/managers/SeigManagerV1_3.sol#L733-L745)
   ```
    function _insertL2RewardPerUnit(
        uint256 l2TotalSeigs_, uint256 totalLayer2TVL_
    ) internal {

        if (l2TotalSeigs_ != 0 && totalLayer2TVL_ != 0) {
            uint256 len = l2UpdateBlock.length;
            if(len != 0)
                require(l2UpdateBlock[len-1] < block.number, "error insertL2RewardPerUnit");

            l2UpdateBlock.push(block.number);
            l2RewardAtBlock[block.number] =  (l2TotalSeigs_ * WEI_UINT) / totalLayer2TVL;
        }
    }
   ```

- When a specific commits,

  - calculate the unsettled reward using _unsettledLayer2Reward function

    [code](https://github.com/tokamak-network/ton-staking-v2/blob/2d843b922a37769669d4f5e148ba02a9dcf60bb7/contracts/stake/managers/SeigManagerV1_3.sol#L787-L823)
    ```
    function _unsettledLayer2RewardView(uint256 liquidity, uint256 startIndex, uint256 prevLastBlock, uint256 maxBlock)
        internal view returns (uint256 amount, uint256 lastIndex, uint256 lastBlock)
    {
        uint256 endIndex ;
        uint256 len = l2UpdateBlock.length;
        if(len == 0) return (0,0,0);
        else  endIndex =  len - 1;

        uint256 _maxLoopCount = maxLoopCount;
        if (_maxLoopCount == 0) _maxLoopCount = MAX_LOOP_COUNT;

        uint256 num;
        uint256 _block;
        uint256 _index = startIndex;

        while (_index <= endIndex) {

            if (num > _maxLoopCount) {
                // emit ExceededMaimumxLoopCount(layer2, liquidity, lastIndex, len-1);
                // lastIndex = len-1;
                break;
            }

            _block = l2UpdateBlock[_index] ; // block number
            if (maxBlock < lastBlock) break;
            if(_block <= prevLastBlock) break;

            lastIndex = _index;
            amount += l2RewardAtBlock[_block] * liquidity / WEI_UINT;
            num ++;
            _index++;
        }

        if (endIndex !=0 && _index != 0 &&  _index != startIndex) lastIndex = _index - 1;
        if (l2UpdateBlock.length != 0) lastBlock = l2UpdateBlock[lastIndex];

    }
    ```

  - save the unsettled reward

    code
    ```
    (uint256 amount, uint256 lastIndex, uint256 lastBlock)
          = _unsettledLayer2Reward (msg.sender, oldLayer2Info.layer2Tvl, startIndex, newLayer2Info.lastBlock, block.number);

      layer2Seigs = amount;
      uint256 reward = amount + newLayer2Info.reward;
      if (newLayer2Info.lastBlock != lastBlock) {
          newLayer2Info.lastIndex = lastIndex;
          newLayer2Info.lastBlock = lastBlock;
      }

      if (_isSenderOperator && reward != 0) {
          ILayer2Manager(_layer2Manager).updateSeigniorage(rollupConfig, reward);
          newLayer2Info.reward = 0;
      } else {
          newLayer2Info.reward = reward;
      }

    ```
  - The operator can claim or take the reward with the staking option if he wants.

    [code](https://github.com/tokamak-network/ton-staking-v2/blob/2d843b922a37769669d4f5e148ba02a9dcf60bb7/contracts/stake/managers/SeigManagerV1_3.sol#L692-L694)
    ```
     if (_isSenderOperator && reward != 0) {
        ILayer2Manager(_layer2Manager).updateSeigniorage(rollupConfig, reward);
        newLayer2Info.reward = 0;
    } else {
        newLayer2Info.reward = reward;
    }

    ```
