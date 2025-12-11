// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Mock L1BridgeRegistry for testing
contract MockL1BridgeRegistry {
    struct RollupInfo {
        uint8 rollupType;
        uint8 status;
        bool rejectedSeigs;
        bool rejectedL2Deposit;
        uint256 l2ChainId;
        address l2TON;
    }

    mapping(address => RollupInfo) public rollupInfos;

    function setRollupInfo(
        address rollupConfig,
        uint8 _rollupType,
        uint8 _status,
        bool _rejectedSeigs,
        bool _rejectedL2Deposit,
        uint256 _l2ChainId,
        address _l2TON
    ) external {
        rollupInfos[rollupConfig] = RollupInfo({
            rollupType: _rollupType,
            status: _status,
            rejectedSeigs: _rejectedSeigs,
            rejectedL2Deposit: _rejectedL2Deposit,
            l2ChainId: _l2ChainId,
            l2TON: _l2TON
        });
    }

    function getRollupInfo(address rollupConfig)
        external
        view
        returns (
            uint8 rollupType,
            uint8 status,
            bool rejectedSeigs,
            bool rejectedL2Deposit,
            uint256 l2ChainId
        )
    {
        RollupInfo storage info = rollupInfos[rollupConfig];
        return (
            info.rollupType,
            info.status,
            info.rejectedSeigs,
            info.rejectedL2Deposit,
            info.l2ChainId
        );
    }

    function rollupType(address rollupConfig) external view returns (uint8) {
        return rollupInfos[rollupConfig].rollupType;
    }

    function l2TON(address rollupConfig) external view returns (address) {
        return rollupInfos[rollupConfig].l2TON;
    }
}
