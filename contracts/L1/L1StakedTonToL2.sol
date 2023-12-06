// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { LibProject } from "../libraries/LibProject.sol";
import "../proxy/ProxyStorage.sol";
import "./L1StakedTonToL2Storage.sol";
// import "hardhat/console.sol";

interface ILockTos {
    function locksInfo(uint256 _lockId)
            external
            view
            returns (
                uint256 start,
                uint256 end,
                uint256 amount
            );

    function locksOf(address _addr)
        external
        view
        returns (uint256[] memory);

    function pointHistoryOf(uint256 _lockId)
        external
        view
        returns (LibLockTOS.Point[] memory);

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
        address addressManagerAddress,
        uint32 minGasLimit_
    ) external onlyOwner {
        _manager = managerAddress;
        lockTos = lockTosAddress;
        addressManager = addressManagerAddress;
        maxLockCountPerRegister = maxLockCountPerRegister_;
        minGasLimitRegister = minGasLimitRegister_;
    }

    function setL2Register(address l2Register_) external onlyManager {
        require(l2Register != l2Register_, "same");
        l2Register = l2Register_;
    }

    /* ========== Anybody can ========== */

    function register(address account) public {
        uint256[] memory lockIds = ILockTos(lockTos).locksOf(account);
        // console.log("register %s", account);
        // console.log("lockIds.length %s", lockIds.length);
        require(lockIds.length != 0, "no register data");
        require(lockIds.length <= maxLockCountPerRegister, "exceeded the maximum number of register.");
        _register(account, lockIds);
    }

    function register(address account, uint256[] memory lockIds) public {
        require(lockIds.length <= maxLockCountPerRegister, "exceeded the maximum number of register.");
        require(lockIds.length != 0, "no register data");
        uint256[] memory userLockIds = ILockTos(lockTos).locksOf(account);

        for(uint256 i = 0; i < lockIds.length; i++){
            bool unMatched = true;
            for(uint256 j = 0; j < userLockIds.length; j++){
                if(lockIds[i] == userLockIds[j]) {
                    unMatched = false;
                    if(j < userLockIds.length-1)
                        userLockIds[j] = userLockIds[userLockIds.length-1];
                    delete userLockIds[userLockIds.length-1];
                    break;
                }
            }
            require(!unMatched, "owner is not account");
        }

        _register(account, lockIds);
    }

    /* ========== VIEW ========== */

    function needSyncList(address account) public view returns (uint256[] memory lockIds, uint256 count) {
        uint256[] memory ids = ILockTos(lockTos).locksOf(account);

        if(ids.length != 0) lockIds = new uint256[](ids.length);
        for(uint256 i = 0; i < ids.length; i++){
            LibLockId.SyncInfo memory curSync = syncInfoOfLockId[ids[i]];
            (, uint256 end, uint256 amount) = ILockTos(lockTos).locksInfo(ids[i]);

            if(amount != 0 && block.timestamp < end) {
                LibLockTOS.Point[] memory history = ILockTos(lockTos).pointHistoryOf(ids[i]);

                if(history.length != 0){
                    LibLockTOS.Point memory point = history[history.length-1];

                    if(uint256(curSync.timestamp) < point.timestamp) {
                        lockIds[count] = ids[i];
                        count++;
                    }
                }
            }
        }
    }

    function viewRegisterInfoOfLockId(uint256 lockId) external view returns(LibLockId.SyncInfo memory) {
        return syncInfoOfLockId[lockId];
    }

    /* === ======= internal ========== */

    function _register(address account, uint256[] memory lockIds) internal {

        bytes memory syncPackets ;
        uint256 syncIdsCount ;

        // packet {address: count to sync: 1st sync packet: 2nd sync packet: .....}
        // address : 20 bytes
        // count to sync : 1 byte (max 256 sync packets) but it is less than maxLockCountPerSync
        // sync packets : count to sync * 104 bytes ( count * 104 )
        // one sync packets : 104 bytes:  (32 byte) uint256 lockId, (32+32+4+4) syncInfo -> total 104

        for(uint256 i = 0; i < lockIds.length; i++){

            LibLockId.SyncInfo memory curSync = syncInfoOfLockId[lockIds[i]];

            (, uint256 end, uint256 amount) = ILockTos(lockTos).locksInfo(lockIds[i]);

            if (amount != 0 && block.timestamp < end){
                LibLockTOS.Point[] memory history = ILockTos(lockTos).pointHistoryOf(lockIds[i]);

                if(history.length != 0){
                    LibLockTOS.Point memory point = history[history.length-1];

                    if(uint256(curSync.timestamp) < point.timestamp) {
                        LibLockId.SyncInfo memory newSync = LibLockId.SyncInfo(
                            {
                                slope: point.slope,
                                bias: point.bias,
                                timestamp: uint32(point.timestamp),
                                syncTime: uint32(block.timestamp)
                            }
                        );

                        syncInfoOfLockId[lockIds[i]] = newSync;
                        syncIdsCount++;

                        syncPackets = bytes.concat(syncPackets,
                            abi.encodePacked(lockIds[i], newSync.slope, newSync.bias, newSync.timestamp, newSync.syncTime));

                    }
                }
            }
            emit Registered(account, lockIds) ;
        }

        require(syncPackets.length > 0, "no register data");
        // console.log('_register syncPackets.length  %s', syncPackets.length);

        _sendMessage(
            l2Register,
            abi.encodePacked(account, syncPackets),
            // bytes.concat(abi.encodePacked(account), syncPackets),
            minGasLimitRegister
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