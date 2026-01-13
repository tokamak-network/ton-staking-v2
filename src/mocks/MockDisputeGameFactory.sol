// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./MockFaultDisputeGame2.sol";
import {IDisputeGameFactory} from "../layer2/interfaces/IDisputeGameFactory.sol";
import {IDisputeGame} from "../layer2/interfaces/IDisputeGame.sol";
import {
    GameType,
    Claim,
    Hash,
    Timestamp,
    GameId,
    LibGameId,
    Duration
} from "../layer2/lib/LibUDT.sol";

contract MockDisputeGameFactory is IDisputeGameFactory {
    mapping(bytes32 => address) public gamesMap;
    mapping(uint256 => address) public gameByIndexMap;
    uint256 public gameCount;

    function games(
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData
    ) external view returns (IDisputeGame proxy_, Timestamp timestamp_) {
        Hash uuid = getGameUUID(_gameType, _rootClaim, _extraData);
        address proxy = gamesMap[Hash.unwrap(uuid)];
        if (proxy != address(0)) {
            proxy_ = IDisputeGame(proxy);
            timestamp_ = proxy_.createdAt();
        }
    }

    function gameAtIndex(
        uint256 _index
    ) external view returns (GameType gameType_, Timestamp timestamp_, IDisputeGame proxy_) {
        address proxy = gameByIndexMap[_index];
        if (proxy != address(0)) {
            proxy_ = IDisputeGame(proxy);
            gameType_ = proxy_.gameType();
            timestamp_ = proxy_.createdAt();
        }
    }

    function gameImpls(GameType _gameType) external view returns (IDisputeGame impl_) {
        return IDisputeGame(address(0));
    }

    function initBonds(GameType _gameType) external view returns (uint256 bond_) {
        return 0;
    }

    function create(
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData
    ) external payable returns (IDisputeGame proxy_) {
        MockFaultDisputeGame2.GameConstructorParams memory params = MockFaultDisputeGame2
            .GameConstructorParams({
                gameType: _gameType,
                absolutePrestate: Claim.wrap(bytes32(0)),
                maxGameDepth: 10,
                splitDepth: 5,
                clockExtension: Duration.wrap(0),
                maxClockDuration: Duration.wrap(0),
                vm: IBigStepper(address(0)),
                weth: IDelayedWETH(address(0)),
                anchorStateRegistry: IAnchorStateRegistry(address(0)),
                l2ChainId: 1
            });

        MockFaultDisputeGame2 game = new MockFaultDisputeGame2(params, _rootClaim, _extraData);
        proxy_ = IDisputeGame(address(game));

        Hash uuid = getGameUUID(_gameType, _rootClaim, _extraData);
        gamesMap[Hash.unwrap(uuid)] = address(game);

        gameByIndexMap[gameCount] = address(game);
        gameCount++;

        emit DisputeGameCreated(address(game), _gameType, _rootClaim);
    }

    function setImplementation(GameType _gameType, IDisputeGame _impl) external {}
    function setInitBond(GameType _gameType, uint256 _initBond) external {}

    function getGameUUID(
        GameType _gameType,
        Claim _rootClaim,
        bytes memory _extraData
    ) public pure returns (Hash uuid_) {
        uuid_ = Hash.wrap(
            keccak256(
                abi.encodePacked(GameType.unwrap(_gameType), Claim.unwrap(_rootClaim), _extraData)
            )
        );
    }

    function findLatestGames(
        GameType _gameType,
        uint256 _start,
        uint256 _n
    ) external view returns (GameSearchResult[] memory games_) {}

    function setGame(
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData,
        address _game
    ) external {
        Hash uuid = getGameUUID(_gameType, _rootClaim, _extraData);
        gamesMap[Hash.unwrap(uuid)] = _game;
    }
}
