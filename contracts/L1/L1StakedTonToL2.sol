// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IRefactor } from "../stake/interfaces/IRefactor.sol";
import { LibRefactorSync } from "../libraries/LibRefactorSync.sol";
import "../proxy/ProxyStorage.sol";
import "./L1StakedTonToL2Storage.sol";
// import "hardhat/console.sol";

interface IRegistry {
    function numLayer2s() external view returns (uint256);
    function layer2ByIndex(uint256 index) external view returns (address);
}

interface ISeigManager {
    function tot() external view returns (address);
    function coinages(address layer2) external view returns (address);
}

interface IRefactorCoinage {
    function getTotalAndFactor() external view returns (IRefactor.Balance memory, IRefactor.Factor memory) ;
    function getBalanceAndFactor(address account) external view returns (IRefactor.Balance memory, IRefactor.Factor memory);
}

interface IL1StosInL2 {
    function register(bytes memory data) external ;
}

interface L1CrossDomainMessengerI {
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
}

contract L1StakedTonToL2 is ProxyStorage, L1StakedTonToL2Storage {

    event RegisteredAccount(address layer2, address account) ;

    modifier onlyOwner() {
        require(_owner == msg.sender, "not owner");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor () {

    }

    function initialize (
        address manager_,
        address seigManger_,
        address registry_,
        address addressManager_,
        uint32 minGasLimit_
    ) external onlyOwner {
        _manager = manager_;
        seigManger = seigManger_;
        registry = registry_;
        addressManager = addressManager_;
        minGasLimit = minGasLimit_;

        tot = ISeigManager(seigManger).tot();
    }

    function setL2SeigManager(address l2SeigManager_) external onlyManager {
        require(l2SeigManager != l2SeigManager_, "same");
        l2SeigManager = l2SeigManager_;
    }

    function setMinGasLimit(uint32 minGasLimit_) external onlyManager {
        require(minGasLimit != minGasLimit_, "same");
        minGasLimit = minGasLimit_;
    }

    /* ========== Anybody can ========== */

    function _coinage(address layer2) internal returns (address){
        if(coinages[layer2] == address(0)) {
            address coinageAddress = ISeigManager(seigManger).coinages(layer2);
            if(coinageAddress != address(0)) coinages[layer2] = coinageAddress;
        }
        return coinages[layer2];
    }

    function register(address account) public {

        (address[] memory layer2s_, LibRefactorSync.RefactorCoinage[] memory syncInfos_, uint256 count) = needSyncLayer2s(account);
        require(count != 0, "no register data");
        LibRefactorSync.CoinageSyncPacket[] memory info = new LibRefactorSync.CoinageSyncPacket[](count);

        for(uint256 i ; i < count; i++){
            info[i] = LibRefactorSync.CoinageSyncPacket(layer2s_[i],syncInfos_[i]);
        }

        _register(account, info);
    }
    /*
    function register(address account, address[] memory layer2s) public {
        uint256 num =  layer2s.length;
        require(layer2s.length != 0, "empty layer2s");

        for (uint256 i = 0; i < num; i++) {
            address coinageAddress = _coinage(layer2s[i]);

            (IRefactor.Balance memory balance, IRefactor.Factor memory factor1) = IRefactorCoinage(coinageAddress).getBalanceAndFactor(account);
            (IRefactor.Balance memory total, IRefactor.Factor memory factor2) = IRefactorCoinage(coinageAddress).getTotalAndFactor();

        }

        _register(account, lockIds);
    }
    */
    /* ========== VIEW ========== */

    function needSyncLayer2s(address account)
        public view
        returns (address[] memory layer2s, LibRefactorSync.RefactorCoinage[] memory syncInfos, uint256 count)
    {
        uint256 num =  IRegistry(registry).numLayer2s();

        if (num != 0) {
            layer2s = new address[](num);
            syncInfos = new address[](num);
            for(uint256 i = 0; i < num; i++){
                address layer2 = IRegistry(registry).layer2ByIndex(i);
                address coinageAddress = _coinage(layer2);

                (IRefactor.Balance memory balance, IRefactor.Factor memory factor1) = IRefactorCoinage(coinageAddress).getBalanceAndFactor(account);
                (IRefactor.Balance memory total, IRefactor.Factor memory factor2) = IRefactorCoinage(coinageAddress).getTotalAndFactor();

                LibRefactorSync.RefactorCoinage memory curSync = coinageSyncInfo[account][layer2];
                bool boolDiff = false;

                if(curSync.refactor.accountBalance.balance != balance.balance)  boolDiff = true;
                else if(curSync.refactor.totalSupply.balance != total.balance)  boolDiff = true;
                else if(curSync.refactor.factor.factor != factor2.factor)  boolDiff = true;

                if(boolDiff) {
                    layer2s[count] = layer2;
                    syncInfos[count] = curSync;
                    count++;
                }
            }
        }
    }

    function viewCoinageSyncInfo(address account, address layer2) external view returns(LibRefactorSync.RefactorCoinage memory) {
        return coinageSyncInfo[account][layer2];
    }

    /* === ======= internal ========== */

    function _register(address account, LibRefactorSync.CoinageSyncPacket[] memory syncInfos) internal {

        bytes memory syncPackets ;
        uint256 count = syncInfos.length ;

        // packet {account address: count to sync: 1st sync packet: 2nd sync packet: .....}
        // account address : 20 bytes
        // count to sync : 1 byte (max 256 sync packets) but it is less than maxLockCountPerSync
        // sync packets : count to sync * 104 bytes ( count * 104 )
        // one sync packets : 104 bytes:  (32 byte) uint256 lockId, (32+32+4+4) syncInfo -> total 104

        LibRefactorSync.CoinageSyncPackets memory packets = LibRefactorSync.CoinageSyncPackets(
            block.timestamp,
            syncInfos
        );

        require(syncPackets.length > 0, "no register data");
        // console.log('_register syncPackets.length  %s', syncPackets.length);

        _sendMessage(
            l2SeigManager,
            abi.encodePacked(account, packets),
            minGasLimit
            );
    }


    function _sendMessage(address target, bytes memory data, uint32 minGasLimit) internal {
        address l1Messenger = LibProject.getL1CommunicationMessenger(addressManager);
        require(l1Messenger != address(0), "l1Messenger is ZeroAddress");

        bytes memory callData = abi.encodeWithSelector(IL1StosInL2.register.selector, data);

        // console.log('_sendMessage target %s', target, ' data.length %s', data.length);
        // console.logBytes(data);
        // console.log('_sendMessage l1Messenger %s', l1Messenger);

        L1CrossDomainMessengerI(l1Messenger).sendMessage(
                target,
                callData,
                minGasLimit
            );
    }

}