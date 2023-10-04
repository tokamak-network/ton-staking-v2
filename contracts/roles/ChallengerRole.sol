// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/Roles.sol";


contract ChallengerRole {
  using Roles for Roles.Role;

  event ChallengerAdded(address indexed account);
  event ChallengerRemoved(address indexed account);

  Roles.Role private _challengers;

  constructor () {
    _addChallenger(msg.sender);
  }

  modifier onlyChallenger() {
    require(isChallenger(msg.sender));
    _;
  }

  function isChallenger(address account) public view returns (bool) {
    return _challengers.has(account);
  }

  function addChallenger(address account) public onlyChallenger {
    _addChallenger(account);
  }

  function renounceChallenger() public {
    _removeChallenger(msg.sender);
  }

  function _addChallenger(address account) internal {
    _challengers.add(account);
    emit ChallengerAdded(account);
  }

  function _removeChallenger(address account) internal {
    _challengers.remove(account);
    emit ChallengerRemoved(account);
  }
}
