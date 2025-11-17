// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ILayer2 } from "../dao/interfaces/ILayer2.sol";
import { Layer2RegistryI } from "../dao/interfaces/Layer2RegistryI.sol";
import { ISeigManager } from "./interfaces/ISeigManager.sol";

import "../proxy/ProxyStorage.sol";
import { AuthControlCoinage } from "../common/AuthControlCoinage.sol";
import { Layer2RegistryStorage } from "./Layer2RegistryStorage.sol";


// TODO: transfer coinages ownership to seig manager
contract Layer2Registry is  ProxyStorage, AuthControlCoinage, Layer2RegistryStorage, Layer2RegistryI {

  modifier onlyMinterOrOperator(address layer2) {
    require(hasRole(MINTER_ROLE, msg.sender) || ILayer2(layer2).operator() == msg.sender, "sender is neither admin nor operator");
    _;
  }

  // ------ onlyOwner

  function deployCoinage(
    address layer2,
    address seigManager
  )
    external
    onlyMinterOrOperator(layer2) override
    returns (bool)
  {
    return _deployCoinage(layer2, seigManager);
  }

  function registerAndDeployCoinage(
    address layer2,
    address seigManager
  )
    external
    onlyMinterOrOperator(layer2) override
    returns (bool)
  {
    require(_register(layer2));
    require(_deployCoinage(layer2, seigManager));
    return true;
  }

  function registerAndDeployCoinageAndSetCommissionRate(
    address layer2,
    address seigManager,
    uint256 commissionRate,
    bool isCommissionRateNegative
  )
    external
    onlyMinterOrOperator(layer2)
    returns (bool)
  {
    require(_register(layer2));
    require(_deployCoinage(layer2, seigManager));
    require(_setCommissionRate(layer2, seigManager, commissionRate, isCommissionRateNegative));
    return true;
  }

  function register(address layer2)
    external
    onlyMinterOrOperator(layer2)  override
    returns (bool)
  {
    return _register(layer2);
  }

  function unregister(address layer2) external onlyOwner returns (bool) {
    require(_layer2s[layer2]);

    _layer2s[layer2] = false;
    return true;
  }


  // ------ external

  function layer2s(address layer2) external view override returns (bool) {
    return _layer2s[layer2];
  }

  function numLayer2s() external view  override returns (uint256) {
    return _numLayer2s;
  }

  function layer2ByIndex(uint256 index) external view override returns (address) {
    return _layer2ByIndex[index];
  }

  // ------ internal

  function _register(address layer2) internal returns (bool) {
    require(!_layer2s[layer2]);
    require(ILayer2(layer2).isLayer2());

    _layer2s[layer2] = true;
    _layer2ByIndex[_numLayer2s] = layer2;
    _numLayer2s += 1;

    return true;
  }

  function _deployCoinage(
    address layer2,
    address seigManager
  )
   internal
   returns (bool)
  {
    return ISeigManager(seigManager).deployCoinage(layer2);
  }

  function _setCommissionRate(
    address layer2,
    address seigManager,
    uint256 commissionRate,
    bool isCommissionRateNegative
  )
    internal
    returns (bool)
  {
    return ISeigManager(seigManager).setCommissionRate(layer2, commissionRate, isCommissionRateNegative);
  }

}