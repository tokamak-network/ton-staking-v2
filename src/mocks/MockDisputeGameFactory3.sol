// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {MockFaultDisputeGame3} from "./MockFaultDisputeGame3.sol";
import {IDisputeGame} from "../layer2/interfaces/IDisputeGame.sol";
import {Claim, GameType, Timestamp} from "../layer2/lib/LibUDT.sol";

/// @title MockDisputeGameFactory3
/// @notice Factory for creating MockFaultDisputeGame3 instances
contract MockDisputeGameFactory3 {
    mapping(bytes32 => address) public gameRegistry;

    event DisputeGameCreated(address indexed game, GameType indexed gameType, Claim rootClaim);

    function create(
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData
    ) external returns (IDisputeGame game) {
        bytes32 gameKey = keccak256(abi.encode(_gameType, _rootClaim, _extraData));
        
        MockFaultDisputeGame3 newGame = new MockFaultDisputeGame3(_gameType, _rootClaim, _extraData, msg.sender);
        gameRegistry[gameKey] = address(newGame);
        
        emit DisputeGameCreated(address(newGame), _gameType, _rootClaim);
        return IDisputeGame(address(newGame));
    }

    function games(
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData
    ) external view returns (IDisputeGame proxy, Timestamp timestamp) {
        bytes32 gameKey = keccak256(abi.encode(_gameType, _rootClaim, _extraData));
        return (IDisputeGame(gameRegistry[gameKey]), Timestamp.wrap(0));
    }
}
