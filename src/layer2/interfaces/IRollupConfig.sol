// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IRollupConfig {
    function unsafeBlockSigner() external view returns (address);
}
