// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Mock Coinage for testing
contract MockCoinage {
    uint256 private _totalSupply;
    uint256 private _factor = 1e27; // RAY
    mapping(address => uint256) private _balances;

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function factor() external view returns (uint256) {
        return _factor;
    }

    function setFactor(uint256 newFactor) external returns (bool) {
        _factor = newFactor;
        return true;
    }

    function mint(address account, uint256 amount) external returns (bool) {
        _totalSupply += amount;
        _balances[account] += amount;
        return true;
    }

    function burnFrom(address account, uint256 amount) external returns (bool) {
        require(_balances[account] >= amount, "insufficient balance");
        _totalSupply -= amount;
        _balances[account] -= amount;
        return true;
    }

    // For testing: set balance directly
    function setBalance(address account, uint256 amount) external {
        uint256 oldBalance = _balances[account];
        _balances[account] = amount;
        if (amount > oldBalance) {
            _totalSupply += (amount - oldBalance);
        } else {
            _totalSupply -= (oldBalance - amount);
        }
    }

    // For testing: set total supply directly
    function setTotalSupply(uint256 amount) external {
        _totalSupply = amount;
    }
}
