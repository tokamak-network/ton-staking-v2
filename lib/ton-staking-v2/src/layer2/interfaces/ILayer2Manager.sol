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

    /// @notice SystemConfig 주소로 Layer2 주소 조회
    /// @param systemConfig SystemConfig 컨트랙트 주소
    /// @return layer2 해당 Layer2 주소 (없으면 address(0))
    function getLayer2BySystemConfig(address systemConfig) external view returns (address layer2);

    /// @notice rollupConfig의 Bridged TON 조회
    /// @param rollupConfig L2의 SystemConfig 주소
    /// @return bridgedTon Bridged TON 양 (TON 단위)
    function getBridgedTon(address rollupConfig) external view returns (uint256 bridgedTon);

    /// @notice Layer2 주소로 Bridged TON 조회
    /// @param layer2 L2 주소 (candidate)
    /// @return bridgedTon Bridged TON 양 (TON 단위)
    function getBridgedTonByLayer(address layer2) external view returns (uint256 bridgedTon);
}