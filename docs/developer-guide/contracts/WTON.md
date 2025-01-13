# [WTON](https://etherscan.io/address/0xc4a11aaf6ea915ed7ac194161d2fc9384f15bff2#code)

- ERC20 Token
    - Name     : Wrapped TON
    - Symbol   : WTON
    - Decimals : **27**

- As a seigniorage token, 3.92 WTON are issued per block.
- After staking TON, seigniorage can only be issued through the update seigniorage function.

## Differentiated functions

### [approveAndCall (address spender, uint256 amount, bytes memory data)](https://etherscan.io/address/0xc4a11aaf6ea915ed7ac194161d2fc9384f15bff2#writeContract#F3)


Supports approveAndCall function. By allowing approve and call to be done at the same time, It can provide a more convenient interface for users in terms of UX/UI.


```
contract ERC20OnApprove is ERC20 {
  function approveAndCall(address spender, uint256 amount, bytes memory data) public returns (bool) {
    require(approve(spender, amount));
    _callOnApprove(msg.sender, spender, amount, data);
    return true;
  }

  function _callOnApprove(address owner, address spender, uint256 amount, bytes memory data) internal {
    bytes4 onApproveSelector = OnApprove(spender).onApprove.selector;

    require(ERC165Checker._supportsInterface(spender, onApproveSelector),
      "ERC20OnApprove: spender doesn't support onApprove");

    (bool ok, bytes memory res) = spender.call(
      abi.encodeWithSelector(
        onApproveSelector,
        owner,
        spender,
        amount,
        data
      )
    );

    // check if low-level call reverted or not
    require(ok, string(res));

    assembly {
      ok := mload(add(res, 0x20))
    }

    // check if OnApprove.onApprove returns true or false
    require(ok, "ERC20OnApprove: failed to call onApprove");
  }

}
```
---

### [swapToTON (uint256 wtonAmount)](https://etherscan.io/address/0xc4a11aaf6ea915ed7ac194161d2fc9384f15bff2#writeContract#F20)

    swap WTON to TON
    - Parameters
        - wtonAmount (uint256) : Amount of WTON to convert to TON (in RAY (10^27) unit)

---

### [swapFromTON (uint256 tonAmount)](https://etherscan.io/address/0xc4a11aaf6ea915ed7ac194161d2fc9384f15bff2#writeContract#F18)

    swap TON to WTON
    - Parameters
        - tonAmount (uint256) : Amount of TON to convert to WTON (in WEI (10^18) unit)

---

### [swapToTONAndTransfer (address to, uint256 wtonAmount)](https://etherscan.io/address/0xc4a11aaf6ea915ed7ac194161d2fc9384f15bff2#writeContract#F21)

    swap WTON to TON, and transfer TON
    - Parameters
        - to (address) : Address to receive changed TON
        - wtonAmount (uint256) :Amount of WTON to convert to TON (in RAY (10^27) unit)

---

### [swapFromTONAndTransfer (address to, uint256 tonAmount)](https://etherscan.io/address/0xc4a11aaf6ea915ed7ac194161d2fc9384f15bff2#writeContract#F19)

    swap TON to WTON, and transfer WTON
    - Parameters
        - to (address) : Address to receive changed WTON
        - tonAmount (uint256) : Amount of TON to convert to WTON (in WEI (10^18) unit)


---