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



## Calculation of Operator Commission

Operators can set a commissionRate to receive a portion of the generated seigniorage as an operator commission, or distribute a portion of the operator's seigniorage to staker(delegator).

### Related Storages
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

### Seigniorage distribution related to isCommissionRateNegative

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
