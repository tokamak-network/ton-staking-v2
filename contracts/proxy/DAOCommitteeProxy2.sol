// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../dao/StorageStateCommittee.sol";
import {AccessControl} from "../accessControl/AccessControl.sol";
import {ERC165A}  from "../accessControl/ERC165A.sol";
import "./ProxyStorage2.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IProxyEvent.sol";
import "../interfaces/IProxyAction2.sol";

contract DAOCommitteeProxy2 is 
    StorageStateCommittee,
    AccessControl,
    ERC165A, 
    ProxyStorage2,
    IProxyEvent, 
    IProxyAction2
{
    address internal _implementation;
    bool public pauseProxy;

    modifier onlyOwner2() {
        // console.log("msg.sedner :", msg.sender);
        // console.logBytes32(DEFAULT_ADMIN_ROLE);
        // console.logBool(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DAOCommitteeProxyV2: msg.sender is not an admin");
        _;
    }


    /* ========== onlyOwner ========== */

    /// @notice Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo2(address impl) external onlyOwner2 {
        require(impl != address(0), "input is zero");
        require(
            _implementation2(0) != impl,
            "same addr"
        );
        _setImplementation2(impl, 0, true);
        emit Upgraded(impl);
    }


    /// @inheritdoc IProxyAction2
    function setImplementation2(
        address newImplementation,
        uint256 _index,
        bool _alive
    ) external override onlyOwner2 {
        _setImplementation2(newImplementation, _index, _alive);
    }

    /// @inheritdoc IProxyAction2
    function setAliveImplementation2(address newImplementation, bool _alive)
        public override onlyOwner2
    {
        _setAliveImplementation2(newImplementation, _alive);
    }

    /// @inheritdoc IProxyAction2
    function setSelectorImplementations2(
        bytes4[] calldata _selectors,
        address _imp
    ) public override onlyOwner2 {
        require(
            _selectors.length > 0,
            "Proxy: _selectors's size is zero"
        );
        require(aliveImplementation[_imp], "Proxy: _imp is not alive");

        for (uint256 i = 0; i < _selectors.length; i++) {
            require(
                selectorImplementation[_selectors[i]] != _imp,
                "LiquidityVaultProxy: same imp"
            );
            selectorImplementation[_selectors[i]] = _imp;
            emit SetSelectorImplementation(_selectors[i], _imp);
        }
    }

    /* ========== Anyone can   ========== */



    /* ========== VIEW ========== */

    /// @dev returns the implementation
    function implementation() external view returns (address) {
        return _implementation2(0);
    }

    /// @inheritdoc IProxyAction2
    function implementation2(uint256 _index) external override view returns (address) {
        return _implementation2(_index);
    }


    /// @inheritdoc IProxyAction2
    function getSelectorImplementation2(bytes4 _selector)
        public override
        view
        returns (address impl)
    {
        if (selectorImplementation[_selector] == address(0))
            return proxyImplementation[0];
        else if (aliveImplementation[selectorImplementation[_selector]]){
            return selectorImplementation[_selector];
        }
        else return proxyImplementation[0];
    }


    /// @dev receive ether
    receive() external payable {
        revert("cannot receive Ether");
    }

    /// @dev fallback function , execute on undefined function call
    fallback() external payable {
        _fallback();
    }

    /* === ======= internal ========== */

    /// @dev view implementation address of the proxy[index]
    /// @param _index index of proxy
    /// @return impl address of the implementation
    function _implementation2(uint256 _index)
        internal
        view
        returns (address impl)
    {
        return proxyImplementation[_index];
    }

    /// @dev fallback function , execute on undefined function call
    function _fallback() internal {
        address _impl = getSelectorImplementation2(msg.sig);

        require(
            _impl != address(0) && !pauseProxy,
            "Proxy: impl OR proxy is false"
        );

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /// @dev set the implementation address and status of the proxy[index]
    /// @param newImplementation Address of the new implementation.
    /// @param _index index of proxy
    /// @param _alive alive status
    function _setImplementation2(
        address newImplementation,
        uint256 _index,
        bool _alive
    ) internal {
        require(
            Address.isContract(newImplementation),
            "Proxy: not contract address"
        );
        if (_alive) proxyImplementation[_index] = newImplementation;
        _setAliveImplementation2(newImplementation, _alive);
    }

    /// @dev set alive status of implementation
    /// @param newImplementation Address of the new implementation.
    /// @param _alive alive status
    function _setAliveImplementation2(address newImplementation, bool _alive)
        internal
    {
        aliveImplementation[newImplementation] = _alive;
        emit SetAliveImplementation(newImplementation, _alive);
    }

}