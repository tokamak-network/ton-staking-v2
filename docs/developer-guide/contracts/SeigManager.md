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

# Composition of seigniorage management

If you look at the TON Staking service, the Candidates are listed. This Candidate was previously named layer2. In other words, the TON Staking service manages seigniorage by layer2. Users can also stake separately by layer2.

The TON Staking service manages seigniorage information in two ways.
  - A. Total seigniorage issued to entire and seigniorage issued to each layer
  - B. Total seigniorage issued to each layer and seigniorage of users who staked in each layer

## A. Total seigniorage issued to entire and seigniorage issued to each layer2

### Related Storages
  - [tot](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f#readProxyContract#F63)
    - A contract that manages the total staking amount and the amount staked in each layer2, reflecting the issued seigniorage.
    - totalSupply of tot : Total staking amount including total issuance seigniorage
    - balanceOf(address layer2) of tot : Total staking amount of layer2 including seigniorage issued on each layer2

### Distribute seigniorage to entire layer2 each time update seigniorage is run
  - When running the update seigniorage, The seigniorage amount given to the staker from the amount of seigniorage issued will be added to the total staking amount of tot.
  - If the factor is adjusted to reflect this added amount, the staking amount of the entire layer2 managed by tot will automatically increase according to the stake amount.
  - You can check the related code in the _increaseTot function.
    ```
    uint256 totalPseig = rmul(maxSeig - stakedSeig - l2TotalSeigs, relativeSeigRate);
    nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
    _lastSeigBlock = block.number;

    _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

    ```
    The amount of seigniorage distributed to the staker is 'stakedSeig + totalPseig'.
    The factor was changed by considering nextTotalSupply including the amount of seigniorage distributed.

    With this, the seigniorage distribution to all layer2 is completed.

  - Through this, the staking amount of tot has distributed seigniorage, but Since the user checks his/her staking amount through the coinage(layer2).balanceOf(account) function, the user has not yet settled (reflected) the seigniorage amount. Please keep this in mind, because the time when the user receives the seigniorage is settled (reflected) when the update seigniorage is executed in the corresponding layer2. (This is explained in B.)

## B. Total seigniorage issued to each layer and seigniorage of users who staked in each layer2

### Related Storages
  - [coinages(address layer2)](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f#readProxyContract#F18)
      - Separately store the contract that manages the staking amount that reflects the seigniorage of each layer2. So users can stake separately for each layer2.
      - totalSupply of coinages(the layer2) : The total amount of staking that has settled seigniorage on the layer2 (When executing 'update seigniorage' on the layer2, the seigniorage that has not been settled until now is applied.)
      - balanceOf(layer2 address) of coinages(the layer2) : The total amount of staking that has settled seigniorage by each user who staked on the layer2 (When executing 'update seigniorage' on the layer2, the seigniorage that has not been settled until now is applied.)

### Reflect seigniorage of specific layer2 when 'specific layer2's update seigniorage' is run
  - When the update seigniorage of a specific layer2 is executed, only the seigniorage of that layer2 is settled, and the seigniorage is reflected in the staking amount.
  - If the number of layers becomes very large, it will take a lot of gas to update all layers at once, so we can specify a layer2 to update only the coinage of that layer2. However, since the tot contract is always updated, when you update the coinage of a specific layer2 in the future, you can calculate the unreflected seigniorage with the difference amount of the tot.balanceOf(layer2) and coinage[layer2].totalSupply.
    - You can check the code in the _updateSeigniorage function.
    ```
      // 2. increase total supply of {coinages[layer2]}
      uint256 prevTotalSupply = coinage.totalSupply();
      uint256 nextTotalSupply = _tot.balanceOf(msg.sender);

      // short circuit if there is no seigs for the layer2
      if (prevTotalSupply >= nextTotalSupply) {
          emit Comitted(msg.sender);
          return true;
      }

      uint256 seigs = nextTotalSupply - prevTotalSupply;
    ```
    The seigniorage seigs reflected in layer2 is calculated as _tot.balanceOf(msg.sender) - coinage.totalSupply().


# Calculation of Operator Commission

Operators can set a commissionRate to receive a portion of the generated seigniorage as an operator commission, or distribute a portion of the operator's seigniorage to staker(delegator).

## Related Storages
  - [commissionRates(address layer2)](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f#readProxyContract#F19)
    - The percentage of commission charged from the generated seigniorage or the percentage of seigniorage received by the operator that will be given to the staker.
    - display in RAY units
    - e.g. among [the layers(candidates)](../../docs/deployed-addresses-mainnet.md#layer-addresses)
      - [tokamak1](https://etherscan.io/address/0xf3b17fdb808c7d0df9acd24da34700ce069007df) ; 25000000000000000000000000 -> 0.025 (2.5%)

  - [isCommissionRateNegative(address layer2)](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f#readProxyContract#F33)
    - Whether to receive an operator commission or to share a portion of operator's seigniorage with stakers
    - If the isCommissionRateNegative value is false, it means that the operator receives a commission fee, and if it is true, it means that a portion of the operator's seigniorage will be distributed to the stakers(delegator).
    - e.g. among [the layers(candidates)](../../docs/deployed-addresses-mainnet.md#layer-addresses)
      - [tokamak1](https://etherscan.io/address/0xf3b17fdb808c7d0df9acd24da34700ce069007df) ; false

## Seigniorage distribution related to isCommissionRateNegative

- Total staking amount with seigniorage added = Previous total staking amount + Seigniorage amount distributed to the layer.

    ```
      nextTotalSupply = prevTotalSupply + seigs;
    ```

- **If isCommissionRateNegative is false,**
  - The amount of commission received by the operator (the commission is deducted from the seigniorage):operatorSeigs is the seigniorage multiplied by the commission rate. -> Seigniorage * commission rate
  - The next total staking amount must be calculated by deducting the operator commission fee (operatorSeigs) from the calculated total staked amount(nextTotalSupply = prevTotalSupply + seigs).

    ```
      if (!isCommissionRateNegative_) {
          operatorSeigs = rmul(seigs, commissionRate); // additional seig for operator
          nextTotalSupply -= operatorSeigs;
          return (nextTotalSupply, operatorSeigs);
      }
    ```
    Since only the amount minus operatorSeigs from the issued seigniorage is reflected in the staking amount,
    the operatorSeigs amount is additionally minted to the operator.  -> coinage.mint(operator, operatorSeigs)
      ```
      // give commission to operator or delegators
        if (operatorSeigs != 0) {
            if (isCommissionRateNegative_) {
                // TODO: adjust arithmetic error
                // burn by 𝜸
                coinage.burnFrom(operator, operatorSeigs);
            } else {
                coinage.mint(operator, operatorSeigs);
            }
        }
      ```
    By doing this, the additional issued seigniorage amount will follow the planned issue amount.

- **If isCommissionRateNegative is true,**
  - the operator distributes a portion(commissionRate) of the operator's seigniorage received from the issued seigniorage to the delegator(staker).

  - First, the seigniorage(ɑ:operatorSeigs) given to the delegator from the operator seigniorage is calculated as $seigs * operatorRate * commissionRate$.<br/>
    In order to distribute operatorSeigs(ɑ) to the delegator, the stock is calculated for one delegator's staking.<br/>
      $OneStock = operatorSeigs / delegatorBalance$ <br/>
    and, the stock should be added to all delegators.<br/>
    $delegatorSeigs = operatorSeigs / delegatorBalance  * prevSupply$ <br/>
      $\therefore$ $delegatorSeigs = operatorSeigs / (1 - operatorRate)$

    ```
      // β:
      uint256 delegatorSeigs = operatorRate == RAY
          ? operatorSeigs
          : rdiv(operatorSeigs, RAY - operatorRate);

    ```
    delegatorSeigs(β) is added to the next staked amount(nextSupply) and reflected in the next factor calculation.
    ```
      nextTotalSupply += delegatorSeigs;
    ```
    By doing this, the individual's staking amount includes both the seigniorage received by the individual and the seigniorage(delegatorSeigs(β)) given by the operator.

    However, since the stocks are reflected in the entire supply above and the stock is added to the operator, the amount added to the operator is burned after the factor is reflected to prevent additional seigniorage from being issued.

    The operatorSeigs(𝜸) value is the amount burning from the value staked by the operator. Another reason for calculating this amount is that since the delegatorSeigs(β) amount was added to the total staked amount, the TON issuance (seigniorage) was increased by the delegatorSeigs(β) amount more than planned.

    ```
    // ɑ: insufficient seig for operator
    operatorSeigs = rmul(
        rmul(seigs, operatorRate), // seigs for operator
        commissionRate
    );

    // β:
    uint256 delegatorSeigs = operatorRate == RAY
        ? operatorSeigs
        : rdiv(operatorSeigs, RAY - operatorRate);

    // 𝜸:
    operatorSeigs = operatorRate == RAY
        ? operatorSeigs
        : operatorSeigs + rmul(delegatorSeigs, operatorRate);

    // nextTotalSupply = nextTotalSupply + delegatorSeigs;
    nextTotalSupply += delegatorSeigs;

    ```

    Therefore, by burning the operatorSeigs(𝜸) value from the operator's staked amount, the seigniorage issuance is adjusted to the planned amount.Therefore, the delegatorSeigs(β) amount and the operatorSeigs(𝜸) amount should always be the same value.

    ```
    if (operatorSeigs != 0) {
        if (isCommissionRateNegative_) {
            // TODO: adjust arithmetic error
            // burn by 𝜸
            coinage.burnFrom(operator, operatorSeigs);
        } else {
            coinage.mint(operator, operatorSeigs);
        }
    }

    ```

  - For example, let's check the values ​​above.

    - Current status
      |storage | value| note |
      |------|---|---|
      |The current factor| 1.0 ||
      |The operator commission rate| 0.1 | commissionRate 10%|
      |The operator commission rate negative| true | isCommissionRateNegative_ |
      |The operator staked rate| 0.7 | operatorRate 70% |
      |The operator deposit amount | 700 ||
      |A account's deposit amount | 300 ||
      |Total deposit amount| 1000 ||
      |The operator's staked amount | 700 | The operator deposit amount * The current factor |
      |A account's staked amount | 300 | The A account deposit amount * The current factor |
      |Total staked amount| 1000 | The total deposit amount * The current factor|


    - Update seigniorage : the first calculation
      |storage | value| note |
      |------|---|---|
      |The previous total supply | 1000 | prevTotalSupply = Total deposit amount * The current factor |
      |Issued seigniorage | 100 | seigs |
      |The next total supply  | 1100 | nextTotalSupply = prevTotalSupply + seigs |

    - Update seigniorage : the second calculation
      |storage | value | note | note |
      |------|---|---|---|
      |ɑ: operatorSeigs | 7 | 100 * 0.7 * 0.1 | seigs * operatorRate * commissionRate |
      |β: delegatorSeigs | 23.3333333333 | 7 / (1-0.7)   | operatorSeigs / (1-operatorRate) |
      |𝜸: operatorSeigs | 23.3333333333 |  7 + (23.3333333333 * 0.7) |  ɑ:operatorSeigs + (delegatorSeigs * operatorRate)|
      |nextTotalSupply | 1123.33333333 | 1100 + 23.3333333333 | nextTotalSupply += delegatorSeigs |

      - nextTotalSupply is added to 23.3333333333 before the factor change.

    - Update seigniorage : the last calculation
      - Factor update and additional amount burned

      |storage | value | note | note |
      |------|---|---|---|
      |The changed factor | 1.12333333333  |  1123.33333333 * 1.0 / 1000 |  nextTotalSupply * The current factor / The previous total supply |
      |The operator deposit amount after burning | 679.228486647 | 700 - (23.3333333333/1.12333333333) | The operator deposit amount - (operatorSeigs/The changed factor) |
      |The operator staked amount | 762.999999998 | 679.228486647 * 1.12333333333 | The operator deposit amount * The changed factor |
      |A account's staked amount | 336.999999999  | 300 *  1.12333333333| The A account deposit amount * The changed factor |
      |Total staked amount| 1100  | (679.228486647 + 300)  * 1.12333333333 | The total deposit amount * The changed factor |

      - The operator should take 70 out of the 100 issued seigniorages(the operator's stake rate is 70%), but 7 of them, which corresponds to a commission rate of 10%, are distributed to the stakers(delegator), so about 63 seigniorages are added to the operator's staking amount. The original staking amount was 700, but after the update seigniorage was executed, it became 762.99999999998.
      - The staker takes 30 out of the 100 issued seigniorages (the staker's stake rate is 30%), and adds the 7 given by the operator, so about 37 seigniorages are added. The original staking amount was 300, but after the update seigniorage was executed, it became  336.999999999.




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


---
