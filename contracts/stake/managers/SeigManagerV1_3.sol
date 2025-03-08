// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DSMath} from '../../libraries/DSMath.sol';
import {RefactorCoinageSnapshotI} from '../interfaces/RefactorCoinageSnapshotI.sol';
import {IWTON} from '../../dao/interfaces/IWTON.sol';
import {Layer2I} from '../../dao/interfaces/Layer2I.sol';
import '../../libraries/SArrays.sol';

import '../../proxy/ProxyStorage.sol';
import {AuthControlSeigManager} from '../../common/AuthControlSeigManager.sol';
import {SeigManagerStorage} from './SeigManagerStorage.sol';
import {SeigManagerV1_1Storage} from './SeigManagerV1_1Storage.sol';
import {SeigManagerV1_3Storage} from './SeigManagerV1_3Storage.sol';

error LastSeigBlockError();
error MinimumAmountError();
error UpdateSeigniorageError();
error IncreaseTotError();
error InvalidCoinageError();
error OnlyLayer2ManagerError();
error Layer2TvlError();

interface ITON {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface ICandidate {
    function updateSeigniorage() external returns (bool);
}

interface IL1BridgeRegistry {
    function layer2TVL(address _rollupConfig) external view returns (uint256 amount);
}

interface ILayer2Manager {
    function transferL2Seigniorage(address rollupConfig, uint256 amount) external;
    function rollupConfigOfOperator(address operator) external view returns (address);
    function statusLayer2(address rollupConfig) external view returns (uint8);
}

interface IILayer2Registry {
    function layer2s(address layer2) external view returns (bool);
    function numLayer2s() external view returns (uint256);
    function layer2ByIndex(uint256 index) external view returns (address);
}
/**
 * @dev SeigManager gives seigniorage to operator and WTON holders.
 * For each commit by operator, operator (or user) will get seigniorage
 * in propotion to the staked (or delegated) amount of WTON.
 *
 * [Tokens]
 * - {tot} tracks total staked or delegated WTON of each Layer2 contract (and depositor?).
 * - {coinages[layer2]} tracks staked or delegated WTON of user or operator to a Layer2 contract.
 *
 * For each commit by operator,
 *  1. increases all layer2's balance of {tot} by (the staked amount of WTON) /
 *     (total supply of TON and WTON) * (num blocks * seigniorage per block).
 *  2. increases all depositors' blanace of {coinages[layer2]} in proportion to the staked amount of WTON,
 *     up to the increased amount in step (1).
 *  3. set the layer2's balance of {committed} as the layer2's {tot} balance.
 *
 * For each stake or delegate with amount of {v} to a Layer2,
 *  1. mint {v} {coinages[layer2]} tokens to the account
 *  2. mint {v} {tot} tokens to the layer2 contract
 *
 * For each unstake or undelegate (or get rewards) with amount of {v} to a Layer2,
 *  1. burn {v} {coinages[layer2]} tokens from the account
 *  2. burn {v + ⍺} {tot} tokens from the layer2 contract,
 *   where ⍺ = SEIGS * staked ratio of the layer2 * withdrawal ratio of the account
 *     - SEIGS                              = tot total supply - tot total supply at last commit from the layer2
 *     - staked ratio of the layer2     = tot balance of the layer2 / tot total supply
 *     - withdrawal ratio of the account  = amount to withdraw / total supply of coinage
 *
 */
contract SeigManagerV1_3 is
    ProxyStorage,
    AuthControlSeigManager,
    SeigManagerStorage,
    SeigManagerV1_1Storage,
    DSMath,
    SeigManagerV1_3Storage
{
    using SArrays for uint256[];

    uint256 internal constant WEI_UINT = 1e18;

    //////////////////////////////
    // Events
    //////////////////////////////

    event SeigGiven(
        address indexed layer2,
        uint256 totalSeig,
        uint256 stakedSeig,
        uint256 unstakedSeig,
        uint256 powertonSeig,
        uint256 daoSeig,
        uint256 pseig
    );
    event Comitted(address indexed layer2);

    /** These were reflected from 18732908 block. */
    event AddedSeigAtLayer(
        address layer2,
        uint256 seigs,
        uint256 operatorSeigs,
        uint256 nextTotalSupply,
        uint256 prevTotalSupply
    );

    /** It was deleted from block 18732908, but was added again on v1. */
    event CommitLog1(
        uint256 totalStakedAmount,
        uint256 totalSupplyOfWTON,
        uint256 prevTotalSupply,
        uint256 nextTotalSupply
    );

    /** Added from v1_3. */
    /**
     * @notice Event that occurs when seigniorage is distributed when update seigniorage is executed
     * @param layer2        The layer2 address
     * @param totalSeig     Total amount of seigniorage issued
     * @param stakedSeig    Seigniorage equals to the staking ratio in TON total supply
     *                      in total issued seigniorage
     * @param unstakedSeig  Total issued seigniorage minus stakedSeig
     * @param powertonSeig  Seigniorage distributed to powerton
     * @param daoSeig       Seigniorage distributed to dao
     * @param pseig         Seigniorage equal to relativeSeigRate ratio from unstakedSeig amount
     *                      Seigniorage given to stakers = stakedSeig + pseig
     * @param l2TotalSeigs  Seigniorage distributed to L2 sequencer
     * @param layer2Seigs   Seigniorage currently settled (give) to CandidateAddOn's operatorManager contract
     */
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

    /**
     * @notice Event that occurs when calling excludeFromL2Seigniorage function
     * @param layer2        the layer2 address
     */
    event ExcludedFromL2Seigniorage(address layer2);

    /**
     * @notice Event that occurs when calling includeFromL2Seigniorage function
     * @param layer2        the layer2 address
     */
    event IncludedFromL2Seigniorage(address layer2);

    event SetLayer2Manager(address layer2Manager_);
    event SetLayer2StartBlock(uint256 startBlock_);
    event SetL1BridgeRegistry(address l1BridgeRegistry_);

    //////////////////////////////
    // onlyOwner
    //////////////////////////////

    /**
     * @notice Set the layer2Manager address
     * @param layer2Manager_    the layer2Manager address
     */
    function setLayer2Manager(address layer2Manager_) external onlyOwner {
        require(layer2Manager != layer2Manager_,"same");
        layer2Manager = layer2Manager_;
        emit SetLayer2Manager(layer2Manager_);
    }
    /**
     * @notice Set the layer2StartBlock
     * @param startBlock_    the start block
     */
    function setLayer2StartBlock(uint256 startBlock_) external onlyOwner {
        require(layer2StartBlock != startBlock_,"same");
        layer2StartBlock = startBlock_;
         emit SetLayer2StartBlock(startBlock_);
    }

    /**
     * @notice Set the l1BridgeRegistry_ address
     * @param l1BridgeRegistry_    the l1BridgeRegistry address
     */
    function setL1BridgeRegistry(address l1BridgeRegistry_) external onlyOwner {
        require(l1BridgeRegistry != l1BridgeRegistry_,"same");
        l1BridgeRegistry = l1BridgeRegistry_;
         emit SetL1BridgeRegistry(l1BridgeRegistry_);
    }

    //////////////////////////////
    // onlyLayer2Manager
    //////////////////////////////

    /**
     * @notice Exclude the layer2 in distributing a seigniorage
     * @param layer2     the layer2(candidate) address
     */
    function excludeFromL2Seigniorage(address layer2) external returns (bool) {
        _onlyLayer2Manager();
        _pauseLayer2Tvl(layer2);
        emit ExcludedFromL2Seigniorage(layer2);
        return true;
    }

    function includeFromL2Seigniorage(address layer2) external returns (bool) {
        _onlyLayer2Manager();
        _unpauseLayer2Tvl(layer2);

        require(!isPauseL2Seigniorage(layer2), "error includeFromL2Seigniorage");

        emit IncludedFromL2Seigniorage(layer2);
        return true;
    }

    //////////////////////////////
    // External functions
    //////////////////////////////

    /**
     * @notice Distribute the issuing seigniorage.
     */
    function updateSeigniorage() external returns (bool) {
        return _updateSeigniorage();
    }

    /**
     * @notice Distribute the issuing seigniorage on layer2(candidate).
     */
    function updateSeigniorageLayer(address layer2) external returns (bool) {
        if (!ICandidate(layer2).updateSeigniorage()) revert UpdateSeigniorageError();
        return true;
    }

    //////////////////////////////
    // View functions
    //////////////////////////////

    /**
     * @notice Estimate the seigniorage to be distributed
     * @param blockNumber         The block number
     * @param layer2              The layer2 address
     * @return maxSeig            Total amount of seigniorage occurring in that block
     * @return stakedSeig         the amount equals to the staking ratio in TON total supply
     *                            in total issuing seigniorage
     * @return unstakedSeig       MaxSeig minus stakedSeig
     * @return powertonSeig       the amount calculated to be distributed to Powerton
     * @return daoSeig            the amount calculated to be distributed to DAO
     * @return relativeSeig       the amount equal to relativeSeigRate ratio from unstakedSeig amount
     * @return l2TotalSeigs       the amount calculated to be distributed to L2 sequencer
     * @return layer2Seigs        the amount currently to be settled (give)  to CandidateAddOn's operatorManager contract
     */
    function estimatedDistribute(
        uint256 blockNumber,
        address layer2
    )
        public
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
        // short circuit if already seigniorage is given.
        if (blockNumber <= _lastSeigBlock || RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }

        uint256 span = blockNumber - _lastSeigBlock;
        if (_unpausedBlock > _lastSeigBlock) span -= (_unpausedBlock - _pausedBlock);

        uint256 prevTotalSupply = _tot.totalSupply();
        maxSeig = span * _seigPerBlock;
        uint256 tos = _totalSupplyOfTon(blockNumber);
        stakedSeig = rdiv(rmul(maxSeig, prevTotalSupply), tos);

        bool layer2Allowed;
        uint256 tempLayer2StartBlock = layer2StartBlock;
        Layer2Reward memory oldLayer2Info = layer2RewardInfo[layer2];
        if (layer2StartBlock == 0) tempLayer2StartBlock = blockNumber - 1;

        if (
            layer2Manager != address(0) &&
            tempLayer2StartBlock != 1 &&
            tempLayer2StartBlock < blockNumber
        ) {
            (, layer2Allowed) = allowIssuanceLayer2Seigs(layer2);
            if (totalLayer2TVL != 0) l2TotalSeigs = rdiv(rmul(maxSeig, totalLayer2TVL * 1e9), tos);
        }

        unstakedSeig = maxSeig - stakedSeig - l2TotalSeigs;
        uint256 totalPseig = rmul(unstakedSeig, relativeSeigRate);

        if (address(_powerton) != address(0)) powertonSeig = rmul(unstakedSeig, powerTONSeigRate);
        if (dao != address(0)) daoSeig = rmul(unstakedSeig, daoSeigRate);

        if (relativeSeigRate != 0) relativeSeig = totalPseig;

        if (layer2Allowed && totalLayer2TVL != 0) {
            if (oldLayer2Info.startBlock != 0 && oldLayer2Info.layer2Tvl != 0) {

                if (oldLayer2Info.layer2Tvl != 0) {
                    uint256 templ2RewardPerUint = l2RewardPerUint + (l2TotalSeigs * WEI_UINT) / totalLayer2TVL;
                    layer2Seigs = ((templ2RewardPerUint * oldLayer2Info.layer2Tvl) / WEI_UINT) - oldLayer2Info.initialDebt;
                }
            }
        }
    }

    /**
     * @notice Query the staking amount held by the operator
     * @param layer2 the layer2(candidate) address
     */
    function getOperatorAmount(address layer2) external view returns (uint256) {
        address operator = Layer2I(layer2).operator();
        return _coinages[layer2].balanceOf(operator);
    }

    /**
     * @notice Check layer2 information managed in Layer2Manager
     * @param layer2            The layer2 address
     * @return rollupConfig     The rollupConfig address of layer2
     * @return allowed          Seigniorage distribution status on layer2.
     *                          If true, seigniorage is being distributed.
     */
    function allowIssuanceLayer2Seigs(
        address layer2
    ) public view returns (address rollupConfig, bool allowed) {
        rollupConfig = ILayer2Manager(layer2Manager).rollupConfigOfOperator(
            Layer2I(layer2).operator()
        );
        if (rollupConfig == address(0)) allowed = false;
        else if (ILayer2Manager(layer2Manager).statusLayer2(rollupConfig) == 1) allowed = true;
    }

    function unallocatedSeigniorage() external view returns (uint256 amount) {
        amount = _tot.totalSupply() - stakeOfAllLayers();
    }

    function unallocatedSeigniorageAt(uint256 snapshotId) external view returns (uint256 amount) {
        amount = _tot.totalSupplyAt(snapshotId) - stakeOfAllLayersAt(snapshotId);
    }

    function stakeOfAllLayers() public view returns (uint256 amount) {
        uint256 num = IILayer2Registry(_registry).numLayer2s();
        for (uint256 i = 0; i < num; i++) {
            address layer2 = IILayer2Registry(_registry).layer2ByIndex(i);
            address coin = address(_coinages[layer2]);
            if (coin != address(0)) amount += _coinages[layer2].totalSupply();
        }
    }

    function stakeOfAllLayersAt(uint256 snapshotId) public view returns (uint256 amount) {
        uint256 num = IILayer2Registry(_registry).numLayer2s();
        for (uint256 i = 0; i < num; i++) {
            address layer2 = IILayer2Registry(_registry).layer2ByIndex(i);
            address coin = address(_coinages[layer2]);
            if (coin != address(0)) amount += _coinages[layer2].totalSupplyAt(snapshotId);
        }
    }

    function isPauseL2Seigniorage(address layer2) public view returns (bool) {
        uint256[] memory pauseBlocks = layer2PauseBlocks[layer2];
        uint256 len = pauseBlocks.length;
        if (len == 0) return false;

        uint256 pauseBlock = pauseBlocks[len - 1];

        if (pauseBlock != 0 && layer2UnpauseBlocks[layer2][pauseBlock] == 0) return true;
        else return false;
    }


    //////////////////////////////
    // Internal functions
    //////////////////////////////

    /**
     * @dev Callback for a new commit
     */
    /// on v1_3, it is changed with reflecting L2 sequencer.
    function _updateSeigniorage() internal ifFree returns (bool) {
        // short circuit if paused
        if (paused) {
            return true;
        }

        if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            _lastSeigBlock = block.number;
            return false;
        }

        RefactorCoinageSnapshotI coinage = _coinages[msg.sender];
        _checkCoinage(address(coinage));

        // require(block.number > _lastSeigBlock, "last seig block is not past");
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

        // calculate commission amount
        bool isCommissionRateNegative_ = _isCommissionRateNegative[msg.sender];

        (nextTotalSupply, operatorSeigs) = _calcSeigsDistribution(
            msg.sender,
            coinage,
            prevTotalSupply,
            seigs,
            isCommissionRateNegative_,
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
                // TODO: adjust arithmetic error
                // burn by 𝜸
                coinage.burnFrom(operator, operatorSeigs);
            } else {
                coinage.mint(operator, operatorSeigs);
            }
        }

        IWTON(_wton).mint(address(_depositManager), seigs);

        emit Comitted(msg.sender);
        emit AddedSeigAtLayer(msg.sender, seigs, operatorSeigs, nextTotalSupply, prevTotalSupply);

        return true;
    }

    function _onlyLayer2Manager() internal view {
        if (msg.sender != layer2Manager) revert OnlyLayer2ManagerError();
    }

    function _checkCoinage(address coinage_) internal pure {
        if (coinage_ == address(0)) revert InvalidCoinageError();
    }

    function _calcSeigsDistribution(
        address layer2,
        RefactorCoinageSnapshotI coinage,
        uint256 prevTotalSupply,
        uint256 seigs,
        bool isCommissionRateNegative_,
        address operator
    ) internal returns (uint256 nextTotalSupply, uint256 operatorSeigs) {
        uint256 _delayedCommissionBlock = delayedCommissionBlock[layer2];

        if (_delayedCommissionBlock != 0 && block.number >= _delayedCommissionBlock) {
            _commissionRates[layer2] = delayedCommissionRate[layer2];
            _isCommissionRateNegative[layer2] = delayedCommissionRateNegative[layer2];
            delayedCommissionBlock[layer2] = 0;
        }

        uint256 commissionRate = _commissionRates[layer2];

        nextTotalSupply = prevTotalSupply + seigs;

        // short circuit if there is no commission rate
        if (commissionRate == 0) return (nextTotalSupply, operatorSeigs);

        // if commission rate is possitive
        if (!isCommissionRateNegative_) {
            operatorSeigs = rmul(seigs, commissionRate); // additional seig for operator
            nextTotalSupply -= operatorSeigs;
            return (nextTotalSupply, operatorSeigs);
        }

        // short circuit if there is no previous total deposit (meanning, there is no deposit)
        if (prevTotalSupply == 0) return (nextTotalSupply, operatorSeigs);

        // See negative commission distribution formular here: TBD
        uint256 operatorBalance = coinage.balanceOf(operator);

        // short circuit if there is no operator deposit
        if (operatorBalance == 0) return (nextTotalSupply, operatorSeigs);

        uint256 operatorRate = rdiv(operatorBalance, prevTotalSupply);

        // ɑ: insufficient seig for operator
        operatorSeigs = rmul(
            rmul(seigs, operatorRate), // seigs for operator
            commissionRate
        );

        // β:
        uint256 delegatorSeigs = operatorRate == RAY
            ? operatorSeigs
            : rdiv(operatorSeigs, RAY - operatorRate);

        // 𝜸:
        operatorSeigs = operatorRate == RAY
            ? operatorSeigs
            : operatorSeigs + rmul(delegatorSeigs, operatorRate);

        // nextTotalSupply = nextTotalSupply + delegatorSeigs;
        nextTotalSupply += delegatorSeigs;

        return (nextTotalSupply, operatorSeigs);
    }

    function _calcNewFactor(
        uint256 source,
        uint256 target,
        uint256 oldFactor
    ) internal pure returns (uint256) {
        return rdiv(rmul(target, oldFactor), source);
    }

    function _increaseTot() internal returns (bool result) {
        // short circuit if already seigniorage is given.
        if (block.number <= _lastSeigBlock) return false;

        if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            _lastSeigBlock = block.number;
            return false;
        }

        // 1. increase total supply of {tot} by maximum seigniorages * staked rate
        //    staked rate = total staked amount / total supply of (W)TON
        uint256 prevTotalSupply = _tot.totalSupply();

        uint256 span = block.number - _lastSeigBlock;
        if (_unpausedBlock > _lastSeigBlock) span -= (_unpausedBlock - _pausedBlock);

        // maximum seigniorages
        uint256 maxSeig = span * _seigPerBlock;

        // total supply of (W)TON , https://github.com/tokamak-network/TON-total-supply
        uint256 tos = _totalSupplyOfTon(block.number);

        // maximum seigniorages * staked rate
        uint256 stakedSeig = rdiv(
            rmul(
                maxSeig,
                // total staked amount
                prevTotalSupply
            ),
            tos
        );

        // If layer2StartBlock is not set, set it to the previous block so that the signiorge will be accumulated to layer2 immediately.
        if (layer2StartBlock == 0) layer2StartBlock = block.number - 1;

        address wton_ = _wton;
        uint256 l2TotalSeigs;
        uint256 layer2Seigs;

        if (layer2Manager != address(0) && layer2StartBlock != 1) {
            if (layer2StartBlock <= block.number && totalLayer2TVL > 0) {
                l2TotalSeigs = rdiv(rmul(maxSeig, totalLayer2TVL * 1e9), tos);
                l2RewardPerUint += (l2TotalSeigs * WEI_UINT) / totalLayer2TVL;
                IWTON(wton_).mint(layer2Manager, l2TotalSeigs);
            }

            (address rollupConfig, bool allowed) = allowIssuanceLayer2Seigs(msg.sender);
            if (allowed && !isPauseL2Seigniorage(msg.sender)) {
                uint256 curLayer2Tvl = IL1BridgeRegistry(l1BridgeRegistry).layer2TVL(rollupConfig);
                Layer2Reward storage newLayer2Info = layer2RewardInfo[msg.sender];
                Layer2Reward memory oldLayer2Info = layer2RewardInfo[msg.sender];

                // update layer2 tvl if it has changed
                // Because the previous information(oldLayer2Info) was loaded into memory, the storage immediately reflects the latest information.
                if (oldLayer2Info.layer2Tvl != curLayer2Tvl) {
                    newLayer2Info.layer2Tvl = curLayer2Tvl;
                    totalLayer2TVL = totalLayer2TVL + curLayer2Tvl - oldLayer2Info.layer2Tvl;
                }

                // If this the first commit, set up an initial debt
                if (oldLayer2Info.startBlock == 0) {
                    newLayer2Info.startBlock = block.number;
                    newLayer2Info.initialDebt = (l2RewardPerUint * curLayer2Tvl) / WEI_UINT;
                } else {
                    newLayer2Info.initialDebt = (l2RewardPerUint * curLayer2Tvl) / WEI_UINT;

                    // distribute seigniorage to layer2 based on previous layer2 tvl
                    // layer2Tvl would be 0 when layer2 has been paused
                    if (oldLayer2Info.layer2Tvl > 0) {
                        layer2Seigs =
                            ((l2RewardPerUint * oldLayer2Info.layer2Tvl) / WEI_UINT) -
                            oldLayer2Info.initialDebt;
                        // rewards just increase higher than layer2Debt because it is calculated based on previous layer2 tvl
                        ILayer2Manager(layer2Manager).transferL2Seigniorage(rollupConfig, layer2Seigs);
                    }
                }
            }
        }

        uint256 unstakedSeig = maxSeig - stakedSeig - l2TotalSeigs;
        uint256 totalPseig = rmul(unstakedSeig, relativeSeigRate);
        uint256 nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
        _lastSeigBlock = block.number;

        _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

        emit CommitLog1(_tot.totalSupply(), tos, prevTotalSupply, nextTotalSupply);

        uint256 powertonSeig;
        uint256 daoSeig;
        uint256 relativeSeig;

        if (_powerton != address(0)) {
            powertonSeig = rmul(unstakedSeig, powerTONSeigRate);
            IWTON(wton_).mint(_powerton, powertonSeig);
        }

        if (dao != address(0)) {
            daoSeig = rmul(unstakedSeig, daoSeigRate);
            IWTON(wton_).mint(dao, daoSeig);
        }

        if (relativeSeigRate != 0) {
            relativeSeig = totalPseig;
            accRelativeSeig += relativeSeig;
        }

        // on v1_3. changed event
        // emit SeigGiven(msg.sender, maxSeig, stakedSeig, unstakedSeig, powertonSeig, daoSeig, relativeSeig);
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

    function _pauseLayer2Tvl(address layer2) internal {
        require(!isPauseL2Seigniorage(layer2), 'already paused');

        if (!ICandidate(layer2).updateSeigniorage()) revert UpdateSeigniorageError();

        Layer2Reward memory info = layer2RewardInfo[layer2];
        totalLayer2TVL -= info.layer2Tvl;
        info.layer2Tvl = 0;
        layer2RewardInfo[layer2] = info;

        layer2PauseBlocks[layer2].push(block.number);
    }

    function _unpauseLayer2Tvl(address layer2) internal {

         (, bool allowed) = allowIssuanceLayer2Seigs(layer2);
        require(allowed, 'not allowed');
        require(isPauseL2Seigniorage(layer2), 'not paused');

        uint256 lastIndex = layer2PauseBlocks[layer2].length - 1;
        layer2UnpauseBlocks[layer2][layer2PauseBlocks[layer2][lastIndex]] = block.number;
        layer2RewardInfo[layer2].startBlock = 0;

        if (!ICandidate(layer2).updateSeigniorage()) revert UpdateSeigniorageError();
    }

    /**
     * @notice  Amount payable to a specific L2 operator
     * @param  layer2           The layer2 addressa
     * @return amount           Amount that can be claimed
     */
    function claimableL2Seigniorage(address layer2) public view returns (uint256 amount) {
        (  , , , , , , , amount ) = estimatedDistribute(block.number+1, layer2);
    }

    //=====

    function _totalSupplyOfTon(uint256 blockNumber) internal view returns (uint256 tos) {
        uint256 startBlock = (seigStartBlock == 0 ? SEIG_START_MAINNET : seigStartBlock);
        uint256 initial = (
            initialTotalSupply == 0 ? INITIAL_TOTAL_SUPPLY_MAINNET : initialTotalSupply
        );
        uint256 burntAmount = (burntAmountAtDAO == 0 ? BURNT_AMOUNT_MAINNET : burntAmountAtDAO);

        tos =
            initial +
            (_seigPerBlock * (blockNumber - startBlock)) -
            (ITON(_ton).balanceOf(address(1)) * (10 ** 9)) -
            burntAmount;
    }


}
