// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { LibL1StakedInfo } from "../libraries/LibL1StakedInfo.sol";
import { IRefactor } from "../stake/interfaces/IRefactor.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";
import "../proxy/ProxyStorage.sol";
import "./L1StakedTonToL2Storage.sol";
// import "hardhat/console.sol";

interface AddressManagerI {
    function getAddress(string memory _name) external view returns (address);
}

interface IRegistry {
    function numLayer2s() external view returns (uint256);
    function layer2ByIndex(uint256 index) external view returns (address);
}

interface ISeigManager {
    function coinages(address layer2) external view returns (address);
    function stakeOf(address layer2, address account) external view returns (uint256);
}

interface IRefactorCoinage {
    function getTotalAndFactor() external view returns (IRefactor.Balance memory, IRefactor.Factor memory) ;
    function getBalanceAndFactor(address account) external view returns (IRefactor.Balance memory, IRefactor.Factor memory);
}

interface IL1StakedTonInL2 {
    function register(bytes memory data) external ;
    function deposit(address layer2, address account, uint256 swton) external ;
    function unstake(address layer2, address account, uint256 swton) external ;
    function updateSeigniorage(address layer2, uint256 swton) external ;
}

interface L1CrossDomainMessengerI {
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
}

contract L1StakedTonToL2 is ProxyStorage, AccessibleCommon, L1StakedTonToL2Storage {

    event RegisteredAccount(address layer2, address account) ;

    modifier onlySeigManager() {
        require(seigManager == msg.sender, "not seigManager");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor () {

    }

    function initialize (
        address manager_,
        address seigManager_,
        address registry_,
        address addressManager_,
        uint32 minGasLimit_
    ) external onlyOwner {
        _manager = manager_;
        seigManager = seigManager_;
        registry = registry_;
        addressManager = addressManager_;
        minGasLimit = minGasLimit_;
    }

    function setL1StakedTonInL2(address l1StakedTonInL2_) external onlyOwner {
        require(l1StakedTonInL2 != l1StakedTonInL2_, "same");
        l1StakedTonInL2 = l1StakedTonInL2_;
    }

    function setMinGasLimit(uint32 minGasLimit_) external onlyOwner {
        require(minGasLimit != minGasLimit_, "same");
        minGasLimit = minGasLimit_;
    }

    /* ========== OnlySeigmanager ========== */
    function deposit(address layer2, address account, uint256 swton) public onlySeigManager {

        bytes memory callData = abi.encodeWithSelector(
            IL1StakedTonInL2.deposit.selector, layer2, account, swton);

        _sendMessage(
            l1StakedTonInL2,
            callData,
            minGasLimit
            );
    }

    function unstake(address layer2, address account, uint256 swton) public onlySeigManager {

        bytes memory callData = abi.encodeWithSelector(
            IL1StakedTonInL2.unstake.selector, layer2, account, swton);

        _sendMessage(
            l1StakedTonInL2,
            callData,
            minGasLimit
            );
    }

    function updateSeigniorage(address layer2, uint256 swton) external {
        bytes memory callData = abi.encodeWithSelector(
            IL1StakedTonInL2.updateSeigniorage.selector, layer2, swton);

        _sendMessage(
            l1StakedTonInL2,
            callData,
            minGasLimit
            );
    }

    /* ========== Anybody can ========== */

    // register account's staked ton fro L1 to L2
    // @param account account address
    function register(address account) public {

        (LibL1StakedInfo.L1StakedPacket[] memory needSyncPackets, uint256 count) = needSyncData(account);

        require(count != 0, "no register data");
        LibL1StakedInfo.L1StakedPacket[] memory sync = new LibL1StakedInfo.L1StakedPacket[](count);

        for(uint256 i ; i < count; i++){
            sync[i] = needSyncPackets[i];
            _record(sync[i].layer, account, sync[i].stakedAmount);
        }

        _register(account, sync);
    }

    // register layer2's account's staked ton fro L1 to L2
    // @param account account address
    // @param layer2s layer2's addresses
    function register(address account, address[] memory layer2s) public {
        uint256 num = layer2s.length;
        uint256 count = 0;
        require(layer2s.length != 0, "empty layer2s");
        LibL1StakedInfo.L1StakedPacket[] memory needSyncInfo = new LibL1StakedInfo.L1StakedPacket[](num);
        for(uint256 i = 0; i < num; i++){
            address layer2 = layer2s[i];
            (bool isNeed, uint256 amount) = isNeedSync(layer2, account);
            if (isNeed) {
                needSyncInfo[count] = LibL1StakedInfo.L1StakedPacket(layer2, amount);
                count++;
            }
        }

        require(count != 0, "no register data");
        LibL1StakedInfo.L1StakedPacket[] memory sync = new LibL1StakedInfo.L1StakedPacket[](count);
        for(uint256 i = 0; i < count; i++){
            sync[i] = needSyncInfo[i];
            _record(sync[i].layer, account, sync[i].stakedAmount);
        }
        _register(account, sync);
    }

    /* ========== VIEW ========== */

    function getBalanceFactor(address layer2, address account)
        public view returns (uint256 balance, uint256 factor)
    {
        address coinage = ISeigManager(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinage");
        (IRefactor.Balance memory b, IRefactor.Factor memory f) = IRefactorCoinage(coinage).getBalanceAndFactor(account);
        balance = b.balance;
        factor = f.factor;
    }

    function isNeedSync(address layer2, address account) public view returns (bool isNeed, uint256 amount)
    {
        amount = ISeigManager(seigManager).stakeOf(layer2, account);
        isNeed = true;
        // (uint256 balance, uint256 factor) = getBalanceFactor(layer2, account);
        // LibL1StakedInfo.L1Staked memory info = syncInfo[account][layer2];
        // if (info.syncTime == 0 && amount != 0) isNeed = true;
        // else if (info.balanceFactor != balance) isNeed = true;
        // else if (info.factor != factor) isNeed = true;
        // else if (info.stakedAmount != amount)  isNeed = true; // rebaseIndex ..
    }

    function needSyncData(address account)
        public view
        returns (LibL1StakedInfo.L1StakedPacket[] memory needSyncInfo, uint256 count)
    {
        uint256 num =  IRegistry(registry).numLayer2s();

        if (num != 0) {
            needSyncInfo = new LibL1StakedInfo.L1StakedPacket[](num);
            for(uint256 i = 0; i < num; i++){
                address layer2 = IRegistry(registry).layer2ByIndex(i);
                (bool isNeed, uint256 amount) = isNeedSync(layer2, account);

                if (isNeed) {
                    needSyncInfo[count] = LibL1StakedInfo.L1StakedPacket(layer2, amount);
                    count++;
                }
            }
        }
    }

    function viewSyncInfo(address account, address layer2) external view returns(LibL1StakedInfo.L1Staked memory) {
        return syncInfo[account][layer2];
    }

    function getL1CommunicationMessenger(address addressManager) public view returns(address _address) {
        if (addressManager == address(0)) return address(0);
        try
            AddressManagerI(addressManager).getAddress('Proxy__OVM_L1CrossDomainMessenger') returns (address a) {
                _address = a;
        } catch (bytes memory ) {
            _address = address(0);
        }
    }

    /* === ======= internal ========== */
    function _record(address layer2, address account, uint256 stakedAmount) internal {
        /*
        LibL1StakedInfo.L1Staked storage info = syncInfo[account][layer2];
        (uint256 balance, uint256 factor) = getBalanceFactor(layer2, account);

        info.syncTime = uint32(block.timestamp);
        info.balanceFactor = balance;
        info.factor = factor;
        info.stakedAmount = stakedAmount;
        */
    }

    function _register(address account, LibL1StakedInfo.L1StakedPacket[] memory syncInfos) internal {

        require(syncInfos.length != 0, "no register data");

        bytes memory syncPackets ;
        uint256 count = syncInfos.length ;

        // packet {account address: 1st sync packet: 2nd sync packet: .....}
        // account address : 20 bytes
        // sync packets : count to sync * 52 bytes ( count * 52 )
            // one sync packets : 52 bytes:  (20 byte) address layer, (32) stakedAmount -> total 52
        for (uint256 i = 0; i < count; i++){
            syncPackets = bytes.concat(syncPackets,
                abi.encodePacked(syncInfos[i].layer, syncInfos[i].stakedAmount));
        }

        bytes memory callData = abi.encodeWithSelector(
            IL1StakedTonInL2.register.selector,
            abi.encodePacked(account, syncPackets));

        _sendMessage(
            l1StakedTonInL2,
            callData,
            minGasLimit
            );
    }

    function _sendMessage(address target, bytes memory data, uint32 minGasLimit) internal {
        address l1Messenger = getL1CommunicationMessenger(addressManager);
        require(l1Messenger != address(0), "l1Messenger is ZeroAddress");

        // console.log('_sendMessage target %s', target, ' data.length %s', data.length);
        // console.logBytes(data);
        // console.log('_sendMessage l1Messenger %s', l1Messenger);

        L1CrossDomainMessengerI(l1Messenger).sendMessage(
                target,
                data,
                minGasLimit
            );
    }


}