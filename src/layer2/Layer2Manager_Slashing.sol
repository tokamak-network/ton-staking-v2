// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '../libraries/SafeERC20.sol';

import {IIDepositManager} from '../stake/interfaces/IIDepositManager.sol';
import {GameType, Claim} from './lib/LibUDT.sol';
import {GameStatus} from './lib/Types.sol';
import {IDisputeGame} from './interfaces/IDisputeGame.sol';
import {IDisputeGameFactory} from './interfaces/IDisputeGameFactory.sol';
import {IFaultDisputeGame} from './interfaces/IFaultDisputeGame.sol';
import {IOptimismSystemConfig as ISystemConfig} from './interfaces/IOptimismSystemConfig.sol';

import './Layer2ManagerStorage.sol';
import './Layer2ManagerV1_2Storage.sol';
import '../proxy/ProxyStorage.sol';
import {AccessibleCommon} from '../common/AccessibleCommon.sol';

error ZeroAddressError();
error StatusError();
error SlashingError();

contract Layer2Manager_Slashing is
    ProxyStorage,
    AccessibleCommon,
    Layer2ManagerStorage,
    Layer2ManagerV1_2Storage
{
    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;

    /**
     * @notice Event occurs when a candidate is slashed
     * @param operator      the operator address that was slashed
     * @param challenger    the challenger address who won the dispute
     * @param disputeGame   the dispute game address
     */
    event CandidateSlashed(
        address indexed operator,
        address indexed challenger,
        address disputeGame
    );

    /* ========== Anybody can execute ========== */

    /**
     * @notice Slash the operator when challenger wins the dispute game
     * @param _operator     The operator address to be slashed
     * @param _gameType     The game type
     * @param _rootClaim    The root claim
     * @param _extraData    Extra data for the dispute game
     * @param _disputeGame  The dispute game address
     */
    function slashingCandidate(
        address _operator,
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData,
        address _disputeGame
    ) external {
        _nonZeroAddress(_operator);
        //DisputeGameFactory 주소 가져오기
        address disputeGameFactory = ISystemConfig(operatorInfo[_operator].rollupConfig)
            .disputeGameFactory();
        //DisputeGameFactory 주소를 가지고 오지 못하면 RollupConfig 주소가 지원되지 않는 주소거나 잘못되었음
        if (disputeGameFactory == address(0)) revert ZeroAddressError();

        //DisputeGameFactory 주소를 가지고 오면 입력한 DisputeGame 주소와 비교하여 DisputeGameFactory에 등록된 DisputeGame 주소인지 확인
        (IDisputeGame disputeGame, ) = IDisputeGameFactory(disputeGameFactory).games(
            _gameType,
            _rootClaim,
            _extraData
        );
        //DisputeGameFactory에 등록된 DisputeGame 주소가 아니면 잘못된 DisputeGame 주소임
        require(address(disputeGame) == _disputeGame, 'wrong dispute game Address');

        //DisputeGame 주소를 가지고 오면 DisputeGame의 상태를 가져오고 상태가 CHALLENGER_WINS가 아니면 Slashing은 일어나지 않음
        GameStatus status = IDisputeGame(disputeGame).status();
        if (status != GameStatus.CHALLENGER_WINS) revert StatusError();

        // 승리한 Challenger 주소 추출: claimData(0).counteredBy
        address challenger = _getWinningChallenger(_disputeGame);
        require(challenger != address(0), 'invalid challenger');

        //Slashing the operator and reward the challenger
        if (
            !IIDepositManager(depositManager).slash(
                operatorInfo[_operator].candidateAddOn,
                _operator,
                challenger
            )
        ) revert SlashingError();

        emit CandidateSlashed(_operator, challenger, _disputeGame);
    }

    /* ========== internal ========== */

    function _nonZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) revert ZeroAddressError();
    }

    /**
     * @notice Extract the winning challenger address from dispute game
     * @param disputeGame The dispute game address
     * @return challenger The address of the winning challenger
     */
    function _getWinningChallenger(address disputeGame) internal view returns (address challenger) {
        // claimData(0)은 루트 클레임이며, counteredBy는 이를 격파한 챌린저의 주소
        (, address counteredBy, , , , , ) = IFaultDisputeGame(disputeGame).claimData(0);
        return counteredBy;
    }
}
