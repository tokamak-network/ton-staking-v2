// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {StorageStateCommittee} from "../../../src/dao/StorageStateCommittee.sol";
import {AccessControl} from "../../../src/accessControl/AccessControl.sol";

/// @title MockDAOCommitteeProxy
/// @notice Shared Mock DAO Proxy for V3 Testing
/// @dev Used by all V3 test files that need DAO proxy functionality
contract MockDAOCommitteeProxy is StorageStateCommittee, AccessControl {
    address internal _implementation;
    bool public pauseProxy;

    event Upgraded(address indexed implementation);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin");
        _;
    }

    constructor(address _ton) {
        ton = _ton;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    function upgradeTo(address impl) external onlyAdmin {
        require(impl != address(0), "zero address");
        _implementation = impl;
        emit Upgraded(impl);
    }

    function implementation() public view returns (address) {
        return _implementation;
    }

    fallback() external payable {
        address _impl = _implementation;
        require(_impl != address(0) && !pauseProxy, "proxy disabled");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

/// @title IDAOCommitteeProxy2
/// @notice Interface for DAOCommitteeProxy2 functions
interface IDAOCommitteeProxy2 {
    function upgradeTo2(address impl) external;
    function setAliveImplementation2(address impl, bool alive) external;
    function setSelectorImplementations2(bytes4[] calldata selectors, address impl) external;
}
