// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISeigManager} from '../interfaces/ISeigManager.sol';
import {ILayer2} from '../../dao/interfaces/ILayer2.sol';

import '../../proxy/ProxyStorage.sol';
import {AccessibleCommon} from '../../common/AccessibleCommon.sol';
import {DepositManagerStorage} from './DepositManagerStorage.sol';
import {DepositManagerV1_1Storage} from './DepositManagerV1_1Storage.sol';

/**
 * @dev DepositManager_Slashing manages the slashing mechanism and reward distribution for the Tokamak Network.
 * It allows the owner to set the slashing reward rate for challengers and provides the core logic
 * for slashing an operator's stake when a dispute is resolved.
 *
 * [Main Functions]
 * 1. setSlashingRewardRate: Configures the percentage of the slashed stake that is awarded to the challenger.
 * 2. slash: Executes the slashing process, which involves zeroing out the operator's stake,
 *    notifying the SeigManager, and transferring the reward to the challenger.
 */
contract DepositManager_Slashing is
    ProxyStorage,
    AccessibleCommon,
    DepositManagerStorage,
    DepositManagerV1_1Storage
{
    using SafeERC20 for IERC20;

    modifier onlyLayer2Manager() {
        require(msg.sender == layer2Manager, 'not layer2Manager');
        _;
    }

    ////////////////////
    // Events
    ////////////////////

    event Slashed(
        address indexed layer2,
        address indexed operator,
        address indexed challenger,
        uint256 slashedAmount,
        uint256 rewardAmount
    );
    event ChallengerRewarded(address indexed layer2, address indexed challenger, uint256 amount);
    event SlashingRewardRateSet(uint256 newRate);

    function setSlashingRewardRate(uint256 newRate) external onlyOwner {
        require(newRate <= 10000, 'rate exceeds 100%');
        slashingRewardRate = newRate;
        emit SlashingRewardRateSet(newRate);
    }

    function slash(
        address layer2,
        address operator,
        address challenger
    ) external onlyLayer2Manager returns (bool) {
        require(operator == ILayer2(layer2).operator(), 'operator is not an operator');
        require(challenger != address(0), 'invalid challenger address');

        uint256 slashedAmount = _accStaked[layer2][operator];
        require(slashedAmount > 0, 'no staked amount to slash');

        // 보상 금액 계산 (slashingRewardRate가 0이면 보상 없음)
        uint256 rewardAmount = 0;
        if (slashingRewardRate > 0) {
            // 100% = 10000 단위로 계산: slashedAmount * slashingRewardRate / 10000
            rewardAmount = (slashedAmount * slashingRewardRate) / 10000;
        }

        // 회계 장부 초기화
        _accStaked[layer2][operator] = 0;
        _accStakedLayer2[layer2] = _accStakedLayer2[layer2] - slashedAmount;
        _accStakedAccount[operator] = _accStakedAccount[operator] - slashedAmount;

        // SeigManager에 슬래싱 처리 요청
        require(ISeigManager(_seigManager).onSlash(layer2, operator), 'fail onSlash');

        // Challenger에게 보상 지급 (WTON 직접 전송)
        if (rewardAmount > 0) {
            IERC20(_wton).safeTransfer(challenger, rewardAmount);
            emit ChallengerRewarded(layer2, challenger, rewardAmount);
        }

        emit Slashed(layer2, operator, challenger, slashedAmount, rewardAmount);

        return true;
    }
}
