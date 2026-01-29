// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../libraries/SafeERC20.sol";

import {IIDepositManager} from "../stake/interfaces/IIDepositManager.sol";
import {GameType, Claim} from "./lib/LibUDT.sol";
import {GameStatus} from "./lib/Types.sol";
import {IDisputeGame} from "./interfaces/IDisputeGame.sol";
import {IDisputeGameFactory} from "./interfaces/IDisputeGameFactory.sol";
import {IFaultDisputeGame} from "./interfaces/IFaultDisputeGame.sol";
import {IOptimismSystemConfig as ISystemConfig} from "./interfaces/IOptimismSystemConfig.sol";

import "./Layer2ManagerStorage.sol";
import "./Layer2ManagerV1_2Storage.sol";
import "../proxy/ProxyStorage.sol";
import {AccessibleCommon} from "../common/AccessibleCommon.sol";

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
     * @param operator        the operator address that was slashed
     * @param challengerCount the number of challengers who won the dispute
     * @param disputeGame     the dispute game address
     */
    event CandidateSlashed(
        address indexed operator,
        uint256 challengerCount,
        address disputeGame
    );

    /* ========== Anybody can execute ========== */

    /**
     * @notice Slash the operator when challenger wins the dispute game
     * @param _operatorManager     The operator manager address to be slashed
     * @param _gameType            The game type
     * @param _rootClaim           The root claim
     * @param _extraData           Extra data for the dispute game
     * @param _disputeGame         The dispute game address
     */
    function slashingCandidate(
        address _operatorManager,
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData,
        address _disputeGame
    ) external {
        _nonZeroAddress(_operatorManager);
        //DisputeGameFactory 주소 가져오기
        address disputeGameFactory = ISystemConfig(operatorInfo[_operatorManager].rollupConfig)
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
        require(address(disputeGame) == _disputeGame, "wrong dispute game Address");

        //DisputeGame 주소를 가지고 오면 DisputeGame의 상태를 가져오고 상태가 CHALLENGER_WINS가 아니면 Slashing은 일어나지 않음
        GameStatus status = IDisputeGame(disputeGame).status();
        if (status != GameStatus.CHALLENGER_WINS) revert StatusError();

        // 이미 슬래싱된 DisputeGame인지 확인
        if (slashedDisputeGames[_disputeGame]) revert SlashingError();

        // 승리한 Challenger 주소들 추출
        address[] memory challengers = _getWinningChallengers(_disputeGame);
        require(challengers.length > 0, "no winning challengers");

        //Slashing the operator and reward the challengers
        if (
            !IIDepositManager(depositManager).slash(
                operatorInfo[_operatorManager].candidateAddOn,
                _operatorManager,
                challengers
            )
        ) revert SlashingError();

        // 슬래싱된 DisputeGame으로 표시
        slashedDisputeGames[_disputeGame] = true;

        emit CandidateSlashed(_operatorManager, challengers.length, _disputeGame);
    }

    /* ========== internal ========== */

    function _nonZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) revert ZeroAddressError();
    }

    /**
     * @notice Extract all winning challenger addresses from dispute game
     * @param disputeGame The dispute game address
     * @return challengers The addresses of the winning challengers
     */
    function _getWinningChallengers(address disputeGame) internal view returns (address[] memory challengers) {
        return IFaultDisputeGame(disputeGame).getWinningChallengers();
    }
}
