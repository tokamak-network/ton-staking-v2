// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface ILayer2Manager {
    function pauseCandidateAddOn(address rollupConfig) external;
    function unpauseCandidateAddOn(address rollupConfig) external;
    function candidateAddOnOfOperator(address operator) external view returns (address);
    function checkL1Bridge(address _rollupConfig) external view returns (bool result, address l1Bridge, address portal, address l2Ton);
    function checkL1BridgeDetail(address _rollupConfig) external view returns
        (bool result, address l1Bridge, address portal, address l2Ton,
        uint8 _type, uint8 status, bool rejectedSeigs, bool rejectedL2Deposit);

    function updateSeigniorage(address rollupConfig, uint256 amount) external;
    function rollupConfigOfOperator(address operator) external view returns (address);
    function statusLayer2(address rollupConfig) external view returns (uint8);

    function transferL2Seigniorage(address layer2, uint256 amount) external;
    function layerInfo(address layer2) external view returns (address rollupConfig, address operator);
}