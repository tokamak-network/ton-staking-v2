// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FullMath} from "../../libraries/FullMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {RefactorCoinageSnapshotI} from "../interfaces/RefactorCoinageSnapshotI.sol";
import {IWTON} from "../../dao/interfaces/IWTON.sol";
import {Layer2I} from "../../dao/interfaces/Layer2I.sol";
import {IL1BridgeRegistry} from "../../layer2/interfaces/IL1BridgeRegistry.sol";
import {ILayer2Manager} from "../../layer2/interfaces/ILayer2Manager.sol";
import {ITON} from "../interfaces/ITON.sol";

import {ProxyStorage} from "../../proxy/ProxyStorage.sol";
import {AuthControlSeigManager} from "../../common/AuthControlSeigManager.sol";
import {SeigManagerStorage} from "./SeigManagerStorage.sol";
import {SeigManagerV1_1Storage} from "./SeigManagerV1_1Storage.sol";
import {SeigManagerV1_3Storage} from "./SeigManagerV1_3Storage.sol";
import {SeigManagerV1_4Storage} from "./SeigManagerV1_4Storage.sol";

// Custom Errors
error LastSeigBlockError();
error MinimumAmountError();
error UpdateSeigniorageError();
error IncreaseTotError();
error InvalidCoinageError();

/**
 * @title SeigManagerV3_2
 * @notice V2 호환 로직 컨트랙트 (delegatecall로 호출됨)
 * @dev SeigManagerV3_1에서 v3Migrated == false일 때 delegatecall로 호출
 *      스토리지 레이아웃은 SeigManagerV3_1과 동일해야 함
 */
contract SeigManagerV3_2 is
    ProxyStorage,
    AuthControlSeigManager,
    SeigManagerStorage,
    SeigManagerV1_1Storage,
    SeigManagerV1_3Storage,
    SeigManagerV1_4Storage
{
    uint256 internal constant WEI_UNIT = 1e18;
    uint256 internal constant GWEI_UNIT = 1e9;
    uint256 internal constant RAY_UNIT = 1e27;

    // ==========================================
    // Events
    // ==========================================

    event Comitted(address indexed layer2);

    event AddedSeigAtLayer(
        address layer2,
        uint256 seigs,
        uint256 operatorSeigs,
        uint256 nextTotalSupply,
        uint256 prevTotalSupply
    );

    event CommitLog1(
        uint256 totalStakedAmount,
        uint256 totalSupplyOfWton,
        uint256 prevTotalSupply,
        uint256 nextTotalSupply
    );

    event SeigGiven2(
        address indexed layer2,
        uint256 totalSeig,
        uint256 stakedSeig,
        uint256 unstakedSeig,
        uint256 powertonSeig,
        uint256 daoSeig,
        uint256 pseig,
        uint256 l2TotalSeigs,
        uint256 layer2Seigs
    );

    // ==========================================
    // V2 Seigniorage Functions
    // ==========================================

    /// @notice V2 시뇨리지 분배 (스테이커 시뇨리지 포함)
    /// @dev delegatecall로 호출됨 - 스토리지는 caller(V3_1)의 것 사용
    function updateSeigniorageV2() external returns (bool) {
        // short circuit if paused
        if (paused) {
            return true;
        }

        RefactorCoinageSnapshotI coinage = _coinages[msg.sender];
        _checkCoinage(address(coinage));

        if (block.number <= _lastSeigBlock) revert LastSeigBlockError();

        address operator = Layer2I(msg.sender).operator();
        uint256 operatorAmount = coinage.balanceOf(operator);

        if (operatorAmount < minimumAmount) revert MinimumAmountError();
        if (!_increaseTot()) revert IncreaseTotError();

        _lastCommitBlock[msg.sender] = block.number;

        // 2. increase total supply of {coinages[layer2]}
        uint256 prevTotalSupply = coinage.totalSupply();
        uint256 nextTotalSupply = _tot.balanceOf(msg.sender);

        // short circuit if there is no seigs for the layer2
        if (prevTotalSupply >= nextTotalSupply) {
            emit Comitted(msg.sender);
            return true;
        }

        uint256 seigs = nextTotalSupply - prevTotalSupply;
        uint256 operatorSeigs;
        bool isCommissionRateNegative_;

        (nextTotalSupply, operatorSeigs, isCommissionRateNegative_) = _calcSeigsDistribution(
            msg.sender,
            coinage,
            prevTotalSupply,
            seigs,
            operator
        );

        // gives seigniorages to the layer2 as coinage
        require(
            coinage.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, coinage.factor())),
            'fail setFactor'
        );

        // give commission to operator or delegators
        if (operatorSeigs != 0) {
            if (isCommissionRateNegative_) {
                coinage.burnFrom(operator, operatorSeigs);
            } else {
                coinage.mint(operator, operatorSeigs);
            }
        }

        if (seigs != 0) IWTON(_wton).mint(address(_depositManager), seigs);

        emit Comitted(msg.sender);
        emit AddedSeigAtLayer(msg.sender, seigs, operatorSeigs, nextTotalSupply, prevTotalSupply);

        return true;
    }

    // ==========================================
    // Internal Functions
    // ==========================================

    function _increaseTot() internal returns (bool result) {
        if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            _lastSeigBlock = block.number;
            return false;
        }

        uint256 prevTotalSupply = _tot.totalSupply();

        uint256 span = block.number - _lastSeigBlock;
        if (_unpausedBlock > _lastSeigBlock) span -= (_unpausedBlock - _pausedBlock);

        uint256 maxSeig = span * _seigPerBlock;
        uint256 tos = _totalSupplyOfTon(block.number);

        uint256 stakedSeig = FullMath.rdiv(
            FullMath.rmul(maxSeig, prevTotalSupply),
            tos
        );

        if (layer2StartBlock == 0) layer2StartBlock = block.number - 1;

        address wton_ = _wton;
        uint256 l2TotalSeigs;
        uint256 layer2Seigs;

        if (layer2Manager != address(0) && layer2StartBlock != 1) {
            if (layer2StartBlock <= block.number && totalLayer2TVL > 0) {
                uint256 tempTotalLayer2Tvl = Math.min(totalLayer2TVL * GWEI_UNIT, tos-prevTotalSupply);
                if (tempTotalLayer2Tvl < RAY_UNIT) tempTotalLayer2Tvl = 0;
                l2TotalSeigs = FullMath.rdiv(FullMath.rmul(maxSeig, tempTotalLayer2Tvl), tos);
                l2RewardPerUint += (l2TotalSeigs * WEI_UNIT) / totalLayer2TVL;
                if (l2TotalSeigs != 0) IWTON(wton_).mint(layer2Manager, l2TotalSeigs);
            }

            (address rollupConfig, bool allowed) = _allowIssuanceLayer2Seigs(msg.sender);

            if (allowed && !_isPauseL2Seigniorage(msg.sender)) {
                uint256 curLayer2Tvl = IL1BridgeRegistry(l1BridgeRegistry).layer2Tvl(rollupConfig);
                Layer2Reward storage newLayer2Info = layer2RewardInfo[msg.sender];
                Layer2Reward memory oldLayer2Info = layer2RewardInfo[msg.sender];

                if (oldLayer2Info.layer2Tvl != curLayer2Tvl) {
                    newLayer2Info.layer2Tvl = curLayer2Tvl;
                    totalLayer2TVL = totalLayer2TVL + curLayer2Tvl - oldLayer2Info.layer2Tvl;
                }

                if (oldLayer2Info.startBlock == 0) {
                    newLayer2Info.startBlock = block.number;
                } else {
                    if (oldLayer2Info.layer2Tvl > 0) {
                        layer2Seigs =
                            ((l2RewardPerUint * oldLayer2Info.layer2Tvl) / WEI_UNIT) -
                            oldLayer2Info.initialDebt;
                        if (layer2Seigs != 0) ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
                    }
                }
                newLayer2Info.initialDebt = (l2RewardPerUint * curLayer2Tvl) / WEI_UNIT;
            }
        }

        uint256 unstakedSeig = maxSeig - stakedSeig - l2TotalSeigs;
        uint256 totalPseig = FullMath.rmul(unstakedSeig, relativeSeigRate);
        uint256 nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
        _lastSeigBlock = block.number;

        _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

        emit CommitLog1(_tot.totalSupply(), tos, prevTotalSupply, nextTotalSupply);

        uint256 powertonSeig;
        uint256 daoSeig;
        uint256 relativeSeig;

        if (_powerton != address(0)) {
            powertonSeig = FullMath.rmul(unstakedSeig, powerTONSeigRate);
            if (powertonSeig != 0) IWTON(wton_).mint(_powerton, powertonSeig);
        }

        if (dao != address(0)) {
            daoSeig = FullMath.rmul(unstakedSeig, daoSeigRate);
            if (daoSeig != 0) IWTON(wton_).mint(dao, daoSeig);
        }

        if (relativeSeigRate != 0) {
            relativeSeig = totalPseig;
            accRelativeSeig += relativeSeig;
        }

        emit SeigGiven2(
            msg.sender,
            maxSeig,
            stakedSeig,
            unstakedSeig,
            powertonSeig,
            daoSeig,
            relativeSeig,
            l2TotalSeigs,
            layer2Seigs
        );

        result = true;
    }

    function _calcSeigsDistribution(
        address layer2,
        RefactorCoinageSnapshotI coinage,
        uint256 prevTotalSupply,
        uint256 seigs,
        address operator
    )
        internal
        returns (
            uint256 nextTotalSupply,
            uint256 operatorSeigs,
            bool isCommissionRateNegative_
        )
    {
        {
            uint256 _delayedCommissionBlock = delayedCommissionBlock[layer2];

            if (_delayedCommissionBlock != 0 && block.number >= _delayedCommissionBlock) {
                _commissionRates[layer2] = delayedCommissionRate[layer2];
                _isCommissionRateNegative[layer2] = delayedCommissionRateNegative[layer2];
                delayedCommissionBlock[layer2] = 0;
            }
        }

        isCommissionRateNegative_ = _isCommissionRateNegative[layer2];
        uint256 commissionRate = _commissionRates[layer2];

        nextTotalSupply = prevTotalSupply + seigs;

        if (commissionRate == 0)
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);

        if (!isCommissionRateNegative_) {
            operatorSeigs = (seigs * commissionRate) / RAY_UNIT;
            nextTotalSupply -= operatorSeigs;
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);
        }

        if (prevTotalSupply == 0)
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);

        uint256 operatorBalance = coinage.balanceOf(operator);

        if (operatorBalance == 0)
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);

        (operatorSeigs, nextTotalSupply) = _calcNegativeCommission(
            seigs,
            operatorBalance,
            prevTotalSupply,
            commissionRate,
            nextTotalSupply
        );

        return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);
    }

    function _calcNegativeCommission(
        uint256 seigs,
        uint256 operatorBalance,
        uint256 prevTotalSupply,
        uint256 commissionRate,
        uint256 nextTotalSupply
    ) internal pure returns (uint256 operatorSeigs, uint256 newNextTotalSupply) {
        uint256 operatorRate = (operatorBalance * RAY_UNIT) / prevTotalSupply;
        operatorSeigs = (seigs * operatorRate * commissionRate) / (RAY_UNIT * RAY_UNIT);

        uint256 delegatorSeigs = (operatorRate == RAY_UNIT)
            ? operatorSeigs
            : (operatorSeigs * RAY_UNIT) / (RAY_UNIT - operatorRate);

        operatorSeigs = delegatorSeigs;
        newNextTotalSupply = nextTotalSupply + delegatorSeigs;
    }

    function _calcNewFactor(
        uint256 source,
        uint256 target,
        uint256 oldFactor
    ) internal pure returns (uint256) {
        return (target * oldFactor) / source;
    }

    function _checkCoinage(address coinage_) internal pure {
        if (coinage_ == address(0)) revert InvalidCoinageError();
    }

    function _totalSupplyOfTon(uint256 blockNumber) internal view returns (uint256 tos) {
        bool isMainnet = block.chainid == 1;
        uint256 initial = initialTotalSupply == 0 ? (isMainnet ? INITIAL_TOTAL_SUPPLY_MAINNET : 0) : initialTotalSupply;
        uint256 startBlock = seigStartBlock == 0 ? (isMainnet ? SEIG_START_MAINNET : 0) : seigStartBlock;
        uint256 burnt = burntAmountAtDAO == 0 ? (isMainnet ? BURNT_AMOUNT_MAINNET : 0) : burntAmountAtDAO;

        tos = initial +
            (_seigPerBlock * (blockNumber - startBlock)) -
            (ITON(_ton).balanceOf(address(1)) * (10 ** 9)) -
            burnt;
    }

    function _isPauseL2Seigniorage(address layer2) internal view returns (bool) {
        uint256[] memory pauseBlocks = layer2PauseBlocks[layer2];
        uint256 len = pauseBlocks.length;
        if (len == 0) return false;

        uint256 pauseBlock = pauseBlocks[len - 1];

        if (pauseBlock != 0 && layer2UnpauseBlocks[layer2][pauseBlock] == 0) return true;
        else return false;
    }

    function _allowIssuanceLayer2Seigs(
        address layer2
    ) internal view returns (address rollupConfig, bool allowed) {
        address tempRollupConfig;
        (tempRollupConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
        rollupConfig = tempRollupConfig;
        if (ILayer2Manager(layer2Manager).statusLayer2(rollupConfig) == 1) allowed = true;
    }

    // ==========================================
    // V2 Estimation Functions
    // ==========================================

    /// @notice V2 시뇨리지 추정 (delegatecall로 호출됨)
    function estimatedDistributeV2(
        uint256 blockNumber,
        address layer2
    )
        external
        view
        returns (
            uint256 maxSeig,
            uint256 stakedSeig,
            uint256 unstakedSeig,
            uint256 powertonSeig,
            uint256 daoSeig,
            uint256 relativeSeig,
            uint256 l2TotalSeigs,
            uint256 layer2Seigs
        )
    {
        return _estimatedDistribute(blockNumber, layer2);
    }

    /// @notice V2 청구 가능 L2 시뇨리지 (delegatecall로 호출됨)
    function claimableL2SeigniorageV2(address layer2) external view returns (uint256 amount) {
        (, , , , , , , amount) = _estimatedDistribute(block.number + 1, layer2);
    }

    function _estimatedDistribute(
        uint256 blockNumber,
        address layer2
    )
        internal
        view
        returns (
            uint256 maxSeig,
            uint256 stakedSeig,
            uint256 unstakedSeig,
            uint256 powertonSeig,
            uint256 daoSeig,
            uint256 relativeSeig,
            uint256 l2TotalSeigs,
            uint256 layer2Seigs
        )
    {
        if (blockNumber <= _lastSeigBlock || RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }

        uint256 prevTotalSupply = _tot.totalSupply();
        uint256 tos = _totalSupplyOfTon(blockNumber);

        {
            uint256 span = blockNumber - _lastSeigBlock;
            if (_unpausedBlock > _lastSeigBlock) span -= (_unpausedBlock - _pausedBlock);
            maxSeig = span * _seigPerBlock;
        }

        stakedSeig = FullMath.rdiv(FullMath.rmul(maxSeig, prevTotalSupply), tos);

        (l2TotalSeigs, layer2Seigs) = _calcLayer2Seigs(blockNumber, layer2, maxSeig, tos, prevTotalSupply);

        unstakedSeig = maxSeig - stakedSeig - l2TotalSeigs;

        if (address(_powerton) != address(0)) {
            powertonSeig = FullMath.rmul(unstakedSeig, powerTONSeigRate);
        }
        if (dao != address(0)) {
            daoSeig = FullMath.rmul(unstakedSeig, daoSeigRate);
        }
        if (relativeSeigRate != 0) {
            relativeSeig = FullMath.rmul(unstakedSeig, relativeSeigRate);
        }
    }

    function _calcLayer2Seigs(
        uint256 blockNumber,
        address layer2,
        uint256 maxSeig,
        uint256 tos,
        uint256 prevTotalSupply
    ) internal view returns (uint256 l2TotalSeigs, uint256 layer2Seigs) {
        uint256 _totalLayer2Tvl = Math.min(totalLayer2TVL * GWEI_UNIT, tos - prevTotalSupply);
        if (_totalLayer2Tvl < RAY_UNIT) return (0, 0);

        uint256 tempLayer2StartBlock = layer2StartBlock;
        if (tempLayer2StartBlock == 0) tempLayer2StartBlock = blockNumber - 1;

        if (
            layer2Manager == address(0) ||
            tempLayer2StartBlock == 1 ||
            tempLayer2StartBlock >= blockNumber
        ) {
            return (0, 0);
        }

        (address rollupConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
        bool layer2Allowed = ILayer2Manager(layer2Manager).statusLayer2(rollupConfig) == 1;

        l2TotalSeigs = FullMath.rdiv(FullMath.rmul(maxSeig, _totalLayer2Tvl), tos);

        if (layer2Allowed && totalLayer2TVL != 0) {
            Layer2Reward memory oldLayer2Info = layer2RewardInfo[layer2];
            if (oldLayer2Info.startBlock != 0 && oldLayer2Info.layer2Tvl != 0) {
                uint256 templ2RewardPerUint = l2RewardPerUint + (l2TotalSeigs * WEI_UNIT) / totalLayer2TVL;
                layer2Seigs = ((templ2RewardPerUint * oldLayer2Info.layer2Tvl) / WEI_UNIT) - oldLayer2Info.initialDebt;
            }
        }
    }
}
