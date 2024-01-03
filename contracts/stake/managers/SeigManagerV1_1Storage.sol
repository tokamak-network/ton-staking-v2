// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract SeigManagerV1_1Storage  {

    uint256 constant public SEIG_START_MAINNET = 10837698;
    uint256 constant public INITIAL_TOTAL_SUPPLY_MAINNET = 50000000000000000000000000000000000;
    uint256 constant public BURNT_AMOUNT_MAINNET = 178111666909855730000000000000000;

    /// Seigniorage issuance start block
    uint256 public seigStartBlock;

    /// initial total supply
    uint256 public initialTotalSupply;

    /// burnt amount at DAO
    uint256 public burntAmountAtDAO;

}
