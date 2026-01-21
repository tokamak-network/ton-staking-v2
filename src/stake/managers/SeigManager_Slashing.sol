// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FullMath} from "../../libraries/FullMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import "../../proxy/ProxyStorage.sol";
import {AuthControlSeigManager} from "../../common/AuthControlSeigManager.sol";
import {SeigManagerStorage} from "./SeigManagerStorage.sol";
import {SeigManagerV1_1Storage} from "./SeigManagerV1_1Storage.sol";
import {SeigManagerV1_3Storage} from "./SeigManagerV1_3Storage.sol";
import {SeigManagerV1_4Storage} from "./SeigManagerV1_4Storage.sol";

interface IDepositSlashing {
    function slashingRewardRate() external view returns (uint256);
}

/**
 * @dev SeigManager_Slashing handles the slashing logic for operators in the Tokamak Network.
 * It is primarily called by the DepositManager when an operator's stake needs to be removed
 * due to a slashable offense (e.g., losing a challenge in a Layer 2).
 *
 * [Slashing Mechanism]
 * 1. The operator's entire staked amount (including principal and accrued seigniorage)
 *    is identified via their balance in {coinages[layer2]}.
 * 2. This amount, along with its proportional share of rewards in the global {tot} pool,
 *    is burned from both {coinages[layer2]} and {tot}.
 *
 * [Burn Amount Calculation]
 * When `onSlash(layer2, operator)` is executed:
 *  1. Burn {v} {coinages[layer2]} tokens from the operator's account.
 *  2. Burn {v + ⍺} {tot} tokens from the layer2 contract address,
 *     where:
 *     - v = operator's balance in {coinages[layer2]}
 *     - ⍺ = (tot.balanceOf(layer2) - coinages[layer2].totalSupply()) * (v / coinages[layer2].totalSupply())
 *
 * This ensures that a slashed operator loses their entire stake and all rewards earned up to that point.
 */
contract SeigManager_Slashing is
    ProxyStorage,
    AuthControlSeigManager,
    SeigManagerStorage,
    SeigManagerV1_1Storage,
    SeigManagerV1_3Storage,
    SeigManagerV1_4Storage
{
    uint256 internal constant WEI_UNIT = 1e18;

    //////////////////////////////
    // Modifiers
    //////////////////////////////

    modifier onlyDepositManager() {
        require(msg.sender == _depositManager, "not onlyDepositManager");
        _;
    }

    //////////////////////////////
    // Events
    //////////////////////////////

    event Slashed(address layer2, address operator);

    //////////////////////////////
    // onlyDepositManager
    //////////////////////////////

    /**
     * @notice Slashing 시 호출되는 함수. Operator의 Coinage와 Tot 토큰을 소각
     * @param layer2 The layer2 address
     * @param operator The operator address to be slashed
     * @param challenger The address of the challenger who proved the fraud
     */
    function onSlash(
        address layer2,
        address operator,
        address challenger
    ) external onlyDepositManager returns (uint256 totalSlashedAmount) {
        uint256 operatorAmount = _coinages[layer2].balanceOf(operator);

        // burn {v + ⍺} {tot} tokens to the layer2 contract,
        uint256 totAmount = _uncommittedOperatorSeigniorage(layer2, operatorAmount);

        _tot.burnFrom(layer2, operatorAmount + totAmount);

        // burn {v} {coinages[layer2]} tokens to the account
        _coinages[layer2].burnFrom(operator, operatorAmount);

        emit Slashed(layer2, operator);

        return operatorAmount + totAmount;
    }

    //////////////////////////////
    // Internal functions
    //////////////////////////////

    // return ⍺, where ⍺ = (tot.balanceOf(layer2) - coinages[layer2].totalSupply()) * (amount / coinages[layer2].totalSupply())
    function _uncommittedOperatorSeigniorage(
        address layer2,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 coinageTotalSupply = _coinages[layer2].totalSupply();
        uint256 totBalance = _tot.balanceOf(layer2);

        // NOTE: arithamtic operations (mul and div) make some errors, so we gonna adjust them under 1e-9 WTON.
        //       note that coinageTotalSupply and totBalance are RAY values.
        if (coinageTotalSupply >= totBalance && coinageTotalSupply - totBalance < WEI_UNIT) {
            return 0;
        }

        return
            FullMath.rdiv(
                FullMath.rmul(totBalance - coinageTotalSupply, amount),
                coinageTotalSupply
            );
    }
}
