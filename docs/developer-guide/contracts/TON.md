# [TON](https://etherscan.io/address/0x2be5e8c109e2197d077d13a82daead6a9b3433c5#code)

- It is a utility token for the Tokamak Network ecosystem.
- ERC20 Token
    - Name     : Tokamak Network Token
    - Symbol   : TON
    - Decimals : 18


## Differentiated functions

###  [transferFrom (address sender, address recipient, uint256 amount) public returns (bool)](https://etherscan.io/address/0x2be5e8c109e2197d077d13a82daead6a9b3433c5?#code#L1093)

When using transferFrom, the caller executing the transaction must be the same account that gives the asset or the account that receives the asset. Otherwise, the transferFrom function will fail.
Therefore, it cannot be used for services that transfer assets by entrusting them to a third party, such as an escrow service. In such cases, WTON should be used instead of TON.

```
  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(msg.sender == sender || msg.sender == recipient, "SeigToken: only sender or recipient can transfer");
    return super.transferFrom(sender, recipient, amount);
  }
```

---

###  [approveAndCall (address spender, uint256 amount, bytes memory data)](https://etherscan.io/address/0x2be5e8c109e2197d077d13a82daead6a9b3433c5#writeContract#F3)


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